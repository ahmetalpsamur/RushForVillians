/// Eşya birleştirmenin **saf** kuralları (demirci, Bölüm 4.3).
///
/// Aynı eşyadan N örnek + coin → **1 örnek, bir üst nadirlikte**.
///
/// `item_leveling.dart` ile aynı desen: `core/utils/` altında saf fonksiyon,
/// ekran ve state buradan okur, ikinci bir hesap yazılmaz.
///
/// ## Üç kural
///
/// 1. **Gereken adet nadirlikle artar** — 3 / 4 / 5 / 6
///    ([GameConstants.itemMergeCounts]). Efsanevilerin üstünde nadirlik yok,
///    birleştirilemiyorlar.
/// 2. **Birleştirilen örnekler aynı eşya ve aynı nadirlikte olmalı.**
///    Seviyeleri farklı olabilir.
/// 3. **Sonuç Sv. 1'e döner** (bkz. GD42). Bu yüzden tüketilecek örnekler
///    otomatik olarak **en düşük seviyelilerden** seçiliyor: oyuncunun
///    yükseltmeye harcadığı coin korunuyor.
library;

import '../../models/item.dart';
import '../../models/owned_item.dart';
import '../../models/reward_rarity.dart';
import '../constants/game_constants.dart';
import 'item_rules.dart';

/// Bir üst nadirlik; efsanevide `null`.
RewardRarity? nextRarity(RewardRarity rarity) {
  final index = RewardRarity.values.indexOf(rarity);
  if (index < 0 || index + 1 >= RewardRarity.values.length) return null;
  return RewardRarity.values[index + 1];
}

/// Bu nadirlikten bir üste geçmek için gereken adet; efsanevide `null`.
int? mergeCountFor(RewardRarity rarity) =>
    GameConstants.itemMergeCounts[rarity];

/// Birleştirme ücreti.
///
/// **Hedef** nadirlikteki fiyatın [GameConstants.itemMergeCostRatio] kadarı,
/// 25'in katına yuvarlı, en az 25. Seviye kilidi değişmediği için (GD40)
/// fiyat da eşyanın kendi kilit seviyesinden hesaplanıyor.
int mergeCostFor(RewardRarity from, int requiredLevel) {
  final target = nextRarity(from);
  if (target == null) return 0;
  final raw = costFor(target, requiredLevel) * GameConstants.itemMergeCostRatio;
  final rounded = (raw / 25).round() * 25;
  return rounded < 25 ? 25 : rounded;
}

/// Birleştirmeyi engelleyen sebep. `null` yerine enum: engel **sessiz
/// kalmamalı** (Model Kuralları #4).
enum MergeBlock {
  /// Engel yok.
  none,

  /// Efsanevinin üstünde nadirlik yok.
  maxRarity,

  /// Yeterli adet yok.
  notEnough,

  /// Para yetmiyor.
  coins,
}

/// Bir birleştirmenin tam tablosu.
class MergeQuote {
  /// Ulaşılacak nadirlik; efsanevide `null`.
  final RewardRarity? target;

  /// Gereken adet; efsanevide `0`.
  final int requiredCount;

  /// Elde bu eşyadan (bu nadirlikte) kaç adet var.
  final int availableCount;

  /// Coin ücreti. Yapılamıyorsa `0`.
  final int cost;

  final MergeBlock block;

  /// Tüketilecek örneklerin kimlikleri — **en düşük seviyeliler önce**,
  /// kuşanılı olanlar en sona.
  final List<int> consumedInstanceIds;

  /// Tüketilecekler arasında kuşanılı bir örnek var mı. Varsa önce
  /// çıkarılacak ve bu kullanıcıya söylenecek.
  final bool consumesEquipped;

  const MergeQuote({
    required this.target,
    required this.requiredCount,
    required this.availableCount,
    required this.cost,
    required this.block,
    required this.consumedInstanceIds,
    required this.consumesEquipped,
  });

  bool get canMerge => block == MergeBlock.none;

  /// Engelin kullanıcıya gösterilecek nedeni; engel yoksa `null`.
  String? reason(RewardRarity rarity) => switch (block) {
    MergeBlock.none => null,
    MergeBlock.maxRarity => '${rarity.label} en üst nadirlik; birleştirilemez.',
    MergeBlock.notEnough =>
      'Birleştirmek için $requiredCount adet gerekiyor, elinde '
          '$availableCount adet var.',
    MergeBlock.coins => '$cost coin gerekiyor.',
  };
}

/// Tüketilecek örnekleri seçer: **en düşük seviyeli ve kuşanılı olmayanlar
/// önce**.
///
/// Sonuç Sv. 1'e döndüğü için (GD42) oyuncunun yükselttiği örneği yakmak
/// gerçek bir kayıp olurdu. Sıralama kararlı: eşitlikte örnek kimliği
/// belirleyici, yani onay ekranında gösterilen liste ile gerçekten tüketilen
/// liste her zaman aynı.
List<OwnedItem> selectMergeInstances(Iterable<OwnedItem> group, int count) {
  final sorted =
      group.toList()..sort((a, b) {
        final aEquipped = a.equipped ? 1 : 0;
        final bEquipped = b.equipped ? 1 : 0;
        if (aEquipped != bEquipped) return aEquipped.compareTo(bEquipped);
        if (a.level != b.level) return a.level.compareTo(b.level);
        return a.instanceId.compareTo(b.instanceId);
      });
  return sorted.take(count).toList();
}

/// Bir eşya grubunun birleştirme tablosu.
///
/// [group] **aynı eşya kimliğine ve aynı nadirliğe** sahip örnekler olmalı;
/// çağıran taraf gruplamayı yapar ([groupForMerging]).
MergeQuote quoteMerge({
  required Item resolved,
  required RewardRarity rarity,
  required Iterable<OwnedItem> group,
  required int coins,
}) {
  final required = mergeCountFor(rarity);
  final available = group.length;

  if (required == null) {
    return MergeQuote(
      target: null,
      requiredCount: 0,
      availableCount: available,
      cost: 0,
      block: MergeBlock.maxRarity,
      consumedInstanceIds: const [],
      consumesEquipped: false,
    );
  }

  final cost = mergeCostFor(rarity, resolved.requiredLevel);
  final selected = selectMergeInstances(group, required);
  final ids = [for (final instance in selected) instance.instanceId];

  final MergeBlock block;
  if (available < required) {
    block = MergeBlock.notEnough;
  } else if (coins < cost) {
    block = MergeBlock.coins;
  } else {
    block = MergeBlock.none;
  }

  return MergeQuote(
    target: nextRarity(rarity),
    requiredCount: required,
    availableCount: available,
    cost: cost,
    block: block,
    // Adet yetmiyorsa tüketilecek bir şey yok; yarım bir liste göstermek
    // yanıltıcı olurdu.
    consumedInstanceIds: available < required ? const [] : ids,
    consumesEquipped:
        available >= required && selected.any((instance) => instance.equipped),
  );
}

/// Envanteri birleştirme grubuna böler: **kimlik + nadirlik**.
///
/// Anahtar `<itemId>|<nadirlik>`; farklı nadirlikteki iki örnek aynı gruba
/// girmiyor, çünkü birleştirme aynı nadirliği şart koşuyor.
Map<String, List<OwnedItem>> groupForMerging(
  Iterable<OwnedItem> items,
  RewardRarity Function(OwnedItem instance) rarityOf,
) {
  final groups = <String, List<OwnedItem>>{};
  for (final instance in items) {
    final key = mergeGroupKey(instance.itemId, rarityOf(instance));
    groups.putIfAbsent(key, () => []).add(instance);
  }
  return groups;
}

/// Bir grubun anahtarı.
String mergeGroupKey(String itemId, RewardRarity rarity) =>
    '$itemId|${rarity.name}';
