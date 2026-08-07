import '../core/constants/game_constants.dart';

/// Bir güne ait adım ilerlemesi.
class DailyProgress {
  DateTime date;
  int steps;
  final int stepGoal;

  DailyProgress({
    required this.date,
    this.steps = 0,
    this.stepGoal = GameConstants.dragonStepGoal,
  });

  double get stepProgress => (steps / stepGoal).clamp(0, 1);

  bool get stepGoalReached => steps >= stepGoal;

  bool get isWheelUnlocked => steps >= GameConstants.dailyWheelUnlockSteps;

  void addSteps(int amount) {
    steps += amount;
  }
}
