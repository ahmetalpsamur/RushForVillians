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
/// `stepsPerCoin`, `stepsPerXp`, `maxDailyStepCoins`, `baseXpPerLevel`,
/// `item_rules.dart:_costBase`, `_levelBand`.
void main() {
  /// Referans oyuncu. Günlük hedefle aynı (bkz. Aşama 1b/2b tabloları).
  const dailySteps = 6000;

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
  const minRatio = 0.5;
  const maxRatio = 1.8;

  final dailyXp = dailySteps / GameConstants.stepsPerXp;
  final dailyCoins = (dailySteps / GameConstants.stepsPerCoin).clamp(
    0,
    GameConstants.maxDailyStepCoins.toDouble(),
  );

  /// N. seviyeye ulaşmak için gereken toplam XP.
  ///
  /// `xpToNextLevel = baseXpPerLevel * level` olduğu için kümülatif maliyet
  /// `base/2 * N * (N-1)`. Aşama 2b'de aynı formül kullanıldı.
  double cumulativeXp(int level) =>
      GameConstants.baseXpPerLevel / 2 * level * (level - 1);

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
      cumulativeXp(
        median(ofRarity(rarity).map((i) => i.requiredLevel).toList()),
      ) /
      dailyXp;

  /// Katmanın fiyatını biriktirme süresi (gün).
  double daysToAfford(RewardRarity rarity) =>
      median(ofRarity(rarity).map((i) => i.cost).toList()) *
      itemsPerTier /
      dailyCoins;

  group('kümülatif XP formülü', () {
    test('addXp ile aynı sonucu verir', () {
      // Formülü modelden bağımsız doğrula: 10. seviye 45.000 XP (Aşama 2b).
      expect(cumulativeXp(10), 45000);
      expect(cumulativeXp(1), 0);
      expect(cumulativeXp(2), GameConstants.baseXpPerLevel.toDouble());
    });

    test('referans oyuncunun günlük kazancı beklenen değerde', () {
      expect(dailyXp, 3000);
      expect(dailyCoins, 120);
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
        final levelDays = daysToTier(rarity);
        final coinDays = daysToAfford(rarity);
        final ratio = coinDays / levelDays;

        expect(
          ratio,
          inInclusiveRange(minRatio, maxRatio),
          reason:
              '${rarity.label}: seviyeye ${levelDays.toStringAsFixed(1)} gün, '
              'paraya ${coinDays.toStringAsFixed(1)} gün '
              '(oran ${ratio.toStringAsFixed(2)}). Bant dışına çıktıysa '
              'DÜZELTME item_rules.dart:_costBase içine yazılmalı — '
              'XP eğrisine dokunma (Aşama 2b\'de ayrıca gerekçelendirildi).',
        );
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
