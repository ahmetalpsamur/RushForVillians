import '../core/constants/game_constants.dart';
import '../core/utils/combat_engine.dart';
import '../core/utils/endless_rules.dart';
import '../core/utils/game_clock.dart';
import '../core/utils/item_rules.dart';
import 'combat_stats.dart';
import 'enemy.dart';
import 'item_effect.dart';

/// Sonsuz Koşunun otoriter sonucu.
enum EndlessRunOutcome {
  /// Koşu sürüyor.
  active,

  /// Oyuncu "Macerayı bitir" dedi — **tam** banka ödenir.
  banked,

  /// Oyuncu düştü — bankanın bir kısmı ödenir, asla sıfır değil.
  defeated,
}

/// Bir adım partisinin sonsuz koşuya etkisi.
class EndlessStepResult {
  /// Bu partide devrilen canavar sayısı.
  final int cuts;

  /// Bu partide oyuncunun aldığı toplam hasar.
  final int damageTaken;

  /// Oyuncu bu partide düştü mü.
  final bool defeated;

  const EndlessStepResult({
    required this.cuts,
    required this.damageTaken,
    required this.defeated,
  });

  static const none = EndlessStepResult(
    cuts: 0,
    damageTaken: 0,
    defeated: false,
  );

  bool get isEmpty => cuts == 0 && damageTaken == 0 && !defeated;
}

/// Sonsuz Koşu durumu.
///
/// **`AdventureQuest`'ten bilerek ayrı bir model** (Bölüm C / Faz 3): macera
/// `stepGoal`'a, `AttackConfig`'e ve zafer damgasına bağlı; sonsuz koşuda
/// bunların hiçbiri yok. Aynı sınıfa sığdırmak hem `AdventureQuest`'i hem
/// ona dayanan ~15 testi riske atardı.
///
/// Model Kuralları #1 temiz: hiçbir Flutter tipi yok, `Enemy` katalogdan
/// çözülüyor, diske yalnızca kimlik ve sayılar yazılıyor.
class EndlessRun {
  /// Sabit: bu modun canavarı eyeball monster.
  static const String enemyId = 'eye_of_nothing';

  final Enemy enemy;
  final String backgroundAsset;

  /// Mod başladığı anda günlük adım sayacının değeri. İlerleme bunun
  /// üstünden hesaplanır — macerada `startingSteps` ile aynı desen.
  final int startingSteps;

  final DateTime startedAt;

  /// Devrilen canavar sayısı. Bütün eğriler bundan türüyor.
  int cutCount;

  /// Bu canavara karşı yürünen adım.
  int stepsIntoCut;

  /// Bu roundun başladığı andaki koşu-içi adım.
  int roundStartingSteps;

  DateTime nextEnemyAttackAt;

  /// Kesimlerde biriken ödül. Çarpan **kesim anında** uygulanmıştır.
  int bankedCoins;
  int bankedXp;

  int playerHealth;
  int playerMaxHealth;

  /// Savaş rastgeleliğinin tohumu (GD50). `0` = henüz kurulmadı.
  int combatSeed;

  int lastEnemyDamage;

  /// Her düşman vuruşunda artar; ekran animasyonu buna bakar.
  int enemyAttackSerial;

  /// Her kesimde artar; yeni canavarın giriş animasyonu buna bakar.
  int cutSerial;

  EndlessRunOutcome outcome;

  /// Koşu bitince verilen eşyanın katalog kimliği.
  String? rewardItemId;
  int? rewardItemInstanceId;

  /// Bitişte gerçekten ödenen altın/XP. Ekran bunu gösterir.
  int paidCoins;
  int paidXp;

  EndlessRun({
    required this.enemy,
    this.backgroundAsset = 'lib/Backgrounds/versionA_platform.png',
    this.startingSteps = 0,
    DateTime? startedAt,
    this.cutCount = 0,
    this.stepsIntoCut = 0,
    int? roundStartingSteps,
    DateTime? nextEnemyAttackAt,
    this.bankedCoins = 0,
    this.bankedXp = 0,
    int? playerHealth,
    this.playerMaxHealth = 100,
    this.combatSeed = 0,
    this.lastEnemyDamage = 0,
    this.enemyAttackSerial = 0,
    this.cutSerial = 0,
    this.outcome = EndlessRunOutcome.active,
    this.rewardItemId,
    this.rewardItemInstanceId,
    this.paidCoins = 0,
    this.paidXp = 0,
  }) : startedAt = startedAt ?? GameClock.now(),
       // Can verilmezse tavana eşitlenir: koşu tam canla başlamalı.
       playerHealth = playerHealth ?? playerMaxHealth,
       roundStartingSteps = roundStartingSteps ?? 0,
       nextEnemyAttackAt =
           nextEnemyAttackAt ??
           (startedAt ?? GameClock.now()).add(
             const Duration(seconds: GameConstants.endlessRoundSeconds),
           );

  // --- Türetilenler ---

  bool get isActive => outcome == EndlessRunOutcome.active;
  bool get isDefeated => outcome == EndlessRunOutcome.defeated;
  bool get isFinished => outcome != EndlessRunOutcome.active;

  /// Şu anki canavarın canı (adım).
  int get monsterHealthSteps => endlessMonsterHealthAt(cutCount);

  int get stepsRemainingInCut =>
      (monsterHealthSteps - stepsIntoCut).clamp(0, monsterHealthSteps);

  double get cutProgress =>
      monsterHealthSteps <= 0
          ? 0
          : (stepsIntoCut / monsterHealthSteps).clamp(0.0, 1.0);

  double get multiplier => endlessMultiplierAt(cutCount);
  double get spriteScale => endlessSpriteScaleAt(cutCount);
  double get damageMultiplier => endlessDamageMultiplierAt(cutCount);

  double get playerHealthProgress =>
      playerMaxHealth <= 0
          ? 0
          : (playerHealth / playerMaxHealth).clamp(0.0, 1.0);

  /// Koşu boyunca yürünen toplam adım.
  int runSteps(int currentSteps) =>
      (currentSteps - startingSteps).clamp(0, 1 << 30);

  /// Bu roundda yürünen adım.
  int stepsThisRound(int currentSteps) =>
      (runSteps(currentSteps) - roundStartingSteps).clamp(
        0,
        GameConstants.endlessRoundSteps,
      );

  Duration countdownRemaining(DateTime now) {
    final remaining = nextEnemyAttackAt.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Şu anda bitirilirse ödenecek altın. "Şimdi bitir mi, devam mı"
  /// sorusunun ekranda gösterilen tarafı.
  int get payoutCoinsIfBanked => bankedCoins;
  int get payoutCoinsIfDefeated => endlessDefeatPayout(bankedCoins);

  // --- Mutasyonlar ---

  /// Adım partisini işler: kesimleri sayar, bankayı büyütür.
  ///
  /// Düşman hasarı burada **verilmez** — o zamana bağlı ve
  /// [resolveExpiredRounds] içinde. Bu ayrım macerayla aynı: adım ilerlemeyi,
  /// saat cezayı yürütüyor.
  int addSteps(int amount, int currentSteps) {
    if (!isActive || amount <= 0) return 0;
    var cuts = 0;
    var remaining = amount;
    while (remaining > 0) {
      final need = stepsRemainingInCut;
      if (need <= 0) break;
      final consumed = remaining < need ? remaining : need;
      stepsIntoCut += consumed;
      remaining -= consumed;
      if (stepsIntoCut >= monsterHealthSteps) {
        // Kesim: ödül **bu kesimin** çarpanıyla bankaya yazılır.
        bankedCoins += endlessCutCoins(cutCount);
        bankedXp += endlessCutXp(cutCount);
        cutCount += 1;
        cutSerial += 1;
        stepsIntoCut = 0;
        cuts += 1;
      }
    }
    return cuts;
  }

  /// Süresi dolmuş roundları çözer; eksik yürünen her round hasar getirir.
  ///
  /// Hasar hesabı **paylaşılan** `combat_engine` üzerinden: ikinci bir savaş
  /// matematiği yazılmıyor (§10 ilke 3). Motorun oyuncuya verdirdiği hasar
  /// yok sayılıyor — bu modda canavarı adım deviriyor, stat değil.
  EndlessStepResult resolveExpiredRounds(
    int currentSteps,
    DateTime now, {
    required CombatStats playerStats,
    List<ItemEffect> onHitEffects = const [],
  }) {
    if (!isActive) return EndlessStepResult.none;
    var damage = 0;
    var guard = 0;
    while (!now.isBefore(nextEnemyAttackAt) && guard < 500) {
      guard++;
      final walked = stepsThisRound(currentSteps);
      final completion = walked / GameConstants.endlessRoundSteps;

      if (combatSeed == 0) {
        // Tohum kurulmadan round çözülürse kararlı bir yedek kurulur
        // (`hashCode` değil, GD8).
        combatSeed = stableSpread('endless|$enemyId|$startingSteps', 0x7FFFFFF0) + 1;
      }
      final stats = playerStats.sanitized();

      final outcome = resolveCombatRound(
        player: stats,
        enemy: enemyCombatStatsForCut(),
        playerHealth: playerHealth,
        // Canavarın canı adımla ölçülüyor; motorun onu öldürmemesi için
        // erişilemez bir değer veriliyor. Motorun `damageDealt` çıktısı
        // bu modda **kullanılmıyor**.
        enemyHealth: 1 << 24,
        completion: completion,
        seed: combatSeed,
        onHitEffects: onHitEffects,
      );
      combatSeed = outcome.nextSeed;
      playerHealth = outcome.playerHealthAfter.clamp(0, playerMaxHealth);
      if (outcome.damageTaken > 0) {
        damage += outcome.damageTaken;
        lastEnemyDamage = outcome.damageTaken;
        enemyAttackSerial += 1;
      }

      roundStartingSteps += walked;
      nextEnemyAttackAt = nextEnemyAttackAt.add(
        const Duration(seconds: GameConstants.endlessRoundSeconds),
      );

      if (playerHealth <= 0) {
        this.outcome = EndlessRunOutcome.defeated;
        return EndlessStepResult(
          cuts: 0,
          damageTaken: damage,
          defeated: true,
        );
      }
    }
    return EndlessStepResult(cuts: 0, damageTaken: damage, defeated: false);
  }

  /// Oyuncunun can tavanını güncel statlarla tazeler.
  ///
  /// **Bedava iyileşme yok** (GD53 ile aynı kural): tavan büyüyünce mevcut
  /// can yükselmez, yalnızca tavan küçülürse kırpılır. Aksi hâlde koşu
  /// ortasında eşya takıp çıkarmak tam iyileşme verirdi.
  void syncPlayerStats(CombatStats stats) {
    final resolved = stats.sanitized();
    playerMaxHealth = resolved.maxHealth.round();
    if (playerHealth > playerMaxHealth) playerHealth = playerMaxHealth;
  }

  /// Şu anki kesimin düşman statları: katalog tabanı + kesim hasar çarpanı.
  CombatStats enemyCombatStatsForCut() =>
      enemy.stats.copyWith(attack: enemy.stats.attack * damageMultiplier);

  /// "Macerayı bitir": tam banka ödenir.
  bool bank() {
    if (!isActive) return false;
    outcome = EndlessRunOutcome.banked;
    paidCoins = bankedCoins;
    paidXp = bankedXp;
    return true;
  }

  /// Yenilgi ödemesi. Ayrı bir çağrı: `resolveExpiredRounds` durumu
  /// değiştiriyor, ödemeyi `RootShell` tek noktadan yapıyor.
  void settleDefeat() {
    if (outcome != EndlessRunOutcome.defeated) return;
    paidCoins = endlessDefeatPayout(bankedCoins);
    paidXp = endlessDefeatPayout(bankedXp);
  }

  // --- Kalıcılık ---

  Map<String, dynamic> toJson() => {
    'enemyId': enemy.id,
    'backgroundAsset': backgroundAsset,
    'startingSteps': startingSteps,
    'startedAt': startedAt.toIso8601String(),
    'cutCount': cutCount,
    'stepsIntoCut': stepsIntoCut,
    'roundStartingSteps': roundStartingSteps,
    'nextEnemyAttackAt': nextEnemyAttackAt.toIso8601String(),
    'bankedCoins': bankedCoins,
    'bankedXp': bankedXp,
    'playerHealth': playerHealth,
    'playerMaxHealth': playerMaxHealth,
    'combatSeed': combatSeed,
    'lastEnemyDamage': lastEnemyDamage,
    'enemyAttackSerial': enemyAttackSerial,
    'cutSerial': cutSerial,
    'outcome': outcome.name,
    'rewardItemId': rewardItemId,
    'rewardItemInstanceId': rewardItemInstanceId,
    'paidCoins': paidCoins,
    'paidXp': paidXp,
  };

  static EndlessRun? fromJson(Map<String, dynamic> json, Enemy enemy) {
    DateTime? parse(Object? value) =>
        value is String ? DateTime.tryParse(value) : null;
    return EndlessRun(
      enemy: enemy,
      backgroundAsset:
          json['backgroundAsset'] as String? ??
          'lib/Backgrounds/versionA_platform.png',
      startingSteps: json['startingSteps'] as int? ?? 0,
      startedAt: parse(json['startedAt']),
      cutCount: (json['cutCount'] as int? ?? 0).clamp(0, 1 << 20),
      stepsIntoCut: (json['stepsIntoCut'] as int? ?? 0).clamp(0, 1 << 20),
      roundStartingSteps: json['roundStartingSteps'] as int? ?? 0,
      nextEnemyAttackAt: parse(json['nextEnemyAttackAt']),
      bankedCoins: json['bankedCoins'] as int? ?? 0,
      bankedXp: json['bankedXp'] as int? ?? 0,
      playerHealth: json['playerHealth'] as int? ?? 100,
      playerMaxHealth: json['playerMaxHealth'] as int? ?? 100,
      combatSeed: json['combatSeed'] as int? ?? 0,
      lastEnemyDamage: json['lastEnemyDamage'] as int? ?? 0,
      enemyAttackSerial: json['enemyAttackSerial'] as int? ?? 0,
      cutSerial: json['cutSerial'] as int? ?? 0,
      outcome: _outcomeFrom(json['outcome']),
      rewardItemId: json['rewardItemId'] as String?,
      rewardItemInstanceId: json['rewardItemInstanceId'] as int?,
      paidCoins: json['paidCoins'] as int? ?? 0,
      paidXp: json['paidXp'] as int? ?? 0,
    );
  }

  static EndlessRunOutcome _outcomeFrom(Object? value) {
    for (final outcome in EndlessRunOutcome.values) {
      if (outcome.name == value) return outcome;
    }
    return EndlessRunOutcome.active;
  }
}
