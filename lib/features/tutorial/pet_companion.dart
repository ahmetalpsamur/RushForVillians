import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/pet_sayings.dart';
import '../../models/tutorial_guide_variant.dart';
import 'tutorial_guide.dart';

/// Eğitim bittikten sonra ekranda serbest dolaşan rehber (Bölüm D).
///
/// **Mevcut pet bileşeni yeniden yazılmadı.** Sprite, animasyon eşlemesi ve
/// karakter seçimi hâlâ `tutorial_guide.dart` içindeki
/// [TutorialGuideAssets] / [TutorialGuideVariant] üzerinden geliyor; bu
/// katman yalnızca **nerede duracağını ve ne zaman konuşacağını** ekliyor.
/// Eğitim akışına (adımlar, spotlight, etkileşim bariyeri) hiç dokunulmadı.
///
/// Üç sert kural:
///
/// 1. **Hiçbir düğmeyi engellemez.** Bütün katman [IgnorePointer] içinde;
///    dokunuşlar altındaki ekrana geçer. Rehber tıklanabilir olsaydı, dar
///    ekranda alt gezinme çubuğunun ya da satın alma düğmesinin üstüne
///    denk geldiği anda oyuncuyu kilitlerdi.
/// 2. **Sık konuşmaz.** İki söz arasında en az [silence] geçer ve baloncuk
///    [bubbleDuration] kadar durur. Sekme değişimi bu bekleyişi **atlar**:
///    yeni bağlama girildiği an rehberin söyleyecek bir şeyi vardır.
/// 3. **Arka arkaya aynı şeyi söylemez** — son cümle hatırlanıp havuzdan
///    eleniyor.
///
/// Eğitim sürerken bu katman hiç kurulmaz (`RootShell` karar veriyor):
/// iki anlatıcının aynı anda konuşması hem görsel hem anlatı olarak yanlış.
class PetCompanionOverlay extends StatefulWidget {
  /// Rehberin o an baktığı durum; değişince yeni bir söz tetiklenir.
  final PetSituation situation;

  /// Oyuncunun seçtiği karakter.
  final TutorialGuideVariant guide;

  /// İki söz arasındaki en kısa süre.
  final Duration silence;

  /// Baloncuğun ekranda kalma süresi.
  final Duration bubbleDuration;

  /// Uçtan uca bir yürüyüşün süresi.
  final Duration strollDuration;

  /// İki yürüyüş arasında rehberin durup beklediği süre.
  final Duration restDuration;

  /// Alt gezinme çubuğuna bırakılan pay; rehber onun üstünde yürür.
  final double bottomInset;

  const PetCompanionOverlay({
    super.key,
    required this.situation,
    this.guide = TutorialGuideVariant.mavili,
    this.silence = const Duration(seconds: 45),
    this.bubbleDuration = const Duration(seconds: 6),
    this.strollDuration = const Duration(seconds: 14),
    this.restDuration = const Duration(seconds: 12),
    this.bottomInset = 96,
  });

  @override
  State<PetCompanionOverlay> createState() => _PetCompanionOverlayState();
}

class _PetCompanionOverlayState extends State<PetCompanionOverlay>
    with SingleTickerProviderStateMixin {
  static const double _spriteSize = 56;

  late final AnimationController _stroll = AnimationController(
    vsync: this,
    duration: widget.strollDuration,
  );

  Timer? _bubbleTimer;
  Timer? _strollTimer;
  String? _line;
  String? _lastLine;
  int _seed = 0;

  @override
  void initState() {
    super.initState();
    // Sekmeye girer girmez bir şey söylesin: ilk izlenim sessiz olmamalı.
    _speak();
    _scheduleStroll();
  }

  /// Rehber **sürekli** yürümüyor: bir tur atıyor, sonra durup dinleniyor.
  ///
  /// Bu yalnızca bir tempo tercihi değil, teknik bir zorunluluk: sonsuz
  /// tekrar eden bir animasyon her karede yeni bir kare planlar ve
  /// `pumpAndSettle` **hiçbir zaman** dönmez — projenin bütün `RootShell`
  /// widget testleri o çağrıya dayanıyor (CLAUDE.md test ortamı notu).
  /// Bitimli tur + zamanlayıcı, hem cihazda daha sakin duruyor hem 60'tan
  /// fazla mevcut testi ayakta tutuyor.
  void _scheduleStroll() {
    _strollTimer?.cancel();
    _strollTimer = Timer(widget.restDuration, () {
      if (!mounted) return;
      final forward = _stroll.value < 0.5;
      final walk = forward ? _stroll.forward() : _stroll.reverse();
      walk.whenComplete(() {
        if (mounted) _scheduleStroll();
      });
    });
  }

  @override
  void didUpdateWidget(PetCompanionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.situation.context != widget.situation.context) {
      // Bağlam değişti: bekleme süresi atlanır (kural 2).
      _speak();
    }
  }

  @override
  void dispose() {
    _bubbleTimer?.cancel();
    _strollTimer?.cancel();
    _stroll.dispose();
    super.dispose();
  }

  void _speak() {
    final line = PetSayings.pick(
      widget.situation,
      seed: _seed++,
      avoid: _lastLine,
    );
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
    // Sessizlik payı: rehber ancak bu süre dolduktan sonra tekrar konuşur.
    _bubbleTimer = Timer(widget.silence, () {
      if (mounted) _speak();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Bütün katman dokunuşa kapalı: rehber hiçbir düğmenin önünü kesemez.
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final travel = (constraints.maxWidth - _spriteSize - 24).clamp(
            0.0,
            double.infinity,
          );
          // Yürüyüşün kendisi GIF; her karede yeniden **inşa** edilmemesi
          // için sprite `child` olarak dışarıda tutuluyor (GD60 deseni).
          final sprite = Image.asset(
            TutorialGuideAssets.forAnimation(
              TutorialGuideAnimation.walking,
              widget.guide,
            ),
            key: const ValueKey('pet-companion-sprite'),
            width: _spriteSize,
            height: _spriteSize,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.assistant,
              size: 44,
              color: Color(0xFF8D6BFF),
            ),
          );
          return Stack(
            children: [
              AnimatedBuilder(
                animation: _stroll,
                builder: (context, child) {
                  final goingLeft = _stroll.status == AnimationStatus.reverse;
                  return Positioned(
                    left: 12 + travel * _stroll.value,
                    bottom: widget.bottomInset,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_line != null) _PetBubble(text: _line!),
                        Transform.flip(flipX: goingLeft, child: child),
                      ],
                    ),
                  );
                },
                child: sprite,
              ),
            ],
          );
        },
      ),
    );
  }
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
        constraints: const BoxConstraints(maxWidth: 232),
        margin: const EdgeInsets.only(bottom: 6),
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
