import '../../data/item_definitions.dart';
import '../../models/item.dart';
import '../../models/reward_rarity.dart';

/// Bir item asset yolunun çözümlenmiş hâli.
class ItemAssetIdentity {
  /// Kalıcı kimlik: `<kategori klasörü>/<dosya adı>` (uzantısız).
  final String id;

  /// Varyant eki atılmış kimlik; [ItemDefinitions] bununla aranır.
  final String baseId;

  final ItemCategory category;

  /// `_variant_NN` ekindeki numara; varyantsız dosyalarda `null`.
  final int? variant;

  const ItemAssetIdentity({
    required this.id,
    required this.baseId,
    required this.category,
    this.variant,
  });
}

final RegExp _variantSuffix = RegExp(r'_variant_(\d+)$');

/// `lib/Items/<kategori>/<dosya>.png` yolunu çözümler.
///
/// Yol bu biçimde değilse ya da klasör bilinen bir kategori değilse `null`
/// döner; katalog o dosyayı sessizce atlar. Böylece klasöre atılan bir
/// `.DS_Store` ya da yanlış yere kopyalanmış bir görsel oyunu bozmaz.
ItemAssetIdentity? parseItemAsset(String assetPath) {
  const root = 'lib/Items/';
  if (!assetPath.startsWith(root)) return null;
  if (!assetPath.toLowerCase().endsWith('.png')) return null;

  final relative = assetPath.substring(root.length);
  final parts = relative.split('/');
  // Kategori klasörünün bir seviye altındaki dosyalar; daha derini atlanır.
  if (parts.length != 2) return null;

  final category = ItemCategoryX.fromFolder(parts.first);
  if (category == null) return null;

  final fileName = parts.last.substring(0, parts.last.length - 4);
  if (fileName.isEmpty) return null;

  final match = _variantSuffix.firstMatch(fileName);
  final baseName =
      match == null ? fileName : fileName.substring(0, match.start);

  return ItemAssetIdentity(
    id: '${parts.first}/$fileName',
    baseId: '${parts.first}/$baseName',
    category: category,
    variant: match == null ? null : int.tryParse(match.group(1)!),
  );
}

/// Nadirliğe göre seviye kilidinin taban değeri ve yayılma genişliği (#10).
///
/// Yayılma, aynı nadirlikteki yüzlerce item'ın hepsinin aynı seviyede
/// açılmasını engelliyor: kilitler bir banda dağılıyor, oyuncu her seviyede
/// yeni bir şey açıyor.
(int, int) _levelBand(RewardRarity rarity) => switch (rarity) {
  RewardRarity.common => (1, 3),
  RewardRarity.uncommon => (4, 4),
  RewardRarity.rare => (8, 5),
  RewardRarity.epic => (14, 6),
  RewardRarity.legendary => (22, 8),
};

/// [id] için kararlı, platformdan bağımsız bir dağılım değeri (0..[buckets]).
///
/// `String.hashCode` **kullanılmaz**: değeri Dart sürümleri ve platformlar
/// arasında sabit değil. Seviye kilidi bu değerden çıktığı için hash değişse
/// oyuncunun sahip olduğu item bir gün "seviyen yetmiyor" derdi.
int stableSpread(String id, int buckets) {
  if (buckets <= 1) return 0;
  var hash = 0;
  for (final unit in id.codeUnits) {
    hash = (hash * 31 + unit) % 1000003;
  }
  return hash % buckets;
}

/// Item'ı kuşanmak için gereken seviye (#10).
int requiredLevelFor(RewardRarity rarity, String id) {
  final (base, span) = _levelBand(rarity);
  return base + stableSpread(id, span);
}

/// Nadirliğin fiyat tabanı (coin).
///
/// Mevcut mağaza fiyatlarıyla (300/500/800/1200) ve Aşama 1b ekonomisiyle
/// aynı ölçekte tutuldu: 6.000 adım/gün = 120 coin/gün.
int _costBase(RewardRarity rarity) => switch (rarity) {
  RewardRarity.common => 120,
  RewardRarity.uncommon => 260,
  RewardRarity.rare => 550,
  RewardRarity.epic => 1400,
  RewardRarity.legendary => 3600,
};

/// Mağaza fiyatı. Seviye kilidi yükseldikçe fiyat da yükselir, ama fiyatı
/// belirleyen asıl şey nadirlik.
///
/// 120 coin/gün (6.000 adım) atan bir oyuncu için kabaca: sıradan yarım gün,
/// nadir bir hafta, epik üç hafta, efsanevi iki aydan uzun.
int costFor(RewardRarity rarity, int requiredLevel) {
  final raw = _costBase(rarity) * (1 + requiredLevel / 20);
  // 25'in katına yuvarlanır; fiyatlar okunur kalsın.
  return (raw / 25).round() * 25;
}

/// Nadirliğin toplam bonus oranı (0.07 = +%7).
double _buffTotal(RewardRarity rarity) => switch (rarity) {
  RewardRarity.common => 0.02,
  RewardRarity.uncommon => 0.04,
  RewardRarity.rare => 0.07,
  RewardRarity.epic => 0.12,
  RewardRarity.legendary => 0.20,
};

/// Kategorinin rolüne göre bonusun dağılımı.
///
/// Bugün yalnızca **adım kazancı** bonusu var; savaş istatistikleri Aşama
/// 4a'da tanımlanacak (bkz. [ItemBuff]). Dağılım rolden çıkıyor:
/// - yakın dövüş → XP (savaş gücü hızlı seviye demek),
/// - menzil ve savunma → para (hazırlıklı gezgin daha çok toplar),
/// - büyü → ikisi yarı yarıya.
///
/// **Kalkanlar geçici olarak menzille aynı yerde.** Doğru cevap savunma
/// istatistiği vermek; o istatistik henüz yok ve uydurmak, Aşama 4a'da ikinci
/// kez yazmak olurdu.
ItemBuff buffFor(RewardRarity rarity, ItemCategory category) {
  final total = _buffTotal(rarity);
  return switch (category.role) {
    ItemRole.melee => ItemBuff(stepXpBonus: total),
    ItemRole.ranged || ItemRole.defense => ItemBuff(stepCoinBonus: total),
    ItemRole.magic => ItemBuff(
      stepCoinBonus: total / 2,
      stepXpBonus: total / 2,
    ),
  };
}

/// Tanımsız bir dosya adını okunur hâle getirir: `fire_sword` → `Fire Sword`.
///
/// Türkçesi [ItemDefinitions] içinde yok demektir; İngilizce görünmesi
/// bilerek — eksikliği görünür kılıyor.
String fallbackDisplayName(String baseName) {
  final words = baseName.split('_').where((word) => word.isNotEmpty);
  return words
      .map(
        (word) =>
            word.length == 1
                ? word.toUpperCase()
                : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

/// Asset yolundan tam bir [Item] üretir. Yol tanınmıyorsa `null`.
Item? buildItemFromAsset(String assetPath) {
  final identity = parseItemAsset(assetPath);
  if (identity == null) return null;

  final definition = ItemDefinitions.of(identity.baseId);
  final rarity = definition?.$2 ?? ItemDefinitions.fallbackRarity;
  final baseName =
      definition?.$1 ?? fallbackDisplayName(identity.baseId.split('/').last);
  final name =
      identity.variant == null ? baseName : '$baseName ${identity.variant}';

  final requiredLevel = requiredLevelFor(rarity, identity.id);

  return Item(
    id: identity.id,
    name: name,
    assetPath: assetPath,
    category: identity.category,
    rarity: rarity,
    requiredLevel: requiredLevel,
    cost: costFor(rarity, requiredLevel),
    buff: buffFor(rarity, identity.category),
  );
}
