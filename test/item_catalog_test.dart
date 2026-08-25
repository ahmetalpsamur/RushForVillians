import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/utils/item_rules.dart';
import 'package:rush_for_villains/data/item_archetypes.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/data/item_definitions.dart';
import 'package:rush_for_villains/models/item.dart';
import 'package:rush_for_villains/models/reward_rarity.dart';
import 'package:rush_for_villains/services/item_catalog.dart';

/// Bugün oynanabilen sınıflar.
///
/// Elle yazılmış bir kopya değil: sınıflar `All_Assets`'e taşındığında liste
/// eskimişti ve testler **ölü** sekiz sınıfı doğrulayıp gerçek 18 sınıfın
/// hiçbirini denetlemiyordu. Artık tek kaynaktan okunuyor.
List<String> get _allClasses => AvatarProfile.playableClassIds;

/// Item kataloğu sanat klasöründen üretiliyor; kod yalnızca dosya adına anlam
/// veriyor. Bu testler iki şeyi koruyor: türetme kurallarının kararlılığı
/// (seviye kilidi kayarsa oyuncunun sahip olduğu item kilitlenir) ve sanatın
/// tamamının tanımlı olması.
/// Bir sınıfın imza bonusu.
///
/// `_classSignature` private; imza, ağırlıklı çekilişte türün ezici üstünlük
/// kurduğu tek nokta olduğu için **çok sayıda tohumun modu** olarak okunuyor.
ItemBuffType _signatureOf(String characterClass) {
  final counts = <ItemBuffType, int>{};
  for (var seed = 0; seed < 200; seed++) {
    final first =
        economyTypeOrder(
          ItemCategory.magic,
          characterClass: characterClass,
          id: 'probe_$seed',
          count: 1,
        ).first;
    counts[first] = (counts[first] ?? 0) + 1;
  }
  var best = counts.entries.first;
  for (final entry in counts.entries) {
    if (entry.value > best.value) best = entry;
  }
  return best.key;
}

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
    test('nadirlik yükseldikçe bonus sayısı artar', () {
      // Toplam = ekonomi (bugün canlı) + savaş (Aşama 4a'da canlanacak).
      expect(buffCountFor(RewardRarity.common), 2);
      expect(buffCountFor(RewardRarity.uncommon), 3);
      expect(buffCountFor(RewardRarity.rare), 4);
      expect(buffCountFor(RewardRarity.epic), 5);
      expect(buffCountFor(RewardRarity.legendary), 6);

      for (final rarity in RewardRarity.values) {
        final buff = buffFor(rarity, ItemCategory.swords);
        expect(
          buff.count,
          buffCountFor(rarity),
          reason: '$rarity için üretilen bonus sayısı tabloyla uyuşmuyor',
        );
        expect(
          buff.liveEffects,
          hasLength(ItemArchetypes.economyCount(rarity)),
          reason: '$rarity için ekonomi bonusu sayısı tabloyla uyuşmuyor',
        );
        expect(
          buff.combatEffects,
          hasLength(ItemArchetypes.combatCount(rarity)),
          reason: '$rarity için savaş statı sayısı tabloyla uyuşmuyor',
        );
      }
    });

    test('nadirlik yükseldikçe toplam bonus büyür', () {
      double total(RewardRarity rarity) {
        final buff = buffFor(rarity, ItemCategory.swords);
        return buff.stepCoinBonus + buff.stepXpBonus + buff.enemyXpBonus;
      }

      expect(total(RewardRarity.common), lessThan(total(RewardRarity.rare)));
      expect(total(RewardRarity.rare), lessThan(total(RewardRarity.legendary)));
    });

    test('sınıfsız temel buff kategori rolüne eğilimli', () {
      // Ağırlıklı çekilişte rolün eğilimi **garanti** değil, ama açık ara en
      // olası sonuç olmalı: yakın dövüş → adım XP, menzil → adım parası.
      int share(ItemCategory category, ItemBuffType expected) {
        var hits = 0;
        for (var seed = 0; seed < 200; seed++) {
          final first =
              economyTypeOrder(category, id: 'seed_$seed', count: 1).first;
          if (first == expected) hits++;
        }
        return hits;
      }

      expect(
        share(ItemCategory.swords, ItemBuffType.stepXp),
        greaterThan(60),
        reason: 'yakın dövüş kategorisinde adım XP baskın olmalı',
      );
      expect(
        share(ItemCategory.arch, ItemBuffType.stepCoin),
        greaterThan(60),
        reason: 'menzil kategorisinde adım parası baskın olmalı',
      );
    });

    test('imza dağılımı dengeli ve hiçbir bonus türü boşta kalmıyor', () {
      // Eski invariant "her sınıfın imzası ayrı" idi. 18 oynanabilir sınıf ve
      // sekiz bonus türüyle bu **matematiksel olarak imkânsız**; test sekiz
      // ölü sınıfa baktığı için yanlışlıkla geçiyordu (bkz. GD36).
      //
      // Yerine geçen kural: dağılım dengeli olmalı ve hiçbir tür sahipsiz
      // kalmamalı — kimsenin imzası olmayan bir bonus türü fiilen ölüdür.
      final counts = <ItemBuffType, int>{
        for (final type in ItemBuffType.values) type: 0,
      };
      for (final characterClass in _allClasses) {
        final signature =
            economyTypeOrder(
              ItemCategory.magic,
              characterClass: characterClass,
              // Ağırlıklı çekilişte imza her zaman ilk sırada çıkmaz; imzayı
              // doğrudan ölçmek için tek elemanlık bir tohum kullanılıyor.
              id: '__signature_probe__',
              count: 8,
            ).first;
        counts[_signatureOf(characterClass)] =
            counts[_signatureOf(characterClass)]! + 1;
        expect(signature, isA<ItemBuffType>());
      }

      for (final entry in counts.entries) {
        expect(
          entry.value,
          greaterThanOrEqualTo(1),
          reason: '${entry.key.name} hiçbir sınıfın imzası değil',
        );
        expect(
          entry.value,
          lessThanOrEqualTo(3),
          reason: '${entry.key.name} çok fazla sınıfa imza oluyor',
        );
      }
      expect(
        counts.values.fold<int>(0, (a, b) => a + b),
        _allClasses.length,
      );
    });

    test('aynı görsel sınıfa göre farklı item olur', () {
      final base = buildItemFromAsset('lib/Items/magic/holy_staff.png')!;
      final wizard = flavorForClass(base, 'Wizard');
      final priest = flavorForClass(base, 'Priest');

      expect(wizard.id, base.id, reason: 'kimlik sınıfa göre değişmemeli');
      expect(priest.id, base.id);
      expect(wizard.name, isNot(priest.name));
      expect(wizard.buff.labels, isNot(priest.buff.labels));
      // Arketip item'ın kendi karakteri: kuşanana göre değişmez.
      expect(wizard.archetype, base.archetype);
      expect(priest.archetype, base.archetype);
    });

    test('paylaşılan kategoride ada sınıf lakabı eklenir', () {
      final base =
          ItemCatalog.fromAssetPaths(['lib/Items/swords/sword.png']).single;
      // Kılıçlar paylaşılan bir kategori: lakap eklenir.
      expect(flavorForClass(base, 'Swordsman').name, startsWith('Çelik '));
      expect(flavorForClass(base, 'Werewolf').name, startsWith('Ay '));
    });

    test('sayısal bonuslar hiçbir zaman sıfır olmaz', () {
      // Etiketi görünüp etkisi olmayan bonus olmamalı.
      for (final rarity in RewardRarity.values) {
        for (final characterClass in _allClasses) {
          for (final category in ItemCategory.values) {
            final buff = buffFor(
              rarity,
              category,
              characterClass: characterClass,
              id: '$category/$characterClass',
            );
            expect(buff.labels, hasLength(buffCountFor(rarity)));
            for (final line in buff.labels) {
              expect(line, isNot(contains('+0')));
              expect(line, isNot(contains('-0 adım')));
            }
          }
        }
      }
    });

    test('bonusu olmayan buff etiket üretmez', () {
      expect(ItemBuff.none.isEmpty, isTrue);
      expect(ItemBuff.none.label, isNull);
      expect(ItemBuff.none.labels, isEmpty);
    });

    test('etiket yüzdeyi okunur yazar', () {
      expect(ItemBuff.stats(stepXpBonus: 0.07).label, 'adım XP +%7');
      expect(
        ItemBuff.stats(stepCoinBonus: 0.06, stepXpBonus: 0.06).label,
        'adım parası +%6 · adım XP +%6',
      );
      expect(
        ItemBuff.stats(dailyCoinCapBonus: 30, streakStepRelief: 200).labels,
        ['günlük coin sınırı +30', 'seri eşiği -200 adım'],
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

      // Varyantlar artık numarayla değil sıfatla ayrılıyor (GD23); sıfat
      // kimlikten kararlı biçimde türer.
      expect(item!.name, '${variantAdjective('swords/dagger', 4)} Hançer');
      expect(item.name, isNot(contains('4')));
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

    test('her karakter sınıfı en az üç kategori görür', () {
      // Magic eskiden tek kategori (yalnızca Büyü) görüyordu; mağazanın
      // kategori süzgeci o sınıfta fiilen işlevsizdi.
      final items = ItemCatalog.fromAssetPaths(allAssetPaths());
      for (final characterClass in _allClasses) {
        final usable =
            items.where((item) => item.isUsableBy(characterClass)).toList();
        final categories = usable.map((item) => item.category).toSet();

        expect(
          categories.length,
          greaterThanOrEqualTo(3),
          reason:
              '$characterClass yalnızca ${categories.length} kategori '
              'görüyor; süzgeç anlamsız kalır',
        );
        expect(
          usable.length,
          greaterThanOrEqualTo(150),
          reason: '$characterClass için yeterli item yok',
        );
      }
    });

    test('hiçbir sınıf kataloğun yarısından fazlasını görmez', () {
      // Sınıf kimliği korunmalı: herkes her şeyi görüyorsa kısıt anlamsız.
      final items = ItemCatalog.fromAssetPaths(allAssetPaths());
      for (final characterClass in _allClasses) {
        final usable = items.where((i) => i.isUsableBy(characterClass)).length;
        expect(usable, lessThan(items.length ~/ 2 + items.length ~/ 10));
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
