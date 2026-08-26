import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/game_constants.dart';
import 'package:rush_for_villains/core/utils/item_rules.dart';
import 'package:rush_for_villains/data/item_definitions.dart';
import 'package:rush_for_villains/data/item_effects.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/item.dart';
import 'package:rush_for_villains/models/item_effect.dart';
import 'package:rush_for_villains/models/reward_rarity.dart';
import 'package:rush_for_villains/services/item_catalog.dart';

/// Bugün oynanabilen sınıflar; tek kaynaktan okunuyor (bkz. GD37).
List<String> get _allClasses => AvatarProfile.playableClassIds;

/// `lib/Items/` altındaki bütün görsel yolları (repo dosya sisteminden).
List<String> _allAssetPaths() {
  final root = Directory('lib/Items');
  return root
      .listSync(recursive: true)
      .whereType<File>()
      .map((file) => file.path.replaceAll(r'\', '/'))
      .where((path) => path.toLowerCase().endsWith('.png'))
      .toList();
}

List<Item> _catalog() => ItemCatalog.fromAssetPaths(_allAssetPaths());

void main() {
  group('efekt etiketi', () {
    test('koşulsuz yüzde etkisi okunur yazılır', () {
      const effect = ItemEffect(stat: ItemStat.stepXp, value: 0.07);
      expect(effect.label, 'adım XP +%7');
      expect(effect.isPassive, isTrue);
    });

    test('sabit savaş artışı birimiyle yazılır', () {
      expect(
        const ItemEffect.flat(stat: ItemStat.attack, value: 12).label,
        'saldırı +12',
      );
    });

    test('seri eşiği artı değerle yazılsa da eksi gösterilir', () {
      // Eşik düştükçe iyileşiyor; "+500 adım" yazmak yanlış olurdu.
      expect(
        const ItemEffect.flat(stat: ItemStat.streakRelief, value: 500).label,
        'seri eşiği -500 adım',
      );
    });

    test('eksi değerli etki eksi yazılır (çift etkili itemler)', () {
      expect(
        const ItemEffect(stat: ItemStat.defense, value: -0.15).label,
        'savunma -%15',
      );
    });

    test('koşullu etki koşulunu söyler', () {
      const effect = ItemEffect(
        stat: ItemStat.attack,
        value: 0.4,
        trigger: ItemEffectTrigger.lowHealth,
        threshold: 0.3,
      );
      expect(effect.label, 'can %30 altındayken saldırı +%40');
      expect(effect.isPassive, isFalse);
    });

    test('tetiklenen etki ihtimalini söyler', () {
      const effect = ItemEffect(
        stat: ItemStat.lifeSteal,
        value: 0.12,
        trigger: ItemEffectTrigger.onHit,
        chance: 0.25,
      );
      expect(effect.label, 'vuruşta %25 ihtimalle can çalma +%12');
      expect(effect.isPassive, isFalse);
    });

    test('eşikli etki tur sayısını söyler', () {
      const effect = ItemEffect(
        stat: ItemStat.critChance,
        value: 0.25,
        trigger: ItemEffectTrigger.untouchedRounds,
        threshold: 3,
      );
      expect(effect.label, '3 tur hasarsız kalınca kritik şansı +%25');
    });

    test('oyun dışı koşullar kendi cümlesini kurar', () {
      expect(
        const ItemEffect(
          stat: ItemStat.stepCoin,
          value: 0.2,
          trigger: ItemEffectTrigger.nightWalk,
        ).label,
        'gece yürüyüşlerinde adım parası +%20',
      );
      expect(
        const ItemEffect(
          stat: ItemStat.stepCoin,
          value: 0.1,
          trigger: ItemEffectTrigger.streakActive,
        ).label,
        'serin ayaktayken adım parası +%10',
      );
    });

    test('serbest metin üretilen cümlenin yerine geçer', () {
      const effect = ItemEffect(
        stat: ItemStat.lifeSteal,
        value: 0.35,
        trigger: ItemEffectTrigger.onKill,
        customLabel: 'düşman yenince canın yarısı geri gelir',
      );
      expect(effect.label, 'düşman yenince canın yarısı geri gelir');
    });
  });

  group('buff toplama', () {
    test('yalnızca koşulsuz etkiler çarpana girer', () {
      const buff = ItemBuff([
        ItemEffect(stat: ItemStat.stepCoin, value: 0.1),
        ItemEffect(
          stat: ItemStat.stepCoin,
          value: 0.5,
          trigger: ItemEffectTrigger.nightWalk,
        ),
        ItemEffect(
          stat: ItemStat.stepCoin,
          value: 0.5,
          trigger: ItemEffectTrigger.onHit,
          chance: 0.2,
        ),
      ]);

      expect(buff.stepCoinBonus, closeTo(0.1, 1e-9));
      expect(buff.count, 3);
      expect(buff.conditionalEffects, hasLength(2));
    });

    test('savaş statları oyun dışı getterlara sızmaz', () {
      const buff = ItemBuff([
        ItemEffect.flat(stat: ItemStat.attack, value: 40),
        ItemEffect(stat: ItemStat.stepXp, value: 0.05),
      ]);

      expect(buff.stepXpBonus, closeTo(0.05, 1e-9));
      expect(buff.stepCoinBonus, 0);
      expect(buff.combatEffects, hasLength(1));
      expect(buff.liveEffects, hasLength(1));
    });

    test('aynı statın iki etkisi toplanır', () {
      const buff = ItemBuff([
        ItemEffect(stat: ItemStat.stepCoin, value: 0.04),
        ItemEffect(stat: ItemStat.stepCoin, value: 0.03),
      ]);
      expect(buff.stepCoinBonus, closeTo(0.07, 1e-9));
    });

    test('sayısal kısayol canlı ekonomi etkilerini korur', () {
      final buff = ItemBuff.stats(stepCoinBonus: 0.075, streakStepRelief: 200);
      expect(buff.labels, ['adım parası +%7,5', 'seri eşiği -200 adım']);
      expect(buff.stepCoinBonus, closeTo(0.075, 1e-9));
      expect(buff.streakStepRelief, 200);
    });
  });

  group('imzalı itemler', () {
    test('bütün epik ve efsanevi temel itemlerin imzası var', () {
      final missing = <String>[];
      ItemDefinitions.entries.forEach((baseId, definition) {
        final rarity = definition.$2;
        if (rarity != RewardRarity.epic && rarity != RewardRarity.legendary) {
          return;
        }
        if (ItemEffects.of(baseId) == null) missing.add(baseId);
      });

      expect(
        missing,
        isEmpty,
        reason: 'ItemEffects.entries içine eklenmesi gereken imzalar: $missing',
      );
    });

    test('imza tablosunda karşılığı olmayan satır yok', () {
      final orphans =
          ItemEffects.entries.keys
              .where((baseId) => ItemDefinitions.of(baseId) == null)
              .toList();
      expect(orphans, isEmpty);
    });

    test('imzalı item kural türetmesini kullanmaz ve lore taşır', () {
      final item = buildItemFromAsset('lib/Items/scythes/reapers_scythe.png')!;

      expect(item.hasSignature, isTrue);
      expect(item.lore, isNotNull);
      expect(item.lore, isNotEmpty);
      expect(
        item.buff.effects,
        ItemEffects.of('scythes/reapers_scythe')!.effects,
      );
    });

    test('imzalı item sınıfa göre değişmez', () {
      final base = buildItemFromAsset('lib/Items/swords/dragons_hook.png')!;
      for (final characterClass in _allClasses) {
        final flavored = flavorForClass(base, characterClass);
        expect(flavored.id, base.id);
        expect(flavored.name, base.name);
        expect(flavored.buff.labels, base.buff.labels);
      }
    });

    test('imzasız item sınıfa göre hâlâ değişir', () {
      final base = buildItemFromAsset('lib/Items/magic/staff_type_1.png')!;
      expect(base.hasSignature, isFalse);
      expect(
        flavorForClass(base, 'Wizard').buff.labels,
        isNot(flavorForClass(base, 'Priest').buff.labels),
      );
    });

    test('her efsanevi item birden fazla etki taşır', () {
      final legendaries =
          _catalog()
              .where((item) => item.rarity == RewardRarity.legendary)
              .toList();

      expect(legendaries, hasLength(18));
      for (final item in legendaries) {
        expect(
          item.buff.count,
          greaterThanOrEqualTo(3),
          reason: '${item.id} efsanevi ama ${item.buff.count} etki taşıyor',
        );
        expect(item.lore, isNotNull, reason: '${item.id} lore taşımıyor');
      }
    });

    test('her efsanevi item bugün de işe yarayan bir etki taşır', () {
      // İmzalı itemler ağırlıkla savaş statı veriyor ve savaş motoru Aşama
      // 4a'da geliyor. En üst katman **bugün** de bir karşılık vermeli;
      // yoksa efsanevi kuşanan oyuncu nadir kuşanandan geri kalır.
      for (final item in _catalog()) {
        if (item.rarity != RewardRarity.legendary) continue;
        final live = item.buff.effects.where(
          (effect) => !effect.stat.isCombat && effect.isPassive,
        );
        expect(
          live,
          isNotEmpty,
          reason: '${item.id} yalnızca savaş statı veriyor',
        );
      }
    });

    test('koşullu, tetiklenen ve çift etkili itemler gerçekten var', () {
      final items = _catalog();

      bool hasTrigger(ItemEffectTrigger trigger) => items.any(
        (item) => item.buff.effects.any((e) => e.trigger == trigger),
      );

      expect(hasTrigger(ItemEffectTrigger.lowHealth), isTrue);
      expect(hasTrigger(ItemEffectTrigger.highHealth), isTrue);
      expect(hasTrigger(ItemEffectTrigger.onHit), isTrue);
      expect(hasTrigger(ItemEffectTrigger.onKill), isTrue);
      expect(hasTrigger(ItemEffectTrigger.untouchedRounds), isTrue);
      expect(hasTrigger(ItemEffectTrigger.nightWalk), isTrue);
      expect(hasTrigger(ItemEffectTrigger.streakActive), isTrue);

      // Çift etkili: bir artı, bir eksi.
      final dual = items.where(
        (item) =>
            item.buff.effects.any((e) => e.value > 0) &&
            item.buff.effects.any((e) => e.value < 0),
      );
      expect(dual, isNotEmpty);
    });

    test('savaş statları bugün hiçbir çarpana dokunmuyor', () {
      for (final item in _catalog()) {
        for (final effect in item.buff.combatEffects) {
          expect(effect.isDormant, isTrue);
        }
      }
    });
  });

  group('ekonomi tavanı', () {
    test('hiçbir item tek başına tavanı aşmıyor', () {
      final offenders = <String>[];
      for (final item in _catalog()) {
        for (final characterClass in [null, ..._allClasses]) {
          final resolved =
              characterClass == null
                  ? item
                  : flavorForClass(item, characterClass);
          for (final stat in ItemStat.values) {
            if (!stat.isEconomyRate) continue;
            var total = 0.0;
            for (final effect in resolved.buff.effects) {
              if (effect.stat == stat && effect.isPassive) {
                total += effect.value;
              }
            }
            if (total > GameConstants.maxSingleItemEconomyBonus + 1e-9) {
              offenders.add('${item.id}/$characterClass ${stat.name}=$total');
            }
          }
        }
      }
      expect(offenders, isEmpty, reason: 'tavanı aşanlar: $offenders');
    });

    test('koşullu etkiler tavana dahil değil ama abartılı da değil', () {
      // Koşullu ekonomi etkileri çarpana girmiyor; yine de tek bir koşullu
      // etkinin tavanın iki katını aşmaması bilinçli bir sınır.
      for (final item in _catalog()) {
        for (final effect in item.buff.effects) {
          if (!effect.stat.isEconomyRate || effect.isPassive) continue;
          expect(
            effect.value.abs(),
            lessThanOrEqualTo(GameConstants.maxSingleItemEconomyBonus * 2),
            reason: '${item.id}: ${effect.label}',
          );
        }
      }
    });

    test('kural türetmesi çark ve düşman XPsini de tavana kırpıyor', () {
      // İki katına çıkarma efsanevide %26'ya kadar çıkıyordu.
      final buff = buffFor(
        RewardRarity.legendary,
        ItemCategory.magic,
        characterClass: 'DarkMagic',
        id: 'magic/x',
      );
      expect(
        buff.wheelXpBonus,
        lessThanOrEqualTo(GameConstants.maxSingleItemEconomyBonus + 1e-9),
      );
    });
  });

  group('varyant adları', () {
    test('aynı temel itemin varyantları farklı sıfat alır', () {
      final names = <String>{};
      for (var variant = 1; variant <= 28; variant++) {
        names.add(variantAdjective('magic/staff_type_1', variant));
      }
      expect(names, hasLength(28));
    });

    test('sıfat kimlikten kararlı türer', () {
      expect(
        variantAdjective('swords/dagger', 3),
        variantAdjective('swords/dagger', 3),
      );
    });

    test('sıfat sınıfa göre kayar', () {
      final classNames = {
        for (final characterClass in _allClasses)
          variantAdjective('swords/dagger', 1, characterClass: characterClass),
      };
      // Sekiz sınıf en az iki farklı sıfat üretmeli; hepsi aynıysa sınıf
      // farkı adda hiç görünmez.
      expect(classNames.length, greaterThan(1));
    });

    test('varyant adında numara kalmadı', () {
      for (final item in _catalog()) {
        expect(
          RegExp(r'\s\d+$').hasMatch(item.name),
          isFalse,
          reason: '${item.id} hâlâ numarayla bitiyor: ${item.name}',
        );
      }
    });

    test('varyantlı imzalı item adında temel ad tanınabilir kalır', () {
      // Varyantı olan iki epik var; adları isimle başladığı için sıfat
      // eklenmesi sorun değil, ama ad yine de tanınabilir kalmalı.
      final item =
          buildItemFromAsset(
            'lib/Items/shields/full_plate_coffin_shield_variant_03.png',
          )!;
      expect(item.name, endsWith('Lahit Kalkanı'));
      expect(item.hasSignature, isTrue);
    });
  });

  group('ad benzersizliği', () {
    test('katalogdaki hiçbir ad tekrar etmiyor', () {
      final items = _catalog();
      final byName = <String, List<String>>{};
      for (final item in items) {
        byName.putIfAbsent(item.name, () => []).add(item.id);
      }
      final duplicates = {
        for (final entry in byName.entries)
          if (entry.value.length > 1) entry.key: entry.value,
      };
      expect(duplicates, isEmpty, reason: 'tekrar eden adlar: $duplicates');
    });

    test('her sınıfın gördüğü listede de ad tekrar etmiyor', () {
      ItemCatalog.reset(_catalog());
      addTearDown(ItemCatalog.reset);

      for (final characterClass in _allClasses) {
        final names =
            ItemCatalog.forCharacterClass(
              characterClass,
            ).map((item) => item.name).toList();
        expect(
          names.toSet(),
          hasLength(names.length),
          reason: '$characterClass için ad tekrarı var',
        );
      }
    });

    test('temel adlar da benzersiz', () {
      final names = ItemDefinitions.entries.values.map((e) => e.$1).toList();
      expect(names.toSet(), hasLength(names.length));
    });
  });
}
