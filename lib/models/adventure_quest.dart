import '../core/constants/attack_config.dart';
import '../core/constants/game_constants.dart';
import '../core/constants/timed_combat_config.dart';
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

/// Maceranın oyuncuya gösterilen fazı (Bölüm A).
///
/// Savaş sonucu ([AdventureBattleOutcome]) **otoriter durumdur**; bu enum ise
/// o durumdan ve yürüyüş ilerlemesinden türeyen sunum katmanıdır. İkinci bir
/// kalıcı alan olarak saklanmaz — tek doğruluk kaynağı [AdventureQuest]
/// alanlarıdır.
enum AdventureQuestPhase {
  /// Düşman ayakta; adımlar vuruşa dönüşüyor.
  combat,

  /// Düşman devrildi ama maceranın adım taahhüdü sürüyor. Kazanç bonuslu.
  walk,

  /// Düşman devrildi ve taahhüt doldu. Macera gerçekten bitti.
  completed,

  /// Oyuncu düştü; 500 adımlık Hayat Yürüyüşü sürüyor ya da bekliyor.
  revival,

  /// Hayat Yürüyüşü tamamlandı.
  revivalCompleted,
}

extension AdventureQuestPhaseLabel on AdventureQuestPhase {
  String get label => switch (this) {
    AdventureQuestPhase.combat => 'Savaş fazı',
    AdventureQuestPhase.walk => 'Yürüyüş fazı',
    AdventureQuestPhase.completed => 'Macera tamamlandı',
    AdventureQuestPhase.revival => 'Hayat Yürüyüşü',
    AdventureQuestPhase.revivalCompleted => 'Hayat Yürüyüşü tamamlandı',
  };
}

class AdventureQuest {
  static const String defaultBackgroundAsset =
      'lib/Backgrounds/versionA_platform.png';
  static const int maxPlayerHealth = 100;

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

  /// Safety confirmation sonrası maceranın gerçekten başladığı an.
  final DateTime adventureStartedAt;

  /// Toplam adım hedefinin ilk kez tamamlandığı an. Savaş ekranını daha sonra
  /// açmak bu damgayı ve dolayısıyla alınacak hasarı değiştirmez.
  DateTime? stepTargetCompletedAt;

  /// Accepted steps from earlier game days keep pending rounds across reset.
  int carriedSteps;
  int notifiedReadyRound;

  bool xpAwarded;
  int victoryXpReward;
  int victoryCoinReward;
  int walkCoinReward;
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

  /// Son çözülen round başlamadan hemen önceki düşman canı.
  /// Can düşüş animasyonu gerçek kaybı göstermek için bunu kullanır.
  int enemyHealthBeforeLastRound;

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

  /// Arka arkaya tamamlanan mükemmel savaş roundu sayısı.
  int perfectRoundStreak;

  /// Son çözülen round mükemmel miydi? Sunum ve geri bildirim için saklanır.
  bool lastRoundPerfect;

  /// Son roundda uygulanan erken bitirme + seri hasar çarpanı.
  double lastPerfectDamageMultiplier;

  /// Son round mevcut mükemmel seriyi kırdı mı.
  bool lastPerfectStreakBroken;
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

  /// Düşman devrildiği anda maceranın kaç adımı harcanmıştı (Bölüm A).
  ///
  /// `-1` = "henüz zafer yok ya da eski kayıt". Zafer anında damgalanır ve
  /// **iki** şeyin tek kaynağı olur: yürüyüş fazının hedefi
  /// ([walkTargetSteps]) ve zafer ödülünün hız çarpanı
  /// ([speedRewardMultiplier]).
  ///
  /// Neden ayrı bir "faz" bayrağı yok: faz durumdan türetilebiliyor
  /// (`zafer + kalan yürüyüş adımı`), ikinci bir kalıcı alan iki doğruluk
  /// kaynağı üretirdi.
  int victorySteps;

  /// Düşmanı deviren roundun numarası. Yalnızca gösterim için: oyuncuya
  /// "3 round'da bitirdin" diyebilmek gerekiyor.
  int victoryRounds;

  /// Yürüyüş fazında biriken adım. [revivalSteps] ile aynı desende: kabul
  /// edilen adım kadar ilerler, hedefi aşamaz.
  int walkSteps;

  AdventureQuest({
    required this.enemy,
    required this.stepGoal,
    this.backgroundAsset = defaultBackgroundAsset,
    this.startingSteps = 0,
    this.carriedSteps = 0,
    this.notifiedReadyRound = 0,
    this.xpAwarded = false,
    this.victoryXpReward = 0,
    this.victoryCoinReward = 0,
    this.walkCoinReward = 0,
    this.acknowledgedDamage = 0,
    this.deathAnimationPlayed = false,
    this.playerHealth = maxPlayerHealth,
    this.playerMaxHealth = maxPlayerHealth,
    int? enemyHealth,
    this.enemyHealthBeforeLastRound = 0,
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
    this.perfectRoundStreak = 0,
    this.lastRoundPerfect = false,
    this.lastPerfectDamageMultiplier = 1,
    this.lastPerfectStreakBroken = false,
    this.battleOutcome = AdventureBattleOutcome.active,
    this.enemyDefeatPending = false,
    this.playerDefeatPending = false,
    this.revivalStarted = false,
    int revivalSteps = 0,
    this.victorySteps = -1,
    this.victoryRounds = 0,
    int walkSteps = 0,
    DateTime? startedAt,
    DateTime? adventureStartedAt,
    this.stepTargetCompletedAt,
  }) : roundStartingSteps = roundStartingSteps ?? startingSteps,
       adventureStartedAt = adventureStartedAt ?? startedAt ?? GameClock.now(),
       walkSteps = walkSteps < 0 ? 0 : walkSteps,
       currentRound = currentRound < 1 ? 1 : currentRound,
       enemyHealth = enemyHealth ?? _scaledEnemyMaxHealth(enemy, stepGoal),
       revivalSteps = revivalSteps.clamp(0, revivalStepTarget),
       roundTargetSteps = _roundTargetFor(stepGoal, currentRound),
       nextEnemyAttackAt = (startedAt ?? GameClock.now()).add(
         roundDurationForSteps(_roundTargetFor(stepGoal, currentRound)),
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
        // Zafer damgası olmadan gelen bir kayıt (v16 ve öncesi) yürüyüş
        // fazına **geriye dönük sokulmaz**: tamamlanmış bir macerayı
        // güncelleme sonrası yeniden açmak, oyuncunun bitirdiği işi geri
        // almak olurdu. Tam hedefte devrilmiş sayılır: yürüyüş hedefi 0,
        // hız çarpanı ×1.
        if (victorySteps < 0) victorySteps = stepGoal;
      } else {
        playerHealth = 0;
      }
    }
    this.walkSteps = this.walkSteps.clamp(0, walkTargetSteps);
  }

  static int _roundTargetFor(int stepGoal, int round) {
    if (stepGoal <= 0) return 0;
    final completedRoundSteps =
        (round - 1) * GameConstants.combatRoundStepTarget;
    final remaining = stepGoal - completedRoundSteps;
    if (remaining <= 0) return GameConstants.combatRoundStepTarget;
    return remaining.clamp(1, GameConstants.combatRoundStepTarget);
  }

  static Duration roundDurationForSteps(int steps) =>
      AttackConfig.durationForSteps(steps);

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
    // Eğitim savaşını guide kazanıyor, oyuncu değil. Bu yüzden zafer **tam
    // hedefte** damgalanır: yürüyüş fazı açılmaz ve hız çarpanı ×1 kalır.
    // Aksi hâlde hiç adım atmamış yeni oyuncu ×2 ödül alır ve eğitimin
    // ortasında binlerce adımlık bir yürüyüşe kilitlenirdi. Yürüyüş fazı
    // eğitimde **anlatılır**, ilk gerçek macerada yaşanır.
    stampVictory(questStepsAtVictory: stepGoal, round: currentRound);
    battleOutcome = AdventureBattleOutcome.victory;
    enemyDefeatPending = false;
    playerDefeatPending = false;
    roundTargetSteps = 0;
    nextEnemyAttackAt = now;
    nextReminderAt = now;
  }

  static int _scaledEnemyMaxHealth(Enemy enemy, int stepGoal) =>
      enemy.maxHealth;

  AttackTargetConfig get attackConfig =>
      AttackConfig.supportsStepTarget(stepGoal)
          ? AttackConfig.forStepTarget(stepGoal)
          : AttackTargetConfig(stepTarget: stepGoal, enemyPowerMultiplier: 1);

  AttackRoundConfig get currentRoundConfig => AttackConfig.roundConfig(
    (currentRound - 1).clamp(0, totalRounds - 1),
    totalRounds,
  );

  AttackPhase get currentPhase => currentRoundConfig.phase;

  Duration get totalAttackDuration =>
      GameConstants.combatRoundDuration * totalRounds;

  Duration get currentRoundDuration =>
      roundTargetSteps <= 0 ? Duration.zero : GameConstants.combatRoundDuration;

  double get enemyPowerMultiplier => 1;

  /// Her okumada katalog tabanından türetilir; ölçeklenmiş stat tekrar
  /// ölçeklenmediği için round sayısı çarpanı katlayamaz.
  CombatStats get scaledEnemyStats =>
      scaleEnemyCombatStats(enemy.stats, enemyPowerMultiplier);

  int get scaledEnemyMaxHealth => scaledEnemyStats.maxHealth.round();

  int get totalRounds => AttackConfig.roundCountForSteps(stepGoal);

  double get perfectStreakCap {
    if (perfectRoundStreak <= 0) return 1;
    final multipliers = GameConstants.perfectRoundStreakMultipliers;
    return multipliers[(perfectRoundStreak - 1).clamp(
      0,
      multipliers.length - 1,
    )];
  }

  double get nextPerfectStreakCap {
    final multipliers = GameConstants.perfectRoundStreakMultipliers;
    return multipliers[perfectRoundStreak.clamp(0, multipliers.length - 1)];
  }

  /// Macera başladığından beri atılan adım — düşmana verilen toplam hasar.
  /// Günlük sayaç sıfırlanmadığı için [startingSteps] farkı alınır.
  int questSteps(int currentSteps) =>
      (currentSteps + carriedSteps - startingSteps).clamp(0, stepGoal);

  bool isStepTargetCompleted(int currentSteps) =>
      questSteps(currentSteps) >= stepGoal;

  Duration get expectedCompletionDuration =>
      TimedCombatConfig.expectedDurationForSteps(stepGoal);

  Duration? get completionDuration {
    final completedAt = stepTargetCompletedAt;
    if (completedAt == null) return null;
    final duration = completedAt.difference(adventureStartedAt);
    return duration.isNegative ? Duration.zero : duration;
  }

  /// Hedefin ilk tamamlandığı anı bir kez kaydeder.
  bool recordStepTargetCompletion(int currentSteps, DateTime now) {
    if (battleOutcome != AdventureBattleOutcome.active ||
        stepTargetCompletedAt != null ||
        !isStepTargetCompleted(currentSteps)) {
      return false;
    }
    stepTargetCompletedAt =
        now.isBefore(adventureStartedAt) ? adventureStartedAt : now;
    return true;
  }

  /// Toplam hedef tamamlandıktan sonra tek karşılaşmayı çözer. Düşman her
  /// zaman önce saldırır; oyuncu hayatta kalırsa mevcut zafer akışına girecek
  /// öldürücü karşı vuruşu yapar.
  TimedCombatOutcome? resolveTimedEncounter(
    int currentSteps,
    DateTime now, {
    CombatStats? playerStats,
    List<ItemEffect> onKillEffects = const [],
  }) {
    if (battleOutcome != AdventureBattleOutcome.active ||
        !isStepTargetCompleted(currentSteps)) {
      return null;
    }
    recordStepTargetCompletion(currentSteps, now);
    final actualDuration = completionDuration;
    if (actualDuration == null) return null;

    final stats = (playerStats ?? defaultPlayerStats).sanitized();
    playerMaxHealth = stats.maxHealth.round();
    playerHealth = playerHealth.clamp(0, playerMaxHealth);
    if (combatSeed == 0) {
      combatSeed = fallbackCombatSeed(enemy.id, startingSteps);
    }
    enemyHealthBeforeLastRound = enemyHealth;
    final timed = resolveTimedCombat(
      player: stats,
      enemy: scaledEnemyStats,
      playerHealth: playerHealth,
      enemyHealth: enemyHealth,
      expectedDuration: expectedCompletionDuration,
      actualDuration: actualDuration,
      difficultyMultiplier: TimedCombatConfig.difficultyMultiplierForSteps(
        stepGoal,
      ),
      seed: combatSeed,
      onKillEffects: onKillEffects,
    );
    final outcome = timed.combat;
    combatSeed = outcome.nextSeed;
    playerHealth = outcome.playerHealthAfter.clamp(0, playerMaxHealth);
    enemyHealth = outcome.enemyHealthAfter;
    lastEnemyDamage = outcome.damageTaken;
    lastPlayerDamage = outcome.damageDealt;
    enemyAttackSerial += 1;
    untouchedRounds = outcome.damageTaken == 0 ? untouchedRounds + 1 : 0;
    lastResolvedRound = totalRounds;
    currentRound = totalRounds;
    lastRoundWon = outcome.enemyDefeated;
    lastRoundPerfect = false;
    lastPerfectStreakBroken = false;
    lastPerfectDamageMultiplier = 1;
    perfectRoundStreak = 0;
    roundOutcomeSerial += 1;
    roundStartingSteps = startingSteps + stepGoal;
    roundTargetSteps = 0;
    nextEnemyAttackAt = now;
    nextReminderAt = now;

    if (outcome.playerDefeated) {
      battleOutcome = AdventureBattleOutcome.defeat;
    } else {
      battleOutcome = AdventureBattleOutcome.victory;
      stampVictory(questStepsAtVictory: stepGoal, round: totalRounds);
    }
    return timed;
  }

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

  String get roundDurationLabel => durationLabel(currentRoundDuration);

  String get totalAttackDurationLabel => durationLabel(totalAttackDuration);

  int stepsThisRound(int currentSteps) =>
      (currentSteps + carriedSteps - roundStartingSteps).clamp(
        0,
        roundTargetSteps,
      );

  int roundStepsRemaining(int currentSteps) =>
      (roundTargetSteps - stepsThisRound(currentSteps)).clamp(
        0,
        roundTargetSteps,
      );

  Duration countdownRemaining(DateTime now) {
    final remaining = nextEnemyAttackAt.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Resolves a banked round on explicit battle confirmation; time never expires it.
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
    final perfect = targetReached && now.isBefore(expiredAt);
    final previousPerfectStreak = perfectRoundStreak;
    if (perfect) {
      perfectRoundStreak += 1;
    } else {
      perfectRoundStreak = 0;
    }
    final roundMilliseconds = currentRoundDuration.inMilliseconds;
    final earlyFraction =
        perfect && roundMilliseconds > 0
            ? expiredAt.difference(now).inMilliseconds / roundMilliseconds
            : 0.0;
    final perfectMultiplier = perfectRoundDamageMultiplier(
      streak: perfectRoundStreak,
      earlyFraction: earlyFraction,
    );
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
      enemyHealthBeforeLastRound = enemyHealth;
      final outcome = resolveCombatRound(
        player: stats,
        enemy: scaledEnemyStats,
        playerHealth: playerHealth,
        enemyHealth: enemyHealth,
        completion: walked / roundTargetSteps,
        seed: combatSeed,
        playerDamageMultiplier: perfectMultiplier,
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
        // Zaferin geldiği nokta burada damgalanır: yürüyüş fazının hedefi ve
        // ödülün hız çarpanı ikisi de bundan türüyor (Bölüm A.1/A.2).
        stampVictory(
          questStepsAtVictory: questSteps(currentSteps),
          round: currentRound,
        );
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
    lastRoundPerfect = perfect;
    lastPerfectStreakBroken = !perfect && previousPerfectStreak > 0;
    lastPerfectDamageMultiplier = perfectMultiplier;
    roundOutcomeSerial += 1;

    roundStartingSteps += walked;

    if (battleOutcome == AdventureBattleOutcome.active) {
      currentRound += 1;
      final remaining = stepGoal - questSteps(currentSteps);
      // Adım taahhüdü bitse bile düşman ayaktaysa savaş kilitlenmesin.
      roundTargetSteps =
          remaining <= 0
              ? _roundTargetFor(stepGoal, totalRounds)
              : _roundTargetFor(stepGoal, currentRound);
      // Arka plan catch-up'ı `now`dan başlamaz; kaçırılan roundlar eski mutlak
      // zaman çizgisinde ilerler; erken tamamlanan round ise o anda yenilenir.
      final nextRoundStartsAt = expired ? expiredAt : now;
      nextEnemyAttackAt = nextRoundStartsAt.add(currentRoundDuration);
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
      perfect: perfect,
      perfectStreak: perfectRoundStreak,
      perfectDamageMultiplier: perfectMultiplier,
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

  /// Legacy batch API: resolves only fully banked rounds. The app does not call
  ///
  /// this from lifecycle or timers; the UI confirms one battle round at a time.
  /// Insufficient steps leave the enemy and player unchanged.
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
    var perfect = false;
    var perfectMultiplier = 1.0;

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
      perfect = result.perfect;
      perfectMultiplier = result.perfectDamageMultiplier;
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
      perfect: perfect,
      perfectStreak: perfectRoundStreak,
      perfectDamageMultiplier: perfectMultiplier,
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
    'adventureStartedAt': adventureStartedAt.toIso8601String(),
    'stepTargetCompletedAt': stepTargetCompletedAt?.toIso8601String(),
    'carriedSteps': carriedSteps,
    'notifiedReadyRound': notifiedReadyRound,
    'xpAwarded': xpAwarded,
    'victoryXpReward': victoryXpReward,
    'victoryCoinReward': victoryCoinReward,
    'walkCoinReward': walkCoinReward,
    'acknowledgedDamage': acknowledgedDamage,
    'deathAnimationPlayed': deathAnimationPlayed,
    'playerHealth': playerHealth,
    'playerMaxHealth': playerMaxHealth,
    'enemyHealth': enemyHealth,
    'enemyHealthBeforeLastRound': enemyHealthBeforeLastRound,
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
    'perfectRoundStreak': perfectRoundStreak,
    'lastRoundPerfect': lastRoundPerfect,
    'lastPerfectDamageMultiplier': lastPerfectDamageMultiplier,
    'lastPerfectStreakBroken': lastPerfectStreakBroken,
    'battleOutcome': battleOutcome.name,
    'enemyDefeatPending': enemyDefeatPending,
    'playerDefeatPending': playerDefeatPending,
    'revivalStarted': revivalStarted,
    'revivalSteps': revivalSteps,
    'victorySteps': victorySteps,
    'victoryRounds': victoryRounds,
    'walkSteps': walkSteps,
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
      adventureStartedAt:
          _parseDate(json['adventureStartedAt']) ??
          _parseDate(json['nextEnemyAttackAt'])?.subtract(
            AttackConfig.durationForSteps(_roundTargetFor(migratedStepGoal, 1)),
          ),
      stepTargetCompletedAt: _parseDate(json['stepTargetCompletedAt']),
      carriedSteps: json['carriedSteps'] as int? ?? 0,
      notifiedReadyRound: json['notifiedReadyRound'] as int? ?? 0,
      xpAwarded: json['xpAwarded'] as bool? ?? false,
      victoryXpReward: json['victoryXpReward'] as int? ?? 0,
      victoryCoinReward: json['victoryCoinReward'] as int? ?? 0,
      walkCoinReward: json['walkCoinReward'] as int? ?? 0,
      acknowledgedDamage: json['acknowledgedDamage'] as int? ?? 0,
      deathAnimationPlayed: json['deathAnimationPlayed'] as bool? ?? false,
      playerHealth: savedPlayerHealth,
      playerMaxHealth: json['playerMaxHealth'] as int? ?? maxPlayerHealth,
      enemyHealth: restoredEnemyHealth,
      enemyHealthBeforeLastRound:
          json['enemyHealthBeforeLastRound'] as int? ?? 0,
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
      perfectRoundStreak: json['perfectRoundStreak'] as int? ?? 0,
      lastRoundPerfect: json['lastRoundPerfect'] as bool? ?? false,
      lastPerfectDamageMultiplier:
          (json['lastPerfectDamageMultiplier'] as num?)?.toDouble() ?? 1,
      lastPerfectStreakBroken:
          json['lastPerfectStreakBroken'] as bool? ?? false,
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
      // Zafer damgası yalnızca zaferli kayıtlarda anlamlı. Eksikse
      // kurucu `stepGoal` ile doldurur: eski kayıt yürüyüş fazına geriye
      // dönük sokulmaz (bkz. kurucu gövdesi).
      victorySteps:
          restoredOutcome == AdventureBattleOutcome.victory
              ? json['victorySteps'] as int? ?? -1
              : -1,
      victoryRounds:
          restoredOutcome == AdventureBattleOutcome.victory
              ? json['victoryRounds'] as int? ?? 0
              : 0,
      walkSteps:
          restoredOutcome == AdventureBattleOutcome.victory
              ? json['walkSteps'] as int? ?? 0
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

  // ---------------------------------------------------------------------
  // Yürüyüş fazı (Bölüm A)
  //
  // Macera iki fazlı: **savaş** düşman devrilene kadar, **yürüyüş** ondan
  // sonra maceranın adım taahhüdü bitene kadar. Macera ancak taahhüt
  // dolduğunda gerçekten biter. Düşmanı erken deviren oyuncu ödülünü hemen
  // alır ve kalan yolu bonuslu yürür.
  //
  // Alanlar [revivalSteps] / [revivalStepTarget] desenini birebir izler:
  // hedef türetilir, ilerleme kalıcı, ekleme kabul edilen miktarı döndürür.
  // ---------------------------------------------------------------------

  /// Zafer damgalandı mı. `false` ise yürüyüş fazı henüz tanımlı değil.
  bool get hasVictoryStamp => victorySteps >= 0;

  /// Yürüyüş fazında yürünmesi gereken adım.
  ///
  /// Düşman adım taahhüdünün tamamı harcandıktan **sonra** devrildiyse 0 —
  /// yani yürüyüş fazı hiç açılmaz ve macera zaferle biter.
  int get walkTargetSteps {
    if (!hasVictoryStamp) return 0;
    return (stepGoal - victorySteps).clamp(0, stepGoal);
  }

  int get walkRemainingSteps =>
      (walkTargetSteps - walkSteps).clamp(0, walkTargetSteps);

  double get walkProgress {
    final target = walkTargetSteps;
    if (target <= 0) return 1;
    return (walkSteps / target).clamp(0.0, 1.0);
  }

  /// Şu an yürüyüş fazında mıyız.
  bool get isWalkPhaseActive => isEnemyDefeated && walkRemainingSteps > 0;

  /// Macera gerçekten bitti mi: düşman devrildi **ve** adım taahhüdü doldu.
  ///
  /// [isEnemyDefeated] artık "macera bitti" demek değil; ekranlar ve ödül
  /// kapıları bu ayrımı gözetmeli.
  bool get isAdventureCompleted => isEnemyDefeated && walkRemainingSteps == 0;

  /// Erken zaferden sonra açılan altın toplama yürüyüşü tamamlandı mı.
  bool get isGoldCollectionCompleted =>
      isAdventureCompleted && walkTargetSteps > 0;

  /// Maceranın hangi fazında olduğu. Yenilgi ve Hayat Yürüyüşü ayrı dallar.
  AdventureQuestPhase get phase {
    if (isPlayerDefeated) {
      return revivalCompleted
          ? AdventureQuestPhase.revivalCompleted
          : AdventureQuestPhase.revival;
    }
    if (!isEnemyDefeated) return AdventureQuestPhase.combat;
    return isWalkPhaseActive
        ? AdventureQuestPhase.walk
        : AdventureQuestPhase.completed;
  }

  /// Yürüyüş fazına adım ekler; gerçekten kabul edilen miktarı döndürür.
  int addWalkSteps(int amount) {
    if (amount <= 0 || !isWalkPhaseActive) return 0;
    final accepted = amount.clamp(0, walkRemainingSteps);
    walkSteps += accepted;
    return accepted;
  }

  /// Zaferin hangi noktada geldiğini damgalar (Bölüm A.1 + A.2).
  ///
  /// Yalnızca ilk çağrıda yazar: ikinci bir çağrı yürüyüş hedefini ve hız
  /// çarpanını sonradan değiştiremez.
  void stampVictory({required int questStepsAtVictory, required int round}) {
    if (hasVictoryStamp) return;
    victorySteps = questStepsAtVictory.clamp(0, stepGoal);
    victoryRounds = round < 1 ? 1 : round;
  }

  /// Zafer ödülünün hız çarpanı (Bölüm A.2).
  ///
  /// **Ölçü adımdır, round değil.** Gerekçe:
  /// - Round sayısı kaba: 500 adımlık bir macerada toplam **tek** round var,
  ///   yani round ölçüsüyle o hedefte hız ödülü hiç oluşamazdı.
  /// - Yürüyüş fazının kendisi de adımla tanımlı; aynı büyüklüğün iki sistemi
  ///   birden sürmesi, "erken bitirdim" ile "kalan yol" arasındaki ilişkiyi
  ///   tutarlı kılıyor: harcamadığın her adım hem çarpana hem bonuslu
  ///   yürüyüşe yazılıyor.
  /// - Beklemek bir kaçamak değil: savaş motoru verilen hasarı round
  ///   tamamlanma oranıyla ölçekliyor, yani hiç yürümeden düşman devrilmiyor.
  ///
  /// Sınırlar: hedefin tamamı harcandıysa ×1, hiç harcanmadıysa
  /// [GameConstants.maxVictorySpeedMultiplier].
  double get speedRewardMultiplier {
    if (!hasVictoryStamp || stepGoal <= 0) return 1;
    final ratio = (victorySteps / stepGoal).clamp(0.0, 1.0);
    final span = GameConstants.maxVictorySpeedMultiplier - 1;
    return 1 + (1 - ratio) * span;
  }

  /// Zafer anındaki ödül ile yürüyüş fazında kazanılan altının toplamı.
  int get totalCoinReward => victoryCoinReward + walkCoinReward;

  /// Kademe bazlı zafer altınının **tohumlu** çekilişi.
  ///
  /// Eskiden `Random()` ile atılıyordu; kalıcı bir ödülü etkileyen rastgelelik
  /// tohumlu olmalı ve tekrarlanabilir kalmalı (CLAUDE.md §4.4, GD18/GD50).
  /// `String.hashCode` **kullanılmaz** (GD8): sürümler arası sabit değil.
  int victoryCoinRoll({required int minimum, required int maximum}) {
    if (maximum <= minimum) return minimum;
    final span = maximum - minimum + 1;
    return minimum +
        stableSpread(
          'victory-coins|${enemy.id}|$startingSteps|$stepGoal',
          span,
        );
  }

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

  /// Hedef süre dolmadan tamamlandı mı.
  final bool perfect;

  /// Bu sonuçtan sonraki ardışık mükemmel round sayısı.
  final int perfectStreak;

  /// Bu roundda oyuncu hasarına uygulanan gerçek çarpan.
  final double perfectDamageMultiplier;

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
    this.perfect = false,
    this.perfectStreak = 0,
    this.perfectDamageMultiplier = 1,
  });

  bool get targetReached => walkedSteps >= targetSteps;
}
