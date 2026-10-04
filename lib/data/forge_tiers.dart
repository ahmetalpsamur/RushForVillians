import '../models/item_effect.dart';

/// Yeniden atmanın **kademeli aralıkları** (Bölüm E / Faz 4, GD112).
///
/// Tablo veridir; `item_forging.dart` yalnızca okur.
///
/// ## Nasıl kuruldu
///
/// Beş kademe, beş nadirliğe karşılık geliyor (Kademe I = sıradan ...
/// Kademe V = efsanevi). Her (stat, kademe) aralığının **merkezi**, o statın
/// o nadirlikteki kuraldan türeyen eşyalarda bugün taşıdığı **ortalama**
/// değer — 18 sınıf × 789 eşya × bütün birleştirme basamakları üzerinden
/// ölçüldü (Faz E4 sondası). Aralık uniform çekildiği için beklenen değer
/// merkezdir: yeniden atmak ortalama gücü değiştirmez.
/// `forge_tiers_test.dart` merkezleri ölçülen ortalamaya bağlıyor.
///
/// - **Savaş statları:** merkez ±%35.
/// - **Ekonomi oranları:** merkez ±%25 ve üst uç o nadirliğin Bölüm E öncesi
///   en yüksek değerine **kırpılı** (adım parası .02 · .03 · .08 · .14 · .15,
///   adım XP .02 · .03 · .054 · .11 · .15). Ekonomi kuralı: yeniden atma ve
///   seçim mevcut en yüksek değeri aşamaz.
/// - **Stok bonusları** (dondurma, çark hakkı) her kademede `+1`: ölçülen
///   ortalama 1,0–1,17. Ekonomi tarafında temkinli kalındı.
///
/// ## Ölçümden bilerek sapan iki merkez
///
/// Kademeler artan olmalı ("Kademe V, Kademe IV'ten zayıf" okunmaz), ama iki
/// statın ölçülen ortalaması nadirlikte düşüyor — çünkü üst nadirlikte o stat
/// çoğunlukla **ikincil yuvaya** düşüyor ve payı küçülüyor:
///
/// | Stat | Kademe | Ölçülen ortalama | Merkez | Fark |
/// |---|---|---|---|---|
/// | saldırı | V | 21,5 | 30 | +%40 |
/// | kritik şansı | III | %5,3 | %6,75 | +%28 |
///
/// İkisi de savaş statı; ekonomi tarafında sapma yok.
///
/// Ölçümü olmayan hücreler (kritik hasarı, can çalma ve can düşük
/// nadirliklerde hiç çıkmıyor) savaş bütçesi oranıyla (9 · 18 · 32 · 55 · 90)
/// ölçülen ilk hücreden geriye uzatıldı.
abstract final class ForgeTiers {
  ForgeTiers._();

  static const int tierCount = 5;

  /// `(alt, üst)`; yüzdeli statlarda oran, sabit statlarda sayı.
  static const Map<ItemStat, List<(double, double)>> ranges = {
    // ── Savaş (±%35) ──
    ItemStat.attack: [(5, 9), (8, 18), (10, 20), (18, 36), (20, 40)],
    ItemStat.maxHealth: [(3, 5), (5, 11), (10, 20), (16, 34), (20, 42)],
    ItemStat.defense: [
      (0.04, 0.09),
      (0.085, 0.175),
      (0.10, 0.20),
      (0.165, 0.345),
      (0.21, 0.44),
    ],
    ItemStat.critChance: [
      (0.02, 0.04),
      (0.04, 0.08),
      (0.045, 0.09),
      (0.06, 0.125),
      (0.075, 0.16),
    ],
    ItemStat.critDamage: [
      (0.025, 0.055),
      (0.05, 0.11),
      (0.095, 0.195),
      (0.16, 0.33),
      (0.225, 0.465),
    ],
    ItemStat.lifeSteal: [
      (0.005, 0.005),
      (0.005, 0.015),
      (0.015, 0.025),
      (0.02, 0.04),
      (0.035, 0.065),
    ],
    ItemStat.dodge: [
      (0.015, 0.035),
      (0.035, 0.065),
      (0.04, 0.08),
      (0.065, 0.135),
      (0.085, 0.175),
    ],
    // ── Ekonomi (±%25, üst uç Bölüm E öncesi en yüksek değere kırpılı) ──
    ItemStat.stepCoin: [
      (0.013, 0.02),
      (0.016, 0.026),
      (0.029, 0.048),
      (0.032, 0.053),
      (0.055, 0.091),
    ],
    ItemStat.stepXp: [
      (0.014, 0.02),
      (0.017, 0.029),
      (0.031, 0.051),
      (0.035, 0.059),
      (0.062, 0.103),
    ],
    ItemStat.wheelXp: [
      (0.028, 0.046),
      (0.034, 0.056),
      (0.062, 0.103),
      (0.068, 0.113),
      (0.096, 0.15),
    ],
    ItemStat.enemyXp: [
      (0.028, 0.046),
      (0.035, 0.058),
      (0.062, 0.104),
      (0.071, 0.118),
      (0.098, 0.15),
    ],
    ItemStat.streakFreezeCap: [(1, 1), (1, 1), (1, 1), (1, 1), (1, 1)],
    ItemStat.wheelSpinCap: [(1, 1), (1, 1), (1, 1), (1, 1), (1, 1)],
    ItemStat.streakRelief: [
      (25, 75),
      (50, 100),
      (75, 175),
      (100, 200),
      (150, 300),
    ],
  };

  /// Aralığın çekiliş adımı: değer `alt + k × adım` biçiminde çıkar.
  static double stepFor(ItemStat stat) => switch (stat) {
    ItemStat.attack ||
    ItemStat.maxHealth ||
    ItemStat.streakFreezeCap ||
    ItemStat.wheelSpinCap => 1,
    ItemStat.streakRelief => 25,
    ItemStat.stepCoin ||
    ItemStat.stepXp ||
    ItemStat.wheelXp ||
    ItemStat.enemyXp => 0.001,
    _ => 0.005,
  };

  /// Bir (stat, kademe) aralığı; tabloda yoksa `null`.
  static (double, double)? rangeFor(ItemStat stat, int tier) {
    final list = ranges[stat];
    if (list == null || tier < 1 || tier > list.length) return null;
    return list[tier - 1];
  }

  /// Aralığın merkezi.
  static double centerOf(ItemStat stat, int tier) {
    final (low, high) = rangeFor(stat, tier)!;
    return (low + high) / 2;
  }
}
