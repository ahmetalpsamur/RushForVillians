import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/wheel_rewards.dart';
import '../../models/item.dart';
import '../../models/reward_rarity.dart';
import '../../models/wheel_reward.dart';
import '../../widgets/day_reset_countdown.dart';
import '../../widgets/reward_reveal.dart';
import '../../widgets/section_card.dart';

/// Günlük çark: adım hedefinin bir kısmı tamamlanınca açılır, günde bir
/// kez çevrilip XP ya da ekipman kazandırır (#16).
///
/// **Sonuç animasyondan önce belirlenir** ve çark tam o dilimin üstünde durur;
/// animasyon sonucu üretmez, yalnızca gösterir. Rastgeleliğin tamamı
/// [seed]'den gelir ve tohum diske yazılır (CLAUDE.md §4.4) — aynı tohum
/// her zaman aynı çarkı ve aynı sonucu verir.
///
/// ## Beklenti inşası
///
/// Çark hızlanır, yavaşlar ve dilime oturur. **İyi ödülde yavaşlama daha uzun
/// sürer** ([spinDurationFor]): süre farkı ödülü ele veriyor ama aranan şey
/// tam olarak bu — "acaba" hissi buradan geliyor.
///
/// Durduğunda ödülün nadirliğine göre bir açılış oynar
/// ([RewardRevealOverlay]): sıradan sade, nadir tam ekran.
///
/// **Her aşama atlanabilir.** Dönerken ekrana dokunmak çarkı sonuca ışınlar,
/// açılış sırasında dokunmak animasyonu tamamlar, tamamlanmışsa kapatır.
class DailyWheelScreen extends StatefulWidget {
  /// Bu oyun gününün **ücretsiz** hakkı kullanıldı mı.
  final bool alreadySpunToday;

  /// Mağazadan alınmış ekstra çark hakkı. Günlük hak bittiğinde bunlar
  /// kullanılır ([UserProfile.consumeWheelSpin]).
  final int extraSpins;

  /// Oyuncunun seviyesi. Dilim havuzu buna göre süzülür — kilidin tek
  /// kaynağı [Item.isUnlockedAt] (#10).
  final int level;

  /// Oyuncunun sınıfının kuşanabileceği ekipman ([ItemCatalog]).
  final List<Item> equipment;

  /// Zaten sahip olunan kimlikler; çarktan çıkmazlar.
  final List<String> ownedItemIds;

  /// Çarkın tohumu ([UserProfile.wheelSeed]).
  final int seed;

  final ValueChanged<WheelReward> onSpinResult;

  const DailyWheelScreen({
    super.key,
    required this.alreadySpunToday,
    required this.onSpinResult,
    required this.seed,
    this.extraSpins = 0,
    this.level = 1,
    this.equipment = const [],
    this.ownedItemIds = const [],
  });

  @override
  State<DailyWheelScreen> createState() => _DailyWheelScreenState();
}

class _DailyWheelScreenState extends State<DailyWheelScreen>
    with TickerProviderStateMixin {
  /// Kapanmış açılışın ardından kalan kalıcı sonuç kaydı.
  WheelReward? _result;

  /// Şu an açılışı gösterilen ödül; kapatılınca [_result]'a geçer.
  WheelReward? _revealing;
  WheelRevealTier _revealTier = WheelRevealTier.plain;

  /// Bu ekran açıldığından beri kaç ücretli hak harcandı.
  ///
  /// Ekran itilen bir rotada duruyor ve [RootShell] `setState`'i onu
  /// tazelemiyor; kalan hakkı burada sayıyoruz ki oyuncu ekrandan çıkmadan
  /// ikinci jetonunu da kullanabilsin.
  int _spentExtras = 0;

  /// Günlük hak bu ekranda kullanıldı mı.
  bool _spentDaily = false;

  /// Çevirme sayısına göre ilerleyen tohum: ikinci çevirme aynı sonucu
  /// vermesin. [RootShell] de aynı adımı profile uyguluyor.
  late int _seed = widget.seed;

  /// Çarkın toplam dönüşü (tur). Kazanan dilimi ibrenin altına getirir.
  double _turnsFrom = 0;
  double _turnsTo = 0;

  late final AnimationController _spinController = AnimationController(
    vsync: this,
    duration: spinDurationFor(WheelRevealTier.plain),
  );

  late final AnimationController _revealController = AnimationController(
    vsync: this,
    duration: revealDurationFor(WheelRevealTier.plain),
  );

  /// Hızlan → yüksek hız → uzun yavaşlama.
  ///
  /// Tek bir `easeInOut` yeterince "oturma" hissi vermiyor; sondaki uzun
  /// kuyruk çarkın son dilimlerde sürünmesini sağlıyor.
  static const _spinCurve = Cubic(0.22, 0, 0.06, 1);

  /// Haptic geri bildirimin son tetiklendiği dilim; her dilim sınırında bir
  /// kez çalsın diye tutuluyor.
  int _lastHapticSlice = -1;

  late List<WheelReward> _slices = _buildSlices();

  List<WheelReward> _buildSlices() => buildWheelSlices(
    level: widget.level,
    candidates: widget.equipment,
    ownedItemIds: [...widget.ownedItemIds, ..._wonIds],
    seed: _seed,
  );

  /// Bu ekranda kazanılan itemler; ikinci çevirmede tekrar çıkmasınlar.
  final List<String> _wonIds = [];

  int get _remainingExtras => widget.extraSpins - _spentExtras;

  bool get _dailyUsed => widget.alreadySpunToday || _spentDaily;

  bool get _canSpin => !_dailyUsed || _remainingExtras > 0;

  bool get _spinning => _spinController.isAnimating;

  @override
  void initState() {
    super.initState();
    _spinController.addListener(_onSpinTick);
  }

  @override
  void dispose() {
    _spinController
      ..removeListener(_onSpinTick)
      ..dispose();
    _revealController.dispose();
    super.dispose();
  }

  /// Dönen çarkın ibre altından geçen her dilimi için titreşim.
  ///
  /// **Şiddet artar, sıklık azalır:** çark yavaşladıkça darbeler seyrekleşir
  /// ama sertleşir. Gerilimi kuran şey bu — hızlı ve hafif tıklarla başlayıp
  /// tek tek ağır vuruşlara inmek.
  void _onSpinTick() {
    if (_slices.isEmpty) return;
    final t = _spinController.value;
    final turns =
        _turnsFrom + (_turnsTo - _turnsFrom) * _spinCurve.transform(t);
    final slice = (turns * _slices.length).floor();
    if (slice == _lastHapticSlice) return;
    _lastHapticSlice = slice;

    if (t < 0.55) {
      HapticFeedback.selectionClick();
    } else if (t < 0.85) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _spin() async {
    if (!_canSpin || _spinning || _revealing != null) return;

    final winner = pickWinningSlice(_slices.length, _seed);
    final reward = _slices[winner];
    final tier = revealTierFor(reward);
    // Hangi hakkın harcandığı burada belirlenir; RootShell aynı kuralı
    // [UserProfile.consumeWheelSpin] içinde uyguluyor.
    final usesExtra = _dailyUsed;

    setState(() {
      _result = null;
      _lastHapticSlice = -1;
      _spinController.duration = spinDurationFor(tier);
      // Kazanan dilimin **ortası** ibrenin altına gelsin. İbre yukarıda
      // (saat 12) duruyor; dilimler saat 12'den başlayıp saat yönünde
      // diziliyor, bu yüzden çark ters yönde o kadar döndürülüyor.
      final sliceTurn = (winner + 0.5) / _slices.length;
      _turnsFrom = _turnsTo;
      _turnsTo += 5 - sliceTurn - (_turnsTo % 1);
    });

    // Atlandığında (`_handleTap`) denetleyicinin değeri elle 1'e çekiliyor;
    // bu ticker'ı **iptal** eder ve `forward`'ın döndürdüğü future normal
    // yoldan hiç tamamlanmaz. İptali yakalamazsak akış burada asılı kalır ve
    // ödül hiç verilmez — atlama sessizce çevirmeyi yutardı.
    try {
      await _spinController.forward(from: 0).orCancel;
    } on TickerCanceled {
      // Atlandı ya da ekran kapandı; ikisi de normal. Sonuç zaten belliydi,
      // aşağıdan devam ediyoruz.
    }
    if (!mounted) return;

    HapticFeedback.heavyImpact();

    setState(() {
      _revealing = reward;
      _revealTier = tier;
      _revealController.duration = revealDurationFor(tier);
      if (reward.isItem) _wonIds.add(reward.item!.id);
      if (usesExtra) {
        _spentExtras++;
      } else {
        _spentDaily = true;
      }
      // Tohum ilerletilir ve çark yeniden kurulur: bir sonraki çevirme
      // aynı dilimleri ve aynı sonucu vermesin.
      _seed = nextWheelSeed(_seed);
      _slices = _buildSlices();
    });

    widget.onSpinResult(reward);
    try {
      await _revealController.forward(from: 0);
    } on TickerCanceled {
      // Açılış atlandı.
    }
  }

  /// Ekrana dokunmanın anlamı, hangi aşamada olduğumuza göre değişir.
  ///
  /// Devre dışı hiçbir aşama yok: her dokunuş bir şey yapar ve oyuncu
  /// animasyonu izlemeye mahkûm değil.
  void _handleTap() {
    if (_spinning) {
      // Çarkı sonuca ışınla; sonuç zaten belliydi.
      _spinController.value = 1;
      return;
    }
    if (_revealing == null) return;
    if (_revealController.isAnimating) {
      _revealController.value = 1;
      return;
    }
    setState(() {
      _result = _revealing;
      _revealing = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final spun = !_canSpin;
    final result = _result;
    final revealing = _revealing;

    return Scaffold(
      appBar: AppBar(title: const Text('Günlük Çark')),
      body: Stack(
        children: [
          GestureDetector(
            // Dönerken ekranın herhangi bir yerine dokunmak animasyonu geçer.
            onTap: _spinning ? _handleTap : null,
            behavior: HitTestBehavior.deferToChild,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _WheelFace(
                    slices: _slices,
                    animation: _spinController,
                    curve: _spinCurve,
                    turnsFrom: _turnsFrom,
                    turnsTo: _turnsTo,
                  ),
                  const SizedBox(height: 24),
                  if (_spinning) ...[
                    const Text(
                      'Dokunarak geçebilirsin',
                      style: TextStyle(fontSize: 12, color: Colors.white38),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (result != null) ...[
                    _ResultCard(reward: result),
                    const SizedBox(height: 12),
                  ],
                  if (spun)
                    SectionCard(
                      child: Column(
                        children: [
                          if (result == null)
                            const Text(
                              'Bugün çarkı zaten çevirdin.',
                              textAlign: TextAlign.center,
                            ),
                          if (result == null) const SizedBox(height: 8),
                          // Gün sınırı GameDay'den okunur; burada ayrı bir
                          // gün/saat hesabı yapılmaz.
                          const DayResetCountdown(
                            prefix: 'Yeni çark hakkına kalan süre: ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    FilledButton.icon(
                      onPressed: _spinning ? null : _spin,
                      icon: const Icon(Icons.play_arrow),
                      label: Text(_spinning ? 'Çevriliyor...' : 'Çarkı Çevir'),
                    ),
                    // Ücretli hak harcanacaksa oyuncu bunu **önceden** bilmeli.
                    if (_dailyUsed) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Bu çevirme ekstra hakkından düşecek '
                        '($_remainingExtras hak kaldı).',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.streak,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          if (revealing != null)
            RewardRevealOverlay(
              reward: revealing,
              tier: _revealTier,
              animation: _revealController,
              seed: _seed,
              onTap: _handleTap,
            ),
        ],
      ),
    );
  }
}

/// Kazanılan ödülün kalıcı kaydı; açılış kapandıktan sonra görünür.
class _ResultCard extends StatelessWidget {
  final WheelReward reward;

  const _ResultCard({required this.reward});

  @override
  Widget build(BuildContext context) {
    final item = reward.item;
    if (item == null) {
      return Text(
        'Kazandın: ${reward.label} 🎉',
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
      );
    }
    return SectionCard(
      child: Column(
        children: [
          const Text('Ekipman kazandın! 🎉', textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Image.asset(
            item.assetPath,
            height: 56,
            filterQuality: FilterQuality.none,
            errorBuilder:
                (context, error, stackTrace) => const Icon(
                  Icons.inventory_2_outlined,
                  size: 40,
                  color: Colors.white24,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            item.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            item.rarity.label,
            style: TextStyle(
              color: item.rarity.color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dilimli çark ve üstündeki sabit ibre.
///
/// **Performans:** çark yüzeyi bir [RepaintBoundary] içinde bir kez çizilip
/// dönme sırasında yalnızca dönüştürülüyor; her karede yeniden boyanmıyor.
/// [_WheelPainter.shouldRepaint] de dilimler değişmedikçe `false` dönüyor.
class _WheelFace extends StatelessWidget {
  final List<WheelReward> slices;
  final Animation<double> animation;
  final Curve curve;
  final double turnsFrom;
  final double turnsTo;

  const _WheelFace({
    required this.slices,
    required this.animation,
    required this.curve,
    required this.turnsFrom,
    required this.turnsTo,
  });

  @override
  Widget build(BuildContext context) {
    final face = RepaintBoundary(
      child: SizedBox(
        width: 260,
        height: 260,
        child: CustomPaint(painter: _WheelPainter(slices)),
      ),
    );

    return SizedBox(
      width: 260,
      height: 276,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 16,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final turns =
                    turnsFrom +
                    (turnsTo - turnsFrom) * curve.transform(animation.value);
                return Transform.rotate(angle: turns * 2 * pi, child: child);
              },
              child: face,
            ),
          ),
          // İbre saat 12'de sabit; kazanan dilim buraya gelir.
          const Icon(
            Icons.arrow_drop_down,
            size: 40,
            color: AppColors.streak,
            shadows: [Shadow(color: Colors.black, blurRadius: 6)],
          ),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<WheelReward> slices;

  _WheelPainter(this.slices);

  /// XP dilimleri tek renk; item dilimleri nadirlik rengini alır — oyuncu
  /// çark dönmeden neyin peşinde olduğunu görsün.
  Color _sliceColor(WheelReward reward, int index) {
    final item = reward.item;
    if (item != null) return item.rarity.color;
    return index.isEven ? AppColors.primary : AppColors.surface;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (slices.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweep = 2 * pi / slices.length;
    // Saat 12'den başla: dilim 0'ın ortası ibrenin altında.
    final start = -pi / 2 - sweep / 2;

    for (var i = 0; i < slices.length; i++) {
      final paint =
          Paint()
            ..style = PaintingStyle.fill
            ..color = _sliceColor(slices[i], i);
      canvas.drawArc(rect, start + i * sweep, sweep, true, paint);

      final border =
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = Colors.black.withValues(alpha: 0.35);
      canvas.drawArc(rect, start + i * sweep, sweep, true, border);

      _paintLabel(canvas, center, radius, start + i * sweep + sweep / 2, i);
    }

    final ring =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = AppColors.primary;
    canvas.drawCircle(center, radius - 2, ring);
  }

  void _paintLabel(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
    int index,
  ) {
    final reward = slices[index];
    final text =
        reward.isItem
            ? reward.item!.rarity.label
            : '${reward.xp} XP'.replaceAll(' ', ' ');

    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: radius * 0.8);

    final position =
        center +
        Offset(cos(angle), sin(angle)) * (radius * 0.62) -
        Offset(painter.width / 2, painter.height / 2);
    painter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(_WheelPainter oldDelegate) => oldDelegate.slices != slices;
}
