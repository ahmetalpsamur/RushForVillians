import '../core/constants/game_constants.dart';
import '../core/utils/game_clock.dart';
import '../core/utils/game_day.dart';

/// Bir güne ait adım ilerlemesi.
class DailyProgress {
  DateTime date;
  int steps;
  final int stepGoal;

  /// Bugün **adımlardan** kazanılan para. Yalnızca gösterim/geçmiş için
  /// tutulur; günlük kazanç tavanı yoktur.
  /// Gün değişince yeni bir [DailyProgress] kurulduğu için kendiliğinden
  /// sıfırlanır.
  int coinsEarned;

  /// Bugün **adımlardan** kazanılan XP. Yalnızca gösterim için; XP'nin günlük
  /// tavanı yok (bkz. [GameConstants.stepsPerXp]). Düşman ve çark XP'si buraya
  /// yazılmaz — bu satır "yürüyerek ne kazandım" sorusunu cevaplar.
  int xpEarned;

  /// Bugün en az bir düşman devrildi mi (Bölüm A.6).
  ///
  /// Seri ve çark kilidi artık **yalnızca** adım eşiğine bakmıyor: bir düşman
  /// devirmek de ikisini açıyor. Gün değişince yeni bir [DailyProgress]
  /// kurulduğu için kendiliğinden sıfırlanır.
  bool enemyDefeated;

  DailyProgress({
    required this.date,
    this.steps = 0,
    this.stepGoal = GameConstants.dragonStepGoal,
    this.coinsEarned = 0,
    this.xpEarned = 0,
    this.enemyDefeated = false,
  });

  /// Eski UI çağrı noktaları için korunur. Günlük kazanç tavanı
  /// kaldırıldığından artık hiçbir zaman dolmaz.
  bool get coinCapReached => false;

  double get stepProgress => (steps / stepGoal).clamp(0, 1);

  bool get stepGoalReached => steps >= stepGoal;

  /// Çark bugün açık mı (Bölüm A.6).
  ///
  /// İki kapıdan **hangisi önce gelirse**: adım eşiği ya da bir zafer.
  /// Adım eşiği bilerek kaldırılmadı — macera oynamayan ama gerçekten yürüyen
  /// oyuncu cezalanmamalı, ve `streakRelief` gibi eşiğe bağlı item etkileri
  /// anlamını korumalı.
  bool get isWheelUnlocked =>
      enemyDefeated || steps >= GameConstants.dailyWheelUnlockSteps;

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
    'xpEarned': xpEarned,
    'enemyDefeated': enemyDefeated,
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
      xpEarned: json['xpEarned'] as int? ?? 0,
      enemyDefeated: json['enemyDefeated'] as bool? ?? false,
    );
  }
}
