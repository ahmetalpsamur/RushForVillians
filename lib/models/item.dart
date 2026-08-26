import 'item_effect.dart';
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

/// Item'ın **karakteri**: aynı güç bütçesini farklı dağıtan eğilim.
///
/// Arketip, item'ın **kendi kimliğinden** (`Item.id`) kararlı biçimde türer
/// ve kategori rolüne göre ağırlıklandırılır (bkz. [ItemArchetypes.wheel]).
/// Aynı sınıfın, aynı nadirlikteki iki kılıcı bu sayede birbirinden ayrışıyor:
/// biri vurucu, öbürü düellocu olabiliyor.
///
/// Model Kuralları #1: enum diske **yazılmaz** — [Item] kalıcı değil, her
/// açılışta katalogdan yeniden çözülüyor.
enum ItemArchetype { striker, guardian, duelist, swift }

extension ItemArchetypeX on ItemArchetype {
  /// Kullanıcıya görünen Türkçe ad.
  String get label => switch (this) {
    ItemArchetype.striker => 'Vurucu',
    ItemArchetype.guardian => 'Muhafız',
    ItemArchetype.duelist => 'Düellocu',
    ItemArchetype.swift => 'Çevik',
  };

  /// Kartta ad(ın altında) tek satırlık açıklama.
  String get description => switch (this) {
    ItemArchetype.striker => 'ham vuruş gücüne yatırım yapar',
    ItemArchetype.guardian => 'dayanıklılığa yatırım yapar',
    ItemArchetype.duelist => 'kritik vuruşa yatırım yapar',
    ItemArchetype.swift => 'kaçınma ve tempoya yatırım yapar',
  };
}

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
    ItemCategory.swords => const [
      'SwordMan',
      'Thief',
      'Armored Axeman',
      'Elite Orc',
      'Armored Skeleton',
      'Greatsword Skeleton',
      'Knight',
      'Knight Templar',
      'Lancer',
      'Skeleton',
      'Soldier',
      'Swordsman',
      'Werewolf',
    ],
    ItemCategory.axesHalberds => const [
      'SwordMan',
      'Paladin',
      'Armored Axeman',
      'Armored Orc',
      'Elite Orc',
      'Orc',
      'Orc rider',
      'Swordsman',
      'Werebear',
    ],
    ItemCategory.macesHammers => const [
      'Paladin',
      'Faith',
      'SwordMan',
      'Armored Orc',
      'Elite Orc',
      'Knight Templar',
      'Orc',
      'Priest',
      'Werebear',
    ],
    // Cirit: okçunun da menzilli silahı.
    ItemCategory.spears => const [
      'Paladin',
      'Nature',
      'Archer',
      'Armored Skeleton',
      'Knight',
      'Lancer',
      'Orc',
      'Orc rider',
      'Skeleton',
      'Soldier',
    ],
    // Tırpan hasat aletidir; Nature'a doğal olarak düşer. Mezar Okçusu da
    // ölümün aletini taşır — ve o sınıfın kategori havuzu onsuz 150 item
    // alt sınırının altında kalıyordu (bkz. GD37).
    ItemCategory.scythes => const [
      'DarkMagic',
      'Thief',
      'Nature',
      'Bat',
      'Greatsword Skeleton',
      'Necromancer',
      'Skeleton Archer',
      'Slime',
      'Werewolf',
    ],
    ItemCategory.magic => const [
      'Magic',
      'DarkMagic',
      'Faith',
      'Nature',
      'Bat',
      'Necromancer',
      'Priest',
      'Slime',
      'Wizard',
    ],
    ItemCategory.shields => const [
      'SwordMan',
      'Paladin',
      'Faith',
      'Armored Axeman',
      'Armored Orc',
      'Armored Skeleton',
      'Greatsword Skeleton',
      'Knight',
      'Knight Templar',
      'Lancer',
      'Priest',
      'Skeleton',
      'Soldier',
      'Swordsman',
      // Ayı Ruhlu ağır bir savaşçı; kalkan ona doğal düşüyor ve sınıfın
      // havuzu onsuz 105 item'da kalıyordu (bkz. GD37).
      'Werebear',
    ],
    // Arbalet hırsızın da işine yarar.
    ItemCategory.arch => const [
      'Archer',
      'Nature',
      'Thief',
      'Orc rider',
      'Skeleton Archer',
    ],
    // Fırlatma silahları: büyücülerin de uzaktan seçeneği.
    ItemCategory.rangedOther => const [
      'Archer',
      'Thief',
      'Magic',
      'DarkMagic',
      'Bat',
      'Skeleton Archer',
      'Soldier',
      'Wizard',
    ],
    ItemCategory.specialOther => const [
      'Thief',
      'Magic',
      'DarkMagic',
      'Bat',
      'Necromancer',
      'Skeleton Archer',
      'Slime',
      'Werebear',
      'Werewolf',
      'Wizard',
    ],
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

/// Bir item'ın verebileceği bonus türü — **kural türetmesinin** alfabesi.
///
/// Sekiz tür var ve her karakter sınıfının bir **imzası** vardır
/// (`item_rules.dart:_classSignature`). İmza, o sınıfın itemlerinde en olası
/// bonus türüdür — **her itemde bulunmaz**: hangi türlerin çıkacağı item'ın
/// kendi kimliğinden ağırlıklı bir çekilişle belirlenir
/// (`item_rules.dart:economyTypeOrder`). Aynı görsel bu sayede hem sınıfa
/// göre hem item'dan item'a farklılaşıyor.
///
/// 18 oynanabilir sınıf ve sekiz tür var; imzalar zorunlu olarak paylaşılıyor
/// (bkz. GD36). Sınıf kimliği tek bir itemde değil, sınıfın gördüğü katalogun
/// tamamındaki dağılımda okunuyor.
///
/// Bu enum yalnızca sıradan/az bulunur/nadir itemlerin kuraldan türeyen
/// bonuslarını tanımlar. Elle tasarlanmış itemler ([ItemEffects]) doğrudan
/// [ItemEffect] listesi taşır ve buradaki türlerle sınırlı değildir.
enum ItemBuffType {
  stepCoin,
  stepCoinMomentum,
  stepXp,
  wheelXp,
  enemyXp,
  streakFreezeCap,
  wheelSpinCap,
  streakRelief,
}

extension ItemBuffTypeX on ItemBuffType {
  /// Kural türetmesindeki türün karşılık geldiği stat.
  ItemStat get stat => switch (this) {
    ItemBuffType.stepCoin => ItemStat.stepCoin,
    ItemBuffType.stepCoinMomentum => ItemStat.stepCoin,
    ItemBuffType.stepXp => ItemStat.stepXp,
    ItemBuffType.wheelXp => ItemStat.wheelXp,
    ItemBuffType.enemyXp => ItemStat.enemyXp,
    ItemBuffType.streakFreezeCap => ItemStat.streakFreezeCap,
    ItemBuffType.wheelSpinCap => ItemStat.wheelSpinCap,
    ItemBuffType.streakRelief => ItemStat.streakRelief,
  };
}

/// Bir item'ın sağladığı etkilerin tamamı.
///
/// **Tek alanı [effects]**: sayısal getter'ların hepsi ondan türetilir. Bu
/// yapı, kuraldan türeyen basit bonuslarla ([buffFor]) elle tasarlanmış
/// koşullu/tetiklenen etkileri ([ItemEffects]) aynı kapta taşımayı mümkün
/// kılıyor — mağaza, envanter ve toplama mantığı ikisini ayırt etmek zorunda
/// kalmıyor.
///
/// **Türetilmiş getter'lar yalnızca [ItemEffect.isPassive] efektleri sayar.**
/// Koşullu bir etki ("can %30 altındayken +%40 saldırı") kuşanıldığı anda
/// pasif bir çarpana dönüşmemeli; kullanıcıya gösterilir, ekonomiye girmez.
///
/// Model Kuralları #1: burada hiçbir Flutter tipi yok — bkz. [Item] yorumu.
class ItemBuff {
  final List<ItemEffect> effects;

  const ItemBuff(this.effects);

  static const none = ItemBuff([]);

  /// Sayısal bonuslardan buff kurar.
  ///
  /// Kural türetmesinin ve testlerin kısayolu; sıfır olan alanlar efekt
  /// üretmez. Sıra sabittir ki aynı item her açılışta aynı görünsün.
  factory ItemBuff.stats({
    double stepCoinBonus = 0,
    double stepXpBonus = 0,
    double wheelXpBonus = 0,
    double enemyXpBonus = 0,
    int dailyCoinCapBonus = 0,
    int streakFreezeCapBonus = 0,
    int wheelSpinCapBonus = 0,
    int streakStepRelief = 0,
  }) {
    return ItemBuff([
      if (stepCoinBonus != 0)
        ItemEffect(stat: ItemStat.stepCoin, value: stepCoinBonus),
      if (stepXpBonus != 0)
        ItemEffect(stat: ItemStat.stepXp, value: stepXpBonus),
      if (wheelXpBonus != 0)
        ItemEffect(stat: ItemStat.wheelXp, value: wheelXpBonus),
      if (enemyXpBonus != 0)
        ItemEffect(stat: ItemStat.enemyXp, value: enemyXpBonus),
      if (dailyCoinCapBonus != 0)
        ItemEffect.flat(
          stat: ItemStat.dailyCoinCap,
          value: dailyCoinCapBonus.toDouble(),
        ),
      if (streakFreezeCapBonus != 0)
        ItemEffect.flat(
          stat: ItemStat.streakFreezeCap,
          value: streakFreezeCapBonus.toDouble(),
        ),
      if (wheelSpinCapBonus != 0)
        ItemEffect.flat(
          stat: ItemStat.wheelSpinCap,
          value: wheelSpinCapBonus.toDouble(),
        ),
      if (streakStepRelief != 0)
        ItemEffect.flat(
          stat: ItemStat.streakRelief,
          value: streakStepRelief.toDouble(),
        ),
    ]);
  }

  bool get isEmpty => effects.isEmpty;

  /// Kaç ayrı etki taşıdığı. Nadirlikle birlikte büyür.
  int get count => effects.length;

  /// Kullanıcıya gösterilecek satırlar; her etki için bir satır.
  List<String> get labels => [for (final effect in effects) effect.label];

  /// Tek satırlık özet; etki yoksa `null`.
  String? get label => labels.isEmpty ? null : labels.join(' · ');

  /// Savaş motoru gelene kadar etkisiz olan etkiler (Aşama 4a).
  List<ItemEffect> get combatEffects => [
    for (final e in effects)
      if (e.stat.isCombat) e,
  ];

  /// Bugün gerçekten çalışan etkiler.
  List<ItemEffect> get liveEffects => [
    for (final e in effects)
      if (!e.stat.isCombat) e,
  ];

  /// Koşullu ya da tetiklenen etkiler: gösterilir, çarpana girmez.
  List<ItemEffect> get conditionalEffects => [
    for (final e in effects)
      if (!e.isPassive) e,
  ];

  double _rate(ItemStat stat) {
    var total = 0.0;
    for (final effect in effects) {
      if (effect.stat == stat && effect.isPassive) total += effect.value;
    }
    return total;
  }

  int _flat(ItemStat stat) {
    var total = 0.0;
    for (final effect in effects) {
      if (effect.stat == stat && effect.isPassive) total += effect.value;
    }
    return total.round();
  }

  /// Adımdan kazanılan paraya eklenen oran (0.05 = +%5).
  /// Uygulama noktası: `calculateStepCoins` çarpanı.
  double get stepCoinBonus => _rate(ItemStat.stepCoin);

  /// Adımdan kazanılan XP'ye eklenen oran.
  /// Uygulama noktası: `calculateStepXp` çarpanı.
  double get stepXpBonus => _rate(ItemStat.stepXp);

  /// Çarktan kazanılan XP'ye eklenen oran.
  double get wheelXpBonus => _rate(ItemStat.wheelXp);

  /// Düşman yenince kazanılan XP'ye eklenen oran.
  double get enemyXpBonus => _rate(ItemStat.enemyXp);

  /// Eski item kayıtları için günlük tavan bonusu. Aktif katalog üretmez;
  /// kuşanıldığında adım-parası oranına dönüştürülür.
  int get dailyCoinCapBonus => _flat(ItemStat.dailyCoinCap);

  /// Seri dondurma stoğuna eklenen hak.
  int get streakFreezeCapBonus => _flat(ItemStat.streakFreezeCap);

  /// Ekstra çark hakkı stoğuna eklenen hak.
  int get wheelSpinCapBonus => _flat(ItemStat.wheelSpinCap);

  /// Seri eşiğinden düşülen adım.
  int get streakStepRelief => _flat(ItemStat.streakRelief);

  @override
  String toString() => 'ItemBuff(${labels.join(', ')})';
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

  /// Item'ın karakteri: aynı bütçeyi hangi yöne dağıttığı.
  ///
  /// Kuraldan türeyen itemlerde kimlikten hesaplanır
  /// (`item_rules.dart:archetypeFor`); elle tasarlanmış itemlerde taşıdıkları
  /// savaş statlarından okunur, yani etiketi gerçekten yaptığı işi anlatır.
  final ItemArchetype archetype;

  /// Elle tasarlanmış itemlerin kısa kural cümlesi; kuraldan türeyenlerde
  /// `null`.
  ///
  /// Aynı zamanda "bu item **imzalı** mı" sorusunun cevabı ([hasSignature]):
  /// imzalı itemler sınıfa göre ad ve buff değiştirmez, kendi kimlikleriyle
  /// dururlar (bkz. GD22).
  final String? lore;

  const Item({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.category,
    required this.rarity,
    required this.requiredLevel,
    required this.cost,
    required this.buff,
    required this.archetype,
    this.lore,
  });

  /// Elle tasarlanmış (imzalı) bir item mi.
  bool get hasSignature => lore != null;

  /// Aynı kimlikle, yalnızca [name] ve [buff] değiştirilmiş bir kopya.
  ///
  /// Sınıfa uyarlama bunun üzerinden yapılır (`item_rules.dart:flavorForClass`).
  /// **[id] hiçbir zaman değişmez:** kalıcı olan tek şey o
  /// ([UserProfile.ownedItemIds]). Kimliğe sınıf gömseydik, oyuncu karakterini
  /// düzenleyip sınıf değiştirdiğinde envanteri sessizce boşalırdı.
  /// [rarity] ve [cost] yalnızca **birleştirilmiş bir örnek** çözülürken
  /// değişir (`item_leveling.dart:withRarity`): envanterdeki bir eşya
  /// birleştirmeyle bir üst nadirliğe çıkabiliyor. [requiredLevel] bilerek
  /// değişmez — bkz. GD40.
  Item copyWith({
    String? name,
    ItemBuff? buff,
    ItemArchetype? archetype,
    RewardRarity? rarity,
    int? cost,
  }) => Item(
    id: id,
    name: name ?? this.name,
    assetPath: assetPath,
    category: category,
    rarity: rarity ?? this.rarity,
    requiredLevel: requiredLevel,
    cost: cost ?? this.cost,
    buff: buff ?? this.buff,
    archetype: archetype ?? this.archetype,
    lore: lore,
  );

  /// Bu item'ı [characterClass] sınıfı kuşanabilir mi.
  bool isUsableBy(String characterClass) =>
      category.characterClasses.contains(characterClass);

  /// Seviye kilidi açık mı (#10).
  bool isUnlockedAt(int level) => level >= requiredLevel;

  @override
  String toString() => 'Item($id)';
}
