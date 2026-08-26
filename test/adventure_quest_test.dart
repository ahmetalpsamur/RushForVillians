import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/data/enemy_catalog.dart';
import 'package:rush_for_villains/models/adventure_quest.dart';
import 'package:rush_for_villains/models/combat_stats.dart';

const _durablePlayer = CombatStats(
  attack: 1,
  defense: 10000,
  maxHealth: 10000,
  speed: 10000,
);

const _victoriousPlayer = CombatStats(
  attack: 10000,
  defense: 10000,
  maxHealth: 10000,
  speed: 10000,
);

void main() {
  group('macera kataloğu', () {
    test('20 farklı düşman 500 adımlık eşiklerle açılır', () {
      expect(EnemyCatalog.enemies.map((enemy) => enemy.minimumDailySteps), [
        500,
        1000,
        1500,
        2000,
        2500,
        3000,
        3500,
        4000,
        4500,
        5000,
        5500,
        6000,
        6500,
        7000,
        7500,
        8000,
        8500,
        9000,
        9500,
        10000,
      ]);
    });

    test('düşman kimlikleri ve All_Assets animasyonları benzersizdir', () {
      expect(EnemyCatalog.enemies, hasLength(20));
      expect(
        EnemyCatalog.enemies.map((enemy) => enemy.id).toSet(),
        hasLength(20),
      );
      expect(
        EnemyCatalog.enemies.map((enemy) => enemy.name).toSet(),
        hasLength(20),
      );

      for (final enemy in EnemyCatalog.enemies) {
        final assets = [
          enemy.idleAsset,
          enemy.walkAsset,
          enemy.hurtAsset,
          ...enemy.attackAssets,
          enemy.deathAsset,
        ];
        expect(enemy.attackAssets.length, greaterThanOrEqualTo(2));
        expect(
          assets.every((asset) => asset.startsWith('lib/All_Assets/Enemies/')),
          isTrue,
        );
        for (final asset in assets) {
          expect(File(asset).existsSync(), isTrue, reason: 'Eksik: $asset');
        }
      }
    });
  });

  group('eski 1000 adımlık round düzeni', () {
    test('adım hedefi dolunca deadline beklenmeden round geçer', () {
      final startedAt = DateTime(2026, 8, 17, 12);
      final quest = AdventureQuest(
        enemy: EnemyCatalog.byId('tense_soldier')!,
        stepGoal: 2000,
        startedAt: startedAt,
      );

      final early = quest.resolveRound(
        quest.roundTargetSteps,
        startedAt.add(const Duration(seconds: 107)),
        playerStats: _durablePlayer,
      );

      expect(early?.roundNumber, 1);
      expect(early?.targetReached, isTrue);
      expect(quest.currentRound, 2);
      expect(
        quest.nextEnemyAttackAt,
        startedAt.add(const Duration(seconds: 107, minutes: 15)),
      );
    });

    test('hiç yürünmeyen süresi dolmuş round oyuncuya hasar verir', () {
      final startedAt = DateTime(2026, 8, 17, 12);
      final quest = AdventureQuest(
        enemy: EnemyCatalog.byId('tense_soldier')!,
        stepGoal: 2000,
        startedAt: startedAt,
      );

      final result = quest.resolveExpiredRound(
        0,
        startedAt.add(const Duration(minutes: 15)),
      );

      expect(result, isNotNull);
      expect(result!.enemyDamage, 0, reason: 'yürümeyen vuramaz');
      expect(result.playerDamage, greaterThan(0));
      expect(quest.enemyHealth, quest.scaledEnemyMaxHealth);
    });

    test('düşman ölünce zafer hemen kesinleşir', () {
      final startedAt = DateTime(2026, 8, 17, 12);
      final quest = AdventureQuest(
        enemy: EnemyCatalog.byId('tense_soldier')!,
        stepGoal: 500,
        startedAt: startedAt,
      );

      quest.resolveExpiredRound(
        quest.roundTargetSteps,
        startedAt.add(const Duration(seconds: 45)),
        playerStats: _victoriousPlayer,
      );

      expect(quest.enemyDefeatPending, isFalse);
      expect(quest.isEnemyDefeated, isTrue);
      expect(quest.battleOutcome, AdventureBattleOutcome.victory);
      expect(quest.enemyHealth, 0);
    });

    test('round süresi sabit 15 dakikadır', () {
      final startedAt = DateTime(2026, 8, 17, 12);
      final quest = AdventureQuest(
        enemy: EnemyCatalog.byId('tense_soldier')!,
        stepGoal: 2500,
        startedAt: startedAt,
      );

      expect(AdventureQuest.roundDuration, const Duration(minutes: 15));
      expect(quest.currentRoundDuration, const Duration(minutes: 15));
      expect(
        quest.nextEnemyAttackAt,
        startedAt.add(const Duration(minutes: 15)),
      );
      expect(quest.totalRounds, 3);
    });
  });

  group('arka plan catch-up', () {
    AdventureQuest questAt(DateTime startedAt) => AdventureQuest(
      enemy: EnemyCatalog.byId('sinister_monster')!,
      stepGoal: 5000,
      startedAt: startedAt,
    );

    test('biriken 15 dakikalık roundların hepsi sırayla çözülür', () {
      final startedAt = DateTime(2026, 8, 18, 12);
      final quest = questAt(startedAt);

      final result = quest.resolveExpiredRounds(
        0,
        startedAt.add(const Duration(minutes: 46)),
        playerStats: _durablePlayer,
      );

      expect(result?.roundNumber, 3);
      expect(quest.roundOutcomeSerial, 3);
      expect(quest.currentRound, 4);
      expect(
        quest.nextEnemyAttackAt,
        startedAt.add(const Duration(minutes: 60)),
      );
    });

    test('arka plandaki adımlar round hedeflerine sırayla dağıtılır', () {
      final startedAt = DateTime(2026, 8, 18, 12);
      final quest = questAt(startedAt);

      final result = quest.resolveExpiredRounds(
        2500,
        startedAt.add(const Duration(minutes: 46)),
        playerStats: _durablePlayer,
      );

      expect(result?.walkedSteps, 2500);
      expect(result?.targetSteps, 3000);
      expect(quest.roundStartingSteps, 2500);
    });

    test('süresi dolmamış ilk round state değiştirmez', () {
      final startedAt = DateTime(2026, 8, 18, 12);
      final quest = questAt(startedAt);

      final result = quest.resolveExpiredRounds(
        0,
        startedAt.add(const Duration(minutes: 14, seconds: 59)),
      );

      expect(result, isNull);
      expect(quest.currentRound, 1);
    });
  });

  group('ilerleme, ölçek ve yeniden doğuş', () {
    test('başlangıç adımı düşülür ve round hedefi 1000 adımdır', () {
      final quest = AdventureQuest(
        enemy: EnemyCatalog.byId('tense_soldier')!,
        stepGoal: 2000,
        startingSteps: 4000,
      );

      expect(quest.questSteps(4000), 0);
      expect(quest.questSteps(5000), 1000);
      expect(quest.roundStartingSteps, 4000);
      expect(quest.roundTargetSteps, 1000);
      expect(quest.stepsThisRound(4150), 150);
      expect(quest.roundStepsRemaining(4150), 850);
    });

    test('düşman canı hedefe göre ölçeklenmez', () {
      final quest = AdventureQuest(
        enemy: EnemyCatalog.byId('tense_soldier')!,
        stepGoal: 2000,
      );

      expect(quest.enemyPowerMultiplier, 1);
      expect(quest.enemyHealth, quest.scaledEnemyMaxHealth);
      expect(quest.enemyHealth, quest.enemy.maxHealth);
      expect(quest.enemyHealthProgress, 1);
    });

    test('çıplak can sıfırı terminal sonuç yerine geçmez', () {
      final quest = AdventureQuest(
        enemy: EnemyCatalog.byId('tense_soldier')!,
        stepGoal: 2000,
      );
      quest.enemyHealth = 0;

      expect(quest.isEnemyDefeated, isFalse);
      expect(quest.battleOutcome, AdventureBattleOutcome.active);
    });

    test('Hayat Yürüyüşü yalnız yenilgide açılır ve 500 adımda biter', () {
      final quest = AdventureQuest(
        enemy: EnemyCatalog.byId('tense_soldier')!,
        stepGoal: 500,
        battleOutcome: AdventureBattleOutcome.defeat,
        playerHealth: 0,
      );

      expect(quest.startRevival(), isTrue);
      expect(quest.addRevivalSteps(499), 499);
      expect(quest.revivalCompleted, isFalse);
      expect(quest.addRevivalSteps(10), 1);
      expect(quest.revivalCompleted, isTrue);
      expect(quest.revivalSteps, AdventureQuest.revivalStepTarget);
    });

    test('revival ve terminal sonuç JSON turunda korunur', () {
      final enemy = EnemyCatalog.byId('tense_soldier')!;
      final quest = AdventureQuest(
        enemy: enemy,
        stepGoal: 500,
        battleOutcome: AdventureBattleOutcome.defeat,
        playerHealth: 0,
        revivalStarted: true,
        revivalSteps: 320,
        victoryXpReward: 175,
        victoryCoinReward: 42,
      );

      final restored = AdventureQuest.fromJson(quest.toJson(), enemy: enemy);

      expect(restored.isPlayerDefeated, isTrue);
      expect(restored.isRevivalActive, isTrue);
      expect(restored.revivalSteps, 320);
      expect(restored.revivalRemainingSteps, 180);
      expect(restored.victoryXpReward, 175);
      expect(restored.victoryCoinReward, 42);
      expect(restored.roundTargetSteps, 0);
    });
  });
}
