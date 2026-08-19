import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/utils/item_rules.dart';
import 'package:rush_for_villains/data/item_definitions.dart';
import 'package:rush_for_villains/models/item.dart';
import 'package:rush_for_villains/models/reward_rarity.dart';
import 'package:rush_for_villains/services/item_catalog.dart';

/// Item kataloğu sanat klasöründen üretiliyor; kod yalnızca dosya adına anlam
/// veriyor. Bu testler iki şeyi koruyor: türetme kurallarının kararlılığı
/// (seviye kilidi kayarsa oyuncunun sahip olduğu item kilitlenir) ve sanatın
/// tamamının tanımlı olması.
void main() {
  group('asset yolu çözümleme', () {
    test('varyantsız dosya çözümlenir', () {
      final identity = parseItemAsset('lib/Items/swords/fire_sword.png');

      expect(identity, isNotNull);
      expect(identity!.id, 'swords/fire_sword');
      expect(identity.baseId, 'swords/fire_sword');
      expect(identity.category, ItemCategory.swords);
      expect(identity.variant, isNull);
    });

    test('varyantlı dosyada temel kimlik ayrılır', () {
      final identity = parseItemAsset('lib/Items/swords/dagger_variant_03.png');

      expect(identity!.id, 'swords/dagger_variant_03');
      expect(identity.baseId, 'swords/dagger');
      expect(identity.variant, 3);
    });

    test('alt çizgili kategori klasörü tanınır', () {
      final identity = parseItemAsset(
        'lib/Items/axes_halberds/axe_type_1_variant_02.png',
      );

      expect(identity!.category, ItemCategory.axesHalberds);
      expect(identity.baseId, 'axes_halberds/axe_type_1');
      expect(identity.variant, 2);
    });

    test('tanınmayan yollar atlanır', () {
      expect(parseItemAsset('lib/Characters/Archer/a.png'), isNull);
      expect(parseItemAsset('lib/Items/swords/notes.txt'), isNull);
      expect(parseItemAsset('lib/Items/unknown_folder/thing.png'), isNull);
      expect(parseItemAsset('lib/Items/swords/sub/deep.png'), isNull);
      expect(parseItemAsset('lib/Items/swords/.png'), isNull);
    });
  });

  group('kararlı dağılım', () {
    test('aynı kimlik her zaman aynı değeri verir', () {
      expect(
        stableSpread('swords/fire_sword', 5),
        stableSpread('swords/fire_sword', 5),
      );
    });

    test('değer aralığın içinde kalır', () {
      for (final id in [
        'a',
        'swords/dagger_variant_07',
        'magic/staff_type_1',
      ]) {
        expect(stableSpread(id, 8), inInclusiveRange(0, 7));
      }
    });

    test('tek kovada her zaman sıfır', () {
      expect(stableSpread('swords/dagger', 1), 0);
      expect(stableSpread('swords/dagger', 0), 0);
    });

    test('farklı kimlikler dağılır', () {
      final values = <int>{
        for (var i = 1; i <= 7; i++)
          stableSpread('swords/dagger_variant_0$i', 3),
      };

      expect(
        values.length,
        greaterThan(1),
        reason: 'hepsi aynı kovaya düşmemeli',
      );
    });
  });

  group('seviye kilidi (#10)', () {
    test('nadirlik yükseldikçe kilit yükselir', () {
      int lowest(RewardRarity rarity) => requiredLevelFor(rarity, 'x/y');

      expect(
        lowest(RewardRarity.common),
        lessThan(lowest(RewardRarity.uncommon)),
      );
      expect(
        lowest(RewardRarity.uncommon),
        lessThan(lowest(RewardRarity.rare)),
      );
      expect(lowest(RewardRarity.rare), lessThan(lowest(RewardRarity.epic)));
      expect(
        lowest(RewardRarity.epic),
        lessThan(lowest(RewardRarity.legendary)),
      );
    });

    test('sıradan itemler ilk seviyelerde açılır', () {
      for (final id in [
        'swords/sword',
        'swords/knife',
        'shields/round_shield',
      ]) {
        expect(
          requiredLevelFor(RewardRarity.common, id),
          inInclusiveRange(1, 3),
        );
      }
    });

    test('efsanevi itemler bandının dışına taşmaz', () {
      for (final id in ['scythes/reapers_scythe', 'magic/time_wardens_book']) {
        expect(
          requiredLevelFor(RewardRarity.legendary, id),
          inInclusiveRange(22, 29),
        );
      }
    });
  });

  group('fiyat', () {
    test('nadirlik yükseldikçe fiyat yükselir', () {
      expect(
        costFor(RewardRarity.common, 2),
        lessThan(costFor(RewardRarity.rare, 2)),
      );
      expect(
        costFor(RewardRarity.rare, 2),
        lessThan(costFor(RewardRarity.epic, 2)),
      );
      expect(
        costFor(RewardRarity.epic, 2),
        lessThan(costFor(RewardRarity.legendary, 2)),
      );
    });

    test('aynı nadirlikte yüksek seviye daha pahalı', () {
      expect(
        costFor(RewardRarity.rare, 8),
        lessThan(costFor(RewardRarity.rare, 12)),
      );
    });

    test('fiyat 25in katı', () {
      for (final rarity in RewardRarity.values) {
        for (var level = 1; level <= 30; level++) {
          expect(costFor(rarity, level) % 25, 0);
        }
      }
    });

    test('en ucuz item günlük coin tavanının altında', () {
      // Günlük tavan 400 coin; ilk item bir günden kısa sürede alınabilmeli.
      expect(costFor(RewardRarity.common, 1), lessThan(400));
    });
  });

  group('buff dağılımı', () {
    test('yakın dövüş XP verir', () {
      final buff = buffFor(RewardRarity.rare, ItemCategory.swords);

      expect(buff.stepXpBonus, greaterThan(0));
      expect(buff.stepCoinBonus, 0);
    });

    test('menzil ve savunma para verir', () {
      for (final category in [ItemCategory.arch, ItemCategory.shields]) {
        final buff = buffFor(RewardRarity.rare, category);
        expect(buff.stepCoinBonus, greaterThan(0));
        expect(buff.stepXpBonus, 0);
      }
    });

    test('büyü ikisini yarı yarıya paylaştırır', () {
      final buff = buffFor(RewardRarity.epic, ItemCategory.magic);

      expect(buff.stepCoinBonus, buff.stepXpBonus);
      expect(buff.stepCoinBonus + buff.stepXpBonus, closeTo(0.12, 1e-9));
    });

    test('nadirlik yükseldikçe toplam bonus büyür', () {
      double total(RewardRarity rarity) {
        final buff = buffFor(rarity, ItemCategory.swords);
        return buff.stepCoinBonus + buff.stepXpBonus;
      }

      expect(total(RewardRarity.common), lessThan(total(RewardRarity.rare)));
      expect(total(RewardRarity.rare), lessThan(total(RewardRarity.legendary)));
    });

    test('bonusu olmayan buff etiket üretmez', () {
      expect(ItemBuff.none.isEmpty, isTrue);
      expect(ItemBuff.none.label, isNull);
    });

    test('etiket yüzdeyi okunur yazar', () {
      expect(const ItemBuff(stepXpBonus: 0.07).label, 'adım XP +%7');
      expect(
        const ItemBuff(stepCoinBonus: 0.06, stepXpBonus: 0.06).label,
        'adım parası +%6 · adım XP +%6',
      );
    });
  });

  group('item üretimi', () {
    test('tanımlı item Türkçe adını alır', () {
      final item = buildItemFromAsset('lib/Items/swords/fire_sword.png');

      expect(item!.name, 'Ateş Kılıcı');
      expect(item.rarity, RewardRarity.rare);
      expect(item.assetPath, 'lib/Items/swords/fire_sword.png');
      expect(item.category, ItemCategory.swords);
    });

    test('varyant numarası ada eklenir', () {
      final item = buildItemFromAsset('lib/Items/swords/dagger_variant_04.png');

      expect(item!.name, 'Hançer 4');
      expect(item.id, 'swords/dagger_variant_04');
    });

    test('tanımsız görsel atılmaz, İngilizce adla gelir', () {
      final item = buildItemFromAsset('lib/Items/swords/mystery_blade.png');

      expect(item, isNotNull);
      expect(item!.name, 'Mystery Blade');
      expect(item.rarity, ItemDefinitions.fallbackRarity);
    });

    test('seviye kilidi ve fiyat türetilen değerlerle tutarlı', () {
      final item = buildItemFromAsset('lib/Items/scythes/reapers_scythe.png')!;

      expect(item.requiredLevel, requiredLevelFor(item.rarity, item.id));
      expect(item.cost, costFor(item.rarity, item.requiredLevel));
    });

    test('sınıf kısıtı ve seviye kilidi sorgulanabilir', () {
      final item = buildItemFromAsset('lib/Items/arch/longbow.png')!;

      expect(item.isUsableBy('Archer'), isTrue);
      expect(item.isUsableBy('Nature'), isTrue);
      expect(item.isUsableBy('Paladin'), isFalse);
      expect(item.isUnlockedAt(item.requiredLevel), isTrue);
      expect(item.isUnlockedAt(item.requiredLevel - 1), isFalse);
    });
  });

  group('katalog', () {
    tearDown(ItemCatalog.reset);

    test('tanınmayan yollar katalog dışında kalır', () {
      final items = ItemCatalog.fromAssetPaths([
        'lib/Items/swords/sword.png',
        'lib/Characters/Archer/a.png',
        'AssetManifest.json',
        'lib/Items/magic/staff_type_1.png',
      ]);

      expect(items, hasLength(2));
    });

    test('sıralama kararlı: kategori, seviye, kimlik', () {
      final first = ItemCatalog.fromAssetPaths([
        'lib/Items/magic/staff_type_1.png',
        'lib/Items/swords/sword.png',
        'lib/Items/swords/knife.png',
      ]);
      final second = ItemCatalog.fromAssetPaths([
        'lib/Items/swords/knife.png',
        'lib/Items/magic/staff_type_1.png',
        'lib/Items/swords/sword.png',
      ]);

      expect(
        first.map((item) => item.id),
        second.map((item) => item.id),
        reason: 'giriş sırası sonucu değiştirmemeli',
      );
      expect(first.first.category, ItemCategory.swords);
    });

    test('kimlikten item çözülür, bilinmeyen kimlik null döner', () {
      ItemCatalog.reset(
        ItemCatalog.fromAssetPaths(['lib/Items/swords/sword.png']),
      );

      expect(ItemCatalog.byId('swords/sword'), isNotNull);
      expect(ItemCatalog.byId('swords/silinmis_item'), isNull);
    });

    test('seviye ve sınıf süzgeçleri çalışır', () {
      ItemCatalog.reset(
        ItemCatalog.fromAssetPaths([
          'lib/Items/swords/sword.png',
          'lib/Items/scythes/reapers_scythe.png',
          'lib/Items/arch/longbow.png',
        ]),
      );

      expect(ItemCatalog.unlockedAt(1).length, lessThan(3));
      expect(ItemCatalog.unlockedAt(40), hasLength(3));
      expect(ItemCatalog.forCharacterClass('Archer').map((item) => item.id), [
        'arch/longbow',
      ]);
      expect(ItemCatalog.byCategory(ItemCategory.scythes), hasLength(1));
      expect(ItemCatalog.byRarity(RewardRarity.legendary), hasLength(1));
    });

    test('yüklenmemiş katalog boştur, çökmez', () {
      expect(ItemCatalog.items, isEmpty);
      expect(ItemCatalog.byId('swords/sword'), isNull);
      expect(ItemCatalog.unlockedAt(50), isEmpty);
    });
  });

  // Sanat klasörünün tamamı gerçekten oyuna giriyor mu? Bu grup dosya
  // sistemini okur; yeni görsel eklenip tanımı unutulursa burada yakalanır.
  group('sanat kapsamı', () {
    final itemsRoot = Directory('lib/Items');

    List<String> allAssetPaths() =>
        itemsRoot
            .listSync(recursive: true)
            .whereType<File>()
            .map((file) => file.path.replaceAll(r'\', '/'))
            .where((path) => path.toLowerCase().endsWith('.png'))
            .toList();

    test('Items klasörü bulunur', () {
      expect(itemsRoot.existsSync(), isTrue);
    });

    test('bütün görseller katalog item\'ına dönüşür', () {
      final paths = allAssetPaths();
      final items = ItemCatalog.fromAssetPaths(paths);

      expect(paths, isNotEmpty);
      expect(
        items,
        hasLength(paths.length),
        reason: 'hiçbir görsel sessizce düşmemeli',
      );
    });

    test('kimlikler benzersiz', () {
      final items = ItemCatalog.fromAssetPaths(allAssetPaths());
      final ids = items.map((item) => item.id).toSet();

      expect(ids, hasLength(items.length));
    });

    test('her görselin Türkçe tanımı var', () {
      final missing =
          allAssetPaths()
              .map(parseItemAsset)
              .whereType<ItemAssetIdentity>()
              .map((identity) => identity.baseId)
              .where((baseId) => ItemDefinitions.of(baseId) == null)
              .toSet();

      expect(
        missing,
        isEmpty,
        reason:
            'ItemDefinitions.entries içine eklenmesi gereken temel adlar: '
            '$missing',
      );
    });

    test('tanımlarda karşılığı olmayan satır yok', () {
      final baseIds =
          allAssetPaths()
              .map(parseItemAsset)
              .whereType<ItemAssetIdentity>()
              .map((identity) => identity.baseId)
              .toSet();
      final orphans =
          ItemDefinitions.entries.keys
              .where((key) => !baseIds.contains(key))
              .toSet();

      expect(orphans, isEmpty, reason: 'görseli silinmiş tanımlar: $orphans');
    });

    test('bütün kategoriler pubspec.yaml içinde kayıtlı', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();

      for (final category in ItemCategory.values) {
        expect(
          pubspec.contains('lib/Items/${category.folder}/'),
          isTrue,
          reason: '${category.folder} asset olarak eklenmemiş',
        );
      }
    });

    test('her karakter sınıfının kuşanabileceği item var', () {
      final items = ItemCatalog.fromAssetPaths(allAssetPaths());
      const classes = [
        'Archer',
        'DarkMagic',
        'Faith',
        'Magic',
        'Nature',
        'Paladin',
        'SwordMan',
        'Thief',
      ];

      for (final characterClass in classes) {
        expect(
          items.any((item) => item.isUsableBy(characterClass)),
          isTrue,
          reason: '$characterClass için item yok',
        );
      }
    });

    test('ilk seviyede alınabilecek item var', () {
      final items = ItemCatalog.fromAssetPaths(allAssetPaths());

      expect(
        items.any((item) => item.requiredLevel == 1),
        isTrue,
        reason: 'yeni oyuncu hiçbir şey alamazsa mağaza ölü kalır',
      );
    });
  });
}
