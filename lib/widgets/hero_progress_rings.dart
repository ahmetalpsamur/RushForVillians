import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/adventure_quest.dart';
import '../models/daily_progress.dart';
import '../models/user_profile.dart';
import 'avatar_view.dart';
import 'stat_bar.dart';

class HeroProgressRings extends StatelessWidget {
  final UserProfile profile;
  final DailyProgress today;

  /// Savaş canının gerçek kaynağı. Macera yokken can çubuğu gösterilmez;
  /// [UserProfile.hp] hiç azalmadığı için "can" diye gösterilmesi yanlıştı.
  final AdventureQuest? adventure;

  const HeroProgressRings({
    super.key,
    required this.profile,
    required this.today,
    this.adventure,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final size = math.min(constraints.maxWidth, 285.0);
            final totalProgress = today.steps / today.stepGoal;
            final completedLaps = totalProgress.floor();
            final remainder = totalProgress - completedLaps;
            final ringProgress = totalProgress.clamp(0.0, 1.0);
            final arrowProgress =
                today.steps > 0 && remainder == 0 ? 1.0 : remainder;
            return SizedBox.square(
              dimension: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _StepRingPainter(
                        progress: ringProgress,
                        arrowProgress: arrowProgress,
                      ),
                    ),
                  ),
                  Container(
                    width: size * 0.68,
                    height: size * 0.68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF171521),
                      border: Border.all(color: Colors.white12, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, blurRadius: 24),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: AvatarView(
                      avatar: profile.avatar,
                      size: size * 0.68,
                      showBackground: false,
                      combatLoop: true,
                    ),
                  ),
                  if (completedLaps > 0)
                    Positioned(
                      top: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF171521),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.55),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Text(
                          '$completedLaps TUR',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF171521),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.directions_walk,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${today.steps} / ${today.stepGoal} adım',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          profile.avatar.characterClassLabel,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 18),
        if (adventure != null) ...[
          StatBar(
            label: 'Savaş Canı',
            icon: Icons.favorite,
            color: AppColors.hp,
            progress: adventure!.playerHealthProgress,
            valueText:
                '${adventure!.playerHealth} / '
                '${adventure!.playerMaxHealth}',
          ),
          const SizedBox(height: 14),
        ],
        StatBar(
          label: 'Seviye ${profile.level}',
          icon: Icons.bolt,
          color: AppColors.xp,
          progress: profile.xpProgress,
          valueText: '${profile.xp} / ${profile.xpToNextLevel} XP',
        ),
      ],
    );
  }
}

class _StepRingPainter extends CustomPainter {
  final double progress;
  final double arrowProgress;

  const _StepRingPainter({required this.progress, required this.arrowProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final strokeWidth = math.min(size.width, size.height) * 0.055;
    final radius = math.min(size.width, size.height) / 2 - strokeWidth * 1.25;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final value = progress.clamp(0.0, 1.0);
    final backgroundPaint =
        Paint()
          ..color = AppColors.primary.withValues(alpha: 0.14)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;
    final glowPaint =
        Paint()
          ..color = AppColors.primary.withValues(alpha: 0.34)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 1.5
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    final progressPaint =
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);
    if (value > 0) {
      final sweep = math.pi * 2 * value;
      canvas.drawArc(rect, -math.pi / 2, sweep, false, glowPaint);
      canvas.drawArc(rect, -math.pi / 2, sweep, false, progressPaint);
      _drawFitnessArrow(
        canvas,
        center: center,
        radius: radius,
        angle: -math.pi / 2 + math.pi * 2 * arrowProgress,
        strokeWidth: strokeWidth,
      );
    }
  }

  void _drawFitnessArrow(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double angle,
    required double strokeWidth,
  }) {
    final radial = Offset(math.cos(angle), math.sin(angle));
    final tangent = Offset(-math.sin(angle), math.cos(angle));
    final endpoint = center + radial * radius;
    final capRadius = strokeWidth * 0.86;

    canvas.drawCircle(
      endpoint,
      capRadius * 1.15,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(
      endpoint + const Offset(2.5, 3.5),
      capRadius,
      Paint()..color = Colors.black.withValues(alpha: 0.58),
    );
    canvas.drawCircle(endpoint, capRadius, Paint()..color = AppColors.primary);
    canvas.drawCircle(
      endpoint - radial * (capRadius * 0.22),
      capRadius * 0.7,
      Paint()
        ..color = const Color(0xFF9C87FF).withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    final chevronCenter = endpoint + tangent * (capRadius * 0.1);
    final back = chevronCenter - tangent * (capRadius * 0.38);
    final tip = chevronCenter + tangent * (capRadius * 0.48);
    final wing = radial * (capRadius * 0.38);
    final chevron =
        Path()
          ..moveTo((back + wing).dx, (back + wing).dy)
          ..lineTo(tip.dx, tip.dy)
          ..lineTo((back - wing).dx, (back - wing).dy);
    canvas.drawPath(
      chevron,
      Paint()
        ..color = const Color(0xFFEAE5FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 0.18
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _StepRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.arrowProgress != arrowProgress;
}
