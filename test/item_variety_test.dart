import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/game_constants.dart';
import 'package:rush_for_villains/core/utils/item_rules.dart';
import 'package:rush_for_villains/data/item_archetypes.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/item.dart';
import 'package:rush_for_villains/models/item_effect.dart';
import 'package:rush_for_villains/models/reward_rarity.dart';
import 'package:rush_for_villains/services/item_catalog.dart';

/// Bölüm 3'ün asıl sözleşmesi: **aynı sınıfın, aynı nadirlikteki iki eşyası
/// birbirinden ayrışmalı.**
///
/// Arketipten önce bir item'ın bonusu yalnızca nadirlik + kategori + sınıftan
/// türüyordu ve sıradan itemde tek bonus vardı — o da her zaman sınıfın
/// imzası. Sonuç: bir sınıfın bütün sıradan kılıçları **birebir aynı**ydı ve
/// oyuncunun seçimi anlamsızdı. Bu dosya o durumun geri gelmesini engelliyor.
List<String> get _allClasses => AvatarProfile.playableClassIds;

List<String> _allAssetPaths() =>
    Directory('lib/Items')
        .listSync(recursive: true)
        .whereType<File>()
        .map((file) => file.path.replaceAll(r'\', '/'))
        .where((path) => path.toLowerCase().endsWith('.png'))
        .toList();

List<Item> _catalog() => ItemCatalog.fromAssetPaths(_allAssetPaths());

/// Bir buff'ın "parmak izi": etiketleri aynıysa oyuncu için aynı itemdir.
String _fingerprint(Item item) =>
    '${item.archetype.name}|${item.buff.labels.join('|')}';

void main() {
  group('buff çeşitliliği', () {
    test('aynı sınıf, kategori ve nadirlikteki itemler tek kalıba sıkışmaz', () {
      ItemCatalog.reset(_catalog());
      addTearDown(ItemCatalog.reset);

      final failures = <String>[];
      for (final characterClass in _allClasses) {
        final groups = <String, List<Item>>{};
        for (final item in ItemCatalog.forCharacterClass(characterClass)) {
          // İmzalı itemler elle tasarlandı ve varyantları bilerek aynı
          // etkileri taşır ("Azrailin Tırpanı" hep aynı item). Bu testin
          // konusu kuraldan türeyen itemler.
          if (item.hasSignature) continue;
          groups
              .putIfAbsent(
                '${item.category.folder}|${item.rarity.name}',
                () => [],
              )
              .add(item);
        }

        for (final entry in groups.entries) {
          final items = entry.value;
          if (items.length < 6) continue;

          final counts = <String, int>{};
          for (final item in items) {
            final key = _fingerprint(item);
            counts[key] = (counts[key] ?? 0) + 1;
          }
          final modal = counts.values.reduce((a, b) => a > b ? a : b);

          if (counts.length < 4) {
            failures.add(
              '$characterClass/${entry.key}: ${items.length} itemde yalnızca '
              '${counts.length} farklı buff',
            );
          }
          if (modal / items.length > 0.5) {
            failures.add(
              '$characterClass/${entry.key}: itemlerin '
              '%${(modal * 100 / items.length).round()}\'i aynı buff\'a sahip',
            );
          }
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('aynı temel görselin varyantları birbirinden ayrışır', () {
      // Hançerin 28 varyantı var; hepsi aynı bonusu verirse varyant sistemi
      // yalnızca kozmetik olur.
      final daggers =
          _catalog()
              .where((item) => item.id.startsWith('swords/dagger_variant_'))
              .toList();

      expect(daggers.length, greaterThan(10));
      final prints = daggers.map(_fingerprint).toSet();
      expect(
        prints.length,
        greaterThanOrEqualTo(5),
        reason: 'hançer varyantları ${prints.length} farklı buff üretiyor',
      );
    });

    test('sınıf kimliği korunuyor: imza hâlâ en sık birincil bonus', () {
      ItemCatalog.reset(_catalog());
      addTearDown(ItemCatalog.reset);

      for (final characterClass in _allClasses) {
        final counts = <ItemStat, int>{};
        var total = 0;
        for (final item in ItemCatalog.forCharacterClass(characterClass)) {
          if (item.hasSignature) continue;
          final live = item.buff.liveEffects;
          if (live.isEmpty) continue;
          counts[live.first.stat] = (counts[live.first.stat] ?? 0) + 1;
          total++;
        }

        final modal = counts.entries.reduce(
          (a, b) => a.value >= b.value ? a : b,
        );
        // İmza ezici değil (aksi hâlde çeşitlilik ölürdü) ama açık ara en
        // sık: sınıf kimliği dağılımda okunuyor (GD36).
        expect(
          modal.value / total,
          greaterThan(0.25),
          reason:
              '$characterClass için baskın bir imza yok; sınıf kimliği '
              'dağılımda kaybolmuş',
        );
        expect(
          modal.value / total,
          lessThan(0.75),
          reason:
              '$characterClass itemlerinin çoğu aynı bonusu veriyor; '
              'çeşitlilik yok',
        );
      }
    });
  });

  group('arketip', () {
    test('kimlikten kararlı türer', () {
      for (final id in ['swords/dagger_variant_03', 'magic/holy_staff']) {
        final category =
            id.startsWith('swords') ? ItemCategory.swords : ItemCategory.magic;
        expect(archetypeFor(category, id), archetypeFor(category, id));
      }
    });

    test('kuşanan sınıfa göre değişmez', () {
      // Arketip item'ın kendi karakteri; kimin kuşandığına bağlı değil.
      final base = buildItemFromAsset('lib/Items/swords/sword.png')!;
      for (final characterClass in _allClasses) {
        expect(flavorForClass(base, characterClass).archetype, base.archetype);
      }
    });

    test('her rolde dört arketip de görülebilir', () {
      // İlk tasarımda menzil çarkında muhafız yoktu; sıradan menzilli itemler
      // yalnızca üç farklı savaş statı üretebiliyordu.
      for (final role in ItemRole.values) {
        expect(
          ItemArchetypes.wheel[role]!.toSet(),
          hasLength(ItemArchetype.values.length),
          reason: '$role rolünde bütün arketipler bulunmalı',
        );
      }
    });

    test('rol eğilimi korunuyor: kalkanların çoğu muhafız', () {
      final shields =
          _catalog()
              .where(
                (item) =>
                    item.category == ItemCategory.shields && !item.hasSignature,
              )
              .toList();
      final guardians =
          shields
              .where((item) => item.archetype == ItemArchetype.guardian)
              .length;

      expect(shields, isNotEmpty);
      expect(
        guardians / shields.length,
        greaterThan(0.4),
        reason: 'kalkanların çoğu muhafız olmalı',
      );
    });

    test('imzalı itemin arketipi taşıdığı savaş statından okunur', () {
      // Uydurulmuş bir etiket değil: "Vurucu" yazan bir kalkan çıkmamalı.
      for (final item in _catalog()) {
        if (!item.hasSignature) continue;
        final combat = item.buff.combatEffects;
        if (combat.isEmpty) continue;

        final stats = ItemArchetypes.combatStats[item.archetype]!;
        expect(
          combat.any((effect) => stats.contains(effect.stat)),
          isTrue,
          reason:
              '${item.id} "${item.archetype.label}" ama o arketipin hiçbir '
              'statını taşımıyor',
        );
      }
    });

    test('her arketip katalogda gerçekten bulunuyor', () {
      final seen = _catalog().map((item) => item.archetype).toSet();
      expect(seen, hasLength(ItemArchetype.values.length));
    });
  });

  group('arketip ekonomiyi büyütmez', () {
    test('ekonomi eğilimi hiçbir arketipte 1.0 üstünde değil', () {
      // Ekonomi dikkatle dengelendi (`economy_pacing_test.dart`). Arketip
      // sistemi dağılımı değiştirir, toplamı büyütmez.
      for (final tilt in ItemArchetypes.economyTilt.values) {
        expect(tilt, lessThanOrEqualTo(1.0));
      }
    });

    test('hiçbir item tek başına ekonomi tavanını aşmıyor', () {
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
      expect(offenders, isEmpty, reason: offenders.take(5).join('\n'));
    });

    test('kuraldan türeyen item elle tasarlanmışın savaş gücünü geçmez', () {
      // GD24: imzalı itemler cömert. Kural türetmesi onların üstüne çıkarsa
      // en üst katmanın anlamı kalmaz.
      var ruleMaxAttack = 0.0;
      for (final rarity in RewardRarity.values) {
        for (final archetype in ItemArchetype.values) {
          final buff = buffFor(
            rarity,
            ItemCategory.swords,
            archetype: archetype,
          );
          for (final effect in buff.combatEffects) {
            if (effect.stat == ItemStat.attack &&
                effect.mode == ItemEffectMode.flat) {
              ruleMaxAttack =
                  effect.value > ruleMaxAttack ? effect.value : ruleMaxAttack;
            }
          }
        }
      }

      var signatureMaxAttack = 0.0;
      for (final item in _catalog()) {
        if (!item.hasSignature) continue;
        for (final effect in item.buff.effects) {
          if (effect.stat == ItemStat.attack &&
              effect.mode == ItemEffectMode.flat) {
            signatureMaxAttack =
                effect.value > signatureMaxAttack
                    ? effect.value
                    : signatureMaxAttack;
          }
        }
      }

      expect(ruleMaxAttack, greaterThan(0));
      expect(ruleMaxAttack, lessThan(signatureMaxAttack));
    });
  });

  group('sayısal sağlamlık', () {
    test('hiçbir savaş statı sıfıra düşmez', () {
      // Etiketi görünüp etkisi olmayan bonus olmamalı.
      for (final rarity in RewardRarity.values) {
        for (final archetype in ItemArchetype.values) {
          for (final category in ItemCategory.values) {
            final buff = buffFor(
              rarity,
              category,
              archetype: archetype,
              id: '${category.folder}/$archetype',
            );
            for (final effect in buff.combatEffects) {
              expect(
                effect.value.abs(),
                greaterThan(0),
                reason: '${effect.stat.name} sıfır değer üretti',
              );
              expect(effect.label, isNot(contains('+0 ')));
            }
          }
        }
      }
    });

    test('savaş statları hâlâ uyuyor: bugün hiçbir çarpana girmiyorlar', () {
      for (final item in _catalog()) {
        for (final effect in item.buff.combatEffects) {
          expect(effect.isDormant, isTrue);
        }
        // Kuraldan türeyen savaş statları ekonomi getter'larına sızmamalı.
        expect(item.buff.stepCoinBonus, lessThanOrEqualTo(0.5));
      }
    });
  });
}
