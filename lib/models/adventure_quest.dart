import '../core/utils/game_clock.dart';
import 'enemy.dart';

class AdventureQuest {
  static const String defaultBackgroundAsset =
      'lib/Backgrounds/versionA_platform.png';
  static const int maxPlayerHealth = 100;
  static const int stageStepTarget = 1000;
  // Geçici test dengesi: her round 30 saniye.
  static const Duration roundDuration = Duration(seconds: 30);
  static const Duration reminderInterval = Duration(minutes: 5);

  /// Tek seferde çözülecek en fazla birikmiş tur. Güvenlik ağı: çok eski bir
  /// kayıttan dönüldüğünde döngü arayüzü kilitlemesin.
  static const int maxCatchUpRounds = 500;

  final Enemy enemy;
  final int stepGoal;
  final String backgroundAsset;

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
  int currentRound;
  int lastResolvedRound;
  int roundOutcomeSerial;
  int presentedRoundOutcomeSerial;
  bool lastRoundWon;

  AdventureQuest({
    required this.enemy,
    required this.stepGoal,
    this.backgroundAsset = defaultBackgroundAsset,
    this.startingSteps = 0,
    this.xpAwarded = false,
    this.acknowledgedDamage = 0,
    this.deathAnimationPlayed = false,
    this.playerHealth = maxPlayerHealth,
    int? roundStartingSteps,
    this.enemyAttackSerial = 0,
    this.lastEnemyDamage = 0,
    this.currentRound = 1,
    this.lastResolvedRound = 0,
    this.roundOutcomeSerial = 0,
    this.presentedRoundOutcomeSerial = 0,
    this.lastRoundWon = false,
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
    return steps <= 0 ? Duration.zero : roundDuration;
  }

  int get totalRounds => (stepGoal / stageStepTarget).ceil();

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

  static String durationLabel(Duration duration) {
    if (duration.inSeconds < 60) return '${duration.inSeconds} saniye';
    return '${duration.inMinutes} dakika';
  }

  static String get configuredRoundDurationLabel =>
      durationLabel(roundDuration);

  String get roundDurationLabel =>
      durationLabel(roundDurationForSteps(roundTargetSteps));

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

  /// Round, hedef erken tamamlanırsa anında; tamamlanmazsa tanımlı süre
  /// dolduğunda çözülür.
  CombatRoundResult? resolveRound(int currentSteps, DateTime now) {
    if (roundTargetSteps <= 0 || playerHealth <= 0) {
      return null;
    }

    final targetReached = stepsThisRound(currentSteps) >= roundTargetSteps;
    final expired = !now.isBefore(nextEnemyAttackAt);
    if (!targetReached && !expired) return null;

    final expiredAt = nextEnemyAttackAt;
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

    final resolvedRound = currentRound;
    lastResolvedRound = resolvedRound;
    lastRoundWon = targetReached;
    roundOutcomeSerial += 1;
    currentRound += 1;

    roundStartingSteps += walked;
    roundTargetSteps = _targetForRemaining(remainingHealth(currentSteps));
    // Erken biten roundun yeni süresi başarı anından başlar. Arka planda süresi
    // geçmiş roundlar ise eski zaman çizgisinde ilerler ve bedavaya silinmez.
    final nextRoundStartsAt = expired ? expiredAt : now;
    nextEnemyAttackAt = nextRoundStartsAt.add(
      roundDurationForSteps(roundTargetSteps),
    );
    nextReminderAt = nextRoundStartsAt.add(reminderInterval);

    return CombatRoundResult(
      roundNumber: resolvedRound,
      walkedSteps: walked,
      targetSteps: walked + missedSteps,
      playerDamage: damage,
    );
  }

  /// Eski çağrı noktaları ve kayıt uyumluluğu için adını koruyan yönlendirme.
  CombatRoundResult? resolveExpiredRound(int currentSteps, DateTime now) =>
      resolveRound(currentSteps, now);

  /// Süresi dolmuş **tüm** turları sırayla çözer ve toplamlarını döner.
  ///
  /// Uygulama arka planda kaldığında birden fazla tur birikir; tek tur çözmek
  /// kalanları sessizce affediyordu (triaj A1). Dolmuş tur yoksa `null`.
  ///
  /// [maxCatchUpRounds] yalnızca güvenlik ağıdır: can sıfırlanınca ya da
  /// düşman yenilince döngü zaten durur.
  CombatRoundResult? resolveExpiredRounds(int currentSteps, DateTime now) {
    var walked = 0;
    var target = 0;
    var damage = 0;
    var rounds = 0;
    var lastRoundNumber = currentRound;

    while (rounds < maxCatchUpRounds) {
      final result = resolveExpiredRound(currentSteps, now);
      if (result == null) break;
      walked += result.walkedSteps;
      target += result.targetSteps;
      damage += result.playerDamage;
      lastRoundNumber = result.roundNumber;
      rounds++;
    }

    if (rounds == 0) return null;
    return CombatRoundResult(
      roundNumber: lastRoundNumber,
      walkedSteps: walked,
      targetSteps: target,
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
    'backgroundAsset': backgroundAsset,
    'startingSteps': startingSteps,
    'xpAwarded': xpAwarded,
    'acknowledgedDamage': acknowledgedDamage,
    'deathAnimationPlayed': deathAnimationPlayed,
    'playerHealth': playerHealth,
    'roundStartingSteps': roundStartingSteps,
    'roundTargetSteps': roundTargetSteps,
    'nextEnemyAttackAt': nextEnemyAttackAt.toIso8601String(),
    'roundDurationSeconds': roundDuration.inSeconds,
    'nextReminderAt': nextReminderAt.toIso8601String(),
    'enemyAttackSerial': enemyAttackSerial,
    'lastEnemyDamage': lastEnemyDamage,
    'currentRound': currentRound,
    'lastResolvedRound': lastResolvedRound,
    'roundOutcomeSerial': roundOutcomeSerial,
    'presentedRoundOutcomeSerial': presentedRoundOutcomeSerial,
    'lastRoundWon': lastRoundWon,
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
      backgroundAsset:
          json['backgroundAsset'] as String? ?? defaultBackgroundAsset,
      startingSteps: json['startingSteps'] as int? ?? 0,
      xpAwarded: json['xpAwarded'] as bool? ?? false,
      acknowledgedDamage: json['acknowledgedDamage'] as int? ?? 0,
      deathAnimationPlayed: json['deathAnimationPlayed'] as bool? ?? false,
      playerHealth: json['playerHealth'] as int? ?? maxPlayerHealth,
      roundStartingSteps: json['roundStartingSteps'] as int?,
      enemyAttackSerial: json['enemyAttackSerial'] as int? ?? 0,
      lastEnemyDamage: json['lastEnemyDamage'] as int? ?? 0,
      currentRound: json['currentRound'] as int? ?? 1,
      lastResolvedRound: json['lastResolvedRound'] as int? ?? 0,
      roundOutcomeSerial: json['roundOutcomeSerial'] as int? ?? 0,
      presentedRoundOutcomeSerial:
          json['presentedRoundOutcomeSerial'] as int? ?? 0,
      lastRoundWon: json['lastRoundWon'] as bool? ?? false,
    );
    final savedRoundTarget = json['roundTargetSteps'] as int?;
    if (savedRoundTarget != null) quest.roundTargetSteps = savedRoundTarget;
    final savedAttackAt = _parseDate(json['nextEnemyAttackAt']);
    final savedRoundDurationSeconds = json['roundDurationSeconds'] as int?;
    // Test/denge sırasında round süresi değişmişse eski uzun geri sayımı
    // taşımak yerine kurucunun güncel süreyle oluşturduğu sayacı kullan.
    if (savedAttackAt != null &&
        savedRoundDurationSeconds == roundDuration.inSeconds) {
      quest.nextEnemyAttackAt = savedAttackAt;
    }
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
  final int roundNumber;
  final int walkedSteps;
  final int targetSteps;
  final int playerDamage;

  const CombatRoundResult({
    required this.roundNumber,
    required this.walkedSteps,
    required this.targetSteps,
    required this.playerDamage,
  });

  bool get targetReached => walkedSteps >= targetSteps;
}
