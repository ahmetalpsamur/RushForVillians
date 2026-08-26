import '../core/constants/attack_config.dart';
import '../core/utils/base_combat_stats.dart';
import '../core/utils/combat_engine.dart';
import '../core/utils/enemy_stats.dart';
import '../core/utils/item_rules.dart';
import '../core/utils/game_clock.dart';
import 'combat_stats.dart';
import 'enemy.dart';
import 'item_effect.dart';

/// Saldırının ödül ve ekran akışını yöneten otoriter terminal sonucu.
///
/// Savaşın ödül ve ekran akışını yöneten otoriter terminal sonucu.
enum AdventureBattleOutcome { active, victory, defeat }

class AdventureQuest {
  static const String defaultBackgroundAsset =
      'lib/Backgrounds/versionA_platform.png';
  static const int maxPlayerHealth = 100;

  /// Her roundun üst adım sınırı.
  static const int stageStepTarget = 1000;
  static const Duration roundDuration = Duration(minutes: 15);
  static const int revivalStepTarget = 500;
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
  int victoryXpReward;
  int victoryCoinReward;
  int acknowledgedDamage;
  bool deathAnimationPlayed;
  int playerHealth;

  /// Oyuncunun savaş canı tavanı.
  ///
  /// Artık sabit değil: seviyeden ve kuşanmadan geliyor
  /// ([effectiveCombatStats]). Macera nesnesinde tutuluyor ki ekran tek bir
  /// yerden okusun; `RootShell` statlar değiştikçe (seviye atlama, kuşanma)
  /// güncelliyor.
  int playerMaxHealth;

  /// Düşmanın kalan savaş canı.
  ///
  /// **Artık adımdan bağımsız** (triaj A2/A3). Eskiden `stepGoal - atılanAdım`
  /// idi; can, saldırı ve savunma ayrı statlar olunca bu bağ koptu. `stepGoal`
  /// bugün yalnızca yürüyüş taahhüdü: round hedefini ve beklenen round
  /// sayısını belirliyor.
  int enemyHealth;

  /// Savaş rastgeleliğinin tohumu. `0` = henüz kurulmadı.
  ///
  /// Motor `Random()` kullanmıyor; tohum durumla birlikte diske yazılıyor,
  /// yani kapat-aç zar attırmaz ve aynı motor sunucuda aynı sonucu üretir
  /// (CLAUDE.md §4.4).
  int combatSeed;

  /// Arka arkaya hiç hasar alınmamış round sayısı.
  /// `untouchedRounds` tetikleyicili item etkilerinin dayanağı.
  int untouchedRounds;

  int roundStartingSteps;
  int roundTargetSteps;
  DateTime nextEnemyAttackAt;
  DateTime nextReminderAt;
  int enemyAttackSerial;
  int lastEnemyDamage;

  /// Son roundda **düşmana** verilen hasar. Sahnedeki "canını aldın"
  /// mesajı bunu gösteriyor.
  int lastPlayerDamage;
  int currentRound;
  int lastResolvedRound;
  int roundOutcomeSerial;
  int presentedRoundOutcomeSerial;
  bool lastRoundWon;
  AdventureBattleOutcome battleOutcome;

  /// Yeni sistemden eski round düzenine dönen kayıtlarla uyumluluk alanı.
  bool enemyDefeatPending;

  /// Yeni sistemden eski round düzenine dönen kayıtlarla uyumluluk alanı.
  bool playerDefeatPending;

  /// Otoriter yenilgiden sonra açılabilen 500 adımlık Hayat Yürüyüşü durumu.
  ///
  /// Bu, saldırının beş rounduna ek bir combat fazı değildir. Savaş terminal
  /// durumdayken ilerleyen ayrı bir yeniden doğuş gereksinimidir.
  bool revivalStarted;
  int revivalSteps;

  AdventureQuest({
    required this.enemy,
    required this.stepGoal,
    this.backgroundAsset = defaultBackgroundAsset,
    this.startingSteps = 0,
    this.xpAwarded = false,
    this.victoryXpReward = 0,
    this.victoryCoinReward = 0,
    this.acknowledgedDamage = 0,
    this.deathAnimationPlayed = false,
    this.playerHealth = maxPlayerHealth,
    this.playerMaxHealth = maxPlayerHealth,
    int? enemyHealth,
    this.combatSeed = 0,
    this.untouchedRounds = 0,
    int? roundStartingSteps,
    this.enemyAttackSerial = 0,
    this.lastEnemyDamage = 0,
    this.lastPlayerDamage = 0,
    int currentRound = 1,
    this.lastResolvedRound = 0,
    this.roundOutcomeSerial = 0,
    this.presentedRoundOutcomeSerial = 0,
    this.lastRoundWon = false,
    this.battleOutcome = AdventureBattleOutcome.active,
    this.enemyDefeatPending = false,
    this.playerDefeatPending = false,
    this.revivalStarted = false,
    int revivalSteps = 0,
    DateTime? startedAt,
  }) : roundStartingSteps = roundStartingSteps ?? startingSteps,
       currentRound = currentRound < 1 ? 1 : currentRound,
       enemyHealth = enemyHealth ?? _scaledEnemyMaxHealth(enemy, stepGoal),
       revivalSteps = revivalSteps.clamp(0, revivalStepTarget),
       roundTargetSteps = _targetForRemaining(stepGoal),
       nextEnemyAttackAt = (startedAt ?? GameClock.now()).add(
         roundDurationForSteps(_targetForRemaining(stepGoal)),
       ),
       nextReminderAt = (startedAt ?? GameClock.now()).add(reminderInterval) {
    if (battleOutcome != AdventureBattleOutcome.active) {
      roundTargetSteps = 0;
      enemyDefeatPending = false;
      playerDefeatPending = false;
      if (battleOutcome == AdventureBattleOutcome.victory) {
        this.enemyHealth = 0;
        revivalStarted = false;
        this.revivalSteps = 0;
      } else {
        playerHealth = 0;
      }
    }
  }

  static AttackTargetConfig _attackConfig(int stepGoal) =>
      AttackConfig.forStepTarget(stepGoal);

  static int _roundIndex(int currentRound) =>
      currentRound.clamp(1, AttackConfig.roundCount) - 1;

  static int _targetForRemaining(int remainingSteps) {
    if (remainingSteps <= 0) return 0;
    return remainingSteps < stageStepTarget ? remainingSteps : stageStepTarget;
  }

  static Duration roundDurationForSteps(int steps) =>
      steps <= 0 ? Duration.zero : roundDuration;

  /// İlk eğitim savaşını guide tamamlar. Gerçek adım sayacına dokunmaz; yalnızca
  /// bu maceranın otoriter savaş sonucunu zafere taşır.
  void completeTutorialVictory(DateTime now) {
    if (battleOutcome != AdventureBattleOutcome.active) return;
    lastResolvedRound = currentRound;
    lastPlayerDamage = enemyHealth;
    lastEnemyDamage = 0;
    lastRoundWon = true;
    roundOutcomeSerial += 1;
    enemyHealth = 0;
    battleOutcome = AdventureBattleOutcome.victory;
    enemyDefeatPending = false;
    playerDefeatPending = false;
    roundTargetSteps = 0;
    nextEnemyAttackAt = now;
    nextReminderAt = now;
  }

  static int _scaledEnemyMaxHealth(Enemy enemy, int stepGoal) =>
      enemy.maxHealth;

  AttackTargetConfig get attackConfig => _attackConfig(stepGoal);

  AttackRoundConfig get currentRoundConfig =>
      AttackConfig.rounds[_roundIndex(currentRound)];

  AttackPhase get currentPhase => currentRoundConfig.phase;

  Duration get totalAttackDuration => roundDuration * totalRounds;

  Duration get currentRoundDuration => roundDurationForSteps(roundTargetSteps);

  double get enemyPowerMultiplier => 1;

  /// Her okumada katalog tabanından türetilir; ölçeklenmiş stat tekrar
  /// ölçeklenmediği için round sayısı çarpanı katlayamaz.
  CombatStats get scaledEnemyStats =>
      scaleEnemyCombatStats(enemy.stats, enemyPowerMultiplier);

  int get scaledEnemyMaxHealth => scaledEnemyStats.maxHealth.round();

  int get totalRounds => (stepGoal / stageStepTarget).ceil();

  /// Macera başladığından beri atılan adım — düşmana verilen toplam hasar.
  /// Günlük sayaç sıfırlanmadığı için [startingSteps] farkı alınır.
  int questSteps(int currentSteps) =>
      (currentSteps - startingSteps).clamp(0, stepGoal);

  /// Ekranın henüz göstermediği **düşmana verilen** hasar; gösterildikten
  /// sonra ikinci kez dönmez.
  ///
  /// Savaş motorundan önce bu sayı doğrudan atılan adımdı (her adım 1 hasar).
  /// Artık hasar statlardan hesaplanıyor ve yalnızca round çözümünde
  /// oluşuyor, o yüzden ölçüt de round çıktısı serisi.
  ///
  /// [acknowledgedDamage] alanı kayıt uyumluluğu için **korunuyor**, anlamı
  /// değişti: artık ekranın gösterdiği son round serisi.
  int takePendingDamage() {
    if (roundOutcomeSerial == acknowledgedDamage) return 0;
    acknowledgedDamage = roundOutcomeSerial;
    return lastPlayerDamage;
  }

  int get roundDurationMinutes => currentRoundDuration.inMinutes;

  static String durationLabel(Duration duration) {
    if (duration.inSeconds < 60) return '${duration.inSeconds} saniye';
    return '${duration.inMinutes} dakika';
  }

  static String get configuredRoundDurationLabel =>
      durationLabel(roundDuration);

  String get roundDurationLabel => durationLabel(currentRoundDuration);

  String get totalAttackDurationLabel => durationLabel(totalAttackDuration);

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

  /// Round hedef erken tamamlanırsa anında, aksi halde 15 dakika sonunda çözülür.
  ///
  /// Hasar artık adımdan değil **statlardan** geliyor: roundun tamamlanma
  /// oranı oyuncunun vuruşunu ölçekliyor, kaçırılan oran da düşmanınkini.
  /// Hesabın tamamı `combat_engine.dart` içinde, saf ve deterministik.
  ///
  /// [playerStats] verilmezse ölçüt (1. seviye, ekipmansız) statlar kullanılır.
  /// Gerçek oyunda `RootShell` her zaman güncel statları veriyor; varsayılan,
  /// statı bilmeyen çağrı noktalarının (ör. bildirim servisi) ve testlerin
  /// sessizce yanlış sonuç üretmemesi için var.
  CombatRoundResult? resolveRound(
    int currentSteps,
    DateTime now, {
    CombatStats? playerStats,
    List<ItemEffect> onHitEffects = const [],
    List<ItemEffect> onKillEffects = const [],
  }) {
    if (battleOutcome != AdventureBattleOutcome.active ||
        roundTargetSteps <= 0) {
      return null;
    }

    final targetReached = stepsThisRound(currentSteps) >= roundTargetSteps;
    final expired = !now.isBefore(nextEnemyAttackAt);
    if (!targetReached && !expired) return null;

    final expiredAt = nextEnemyAttackAt;
    final resolvedPhase = currentPhase;
    final walked = stepsThisRound(currentSteps);
    final targetSteps = roundTargetSteps;

    final stats = (playerStats ?? defaultPlayerStats).sanitized();
    playerMaxHealth = stats.maxHealth.round();
    if (playerHealth > playerMaxHealth) playerHealth = playerMaxHealth;

    var damageDealt = 0;
    var damageTaken = 0;
    var playerCrit = false;
    var playerDodged = false;
    var playerActedFirst = true;

    {
      if (combatSeed == 0) {
        combatSeed = fallbackCombatSeed(enemy.id, startingSteps);
      }
      final outcome = resolveCombatRound(
        player: stats,
        enemy: scaledEnemyStats,
        playerHealth: playerHealth,
        enemyHealth: enemyHealth,
        completion: walked / roundTargetSteps,
        seed: combatSeed,
        onHitEffects: onHitEffects,
        onKillEffects: onKillEffects,
      );
      combatSeed = outcome.nextSeed;
      playerHealth = outcome.playerHealthAfter.clamp(0, playerMaxHealth);
      damageDealt = outcome.damageDealt;
      damageTaken = outcome.damageTaken;
      playerCrit = outcome.playerCrit;
      playerDodged = outcome.playerDodged;
      playerActedFirst = outcome.firstMover == Combatant.player;

      enemyHealth = outcome.enemyHealthAfter;

      if (outcome.playerDefeated) {
        battleOutcome = AdventureBattleOutcome.defeat;
      } else if (outcome.enemyDefeated) {
        battleOutcome = AdventureBattleOutcome.victory;
      }
    }

    lastPlayerDamage = damageDealt;
    final damage = damageTaken;
    if (damage > 0) {
      lastEnemyDamage = damage;
      enemyAttackSerial += 1;
      untouchedRounds = 0;
    } else {
      lastEnemyDamage = 0;
      untouchedRounds += 1;
    }

    final resolvedRound = currentRound;
    lastResolvedRound = resolvedRound;
    lastRoundWon = targetReached;
    roundOutcomeSerial += 1;

    roundStartingSteps += walked;

    if (battleOutcome == AdventureBattleOutcome.active) {
      currentRound += 1;
      final remaining = stepGoal - questSteps(currentSteps);
      // Adım taahhüdü bitse bile düşman ayaktaysa savaş kilitlenmesin.
      roundTargetSteps =
          remaining <= 0 ? stageStepTarget : _targetForRemaining(remaining);
      // Arka plan catch-up'ı `now`dan başlamaz; kaçırılan roundlar eski mutlak
      // zaman çizgisinde ilerler; erken tamamlanan round ise o anda yenilenir.
      final nextRoundStartsAt = expired ? expiredAt : now;
      nextEnemyAttackAt = nextRoundStartsAt.add(roundDuration);
      nextReminderAt = nextRoundStartsAt.add(reminderInterval);
    } else {
      roundTargetSteps = 0;
      nextEnemyAttackAt = now;
      nextReminderAt = now;
    }

    return CombatRoundResult(
      roundNumber: resolvedRound,
      phase: resolvedPhase,
      walkedSteps: walked,
      targetSteps: targetSteps,
      playerDamage: damage,
      enemyDamage: damageDealt,
      playerCrit: playerCrit,
      playerDodged: playerDodged,
      enemyDefeated: battleOutcome == AdventureBattleOutcome.victory,
      playerDefeated: battleOutcome == AdventureBattleOutcome.defeat,
      playerActedFirst: playerActedFirst,
      battleOutcome: battleOutcome,
    );
  }

  /// Eski çağrı noktaları ve kayıt uyumluluğu için adını koruyan yönlendirme.
  CombatRoundResult? resolveExpiredRound(
    int currentSteps,
    DateTime now, {
    CombatStats? playerStats,
    List<ItemEffect> onHitEffects = const [],
    List<ItemEffect> onKillEffects = const [],
  }) => resolveRound(
    currentSteps,
    now,
    playerStats: playerStats,
    onHitEffects: onHitEffects,
    onKillEffects: onKillEffects,
  );

  /// Süresi dolmuş **tüm** turları sırayla çözer ve toplamlarını döner.
  ///
  /// Uygulama arka planda kaldığında birden fazla tur birikir; tek tur çözmek
  /// kalanları sessizce affediyordu (triaj A1). Dolmuş tur yoksa `null`.
  ///
  /// [maxCatchUpRounds] yalnızca güvenlik ağıdır: can sıfırlanınca ya da
  /// düşman yenilince döngü zaten durur.
  CombatRoundResult? resolveExpiredRounds(
    int currentSteps,
    DateTime now, {
    CombatStats? playerStats,
    List<ItemEffect> onHitEffects = const [],
    List<ItemEffect> onKillEffects = const [],
  }) {
    var walked = 0;
    var target = 0;
    var damage = 0;
    var dealt = 0;
    var rounds = 0;
    var crit = false;
    var dodged = false;
    var lastRoundNumber = currentRound;
    var enemyDown = false;
    var playerDown = false;
    var actedFirst = true;
    var lastPhase = currentPhase;
    var outcome = battleOutcome;

    while (rounds < maxCatchUpRounds) {
      final result = resolveExpiredRound(
        currentSteps,
        now,
        playerStats: playerStats,
        onHitEffects: onHitEffects,
        onKillEffects: onKillEffects,
      );
      if (result == null) break;
      walked += result.walkedSteps;
      target += result.targetSteps;
      damage += result.playerDamage;
      dealt += result.enemyDamage;
      crit = crit || result.playerCrit;
      dodged = dodged || result.playerDodged;
      enemyDown = result.enemyDefeated;
      playerDown = result.playerDefeated;
      actedFirst = result.playerActedFirst;
      lastRoundNumber = result.roundNumber;
      lastPhase = result.phase;
      outcome = result.battleOutcome;
      rounds++;
    }

    if (rounds == 0) return null;
    return CombatRoundResult(
      roundNumber: lastRoundNumber,
      phase: lastPhase,
      walkedSteps: walked,
      targetSteps: target,
      playerDamage: damage,
      enemyDamage: dealt,
      playerCrit: crit,
      playerDodged: dodged,
      enemyDefeated: enemyDown,
      playerDefeated: playerDown,
      playerActedFirst: actedFirst,
      battleOutcome: outcome,
    );
  }

  bool takeDueReminder(DateTime now) {
    if (battleOutcome != AdventureBattleOutcome.active) return false;
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
    'victoryXpReward': victoryXpReward,
    'victoryCoinReward': victoryCoinReward,
    'acknowledgedDamage': acknowledgedDamage,
    'deathAnimationPlayed': deathAnimationPlayed,
    'playerHealth': playerHealth,
    'playerMaxHealth': playerMaxHealth,
    'enemyHealth': enemyHealth,
    'combatSeed': combatSeed,
    'untouchedRounds': untouchedRounds,
    'roundStartingSteps': roundStartingSteps,
    'roundTargetSteps': roundTargetSteps,
    'nextEnemyAttackAt': nextEnemyAttackAt.toIso8601String(),
    'roundDurationSeconds': currentRoundDuration.inSeconds,
    'attackConfigVersion': AttackConfig.version,
    'nextReminderAt': nextReminderAt.toIso8601String(),
    'enemyAttackSerial': enemyAttackSerial,
    'lastEnemyDamage': lastEnemyDamage,
    'lastPlayerDamage': lastPlayerDamage,
    'currentRound': currentRound,
    'lastResolvedRound': lastResolvedRound,
    'roundOutcomeSerial': roundOutcomeSerial,
    'presentedRoundOutcomeSerial': presentedRoundOutcomeSerial,
    'lastRoundWon': lastRoundWon,
    'battleOutcome': battleOutcome.name,
    'enemyDefeatPending': enemyDefeatPending,
    'playerDefeatPending': playerDefeatPending,
    'revivalStarted': revivalStarted,
    'revivalSteps': revivalSteps,
  };

  /// Kayıttan geri yükler. Tur hedefi ve geri sayım kurucuda hesaplandığı
  /// için, kayıtlı değerler varsa üzerine yazılır; böylece uygulama kapanıp
  /// açıldığında geri sayım bedava sıfırlanmaz.
  factory AdventureQuest.fromJson(
    Map<String, dynamic> json, {
    required Enemy enemy,
  }) {
    final migratedStepGoal =
        json['stepGoal'] as int? ?? enemy.minimumDailySteps;
    final savedPlayerHealth = json['playerHealth'] as int? ?? maxPlayerHealth;
    final rawEnemyHealth = json['enemyHealth'] as int?;

    final scaledMaxHealth = _scaledEnemyMaxHealth(enemy, migratedStepGoal);
    final restoredEnemyHealth = switch (rawEnemyHealth) {
      null => null,
      _ => rawEnemyHealth.clamp(0, scaledMaxHealth),
    };

    final savedOutcome = _parseBattleOutcome(json['battleOutcome']);
    final restoredOutcome =
        savedOutcome ??
        (savedPlayerHealth <= 0
            ? AdventureBattleOutcome.defeat
            : rawEnemyHealth != null && rawEnemyHealth <= 0
            ? AdventureBattleOutcome.victory
            : AdventureBattleOutcome.active);
    final isActive = restoredOutcome == AdventureBattleOutcome.active;

    final quest = AdventureQuest(
      enemy: enemy,
      stepGoal: migratedStepGoal,
      backgroundAsset:
          json['backgroundAsset'] as String? ?? defaultBackgroundAsset,
      startingSteps: json['startingSteps'] as int? ?? 0,
      xpAwarded: json['xpAwarded'] as bool? ?? false,
      victoryXpReward: json['victoryXpReward'] as int? ?? 0,
      victoryCoinReward: json['victoryCoinReward'] as int? ?? 0,
      acknowledgedDamage: json['acknowledgedDamage'] as int? ?? 0,
      deathAnimationPlayed: json['deathAnimationPlayed'] as bool? ?? false,
      playerHealth: savedPlayerHealth,
      playerMaxHealth: json['playerMaxHealth'] as int? ?? maxPlayerHealth,
      enemyHealth: restoredEnemyHealth,
      combatSeed: json['combatSeed'] as int? ?? 0,
      untouchedRounds: json['untouchedRounds'] as int? ?? 0,
      roundStartingSteps: json['roundStartingSteps'] as int?,
      enemyAttackSerial: json['enemyAttackSerial'] as int? ?? 0,
      lastEnemyDamage: json['lastEnemyDamage'] as int? ?? 0,
      lastPlayerDamage: json['lastPlayerDamage'] as int? ?? 0,
      currentRound: json['currentRound'] as int? ?? 1,
      lastResolvedRound: json['lastResolvedRound'] as int? ?? 0,
      roundOutcomeSerial: json['roundOutcomeSerial'] as int? ?? 0,
      presentedRoundOutcomeSerial:
          json['presentedRoundOutcomeSerial'] as int? ?? 0,
      lastRoundWon: json['lastRoundWon'] as bool? ?? false,
      battleOutcome: restoredOutcome,
      enemyDefeatPending: false,
      playerDefeatPending: false,
      revivalStarted:
          restoredOutcome == AdventureBattleOutcome.defeat &&
          (json['revivalStarted'] as bool? ?? false),
      revivalSteps:
          restoredOutcome == AdventureBattleOutcome.defeat
              ? json['revivalSteps'] as int? ?? 0
              : 0,
    );

    if (!isActive) {
      quest.roundTargetSteps = 0;
      quest.enemyDefeatPending = false;
      quest.playerDefeatPending = false;
    }

    final savedAttackAt = _parseDate(json['nextEnemyAttackAt']);
    final savedRoundDurationSeconds = json['roundDurationSeconds'] as int?;
    // Test/denge sırasında round süresi değişmişse eski uzun geri sayımı
    // taşımak yerine kurucunun güncel süreyle oluşturduğu sayacı kullan.
    if (isActive &&
        savedAttackAt != null &&
        savedRoundDurationSeconds == quest.currentRoundDuration.inSeconds) {
      quest.nextEnemyAttackAt = savedAttackAt;
    }
    final savedReminderAt = _parseDate(json['nextReminderAt']);
    if (isActive && savedReminderAt != null) {
      quest.nextReminderAt = savedReminderAt;
    }
    return quest;
  }

  static AdventureBattleOutcome? _parseBattleOutcome(Object? value) {
    if (value is! String) return null;
    for (final outcome in AdventureBattleOutcome.values) {
      if (outcome.name == value) return outcome;
    }
    return null;
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }

  /// Düşmanın kalan canı. Adımdan **bağımsız**; savaş motoru düşürüyor.
  int get remainingEnemyHealth => enemyHealth < 0 ? 0 : enemyHealth;

  /// Düşmanın canının tavanına oranı (0..1). Can barı bunu çiziyor.
  double get enemyHealthProgress {
    final max = scaledEnemyMaxHealth;
    if (max <= 0) return 0;
    return (remainingEnemyHealth / max).clamp(0.0, 1.0);
  }

  /// Oyuncunun canının tavanına oranı (0..1).
  double get playerHealthProgress {
    final max = playerMaxHealth <= 0 ? 1 : playerMaxHealth;
    return (playerHealth / max).clamp(0.0, 1.0);
  }

  /// Beş roundun tamamı terminal sonuçla kapandı mı.
  bool get isBattleCompleted => battleOutcome != AdventureBattleOutcome.active;

  /// Düşman otoriter final sonuçta devrildi mi.
  bool get isEnemyDefeated => battleOutcome == AdventureBattleOutcome.victory;

  /// Oyuncu otoriter final sonuçta düştü mü.
  bool get isPlayerDefeated => battleOutcome == AdventureBattleOutcome.defeat;

  bool get revivalCompleted =>
      isPlayerDefeated && revivalStarted && revivalSteps >= revivalStepTarget;

  bool get isRevivalActive =>
      isPlayerDefeated && revivalStarted && !revivalCompleted;

  int get revivalRemainingSteps =>
      (revivalStepTarget - revivalSteps).clamp(0, revivalStepTarget);

  double get revivalProgress =>
      (revivalSteps / revivalStepTarget).clamp(0.0, 1.0);

  /// Otoriter yenilgiden sonra Hayat Yürüyüşünü başlatır.
  bool startRevival() {
    if (!isPlayerDefeated || revivalCompleted) return false;
    revivalStarted = true;
    return true;
  }

  /// Hayat Yürüyüşüne adım ekler ve gerçekten kabul edilen miktarı döndürür.
  int addRevivalSteps(int amount) {
    if (amount <= 0 || !isRevivalActive) return 0;
    final accepted = amount.clamp(0, revivalRemainingSteps);
    revivalSteps += accepted;
    return accepted;
  }

  /// Ölçüt oyuncu statları.
  ///
  /// Statı bilmeyen bir çağrı noktası roundu çözerse sessizce yanlış sonuç
  /// üretmesin diye açık bir varsayılan var: 1. seviye, ekipmansız oyuncu.
  static CombatStats get defaultPlayerStats => baseCombatStats(1);

  /// Tohum kurulmadan round çözülürse kullanılan yedek tohum.
  ///
  /// Deterministik: aynı düşman ve aynı başlangıç adımı her zaman aynı
  /// tohumu verir. `String.hashCode` **kullanılmaz** (GD8).
  static int fallbackCombatSeed(String enemyId, int startingSteps) =>
      stableSpread('combat|$enemyId|$startingSteps', 0x7FFFFFF0) + 1;
}

class CombatRoundResult {
  final int roundNumber;
  final AttackPhase phase;
  final int walkedSteps;
  final int targetSteps;

  /// Oyuncunun **aldığı** hasar. (Ad tarihsel; alan adı korunuyor.)
  final int playerDamage;

  /// Oyuncunun **verdiği** hasar.
  final int enemyDamage;

  final bool playerCrit;

  /// Oyuncu düşmanın vuruşunu sıyırdı mı.
  final bool playerDodged;

  final bool enemyDefeated;
  final bool playerDefeated;

  /// Turu oyuncu mu açtı (inisiyatif).
  final bool playerActedFirst;

  /// Bu round çözüldükten sonraki otoriter savaş sonucu.
  final AdventureBattleOutcome battleOutcome;

  const CombatRoundResult({
    required this.roundNumber,
    required this.phase,
    required this.walkedSteps,
    required this.targetSteps,
    required this.playerDamage,
    this.enemyDamage = 0,
    this.playerCrit = false,
    this.playerDodged = false,
    this.enemyDefeated = false,
    this.playerDefeated = false,
    this.playerActedFirst = true,
    this.battleOutcome = AdventureBattleOutcome.active,
  });

  bool get targetReached => walkedSteps >= targetSteps;
}
