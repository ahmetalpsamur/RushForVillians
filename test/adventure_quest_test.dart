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

  group('sabit kademe tablosundan round düzeni', () {
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
      // 2.000 adım → 1000–2999 kademesi → 4 × 500 adım, round süresi 5 dk.
      expect(quest.roundTargetSteps, 500);
      expect(
        quest.nextEnemyAttackAt,
        startedAt.add(const Duration(seconds: 107, minutes: 5)),
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
        startedAt.add(const Duration(minutes: 5)),
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

    test('round sayısı ve süresi toplam hedeften türetilir', () {
      final startedAt = DateTime(2026, 8, 17, 12);
      final quest = AdventureQuest(
        enemy: EnemyCatalog.byId('tense_soldier')!,
        stepGoal: 2500,
        startedAt: startedAt,
      );

      expect(quest.currentRoundDuration, const Duration(minutes: 5));
      expect(
        quest.nextEnemyAttackAt,
        startedAt.add(const Duration(minutes: 5)),
      );
      expect(quest.totalRounds, 5);
      expect(quest.totalAttackDuration, const Duration(minutes: 25));
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

      expect(result?.roundNumber, 3);
      expect(quest.roundOutcomeSerial, 3);
      expect(quest.currentRound, 4);
      expect(
        quest.nextEnemyAttackAt,
        startedAt.add(const Duration(minutes: 40)),
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

      expect(result?.walkedSteps, 2500);
      expect(result?.targetSteps, 3000);
      expect(quest.roundStartingSteps, 2500);
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
      expect(quest.roundTargetSteps, 500);
      expect(quest.stepsThisRound(4150), 150);
      expect(quest.roundStepsRemaining(4150), 350);
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

  // --- Bölüm B.2: hasar formülü ORAN'a bakar, mutlak adıma değil ---
  //
  // Round büyüklüğü kademe tablosuyla 250'den 2.000'e çıkıyor. Formül mutlak
  // kaçırılan adıma baksaydı 250'lik roundda 200 adım kaçırmak (%80) ile
  // 2.000'lik roundda 200 adım kaçırmak (%10) aynı cezayı alırdı; küçük
  // düşmanlar orantısız cezalandırılırdı.
  group('hasar formülü oranla ölçülür', () {
    /// Savunması sıfır ölçüm oyuncusu.
    ///
    /// [_durablePlayer]'ın 10.000 savunması gelen her vuruşu en düşük hasara
    /// kırpıyor ve eğri ölçülemiyordu; burada düşmanın vuruşu olduğu gibi
    /// okunmalı. Saldırısı 1 çünkü ölçüm **alınan** hasara bakıyor.
    const probePlayer = CombatStats(
      attack: 1,
      defense: 0,
      maxHealth: 100000,
      speed: 10000,
    );

    /// [stepGoal] hedefli bir maceranın **ilk** roundunu [completion] oranıyla
    /// süresi dolmuş olarak çözer ve oyuncunun aldığı hasarı döner.
    int enemyDamageAt(int stepGoal, double completion) {
      final startedAt = DateTime(2026, 8, 25, 12);
      final quest = AdventureQuest(
        enemy: EnemyCatalog.byId('tense_soldier')!,
        stepGoal: stepGoal,
        startedAt: startedAt,
      );
      final walked = (quest.roundTargetSteps * completion).round();
      final result = quest.resolveExpiredRound(
        walked,
        quest.nextEnemyAttackAt,
        playerStats: probePlayer,
      );
      return result!.playerDamage;
    }

    test('farklı round büyüklüklerinde aynı oran aynı hasarı verir', () {
      // 500 adım → 250'lik round · 2.000 adım → 500'lük round
      // 3.000 adım → 1.000'lik round · 10.000 adım → 2.000'lik round
      const goals = [500, 2000, 3000, 10000];
      const sizes = [250, 500, 1000, 2000];
      for (var i = 0; i < goals.length; i++) {
        expect(
          AdventureQuest(
            enemy: EnemyCatalog.byId('tense_soldier')!,
            stepGoal: goals[i],
          ).roundTargetSteps,
          sizes[i],
        );
      }

      for (final completion in [0.2, 0.5, 0.8]) {
        final damages = goals.map((goal) => enemyDamageAt(goal, completion));
        expect(
          damages.toSet(),
          hasLength(1),
          reason:
              '%${(completion * 100).round()} tamamlama dört round '
              'büyüklüğünde de aynı hasarı vermeli: ${damages.toList()}',
        );
      }
    });

    test('tam tamamlama sıfır hasar, hiç yürümemek tam hasar', () {
      for (final goal in [500, 2000, 10000]) {
        expect(enemyDamageAt(goal, 1), 0, reason: '$goal adım');
        expect(enemyDamageAt(goal, 0), greaterThan(0), reason: '$goal adım');
        expect(
          enemyDamageAt(goal, 0),
          greaterThan(enemyDamageAt(goal, 0.5)),
          reason: '$goal adım: hiç yürümemek yarıdan çok acıtmalı',
        );
      }
    });

    test('az kaçıran orantısız cezalanmaz: eğri dışbükey', () {
      // %90 → %50 arasındaki artış, %50 → %10 arasındakinden küçük olmalı.
      final at90 = enemyDamageAt(2000, 0.9);
      final at50 = enemyDamageAt(2000, 0.5);
      final at10 = enemyDamageAt(2000, 0.1);
      expect(at50 - at90, lessThan(at10 - at50));
    });

    test('roundun büyüklüğü oyuncunun vuruşunu ölçekler', () {
      // Aynı oranı tutturan oyuncu, dört kat büyük bir roundda dört kat
      // vurmalı (GD86) — yoksa büyük roundlu macerada yürümek değersizleşir.
      int playerDamageAt(int stepGoal) {
        final startedAt = DateTime(2026, 8, 25, 12);
        final quest = AdventureQuest(
          enemy: EnemyCatalog.byId('tense_soldier')!,
          stepGoal: stepGoal,
          startedAt: startedAt,
        );
        return quest
            .resolveExpiredRound(
              quest.roundTargetSteps,
              quest.nextEnemyAttackAt,
              playerStats: const CombatStats(
                attack: 100,
                defense: 10000,
                maxHealth: 100000,
                speed: 10000,
              ),
            )!
            .enemyDamage;
      }

      final small = playerDamageAt(500); // 250'lik round → ağırlık 1
      final large = playerDamageAt(3000); // 1.000'lik round → ağırlık 4
      expect(large, greaterThan(small * 3));
      expect(large, lessThan(small * 5));
    });
  });

  group('mükemmel round serisi', () {
    test('erken tamamlamalar seriyi büyütür, üçüncüde ×2 tavanını açar', () {
      final startedAt = DateTime(2026, 8, 20, 12);
      // 1.500 adım → 1000–2999 kademesi → 3 × 500 adım, round süresi 5 dk.
      final quest = AdventureQuest(
        enemy: EnemyCatalog.byId('tense_soldier')!,
        stepGoal: 1500,
        startedAt: startedAt,
      );
      expect(quest.totalRounds, 3);

      for (var round = 1; round <= 3; round++) {
        final result = quest.resolveRound(
          round * 500,
          startedAt.add(Duration(seconds: round)),
          playerStats: _durablePlayer,
        );
        expect(result?.perfect, isTrue);
        expect(result?.perfectStreak, round);
      }

      expect(quest.perfectRoundStreak, 3);
      expect(quest.perfectStreakCap, 2);
      expect(quest.lastPerfectDamageMultiplier, closeTo(2, 0.02));
    });

    test('kaçırılan round seriyi sıfırlar ve kırılmayı işaretler', () {
      final startedAt = DateTime(2026, 8, 20, 12);
      final quest = AdventureQuest(
        enemy: EnemyCatalog.byId('tense_soldier')!,
        stepGoal: 1000,
        startedAt: startedAt,
      );
      // 1.000 adım → 2 × 500 adım; ilk round erken tamamlanıyor.
      expect(quest.roundTargetSteps, 500);
      quest.resolveRound(
        500,
        startedAt.add(const Duration(seconds: 1)),
        playerStats: _durablePlayer,
      );

      final missed = quest.resolveRound(
        500,
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
