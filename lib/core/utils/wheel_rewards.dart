import 'dart:math';

import '../../data/mock_data.dart';
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
const int maxItemSlices = 3;

/// Çarkta çıkabilecek en yüksek nadirlik.
///
/// Epik ve efsanevi bilerek dışarıda: onlar mağazanın uzun vadeli hedefi
/// (efsanevi ~iki aylık birikim). Çarktan düşmesi ekonomiyi çökertirdi.
const RewardRarity maxWheelRarity = RewardRarity.rare;

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
/// - [maxWheelRarity] üstü elenir.
///
/// Uygun item yoksa (seviye düşük, hepsi alınmış, katalog boş) dilimlerin
/// tamamı XP olur — **boş dilim hiçbir koşulda oluşmaz.**
List<WheelReward> buildWheelSlices({
  required int level,
  required List<Item> candidates,
  required List<String> ownedItemIds,
  required int seed,
}) {
  final random = Random(seed);

  final eligible =
      candidates
          .where(
            (item) =>
                item.isUnlockedAt(level) &&
                !ownedItemIds.contains(item.id) &&
                item.rarity.index <= maxWheelRarity.index,
          )
          .toList();

  // Kararlı sıra: katalog sırası zaten kararlı, karıştırma tohumdan geliyor.
  eligible.shuffle(random);

  final itemSliceCount = min(maxItemSlices, eligible.length);
  final xpOptions = MockData.wheelXpOptions;

  final slices = <WheelReward>[
    for (var i = 0; i < itemSliceCount; i++) WheelReward.item(eligible[i]),
    for (var i = itemSliceCount; i < wheelSliceCount; i++)
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
