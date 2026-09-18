import '../../models/combat_stats.dart';

/// Oyuncunun **taban** savaş statları: yalnızca seviyeden gelir.
///
/// Ekipmansız, serisiz bir oyuncunun sahip olduğu değerler. Efektif statlar
/// bunun üstüne kurulur (`effective_stats.dart`).
///
/// Combat stats still scale linearly with the level, independently of the
/// walking step curve. This update does not rebalance equipment or enemies.
///
/// ## Neden bazı statlar seviyeyle büyümüyor
///
/// Kritik ihtimali, kritik hasarı, can çalma, sıyrılma ve şans **sabit**:
/// bunlar ekipmanın ve serinin alanı. Seviye ham gücü (saldırı, savunma, can)
/// büyütür; "nasıl dövüşüyorsun" sorusunun cevabı kuşandığın şeyden gelir.
/// Aksi hâlde seviye tek başına her şeyi verir ve item seçimi süse dönerdi.

/// Taban saldırı: 1. seviyede 10, her seviyede +2.
const double baseAttackAtLevelOne = 10;
const double attackPerLevel = 2;

/// Taban savunma: 1. seviyede 4, her seviyede +1.
const double baseDefenseAtLevelOne = 4;
const double defensePerLevel = 1;

/// Taban savaş canı: 1. seviyede 100, her seviyede +10.
///
/// 100 bilerek korundu: savaş canı Aşama 0'dan beri 0–100 aralığında
/// gösteriliyordu ve oyuncunun alıştığı ölçek bu.
const double baseHealthAtLevelOne = 100;
const double healthPerLevel = 10;

/// Seviyeyle büyümeyen taban değerler.
const double baseCritChance = 0.05;
const double baseCritDamage = 0.5;
const double baseLifeSteal = 0;
const double baseDodge = 0.03;
const double baseSpeed = 10;
const double baseLuck = 5;

/// [level] seviyesindeki bir oyuncunun ekipmansız savaş statları.
CombatStats baseCombatStats(int level) {
  final steps = (level < 1 ? 1 : level) - 1;
  return CombatStats(
    attack: baseAttackAtLevelOne + attackPerLevel * steps,
    defense: baseDefenseAtLevelOne + defensePerLevel * steps,
    maxHealth: baseHealthAtLevelOne + healthPerLevel * steps,
    critChance: baseCritChance,
    critDamage: baseCritDamage,
    lifeSteal: baseLifeSteal,
    dodge: baseDodge,
    speed: baseSpeed,
    luck: baseLuck,
  );
}
