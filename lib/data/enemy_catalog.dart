import '../models/enemy.dart';

class EnemyCatalog {
  EnemyCatalog._();

  static const enemies = [
    Enemy(
      id: 'tense_soldier',
      name: 'Gergin Asker',
      idleAsset: 'lib/Enemies/Gergin Asker/Soldier_Idle.gif',
      walkAsset: 'lib/Enemies/Gergin Asker/Soldier_Walk.gif',
      hurtAsset: 'lib/Enemies/Gergin Asker/Soldier_Hurt.gif',
      attackAsset: 'lib/Enemies/Gergin Asker/Soldier_Attack01.gif',
      deathAsset: 'lib/Enemies/Gergin Asker/Soldier_Death.gif',
      attackAnimationDurationMs: 540,
      deathAnimationDurationMs: 640,
      attackDamage: 8,
      questText:
          'Gergin Asker yolunu kesmeye hazır. Korkusunun seni yavaşlatmasına '
          'izin verme; ritmini koru ve asla pes etme!',
      minimumDailySteps: 2000,
      xpReward: 300,
    ),
    Enemy(
      id: 'sinister_monster',
      name: 'Tekinsiz Canavar!',
      idleAsset: 'lib/Enemies/Tekinsiz Canavar!/Orc_Idle.gif',
      walkAsset: 'lib/Enemies/Tekinsiz Canavar!/Orc_Walk.gif',
      hurtAsset: 'lib/Enemies/Tekinsiz Canavar!/Orc_Hurt.gif',
      attackAsset: 'lib/Enemies/Tekinsiz Canavar!/Orc_Attack01.gif',
      deathAsset: 'lib/Enemies/Tekinsiz Canavar!/Orc_Death.gif',
      attackAnimationDurationMs: 540,
      deathAnimationDurationMs: 640,
      attackDamage: 12,
      questText:
          'Tekinsiz Canavar’a dikkat et; enerjini emmeye çalışabilir. Her '
          'adımda gücünü geri kazan, yolundan dönme ve asla pes etme!',
      minimumDailySteps: 5000,
      xpReward: 750,
    ),
    Enemy(
      id: 'blood_monster',
      name: 'Kana Susamış Canavar',
      idleAsset: 'lib/Enemies/Blood_Monster_A_GIFs/Blood Monster_A_Idle.gif',
      walkAsset: 'lib/Enemies/Blood_Monster_A_GIFs/Blood Monster_A_Walk.gif',
      hurtAsset: 'lib/Enemies/Blood_Monster_A_GIFs/Blood Monster_A_Hurt.gif',
      attackAsset:
          'lib/Enemies/Blood_Monster_A_GIFs/Blood Monster_A_Attack01.gif',
      deathAsset: 'lib/Enemies/Blood_Monster_A_GIFs/Blood Monster_A_Death.gif',
      attackAnimationDurationMs: 800,
      deathAnimationDurationMs: 560,
      attackDamage: 16,
      questText:
          'Kana Susamış Canavar karşında. Cesaretini topla, adımlarınla '
          'gücünü tüket ve karanlığa boyun eğme!',
      minimumDailySteps: 7000,
      xpReward: 1100,
    ),
    Enemy(
      id: 'demon',
      name: 'Şişli Şeytan',
      idleAsset: 'lib/Enemies/Demon_A_GIFs/Demon_A_Idle.gif',
      walkAsset: 'lib/Enemies/Demon_A_GIFs/Demon_A_Walk.gif',
      hurtAsset: 'lib/Enemies/Demon_A_GIFs/Demon_A_Hurt.gif',
      attackAsset: 'lib/Enemies/Demon_A_GIFs/Demon_A_Attack01.gif',
      deathAsset: 'lib/Enemies/Demon_A_GIFs/Demon_A_Death.gif',
      attackAnimationDurationMs: 700,
      deathAnimationDurationMs: 560,
      attackDamage: 20,
      questText:
          'Şişli Şeytan yoluna dikildi. Temponu koru, her adımda onu '
          'zayıflat ve zafere doğru ilerle!',
      minimumDailySteps: 10000,
      xpReward: 1500,
    ),
  ];

  /// Kayıtlı maceranın düşmanını kimliğinden geri bulur.
  static Enemy? byId(String id) {
    for (final enemy in enemies) {
      if (enemy.id == id) return enemy;
    }
    return null;
  }
}
