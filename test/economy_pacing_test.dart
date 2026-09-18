import 'package:rush_for_villains/models/user_profile.dart';
import 'level_steps_test.dart' show avatar;
import 'package:rush_for_villains/core/utils/level_steps.dart';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/game_constants.dart';
import 'package:rush_for_villains/core/utils/item_rules.dart';
import 'package:rush_for_villains/models/item.dart';
import 'package:rush_for_villains/models/reward_rarity.dart';

/// **Seviye ↔ fiyat hizalaması.**
///
/// Aşama 3'te seviye kilidi ve fiyat ayrı ayrı türetildi; ikisinin aynı
/// ilerleme hızına oturup oturmadığı ölçülmemişti. Bu dosya o ölçümü
/// **test hâline getiriyor** — prosa tahmini olarak bırakılmıyor.
///
/// Sorulan soru: bir nadirlik katmanına ulaşmak kaç gün sürer (seviye kapısı)
/// ve o katmanın fiyatını biriktirmek kaç gün sürer (para kapısı)? İkisi
/// birbirinden kopmuşsa kapılardan biri dekoratif hâle gelir.
///
/// Bu test şu sabitlerden herhangi biri değişirse alarm verir:
/// `stepsPerCoin`, `stepsPerXp`, `calculateRequiredSteps`,
/// `item_rules.dart:_costBase`, `_levelBand`.
void main() {
  /// Referans oyuncu. Günlük hedefle aynı (bkz. Aşama 1b/2b tabloları).
  const dailySteps = GameConstants.dailyStepGoal;

  /// **Açık varsayım:** oyuncu her nadirlik katmanında kaç item alıyor?
  ///
  /// Fiyat eğrisi buna göre kalibre edildi. Her sınıf 3–5 kategori görüyor
  /// (bkz. GD15) ve gerçekçi bir oyuncu katman başına bunların ikisinde
  /// yükseltme yapar. Tek item varsayımı parayı seviyeden **iki kat** önce
  /// biriktirir, üç item varsayımı tersini yapar; kesişim ikide.
  const itemsPerTier = 2;

  /// Oranın kalması gereken bant.
  ///
  /// Altına düşerse para hiçbir zaman kısıt olmaz (fiyat dekoratif),
  /// üstüne çıkarsa seviye hiçbir zaman kısıt olmaz (kilit dekoratif).
  /// Bant 2× sapmayı yakalayacak kadar dar, gürültüye takılmayacak kadar geniş.
  final dailyXp = dailySteps / GameConstants.stepsPerXp;
  final dailyCoins = dailySteps / GameConstants.stepsPerCoin;

  /// The new cumulative walking requirement; equipment prices are unchanged.
  double cumulativeSteps(int level) =>
      List.generate(
        level - 1,
        (i) => calculateRequiredSteps(i + 1),
      ).fold<int>(0, (a, b) => a + b).toDouble();

  final catalog =
      [
        for (final entity in Directory('lib/Items').listSync(recursive: true))
          if (entity is File)
            buildItemFromAsset(
              entity.path.replaceAll(Platform.pathSeparator, '/'),
            ),
      ].nonNulls.toList();

  List<Item> ofRarity(RewardRarity rarity) =>
      catalog.where((item) => item.rarity == rarity).toList();

  int median(List<int> values) {
    final sorted = [...values]..sort();
    return sorted[sorted.length ~/ 2];
  }

  /// Katmanın seviye kapısına ulaşma süresi (gün).
  double daysToTier(RewardRarity rarity) =>
      cumulativeSteps(
        median(ofRarity(rarity).map((i) => i.requiredLevel).toList()),
      ) /
      dailySteps;

  /// Katmanın fiyatını biriktirme süresi (gün).
  double daysToAfford(RewardRarity rarity) =>
      median(ofRarity(rarity).map((i) => i.cost).toList()) *
      itemsPerTier /
      dailyCoins;

  group('step pacing and independent XP', () {
    test('reference step totals', () {
      expect(cumulativeSteps(80), 371850);
      expect(cumulativeSteps(1), 0);
      expect(cumulativeSteps(2), 500);
    });

    test('referans oyuncunun günlük kazancı beklenen değerde', () {
      expect(dailyXp, 3500);
      expect(dailyCoins, 140);
    });
  });

  group('seviye ↔ fiyat hizalaması', () {
    // Sıradan katman **bilerek dışarıda**: seviye bandı 1-3, yani seviye
    // kapısı birkaç saatte geçiliyor ve oran anlamını yitiriyor. O katmanın
    // ölçütü mutlak: aşağıdaki "ilk satın alma" testi.
    const measured = [
      RewardRarity.uncommon,
      RewardRarity.rare,
      RewardRarity.epic,
      RewardRarity.legendary,
    ];

    for (final rarity in measured) {
      test('${rarity.label}: iki kapı da anlamlı kalıyor', () {
        final items = ofRarity(rarity);
        final required = median(items.map((i) => i.requiredLevel).toList());
        final item = items.firstWhere((i) => i.requiredLevel == required);
        final player = UserProfile(avatar: avatar);
        final threshold = cumulativeSteps(required).toInt();
        player.creditLevelStepsThrough(threshold - 1);
        expect(item.isUnlockedAt(player.level), isFalse);
        player.creditLevelStepsThrough(threshold);
        expect(item.isUnlockedAt(player.level), isTrue);
        expect(
          player.coins,
          0,
          reason: 'unlocking a level never pays the item price',
        );
        expect(item.cost, greaterThan(player.coins));
      });
    }

    test('nadirlik yükseldikçe iki kapı da uzuyor', () {
      for (var i = 1; i < RewardRarity.values.length; i++) {
        final previous = RewardRarity.values[i - 1];
        final current = RewardRarity.values[i];

        expect(
          daysToTier(current),
          greaterThan(daysToTier(previous)),
          reason: '${current.label} seviye kapısı gerilemiş',
        );
        expect(
          daysToAfford(current),
          greaterThan(daysToAfford(previous)),
          reason: '${current.label} para kapısı gerilemiş',
        );
      }
    });
  });

  group('ilk satın alma', () {
    test('günlük hedefi tutturan oyuncu ilk akşam bir item alabilir', () {
      // Mağazanın ilk gün ölü görünmemesi için tek şart bu.
      final cheapest = catalog
          .map((item) => item.cost)
          .reduce((a, b) => a < b ? a : b);

      expect(
        cheapest,
        lessThanOrEqualTo(dailyCoins),
        reason:
            '6.000 adım = $dailyCoins coin; en ucuz item $cheapest coin. '
            'Oyuncu ilk günü eli boş kapatıyor.',
      );
    });

    test('en ucuz item ilk seviyede açık', () {
      final cheapest = catalog.reduce((a, b) => a.cost <= b.cost ? a : b);

      expect(
        cheapest.isUnlockedAt(1),
        isTrue,
        reason: 'parası yeten yeni oyuncu seviye kilidine takılmamalı',
      );
    });

    test('en ucuz item bedava değil', () {
      final cheapest = catalog
          .map((item) => item.cost)
          .reduce((a, b) => a < b ? a : b);

      // Yarım günlük yürüyüşün altına inmesin; ekonomi anlamını yitirir.
      expect(cheapest, greaterThanOrEqualTo(dailyCoins / 2));
    });
  });
}
