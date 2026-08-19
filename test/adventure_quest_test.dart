import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/data/enemy_catalog.dart';
import 'package:rush_for_villains/models/adventure_quest.dart';

void main() {
  group('macera dengesi', () {
    test('başlangıçtan ileri seviyeye düşman hedefleri 500 artarak başlar', () {
      expect(EnemyCatalog.enemies.map((enemy) => enemy.minimumDailySteps), [
        500,
        1000,
        1500,
        2000,
        5000,
        7000,
        10000,
      ]);
    });

    test('her round için 20 dakika verir', () {
      expect(
        AdventureQuest.roundDurationForSteps(1000),
        const Duration(minutes: 20),
      );
      expect(AdventureQuest.reminderInterval, const Duration(minutes: 5));
    });

    test('1000 adım süre dolmadan tamamlanırsa round anında kazanılır', () {
      final startedAt = DateTime(2026, 8, 17, 12);
      final quest = AdventureQuest(
        enemy: EnemyCatalog.byId('tense_soldier')!,
        stepGoal: 2000,
        startedAt: startedAt,
      );

      final result = quest.resolveRound(
        1000,
        startedAt.add(const Duration(minutes: 8)),
      );

      expect(result?.targetReached, isTrue);
      expect(result?.roundNumber, 1);
      expect(quest.lastRoundWon, isTrue);
      expect(quest.currentRound, 2);
      expect(
        quest.nextEnemyAttackAt,
        startedAt.add(const Duration(minutes: 28)),
      );
    });

    test('eksik adım oranı kadar oyuncu hasarı uygular', () {
      final startedAt = DateTime(2026, 8, 17, 12);
      final quest = AdventureQuest(
        enemy: EnemyCatalog.byId('tense_soldier')!,
        stepGoal: 2000,
        startedAt: startedAt,
      );

      final result = quest.resolveExpiredRound(
        500,
        startedAt.add(const Duration(minutes: 20)),
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
        enemy: EnemyCatalog.byId('sinister_monster')!,
        stepGoal: 5000,
        startedAt: startedAt,
      );

      final result = quest.resolveExpiredRound(
        1000,
        startedAt.add(const Duration(minutes: 10)),
      );

      expect(result?.targetReached, isTrue);
      expect(result?.playerDamage, 0);
      expect(quest.playerHealth, AdventureQuest.maxPlayerHealth);
      expect(quest.roundStartingSteps, 1000);
    });
  });

  // Uygulama arka planda kaldığında birden fazla tur birikir. Tek tur çözüp
  // kalanları affetmek oyuncunun kalıcı savaş canını yanlış bırakıyordu
  // (triaj A1).
  group('biriken tur çözümü', () {
    // sinister_monster: attackDamage 12, round hedefi 1000 adım → 20 dakika.
    AdventureQuest questAt(DateTime startedAt) => AdventureQuest(
      enemy: EnemyCatalog.byId('sinister_monster')!,
      stepGoal: 5000,
      startedAt: startedAt,
    );

    test('arka planda biriken turların hepsi çözülür', () {
      final startedAt = DateTime(2026, 8, 18, 12);
      final quest = questAt(startedAt);

      // 60 dakika arka plan, hiç adım atılmadı: 20, 40 ve 60.
      // dakikalardaki üç round dolmuş olmalı.
      final result = quest.resolveExpiredRounds(
        0,
        startedAt.add(const Duration(minutes: 60)),
      );

      expect(result?.playerDamage, 36, reason: '3 round × 12 hasar');
      expect(quest.playerHealth, 64);
      expect(quest.enemyAttackSerial, 3);
    });

    test('bir sonraki geri sayım geleceğe taşınır', () {
      final startedAt = DateTime(2026, 8, 18, 12);
      final quest = questAt(startedAt);
      final now = startedAt.add(const Duration(minutes: 60));

      quest.resolveExpiredRounds(0, now);

      expect(quest.nextEnemyAttackAt.isAfter(now), isTrue);
      // Sıra `now`'dan değil, dolan sıradan ileri taşınır: 60 + 20 = 80.
      expect(
        quest.nextEnemyAttackAt,
        startedAt.add(const Duration(minutes: 80)),
      );
    });

    test('arka planda atılan adımlar turlara sırayla sayılır', () {
      final startedAt = DateTime(2026, 8, 18, 12);
      final quest = questAt(startedAt);

      // 60 dakikada 2.500 adım: ilk iki round tam, üçüncüsü yarım.
      final result = quest.resolveExpiredRounds(
        2500,
        startedAt.add(const Duration(minutes: 60)),
      );

      expect(result?.walkedSteps, 2500);
      expect(result?.playerDamage, 6);
      expect(quest.playerHealth, 94);
    });

    test('süresi dolmamış turda hiçbir şey olmaz', () {
      final startedAt = DateTime(2026, 8, 18, 12);
      final quest = questAt(startedAt);

      final result = quest.resolveExpiredRounds(
        0,
        startedAt.add(const Duration(minutes: 5)),
      );

      expect(result, isNull);
      expect(quest.playerHealth, AdventureQuest.maxPlayerHealth);
    });

    test('can bitince döngü durur, can eksiye düşmez', () {
      final startedAt = DateTime(2026, 8, 18, 12);
      final quest = questAt(startedAt);

      // 3 gün arka plan: canı bitirmeye fazlasıyla yeter.
      quest.resolveExpiredRounds(0, startedAt.add(const Duration(days: 3)));

      expect(quest.playerHealth, 0);
    });
  });

  // Macera başlatmak günün adımlarını sıfırlamaz; ilerleme
  // [AdventureQuest.startingSteps] farkı üzerinden hesaplanır.
  group('macera başlangıç adımı', () {
    AdventureQuest questAt(int startingSteps, {DateTime? startedAt}) =>
        AdventureQuest(
          enemy: EnemyCatalog.byId('tense_soldier')!,
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
        startedAt.add(const Duration(minutes: 20)),
      );

      expect(result?.walkedSteps, 500);
      expect(result?.playerDamage, 4);
      expect(quest.playerHealth, 96);
      expect(quest.remainingHealth(4500), 1500);
    });

    test('başlangıç adımı verilmezse eski davranış korunur', () {
      final quest = AdventureQuest(
        enemy: EnemyCatalog.byId('tense_soldier')!,
        stepGoal: 2000,
      );

      expect(quest.startingSteps, 0);
      expect(quest.roundStartingSteps, 0);
      expect(quest.remainingHealth(500), 1500);
    });
  });
}
