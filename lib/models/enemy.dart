import 'combat_stats.dart';

/// Düşmanın savaş davranışı.
///
/// Aynı kademedeki iki düşman aynı güç bütçesini farklı dağıtır: hangisiyle
/// karşılaştığın, nasıl dövüşeceğini değiştirir. Item arketipleriyle
/// (`ItemArchetype`) aynı fikir, düşman tarafında.
enum EnemyArchetype {
  /// Dengeli. Bütçeyi eşit dağıtır; kademenin ölçüt düşmanı.
  bruiser,

  /// Etli butlu. Yüksek can ve savunma, düşük hız — geç vurur ama uzun dayanır.
  tank,

  /// Çevik. Düşük can, yüksek hız ve sıyrılma — önce vurur, kaçar.
  swift,

  /// Büyücü. Düşük can ve savunma, yüksek saldırı ve kritik — cam top.
  caster,
}

extension EnemyArchetypeX on EnemyArchetype {
  String get label => switch (this) {
    EnemyArchetype.bruiser => 'Dengeli',
    EnemyArchetype.tank => 'Dayanıklı',
    EnemyArchetype.swift => 'Çevik',
    EnemyArchetype.caster => 'Büyücü',
  };

  /// Kartta gösterilen tek cümlelik davranış açıklaması.
  String get description => switch (this) {
    EnemyArchetype.bruiser => 'Dengeli dövüşür; sürprizi yoktur.',
    EnemyArchetype.tank => 'Yavaş ama çok dayanıklı; canını eritmek zaman ister.',
    EnemyArchetype.swift => 'Genelde önce vurur ve vuruşlarını sıyırır.',
    EnemyArchetype.caster => 'Kırılgan ama sert vurur; kritiği yüksektir.',
  };
}

class Enemy {
  final String id;
  final String name;
  final String idleAsset;
  final String walkAsset;
  final String hurtAsset;
  final List<String> attackAssets;
  final String deathAsset;
  final int attackAnimationDurationMs;
  final int deathAnimationDurationMs;

  /// Düşmanın ham saldırı gücü. Savaş motorunda [CombatStats.attack] olur.
  final int attackDamage;
  final String questText;
  final int minimumDailySteps;
  final int xpReward;

  /// Savaş davranışı; statların bütçesini dağıtır.
  final EnemyArchetype archetype;

  /// Savaşa giren tam stat kümesi. Kademe + arketipten türetilir
  /// (`data/enemy_catalog.dart`), elle tek tek yazılmaz.
  final CombatStats stats;

  const Enemy({
    required this.id,
    required this.name,
    required this.idleAsset,
    required this.walkAsset,
    required this.hurtAsset,
    required this.attackAssets,
    required this.deathAsset,
    required this.attackAnimationDurationMs,
    required this.deathAnimationDurationMs,
    required this.attackDamage,
    required this.questText,
    required this.minimumDailySteps,
    required this.xpReward,
    required this.archetype,
    required this.stats,
  });

  String get attackAsset => attackAssets.first;

  /// Düşmanın savaş canı tavanı.
  int get maxHealth => stats.maxHealth.round();

  /// Kademe numarası (1..20). Kilit eşiği 500 adımlık basamaklarla artıyor.
  int get tier => (minimumDailySteps / 500).ceil().clamp(1, 999);
}
