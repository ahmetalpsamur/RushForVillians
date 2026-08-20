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

  /// Bugün **adımlardan** kazanılan XP. Yalnızca gösterim için; XP'nin günlük
  /// tavanı yok (bkz. [GameConstants.stepsPerXp]). Düşman ve çark XP'si buraya
  /// yazılmaz — bu satır "yürüyerek ne kazandım" sorusunu cevaplar.
  int xpEarned;

  DailyProgress({
    required this.date,
    this.steps = 0,
    this.stepGoal = GameConstants.dragonStepGoal,
    this.coinsEarned = 0,
    this.xpEarned = 0,
  });

  /// Günlük adım-para tavanı doldu mu.
  ///
  /// [cap] verilmezse taban tavan ([GameConstants.maxDailyStepCoins])
  /// kullanılır. Kuşanılan ekipman tavanı büyütebildiği için
  /// ([EquippedBuffs.dailyCoinCap]) çağıranların oyuncunun **gerçek**
  /// tavanını vermesi gerekir; aksi halde tavan dolmadan "doldu" denir.
  bool coinCapReachedAt([int? cap]) =>
      coinsEarned >= (cap ?? GameConstants.maxDailyStepCoins);

  /// Taban tavana göre doluluk. Ekipman bonusunu **hesaba katmaz**;
  /// buff'ı olan çağıranlar [coinCapReachedAt] kullanmalı.
  bool get coinCapReached => coinCapReachedAt();

  /// Bu günün ilerlemesini koruyarak yalnızca [stepGoal]'ü değiştiren kopya.
  ///
  /// [stepGoal] `final` olduğu için hedef değişimi yeni bir nesne gerektiriyor.
  /// Bunu elle kurmak, gün içinde kazanılan para ve XP sayaçlarını sıfırlama
  /// riskini taşıyor — macera seçmek günlük coin tavanını sıfırlıyordu.
  DailyProgress withStepGoal(int stepGoal) => DailyProgress(
    date: date,
    steps: steps,
    stepGoal: stepGoal,
    coinsEarned: coinsEarned,
    xpEarned: xpEarned,
  );

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
    'xpEarned': xpEarned,
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
    );
  }
}
