import '../models/reward_rarity.dart';

/// Kategorilerin nadirlik zincirindeki **ara boşlukları** dolduran eşyalar
/// (Bölüm E / Faz 2, GD111).
///
/// Katalog `lib/Items/` klasöründen üretiliyor ve her görsel tek bir eşya:
/// kimlik = görsel yolu. Bazı kategorilerde en düşük ve en yüksek nadirlik
/// arasında boşluk vardı (tırpanlarda sıradandan doğrudan efsaneviye) ve
/// yeni sanat yok.
///
/// Var olan bir varyantın nadirliğini değiştirmek **seçilmedi**: o görseli
/// taşıyan oyuncunun eşyası altından değişirdi — sıradan bir tırpanın
/// seviye kilidi bir gün sonra 22'ye çıkar ve oyuncu onu kuşanamazdı.
/// Bunun yerine aynı görseli kullanan **yeni bir kimlik** üretiliyor.
///
/// ## Kimlik şeması
///
/// ```
/// <görsel kimliği>@<nadirlik adı>
/// scythes/scythe_variant_12@uncommon
/// ```
///
/// - `@` öncesi her zaman var olan bir görselin kimliği (`<kategori>/<dosya>`);
///   kimlik hâlâ görsel yolundan **türetilebilir**: `lib/Items/` + önek +
///   `.png`.
/// - `@` sonrası [RewardRarity.name]. Görsel kimliklerinde `@` geçmiyor,
///   yani iki kimlik türü asla çakışmıyor.
/// - Görselin kendi kimliği (`scythes/scythe_variant_12`) olduğu gibi
///   duruyor: o eşyayı taşıyan oyuncunun envanteri değişmiyor.
///
/// Bu tablo veridir: hiçbir yerde `switch (id)` yok. Görseli klasörde
/// bulunmayan bir satır katalogda **hiç üretilmez** (sanat klasörü doğruluk
/// kaynağı olmaya devam ediyor).
class ItemTierExtension {
  /// Görselin kimliği: `<kategori klasörü>/<dosya adı>` (uzantısız).
  final String assetId;

  /// Bu kimliğin taşıdığı nadirlik.
  final RewardRarity rarity;

  /// Türkçe ad. Görsel paylaşıldığı için ad görselden türetilemez: türetilse
  /// kaynak varyantla aynı adı alırdı.
  final String name;

  /// İngilizce ad (aynı gerekçe).
  final String nameEn;

  const ItemTierExtension({
    required this.assetId,
    required this.rarity,
    required this.name,
    required this.nameEn,
  });

  /// Kalıcı kimlik — bkz. dosya başındaki şema.
  String get id => tierExtensionId(assetId, rarity);

  /// Görselin paket içindeki yolu.
  String get assetPath => 'lib/Items/$assetId.png';
}

/// Kimlik şemasının tek uygulama noktası.
String tierExtensionId(String assetId, RewardRarity rarity) =>
    '$assetId@${rarity.name}';

abstract final class ItemTierExtensions {
  ItemTierExtensions._();

  /// Beş ara boşluk. Her boşluğa bir eşya; görsel, ailenin en son
  /// varyantlarından seçildi.
  static const List<ItemTierExtension> all = [
    // Tırpanlar: sıradan → [az bulunur, nadir, epik] → efsanevi.
    ItemTierExtension(
      assetId: 'scythes/scythe_variant_12',
      rarity: RewardRarity.uncommon,
      name: 'Hasat Tırpanı',
      nameEn: 'Harvest Scythe',
    ),
    ItemTierExtension(
      assetId: 'scythes/scythe_variant_13',
      rarity: RewardRarity.rare,
      name: 'Kan Tırpanı',
      nameEn: 'Blood Scythe',
    ),
    ItemTierExtension(
      assetId: 'scythes/scythe_variant_14',
      rarity: RewardRarity.epic,
      name: 'Ayaz Tırpanı',
      nameEn: 'Rime Scythe',
    ),
    // Topuz ve çekiç: az bulunur → [nadir] → epik.
    ItemTierExtension(
      assetId: 'maces_hammers/mace_type_2_variant_14',
      rarity: RewardRarity.rare,
      name: 'Gece Topuzu',
      nameEn: 'Night Mace',
    ),
    // Mızraklar: az bulunur → [nadir] → epik.
    ItemTierExtension(
      assetId: 'spears/trident_variant_14',
      rarity: RewardRarity.rare,
      name: 'Buz Çatalı',
      nameEn: 'Frost Trident',
    ),
  ];

  /// Kimlikten satır; tabloda yoksa `null`.
  static ItemTierExtension? byId(String id) {
    for (final extension in all) {
      if (extension.id == id) return extension;
    }
    return null;
  }
}
