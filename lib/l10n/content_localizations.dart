import '../data/pet_sayings.dart';
import '../core/utils/item_rules.dart';
import '../core/utils/item_leveling.dart';
import '../core/utils/item_merging.dart';
import '../core/utils/item_comparison.dart';
import '../core/constants/game_constants.dart';
import '../data/enemy_catalog.dart';
import '../models/avatar_profile.dart';
import '../models/adventure_quest.dart';
import '../models/collection_reward.dart';
import '../models/enemy.dart';
import '../models/game_title.dart';
import '../models/item.dart';
import '../models/item_effect.dart';
import '../models/reward_rarity.dart';
import '../models/tutorial_guide_variant.dart';
import '../models/xp_store_item.dart';
import '../models/wheel_reward.dart';
import 'app_localizations.dart';

/// Localizes catalog content by stable persisted IDs.
///
/// The Turkish fields on models remain the storage-safe canonical fallback.
/// Unknown IDs therefore keep working after a catalog update or when an old
/// save is restored.
extension ContentLocalizations on AppLocalizations {
  bool get _isEnglish => localeName.startsWith('en');

  String adventureDuration(Duration duration) =>
      duration.inSeconds < 60
          ? durationSecondsLong(duration.inSeconds)
          : durationMinutesLong(duration.inMinutes);

  String enemyName(Enemy enemy) => switch (enemy.id) {
    'ash_guardian' => enemyAshGuardianName,
    'night_oath' => enemyNightOathName,
    'void_knight' => enemyVoidKnightName,
    'blood_weaver' => enemyBloodWeaverName,
    'crimson_wing' => enemyCrimsonWingName,
    'ember_siren' => enemyEmberSirenName,
    'dusk_temptress' => enemyDuskTemptressName,
    'horned_executioner' => enemyHornedExecutionerName,
    'infernal_sentinel' => enemyInfernalSentinelName,
    'black_claw' => enemyBlackClawName,
    'ember_heir' => enemyEmberHeirName,
    'abyss_overlord' => enemyAbyssOverlordName,
    'eye_of_nothing' => enemyEyeOfNothingName,
    'cinder_colossus' => enemyCinderColossusName,
    'spirit_flame' => enemySpiritFlameName,
    'hell_wing' => enemyHellWingName,
    'ash_fang' => enemyAshFangName,
    'magma_devourer' => enemyMagmaDevourerName,
    'maze_butcher' => enemyMazeButcherName,
    'lord_of_last_seal' => enemyLordOfLastSealName,
    _ => enemy.name,
  };

  String enemyQuest(Enemy enemy) => switch (enemy.id) {
    'ash_guardian' => enemyAshGuardianQuest,
    'night_oath' => enemyNightOathQuest,
    'void_knight' => enemyVoidKnightQuest,
    'blood_weaver' => enemyBloodWeaverQuest,
    'crimson_wing' => enemyCrimsonWingQuest,
    'ember_siren' => enemyEmberSirenQuest,
    'dusk_temptress' => enemyDuskTemptressQuest,
    'horned_executioner' => enemyHornedExecutionerQuest,
    'infernal_sentinel' => enemyInfernalSentinelQuest,
    'black_claw' => enemyBlackClawQuest,
    'ember_heir' => enemyEmberHeirQuest,
    'abyss_overlord' => enemyAbyssOverlordQuest,
    'eye_of_nothing' => enemyEyeOfNothingQuest,
    'cinder_colossus' => enemyCinderColossusQuest,
    'spirit_flame' => enemySpiritFlameQuest,
    'hell_wing' => enemyHellWingQuest,
    'ash_fang' => enemyAshFangQuest,
    'magma_devourer' => enemyMagmaDevourerQuest,
    'maze_butcher' => enemyMazeButcherQuest,
    'lord_of_last_seal' => enemyLordOfLastSealQuest,
    _ => enemy.questText,
  };

  String enemyArchetypeName(EnemyArchetype archetype) => switch (archetype) {
    EnemyArchetype.bruiser => enemyArchetypeBruiser,
    EnemyArchetype.tank => enemyArchetypeTank,
    EnemyArchetype.swift => enemyArchetypeSwift,
    EnemyArchetype.caster => enemyArchetypeCaster,
  };

  String enemyArchetypeDetails(EnemyArchetype archetype) => switch (archetype) {
    EnemyArchetype.bruiser => enemyArchetypeBruiserDescription,
    EnemyArchetype.tank => enemyArchetypeTankDescription,
    EnemyArchetype.swift => enemyArchetypeSwiftDescription,
    EnemyArchetype.caster => enemyArchetypeCasterDescription,
  };

  String guideName(TutorialGuideVariant guide) => switch (guide) {
    TutorialGuideVariant.mavili => guideMaviliName,
    TutorialGuideVariant.pinky => guidePinkyName,
    TutorialGuideVariant.kupkuzu => guideKupkuzuName,
  };

  String guideDescription(TutorialGuideVariant guide) => switch (guide) {
    TutorialGuideVariant.mavili => guideMaviliDescription,
    TutorialGuideVariant.pinky => guidePinkyDescription,
    TutorialGuideVariant.kupkuzu => guideKupkuzuDescription,
  };

  List<String> petPool(PetSituation situation) => switch (situation.context) {
    PetContext.home => [
      petHome1,
      petHome2,
      petHome3,
      petHome4,
      petHome5,
      if (!situation.streakSecured) petHomeNoStreak1,
      if (!situation.streakSecured) petHomeNoStreak2,
      if (situation.wheelAvailable) petHomeWheelReady1,
      if (situation.wheelAvailable) petHomeWheelReady2,
    ],
    PetContext.adventure =>
      situation.hasAdventure
          ? [petAdventure1, petAdventure2, petAdventure3]
          : [petAdventureIdle1, petAdventureIdle2],
    PetContext.store => [petStore1, petStore2, petStore3],
    PetContext.tavern => [petTavernTeaser, petTavern2, petTavern3],
    PetContext.profile => [petProfile1, petProfile2, petProfile3],
  };

  String rarityName(RewardRarity rarity) => switch (rarity) {
    RewardRarity.common => rarityCommon,
    RewardRarity.uncommon => rarityUncommon,
    RewardRarity.rare => rarityRare,
    RewardRarity.epic => rarityEpic,
    RewardRarity.legendary => rarityLegendary,
  };

  String itemCategoryName(ItemCategory category) => switch (category) {
    ItemCategory.swords => itemCategorySwords,
    ItemCategory.axesHalberds => itemCategoryAxesHalberds,
    ItemCategory.macesHammers => itemCategoryMacesHammers,
    ItemCategory.spears => itemCategorySpears,
    ItemCategory.scythes => itemCategoryScythes,
    ItemCategory.magic => itemCategoryMagic,
    ItemCategory.shields => itemCategoryShields,
    ItemCategory.arch => itemCategoryArch,
    ItemCategory.rangedOther => itemCategoryRangedOther,
    ItemCategory.specialOther => itemCategorySpecialOther,
  };

  String itemArchetypeName(ItemArchetype archetype) => switch (archetype) {
    ItemArchetype.striker => itemArchetypeStriker,
    ItemArchetype.guardian => itemArchetypeGuardian,
    ItemArchetype.duelist => itemArchetypeDuelist,
    ItemArchetype.swift => itemArchetypeSwift,
  };

  String itemArchetypeDetails(ItemArchetype archetype) => switch (archetype) {
    ItemArchetype.striker => itemArchetypeStrikerDescription,
    ItemArchetype.guardian => itemArchetypeGuardianDescription,
    ItemArchetype.duelist => itemArchetypeDuelistDescription,
    ItemArchetype.swift => itemArchetypeSwiftDescription,
  };

  String itemStatName(ItemStat stat) => switch (stat) {
    ItemStat.attack => statAttack,
    ItemStat.defense => statDefense,
    ItemStat.maxHealth => statMaxHealth,
    ItemStat.critChance => statCritChance,
    ItemStat.critDamage => statCritDamage,
    ItemStat.lifeSteal => statLifeSteal,
    ItemStat.dodge => statDodge,
    ItemStat.speed => statSpeed,
    ItemStat.luck => statLuck,
    ItemStat.stepCoin => statStepCoin,
    ItemStat.stepXp => statStepXp,
    ItemStat.wheelXp => statWheelXp,
    ItemStat.enemyXp => statEnemyXp,
    ItemStat.dailyCoinCap => statDailyCoinCap,
    ItemStat.streakFreezeCap => statStreakFreezeCap,
    ItemStat.wheelSpinCap => statWheelSpinCap,
    ItemStat.streakRelief => statStreakRelief,
  };

  String itemEffectLabel(ItemEffect effect) {
    if (!_isEnglish) return effect.label;
    final stat = itemStatName(effect.stat);
    final value = _englishEffectValue(effect);
    final threshold = _plainNumber(effect.threshold * 100);
    return switch (effect.trigger) {
      ItemEffectTrigger.always => effectAlways(stat, value),
      ItemEffectTrigger.lowHealth => effectLowHealth(threshold, stat, value),
      ItemEffectTrigger.highHealth => effectHighHealth(threshold, stat, value),
      ItemEffectTrigger.onHit => effectOnHit(
        _plainNumber(effect.chance * 100),
        stat,
        value,
      ),
      ItemEffectTrigger.onKill => effectOnKill(stat, value),
      ItemEffectTrigger.untouchedRounds => effectUntouchedRounds(
        _plainNumber(effect.threshold),
        stat,
        value,
      ),
      ItemEffectTrigger.nightWalk => effectNightWalk(stat, value),
      ItemEffectTrigger.streakActive => effectStreakActive(stat, value),
    };
  }

  String itemStatDeltaLabel(ItemStatDelta delta) {
    if (!_isEnglish) return delta.label;
    final magnitude = delta.delta.abs();
    final stat = itemStatName(delta.stat);
    if (delta.mode == ItemEffectMode.percent) {
      final sign = delta.delta > 0 ? '+' : '-';
      return '$sign${ItemEffect.formatPercent(magnitude)}% $stat';
    }
    final rounded = magnitude.round();
    if (delta.stat.isReduction) {
      final sign = delta.delta > 0 ? '-' : '+';
      return '$stat $sign$rounded steps';
    }
    final sign = delta.delta > 0 ? '+' : '-';
    return '$sign$rounded $stat';
  }

  List<String> itemBuffLabels(Item item) => [
    for (final effect in item.buff.effects) itemEffectLabel(effect),
  ];

  String itemLore(Item item) =>
      _isEnglish && item.lore != null ? signatureItemLore : (item.lore ?? '');

  String adventurePhaseName(AdventureQuestPhase phase) => switch (phase) {
    AdventureQuestPhase.combat => adventurePhaseCombat,
    AdventureQuestPhase.walk => adventurePhaseWalk,
    AdventureQuestPhase.completed => adventurePhaseCompleted,
    AdventureQuestPhase.revival => adventurePhaseRevival,
    AdventureQuestPhase.revivalCompleted => adventurePhaseRevivalCompleted,
  };

  String upgradeBlockReason(
    UpgradeQuote quote,
    RewardRarity rarity,
    int playerLevel,
  ) => switch (quote.block) {
    UpgradeBlock.none => '',
    UpgradeBlock.rarityCap => upgradeBlockedRarity(
      rarityName(rarity),
      quote.rarityCap,
    ),
    UpgradeBlock.playerLevel => upgradeBlockedLevel(playerLevel),
    UpgradeBlock.coins => coinsRequired(quote.cost),
  };

  String mergeBlockReason(MergeQuote quote, RewardRarity rarity) =>
      switch (quote.block) {
        MergeBlock.none => '',
        MergeBlock.maxRarity => mergeBlockedMaxRarity(rarityName(rarity)),
        MergeBlock.notEnough => mergeBlockedCopies(
          quote.requiredCount,
          quote.availableCount,
        ),
        MergeBlock.coins => coinsRequired(quote.cost),
      };

  String titleSourceName(TitleSource source) => switch (source) {
    TitleSource.purchase => titleSourcePurchase,
    TitleSource.achievement => titleSourceAchievement,
    TitleSource.wheel => titleSourceWheel,
    TitleSource.milestone => titleSourceMilestone,
  };

  /// English asset IDs are stable and already curated, so they provide a
  /// safe display fallback until an individually authored catalog entry is
  /// added. Turkish continues to use the authored canonical name.
  String itemName(Item item) {
    if (!_isEnglish) return item.name;
    final identity = parseItemAsset(item.assetPath);
    if (identity == null) return _titleCaseIdentifier(item.id.split('/').last);
    var name = _titleCaseIdentifier(identity.baseId.split('/').last)
        .replaceAllMapped(
          RegExp(r' Type ([1-9])$'),
          (match) => _roman(match[1]!),
        )
        .replaceAll(' V2', ' II')
        .replaceAll(' Demons ', " Demon's ")
        .replaceAll(' Dragons ', " Dragon's ")
        .replaceAll(' Vampires ', " Vampire's ")
        .replaceAll(' Nights ', " Night's ")
        .replaceAll(' Reapers ', " Reaper's ")
        .replaceAll(' Sages ', " Sage's ");
    final variant = identity.variant;
    if (variant != null) {
      final offset = stableSpread(identity.baseId, _englishAdjectives.length);
      name =
          '${_englishAdjectives[(offset + variant - 1) % _englishAdjectives.length]} $name';
    }
    return name;
  }

  String titleName(GameTitle title) =>
      _isEnglish ? _titleCaseIdentifier(title.id) : title.name;

  String titleLore(GameTitle title) {
    if (!_isEnglish) return title.lore;
    final name = titleName(title);
    return switch (title.source) {
      TitleSource.purchase => titleLorePurchase(name),
      TitleSource.achievement => titleLoreAchievement(name),
      TitleSource.wheel => titleLoreWheel(name),
      TitleSource.milestone => titleLoreMilestone(name),
    };
  }

  String titleUnlockRequirement(GameTitle title) {
    if (!_isEnglish) return title.unlockHint;
    return switch (title.source) {
      TitleSource.purchase => titleUnlockPurchase(title.cost),
      TitleSource.wheel => titleUnlockWheel,
      TitleSource.milestone => titleUnlockMilestone(title.milestoneDay),
      TitleSource.achievement =>
        title.condition == null
            ? titleUnlockPlaying
            : '${_titleCondition(title.condition!, title.conditionThreshold)}.',
    };
  }

  String _titleCondition(TitleCondition condition, int count) =>
      switch (condition) {
        TitleCondition.level => titleConditionLevel(count),
        TitleCondition.totalSteps => titleConditionSteps('$count'),
        TitleCondition.longestStreak => titleConditionStreak(count),
        TitleCondition.enemiesDefeated => titleConditionEnemies(count),
        TitleCondition.adventuresCompleted => titleConditionAdventures(count),
        TitleCondition.ownedItemCount => titleConditionItems(count),
        TitleCondition.maxItemLevel => titleConditionItemLevel(count),
        TitleCondition.wheelSpins => titleConditionWheelSpins(count),
        TitleCondition.itemsMerged => titleConditionMerges(count),
        TitleCondition.lifetimeCoins => titleConditionCoins('$count'),
      };

  String characterClassName(String id) => switch (id) {
    'Archer' => classArcher,
    'Armored Axeman' => classArmoredAxeman,
    'Armored Orc' => classArmoredOrc,
    'Armored Skeleton' => classArmoredSkeleton,
    'Bat' => classBat,
    'Elite Orc' => classEliteOrc,
    'Greatsword Skeleton' => classGreatswordSkeleton,
    'Knight' => classKnight,
    'Knight Templar' => classKnightTemplar,
    'Lancer' => classLancer,
    'Necromancer' => classNecromancer,
    'Orc' => classOrc,
    'Orc rider' => classOrcRider,
    'Priest' => classPriest,
    'Skeleton' => classSkeleton,
    'Skeleton Archer' => classSkeletonArcher,
    'Slime' => classSlime,
    'Soldier' => classSoldier,
    'Swordsman' || 'SwordMan' => classSwordsman,
    'Werebear' => classWerebear,
    'Werewolf' || 'Thief' => classWerewolf,
    'Wizard' || 'Magic' || 'DarkMagic' => classWizard,
    'Paladin' => classKnightTemplar,
    'Faith' => classPriest,
    'Nature' => classOrc,
    _ => AvatarProfile.classLabels[id] ?? id,
  };

  String characterClassSlogan(String id, String canonicalSlogan) =>
      _isEnglish ? classSelectionSloganFallback : canonicalSlogan;

  String genderName(String canonical) => switch (canonical) {
    'Kadın' => genderFemale,
    'Erkek' => genderMale,
    'Diğer' => genderOther,
    _ => canonical,
  };

  String storeUpgradeName(XpStoreItem item) => switch (item.id) {
    'reincarnation_potion' => storeReincarnationName,
    'boost_double_xp' => storeDoubleXpName,
    'wheel_extra_spin' => storeExtraSpinName,
    'upgrade_streak_freeze' => storeStreakFreezeName,
    _ => item.name,
  };

  String storeUpgradeDescription(XpStoreItem item) => switch (item.id) {
    'reincarnation_potion' => storeReincarnationDescription,
    'boost_double_xp' => storeDoubleXpDescription,
    'wheel_extra_spin' => storeExtraSpinDescription(
      GameConstants.maxExtraWheelSpins,
    ),
    'upgrade_streak_freeze' => storeStreakFreezeDescription(
      GameConstants.maxStreakFreezes,
    ),
    _ => item.description,
  };

  String rewardConditionName(RewardConditionType type) => switch (type) {
    RewardConditionType.totalDistance => rewardConditionTotalDistance,
    RewardConditionType.singleWalkDistance => rewardConditionSingleWalkDistance,
    RewardConditionType.dailyStepGoals => rewardConditionDailyStepGoals,
    RewardConditionType.streakDays => rewardConditionStreakDays,
    RewardConditionType.completedDays => rewardConditionCompletedDays,
    RewardConditionType.monstersDefeated => rewardConditionMonstersDefeated,
    RewardConditionType.specificVillain => rewardConditionSpecificVillain,
    RewardConditionType.villainsDefeated => rewardConditionVillainsDefeated,
    RewardConditionType.flawlessWins => rewardConditionFlawlessWins,
    RewardConditionType.winStreak => rewardConditionWinStreak,
    RewardConditionType.questsCompleted => rewardConditionQuestsCompleted,
    RewardConditionType.level => rewardConditionLevel,
    RewardConditionType.xpEarned => rewardConditionXpEarned,
    RewardConditionType.bossesDefeated => rewardConditionBossesDefeated,
    RewardConditionType.rareVillainsDefeated =>
      rewardConditionRareVillainsDefeated,
    RewardConditionType.villainsDiscovered => rewardConditionVillainsDiscovered,
    RewardConditionType.activeDays => rewardConditionActiveDays,
  };

  String collectionRewardName(CollectionReward reward) {
    if (!_isEnglish) return reward.name;
    final series =
        int.tryParse(
          RegExp(r'(\d+)$').firstMatch(reward.name)?.group(1) ?? '',
        ) ??
        1;
    return generatedRewardName(
      rewardConditionName(reward.conditionType),
      series,
    );
  }

  String collectionRewardRequirement(CollectionReward reward) {
    if (!_isEnglish) return reward.requirement;
    final count = reward.target;
    final distance = _localizedDistance(reward.target);
    return switch (reward.conditionType) {
      RewardConditionType.totalDistance => rewardRequirementTotalDistance(
        distance,
      ),
      RewardConditionType.singleWalkDistance =>
        rewardRequirementSingleWalkDistance(distance),
      RewardConditionType.dailyStepGoals => rewardRequirementDailyGoals(count),
      RewardConditionType.streakDays => rewardRequirementStreak(count),
      RewardConditionType.completedDays => rewardRequirementCompletedDays(
        count,
      ),
      RewardConditionType.monstersDefeated => rewardRequirementMonsters(count),
      RewardConditionType.specificVillain => rewardRequirementSpecificVillain(
        enemyName(EnemyCatalog.byId(reward.villainId ?? '')!),
        count,
      ),
      RewardConditionType.villainsDefeated => rewardRequirementVillains(count),
      RewardConditionType.flawlessWins => rewardRequirementFlawless(count),
      RewardConditionType.winStreak => rewardRequirementWinStreak(count),
      RewardConditionType.questsCompleted => rewardRequirementQuests(count),
      RewardConditionType.level => rewardRequirementLevel(count),
      RewardConditionType.xpEarned => rewardRequirementXp(count),
      RewardConditionType.bossesDefeated => rewardRequirementBosses(count),
      RewardConditionType.rareVillainsDefeated => rewardRequirementRareVillains(
        count,
      ),
      RewardConditionType.villainsDiscovered => rewardRequirementDiscovered(
        count,
      ),
      RewardConditionType.activeDays => rewardRequirementActiveDays(count),
    };
  }

  String collectionRewardDescription(CollectionReward reward) =>
      _isEnglish
          ? rewardDescription(collectionRewardRequirement(reward))
          : reward.description;

  String wheelRewardName(WheelReward reward) {
    final item = reward.item;
    if (item != null) return itemName(item);
    final title = reward.title;
    if (title != null) return titleName(title);
    return reward.isCoins
        ? wheelCoinsLabel(reward.coins)
        : wheelXpLabel(reward.xp);
  }

  String _localizedDistance(int steps) {
    final km = steps / GameConstants.stepsPerKilometer;
    return km == km.roundToDouble() ? '${km.toInt()}' : km.toStringAsFixed(1);
  }

  String _englishEffectValue(ItemEffect effect) {
    final sign = (effect.value < 0) != effect.stat.isReduction ? '-' : '+';
    final magnitude = effect.value.abs();
    if (effect.mode == ItemEffectMode.percent) {
      return '$sign${_plainNumber(magnitude * 100)}%';
    }
    final unit = effect.stat == ItemStat.streakRelief ? ' steps' : '';
    return '$sign${_plainNumber(magnitude)}$unit';
  }
}

const _englishAdjectives = <String>[
  'Rusty',
  'Worn',
  'Notched',
  'Sharp',
  'Heavy',
  'Light',
  'Ominous',
  'Bloody',
  'Pale',
  'Dark',
  'Silent',
  'Ancient',
  'Crooked',
  'Slender',
  'Ornate',
  'Plain',
  'Scorched',
  'Frozen',
  'Cracked',
  'Restored',
  'Chained',
  'Carved',
  'Gilded',
  'Dusty',
  'Stormbound',
  'Ashen',
  'Barbed',
  'Enchanted',
  'Sleepless',
  'Weary',
  'Furious',
  'Patient',
  'Frosted',
  'Emberlit',
  'Mottled',
  'Oathbound',
];

String _titleCaseIdentifier(String value) => value
    .split('_')
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');

String _roman(String digit) => switch (digit) {
  '1' => 'I',
  '2' => 'II',
  '3' => 'III',
  '4' => 'IV',
  '5' => 'V',
  '6' => 'VI',
  '7' => 'VII',
  '8' => 'VIII',
  '9' => 'IX',
  _ => digit,
};

String _plainNumber(double value) {
  final rounded = value.round();
  if ((value - rounded).abs() < 0.05) return '$rounded';
  return value.toStringAsFixed(1);
}
