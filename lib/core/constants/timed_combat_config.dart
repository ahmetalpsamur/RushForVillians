import 'attack_config.dart';

/// Central tuning for the one-shot encounter unlocked by a walking target.
abstract final class TimedCombatConfig {
  /// Natural-looking deterministic damage variation around the time result.
  static const double variance = 0.08;

  /// A faster-than-expected walk still receives a real, low enemy hit.
  static const double fastestMultiplier = 0.55;

  /// Very late walks can become lethal, while the curve remains gradual.
  static const double maximumTimeMultiplier = 5.5;

  static Duration expectedDurationForSteps(int steps) =>
      AttackConfig.durationForSteps(steps);

  static double difficultyMultiplierForSteps(int steps) {
    if (AttackConfig.supportsStepTarget(steps)) {
      return AttackConfig.forStepTarget(steps).enemyPowerMultiplier;
    }
    final targets = AttackConfig.targets;
    if (steps <= targets.first.stepTarget) {
      return targets.first.enemyPowerMultiplier;
    }
    for (var index = 1; index < targets.length; index++) {
      final upper = targets[index];
      final lower = targets[index - 1];
      if (steps <= upper.stepTarget) {
        final position =
            (steps - lower.stepTarget) /
            (upper.stepTarget - lower.stepTarget);
        return lower.enemyPowerMultiplier +
            (upper.enemyPowerMultiplier - lower.enemyPowerMultiplier) *
                position;
      }
    }
    return targets.last.enemyPowerMultiplier;
  }

  /// Piecewise-linear curve with no sudden boundary jumps.
  static double timeMultiplier(double completionRatio) {
    final ratio = completionRatio.isFinite
        ? completionRatio.clamp(0.0, 3.0)
        : 3.0;
    if (ratio <= 1) {
      return fastestMultiplier + (1 - fastestMultiplier) * ratio;
    }
    if (ratio <= 1.25) return _lerp(1, 1.20, (ratio - 1) / 0.25);
    if (ratio <= 1.50) return _lerp(1.20, 1.55, (ratio - 1.25) / 0.25);
    if (ratio <= 2) return _lerp(1.55, 2.30, (ratio - 1.50) / 0.50);
    return _lerp(2.30, maximumTimeMultiplier, ratio - 2);
  }

  static double _lerp(double start, double end, double position) =>
      start + (end - start) * position.clamp(0.0, 1.0);
}
