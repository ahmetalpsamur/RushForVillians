import 'reward_rarity.dart';

/// Item kategorisi. Her kategori bir asset klasörüne birebir karşılık gelir
/// (`lib/Items/<folder>/`), böylece katalog dosya sisteminden üretilebiliyor.
enum ItemCategory {
  swords,
  axesHalberds,
  macesHammers,
  spears,
  scythes,
  magic,
  shields,
  arch,
  rangedOther,
  specialOther,
}

/// Kategorinin oyun içindeki rolü. Buff dağılımı buradan çıkar.
enum ItemRole { melee, magic, ranged, defense }

extension ItemCategoryX on ItemCategory {
  /// `lib/Items/` altındaki klasör adı. Katalog taraması bunu kullanır.
  String get folder => switch (this) {
    ItemCategory.swords => 'swords',
    ItemCategory.axesHalberds => 'axes_halberds',
    ItemCategory.macesHammers => 'maces_hammers',
    ItemCategory.spears => 'spears',
    ItemCategory.scythes => 'scythes',
    ItemCategory.magic => 'magic',
    ItemCategory.shields => 'shields',
    ItemCategory.arch => 'arch',
    ItemCategory.rangedOther => 'ranged_other',
    ItemCategory.specialOther => 'special_other',
  };

  String get label => switch (this) {
    ItemCategory.swords => 'Kılıçlar',
    ItemCategory.axesHalberds => 'Baltalar ve Teberler',
    ItemCategory.macesHammers => 'Topuzlar ve Çekiçler',
    ItemCategory.spears => 'Mızraklar',
    ItemCategory.scythes => 'Tırpanlar',
    ItemCategory.magic => 'Büyü',
    ItemCategory.shields => 'Kalkanlar',
    ItemCategory.arch => 'Yay ve Ok',
    ItemCategory.rangedOther => 'Fırlatma Silahları',
    ItemCategory.specialOther => 'Özel',
  };

  ItemRole get role => switch (this) {
    ItemCategory.swords ||
    ItemCategory.axesHalberds ||
    ItemCategory.macesHammers ||
    ItemCategory.spears ||
    ItemCategory.scythes => ItemRole.melee,
    ItemCategory.magic => ItemRole.magic,
    ItemCategory.arch ||
    ItemCategory.rangedOther ||
    ItemCategory.specialOther => ItemRole.ranged,
    ItemCategory.shields => ItemRole.defense,
  };

  /// Bu kategoriyi kuşanabilen karakter sınıfları
  /// ([AvatarProfile.classLabels] anahtarları).
  ///
  /// Her sınıfa en az iki kategori düşecek şekilde dağıtıldı; kimse
  /// kuşanacak item bulamamakla kalmasın.
  List<String> get characterClasses => switch (this) {
    ItemCategory.swords => const ['SwordMan', 'Thief'],
    ItemCategory.axesHalberds => const ['SwordMan', 'Paladin'],
    ItemCategory.macesHammers => const ['Paladin', 'Faith'],
    ItemCategory.spears => const ['Paladin', 'Nature'],
    ItemCategory.scythes => const ['DarkMagic', 'Thief'],
    ItemCategory.magic => const ['Magic', 'DarkMagic', 'Faith', 'Nature'],
    ItemCategory.shields => const ['SwordMan', 'Paladin', 'Faith'],
    ItemCategory.arch => const ['Archer', 'Nature'],
    ItemCategory.rangedOther => const ['Archer', 'Thief'],
    ItemCategory.specialOther => const ['Thief'],
  };

  static ItemCategory? fromFolder(String folder) {
    for (final category in ItemCategory.values) {
      if (category.folder == folder) return category;
    }
    return null;
  }
}

/// Bir item'ın sağladığı kalıcı bonus.
///
/// Bugün yalnızca **adım kazancını** büyüten iki çarpan var, çünkü Aşama 1b/2b
/// bu iki noktaya (`calculateStepCoins`, `calculateStepXp`) zaten birer
/// `TODO(items)` çarpan kancası bıraktı. Savaş istatistikleri (can, saldırı,
/// savunma) Aşama 4a'da tanımlanacak; onlar netleşmeden buraya savaş alanı
/// eklemek, iki kez yazmak demek olurdu.
class ItemBuff {
  /// Adımdan kazanılan paraya eklenen oran (0.05 = +%5).
  final double stepCoinBonus;

  /// Adımdan kazanılan XP'ye eklenen oran (0.05 = +%5).
  final double stepXpBonus;

  const ItemBuff({this.stepCoinBonus = 0, this.stepXpBonus = 0});

  static const none = ItemBuff();

  bool get isEmpty => stepCoinBonus == 0 && stepXpBonus == 0;

  /// Kullanıcıya gösterilecek kısa açıklama; bonus yoksa `null`.
  String? get label {
    if (isEmpty) return null;
    final parts = <String>[];
    if (stepCoinBonus > 0) {
      parts.add('adım parası +%${_percent(stepCoinBonus)}');
    }
    if (stepXpBonus > 0) parts.add('adım XP +%${_percent(stepXpBonus)}');
    return parts.join(' · ');
  }

  static String _percent(double value) {
    final percent = value * 100;
    final rounded = percent.round();
    // Yarım yüzdeleri yuvarlayıp saklamak yerine göster: %2,5 gibi.
    if ((percent - rounded).abs() < 0.05) return '$rounded';
    return percent.toStringAsFixed(1).replaceAll('.', ',');
  }
}

/// Envanterde ve mağazada kullanılan item.
///
/// **Kalıcı değildir.** Diske yalnızca [id] yazılır
/// ([UserProfile.ownedItemIds]); item'ın kendisi her açılışta katalogdan
/// yeniden üretilir. Bu yüzden Model Kuralları #1 gereği burada hiçbir
/// Flutter tipi yok — görsel [assetPath] ile `String` olarak taşınıyor.
class Item {
  /// Kalıcı kimlik: `<kategori klasörü>/<dosya adı>` (uzantısız).
  /// Örn. `swords/fire_sword`. Asset yolu değişse bile kimlik sabit kalır.
  final String id;

  /// Kullanıcıya görünen Türkçe ad.
  final String name;

  /// Görselin asset yolu. Model Kuralları #1: `IconData` değil, `String`.
  final String assetPath;

  final ItemCategory category;
  final RewardRarity rarity;

  /// Kuşanmak için gereken en düşük seviye (#10).
  final int requiredLevel;

  /// Mağaza fiyatı — para birimi **coin** (bkz. triaj A4).
  final int cost;

  final ItemBuff buff;

  const Item({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.category,
    required this.rarity,
    required this.requiredLevel,
    required this.cost,
    required this.buff,
  });

  /// Bu item'ı [characterClass] sınıfı kuşanabilir mi.
  bool isUsableBy(String characterClass) =>
      category.characterClasses.contains(characterClass);

  /// Seviye kilidi açık mı (#10).
  bool isUnlockedAt(int level) => level >= requiredLevel;

  @override
  String toString() => 'Item($id)';
}
