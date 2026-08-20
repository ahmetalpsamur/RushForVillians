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

/// Nadirliğin toplam bonus bütçesi (0.07 = +%7). Bütçe, item'ın taşıdığı
/// bonuslara [_buffShares] oranlarıyla bölünür.
double _buffTotal(RewardRarity rarity) => switch (rarity) {
  RewardRarity.common => 0.02,
  RewardRarity.uncommon => 0.05,
  RewardRarity.rare => 0.09,
  RewardRarity.epic => 0.15,
  RewardRarity.legendary => 0.26,
};

/// Nadirliğin taşıdığı **bonus sayısı**.
///
/// Sıradan bir item tek şey yapar; efsanevi bir item üç şey birden. Üçte
/// duruyoruz: mağaza kartı sabit yükseklikte (bkz. GD12) ve dört satır
/// bonus okunmaz hâle geliyor.
int buffCountFor(RewardRarity rarity) => switch (rarity) {
  RewardRarity.common => 1,
  RewardRarity.uncommon => 2,
  RewardRarity.rare => 2,
  RewardRarity.epic => 3,
  RewardRarity.legendary => 3,
};

/// Bütçenin bonuslara dağılımı. Birincil bonus her zaman en büyük payı alır;
/// item'ın "ne işe yaradığı" tek bakışta anlaşılsın.
List<double> _buffShares(int count) => switch (count) {
  1 => const [1.0],
  2 => const [0.6, 0.4],
  _ => const [0.5, 0.3, 0.2],
};

/// Karakter sınıfının **imza bonusu**: o sınıfın itemlerinde her zaman
/// birincil sırada durur.
///
/// Aynı görselin Büyücüde ve Kara Büyücüde farklı bir item olmasını sağlayan
/// şey bu. Sekiz sınıfa sekiz ayrı tür düşüyor; hiçbiri tekrar etmiyor.
ItemBuffType _classSignature(String characterClass) => switch (characterClass) {
  // Savaşçı düşmandan daha çok ders çıkarır.
  'SwordMan' => ItemBuffType.enemyXp,
  // Paladin kararlıdır: serisini korur.
  'Paladin' => ItemBuffType.streakFreezeCap,
  // Hırsız günlük kazanç tavanını zorlar.
  'Thief' => ItemBuffType.dailyCoinCap,
  // Okçu gezgindir: yol para eder.
  'Archer' => ItemBuffType.stepCoin,
  // Büyücü öğrenir.
  'Magic' => ItemBuffType.stepXp,
  // Kara büyücü kaderi kendine çevirir.
  'DarkMagic' => ItemBuffType.wheelXp,
  // İnanç disiplindir: seri eşiği düşer.
  'Faith' => ItemBuffType.streakRelief,
  // Doğa döngüseldir: çark hakkı birikir.
  'Nature' => ItemBuffType.wheelSpinCap,
  _ => ItemBuffType.stepCoin,
};

/// Kategorinin rolüne göre ikincil bonus eğilimi.
///
/// - yakın dövüş → XP ve düşman XP'si (savaş gücü hızlı seviye demek),
/// - menzil → para ve kazanç tavanı (hazırlıklı gezgin daha çok toplar),
/// - savunma → dayanıklılık (seri koruma, eşik indirimi),
/// - büyü → çark ve XP (şans ve bilgi).
///
/// **Kalkanlar artık menzille aynı yerde değil** — savunma rolü kendi
/// eğilimini aldı (bkz. GD9'daki bilinçli tuhaflık). Savaş istatistiği hâlâ
/// yok; verilen şey "dayanıklılığın oyun dışı karşılığı".
List<ItemBuffType> _roleOrder(ItemRole role) => switch (role) {
  ItemRole.melee => const [
    ItemBuffType.stepXp,
    ItemBuffType.enemyXp,
    ItemBuffType.streakRelief,
  ],
  ItemRole.ranged => const [
    ItemBuffType.stepCoin,
    ItemBuffType.dailyCoinCap,
    ItemBuffType.wheelSpinCap,
  ],
  ItemRole.defense => const [
    ItemBuffType.stepCoin,
    ItemBuffType.streakFreezeCap,
    ItemBuffType.streakRelief,
  ],
  ItemRole.magic => const [
    ItemBuffType.stepXp,
    ItemBuffType.wheelXp,
    ItemBuffType.stepCoin,
  ],
};

/// Bir item'ın bonus türlerini sırayla verir: önce sınıf imzası, sonra
/// kategori eğilimi, sonra kalanlar.
///
/// Kuyruk [stableSpread] ile döndürülür; böylece aynı sınıf ve kategorideki
/// yüzlerce item aynı ikincil bonusa yapışmaz. Döndürme kimlikten çıktığı için
/// **kararlı**: aynı item her açılışta aynı bonusları verir (bkz. GD8).
List<ItemBuffType> buffTypeOrder(
  ItemCategory category, {
  String? characterClass,
  String id = '',
}) {
  final signature =
      characterClass == null
          ? _roleOrder(category.role).first
          : _classSignature(characterClass);

  final seen = <ItemBuffType>{signature};
  final tail = <ItemBuffType>[];
  for (final type in [..._roleOrder(category.role), ...ItemBuffType.values]) {
    if (seen.add(type)) tail.add(type);
  }

  if (tail.isEmpty) return [signature];
  final offset = stableSpread(id, tail.length);
  return [signature, ...tail.sublist(offset), ...tail.sublist(0, offset)];
}

/// Item'ın buff'ı. [characterClass] verilmezse sınıftan bağımsız temel buff
/// üretilir; sınıfa uyarlama [flavorForClass] üzerinden yapılır.
///
/// Sayı olarak verilen bonuslar (tavan, eşik) oranla ölçeklenip okunur
/// değerlere yuvarlanır ve hiçbiri sıfıra düşmez: etiketi görünüp etkisi
/// olmayan bir bonus olmamalı.
ItemBuff buffFor(
  RewardRarity rarity,
  ItemCategory category, {
  String? characterClass,
  String id = '',
}) {
  final count = buffCountFor(rarity);
  final shares = _buffShares(count);
  final total = _buffTotal(rarity);
  final types = buffTypeOrder(
    category,
    characterClass: characterClass,
    id: id,
  ).take(count);

  var stepCoin = 0.0;
  var stepXp = 0.0;
  var wheelXp = 0.0;
  var enemyXp = 0.0;
  var coinCap = 0;
  var freezeCap = 0;
  var spinCap = 0;
  var relief = 0;

  var index = 0;
  for (final type in types) {
    final value = total * shares[index++];
    switch (type) {
      case ItemBuffType.stepCoin:
        stepCoin += value;
      case ItemBuffType.stepXp:
        stepXp += value;
      // Çark ve düşman XP'si nadir olaylar: aynı bütçe payı orada daha az
      // hissedilir, bu yüzden iki katına çıkarılıyor.
      case ItemBuffType.wheelXp:
        wheelXp += value * 2;
      case ItemBuffType.enemyXp:
        enemyXp += value * 2;
      case ItemBuffType.dailyCoinCap:
        coinCap += _roundTo(value * 600, 5);
      case ItemBuffType.streakFreezeCap:
        freezeCap += _atLeastOne(value * 12);
      case ItemBuffType.wheelSpinCap:
        spinCap += _atLeastOne(value * 12);
      case ItemBuffType.streakRelief:
        relief += _roundTo(value * 3000, 25);
    }
  }

  return ItemBuff(
    stepCoinBonus: stepCoin,
    stepXpBonus: stepXp,
    wheelXpBonus: wheelXp,
    enemyXpBonus: enemyXp,
    dailyCoinCapBonus: coinCap,
    streakFreezeCapBonus: freezeCap,
    wheelSpinCapBonus: spinCap,
    streakStepRelief: relief,
  );
}

int _roundTo(double value, int step) {
  final rounded = (value / step).round() * step;
  return rounded < step ? step : rounded;
}

int _atLeastOne(double value) {
  final rounded = value.round();
  return rounded < 1 ? 1 : rounded;
}

/// Karakter sınıfının, paylaşılan itemlerin adına eklenen lakabı.
///
/// Sıfat kullanılıyor, tamlama değil: "Şövalyenin Hançer" gibi bozuk Türkçe
/// üretmesin. Sıfat her ada takılabilir ve ek gerektirmez.
String classEpithet(String characterClass) => switch (characterClass) {
  'SwordMan' => 'Çelik',
  'Paladin' => 'Kutsanmış',
  'Thief' => 'Gölge',
  'Archer' => 'Çevik',
  'Magic' => 'Esrarlı',
  'DarkMagic' => 'Lanetli',
  'Faith' => 'Adanmış',
  'Nature' => 'Yabani',
  _ => '',
};

/// Item'ı bir karakter sınıfına uyarlar: paylaşılan kategorilerde ad lakapla
/// değişir, buff sınıfın imzasına göre yeniden türetilir.
///
/// Kimlik **değişmez** (bkz. [Item.copyWith] yorumu): sahiplik kaydı sınıftan
/// bağımsız durur, oyuncu sınıf değiştirdiğinde envanteri kaybolmaz.
Item flavorForClass(Item item, String characterClass) {
  final epithet = item.category.isShared ? classEpithet(characterClass) : '';
  return item.copyWith(
    name: epithet.isEmpty ? item.name : '$epithet ${item.name}',
    buff: buffFor(
      item.rarity,
      item.category,
      characterClass: characterClass,
      id: item.id,
    ),
  );
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
