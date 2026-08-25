import '../../models/combat_stats.dart';
import '../../models/item_effect.dart';
import '../../models/streak_stat_bonuses.dart';
import 'base_combat_stats.dart';
import 'equipped_buffs.dart';

/// Savaşa giren statların **tek** hesaplayıcısı.
///
/// Dört kaynağı toplar:
///
/// 1. **Taban** — seviyeden (`base_combat_stats.dart`).
/// 2. **Ekipman** — kuşanılan itemlerin sabit ve oransal katkısı
///    ([EquippedBuffs]). Eşya seviyesi ve birleştirmenin büyüttüğü değerler
///    zaten buff'ın içinde: `RootShell._resolveInstance` örneği katalogdan
///    çözerken `scaleForLevel` uyguluyor.
/// 3. **Seri** — [StreakStatBonuses], oransal (Bölüm 5C).
/// 4. **Koşullu etkiler** — o anki duruma uyan tetikleyiciler.
///
/// Formül, stat başına:
/// ```
/// değer = (taban + ekipmanSabit) × (1 + ekipmanOran + seriOran + koşulluOran)
/// ```
/// Sabit katkı çarpandan **önce** giriyor: aksi hâlde "+12 saldırı" veren bir
/// item, oran bonusları büyüdükçe kendiliğinden değersizleşirdi.
///
/// Motorda ikinci bir toplama yok; `combat_engine.dart` yalnızca buradan
/// çıkan [CombatStats]'i okur.

/// Koşullu etkilerin değerlendirileceği anlık durum.
///
/// [ItemEffectTrigger.onHit] ve [ItemEffectTrigger.onKill] burada **yok**:
/// onlar bir duruma değil bir **olaya** bağlı ve motorun içinde, vuruş
/// anında çözülüyor.
class CombatConditions {
  /// Savaşanın canının tavanına oranı (0..1).
  final double healthRatio;

  /// Arka arkaya hiç hasar alınmamış round sayısı.
  final int untouchedRounds;

  /// Gece yürüyüşü mü (oyun gününün karanlık saatleri).
  final bool nightWalk;

  /// Günlük seri ayakta mı.
  final bool streakActive;

  const CombatConditions({
    this.healthRatio = 1,
    this.untouchedRounds = 0,
    this.nightWalk = false,
    this.streakActive = false,
  });

  /// Hiçbir koşullu etkinin açılmadığı durum. Menü ve panel gösterimlerinde
  /// "pasif statlarım neler" sorusunun cevabı bu.
  static const CombatConditions passive = CombatConditions();

  /// [effect] bu durumda geçerli mi.
  ///
  /// Olaya bağlı tetikleyiciler (`onHit`, `onKill`) burada **hiçbir zaman**
  /// açılmaz; motorun sorumluluğunda.
  bool allows(ItemEffect effect) => switch (effect.trigger) {
    ItemEffectTrigger.always => true,
    ItemEffectTrigger.lowHealth => healthRatio <= effect.threshold,
    ItemEffectTrigger.highHealth => healthRatio >= effect.threshold,
    ItemEffectTrigger.untouchedRounds => untouchedRounds >= effect.threshold,
    ItemEffectTrigger.nightWalk => nightWalk,
    ItemEffectTrigger.streakActive => streakActive,
    ItemEffectTrigger.onHit || ItemEffectTrigger.onKill => false,
  };
}

/// Oyuncunun o andaki savaş statları.
CombatStats effectiveCombatStats({
  required int level,
  required EquippedBuffs buffs,
  StreakStatBonuses streak = StreakStatBonuses.empty,
  CombatConditions conditions = CombatConditions.passive,
}) {
  final base = baseCombatStats(level);
  final flat = <ItemStat, double>{};
  final rate = <ItemStat, double>{};

  for (final effect in buffs.combatEffects) {
    if (!effect.stat.isCombat) continue;
    // İhtimalli etkiler (`chance < 1`) burada toplanmaz: onlar vuruş anında,
    // zarla çözülüyor.
    if (effect.chance < 1) continue;
    if (!conditions.allows(effect)) continue;
    if (effect.mode == ItemEffectMode.flat) {
      flat[effect.stat] = (flat[effect.stat] ?? 0) + effect.value;
    } else {
      rate[effect.stat] = (rate[effect.stat] ?? 0) + effect.value;
    }
  }

  var stats = base;
  for (final stat in ItemStat.values) {
    if (!stat.isCombat) continue;
    final combined =
        (base.statFor(stat) + (flat[stat] ?? 0)) *
        (1 + (rate[stat] ?? 0) + streak.bonusFor(stat));
    stats = stats.withStat(stat, combined);
  }
  return stats.sanitized();
}

/// Vuruş anında tetiklenen (`onHit` / `onKill`) etkiler.
///
/// Motor bunları zarla çözer; efektif statlara katılmazlar.
List<ItemEffect> triggeredEffects(
  EquippedBuffs buffs,
  ItemEffectTrigger trigger,
) => [
  for (final effect in buffs.combatEffects)
    if (effect.trigger == trigger && effect.stat.isCombat) effect,
];
