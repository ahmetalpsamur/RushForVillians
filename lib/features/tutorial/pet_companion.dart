import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/pet_sayings.dart';
import '../../core/utils/item_rules.dart' show stableSpread;
import '../../l10n/content_localizations.dart';
import '../../l10n/l10n_context.dart';
import '../../models/tutorial_guide_variant.dart';
import 'tutorial_guide.dart';

/// Tutorial bittikten sonra ekranın altında dolaşan rehber pet.
///
/// Katman dokunuşları yutmaz. Pet seyrek konuşur, ekranın iki kenarında kısa
/// bir idle + climb/attack gösterisi yapar ve ancak sonra yön değiştirir.
class PetCompanionOverlay extends StatefulWidget {
  final PetSituation situation;
  final TutorialGuideVariant guide;

  /// False olduğunda pet bulunduğu yerde death animasyonunu oynatıp kaybolur.
  final bool enabled;
  final VoidCallback? onDismissed;

  /// İlk söz uygulama/overlay açılır açılmaz gelmez.
  final Duration initialDelay;

  /// İki söz arasındaki sessiz süre.
  final Duration silence;
  final Duration bubbleDuration;
  final Duration strollDuration;

  /// Köşede idle animasyonunun kaldığı süre.
  final Duration restDuration;

  /// Idle sonrasındaki climb/attack gösterisinin süresi.
  final Duration edgeActionDuration;

  /// Pet'in ayağının basacağı taban çizgisinin, katmanın **kendi** alt
  /// kenarından yüksekliği.
  ///
  /// Varsayılan `0`: katman `Scaffold.body` içine yerleştirildiğinde body'nin
  /// alt kenarı zaten alt gezinme çubuğunun üst kenarıdır, yani pet hiçbir
  /// sabit piksel hesabı olmadan "barın üstünde" yürür (bkz. GD82). Katmanı
  /// tam ekran bir yere koyan çağıran taraf kendi payını verir.
  final double bottomInset;

  const PetCompanionOverlay({
    super.key,
    required this.situation,
    this.guide = TutorialGuideVariant.mavili,
    this.enabled = true,
    this.onDismissed,
    this.initialDelay = const Duration(seconds: 25),
    this.silence = const Duration(seconds: 90),
    this.bubbleDuration = const Duration(seconds: 5),
    this.strollDuration = const Duration(seconds: 14),
    this.restDuration = const Duration(seconds: 3),
    this.edgeActionDuration = const Duration(milliseconds: 900),
    this.bottomInset = 0,
  });

  /// Sprite kenarı: ekran genişliğinin oranı, makul sınırlar içinde.
  ///
  /// Sabit 56 px küçük telefonda devasa, tablette minik duruyordu. Sınırlar
  /// oranın uçlarda saçmalamasını engelliyor (320 dp → 48, 800 dp → 88).
  static double spriteSizeFor(double screenWidth) =>
      (screenWidth * 0.15).clamp(44.0, 88.0);

  /// Yatay yürüyüş şeridinin iki yanındaki boşluk.
  ///
  /// Alt sınır 12: baloncuğun dar ekranda kenara yapışmaması bu paya bağlı.
  static double marginFor(double screenWidth) =>
      (screenWidth * 0.035).clamp(12.0, 28.0);

  /// Konuşma baloncuğunun en fazla genişliği.
  static double bubbleWidthFor(double screenWidth) =>
      (screenWidth * 0.66).clamp(180.0, 320.0);

  @override
  State<PetCompanionOverlay> createState() => _PetCompanionOverlayState();
}

enum _PetMotion { idle, walking, climbing, attacking, dying, frozen }

class _PetCompanionOverlayState extends State<PetCompanionOverlay>
    with SingleTickerProviderStateMixin {
  static const _deathFreeze = Duration(milliseconds: 320);
  static const _deathFade = Duration(milliseconds: 260);

  late final AnimationController _stroll = AnimationController(
    vsync: this,
    duration: widget.strollDuration,
  );

  Timer? _speechTimer;
  Timer? _bubbleTimer;
  Timer? _patrolTimer;
  Completer<void>? _patrolDelay;
  Timer? _deathTimer;
  Completer<void>? _deathDelay;
  String? _line;
  String? _lastLine;
  int _seed = 0;
  int _patrolRun = 0;
  int _deathRun = 0;
  int _edgeActionIndex = 0;
  int _spriteSerial = 0;
  bool _facingLeft = false;
  double _spriteOpacity = 1;
  _PetMotion _motion = _PetMotion.idle;
  ui.Image? _deathFinalFrame;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _activate();
    } else {
      _beginDeath();
    }
  }

  @override
  void didUpdateWidget(covariant PetCompanionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.strollDuration != widget.strollDuration) {
      _stroll.duration = widget.strollDuration;
    }
    if (oldWidget.enabled && !widget.enabled) {
      _beginDeath();
    } else if (!oldWidget.enabled && widget.enabled) {
      _activate();
    }
    // Bağlam değişimi artık anında konuşturmaz. Bir sonraki planlı söz yeni
    // bağlamın havuzundan seçilir; sekmelere her dokunuşta balon çıkmaz.
  }

  void _activate() {
    _deathRun++;
    _cancelDeathDelay();
    _disposeDeathFrame();
    _spriteOpacity = 1;
    _motion = _PetMotion.idle;
    _spriteSerial++;
    _scheduleSpeech(widget.initialDelay);
    _startPatrol();
  }

  void _scheduleSpeech(Duration delay) {
    _speechTimer?.cancel();
    if (!widget.enabled) return;
    _speechTimer = Timer(delay, _speak);
  }

  void _speak() {
    if (!mounted || !widget.enabled) return;
    final pool = context.l10n.petPool(widget.situation);
    final options =
        pool.length > 1 && _lastLine != null
            ? [
              for (final line in pool)
                if (line != _lastLine) line,
            ]
            : pool;
    final line = options[stableSpread('pet-${_seed++}', options.length)];
    _bubbleTimer?.cancel();
    setState(() {
      _line = line;
      _lastLine = line;
    });
    _bubbleTimer = Timer(widget.bubbleDuration, _hush);
  }

  void _hush() {
    if (!mounted) return;
    setState(() => _line = null);
    _scheduleSpeech(widget.silence);
  }

  void _startPatrol() {
    _cancelPatrolDelay();
    final run = ++_patrolRun;
    unawaited(_patrol(run));
  }

  Future<void> _patrol(int run) async {
    while (mounted && widget.enabled && run == _patrolRun) {
      await _waitForPatrol(widget.restDuration);
      if (!mounted || !widget.enabled || run != _patrolRun) return;

      final action =
          (_edgeActionIndex++).isEven
              ? _PetMotion.climbing
              : _PetMotion.attacking;
      _setMotion(action);
      await _waitForPatrol(widget.edgeActionDuration);
      if (!mounted || !widget.enabled || run != _patrolRun) return;

      final towardRight = _stroll.value < .5;
      _facingLeft = !towardRight;
      _setMotion(_PetMotion.walking);
      try {
        await (towardRight ? _stroll.forward() : _stroll.reverse()).orCancel;
      } on TickerCanceled {
        return;
      }
      if (!mounted || !widget.enabled || run != _patrolRun) return;
      _setMotion(_PetMotion.idle);
    }
  }

  Future<void> _waitForPatrol(Duration duration) {
    _patrolTimer?.cancel();
    final completer = Completer<void>();
    _patrolDelay = completer;
    _patrolTimer = Timer(duration, () {
      _patrolTimer = null;
      if (!completer.isCompleted) completer.complete();
      if (identical(_patrolDelay, completer)) _patrolDelay = null;
    });
    return completer.future;
  }

  void _cancelPatrolDelay() {
    _patrolTimer?.cancel();
    _patrolTimer = null;
    final completer = _patrolDelay;
    _patrolDelay = null;
    if (completer != null && !completer.isCompleted) completer.complete();
  }

  void _setMotion(_PetMotion motion) {
    if (!mounted) return;
    setState(() {
      _motion = motion;
      _spriteSerial++;
    });
  }

  void _beginDeath() {
    _patrolRun++;
    _cancelPatrolDelay();
    _cancelDeathDelay();
    _speechTimer?.cancel();
    _bubbleTimer?.cancel();
    _stroll.stop();
    _disposeDeathFrame();
    final run = ++_deathRun;
    setState(() {
      _line = null;
      _motion = _PetMotion.dying;
      _spriteOpacity = 1;
      _spriteSerial++;
    });
    unawaited(_playDeath(run));
  }

  Future<void> _playDeath(int run) async {
    final asset = TutorialGuideAssets.forAnimation(
      TutorialGuideAnimation.dying,
      widget.guide,
    );
    final stopwatch = Stopwatch()..start();
    final captured = await _decodeLastFrame(asset);
    final duration = captured?.duration ?? const Duration(milliseconds: 900);
    final remaining = duration - stopwatch.elapsed;
    if (remaining > Duration.zero) await _waitForDeath(remaining);

    if (!mounted || widget.enabled || run != _deathRun) {
      captured?.image.dispose();
      return;
    }
    setState(() {
      _deathFinalFrame = captured?.image;
      _motion = _PetMotion.frozen;
      _spriteSerial++;
    });
    await _waitForDeath(_deathFreeze);
    if (!mounted || widget.enabled || run != _deathRun) return;
    setState(() => _spriteOpacity = 0);
    await _waitForDeath(_deathFade);
    if (mounted && !widget.enabled && run == _deathRun) {
      widget.onDismissed?.call();
    }
  }

  Future<void> _waitForDeath(Duration duration) {
    _deathTimer?.cancel();
    final completer = Completer<void>();
    _deathDelay = completer;
    _deathTimer = Timer(duration, () {
      _deathTimer = null;
      if (!completer.isCompleted) completer.complete();
      if (identical(_deathDelay, completer)) _deathDelay = null;
    });
    return completer.future;
  }

  void _cancelDeathDelay() {
    _deathTimer?.cancel();
    _deathTimer = null;
    final completer = _deathDelay;
    _deathDelay = null;
    if (completer != null && !completer.isCompleted) completer.complete();
  }

  Future<_CapturedGifFrame?> _decodeLastFrame(String asset) async {
    ui.Codec? codec;
    ui.Image? lastImage;
    try {
      final data = await rootBundle.load(asset);
      codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      var duration = Duration.zero;
      for (var index = 0; index < codec.frameCount; index++) {
        final frame = await codec.getNextFrame();
        duration += frame.duration;
        lastImage?.dispose();
        lastImage = frame.image;
      }
      if (lastImage == null) return null;
      return _CapturedGifFrame(image: lastImage, duration: duration);
    } catch (_) {
      lastImage?.dispose();
      return null;
    } finally {
      codec?.dispose();
    }
  }

  void _disposeDeathFrame() {
    _deathFinalFrame?.dispose();
    _deathFinalFrame = null;
  }

  TutorialGuideAnimation get _animation => switch (_motion) {
    _PetMotion.idle => TutorialGuideAnimation.idle,
    _PetMotion.walking => TutorialGuideAnimation.walking,
    _PetMotion.climbing => TutorialGuideAnimation.climbing,
    _PetMotion.attacking => TutorialGuideAnimation.attacking,
    _PetMotion.dying || _PetMotion.frozen => TutorialGuideAnimation.dying,
  };

  Widget _sprite(double spriteSize) {
    final frozen = _deathFinalFrame;
    final image =
        _motion == _PetMotion.frozen && frozen != null
            ? RawImage(
              image: frozen,
              width: spriteSize,
              height: spriteSize,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
            )
            : Image.asset(
              TutorialGuideAssets.forAnimation(_animation, widget.guide),
              key: ValueKey('pet-$_spriteSerial-${_animation.name}'),
              width: spriteSize,
              height: spriteSize,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
              gaplessPlayback: false,
              errorBuilder:
                  (_, __, ___) => const Icon(
                    Icons.assistant,
                    size: 44,
                    color: Color(0xFF8D6BFF),
                  ),
            );
    return AnimatedOpacity(
      key: const ValueKey('pet-companion-sprite'),
      opacity: _spriteOpacity,
      duration: _deathFade,
      child: Transform.flip(flipX: _facingLeft, child: image),
    );
  }

  @override
  void dispose() {
    _patrolRun++;
    _deathRun++;
    _speechTimer?.cancel();
    _bubbleTimer?.cancel();
    _cancelPatrolDelay();
    _cancelDeathDelay();
    _stroll.dispose();
    _disposeDeathFrame();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Ölçek **ekran** genişliğinden çıkar, katmanın kendi genişliğinden
          // değil: pet aynı cihazda hep aynı boyutta olmalı, katman nereye
          // yerleştirilirse yerleştirilsin.
          final screenWidth = MediaQuery.sizeOf(context).width;
          final spriteSize = PetCompanionOverlay.spriteSizeFor(screenWidth);
          final margin = PetCompanionOverlay.marginFor(screenWidth);

          // Alt gezinme çubuğu varken `Scaffold` body'den SafeArea payını
          // zaten düşüyor, yani burada `0` gelir ve pet çubuğun üstünde
          // kalır. Çubuk **yokken** pay düşülmez ve pet jest çubuğunun
          // altına kayardı; o yüzden kalan payı burada ekliyoruz. İki durum
          // da tek satırla doğru (GD82).
          final baseline =
              widget.bottomInset + MediaQuery.paddingOf(context).bottom;

          // Yürüyüş şeridi katmanın gerçek genişliğinden türer; pet hiçbir
          // ekranda dışarı taşmaz. Kenar GIF'lerinin tetiklenmesi bu hesaba
          // değil, devriye döngüsüne ve `_stroll.value`'ya bağlı — bu yüzden
          // sınır değişmesi animasyon durumlarını etkilemez.
          final travel = (constraints.maxWidth - spriteSize - margin * 2).clamp(
            0.0,
            double.infinity,
          );
          final bubbleWidth = (constraints.maxWidth - margin * 2).clamp(
            0.0,
            PetCompanionOverlay.bubbleWidthFor(screenWidth),
          );
          final maxBubbleLeft = constraints.maxWidth - bubbleWidth - margin;
          final sprite = _sprite(spriteSize);

          return AnimatedBuilder(
            animation: _stroll,
            child: sprite,
            builder: (context, child) {
              final petLeft = margin + travel * _stroll.value;
              final bubbleLeft = (petLeft + spriteSize * .2).clamp(
                margin,
                maxBubbleLeft < margin ? margin : maxBubbleLeft,
              );
              return Stack(
                children: [
                  if (_line != null)
                    Positioned(
                      left: bubbleLeft,
                      bottom: baseline + spriteSize + 6,
                      width: bubbleWidth,
                      child: _PetBubble(text: _line!),
                    ),
                  Positioned(left: petLeft, bottom: baseline, child: child!),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _CapturedGifFrame {
  final ui.Image image;
  final Duration duration;

  const _CapturedGifFrame({required this.image, required this.duration});
}

class _PetBubble extends StatelessWidget {
  final String text;

  const _PetBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: text,
      child: Container(
        key: const ValueKey('pet-companion-bubble'),
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
        decoration: BoxDecoration(
          color: const Color(0xEE201A35),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: const Color(0x887652FF), width: 1.1),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            height: 1.25,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
