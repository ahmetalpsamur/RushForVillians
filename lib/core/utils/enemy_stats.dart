import '../../models/combat_stats.dart';
import '../../models/enemy.dart';
import '../constants/attack_config.dart';
import '../constants/timed_combat_config.dart';
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
///    kilit eşiğinin türetilmiş round yapısından geliyor. Yani
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

/// Kademe *i* için beklenen round sayısı — düşmanın **kendi kilit eşiğinde**
/// (kademe × 500 adım) dövüştüğü varsayımı, **azalmayan zarf** olarak.
///
/// Yalnızca **katalog tabanı** için: gerçek savaşta can [enemyCombatStats]'a
/// verilen `plannedRounds` ile, yani o maceranın gerçekten planlanan round
/// sayısıyla hesaplanıyor (GD49) ve bu fonksiyon devreye hiç girmiyor.
///
/// ⚠️ **Zarf hâlâ gerekli.** Doğrudan `roundCountForSteps(kademe × 500)`
/// kullanılınca tempo tablosu bant sınırında round sayısını düşürüyor
/// (2.500 → 5 round, 3.000 → 3 round) ve katalogdaki 6. kademe düşman
/// 5. kademeden **zayıf** görünüyor. Katalog tabanı bugün yalnızca ölçüm ve
/// eski çağrı noktaları tarafından okunuyor ama "üst kademe asla daha zayıf
/// değildir" gerçek bir değişmez; `combat_balance_test` onu bağlıyor.
int expectedRoundsForTier(int tier) {
  var rounds = 0;
  for (var step = 1; step <= tier; step++) {
    final count = AttackConfig.roundCountForSteps(step * 500);
    if (count > rounds) rounds = count;
  }
  return rounds;
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
///
/// [plannedRounds] verilirse can **o maceranın gerçekten planlanan round
/// sayısından** hesaplanır; verilmezse düşmanın kendi kilit eşiğindeki
/// beklenti kullanılır (önizleme/katalog tabanı).
///
/// **Neden hedefin round sayısı** (GD49): §6.10'un can formülü zaten
/// "round başına hasar × **beklenen round sayısı**" ve GD49 `stepGoal`'un
/// beklenen round sayısını belirlediğini açıkça söylüyor. Kademeden türetilen
/// vekil kullanılınca tempo bandı değiştiren hedeflerde ikisi ayrışıyordu:
/// 3.000 adımlık macera 3 round planlıyor ama tier-6 düşmanın canı 5 round
/// için kuruluyordu — taahhüt bittiğinde düşman hâlâ ayakta kalıyordu
/// (ölçülen yük oranı 1,81).
CombatStats enemyCombatStats({
  required int tier,
  required EnemyArchetype archetype,
  required int catalogAttackDamage,
  int? plannedRounds,
}) {
  final profile = enemyArchetypeProfile(archetype);
  final player = baseCombatStats(tier);

  final defense = baseEnemyDefense(tier) * profile.defense;

  // 1) Can: ölçüt oyuncunun round başına hasarı × planlanan round sayısı.
  final defenseForHealth = CombatStats(defense: defense);
  final playerDamagePerRound = defenseForHealth.damageAfterDefense(
    player.attack,
  );
  final rounds = plannedRounds ?? expectedRoundsForTier(tier);
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

/// Bir saldırı hedefinin güç çarpanını düşmanın **katalog tabanına** uygular.
///
/// Sağlık ve ham saldırı doğrusal ölçeklenir. Savunma, hız ve olasılık statları
/// sabit kalır; onları da çarpmak efektif dayanıklılığı doğrusal değerin üstüne
/// taşır ve kritik/sıyrılma oranlarını anlamsız biçimde tavana vurur.
///
/// Çağıran taraf her zaman [baseStats] olarak katalog statını vermelidir. Böylece
/// round ilerledikçe daha önce ölçeklenmiş bir değer tekrar çarpılmaz.
CombatStats scaleEnemyCombatStats(
  CombatStats baseStats,
  double enemyPowerMultiplier,
) {
  if (enemyPowerMultiplier <= 0 || !enemyPowerMultiplier.isFinite) {
    throw ArgumentError.value(
      enemyPowerMultiplier,
      'enemyPowerMultiplier',
      'Must be a finite value greater than zero.',
    );
  }
  return baseStats
      .copyWith(
        attack: baseStats.attack * enemyPowerMultiplier,
        maxHealth: baseStats.maxHealth * enemyPowerMultiplier,
      )
      .sanitized();
}

/// Bir maceranın düşman statları: canı **o hedefin planlanan round
/// sayısından** kurar, sonra hedefin güç çarpanını uygular.
///
/// Savaşın tek stat kaynağı bu. Katalogdaki [Enemy.stats] yalnızca
/// önizlemenin tabanı; ikisi ayrışmasın diye burada yeniden türetiliyor,
/// ölçeklenmiş bir değer ikinci kez çarpılmıyor.
CombatStats enemyStatsForGoal({required Enemy enemy, required int stepGoal}) =>
    scaleEnemyCombatStats(
      enemyBaseStatsForGoal(enemy: enemy, stepGoal: stepGoal),
      TimedCombatConfig.difficultyMultiplierForSteps(stepGoal),
    );

/// [enemyStatsForGoal]'un **güç çarpanı uygulanmamış** hâli.
///
/// Yalnızca çarpanı ayrıca uygulayan çağrı noktaları için: v13 taşıması
/// kalan can oranını bununla kuruyor, çarpanı v25→v26 taşıması ekliyor.
/// İkisini birden uygulamak çarpanı **iki kez** saymak olurdu.
CombatStats enemyBaseStatsForGoal({
  required Enemy enemy,
  required int stepGoal,
}) => enemyCombatStats(
  tier: enemy.tier,
  archetype: enemy.archetype,
  catalogAttackDamage: enemy.attackDamage,
  plannedRounds: AttackConfig.roundCountForSteps(stepGoal),
);
