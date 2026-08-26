import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../models/tutorial_guide_variant.dart';

/// Tutorial karakterinin uygulama genelindeki tek animasyon dili.
enum TutorialGuideAnimation {
  idle,
  walking,
  pointing,
  attacking,
  reacting,
  celebrating,
  talking,
  leaving,
}

/// Tutorial akışının kalıcı adımları. Sıra, diskte saklanan indeks olduğu için
/// yeni adımlar listenin sonuna eklenmelidir.
enum TutorialGuideStep {
  welcome,
  adventurePrompt,
  enemyChoice,
  enemySelected,
  combatDemo,
  combatWaiting,
  enemyReaction,
  victoryCelebration,
  rewardCoins,
  rewardXp,
  shopPrompt,
  shopWaiting,
  itemBought,
  equipWaiting,
  itemEquipped,
  blacksmithPrompt,
  upgradeWaiting,
  upgradeCompleted,
  wheelPrompt,
  wheelWaiting,
  wheelReward,
  finalReady,
  finalMotto,
  onlineTeaser,
  ratingRequest,
  farewellWorkDone,
  farewellYourTurn,
  farewell,
  leaving,
  completed;

  static TutorialGuideStep fromStoredIndex(int index) {
    if (index < 0 || index >= values.length) return welcome;
    return values[index];
  }
}

enum TutorialGuideTarget {
  none,
  adventureTab,
  enemyList,
  combatArea,
  rewardArea,
  shopTab,
  shopItem,
  inventoryItem,
  upgradeButton,
  wheel,
  wheelReward,
}

/// Spotlight'ın oran tahmini yerine gerçek ekrandaki hedefi izlemesini sağlar.
/// Anahtarlar yalnızca ilgili zorunlu eğitim adımında bir widget'a bağlanır.
abstract final class TutorialGuideTargetKeys {
  static final enemy = GlobalKey(debugLabel: 'tutorial-enemy-target');
  static final shopItem = GlobalKey(debugLabel: 'tutorial-shop-item-target');
  static final inventoryItem = GlobalKey(
    debugLabel: 'tutorial-inventory-item-target',
  );
  static final wheel = GlobalKey(debugLabel: 'tutorial-wheel-target');
  static final wheelReward = GlobalKey(
    debugLabel: 'tutorial-wheel-reward-target',
  );
}

/// Gerçek dosya taramasından çıkan üç karakterin animasyon eşlemesi.
///
/// Asset paketinde ayrı gesture/celebrate/wave dosyası yoktur. Bu yüzden
/// pointing -> Push, celebrating -> Jump, talking -> Idle ve leaving -> Walk
/// eşlemesi kullanılır. Bilinmeyen her durum [idle] ile güvenli biçimde açılır.
abstract final class TutorialGuideAssets {
  static String forAnimation(
    TutorialGuideAnimation animation, [
    TutorialGuideVariant guide = TutorialGuideVariant.mavili,
  ]) {
    final base = guide.assetBase;
    return switch (animation) {
      TutorialGuideAnimation.idle => '${base}_Idle_4.gif',
      TutorialGuideAnimation.walking => '${base}_Walk_6.gif',
      TutorialGuideAnimation.pointing => '${base}_Push_6.gif',
      TutorialGuideAnimation.attacking => '${base}_Attack2_6.gif',
      TutorialGuideAnimation.reacting => '${base}_Hurt_4.gif',
      TutorialGuideAnimation.celebrating => '${base}_Jump_8.gif',
      TutorialGuideAnimation.talking => '${base}_Idle_4.gif',
      TutorialGuideAnimation.leaving => '${base}_Walk_6.gif',
    };
  }
}

class TutorialGuideFrame {
  final String message;
  final TutorialGuideAnimation animation;
  final TutorialGuideTarget target;
  final Alignment alignment;
  final String? primaryLabel;
  final String? secondaryLabel;
  final bool showComingSoon;

  const TutorialGuideFrame({
    required this.message,
    required this.animation,
    required this.alignment,
    this.target = TutorialGuideTarget.none,
    this.primaryLabel,
    this.secondaryLabel,
    this.showComingSoon = false,
  });

  factory TutorialGuideFrame.forStep(TutorialGuideStep step) => switch (step) {
    TutorialGuideStep.welcome => const TutorialGuideFrame(
      message: 'Selam! Maceranda yanında olacağım. Hazırsan başlayalım.',
      animation: TutorialGuideAnimation.talking,
      alignment: Alignment(-0.68, 0.55),
      primaryLabel: 'Başlayalım',
    ),
    TutorialGuideStep.adventurePrompt => const TutorialGuideFrame(
      message: 'Gel, ilk maceranı seçelim.',
      animation: TutorialGuideAnimation.pointing,
      target: TutorialGuideTarget.adventureTab,
      alignment: Alignment(-0.35, 0.35),
    ),
    TutorialGuideStep.enemyChoice => const TutorialGuideFrame(
      message: 'İlk rakibini seç. Acele etme, burada seni bekliyorum.',
      animation: TutorialGuideAnimation.idle,
      target: TutorialGuideTarget.enemyList,
      alignment: Alignment(-0.68, -0.68),
    ),
    TutorialGuideStep.enemySelected => const TutorialGuideFrame(
      message:
          'İyi seçim! İlk maceranda senin yerine ben yürürüm. Sen vuruşumu izle.',
      animation: TutorialGuideAnimation.celebrating,
      alignment: Alignment(-0.65, 0.48),
      primaryLabel: 'Macerayı başlat',
    ),
    TutorialGuideStep.combatDemo => const TutorialGuideFrame(
      message:
          'Bu ilk savaş benden! Adımlarını ve vuruşlarını senin için tamamlıyorum.',
      animation: TutorialGuideAnimation.attacking,
      target: TutorialGuideTarget.combatArea,
      alignment: Alignment(-0.65, 0.5),
    ),
    TutorialGuideStep.combatWaiting => const TutorialGuideFrame(
      message:
          'Şimdi sıra sende. Adımlarını tamamla; savaşı burada izleyeceğim.',
      animation: TutorialGuideAnimation.idle,
      target: TutorialGuideTarget.combatArea,
      alignment: Alignment(-0.7, 0.55),
    ),
    TutorialGuideStep.enemyReaction => const TutorialGuideFrame(
      message: 'Gördün mü? Düşmanlar da karşılık verir.',
      animation: TutorialGuideAnimation.reacting,
      target: TutorialGuideTarget.combatArea,
      alignment: Alignment(-0.65, 0.5),
      primaryLabel: 'Anladım',
    ),
    TutorialGuideStep.victoryCelebration => const TutorialGuideFrame(
      message: 'İşte bu! İlk zaferin.',
      animation: TutorialGuideAnimation.celebrating,
      target: TutorialGuideTarget.rewardArea,
      alignment: Alignment(-0.65, 0.42),
      primaryLabel: 'Ödüllere bak',
    ),
    TutorialGuideStep.rewardCoins => const TutorialGuideFrame(
      message: 'Düşmanları yenerek rastgele altın kazanırsın.',
      animation: TutorialGuideAnimation.pointing,
      target: TutorialGuideTarget.rewardArea,
      alignment: Alignment(-0.65, 0.42),
      primaryLabel: 'Devam',
    ),
    TutorialGuideStep.rewardXp => const TutorialGuideFrame(
      message: 'Deneyim de seni seviye seviye güçlendirir.',
      animation: TutorialGuideAnimation.pointing,
      target: TutorialGuideTarget.rewardArea,
      alignment: Alignment(-0.65, 0.42),
      primaryLabel: 'Mağazaya git',
    ),
    TutorialGuideStep.shopPrompt => const TutorialGuideFrame(
      message: 'Şimdi altınını güce çevirelim. Mağaza burada.',
      animation: TutorialGuideAnimation.pointing,
      target: TutorialGuideTarget.shopTab,
      alignment: Alignment(0.05, 0.35),
    ),
    TutorialGuideStep.shopWaiting => const TutorialGuideFrame(
      message: 'Eğitim altınınla gösterdiğim ilk silahı satın al.',
      animation: TutorialGuideAnimation.idle,
      target: TutorialGuideTarget.shopItem,
      alignment: Alignment(-0.62, -0.72),
    ),
    TutorialGuideStep.itemBought => const TutorialGuideFrame(
      message: 'İşte şimdi güçleniyoruz!',
      animation: TutorialGuideAnimation.celebrating,
      alignment: Alignment(-0.65, 0.48),
      primaryLabel: 'Envanteri aç',
    ),
    TutorialGuideStep.equipWaiting => const TutorialGuideFrame(
      message: 'Yeni eşyanı bul ve Kuşan düğmesine dokun.',
      animation: TutorialGuideAnimation.pointing,
      target: TutorialGuideTarget.inventoryItem,
      alignment: Alignment(0.62, -0.72),
    ),
    TutorialGuideStep.itemEquipped => const TutorialGuideFrame(
      message: 'Çok daha iyi!',
      animation: TutorialGuideAnimation.celebrating,
      alignment: Alignment(-0.65, 0.5),
      primaryLabel: 'Çarka git',
    ),
    TutorialGuideStep.blacksmithPrompt => const TutorialGuideFrame(
      message: 'Biraz daha güç lazım. Demirciye gidelim.',
      animation: TutorialGuideAnimation.walking,
      alignment: Alignment(-0.65, 0.5),
      primaryLabel: 'Demirciyi aç',
    ),
    TutorialGuideStep.upgradeWaiting => const TutorialGuideFrame(
      message: 'Yükselt düğmesi eşyanın seviyesini artırır.',
      animation: TutorialGuideAnimation.pointing,
      target: TutorialGuideTarget.upgradeButton,
      alignment: Alignment(0.65, 0.48),
    ),
    TutorialGuideStep.upgradeCompleted => const TutorialGuideFrame(
      message: 'Şimdi oldu! Eşyan artık çok daha güçlü.',
      animation: TutorialGuideAnimation.celebrating,
      alignment: Alignment(-0.65, 0.5),
      primaryLabel: 'Çarka geç',
    ),
    TutorialGuideStep.wheelPrompt => const TutorialGuideFrame(
      message: 'Son durak: Günlük Çark. Şansını deneyelim.',
      animation: TutorialGuideAnimation.walking,
      alignment: Alignment(-0.65, 0.5),
      primaryLabel: 'Çarkı aç',
    ),
    TutorialGuideStep.wheelWaiting => const TutorialGuideFrame(
      message: 'Çevir ve sonucu birlikte izleyelim.',
      animation: TutorialGuideAnimation.idle,
      target: TutorialGuideTarget.wheel,
      alignment: Alignment(0.68, 0.38),
    ),
    TutorialGuideStep.wheelReward => const TutorialGuideFrame(
      message: 'Şans bugün senden yana!',
      animation: TutorialGuideAnimation.celebrating,
      target: TutorialGuideTarget.wheelReward,
      alignment: Alignment(-0.65, -0.72),
      primaryLabel: 'Devam',
    ),
    TutorialGuideStep.finalReady => const TutorialGuideFrame(
      message: 'Artık hazırsın.',
      animation: TutorialGuideAnimation.celebrating,
      alignment: Alignment(-0.62, 0.2),
      primaryLabel: 'Devam',
    ),
    TutorialGuideStep.finalMotto => const TutorialGuideFrame(
      message: 'Yürü. Güçlen. Düşmanlarını yen.',
      animation: TutorialGuideAnimation.talking,
      alignment: Alignment(-0.62, 0.2),
      primaryLabel: 'Devam',
    ),
    TutorialGuideStep.onlineTeaser => const TutorialGuideFrame(
      message:
          'Ama bu daha başlangıç... Yakında Online Maceralar da burada olacak.',
      animation: TutorialGuideAnimation.pointing,
      alignment: Alignment(-0.62, 0.1),
      primaryLabel: 'Devam',
      showComingSoon: true,
    ),
    TutorialGuideStep.ratingRequest => const TutorialGuideFrame(
      message:
          'Ben gitmeden önce küçük bir ricam var. Maceranı sevdiysen bizi değerlendirmeyi unutma!',
      animation: TutorialGuideAnimation.talking,
      alignment: Alignment(-0.62, 0.15),
      primaryLabel: 'Sonra',
      secondaryLabel: 'Değerlendir',
    ),
    TutorialGuideStep.farewellWorkDone => const TutorialGuideFrame(
      message: 'Benim işim burada bitti.',
      animation: TutorialGuideAnimation.talking,
      alignment: Alignment(-0.55, 0.18),
      primaryLabel: 'Devam',
    ),
    TutorialGuideStep.farewellYourTurn => const TutorialGuideFrame(
      message: 'Şimdi sıra sende.',
      animation: TutorialGuideAnimation.pointing,
      alignment: Alignment(-0.35, 0.18),
      primaryLabel: 'Devam',
    ),
    TutorialGuideStep.farewell => const TutorialGuideFrame(
      message: 'Ben gidiyorum. Macerada görüşürüz!',
      animation: TutorialGuideAnimation.celebrating,
      alignment: Alignment(0.05, 0.18),
      primaryLabel: 'Eğitimi Bitir',
    ),
    TutorialGuideStep.leaving => const TutorialGuideFrame(
      message: '',
      animation: TutorialGuideAnimation.leaving,
      alignment: Alignment(1.8, 0.18),
    ),
    TutorialGuideStep.completed => const TutorialGuideFrame(
      message: '',
      animation: TutorialGuideAnimation.idle,
      alignment: Alignment(1.8, 0.18),
    ),
  };
}

/// Her rota üzerinde kullanılabilen; hedef dışındaki UI'ı kilitleyen guide katmanı.
class TutorialGuideOverlay extends StatefulWidget {
  final ValueListenable<TutorialGuideStep> step;
  final ValueChanged<TutorialGuideStep> onPrimary;
  final ValueChanged<TutorialGuideStep> onSecondary;
  final VoidCallback onLeavingCompleted;
  final TutorialGuideVariant guide;

  const TutorialGuideOverlay({
    super.key,
    required this.step,
    required this.onPrimary,
    required this.onSecondary,
    required this.onLeavingCompleted,
    this.guide = TutorialGuideVariant.mavili,
  });

  @override
  State<TutorialGuideOverlay> createState() => _TutorialGuideOverlayState();
}

class _TutorialGuideOverlayState extends State<TutorialGuideOverlay> {
  Timer? _settleTimer;
  Timer? _leaveTimer;
  Alignment? _lastAlignment;
  TutorialGuideAnimation? _transientAnimation;
  bool _targetRefreshScheduled = false;

  @override
  void dispose() {
    _settleTimer?.cancel();
    _leaveTimer?.cancel();
    super.dispose();
  }

  void _prepareFrame(TutorialGuideStep step, TutorialGuideFrame frame) {
    if (_lastAlignment == null) {
      _lastAlignment = frame.alignment;
      return;
    }
    if (_lastAlignment != frame.alignment &&
        step != TutorialGuideStep.leaving) {
      _lastAlignment = frame.alignment;
      _settleTimer?.cancel();
      _transientAnimation = TutorialGuideAnimation.walking;
      _settleTimer = Timer(const Duration(milliseconds: 620), () {
        if (mounted) setState(() => _transientAnimation = null);
      });
    }
    if (step == TutorialGuideStep.leaving && _leaveTimer == null) {
      _leaveTimer = Timer(const Duration(milliseconds: 1050), () {
        if (mounted) widget.onLeavingCompleted();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TutorialGuideStep>(
      valueListenable: widget.step,
      builder: (context, step, _) {
        if (step == TutorialGuideStep.completed) return const SizedBox.shrink();
        final frame = TutorialGuideFrame.forStep(step);
        _prepareFrame(step, frame);
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final target = _targetRect(
              frame.target,
              size,
              MediaQuery.paddingOf(context),
            );
            return Stack(
              children: [
                if (target != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(painter: _SpotlightPainter(target)),
                    ),
                  ),
                Positioned.fill(child: _TutorialInteractionBarrier(target)),
                if (target != null) _TargetArrow(rect: target),
                AnimatedAlign(
                  duration:
                      step == TutorialGuideStep.leaving
                          ? const Duration(milliseconds: 950)
                          : step == TutorialGuideStep.wheelReward
                          ? Duration.zero
                          : const Duration(milliseconds: 560),
                  curve: Curves.easeInOutCubic,
                  alignment: frame.alignment,
                  child: IgnorePointer(
                    // Yalnızca bilgi veren balon hedefin üzerinden geçerken bile
                    // zorunlu hedef dokunmasını engellememeli. Eylem düğmeli
                    // balonlar ise kendi düğmelerini almaya devam eder.
                    ignoring:
                        frame.primaryLabel == null &&
                        frame.secondaryLabel == null,
                    child: _GuideConversation(
                      key: ValueKey(step),
                      frame: frame,
                      animation: _transientAnimation ?? frame.animation,
                      guide: widget.guide,
                      onPrimary:
                          frame.primaryLabel == null
                              ? null
                              : () => widget.onPrimary(step),
                      onSecondary:
                          frame.secondaryLabel == null
                              ? null
                              : () => widget.onSecondary(step),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Rect? _targetRect(TutorialGuideTarget target, Size size, EdgeInsets safe) {
    final anchoredTarget = _anchoredTargetRect(target);
    if (anchoredTarget != null) return anchoredTarget.inflate(7);

    final usableHeight = size.height - safe.top - safe.bottom;
    return switch (target) {
      TutorialGuideTarget.none => null,
      TutorialGuideTarget.adventureTab => Rect.fromLTWH(
        size.width * .2,
        size.height - safe.bottom - 76,
        size.width * .2,
        72,
      ),
      TutorialGuideTarget.shopTab => Rect.fromLTWH(
        size.width * .4,
        size.height - safe.bottom - 76,
        size.width * .2,
        72,
      ),
      TutorialGuideTarget.enemyList => Rect.fromLTWH(
        size.width * .03,
        safe.top + usableHeight * .59,
        size.width * .94,
        usableHeight * .23,
      ),
      TutorialGuideTarget.combatArea => Rect.fromLTWH(
        size.width * .09,
        safe.top + usableHeight * .2,
        size.width * .82,
        usableHeight * .47,
      ),
      TutorialGuideTarget.rewardArea => Rect.fromLTWH(
        size.width * .22,
        safe.top + usableHeight * .12,
        size.width * .56,
        usableHeight * .27,
      ),
      TutorialGuideTarget.shopItem ||
      TutorialGuideTarget.inventoryItem => Rect.fromLTWH(
        size.width * .03,
        safe.top + usableHeight * .12,
        size.width * .94,
        usableHeight * .72,
      ),
      TutorialGuideTarget.upgradeButton => Rect.fromLTWH(
        size.width * .14,
        safe.top + usableHeight * .67,
        size.width * .72,
        usableHeight * .12,
      ),
      TutorialGuideTarget.wheel => Rect.fromCircle(
        center: Offset(size.width * .5, safe.top + usableHeight * .36),
        radius: size.shortestSide * .33,
      ),
      TutorialGuideTarget.wheelReward => Rect.fromLTWH(
        size.width * .12,
        safe.top + usableHeight * .36,
        size.width * .76,
        usableHeight * .42,
      ),
    };
  }

  Rect? _anchoredTargetRect(TutorialGuideTarget target) {
    final key = switch (target) {
      TutorialGuideTarget.enemyList => TutorialGuideTargetKeys.enemy,
      TutorialGuideTarget.shopItem => TutorialGuideTargetKeys.shopItem,
      TutorialGuideTarget.inventoryItem =>
        TutorialGuideTargetKeys.inventoryItem,
      TutorialGuideTarget.wheel => TutorialGuideTargetKeys.wheel,
      TutorialGuideTarget.wheelReward => TutorialGuideTargetKeys.wheelReward,
      _ => null,
    };
    if (key == null) return null;

    final targetBox = key.currentContext?.findRenderObject();
    final overlayBox = context.findRenderObject();
    if (targetBox is! RenderBox ||
        overlayBox is! RenderBox ||
        !targetBox.hasSize ||
        !overlayBox.hasSize) {
      _scheduleTargetRefresh();
      return null;
    }

    final targetOrigin = targetBox.localToGlobal(Offset.zero);
    final overlayOrigin = overlayBox.localToGlobal(Offset.zero);
    return (targetOrigin - overlayOrigin) & targetBox.size;
  }

  void _scheduleTargetRefresh() {
    if (_targetRefreshScheduled) return;
    _targetRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _targetRefreshScheduled = false;
      if (mounted) setState(() {});
    });
  }
}

class _GuideConversation extends StatefulWidget {
  final TutorialGuideFrame frame;
  final TutorialGuideAnimation animation;
  final TutorialGuideVariant guide;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;

  const _GuideConversation({
    super.key,
    required this.frame,
    required this.animation,
    required this.guide,
    this.onPrimary,
    this.onSecondary,
  });

  @override
  State<_GuideConversation> createState() => _GuideConversationState();
}

class _GuideConversationState extends State<_GuideConversation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _emotion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _emotion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final right = widget.frame.alignment.x > .2;
    final conversationWidth =
        (MediaQuery.sizeOf(context).width - 20).clamp(260.0, 520.0).toDouble();
    final guide = IgnorePointer(
      child: AnimatedBuilder(
        animation: _emotion,
        builder: (context, child) {
          final emotional =
              widget.animation == TutorialGuideAnimation.celebrating;
          final reacting = widget.animation == TutorialGuideAnimation.reacting;
          final dy = emotional ? -5 * _emotion.value : -1.5 * _emotion.value;
          final angle = reacting ? (_emotion.value - .5) * .12 : 0.0;
          return Transform.translate(
            offset: Offset(0, dy),
            child: Transform.rotate(angle: angle, child: child),
          );
        },
        child: _GuideImage(
          animation: widget.animation,
          faceLeft: right,
          guide: widget.guide,
        ),
      ),
    );
    final bubble =
        widget.frame.message.isEmpty
            ? const SizedBox.shrink()
            : Expanded(
              child: _SpeechBubble(
                frame: widget.frame,
                tailOnRight: right,
                onPrimary: widget.onPrimary,
                onSecondary: widget.onSecondary,
              ),
            );

    return Padding(
      padding: const EdgeInsets.all(10),
      child: SizedBox(
        width: conversationWidth,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.end,
          children:
              right
                  ? [bubble, const SizedBox(width: 6), guide]
                  : [guide, const SizedBox(width: 6), bubble],
        ),
      ),
    );
  }
}

class _GuideImage extends StatelessWidget {
  final TutorialGuideAnimation animation;
  final bool faceLeft;
  final TutorialGuideVariant guide;

  const _GuideImage({
    required this.animation,
    required this.faceLeft,
    required this.guide,
  });

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      TutorialGuideAssets.forAnimation(animation, guide),
      key: ValueKey(animation),
      width: 76,
      height: 76,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
      gaplessPlayback: false,
      errorBuilder: (context, error, stackTrace) {
        if (animation == TutorialGuideAnimation.idle) {
          return const Icon(
            Icons.assistant,
            size: 58,
            color: Color(0xFF8D6BFF),
          );
        }
        return Image.asset(
          guide.idleAsset,
          width: 76,
          height: 76,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          errorBuilder:
              (_, __, ___) => const Icon(
                Icons.assistant,
                size: 58,
                color: Color(0xFF8D6BFF),
              ),
        );
      },
    );
    return Transform.flip(flipX: faceLeft, child: image);
  }
}

class _SpeechBubble extends StatelessWidget {
  final TutorialGuideFrame frame;
  final bool tailOnRight;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;

  const _SpeechBubble({
    required this.frame,
    required this.tailOnRight,
    this.onPrimary,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: frame.message,
      child: Material(
        key: const Key('tutorial-speech-bubble'),
        elevation: 12,
        color: const Color(0xFF201A35),
        shadowColor: const Color(0xAA7652FF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(tailOnRight ? 18 : 3),
            bottomRight: Radius.circular(tailOnRight ? 3 : 18),
          ),
          side: const BorderSide(color: Color(0xFF7652FF), width: 1.2),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (frame.showComingSoon) ...[
                const Text(
                  'ONLINE ADVENTURE · COMING SOON',
                  style: TextStyle(
                    color: Color(0xFFFFC84A),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                frame.message,
                style: const TextStyle(
                  color: Colors.white,
                  height: 1.3,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onPrimary != null || onSecondary != null) ...[
                const SizedBox(height: 9),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (onPrimary != null)
                      FilledButton(
                        key: const Key('tutorial-primary-action'),
                        onPressed: onPrimary,
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: Text(frame.primaryLabel!),
                      ),
                    if (onSecondary != null)
                      TextButton(
                        key: const Key('tutorial-secondary-action'),
                        onPressed: onSecondary,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: Text(frame.secondaryLabel!),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetArrow extends StatelessWidget {
  final Rect rect;

  const _TargetArrow({required this.rect});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: rect.center.dx - 18,
      top: (rect.top - 34).clamp(4, double.infinity),
      child: const IgnorePointer(
        child: Icon(
          Icons.keyboard_double_arrow_down_rounded,
          size: 36,
          color: Color(0xFFFFD85C),
          shadows: [Shadow(color: Colors.black, blurRadius: 8)],
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect target;

  const _SpotlightPainter(this.target);

  @override
  void paint(Canvas canvas, Size size) {
    final overlay =
        Path()
          ..addRect(Offset.zero & size)
          ..addRRect(RRect.fromRectAndRadius(target, const Radius.circular(18)))
          ..fillType = PathFillType.evenOdd;
    canvas.drawPath(overlay, Paint()..color = const Color(0x7A000000));
    canvas.drawRRect(
      RRect.fromRectAndRadius(target, const Radius.circular(18)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFFFD85C),
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.target != target;
}

/// Spotlight dışındaki bütün pointer olaylarını yutar. Hedef deliğinde hit-test
/// sonucu üretmediği için olay alttaki gerçek UI elemanına ulaşır.
class _TutorialInteractionBarrier extends LeafRenderObjectWidget {
  final Rect? target;

  const _TutorialInteractionBarrier(this.target);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTutorialInteractionBarrier(target);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderTutorialInteractionBarrier renderObject,
  ) {
    renderObject.target = target;
  }
}

class _RenderTutorialInteractionBarrier extends RenderBox {
  Rect? _target;

  _RenderTutorialInteractionBarrier(this._target);

  set target(Rect? value) {
    if (_target == value) return;
    _target = value;
    markNeedsPaint();
  }

  @override
  void performLayout() => size = constraints.biggest;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (_target?.contains(position) == true) return false;
    if (!size.contains(position)) return false;
    result.add(BoxHitTestEntry(this, position));
    return true;
  }

  @override
  void handleEvent(PointerEvent event, covariant HitTestEntry entry) {}
}
