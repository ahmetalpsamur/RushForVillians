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

  group('1000 adım ve 15 dakikalık sabit round düzeni', () {
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

    test('aşırı hasar düşmanı planlanan roundların yüzde 60ından önce öldüremez', () {
      final startedAt = DateTime(2026, 8, 17, 12);
      final quest = AdventureQuest(
        enemy: EnemyCatalog.byId('ash_guardian')!,
        stepGoal: 5000,
        startedAt: startedAt,
      );

      expect(quest.totalRounds, 5);
      expect(quest.earliestEnemyDefeatRound, 3);

      for (var round = 1; round < quest.earliestEnemyDefeatRound; round++) {
        final result = quest.resolveRound(
          round * 1000,
          quest.nextEnemyAttackAt.subtract(const Duration(seconds: 1)),
          playerStats: _victoriousPlayer,
        );
        expect(result, isNotNull);
        expect(quest.isEnemyDefeated, isFalse, reason: '$round. round');
        expect(quest.enemyHealth, greaterThan(0));
      }

      quest.resolveRound(
        3000,
        quest.nextEnemyAttackAt.subtract(const Duration(seconds: 1)),
        playerStats: _victoriousPlayer,
      );

      expect(quest.isEnemyDefeated, isTrue);
      expect(quest.victoryRounds, 3);
    });

    test('round sayısı ve süresi toplam hedeften türetilir', () {
      final startedAt = DateTime(2026, 8, 17, 12);
      final quest = AdventureQuest(
        enemy: EnemyCatalog.byId('tense_soldier')!,
        stepGoal: 2500,
        startedAt: startedAt,
      );

      expect(quest.currentRoundDuration, const Duration(minutes: 15));
      expect(
        quest.nextEnemyAttackAt,
        startedAt.add(const Duration(minutes: 15)),
      );
      expect(quest.totalRounds, 3);
      expect(quest.totalAttackDuration, const Duration(minutes: 45));
    });
  });

  group('arka plan catch-up', () {
    AdventureQuest questAt(DateTime startedAt) => AdventureQuest(
      enemy: EnemyCatalog.byId('sinister_monster')!,
      stepGoal: 5000,
      startedAt: startedAt,
    );

    test('biriken türetilmiş roundların hepsi sırayla çözülür', () {
      final startedAt = DateTime(2026, 8, 18, 12);
      final quest = questAt(startedAt);

      final result = quest.resolveExpiredRounds(
        0,
        startedAt.add(const Duration(minutes: 31)),
        playerStats: _durablePlayer,
      );

      expect(result?.roundNumber, 2);
      expect(quest.roundOutcomeSerial, 2);
      expect(quest.currentRound, 3);
      expect(
        quest.nextEnemyAttackAt,
        startedAt.add(const Duration(minutes: 45)),
      );
    });

    test('arka plandaki adımlar round hedeflerine sırayla dağıtılır', () {
      final startedAt = DateTime(2026, 8, 18, 12);
      final quest = questAt(startedAt);

      final result = quest.resolveExpiredRounds(
        2500,
        startedAt.add(const Duration(minutes: 31)),
        playerStats: _durablePlayer,
      );

      expect(result?.walkedSteps, 2000);
      expect(result?.targetSteps, 2000);
      expect(quest.roundStartingSteps, 2000);
    });

    test('süresi dolmamış ilk round state değiştirmez', () {
      final startedAt = DateTime(2026, 8, 18, 12);
      final quest = questAt(startedAt);

      final result = quest.resolveExpiredRounds(
        0,
        startedAt.add(const Duration(minutes: 9, seconds: 59)),
      );

      expect(result, isNull);
      expect(quest.currentRound, 1);
    });
  });

  group('ilerleme, ölçek ve yeniden doğuş', () {
    test('başlangıç adımı düşülür ve round hedefi toplamdan türetilir', () {
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
        walkCoinReward: 17,
      );

      final restored = AdventureQuest.fromJson(quest.toJson(), enemy: enemy);

      expect(restored.isPlayerDefeated, isTrue);
      expect(restored.isRevivalActive, isTrue);
      expect(restored.revivalSteps, 320);
      expect(restored.revivalRemainingSteps, 180);
      expect(restored.victoryXpReward, 175);
      expect(restored.victoryCoinReward, 42);
      expect(restored.walkCoinReward, 17);
      expect(restored.totalCoinReward, 59);
      expect(restored.roundTargetSteps, 0);
    });

    test('son round öncesindeki düşman canı JSON turunda korunur', () {
      final enemy = EnemyCatalog.byId('tense_soldier')!;
      final quest = AdventureQuest(enemy: enemy, stepGoal: 2000)
        ..enemyHealthBeforeLastRound = 73;

      final restored = AdventureQuest.fromJson(quest.toJson(), enemy: enemy);

      expect(restored.enemyHealthBeforeLastRound, 73);
    });
  });

  group('mükemmel round serisi', () {
    test('erken tamamlamalar seriyi büyütür, üçüncüde ×1,02 tavanını açar', () {
      final startedAt = DateTime(2026, 8, 20, 12);
      final quest = AdventureQuest(
        enemy: EnemyCatalog.byId('tense_soldier')!,
        stepGoal: 3000,
        startedAt: startedAt,
      );

      for (var round = 1; round <= 3; round++) {
        final result = quest.resolveRound(
          round * 1000,
          startedAt.add(Duration(seconds: round)),
          playerStats: _durablePlayer,
        );
        expect(result?.perfect, isTrue);
        expect(result?.perfectStreak, round);
      }

      expect(quest.perfectRoundStreak, 3);
      expect(quest.perfectStreakCap, 1.02);
      expect(quest.lastPerfectDamageMultiplier, closeTo(1.02, 0.002));
    });

    test('kaçırılan round seriyi sıfırlar ve kırılmayı işaretler', () {
      final startedAt = DateTime(2026, 8, 20, 12);
      final quest = AdventureQuest(
        enemy: EnemyCatalog.byId('tense_soldier')!,
        stepGoal: 2000,
        startedAt: startedAt,
      );
      quest.resolveRound(
        1000,
        startedAt.add(const Duration(seconds: 1)),
        playerStats: _durablePlayer,
      );

      final missed = quest.resolveRound(
        1000,
        quest.nextEnemyAttackAt,
        playerStats: _durablePlayer,
      );

      expect(missed?.perfect, isFalse);
      expect(quest.perfectRoundStreak, 0);
      expect(quest.lastPerfectStreakBroken, isTrue);
      expect(quest.lastPerfectDamageMultiplier, 1);
    });

    test('seri JSON turunda korunur, yeni maceraya taşınmaz', () {
      final enemy = EnemyCatalog.byId('tense_soldier')!;
      final quest =
          AdventureQuest(enemy: enemy, stepGoal: 1000)
            ..perfectRoundStreak = 2
            ..lastRoundPerfect = true
            ..lastPerfectDamageMultiplier = 1.45;

      final restored = AdventureQuest.fromJson(quest.toJson(), enemy: enemy);
      final nextDayQuest = AdventureQuest(enemy: enemy, stepGoal: 1000);

      expect(restored.perfectRoundStreak, 2);
      expect(restored.lastRoundPerfect, isTrue);
      expect(restored.lastPerfectDamageMultiplier, 1.45);
      expect(nextDayQuest.perfectRoundStreak, 0);
    });
  });
}
