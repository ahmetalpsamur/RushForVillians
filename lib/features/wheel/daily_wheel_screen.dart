import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/wheel_rewards.dart';
import '../../models/item.dart';
import '../../models/game_title.dart';
import '../../models/reward_rarity.dart';
import '../../models/wheel_reward.dart';
import '../../services/reward_sound.dart';
import '../../widgets/day_reset_countdown.dart';
import '../../widgets/section_card.dart';
import '../../widgets/title_badge.dart';
import '../tutorial/tutorial_guide.dart';

/// Günlük çark: adım hedefinin bir kısmı tamamlanınca açılır, günde bir
/// kez çevrilip XP ya da ekipman kazandırır (#16).
///
/// **Sonuç animasyondan önce belirlenir** ve çark tam o dilimin üstünde durur;
/// animasyon sonucu üretmez, yalnızca gösterir. Rastgeleliğin tamamı
/// [seed]'den gelir ve tohum diske yazılır (CLAUDE.md §4.4) — aynı tohum
/// her zaman aynı çarkı ve aynı sonucu verir.
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

  /// Çarktan çıkabilecek ünvan adayları (Bölüm C.4). Havuz süzmeyi
  /// `buildWheelSlices` yapıyor: yalnızca çark kaynaklı ve sahip olunmayanlar.
  final List<GameTitle> titles;

  /// Sahip olunan ünvan kimlikleri.
  final List<String> ownedTitleIds;

  /// Çarkın tohumu ([UserProfile.wheelSeed]).
  final int seed;

  final ValueChanged<WheelReward> onSpinResult;
  final bool tutorialMode;

  const DailyWheelScreen({
    super.key,
    required this.alreadySpunToday,
    required this.onSpinResult,
    required this.seed,
    this.extraSpins = 0,
    this.level = 1,
    this.equipment = const [],
    this.ownedItemIds = const [],
    this.titles = const [],
    this.ownedTitleIds = const [],
    this.tutorialMode = false,
  });

  @override
  State<DailyWheelScreen> createState() => _DailyWheelScreenState();
}

class _DailyWheelScreenState extends State<DailyWheelScreen> {
  bool _spinning = false;
  bool _gearsRunning = false;
  bool _showReward = false;
  WheelReward? _result;

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

  static const _spinDuration = Duration(milliseconds: 2600);
  static const _revealDuration = Duration(milliseconds: 2400);

  late List<WheelReward> _slices = _buildSlices();

  List<WheelReward> _buildSlices() => buildWheelSlices(
    level: widget.level,
    candidates: widget.equipment,
    ownedItemIds: [...widget.ownedItemIds, ..._wonIds],
    seed: _seed,
    titleCandidates: widget.titles,
    ownedTitleIds: [...widget.ownedTitleIds, ..._wonTitleIds],
  );

  /// Bu ekranda kazanılan itemler; ikinci çevirmede tekrar çıkmasınlar.
  final List<String> _wonIds = [];

  /// Aynı kural ünvanlar için (Bölüm C.4).
  final List<String> _wonTitleIds = [];

  int get _remainingExtras => widget.extraSpins - _spentExtras;

  bool get _dailyUsed => widget.alreadySpunToday || _spentDaily;

  bool get _canSpin => !_dailyUsed || _remainingExtras > 0;

  Future<void> _spin() async {
    if (!_canSpin || _spinning) return;

    final winner = pickWinningSlice(_slices.length, _seed);
    final reward = _slices[winner];
    // Hangi hakkın harcandığı burada belirlenir; RootShell aynı kuralı
    // [UserProfile.consumeWheelSpin] içinde uyguluyor.
    final usesExtra = _dailyUsed;

    setState(() {
      _spinning = true;
      _gearsRunning = true;
    });

    await Future<void>.delayed(_spinDuration);
    if (!mounted) return;

    setState(() {
      _spinning = false;
      _result = reward;
      _showReward = true;
      if (reward.isItem) _wonIds.add(reward.item!.id);
      if (reward.isTitle) _wonTitleIds.add(reward.title!.id);
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
    RewardSound.play();

    await Future<void>.delayed(_revealDuration);
    if (!mounted) return;
    setState(() => _showReward = false);
  }

  @override
  Widget build(BuildContext context) {
    final spun = !_canSpin;
    final result = _result;

    return Scaffold(
      appBar: AppBar(title: const Text('Günlük Çark')),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              physics:
                  widget.tutorialMode
                      ? const NeverScrollableScrollPhysics()
                      : null,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _WheelFace(seed: _seed, running: _gearsRunning),
                  const SizedBox(height: 24),
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
                      key:
                          widget.tutorialMode
                              ? TutorialGuideTargetKeys.wheel
                              : null,
                      onPressed: _spinning ? null : _spin,
                      icon: const Icon(Icons.play_arrow),
                      label: Text(
                        _spinning ? 'Dişliler dönüyor...' : 'Çarkı Çevir',
                      ),
                    ),
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
          if (_showReward && result != null)
            Positioned.fill(
              child: _RewardReveal(
                reward: result,
                tutorialMode: widget.tutorialMode,
              ),
            ),
        ],
      ),
    );
  }
}

/// Kazanılan ödülün kartı: item ise görseli ve nadirliğiyle.
class _ResultCard extends StatelessWidget {
  final WheelReward reward;

  const _ResultCard({required this.reward});

  @override
  Widget build(BuildContext context) {
    final title = reward.title;
    if (title != null) {
      return SectionCard(
        child: Column(
          children: [
            const Text('Ünvan kazandın! 🎉', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TitleBadge(title: title),
            const SizedBox(height: 6),
            Text(
              title.lore,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white60,
                fontStyle: FontStyle.italic,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Profildeki Ünvanlar ekranından takabilirsin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 11.5),
            ),
          ],
        ),
      );
    }
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

class _RewardReveal extends StatelessWidget {
  final WheelReward reward;
  final bool tutorialMode;

  const _RewardReveal({required this.reward, required this.tutorialMode});

  @override
  Widget build(BuildContext context) {
    final item = reward.item;
    final glowColor = reward.rarity?.color ?? AppColors.xp;

    return ColoredBox(
      key: const ValueKey('wheel-reward-reveal'),
      color: Colors.black.withValues(alpha: 0.92),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.72, end: 1),
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutBack,
          builder:
              (context, scale, child) => Transform.scale(
                scale: scale,
                child: Opacity(opacity: scale.clamp(0, 1), child: child),
              ),
          child: Container(
            key: tutorialMode ? TutorialGuideTargetKeys.wheelReward : null,
            width: 274,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: glowColor.withValues(alpha: 0.9),
                width: 1.8,
              ),
              gradient: RadialGradient(
                radius: 1.05,
                colors: [
                  glowColor.withValues(alpha: 0.28),
                  const Color(0xFF211C32),
                  const Color(0xFF100D18),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.55),
                  blurRadius: 42,
                  spreadRadius: 7,
                ),
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.26),
                  blurRadius: 90,
                  spreadRadius: 20,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item == null
                      ? 'XP KAZANDIN'
                      : '${item.rarity.label.toUpperCase()} ÖDÜL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: glowColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    shadows: [Shadow(color: glowColor, blurRadius: 14)],
                  ),
                ),
                const SizedBox(height: 18),
                if (item == null)
                  Icon(
                    Icons.bolt_rounded,
                    size: 92,
                    color: glowColor,
                    shadows: [Shadow(color: glowColor, blurRadius: 26)],
                  )
                else
                  Image.asset(
                    item.assetPath,
                    height: 112,
                    width: 112,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none,
                    errorBuilder:
                        (_, _, _) => Icon(
                          Icons.inventory_2_outlined,
                          size: 74,
                          color: glowColor,
                        ),
                  ),
                const SizedBox(height: 16),
                Text(
                  item?.name ?? '+${reward.xp} XP',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (item?.buff.label case final effect?) ...[
                  const SizedBox(height: 8),
                  Text(
                    effect,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: glowColor.withValues(alpha: 0.95),
                      fontSize: 12,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                const Text(
                  'Ödül envanterine işlendi',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Birbirine geçmiş ChanceWheel dişlileri. İlk çevirmede GIF'ler yüklenir ve
/// ekran açık kaldığı sürece kendi sonsuz döngülerinde çalışmaya devam eder.
class _WheelFace extends StatelessWidget {
  final int seed;
  final bool running;

  const _WheelFace({required this.seed, required this.running});

  @override
  Widget build(BuildContext context) {
    final random = Random(seed);
    final gears = List.generate(7, (_) => random.nextInt(11) + 1);
    const placements = <({double left, double top, double size, bool silver})>[
      (left: 18, top: 72, size: 132, silver: false),
      (left: 128, top: 38, size: 112, silver: true),
      (left: 210, top: 112, size: 94, silver: false),
      (left: 120, top: 152, size: 88, silver: true),
      (left: 54, top: 194, size: 72, silver: false),
      (left: 190, top: 220, size: 66, silver: true),
      (left: 20, top: 20, size: 62, silver: true),
    ];

    return SizedBox(
      key: const ValueKey('chance-wheel-face'),
      width: 320,
      height: 330,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          for (var index = 0; index < placements.length; index++)
            Positioned(
              left: placements[index].left,
              top: placements[index].top,
              width: placements[index].size,
              height: placements[index].size,
              child: _GearSprite(
                number: gears[index],
                silver: placements[index].silver,
                running: running,
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            top: 300,
            child: Text(
              running ? 'ŞANS MEKANİZMASI ÇALIŞIYOR' : 'DİŞLİLERİ UYANDIR',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: running ? AppColors.streak : Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                shadows: const [Shadow(color: Colors.black, blurRadius: 6)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GearSprite extends StatelessWidget {
  final int number;
  final bool silver;
  final bool running;

  const _GearSprite({
    required this.number,
    required this.silver,
    required this.running,
  });

  @override
  Widget build(BuildContext context) {
    final tone = silver ? 'silver' : 'normal';
    final asset = 'lib/ChanceWheel/${tone}_gear_$number.gif';
    if (!running) {
      return StillGifFrame(asset: asset);
    }
    return Image.asset(
      asset,
      key: ValueKey('gear-$tone-$number'),
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
      gaplessPlayback: false,
    );
  }
}

/// Bir GIF'in **ilk karesini** durağan olarak çizer.
///
/// Çark dönmüyorken dişlilerin donmuş görünmesi için kullanılıyor.
/// Kasıtlı olarak public: yükleme hatasının sessiz kalmadığı ancak doğrudan
/// widget testiyle doğrulanabiliyor (asset yolunu dışarıdan vermek gerekiyor).
class StillGifFrame extends StatefulWidget {
  final String asset;

  const StillGifFrame({super.key, required this.asset});

  @override
  State<StillGifFrame> createState() => _StillGifFrameState();
}

class _StillGifFrameState extends State<StillGifFrame> {
  ui.Image? _frame;
  ui.Codec? _codec;
  int _loadSerial = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant StillGifFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) _load();
  }

  /// Asset eksik ya da bozuk olabilir; hata sessizce yutulmaz ama uygulamayı
  /// da düşürmez. `_load` bekletilmediği için yakalanmayan bir istisna
  /// buradan çıkıp çark ekranını açan çağrı noktasına düşüyordu (triaj A6).
  /// Aynı dosyadaki `GifTiming._measure` bu deseni zaten izliyor.
  Future<void> _load() async {
    final serial = ++_loadSerial;
    ui.Codec? codec;
    ui.Image? image;
    try {
      final data = await rootBundle.load(widget.asset);
      codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      image = (await codec.getNextFrame()).image;
    } catch (error, stackTrace) {
      debugPrint('Çark karesi yüklenemedi (${widget.asset}): $error');
      debugPrintStack(stackTrace: stackTrace);
      // Yarım kalan kaynaklar bırakılmaz.
      image?.dispose();
      codec?.dispose();
      return;
    }

    if (!mounted || serial != _loadSerial) {
      image.dispose();
      codec.dispose();
      return;
    }
    _frame?.dispose();
    _codec?.dispose();
    setState(() {
      _frame = image;
      _codec = codec;
    });
  }

  @override
  void dispose() {
    _loadSerial++;
    _frame?.dispose();
    _codec?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = _frame;
    if (frame == null) return const SizedBox.shrink();
    return RawImage(
      image: frame,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
    );
  }
}
