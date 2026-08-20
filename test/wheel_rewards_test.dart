import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/utils/item_rules.dart';
import 'package:rush_for_villains/core/utils/wheel_rewards.dart';
import 'package:rush_for_villains/data/mock_data.dart';
import 'package:rush_for_villains/models/item.dart';
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
            reward.isItem || reward.xp > 0,
            isTrue,
            reason: 'ödülsüz dilim üretildi',
          );
        }
      }
    });

    test('ekipman yoksa dilimlerin tamamı XP olur', () {
      final slices = buildWheelSlices(
        level: 50,
        candidates: const [],
        ownedItemIds: const [],
        seed: 7,
      );

      expect(slices, hasLength(wheelSliceCount));
      expect(slices.every((reward) => !reward.isItem), isTrue);
      expect(slices.every((reward) => reward.xp > 0), isTrue);
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

    test('epik ve efsanevi çarktan çıkmaz', () {
      // Aday listesi yalnızca epik + efsanevi olsa bile item dilimi olmamalı.
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
        expect(slices.every((reward) => !reward.isItem), isTrue);
      }
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

      for (final reward in slices.where((r) => !r.isItem)) {
        expect(MockData.wheelXpOptions, contains(reward.xp));
      }
    });

    test('aday listesi tavandan az ise hepsi kullanılır', () {
      final two = byRarity(RewardRarity.common).take(2).toList();
      final slices = buildWheelSlices(
        level: 99,
        candidates: two,
        ownedItemIds: const [],
        seed: 5,
      );

      expect(slices.where((reward) => reward.isItem), hasLength(2));
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
      final xp =
          buildWheelSlices(
            level: 1,
            candidates: const [],
            ownedItemIds: const [],
            seed: 1,
          ).first;

      expect(xp.isItem, isFalse);
      expect(xp.item, isNull);
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
}
