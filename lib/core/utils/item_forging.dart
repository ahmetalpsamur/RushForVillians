/// Demircide **yeniden atmanın** saf kuralları (Bölüm E / Faz 4, GD112).
///
/// `item_leveling.dart` ve `item_merging.dart` ile aynı desen: kural burada,
/// ekran ve `RootShell` buradan okur, ikinci bir hesap yazılmaz.
///
/// ## Dört kural
///
/// 1. **Tek yuva.** Oyuncu hangi etkiyi atacağını seçer; diğerleri olduğu
///    gibi kalır. **İmzalı etkiler yeniden atılamaz** — eşyanın kimliği.
///    Yalnızca kural havuzundan gelen (jenerik) yuvalar atılabilir.
/// 2. **Yuvanın türü korunur.** Ekonomi yuvası ekonomi, savaş yuvası savaş
///    olarak kalır; aynı stat bir eşyada iki yuvada bulunmaz. Havuz kural
///    türetmesinin havuzu: ekonomide sınıf imzası + kategori eğilimi
///    ağırlıkları, savaşta eşyanın arketipinin üç statı.
/// 3. **Kademe nadirlik ve seviyeden.** En yüksek kademe nadirliğin kademesi
///    (sıradan I ... efsanevi V); eşya seviyesi nadirlik tavanının yarısına
///    ulaşmadan bir altı. Düşük nadirlikte üst kademe hiç çıkmaz.
/// 4. **Rastgelelik tohumlu ve saklanan** (§10 #1): ayrı bir akış,
///    `UserProfile.forgeSeed`. Çark ve savaş tohumuyla paylaşılmaz — yoksa
///    çark çevirerek demircinin zarı kaydırılabilirdi (GD50 ile aynı sebep).
library;

import 'dart:math';

import '../../data/forge_tiers.dart';
import '../../data/item_archetypes.dart';
import '../../models/forged_effect.dart';
import '../../models/item.dart';
import '../../models/item_effect.dart';
import '../../models/owned_item.dart';
import '../../models/reward_rarity.dart';
import '../constants/game_constants.dart';
import 'item_leveling.dart';
import 'item_rules.dart';

/// Nadirliğin kademesi: sıradan 1 ... efsanevi 5.
int rarityTier(RewardRarity rarity) => rarity.index + 1;

/// Nadirliğin en yüksek kademesinin açıldığı eşya seviyesi: nadirlik
/// tavanının yarısı (5 · 10 · 15 · 20 · 25).
int forgeTopTierUnlockLevel(RewardRarity rarity) =>
    (itemLevelCap(rarity) / 2).ceil();

/// Bu eşyada atılabilecek en yüksek kademe.
int maxForgeTier(RewardRarity rarity, int level) {
  final top = rarityTier(rarity);
  if (top <= 1) return 1;
  return level >= forgeTopTierUnlockLevel(rarity) ? top : top - 1;
}

/// [rerollCount] kez atılmış bir örnekte bir sonraki rastgele atışın
/// maliyeti: `taban × (1 + 0,5 × n)`, tavan `taban × 3`. 5'e yuvarlı.
int rerollCost(RewardRarity rarity, int rerollCount) {
  final base = GameConstants.forgeRerollBaseCost[rarity] ?? 0;
  final factor = min(
    1 + GameConstants.forgeRerollStep * rerollCount,
    GameConstants.forgeRerollCapMultiplier,
  );
  return ((base * factor) / 5).round() * 5;
}

/// "Keşiften seç" maliyeti: o anki atış maliyetinin 4 katı.
int pickCost(RewardRarity rarity, int rerollCount) =>
    rerollCost(rarity, rerollCount) * GameConstants.forgePickMultiplier;

/// Ekonomi yuvalarının stat havuzu. `stepCoinMomentum` da `stepCoin`'e
/// yazdığı için ayrı bir stat değil.
const List<ItemStat> forgeEconomyStats = [
  ItemStat.stepCoin,
  ItemStat.stepXp,
  ItemStat.wheelXp,
  ItemStat.enemyXp,
  ItemStat.streakFreezeCap,
  ItemStat.wheelSpinCap,
  ItemStat.streakRelief,
];

/// Yeniden atılabilir yuva sayısı: imzalı etkiler hariç.
int forgeSlotCount(Item item) =>
    item.buff.effects.length - signatureCoreCount(item);

/// Bir yuvanın şimdiki etkisi.
ItemEffect forgeSlotEffect(Item item, int slot) =>
    item.buff.effects[signatureCoreCount(item) + slot];

/// Bir yuvaya gelebilecek statlar, ağırlıklarıyla.
///
/// Yuvanın türü korunur (ekonomi/savaş) ve eşyanın **başka** yuvalarında
/// bulunan statlar elenir; yuvanın kendi statı havuzda kalır. Savaş
/// havuzunun üç statı da başka yuvalardaysa yuvanın kendi statı tek seçenek
/// olur — o zaman yalnızca değer yeniden atılır.
Map<ItemStat, int> forgeSlotPool(
  Item item,
  int slot, {
  String? characterClass,
}) {
  final effects = item.buff.effects;
  final index = signatureCoreCount(item) + slot;
  final current = effects[index].stat;
  final others = {
    for (var i = 0; i < effects.length; i++)
      if (i != index) effects[i].stat,
  };

  final pool = <ItemStat, int>{};
  if (current.isCombat) {
    final stats = ItemArchetypes.combatStats[item.archetype]!;
    for (var rank = 0; rank < stats.length; rank++) {
      if (others.contains(stats[rank])) continue;
      if (ForgeTiers.ranges[stats[rank]] == null) continue;
      pool[stats[rank]] = stats.length - rank;
    }
  } else {
    final weights = economyTypeWeights(
      item.category,
      characterClass: characterClass,
    );
    for (final entry in weights.entries) {
      final stat = entry.key.stat;
      if (others.contains(stat)) continue;
      pool[stat] = (pool[stat] ?? 0) + entry.value;
    }
  }
  if (pool.isEmpty && ForgeTiers.ranges[current] != null) pool[current] = 1;
  return pool;
}

/// Tohumdan bir sonraki tohum. Savaşın ve çarkın LCG'sinden **farklı**
/// sabitler: aynı başlangıç değerinden bile ayrı diziler üretsinler.
int nextForgeSeed(int seed) {
  final next = (seed * 214013 + 2531011) & 0x7FFFFFFF;
  return next == 0 ? 1 : next;
}

/// Oyuncuya özel başlangıç tohumu (çarkın `initialWheelSeed` deseni).
int initialForgeSeed(String salt) => stableSpread('forge|$salt', 0x3FFFFFFF) + 1;

/// Bir atışın sonucu.
class ForgeRoll {
  final ForgedEffect effect;
  final int nextSeed;

  const ForgeRoll(this.effect, this.nextSeed);
}

/// Bir yuvayı atar.
///
/// [chosenStat] + [chosenTier] verilirse "keşiften seç": tür ve kademe
/// kesin, **değer yine rastgele**. Verilmezse tür havuzdan ağırlıklı,
/// kademe eşyanın en yüksek kademesi.
///
/// Saf ve deterministik: aynı tohum aynı sonucu verir.
ForgeRoll rollForge({
  required int seed,
  required Item item,
  required int slot,
  required RewardRarity rarity,
  required int level,
  String? characterClass,
  ItemStat? chosenStat,
  int? chosenTier,
}) {
  final random = Random(seed);
  final stat =
      chosenStat ??
      _weightedPick(
        forgeSlotPool(item, slot, characterClass: characterClass),
        random,
      );
  final tier = chosenTier ?? maxForgeTier(rarity, level);
  return ForgeRoll(
    ForgedEffect(stat: stat, tier: tier, value: _rollValue(stat, tier, random)),
    nextForgeSeed(seed),
  );
}

ItemStat _weightedPick(Map<ItemStat, int> pool, Random random) {
  var total = 0;
  for (final weight in pool.values) {
    total += weight;
  }
  var point = random.nextInt(total);
  // Yineleme enum sırasında: sonuç `Map` ekleme sırasından bağımsız.
  for (final stat in ItemStat.values) {
    final weight = pool[stat];
    if (weight == null) continue;
    if (point < weight) return stat;
    point -= weight;
  }
  return pool.keys.first;
}

/// Aralıktan **düzgün dağılımla** bir değer: `alt + k × adım`.
double _rollValue(ItemStat stat, int tier, Random random) {
  final (low, high) = ForgeTiers.rangeFor(stat, tier)!;
  final step = ForgeTiers.stepFor(stat);
  final steps = ((high - low) / step).round();
  final k = steps <= 0 ? 0 : random.nextInt(steps + 1);
  return _snap(low + k * step, step);
}

/// Kayan nokta artığını adıma oturtur (`0.013 + 3 × 0.001` → `0.016`).
double _snap(double value, double step) =>
    double.parse(((value / step).round() * step).toStringAsFixed(6));

/// Bir etkinin kademesi: değerin merkezine **en yakın** kademe.
///
/// Türetilmiş (hiç atılmamış) etkilerin kademesini göstermek için. Değer
/// merkezler arasında eşit uzaklıktaysa alttaki kademe seçilir.
int classifyForgeTier(ItemStat stat, double value) {
  final list = ForgeTiers.ranges[stat];
  if (list == null) return 1;
  var best = 1;
  var bestDistance = double.infinity;
  for (var tier = 1; tier <= list.length; tier++) {
    final distance = (ForgeTiers.centerOf(stat, tier) - value.abs()).abs();
    if (distance < bestDistance - 1e-12) {
      best = tier;
      bestDistance = distance;
    }
  }
  return best;
}

/// Atılmış bir etkinin oyun içi karşılığı.
ItemEffect forgedToItemEffect(ForgedEffect forged) {
  final spec = ItemArchetypes.combatSpec[forged.stat];
  if (spec != null) {
    return spec.$1 == ItemEffectMode.flat
        ? ItemEffect.flat(stat: forged.stat, value: forged.value)
        : ItemEffect(stat: forged.stat, value: forged.value);
  }
  return switch (forged.stat) {
    ItemStat.streakFreezeCap ||
    ItemStat.wheelSpinCap ||
    ItemStat.streakRelief => ItemEffect.flat(
      stat: forged.stat,
      value: forged.value,
    ),
    _ => ItemEffect(stat: forged.stat, value: forged.value),
  };
}

/// Türetilmiş bir etkiyi saklanabilir biçime çevirir (ilk atışta bütün
/// yuvalar bir kez **dondurulur**; atılan yuva dışındakiler aynı kalır).
ForgedEffect forgedFromEffect(ItemEffect effect) => ForgedEffect(
  stat: effect.stat,
  tier: classifyForgeTier(effect.stat, effect.value),
  value: effect.value,
);

/// Örneğin atılmış etkilerini nadirliğe taşınmış item'a uygular.
///
/// Seviye büyümesinden **önce** çağrılır (`resolveOwnedItem`): saklanan
/// değerler Sv. 1 değeri, yükseltme onları da büyütür. İmzalı etkiler
/// katalogdan gelir ve dokunulmaz. Uzunluk uyuşmazsa (bozuk kayıt, ileride
/// değişen yuva sayısı) türetilmiş buff'a düşülür — eşya kaybolmaz. Ekonomi
/// toplamı yine %15'e kırpılır (Faz E2 kuralı yeniden atmaya da geçerli).
Item applyForgedEffects(Item item, OwnedItem instance) {
  final forged = instance.forgedEffects;
  if (forged == null) return item;
  final core = signatureCoreCount(item);
  if (item.buff.effects.length - core != forged.length) return item;
  return item.copyWith(
    buff: ItemBuff(
      capEconomyTotals([
        ...item.buff.effects.take(core),
        for (final effect in forged) forgedToItemEffect(effect),
      ]),
    ),
  );
}

/// Bir (stat, kademe) keşfinin bu yuvada seçilebilir olup olmadığı.
bool canPickForSlot(
  Item item,
  int slot,
  ItemStat stat,
  int tier, {
  required RewardRarity rarity,
  required int level,
  String? characterClass,
}) =>
    tier <= maxForgeTier(rarity, level) &&
    forgeSlotPool(item, slot, characterClass: characterClass).containsKey(stat);
