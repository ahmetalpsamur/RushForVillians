import '../models/reward_rarity.dart';

/// Çarkın **bütün** oranları tek dosyada.
///
/// Kural: çarkta hiçbir şey "öylesine" seçilmez. Dilimin türü, ekipmanın
/// nadirliği, XP ve altın miktarı — hepsi burada yazılı bir ağırlık
/// tablosundan çıkar. Denge değişecekse yalnızca bu dosya düzenlenir ve
/// `wheel_rewards_test.dart` sapmayı yakalar.
///
/// Ağırlıklar **bağıl**: 60 ağırlıklı bir seçenek, 30 ağırlıklı olanın iki
/// katı sıklıkta çıkar. Yüzdeye çevirmek için ağırlığı toplamına böl.
abstract final class WheelOdds {
  /// Çarktaki toplam dilim sayısı.
  static const int sliceCount = 8;

  // ---------------------------------------------------------------- ünvan

  /// Uygun ünvan varken çarkta ünvan dilimi çıkma ihtimali (%25).
  ///
  /// Ünvan dört kazanma yolundan yalnızca biri (GD71); her çevirmede
  /// görünmesi başarım ve kilometre taşı yollarını anlamsızlaştırırdı.
  static const double titleSliceChance = 0.25;

  /// Bir çarkta en fazla kaç ünvan dilimi olabilir.
  static const int maxTitleSlices = 1;

  // -------------------------------------------------------------- ekipman

  /// Bir çarkta en fazla kaç ekipman dilimi olabilir.
  static const int maxItemSlices = 4;

  /// Uygun ekipman varken kaç dilimin ekipman olacağı.
  ///
  /// İndeks 0 = bir dilim. **En az bir** ekipman dilimi garanti: çark
  /// ekipman vaadini her çevirmede tutmalı.
  static const List<int> itemSliceCountWeights = [55, 28, 12, 5];

  /// Çarktan çıkabilecek en yüksek ekipman nadirliği.
  ///
  /// Epik ~üç haftalık, efsanevi ~iki aylık birikim (Aşama 3 denge tablosu).
  /// Günde bir dönen bir çarktan düşmeleri hem mağazayı hem seviye kilidini
  /// anlamsız kılardı.
  static const RewardRarity maxItemRarity = RewardRarity.rare;

  /// Ekipman seçilirken kullanılan nadirlik ağırlığı.
  ///
  /// [maxItemRarity] üstündekiler zaten havuza girmiyor; ağırlıkları
  /// tabloda sıfır olarak duruyor ki kuralın nerede uygulandığı görünsün.
  static double itemRarityWeight(RewardRarity rarity) => switch (rarity) {
    RewardRarity.common => 60,
    RewardRarity.uncommon => 27,
    RewardRarity.rare => 10,
    RewardRarity.epic => 0,
    RewardRarity.legendary => 0,
  };

  /// Ünvan seçilirken kullanılan nadirlik ağırlığı.
  ///
  /// Ekipmandan farklı: çark kaynaklı ünvanlar zaten yedi tane ve biri
  /// efsanevi. Onu tamamen kapatmak yerine çok düşük ağırlıkla bırakıyoruz —
  /// ünvan kalıcı bir kimlik, ekonomiye girmiyor.
  static double titleRarityWeight(RewardRarity rarity) => switch (rarity) {
    RewardRarity.common => 50,
    RewardRarity.uncommon => 28,
    RewardRarity.rare => 14,
    RewardRarity.epic => 6,
    RewardRarity.legendary => 2,
  };

  // ---------------------------------------------------------------- altın

  /// Bir çarkta en fazla kaç altın dilimi olabilir.
  static const int maxCoinSlices = 3;

  /// Kaç dilimin altın olacağı. İndeks 0 = bir dilim.
  static const List<int> coinSliceCountWeights = [30, 45, 25];

  /// Altın dilimlerinin değerleri.
  static const List<int> coinOptions = [25, 50, 75, 100, 150, 200, 300, 500];

  /// [coinOptions] ile aynı sıradaki ağırlıklar.
  ///
  /// Beklenen değer ≈ **77 altın**. İki altın dilimiyle bir çevirmenin
  /// beklenen getirisi ≈ 19 altın/gün; referans oyuncunun günlük 120
  /// altınının yaklaşık **%16**'sı — hissedilir ama adım ekonomisini
  /// (`economy_pacing_test.dart`) devirmez.
  static const List<int> coinWeights = [30, 25, 18, 12, 8, 4, 2, 1];

  // ------------------------------------------------------------------- XP

  /// XP dilimlerinin değerleri: 50'den 1000'e, 50'şer.
  ///
  /// Sıfır **yok**: boş dilim hiçbir koşulda oluşmamalı.
  static const List<int> xpOptions = [
    50, 100, 150, 200, 250, 300, 350, 400, 450, 500, //
    550, 600, 650, 700, 750, 800, 850, 900, 950, 1000,
  ];

  /// [xpOptions] ile aynı sıradaki ağırlıklar: küçük ödül sık, büyük ödül
  /// nadir. Beklenen değer ≈ **367 XP** (referans oyuncunun günlük 3.000
  /// adım XP'sinin ~%12'si).
  static const List<int> xpWeights = [
    20, 19, 18, 17, 16, 15, 14, 13, 12, 11, //
    10, 9, 8, 7, 6, 5, 4, 3, 2, 1,
  ];
}
