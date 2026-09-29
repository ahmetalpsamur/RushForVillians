import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/game_constants.dart';
import 'package:rush_for_villains/core/utils/endless_rules.dart';
import 'package:rush_for_villains/core/utils/game_clock.dart';
import 'package:rush_for_villains/data/enemy_catalog.dart';
import 'package:rush_for_villains/models/combat_stats.dart';
import 'package:rush_for_villains/models/endless_run.dart';

/// Sonsuz Koşu (Bölüm C / Faz 3).
///
/// Eğrilerin hepsi config'ten okunur; bu dosyada koda gömülü denge sayısı
/// yok — bir sabit değişirse test **davranışı** yakalar, sayıyı değil.
void main() {
  final enemy = EnemyCatalog.byId(EndlessRun.enemyId)!;
  final startedAt = DateTime(2026, 3, 1, 9);

  EndlessRun run() =>
      EndlessRun(enemy: enemy, startedAt: startedAt, combatSeed: 4242);

  group('çarpan eğrisi', () {
    test('0,25 ile başlar ve kesim başına sabit artar', () {
      expect(
        endlessMultiplierAt(0),
        GameConstants.endlessStartMultiplier,
      );
      expect(
        endlessMultiplierAt(1) - endlessMultiplierAt(0),
        closeTo(GameConstants.endlessMultiplierStep, 1e-9),
      );
      expect(
        endlessMultiplierAt(5) - endlessMultiplierAt(4),
        closeTo(GameConstants.endlessMultiplierStep, 1e-9),
        reason: 'artış hızlanmamalı',
      );
    });

    test('tavanı aşmaz ve azalmaz', () {
      var previous = 0.0;
      for (var cut = 0; cut <= 200; cut++) {
        final value = endlessMultiplierAt(cut);
        expect(value, lessThanOrEqualTo(GameConstants.endlessMaxMultiplier));
        expect(value, greaterThanOrEqualTo(previous));
        previous = value;
      }
      expect(endlessMultiplierAt(200), GameConstants.endlessMaxMultiplier);
    });
  });

  group('can eğrisi', () {
    test('200 adımla başlar — tam iki round', () {
      expect(endlessMonsterHealthAt(0), GameConstants.endlessBaseHealthSteps);
      expect(
        endlessMonsterHealthAt(0) / GameConstants.endlessRoundSteps,
        2,
      );
      expect(endlessRoundsForCut(0), 2);
    });

    test('tavanı aşmaz ve azalmaz', () {
      var previous = 0;
      for (var cut = 0; cut <= 200; cut++) {
        final value = endlessMonsterHealthAt(cut);
        expect(value, lessThanOrEqualTo(GameConstants.endlessMaxHealthSteps));
        expect(value, greaterThanOrEqualTo(previous));
        previous = value;
      }
      expect(
        endlessMonsterHealthAt(200),
        GameConstants.endlessMaxHealthSteps,
      );
    });

    test('kesim süresi tavanda sabitlenir', () {
      // "Her kesim bir öncekinden uzun" hissi tempoyu öldürür; can tavanı
      // tam olarak bunun için var.
      final capped = endlessCutDuration(200);
      expect(capped, endlessCutDuration(500));
      expect(capped.inMinutes, lessThanOrEqualTo(10));
    });
  });

  group('hasar eğrisi', () {
    test('can eğrisinin bağıl hızını geçmez — can tavana vurana kadar', () {
      // Kural: oyuncu önce "bu uzuyor", sonra "bu tehlikeli" hissetmeli.
      for (var cut = 0; cut <= 15; cut++) {
        final healthRatio =
            endlessMonsterHealthAt(cut) /
            GameConstants.endlessBaseHealthSteps;
        final damageRatio =
            endlessDamageMultiplierAt(cut) /
            GameConstants.endlessStartDamageMultiplier;
        expect(
          damageRatio,
          lessThanOrEqualTo(healthRatio + 1e-9),
          reason: 'kesim $cut: hasar candan hızlı büyüyor',
        );
      }
    });

    test('can tavana vurduktan sonra hasar büyümeye devam eder', () {
      expect(
        endlessDamageMultiplierAt(25),
        greaterThan(endlessDamageMultiplierAt(15)),
      );
      expect(
        endlessMonsterHealthAt(25),
        endlessMonsterHealthAt(15),
        reason: 'can zaten tavanda',
      );
    });

    test('tavanı aşmaz', () {
      expect(
        endlessDamageMultiplierAt(500),
        GameConstants.endlessMaxDamageMultiplier,
      );
    });
  });

  group('ölçek tavanı', () {
    test('1,0 ile başlar, tavanı aşmaz, azalmaz', () {
      expect(endlessSpriteScaleAt(0), 1.0);
      var previous = 0.0;
      for (var cut = 0; cut <= 200; cut++) {
        final value = endlessSpriteScaleAt(cut);
        expect(value, lessThanOrEqualTo(GameConstants.endlessMaxSpriteScale));
        expect(value, greaterThanOrEqualTo(previous));
        previous = value;
      }
      expect(
        endlessSpriteScaleAt(200),
        GameConstants.endlessMaxSpriteScale,
      );
    });
  });

  group('kesim ve banka', () {
    test('200 adım bir canavarı devirir', () {
      final r = run();
      expect(r.cutCount, 0);
      final cuts = r.addSteps(
        GameConstants.endlessBaseHealthSteps,
        GameConstants.endlessBaseHealthSteps,
      );
      expect(cuts, 1);
      expect(r.cutCount, 1);
      expect(r.stepsIntoCut, 0);
    });

    test('tek partide birden fazla kesim olabilir', () {
      final r = run();
      final cuts = r.addSteps(1000, 1000);
      expect(cuts, greaterThan(1));
      expect(r.cutCount, cuts);
    });

    test('banka kesim anındaki çarpanla büyür, sonda tek çarpanla değil', () {
      final r = run();
      r.addSteps(endlessMonsterHealthAt(0), endlessMonsterHealthAt(0));
      final afterFirst = r.bankedCoins;
      expect(afterFirst, endlessCutCoins(0));
      r.addSteps(endlessMonsterHealthAt(1), 10000);
      expect(r.bankedCoins, endlessCutCoins(0) + endlessCutCoins(1));
      expect(
        endlessCutCoins(1),
        greaterThan(endlessCutCoins(0)),
        reason: 'sonraki kesim daha çok ödemeli',
      );
    });

    test('ilk kesim bilerek çok az ödüyor', () {
      expect(
        endlessCutCoins(0),
        lessThan(GameConstants.endlessCutBaseCoins ~/ 2),
      );
    });
  });

  group('bitiş ve yenilgi', () {
    test('"bitir" tam bankayı öder', () {
      final r = run();
      r.addSteps(1000, 1000);
      final banked = r.bankedCoins;
      expect(r.bank(), isTrue);
      expect(r.outcome, EndlessRunOutcome.banked);
      expect(r.paidCoins, banked);
      expect(r.bank(), isFalse, reason: 'ikinci kez bankalanamaz');
    });

    test('yenilgi ödemesi asla sıfır değil', () {
      // Sıfır olsaydı oyuncu canını takip etmek için telefona bakardı.
      for (final banked in [1, 10, 250, 9999]) {
        expect(endlessDefeatPayout(banked), greaterThan(0));
        expect(endlessDefeatPayout(banked), lessThan(banked + 1));
      }
    });

    test('yenilgi bankanın bir kısmını öder', () {
      final r = run();
      r.addSteps(1000, 1000);
      r.outcome = EndlessRunOutcome.defeated;
      r.settleDefeat();
      expect(r.paidCoins, endlessDefeatPayout(r.bankedCoins));
      expect(r.paidCoins, greaterThan(0));
      expect(r.paidCoins, lessThan(r.bankedCoins));
    });

    test('bitmiş koşu adım almaz', () {
      final r = run();
      r.bank();
      expect(r.addSteps(500, 500), 0);
      expect(r.cutCount, 0);
    });
  });

  group('hasar ve ölüm', () {
    const frail = CombatStats(
      attack: 10,
      defense: 0,
      maxHealth: 12,
      speed: 1,
    );
    const sturdy = CombatStats(
      attack: 10,
      defense: 50,
      maxHealth: 5000,
      speed: 1,
    );

    test('tam yürünen round hiç hasar getirmez', () {
      final r = EndlessRun(
        enemy: enemy,
        startedAt: startedAt,
        combatSeed: 4242,
        playerMaxHealth: sturdy.maxHealth.round(),
      );
      expect(
        r.playerHealth,
        r.playerMaxHealth,
        reason: 'koşu tam canla başlamalı',
      );
      r.addSteps(GameConstants.endlessRoundSteps, 100);
      final result = r.resolveExpiredRounds(
        100,
        startedAt.add(const Duration(seconds: 130)),
        playerStats: sturdy,
      );
      expect(result.damageTaken, 0);
      expect(r.playerHealth, r.playerMaxHealth, reason: 'hiç hasar almadı');
    });

    test('tavan büyüyünce bedava iyileşme yok (GD53)', () {
      final r = EndlessRun(
        enemy: enemy,
        startedAt: startedAt,
        playerMaxHealth: 100,
        playerHealth: 40,
      );
      r.syncPlayerStats(sturdy);
      expect(r.playerMaxHealth, sturdy.maxHealth.round());
      expect(r.playerHealth, 40, reason: 'tavan büyüdü, can yükselmedi');
      r.syncPlayerStats(const CombatStats(maxHealth: 25));
      expect(r.playerHealth, 25, reason: 'tavan küçülünce kırpılır');
    });

    test('hiç yürünmeyen round hasar getirir', () {
      final r = run();
      final result = r.resolveExpiredRounds(
        0,
        startedAt.add(const Duration(seconds: 130)),
        playerStats: sturdy,
      );
      expect(result.damageTaken, greaterThan(0));
    });

    test('can biterse koşu yenilgiyle kapanır', () {
      final r = run();
      final result = r.resolveExpiredRounds(
        0,
        startedAt.add(const Duration(minutes: 60)),
        playerStats: frail,
      );
      expect(result.defeated, isTrue);
      expect(r.outcome, EndlessRunOutcome.defeated);
      expect(r.playerHealth, 0);
    });

    test('aynı tohum aynı hasarı verir — determinizm', () {
      int damageFor() {
        final r = run();
        return r
            .resolveExpiredRounds(
              0,
              startedAt.add(const Duration(seconds: 130)),
              playerStats: sturdy,
            )
            .damageTaken;
      }

      expect(damageFor(), damageFor());
    });
  });

  group('kalıcılık', () {
    test('yarım koşu kayıt turunda kaybolmaz', () {
      GameClock.reset();
      final r = run();
      r.addSteps(450, 450);
      r.resolveExpiredRounds(
        450,
        startedAt.add(const Duration(seconds: 130)),
        playerStats: const CombatStats(
          attack: 10,
          defense: 50,
          maxHealth: 500,
          speed: 1,
        ),
      );

      final restored = EndlessRun.fromJson(r.toJson(), enemy)!;
      expect(restored.cutCount, r.cutCount);
      expect(restored.stepsIntoCut, r.stepsIntoCut);
      expect(restored.bankedCoins, r.bankedCoins);
      expect(restored.bankedXp, r.bankedXp);
      expect(restored.playerHealth, r.playerHealth);
      expect(restored.combatSeed, r.combatSeed);
      expect(restored.roundStartingSteps, r.roundStartingSteps);
      expect(restored.nextEnemyAttackAt, r.nextEnemyAttackAt);
      expect(restored.outcome, r.outcome);
      expect(restored.startingSteps, r.startingSteps);
    });

    test('bozuk kayıt varsayılana düşer, patlamaz', () {
      final restored = EndlessRun.fromJson(const {}, enemy)!;
      expect(restored.cutCount, 0);
      expect(restored.outcome, EndlessRunOutcome.active);
      expect(restored.bankedCoins, 0);
    });

    test('şişkin kesim sayısı kırpılır', () {
      final restored = EndlessRun.fromJson(const {
        'cutCount': -5,
        'stepsIntoCut': -10,
      }, enemy)!;
      expect(restored.cutCount, 0);
      expect(restored.stepsIntoCut, 0);
    });
  });
}
