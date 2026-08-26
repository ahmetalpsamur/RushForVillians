/// Eşya yükseltmenin **saf** kuralları (demirci, Bölüm 4).
///
/// Projedeki desen: `core/utils/` altında saf fonksiyon
/// ([calculateStepCoins], [limitStepBatch], [archiveStepDay],
/// [EquippedBuffs]). Ekran ve state buradan okur; ikinci bir hesap yazılmaz.
///
/// ## Eşyalar otomatik seviye atlamaz
///
/// Her örnek 1. seviyede başlar. Oyuncu **coin** harcayarak yükseltir ve iki
/// tavanın **ikisine birden** takılır:
///
/// 1. **Nadirlik tavanı** ([GameConstants.itemLevelCapByRarity]) — sıradan
///    bir eşya sonuna kadar yükseltilse bile efsanevi bir eşyaya yetişemez;
///    nadirlik kalıcı bir üstünlük.
/// 2. **Oyuncu seviyesi** — eşya seviyesi oyuncunun seviyesini geçemez.
///    1. seviyedeki oyuncu eşyasını tavana çıkaramaz.
///
/// ## ⚠️ Yükseltme yalnızca SAVAŞ statlarını büyütür
///
/// Ekonomi bonusları (adım→para, adım→XP, çark XP, düşman XP, stoklar, seri
/// eşiği) **sabit kalır**. Ekonomi dikkatle dengelendi
/// (`economy_pacing_test.dart` ve ekonomi sınırları); çarpanlar seviyeyle
/// büyüseydi adım kazancı katlanır ve denge çökerdi. Bu kural
/// [scaleForLevel] içinde kodla zorlanıyor ve testle bağlı.
library;

import '../../models/item.dart';
import '../../models/item_effect.dart';
import '../../models/owned_item.dart';
import '../../models/reward_rarity.dart';
import '../constants/game_constants.dart';
import 'item_rules.dart';

/// Bu nadirliğin izin verdiği en yüksek eşya seviyesi.
int itemLevelCap(RewardRarity rarity) =>
    GameConstants.itemLevelCapByRarity[rarity] ?? 1;

/// İki tavanın **ikisini birden** uygulayan gerçek üst sınır.
int maxItemLevelFor(RewardRarity rarity, int playerLevel) {
  final cap = itemLevelCap(rarity);
  final bound = playerLevel < cap ? playerLevel : cap;
  return bound < 1 ? 1 : bound;
}

/// Yükseltmeyi engelleyen sebep. `null` yerine enum: engel **sessiz
/// kalmamalı** (Model Kuralları #4), kullanıcıya hangi tavanın bağladığı
/// söylenmeli.
enum UpgradeBlock {
  /// Engel yok, yükseltilebilir.
  none,

  /// Nadirlik tavanına ulaşıldı.
  rarityCap,

  /// Oyuncunun kendi seviyesi bağlıyor.
  playerLevel,

  /// Para yetmiyor.
  coins,
}

/// Bir yükseltmenin tam tablosu: maliyet, engel, tavanlar.
class UpgradeQuote {
  /// Yükseltmeden sonraki seviye. Engel varsa mevcut seviyeye eşit.
  final int nextLevel;

  /// Bu adımın coin maliyeti. Yükseltilemiyorsa `0`.
  final int cost;

  final UpgradeBlock block;

  /// Nadirliğin izin verdiği tavan (kullanıcıya gösterilir).
  final int rarityCap;

  /// İki tavanın birlikte verdiği gerçek sınır.
  final int effectiveCap;

  const UpgradeQuote({
    required this.nextLevel,
    required this.cost,
    required this.block,
    required this.rarityCap,
    required this.effectiveCap,
  });

  bool get canUpgrade => block == UpgradeBlock.none;

  /// Engelin kullanıcıya gösterilecek nedeni; engel yoksa `null`.
  String? reason(RewardRarity rarity, int playerLevel) => switch (block) {
    UpgradeBlock.none => null,
    UpgradeBlock.rarityCap =>
      'Nadirlik sınırı (${rarity.label}: $rarityCap). Daha ileri gitmek için '
          'birleştirerek nadirliğini yükseltmelisin.',
    UpgradeBlock.playerLevel =>
      'Eşya kendi seviyeni geçemez (Sv. $playerLevel). Sen yükseldikçe eşyan '
          'da yükselebilir.',
    UpgradeBlock.coins => '$cost coin gerekiyor.',
  };
}

/// Tek bir seviye atlamanın maliyeti.
///
/// `fiyat × toplam kat × (erken ağırlık + seviye / tavan) / (tavan − 1)`.
///
/// Ağırlıkların toplamı tam olarak `tavan − 1` ettiği için 1'den tavana
/// çıkarmanın toplamı `fiyat × GameConstants.itemUpgradeTotalMultiplier`
/// oluyor — yuvarlama payı dışında. İlk seviyeler ucuz, son seviyeler pahalı.
int upgradeCostFor(int itemCost, RewardRarity rarity, int fromLevel) {
  final cap = itemLevelCap(rarity);
  if (cap <= 1) return 0;
  final weight = GameConstants.itemUpgradeEarlyWeight + fromLevel / cap;
  final raw =
      itemCost * GameConstants.itemUpgradeTotalMultiplier * weight / (cap - 1);
  final rounded = (raw / 25).round() * 25;
  return rounded < 25 ? 25 : rounded;
}

/// 1. seviyeden tavana çıkarmanın toplam maliyeti. Denge ölçümü ve arayüzde
/// "bu eşya toplam ne tutar" bilgisi için.
int totalUpgradeCost(int itemCost, RewardRarity rarity) {
  var total = 0;
  for (var level = 1; level < itemLevelCap(rarity); level++) {
    total += upgradeCostFor(itemCost, rarity, level);
  }
  return total;
}

/// Bir örneğin yükseltme tablosu.
UpgradeQuote quoteUpgrade({
  required Item resolved,
  required OwnedItem instance,
  required int playerLevel,
  required int coins,
}) {
  final rarity = instance.effectiveRarity(resolved.rarity);
  final rarityCap = itemLevelCap(rarity);
  final effectiveCap = maxItemLevelFor(rarity, playerLevel);
  final cost = upgradeCostFor(resolved.cost, rarity, instance.level);

  UpgradeBlock block;
  if (instance.level >= rarityCap) {
    block = UpgradeBlock.rarityCap;
  } else if (instance.level >= effectiveCap) {
    // Nadirlik tavanı dolmadı ama oyuncu seviyesi bağlıyor: hangisinin
    // bağladığı **ayrı ayrı** söylenmeli, yoksa oyuncu neyi bekleyeceğini
    // bilemez.
    block = UpgradeBlock.playerLevel;
  } else if (coins < cost) {
    block = UpgradeBlock.coins;
  } else {
    block = UpgradeBlock.none;
  }

  return UpgradeQuote(
    nextLevel: block == UpgradeBlock.none ? instance.level + 1 : instance.level,
    cost:
        block == UpgradeBlock.rarityCap || block == UpgradeBlock.playerLevel
            ? 0
            : cost,
    block: block,
    rarityCap: rarityCap,
    effectiveCap: effectiveCap,
  );
}

/// Katalog item'ını, sahip olunan örneğin nadirliği ve seviyesiyle çözer.
///
/// İki adım:
/// 1. **Nadirlik**: örnek birleştirmeyle yükseltilmişse item o nadirliğe
///    taşınır ([withRarity]).
/// 2. **Seviye**: savaş statları [scaleForLevel] ile büyütülür; ekonomi
///    bonuslarına dokunulmaz.
///
/// [base] oyuncunun sınıfına **uyarlanmış** olmalı
/// (`ItemCatalog.byId(id, characterClass:)`), yoksa sınıfa özel buff'lar
/// (GD16) uygulanmaz.
Item resolveOwnedItem(Item base, OwnedItem instance, {String? characterClass}) {
  final rarity = instance.effectiveRarity(base.rarity);
  final withNewRarity =
      rarity == base.rarity
          ? base
          : withRarity(base, rarity, characterClass: characterClass);
  if (instance.level <= 1) return withNewRarity;
  return withNewRarity.copyWith(
    buff: scaleForLevel(withNewRarity.buff, instance.level),
  );
}

/// İki seviye arasındaki **savaş statı** farkını okunur satırlara çevirir.
///
/// Demirci panelinde "Sv. 5: saldırı 8 → 9, kritik hasarı %11 → %12,5"
/// satırını üretiyor. Ekonomi bonusları değişmediği için hiç listelenmiyor —
/// değişmeyen bir satırı göstermek yanıltıcı olurdu.
List<String> compareLevels(Item item, int fromLevel, int toLevel) {
  final before = scaleForLevel(item.buff, fromLevel).effects;
  final after = scaleForLevel(item.buff, toLevel).effects;
  final lines = <String>[];
  for (var i = 0; i < before.length && i < after.length; i++) {
    if (!before[i].stat.isCombat) continue;
    if (before[i].value == after[i].value) continue;
    lines.add(
      '${before[i].stat.label} '
      '${_valueText(before[i])} → ${_valueText(after[i])}',
    );
  }
  return lines;
}

String _valueText(ItemEffect effect) {
  if (effect.mode == ItemEffectMode.flat) {
    return effect.value.abs().round().toString();
  }
  return '%${ItemEffect.formatPercent(effect.value.abs())}';
}

/// Seviye çarpanı: seviye 1 = ×1.00, seviye 10 = ×1.90, seviye 50 = ×5.90.
double levelMultiplier(int level) =>
    1 + (level - 1) * GameConstants.itemStatGrowthPerLevel;

/// Buff'ın **yalnızca savaş** etkilerini seviyeye göre büyütür.
///
/// ⚠️ Ekonomi etkilerine dokunulmaz — bkz. dosya başındaki uyarı. Bu kural
/// burada kodla zorlanıyor: `effect.stat.isCombat` olmayan her etki olduğu
/// gibi geçiyor.
///
/// Eksi değerli etkiler (çift etkili itemlerin bedeli) de büyür: yükselen bir
/// eşyanın hem gücü hem bedeli artar, yoksa bedel seviyeyle erir.
ItemBuff scaleForLevel(ItemBuff buff, int level) {
  if (level <= 1) return buff;
  final factor = levelMultiplier(level);
  return ItemBuff([
    for (final effect in buff.effects)
      if (!effect.stat.isCombat) effect else _scaleCombat(effect, factor),
  ]);
}

ItemEffect _scaleCombat(ItemEffect effect, double factor) {
  final scaled = effect.value * factor;
  if (effect.mode == ItemEffectMode.flat) {
    final rounded = scaled.round();
    final safe = rounded == 0 ? (scaled < 0 ? -1 : 1) : rounded;
    return ItemEffect.flat(
      stat: effect.stat,
      value: safe.toDouble(),
      trigger: effect.trigger,
      chance: effect.chance,
      threshold: effect.threshold,
      customLabel: effect.customLabel,
    );
  }
  // Yarım yüzdeye yuvarlanır: `+%6,5` okunur kalsın.
  final rounded = (scaled * 200).round() / 200;
  final safe = rounded == 0 ? (scaled < 0 ? -0.005 : 0.005) : rounded;
  return ItemEffect(
    stat: effect.stat,
    value: safe,
    mode: effect.mode,
    trigger: effect.trigger,
    chance: effect.chance,
    threshold: effect.threshold,
    customLabel: effect.customLabel,
  );
}
