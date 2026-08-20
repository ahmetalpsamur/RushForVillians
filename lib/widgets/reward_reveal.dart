import 'dart:math';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/wheel_rewards.dart';
import '../models/reward_rarity.dart';
import '../models/wheel_reward.dart';

/// Kazanılan ödülün tam ekran açılışı.
///
/// Çark durduktan sonra gösterilir. Şiddeti [WheelRevealTier] belirler:
/// sıradan ödül sadece büyüyerek açılır, çarkın en iyi ödülü ışık patlaması
/// ve parçacıklarla gelir.
///
/// **Animasyon sonucu üretmez.** Ödül çark dönmeden önce belli
/// ([pickWinningSlice]); burası yalnızca onu gösteriyor.
///
/// **Atlanabilir.** Dokunmak animasyonu tamamlar; tamamlanmışsa kapatır.
/// Her gün çeviren biri onuncu günde animasyonu izlemek istemez.
///
/// ## Performans
///
/// - Parçacıkların tamamı **tek** bir [CustomPainter] içinde çiziliyor ve
///   tek bir [Animation]'dan besleniyor; parçacık başına widget yok.
/// - Sayı [particleCountFor] ile sınırlı (en fazla 48) ve sıradan ödülde
///   sıfır.
/// - Yeniden çizim [AnimatedBuilder] ile yalnızca animasyonlu katmana
///   kapsanıyor; ödül kartının içeriği (görsel, metin) animasyonun dışında
///   kurulup [child] olarak geçiriliyor, yani her karede yeniden inşa
///   edilmiyor.
/// - Parçacık geometrisi tohumdan **bir kez** üretiliyor
///   ([_ParticleField]); her karede rastgele sayı çekilmiyor.
class RewardRevealOverlay extends StatelessWidget {
  final WheelReward reward;
  final WheelRevealTier tier;

  /// 0 → 1 ilerleyen açılış animasyonu.
  final Animation<double> animation;

  /// Parçacıkların yönü ve hızı bundan türer; aynı tohum aynı görüntüyü
  /// verir (CLAUDE.md §4.4 ile aynı disiplin).
  final int seed;

  final VoidCallback onTap;

  const RewardRevealOverlay({
    super.key,
    required this.reward,
    required this.tier,
    required this.animation,
    required this.seed,
    required this.onTap,
  });

  Color get _accent => reward.item?.rarity.color ?? AppColors.xp;

  @override
  Widget build(BuildContext context) {
    final particles = _ParticleField(count: particleCountFor(tier), seed: seed);

    // Kartın içeriği animasyonun dışında bir kez kuruluyor.
    final card = _RewardCard(reward: reward, accent: _accent, tier: tier);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final t = animation.value.clamp(0.0, 1.0);
          // Kart geriden gelip hafifçe zıplayarak oturur.
          final scale = 0.55 + 0.45 * Curves.easeOutBack.transform(t);
          return Stack(
            fit: StackFit.expand,
            children: [
              // Karartma: arka plan geri çekilsin, ödül öne çıksın.
              ColoredBox(color: Colors.black.withValues(alpha: 0.72 * t)),
              if (tier != WheelRevealTier.plain)
                CustomPaint(
                  painter: _BurstPainter(
                    progress: t,
                    color: _accent,
                    particles: particles,
                    spectacular: tier == WheelRevealTier.spectacular,
                  ),
                ),
              Center(
                child: Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Transform.scale(scale: scale, child: child),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 36,
                child: Opacity(
                  opacity: (t - 0.6).clamp(0.0, 1.0) / 0.4,
                  child: const Text(
                    'Devam etmek için dokun',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                ),
              ),
            ],
          );
        },
        child: card,
      ),
    );
  }
}

/// Açılış kartı: ödülün adı, görseli ve etkileri.
class _RewardCard extends StatelessWidget {
  final WheelReward reward;
  final Color accent;
  final WheelRevealTier tier;

  const _RewardCard({
    required this.reward,
    required this.accent,
    required this.tier,
  });

  @override
  Widget build(BuildContext context) {
    final item = reward.item;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent, width: 2),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.45),
            blurRadius: tier == WheelRevealTier.spectacular ? 46 : 22,
            spreadRadius: tier == WheelRevealTier.spectacular ? 6 : 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            switch (tier) {
              WheelRevealTier.plain => 'Kazandın',
              WheelRevealTier.bright => 'Güzel çıktı!',
              WheelRevealTier.spectacular => 'NADİR ÖDÜL!',
            },
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
              fontSize: tier == WheelRevealTier.spectacular ? 20 : 15,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          if (item == null)
            Text(
              '+${reward.xp} XP',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: AppColors.xp,
              ),
            )
          else ...[
            Image.asset(
              item.assetPath,
              height: 92,
              filterQuality: FilterQuality.none,
              errorBuilder:
                  (context, error, stackTrace) => const Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.white24,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              item.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              item.rarity.label,
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            if (item.lore case final lore?) ...[
              const SizedBox(height: 10),
              Text(
                lore,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.35,
                  fontStyle: FontStyle.italic,
                  color: accent,
                ),
              ),
            ],
            if (item.buff.labels.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (final line in item.buff.labels.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    line,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.xp,
                      height: 1.25,
                    ),
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Parçacıkların **sabit** geometrisi.
///
/// Tohumdan bir kez üretilir; her karede rastgele sayı çekmek hem pahalı hem
/// de titrek görünür.
class _ParticleField {
  final List<double> angles;
  final List<double> speeds;
  final List<double> sizes;
  final List<double> delays;

  _ParticleField._(this.angles, this.speeds, this.sizes, this.delays);

  factory _ParticleField({required int count, required int seed}) {
    final random = Random(seed);
    return _ParticleField._(
      [for (var i = 0; i < count; i++) random.nextDouble() * 2 * pi],
      [for (var i = 0; i < count; i++) 0.45 + random.nextDouble() * 0.55],
      [for (var i = 0; i < count; i++) 2.0 + random.nextDouble() * 3.5],
      [for (var i = 0; i < count; i++) random.nextDouble() * 0.25],
    );
  }

  int get length => angles.length;
}

/// Işık patlaması, renk dalgası ve parçacıklar — hepsi tek geçişte.
class _BurstPainter extends CustomPainter {
  final double progress;
  final Color color;
  final _ParticleField particles;
  final bool spectacular;

  const _BurstPainter({
    required this.progress,
    required this.color,
    required this.particles,
    required this.spectacular,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.longestSide * 0.6;

    // 1) Işık patlaması: ilk %35'te hızla açılıp söner.
    final flash = (1 - (progress / 0.35)).clamp(0.0, 1.0);
    if (flash > 0) {
      canvas.drawCircle(
        center,
        maxRadius * 0.5 * (1 - flash),
        Paint()
          ..color = color.withValues(alpha: 0.55 * flash)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
      );
    }

    // 2) Renk dalgası: dışa doğru genişleyen halka.
    final waveRadius = maxRadius * Curves.easeOut.transform(progress);
    final waveAlpha = (1 - progress).clamp(0.0, 1.0);
    canvas.drawCircle(
      center,
      waveRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = spectacular ? 5 : 3
        ..color = color.withValues(alpha: 0.5 * waveAlpha),
    );
    if (spectacular) {
      // İkinci halka biraz geriden gelir; tek halka cılız kalıyor.
      final second =
          maxRadius *
          Curves.easeOut.transform((progress - 0.18).clamp(0.0, 1.0));
      canvas.drawCircle(
        center,
        second,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = color.withValues(alpha: 0.35 * waveAlpha),
      );
    }

    // 3) Parçacıklar.
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < particles.length; i++) {
      final t = ((progress - particles.delays[i]) / (1 - particles.delays[i]))
          .clamp(0.0, 1.0);
      if (t <= 0) continue;
      final distance =
          maxRadius * particles.speeds[i] * Curves.easeOut.transform(t);
      final offset =
          center +
          Offset(cos(particles.angles[i]), sin(particles.angles[i])) * distance;
      paint.color = color.withValues(alpha: (1 - t) * 0.9);
      canvas.drawCircle(offset, particles.sizes[i] * (1 - t * 0.4), paint);
    }
  }

  @override
  bool shouldRepaint(_BurstPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.particles != particles;
}
