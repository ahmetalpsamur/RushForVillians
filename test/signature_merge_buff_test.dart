import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/game_constants.dart';
import 'package:rush_for_villains/core/utils/item_leveling.dart';
import 'package:rush_for_villains/core/utils/item_merging.dart';
import 'package:rush_for_villains/core/utils/item_rules.dart';
import 'package:rush_for_villains/data/item_archetypes.dart';
import 'package:rush_for_villains/data/item_effects.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/item.dart';
import 'package:rush_for_villains/models/item_effect.dart';
import 'package:rush_for_villains/models/owned_item.dart';
import 'package:rush_for_villains/models/reward_rarity.dart';
import 'package:rush_for_villains/services/game_storage.dart';
import 'package:rush_for_villains/services/item_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bölüm E / Faz 1: birleştirmede imzalı eşyaya **+1 buff** (GD110).
///
/// Hata: imzalı eşya bir üst nadirliğe çıkınca etkileri yalnızca büyüyordu,
/// sayısı artmıyordu. Kuraldan türeyen eşya ise her basamakta +1 alıyordu.
/// İki şerit artık aynı kurala bağlı:
///
/// - kuraldan türeyen: 2-3-4-5-6 (değişmedi),
/// - imzalı: nadir 2 · epik 3 · efsanevi 4.
List<String> get _allClasses => AvatarProfile.playableClassIds;

List<Item> _catalog() => ItemCatalog.fromAssetPaths(
  Directory('lib/Items')
      .listSync(recursive: true)
      .whereType<File>()
      .map((file) => file.path.replaceAll(r'\', '/'))
      .where((path) => path.toLowerCase().endsWith('.png')),
);

String _baseId(Item item) => parseItemAsset(item.assetPath)!.baseId;

/// Bir item'ın elle yazılmış imza etkileri (tablodaki satır).
List<ItemEffect> _signature(Item item) => ItemEffects.of(_baseId(item))!.effects;

/// Bölüm E öncesi kuralla bir eşyanın kaç etki taşıdığı.
///
/// **Donmuş eski kural**: imzalı eşya nadirlik ne olursa olsun yalnızca
/// imza satırındaki etkileri taşıyordu; kuraldan türeyen eşyanın kuralı
/// değişmedi. Ölçüm "kaç eşyaya kaç buff eklendi" sorusunu buna göre
/// cevaplıyor.
int _legacyEffectCount(Item base, Item resolved) =>
    base.hasSignature ? _signature(base).length : resolved.buff.effects.length;

/// Bölüm E öncesinde ölçülen en yüksek koşulsuz adım parası / adım XP'si,
/// nadirlik başına (Faz E0 sondası, 18 sınıf × 784 eşya, birleştirmeyle
/// ulaşılan nadirlikler dahil). Faz E1 bunların hiçbirini aşmamalı.
const _legacyEconomyMax = {
  RewardRarity.common: (coin: 0.02, xp: 0.02),
  RewardRarity.uncommon: (coin: 0.03, xp: 0.03),
  RewardRarity.rare: (coin: 0.08, xp: 0.054),
  RewardRarity.epic: (coin: 0.14, xp: 0.11),
  RewardRarity.legendary: (coin: 0.15, xp: 0.15),
};

/// Eşyanın katalog nadirliğinden efsaneviye kadar bütün hâlleri.
Iterable<Item> _mergeChain(Item flavored, String characterClass) sync* {
  yield flavored;
  for (
    var next = nextRarity(flavored.rarity);
    next != null;
    next = nextRarity(next)
  ) {
    yield withRarity(flavored, next, characterClass: characterClass);
  }
}

void main() {
  final catalog = _catalog();

  group('iki şerit, basamak başına +1', () {
    test('imzalı katalog eşyası nadirliğinin istediği sayıda etki taşır', () {
      final offenders = <String>[];
      for (final item in catalog.where((item) => item.hasSignature)) {
        for (final characterClass in [null, ..._allClasses]) {
          final resolved =
              characterClass == null
                  ? item
                  : flavorForClass(item, characterClass);
          final want = ItemArchetypes.signatureEffectCount(item.rarity);
          // Elle yazılmış dört etkili efsaneviler kırpılmaz.
          final expected =
              _signature(item).length > want ? _signature(item).length : want;
          if (resolved.buff.effects.length != expected) {
            offenders.add(
              '${item.id}/$characterClass '
              '${resolved.buff.effects.length} != $expected',
            );
          }
        }
      }
      expect(offenders, isEmpty, reason: offenders.take(3).join('\n'));
    });

    test('kuraldan türeyen şerit değişmedi: 2-3-4-5-6', () {
      for (final rarity in RewardRarity.values) {
        expect(buffCountFor(rarity), RewardRarity.values.indexOf(rarity) + 2);
      }
    });

    test('her birleştirme basamağı iki şeritte de tam bir etki ekler', () {
      final offenders = <String>[];
      for (final item in catalog) {
        for (final characterClass in _allClasses) {
          if (!item.isUsableBy(characterClass)) continue;
          final chain =
              _mergeChain(flavorForClass(item, characterClass), characterClass)
                  .toList();
          for (var i = 1; i < chain.length; i++) {
            final before = chain[i - 1].buff.effects.length;
            final after = chain[i].buff.effects.length;
            if (after != before + 1) {
              offenders.add(
                '${item.id}/$characterClass '
                '${chain[i - 1].rarity.name}→${chain[i].rarity.name}: '
                '$before→$after',
              );
            }
          }
        }
      }
      expect(offenders, isEmpty, reason: offenders.take(3).join('\n'));
    });

    test('imzalı nadir eşya birleşerek 2 → 3 → 4 olur', () {
      final aqua = catalog.firstWhere((item) => item.id == 'swords/aqua_sword');
      final flavored = flavorForClass(aqua, 'Swordsman');
      final counts = [
        for (final item in _mergeChain(flavored, 'Swordsman'))
          item.buff.effects.length,
      ];
      expect(counts, [2, 3, 4]);
    });
  });

  group('imzalı etkinin kimliği', () {
    test('imzalı etkiler önde ve sırasıyla durur', () {
      for (final item in catalog.where((item) => item.hasSignature)) {
        for (final characterClass in _allClasses) {
          final flavored = flavorForClass(item, characterClass);
          final signature = _signature(item);
          expect(
            flavored.buff.effects.take(signature.length).toList(),
            signature,
            reason: '${item.id}/$characterClass',
          );
        }
      }
    });

    test('birleşince imzalı etkiler büyür ve hâlâ önde kalır', () {
      final wind = catalog.firstWhere((item) => item.id == 'arch/wind_arrow');
      final merged = withRarity(
        flavorForClass(wind, 'Archer'),
        RewardRarity.legendary,
        characterClass: 'Archer',
      );
      final signature = _signature(wind);
      for (var i = 0; i < signature.length; i++) {
        expect(merged.buff.effects[i].stat, signature[i].stat);
        expect(merged.buff.effects[i].trigger, signature[i].trigger);
        expect(
          merged.buff.effects[i].value.abs(),
          greaterThan(signature[i].value.abs()),
          reason: 'mevcut etkilerin güçlenmesi devam etmeli',
        );
      }
    });

    test('dolgu var olan bir statı tekrar etmez', () {
      final offenders = <String>[];
      for (final item in catalog.where((item) => item.hasSignature)) {
        for (final characterClass in _allClasses) {
          for (final resolved in _mergeChain(
            flavorForClass(item, characterClass),
            characterClass,
          )) {
            final core = _signature(item).length;
            final coreStats = {
              for (final effect in resolved.buff.effects.take(core))
                effect.stat,
            };
            final filler = [
              for (final effect in resolved.buff.effects.skip(core))
                effect.stat,
            ];
            if (filler.any(coreStats.contains) ||
                filler.toSet().length != filler.length) {
              offenders.add('${resolved.id}/$characterClass/${resolved.rarity}');
            }
          }
        }
      }
      expect(offenders, isEmpty, reason: offenders.take(3).join('\n'));
    });

    test('imza sınıfa göre değişmez, yalnızca dolgu sınıfa göre çözülür', () {
      final meteor = catalog.firstWhere(
        (item) => item.id == 'arch/meteor_strike_arrow',
      );
      final signature = _signature(meteor);
      expect(signature, hasLength(3));
      for (final characterClass in _allClasses) {
        final flavored = flavorForClass(meteor, characterClass);
        expect(flavored.name, meteor.name);
        expect(flavored.buff.effects.take(3).toList(), signature);
        expect(flavored.buff.effects, hasLength(4));
      }
    });

    test('epikte eklenen dolgu efsanevide de ilk dolgu olarak kalır', () {
      for (final item in catalog.where(
        (item) => item.hasSignature && item.rarity == RewardRarity.rare,
      )) {
        for (final characterClass in _allClasses) {
          final flavored = flavorForClass(item, characterClass);
          final epic = withRarity(
            flavored,
            RewardRarity.epic,
            characterClass: characterClass,
          );
          final legendary = withRarity(
            flavored,
            RewardRarity.legendary,
            characterClass: characterClass,
          );
          final core = _signature(item).length;
          expect(
            legendary.buff.effects[core].stat,
            epic.buff.effects[core].stat,
            reason: '${item.id}/$characterClass',
          );
        }
      }
    });
  });

  group('ekonomi kuralı', () {
    test('adım parası ve adım XP en yüksek değerlerini aşmaz', () {
      final offenders = <String>[];
      for (final item in catalog) {
        for (final characterClass in _allClasses) {
          if (!item.isUsableBy(characterClass)) continue;
          for (final resolved in _mergeChain(
            flavorForClass(item, characterClass),
            characterClass,
          )) {
            final limit = _legacyEconomyMax[resolved.rarity]!;
            var coin = 0.0;
            var xp = 0.0;
            for (final effect in resolved.buff.effects) {
              if (!effect.isPassive) continue;
              if (effect.stat == ItemStat.stepCoin &&
                  effect.value > limit.coin + 1e-9) {
                offenders.add('${resolved.id} ${resolved.rarity} coin');
              }
              if (effect.stat == ItemStat.stepXp &&
                  effect.value > limit.xp + 1e-9) {
                offenders.add('${resolved.id} ${resolved.rarity} xp');
              }
              if (effect.stat == ItemStat.stepCoin) coin += effect.value;
              if (effect.stat == ItemStat.stepXp) xp += effect.value;
            }
            // Tek item tavanı, imzalı eşyada toplam olarak da geçerli: dolgu
            // var olan statı tekrar etmediği için aynı stata iki pay binemez.
            //
            // ⚠️ Kuraldan türeyen şeritte bu toplam bugün de aşılabiliyor
            // (`stepCoin` + `stepCoinMomentum` ikisi de adım parasına
            // yazıyor; birleştirilmiş 170 efsanevi × sınıf, en kötüsü
            // %18,85). Faz E1 o şeride dokunmuyor; karar bekliyor.
            if (resolved.hasSignature &&
                (coin > GameConstants.maxSingleItemEconomyBonus + 1e-9 ||
                    xp > GameConstants.maxSingleItemEconomyBonus + 1e-9)) {
              offenders.add('${resolved.id} ${resolved.rarity} toplam');
            }
          }
        }
      }
      expect(offenders, isEmpty, reason: offenders.take(3).join('\n'));
    });
  });

  group('eski kayıt ölçümü', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    const avatar = AvatarProfile(
      name: 'Eski Oyuncu',
      age: 30,
      weight: 70,
      gender: 'Erkek',
      characterClass: 'Archer',
      characterAsset: 'lib/Characters/Archer/test.png',
    );

    /// Bölüm E'den önce yazılmış bir kaydın envanteri. Birleştirilmiş
    /// imzalı eşyalar `rarity` alanında yükseltilmiş nadirliği taşıyor.
    final rows = <Map<String, dynamic>>[
      // Katalogda 3 etkili efsanevi: +1.
      {'instanceId': 1, 'itemId': 'arch/meteor_strike_arrow', 'level': 4,
        'rarity': null, 'equipped': true},
      // Katalogda zaten 4 etkili efsanevi: +0.
      {'instanceId': 2, 'itemId': 'scythes/reapers_scythe', 'level': 1,
        'rarity': null, 'equipped': false},
      // Katalog epiği, birleştirilmemiş: +0.
      {'instanceId': 3, 'itemId': 'arch/energy_bow', 'level': 2,
        'rarity': null, 'equipped': false},
      // Nadir imzalı → epiğe birleştirilmiş: +1.
      {'instanceId': 4, 'itemId': 'arch/wind_arrow', 'level': 1,
        'rarity': 'epic', 'equipped': false},
      // Nadir imzalı → efsaneviye birleştirilmiş: +2.
      {'instanceId': 5, 'itemId': 'swords/aqua_sword', 'level': 3,
        'rarity': 'legendary', 'equipped': false},
      // Epik imzalı → efsaneviye birleştirilmiş: +1.
      {'instanceId': 6, 'itemId': 'arch/turkish_bow_variant_02', 'level': 1,
        'rarity': 'legendary', 'equipped': false},
      // Kuraldan türeyen, birleştirilmiş: kural değişmedi, +0.
      {'instanceId': 7, 'itemId': 'swords/dagger_variant_01', 'level': 5,
        'rarity': 'rare', 'equipped': false},
      // Sıradan, dokunulmamış: +0.
      {'instanceId': 8, 'itemId': 'arch/longbow_variant_01', 'level': 1,
        'rarity': null, 'equipped': false},
    ];

    setUp(() {
      SharedPreferences.setMockInitialValues({
        'game_state_v1': jsonEncode({
          'schemaVersion': 32,
          'savedAt': '2026-10-02T10:00:00.000',
          'state': {
            'profile': {
              'level': 40,
              'coins': 500,
              'ownedItems': rows,
              'nextItemInstanceId': 9,
            },
            'today': {'steps': 0, 'stepGoal': 7000},
          },
        }),
      });
      ItemCatalog.reset(catalog);
      addTearDown(ItemCatalog.reset);
    });

    test('düzeltme kaydı değiştirmeden gelir: kaç eşyaya kaç buff', () async {
      final restored = await GameStorage.load(avatar: avatar);
      expect(restored, isNotNull);
      final owned = restored!.profile.ownedItems;

      // Veri göçü gerekmiyor: kayıttaki satırlar bit bit aynı geri okunuyor
      // ve hiçbirinde buff alanı yok. Buff her açılışta katalogdan çözülüyor.
      expect([for (final item in owned) item.toJson()], rows);
      for (final item in owned) {
        expect(
          item.toJson().keys.toSet(),
          {'instanceId', 'itemId', 'level', 'rarity', 'equipped'},
        );
      }

      final added = <String, int>{};
      for (final instance in owned) {
        final base = ItemCatalog.byId(instance.itemId, characterClass: 'Archer')!;
        final resolved = resolveOwnedItem(
          base,
          instance,
          characterClass: 'Archer',
        );
        final gained =
            resolved.buff.effects.length - _legacyEffectCount(base, resolved);
        if (gained > 0) added[instance.itemId] = gained;
      }

      expect(added, {
        'arch/meteor_strike_arrow': 1,
        'arch/wind_arrow': 1,
        'swords/aqua_sword': 2,
        'arch/turkish_bow_variant_02': 1,
      });
      // 8 eşyadan 4'üne toplam 5 buff.
      expect(added.length, 4);
      expect(added.values.fold<int>(0, (sum, value) => sum + value), 5);
    });

    test('iki kez açmak buff\'ı iki kez eklemez', () async {
      int totalEffects() {
        var total = 0;
        for (final row in rows) {
          final instance = OwnedItem.fromJson(row)!;
          final base =
              ItemCatalog.byId(instance.itemId, characterClass: 'Archer')!;
          total += resolveOwnedItem(
            base,
            instance,
            characterClass: 'Archer',
          ).buff.effects.length;
        }
        return total;
      }

      final first = await GameStorage.load(avatar: avatar);
      final countAfterFirst = totalEffects();
      // Göçten sonra yazılan kayıt ikinci kez okunuyor.
      final second = await GameStorage.load(avatar: avatar);
      expect(totalEffects(), countAfterFirst);
      expect(
        [for (final item in second!.profile.ownedItems) item.toJson()],
        [for (final item in first!.profile.ownedItems) item.toJson()],
      );
    });
  });
}
