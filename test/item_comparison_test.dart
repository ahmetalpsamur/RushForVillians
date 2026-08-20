import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/utils/item_comparison.dart';
import 'package:rush_for_villains/models/item.dart';
import 'package:rush_for_villains/models/item_effect.dart';
import 'package:rush_for_villains/models/reward_rarity.dart';

Item _item(String id, List<ItemEffect> effects) => Item(
  id: id,
  name: id,
  assetPath: 'lib/Items/swords/$id.png',
  category: ItemCategory.swords,
  rarity: RewardRarity.common,
  requiredLevel: 1,
  cost: 100,
  buff: ItemBuff(effects),
);

void main() {
  group('sayısal fark', () {
    test('boş slota kuşanınca adayın tamamı kazanç', () {
      final comparison = compareItems(
        candidate: _item('a', const [
          ItemEffect.flat(stat: ItemStat.attack, value: 8),
        ]),
      );

      expect(comparison.deltas, hasLength(1));
      expect(comparison.deltas.single.label, '+8 saldırı');
      expect(comparison.deltas.single.isGain, isTrue);
    });

    test('aynı statta artı ve eksi fark birlikte çıkar', () {
      final comparison = compareItems(
        candidate: _item('yeni', const [
          ItemEffect.flat(stat: ItemStat.attack, value: 20),
          ItemEffect(stat: ItemStat.defense, value: 0.05),
        ]),
        current: _item('eski', const [
          ItemEffect.flat(stat: ItemStat.attack, value: 12),
          ItemEffect(stat: ItemStat.defense, value: 0.08),
        ]),
      );

      final labels = comparison.ordered.map((delta) => delta.label).toList();
      expect(labels, ['+8 saldırı', '-%3 savunma']);
      // Kazançlar önce sıralanır.
      expect(comparison.ordered.first.isGain, isTrue);
      expect(comparison.ordered.last.isGain, isFalse);
    });

    test('denk itemler fark üretmez', () {
      const effects = [ItemEffect(stat: ItemStat.stepCoin, value: 0.05)];
      final comparison = compareItems(
        candidate: _item('a', effects),
        current: _item('b', effects),
      );
      expect(comparison.isEmpty, isTrue);
      expect(comparison.deltas, isEmpty);
    });

    test('sabit ve oransal aynı statta ayrı satır olur', () {
      final comparison = compareItems(
        candidate: _item('a', const [
          ItemEffect.flat(stat: ItemStat.attack, value: 10),
          ItemEffect(stat: ItemStat.attack, value: 0.2),
        ]),
      );
      expect(comparison.deltas, hasLength(2));
      expect(
        comparison.deltas.map((d) => d.label),
        containsAll(['+10 saldırı', '+%20 saldırı']),
      );
    });

    test('aynı statın iki etkisi toplanıp tek fark olur', () {
      final comparison = compareItems(
        candidate: _item('a', const [
          ItemEffect(stat: ItemStat.stepCoin, value: 0.04),
          ItemEffect(stat: ItemStat.stepCoin, value: 0.03),
        ]),
      );
      expect(comparison.deltas, hasLength(1));
      expect(comparison.deltas.single.label, '+%7 adım parası');
    });

    test('seri eşiği farkı birimiyle yazılır', () {
      final comparison = compareItems(
        candidate: _item('a', const [
          ItemEffect.flat(stat: ItemStat.streakRelief, value: 300),
        ]),
        current: _item('b', const [
          ItemEffect.flat(stat: ItemStat.streakRelief, value: 100),
        ]),
      );
      // Eşik düştükçe iyileşiyor: artı fark eksi olarak yazılır.
      expect(comparison.deltas.single.label, 'seri eşiği -200 adım');
      expect(comparison.deltas.single.isGain, isTrue);
    });
  });

  group('koşullu etkiler', () {
    test('koşullu etki sayıya indirgenmez', () {
      final comparison = compareItems(
        candidate: _item('a', const [
          ItemEffect(
            stat: ItemStat.attack,
            value: 0.4,
            trigger: ItemEffectTrigger.lowHealth,
            threshold: 0.3,
          ),
        ]),
      );

      expect(comparison.deltas, isEmpty);
      expect(comparison.gainedConditions, ['can %30 altındayken saldırı +%40']);
    });

    test('kaybedilen koşul ayrı listelenir', () {
      final comparison = compareItems(
        candidate: _item('yeni', const []),
        current: _item('eski', const [
          ItemEffect(
            stat: ItemStat.stepCoin,
            value: 0.2,
            trigger: ItemEffectTrigger.nightWalk,
          ),
        ]),
      );

      expect(comparison.gainedConditions, isEmpty);
      expect(comparison.lostConditions, [
        'gece yürüyüşlerinde adım parası +%20',
      ]);
    });

    test('ortak koşul ne kazanç ne kayıp sayılır', () {
      const shared = ItemEffect(
        stat: ItemStat.lifeSteal,
        value: 0.1,
        trigger: ItemEffectTrigger.onHit,
        chance: 0.2,
      );
      final comparison = compareItems(
        candidate: _item('a', const [shared]),
        current: _item('b', const [shared]),
      );
      expect(comparison.isEmpty, isTrue);
    });
  });

  test('ItemComparison.none boştur', () {
    expect(ItemComparison.none.isEmpty, isTrue);
    expect(ItemComparison.none.ordered, isEmpty);
  });
}
