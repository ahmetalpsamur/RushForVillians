import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/game_constants.dart';
import 'package:rush_for_villains/core/utils/item_leveling.dart';
import 'package:rush_for_villains/core/utils/item_rules.dart';
import 'package:rush_for_villains/models/item.dart';
import 'package:rush_for_villains/models/item_effect.dart';
import 'package:rush_for_villains/models/owned_item.dart';
import 'package:rush_for_villains/models/reward_rarity.dart';

/// Demirci kurallarının sözleşmesi (Bölüm 4.2).
///
/// En kritik iddia: **yükseltme ekonomi bonuslarını büyütmez.** Ekonomi
/// dikkatle dengelendi (`economy_pacing_test.dart`); adım→para ve adım→XP
/// çarpanları eşya seviyesiyle büyüseydi adım kazancı katlanır ve denge
/// çökerdi.
Item _item({
  RewardRarity rarity = RewardRarity.common,
  List<ItemEffect>? effects,
  int cost = 100,
  int requiredLevel = 1,
  String? lore,
}) => Item(
  id: 'swords/test_blade',
  name: 'Test Kılıcı',
  assetPath: 'lib/Items/swords/test_blade.png',
  category: ItemCategory.swords,
  rarity: rarity,
  requiredLevel: requiredLevel,
  cost: cost,
  archetype: ItemArchetype.striker,
  lore: lore,
  buff: ItemBuff(
    effects ??
        const [
          ItemEffect(stat: ItemStat.stepCoin, value: 0.10),
          ItemEffect.flat(stat: ItemStat.attack, value: 10),
          ItemEffect(stat: ItemStat.defense, value: 0.20),
        ],
  ),
);

OwnedItem _instance({int level = 1, RewardRarity? rarity}) => OwnedItem(
  instanceId: 1,
  itemId: 'swords/test_blade',
  level: level,
  rarity: rarity,
);

/// 6.000 adım/gün atan referans oyuncu.
const _coinsPerDay = 6000 / GameConstants.stepsPerCoin;
const _xpPerDay = 6000 / GameConstants.stepsPerXp;

void main() {
  group('iki tavan', () {
    test('nadirlik tavanları sıralı ve tablodaki gibi', () {
      expect(itemLevelCap(RewardRarity.common), 10);
      expect(itemLevelCap(RewardRarity.uncommon), 20);
      expect(itemLevelCap(RewardRarity.rare), 30);
      expect(itemLevelCap(RewardRarity.epic), 40);
      expect(itemLevelCap(RewardRarity.legendary), 50);
    });

    test('oyuncu seviyesi eşya seviyesini bağlar', () {
      // 1. seviyedeki oyuncu eşyasını tavana çıkaramaz — istenen bu.
      expect(maxItemLevelFor(RewardRarity.legendary, 1), 1);
      expect(maxItemLevelFor(RewardRarity.legendary, 7), 7);
      // Oyuncu yüksekse nadirlik bağlar.
      expect(maxItemLevelFor(RewardRarity.common, 50), 10);
    });

    test('sıfır ya da eksi oyuncu seviyesinde bile en az 1', () {
      expect(maxItemLevelFor(RewardRarity.common, 0), 1);
      expect(maxItemLevelFor(RewardRarity.common, -3), 1);
    });

    test('nadirlik tavanı bağlıyorsa sebebi nadirlik, seviye değil', () {
      final quote = quoteUpgrade(
        resolved: _item(),
        instance: _instance(level: 10),
        playerLevel: 50,
        coins: 999999,
      );
      expect(quote.block, UpgradeBlock.rarityCap);
      expect(quote.canUpgrade, isFalse);
      expect(quote.cost, 0);
      expect(
        quote.reason(RewardRarity.common, 50),
        contains('Nadirlik sınırı'),
      );
    });

    test('oyuncu seviyesi bağlıyorsa sebebi ayrı söylenir', () {
      final quote = quoteUpgrade(
        resolved: _item(),
        instance: _instance(level: 5),
        playerLevel: 5,
        coins: 999999,
      );
      expect(quote.block, UpgradeBlock.playerLevel);
      expect(quote.reason(RewardRarity.common, 5), contains('kendi seviyeni'));
    });

    test('para bağlıyorsa maliyet söylenir', () {
      final quote = quoteUpgrade(
        resolved: _item(),
        instance: _instance(),
        playerLevel: 50,
        coins: 0,
      );
      expect(quote.block, UpgradeBlock.coins);
      expect(quote.cost, greaterThan(0));
      expect(quote.reason(RewardRarity.common, 50), contains('coin'));
    });

    test('engel yoksa sonraki seviye ve maliyet doğru', () {
      final quote = quoteUpgrade(
        resolved: _item(),
        instance: _instance(level: 3),
        playerLevel: 50,
        coins: 999999,
      );
      expect(quote.canUpgrade, isTrue);
      expect(quote.nextLevel, 4);
      expect(quote.cost, upgradeCostFor(100, RewardRarity.common, 3));
      expect(quote.reason(RewardRarity.common, 50), isNull);
    });
  });

  group('yükseltme maliyeti', () {
    test('seviye yükseldikçe adım maliyeti artar', () {
      for (final rarity in RewardRarity.values) {
        final cap = itemLevelCap(rarity);
        var previous = 0;
        for (var level = 1; level < cap; level++) {
          final cost = upgradeCostFor(1000, rarity, level);
          expect(
            cost,
            greaterThanOrEqualTo(previous),
            reason: '$rarity Sv.$level maliyeti düştü',
          );
          previous = cost;
        }
        expect(
          upgradeCostFor(1000, rarity, cap - 1),
          greaterThan(upgradeCostFor(1000, rarity, 1)),
        );
      }
    });

    test('maliyet 25 katına yuvarlanır ve hiç sıfır olmaz', () {
      for (final rarity in RewardRarity.values) {
        for (var level = 1; level < itemLevelCap(rarity); level++) {
          final cost = upgradeCostFor(100, rarity, level);
          expect(cost % 25, 0);
          expect(cost, greaterThanOrEqualTo(25));
        }
      }
    });

    test('tavana çıkarmak fiyatın ~7 katı tutar', () {
      // Tek sayı, bütün katmanlarda aynı şekil: eğri yalnızca ölçekleniyor.
      for (final entry
          in {
            RewardRarity.common: 100,
            RewardRarity.uncommon: 325,
            RewardRarity.rare: 825,
            RewardRarity.epic: 2600,
            RewardRarity.legendary: 8450,
          }.entries) {
        final ratio = totalUpgradeCost(entry.value, entry.key) / entry.value;
        expect(
          ratio,
          closeTo(GameConstants.itemUpgradeTotalMultiplier, 0.4),
          reason: '${entry.key.name} için toplam maliyet oranı $ratio',
        );
      }
    });

    test('ilk dört katmanda seviye kapısı coin kapısından daha sıkı', () {
      // "Yükseltmek yeni eşya almakla yarışabilir olsun": para gerçek bir
      // maliyet ama duvar değil. En üst katman (efsanevi) bilerek istisna —
      // aylara yayılan bir hedef.
      const prices = {
        RewardRarity.common: 100,
        RewardRarity.uncommon: 325,
        RewardRarity.rare: 825,
        RewardRarity.epic: 2600,
      };
      for (final entry in prices.entries) {
        final cap = itemLevelCap(entry.key);
        final coinDays =
            totalUpgradeCost(entry.value, entry.key) / _coinsPerDay;
        final levelDays =
            GameConstants.baseXpPerLevel / 2 * cap * (cap - 1) / _xpPerDay;
        expect(
          coinDays,
          lessThan(levelDays),
          reason:
              '${entry.key.name}: coin ${coinDays.round()} gün, '
              'seviye ${levelDays.round()} gün',
        );
      }
    });

    test('en ucuz yükseltme en ucuz eşyadan pahalı değil', () {
      // İlk yükseltme, oyuncunun ilk gününde ulaşabileceği bir adım olmalı.
      expect(
        upgradeCostFor(costFor(RewardRarity.common, 1), RewardRarity.common, 1),
        lessThanOrEqualTo(costFor(RewardRarity.common, 1)),
      );
    });
  });

  group('seviye statlara nasıl işliyor', () {
    test('ekonomi bonusları seviyeyle BÜYÜMEZ', () {
      final base = _item();
      for (final level in [1, 2, 5, 10]) {
        final scaled = scaleForLevel(base.buff, level);
        expect(
          scaled.stepCoinBonus,
          base.buff.stepCoinBonus,
          reason: 'Sv.$level adım parası değişti — ekonomi dengesi bozulur',
        );
      }
    });

    test('bütün canlı ekonomi statları sabit kalır', () {
      final base = _item(
        rarity: RewardRarity.legendary,
        effects: const [
          ItemEffect(stat: ItemStat.stepCoin, value: 0.10),
          ItemEffect(stat: ItemStat.stepXp, value: 0.10),
          ItemEffect(stat: ItemStat.wheelXp, value: 0.10),
          ItemEffect(stat: ItemStat.enemyXp, value: 0.10),
          ItemEffect.flat(stat: ItemStat.streakFreezeCap, value: 1),
          ItemEffect.flat(stat: ItemStat.wheelSpinCap, value: 1),
          ItemEffect.flat(stat: ItemStat.streakRelief, value: 200),
        ],
      );
      final scaled = scaleForLevel(base.buff, 50);

      expect(scaled.stepCoinBonus, base.buff.stepCoinBonus);
      expect(scaled.stepXpBonus, base.buff.stepXpBonus);
      expect(scaled.wheelXpBonus, base.buff.wheelXpBonus);
      expect(scaled.enemyXpBonus, base.buff.enemyXpBonus);
      expect(scaled.streakFreezeCapBonus, base.buff.streakFreezeCapBonus);
      expect(scaled.wheelSpinCapBonus, base.buff.wheelSpinCapBonus);
      expect(scaled.streakStepRelief, base.buff.streakStepRelief);
    });

    test('savaş statları seviyeyle büyür', () {
      final base = _item();
      final level10 = scaleForLevel(base.buff, 10);

      double attack(ItemBuff buff) =>
          buff.effects.firstWhere((e) => e.stat == ItemStat.attack).value;
      double defense(ItemBuff buff) =>
          buff.effects.firstWhere((e) => e.stat == ItemStat.defense).value;

      // Sv.10 = ×1.90.
      expect(attack(level10), 19);
      expect(defense(level10), closeTo(0.38, 0.005));
      expect(levelMultiplier(1), 1.0);
      expect(levelMultiplier(10), closeTo(1.9, 1e-9));
      expect(levelMultiplier(50), closeTo(5.9, 1e-9));
    });

    test('çift etkili itemin bedeli de büyür', () {
      // Yükselen bir eşyanın hem gücü hem bedeli artar; yoksa bedel
      // seviyeyle erir ve dezavantaj kendiliğinden yok olur.
      final base = _item(
        effects: const [
          ItemEffect.flat(stat: ItemStat.attack, value: 20),
          ItemEffect(stat: ItemStat.defense, value: -0.20),
        ],
      );
      final scaled = scaleForLevel(base.buff, 6);
      final penalty =
          scaled.effects.firstWhere((e) => e.stat == ItemStat.defense).value;

      expect(penalty, lessThan(-0.20));
    });

    test('seviye 1 buff nesnesini hiç değiştirmez', () {
      final base = _item();
      expect(identical(scaleForLevel(base.buff, 1), base.buff), isTrue);
      expect(identical(scaleForLevel(base.buff, 0), base.buff), isTrue);
    });

    test('bir katmanın tavanı bir üst katmanın tavanını geçemez', () {
      // "Sıradan bir eşya asla efsaneviye yetişemez."
      double maxAttack(RewardRarity rarity) {
        final buff = buffFor(
          rarity,
          ItemCategory.swords,
          archetype: ItemArchetype.striker,
          id: 'swords/probe',
        );
        final scaled = scaleForLevel(buff, itemLevelCap(rarity));
        return scaled.effects
            .firstWhere((e) => e.stat == ItemStat.attack)
            .value;
      }

      var previous = 0.0;
      for (final rarity in RewardRarity.values) {
        final value = maxAttack(rarity);
        expect(
          value,
          greaterThan(previous),
          reason: '${rarity.name} tavanı bir önceki katmanı geçmiyor',
        );
        previous = value;
      }
    });

    test('seviye karşılaştırması yalnızca savaş statlarını listeler', () {
      final lines = compareLevels(_item(), 1, 5);
      expect(lines, isNotEmpty);
      for (final line in lines) {
        expect(line, isNot(contains('adım parası')));
      }
      expect(lines.any((line) => line.contains('saldırı')), isTrue);
    });
  });

  group('örnek çözümleme', () {
    test('seviye 1 örnek katalog item ile aynı', () {
      final base = _item();
      final resolved = resolveOwnedItem(base, _instance());
      expect(resolved.buff.labels, base.buff.labels);
      expect(resolved.rarity, base.rarity);
      expect(resolved.cost, base.cost);
    });

    test('yükseltilmiş örnek savaş statlarını büyütür, fiyatı değiştirmez', () {
      final base = _item();
      final resolved = resolveOwnedItem(base, _instance(level: 5));

      expect(resolved.cost, base.cost);
      expect(resolved.buff.stepCoinBonus, base.buff.stepCoinBonus);
      expect(
        resolved.buff.effects
            .firstWhere((e) => e.stat == ItemStat.attack)
            .value,
        greaterThan(10),
      );
    });

    test('birleştirilmiş örnek yeni nadirlikte çözülür', () {
      final base = _item(requiredLevel: 3);
      final resolved = resolveOwnedItem(
        base,
        _instance(rarity: RewardRarity.rare),
      );

      expect(resolved.rarity, RewardRarity.rare);
      expect(resolved.cost, costFor(RewardRarity.rare, 3));
      // Seviye kilidi **değişmez**: emek verip birleştirdiğin eşya birden
      // kuşanılamaz hâle gelmemeli (GD40).
      expect(resolved.requiredLevel, 3);
      expect(resolved.id, base.id);
    });

    test('imzalı item birleştirilince karakterini korur', () {
      final base = _item(
        rarity: RewardRarity.epic,
        lore: 'Elle dövüldü.',
        effects: const [
          ItemEffect.flat(stat: ItemStat.attack, value: 40),
          ItemEffect(
            stat: ItemStat.critChance,
            value: 0.12,
            trigger: ItemEffectTrigger.lowHealth,
            threshold: 0.3,
          ),
        ],
      );
      final resolved = withRarity(base, RewardRarity.legendary);

      expect(resolved.lore, base.lore);
      expect(resolved.buff.effects, hasLength(2));
      // Koşullu etki koşullu kalır.
      expect(resolved.buff.effects[1].trigger, ItemEffectTrigger.lowHealth);
      // Etkiler büyür.
      expect(resolved.buff.effects[0].value, greaterThan(40));
    });

    test('nadirlik yükselse de tek item ekonomi tavanı aşılmaz', () {
      final base = _item(
        rarity: RewardRarity.common,
        lore: 'Elle dövüldü.',
        effects: const [ItemEffect(stat: ItemStat.stepCoin, value: 0.14)],
      );
      final resolved = withRarity(base, RewardRarity.legendary);

      expect(
        resolved.buff.stepCoinBonus,
        lessThanOrEqualTo(GameConstants.maxSingleItemEconomyBonus + 1e-9),
      );
    });

    test('aynı nadirliğe taşımak nesneyi değiştirmez', () {
      final base = _item();
      expect(identical(withRarity(base, base.rarity), base), isTrue);
    });
  });

  group('örnek modeli', () {
    test('kayıt turu bilgi kaybetmez', () {
      const instance = OwnedItem(
        instanceId: 7,
        itemId: 'swords/sword',
        level: 4,
        rarity: RewardRarity.rare,
        equipped: true,
      );
      final restored = OwnedItem.fromJson(instance.toJson())!;

      expect(restored.instanceId, 7);
      expect(restored.itemId, 'swords/sword');
      expect(restored.level, 4);
      expect(restored.rarity, RewardRarity.rare);
      expect(restored.equipped, isTrue);
    });

    test('bozuk satır null döner, sağlam satır okunur', () {
      expect(OwnedItem.fromJson(null), isNull);
      expect(OwnedItem.fromJson(const {'itemId': 'a/b'}), isNull);
      expect(OwnedItem.fromJson(const {'instanceId': 1}), isNull);
      expect(OwnedItem.fromJson(const {'instanceId': 1, 'itemId': 42}), isNull);

      final ok =
          OwnedItem.fromJson(const {
            'instanceId': 2,
            'itemId': 'a/b',
            'level': 0,
            'rarity': 'yok_boyle_bir_sey',
          })!;
      // Seviye 1'in altına düşmez, tanınmayan nadirlik katalog nadirliğine
      // düşer (kayıt reddedilmez).
      expect(ok.level, 1);
      expect(ok.rarity, isNull);
    });

    test('effectiveRarity katalog nadirliğine düşer', () {
      expect(_instance().effectiveRarity(RewardRarity.epic), RewardRarity.epic);
      expect(
        _instance(rarity: RewardRarity.rare).effectiveRarity(RewardRarity.epic),
        RewardRarity.rare,
      );
    });
  });
}
