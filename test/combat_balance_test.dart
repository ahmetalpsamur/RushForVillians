import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/attack_config.dart';
import 'package:rush_for_villains/core/utils/base_combat_stats.dart';
import 'package:rush_for_villains/core/utils/combat_engine.dart';
import 'package:rush_for_villains/core/utils/effective_stats.dart';
import 'package:rush_for_villains/core/utils/enemy_stats.dart';
import 'package:rush_for_villains/core/utils/equipped_buffs.dart';
import 'package:rush_for_villains/data/enemy_catalog.dart';
import 'package:rush_for_villains/models/combat_stats.dart';
import 'package:rush_for_villains/models/enemy.dart';
import 'package:rush_for_villains/models/item.dart';
import 'package:rush_for_villains/models/item_effect.dart';
import 'package:rush_for_villains/models/reward_rarity.dart';
import 'package:rush_for_villains/models/streak_stat_bonuses.dart';

/// Savaş dengesi ve stat kaynakları (Bölüm 7).
///
/// Buradaki sayılar prosa tahmini değil: her iddia motorun kendisi
/// çalıştırılarak ölçülüyor. Denge sabitlerinden biri değişirse bu dosya
/// alarm verir.
void main() {
  /// [player] statlarıyla [enemy]'yi devirmek kaç round sürer.
  ///
  /// [completion] her roundun tamamlanma oranı. Sonsuz döngüye karşı üst
  /// sınır var.
  int roundsToKill(
    CombatStats player,
    Enemy enemy, {
    double completion = 1,
    int seed = 12345,
  }) {
    var playerHp = player.maxHealth.round();
    var enemyHp = enemy.maxHealth;
    var currentSeed = seed;
    var rounds = 0;
    while (enemyHp > 0 && playerHp > 0 && rounds < 500) {
      final outcome = resolveCombatRound(
        player: player,
        enemy: enemy.stats,
        playerHealth: playerHp,
        enemyHealth: enemyHp,
        completion: completion,
        seed: currentSeed,
      );
      playerHp = outcome.playerHealthAfter;
      enemyHp = outcome.enemyHealthAfter;
      currentSeed = outcome.nextSeed;
      rounds++;
    }
    return rounds;
  }

  /// [roundsToKill]'in hedefe göre ölçeklenmiş statlarla çalışan eşi.
  ///
  /// Katalogdaki [Enemy.stats] yalnızca önizlemenin tabanı; hedef dengesi
  /// ölçülürken `enemyStatsForGoal` çıktısı kullanılmalı.
  int roundsToKillStats(
    CombatStats player,
    CombatStats enemy,
    int enemyHealth, {
    int seed = 12345,
  }) {
    var playerHp = player.maxHealth.round();
    var enemyHp = enemyHealth;
    var currentSeed = seed;
    var rounds = 0;
    while (enemyHp > 0 && playerHp > 0 && rounds < 400) {
      final outcome = resolveCombatRound(
        player: player,
        enemy: enemy,
        playerHealth: playerHp,
        enemyHealth: enemyHp,
        completion: 1,
        seed: currentSeed,
      );
      playerHp = outcome.playerHealthAfter;
      enemyHp = outcome.enemyHealthAfter;
      currentSeed = outcome.nextSeed;
      rounds++;
    }
    return rounds;
  }

  /// Hiç yürümeyen oyuncu kaç roundda düşer.
  int roundsToDie(CombatStats player, Enemy enemy, {int seed = 999}) {
    var playerHp = player.maxHealth.round();
    var currentSeed = seed;
    var rounds = 0;
    while (playerHp > 0 && rounds < 500) {
      final outcome = resolveCombatRound(
        player: player,
        enemy: enemy.stats,
        playerHealth: playerHp,
        enemyHealth: enemy.maxHealth,
        completion: 0,
        seed: currentSeed,
      );
      playerHp = outcome.playerHealthAfter;
      currentSeed = outcome.nextSeed;
      rounds++;
    }
    return rounds;
  }

  int expectedRounds(Enemy enemy) => expectedRoundsForTier(enemy.tier);

  group('düşman kataloğu', () {
    test('20 düşman, hepsinin savaş statı ve arketipi var', () {
      expect(EnemyCatalog.enemies, hasLength(20));
      for (final enemy in EnemyCatalog.enemies) {
        expect(enemy.maxHealth, greaterThan(0), reason: enemy.name);
        expect(enemy.stats.attack, greaterThan(0), reason: enemy.name);
        expect(enemy.stats.speed, greaterThan(0), reason: enemy.name);
      }
    });

    test('dört arketipin hepsi katalogda var', () {
      final used = EnemyCatalog.enemies.map((e) => e.archetype).toSet();
      expect(used, EnemyArchetype.values.toSet());
    });

    test('kademe yükseldikçe düşman canı ve saldırısı büyür', () {
      // Arketip dalgalanmasını dışarıda bırakmak için aynı arketip
      // karşılaştırılıyor.
      for (final archetype in EnemyArchetype.values) {
        final sameKind =
            EnemyCatalog.enemies
                .where((enemy) => enemy.archetype == archetype)
                .toList()
              ..sort((a, b) => a.tier.compareTo(b.tier));
        for (var i = 1; i < sameKind.length; i++) {
          expect(
            sameKind[i].maxHealth,
            greaterThan(sameKind[i - 1].maxHealth),
            reason: '${sameKind[i].name} canı önceki kademeden düşük',
          );
        }
      }
    });

    test('kademe yükseldikçe saldırı hedefi büyür', () {
      // Katalogdaki elle yazılmış saldırı farkı **korunduğu** için ham
      // değerler her zaman artmıyor (13. kademedeki Eyeball Monster bilerek
      // zayıf). Kademenin kendi hedefi ise her adımda büyümeli.
      double targetFor(int tier) =>
          enemyCombatStats(
            tier: tier,
            archetype: EnemyArchetype.bruiser,
            catalogAttackDamage: expectedCatalogAttack(tier).round(),
          ).attack;

      for (var tier = 2; tier <= 20; tier++) {
        expect(
          targetFor(tier),
          greaterThan(targetFor(tier - 1)),
          reason: '$tier. kademe saldırı hedefi büyümüyor',
        );
      }
    });

    test('arketip aynı kademede statların şeklini değiştirir', () {
      const tier = 10;
      CombatStats statsFor(EnemyArchetype archetype) => enemyCombatStats(
        tier: tier,
        archetype: archetype,
        catalogAttackDamage: 17,
      );

      final bruiser = statsFor(EnemyArchetype.bruiser);
      final tank = statsFor(EnemyArchetype.tank);
      final swift = statsFor(EnemyArchetype.swift);
      final caster = statsFor(EnemyArchetype.caster);

      expect(tank.maxHealth, greaterThan(bruiser.maxHealth));
      expect(tank.speed, lessThan(bruiser.speed));
      expect(swift.speed, greaterThan(bruiser.speed));
      expect(swift.dodge, greaterThan(bruiser.dodge));
      expect(caster.attack, greaterThan(bruiser.attack));
      expect(caster.maxHealth, lessThan(bruiser.maxHealth));
      expect(caster.critChance, greaterThan(bruiser.critChance));
    });

    test('katalogdaki elle yazılmış saldırı farkı korunur', () {
      // 13. kademedeki Eyeball Monster bilerek zayıf bırakılmış
      // (attackDamage 12, kademe beklentisi 20). Bu fark statlara da yansımalı.
      final weak = EnemyCatalog.byId('eye_of_nothing')!;
      final reference = enemyCombatStats(
        tier: weak.tier,
        archetype: weak.archetype,
        catalogAttackDamage: expectedCatalogAttack(weak.tier).round(),
      );
      expect(weak.stats.attack, lessThan(reference.attack));
    });
  });

  group('hedef dengesi (Bölüm D / Faz 1)', () {
    // Altı hedef `AttackConfig.targets`'tan okunuyor — sabit kopyalanmıyor.
    final goals = AttackConfig.supportedStepTargets;

    test('DOMİNANS YOK: büyük hedef hem kolay hem çok ödüllü olamaz', () {
      // **Zorunlu değişmez.** Aynı oyun kalitesinde daha büyük bir hedef,
      // hem daha kolay hem daha çok ödül veren bir seçenek olamaz — yoksa
      // küçük hedefleri seçmek için sebep kalmaz.
      //
      // Bu test, "ham can hedefte monoton" değişmezinin **yerine geçti**
      // (GD107). Can artık planlanan round sayısıyla orantılı, yani 3.000
      // hedefinin düşmanı 2.000'inkinden daha az **cana** sahip olabilir —
      // çünkü oyuncunun da daha az roundu var. Ölçülmesi gereken şey ham
      // can değil, **zorluk**.
      final goals = AttackConfig.supportedStepTargets;
      final loads = <int, double>{};

      for (final goal in goals) {
        var worst = 0.0;
        for (final enemy in EnemyCatalog.enemies) {
          final player = baseCombatStats(enemy.tier < 1 ? 1 : enemy.tier);
          final stats = enemyStatsForGoal(enemy: enemy, stepGoal: goal);
          final planned = AttackConfig.roundCountForSteps(goal);
          final load =
              stats.maxHealth /
              (stats.damageAfterDefense(player.attack) * planned);
          if (load > worst) worst = load;
        }
        loads[goal] = worst;
      }

      // 1) Altı hedefin yükü **aynı**: hiçbiri diğerinden kolay değil.
      final reference = loads[goals.first]!;
      for (final goal in goals) {
        expect(
          loads[goal],
          closeTo(reference, 0.02),
          reason:
              '$goal hedefinin yükü ${loads[goal]}, '
              '${goals.first} hedefininki $reference',
        );
      }

      // 2) Ödül çarpanı hedef büyüdükçe **asla azalmaz**.
      var previousReward = 0.0;
      for (final goal in goals) {
        final reward = AttackConfig.rewardMultiplierFor(goal);
        expect(
          reward,
          greaterThanOrEqualTo(previousReward),
          reason: '$goal hedefinin ödül çarpanı geriye gidiyor',
        );
        previousReward = reward;
      }

      // 3) Hiçbir hedef **seçilmeyecek kadar kötü** değil: her hedef kendi
      //    adım aralığı için en iyi seçenek olmalı. Ölçüt adım başına
      //    ödül çarpanı: daha büyük hedefi seçen oyuncu daha çok yürüyor,
      //    karşılığında adım başına en az aynı değeri almalı.
      for (var i = 1; i < goals.length; i++) {
        final small = goals[i - 1];
        final large = goals[i];
        expect(
          AttackConfig.rewardMultiplierFor(large) /
              AttackConfig.rewardMultiplierFor(small),
          greaterThanOrEqualTo(0.99),
          reason:
              '$large hedefi $small ile aynı zorlukta ama daha az ödüllü',
        );
      }
    });

    test('ekipmanlı yük hedef bandinda, çıplak oyuncu taşmıyor', () {
      // Hedef bant: ekipmanlı **0,60–0,85**. Çıplak oyuncu (hiç eşya
      // kuşanmamış, kademeye denk seviyede) taşmamalı — taahhüdünden fazla
      // yürümemeli.
      //
      // Ekipmanın gerçek katkısı `ItemCatalog` istiyor ve test ortamında
      // asset manifesti yok; bu yüzden burada **çıplak** yük ölçülüyor ve
      // bant, ölçülmüş ekipman avantajının (en kötü durumda ×1,31)
      // altından türetiliyor.
      for (final goal in AttackConfig.supportedStepTargets) {
        var worst = 0.0;
        for (final enemy in EnemyCatalog.enemies) {
          final player = baseCombatStats(enemy.tier < 1 ? 1 : enemy.tier);
          final stats = enemyStatsForGoal(enemy: enemy, stepGoal: goal);
          final planned = AttackConfig.roundCountForSteps(goal);
          final load =
              stats.maxHealth /
              (stats.damageAfterDefense(player.attack) * planned);
          if (load > worst) worst = load;
        }
        expect(
          worst,
          lessThan(1.0),
          reason: '$goal hedefinde çıplak oyuncu taahhüdünden fazla yürüyor',
        );
        // En kötü ekipman avantajı ×1,31 (20. kademe, 3 slot).
        expect(
          worst / 1.31,
          inInclusiveRange(0.55, 0.85),
          reason: '$goal hedefinde ekipmanlı yük bandin dışında',
        );
      }
    });

    test('güç çarpanı yalnızca saldırıya giriyor', () {
      // GD101: hedef cana **iki kez** girmemeli. Can adım taahhüdünden,
      // tehlike çarpandan geliyor.
      for (final enemy in EnemyCatalog.enemies.take(5)) {
        for (final goal in goals) {
          final scaled = enemyStatsForGoal(enemy: enemy, stepGoal: goal);
          final base = enemyBaseStatsForGoal(enemy: enemy, stepGoal: goal);
          expect(
            scaled.maxHealth,
            closeTo(base.maxHealth, 0.001),
            reason: '${enemy.name} $goal: can çarpandan etkilenmemeli',
          );
          final multiplier = scaled.attack / base.attack;
          expect(
            multiplier,
            closeTo(AttackConfig.forStepTarget(goal).enemyPowerMultiplier, 0.01),
            reason: '${enemy.name} $goal: saldırı çarpanı uygulanmamış',
          );
        }
      }
    });

    test('çıplak seviye-uygun oyuncu planlanan roundların içinde bitirir', () {
      // "Seviye-uygun" tanımı can formülünün kendi varsayımı: kademeye
      // denk seviyedeki ölçüt oyuncu (§6.10). Mükemmel round bonusu
      // **verilmiyor** — roundu tam ama süresi dolarken bitiren oyuncu.
      for (final enemy in EnemyCatalog.enemies) {
        final player = baseCombatStats(enemy.tier < 1 ? 1 : enemy.tier);
        for (final goal in goals) {
          final stats = enemyStatsForGoal(enemy: enemy, stepGoal: goal);
          final planned = AttackConfig.roundCountForSteps(goal);
          final rounds = roundsToKillStats(
            player,
            stats,
            stats.maxHealth.round(),
          );
          expect(
            rounds,
            lessThanOrEqualTo(planned),
            reason:
                '${enemy.name} $goal hedefinde $rounds round istiyor, '
                'planlanan $planned — oyuncu taahhüdünden fazla yürüyor',
          );
        }
      }
    });

    test('yük oranı bandların içinde sabit ve 1,0\'ın altında', () {
      // Sürekli ölçü: can / (round başına hasar × planlanan round).
      // Tam sayı round sayan ölçü düşük round sayılarında marjı gizliyor.
      final worst = <int, double>{};
      for (final enemy in EnemyCatalog.enemies) {
        final player = baseCombatStats(enemy.tier < 1 ? 1 : enemy.tier);
        for (final goal in goals) {
          final stats = enemyStatsForGoal(enemy: enemy, stepGoal: goal);
          final planned = AttackConfig.roundCountForSteps(goal);
          final perRound = stats.damageAfterDefense(player.attack);
          final load = stats.maxHealth / (perRound * planned);
          if (load > (worst[goal] ?? 0)) worst[goal] = load;
        }
      }
      for (final goal in goals) {
        expect(
          worst[goal],
          lessThan(1.0),
          reason: '$goal hedefinde çıplak yük ${worst[goal]}',
        );
      }
      // Tempo tablosunun iki bandı round boyu 500 ve 1.000; yani yük bant
      // içinde sabit, bantlar arasında iki katına çıkıyor. Sayılar
      // kopyalanmıyor, tablodan türetiliyor.
      for (final goal in goals) {
        final other = goals.firstWhere(
          (g) =>
              g != goal &&
              AttackConfig.roundStepsFor(g) ==
                  AttackConfig.roundStepsFor(goal),
          orElse: () => goal,
        );
        if (other == goal) continue;
        expect(
          worst[goal],
          closeTo(worst[other]!, 0.06),
          reason: 'aynı bantta ($goal / $other) yük ayrışıyor',
        );
      }
    });
  });

  group('kademe dengesi', () {
    test('kendi kademesindeki oyuncu her düşmanı makul sürede devirir', () {
      for (final enemy in EnemyCatalog.enemies) {
        final player = baseCombatStats(enemy.tier);
        final rounds = roundsToKill(player, enemy);
        final expected = expectedRounds(enemy);

        expect(
          rounds,
          greaterThanOrEqualTo(1),
          reason: '${enemy.name} tek vuruşta bile ölmüyor olamaz',
        );
        // Arketip bandı: dayanıklı düşman uzatır, cam top kısaltır.
        expect(
          rounds,
          lessThanOrEqualTo(expected + 3),
          reason:
              '${enemy.name} (${enemy.archetype.name}) çok uzun sürüyor: '
              '$rounds round, beklenen $expected',
        );
      }
    });

    test('tam yürüyen oyuncu hiç hasar almaz', () {
      for (final enemy in EnemyCatalog.enemies) {
        final player = baseCombatStats(enemy.tier);
        final outcome = resolveCombatRound(
          player: player,
          enemy: enemy.stats,
          playerHealth: player.maxHealth.round(),
          enemyHealth: enemy.maxHealth,
          completion: 1,
          seed: 31,
        );
        expect(outcome.damageTaken, 0, reason: enemy.name);
      }
    });

    test('hiç yürümeyen oyuncu her kademede benzer sürede düşer', () {
      for (final enemy in EnemyCatalog.enemies) {
        final player = baseCombatStats(enemy.tier);
        final rounds = roundsToDie(player, enemy);
        // Hedef ~7 round (missedRoundHealthCost = %15). Bant, arketip ve
        // katalog saldırı farkını içine alacak kadar geniş.
        expect(
          rounds,
          inInclusiveRange(4, 12),
          reason: '${enemy.name}: $rounds round',
        );
      }
    });

    test('güçlü oyuncu düşmanı erken devirir', () {
      // Bölüm 8'in yürüyüş fazının zemini: seviye farkı savaşı kısaltmalı.
      final enemy = EnemyCatalog.byId('black_claw')!;
      final matched = roundsToKill(baseCombatStats(enemy.tier), enemy);
      final overLevelled = roundsToKill(
        baseCombatStats(enemy.tier + 25),
        enemy,
      );
      expect(overLevelled, lessThan(matched));
    });

    test('düşük seviyeli oyuncu üst kademede zorlanır', () {
      final enemy = EnemyCatalog.enemies.last;
      final weak = baseCombatStats(1);
      final matched = baseCombatStats(enemy.tier);
      expect(
        roundsToKill(weak, enemy),
        greaterThan(roundsToKill(matched, enemy)),
      );
    });
  });

  group('stat kaynakları savaşa işliyor', () {
    Item swordWith(List<ItemEffect> effects) => Item(
      id: 'swords/test_blade',
      name: 'Test Kılıcı',
      assetPath: 'lib/Items/swords/test_blade.png',
      category: ItemCategory.swords,
      rarity: RewardRarity.legendary,
      requiredLevel: 1,
      cost: 1000,
      lore: 'Test için dövüldü.',
      buff: ItemBuff(effects),
      archetype: ItemArchetype.striker,
    );

    test('ekipmanın sabit katkısı statı büyütür', () {
      final plain = effectiveCombatStats(level: 5, buffs: EquippedBuffs.none);
      final armed = effectiveCombatStats(
        level: 5,
        buffs: EquippedBuffs.from([
          swordWith(const [ItemEffect.flat(stat: ItemStat.attack, value: 25)]),
        ]),
      );
      expect(armed.attack, plain.attack + 25);
    });

    test('ekipmanın oransal katkısı sabit katkının üstüne çarpan gelir', () {
      final armed = effectiveCombatStats(
        level: 5,
        buffs: EquippedBuffs.from([
          swordWith(const [
            ItemEffect.flat(stat: ItemStat.attack, value: 10),
            ItemEffect(stat: ItemStat.attack, value: 0.5),
          ]),
        ]),
      );
      final base = baseCombatStats(5);
      expect(armed.attack, closeTo((base.attack + 10) * 1.5, 0.001));
    });

    test('seri bonusu savaş statını büyütür', () {
      // 10 gün x +%1 (eski oran) yerine doğrudan +%10 birikim: bu test
      // seri bonusunun statlara **işlediğini** ölçüyor, basamak tablosunu
      // değil (o `streak_stat_bonus_test.dart` içinde).
      final streak = StreakStatBonuses.empty.withGrant(ItemStat.attack, 100);
      final plain = effectiveCombatStats(level: 5, buffs: EquippedBuffs.none);
      final streaked = effectiveCombatStats(
        level: 5,
        buffs: EquippedBuffs.none,
        streak: streak,
      );
      expect(streaked.attack, closeTo(plain.attack * 1.1, 0.001));
    });

    test('seri bonusu ekonomi statlarına dokunmaz', () {
      final streak = StreakStatBonuses.empty.withGrant(ItemStat.attack, 200);
      final buffs = EquippedBuffs.from([
        swordWith(const [ItemEffect(stat: ItemStat.stepCoin, value: 0.1)]),
      ]);
      final withStreak = effectiveCombatStats(
        level: 5,
        buffs: buffs,
        streak: streak,
      );
      // Ekonomi çarpanı `EquippedBuffs` üzerinden okunuyor ve seriden
      // etkilenmiyor; efektif savaş statlarında ekonomi statı hiç yok.
      expect(buffs.stepCoinMultiplier, closeTo(1.1, 0.001));
      expect(withStreak.statFor(ItemStat.stepCoin), 0);
    });

    test('seri bonusu gerçekten savaşı kısaltır', () {
      final enemy = EnemyCatalog.byId('ember_heir')!;
      // Tavan kalktı (Bölüm B); "uzun seri" artık bir sayı, bir sınır değil.
      final streak = StreakStatBonuses.empty.withGrant(ItemStat.attack, 250);
      final plain = effectiveCombatStats(
        level: enemy.tier,
        buffs: EquippedBuffs.none,
      );
      final streaked = effectiveCombatStats(
        level: enemy.tier,
        buffs: EquippedBuffs.none,
        streak: streak,
      );
      expect(
        roundsToKill(streaked, enemy),
        lessThanOrEqualTo(roundsToKill(plain, enemy)),
      );
      expect(streaked.attack, greaterThan(plain.attack));
    });

    test('koşullu etki yalnızca koşul sağlanınca sayılır', () {
      final buffs = EquippedBuffs.from([
        swordWith(const [
          ItemEffect(
            stat: ItemStat.attack,
            value: 0.4,
            trigger: ItemEffectTrigger.lowHealth,
            threshold: 0.3,
          ),
        ]),
      ]);
      final healthy = effectiveCombatStats(
        level: 5,
        buffs: buffs,
        conditions: const CombatConditions(healthRatio: 0.9),
      );
      final wounded = effectiveCombatStats(
        level: 5,
        buffs: buffs,
        conditions: const CombatConditions(healthRatio: 0.2),
      );
      expect(healthy.attack, baseCombatStats(5).attack);
      expect(wounded.attack, greaterThan(healthy.attack));
    });

    test('gece ve seri tetikleyicileri de çalışıyor', () {
      final buffs = EquippedBuffs.from([
        swordWith(const [
          ItemEffect(
            stat: ItemStat.attack,
            value: 0.3,
            trigger: ItemEffectTrigger.nightWalk,
          ),
          ItemEffect(
            stat: ItemStat.defense,
            value: 0.3,
            trigger: ItemEffectTrigger.streakActive,
          ),
        ]),
      ]);
      final day = effectiveCombatStats(level: 5, buffs: buffs);
      final night = effectiveCombatStats(
        level: 5,
        buffs: buffs,
        conditions: const CombatConditions(nightWalk: true, streakActive: true),
      );
      expect(night.attack, greaterThan(day.attack));
      expect(night.defense, greaterThan(day.defense));
    });

    test('eşik tetikleyicisi tur sayısına bakar', () {
      final buffs = EquippedBuffs.from([
        swordWith(const [
          ItemEffect(
            stat: ItemStat.attack,
            value: 0.5,
            trigger: ItemEffectTrigger.untouchedRounds,
            threshold: 3,
          ),
        ]),
      ]);
      final early = effectiveCombatStats(
        level: 5,
        buffs: buffs,
        conditions: const CombatConditions(untouchedRounds: 2),
      );
      final earned = effectiveCombatStats(
        level: 5,
        buffs: buffs,
        conditions: const CombatConditions(untouchedRounds: 3),
      );
      expect(earned.attack, greaterThan(early.attack));
    });

    test('onHit ve onKill etkileri pasif çarpana girmez', () {
      final buffs = EquippedBuffs.from([
        swordWith(const [
          ItemEffect(
            stat: ItemStat.attack,
            value: 2,
            trigger: ItemEffectTrigger.onHit,
            chance: 0.2,
          ),
          ItemEffect(
            stat: ItemStat.attack,
            value: 2,
            trigger: ItemEffectTrigger.onKill,
          ),
        ]),
      ]);
      final stats = effectiveCombatStats(level: 5, buffs: buffs);
      expect(stats.attack, baseCombatStats(5).attack);
      expect(triggeredEffects(buffs, ItemEffectTrigger.onHit), hasLength(1));
      expect(triggeredEffects(buffs, ItemEffectTrigger.onKill), hasLength(1));
    });

    test('eksi değerli etki statı sıfırın altına indirmez', () {
      final stats = effectiveCombatStats(
        level: 1,
        buffs: EquippedBuffs.from([
          swordWith(const [
            ItemEffect.flat(stat: ItemStat.attack, value: -9999),
          ]),
        ]),
      );
      expect(stats.attack, greaterThanOrEqualTo(0));
      expect(stats.maxHealth, greaterThanOrEqualTo(1));
    });
  });
}
