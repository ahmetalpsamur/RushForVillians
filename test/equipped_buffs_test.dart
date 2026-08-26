import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/game_constants.dart';
import 'package:rush_for_villains/core/utils/equipped_buffs.dart';
import 'package:rush_for_villains/core/utils/item_rules.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/item.dart';
import 'package:rush_for_villains/models/item_effect.dart';
import 'package:rush_for_villains/models/reward_rarity.dart';
import 'package:rush_for_villains/services/item_catalog.dart';

/// Bugün oynanabilen sınıflar; tek kaynaktan okunuyor (bkz. GD37).
List<String> get _allClasses => AvatarProfile.playableClassIds;

Item _item(String id, List<ItemEffect> effects) => Item(
  id: id,
  name: id,
  assetPath: 'lib/Items/swords/$id.png',
  category: ItemCategory.swords,
  rarity: RewardRarity.common,
  requiredLevel: 1,
  cost: 100,
  buff: ItemBuff(effects),
  archetype: ItemArchetype.striker,
);

List<Item> _catalog() {
  final paths =
      Directory('lib/Items')
          .listSync(recursive: true)
          .whereType<File>()
          .map((file) => file.path.replaceAll(r'\', '/'))
          .where((path) => path.toLowerCase().endsWith('.png'))
          .toList();
  return ItemCatalog.fromAssetPaths(paths);
}

void main() {
  group('toplama', () {
    test('boş kuşanma hiçbir şey değiştirmez', () {
      final buffs = EquippedBuffs.from(const []);
      expect(buffs.isEmpty, isTrue);
      expect(buffs.stepCoinMultiplier, 1);
      expect(buffs.stepXpMultiplier, 1);
      expect(buffs.dailyCoinCap, GameConstants.maxDailyStepCoins);
      expect(buffs.streakFreezeCap, GameConstants.maxStreakFreezes);
      expect(buffs.wheelSpinCap, GameConstants.maxExtraWheelSpins);
      expect(buffs.streakStepThreshold, GameConstants.streakStepThreshold);
    });

    test('EquippedBuffs.none boş toplamayla aynı', () {
      expect(EquippedBuffs.none.isEmpty, isTrue);
      expect(EquippedBuffs.none.dailyCoinCap, GameConstants.maxDailyStepCoins);
    });

    test('aynı statı veren itemler toplanır', () {
      final buffs = EquippedBuffs.from([
        _item('a', const [ItemEffect(stat: ItemStat.stepCoin, value: 0.05)]),
        _item('b', const [ItemEffect(stat: ItemStat.stepCoin, value: 0.07)]),
      ]);
      expect(buffs.stepCoinBonus, closeTo(0.12, 1e-9));
      expect(buffs.stepCoinMultiplier, closeTo(1.12, 1e-9));
    });

    test('eski coin tavanı bonusu adım parasına dönüşür', () {
      final buffs = EquippedBuffs.from([
        _item('a', const [
          ItemEffect.flat(stat: ItemStat.dailyCoinCap, value: 40),
          ItemEffect.flat(stat: ItemStat.streakRelief, value: 300),
        ]),
        _item('b', const [
          ItemEffect.flat(stat: ItemStat.dailyCoinCap, value: 60),
          ItemEffect.flat(stat: ItemStat.streakFreezeCap, value: 1),
          ItemEffect.flat(stat: ItemStat.wheelSpinCap, value: 1),
        ]),
      ]);

      expect(buffs.stepCoinBonus, closeTo(0.25, 1e-9));
      expect(buffs.dailyCoinCapBonus, 0);
      expect(
        buffs.streakStepThreshold,
        GameConstants.streakStepThreshold - 300,
      );
      expect(buffs.streakFreezeCap, GameConstants.maxStreakFreezes + 1);
      expect(buffs.wheelSpinCap, GameConstants.maxExtraWheelSpins + 1);
    });

    test('koşullu etkiler çarpana girmez, ayrı listede taşınır', () {
      final buffs = EquippedBuffs.from([
        _item('a', const [
          ItemEffect(
            stat: ItemStat.stepCoin,
            value: 0.4,
            trigger: ItemEffectTrigger.nightWalk,
          ),
        ]),
      ]);

      expect(buffs.stepCoinBonus, 0);
      expect(buffs.isEmpty, isTrue);
      expect(buffs.conditionalEffects, hasLength(1));
    });

    test('savaş etkileri ayrı listede ve çarpana girmez', () {
      final buffs = EquippedBuffs.from([
        _item('a', const [
          ItemEffect.flat(stat: ItemStat.attack, value: 40),
          ItemEffect(stat: ItemStat.defense, value: 0.25),
        ]),
      ]);

      expect(buffs.isEmpty, isTrue);
      expect(buffs.combatEffects, hasLength(2));
      expect(buffs.flatBonusFor(ItemStat.attack), 40);
      expect(buffs.rateBonusFor(ItemStat.defense), closeTo(0.25, 1e-9));
      expect(buffs.touchedCombatStats, [ItemStat.attack, ItemStat.defense]);
    });

    test('eksi savaş etkisi toplamı düşürür (çift etkili itemler)', () {
      final buffs = EquippedBuffs.from([
        _item('a', const [
          ItemEffect(stat: ItemStat.defense, value: 0.3),
          ItemEffect(stat: ItemStat.defense, value: -0.18),
        ]),
      ]);
      expect(buffs.rateBonusFor(ItemStat.defense), closeTo(0.12, 1e-9));
    });
  });

  group('tavanlar', () {
    test('oyun dışı oran toplamı %50yi geçemez', () {
      final buffs = EquippedBuffs.from([
        for (var i = 0; i < 5; i++)
          _item('item$i', const [
            ItemEffect(stat: ItemStat.stepCoin, value: 0.15),
            ItemEffect(stat: ItemStat.stepXp, value: 0.15),
          ]),
      ]);

      // Ham toplam %75 olurdu.
      expect(buffs.stepCoinBonus, GameConstants.maxEquippedEconomyBonus);
      expect(buffs.stepXpBonus, GameConstants.maxEquippedEconomyBonus);
      expect(buffs.stepCoinMultiplier, closeTo(1.5, 1e-9));
    });

    test('eski coin tavanı bonusu toplam ekonomi tavanını aşmaz', () {
      final buffs = EquippedBuffs.from([
        for (var i = 0; i < 5; i++)
          _item('item$i', const [
            ItemEffect.flat(stat: ItemStat.dailyCoinCap, value: 120),
          ]),
      ]);
      expect(buffs.dailyCoinCapBonus, 0);
      expect(buffs.stepCoinBonus, GameConstants.maxEquippedEconomyBonus);
    });

    test('stok bonusları sınırlı', () {
      final buffs = EquippedBuffs.from([
        for (var i = 0; i < 5; i++)
          _item('item$i', const [
            ItemEffect.flat(stat: ItemStat.streakFreezeCap, value: 2),
            ItemEffect.flat(stat: ItemStat.wheelSpinCap, value: 2),
          ]),
      ]);
      expect(buffs.streakFreezeCapBonus, GameConstants.maxEquippedStockBonus);
      expect(buffs.wheelSpinCapBonus, GameConstants.maxEquippedStockBonus);
    });

    test('seri eşiği tabanın yarısının altına inmez', () {
      final buffs = EquippedBuffs.from([
        for (var i = 0; i < 5; i++)
          _item('item$i', const [
            ItemEffect.flat(stat: ItemStat.streakRelief, value: 900),
          ]),
      ]);
      expect(buffs.streakStepRelief, GameConstants.maxEquippedStreakRelief);
      expect(
        buffs.streakStepThreshold,
        GameConstants.streakStepThreshold -
            GameConstants.maxEquippedStreakRelief,
      );
      expect(buffs.streakStepThreshold, greaterThan(0));
    });
  });

  group('gerçek katalogla en kötü durum', () {
    test('aktif katalog kaldırılmış günlük tavan etkisini üretmez', () {
      for (final item in _catalog()) {
        for (final characterClass in [null, ..._allClasses]) {
          final resolved =
              characterClass == null
                  ? item
                  : flavorForClass(item, characterClass);
          expect(
            resolved.buff.effects.any(
              (effect) => effect.stat == ItemStat.dailyCoinCap,
            ),
            isFalse,
            reason: '${item.id} / $characterClass',
          );
        }
      }
    });

    test('her sınıfın en güçlü kuşanması tavanı aşmıyor', () {
      final catalog = _catalog();

      for (final characterClass in _allClasses) {
        final usable =
            catalog
                .where((item) => item.isUsableBy(characterClass))
                .map((item) => flavorForClass(item, characterClass))
                .toList();

        // Slot = kategori; her kategoriden o statı en çok veren item seçilir.
        for (final stat in [
          ItemStat.stepCoin,
          ItemStat.stepXp,
          ItemStat.wheelXp,
          ItemStat.enemyXp,
        ]) {
          final best = <ItemCategory, Item>{};
          for (final item in usable) {
            final value = item.buff.effects
                .where((e) => e.stat == stat && e.isPassive)
                .fold<double>(0, (sum, e) => sum + e.value);
            final current = best[item.category];
            final currentValue =
                current == null
                    ? -1.0
                    : current.buff.effects
                        .where((e) => e.stat == stat && e.isPassive)
                        .fold<double>(0, (sum, e) => sum + e.value);
            if (value > currentValue) best[item.category] = item;
          }

          final buffs = EquippedBuffs.from(best.values);
          expect(
            buffs.rateBonusFor(stat),
            lessThanOrEqualTo(GameConstants.maxEquippedEconomyBonus + 1e-9),
            reason: '$characterClass / ${stat.name}',
          );
        }
      }
    });

    test('gerçekçi kuşanmada çarpan makul bandda kalıyor', () {
      // Her kategoriden **rastgele değil, en yüksek seviyeli** item: oyuncunun
      // uzun vadede varacağı yer. Toplamın kırpmaya dayanmadan makul kalması
      // item tasarımının doğru olduğunu gösterir.
      final catalog = _catalog();
      final usable =
          catalog
              .where((item) => item.isUsableBy('Archer'))
              .map((item) => flavorForClass(item, 'Archer'))
              .toList();

      final best = <ItemCategory, Item>{};
      for (final item in usable) {
        final current = best[item.category];
        if (current == null || item.rarity.index > current.rarity.index) {
          best[item.category] = item;
        }
      }

      final buffs = EquippedBuffs.from(best.values);
      // Okçunun imzası adım parası; en iyi ekipmanla bile kırpmaya
      // dayanmadan tavanın altında kalmalı.
      expect(
        buffs.stepCoinBonus,
        lessThan(GameConstants.maxEquippedEconomyBonus),
      );
      expect(buffs.stepCoinBonus, greaterThan(0));
    });
  });
}
