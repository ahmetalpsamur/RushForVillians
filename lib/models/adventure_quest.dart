import '../core/utils/base_combat_stats.dart';
import '../core/utils/combat_engine.dart';
import '../core/utils/item_rules.dart';
import '../core/utils/game_clock.dart';
import 'combat_stats.dart';
import 'enemy.dart';
import 'item_effect.dart';

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

  AdventureQuest({
    required this.enemy,
    required this.stepGoal,
    this.backgroundAsset = defaultBackgroundAsset,
    this.startingSteps = 0,
    this.xpAwarded = false,
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
    this.currentRound = 1,
    this.lastResolvedRound = 0,
    this.roundOutcomeSerial = 0,
    this.presentedRoundOutcomeSerial = 0,
    this.lastRoundWon = false,
    DateTime? startedAt,
  }) : roundStartingSteps = roundStartingSteps ?? startingSteps,
       enemyHealth = enemyHealth ?? enemy.maxHealth,
       roundTargetSteps = _targetForRemaining(stepGoal),
       nextEnemyAttackAt = (startedAt ?? GameClock.now()).add(
         roundDurationForSteps(_targetForRemaining(stepGoal)),
       ),
       nextReminderAt = (startedAt ?? GameClock.now()).add(reminderInterval);

  /// Bir sonraki roundun adım hedefi.
  ///
  /// Adım hedefi tükendiği hâlde düşman hâlâ ayaktaysa **tam boy** round
  /// devam eder. Sıfır dönseydi round çözülemez ve savaş kilitlenirdi:
  /// düşman canı artık adımdan gelmiyor, yani "hedefi bitirdim" savaşın
  /// bittiği anlamına gelmiyor.
  int _nextRoundTarget(int questProgress) {
    final remaining = stepGoal - questProgress;
    if (remaining <= 0) return stageStepTarget;
    return remaining < stageStepTarget ? remaining : stageStepTarget;
  }

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
    if (roundTargetSteps <= 0 || playerHealth <= 0 || enemyHealth <= 0) {
      return null;
    }

    final targetReached = stepsThisRound(currentSteps) >= roundTargetSteps;
    final expired = !now.isBefore(nextEnemyAttackAt);
    if (!targetReached && !expired) return null;

    final expiredAt = nextEnemyAttackAt;
    final walked = stepsThisRound(currentSteps);
    final missedSteps = (roundTargetSteps - walked).clamp(0, roundTargetSteps);

    final stats = (playerStats ?? defaultPlayerStats).sanitized();
    if (combatSeed == 0) combatSeed = fallbackCombatSeed(enemy.id, startingSteps);
    final outcome = resolveCombatRound(
      player: stats,
      enemy: enemy.stats,
      playerHealth: playerHealth,
      enemyHealth: enemyHealth,
      completion: roundTargetSteps == 0 ? 1 : walked / roundTargetSteps,
      seed: combatSeed,
      onHitEffects: onHitEffects,
      onKillEffects: onKillEffects,
    );
    combatSeed = outcome.nextSeed;

    playerMaxHealth = stats.maxHealth.round();
    playerHealth = outcome.playerHealthAfter.clamp(0, playerMaxHealth);
    enemyHealth = outcome.enemyHealthAfter;

    lastPlayerDamage = outcome.damageDealt;
    final damage = outcome.damageTaken;
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
    currentRound += 1;

    roundStartingSteps += walked;
    roundTargetSteps = _nextRoundTarget(questSteps(currentSteps));
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
      enemyDamage: outcome.damageDealt,
      playerCrit: outcome.playerCrit,
      playerDodged: outcome.playerDodged,
      enemyDefeated: outcome.enemyDefeated,
      playerDefeated: outcome.playerDefeated,
      playerActedFirst: outcome.firstMover == Combatant.player,
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
      rounds++;
    }

    if (rounds == 0) return null;
    return CombatRoundResult(
      roundNumber: lastRoundNumber,
      walkedSteps: walked,
      targetSteps: target,
      playerDamage: damage,
      enemyDamage: dealt,
      playerCrit: crit,
      playerDodged: dodged,
      enemyDefeated: enemyDown,
      playerDefeated: playerDown,
      playerActedFirst: actedFirst,
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
    'playerMaxHealth': playerMaxHealth,
    'enemyHealth': enemyHealth,
    'combatSeed': combatSeed,
    'untouchedRounds': untouchedRounds,
    'roundStartingSteps': roundStartingSteps,
    'roundTargetSteps': roundTargetSteps,
    'nextEnemyAttackAt': nextEnemyAttackAt.toIso8601String(),
    'roundDurationSeconds': roundDuration.inSeconds,
    'nextReminderAt': nextReminderAt.toIso8601String(),
    'enemyAttackSerial': enemyAttackSerial,
    'lastEnemyDamage': lastEnemyDamage,
    'lastPlayerDamage': lastPlayerDamage,
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
      playerMaxHealth: json['playerMaxHealth'] as int? ?? maxPlayerHealth,
      enemyHealth: json['enemyHealth'] as int?,
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

  /// Düşmanın kalan canı. Adımdan **bağımsız**; savaş motoru düşürüyor.
  int get remainingEnemyHealth => enemyHealth < 0 ? 0 : enemyHealth;

  /// Düşmanın canının tavanına oranı (0..1). Can barı bunu çiziyor.
  double get enemyHealthProgress {
    final max = enemy.maxHealth;
    if (max <= 0) return 0;
    return (remainingEnemyHealth / max).clamp(0.0, 1.0);
  }

  /// Oyuncunun canının tavanına oranı (0..1).
  double get playerHealthProgress {
    final max = playerMaxHealth <= 0 ? 1 : playerMaxHealth;
    return (playerHealth / max).clamp(0.0, 1.0);
  }

  /// Düşman devrildi mi.
  bool get isEnemyDefeated => enemyHealth <= 0;

  /// Oyuncu düştü mü.
  bool get isPlayerDefeated => playerHealth <= 0;

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

  const CombatRoundResult({
    required this.roundNumber,
    required this.walkedSteps,
    required this.targetSteps,
    required this.playerDamage,
    this.enemyDamage = 0,
    this.playerCrit = false,
    this.playerDodged = false,
    this.enemyDefeated = false,
    this.playerDefeated = false,
    this.playerActedFirst = true,
  });

  bool get targetReached => walkedSteps >= targetSteps;
}
