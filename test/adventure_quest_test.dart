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
}
