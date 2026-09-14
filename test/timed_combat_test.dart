import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/utils/combat_engine.dart';
import 'package:rush_for_villains/data/enemy_catalog.dart';
import 'package:rush_for_villains/models/adventure_quest.dart';
import 'package:rush_for_villains/models/combat_stats.dart';

void main() {
  const player = CombatStats(
    attack: 25,
    defense: 0,
    maxHealth: 100,
    dodge: 0,
    luck: 0,
  );
  const enemy = CombatStats(
    attack: 20,
    defense: 5,
    maxHealth: 80,
  );

  TimedCombatOutcome combat(
    Duration actual, {
    CombatStats playerStats = player,
    int playerHealth = 100,
    int seed = 4242,
    double difficulty = 1,
  }) => resolveTimedCombat(
    player: playerStats,
    enemy: enemy,
    playerHealth: playerHealth,
    enemyHealth: 80,
    expectedDuration: const Duration(minutes: 10),
    actualDuration: actual,
    difficultyMultiplier: difficulty,
    seed: seed,
  );

  group('zamana bağlı tek karşılaşma', () {
    test('hasar eğrisi hızlı, normal, hafif geç ve çok geçte kademeli artar', () {
      final fast = combat(const Duration(minutes: 8));
      final normal = combat(const Duration(minutes: 10));
      final slightlyLate = combat(const Duration(minutes: 13));
      final veryLate = combat(const Duration(minutes: 25));

      expect(fast.combat.damageTaken, lessThan(normal.combat.damageTaken));
      expect(
        normal.combat.damageTaken,
        lessThan(slightlyLate.combat.damageTaken),
      );
      expect(
        slightlyLate.combat.damageTaken,
        lessThan(veryLate.combat.damageTaken),
      );
    });

    test('aynı tohum ve girdiler aynı sonucu üretir', () {
      final first = combat(const Duration(minutes: 13), seed: 77);
      final second = combat(const Duration(minutes: 13), seed: 77);

      expect(first.combat.damageTaken, second.combat.damageTaken);
      expect(first.combat.nextSeed, second.combat.nextSeed);
      expect(first.breakdown.varianceAmount, second.breakdown.varianceAmount);
    });

    test('düşman önce vurur, sağ kalan oyuncu düşmanı öldürür', () {
      final result = combat(const Duration(minutes: 10));

      expect(result.combat.firstMover, Combatant.enemy);
      expect(result.combat.blows.map((blow) => blow.attacker), [
        Combatant.enemy,
        Combatant.player,
      ]);
      expect(result.combat.enemyDefeated, isTrue);
      expect(result.combat.enemyHealthAfter, 0);
    });

    test('ölümcül düşman saldırısından sonra oyuncu vurmaz', () {
      final result = combat(
        const Duration(minutes: 30),
        playerHealth: 40,
      );

      expect(result.combat.playerDefeated, isTrue);
      expect(result.combat.blows, hasLength(1));
      expect(result.combat.blows.single.attacker, Combatant.enemy);
      expect(result.combat.damageDealt, 0);
      expect(result.combat.enemyHealthAfter, 80);
    });

    test('savunma ve zırh gelen hasarı azaltır', () {
      final unarmored = combat(const Duration(minutes: 15));
      final armored = combat(
        const Duration(minutes: 15),
        playerStats: player.copyWith(defense: 100),
      );

      expect(armored.combat.damageTaken, lessThan(unarmored.combat.damageTaken));
    });

    test('macera zorluğu düşman hasarına uygulanır', () {
      final normal = combat(const Duration(minutes: 10));
      final difficult = combat(
        const Duration(minutes: 10),
        difficulty: 1.8,
      );

      expect(difficult.combat.damageTaken, greaterThan(normal.combat.damageTaken));
    });
  });

  test('hedef damgasından sonra beklemek hasarı artırmaz ve damga saklanır', () {
    final startedAt = DateTime(2026, 9, 14, 12);
    final completedAt = startedAt.add(const Duration(minutes: 8));
    final quest = AdventureQuest(
      enemy: EnemyCatalog.enemies.first,
      stepGoal: 500,
      startedAt: startedAt,
      playerHealth: 10000,
      playerMaxHealth: 10000,
      combatSeed: 91,
    );

    expect(quest.resolveTimedEncounter(499, completedAt), isNull);
    expect(quest.stepTargetCompletedAt, isNull);
    expect(quest.recordStepTargetCompletion(500, completedAt), isTrue);
    expect(
      quest.recordStepTargetCompletion(500, completedAt.add(const Duration(days: 2))),
      isFalse,
    );
    final restored = AdventureQuest.fromJson(
      Map<String, dynamic>.from(quest.toJson()),
      enemy: quest.enemy,
    );
    final result = restored.resolveTimedEncounter(
      500,
      completedAt.add(const Duration(days: 2)),
      playerStats: const CombatStats(
        attack: 50,
        defense: 1000,
        maxHealth: 10000,
      ),
    );

    expect(restored.adventureStartedAt, startedAt);
    expect(restored.stepTargetCompletedAt, completedAt);
    expect(result, isNotNull);
    expect(result!.breakdown.actualDuration, const Duration(minutes: 8));
  });
}
