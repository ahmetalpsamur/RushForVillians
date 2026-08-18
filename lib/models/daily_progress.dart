import '../core/constants/game_constants.dart';
import '../core/utils/game_clock.dart';
import '../core/utils/game_day.dart';

/// Bir güne ait adım ilerlemesi.
class DailyProgress {
  DateTime date;
  int steps;
  final int stepGoal;

  /// Bugün **adımlardan** kazanılan para. Günlük tavan buna göre uygulanır.
  /// Gün değişince yeni bir [DailyProgress] kurulduğu için kendiliğinden
  /// sıfırlanır.
  int coinsEarned;

  DailyProgress({
    required this.date,
    this.steps = 0,
    this.stepGoal = GameConstants.dragonStepGoal,
    this.coinsEarned = 0,
  });

  /// Günlük adım-para tavanı doldu mu.
  bool get coinCapReached => coinsEarned >= GameConstants.maxDailyStepCoins;

  double get stepProgress => (steps / stepGoal).clamp(0, 1);

  bool get stepGoalReached => steps >= stepGoal;

  bool get isWheelUnlocked => steps >= GameConstants.dailyWheelUnlockSteps;

  void addSteps(int amount) {
    steps += amount;
  }

  /// Kayıtlı ilerlemenin hâlâ aynı oyun gününe ait olup olmadığını söyler.
  /// Gün sınırı [GameDay] tarafından belirlenir.
  bool isSameDayAs(DateTime other) => GameDay.isSameGameDay(date, other);

  Map<String, Object?> toJson() => {
    'date': date.toIso8601String(),
    'steps': steps,
    'stepGoal': stepGoal,
    'coinsEarned': coinsEarned,
  };

  factory DailyProgress.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'];
    return DailyProgress(
      date:
          (rawDate is String ? DateTime.tryParse(rawDate) : null) ??
          GameClock.now(),
      steps: json['steps'] as int? ?? 0,
      stepGoal: json['stepGoal'] as int? ?? GameConstants.dragonStepGoal,
      coinsEarned: json['coinsEarned'] as int? ?? 0,
    );
  }
}
