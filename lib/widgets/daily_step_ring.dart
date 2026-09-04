import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/localization/app_formatters.dart';
import '../core/theme/app_theme.dart';
import '../l10n/l10n_context.dart';
import '../models/daily_step_record.dart';

class DailyStepRing extends StatelessWidget {
  final DailyStepRecord record;
  final double size;
  final String centerLabel;
  final VoidCallback? onTap;

  const DailyStepRing({
    super.key,
    required this.record,
    required this.size,
    required this.centerLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ring = SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _DailyStepRingPainter(progress: record.progress),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerLabel,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (size >= 70)
                Text(
                  AppFormatters.integer(context, record.steps),
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: size * 0.12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return ring;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: ring,
      ),
    );
  }
}

class _DailyStepRingPainter extends CustomPainter {
  final double progress;

  const _DailyStepRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final stroke = size.shortestSide * 0.09;
    final radius = size.shortestSide / 2 - stroke;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final value = progress.clamp(0.0, 1.0);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.17)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (value <= 0) return;

    final sweep = math.pi * 2 * value;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 1.5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );

    final angle = -math.pi / 2 + sweep;
    final endpoint = center + Offset(math.cos(angle), math.sin(angle)) * radius;
    canvas.drawCircle(
      endpoint,
      stroke * 0.58,
      Paint()..color = const Color(0xFFB4A6FF),
    );
  }

  @override
  bool shouldRepaint(covariant _DailyStepRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

Future<void> showDailyStepDetails(
  BuildContext context,
  DailyStepRecord record,
) {
  final completedLaps =
      record.stepGoal <= 0 ? 0 : record.steps ~/ record.stepGoal;
  return showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppFormatters.longDate(context, record.date),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 20),
              DailyStepRing(
                record: record,
                size: 210,
                centerLabel: context.l10n.stepsRingLabel,
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.stepsTaken(record.steps),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${context.l10n.dailyGoalSteps(record.stepGoal)}'
                '${completedLaps > 0 ? ' • ${context.l10n.completedRounds(completedLaps)}' : ''}',
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.l10n.commonClose),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
