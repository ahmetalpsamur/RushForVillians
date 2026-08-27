import '../core/utils/enemy_stats.dart';
import '../models/enemy.dart';

const _root = 'lib/All_Assets/Enemies/Characters(100x100 split)';

const _attackVariants = <String, List<String>>{
  'Black Knight_A': ['Attack01', 'Attack02', 'Attack03'],
  'Black Knight_B': ['Attack01', 'Attack02', 'Attack03'],
  'Black Knight_C': ['Attack01', 'Attack02', 'Attack03'],
  'Blood Monster_A': ['Attack01', 'Attack02'],
  'Blood Monster_B': ['Attack01', 'Attack02'],
  'Demoness_A': ['Attack01', 'Attack02', 'Attack03'],
  'Demoness_B': ['Attack01', 'Attack02'],
  'Demon_A': ['Attack01', 'Attack02'],
  'Demon_B': ['Attack01', 'Attack02'],
  'Demon_C': ['Attack01', 'Attack02'],
  'Demon_D': ['Attack01', 'Attack02', 'Attack03'],
  'Demon_E': ['Attack01', 'Attack02', 'Attack03'],
  'Eyeball Monster': ['Attack01', 'Attack02', 'Attack03'],
  'Flame Golem': ['Attack01', 'Attack02', 'Attack03'],
  'Ghostfire': ['Attack01', 'Attack02'],
  'Hellbat': ['Attack01', 'Attack02'],
  'Hellhound': ['Attack01', 'Attack02'],
  'Lava Slime': ['Attack01', 'Attack02'],
  'Minotaur': ['Attack01', 'Attack02', 'Attack03'],
  'Warlock': ['Attack01', 'Attack02(With magic effects)', 'Attack02'],
};

Enemy _enemy({
  required String id,
  required String folder,
  required String name,
  required String questText,
  required int minimumDailySteps,
  required int attackDamage,
  required int xpReward,
  required EnemyArchetype archetype,
  String idleAnimation = 'Idle',
  String walkAnimation = 'Walk',
  String attackAnimation = 'Attack01',
  int attackAnimationDurationMs = 700,
  int deathAnimationDurationMs = 700,
}) {
  final base = '$_root/$folder/$folder/$folder';
  // Savaş statları elle yazılmaz: kademe + arketipten türetilir
  // (`core/utils/enemy_stats.dart`). Elle verilen tek şey arketip.
  final tier = (minimumDailySteps / 500).ceil().clamp(1, 999);
  return Enemy(
    archetype: archetype,
    stats: enemyCombatStats(
      tier: tier,
      archetype: archetype,
      catalogAttackDamage: attackDamage,
    ),
    id: id,
    name: name,
    idleAsset: '${base}_$idleAnimation.gif',
    walkAsset: '${base}_$walkAnimation.gif',
    hurtAsset: '${base}_Hurt.gif',
    attackAssets: List.unmodifiable(
      (_attackVariants[folder] ?? [attackAnimation]).map(
        (animation) => '${base}_$animation.gif',
      ),
    ),
    deathAsset: '${base}_Death.gif',
    attackAnimationDurationMs: attackAnimationDurationMs,
    deathAnimationDurationMs: deathAnimationDurationMs,
    attackDamage: attackDamage,
    questText: questText,
    minimumDailySteps: minimumDailySteps,
    xpReward: xpReward,
  );
}

class EnemyCatalog {
  EnemyCatalog._();

  /// All_Assets düşmanları zorluk sırasında. Her 500 adımda yeni
  /// bir karşılaşma açılır; aynı sprite'ı tekrar kullanan düşman yoktur.
  static final List<Enemy> enemies = [
    _enemy(
      id: 'ash_guardian',
      archetype: EnemyArchetype.tank,
      folder: 'Black Knight_A',
      name: 'Kül Muhafızı',
      questText:
          'Kül Muhafızı sessiz geçidi tuttu. İlk 500 adımınla zırhındaki mührü parçala!',
      minimumDailySteps: 500,
      attackDamage: 8,
      xpReward: 100,
    ),
    _enemy(
      id: 'night_oath',
      archetype: EnemyArchetype.bruiser,
      folder: 'Black Knight_B',
      name: 'Gece Yeminlisi',
      questText:
          'Gece Yeminlisi kılıcını ay ışığında kaldırdı. 1.000 adımlık ritmini bozmadan onu geride bırak!',
      minimumDailySteps: 1000,
      attackDamage: 9,
      xpReward: 175,
    ),
    _enemy(
      id: 'void_knight',
      archetype: EnemyArchetype.bruiser,
      folder: 'Black Knight_C',
      name: 'Hiçlik Şövalyesi',
      questText:
          'Hiçlik Şövalyesi yolun üzerine karanlık bir yarık açtı. 1.500 adımla mührü kapat!',
      minimumDailySteps: 1500,
      attackDamage: 10,
      xpReward: 250,
    ),
    _enemy(
      id: 'blood_weaver',
      archetype: EnemyArchetype.caster,
      folder: 'Blood Monster_A',
      name: 'Kan Dokuyan',
      questText:
          'Kan Dokuyan her tereddüdünden güç alıyor. 2.000 adım boyunca temponu koru ve ağını boz!',
      minimumDailySteps: 2000,
      attackDamage: 11,
      xpReward: 325,
      attackAnimationDurationMs: 800,
    ),
    _enemy(
      id: 'crimson_wing',
      archetype: EnemyArchetype.swift,
      folder: 'Blood Monster_B',
      name: 'Kızıl Kanat',
      questText:
          'Kızıl Kanat gökyüzünü kana boyadı. 2.500 adım at, gölgesinin dışına çık!',
      minimumDailySteps: 2500,
      attackDamage: 12,
      xpReward: 400,
      idleAnimation: 'Flying',
      walkAnimation: 'Flying',
      attackAnimationDurationMs: 800,
    ),
    _enemy(
      id: 'ember_siren',
      archetype: EnemyArchetype.caster,
      folder: 'Demoness_A',
      name: 'Kor Sireni',
      questText:
          'Kor Sireni ateşli ezgisiyle adımlarını yavaşlatıyor. 3.000 adımla büyüyü sustur!',
      minimumDailySteps: 3000,
      attackDamage: 13,
      xpReward: 500,
    ),
    _enemy(
      id: 'dusk_temptress',
      archetype: EnemyArchetype.swift,
      folder: 'Demoness_B',
      name: 'Alacakaranlık Cadısı',
      questText:
          'Alacakaranlık Cadısı patikayı sahte hayallerle kapladı. 3.500 gerçek adımla sisini dağıt!',
      minimumDailySteps: 3500,
      attackDamage: 14,
      xpReward: 600,
    ),
    _enemy(
      id: 'horned_executioner',
      archetype: EnemyArchetype.bruiser,
      folder: 'Demon_A',
      name: 'Boynuzlu Cellat',
      questText:
          'Boynuzlu Cellat baltasını yol taşına vurdu. 4.000 adımla meydan okumasını kabul et!',
      minimumDailySteps: 4000,
      attackDamage: 15,
      xpReward: 700,
    ),
    _enemy(
      id: 'infernal_sentinel',
      archetype: EnemyArchetype.tank,
      folder: 'Demon_B',
      name: 'Cehennem Nöbetçisi',
      questText:
          'Cehennem Nöbetçisi köprüyü ateşle çevirdi. 4.500 adımla alev çemberini yar!',
      minimumDailySteps: 4500,
      attackDamage: 16,
      xpReward: 800,
    ),
    _enemy(
      id: 'black_claw',
      archetype: EnemyArchetype.swift,
      folder: 'Demon_C',
      name: 'Kara Pençe',
      questText:
          'Kara Pençe izini buldu. 5.000 adım boyunca avcıdan hızlı ol ve karanlığı geride bırak!',
      minimumDailySteps: 5000,
      attackDamage: 17,
      xpReward: 900,
    ),
    _enemy(
      id: 'ember_heir',
      archetype: EnemyArchetype.bruiser,
      folder: 'Demon_D',
      name: 'Alev Tahtının Varisi',
      questText:
          'Alev Tahtının Varisi tacını savunuyor. 5.500 adımla krallığını sars!',
      minimumDailySteps: 5500,
      attackDamage: 18,
      xpReward: 1000,
    ),
    _enemy(
      id: 'abyss_overlord',
      archetype: EnemyArchetype.caster,
      folder: 'Demon_E',
      name: 'Uçurum Hükümdarı',
      questText:
          'Uçurum Hükümdarı dönüş yolunu yuttu. 6.000 adımla kendi geçidini aç!',
      minimumDailySteps: 6000,
      attackDamage: 19,
      xpReward: 1150,
    ),
    _enemy(
      id: 'eye_of_nothing',
      archetype: EnemyArchetype.caster,
      folder: 'Eyeball Monster',
      name: 'Hiçliğin Gözü',
      questText:
          'Hiçliğin Gözü her adımını izliyor. 6.500 adımla bakışını yere indir!',
      minimumDailySteps: 6500,
      attackDamage: 12,
      xpReward: 1300,
    ),
    _enemy(
      id: 'cinder_colossus',
      archetype: EnemyArchetype.tank,
      folder: 'Flame Golem',
      name: 'Köz Devi',
      questText:
          'Köz Devi her darbede dağı uyandırıyor. 7.000 adımla taş kalbini soğut!',
      minimumDailySteps: 7000,
      attackDamage: 21,
      xpReward: 1450,
    ),
    _enemy(
      id: 'spirit_flame',
      archetype: EnemyArchetype.swift,
      folder: 'Ghostfire',
      name: 'Ruh Alevi',
      questText:
          'Ruh Alevi sönmeyen bir iz gibi peşinde. 7.500 adımla lanetli ateşi tüket!',
      minimumDailySteps: 7500,
      attackDamage: 22,
      xpReward: 1600,
      idleAnimation: 'Flying',
      walkAnimation: 'Flying',
    ),
    _enemy(
      id: 'hell_wing',
      archetype: EnemyArchetype.swift,
      folder: 'Hellbat',
      name: 'Cehennem Kanadı',
      questText:
          'Cehennem Kanadı göğü kararttı. 8.000 adımla kanatlarının altından şafağa ulaş!',
      minimumDailySteps: 8000,
      attackDamage: 23,
      xpReward: 1800,
      idleAnimation: 'Flying',
      walkAnimation: 'Flying',
    ),
    _enemy(
      id: 'ash_fang',
      archetype: EnemyArchetype.bruiser,
      folder: 'Hellhound',
      name: 'Kül Diş',
      questText:
          'Kül Diş kokunu aldı ve av başladı. 8.500 adımla cehennem tazısını yıprat!',
      minimumDailySteps: 8500,
      attackDamage: 24,
      xpReward: 2000,
    ),
    _enemy(
      id: 'magma_devourer',
      archetype: EnemyArchetype.tank,
      folder: 'Lava Slime',
      name: 'Magma Yutan',
      questText:
          'Magma Yutan bastığın zemini eritiyor. 9.000 adımla lav denizinin önüne geç!',
      minimumDailySteps: 9000,
      attackDamage: 25,
      xpReward: 2200,
    ),
    _enemy(
      id: 'maze_butcher',
      archetype: EnemyArchetype.bruiser,
      folder: 'Minotaur',
      name: 'Labirent Kasabı',
      questText:
          'Labirent Kasabı çıkışını bekliyor. 9.500 adımla duvarlardan önce iradesini yık!',
      minimumDailySteps: 9500,
      attackDamage: 27,
      xpReward: 2450,
    ),
    _enemy(
      id: 'lord_of_last_seal',
      archetype: EnemyArchetype.caster,
      folder: 'Warlock',
      name: 'Son Mührün Efendisi',
      questText:
          'Son Mührün Efendisi yolculuğunun sonuna karanlık imzasını attı. 10.000 adımla mührü sonsuza dek kır!',
      minimumDailySteps: 10000,
      attackDamage: 30,
      xpReward: 2750,
      attackAnimationDurationMs: 850,
      deathAnimationDurationMs: 800,
    ),
  ];

  /// Eski sürümde başlatılmış maceralar yeni kataloğa taşınır.
  static const _legacyIds = {
    'border_scout': 'ash_guardian',
    'forest_raider': 'ash_fang',
    'blood_apprentice': 'blood_weaver',
    'tense_soldier': 'ash_guardian',
    'sinister_monster': 'eye_of_nothing',
    'blood_monster': 'blood_weaver',
    'demon': 'horned_executioner',
  };

  static Enemy? byId(String id) {
    final resolvedId = _legacyIds[id] ?? id;
    for (final enemy in enemies) {
      if (enemy.id == resolvedId) return enemy;
    }
    return null;
  }
}
