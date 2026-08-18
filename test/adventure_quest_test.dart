import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/data/enemy_catalog.dart';
import 'package:rush_for_villains/models/adventure_quest.dart';

void main() {
  group('macera dengesi', () {
    test('düşman hedefleri 2000, 5000, 7000 ve 10000 adımdır', () {
      expect(EnemyCatalog.enemies.map((enemy) => enemy.minimumDailySteps), [
        2000,
        5000,
        7000,
        10000,
      ]);
    });

    test('1000 adımlık tura 10 dakika yürüyüş ve 1 dakika pay verir', () {
      expect(
        AdventureQuest.roundDurationForSteps(1000),
        const Duration(minutes: 11),
      );
    });

    test('eksik adım oranı kadar oyuncu hasarı uygular', () {
      final startedAt = DateTime(2026, 8, 17, 12);
      final quest = AdventureQuest(
        enemy: EnemyCatalog.enemies.first,
        stepGoal: 2000,
        startedAt: startedAt,
      );

      final result = quest.resolveExpiredRound(
        500,
        startedAt.add(const Duration(minutes: 11)),
      );

      expect(result?.walkedSteps, 500);
      expect(result?.playerDamage, 4);
      expect(quest.playerHealth, 96);
      expect(quest.remainingHealth(500), 1500);
      expect(quest.enemyAttackSerial, 1);
    });

    test('tur hedefi tamamlanırsa oyuncu hasar almaz', () {
      final startedAt = DateTime(2026, 8, 17, 12);
      final quest = AdventureQuest(
        enemy: EnemyCatalog.enemies[1],
        stepGoal: 5000,
        startedAt: startedAt,
      );

      final result = quest.resolveExpiredRound(
        1000,
        startedAt.add(const Duration(minutes: 11)),
      );

      expect(result?.targetReached, isTrue);
      expect(result?.playerDamage, 0);
      expect(quest.playerHealth, AdventureQuest.maxPlayerHealth);
      expect(quest.roundStartingSteps, 1000);
    });
  });

  // Macera başlatmak günün adımlarını sıfırlamaz; ilerleme
  // [AdventureQuest.startingSteps] farkı üzerinden hesaplanır.
  group('macera başlangıç adımı', () {
    AdventureQuest questAt(int startingSteps, {DateTime? startedAt}) =>
        AdventureQuest(
          enemy: EnemyCatalog.enemies.first,
          stepGoal: 2000,
          startingSteps: startingSteps,
          startedAt: startedAt,
        );

    test('ilerleme günlük sayaçtan değil başlangıç adımından sayılır', () {
      final quest = questAt(4000);

      expect(quest.questSteps(4000), 0);
      expect(quest.questSteps(5000), 1000);
      expect(quest.remainingHealth(4000), 2000);
      expect(quest.remainingHealth(5000), 1000);
      expect(quest.healthProgress(5000), 0.5);
    });

    test('düşman ancak hedef kadar yeni adım atılınca yenilir', () {
      final quest = questAt(4000);

      expect(quest.isDefeated(5999), isFalse);
      expect(quest.isDefeated(6000), isTrue);
    });

    test('ilk tur da başlangıç adımından başlar', () {
      final quest = questAt(4000);

      expect(quest.roundStartingSteps, 4000);
      expect(quest.stepsThisRound(4500), 500);
      expect(quest.roundStepsRemaining(4500), 500);
    });

    test('bekleyen hasar başlangıç adımına göre hesaplanır', () {
      final quest = questAt(4000);

      expect(quest.takePendingDamage(4500), 500);
      expect(quest.takePendingDamage(4700), 200);
      expect(quest.takePendingDamage(4700), 0);
    });

    test('tur çözümü başlangıç adımlı macerada da doğru hasar verir', () {
      final startedAt = DateTime(2026, 8, 18, 12);
      final quest = questAt(4000, startedAt: startedAt);

      final result = quest.resolveExpiredRound(
        4500,
        startedAt.add(const Duration(minutes: 11)),
      );

      expect(result?.walkedSteps, 500);
      expect(result?.playerDamage, 4);
      expect(quest.playerHealth, 96);
      expect(quest.remainingHealth(4500), 1500);
    });

    test('başlangıç adımı verilmezse eski davranış korunur', () {
      final quest = AdventureQuest(
        enemy: EnemyCatalog.enemies.first,
        stepGoal: 2000,
      );

      expect(quest.startingSteps, 0);
      expect(quest.roundStartingSteps, 0);
      expect(quest.remainingHealth(500), 1500);
    });
  });
}
