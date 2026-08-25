import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/game_constants.dart';
import 'package:rush_for_villains/core/utils/item_leveling.dart';
import 'package:rush_for_villains/core/utils/item_merging.dart';
import 'package:rush_for_villains/core/utils/item_rules.dart';
import 'package:rush_for_villains/models/item.dart';
import 'package:rush_for_villains/models/item_effect.dart';
import 'package:rush_for_villains/models/owned_item.dart';
import 'package:rush_for_villains/models/reward_rarity.dart';

/// Birleştirmenin sözleşmesi (Bölüm 4.3).
Item _item({
  RewardRarity rarity = RewardRarity.common,
  int cost = 100,
  int requiredLevel = 2,
}) => Item(
  id: 'swords/test_blade',
  name: 'Test Kılıcı',
  assetPath: 'lib/Items/swords/test_blade.png',
  category: ItemCategory.swords,
  rarity: rarity,
  requiredLevel: requiredLevel,
  cost: cost,
  archetype: ItemArchetype.striker,
  buff: const ItemBuff([ItemEffect.flat(stat: ItemStat.attack, value: 10)]),
);

List<OwnedItem> _group(
  int count, {
  RewardRarity? rarity,
  List<int>? levels,
  Set<int> equipped = const {},
}) => [
  for (var i = 0; i < count; i++)
    OwnedItem(
      instanceId: i + 1,
      itemId: 'swords/test_blade',
      level: levels == null ? 1 : levels[i],
      rarity: rarity,
      equipped: equipped.contains(i + 1),
    ),
];

void main() {
  group('gereken adet', () {
    test('3\'ten başlar ve her kademede bir artar', () {
      expect(mergeCountFor(RewardRarity.common), 3);
      expect(mergeCountFor(RewardRarity.uncommon), 4);
      expect(mergeCountFor(RewardRarity.rare), 5);
      expect(mergeCountFor(RewardRarity.epic), 6);
    });

    test('efsanevinin adedi yok — birleştirilemez', () {
      expect(mergeCountFor(RewardRarity.legendary), isNull);
      expect(nextRarity(RewardRarity.legendary), isNull);
    });

    test('sayılar tek config sabitinden okunuyor', () {
      // Koda gömülü sayı olmamalı: tablo değişirse kural da değişmeli.
      for (final entry in GameConstants.itemMergeCounts.entries) {
        expect(mergeCountFor(entry.key), entry.value);
      }
      expect(
        GameConstants.itemMergeCounts.containsKey(RewardRarity.legendary),
        isFalse,
      );
    });

    test('bir üst nadirlik sırayla gelir', () {
      expect(nextRarity(RewardRarity.common), RewardRarity.uncommon);
      expect(nextRarity(RewardRarity.uncommon), RewardRarity.rare);
      expect(nextRarity(RewardRarity.rare), RewardRarity.epic);
      expect(nextRarity(RewardRarity.epic), RewardRarity.legendary);
    });
  });

  group('ücret', () {
    test('nadirlik yükseldikçe ücret artar', () {
      var previous = 0;
      for (final rarity in [
        RewardRarity.common,
        RewardRarity.uncommon,
        RewardRarity.rare,
        RewardRarity.epic,
      ]) {
        final cost = mergeCostFor(rarity, 5);
        expect(cost, greaterThan(previous), reason: rarity.name);
        previous = cost;
      }
    });

    test('ücret 25 katına yuvarlanır ve en az 25', () {
      for (final rarity in RewardRarity.values) {
        final cost = mergeCostFor(rarity, 1);
        if (rarity == RewardRarity.legendary) {
          expect(cost, 0);
        } else {
          expect(cost % 25, 0);
          expect(cost, greaterThanOrEqualTo(25));
        }
      }
    });

    test('birleştirmek doğrudan satın almaktan pahalı', () {
      // Karşılığında seviye kilidi değişmiyor (GD40) ve nadirlik tavanı
      // yükseliyor; bunun bir bedeli olmalı, yoksa mağaza anlamsızlaşır.
      const prices = {
        RewardRarity.common: 100,
        RewardRarity.uncommon: 325,
        RewardRarity.rare: 825,
        RewardRarity.epic: 2600,
      };
      for (final entry in prices.entries) {
        final target = nextRarity(entry.key)!;
        final direct = prices[target] ?? 8450;
        final total =
            entry.value * mergeCountFor(entry.key)! +
            mergeCostFor(entry.key, 5);
        expect(
          total,
          greaterThan(direct),
          reason:
              '${entry.key.name}: birleştirme $total, doğrudan alım $direct',
        );
      }
    });
  });

  group('tüketilecek örneklerin seçimi', () {
    test('en düşük seviyeliler önce harcanır', () {
      final selected = selectMergeInstances(
        _group(4, levels: const [5, 1, 9, 2]),
        3,
      );
      expect([for (final i in selected) i.level], [1, 2, 5]);
    });

    test('kuşanılı örnek en sona atılır', () {
      // Sv.1 ama kuşanılı olan, Sv.9 ama kuşanılmayanın arkasında kalır.
      final selected = selectMergeInstances(
        _group(3, levels: const [1, 9, 4], equipped: {1}),
        2,
      );
      expect([for (final i in selected) i.instanceId], [3, 2]);
    });

    test('seçim kararlı: aynı girdi aynı sırayı verir', () {
      final group = _group(5, levels: const [2, 2, 2, 2, 2]);
      expect(
        [for (final i in selectMergeInstances(group, 3)) i.instanceId],
        [for (final i in selectMergeInstances(group, 3)) i.instanceId],
      );
    });

    test('gelen liste değiştirilmez', () {
      final group = _group(3, levels: const [9, 1, 5]);
      selectMergeInstances(group, 2);
      expect([for (final i in group) i.level], [9, 1, 5]);
    });
  });

  group('birleştirme tablosu', () {
    MergeQuote quote({
      required int count,
      RewardRarity rarity = RewardRarity.common,
      int coins = 99999,
      List<int>? levels,
      Set<int> equipped = const {},
    }) => quoteMerge(
      resolved: _item(rarity: rarity),
      rarity: rarity,
      group: _group(
        count,
        rarity: rarity == RewardRarity.common ? null : rarity,
        levels: levels,
        equipped: equipped,
      ),
      coins: coins,
    );

    test('yeterli adet ve parayla birleştirilebilir', () {
      final result = quote(count: 3);
      expect(result.canMerge, isTrue);
      expect(result.target, RewardRarity.uncommon);
      expect(result.requiredCount, 3);
      expect(result.consumedInstanceIds, hasLength(3));
      expect(result.reason(RewardRarity.common), isNull);
    });

    test('adet yetmezse sebebi söylenir ve tüketilecek liste boş', () {
      final result = quote(count: 2);
      expect(result.block, MergeBlock.notEnough);
      expect(result.consumedInstanceIds, isEmpty);
      expect(result.reason(RewardRarity.common), contains('3 adet gerekiyor'));
    });

    test('para yetmezse sebebi söylenir', () {
      final result = quote(count: 3, coins: 0);
      expect(result.block, MergeBlock.coins);
      expect(result.reason(RewardRarity.common), contains('coin'));
      // Adet yeterli olduğu için tüketilecek liste yine de gösterilir.
      expect(result.consumedInstanceIds, hasLength(3));
    });

    test('efsanevi birleştirilemez ve nedeni söylenir', () {
      final result = quote(count: 10, rarity: RewardRarity.legendary);
      expect(result.block, MergeBlock.maxRarity);
      expect(result.target, isNull);
      expect(result.cost, 0);
      expect(
        result.reason(RewardRarity.legendary),
        contains('en üst nadirlik'),
      );
    });

    test('kuşanılı örnek harcanacaksa önceden bildirilir', () {
      // Üç adet var, üçü de gerekiyor; biri kuşanılı.
      final result = quote(count: 3, equipped: {1});
      expect(result.canMerge, isTrue);
      expect(result.consumesEquipped, isTrue);
    });

    test('kuşanılı örnek gerekmiyorsa bildirilmez', () {
      final result = quote(count: 4, equipped: {1});
      expect(result.canMerge, isTrue);
      expect(result.consumesEquipped, isFalse);
    });

    test('fazla adet varken yalnızca gerekli kadarı harcanır', () {
      final result = quote(count: 7);
      expect(result.availableCount, 7);
      expect(result.consumedInstanceIds, hasLength(3));
    });
  });

  group('gruplama', () {
    test('farklı nadirlikteki örnekler ayrı gruplara düşer', () {
      final items = [
        const OwnedItem(instanceId: 1, itemId: 'swords/a'),
        const OwnedItem(
          instanceId: 2,
          itemId: 'swords/a',
          rarity: RewardRarity.uncommon,
        ),
        const OwnedItem(instanceId: 3, itemId: 'swords/a'),
      ];
      final groups = groupForMerging(
        items,
        (instance) => instance.effectiveRarity(RewardRarity.common),
      );

      expect(groups, hasLength(2));
      expect(
        groups[mergeGroupKey('swords/a', RewardRarity.common)],
        hasLength(2),
      );
      expect(
        groups[mergeGroupKey('swords/a', RewardRarity.uncommon)],
        hasLength(1),
      );
    });

    test('farklı eşyalar ayrı gruplara düşer', () {
      final groups = groupForMerging(const [
        OwnedItem(instanceId: 1, itemId: 'swords/a'),
        OwnedItem(instanceId: 2, itemId: 'swords/b'),
      ], (_) => RewardRarity.common);
      expect(groups, hasLength(2));
    });
  });

  group('birleştirmenin sonucu', () {
    test('nadirlik yükselir, tavan da yükselir', () {
      final base = _item();
      final merged = withRarity(base, RewardRarity.uncommon);

      expect(merged.rarity, RewardRarity.uncommon);
      expect(
        itemLevelCap(merged.rarity),
        greaterThan(itemLevelCap(base.rarity)),
      );
      // Seviye kilidi **değişmez** (GD40).
      expect(merged.requiredLevel, base.requiredLevel);
    });

    test('efsaneviye kadar zincirleme yükselebilir', () {
      var item = _item();
      var rarity = RewardRarity.common;
      for (
        var next = nextRarity(rarity);
        next != null;
        next = nextRarity(rarity)
      ) {
        item = withRarity(item, next);
        rarity = next;
      }
      expect(rarity, RewardRarity.legendary);
      expect(item.rarity, RewardRarity.legendary);
      expect(item.requiredLevel, 2);
      expect(mergeCountFor(rarity), isNull);
    });
  });
}
