import '../core/constants/game_constants.dart';
import '../models/game_title.dart';
import '../models/item_effect.dart';
import '../models/reward_rarity.dart';

/// Ünvanların tanımı (Bölüm C).
///
/// **Bu dosya veridir, kod değil.** Hiçbir yerde `switch (title.id)` yok;
/// çözümleme [TitleCatalog.byId] üzerinden yapılır ve etkiler [ItemEffect]
/// listesi olarak taşınır. Aynı desen `data/item_effects.dart` içinde
/// kullanılıyor.
///
/// ## Tasarım kuralı: düz stat artışı yok
///
/// Her ünvanın bir **karakteri** var: ya bir tetikleyiciye bağlı
/// ([ItemEffectTrigger]), ya bir eşiğe, ya da iki uçlu (bir artı bir eksi).
/// Koşulsuz bir "+%10 saldırı" ünvanı bilerek yazılmadı — böyle bir ünvan
/// eşyadan ayrışmaz ve takma kararı "hangi sayı büyük"e iner.
///
/// ## Ekonomi sınırı
///
/// Ekonomiye dokunan koşulsuz oran hiçbir ünvanda
/// [GameConstants.maxTitleEconomyBonus] (+%25) değerini geçmez; testle
/// bağlıdır. Kuşanılan **toplam** ise `EquippedBuffs.from` içinde sert
/// kırpmaya tabi (+%50), yani ünvan + eşya birlikte bile tavanı aşamaz.
/// Koşullu etkiler (gece yürüyüşü, seri ayaktayken) çarpana hiç girmez —
/// [ItemEffect.isPassive] yalnızca koşulsuz ve tam ihtimalli etkileri sayar.
abstract final class TitleCatalog {
  /// Katalogdaki bütün ünvanlar. Sıra: nadirlik, sonra tanım sırası.
  static const List<GameTitle> all = [
    // ---------------------------------------------------------------
    // SIRADAN — erken oyuna eşlik eden, küçük ama karakterli ünvanlar
    // ---------------------------------------------------------------
    GameTitle(
      id: 'first_step',
      name: 'İlk Adım',
      lore: 'Her yolculuk aynı yerden başlar: ayağını kaldırdığın andan.',
      rarity: RewardRarity.common,
      source: TitleSource.achievement,
      condition: TitleCondition.totalSteps,
      conditionThreshold: 5000,
      effects: [
        ItemEffect(
          stat: ItemStat.stepXp,
          value: 0.10,
          customLabel: 'günün ilk yürüyüşünde adım XP +%10',
          customLabelEn: 'on your first walk of the day, step XP +10%',
          trigger: ItemEffectTrigger.streakActive,
        ),
      ],
    ),
    GameTitle(
      id: 'night_walker',
      name: 'Gece Yürüyüşçüsü',
      lore: 'Şehir uyurken sokaklar sana kalır.',
      rarity: RewardRarity.common,
      source: TitleSource.purchase,
      cost: 900,
      effects: [
        ItemEffect(
          stat: ItemStat.stepCoin,
          value: 0.25,
          trigger: ItemEffectTrigger.nightWalk,
          customLabel: 'gece yürüyüşlerinde adım parası +%25',
          customLabelEn: 'on night walks, step coins +25%',
        ),
      ],
    ),
    GameTitle(
      id: 'dawn_hunter',
      name: 'Şafak Avcısı',
      lore: 'Güneşten önce kalkan, günü kendi kurar.',
      rarity: RewardRarity.common,
      source: TitleSource.purchase,
      cost: 900,
      effects: [
        ItemEffect(
          stat: ItemStat.stepXp,
          value: 0.20,
          trigger: ItemEffectTrigger.streakActive,
          customLabel: 'serin ayaktayken adım XP +%20',
          customLabelEn: 'while your streak is active, step XP +20%',
        ),
      ],
    ),
    GameTitle(
      id: 'stubborn_boot',
      name: 'İnatçı Çizme',
      lore: 'Tabanı delik, sahibi kararlı.',
      rarity: RewardRarity.common,
      source: TitleSource.achievement,
      condition: TitleCondition.adventuresCompleted,
      conditionThreshold: 3,
      effects: [
        ItemEffect.flat(
          stat: ItemStat.streakRelief,
          value: 250,
          customLabel: 'seri eşiği 250 adım düşer',
          customLabelEn: 'streak threshold drops by 250 steps',
        ),
      ],
    ),
    GameTitle(
      id: 'coin_sniffer',
      name: 'Bozukluk Koklayan',
      lore: 'Kaldırım taşlarının arasına bakmayı asla bırakmadı.',
      rarity: RewardRarity.common,
      source: TitleSource.achievement,
      condition: TitleCondition.lifetimeCoins,
      conditionThreshold: 1000,
      effects: [
        ItemEffect(
          stat: ItemStat.stepCoin,
          value: 0.08,
          customLabel: 'adım parası +%8',
          customLabelEn: 'step coins +8%',
        ),
        ItemEffect(
          stat: ItemStat.stepXp,
          value: -0.05,
          customLabel: 'ama adım XP -%5',
          customLabelEn: 'but step XP -5%',
        ),
      ],
    ),
    GameTitle(
      id: 'lost_map',
      name: 'Kayıp Haritalı',
      lore: 'Nereye gittiğini bilmiyor ama çok yürüyor.',
      rarity: RewardRarity.common,
      source: TitleSource.wheel,
      effects: [
        ItemEffect(
          stat: ItemStat.wheelXp,
          value: 0.15,
          customLabel: 'çark XP +%15',
          customLabelEn: 'wheel XP +15%',
        ),
      ],
    ),
    GameTitle(
      id: 'bruised_knuckle',
      name: 'Morarmış Yumruk',
      lore: 'Kazanmayı değil, durmamayı öğrendi.',
      rarity: RewardRarity.common,
      source: TitleSource.achievement,
      condition: TitleCondition.enemiesDefeated,
      conditionThreshold: 5,
      effects: [
        ItemEffect(
          stat: ItemStat.attack,
          value: 0.25,
          trigger: ItemEffectTrigger.lowHealth,
          threshold: 0.35,
          customLabel: 'can %35 altındayken saldırı +%25',
          customLabelEn: 'while below 35% HP, attack +25%',
        ),
      ],
    ),
    GameTitle(
      id: 'patient_one',
      name: 'Sabırlı',
      lore: 'Beklemek de bir hamledir.',
      rarity: RewardRarity.common,
      source: TitleSource.purchase,
      cost: 1100,
      effects: [
        ItemEffect.flat(
          stat: ItemStat.wheelSpinCap,
          value: 1,
          customLabel: 'çark hakkı stoğu +1',
          customLabelEn: 'wheel-spin capacity +1',
        ),
      ],
    ),
    GameTitle(
      id: 'clumsy_apprentice',
      name: 'Sakar Çırak',
      lore: 'Kırdığı her şeyden bir şey öğrendi.',
      rarity: RewardRarity.common,
      source: TitleSource.achievement,
      condition: TitleCondition.ownedItemCount,
      conditionThreshold: 5,
      effects: [
        ItemEffect(
          stat: ItemStat.critChance,
          value: 0.35,
          customLabel: 'kritik şansı +%35',
          customLabelEn: 'critical chance +35%',
        ),
        ItemEffect(
          stat: ItemStat.critDamage,
          value: -0.25,
          customLabel: 'ama kritik hasarı -%25',
          customLabelEn: 'but critical damage -25%',
        ),
      ],
    ),
    GameTitle(
      id: 'stray_dog_friend',
      name: 'Sokak Köpeği Dostu',
      lore: 'Yolda hep birileri ona eşlik ediyor.',
      rarity: RewardRarity.common,
      source: TitleSource.wheel,
      effects: [
        ItemEffect(
          stat: ItemStat.dodge,
          value: 0.3,
          trigger: ItemEffectTrigger.untouchedRounds,
          threshold: 2,
          customLabel: '2 tur hasarsız kalınca sıyrılma +%30',
          customLabelEn: 'after 2 damage-free rounds, dodge +30%',
        ),
      ],
    ),

    // ---------------------------------------------------------------
    // AZ BULUNUR — oyunun ilk haftalarını taşıyan ünvanlar
    // ---------------------------------------------------------------
    GameTitle(
      id: 'iron_heart',
      name: 'Demir Yürek',
      lore: 'Kanaması durmadı ama adımı da durmadı.',
      rarity: RewardRarity.uncommon,
      source: TitleSource.achievement,
      condition: TitleCondition.enemiesDefeated,
      conditionThreshold: 25,
      effects: [
        ItemEffect(
          stat: ItemStat.defense,
          value: 0.75,
          trigger: ItemEffectTrigger.lowHealth,
          threshold: 0.20,
          customLabel: 'can %20 altına düşünce savunma +%75',
          customLabelEn: 'when HP drops below 20%, defense +75%',
        ),
      ],
    ),
    GameTitle(
      id: 'collector',
      name: 'Koleksiyoner',
      lore: 'Sandığı doldu, evi taştı, hâlâ topluyor.',
      rarity: RewardRarity.uncommon,
      source: TitleSource.achievement,
      condition: TitleCondition.ownedItemCount,
      conditionThreshold: 20,
      effects: [
        ItemEffect(
          stat: ItemStat.luck,
          value: 0.45,
          customLabel: 'şans +%45 — envanterin ne kadar doluysa o kadar hazır',
          customLabelEn: 'luck +45% — the fuller your inventory, the readier you are',
        ),
      ],
    ),
    GameTitle(
      id: 'marathoner',
      name: 'Maratoncu',
      lore: 'Bitiş çizgisi diye bir şey olduğuna inanmıyor.',
      rarity: RewardRarity.uncommon,
      source: TitleSource.achievement,
      condition: TitleCondition.totalSteps,
      conditionThreshold: 100000,
      effects: [
        ItemEffect(
          stat: ItemStat.enemyXp,
          value: 0.25,
          customLabel: 'düşman XP +%25',
          customLabelEn: 'enemy XP +25%',
        ),
      ],
    ),
    GameTitle(
      id: 'bloody_victory',
      name: 'Kanlı Zafer',
      lore: 'Kazandığı her savaştan biraz daha az kan kaybederek çıkıyor.',
      rarity: RewardRarity.uncommon,
      source: TitleSource.purchase,
      cost: 2400,
      effects: [
        ItemEffect(
          stat: ItemStat.lifeSteal,
          value: 0.55,
          trigger: ItemEffectTrigger.onKill,
          customLabel: 'düşman yenince kaybettiğin canın %55\'i geri gelir',
          customLabelEn: 'after defeating an enemy, you recover 55% of the HP you lost',
        ),
      ],
    ),
    GameTitle(
      id: 'unlucky_explorer',
      name: 'Şanssız Kâşif',
      lore: 'Az bulur ama bulduğu şey hep değerli çıkar.',
      rarity: RewardRarity.uncommon,
      source: TitleSource.purchase,
      cost: 2400,
      effects: [
        ItemEffect(
          stat: ItemStat.wheelXp,
          value: 0.40,
          customLabel: 'çark XP +%40',
          customLabelEn: 'wheel XP +40%',
        ),
        ItemEffect(
          stat: ItemStat.stepCoin,
          value: -0.10,
          customLabel: 'ama adım parası -%10',
          customLabelEn: 'but step coins -10%',
        ),
      ],
    ),
    GameTitle(
      id: 'frost_keeper',
      name: 'Buz Bekçisi',
      lore: 'Kaçırdığı günü buzda saklıyor.',
      rarity: RewardRarity.uncommon,
      source: TitleSource.milestone,
      milestoneDay: 7,
      effects: [
        ItemEffect.flat(
          stat: ItemStat.streakFreezeCap,
          value: 1,
          customLabel: 'dondurma stoğu +1',
          customLabelEn: 'freeze capacity +1',
        ),
        ItemEffect.flat(
          stat: ItemStat.streakRelief,
          value: 400,
          customLabel: 'seri eşiği 400 adım düşer',
          customLabelEn: 'streak threshold drops by 400 steps',
        ),
      ],
    ),
    GameTitle(
      id: 'quiet_step',
      name: 'Sessiz Adım',
      lore: 'Kimse geldiğini duymuyor. Gittiğini de.',
      rarity: RewardRarity.uncommon,
      source: TitleSource.wheel,
      effects: [
        ItemEffect(
          stat: ItemStat.speed,
          value: 0.5,
          trigger: ItemEffectTrigger.nightWalk,
          customLabel: 'gece yürüyüşlerinde hız +%50',
          customLabelEn: 'on night walks, speed +50%',
        ),
        ItemEffect(
          stat: ItemStat.dodge,
          value: 0.25,
          trigger: ItemEffectTrigger.nightWalk,
          customLabel: 've sıyrılma +%25',
          customLabelEn: 'and dodge +25%',
        ),
      ],
    ),
    GameTitle(
      id: 'blacksmiths_regular',
      name: 'Demircinin Müdavimi',
      lore: 'Örsün sesi ona ninni gibi geliyor.',
      rarity: RewardRarity.uncommon,
      source: TitleSource.achievement,
      condition: TitleCondition.itemsMerged,
      conditionThreshold: 3,
      effects: [
        ItemEffect.flat(
          stat: ItemStat.attack,
          value: 22,
          trigger: ItemEffectTrigger.untouchedRounds,
          threshold: 1,
          customLabel: 'bir tur hasarsız kalınca saldırı +22',
          customLabelEn: 'after one damage-free round, attack +22',
        ),
      ],
    ),
    GameTitle(
      id: 'wheel_addict',
      name: 'Çark Tutkunu',
      lore: 'Sabahları çarkı çevirmeden kahvaltı etmiyor.',
      rarity: RewardRarity.uncommon,
      source: TitleSource.achievement,
      condition: TitleCondition.wheelSpins,
      conditionThreshold: 15,
      effects: [
        ItemEffect(
          stat: ItemStat.wheelXp,
          value: 0.25,
          customLabel: 'çark XP +%25',
          customLabelEn: 'wheel XP +25%',
        ),
        ItemEffect.flat(
          stat: ItemStat.wheelSpinCap,
          value: 1,
          customLabel: 've çark hakkı stoğu +1',
          customLabelEn: 'and wheel-spin capacity +1',
        ),
      ],
    ),
    GameTitle(
      id: 'road_reader',
      name: 'Yol Okuyucu',
      lore: 'Toprağa bakıp kimin geçtiğini söyleyebiliyor.',
      rarity: RewardRarity.uncommon,
      source: TitleSource.achievement,
      condition: TitleCondition.adventuresCompleted,
      conditionThreshold: 15,
      effects: [
        ItemEffect(
          stat: ItemStat.critChance,
          value: 0.45,
          trigger: ItemEffectTrigger.highHealth,
          threshold: 0.80,
          customLabel: 'can %80 üstündeyken kritik şansı +%45',
          customLabelEn: 'while above 80% HP, critical chance +45%',
        ),
      ],
    ),
    GameTitle(
      id: 'rust_eater',
      name: 'Pas Yiyen',
      lore: 'Kırık bir kılıcı bile işe yarar hâle getiriyor.',
      rarity: RewardRarity.uncommon,
      source: TitleSource.achievement,
      condition: TitleCondition.maxItemLevel,
      conditionThreshold: 5,
      effects: [
        ItemEffect(
          stat: ItemStat.attack,
          value: 0.3,
          customLabel: 'saldırı +%30',
          customLabelEn: 'attack +30%',
        ),
        ItemEffect(
          stat: ItemStat.dodge,
          value: -0.2,
          customLabel: 'ama sıyrılma -%20 — ağır çelik hızlı dönmez',
          customLabelEn: 'but dodge -20% — heavy steel does not turn quickly',
        ),
      ],
    ),
    GameTitle(
      id: 'lantern_bearer',
      name: 'Fener Taşıyan',
      lore: 'Karanlıkta yürüyen herkesin gördüğü tek ışık.',
      rarity: RewardRarity.uncommon,
      source: TitleSource.purchase,
      cost: 2600,
      effects: [
        ItemEffect(
          stat: ItemStat.stepXp,
          value: 0.30,
          trigger: ItemEffectTrigger.nightWalk,
          customLabel: 'gece yürüyüşlerinde adım XP +%30',
          customLabelEn: 'on night walks, step XP +30%',
        ),
        ItemEffect(
          stat: ItemStat.stepCoin,
          value: 0.15,
          trigger: ItemEffectTrigger.nightWalk,
          customLabel: 've adım parası +%15',
          customLabelEn: 'and step coins +15%',
        ),
      ],
    ),

    // ---------------------------------------------------------------
    // NADİR — oyunun ortası: gerçekten bir tarz seçtiren ünvanlar
    // ---------------------------------------------------------------
    GameTitle(
      id: 'villain_hunter',
      name: 'Kötü Ruh Avcısı',
      lore: 'Adı korkuyu değil, borcu hatırlatıyor.',
      rarity: RewardRarity.rare,
      source: TitleSource.purchase,
      cost: 5200,
      effects: [
        ItemEffect(
          stat: ItemStat.enemyXp,
          value: 0.20,
          customLabel: 'düşman XP +%20',
          customLabelEn: 'enemy XP +20%',
        ),
        ItemEffect(
          stat: ItemStat.attack,
          value: 0.4,
          trigger: ItemEffectTrigger.onKill,
          customLabel: 've düşman yenince sonraki vuruş +%40 saldırı taşır',
          customLabelEn: 'and after a kill, your next strike carries +40% attack',
        ),
      ],
    ),
    GameTitle(
      id: 'hundred_scars',
      name: 'Yüz Yara',
      lore: 'Her yara bir düşmanın adını taşıyor.',
      rarity: RewardRarity.rare,
      source: TitleSource.achievement,
      condition: TitleCondition.enemiesDefeated,
      conditionThreshold: 100,
      effects: [
        ItemEffect(
          stat: ItemStat.maxHealth,
          value: 0.45,
          customLabel: 'savaş canı +%45',
          customLabelEn: 'combat HP +45%',
        ),
        ItemEffect(
          stat: ItemStat.lifeSteal,
          value: 0.3,
          trigger: ItemEffectTrigger.lowHealth,
          threshold: 0.40,
          customLabel: 'can %40 altındayken can çalma +%30',
          customLabelEn: 'while below 40% HP, life steal +30%',
        ),
      ],
    ),
    GameTitle(
      id: 'thirty_dawns',
      name: 'Otuz Şafak',
      lore: 'Otuz sabah üst üste aynı sözü tuttu.',
      rarity: RewardRarity.rare,
      source: TitleSource.milestone,
      milestoneDay: 30,
      effects: [
        ItemEffect(
          stat: ItemStat.attack,
          value: 0.4,
          trigger: ItemEffectTrigger.streakActive,
          customLabel: 'serin ayaktayken saldırı +%40',
          customLabelEn: 'while your streak is active, attack +40%',
        ),
        ItemEffect(
          stat: ItemStat.defense,
          value: 0.4,
          trigger: ItemEffectTrigger.streakActive,
          customLabel: 've savunma +%40',
          customLabelEn: 'and defense +40%',
        ),
      ],
    ),
    GameTitle(
      id: 'glass_cannon',
      name: 'Cam Top',
      lore: 'Bir vuruş yeter. Kimin vurduğu önemli.',
      rarity: RewardRarity.rare,
      source: TitleSource.purchase,
      cost: 5200,
      effects: [
        // Saldırı ve can **aynı sabitten** türüyor: ünvanın sözü "ne kadar
        // vurursan o kadar kırılgansın". Ayrı yazıldığında biri değişip
        // diğeri unutulmuştu (+%70 saldırıya karşılık yalnızca −%30 can).
        ItemEffect(
          stat: ItemStat.attack,
          value: GameConstants.glassCannonPercent / 100,
          customLabel: 'saldırı +%${GameConstants.glassCannonPercent}',
          customLabelEn: 'attack +${GameConstants.glassCannonPercent}%',
        ),
        ItemEffect(
          stat: ItemStat.maxHealth,
          value: -GameConstants.glassCannonPercent / 100,
          customLabel: 'ama savaş canı -%${GameConstants.glassCannonPercent}',
          customLabelEn:
              'but combat HP -${GameConstants.glassCannonPercent}%',
        ),
      ],
    ),
    GameTitle(
      id: 'untouchable',
      name: 'Dokunulmaz',
      lore: 'Vurmaya çalışanların hepsi havayı dövdü.',
      rarity: RewardRarity.rare,
      source: TitleSource.achievement,
      condition: TitleCondition.adventuresCompleted,
      conditionThreshold: 50,
      effects: [
        ItemEffect(
          stat: ItemStat.dodge,
          value: 0.65,
          trigger: ItemEffectTrigger.untouchedRounds,
          threshold: 3,
          customLabel: '3 tur hasarsız kalınca sıyrılma +%65',
          customLabelEn: 'after 3 damage-free rounds, dodge +65%',
        ),
        ItemEffect(
          stat: ItemStat.speed,
          value: 0.4,
          trigger: ItemEffectTrigger.untouchedRounds,
          threshold: 3,
          customLabel: 've hız +%40',
          customLabelEn: 'and speed +40%',
        ),
      ],
    ),
    GameTitle(
      id: 'gold_tongue',
      name: 'Altın Dilli',
      lore: 'Pazarlıkta kaybettiği tek şey zaman.',
      rarity: RewardRarity.rare,
      source: TitleSource.achievement,
      condition: TitleCondition.lifetimeCoins,
      conditionThreshold: 50000,
      effects: [
        ItemEffect(
          stat: ItemStat.stepCoin,
          value: 0.22,
          customLabel: 'adım parası +%22',
          customLabelEn: 'step coins +22%',
        ),
      ],
    ),
    GameTitle(
      id: 'anvil_son',
      name: 'Örsün Oğlu',
      lore: 'Demirci ona ustalık değil, sabır öğretti.',
      rarity: RewardRarity.rare,
      source: TitleSource.achievement,
      condition: TitleCondition.maxItemLevel,
      conditionThreshold: 15,
      effects: [
        ItemEffect.flat(
          stat: ItemStat.attack,
          value: 44,
          customLabel: 'saldırı +44',
          customLabelEn: 'attack +44',
        ),
        ItemEffect.flat(
          stat: ItemStat.defense,
          value: 29,
          customLabel: 've savunma +29',
          customLabelEn: 'and defense +29',
        ),
        ItemEffect(
          stat: ItemStat.speed,
          value: -0.25,
          customLabel: 'ama hız -%25',
          customLabelEn: 'but speed -25%',
        ),
      ],
    ),
    GameTitle(
      id: 'moon_pact',
      name: 'Ay Anlaşması',
      lore: 'Gece ona yol veriyor, karşılığında gündüzü alıyor.',
      rarity: RewardRarity.rare,
      source: TitleSource.wheel,
      effects: [
        ItemEffect(
          stat: ItemStat.stepCoin,
          value: 0.25,
          trigger: ItemEffectTrigger.nightWalk,
          customLabel: 'gece yürüyüşlerinde adım parası +%25',
          customLabelEn: 'on night walks, step coins +25%',
        ),
        ItemEffect(
          stat: ItemStat.critDamage,
          value: 0.8,
          trigger: ItemEffectTrigger.nightWalk,
          customLabel: 've kritik hasarı +%80',
          customLabelEn: 'and critical damage +80%',
        ),
      ],
    ),
    GameTitle(
      id: 'first_light',
      name: 'İlk Işık',
      lore: 'Karanlıkta doğdu ama hep sabaha yürüdü.',
      rarity: RewardRarity.rare,
      source: TitleSource.achievement,
      condition: TitleCondition.longestStreak,
      conditionThreshold: 21,
      effects: [
        ItemEffect(
          stat: ItemStat.maxHealth,
          value: 0.4,
          trigger: ItemEffectTrigger.streakActive,
          customLabel: 'serin ayaktayken savaş canı +%40',
          customLabelEn: 'while your streak is active, combat HP +40%',
        ),
        ItemEffect(
          stat: ItemStat.luck,
          value: 0.3,
          trigger: ItemEffectTrigger.streakActive,
          customLabel: 've şans +%30',
          customLabelEn: 'and luck +30%',
        ),
      ],
    ),
    GameTitle(
      id: 'gambler',
      name: 'Kumarbaz',
      lore: 'Her turu son turu gibi oynuyor. Bazen öyle oluyor.',
      rarity: RewardRarity.rare,
      source: TitleSource.purchase,
      cost: 5600,
      effects: [
        ItemEffect(
          stat: ItemStat.critDamage,
          value: 1.15,
          trigger: ItemEffectTrigger.onHit,
          chance: 0.25,
          customLabel: 'vuruşta %25 ihtimalle kritik hasarı +%115',
          customLabelEn: '25% chance on hit: critical damage +115%',
        ),
        ItemEffect(
          stat: ItemStat.defense,
          value: -0.25,
          customLabel: 'ama savunma -%25',
          customLabelEn: 'but defense -25%',
        ),
      ],
    ),
    GameTitle(
      id: 'ten_thousand_steps',
      name: 'On Bin Adım',
      lore: 'Sayıyı hedef değil, alışkanlık yaptı.',
      rarity: RewardRarity.rare,
      source: TitleSource.achievement,
      condition: TitleCondition.totalSteps,
      conditionThreshold: 500000,
      effects: [
        ItemEffect(
          stat: ItemStat.stepXp,
          value: 0.20,
          customLabel: 'adım XP +%20',
          customLabelEn: 'step XP +20%',
        ),
        ItemEffect.flat(
          stat: ItemStat.streakRelief,
          value: 600,
          customLabel: 've seri eşiği 600 adım düşer',
          customLabelEn: 'and streak threshold drops by 600 steps',
        ),
      ],
    ),
    GameTitle(
      id: 'bear_stubborn',
      name: 'Ayı İnadı',
      lore: 'Yerinden oynatmak için kış lazım.',
      rarity: RewardRarity.rare,
      source: TitleSource.wheel,
      effects: [
        ItemEffect(
          stat: ItemStat.defense,
          value: 0.6,
          customLabel: 'savunma +%60',
          customLabelEn: 'defense +60%',
        ),
        ItemEffect(
          stat: ItemStat.speed,
          value: -0.3,
          customLabel: 'ama hız -%30',
          customLabelEn: 'but speed -30%',
        ),
      ],
    ),

    // ---------------------------------------------------------------
    // EPİK — uzun oynamanın karşılığı
    // ---------------------------------------------------------------
    GameTitle(
      id: 'hundred_dawns',
      name: 'Yüz Şafak',
      lore: 'Yüz sabah aynı yola çıktı ve yol onu tanıdı.',
      rarity: RewardRarity.epic,
      source: TitleSource.milestone,
      milestoneDay: 100,
      effects: [
        ItemEffect(
          stat: ItemStat.attack,
          value: 0.55,
          trigger: ItemEffectTrigger.streakActive,
          customLabel: 'serin ayaktayken saldırı +%55',
          customLabelEn: 'while your streak is active, attack +55%',
        ),
        ItemEffect(
          stat: ItemStat.maxHealth,
          value: 0.55,
          trigger: ItemEffectTrigger.streakActive,
          customLabel: ', savaş canı +%55',
          customLabelEn: ', combat HP +55%',
        ),
        ItemEffect.flat(
          stat: ItemStat.streakFreezeCap,
          value: 1,
          customLabel: 've dondurma stoğu +1',
          customLabelEn: 'and freeze capacity +1',
        ),
      ],
    ),
    GameTitle(
      id: 'last_breath',
      name: 'Son Nefes',
      lore: 'Düştüğünü sananlar hep aynı hatayı yapıyor.',
      rarity: RewardRarity.epic,
      source: TitleSource.achievement,
      condition: TitleCondition.enemiesDefeated,
      conditionThreshold: 300,
      effects: [
        ItemEffect(
          stat: ItemStat.attack,
          value: 1.35,
          trigger: ItemEffectTrigger.lowHealth,
          threshold: 0.15,
          customLabel: 'can %15 altına düşünce saldırı ikiye katlanır',
          customLabelEn: 'when HP drops below 15%, attack doubles',
        ),
        ItemEffect(
          stat: ItemStat.lifeSteal,
          value: 0.55,
          trigger: ItemEffectTrigger.lowHealth,
          threshold: 0.15,
          customLabel: 've can çalma +%55',
          customLabelEn: 'and life steal +55%',
        ),
      ],
    ),
    GameTitle(
      id: 'blade_dancer',
      name: 'Bıçak Dansçısı',
      lore: 'Vuruşları sayılmıyor, ritmi sayılıyor.',
      rarity: RewardRarity.epic,
      source: TitleSource.purchase,
      cost: 12000,
      effects: [
        ItemEffect(stat: ItemStat.speed, value: 0.55, customLabel: 'hız +%55'),
        ItemEffect(
          stat: ItemStat.critChance,
          value: 0.55,
          trigger: ItemEffectTrigger.untouchedRounds,
          threshold: 2,
          customLabel: '2 tur hasarsız kalınca kritik şansı +%55',
          customLabelEn: 'after 2 damage-free rounds, critical chance +55%',
        ),
        ItemEffect(
          stat: ItemStat.defense,
          value: -0.35,
          customLabel: 'ama savunma -%35',
          customLabelEn: 'but defense -35%',
        ),
      ],
    ),
    GameTitle(
      id: 'hoarder_king',
      name: 'Yığın Kralı',
      lore: 'Sandıkları taştı, kapıları kapanmıyor.',
      rarity: RewardRarity.epic,
      source: TitleSource.achievement,
      condition: TitleCondition.ownedItemCount,
      conditionThreshold: 80,
      effects: [
        ItemEffect(stat: ItemStat.luck, value: 0.60, customLabel: 'şans +%60'),
        ItemEffect(
          stat: ItemStat.stepCoin,
          value: 0.18,
          customLabel: 've adım parası +%18',
          customLabelEn: 'and step coins +18%',
        ),
      ],
    ),
    GameTitle(
      id: 'forge_master',
      name: 'Ocak Ustası',
      lore: 'Ateşin ne zaman söneceğini sesinden anlıyor.',
      rarity: RewardRarity.epic,
      source: TitleSource.achievement,
      condition: TitleCondition.itemsMerged,
      conditionThreshold: 25,
      effects: [
        ItemEffect.flat(
          stat: ItemStat.attack,
          value: 70,
          customLabel: 'saldırı +70',
          customLabelEn: 'attack +70',
        ),
        ItemEffect.flat(
          stat: ItemStat.maxHealth,
          value: 81,
          customLabel: 've savaş canı +81',
          customLabelEn: 'and combat HP +81',
        ),
      ],
    ),
    GameTitle(
      id: 'storm_walker',
      name: 'Fırtına Yürüyüşçüsü',
      lore: 'Hava raporunu okumayı bıraktı.',
      rarity: RewardRarity.epic,
      source: TitleSource.achievement,
      condition: TitleCondition.totalSteps,
      conditionThreshold: 2000000,
      effects: [
        ItemEffect(
          stat: ItemStat.stepCoin,
          value: 0.25,
          customLabel: 'adım parası +%25',
          customLabelEn: 'step coins +25%',
        ),
        ItemEffect(
          stat: ItemStat.speed,
          value: 0.45,
          customLabel: 've hız +%45',
          customLabelEn: 'and speed +45%',
        ),
      ],
    ),
    GameTitle(
      id: 'shadow_pact',
      name: 'Gölge Anlaşması',
      lore: 'Gölgesi ondan önce varıyor.',
      rarity: RewardRarity.epic,
      source: TitleSource.wheel,
      effects: [
        ItemEffect(
          stat: ItemStat.critDamage,
          value: 1.5,
          trigger: ItemEffectTrigger.nightWalk,
          customLabel: 'gece yürüyüşlerinde kritik hasarı +%150',
          customLabelEn: 'on night walks, critical damage +150%',
        ),
        ItemEffect(
          stat: ItemStat.dodge,
          value: 0.45,
          trigger: ItemEffectTrigger.nightWalk,
          customLabel: 've sıyrılma +%45',
          customLabelEn: 'and dodge +45%',
        ),
        ItemEffect(
          stat: ItemStat.defense,
          value: -0.25,
          customLabel: 'ama savunma -%25 (her zaman)',
          customLabelEn: 'but defense -25% (always)',
        ),
      ],
    ),
    GameTitle(
      id: 'wheel_oracle',
      name: 'Çark Kâhini',
      lore: 'Çark dönmeden nerede duracağını biliyor. Öyle diyor.',
      rarity: RewardRarity.epic,
      source: TitleSource.achievement,
      condition: TitleCondition.wheelSpins,
      conditionThreshold: 100,
      effects: [
        ItemEffect(
          stat: ItemStat.wheelXp,
          value: 0.50,
          customLabel: 'çark XP +%50',
          customLabelEn: 'wheel XP +50%',
        ),
        ItemEffect.flat(
          stat: ItemStat.wheelSpinCap,
          value: 2,
          customLabel: 've çark hakkı stoğu +2',
          customLabelEn: 'and wheel-spin capacity +2',
        ),
      ],
    ),
    GameTitle(
      id: 'unbroken',
      name: 'Kırılmayan',
      lore: 'Serisi bir kez bile elinden kaymadı.',
      rarity: RewardRarity.epic,
      source: TitleSource.achievement,
      condition: TitleCondition.longestStreak,
      conditionThreshold: 90,
      effects: [
        ItemEffect(
          stat: ItemStat.defense,
          value: 0.75,
          trigger: ItemEffectTrigger.streakActive,
          customLabel: 'serin ayaktayken savunma +%75',
          customLabelEn: 'while your streak is active, defense +75%',
        ),
        ItemEffect.flat(
          stat: ItemStat.streakFreezeCap,
          value: 2,
          customLabel: 've dondurma stoğu +2',
          customLabelEn: 'and freeze capacity +2',
        ),
      ],
    ),
    GameTitle(
      id: 'sun_forged',
      name: 'Güneşte Dövülmüş',
      lore: 'Yazın ortasında çalıştı, kışın hiç üşümedi.',
      rarity: RewardRarity.epic,
      source: TitleSource.achievement,
      condition: TitleCondition.level,
      conditionThreshold: 25,
      effects: [
        ItemEffect(
          stat: ItemStat.maxHealth,
          value: 0.6,
          trigger: ItemEffectTrigger.highHealth,
          threshold: 0.60,
          customLabel: 'can %60 üstündeyken savaş canı +%60',
          customLabelEn: 'while above 60% HP, combat HP +60%',
        ),
        ItemEffect(
          stat: ItemStat.attack,
          value: 0.45,
          trigger: ItemEffectTrigger.highHealth,
          threshold: 0.60,
          customLabel: 've saldırı +%45',
          customLabelEn: 'and attack +45%',
        ),
      ],
    ),
    GameTitle(
      id: 'coin_river',
      name: 'Altın Nehri',
      lore: 'Kasası dolmuyor çünkü akıyor.',
      rarity: RewardRarity.epic,
      source: TitleSource.achievement,
      condition: TitleCondition.lifetimeCoins,
      conditionThreshold: 250000,
      effects: [
        ItemEffect(
          stat: ItemStat.stepCoin,
          value: 0.25,
          customLabel: 'adım parası +%25',
          customLabelEn: 'step coins +25%',
        ),
        ItemEffect(
          stat: ItemStat.enemyXp,
          value: 0.30,
          customLabel: 've düşman XP +%30',
          customLabelEn: 'and enemy XP +30%',
        ),
      ],
    ),

    // ---------------------------------------------------------------
    // EFSANEVİ — yıllarca oynayanın gösterebileceği ünvanlar
    // ---------------------------------------------------------------
    GameTitle(
      id: 'five_hundred_dawns',
      name: 'Beş Yüz Şafak',
      lore: 'Döngü onun için başa döndü. Bir kez daha.',
      rarity: RewardRarity.legendary,
      source: TitleSource.milestone,
      milestoneDay: 500,
      effects: [
        ItemEffect(
          stat: ItemStat.attack,
          value: 0.85,
          trigger: ItemEffectTrigger.streakActive,
          customLabel: 'serin ayaktayken saldırı +%85',
          customLabelEn: 'while your streak is active, attack +85%',
        ),
        ItemEffect(
          stat: ItemStat.defense,
          value: 0.85,
          trigger: ItemEffectTrigger.streakActive,
          customLabel: ', savunma +%85',
          customLabelEn: ', defense +85%',
        ),
        ItemEffect(
          stat: ItemStat.maxHealth,
          value: 0.85,
          trigger: ItemEffectTrigger.streakActive,
          customLabel: 've savaş canı +%85',
          customLabelEn: 'and combat HP +85%',
        ),
      ],
    ),
    GameTitle(
      id: 'city_wearer',
      name: 'Şehri Aşındıran',
      lore: 'Kaldırımlar onun yüzünden yenilendi.',
      rarity: RewardRarity.legendary,
      source: TitleSource.achievement,
      condition: TitleCondition.totalSteps,
      conditionThreshold: 10000000,
      effects: [
        ItemEffect(
          stat: ItemStat.stepCoin,
          value: 0.25,
          customLabel: 'adım parası +%25',
          customLabelEn: 'step coins +25%',
        ),
        ItemEffect(
          stat: ItemStat.stepXp,
          value: 0.25,
          customLabel: ', adım XP +%25',
          customLabelEn: ', step XP +25%',
        ),
        ItemEffect.flat(
          stat: ItemStat.streakRelief,
          value: 1000,
          customLabel: 've seri eşiği 1000 adım düşer',
          customLabelEn: 'and streak threshold drops by 1000 steps',
        ),
      ],
    ),
    GameTitle(
      id: 'thousand_graves',
      name: 'Bin Mezar',
      lore: 'Adını söyleyen düşman kalmadı.',
      rarity: RewardRarity.legendary,
      source: TitleSource.achievement,
      condition: TitleCondition.enemiesDefeated,
      conditionThreshold: 1000,
      effects: [
        ItemEffect(
          stat: ItemStat.attack,
          value: 0.7,
          trigger: ItemEffectTrigger.onKill,
          customLabel: 'düşman yenince sonraki vuruş +%70 saldırı taşır',
          customLabelEn: 'after a kill, your next strike carries +70% attack',
        ),
        ItemEffect(
          stat: ItemStat.maxHealth,
          value: 0.85,
          trigger: ItemEffectTrigger.onKill,
          customLabel: 've canının %85\'ı geri gelir',
          customLabelEn: 'and you recover 85% of your HP',
        ),
        ItemEffect(
          stat: ItemStat.enemyXp,
          value: 0.25,
          customLabel: 'düşman XP +%25',
          customLabelEn: 'enemy XP +25%',
        ),
      ],
    ),
    GameTitle(
      id: 'deathless',
      name: 'Ölümsüz',
      lore: 'Kaç kez düştüğünü sayan kalmadı; kaç kez kalktığını da.',
      rarity: RewardRarity.legendary,
      source: TitleSource.achievement,
      condition: TitleCondition.adventuresCompleted,
      conditionThreshold: 250,
      effects: [
        ItemEffect(
          stat: ItemStat.defense,
          value: 1.7,
          trigger: ItemEffectTrigger.lowHealth,
          threshold: 0.25,
          customLabel: 'can %25 altına düşünce savunma ikiye katlanır',
          customLabelEn: 'when HP drops below 25%, defense doubles',
        ),
        ItemEffect(
          stat: ItemStat.lifeSteal,
          value: 0.75,
          trigger: ItemEffectTrigger.lowHealth,
          threshold: 0.25,
          customLabel: 've can çalma +%75',
          customLabelEn: 'and life steal +75%',
        ),
      ],
    ),
    GameTitle(
      id: 'star_forge',
      name: 'Yıldız Ocağı',
      lore: 'Dövdüğü demir gökten geldi, ona geri dönmüyor.',
      rarity: RewardRarity.legendary,
      source: TitleSource.achievement,
      condition: TitleCondition.maxItemLevel,
      conditionThreshold: 40,
      effects: [
        ItemEffect.flat(
          stat: ItemStat.attack,
          value: 126,
          customLabel: 'saldırı +126',
          customLabelEn: 'attack +126',
        ),
        ItemEffect.flat(
          stat: ItemStat.defense,
          value: 77,
          customLabel: ', savunma +77',
          customLabelEn: ', defense +77',
        ),
        ItemEffect.flat(
          stat: ItemStat.maxHealth,
          value: 168,
          customLabel: 've savaş canı +168',
          customLabelEn: 'and combat HP +168',
        ),
      ],
    ),
    GameTitle(
      id: 'moonless_night',
      name: 'Aysız Gece',
      lore: 'Karanlığın kendisi ondan çekiniyor.',
      rarity: RewardRarity.legendary,
      source: TitleSource.wheel,
      effects: [
        ItemEffect(
          stat: ItemStat.critChance,
          value: 0.75,
          trigger: ItemEffectTrigger.nightWalk,
          customLabel: 'gece yürüyüşlerinde kritik şansı +%75',
          customLabelEn: 'on night walks, critical chance +75%',
        ),
        ItemEffect(
          stat: ItemStat.critDamage,
          value: 1.95,
          trigger: ItemEffectTrigger.nightWalk,
          customLabel: ', kritik hasarı +%195',
          customLabelEn: ', critical damage +195%',
        ),
        ItemEffect(
          stat: ItemStat.stepCoin,
          value: 0.25,
          trigger: ItemEffectTrigger.nightWalk,
          customLabel: 've adım parası +%25',
          customLabelEn: 'and step coins +25%',
        ),
      ],
    ),
    GameTitle(
      id: 'gold_mountain',
      name: 'Altın Dağı',
      lore: 'Saydığı parayı taşıyacak katır bulamıyor.',
      rarity: RewardRarity.legendary,
      source: TitleSource.purchase,
      cost: 45000,
      effects: [
        ItemEffect(
          stat: ItemStat.stepCoin,
          value: 0.25,
          customLabel: 'adım parası +%25',
          customLabelEn: 'step coins +25%',
        ),
        ItemEffect(
          stat: ItemStat.luck,
          value: 1.1,
          customLabel: 've şans +%110',
          customLabelEn: 'and luck +110%',
        ),
      ],
    ),
    GameTitle(
      id: 'time_thief',
      name: 'Zaman Hırsızı',
      lore: 'Savaş bitmeden bitiriyor.',
      rarity: RewardRarity.legendary,
      source: TitleSource.purchase,
      cost: 48000,
      effects: [
        ItemEffect(
          stat: ItemStat.speed,
          value: 1.25,
          customLabel: 'hız +%125 — vuruş sırası neredeyse hep senin',
          customLabelEn: 'speed +125% — you almost always strike first',
        ),
        ItemEffect(
          stat: ItemStat.maxHealth,
          value: -0.3,
          customLabel: 'ama savaş canı -%30',
          customLabelEn: 'but combat HP -30%',
        ),
      ],
    ),
    GameTitle(
      id: 'wheel_breaker',
      name: 'Çarkı Kıran',
      lore: 'Şansı bir kez fazla zorladı ve şans pes etti.',
      rarity: RewardRarity.legendary,
      source: TitleSource.achievement,
      condition: TitleCondition.wheelSpins,
      conditionThreshold: 365,
      effects: [
        ItemEffect(
          stat: ItemStat.wheelXp,
          value: 0.25,
          customLabel: 'çark XP +%25',
          customLabelEn: 'wheel XP +25%',
        ),
        ItemEffect(
          stat: ItemStat.luck,
          value: 1.0,
          customLabel: ', şans +%100',
          customLabelEn: ', luck +100%',
        ),
        ItemEffect.flat(
          stat: ItemStat.wheelSpinCap,
          value: 2,
          customLabel: 've çark hakkı stoğu +2',
          customLabelEn: 'and wheel-spin capacity +2',
        ),
      ],
    ),
    GameTitle(
      id: 'living_legend',
      name: 'Yaşayan Efsane',
      lore: 'Hakkında anlatılanların yarısı doğru. Kötü yarısı.',
      rarity: RewardRarity.legendary,
      source: TitleSource.achievement,
      condition: TitleCondition.level,
      conditionThreshold: 60,
      effects: [
        ItemEffect(
          stat: ItemStat.attack,
          value: 0.5,
          customLabel: 'saldırı +%50',
          customLabelEn: 'attack +50%',
        ),
        ItemEffect(
          stat: ItemStat.defense,
          value: 0.5,
          customLabel: ', savunma +%50',
          customLabelEn: ', defense +50%',
        ),
        ItemEffect(
          stat: ItemStat.enemyXp,
          value: 0.25,
          customLabel: 've düşman XP +%25',
          customLabelEn: 'and enemy XP +25%',
        ),
      ],
    ),

    // ---------------------------------------------------------------
    // Ek ünvanlar — kaynak ve tetikleyici çeşitliliğini tamamlayanlar
    // ---------------------------------------------------------------
    GameTitle(
      id: 'morning_bell',
      name: 'Sabah Çanı',
      lore: 'Kalkma saatini kimseye sormuyor.',
      rarity: RewardRarity.common,
      source: TitleSource.achievement,
      condition: TitleCondition.longestStreak,
      conditionThreshold: 3,
      effects: [
        ItemEffect(
          stat: ItemStat.luck,
          value: 0.25,
          trigger: ItemEffectTrigger.streakActive,
          customLabel: 'serin ayaktayken şans +%25',
          customLabelEn: 'while your streak is active, luck +25%',
        ),
      ],
    ),
    GameTitle(
      id: 'green_recruit',
      name: 'Acemi Er',
      lore: 'Kılıcı ters tutuyordu. Artık tutmuyor.',
      rarity: RewardRarity.common,
      source: TitleSource.achievement,
      condition: TitleCondition.level,
      conditionThreshold: 3,
      effects: [
        ItemEffect.flat(
          stat: ItemStat.maxHealth,
          value: 30,
          trigger: ItemEffectTrigger.highHealth,
          threshold: 0.90,
          customLabel: 'can %90 üstündeyken savaş canı +30',
          customLabelEn: 'while above 90% HP, combat HP +30',
        ),
      ],
    ),
    GameTitle(
      id: 'window_shopper',
      name: 'Vitrin Gezgini',
      lore: 'Almadan çıkmayı hiç beceremedi.',
      rarity: RewardRarity.common,
      source: TitleSource.purchase,
      cost: 700,
      effects: [
        ItemEffect(
          stat: ItemStat.enemyXp,
          value: 0.12,
          customLabel: 'düşman XP +%12',
          customLabelEn: 'enemy XP +12%',
        ),
      ],
    ),
    GameTitle(
      id: 'salt_road',
      name: 'Tuz Yolu',
      lore: 'Kervanların bıraktığı izden gidiyor.',
      rarity: RewardRarity.uncommon,
      source: TitleSource.achievement,
      condition: TitleCondition.totalSteps,
      conditionThreshold: 30000,
      effects: [
        ItemEffect(
          stat: ItemStat.stepCoin,
          value: 0.12,
          customLabel: 'adım parası +%12',
          customLabelEn: 'step coins +12%',
        ),
        ItemEffect(
          stat: ItemStat.stepXp,
          value: 0.12,
          customLabel: 've adım XP +%12',
          customLabelEn: 'and step XP +12%',
        ),
      ],
    ),
    GameTitle(
      id: 'ember_keeper',
      name: 'Kor Bekçisi',
      lore: 'Ateşi söndürmemek onun tek işi.',
      rarity: RewardRarity.uncommon,
      source: TitleSource.milestone,
      milestoneDay: 14,
      effects: [
        ItemEffect(
          stat: ItemStat.critDamage,
          value: 0.55,
          trigger: ItemEffectTrigger.streakActive,
          customLabel: 'serin ayaktayken kritik hasarı +%55',
          customLabelEn: 'while your streak is active, critical damage +55%',
        ),
      ],
    ),
    GameTitle(
      id: 'thorn_crown',
      name: 'Diken Tacı',
      lore: 'Taşıması acıtıyor ama kimse elinden alamıyor.',
      rarity: RewardRarity.rare,
      source: TitleSource.achievement,
      condition: TitleCondition.itemsMerged,
      conditionThreshold: 10,
      effects: [
        ItemEffect(
          stat: ItemStat.attack,
          value: 0.6,
          customLabel: 'saldırı +%60',
          customLabelEn: 'attack +60%',
        ),
        ItemEffect(
          stat: ItemStat.lifeSteal,
          value: -0.4,
          customLabel: 'ama can çalma -%40',
          customLabelEn: 'but life steal -40%',
        ),
      ],
    ),
    GameTitle(
      id: 'silent_ledger',
      name: 'Sessiz Defter',
      lore: 'Kimin ne kadar yürüdüğünü yalnızca o biliyor.',
      rarity: RewardRarity.rare,
      source: TitleSource.milestone,
      milestoneDay: 60,
      effects: [
        ItemEffect(
          stat: ItemStat.stepXp,
          value: 0.25,
          customLabel: 'adım XP +%25',
          customLabelEn: 'step XP +25%',
        ),
        ItemEffect.flat(
          stat: ItemStat.streakFreezeCap,
          value: 1,
          customLabel: 've dondurma stoğu +1',
          customLabelEn: 'and freeze capacity +1',
        ),
      ],
    ),
    GameTitle(
      id: 'iron_lung',
      name: 'Demir Ciğer',
      lore: 'Nefesi bitmiyor; bitse de haber vermiyor.',
      rarity: RewardRarity.epic,
      source: TitleSource.achievement,
      condition: TitleCondition.adventuresCompleted,
      conditionThreshold: 120,
      effects: [
        ItemEffect(
          stat: ItemStat.maxHealth,
          value: 0.7,
          customLabel: 'savaş canı +%70',
          customLabelEn: 'combat HP +70%',
        ),
        ItemEffect(
          stat: ItemStat.defense,
          value: 0.35,
          trigger: ItemEffectTrigger.untouchedRounds,
          threshold: 4,
          customLabel: '4 tur hasarsız kalınca savunma +%35 daha',
          customLabelEn: 'after 4 damage-free rounds, a further defense +35%',
        ),
      ],
    ),
    GameTitle(
      id: 'sleepless',
      name: 'Uykusuz',
      lore: 'Gece de gündüz de aynı hızda.',
      rarity: RewardRarity.epic,
      source: TitleSource.purchase,
      cost: 14000,
      effects: [
        ItemEffect(
          stat: ItemStat.stepXp,
          value: 0.22,
          customLabel: 'adım XP +%22',
          customLabelEn: 'step XP +22%',
        ),
        ItemEffect(
          stat: ItemStat.speed,
          value: 0.4,
          trigger: ItemEffectTrigger.nightWalk,
          customLabel: 've gece yürüyüşlerinde hız +%40',
          customLabelEn: 'and on night walks, speed +40%',
        ),
      ],
    ),
    GameTitle(
      id: 'world_ender',
      name: 'Dünya Bitiren',
      lore: 'Gidecek yol kalmayınca yenisini açtı.',
      rarity: RewardRarity.legendary,
      source: TitleSource.achievement,
      condition: TitleCondition.longestStreak,
      conditionThreshold: 365,
      effects: [
        ItemEffect(
          stat: ItemStat.attack,
          value: 0.75,
          trigger: ItemEffectTrigger.streakActive,
          customLabel: 'serin ayaktayken saldırı +%75',
          customLabelEn: 'while your streak is active, attack +75%',
        ),
        ItemEffect(
          stat: ItemStat.critChance,
          value: 0.55,
          trigger: ItemEffectTrigger.streakActive,
          customLabel: ', kritik şansı +%55',
          customLabelEn: ', critical chance +55%',
        ),
        ItemEffect(
          stat: ItemStat.stepXp,
          value: 0.25,
          customLabel: 've adım XP +%25',
          customLabelEn: 'and step XP +25%',
        ),
      ],
    ),
  ];

  static final Map<String, GameTitle> _byId = {
    for (final title in all) title.id: title,
  };

  static GameTitle? byId(String? id) => id == null ? null : _byId[id];

  static List<GameTitle> withSource(TitleSource source) => [
    for (final title in all)
      if (title.source == source) title,
  ];

  /// Mağazada satılan ünvanlar, ucuzdan pahalıya.
  static List<GameTitle> get purchasable =>
      withSource(TitleSource.purchase)
        ..sort((a, b) => a.cost.compareTo(b.cost));

  /// [day] kilometre taşında verilecek ünvan (yoksa null).
  static GameTitle? forMilestone(int day) {
    for (final title in all) {
      if (title.source == TitleSource.milestone && title.milestoneDay == day) {
        return title;
      }
    }
    return null;
  }
}
