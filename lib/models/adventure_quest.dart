import 'enemy.dart';

class AdventureQuest {
  static const int maxPlayerHealth = 100;
  static const int stageStepTarget = 1000;
  static const int briskWalkingStepsPerMinute = 100;
  static const int syncGraceMinutes = 1;
  static const Duration reminderInterval = Duration(minutes: 10);

  final Enemy enemy;
  final int stepGoal;
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
    this.xpAwarded = false,
    this.acknowledgedDamage = 0,
    this.deathAnimationPlayed = false,
    this.playerHealth = maxPlayerHealth,
    this.roundStartingSteps = 0,
    this.enemyAttackSerial = 0,
    this.lastEnemyDamage = 0,
    DateTime? startedAt,
  }) : roundTargetSteps = _targetForRemaining(stepGoal),
       nextEnemyAttackAt = (startedAt ?? DateTime.now()).add(
         roundDurationForSteps(_targetForRemaining(stepGoal)),
       ),
       nextReminderAt = (startedAt ?? DateTime.now()).add(reminderInterval);

  static int _targetForRemaining(int remainingSteps) {
    if (remainingSteps <= 0) return 0;
    return remainingSteps < stageStepTarget ? remainingSteps : stageStepTarget;
  }

  static Duration roundDurationForSteps(int steps) {
    final walkingMinutes = (steps / briskWalkingStepsPerMinute).ceil();
    return Duration(minutes: walkingMinutes + syncGraceMinutes);
  }

  int takePendingDamage(int currentSteps) {
    final totalDamage = currentSteps.clamp(0, stepGoal);
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

  // TODO(combat): Şimdilik düşman canı doğrudan günlük adım hedefine eşit ve
  // her adım 1 hasar veriyor. Can, saldırı ve hasar değerleri ileride ayrı
  // combat istatistikleri olarak modellenmeli.
  int remainingHealth(int currentSteps) =>
      (stepGoal - currentSteps).clamp(0, stepGoal);

  double healthProgress(int currentSteps) =>
      (remainingHealth(currentSteps) / stepGoal).clamp(0, 1);

  bool isDefeated(int currentSteps) => currentSteps >= stepGoal;
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
