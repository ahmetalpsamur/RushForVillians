import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

// Savaş HUD'unun **iki ekran tarafından paylaşılan** parçaları
// (Bölüm D / Faz 2).
//
// Normal macera ve Sonsuz Koşu aynı savaş ekranını gösterir; ayrı bir
// tasarım dili yok. Bu dosya ikisinin ortak yapı taşlarını tutar, böylece
// bir kenar boşluğu ya da renk değiştiğinde iki yerde birden düzeltilmesi
// gerekmez.
//
// ⚠️ Bu parçalar `adventure_screen.dart` içindeki private yardımcılardan
// **birebir** taşındı; `ValueKey`'ler korunuyor, yani mevcut macera
// testleri aynı elemanları bulmaya devam ediyor. Davranış değişikliği
// yapılmadı — yalnızca sahiplik değişti.

/// Sahnenin üstündeki tek taraflı can çubuğu.
///
/// Oyuncu solda, düşman sağda; [alignment] metni hangi kenara yasladığını
/// belirler.
class CombatHudHealthBar extends StatelessWidget {
  final Key progressKey;
  final String label;
  final double value;
  final String valueText;
  final Color color;
  final CrossAxisAlignment alignment;

  const CombatHudHealthBar({
    super.key,
    required this.progressKey,
    required this.label,
    required this.value,
    required this.valueText,
    required this.color,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Column(
          crossAxisAlignment: alignment,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
                shadows: [Shadow(color: Colors.black, blurRadius: 6)],
              ),
            ),
            const SizedBox(height: 5),
            LinearProgressIndicator(
              key: progressKey,
              value: value.clamp(0, 1),
              minHeight: 9,
              borderRadius: BorderRadius.circular(10),
              color: color,
              backgroundColor: Colors.white12,
            ),
            const SizedBox(height: 3),
            Text(
              valueText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sahnenin üstünde beliren hasar/olay etiketi.
class CombatHudDamageLabel extends StatelessWidget {
  final String text;
  final Color color;

  const CombatHudDamageLabel({
    super.key,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            shadows: const [Shadow(color: Colors.black, blurRadius: 8)],
          ),
        ),
      ),
    );
  }
}

/// Savaş sahnesinin arka planı: görsel + iki gradyan katmanı.
///
/// Gradyanlar sprite'ların ve HUD yazılarının her arka planda okunur
/// kalmasını sağlıyor; altı farklı savaş arka planı var ve bazıları açık.
class CombatHudBackdrop extends StatelessWidget {
  final String backgroundAsset;

  const CombatHudBackdrop({super.key, required this.backgroundAsset});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          backgroundAsset,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.none,
          errorBuilder: (context, error, stackTrace) =>
              const ColoredBox(color: AppColors.surface),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, 0.18, 0.52, 0.76, 1],
              colors: [
                Color(0xF20A0813),
                Color(0xB8121020),
                Color(0x3317132B),
                Color(0xB8121020),
                Color(0xFA08070F),
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.05),
              radius: 0.95,
              colors: [
                AppColors.primary.withValues(alpha: 0.12),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// HUD'un alt kartı: ilerleme çubuklarını ve çıkış düğmesini taşıyan koyu
/// yuvarlak panel.
class CombatHudPanel extends StatelessWidget {
  final Widget child;

  const CombatHudPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xE6151224),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.34)),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 24)],
      ),
      child: child,
    );
  }
}
