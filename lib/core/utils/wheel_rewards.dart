import 'dart:math';

import '../../data/mock_data.dart';
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
/// Seviye kilidi burada **yeniden yazılmaz**: tek kaynak
/// [Item.isUnlockedAt] (#10).

/// Çarkın dilim sayısı. Görselde eşit açılara bölünür.
const int wheelSliceCount = 8;

/// Bir çarkta en fazla kaç dilimin item olabileceği.
///
/// Kalanı XP. Item dilimleri azınlıkta: çark günde bir kez dönüyor ve her
/// gün ekipman dağıtmak hem mağazayı hem seviye kilidini anlamsız kılar.
const int maxItemSlices = 4;

/// Bir çarkta en fazla kaç dilimin **ünvan** olabileceği (Bölüm C.4).
///
/// Bir: ünvan çarkın dört kaynağından yalnızca biri ve en nadir olanı.
/// İkiden fazlası, başarım ve kilometre taşı yollarını anlamsızlaştırırdı.
const int maxTitleSlices = 1;

/// Item seçilirken kullanılan nadirlik ağırlığı. Her nadirlik çarktan
/// çıkabilir; yüksek nadirlikler giderek daha düşük ağırlık alır.
double wheelRarityWeight(RewardRarity rarity) => switch (rarity) {
  RewardRarity.common => 60,
  RewardRarity.uncommon => 27,
  RewardRarity.rare => 10,
  RewardRarity.epic => 2.5,
  RewardRarity.legendary => 0.5,
};

/// Tohumu bir sonraki çevirmeye ilerletir.
///
/// Basit bir doğrusal eşlemeli üreteç (LCG) adımı; kriptografik değil,
/// yalnızca tekrarlanabilir olması gerekiyor. 32 bitte tutuluyor ki JSON'a
/// yazılan sayı platformlar arasında aynı kalsın.
int nextWheelSeed(int seed) => (seed * 1103515245 + 12345) & 0x7FFFFFFF;

/// Oyuncuya özel başlangıç tohumu.
///
/// `String.hashCode` **kullanılmaz** (bkz. GD8): sürümler arası sabit değil.
/// Aynı isim + sınıf her zaman aynı başlangıcı verir, farklı oyuncular farklı
/// çark görür. Sıfır dönmez; sıfır "henüz kurulmadı" anlamında.
int initialWheelSeed(String salt) => stableSpread(salt, 0x7FFFFFF0) + 1;

/// Çarkın dilimlerini kurar.
///
/// Item dilimleri [candidates] içinden seçilir; liste **oyuncunun sınıfına
/// göre süzülmüş** gelmeli ([ItemCatalog.forCharacterClass]). Buradaki tek
/// süzme seviye kilidi ve sahiplik:
/// - [Item.isUnlockedAt] — kilidin tek kaynağı, ikinci bir kontrol yok (#10),
/// - zaten sahip olunanlar elenir; çarktan sahip olduğun şeyin çıkması ödül
///   değil, hayal kırıklığı,
/// - nadirlik seçim ihtimalini [wheelRarityWeight] üzerinden etkiler.
///
/// Uygun item yoksa (seviye düşük, hepsi alınmış, katalog boş) dilimlerin
/// tamamı XP olur — **boş dilim hiçbir koşulda oluşmaz.**
List<WheelReward> buildWheelSlices({
  required int level,
  required List<Item> candidates,
  required List<String> ownedItemIds,
  required int seed,
  List<GameTitle> titleCandidates = const [],
  List<String> ownedTitleIds = const [],
}) {
  final random = Random(seed);

  // Ünvan dilimi (Bölüm C.4): yalnızca **çark kaynaklı** ve henüz sahip
  // olunmayan ünvanlar. Başka bir yoldan gelen ünvanın çarktan da çıkması,
  // o yolu anlamsız kılardı — bu yüzden süzme çağıran tarafta değil, burada.
  final eligibleTitles = [
    for (final title in titleCandidates)
      if (title.source == TitleSource.wheel && !ownedTitleIds.contains(title.id))
        title,
  ];
  final selectedTitles = <GameTitle>[];
  if (eligibleTitles.isNotEmpty) {
    final remainingTitles = [...eligibleTitles];
    while (selectedTitles.length < maxTitleSlices && remainingTitles.isNotEmpty) {
      final totalWeight = remainingTitles.fold<double>(
        0,
        (sum, title) => sum + wheelRarityWeight(title.rarity),
      );
      var cursor = random.nextDouble() * totalWeight;
      var selectedIndex = remainingTitles.length - 1;
      for (var index = 0; index < remainingTitles.length; index++) {
        cursor -= wheelRarityWeight(remainingTitles[index].rarity);
        if (cursor <= 0) {
          selectedIndex = index;
          break;
        }
      }
      selectedTitles.add(remainingTitles.removeAt(selectedIndex));
    }
  }

  final eligible =
      candidates
          .where(
            (item) =>
                item.isUnlockedAt(level) && !ownedItemIds.contains(item.id),
          )
          .toList();

  // Ünvan dilimi item dilimlerinden pay alır: toplam dilim sayısı sabit.
  final itemSliceCount = min(
    maxItemSlices,
    min(eligible.length, wheelSliceCount - selectedTitles.length - 1),
  );
  final selectedItems = <Item>[];
  final remaining = [...eligible];
  while (selectedItems.length < itemSliceCount && remaining.isNotEmpty) {
    final totalWeight = remaining.fold<double>(
      0,
      (sum, item) => sum + wheelRarityWeight(item.rarity),
    );
    var cursor = random.nextDouble() * totalWeight;
    var selectedIndex = remaining.length - 1;
    for (var index = 0; index < remaining.length; index++) {
      cursor -= wheelRarityWeight(remaining[index].rarity);
      if (cursor <= 0) {
        selectedIndex = index;
        break;
      }
    }
    selectedItems.add(remaining.removeAt(selectedIndex));
  }

  final xpOptions = MockData.wheelXpOptions;

  final rewardSliceCount = itemSliceCount + selectedTitles.length;
  final slices = <WheelReward>[
    for (final item in selectedItems) WheelReward.item(item),
    for (final title in selectedTitles) WheelReward.title(title),
    // Kalan dilimler XP: **boş dilim hiçbir koşulda oluşmaz.**
    for (var i = rewardSliceCount; i < wheelSliceCount; i++)
      WheelReward.xp(xpOptions[random.nextInt(xpOptions.length)]),
  ];

  // Item dilimleri baştan sona dağılsın; hepsi yan yana durmasın.
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
