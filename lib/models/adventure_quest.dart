import '../core/utils/game_clock.dart';
import 'enemy.dart';

class AdventureQuest {
  static const int maxPlayerHealth = 100;
  static const int stageStepTarget = 1000;
  static const int briskWalkingStepsPerMinute = 100;
  static const int syncGraceMinutes = 1;
  static const Duration reminderInterval = Duration(minutes: 10);

  final Enemy enemy;
  final int stepGoal;

  /// Macera başladığı anda günlük adım sayacının değeri.
  ///
  /// Macera ilerlemesi bu değerin üstünden hesaplanır ([questSteps]); böylece
  /// macera başlatmak için günün adımlarını sıfırlamak gerekmez.
  final int startingSteps;

  bool xpAwarded;
  int acknowledgedDamage;
  bool deathAnimationPlayed;
  int playerHealth;
  int roundStartingSteps;
  int roundTargetSteps;
  DateTime nextEnemyAttackAt;
  DateTime nextReminderAt;
  int enemyAttackSerial;
  int lastEnemyDamage;

  AdventureQuest({
    required this.enemy,
    required this.stepGoal,
    this.startingSteps = 0,
    this.xpAwarded = false,
    this.acknowledgedDamage = 0,
    this.deathAnimationPlayed = false,
    this.playerHealth = maxPlayerHealth,
    int? roundStartingSteps,
    this.enemyAttackSerial = 0,
    this.lastEnemyDamage = 0,
    DateTime? startedAt,
  }) : roundStartingSteps = roundStartingSteps ?? startingSteps,
       roundTargetSteps = _targetForRemaining(stepGoal),
       nextEnemyAttackAt = (startedAt ?? GameClock.now()).add(
         roundDurationForSteps(_targetForRemaining(stepGoal)),
       ),
       nextReminderAt = (startedAt ?? GameClock.now()).add(reminderInterval);

  static int _targetForRemaining(int remainingSteps) {
    if (remainingSteps <= 0) return 0;
    return remainingSteps < stageStepTarget ? remainingSteps : stageStepTarget;
  }

  static Duration roundDurationForSteps(int steps) {
    final walkingMinutes = (steps / briskWalkingStepsPerMinute).ceil();
    return Duration(minutes: walkingMinutes + syncGraceMinutes);
  }

  /// Macera başladığından beri atılan adım — düşmana verilen toplam hasar.
  /// Günlük sayaç sıfırlanmadığı için [startingSteps] farkı alınır.
  int questSteps(int currentSteps) =>
      (currentSteps - startingSteps).clamp(0, stepGoal);

  int takePendingDamage(int currentSteps) {
    final totalDamage = questSteps(currentSteps);
    final pendingDamage = (totalDamage - acknowledgedDamage).clamp(0, stepGoal);
    acknowledgedDamage = totalDamage;
    return pendingDamage;
  }

  int get roundDurationMinutes =>
      roundDurationForSteps(roundTargetSteps).inMinutes;

  int stepsThisRound(int currentSteps) =>
      (currentSteps - roundStartingSteps).clamp(0, roundTargetSteps);

  int roundStepsRemaining(int currentSteps) =>
      (roundTargetSteps - stepsThisRound(currentSteps)).clamp(
        0,
        roundTargetSteps,
      );

  Duration countdownRemaining(DateTime now) {
    final remaining = nextEnemyAttackAt.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  CombatRoundResult? resolveExpiredRound(int currentSteps, DateTime now) {
    if (isDefeated(currentSteps) ||
        playerHealth <= 0 ||
        now.isBefore(nextEnemyAttackAt)) {
      return null;
    }

    final walked = stepsThisRound(currentSteps);
    final missedSteps = (roundTargetSteps - walked).clamp(0, roundTargetSteps);
    final damage =
        missedSteps == 0
            ? 0
            : (enemy.attackDamage * missedSteps / roundTargetSteps).ceil();

    if (damage > 0) {
      playerHealth = (playerHealth - damage).clamp(0, maxPlayerHealth);
      lastEnemyDamage = damage;
      enemyAttackSerial += 1;
    } else {
      lastEnemyDamage = 0;
    }

    roundStartingSteps = currentSteps;
    roundTargetSteps = _targetForRemaining(remainingHealth(currentSteps));
    nextEnemyAttackAt = now.add(roundDurationForSteps(roundTargetSteps));

    return CombatRoundResult(
      walkedSteps: walked,
      targetSteps: walked + missedSteps,
      playerDamage: damage,
    );
  }

  bool takeDueReminder(DateTime now) {
    if (now.isBefore(nextReminderAt)) return false;
    nextReminderAt = now.add(reminderInterval);
    return true;
  }

  /// Düşman sabit katalogdan geldiği için yalnızca kimliği yazılır.
  Map<String, Object?> toJson() => {
    'enemyId': enemy.id,
    'stepGoal': stepGoal,
    'startingSteps': startingSteps,
    'xpAwarded': xpAwarded,
    'acknowledgedDamage': acknowledgedDamage,
    'deathAnimationPlayed': deathAnimationPlayed,
    'playerHealth': playerHealth,
    'roundStartingSteps': roundStartingSteps,
    'roundTargetSteps': roundTargetSteps,
    'nextEnemyAttackAt': nextEnemyAttackAt.toIso8601String(),
    'nextReminderAt': nextReminderAt.toIso8601String(),
    'enemyAttackSerial': enemyAttackSerial,
    'lastEnemyDamage': lastEnemyDamage,
  };

  /// Kayıttan geri yükler. Tur hedefi ve geri sayım kurucuda hesaplandığı
  /// için, kayıtlı değerler varsa üzerine yazılır; böylece uygulama kapanıp
  /// açıldığında geri sayım bedava sıfırlanmaz.
  factory AdventureQuest.fromJson(
    Map<String, dynamic> json, {
    required Enemy enemy,
  }) {
    final quest = AdventureQuest(
      enemy: enemy,
      stepGoal: json['stepGoal'] as int? ?? enemy.minimumDailySteps,
      startingSteps: json['startingSteps'] as int? ?? 0,
      xpAwarded: json['xpAwarded'] as bool? ?? false,
      acknowledgedDamage: json['acknowledgedDamage'] as int? ?? 0,
      deathAnimationPlayed: json['deathAnimationPlayed'] as bool? ?? false,
      playerHealth: json['playerHealth'] as int? ?? maxPlayerHealth,
      roundStartingSteps: json['roundStartingSteps'] as int?,
      enemyAttackSerial: json['enemyAttackSerial'] as int? ?? 0,
      lastEnemyDamage: json['lastEnemyDamage'] as int? ?? 0,
    );
    final savedRoundTarget = json['roundTargetSteps'] as int?;
    if (savedRoundTarget != null) quest.roundTargetSteps = savedRoundTarget;
    final savedAttackAt = _parseDate(json['nextEnemyAttackAt']);
    if (savedAttackAt != null) quest.nextEnemyAttackAt = savedAttackAt;
    final savedReminderAt = _parseDate(json['nextReminderAt']);
    if (savedReminderAt != null) quest.nextReminderAt = savedReminderAt;
    return quest;
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }

  // TODO(combat): Şimdilik düşman canı doğrudan günlük adım hedefine eşit ve
  // her adım 1 hasar veriyor. Can, saldırı ve hasar değerleri ileride ayrı
  // combat istatistikleri olarak modellenmeli.
  int remainingHealth(int currentSteps) =>
      (stepGoal - questSteps(currentSteps)).clamp(0, stepGoal);

  double healthProgress(int currentSteps) =>
      (remainingHealth(currentSteps) / stepGoal).clamp(0, 1);

  bool isDefeated(int currentSteps) => questSteps(currentSteps) >= stepGoal;
}

class CombatRoundResult {
  final int walkedSteps;
  final int targetSteps;
  final int playerDamage;

  const CombatRoundResult({
    required this.walkedSteps,
    required this.targetSteps,
    required this.playerDamage,
  });

  bool get targetReached => walkedSteps >= targetSteps;
}
