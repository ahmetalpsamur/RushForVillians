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
  /// **Her sınıfa en az üç kategori** düşer. Önceki dağılımda Magic tek
  /// kategori (yalnızca Büyü) görüyordu; süzgeç çubuğu "Tümü + Büyü"ye
  /// düşüyor ve fiilen işlevsiz kalıyordu. Archer ve DarkMagic de ikide
  /// kalmıştı. Kapsam `item_catalog_test.dart` içinde doğrulanıyor.
  List<String> get characterClasses => switch (this) {
    ItemCategory.swords => const ['SwordMan', 'Thief'],
    ItemCategory.axesHalberds => const ['SwordMan', 'Paladin'],
    ItemCategory.macesHammers => const ['Paladin', 'Faith', 'SwordMan'],
    // Cirit: okçunun da menzilli silahı.
    ItemCategory.spears => const ['Paladin', 'Nature', 'Archer'],
    // Tırpan hasat aletidir; Nature'a doğal olarak düşer.
    ItemCategory.scythes => const ['DarkMagic', 'Thief', 'Nature'],
    ItemCategory.magic => const ['Magic', 'DarkMagic', 'Faith', 'Nature'],
    ItemCategory.shields => const ['SwordMan', 'Paladin', 'Faith'],
    // Arbalet hırsızın da işine yarar.
    ItemCategory.arch => const ['Archer', 'Nature', 'Thief'],
    // Fırlatma silahları: büyücülerin de uzaktan seçeneği.
    ItemCategory.rangedOther => const ['Archer', 'Thief', 'Magic', 'DarkMagic'],
    ItemCategory.specialOther => const ['Thief', 'Magic', 'DarkMagic'],
  };

  /// Bu kategori birden fazla sınıf tarafından paylaşılıyor mu.
  ///
  /// Paylaşılan itemler sınıfa göre farklı ad ve farklı buff alır
  /// ([Item.withClassFlavor]); tek sınıfa özel olanlar temel adıyla kalır.
  bool get isShared => characterClasses.length > 1;

  static ItemCategory? fromFolder(String folder) {
    for (final category in ItemCategory.values) {
      if (category.folder == folder) return category;
    }
    return null;
  }
}

/// Bir item'ın verebileceği bonus türü.
///
/// Sekiz tür var ve her karakter sınıfının **imzası** ayrı bir tür
/// (`item_rules.dart:_classSignature`); aynı görsel bu sayede sınıfa göre
/// farklı bir item oluyor.
enum ItemBuffType {
  stepCoin,
  stepXp,
  wheelXp,
  enemyXp,
  dailyCoinCap,
  streakFreezeCap,
  wheelSpinCap,
  streakRelief,
}

/// Bir item'ın sağladığı kalıcı bonuslar.
///
/// Nadirlik yükseldikçe **hem bonus miktarı hem bonus sayısı** artar
/// (sıradan 1, az bulunur/nadir 2, epik/efsanevi 3) ve hangi bonusların
/// düştüğü oyuncunun **karakter sınıfına** göre değişir: aynı görsel, Büyücüde
/// başka bir item, Kara Büyücüde başka.
///
/// Buradaki her alan **bugün var olan** bir uygulama noktasına karşılık gelir.
/// Savaş istatistiği (can, saldırı, savunma) bilerek yok: o statlar Aşama 4a'da
/// tanımlanacak ve şimdi uydurmak iki kez yazmak olurdu (bkz. GD9).
class ItemBuff {
  /// Adımdan kazanılan paraya eklenen oran (0.05 = +%5).
  /// Uygulama noktası: `calculateStepCoins` çarpanı.
  final double stepCoinBonus;

  /// Adımdan kazanılan XP'ye eklenen oran.
  /// Uygulama noktası: `calculateStepXp` çarpanı.
  final double stepXpBonus;

  /// Çarktan kazanılan XP'ye eklenen oran.
  /// Uygulama noktası: `RootShell._spinWheel` → `_awardXp`.
  final double wheelXpBonus;

  /// Düşman yenince kazanılan XP'ye eklenen oran.
  /// Uygulama noktası: `RootShell._onStepsReported` düşman yenilme dalı.
  final double enemyXpBonus;

  /// Günlük adım-para tavanına eklenen coin
  /// ([GameConstants.maxDailyStepCoins] üstüne).
  final int dailyCoinCapBonus;

  /// Seri dondurma stoğuna eklenen hak
  /// ([GameConstants.maxStreakFreezes] üstüne).
  final int streakFreezeCapBonus;

  /// Ekstra çark hakkı stoğuna eklenen hak
  /// ([GameConstants.maxExtraWheelSpins] üstüne).
  final int wheelSpinCapBonus;

  /// Seri eşiğinden ([GameConstants.streakStepThreshold]) düşülen adım.
  final int streakStepRelief;

  const ItemBuff({
    this.stepCoinBonus = 0,
    this.stepXpBonus = 0,
    this.wheelXpBonus = 0,
    this.enemyXpBonus = 0,
    this.dailyCoinCapBonus = 0,
    this.streakFreezeCapBonus = 0,
    this.wheelSpinCapBonus = 0,
    this.streakStepRelief = 0,
  });

  static const none = ItemBuff();

  bool get isEmpty => labels.isEmpty;

  /// Kaç ayrı bonus taşıdığı. Nadirlikle birlikte büyür.
  int get count => labels.length;

  /// Kullanıcıya gösterilecek satırlar; her bonus için bir satır.
  ///
  /// Sıra sabit tutuluyor ki aynı item her açılışta aynı görünsün.
  List<String> get labels => [
    if (stepCoinBonus > 0) 'adım parası +%${_percent(stepCoinBonus)}',
    if (stepXpBonus > 0) 'adım XP +%${_percent(stepXpBonus)}',
    if (wheelXpBonus > 0) 'çark XP +%${_percent(wheelXpBonus)}',
    if (enemyXpBonus > 0) 'düşman XP +%${_percent(enemyXpBonus)}',
    if (dailyCoinCapBonus > 0) 'günlük coin sınırı +$dailyCoinCapBonus',
    if (streakFreezeCapBonus > 0) 'dondurma stoğu +$streakFreezeCapBonus',
    if (wheelSpinCapBonus > 0) 'çark hakkı stoğu +$wheelSpinCapBonus',
    if (streakStepRelief > 0) 'seri eşiği -$streakStepRelief adım',
  ];

  /// Tek satırlık özet; bonus yoksa `null`.
  String? get label => labels.isEmpty ? null : labels.join(' · ');

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

  /// Aynı kimlikle, yalnızca [name] ve [buff] değiştirilmiş bir kopya.
  ///
  /// Sınıfa uyarlama bunun üzerinden yapılır (`item_rules.dart:flavorForClass`).
  /// **[id] hiçbir zaman değişmez:** kalıcı olan tek şey o
  /// ([UserProfile.ownedItemIds]). Kimliğe sınıf gömseydik, oyuncu karakterini
  /// düzenleyip sınıf değiştirdiğinde envanteri sessizce boşalırdı.
  Item copyWith({String? name, ItemBuff? buff}) => Item(
    id: id,
    name: name ?? this.name,
    assetPath: assetPath,
    category: category,
    rarity: rarity,
    requiredLevel: requiredLevel,
    cost: cost,
    buff: buff ?? this.buff,
  );

  /// Bu item'ı [characterClass] sınıfı kuşanabilir mi.
  bool isUsableBy(String characterClass) =>
      category.characterClasses.contains(characterClass);

  /// Seviye kilidi açık mı (#10).
  bool isUnlockedAt(int level) => level >= requiredLevel;

  @override
  String toString() => 'Item($id)';
}
