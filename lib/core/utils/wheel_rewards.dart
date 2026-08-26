import 'dart:math';

import '../../data/wheel_odds.dart';
import '../../models/game_title.dart';
import '../../models/item.dart';
import '../../models/reward_rarity.dart';
import '../../models/wheel_reward.dart';
import 'item_rules.dart';

/// Günlük çarkın dilim havuzunu ve sonucunu üreten **saf** kurallar (#16).
///
/// Rastgeleliğin tamamı dışarıdan verilen tohumdan gelir: aynı tohum + aynı
/// girdi her zaman aynı çarkı ve aynı sonucu üretir. Gerekçe CLAUDE.md §4.4 —
/// kalıcı oyun sonucunu etkileyen rastgelelik tohumlu olmalı ve tohum durumla
/// birlikte saklanmalı ([UserProfile.wheelSeed]).
///
/// **Oranların tamamı `data/wheel_odds.dart` içinde.** Burada karar yok,
/// yalnızca o tablonun uygulanması var: dilim türü, ekipman nadirliği, XP ve
/// altın miktarı hepsi oradan çekiliyor.
///
/// Seviye kilidi burada **yeniden yazılmaz**: tek kaynak
/// [Item.isUnlockedAt] (#10).

/// Çarkın dilim sayısı. Görselde eşit açılara bölünür.
const int wheelSliceCount = WheelOdds.sliceCount;

/// Bir çarkta en fazla kaç dilimin item olabileceği.
const int maxItemSlices = WheelOdds.maxItemSlices;

/// Bir çarkta en fazla kaç dilimin **ünvan** olabileceği (Bölüm C.4).
const int maxTitleSlices = WheelOdds.maxTitleSlices;

/// Bir çarkta en fazla kaç dilimin **altın** olabileceği.
const int maxCoinSlices = WheelOdds.maxCoinSlices;

/// Ekipman seçilirken kullanılan nadirlik ağırlığı.
///
/// [WheelOdds.maxItemRarity] üstündeki nadirlikler sıfır ağırlık taşır ve
/// havuza hiç girmez.
double wheelRarityWeight(RewardRarity rarity) =>
    WheelOdds.itemRarityWeight(rarity);

/// Tohumu bir sonraki çevirmeye ilerletir.
///
/// Basit bir doğrusal eşlemeli üreteç (LCG) adımı; kriptografik değil,
/// yalnızca tekrarlanabilir olması gerekiyor. 32 bitte tutuluyor ki JSON'a
/// yazılan sayı platformlar arasında aynı kalsın.
int nextWheelSeed(int seed) => (seed * 1103515245 + 12345) & 0x7FFFFFFF;

/// Oyuncuya özel başlangıç tohumu.
///
/// `String.hashCode` **kullanılmaz** (GD8): sürümler arası sabit değil, bir
/// güncelleme sonrası çark sıralaması değişirdi.
int initialWheelSeed(String identity) =>
    stableSpread('wheel-$identity', 0x7FFFFFF) + 1;

/// Ağırlıklı çekiliş: [weights] içindeki indekslerden birini döndürür.
///
/// Toplam ağırlık sıfırsa 0 döner (çağıran taraf zaten boş havuzu ayrıca
/// kontrol ediyor).
int _weightedIndex(List<num> weights, Random random) {
  var total = 0.0;
  for (final weight in weights) {
    if (weight > 0) total += weight;
  }
  if (total <= 0) return 0;
  var cursor = random.nextDouble() * total;
  for (var index = 0; index < weights.length; index++) {
    final weight = weights[index];
    if (weight <= 0) continue;
    cursor -= weight;
    if (cursor <= 0) return index;
  }
  // Kayan nokta artığı: son geçerli indekse düş.
  for (var index = weights.length - 1; index >= 0; index--) {
    if (weights[index] > 0) return index;
  }
  return 0;
}

/// Verilen tohumla çarkın dilimlerini kurar.
///
/// Kompozisyon sırası (hepsi [WheelOdds] tablosundan):
///
/// 1. **Ünvan** — uygun ünvan varsa [WheelOdds.titleSliceChance] ihtimalle
///    bir dilim.
/// 2. **Ekipman** — uygun ekipman varsa **en az bir**, en fazla
///    [maxItemSlices]; adet [WheelOdds.itemSliceCountWeights] ile çekilir.
/// 3. **Altın** — adet [WheelOdds.coinSliceCountWeights] ile çekilir; en az
///    bir dilim XP'ye kalacak şekilde kırpılır.
/// 4. **XP** — kalan bütün dilimler.
///
/// Ekipman adayları için seviye kilidi, sahiplik ve
/// [WheelOdds.maxItemRarity] uygulanır. Sınıf süzgeci **çağıran tarafta**
/// (`ItemCatalog.forCharacterClass`).
///
/// Uygun ödül bulunamazsa dilimler XP ve altına düşer — **boş dilim hiçbir
/// koşulda oluşmaz.**
List<WheelReward> buildWheelSlices({
  required int level,
  required List<Item> candidates,
  required List<String> ownedItemIds,
  required int seed,
  List<GameTitle> titleCandidates = const [],
  List<String> ownedTitleIds = const [],
}) {
  final random = Random(seed);

  // 1) Ünvan dilimi (Bölüm C.4): yalnızca **çark kaynaklı** ve henüz sahip
  // olunmayan ünvanlar. Başka bir yoldan gelen ünvanın çarktan da çıkması,
  // o yolu anlamsız kılardı — bu yüzden süzme çağıran tarafta değil, burada.
  final eligibleTitles = [
    for (final title in titleCandidates)
      if (title.source == TitleSource.wheel &&
          !ownedTitleIds.contains(title.id))
        title,
  ];
  final selectedTitles = <GameTitle>[];
  if (eligibleTitles.isNotEmpty &&
      random.nextDouble() < WheelOdds.titleSliceChance) {
    final remaining = [...eligibleTitles];
    while (selectedTitles.length < maxTitleSlices && remaining.isNotEmpty) {
      final index = _weightedIndex([
        for (final t in remaining) WheelOdds.titleRarityWeight(t.rarity),
      ], random);
      selectedTitles.add(remaining.removeAt(index));
    }
  }

  // 2) Ekipman dilimleri.
  final eligible = [
    for (final item in candidates)
      if (item.isUnlockedAt(level) &&
          !ownedItemIds.contains(item.id) &&
          item.rarity.index <= WheelOdds.maxItemRarity.index)
        item,
  ];

  var freeSlices = wheelSliceCount - selectedTitles.length;
  var itemSliceCount = 0;
  if (eligible.isNotEmpty) {
    // En az bir ekipman dilimi: çark ekipman vaadini her çevirmede tutmalı.
    itemSliceCount =
        _weightedIndex(WheelOdds.itemSliceCountWeights, random) + 1;
    itemSliceCount = min(itemSliceCount, min(maxItemSlices, eligible.length));
    // Altına ve XP'ye en az birer dilim kalsın.
    itemSliceCount = min(itemSliceCount, freeSlices - 2);
    if (itemSliceCount < 1) itemSliceCount = min(1, freeSlices - 1);
  }

  final selectedItems = <Item>[];
  final remainingItems = [...eligible];
  while (selectedItems.length < itemSliceCount && remainingItems.isNotEmpty) {
    final index = _weightedIndex([
      for (final item in remainingItems) wheelRarityWeight(item.rarity),
    ], random);
    selectedItems.add(remainingItems.removeAt(index));
  }
  freeSlices -= selectedItems.length;

  // 3) Altın dilimleri; en az bir dilim XP'ye kalır.
  var coinSliceCount =
      _weightedIndex(WheelOdds.coinSliceCountWeights, random) + 1;
  coinSliceCount = min(coinSliceCount, min(maxCoinSlices, freeSlices - 1));
  if (coinSliceCount < 0) coinSliceCount = 0;

  final coinRewards = [
    for (var i = 0; i < coinSliceCount; i++)
      WheelReward.coins(
        WheelOdds.coinOptions[_weightedIndex(WheelOdds.coinWeights, random)],
      ),
  ];
  freeSlices -= coinRewards.length;

  // 4) Kalan dilimler XP.
  final slices = <WheelReward>[
    for (final item in selectedItems) WheelReward.item(item),
    for (final title in selectedTitles) WheelReward.title(title),
    ...coinRewards,
    for (var i = 0; i < freeSlices; i++)
      WheelReward.xp(
        WheelOdds.xpOptions[_weightedIndex(WheelOdds.xpWeights, random)],
      ),
  ];

  // Ödül dilimleri baştan sona dağılsın; hepsi yan yana durmasın.
  slices.shuffle(random);
  return slices;
}

/// Kazanan dilimin indeksi. Aynı tohum ve aynı dilim sayısı her zaman aynı
/// indeksi verir.
int pickWinningSlice(int sliceCount, int seed) {
  if (sliceCount <= 0) return 0;
  // Dilim kurulumuyla aynı tohumdan farklı bir akış: üreteç bir adım
  // ilerletiliyor ki sonuç dilim sırasına bağlı kalmasın.
  return Random(nextWheelSeed(seed)).nextInt(sliceCount);
}
