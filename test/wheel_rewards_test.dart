import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/utils/item_rules.dart';
import 'package:rush_for_villains/core/utils/wheel_rewards.dart';
import 'package:rush_for_villains/models/item.dart';
import 'package:rush_for_villains/data/wheel_odds.dart';
import 'package:rush_for_villains/models/wheel_reward.dart';
import 'package:rush_for_villains/models/reward_rarity.dart';

/// Çark havuzunun **saf** kuralları (#16).
///
/// Rastgeleliğin tamamı tohumdan geliyor: aynı tohum + aynı girdi her zaman
/// aynı çarkı üretiyor. Gerekçe CLAUDE.md §4.4 — kalıcı sonuç üreten
/// rastgelelik tohumlu olmalı; Aşama 6b'de aynı motor sunucuda çalışacak.
void main() {
  final allItems =
      [
        for (final entity in Directory('lib/Items').listSync(recursive: true))
          if (entity is File)
            buildItemFromAsset(
              entity.path.replaceAll(Platform.pathSeparator, '/'),
            ),
      ].nonNulls.toList();

  final swordManItems =
      allItems.where((item) => item.isUsableBy('SwordMan')).toList();

  List<Item> byRarity(RewardRarity rarity) =>
      swordManItems.where((item) => item.rarity == rarity).toList();

  group('determinizm', () {
    test('aynı tohum aynı dilimleri verir', () {
      List<String> slices(int seed) =>
          buildWheelSlices(
            level: 50,
            candidates: swordManItems,
            ownedItemIds: const [],
            seed: seed,
          ).map((reward) => reward.label).toList();

      expect(slices(1234), slices(1234));
      expect(slices(1234), isNot(slices(9999)));
    });

    test('aynı tohum aynı kazananı verir', () {
      expect(pickWinningSlice(wheelSliceCount, 42), pickWinningSlice(8, 42));
      expect(pickWinningSlice(8, 42), isNot(pickWinningSlice(8, 43)));
    });

    test('kazanan indeks her zaman geçerli bir dilim', () {
      for (var seed = 0; seed < 200; seed++) {
        final winner = pickWinningSlice(wheelSliceCount, seed);
        expect(winner, inInclusiveRange(0, wheelSliceCount - 1));
      }
    });

    test('tohum ilerletilince değişir ve 32 bitte kalır', () {
      var seed = 1;
      final seen = <int>{};
      for (var i = 0; i < 500; i++) {
        seed = nextWheelSeed(seed);
        expect(seed, greaterThanOrEqualTo(0));
        expect(seed, lessThanOrEqualTo(0x7FFFFFFF));
        seen.add(seed);
      }
      // Kısa bir döngüye düşmemeli.
      expect(seen.length, greaterThan(400));
    });

    test('başlangıç tohumu oyuncuya özel ve sıfır değil', () {
      final a = initialWheelSeed('Barca|SwordMan');
      final b = initialWheelSeed('Ayşe|Magic');

      expect(a, isNot(0));
      expect(b, isNot(0));
      expect(a, isNot(b));
      // Kararlı: aynı girdi her zaman aynı tohum (bkz. GD8).
      expect(initialWheelSeed('Barca|SwordMan'), a);
    });
  });

  group('havuz kuralları', () {
    test('boş dilim yok: her dilim bir ödül taşır', () {
      for (var seed = 0; seed < 50; seed++) {
        final slices = buildWheelSlices(
          level: 50,
          candidates: swordManItems,
          ownedItemIds: const [],
          seed: seed,
        );
        expect(slices, hasLength(wheelSliceCount));
        for (final reward in slices) {
          expect(
            reward.isItem || reward.isTitle || reward.xp > 0 || reward.coins > 0,
            isTrue,
            reason: 'ödülsüz dilim üretildi',
          );
        }
      }
    });

    test('ekipman yoksa dilimler XP ve altına düşer', () {
      final slices = buildWheelSlices(
        level: 50,
        candidates: const [],
        ownedItemIds: const [],
        seed: 7,
      );

      expect(slices, hasLength(wheelSliceCount));
      expect(slices.every((reward) => !reward.isItem), isTrue);
      expect(
        slices.every((reward) => reward.xp > 0 || reward.coins > 0),
        isTrue,
      );
      // Altın da bir ödül türü: hiç XP dilimi kalmasa bile boşluk olmaz.
      expect(slices.any((reward) => reward.xp > 0), isTrue);
    });

    test('seviye kilidi tutar: kilitli item çarka girmez', () {
      // 1. seviyede yalnızca sıradan itemlerin bir kısmı açık.
      for (var seed = 0; seed < 50; seed++) {
        final slices = buildWheelSlices(
          level: 1,
          candidates: swordManItems,
          ownedItemIds: const [],
          seed: seed,
        );
        for (final reward in slices.where((r) => r.isItem)) {
          expect(
            reward.item!.isUnlockedAt(1),
            isTrue,
            reason: '${reward.item!.id} 1. seviyede kilitli olmalıydı',
          );
        }
      }
    });

    test('sahip olunan item çarka girmez', () {
      final owned = swordManItems.map((item) => item.id).toList();
      final slices = buildWheelSlices(
        level: 50,
        candidates: swordManItems,
        ownedItemIds: owned,
        seed: 3,
      );

      expect(slices.every((reward) => !reward.isItem), isTrue);
    });

    test('epik ve efsanevi ekipman çarka hiç girmez', () {
      // Kullanıcı kararı (2026-08-26): aylara yayılan birikimler günlük
      // çarktan düşmemeli. Kural tek yerde: WheelOdds.maxItemRarity.
      final rich = [
        ...byRarity(RewardRarity.epic),
        ...byRarity(RewardRarity.legendary),
      ];
      expect(rich, isNotEmpty, reason: 'test verisi yetersiz');

      for (var seed = 0; seed < 30; seed++) {
        final slices = buildWheelSlices(
          level: 99,
          candidates: rich,
          ownedItemIds: const [],
          seed: seed,
        );
        expect(slices.any((reward) => reward.isItem), isFalse);
      }
    });

    test('nadir ve altı ekipman çarka girer', () {
      final ok = [
        ...byRarity(RewardRarity.common),
        ...byRarity(RewardRarity.uncommon),
        ...byRarity(RewardRarity.rare),
      ];

      for (var seed = 0; seed < 30; seed++) {
        final slices = buildWheelSlices(
          level: 99,
          candidates: ok,
          ownedItemIds: const [],
          seed: seed,
        );
        final rewards = slices.where((reward) => reward.isItem).toList();
        expect(rewards, isNotEmpty);
        expect(
          rewards.every(
            (reward) =>
                reward.item!.rarity.index <= WheelOdds.maxItemRarity.index,
          ),
          isTrue,
        );
      }
    });

    test('nadirlik arttıkça seçim ağırlığı azalır', () {
      expect(
        wheelRarityWeight(RewardRarity.common),
        greaterThan(wheelRarityWeight(RewardRarity.uncommon)),
      );
      expect(
        wheelRarityWeight(RewardRarity.uncommon),
        greaterThan(wheelRarityWeight(RewardRarity.rare)),
      );
      // Epik ve efsanevi artık havuzda değil: ağırlıkları sıfır.
      expect(wheelRarityWeight(RewardRarity.epic), 0);
      expect(wheelRarityWeight(RewardRarity.legendary), 0);
    });

    test('item dilimi sayısı tavanı aşmaz', () {
      for (var seed = 0; seed < 50; seed++) {
        final slices = buildWheelSlices(
          level: 50,
          candidates: swordManItems,
          ownedItemIds: const [],
          seed: seed,
        );
        final itemCount = slices.where((reward) => reward.isItem).length;
        expect(itemCount, lessThanOrEqualTo(maxItemSlices));
        expect(itemCount, greaterThan(0), reason: 'hiç item dilimi yok');
      }
    });

    test('aynı item iki dilimde birden çıkmaz', () {
      for (var seed = 0; seed < 50; seed++) {
        final slices = buildWheelSlices(
          level: 50,
          candidates: swordManItems,
          ownedItemIds: const [],
          seed: seed,
        );
        final ids = slices.where((r) => r.isItem).map((r) => r.item!.id);
        expect(ids.toSet().length, ids.length);
      }
    });

    test('XP dilimleri havuzdaki değerlerden gelir', () {
      final slices = buildWheelSlices(
        level: 50,
        candidates: swordManItems,
        ownedItemIds: const [],
        seed: 11,
      );

      for (final reward in slices.where((r) => r.isXp)) {
        expect(WheelOdds.xpOptions, contains(reward.xp));
      }
      for (final reward in slices.where((r) => r.isCoins)) {
        expect(WheelOdds.coinOptions, contains(reward.coins));
      }
    });

    test('aday listesi tavandan az ise hepsinden fazlası seçilmez', () {
      final two = byRarity(RewardRarity.common).take(2).toList();
      for (var seed = 0; seed < 30; seed++) {
        final slices = buildWheelSlices(
          level: 99,
          candidates: two,
          ownedItemIds: const [],
          seed: seed,
        );
        final items = slices.where((reward) => reward.isItem);
        expect(items.length, inInclusiveRange(1, 2));
      }
    });

    test(
      'adaylar sınıfa göre süzülmüş geldiği için başka sınıfın itemi yok',
      () {
        // Sözleşme: çağıran taraf sınıfa göre süzer (ItemCatalog).
        final slices = buildWheelSlices(
          level: 50,
          candidates: swordManItems,
          ownedItemIds: const [],
          seed: 21,
        );

        for (final reward in slices.where((r) => r.isItem)) {
          expect(reward.item!.isUsableBy('SwordMan'), isTrue);
        }
      },
    );
  });

  group('ödül modeli', () {
    test('XP ödülü item taşımaz, item ödülü XP taşımaz', () {
      final xp = buildWheelSlices(
        level: 1,
        candidates: const [],
        ownedItemIds: const [],
        seed: 1,
      ).firstWhere((reward) => reward.isXp);

      expect(xp.isItem, isFalse);
      expect(xp.item, isNull);
      expect(xp.coins, 0);
      expect(xp.label, '+${xp.xp} XP');
    });

    test('item ödülünün etiketi item adıdır', () {
      final item = byRarity(RewardRarity.common).first;
      final slices = buildWheelSlices(
        level: 99,
        candidates: [item],
        ownedItemIds: const [],
        seed: 2,
      );
      final reward = slices.firstWhere((r) => r.isItem);

      expect(reward.xp, 0);
      expect(reward.label, item.name);
    });
  });

  group('oran tabloları tek dosyada (kullanıcı isteği)', () {
    test('XP havuzu 50den 1000e 50şer artıyor', () {
      expect(WheelOdds.xpOptions.first, 50);
      expect(WheelOdds.xpOptions.last, 1000);
      expect(WheelOdds.xpOptions, hasLength(20));
      for (var i = 0; i < WheelOdds.xpOptions.length; i++) {
        expect(WheelOdds.xpOptions[i], 50 * (i + 1));
      }
      // Sıfır yok: boş dilim hiçbir koşulda oluşmamalı.
      expect(WheelOdds.xpOptions, isNot(contains(0)));
    });

    test('her değerin bir ağırlığı var ve büyük ödül daha nadir', () {
      expect(WheelOdds.xpWeights, hasLength(WheelOdds.xpOptions.length));
      expect(WheelOdds.coinWeights, hasLength(WheelOdds.coinOptions.length));

      for (var i = 1; i < WheelOdds.xpWeights.length; i++) {
        expect(
          WheelOdds.xpWeights[i],
          lessThan(WheelOdds.xpWeights[i - 1]),
          reason: 'XP ağırlıkları azalan olmalı',
        );
      }
      for (var i = 1; i < WheelOdds.coinWeights.length; i++) {
        expect(
          WheelOdds.coinWeights[i],
          lessThan(WheelOdds.coinWeights[i - 1]),
          reason: 'altın ağırlıkları azalan olmalı',
        );
      }
      expect(WheelOdds.xpWeights.every((w) => w > 0), isTrue);
      expect(WheelOdds.coinWeights.every((w) => w > 0), isTrue);
    });

    test('beklenen değerler ölçülmüş ekonomiyle uyumlu', () {
      double expected(List<int> values, List<int> weights) {
        final total = weights.fold<int>(0, (sum, w) => sum + w);
        var acc = 0.0;
        for (var i = 0; i < values.length; i++) {
          acc += values[i] * weights[i];
        }
        return acc / total;
      }

      final xp = expected(WheelOdds.xpOptions, WheelOdds.xpWeights);
      final coins = expected(WheelOdds.coinOptions, WheelOdds.coinWeights);

      // Referans oyuncu: 3.000 XP ve 120 altın/gün (economy_pacing_test).
      // Çark günde bir dönüyor; beklenen getirisi günlük kazancın küçük bir
      // payı olmalı, yoksa yürüyüş ekonomisi anlamsızlaşır.
      expect(xp, closeTo(367, 5));
      expect(coins, closeTo(77, 3));
      expect(xp, lessThan(3000 * 0.25));
      expect(coins, lessThan(120));
    });

    test('dilim adedi ağırlıkları tavanlarla tutarlı', () {
      expect(
        WheelOdds.itemSliceCountWeights,
        hasLength(WheelOdds.maxItemSlices),
      );
      expect(
        WheelOdds.coinSliceCountWeights,
        hasLength(WheelOdds.maxCoinSlices),
      );
      expect(WheelOdds.titleSliceChance, inInclusiveRange(0, 1));
    });
  });

  group('altın dilimi', () {
    test('altın dilimi çıkıyor ve tavanı aşmıyor', () {
      var sawCoins = false;
      for (var seed = 0; seed < 60; seed++) {
        final slices = buildWheelSlices(
          level: 50,
          candidates: swordManItems,
          ownedItemIds: const [],
          seed: seed,
        );
        final coinSlices = slices.where((reward) => reward.isCoins).toList();
        expect(coinSlices.length, lessThanOrEqualTo(WheelOdds.maxCoinSlices));
        if (coinSlices.isNotEmpty) sawCoins = true;
        for (final reward in coinSlices) {
          expect(WheelOdds.coinOptions, contains(reward.coins));
          // Altın dilimi başka bir ödül taşımaz.
          expect(reward.xp, 0);
          expect(reward.isItem, isFalse);
          expect(reward.isTitle, isFalse);
        }
      }
      expect(sawCoins, isTrue, reason: 'hiç altın dilimi çıkmadı');
    });

    test('her çarkta en az bir XP dilimi kalıyor', () {
      for (var seed = 0; seed < 60; seed++) {
        final slices = buildWheelSlices(
          level: 50,
          candidates: swordManItems,
          ownedItemIds: const [],
          seed: seed,
        );
        expect(
          slices.any((reward) => reward.isXp),
          isTrue,
          reason: 'tohum $seed: XP dilimi kalmadı',
        );
      }
    });

    test('altın ödülünün etiketi miktarı söyler', () {
      const reward = WheelReward.coins(150);
      expect(reward.label, '+150 altın');
      expect(reward.isCoins, isTrue);
      expect(reward.isXp, isFalse);
      expect(reward.rarity, isNull);
    });
  });

}
