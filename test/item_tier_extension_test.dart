import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/utils/item_drop.dart';
import 'package:rush_for_villains/core/utils/item_leveling.dart';
import 'package:rush_for_villains/core/utils/item_merging.dart';
import 'package:rush_for_villains/core/utils/item_rules.dart';
import 'package:rush_for_villains/data/item_tier_extensions.dart';
import 'package:rush_for_villains/l10n/app_localizations.dart';
import 'package:rush_for_villains/l10n/content_localizations.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/item.dart';
import 'package:rush_for_villains/models/owned_item.dart';
import 'package:rush_for_villains/models/reward_rarity.dart';
import 'package:rush_for_villains/services/game_storage.dart';
import 'package:rush_for_villains/services/item_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bölüm E / Faz 2: kategorilerin nadirlik zincirindeki ara boşluklar
/// (GD111).
///
/// Yöntem: aynı görseli kullanan **yeni kimlikler**
/// (`<görsel kimliği>@<nadirlik>`). Var olan hiçbir eşyanın kimliği,
/// nadirliği ya da seviye kilidi değişmiyor.
List<String> _assetPaths() =>
    Directory('lib/Items')
        .listSync(recursive: true)
        .whereType<File>()
        .map((file) => file.path.replaceAll(r'\', '/'))
        .where((path) => path.toLowerCase().endsWith('.png'))
        .toList();

/// Bölüm E'den önce kaynak görsellerin taşıdığı değerler (Faz E2 sondası).
/// Bu eşyalar oyuncuların envanterinde olabilir; hiçbiri değişmemeli.
const _sourcesBefore = {
  'scythes/scythe_variant_12': (rarity: RewardRarity.common, level: 3, cost: 125),
  'scythes/scythe_variant_13': (rarity: RewardRarity.common, level: 1, cost: 100),
  'scythes/scythe_variant_14': (rarity: RewardRarity.common, level: 2, cost: 100),
  'maces_hammers/mace_type_2_variant_14': (
    rarity: RewardRarity.uncommon,
    level: 6,
    cost: 350,
  ),
  'spears/trident_variant_14': (
    rarity: RewardRarity.uncommon,
    level: 4,
    cost: 300,
  ),
};

void main() {
  final paths = _assetPaths();
  final catalog = ItemCatalog.fromAssetPaths(paths);
  Item byId(String id) => catalog.firstWhere((item) => item.id == id);

  group('kimlik şeması', () {
    test('kimlik = görsel kimliği @ nadirlik, görselden türetilebilir', () {
      for (final extension in ItemTierExtensions.all) {
        final item = byId(extension.id);
        expect(item.id, '${extension.assetId}@${extension.rarity.name}');
        expect(item.assetPath, 'lib/Items/${extension.assetId}.png');
        expect(paths, contains(item.assetPath), reason: 'yeni sanat yok');
        // Kimliğin `@` öncesi gerçekten bir görselin kimliği.
        expect(
          parseItemAsset(item.assetPath)!.id,
          item.id.substring(0, item.id.indexOf('@')),
        );
        expect(item.rarity, extension.rarity);
      }
    });

    test('görsel kimliklerinde @ geçmiyor: iki kimlik türü çakışamaz', () {
      for (final path in paths) {
        expect(parseItemAsset(path)?.id ?? '', isNot(contains('@')));
      }
    });

    test('görseli pakette olmayan satır eşya doğurmaz', () {
      final without = ItemCatalog.fromAssetPaths(
        paths.where((path) => !path.contains('scythe_variant_12')),
      );
      expect(
        without.any((item) => item.id == 'scythes/scythe_variant_12@uncommon'),
        isFalse,
      );
    });

    test('katalog: 784 görsel + 5 ara basamak, kimlikler benzersiz', () {
      expect(paths, hasLength(784));
      expect(catalog, hasLength(789));
      expect(catalog.map((item) => item.id).toSet(), hasLength(789));
    });
  });

  group('var olan eşyalar değişmez', () {
    test('kaynak görsellerin kimliği, nadirliği, kilidi ve fiyatı aynı', () {
      for (final entry in _sourcesBefore.entries) {
        final item = byId(entry.key);
        expect(item.rarity, entry.value.rarity, reason: entry.key);
        expect(item.requiredLevel, entry.value.level, reason: entry.key);
        expect(item.cost, entry.value.cost, reason: entry.key);
      }
    });

    test('görselden üretilen her eşya E2 öncesi kuralla birebir aynı', () {
      // `buildItemFromAsset` E2'de değişmedi; katalog görsel eşyalarını hâlâ
      // ondan alıyor. Ara basamaklar yalnızca **eklendi**.
      for (final path in paths) {
        final direct = buildItemFromAsset(path)!;
        final listed = byId(direct.id);
        expect(listed.rarity, direct.rarity);
        expect(listed.requiredLevel, direct.requiredLevel);
        expect(listed.cost, direct.cost);
        expect(listed.name, direct.name);
      }
    });
  });

  group('eski kayıt', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    const avatar = AvatarProfile(
      name: 'Eski Oyuncu',
      age: 30,
      weight: 70,
      gender: 'Erkek',
      characterClass: 'Werewolf',
      characterAsset: 'lib/Characters/Werewolf/test.png',
    );

    final rows = <Map<String, dynamic>>[
      // Ara basamaklara görsel veren eşyaların hepsi.
      {'instanceId': 1, 'itemId': 'scythes/scythe_variant_12', 'level': 3,
        'rarity': null, 'equipped': true},
      {'instanceId': 2, 'itemId': 'scythes/scythe_variant_13', 'level': 1,
        'rarity': null, 'equipped': false},
      // Birleştirilip epiğe çıkmış bir sıradan tırpan.
      {'instanceId': 3, 'itemId': 'scythes/scythe_variant_14', 'level': 2,
        'rarity': 'epic', 'equipped': false},
      {'instanceId': 4, 'itemId': 'maces_hammers/mace_type_2_variant_14',
        'level': 1, 'rarity': null, 'equipped': false},
      {'instanceId': 5, 'itemId': 'spears/trident_variant_14', 'level': 1,
        'rarity': 'rare', 'equipped': false},
      {'instanceId': 6, 'itemId': 'scythes/reapers_scythe', 'level': 1,
        'rarity': null, 'equipped': false},
    ];

    /// Kayıttaki her örneğin E2 öncesi kuralla nadirliği ve kilidi.
    Map<int, (RewardRarity, int)> expected() => {
      for (final row in rows)
        row['instanceId'] as int: () {
          final instance = OwnedItem.fromJson(row)!;
          final asset = buildItemFromAsset(
            'lib/Items/${instance.itemId}.png',
          )!;
          return (instance.effectiveRarity(asset.rarity), asset.requiredLevel);
        }(),
    };

    Map<int, (RewardRarity, int)> resolve(List<OwnedItem> owned) => {
      for (final instance in owned)
        instance.instanceId: () {
          final base = ItemCatalog.byId(
            instance.itemId,
            characterClass: avatar.characterClass,
          )!;
          final item = resolveOwnedItem(
            base,
            instance,
            characterClass: avatar.characterClass,
          );
          return (item.rarity, item.requiredLevel);
        }(),
    };

    setUp(() {
      SharedPreferences.setMockInitialValues({
        'game_state_v1': jsonEncode({
          'schemaVersion': 32,
          'savedAt': '2026-10-02T10:00:00.000',
          'state': {
            'profile': {
              'level': 12,
              'coins': 500,
              'ownedItems': rows,
              'nextItemInstanceId': 7,
            },
            'today': {'steps': 0, 'stepGoal': 7000},
          },
        }),
      });
      ItemCatalog.reset(catalog);
      addTearDown(ItemCatalog.reset);
    });

    test('v32 kaydı açılıp kapanınca her eşyanın nadirliği ve kilidi aynı', () async {
      final first = await GameStorage.load(avatar: avatar);
      expect(first, isNotNull);
      expect(resolve(first!.profile.ownedItems), expected());

      // Kapat: kaydı yaz. Aç: tekrar oku.
      await GameStorage.save(first);
      final second = await GameStorage.load(avatar: avatar);
      expect(resolve(second!.profile.ownedItems), expected());
      expect(
        [for (final item in second.profile.ownedItems) item.toJson()],
        rows,
      );
    });

    test('kayıttaki hiçbir kimlik yeni bir ara basamağa kaymaz', () async {
      final restored = await GameStorage.load(avatar: avatar);
      for (final instance in restored!.profile.ownedItems) {
        expect(instance.itemId, isNot(contains('@')));
        expect(ItemCatalog.byId(instance.itemId)!.id, instance.itemId);
      }
    });
  });

  group('kesintisiz zincir', () {
    test('her kategoride en düşükten en yükseğe boşluk yok', () {
      for (final category in ItemCategory.values) {
        final present = {
          for (final item in catalog)
            if (item.category == category) item.rarity.index,
        };
        if (present.isEmpty) continue;
        final low = present.reduce((a, b) => a < b ? a : b);
        final high = present.reduce((a, b) => a > b ? a : b);
        for (var index = low; index <= high; index++) {
          expect(
            present,
            contains(index),
            reason: '${category.name}: ${RewardRarity.values[index].name} eksik',
          );
        }
      }
    });

    test('birleştirme her kategoride efsaneviye kadar duvara çarpmaz', () {
      // Uçtaki eksikler (balta ve topuz efsanevisi, Özel'in dört basamağı)
      // katalogda yok ama birleştirme kataloğa bakmıyor: örneğin nadirliği
      // [nextRarity] ile yükseliyor ve eşya yeni nadirlikte yeniden
      // çözülüyor.
      for (final category in ItemCategory.values) {
        final item = catalog
            .where((item) => item.category == category)
            .reduce((a, b) => a.rarity.index <= b.rarity.index ? a : b);
        var current = item;
        for (
          var next = nextRarity(item.rarity);
          next != null;
          next = nextRarity(next)
        ) {
          expect(
            mergeCountFor(current.rarity),
            isNotNull,
            reason: '${category.name}: ${current.rarity.name} birleşemiyor',
          );
          current = withRarity(item, next);
          expect(current.rarity, next);
          expect(current.requiredLevel, item.requiredLevel);
        }
        expect(current.rarity, RewardRarity.legendary, reason: category.name);
      }
    });
  });

  group('yeni basamaklar nadirlik kurallarına uyar', () {
    test('kilit, fiyat ve yükseltme maliyeti kuraldan, özel durum yok', () {
      for (final extension in ItemTierExtensions.all) {
        final item = byId(extension.id);
        expect(item.requiredLevel, requiredLevelFor(item.rarity, item.id));
        expect(item.cost, costFor(item.rarity, item.requiredLevel));
        expect(itemLevelCap(item.rarity), isPositive);
        expect(item.hasSignature, isFalse);
        // Kuraldan türeyen şerit: 2-3-4-5-6.
        expect(item.buff.effects, hasLength(buffCountFor(item.rarity)));
      }
    });

    test('komşularının arasına oturur: kilit, fiyat, yükseltme maliyeti', () {
      for (final extension in ItemTierExtensions.all) {
        final item = byId(extension.id);
        final ownUpgrade = totalUpgradeCost(item.cost, item.rarity);
        for (final other in catalog.where(
          (other) => other.category == item.category && other.id != item.id,
        )) {
          final otherUpgrade = totalUpgradeCost(other.cost, other.rarity);
          if (other.rarity.index < item.rarity.index) {
            expect(other.requiredLevel, lessThan(item.requiredLevel));
            expect(other.cost, lessThan(item.cost));
            expect(otherUpgrade, lessThan(ownUpgrade));
          } else if (other.rarity.index > item.rarity.index) {
            expect(other.requiredLevel, greaterThan(item.requiredLevel));
            expect(other.cost, greaterThan(item.cost));
            expect(otherUpgrade, greaterThan(ownUpgrade));
          }
        }
      }
    });

    test('savaş gücü komşuların arasında: ana stat sıçramıyor', () {
      // Tırpan zinciri: sıradan → [az bulunur, nadir, epik] → efsanevi.
      // Aynı arketipte birincil stat nadirlikle kesin artmalı.
      final striker = [
        for (final rarity in RewardRarity.values.take(4))
          buffFor(
            rarity,
            ItemCategory.scythes,
            archetype: ItemArchetype.striker,
          ).combatEffects.first.value,
      ];
      for (var i = 1; i < striker.length; i++) {
        expect(striker[i], greaterThan(striker[i - 1]));
      }
    });

    test('sınıfa uyarlanınca adı değişmez, buff sınıfa göre çözülür', () {
      final item = byId('scythes/scythe_variant_13@rare');
      final names = {
        for (final characterClass in AvatarProfile.playableClassIds)
          if (item.isUsableBy(characterClass))
            flavorForClass(item, characterClass).name,
      };
      expect(names, {'Kan Tırpanı'});
    });
  });

  group('adlar', () {
    test('Türkçe ve İngilizce adlar kaynak varyanttan ayrı ve benzersiz', () async {
      final english = await AppLocalizations.delegate.load(const Locale('en'));
      final turkish = await AppLocalizations.delegate.load(const Locale('tr'));
      for (final l10n in [english, turkish]) {
        for (final extension in ItemTierExtensions.all) {
          final name = l10n.itemName(byId(extension.id));
          final clashes = [
            for (final item in catalog)
              if (item.id != extension.id && l10n.itemName(item) == name)
                item.id,
          ];
          expect(clashes, isEmpty, reason: '"$name" ${l10n.localeName}');
        }
      }
      expect(english.itemName(byId('spears/trident_variant_14@rare')),
          'Frost Trident');
      expect(turkish.itemName(byId('spears/trident_variant_14@rare')),
          'Buz Çatalı');
    });
  });

  group('etki: düşme ve mağaza', () {
    test('her sınıfın düşme havuzunda beş nadirlik de zaten vardı', () {
      // Düşme önce tablodan nadirlik çeker, sonra o nadirlikte eşya seçer;
      // nadirlik boşsa aşağı kayar. Ara basamaklardan önce de hiçbir
      // sınıfın havuzunda boş nadirlik yoktu, yani nadirlik dağılımı
      // değişmedi — yalnızca o nadirlik içindeki seçim genişledi.
      for (final characterClass in AvatarProfile.playableClassIds) {
        final before = catalog.where(
          (item) => item.isUsableBy(characterClass) && !item.id.contains('@'),
        );
        for (final rarity in RewardRarity.values) {
          expect(
            before.any((item) => item.rarity == rarity),
            isTrue,
            reason: '$characterClass / ${rarity.name}',
          );
        }
      }
    });

    test('ara basamak düşebilir: tohumlu çekiliş onu da seçiyor', () {
      final pool = [
        for (final item in catalog)
          if (item.isUsableBy('Werewolf')) item,
      ];
      final dropped = <String>{};
      for (var seed = 0; seed < 4000; seed++) {
        final item = rollItemDrop(tier: 20, seed: 'e2-$seed', pool: pool);
        if (item != null) dropped.add(item.id);
      }
      expect(dropped, contains('scythes/scythe_variant_13@rare'));
    });

    test('mağaza havuzunda kendi sınıfına görünür, fiyatı kuraldan', () {
      ItemCatalog.reset(catalog);
      addTearDown(ItemCatalog.reset);
      final store = ItemCatalog.forCharacterClass('Werewolf');
      for (final id in [
        'scythes/scythe_variant_12@uncommon',
        'scythes/scythe_variant_13@rare',
        'scythes/scythe_variant_14@epic',
      ]) {
        final item = store.firstWhere((item) => item.id == id);
        expect(item.cost, costFor(item.rarity, item.requiredLevel));
      }
      // Tırpan kullanmayan bir sınıf onları görmüyor.
      expect(
        ItemCatalog.forCharacterClass('Wizard').any(
          (item) => item.id.contains('@'),
        ),
        isFalse,
      );
    });
  });
}
