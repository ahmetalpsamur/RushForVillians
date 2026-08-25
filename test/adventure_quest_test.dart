import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/data/enemy_catalog.dart';
import 'package:rush_for_villains/models/adventure_quest.dart';

void main() {
  group('macera dengesi', () {
    test('20 farklı düşman hedefi 500 adımlık aralıklarla açılır', () {
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

    test('her düşman farklı ve bütün All_Assets animasyonları mevcut', () {
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
        expect(
          enemy.attackAssets.length,
          greaterThanOrEqualTo(2),
          reason: '${enemy.name} için saldırı çeşitliliği yetersiz',
        );
        expect(
          assets.every((asset) => asset.startsWith('lib/All_Assets/Enemies/')),
          isTrue,
          reason: '${enemy.name} eski Enemies klasörünü kullanıyor',
        );
        for (final asset in assets) {
          expect(File(asset).existsSync(), isTrue, reason: 'Eksik: $asset');
        }
      }
    });

    test('test dengesi her round için 30 saniye verir', () {
      expect(
        AdventureQuest.roundDurationForSteps(1000),
        const Duration(seconds: 30),
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
        startedAt.add(const Duration(seconds: 10)),
      );

      expect(result?.targetReached, isTrue);
      expect(result?.roundNumber, 1);
      expect(quest.lastRoundWon, isTrue);
      expect(quest.currentRound, 2);
      expect(
        quest.nextEnemyAttackAt,
        startedAt.add(const Duration(seconds: 40)),
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
        startedAt.add(const Duration(seconds: 30)),
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
        startedAt.add(const Duration(seconds: 10)),
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
    // sinister_monster: attackDamage 12, round hedefi 1000 adım → 30 saniye.
    AdventureQuest questAt(DateTime startedAt) => AdventureQuest(
      enemy: EnemyCatalog.byId('sinister_monster')!,
      stepGoal: 5000,
      startedAt: startedAt,
    );

    test('arka planda biriken turların hepsi çözülür', () {
      final startedAt = DateTime(2026, 8, 18, 12);
      final quest = questAt(startedAt);

      // 90 saniye arka plan, hiç adım atılmadı: 30, 60 ve 90.
      // saniyelerdeki üç round dolmuş olmalı.
      final result = quest.resolveExpiredRounds(
        0,
        startedAt.add(const Duration(seconds: 90)),
      );

      expect(result?.playerDamage, 36, reason: '3 round × 12 hasar');
      expect(quest.playerHealth, 64);
      expect(quest.enemyAttackSerial, 3);
    });

    test('bir sonraki geri sayım geleceğe taşınır', () {
      final startedAt = DateTime(2026, 8, 18, 12);
      final quest = questAt(startedAt);
      final now = startedAt.add(const Duration(seconds: 90));

      quest.resolveExpiredRounds(0, now);

      expect(quest.nextEnemyAttackAt.isAfter(now), isTrue);
      // Sıra `now`'dan değil, dolan sıradan ileri taşınır: 90 + 30 = 120.
      expect(
        quest.nextEnemyAttackAt,
        startedAt.add(const Duration(seconds: 120)),
      );
    });

    test('arka planda atılan adımlar turlara sırayla sayılır', () {
      final startedAt = DateTime(2026, 8, 18, 12);
      final quest = questAt(startedAt);

      // 90 saniyede 2.500 adım: ilk iki round tam, üçüncüsü yarım.
      final result = quest.resolveExpiredRounds(
        2500,
        startedAt.add(const Duration(seconds: 90)),
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
        startedAt.add(const Duration(seconds: 15)),
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
        startedAt.add(const Duration(seconds: 30)),
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
