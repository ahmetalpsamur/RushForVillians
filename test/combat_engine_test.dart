import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/utils/base_combat_stats.dart';
import 'package:rush_for_villains/core/utils/combat_engine.dart';
import 'package:rush_for_villains/models/combat_stats.dart';
import 'package:rush_for_villains/models/item_effect.dart';

/// Savaş motorunun mekaniği (Bölüm 7).
///
/// Motor saf ve deterministik: `Random()` yok, rastgeleliğin tamamı dışarıdan
/// verilen tohumdan geliyor. Aşama 6b'de aynı motor sunucuda çalışacak, o
/// yüzden bu özellik testle **bağlanıyor**.
void main() {
  const attacker = CombatStats(
    attack: 40,
    defense: 10,
    maxHealth: 200,
    critChance: 0,
    critDamage: 0.5,
    speed: 20,
  );
  const defender = CombatStats(
    attack: 30,
    defense: 10,
    maxHealth: 200,
    critChance: 0,
    critDamage: 0.5,
    speed: 10,
  );

  CombatRoundOutcome round({
    CombatStats? player,
    CombatStats? enemy,
    int playerHealth = 200,
    int enemyHealth = 200,
    double completion = 1,
    double playerDamageMultiplier = 1,
    int seed = 4242,
    List<ItemEffect> onHit = const [],
    List<ItemEffect> onKill = const [],
  }) => resolveCombatRound(
    player: player ?? attacker,
    enemy: enemy ?? defender,
    playerHealth: playerHealth,
    enemyHealth: enemyHealth,
    completion: completion,
    playerDamageMultiplier: playerDamageMultiplier,
    seed: seed,
    onHitEffects: onHit,
    onKillEffects: onKill,
  );

  group('determinizm', () {
    test('aynı tohum ve aynı girdi aynı sonucu verir', () {
      final a = round();
      final b = round();
      expect(a.damageDealt, b.damageDealt);
      expect(a.damageTaken, b.damageTaken);
      expect(a.nextSeed, b.nextSeed);
      expect(a.playerHealthAfter, b.playerHealthAfter);
    });

    test('farklı tohum farklı zar üretir', () {
      // Değişkenlik bandı ±%12; farklı tohumlar en az bir turda ayrışmalı.
      final results = {
        for (var seed = 1; seed <= 40; seed++) round(seed: seed).damageDealt,
      };
      expect(results.length, greaterThan(1));
    });

    test('tohum her turda ilerler', () {
      final first = round(seed: 7);
      expect(first.nextSeed, isNot(7));
      final second = round(seed: first.nextSeed);
      expect(second.nextSeed, isNot(first.nextSeed));
    });

    test('motor kendi başına zar atmaz: aynı tohum tekrar tekrar aynı', () {
      final values = [for (var i = 0; i < 5; i++) round(seed: 99).damageDealt];
      expect(values.toSet(), hasLength(1));
    });
  });

  group('adım ↔ hasar bağı', () {
    test('tam tamamlanan round: oyuncu vurur, düşman vuramaz', () {
      final outcome = round(completion: 1);
      expect(outcome.damageDealt, greaterThan(0));
      expect(outcome.damageTaken, 0);
    });

    test('hiç yürünmeyen round: düşman vurur, oyuncu vuramaz', () {
      final outcome = round(completion: 0);
      expect(outcome.damageDealt, 0);
      expect(outcome.damageTaken, greaterThan(0));
    });

    test('yarım round ikisini de vurdurur', () {
      final outcome = round(completion: 0.5);
      expect(outcome.damageDealt, greaterThan(0));
      expect(outcome.damageTaken, greaterThan(0));
    });

    test('düşman hasar eğrisi sınırları ve hafif cezayı korur', () {
      expect(enemyDamageScaleForCompletion(1), 0);
      expect(enemyDamageScaleForCompletion(0), 1);

      final at90 = enemyDamageScaleForCompletion(0.9);
      final at50 = enemyDamageScaleForCompletion(0.5);
      final at10 = enemyDamageScaleForCompletion(0.1);
      expect(at50 - at90, lessThan(at10 - at50));
      expect(
        at90,
        lessThan(0.1),
        reason: 'az kaçıran doğrusal cezadan az yemeli',
      );
    });

    test('mükemmel seri tavanları ×1,2 → ×1,5 → ×2 büyür', () {
      expect(perfectRoundDamageMultiplier(streak: 1, earlyFraction: 1), 1.2);
      expect(perfectRoundDamageMultiplier(streak: 2, earlyFraction: 1), 1.5);
      expect(perfectRoundDamageMultiplier(streak: 3, earlyFraction: 1), 2);
      expect(perfectRoundDamageMultiplier(streak: 99, earlyFraction: 1), 2);
    });

    test('aynı seride daha erken bitirmek daha çok bonus hasar verir', () {
      final late = perfectRoundDamageMultiplier(streak: 2, earlyFraction: 0.1);
      final early = perfectRoundDamageMultiplier(streak: 2, earlyFraction: 0.9);
      expect(early, greaterThan(late));
      expect(early, lessThanOrEqualTo(1.5));
    });

    test('tamamlanma oranı arttıkça oyuncunun hasarı artar', () {
      final low = round(completion: 0.25).damageDealt;
      final high = round(completion: 1).damageDealt;
      expect(high, greaterThan(low));
    });

    test('sınır dışı oran kırpılır', () {
      expect(round(completion: 5).damageTaken, 0);
      expect(round(completion: -3).damageDealt, 0);
      expect(round(completion: double.nan).damageDealt, 0);
    });
  });

  group('statlar', () {
    test('savunma gelen hasarı azaltır ama sıfırlamaz', () {
      final soft = round(enemy: defender.copyWith(defense: 0)).damageDealt;
      final hard = round(enemy: defender.copyWith(defense: 200)).damageDealt;
      expect(hard, lessThan(soft));
      expect(hard, greaterThanOrEqualTo(minimumDamage));
    });

    test('saldırı arttıkça hasar artar', () {
      final weak = round(player: attacker.copyWith(attack: 10)).damageDealt;
      final strong = round(player: attacker.copyWith(attack: 80)).damageDealt;
      expect(strong, greaterThan(weak));
    });

    test('kritik hasarı büyütür', () {
      // Kritik ihtimali tavanla sınırlı ([CombatStats.maxCritChance]), yani
      // tek turda garanti değil; ölçüm bir tohum aralığında yapılıyor.
      var critTotal = 0;
      var plainTotal = 0;
      var critSeen = false;
      for (var seed = 1; seed <= 60; seed++) {
        final crit = round(
          player: attacker.copyWith(critChance: 1, critDamage: 1),
          seed: seed,
        );
        critSeen = critSeen || crit.playerCrit;
        critTotal += crit.damageDealt;
        plainTotal +=
            round(
              player: attacker.copyWith(critChance: 0),
              seed: seed,
            ).damageDealt;
      }
      expect(critSeen, isTrue);
      expect(critTotal, greaterThan(plainTotal));
      expect(
        round(player: attacker.copyWith(critChance: 0)).playerCrit,
        isFalse,
      );
    });

    test('sıyrılma vuruşu tamamen boşa çıkarır', () {
      final outcome = round(completion: 0, player: attacker.copyWith(dodge: 1));
      expect(outcome.damageTaken, 0);
      expect(outcome.playerDodged, isTrue);
    });

    test('sıyrılma tavanı savaşı kilitlemez', () {
      // `dodge: 1` sanitize edilince tavana (%40) iner.
      final stats = attacker.copyWith(dodge: 1).sanitized();
      expect(stats.dodge, CombatStats.maxDodge);
    });

    test('can çalma verilen hasar kadar can yeniler', () {
      final outcome = round(
        player: attacker.copyWith(lifeSteal: 0.5),
        playerHealth: 100,
      );
      expect(outcome.playerHealthAfter, greaterThan(100));
      expect(
        outcome.playerHealthAfter,
        lessThanOrEqualTo(attacker.maxHealth.round()),
      );
    });

    test('hız inisiyatifi belirler', () {
      final fastPlayer = round(
        player: attacker.copyWith(speed: 99),
        enemy: defender.copyWith(speed: 1),
      );
      expect(fastPlayer.firstMover, Combatant.player);

      final fastEnemy = round(
        player: attacker.copyWith(speed: 1),
        enemy: defender.copyWith(speed: 99),
      );
      expect(fastEnemy.firstMover, Combatant.enemy);
    });

    test('inisiyatif öldürücü turda belirleyici', () {
      // Düşman tek vuruşta ölecek kadar zayıf; oyuncu önce vurursa düşman
      // karşılık veremez.
      final playerFirst = round(
        player: attacker.copyWith(speed: 99),
        enemy: defender.copyWith(speed: 1),
        enemyHealth: 1,
        completion: 0.5,
      );
      expect(playerFirst.enemyDefeated, isTrue);
      expect(playerFirst.damageTaken, 0, reason: 'ölen düşman vuramaz');

      final enemyFirst = round(
        player: attacker.copyWith(speed: 1),
        enemy: defender.copyWith(speed: 99),
        enemyHealth: 1,
        completion: 0.5,
      );
      expect(enemyFirst.enemyDefeated, isTrue);
      expect(enemyFirst.damageTaken, greaterThan(0));
    });

    test('şans kritik ve sıyrılma ihtimalini büyütür', () {
      const lucky = CombatStats(critChance: 0.1, dodge: 0.1, luck: 50);
      const plain = CombatStats(critChance: 0.1, dodge: 0.1);
      expect(lucky.effectiveCritChance, greaterThan(plain.effectiveCritChance));
      expect(lucky.effectiveDodge, greaterThan(plain.effectiveDodge));
      expect(
        lucky.effectiveCritChance,
        lessThanOrEqualTo(CombatStats.maxCritChance),
      );
      expect(lucky.effectiveDodge, lessThanOrEqualTo(CombatStats.maxDodge));
    });

    test('şans hasar değişkenliğini yukarı kaydırır', () {
      var luckyTotal = 0;
      var plainTotal = 0;
      for (var seed = 1; seed <= 60; seed++) {
        luckyTotal +=
            round(player: attacker.copyWith(luck: 60), seed: seed).damageDealt;
        plainTotal +=
            round(player: attacker.copyWith(luck: 0), seed: seed).damageDealt;
      }
      expect(luckyTotal, greaterThan(plainTotal));
    });
  });

  group('sonlanma', () {
    test('düşman canı bitince zafer', () {
      final outcome = round(enemyHealth: 1);
      expect(outcome.enemyDefeated, isTrue);
      expect(outcome.enemyHealthAfter, 0);
    });

    test('oyuncu canı bitince yenilgi', () {
      final outcome = round(completion: 0, playerHealth: 1);
      expect(outcome.playerDefeated, isTrue);
      expect(outcome.playerHealthAfter, 0);
    });

    test('can eksiye düşmez', () {
      final outcome = round(completion: 0, playerHealth: 1);
      expect(outcome.playerHealthAfter, greaterThanOrEqualTo(0));
    });

    test('hasar hiçbir zaman sıfır olmaz', () {
      // Devasa savunmaya rağmen vuruş bir şey yapmalı, yoksa savaş kilitlenir.
      final outcome = round(enemy: defender.copyWith(defense: 100000));
      expect(outcome.damageDealt, greaterThanOrEqualTo(minimumDamage));
    });
  });

  group('tetiklenen etkiler', () {
    test('onHit etkisi tam ihtimalle hasarı büyütür', () {
      final plain = round().damageDealt;
      final boosted =
          round(
            onHit: const [
              ItemEffect(
                stat: ItemStat.attack,
                value: 1,
                trigger: ItemEffectTrigger.onHit,
              ),
            ],
          ).damageDealt;
      expect(boosted, greaterThan(plain));
    });

    test('sıfır ihtimalli onHit etkisi hiç çalışmaz', () {
      final plain = round().damageDealt;
      final zero =
          round(
            onHit: const [
              ItemEffect(
                stat: ItemStat.attack,
                value: 1,
                trigger: ItemEffectTrigger.onHit,
                chance: 0,
              ),
            ],
          ).damageDealt;
      expect(zero, plain);
    });

    test('onKill can çalma etkisi düşman ölünce iyileştirir', () {
      final outcome = round(
        enemyHealth: 1,
        playerHealth: 50,
        onKill: const [
          ItemEffect(
            stat: ItemStat.lifeSteal,
            value: 0.5,
            trigger: ItemEffectTrigger.onKill,
          ),
        ],
      );
      expect(outcome.enemyDefeated, isTrue);
      expect(outcome.killHeal, greaterThan(0));
      // Kaybedilen canın yarısı geri gelir: 200 - 50 = 150 eksik → +75.
      expect(outcome.playerHealthAfter, 125);
    });

    test('düşman ölmezse onKill iyileştirmesi çalışmaz', () {
      final outcome = round(
        enemyHealth: 100000,
        playerHealth: 50,
        onKill: const [
          ItemEffect(
            stat: ItemStat.lifeSteal,
            value: 0.5,
            trigger: ItemEffectTrigger.onKill,
          ),
        ],
      );
      expect(outcome.enemyDefeated, isFalse);
      expect(outcome.killHeal, 0);
    });

    test('onKill saldırı bonusu bitirici vuruşu mümkün kılar', () {
      // Normal hasarın **hemen üstünde** bir düşman canı seçiliyor: bonussuz
      // ölmüyor, bonusla ölüyor.
      final plain = round(enemyHealth: 100000).damageDealt;
      final target = plain + 1;

      final withoutBonus = round(enemyHealth: target);
      expect(withoutBonus.enemyDefeated, isFalse);

      final withBonus = round(
        enemyHealth: target,
        onKill: const [
          ItemEffect(
            stat: ItemStat.attack,
            value: 0.5,
            trigger: ItemEffectTrigger.onKill,
          ),
        ],
      );
      expect(withBonus.enemyDefeated, isTrue);
    });

    test('bitirici bonus öldürmeyeceği turda hasarı büyütmez', () {
      final plain = round(enemyHealth: 100000).damageDealt;
      final boosted =
          round(
            enemyHealth: 100000,
            onKill: const [
              ItemEffect(
                stat: ItemStat.attack,
                value: 0.5,
                trigger: ItemEffectTrigger.onKill,
              ),
            ],
          ).damageDealt;
      expect(
        boosted,
        plain,
        reason: 'onKill koşulsuz bir saldırı bonusu değil',
      );
    });
  });

  group('taban statlar', () {
    test('seviye ham gücü doğrusal büyütür', () {
      // Eşit seviye aralıkları: 1→11 ve 11→21 (onar basamak).
      final low = baseCombatStats(1);
      final mid = baseCombatStats(11);
      final high = baseCombatStats(21);

      expect(mid.attack - low.attack, high.attack - mid.attack);
      expect(mid.defense - low.defense, high.defense - mid.defense);
      expect(mid.maxHealth - low.maxHealth, high.maxHealth - mid.maxHealth);
    });

    test('kritik, şans ve sıyrılma seviyeyle büyümez', () {
      final low = baseCombatStats(1);
      final high = baseCombatStats(30);
      expect(high.critChance, low.critChance);
      expect(high.critDamage, low.critDamage);
      expect(high.dodge, low.dodge);
      expect(high.luck, low.luck);
      expect(high.speed, low.speed);
    });

    test('geçersiz seviye 1. seviyeye düşer', () {
      expect(baseCombatStats(0).attack, baseCombatStats(1).attack);
      expect(baseCombatStats(-5).maxHealth, baseCombatStats(1).maxHealth);
    });
  });
}
