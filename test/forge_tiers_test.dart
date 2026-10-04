import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/utils/item_forging.dart';
import 'package:rush_for_villains/core/utils/item_merging.dart';
import 'package:rush_for_villains/core/utils/item_rules.dart';
import 'package:rush_for_villains/data/forge_tiers.dart';
import 'package:rush_for_villains/data/item_archetypes.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/item_effect.dart';
import 'package:rush_for_villains/models/reward_rarity.dart';
import 'package:rush_for_villains/services/item_catalog.dart';

/// Bölüm E / Faz 4: yeniden atmanın kademe tablosu (GD112).
///
/// Tablo elle yazılmış veri; bu dosya onu **ölçülen gerçeğe** bağlıyor:
/// merkezler bugünkü ortalama değerlere oturuyor, ekonomi tavanı aşılmıyor,
/// kademeler artıyor.

/// Bölüm E öncesi en yüksek koşulsuz adım parası / adım XP'si, nadirlik
/// başına (Faz E0 sondası). Ekonomi kuralı: yeniden atma bunları aşamaz.
const _legacyMax = {
  RewardRarity.common: (coin: 0.02, xp: 0.02),
  RewardRarity.uncommon: (coin: 0.03, xp: 0.03),
  RewardRarity.rare: (coin: 0.08, xp: 0.054),
  RewardRarity.epic: (coin: 0.14, xp: 0.11),
  RewardRarity.legendary: (coin: 0.15, xp: 0.15),
};

/// Ölçümden bilerek sapan merkezler (`forge_tiers.dart` başındaki tablo):
/// kademeler artan kalsın diye yükseltildi. İkisi de savaş statı.
const _documentedDeviations = {'attack:5', 'critChance:3'};

void main() {
  final catalog = ItemCatalog.fromAssetPaths(
    Directory('lib/Items')
        .listSync(recursive: true)
        .whereType<File>()
        .map((file) => file.path.replaceAll(r'\', '/'))
        .where((path) => path.endsWith('.png')),
  );

  /// (stat, kademe) → bugün kural havuzundan gelen değerlerin ortalaması.
  Map<String, double> measureMeans() {
    final sums = <String, double>{};
    final counts = <String, int>{};
    for (final item in catalog) {
      for (final characterClass in AvatarProfile.playableClassIds) {
        if (!item.isUsableBy(characterClass)) continue;
        final flavored = flavorForClass(item, characterClass);
        for (var rarity = flavored.rarity; ; ) {
          final resolved =
              rarity == flavored.rarity
                  ? flavored
                  : withRarity(flavored, rarity, characterClass: characterClass);
          for (var slot = 0; slot < forgeSlotCount(resolved); slot++) {
            final effect = forgeSlotEffect(resolved, slot);
            final key = '${effect.stat.name}:${rarityTier(rarity)}';
            sums[key] = (sums[key] ?? 0) + effect.value;
            counts[key] = (counts[key] ?? 0) + 1;
          }
          final next = nextRarity(rarity);
          if (next == null) break;
          rarity = next;
        }
      }
    }
    return {for (final key in sums.keys) key: sums[key]! / counts[key]!};
  }

  test('kural havuzunun ürettiği her statın beş kademesi var', () {
    final stats = {
      ...ItemArchetypes.combatSpec.keys,
      ...forgeEconomyStats,
    };
    for (final stat in stats) {
      for (var tier = 1; tier <= ForgeTiers.tierCount; tier++) {
        final range = ForgeTiers.rangeFor(stat, tier);
        expect(range, isNotNull, reason: '${stat.name} K$tier');
        expect(range!.$1, lessThanOrEqualTo(range.$2));
        expect(range.$1, greaterThan(0));
      }
    }
  });

  test('merkezler bugünkü ortalamaya oturuyor: ortalama güç değişmiyor', () {
    final means = measureMeans();
    final offenders = <String>[];
    for (final entry in means.entries) {
      final [name, tierText] = entry.key.split(':');
      final stat = ItemStat.values.byName(name);
      final tier = int.parse(tierText);
      final center = ForgeTiers.centerOf(stat, tier);
      final deviation = (center - entry.value).abs() / entry.value;
      if (_documentedDeviations.contains(entry.key)) {
        // Belgelenmiş sapma yine **yukarı** ve sınırlı olmalı.
        expect(center, greaterThan(entry.value), reason: entry.key);
        expect(deviation, lessThan(0.45), reason: entry.key);
        continue;
      }
      if (deviation > 0.15) {
        offenders.add(
          '${entry.key}: ortalama ${entry.value.toStringAsFixed(4)}, '
          'merkez ${center.toStringAsFixed(4)}',
        );
      }
    }
    expect(offenders, isEmpty, reason: offenders.take(5).join('\n'));
  });

  test('kademeler artan: üst kademenin merkezi alttakinden küçük değil', () {
    for (final entry in ForgeTiers.ranges.entries) {
      for (var tier = 2; tier <= ForgeTiers.tierCount; tier++) {
        expect(
          ForgeTiers.centerOf(entry.key, tier),
          greaterThanOrEqualTo(ForgeTiers.centerOf(entry.key, tier - 1)),
          reason: '${entry.key.name} K$tier',
        );
      }
    }
  });

  test('ekonomi kuralı: adım parası ve XP eski en yüksek değeri aşamaz', () {
    // Bir eşyada çıkabilecek en yüksek kademe nadirliğin kademesi; her
    // kademenin üst ucu o nadirliğin Bölüm E öncesi en yüksek değerinde.
    for (final rarity in RewardRarity.values) {
      final tier = rarityTier(rarity);
      final coin = ForgeTiers.rangeFor(ItemStat.stepCoin, tier)!.$2;
      final xp = ForgeTiers.rangeFor(ItemStat.stepXp, tier)!.$2;
      expect(coin, lessThanOrEqualTo(_legacyMax[rarity]!.coin + 1e-9));
      expect(xp, lessThanOrEqualTo(_legacyMax[rarity]!.xp + 1e-9));
      // Hiçbir kademe nadirliğin kademesini geçemiyor (seviye ne olursa).
      expect(maxForgeTier(rarity, 999), tier);
    }
  });

  test('aralık adımı aralığı tam bölüyor: uç değerler çekilebilir', () {
    for (final entry in ForgeTiers.ranges.entries) {
      final step = ForgeTiers.stepFor(entry.key);
      for (final (low, high) in entry.value) {
        final steps = (high - low) / step;
        expect(
          (steps - steps.round()).abs(),
          lessThan(1e-6),
          reason: '${entry.key.name} $low-$high / $step',
        );
      }
    }
  });
}
