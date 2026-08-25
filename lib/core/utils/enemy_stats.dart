import '../../models/combat_stats.dart';
import '../../models/enemy.dart';
import 'base_combat_stats.dart';

/// Düşman savaş statlarını **kademeden ve arketipten** türeten saf kurallar.
///
/// 20 düşmana elle 9'ar stat yazmak hem tutarsız olurdu hem bakımı imkânsız
/// (item kataloğunda aynı karar GD7'de verildi). Elle verilen tek şey
/// arketip; geri kalanı buradan çıkıyor.
///
/// ## Denge nasıl kuruldu
///
/// Her kademe bir **beklenen oyuncu seviyesine** bağlandı: kademe *i* için
/// beklenen seviye *i*. Gerekçe: düşmanlar 500 adımlık basamaklarla açılıyor
/// ve adım hedefi büyüdükçe oyuncu da seviye atlıyor.
///
/// İki hedef sayı var:
///
/// 1. **Düşman canı**, o seviyedeki ölçüt oyuncunun tam tuttuğu round başına
///    verdiği hasar × beklenen round sayısı. Beklenen round sayısı düşmanın
///    kilit eşiğinden geliyor (`minimumDailySteps / 1000`, en az 1). Yani
///    kilit eşiğini seçen ölçüt bir oyuncu, maceranın sonunda düşmanı devirir;
///    daha güçlü oyuncu **erken** devirir.
/// 2. **Düşman saldırısı**, tamamen kaçırılan bir roundun o seviyedeki
///    oyuncunun canının [missedRoundHealthCost] kadarını götürmesi.
///    Böylece "kaç round kaçırırsam ölürüm" sorusunun cevabı her kademede
///    aynı kalıyor ve kademe atlamak cezayı sessizce ağırlaştırmıyor.
///
/// Katalogdaki elle yazılmış [Enemy.attackDamage] değerleri **korunuyor**:
/// kademenin doğrusal beklentisine oranlanıp bir çarpan olarak uygulanıyor.
/// Böylece tasarımcının bilerek zayıf bıraktığı düşman (ör. 13. kademedeki
/// Eyeball Monster) zayıf kalıyor.

/// Tamamen kaçırılan bir roundun oyuncunun canından götürdüğü oran.
///
/// %15: yedi round üst üste hiç yürümeyen oyuncu ölür. Daha düşüğü ölümü
/// imkânsız kılar (macera en fazla 10 round), daha yükseği tek kötü günü
/// yenilgiye çevirir.
const double missedRoundHealthCost = 0.15;

/// Kademenin doğrusal saldırı beklentisi. Katalogdaki değer buna oranlanır.
double expectedCatalogAttack(int tier) => 7 + tier.toDouble();

/// Kademe *i* için beklenen round sayısı.
int expectedRoundsForTier(int tier, int stageStepTarget) {
  final steps = tier * 500;
  final rounds = (steps / stageStepTarget).ceil();
  return rounds < 1 ? 1 : rounds;
}

/// Arketipin stat bütçesini nasıl kaydırdığı.
///
/// Çarpanların hepsi cana göre dengeli: canı büyüyen arketip saldırıdan ya da
/// hızdan veriyor. Toplam tehdit kabaca sabit kalıyor, **şekli** değişiyor.
({
  double health,
  double defense,
  double attack,
  double speed,
  double critChance,
  double critDamage,
  double dodge,
  double lifeSteal,
})
enemyArchetypeProfile(EnemyArchetype archetype) => switch (archetype) {
  EnemyArchetype.bruiser => (
    health: 1.0,
    defense: 1.0,
    attack: 1.0,
    speed: 1.0,
    critChance: 0.05,
    critDamage: 0.5,
    dodge: 0.02,
    lifeSteal: 0.0,
  ),
  EnemyArchetype.tank => (
    health: 1.45,
    defense: 1.4,
    attack: 0.85,
    speed: 0.6,
    critChance: 0.03,
    critDamage: 0.4,
    dodge: 0.0,
    lifeSteal: 0.0,
  ),
  EnemyArchetype.swift => (
    health: 0.75,
    defense: 0.8,
    attack: 0.95,
    speed: 1.6,
    critChance: 0.08,
    critDamage: 0.5,
    dodge: 0.12,
    lifeSteal: 0.0,
  ),
  EnemyArchetype.caster => (
    health: 0.7,
    defense: 0.6,
    attack: 1.3,
    speed: 1.1,
    critChance: 0.15,
    critDamage: 0.8,
    dodge: 0.02,
    lifeSteal: 0.1,
  ),
};

/// Kademenin ham (arketipsiz) savunması.
double baseEnemyDefense(int tier) => 2 + tier.toDouble();

/// Bir düşmanın savaş statları.
///
/// [catalogAttackDamage] katalogdaki elle yazılmış saldırı değeri;
/// [stageStepTarget] bir roundun adım hedefi ([AdventureQuest.stageStepTarget]).
CombatStats enemyCombatStats({
  required int tier,
  required EnemyArchetype archetype,
  required int catalogAttackDamage,
  required int stageStepTarget,
}) {
  final profile = enemyArchetypeProfile(archetype);
  final player = baseCombatStats(tier);

  final defense = baseEnemyDefense(tier) * profile.defense;

  // 1) Can: ölçüt oyuncunun round başına hasarı × beklenen round sayısı.
  final defenseForHealth = CombatStats(defense: defense);
  final playerDamagePerRound = defenseForHealth.damageAfterDefense(
    player.attack,
  );
  final rounds = expectedRoundsForTier(tier, stageStepTarget);
  final health = playerDamagePerRound * rounds * profile.health;

  // 2) Saldırı: kaçırılan roundun oyuncu canından götürdüğü oran sabit.
  //    Oyuncunun savunması hasabı azaltacağı için o azalma geri çarpılıyor.
  final playerReduction =
      1 - player.defense / (player.defense + CombatStats.defenseSoftening);
  final targetAttack =
      missedRoundHealthCost * player.maxHealth / playerReduction;
  // Katalogdaki elle yazılmış değerin kademe beklentisine oranı korunur.
  final catalogRatio = catalogAttackDamage / expectedCatalogAttack(tier);
  final attack = targetAttack * catalogRatio * profile.attack;

  return CombatStats(
    attack: attack,
    defense: defense,
    maxHealth: health < 1 ? 1 : health,
    critChance: profile.critChance,
    critDamage: profile.critDamage,
    lifeSteal: profile.lifeSteal,
    dodge: profile.dodge,
    speed: (baseSpeed + tier * 0.5) * profile.speed,
    luck: tier.toDouble(),
  ).sanitized();
}
