import 'dart:math';

import '../constants/game_constants.dart';
import '../constants/timed_combat_config.dart';
import '../../models/combat_stats.dart';
import '../../models/item_effect.dart';

/// Savaş motoru — **saf ve deterministik**.
///
/// ## Determinizm neden şart
///
/// CLAUDE.md §4.4: aynı motor Aşama 6b'de takım savaşları için **sunucuda**
/// çalışacak. İstemci ile sunucu aynı girdiden farklı sonuç üretirse ya hile
/// kapısı açılır ya da savaş sistemi ikinci kez yazılır.
///
/// Bu yüzden burada `Random()` **yok**: rastgeleliğin tamamı dışarıdan
/// verilen [seed]'den gelir ve tohum sonuçla birlikte geri döner
/// ([CombatRoundOutcome.nextSeed]). Tohum maceranın durumuyla birlikte diske
/// yazılıyor ([AdventureQuest.combatSeed]), yani uygulamayı kapatıp açmak zar
/// attırmaz. İzlenen desen çarkınkiyle aynı (GD18).
///
/// ## Adım ↔ savaş bağı
///
/// Oyun adım tabanlı; savaş da öyle kalmalı. Bir roundun **tamamlanma oranı**
/// (`yürünen / hedef`) iki işi birden yapıyor:
///
/// - Oyuncunun vuruşu bu oranla ölçekleniyor: hedefi tam tutturan tam vurur.
/// - Düşmanın vuruşu **kaçırılan** oranla ölçekleniyor: hiç yürümeyen tam
///   yer.
///
/// Yani hedefi tutturmak yalnızca hasardan kaçmak değil, hasar vermek demek.
/// Bu, motordan önceki davranışın (tam round = hasar yok) korunmuş hâli.
///
/// ## Tur akışı
///
/// 1. **İnisiyatif**: hızı yüksek olan önce vurur; eşitlikte oyuncu.
///    Öldürücü turlarda belirleyici — ölen taraf karşılık veremez.
/// 2. **Sıyrılma**: savunanın [CombatStats.effectiveDodge] ihtimaliyle vuruş
///    boşa gider.
/// 3. **Kritik**: [CombatStats.effectiveCritChance] ihtimaliyle hasar
///    `1 + critDamage` ile çarpılır.
/// 4. **Değişkenlik**: hasar ±[damageVariance] bandında sallanır; şans bandı
///    yukarı kaydırır.
/// 5. **Savunma**: `hasar × (1 - savunma/(savunma+50))`.
/// 6. **Can çalma**: verilen hasarın [CombatStats.lifeSteal] kadarı geri
///    alınır.
/// 7. Savunan öldüyse ikinci vuruş yapılmaz.

/// Hasarın rastgele sallanma bandı (±%12).
///
/// Sıfır olsaydı her tur birebir aynı sayı çıkardı ve savaş bir tabloya
/// dönerdi; büyük olsaydı stat farkı gürültüye boğulurdu.
const double damageVariance = 0.12;

/// Şansın değişkenlik bandını yukarı kaydırma katsayısı (şans başına).
///
/// 40 şansta band tamamen yukarı kayar; tavanı bu yüzden var.
const double luckToVarianceShift = 0.0125;

/// Hasar tavanı uygulanmayan bir vuruşun en düşük değeri.
const int minimumDamage = 1;

class TimedCombatBreakdown {
  final Duration expectedDuration;
  final Duration actualDuration;
  final double completionRatio;
  final double enemyBaseDamage;
  final double timeMultiplier;
  final double difficultyMultiplier;
  final double varianceAmount;
  final int finalEnemyDamage;

  const TimedCombatBreakdown({
    required this.expectedDuration,
    required this.actualDuration,
    required this.completionRatio,
    required this.enemyBaseDamage,
    required this.timeMultiplier,
    required this.difficultyMultiplier,
    required this.varianceAmount,
    required this.finalEnemyDamage,
  });
}

class TimedCombatOutcome {
  final CombatRoundOutcome combat;
  final TimedCombatBreakdown breakdown;

  const TimedCombatOutcome({required this.combat, required this.breakdown});
}

/// Resolves the target encounter. The enemy always acts first. If the player
/// survives, their existing attack/death presentation receives a lethal hit.
/// Waiting after [actualDuration] was recorded cannot affect this result.
TimedCombatOutcome resolveTimedCombat({
  required CombatStats player,
  required CombatStats enemy,
  required int playerHealth,
  required int enemyHealth,
  required Duration expectedDuration,
  required Duration actualDuration,
  required double difficultyMultiplier,
  required int seed,
  List<ItemEffect> onKillEffects = const [],
}) {
  final safePlayer = player.sanitized();
  final safeEnemy = enemy.sanitized();
  final expectedMicros = max(1, expectedDuration.inMicroseconds);
  final actualMicros = max(0, actualDuration.inMicroseconds);
  final ratio = actualMicros / expectedMicros;
  final timeMultiplier = TimedCombatConfig.timeMultiplier(ratio);
  var currentSeed = seed <= 0 ? 1 : seed;
  double roll() {
    final value = Random(currentSeed).nextDouble();
    currentSeed = nextCombatSeed(currentSeed);
    return value;
  }

  final dodge = roll() < safePlayer.effectiveDodge;
  final varianceAmount = (roll() * 2 - 1) * TimedCombatConfig.variance;
  final rawDamage =
      safeEnemy.attack *
      difficultyMultiplier.clamp(0.1, 10.0) *
      timeMultiplier *
      (1 + varianceAmount);
  final reducedDamage = safePlayer.damageAfterDefense(rawDamage).round();
  final enemyDamage = dodge
      ? 0
      : reducedDamage.clamp(minimumDamage, 1 << 30);
  final playerAfterEnemy = max(0, playerHealth - enemyDamage);
  final blows = <CombatBlow>[
    CombatBlow(
      attacker: Combatant.enemy,
      damage: enemyDamage,
      critical: false,
      dodged: dodge,
      healed: 0,
      lethal: playerAfterEnemy <= 0,
    ),
  ];

  var playerAfterCombat = playerAfterEnemy;
  var enemyAfterCombat = enemyHealth;
  var playerDamage = 0;
  var killHeal = 0;
  if (playerAfterEnemy > 0) {
    playerDamage = max(0, enemyHealth);
    enemyAfterCombat = 0;
    var healed = (playerDamage * safePlayer.lifeSteal).round();
    final missingBeforeKillEffects =
        safePlayer.maxHealth.round() - playerAfterCombat;
    for (final effect in onKillEffects) {
      if (effect.stat != ItemStat.lifeSteal &&
          effect.stat != ItemStat.maxHealth) {
        continue;
      }
      killHeal += effect.mode == ItemEffectMode.flat
          ? effect.value.round()
          : (missingBeforeKillEffects * effect.value).round();
    }
    healed += killHeal;
    playerAfterCombat = min(
      safePlayer.maxHealth.round(),
      playerAfterCombat + max(0, healed),
    );
    blows.add(
      CombatBlow(
        attacker: Combatant.player,
        damage: playerDamage,
        critical: false,
        dodged: false,
        healed: max(0, healed),
        lethal: true,
      ),
    );
  }

  final combat = CombatRoundOutcome(
    blows: List.unmodifiable(blows),
    killHeal: killHeal,
    playerHealthAfter: playerAfterCombat,
    enemyHealthAfter: enemyAfterCombat,
    damageDealt: playerDamage,
    damageTaken: enemyDamage,
    enemyDefeated: enemyAfterCombat <= 0,
    playerDefeated: playerAfterCombat <= 0,
    firstMover: Combatant.enemy,
    nextSeed: currentSeed,
  );
  return TimedCombatOutcome(
    combat: combat,
    breakdown: TimedCombatBreakdown(
      expectedDuration: expectedDuration,
      actualDuration: actualDuration,
      completionRatio: ratio,
      enemyBaseDamage: safeEnemy.attack,
      timeMultiplier: timeMultiplier,
      difficultyMultiplier: difficultyMultiplier,
      varianceAmount: varianceAmount,
      finalEnemyDamage: enemyDamage,
    ),
  );
}

/// Round tamamlama oranını düşman hasar ölçeğine çevirir.
///
/// Eğri hafif dışbükeydir: `%90 → %50` tamamlama arasındaki hasar farkı,
/// `%50 → %10` arasındakinden küçüktür. Sınırlar kesindir: tamamlama 1 ise
/// sıfır, 0 ise tam hasar.
double enemyDamageScaleForCompletion(double completion) {
  final ratio = completion.isNaN ? 0.0 : completion.clamp(0.0, 1.0);
  return pow(1 - ratio, GameConstants.missedRoundDamageExponent).toDouble();
}

/// Mükemmel roundun erken bitirme ve seri kaynaklı hasar çarpanı.
///
/// [earlyFraction] round süresinin bitiş anında kalan oranıdır (0..1).
/// Seri, erişilebilecek tavanı ×1,01 → ×1,015 → ×1,02 büyütür; hedefe son anda
/// ulaşmak küçük, çok erken ulaşmak tavana yakın bonus verir.
double perfectRoundDamageMultiplier({
  required int streak,
  required double earlyFraction,
}) {
  if (streak <= 0) return 1;
  final caps = GameConstants.perfectRoundStreakMultipliers;
  final cap = caps[(streak - 1).clamp(0, caps.length - 1)];
  final early = earlyFraction.isNaN ? 0.0 : earlyFraction.clamp(0.0, 1.0);
  return 1 + (cap - 1) * early;
}

/// Tohumu bir sonraki adıma ilerletir.
///
/// Çarkla (`nextWheelSeed`) ve seri bonusuyla (`nextStreakSeed`) aynı LCG,
/// **ayrı** akış: üçünün sırası birbirini etkilememeli, yoksa oyuncu bir
/// sistemi kullanarak diğerinin zarını kaydırabilir.
int nextCombatSeed(int seed) => (seed * 1103515245 + 12345) & 0x7FFFFFFF;

/// Savaşanlardan biri.
enum Combatant { player, enemy }

/// Tek bir vuruşun sonucu.
class CombatBlow {
  final Combatant attacker;

  /// Gerçekten uygulanan hasar (sıyrıldıysa 0).
  final int damage;

  final bool critical;
  final bool dodged;

  /// Can çalmayla geri alınan can.
  final int healed;

  /// Bu vuruş savunanı devirdi mi.
  final bool lethal;

  const CombatBlow({
    required this.attacker,
    required this.damage,
    required this.critical,
    required this.dodged,
    required this.healed,
    required this.lethal,
  });
}

/// Bir savaş turunun tam sonucu.
class CombatRoundOutcome {
  /// Vuruşlar, gerçekleşme sırasında. Savunan ilk vuruşta öldüyse tek eleman.
  final List<CombatBlow> blows;

  final int playerHealthAfter;
  final int enemyHealthAfter;

  /// Turda oyuncunun verdiği toplam hasar.
  final int damageDealt;

  /// Turda oyuncunun aldığı toplam hasar.
  final int damageTaken;

  final bool enemyDefeated;
  final bool playerDefeated;

  /// Turu kimin açtığı.
  final Combatant firstMover;

  /// Bir sonraki tur için ilerletilmiş tohum.
  final int nextSeed;

  /// Düşman devrildiğinde `onKill` etkilerinden gelen iyileşme.
  final int killHeal;

  const CombatRoundOutcome({
    required this.blows,
    this.killHeal = 0,
    required this.playerHealthAfter,
    required this.enemyHealthAfter,
    required this.damageDealt,
    required this.damageTaken,
    required this.enemyDefeated,
    required this.playerDefeated,
    required this.firstMover,
    required this.nextSeed,
  });

  bool get playerCrit =>
      blows.any((blow) => blow.attacker == Combatant.player && blow.critical);

  bool get playerDodged =>
      blows.any((blow) => blow.attacker == Combatant.enemy && blow.dodged);
}

/// Bir savaş turunu çözer.
///
/// [completion] roundun tamamlanma oranı (0..1): `yürünenAdım / hedefAdım`.
/// [onHitEffects] oyuncunun vuruş anında tetiklenen etkileri; her biri kendi
/// [ItemEffect.chance] ihtimaliyle, aynı tohum akışından çözülür.
CombatRoundOutcome resolveCombatRound({
  required CombatStats player,
  required CombatStats enemy,
  required int playerHealth,
  required int enemyHealth,
  required double completion,
  required int seed,
  double playerDamageMultiplier = 1,
  int? maxPlayerDamage,
  List<ItemEffect> onHitEffects = const [],
  List<ItemEffect> onKillEffects = const [],
}) {
  final ratio = completion.isNaN ? 0.0 : completion.clamp(0.0, 1.0);
  var currentSeed = seed;
  double roll() {
    final value = Random(currentSeed).nextDouble();
    currentSeed = nextCombatSeed(currentSeed);
    return value;
  }

  var playerHp = playerHealth;
  var enemyHp = enemyHealth;
  final blows = <CombatBlow>[];
  var dealt = 0;
  var taken = 0;

  // İnisiyatif: hızı yüksek olan önce. Eşitlikte oyuncu — beraberlikte
  // savunanın değil saldıranın lehine karar vermek, oyuncuyu cezalandırmamak
  // için.
  final playerFirst = player.speed >= enemy.speed;
  final order =
      playerFirst
          ? [Combatant.player, Combatant.enemy]
          : [Combatant.enemy, Combatant.player];

  for (final attacker in order) {
    if (playerHp <= 0 || enemyHp <= 0) break;

    final isPlayer = attacker == Combatant.player;
    final attackerStats = isPlayer ? player : enemy;
    final defenderStats = isPlayer ? enemy : player;
    // Oyuncu yürüdüğü kadar vurur. Düşmanın eksik oranı hafif eğrili bir
    // cezaya dönüşür; az kaçıran oyuncu orantısız hasar yemez.
    final scale =
        isPlayer
            ? ratio * playerDamageMultiplier.clamp(1.0, double.infinity)
            : enemyDamageScaleForCompletion(ratio);

    if (scale <= 0) continue;

    // 1) Sıyrılma
    final dodged = roll() < defenderStats.effectiveDodge;
    if (dodged) {
      blows.add(
        CombatBlow(
          attacker: attacker,
          damage: 0,
          critical: false,
          dodged: true,
          healed: 0,
          lethal: false,
        ),
      );
      continue;
    }

    // 2) Kritik
    final critical = roll() < attackerStats.effectiveCritChance;

    // 3) Değişkenlik — şans bandı yukarı kaydırır.
    final shift = (attackerStats.luck * luckToVarianceShift).clamp(0.0, 1.0);
    final varianceRoll = roll() * (1 - shift) + shift;
    final varianceFactor = 1 + (varianceRoll - 0.5) * 2 * damageVariance;

    var raw = attackerStats.attack * scale * varianceFactor;
    if (critical) raw *= 1 + attackerStats.critDamage;

    // 4) Vuruş anında tetiklenen etkiler (yalnızca oyuncu tarafında).
    if (isPlayer) {
      for (final effect in onHitEffects) {
        if (effect.stat != ItemStat.attack) continue;
        if (roll() >= effect.chance) continue;
        raw +=
            effect.mode == ItemEffectMode.flat
                ? effect.value * scale
                : attackerStats.attack * scale * effect.value;
      }
    }

    // 5) Bitirici vuruş: `onKill` etkileri **öldürücü** vuruşa katılır.
    //
    // Savaş düşman ölünce bittiği için "düşman yenince +X" bir sonraki tura
    // uygulanamaz — uygulanacak tur yok. Bunun yerine: normal hasar yetmiyor
    // ama `onKill` bonusuyla yetiyorsa, o bonus devreye girer ve vuruş
    // bitirici olur. Böylece etki gerçekten bir şey yapar ve söz verdiği anda
    // (düşman yenilirken) çalışır.
    if (isPlayer && onKillEffects.isNotEmpty) {
      var bonus = 0.0;
      for (final effect in onKillEffects) {
        switch (effect.stat) {
          case ItemStat.attack:
            bonus +=
                effect.mode == ItemEffectMode.flat
                    ? effect.value * scale
                    : attackerStats.attack * scale * effect.value;
          case ItemStat.critDamage:
            if (critical) bonus += raw * effect.value;
          default:
            break;
        }
      }
      if (bonus > 0) {
        final plain = defenderStats.damageAfterDefense(raw).round();
        final boosted = defenderStats.damageAfterDefense(raw + bonus).round();
        if (plain < enemyHp && boosted >= enemyHp) raw += bonus;
      }
    }

    // 6) Savunma
    final reduced = defenderStats.damageAfterDefense(raw);
    final uncappedDamage = reduced.round().clamp(minimumDamage, 1 << 30);
    final damage =
        isPlayer && maxPlayerDamage != null
            ? min(uncappedDamage, maxPlayerDamage.clamp(0, 1 << 30))
            : uncappedDamage;

    if (isPlayer) {
      enemyHp -= damage;
      dealt += damage;
    } else {
      playerHp -= damage;
      taken += damage;
    }

    // 7) Can çalma
    var healed = 0;
    if (attackerStats.lifeSteal > 0) {
      healed = (damage * attackerStats.lifeSteal).round();
      if (healed > 0) {
        if (isPlayer) {
          playerHp = min(playerHp + healed, player.maxHealth.round());
        } else {
          enemyHp = min(enemyHp + healed, enemy.maxHealth.round());
        }
      }
    }

    final lethal = isPlayer ? enemyHp <= 0 : playerHp <= 0;
    blows.add(
      CombatBlow(
        attacker: attacker,
        damage: damage,
        critical: critical,
        dodged: false,
        healed: healed,
        lethal: lethal,
      ),
    );
  }

  // Düşman devrildiyse `onKill` iyileştirmeleri uygulanır.
  //
  // `lifeSteal` ve `maxHealth` statlı `onKill` etkileri "kaybettiğin canın
  // %N'i geri gelir" sözünü veriyor; kaybedilen can üzerinden hesaplanıyor.
  var killHeal = 0;
  if (enemyHp <= 0 && playerHp > 0) {
    final maxHp = player.maxHealth.round();
    final missing = maxHp - playerHp;
    if (missing > 0) {
      for (final effect in onKillEffects) {
        if (effect.stat != ItemStat.lifeSteal &&
            effect.stat != ItemStat.maxHealth) {
          continue;
        }
        killHeal +=
            effect.mode == ItemEffectMode.flat
                ? effect.value.round()
                : (missing * effect.value).round();
      }
    }
    if (killHeal > 0) playerHp = min(playerHp + killHeal, maxHp);
  }

  return CombatRoundOutcome(
    blows: List.unmodifiable(blows),
    killHeal: killHeal,
    playerHealthAfter: playerHp < 0 ? 0 : playerHp,
    enemyHealthAfter: enemyHp < 0 ? 0 : enemyHp,
    damageDealt: dealt,
    damageTaken: taken,
    enemyDefeated: enemyHp <= 0,
    playerDefeated: playerHp <= 0,
    firstMover: order.first,
    nextSeed: currentSeed,
  );
}
