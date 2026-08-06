import '../core/constants/game_constants.dart';

/// Bir güne ait adım ve kalori ilerlemesi.
class DailyProgress {
  DateTime date;
  int steps;
  double caloriesBurned;
  final int stepGoal;
  final double calorieGoal;

  DailyProgress({
    required this.date,
    this.steps = 0,
    this.caloriesBurned = 0,
    this.stepGoal = GameConstants.dragonStepGoal,
    this.calorieGoal = GameConstants.dailyCalorieGoal,
  });

  double get stepProgress => (steps / stepGoal).clamp(0, 1);

  double get calorieProgress => (caloriesBurned / calorieGoal).clamp(0, 1);

  bool get calorieGoalReached => caloriesBurned >= calorieGoal;

  bool get isWheelUnlocked => steps >= GameConstants.dailyWheelUnlockSteps;

  /// Basit tahmini dönüşüm: ~20 adım ≈ 1 kalori (demo amaçlı).
  void addSteps(int amount) {
    steps += amount;
    caloriesBurned += amount / 20;
  }
}
