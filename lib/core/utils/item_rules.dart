import '../../data/item_archetypes.dart';
import '../../data/item_definitions.dart';
import '../../data/item_effects.dart';
import '../../models/item.dart';
import '../../models/item_effect.dart';
import '../../models/reward_rarity.dart';
import '../constants/game_constants.dart';

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
  // 120 değil 100: 120 coin/gün kazanan oyuncu (6.000 adım) günlük hedefini
  // tutturduğu **ilk akşam** ilk ekipmanını alabilmeli. 120 tabanı en ucuz
  // sıradan item'ı 125'e çıkarıyordu ve oyuncu 5 coin farkla ikinci güne
  // sarkıyordu — mağazanın ilk gün ölü görünmesinin tek sebebi buydu.
  // Ayrıntı: "Ekonomi hizalama ölçümü" bölümü ve `economy_pacing_test.dart`.
  RewardRarity.common => 100,
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

/// Item satılınca geri alınan coin.
///
/// Fiyatın [GameConstants.itemSellRatio] kadarı, 5'in katına yuvarlanır ve
/// **en az 5** olur: satılabilen hiçbir item sıfır etmemeli.
int sellValueFor(int cost) {
  final raw = cost * GameConstants.itemSellRatio;
  final rounded = (raw / 5).round() * 5;
  return rounded < 5 ? 5 : rounded;
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

/// Kuraldan türeyen bir item'ın taşıdığı **toplam etki sayısı**.
///
/// Ekonomi ([ItemArchetypes.economyCount]) + savaş
/// ([ItemArchetypes.combatCount]). Sıradan bir item iki şey yapar (biri
/// bugün canlı, biri savaş motorunu bekliyor), efsanevi altı şey birden.
///
/// Mağaza kartı artık **esnek yükseklikte** (bkz. K9); GD12'nin sabit
/// yükseklik kısıtı kalktığı için satır sayısı üçte durmak zorunda değil.
int buffCountFor(RewardRarity rarity) =>
    ItemArchetypes.economyCount(rarity) + ItemArchetypes.combatCount(rarity);

/// Bütçenin bonuslara dağılımı. Birincil bonus her zaman en büyük payı alır;
/// item'ın "ne işe yaradığı" tek bakışta anlaşılsın.
List<double> _buffShares(int count) => switch (count) {
  1 => const [1.0],
  2 => const [0.6, 0.4],
  _ => const [0.5, 0.3, 0.2],
};

/// Karakter sınıfının **imza bonusu**: o sınıfın itemlerinde en olası
/// ekonomi bonusu.
///
/// **Her itemde bulunmaz** (bkz. GD36). İmza, ekonomi türü çekilişinde
/// [ItemArchetypes.signatureWeight] kadar ağırlık taşır; sınıfın gördüğü
/// katalogun kabaca yarısında birincil bonus olur, kalanında item kendi
/// kimliğinden başka bir tür çeker. Sınıf kimliği tek bir itemde değil,
/// dağılımda okunuyor — aksi hâlde aynı sınıfın bütün sıradan itemleri
/// birebir aynı olurdu.
///
/// 18 oynanabilir sınıf, sekiz tür: imzalar zorunlu olarak paylaşılıyor.
/// Dağılım dengeli tutuldu — her tür en az iki, en fazla üç sınıfın imzası
/// (`item_variety_test.dart` bunu bağlıyor). Boşta kalan tür bırakılmadı:
/// hiç kimsenin imzası olmayan bir bonus türü fiilen ölü olurdu.
ItemBuffType _classSignature(String characterClass) => switch (characterClass) {
  // --- Oynanabilir sınıflar (All_Assets) ---
  // Kılıç ustaları düşmandan ders çıkarır.
  'Swordsman' || 'Elite Orc' || 'Armored Axeman' => ItemBuffType.enemyXp,
  // Zırhlı olanlar kararlıdır: serilerini korurlar.
  'Knight' || 'Armored Skeleton' => ItemBuffType.streakFreezeCap,
  // Yağmacılar yürüyüş ivmesini doğrudan paraya çevirir.
  'Orc' || 'Werewolf' => ItemBuffType.stepCoinMomentum,
  // Gezginler için yol para eder.
  'Archer' || 'Soldier' => ItemBuffType.stepCoin,
  // Öğrenenler adımdan bilgi devşirir.
  'Wizard' || 'Skeleton' => ItemBuffType.stepXp,
  // Kaderle oynayanlar çarktan daha çok alır.
  'Slime' || 'Skeleton Archer' => ItemBuffType.wheelXp,
  // İnanç disiplindir: seri eşiği düşer.
  'Knight Templar' || 'Priest' => ItemBuffType.streakRelief,
  // Döngüsel olanlarda çark hakkı birikir.
  'Werebear' ||
  'Armored Orc' ||
  'Greatsword Skeleton' => ItemBuffType.wheelSpinCap,

  // --- Yalnızca eski kayıtlarda geçen sınıflar ---
  // Kimlikleri korunuyor: eski bir kaydın itemleri güncelleme sonrası
  // sessizce başka bir bonusa kaymamalı.
  'SwordMan' => ItemBuffType.enemyXp,
  'Paladin' => ItemBuffType.streakFreezeCap,
  'Thief' || 'Bat' => ItemBuffType.stepCoinMomentum,
  'Lancer' || 'Orc rider' => ItemBuffType.stepCoin,
  'Magic' => ItemBuffType.stepXp,
  'DarkMagic' || 'Necromancer' => ItemBuffType.wheelXp,
  'Faith' => ItemBuffType.streakRelief,
  'Nature' => ItemBuffType.wheelSpinCap,
  _ => ItemBuffType.stepCoin,
};

/// Kategorinin rolüne göre ikincil bonus eğilimi.
///
/// - yakın dövüş → XP ve düşman XP'si (savaş gücü hızlı seviye demek),
/// - menzil → para, para ivmesi ve çark stoğu,
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
    ItemBuffType.stepCoinMomentum,
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

/// Bir item'ın **ekonomi** bonus türlerini sırayla verir.
///
/// Eskiden bu liste "önce sınıf imzası, sonra kategori eğilimi, sonra
/// kalanlar" biçiminde sabitti ve yalnızca kuyruğu item kimliğine göre
/// dönüyordu. Sonuç: sıradan itemde tek bonus vardı ve o **her zaman** sınıf
/// imzasıydı — aynı sınıfın bütün sıradan kılıçları birebir aynı bonusu
/// veriyordu. Oyuncu iki kılıç arasında gerçek bir tercih yapamıyordu.
///
/// Şimdi türler **ağırlıklı, tekrarsız ve kararlı** bir çekilişten geliyor:
///
/// - sınıf imzası [ItemArchetypes.signatureWeight] ek ağırlık,
/// - kategori rolünün eğilim listesi [ItemArchetypes.roleWeights] ek ağırlık,
/// - her tür [ItemArchetypes.baseWeight] taban ağırlık (hiçbiri elenmiyor).
///
/// Çekiliş tohumu item kimliği + sınıf: aynı item her açılışta aynı bonusları
/// verir (GD8 — `String.hashCode` kullanılmaz), ama iki farklı item aynı
/// olmak zorunda değildir.
List<ItemBuffType> economyTypeOrder(
  ItemCategory category, {
  String? characterClass,
  String id = '',
  int count = 8,
}) {
  final signature =
      characterClass == null
          ? _roleOrder(category.role).first
          : _classSignature(characterClass);

  final weights = <ItemBuffType, int>{
    for (final type in ItemBuffType.values) type: ItemArchetypes.baseWeight,
  };
  weights[signature] = weights[signature]! + ItemArchetypes.signatureWeight;

  final role = _roleOrder(category.role);
  final roleWeights = ItemArchetypes.roleWeights;
  for (var i = 0; i < role.length && i < roleWeights.length; i++) {
    weights[role[i]] = weights[role[i]]! + roleWeights[i];
  }

  return _weightedDraw(weights, '$id|${characterClass ?? ''}', count);
}

/// Ağırlıklı, tekrarsız, kararlı çekiliş.
///
/// Her turda kalan ağırlık toplamı üzerinden [stableSpread] ile bir nokta
/// seçilir ve kümülatif ağırlıklar üzerinde yürünür. Yineleme sırası
/// [ItemBuffType.values] olduğu için sonuç platformdan ve `Map` ekleme
/// sırasından bağımsız.
List<ItemBuffType> _weightedDraw(
  Map<ItemBuffType, int> weights,
  String salt,
  int count,
) {
  final remaining = Map<ItemBuffType, int>.from(weights);
  final drawn = <ItemBuffType>[];

  while (drawn.length < count && remaining.isNotEmpty) {
    var total = 0;
    for (final weight in remaining.values) {
      total += weight;
    }
    var point = stableSpread('$salt|${drawn.length}', total);

    ItemBuffType? chosen;
    for (final type in ItemBuffType.values) {
      final weight = remaining[type];
      if (weight == null) continue;
      if (point < weight) {
        chosen = type;
        break;
      }
      point -= weight;
    }
    // Toplam ağırlık > 0 olduğu sürece buraya düşülmez; yine de sessiz
    // kalmamak için son çare olarak kalanın ilki seçilir.
    chosen ??= remaining.keys.first;

    remaining.remove(chosen);
    drawn.add(chosen);
  }
  return drawn;
}

/// Item'ın arketipi: kimliğinden kararlı biçimde türer, kategori rolüne göre
/// ağırlıklandırılır.
///
/// Rol kısıtı bilinçli — kalkanın "vurucu" olması saçma olurdu — ama hiçbir
/// rol tek arketipe kilitli değil: dört arketip de her rolde çıkabiliyor,
/// sadece farklı sıklıkta (bkz. [ItemArchetypes.wheel]).
ItemArchetype archetypeFor(ItemCategory category, String id) {
  final wheel = ItemArchetypes.wheel[category.role]!;
  return wheel[stableSpread('$id|archetype', wheel.length)];
}

/// Elle tasarlanmış bir item'ın arketipi: **taşıdığı savaş statlarından**
/// okunur, uydurulmaz.
///
/// Etiket item'ın gerçekten yaptığı işi anlatmalı; imzalı bir itemin
/// arketipini kimlikten hesaplasaydık "Vurucu" yazan bir kalkan çıkabilirdi.
/// Hiç savaş statı yoksa kimliğe düşülür.
ItemArchetype archetypeFromEffects(
  List<ItemEffect> effects,
  ItemCategory category,
  String id,
) {
  final scores = <ItemArchetype, double>{};
  for (final effect in effects) {
    if (!effect.stat.isCombat) continue;
    for (final entry in ItemArchetypes.combatStats.entries) {
      final rank = entry.value.indexOf(effect.stat);
      if (rank < 0) continue;
      // Birincil stat üç, ikincil iki, üçüncül bir puan. Eksi değerli
      // etkiler (çift etkili itemlerin bedeli) puanı düşürür.
      final direction = effect.value < 0 ? -1 : 1;
      scores[entry.key] = (scores[entry.key] ?? 0) + (3 - rank) * direction;
    }
  }
  if (scores.isEmpty) return archetypeFor(category, id);

  ItemArchetype? best;
  var bestScore = double.negativeInfinity;
  // Yineleme enum sırasında: eşitlikte sonuç her açılışta aynı olmalı.
  for (final archetype in ItemArchetype.values) {
    final score = scores[archetype];
    if (score != null && score > bestScore) {
      best = archetype;
      bestScore = score;
    }
  }
  return best ?? archetypeFor(category, id);
}

/// Item'ın buff'ı: **ekonomi** bonusları + **savaş** statları.
///
/// [characterClass] verilmezse sınıftan bağımsız temel buff üretilir; sınıfa
/// uyarlama [flavorForClass] üzerinden yapılır.
///
/// Bütçe iki kaynağa bölünür ve arketip dağılımı eğer:
/// - ekonomi bütçesi [ItemArchetypes.economyTilt] ile çarpılır — **hepsi 1.0
///   ya da altında**, yani arketip sistemi ekonomiyi hiçbir koşulda
///   bugünkünün üstüne çıkarmaz (`economy_pacing_test.dart` bugünkü dengeyi
///   ölçüyor),
/// - savaş bütçesi [ItemArchetypes.combatTilt] ile çarpılır. Savaş statları
///   Aşama 4a'ya kadar uygulanmıyor; orada cömert olmak bedava (GD24).
ItemBuff buffFor(
  RewardRarity rarity,
  ItemCategory category, {
  String? characterClass,
  String id = '',
  ItemArchetype? archetype,
}) {
  final resolved = archetype ?? archetypeFor(category, id);
  return ItemBuff([
    ..._economyEffects(rarity, category, resolved, characterClass, id),
    ..._combatEffects(rarity, resolved),
  ]);
}

List<ItemEffect> _economyEffects(
  RewardRarity rarity,
  ItemCategory category,
  ItemArchetype archetype,
  String? characterClass,
  String id,
) {
  final count = ItemArchetypes.economyCount(rarity);
  final shares = _buffShares(count);
  final total = _buffTotal(rarity) * ItemArchetypes.economyTilt[archetype]!;
  final types = economyTypeOrder(
    category,
    characterClass: characterClass,
    id: id,
    count: count,
  );

  return [
    for (var i = 0; i < types.length; i++)
      _ruleEffect(types[i], total * shares[i]),
  ];
}

List<ItemEffect> _combatEffects(RewardRarity rarity, ItemArchetype archetype) {
  final count = ItemArchetypes.combatCount(rarity);
  final shares = ItemArchetypes.combatShares(count);
  final budget =
      ItemArchetypes.combatBudget(rarity) *
      ItemArchetypes.combatTilt[archetype]!;
  final stats = ItemArchetypes.combatStats[archetype]!;

  return [
    for (var i = 0; i < count && i < stats.length; i++)
      _combatEffect(stats[i], budget * shares[i]),
  ];
}

/// Savaş bütçesinin bir dilimini [ItemEffect]'e çevirir.
///
/// Sıfıra düşen bir stat üretilmez: etiketi görünüp etkisi olmayan bonus
/// olmamalı. Oranlar yarım yüzdeye yuvarlanır ki `+%6,5` gibi okunur kalsın.
ItemEffect _combatEffect(ItemStat stat, double budget) {
  final (mode, factor) = ItemArchetypes.combatSpec[stat]!;
  final raw = budget * factor;
  if (mode == ItemEffectMode.flat) {
    final rounded = raw.round();
    return ItemEffect.flat(
      stat: stat,
      value: (rounded < 1 ? 1 : rounded).toDouble(),
    );
  }
  final rounded = (raw * 200).round() / 200;
  return ItemEffect(stat: stat, value: rounded < 0.01 ? 0.01 : rounded);
}

/// Kural türetmesinin tek bir **ekonomi** bonusunu [ItemEffect]'e çevirir.
///
/// Sayı olarak verilen bonuslar (tavan, eşik) oranla ölçeklenip okunur
/// değerlere yuvarlanır ve hiçbiri sıfıra düşmez: etiketi görünüp etkisi
/// olmayan bir bonus olmamalı.
ItemEffect _ruleEffect(ItemBuffType type, double value) {
  switch (type) {
    case ItemBuffType.stepCoin:
    case ItemBuffType.stepXp:
      return ItemEffect(stat: type.stat, value: _cappedRate(value));
    // Eski günlük coin tavanı kanalının yerini alan ikinci para eğilimi.
    // Ayrı katsayı katalog çeşitliliğini korur; ödeme yine sınırsız stepCoin
    // çarpanından geçer ve günlük bir tavana dönüşmez.
    case ItemBuffType.stepCoinMomentum:
      return ItemEffect(
        stat: ItemStat.stepCoin,
        value: _cappedRate(value * 0.75),
      );
    // Çark ve düşman XP'si nadir olaylar: aynı bütçe payı orada daha az
    // hissedilir, bu yüzden iki katına çıkarılıyor — ama tek item tavanını
    // ([GameConstants.maxSingleItemEconomyBonus]) yine de aşamıyor.
    case ItemBuffType.wheelXp:
    case ItemBuffType.enemyXp:
      return ItemEffect(stat: type.stat, value: _cappedRate(value * 2));
    case ItemBuffType.streakFreezeCap:
    case ItemBuffType.wheelSpinCap:
      return ItemEffect.flat(
        stat: type.stat,
        value: _atLeastOne(value * 12).toDouble(),
      );
    case ItemBuffType.streakRelief:
      return ItemEffect.flat(
        stat: type.stat,
        value: _roundTo(value * 3000, 25).toDouble(),
      );
  }
}

/// Oyun dışı oran bonusunu tek item tavanına kırpar.
double _cappedRate(double value) =>
    value > GameConstants.maxSingleItemEconomyBonus
        ? GameConstants.maxSingleItemEconomyBonus
        : value;

int _roundTo(double value, int step) {
  final rounded = (value / step).round() * step;
  return rounded < step ? step : rounded;
}

int _atLeastOne(double value) {
  final rounded = value.round();
  return rounded < 1 ? 1 : rounded;
}

/// Varyant sıfatları.
///
/// Aynı temel görselin varyantları eskiden "Hançer 4" diye numaralanıyordu;
/// sayı bir ad değil, bir dosya indeksidir. Bu havuz her varyanta bir sıfat
/// verir: *Paslı Hançer*, *Uğursuz Hançer*, *Kanlı Hançer*.
///
/// **En kalabalık temel item 28 varyant taşıyor** (`magic/staff_type_1`);
/// havuz 36 girişle bunun üstünde tutuldu ki aynı temel item'ın iki varyantı
/// asla aynı sıfatı almasın (indeksler ardışık ilerliyor).
///
/// Sıfatlar bilerek "durum/geçmiş" bildiriyor, "malzeme" değil: sınıf lakabı
/// (`classEpithet`) zaten malzeme/karakter bildiriyor ve ikisi çelişmesin.
const List<String> variantAdjectives = [
  'Paslı',
  'Yıpranmış',
  'Çentikli',
  'Keskin',
  'Ağır',
  'Hafif',
  'Uğursuz',
  'Kanlı',
  'Solgun',
  'Karanlık',
  'Sessiz',
  'Kadim',
  'Eğri',
  'İnce',
  'Süslü',
  'Sade',
  'Yanık',
  'Buzlu',
  'Çatlak',
  'Onarılmış',
  'Zincirli',
  'Oymalı',
  'Yaldızlı',
  'Tozlu',
  'Fırtınalı',
  'Küllü',
  'Dikenli',
  'Tılsımlı',
  'Uykusuz',
  'Yorgun',
  'Öfkeli',
  'Sabırlı',
  'Kırağılı',
  'Közlü',
  'Alacalı',
  'Yeminli',
];

/// Bir varyantın sıfatı.
///
/// [characterClass] verildiğinde havuzdaki başlangıç noktası kayar: aynı
/// görsel Savaşçıda *Paslı Hançer*, Hırsızda *Uğursuz Hançer* olur. Sıfat
/// yığmak yerine (bkz. GD23) sınıf farkı **sıfatın kendisinden** geliyor;
/// böylece ad hâlâ iki kelime kalıyor ve mağaza kartında kırpılmıyor.
///
/// Dağılım [stableSpread] ile kararlı: aynı item her açılışta aynı adı alır.
String variantAdjective(String baseId, int variant, {String? characterClass}) {
  final salt = characterClass == null ? baseId : '$baseId|$characterClass';
  final offset = stableSpread(salt, variantAdjectives.length);
  final index = (offset + variant - 1) % variantAdjectives.length;
  return variantAdjectives[index];
}

/// Varyantlı bir item'ın tam adı; varyantsızsa ad olduğu gibi döner.
String decorateVariantName(
  String baseName,
  ItemAssetIdentity identity, {
  String? characterClass,
}) {
  final variant = identity.variant;
  if (variant == null) return baseName;
  final adjective = variantAdjective(
    identity.baseId,
    variant,
    characterClass: characterClass,
  );
  return '$adjective $baseName';
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
  'Armored Axeman' => 'Demir',
  'Armored Orc' => 'Zırhlı',
  'Armored Skeleton' => 'Kemik',
  'Bat' => 'Gece',
  'Elite Orc' => 'Kızıl',
  'Greatsword Skeleton' => 'Mezar',
  'Knight' => 'Kraliyet',
  'Knight Templar' => 'Şafak',
  'Lancer' => 'Fırtına',
  'Necromancer' => 'Ruh',
  'Orc' => 'Yaban',
  'Orc rider' => 'Bozkır',
  'Priest' => 'Işık',
  'Skeleton' => 'Kadim',
  'Skeleton Archer' => 'Solgun',
  'Slime' => 'Öz',
  'Soldier' => 'Hudut',
  'Swordsman' => 'Çelik',
  'Werebear' => 'Pençe',
  'Werewolf' => 'Ay',
  'Wizard' => 'Gök',
  _ => '',
};

/// Item'ı bir karakter sınıfına uyarlar: paylaşılan kategorilerde ad lakapla
/// değişir, buff sınıfın imzasına göre yeniden türetilir.
///
/// Kimlik **değişmez** (bkz. [Item.copyWith] yorumu): sahiplik kaydı sınıftan
/// bağımsız durur, oyuncu sınıf değiştirdiğinde envanteri kaybolmaz.
Item flavorForClass(Item item, String characterClass) {
  // İmzalı itemler sınıfa göre değişmez: karakterleri elle yazıldı ve o
  // karakter herkes için aynı olmalı. "Azrailin Tırpanı" her sınıfta
  // Azrailin Tırpanı'dır (bkz. GD22).
  if (item.hasSignature) return item;

  // Arketip sınıfa göre **değişmez**: item'ın karakteri onun kendi kimliğinden
  // geliyor, kuşanan kişiden değil. Değişen şey, o karakterin hangi ekonomi
  // bonusuyla eşleştiği.
  return item.copyWith(
    name: _classFlavoredName(item, characterClass),
    buff: buffFor(
      item.rarity,
      item.category,
      characterClass: characterClass,
      id: item.id,
      archetype: item.archetype,
    ),
  );
}

/// Item'ı **başka bir nadirliğe** taşır (birleştirme, Bölüm 4.3).
///
/// Envanterdeki bir eşya birleştirmeyle bir üst nadirliğe çıkabiliyor; o
/// örnek çözülürken katalog item'ı bu fonksiyondan geçiyor.
///
/// - **Kuraldan türeyen** item: buff yeni nadirlikte baştan türetilir. Arketip
///   korunur — eşyanın karakteri nadirlikle değişmez, yalnızca güçlenir.
/// - **İmzalı** item: elle yazılmış etkileri korunur (GD22 — karakteri
///   silinmemeli) ve nadirlik bütçesi oranında ölçeklenir. Ekonomi oranları
///   yine tek item tavanına kırpılır.
///
/// [Item.requiredLevel] **değişmez**: oyuncunun emek verip birleştirdiği bir
/// eşyanın birden kuşanılamaz hâle gelmesi cezalandırıcı olurdu (GD40).
/// Fiyat yeni nadirlikten hesaplanır, çünkü satış değeri ona bağlı.
Item withRarity(Item base, RewardRarity rarity, {String? characterClass}) {
  if (rarity == base.rarity) return base;
  final cost = costFor(rarity, base.requiredLevel);

  if (!base.hasSignature) {
    return base.copyWith(
      rarity: rarity,
      cost: cost,
      buff: buffFor(
        rarity,
        base.category,
        characterClass: characterClass,
        id: base.id,
        archetype: base.archetype,
      ),
    );
  }

  final factor = rarityBudgetRatio(base.rarity, rarity);
  return base.copyWith(
    rarity: rarity,
    cost: cost,
    buff: ItemBuff([
      for (final effect in base.buff.effects) _scaleSignature(effect, factor),
    ]),
  );
}

/// İki nadirliğin bonus bütçesi oranı. İmzalı itemlerin etkileri bununla
/// ölçekleniyor.
double rarityBudgetRatio(RewardRarity from, RewardRarity to) =>
    _buffTotal(to) / _buffTotal(from);

ItemEffect _scaleSignature(ItemEffect effect, double factor) {
  final scaled = effect.scaled(factor);
  // Ekonomi oranları tek item tavanını aşamaz; savaş statları serbest
  // (savaş motoru Aşama 4a, bkz. GD24).
  if (!scaled.stat.isEconomyRate) return scaled;
  return scaled.clampedTo(GameConstants.maxSingleItemEconomyBonus);
}

/// Item'ın sınıfa uyarlanmış adı.
///
/// İki yol var ve **hiçbir zaman ikisi birden** uygulanmaz (GD23):
/// - varyantlı item → sıfat sınıfa göre kayar (*Paslı* / *Uğursuz* Hançer),
/// - varyantsız item → paylaşılan kategoride sınıf lakabı öne gelir
///   (*Esrarlı* Kutsal Asa).
String _classFlavoredName(Item item, String characterClass) {
  final identity = parseItemAsset(item.assetPath);
  if (identity?.variant != null) {
    final definition = ItemDefinitions.of(identity!.baseId);
    final baseName =
        definition?.$1 ?? fallbackDisplayName(identity.baseId.split('/').last);
    return decorateVariantName(
      baseName,
      identity,
      characterClass: characterClass,
    );
  }

  final epithet = item.category.isShared ? classEpithet(characterClass) : '';
  return epithet.isEmpty ? item.name : '$epithet ${item.name}';
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
  final name = decorateVariantName(baseName, identity);

  final requiredLevel = requiredLevelFor(rarity, identity.id);

  // Elle tasarlanmış (imzalı) itemler kuraldan türeyen bonusun yerine kendi
  // etkilerini alır. Tablo veridir; burada `switch (id)` yok.
  final signature = ItemEffects.of(identity.baseId);

  // Arketip: kuraldan türeyen itemde kimlikten hesaplanır, imzalı itemde
  // taşıdığı savaş statlarından okunur — etiket gerçekten yaptığı işi
  // anlatsın diye (bkz. [archetypeFromEffects]).
  final archetype =
      signature == null
          ? archetypeFor(identity.category, identity.id)
          : archetypeFromEffects(
            signature.effects,
            identity.category,
            identity.id,
          );

  return Item(
    id: identity.id,
    name: name,
    assetPath: assetPath,
    category: identity.category,
    rarity: rarity,
    requiredLevel: requiredLevel,
    cost: costFor(rarity, requiredLevel),
    buff:
        signature == null
            ? buffFor(
              rarity,
              identity.category,
              id: identity.id,
              archetype: archetype,
            )
            : ItemBuff(signature.effects),
    archetype: archetype,
    lore: signature?.lore,
  );
}
