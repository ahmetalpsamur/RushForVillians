// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Rush for Villains';

  @override
  String get language => 'Language';

  @override
  String get languageDescription =>
      'Choose the app language. Changes apply instantly.';

  @override
  String get languageSystem => 'System';

  @override
  String get languageTurkish => 'Turkish';

  @override
  String get languageEnglish => 'English';

  @override
  String get fallbackSafetyMessage => 'Türkçe yedek metin';

  @override
  String get commonClose => 'Close';

  @override
  String get scrollToTop => 'Back to top';

  @override
  String get tavernTitle => 'Tavern';

  @override
  String get tavernComingSoon => 'The Tavern isn\'t open yet';

  @override
  String get tavernPreview => 'The team below is just a preview for now.';

  @override
  String get teamWalkingBonusActive =>
      'The whole team is walking together! Bonus XP is active.';

  @override
  String get teamWalkingBonusRequirement =>
      'All members must be walking at the same time to earn the bonus.';

  @override
  String teamTotalSteps(int count) {
    return 'Total Team Steps: $count';
  }

  @override
  String stepCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count steps',
      one: '1 step',
    );
    return '$_temp0';
  }

  @override
  String get chooseCompanionEyebrow => 'CHOOSE YOUR COMPANION';

  @override
  String get chooseCompanionTitle =>
      'Who will join you on your first adventure?';

  @override
  String get chooseCompanionDescription =>
      'Your chosen companion will guide you through the tutorial.';

  @override
  String get chooseMyCompanion => 'Choose My Companion';

  @override
  String get stepsRingLabel => 'STEPS';

  @override
  String stepsTaken(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You took $count steps',
      one: 'You took 1 step',
    );
    return '$_temp0';
  }

  @override
  String dailyGoalSteps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count steps',
      one: '1 step',
    );
    return 'Daily goal: $_temp0';
  }

  @override
  String completedRounds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rounds',
      one: '1 round',
    );
    return '$_temp0';
  }

  @override
  String roundBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ROUNDS',
      one: '1 ROUND',
    );
    return '$_temp0';
  }

  @override
  String get combatHealth => 'Combat Health';

  @override
  String levelNumber(int level) {
    return 'Level $level';
  }

  @override
  String stepProgress(int steps, int goal, String distance) {
    return '$steps / $goal steps ($distance km)';
  }

  @override
  String get dismissPet => 'Dismiss pet';

  @override
  String get summonPet => 'Summon pet';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String helloPlayer(String name) {
    return 'Hello, $name';
  }

  @override
  String get adventure => 'Adventure';

  @override
  String get adventureStartPrompt =>
      'Choose your daily goal and enemy to begin an adventure.';

  @override
  String enemyWaiting(String name) {
    return '$name is waiting for you. Keep your rhythm!';
  }

  @override
  String get monsterHealth => 'Monster Health';

  @override
  String get dailyWheel => 'Daily Wheel';

  @override
  String wheelUnlockRequirement(int goal, int remaining) {
    return 'Complete an adventure (defeat the enemy) or take $goal steps to unlock the wheel. $remaining steps remaining.';
  }

  @override
  String get newWheelPrefix => 'New wheel: ';

  @override
  String get myRewards => 'My Rewards';

  @override
  String get store => 'Store';

  @override
  String get inventory => 'Inventory';

  @override
  String get stepCounter => 'Step Counter';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get permissionUnknown =>
      'Step-counter permission has not been checked yet.';

  @override
  String get permissionGranted => 'The step counter is running.';

  @override
  String get permissionDenied =>
      'We need motion-data permission to count your steps. The rest of the game will still work without it, but your steps won\'t be recorded.';

  @override
  String get permissionPermanentlyDenied =>
      'Motion-data permission is off. Enable Physical Activity in system settings to count your steps.';

  @override
  String get permissionUnavailable =>
      'No step counter was found on this device. The rest of the game still works, and you can simulate steps with the demo controls.';

  @override
  String get stepSource => 'Step Source';

  @override
  String get realPedometer => 'Pedometer (device sensor)';

  @override
  String get manualStepSource => 'Manual (demo controls)';

  @override
  String get realPedometerDescription =>
      'Steps come from your device sensor. Demo buttons are disabled; switch to the manual source to enable them.';

  @override
  String get manualStepSourceDescription => 'Simulate steps here.';

  @override
  String coinsEarnedToday(int count) {
    return 'You earned $count coins from steps today.';
  }

  @override
  String xpEarnedToday(int count) {
    return 'You earned $count XP from steps today.';
  }

  @override
  String stepsPerReward(int count) {
    return '$count steps = 1';
  }

  @override
  String get dailyStreak => 'Daily Streak';

  @override
  String get completedToday => 'Completed today';

  @override
  String get pendingToday => 'Pending today';

  @override
  String streakContinueTomorrow(int count) {
    return 'Your streak is safe. Defeat an enemy or take $count steps tomorrow.';
  }

  @override
  String secureStreak(int count) {
    return 'Defeat an enemy to secure your streak—or take $count more steps.';
  }

  @override
  String nextMilestone(int milestone, int remaining) {
    return 'Next milestone: $milestone days ($remaining remaining)';
  }

  @override
  String streakBonusSummary(String rate) {
    return 'Streak bonus: +$rate% to combat stats (see each stat on your profile).';
  }

  @override
  String streakFreezeSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count streak freezes',
      one: '1 streak freeze',
    );
    return 'You have $_temp0. One is used automatically if you miss a day.';
  }

  @override
  String streakEndingSoon(String remaining) {
    return 'The day ends in $remaining. Don\'t lose your streak!';
  }

  @override
  String streakEndingSoonWithBonus(String remaining, String rate) {
    return 'The day ends in $remaining. Don\'t lose your streak—or your accumulated +$rate% combat bonus!';
  }

  @override
  String simulateSteps(int count) {
    return '+$count steps';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String durationMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String get profile => 'Profile';

  @override
  String profileDetails(int age, int weight, String gender) {
    return 'Age $age • $weight kg • $gender';
  }

  @override
  String get useReincarnationPotion => 'Use Reincarnation Potion';

  @override
  String get reincarnationPotionRequired => 'Reincarnation Potion Required';

  @override
  String get equipment => 'Equipment';

  @override
  String get nothingEquipped => 'You haven\'t equipped anything.';

  @override
  String equippedItemsSummary(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items equipped: $names',
      one: '1 item equipped: $names',
    );
    return '$_temp0';
  }

  @override
  String get openInventory => 'Open Inventory';

  @override
  String get titles => 'Titles';

  @override
  String earnedTitlesPrompt(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titles',
      one: '1 title',
    );
    return 'You\'ve earned $_temp0. Equip one to show it beside your name.';
  }

  @override
  String equippedTitleSummary(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titles earned',
      one: '1 title earned',
    );
    return 'Equipped: $name · $_temp0.';
  }

  @override
  String get blacksmith => 'Blacksmith';

  @override
  String get blacksmithProfileDescription =>
      'Merge your weapons and grow stronger.';

  @override
  String get lastThreeDays => 'Last 3 Days';

  @override
  String get viewAllStepRings => 'View all step rings';

  @override
  String get statistics => 'Stats';

  @override
  String get combatHealthAdventureOnly =>
      'Combat health is tracked only during an adventure.';

  @override
  String get dailyStreakProfile => 'Daily Streak';

  @override
  String longestStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return 'Longest streak: $_temp0';
  }

  @override
  String get coin => 'Coins';

  @override
  String get stepRings => 'Step Rings';

  @override
  String get buffStepCoins => 'step coins';

  @override
  String get buffStepXp => 'step XP';

  @override
  String get buffWheelXp => 'wheel XP';

  @override
  String get buffEnemyXp => 'enemy XP';

  @override
  String buffFreezeStock(int count) {
    return 'freeze capacity +$count';
  }

  @override
  String buffWheelStock(int count) {
    return 'wheel capacity +$count';
  }

  @override
  String buffStreakThreshold(int count) {
    return 'streak threshold -$count';
  }

  @override
  String buffRate(String label, int rate) {
    return '$label +$rate%';
  }

  @override
  String get wheelAlreadySpun => 'You\'ve already spun the wheel today.';

  @override
  String get wheelResetCountdownPrefix => 'Next wheel in: ';

  @override
  String get gearsSpinning => 'Gears spinning...';

  @override
  String get spinWheel => 'Spin the Wheel';

  @override
  String extraSpinNotice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count remaining',
      one: '1 remaining',
    );
    return 'This spin will use an extra spin ($_temp0).';
  }

  @override
  String get titleWon => 'You won a title! 🎉';

  @override
  String get equipTitleFromProfile =>
      'Equip it from the Titles screen in your profile.';

  @override
  String coinsWon(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coins',
      one: '1 coin',
    );
    return 'You won $_temp0! 🎉';
  }

  @override
  String rewardWon(String reward) {
    return 'You won: $reward 🎉';
  }

  @override
  String get equipmentWon => 'You won equipment! 🎉';

  @override
  String rewardTier(String rarity) {
    return '$rarity REWARD';
  }

  @override
  String titleTier(String rarity) {
    return '$rarity TITLE';
  }

  @override
  String get goldWonHeader => 'COINS WON';

  @override
  String get xpWonHeader => 'XP WON';

  @override
  String get rewardAddedToInventory => 'Reward added to your inventory';

  @override
  String get chanceMechanismRunning => 'THE CHANCE MECHANISM IS RUNNING';

  @override
  String get wakeTheGears => 'AWAKEN THE GEARS';

  @override
  String get equippedTitle => 'Equipped Title';

  @override
  String get noEquippedTitle =>
      'You don\'t have a title equipped. Equip one to display it beside your name and activate its effect.';

  @override
  String get unequipTitle => 'UNEQUIP TITLE';

  @override
  String get singleTitleExplanation =>
      'You can equip only one title at a time. Your other titles remain in your collection, ready whenever you want to switch.';

  @override
  String get noTitlesForFilters => 'No titles match these filters.';

  @override
  String get clearFilters => 'CLEAR FILTERS';

  @override
  String get clear => 'CLEAR';

  @override
  String titlesEarnedProgress(int owned, int total) {
    return '$owned / $total titles earned';
  }

  @override
  String get titleSearchHint => 'Search titles, lore, or effects…';

  @override
  String get filterAll => 'All';

  @override
  String get filterOwned => 'Owned';

  @override
  String get filterLocked => 'Locked';

  @override
  String get anyRarity => 'Any rarity';

  @override
  String get anySource => 'Any source';

  @override
  String get sourceAchievement => 'Achievement';

  @override
  String get sourceStore => 'Store';

  @override
  String get sourceWheel => 'Wheel';

  @override
  String get sourceMilestone => 'Milestone';

  @override
  String get sortDefault => 'Default';

  @override
  String get sortRarity => 'Rarity';

  @override
  String get sortNearlyThere => 'Nearly there';

  @override
  String get sortName => 'A–Z';

  @override
  String titlesShown(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titles shown',
      one: '1 title shown',
    );
    return '$_temp0';
  }

  @override
  String get equippedBadge => 'EQUIPPED';

  @override
  String completionPercent(int percent) {
    return '$percent% complete';
  }

  @override
  String get equipAction => 'EQUIP';

  @override
  String showcasePinLimit(int count) {
    return 'You can pin up to $count rewards to your showcase.';
  }

  @override
  String get allRewards => 'All Rewards';

  @override
  String get showcase => 'Showcase';

  @override
  String get noRewardsForFilters => 'No rewards match these filters.';

  @override
  String get rewardSearchHint => 'Search rewards or unlock requirements';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get category => 'Category';

  @override
  String get rarity => 'Rarity';

  @override
  String get filterEarned => 'Earned';

  @override
  String get noRewardsYet =>
      'You haven\'t earned any rewards yet. Defeat your first enemy or complete a walking goal to start your collection.';

  @override
  String get pinnedRewards => 'Pinned';

  @override
  String get collection => 'Collection';

  @override
  String get closeRewardDetails => 'Close reward details';

  @override
  String rewardsEarnedProgress(int earned, int total) {
    return '$earned / $total rewards earned';
  }

  @override
  String get earned => 'Earned';

  @override
  String filterMenuAll(String label) {
    return '$label: All';
  }

  @override
  String get removeFromShowcase => 'Remove from showcase';

  @override
  String get pinToShowcase => 'Pin to showcase';

  @override
  String rewardEarnedForRequirement(String requirement) {
    return 'Earned by completing: $requirement';
  }

  @override
  String rewardWithDate(String rarity, String date) {
    return '$rarity Reward • $date';
  }

  @override
  String progressValue(int progress, int target) {
    return 'Progress: $progress / $target';
  }

  @override
  String rewardEarnedSemantics(String name) {
    return '$name, earned';
  }

  @override
  String rewardLockedSemantics(String name, int progress, int target) {
    return '$name, locked, $progress / $target';
  }

  @override
  String dragonLoot(String name) {
    return '$name Loot';
  }

  @override
  String get dragonLootDescription => 'A reward for defeating the dragon.';

  @override
  String get dragonDefeatedCelebration => 'Dragon Defeated! 🐉';

  @override
  String get great => 'Awesome!';

  @override
  String get dragonHealthSteps => 'Dragon Health (reduced by steps)';

  @override
  String get dragonDefeated => 'Dragon defeated!';

  @override
  String stepsRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more steps',
      one: '1 more step',
    );
    return '$_temp0 remaining.';
  }

  @override
  String get rewardRarityExplanation => 'How Is Reward Rarity Determined?';

  @override
  String get rarityBelow75 => 'Below 75% of goal';

  @override
  String get rarity75To99 => '75–99% of goal';

  @override
  String get rarityMeetGoal => 'Meet the goal';

  @override
  String get rarity125 => 'Reach 125% of goal';

  @override
  String get rarity150 => 'Reach 150% of goal';

  @override
  String get rewardClaimed => 'Reward Claimed';

  @override
  String get claimReward => 'Claim Reward';

  @override
  String get home => 'Home';

  @override
  String get characterCatalogEmpty =>
      'No characters were found in the All_Assets avatar folder.';

  @override
  String get characterCatalogLoadFailed =>
      'Character files couldn\'t be loaded.';

  @override
  String get heroNameTooShort =>
      'Your hero\'s name must be at least 2 characters.';

  @override
  String get fateSecondLine => 'THE SECOND LINE OF YOUR FATE';

  @override
  String get ageQuestion => 'How old are you?';

  @override
  String get ageDescription => 'Your age helps shape your hero\'s story.';

  @override
  String get ageSuffix => 'years';

  @override
  String get defineBody => 'DEFINE YOUR BUILD';

  @override
  String get weightQuestion => 'How much do you weigh?';

  @override
  String get weightDescription =>
      'This will become part of your character profile.';

  @override
  String get fateFirstLine => 'THE FIRST LINE OF YOUR FATE';

  @override
  String get nameQuestion => 'What should we call you?';

  @override
  String get nameDescription =>
      'This name will be etched into your enemies\' memories.';

  @override
  String get heroNameHint => 'Your hero\'s name';

  @override
  String get genderFemale => 'Woman';

  @override
  String get genderMale => 'Man';

  @override
  String get genderOther => 'Other';

  @override
  String get defineIdentity => 'DEFINE YOUR IDENTITY';

  @override
  String get identityQuestion => 'Who is your hero?';

  @override
  String get identityDescription =>
      'Choose the option that best represents you.';

  @override
  String get choosePower => 'CHOOSE YOUR POWER';

  @override
  String get classQuestion => 'Which class are you?';

  @override
  String get classDescription => 'Choose your path for walking and battle.';

  @override
  String get classSelectionHint =>
      'Tap a class to view its introduction, then press “CHOOSE THIS CLASS” to continue.';

  @override
  String get fateSealed => 'YOUR FATE IS BEING SEALED';

  @override
  String heroReadyQuestion(String name) {
    return 'Are you ready, $name?';
  }

  @override
  String get confirmHeroDescription =>
      'Confirm your choices and enter the world of Rush for Villains.';

  @override
  String get scrollToChangeValue => 'Scroll up or down to change the value';

  @override
  String get backToClassList => 'Back to class list';

  @override
  String get usableItemTypes => 'ITEM TYPES THIS CLASS CAN USE';

  @override
  String get chooseThisClass => 'CHOOSE THIS CLASS';

  @override
  String get back => 'Back';

  @override
  String get sealChanges => 'SEAL CHANGES';

  @override
  String get startAdventureAction => 'START ADVENTURE';

  @override
  String get continueAction => 'CONTINUE';

  @override
  String get retry => 'Try again';

  @override
  String stockRights(int count) {
    return 'You have $count available';
  }

  @override
  String get activeUntilEndOfDay => 'Active now—until the end of the day';

  @override
  String get titleStore => 'Title Store';

  @override
  String get noTitlesForSale => 'There are no titles for sale right now.';

  @override
  String get firstWeapon => 'YOUR FIRST WEAPON';

  @override
  String get companionChoseWeapon =>
      'Your companion chose this weapon for you.';

  @override
  String get upgrades => 'Upgrades';

  @override
  String get noClassEquipment => 'No equipment was found for your class.';

  @override
  String get affordableOnly => 'Affordable';

  @override
  String equipmentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get noEquipmentForFilters =>
      'No equipment matches these filters. Keep walking; more items unlock as you level up.';

  @override
  String get adventureStore => 'Adventure Store';

  @override
  String get titleStoreExplanation =>
      'A title is part of your identity: it appears beside your name and carries a unique effect. You can equip one at a time, and every title remains yours.';

  @override
  String titleStoreSummary(int owned, int total, int shown) {
    return '$owned / $total titles owned · $shown shown';
  }

  @override
  String get hideOwned => 'Hide owned';

  @override
  String get noStoreTitlesForFilters =>
      'No titles match these filters. Relax a filter or save a little more gold.';

  @override
  String titleAlreadyOwned(String name) {
    return 'You already own “$name.” Equip it from your profile.';
  }

  @override
  String moreGoldNeeded(int count) {
    return 'You need $count more gold.';
  }

  @override
  String get ownedUpper => 'OWNED';

  @override
  String goldPrice(int count) {
    return '$count GOLD';
  }

  @override
  String get owned => 'Owned';

  @override
  String itemAlreadyOwned(String name) {
    return 'You already own $name.';
  }

  @override
  String itemCoinsNeeded(String name, int count) {
    return 'You need $count more coins for $name.';
  }

  @override
  String maxRarityInvestment(int level) {
    return 'Upgradeable · Max Lv. $level · highest rarity';
  }

  @override
  String mergeInvestment(int level, int count, String rarity) {
    return 'Upgradeable · Max Lv. $level · merge $count to reach $rarity';
  }

  @override
  String itemLevelNeeded(String name, int required, int current) {
    return '$name requires level $required. You are currently level $current.';
  }

  @override
  String levelShort(int level) {
    return 'Lv. $level';
  }

  @override
  String ownedCount(int count) {
    return '$count owned';
  }

  @override
  String get sellItemQuestion => 'Sell this item?';

  @override
  String sellItemWarning(String name, String levelSuffix, int value, int cost) {
    return '$name$levelSuffix will be removed from your inventory and you\'ll receive $value coins. This cannot be undone; buying it again will cost $cost coins and its upgrades will be reset.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String sellWithValue(int value) {
    return 'Sell (+$value)';
  }

  @override
  String emptySlotPrompt(String category) {
    return 'Your $category slot is empty. Choose an item below.';
  }

  @override
  String get noItemsOwned =>
      'You don\'t own any items yet. Buy equipment from the store or spin the daily wheel.';

  @override
  String get usableOnly => 'Usable by Me';

  @override
  String get noInventoryItemsForFilters => 'No items match this filter.';

  @override
  String get tutorialWeaponMissing => 'Tutorial weapon not found.';

  @override
  String get firstWeaponTitle => 'Your First Weapon';

  @override
  String get equippedAction => 'Equipped';

  @override
  String get equip => 'Equip';

  @override
  String get noEquippedItems => 'No items equipped yet';

  @override
  String get noEffect => 'No effect';

  @override
  String get characterPower => 'Character Power';

  @override
  String filledSlots(int filled, int total) {
    return '$filled / $total slots filled';
  }

  @override
  String get combatStats => 'Combat Stats';

  @override
  String get combatStatsDescription =>
      'Used in adventure combat: base values come from your level, while bonuses come from equipment and your streak.';

  @override
  String get conditionalEffects => 'Conditional Effects';

  @override
  String get columnBase => 'BASE';

  @override
  String get columnEquipment => 'EQUIPMENT';

  @override
  String get columnBonus => 'BONUS';

  @override
  String get columnTotal => 'TOTAL';

  @override
  String get columnShare => 'SHARE';

  @override
  String get columnStatus => 'STATUS';

  @override
  String get streakBonus => 'Streak Bonus';

  @override
  String streakBonusTotal(String rate) {
    return 'total +$rate%';
  }

  @override
  String streakCombatGrowth(int days) {
    return 'Your $days-day streak has increased your combat stats. All of it is lost if the streak breaks.';
  }

  @override
  String streakCurrentRate(String rate, int tier, int cycle) {
    return 'Current gain: +$rate% per day. It decreases every $tier days and resets after day $cycle.';
  }

  @override
  String get equippedItems => 'Equipped Items';

  @override
  String get empty => 'Empty';

  @override
  String get equippedTag => 'Equipped';

  @override
  String levelRequirement(int required, int current) {
    return 'Requires level $required. You are currently level $current.';
  }

  @override
  String get effects => 'Effects';

  @override
  String get dormantCombatEffects =>
      'Dimmed rows are combat stats; they activate with the combat system.';

  @override
  String equipIntoEmptySlot(String category) {
    return 'Your $category slot is empty. Equipping this gives:';
  }

  @override
  String replaceEquippedItem(String name) {
    return 'Replacing $name gives:';
  }

  @override
  String get noNumericDifference => 'No numerical difference.';

  @override
  String get unequip => 'Unequip';

  @override
  String sellValue(int value) {
    return 'Sell +$value';
  }

  @override
  String blacksmithLevel(int level, int cap) {
    return 'Blacksmith — Lv. $level / $cap';
  }

  @override
  String get upgradeCombatOnly =>
      'Upgrades increase only combat stats; economy bonuses stay fixed.';

  @override
  String nextLevelPreview(int level, String preview) {
    return 'Lv. $level: $preview';
  }

  @override
  String upgradeToLevel(int level, int cost) {
    return 'Upgrade to Lv. $level — $cost coins';
  }

  @override
  String get cannotUpgrade => 'Can\'t upgrade';

  @override
  String get emptyForge =>
      'The forge is empty. Buy equipment in the store to upgrade it here, or collect copies of the same item to merge them.';

  @override
  String get mergeQuestion => 'Merge these items?';

  @override
  String mergeCostWarning(int count, String name, int cost) {
    return 'This will consume $count copies of $name and $cost coins.';
  }

  @override
  String mergeResult(String rarity, String name, int cap) {
    return 'You\'ll receive 1 $rarity $name at Lv. 1, with a rarity cap of $cap.';
  }

  @override
  String consumedItemLevels(String levels) {
    return 'Levels of consumed items: $levels.';
  }

  @override
  String get equippedItemConsumed =>
      'An equipped copy will be consumed and unequipped first.';

  @override
  String get irreversibleAction => 'This action cannot be undone.';

  @override
  String get merge => 'Merge';

  @override
  String upgradeBestItem(int level, int cap, String suffix) {
    return 'Upgrade — Lv. $level / $cap$suffix';
  }

  @override
  String get mostAdvancedSuffix => ' (most advanced copy)';

  @override
  String get cannotUpgradeNow => 'Can\'t upgrade right now.';

  @override
  String get mergeHighestRarity => 'Merge — highest rarity';

  @override
  String get cannotMerge => 'Can\'t merge';

  @override
  String mergeProgressTitle(int owned, int required, String rarity) {
    return 'Merge — $owned/$required copies → $rarity';
  }

  @override
  String mergeResetDetail(int cap) {
    return 'The result returns to Lv. 1 with a rarity cap of $cap';
  }

  @override
  String mergeWithCost(int cost) {
    return 'Merge — $cost coins';
  }

  @override
  String get cannotMergeNow => 'Can\'t merge right now.';

  @override
  String get chooseDailyGoal => 'CHOOSE YOUR DAILY GOAL';

  @override
  String get goalPickerHint => 'Scroll up or down in 500-step increments';

  @override
  String selectStepGoal(String count) {
    return 'SELECT $count STEPS';
  }

  @override
  String roundNumberUpper(int round) {
    return 'ROUND $round';
  }

  @override
  String get victoryUpper => 'VICTORY!';

  @override
  String get roundYoursUpper => 'ROUND WON!';

  @override
  String enemyDefeatedNamed(String name) {
    return '$name defeated!';
  }

  @override
  String get roundCompletedEarly =>
      'You completed the round goal before time ran out';

  @override
  String speedRewardSummary(int rounds, String steps, String multiplier) {
    return '$rounds rounds · $steps steps — speed reward ×$multiplier';
  }

  @override
  String walkPhaseRemainingNotice(String steps, int rate) {
    return 'The adventure continues: $steps steps remain in the walking phase. During this phase, $rate steps = 1 coin.';
  }

  @override
  String get hitUpper => 'HIT!';

  @override
  String healthDamageUpper(int count) {
    return '-$count HP';
  }

  @override
  String get continueWalkingUpper => 'KEEP WALKING';

  @override
  String get chooseNewAdventureUpper => 'CHOOSE A NEW ADVENTURE';

  @override
  String get finalBlow => 'Final blow!';

  @override
  String attackSequence(int current, int total) {
    return 'Attack $current / $total';
  }

  @override
  String get enemyRoundUpper => 'ENEMY\'S ROUND!';

  @override
  String get restTime => 'Time to recover';

  @override
  String revivalIntro(String name) {
    return '$name depleted your health. Complete a 500-step Walk of Life before you can adventure again.';
  }

  @override
  String get revivalNoXp =>
      'This special walk does not award XP. Keep walking.';

  @override
  String get startLifeWalk => 'Start the Walk of Life';

  @override
  String get lifeWalk => 'Walk of Life';

  @override
  String get lifeWalkDescription =>
      'Keep moving at an easy pace to return. These 500 steps do not award XP.';

  @override
  String get revived => 'You\'re back!';

  @override
  String get revivalCompleted =>
      'You completed the Walk of Life. It awarded no XP, and you can now adventure again.';

  @override
  String get backToAdventures => 'Back to Adventures';

  @override
  String extraGold(int count) {
    return '+$count BONUS COINS';
  }

  @override
  String get congratulations => 'Congratulations!';

  @override
  String xpWonNextAdventure(int xp) {
    return 'You earned $xp XP. A new adventure awaits.';
  }

  @override
  String get chooseNewAdventure => 'Choose a New Adventure';

  @override
  String get chooseTodaysAdventure => 'Choose Today\'s Adventure';

  @override
  String get adventureSelectionDescription =>
      'Set your goal, choose an enemy you can challenge, and start walking.';

  @override
  String get chooseEnemy => 'Choose Your Enemy';

  @override
  String get tapEnemyForDetails =>
      'Tap a card to view the enemy\'s details and start the adventure.';

  @override
  String get victoryIsYours => 'Victory is Yours';

  @override
  String enemyFelledRoadYours(String name) {
    return '$name has fallen. The rest of the road is yours.';
  }

  @override
  String walkPhaseRate(int rate) {
    return 'Walking phase · $rate steps = 1 coin';
  }

  @override
  String walkProgressRemaining(
    String current,
    String target,
    String remaining,
  ) {
    return '$current / $target steps — $remaining remaining';
  }

  @override
  String walkPhaseExplanation(int normal, int bonus) {
    return 'The adventure ends when you fulfill your step commitment. Until then, every step is worth more: the rate is $bonus instead of $normal. After this phase it returns to $normal steps = 1 coin. The XP rate does not change.';
  }

  @override
  String get victorySummary => 'Victory Summary';

  @override
  String get streakAndWheelSecured =>
      'This victory has secured your streak and wheel access.';

  @override
  String get abandonWalkUpper => 'END WALK AND CHOOSE A NEW ADVENTURE';

  @override
  String get abandonWalkWarning =>
      'Ending the walk stops the bonus rate; your victory reward remains yours.';

  @override
  String get defeated => 'Defeated';

  @override
  String get waitingForYou => 'Waiting for you';

  @override
  String get missionMessage => 'Your Mission';

  @override
  String get adventureStatus => 'Adventure Status';

  @override
  String get yourHealth => 'Your Health';

  @override
  String get dailySteps => 'Daily Steps';

  @override
  String victoryRewardXp(int xp) {
    return 'Victory reward: $xp XP';
  }

  @override
  String get leaveAdventure => 'Leave Adventure';

  @override
  String roundProgress(int current, int total) {
    return 'Round $current/$total';
  }

  @override
  String get chooseGoalUpper => 'CHOOSE GOAL';

  @override
  String get tapToChange => 'Tap to change';

  @override
  String get enemyEncounterUpper => 'ENEMY ENCOUNTER';

  @override
  String get enemyAboutUpper => 'ABOUT THE ENEMY';

  @override
  String attackStat(int value) {
    return '$value attack';
  }

  @override
  String defenseStat(int value) {
    return '$value defense';
  }

  @override
  String get startAdventure => 'Start Adventure';

  @override
  String get goalSuitable => 'Suitable for this goal';

  @override
  String unlocksAtSteps(String steps) {
    return 'Unlocks at $steps steps';
  }

  @override
  String victoryMissionMessage(String name, int xp) {
    return '$name defeated. You earned $xp XP—you earned this victory one step at a time!';
  }

  @override
  String totalDuration(String duration) {
    return '$duration total';
  }

  @override
  String enemyCombatExplanation(int rounds, int steps, String duration) {
    return '$rounds rounds; each round requires $steps steps within $duration. Reaching the goal early builds a perfect-round streak and increases damage. Missing it breaks the streak, and the enemy attacks based on your shortfall.';
  }

  @override
  String get storageUnavailable =>
      'Your saved progress is unavailable right now. The game opened with a temporary save; try restarting the app.';

  @override
  String get studioSplashSemantics => 'Heapchi Studios splash screen';

  @override
  String get enemyAshGuardianName => 'Ash Guardian';

  @override
  String get enemyAshGuardianQuest =>
      'The Ash Guardian holds the silent pass. Break the seal on its armor with your first 500 steps!';

  @override
  String get enemyNightOathName => 'Night Oath';

  @override
  String get enemyNightOathQuest =>
      'The Night Oath raises its sword in the moonlight. Keep your rhythm for 1,000 steps and leave it behind!';

  @override
  String get enemyVoidKnightName => 'Void Knight';

  @override
  String get enemyVoidKnightQuest =>
      'The Void Knight has torn a dark rift across the road. Seal it with 1,500 steps!';

  @override
  String get enemyBloodWeaverName => 'Blood Weaver';

  @override
  String get enemyBloodWeaverQuest =>
      'The Blood Weaver feeds on every hesitation. Hold your pace for 2,000 steps and tear apart its web!';

  @override
  String get enemyCrimsonWingName => 'Crimson Wing';

  @override
  String get enemyCrimsonWingQuest =>
      'Crimson Wing has painted the sky red. Take 2,500 steps and escape its shadow!';

  @override
  String get enemyEmberSirenName => 'Ember Siren';

  @override
  String get enemyEmberSirenQuest =>
      'The Ember Siren slows your stride with a burning song. Silence the spell with 3,000 steps!';

  @override
  String get enemyDuskTemptressName => 'Dusk Temptress';

  @override
  String get enemyDuskTemptressQuest =>
      'The Dusk Temptress has shrouded the path in false visions. Scatter the mist with 3,500 true steps!';

  @override
  String get enemyHornedExecutionerName => 'Horned Executioner';

  @override
  String get enemyHornedExecutionerQuest =>
      'The Horned Executioner strikes its axe against the road. Answer the challenge with 4,000 steps!';

  @override
  String get enemyInfernalSentinelName => 'Infernal Sentinel';

  @override
  String get enemyInfernalSentinelQuest =>
      'The Infernal Sentinel has ringed the bridge with fire. Break through the flames with 4,500 steps!';

  @override
  String get enemyBlackClawName => 'Black Claw';

  @override
  String get enemyBlackClawQuest =>
      'Black Claw has found your trail. Outpace the hunter for 5,000 steps and leave the darkness behind!';

  @override
  String get enemyEmberHeirName => 'Heir to the Ember Throne';

  @override
  String get enemyEmberHeirQuest =>
      'The Heir to the Ember Throne defends the crown. Shake the kingdom with 5,500 steps!';

  @override
  String get enemyAbyssOverlordName => 'Abyss Overlord';

  @override
  String get enemyAbyssOverlordQuest =>
      'The Abyss Overlord has swallowed the road home. Carve out your own passage with 6,000 steps!';

  @override
  String get enemyEyeOfNothingName => 'Eye of Nothingness';

  @override
  String get enemyEyeOfNothingQuest =>
      'The Eye of Nothingness watches every step. Force its gaze down with 6,500 steps!';

  @override
  String get enemyCinderColossusName => 'Cinder Colossus';

  @override
  String get enemyCinderColossusQuest =>
      'The Cinder Colossus wakes the mountain with every blow. Cool its stone heart with 7,000 steps!';

  @override
  String get enemySpiritFlameName => 'Spirit Flame';

  @override
  String get enemySpiritFlameQuest =>
      'The Spirit Flame follows like a trail that never fades. Exhaust the cursed fire with 7,500 steps!';

  @override
  String get enemyHellWingName => 'Hellwing';

  @override
  String get enemyHellWingQuest =>
      'Hellwing has darkened the sky. Reach the dawn beneath its wings with 8,000 steps!';

  @override
  String get enemyAshFangName => 'Ash Fang';

  @override
  String get enemyAshFangQuest =>
      'Ash Fang has your scent, and the hunt has begun. Wear down the hellhound with 8,500 steps!';

  @override
  String get enemyMagmaDevourerName => 'Magma Devourer';

  @override
  String get enemyMagmaDevourerQuest =>
      'The Magma Devourer melts the ground beneath you. Outrun the sea of lava with 9,000 steps!';

  @override
  String get enemyMazeButcherName => 'Maze Butcher';

  @override
  String get enemyMazeButcherQuest =>
      'The Maze Butcher waits at the exit. Break its will before the walls with 9,500 steps!';

  @override
  String get enemyLordOfLastSealName => 'Lord of the Last Seal';

  @override
  String get enemyLordOfLastSealQuest =>
      'The Lord of the Last Seal has marked the end of your journey in darkness. Shatter the seal forever with 10,000 steps!';

  @override
  String get enemyArchetypeBruiser => 'Balanced';

  @override
  String get enemyArchetypeBruiserDescription =>
      'Fights evenly, with no surprises.';

  @override
  String get enemyArchetypeTank => 'Tank';

  @override
  String get enemyArchetypeTankDescription =>
      'Slow but extremely tough; wearing down its health takes time.';

  @override
  String get enemyArchetypeSwift => 'Swift';

  @override
  String get enemyArchetypeSwiftDescription =>
      'Usually strikes first and dodges your attacks.';

  @override
  String get enemyArchetypeCaster => 'Caster';

  @override
  String get enemyArchetypeCasterDescription =>
      'Fragile but hits hard, with a high critical chance.';

  @override
  String get guideMaviliName => 'Mavili';

  @override
  String get guideMaviliDescription => 'Calm, brave, and dependable.';

  @override
  String get guidePinkyName => 'Pinky';

  @override
  String get guidePinkyDescription => 'Cheerful, quick, and curious.';

  @override
  String get guideKupkuzuName => 'Kupkuzu';

  @override
  String get guideKupkuzuDescription => 'Small, wise, and fearless.';

  @override
  String get petTavernTeaser =>
      'Online mode is coming soon — now off you go, keep walking!';

  @override
  String get petHome1 => 'We\'re walking today too, right? I\'m ready.';

  @override
  String get petHome2 => 'Your steps are adding up. This will end well.';

  @override
  String get petHome3 => 'I love watching that ring fill up.';

  @override
  String get petHome4 => 'One more lap sounds good to me.';

  @override
  String get petHome5 => 'I\'m quiet, but I\'m keeping an eye on you.';

  @override
  String get petHomeNoStreak1 =>
      'You haven\'t secured your streak today. No rush—just don\'t forget.';

  @override
  String get petHomeNoStreak2 =>
      'Defeat one enemy and your streak will be safe tonight.';

  @override
  String get petHomeWheelReady1 =>
      'The wheel is still waiting for a spin, just so you know.';

  @override
  String get petHomeWheelReady2 =>
      'Today\'s wheel spin is still available. Don\'t you like free stuff?';

  @override
  String get petAdventure1 =>
      'Don\'t look that enemy in the eyes. You\'re ruining its confidence.';

  @override
  String get petAdventure2 => 'Every step lands a hit. Simple, but effective.';

  @override
  String get petAdventure3 =>
      'Don\'t miss this round too—I know you better than that.';

  @override
  String get petAdventureIdle1 =>
      'No adventure selected. Which rival should we annoy?';

  @override
  String get petAdventureIdle2 => 'Seeing a hero stand idle makes me nervous.';

  @override
  String get petStore1 => 'Looking is free. Buying isn\'t.';

  @override
  String get petStore2 =>
      'Buy that shield and you may never worry about health again.';

  @override
  String get petStore3 =>
      'I\'d tell you to save your coins, but you never listen.';

  @override
  String get petTavern2 =>
      'Once this place fills up, finding a table will be tough. Fair warning.';

  @override
  String get petTavern3 => 'We\'ll form teams and share enemies—but not yet.';

  @override
  String get petProfile1 =>
      'Have you changed your title lately? Try a new one.';

  @override
  String get petProfile2 => 'Looking at these numbers makes me proud.';

  @override
  String get petProfile3 => 'Your streak bonus grows a little more every day.';

  @override
  String get tutorialWelcome =>
      'Hi! I\'ll be by your side on this adventure. Let\'s begin when you\'re ready.';

  @override
  String get tutorialAdventurePrompt =>
      'Come on, let\'s choose your first adventure.';

  @override
  String get tutorialEnemyChoice =>
      'Choose your first rival. Take your time—I\'ll wait right here.';

  @override
  String get tutorialEnemySelected =>
      'Good choice! I\'ll walk for you on this first adventure. Watch me strike.';

  @override
  String get tutorialCombatDemo =>
      'This first battle is on me! I\'ll complete the steps and attacks for you.';

  @override
  String get tutorialCombatWaiting =>
      'Now it\'s your turn. Complete your steps; I\'ll watch the battle from here.';

  @override
  String get tutorialEnemyReaction => 'See? Enemies fight back too.';

  @override
  String get tutorialVictoryCelebration => 'That\'s it! Your first victory.';

  @override
  String get tutorialRewardCoins =>
      'Defeating enemies earns you a random amount of coins.';

  @override
  String get tutorialRewardXp =>
      'Experience also makes you stronger, one level at a time.';

  @override
  String get tutorialShopPrompt =>
      'Now let\'s turn those coins into power. The Store is right here.';

  @override
  String get tutorialShopWaiting =>
      'Use your training coins to buy the first weapon I\'ve marked.';

  @override
  String get tutorialItemBought => 'Now we\'re getting stronger!';

  @override
  String get tutorialEquipWaiting => 'Find your new item and tap Equip.';

  @override
  String get tutorialItemEquipped => 'Much better!';

  @override
  String get tutorialBlacksmithPrompt =>
      'We need a little more power. Let\'s visit the Blacksmith.';

  @override
  String get tutorialUpgradeWaiting =>
      'The Upgrade button increases your item\'s level.';

  @override
  String get tutorialUpgradeCompleted =>
      'That\'s more like it! Your item is much stronger now.';

  @override
  String get tutorialWheelPrompt =>
      'Last stop: the Daily Wheel. Let\'s try your luck.';

  @override
  String get tutorialWheelWaiting =>
      'Spin it and let\'s watch the result together.';

  @override
  String get tutorialWheelReward => 'Luck is on your side today!';

  @override
  String get tutorialFinalReady => 'You\'re ready now.';

  @override
  String get tutorialFinalMotto => 'Walk. Grow stronger. Defeat your enemies.';

  @override
  String get tutorialOnlineTeaser =>
      'But this is only the beginning... Online Adventures are coming soon.';

  @override
  String get tutorialRatingRequest =>
      'Before I go, I have one small favor. If you enjoyed your adventure, don\'t forget to rate us!';

  @override
  String get tutorialFarewellWorkDone => 'My work here is done.';

  @override
  String get tutorialFarewellYourTurn =>
      'This place is yours now. If you want me to fight beside you, tap the pet button at the lower-left of the step ring on the Home screen.';

  @override
  String get tutorialFarewell =>
      'I\'m leaving for now. Call me and I\'ll be right beside you again!';

  @override
  String get tutorialBegin => 'Let\'s Begin';

  @override
  String get tutorialStartAdventure => 'Start the Adventure';

  @override
  String get tutorialUnderstood => 'Got It';

  @override
  String get tutorialViewRewards => 'View Rewards';

  @override
  String get tutorialContinue => 'Continue';

  @override
  String get tutorialGoToStore => 'Go to Store';

  @override
  String get tutorialOpenInventory => 'Open Inventory';

  @override
  String get tutorialGoToWheel => 'Go to Wheel';

  @override
  String get tutorialOpenBlacksmith => 'Open Blacksmith';

  @override
  String get tutorialOpenWheel => 'Open Wheel';

  @override
  String get tutorialLater => 'Later';

  @override
  String get tutorialRate => 'Rate Us';

  @override
  String get tutorialFinish => 'Finish Tutorial';

  @override
  String adventureReminder1(int round, String steps, String enemy) {
    return 'Round $round: $steps steps remain against $enemy.';
  }

  @override
  String adventureReminder2(int round, String steps) {
    return 'Round $round is still underway! Complete the remaining $steps steps.';
  }

  @override
  String adventureReminder3(int round, String steps) {
    return 'Keep your rhythm! You have $steps steps left in round $round.';
  }

  @override
  String adventureReminder4(int round, String steps, String enemy) {
    return 'Round $round: take $steps more steps and make $enemy lose power!';
  }

  @override
  String get adventureReminderChannel => 'Adventure Reminders';

  @override
  String get adventureReminderChannelDescription =>
      'Ongoing adventure and step reminders';

  @override
  String get rarityCommon => 'Common';

  @override
  String get rarityUncommon => 'Uncommon';

  @override
  String get rarityRare => 'Rare';

  @override
  String get rarityEpic => 'Epic';

  @override
  String get rarityLegendary => 'Legendary';

  @override
  String get itemCategorySwords => 'Swords';

  @override
  String get itemCategoryAxesHalberds => 'Axes & Halberds';

  @override
  String get itemCategoryMacesHammers => 'Maces & Hammers';

  @override
  String get itemCategorySpears => 'Spears';

  @override
  String get itemCategoryScythes => 'Scythes';

  @override
  String get itemCategoryMagic => 'Magic';

  @override
  String get itemCategoryShields => 'Shields';

  @override
  String get itemCategoryArch => 'Bows & Arrows';

  @override
  String get itemCategoryRangedOther => 'Thrown Weapons';

  @override
  String get itemCategorySpecialOther => 'Special';

  @override
  String get itemArchetypeStriker => 'Striker';

  @override
  String get itemArchetypeStrikerDescription => 'invests in raw attack power';

  @override
  String get itemArchetypeGuardian => 'Guardian';

  @override
  String get itemArchetypeGuardianDescription => 'invests in durability';

  @override
  String get itemArchetypeDuelist => 'Duelist';

  @override
  String get itemArchetypeDuelistDescription => 'invests in critical strikes';

  @override
  String get itemArchetypeSwift => 'Swift';

  @override
  String get itemArchetypeSwiftDescription => 'invests in evasion and tempo';

  @override
  String get titleSourcePurchase => 'Store';

  @override
  String get titleSourceAchievement => 'Achievement';

  @override
  String get titleSourceWheel => 'Wheel';

  @override
  String get titleSourceMilestone => 'Milestone';

  @override
  String get classArcher => 'Hawkeye Archer';

  @override
  String get classArmoredAxeman => 'Iron Executioner';

  @override
  String get classArmoredOrc => 'Armored Ravager';

  @override
  String get classArmoredSkeleton => 'Bone Guardian';

  @override
  String get classEliteOrc => 'Crimson War Chief';

  @override
  String get classGreatswordSkeleton => 'Graveblade';

  @override
  String get classKnight => 'Royal Knight';

  @override
  String get classKnightTemplar => 'Dawn Templar';

  @override
  String get classOrc => 'Wild Raider';

  @override
  String get classPriest => 'Priest of Light';

  @override
  String get classSkeleton => 'Bone Warrior';

  @override
  String get classSkeletonArcher => 'Grave Archer';

  @override
  String get classSlime => 'Curious Slime';

  @override
  String get classSoldier => 'Border Guard';

  @override
  String get classSwordsman => 'Swordmaster';

  @override
  String get classWerebear => 'Bear Spirit';

  @override
  String get classWerewolf => 'Moon Wolf';

  @override
  String get classWizard => 'Sky Mage';

  @override
  String get classSelectionSloganFallback =>
      'A fine choice. Together, we\'ll walk to victory!';

  @override
  String get rewardConditionTotalDistance => 'Total Distance';

  @override
  String get rewardConditionSingleWalkDistance => 'Single-Walk Distance';

  @override
  String get rewardConditionDailyStepGoals => 'Daily Goal';

  @override
  String get rewardConditionStreakDays => 'Goal Streak';

  @override
  String get rewardConditionCompletedDays => 'Completed Days';

  @override
  String get rewardConditionMonstersDefeated => 'Monster Hunt';

  @override
  String get rewardConditionSpecificVillain => 'Villain Hunt';

  @override
  String get rewardConditionVillainsDefeated => 'Villain Victories';

  @override
  String get rewardConditionFlawlessWins => 'Flawless Victories';

  @override
  String get rewardConditionWinStreak => 'Win Streak';

  @override
  String get rewardConditionQuestsCompleted => 'Quest Completion';

  @override
  String get rewardConditionLevel => 'Level';

  @override
  String get rewardConditionXpEarned => 'XP Earned';

  @override
  String get rewardConditionBossesDefeated => 'Boss Hunt';

  @override
  String get rewardConditionRareVillainsDefeated => 'Rare Villain Hunt';

  @override
  String get rewardConditionVillainsDiscovered => 'Villain Discovery';

  @override
  String get rewardConditionActiveDays => 'Active Days';

  @override
  String generatedRewardName(String condition, int series) {
    return '$condition Trophy · $series';
  }

  @override
  String rewardRequirementTotalDistance(String distance) {
    return 'Walk $distance km';
  }

  @override
  String rewardRequirementSingleWalkDistance(String distance) {
    return 'Walk $distance km in a single outing';
  }

  @override
  String rewardRequirementDailyGoals(int count) {
    return 'Complete your daily step goal on $count days';
  }

  @override
  String rewardRequirementStreak(int count) {
    return 'Meet your goal for $count consecutive days';
  }

  @override
  String rewardRequirementCompletedDays(int count) {
    return 'Complete $count goal days';
  }

  @override
  String rewardRequirementMonsters(int count) {
    return 'Defeat $count monsters';
  }

  @override
  String rewardRequirementSpecificVillain(String enemy, int count) {
    return 'Defeat $enemy $count times';
  }

  @override
  String rewardRequirementVillains(int count) {
    return 'Defeat $count villains';
  }

  @override
  String rewardRequirementFlawless(int count) {
    return 'Win $count battles without taking damage';
  }

  @override
  String rewardRequirementWinStreak(int count) {
    return 'Reach a $count-battle win streak';
  }

  @override
  String rewardRequirementQuests(int count) {
    return 'Complete $count quests';
  }

  @override
  String rewardRequirementLevel(int count) {
    return 'Reach level $count';
  }

  @override
  String rewardRequirementXp(int count) {
    return 'Earn $count XP in total';
  }

  @override
  String rewardRequirementBosses(int count) {
    return 'Defeat $count bosses';
  }

  @override
  String rewardRequirementRareVillains(int count) {
    return 'Defeat $count rare villains';
  }

  @override
  String rewardRequirementDiscovered(int count) {
    return 'Discover $count different villains';
  }

  @override
  String rewardRequirementActiveDays(int count) {
    return 'Use the app on $count different days';
  }

  @override
  String rewardDescription(String requirement) {
    return '$requirement and add this keepsake to your collection.';
  }

  @override
  String thisRoundSteps(String current, String target) {
    return 'This round: $current / $target steps';
  }

  @override
  String roundRules(String steps, String duration, String enemy) {
    return 'This round requires $steps steps in $duration. Finish before time runs out to earn a perfect round and an early-finish bonus. Missing the goal breaks your streak, and $enemy attacks based on your shortfall.';
  }

  @override
  String roundGoalSummary(int rounds, String steps, String duration) {
    return '$rounds rounds · $steps steps/round · $duration/round';
  }

  @override
  String healthValue(String value) {
    return '$value HP';
  }

  @override
  String stepsLabel(String value) {
    return '$value steps';
  }

  @override
  String enemyAttackedAfterTimeout(String enemy) {
    return '$enemy attacked when time ran out';
  }

  @override
  String enemyAttackingCycle(String enemy, int current, int total) {
    return '$enemy is attacking · $current / $total';
  }

  @override
  String victoryCoinsTotal(String total, String base, String bonus) {
    return '$total coins in total · base $base + speed bonus $bonus';
  }

  @override
  String damageDealt(int damage) {
    return 'You dealt $damage damage to the enemy!';
  }

  @override
  String dailyStepProgressValue(String current, String goal) {
    return '$current / $goal steps';
  }

  @override
  String adventureProgressValue(String current, String goal) {
    return '$current / $goal steps — adventure progress';
  }

  @override
  String walkRewardBreakdown(
    String victory,
    String walk,
    String total,
    String xp,
  ) {
    return 'Victory +$victory · walking +$walk coins · total +$total coins · +$xp XP';
  }

  @override
  String perfectStreakNextCap(String cap) {
    return 'Perfect streak: — · next cap ×$cap';
  }

  @override
  String perfectStreakCap(int count, String cap) {
    return 'PERFECT STREAK $count · cap ×$cap';
  }

  @override
  String get streakBrokenUpper => 'STREAK BROKEN · ×1.0';

  @override
  String perfectStreakUpper(int count) {
    return 'PERFECT · STREAK $count';
  }

  @override
  String get newRoundStartedUpper => 'NEW ROUND STARTED';

  @override
  String get walkingPhaseUpper => 'WALKING PHASE';

  @override
  String get titleUnequippedNotice => 'Title unequipped.';

  @override
  String titleEquippedNotice(String name) {
    return 'You equipped “$name.”';
  }

  @override
  String titleOwnedNotice(String name) {
    return 'You already own “$name.”';
  }

  @override
  String coinsStillNeeded(int count) {
    return 'You need $count more coins.';
  }

  @override
  String titlePurchasedNotice(String name) {
    return 'You bought “$name.” Equip it from your profile.';
  }

  @override
  String newTitleNotice(String names) {
    return 'New title: $names — equip it from your profile.';
  }

  @override
  String newTitlesNotice(String names) {
    return 'New titles: $names';
  }

  @override
  String newRewardNotice(String name) {
    return 'New reward: $name';
  }

  @override
  String newRewardsNotice(int count) {
    return '$count new rewards were added to your collection!';
  }

  @override
  String enemyAttackNotice(String enemy, int damage) {
    return '$enemy attacked! You lost $damage HP.';
  }

  @override
  String perfectRoundNotice(int streak, String multiplier) {
    return 'Perfect round! Streak $streak · damage ×$multiplier';
  }

  @override
  String get perfectRoundBrokenNotice =>
      'Your perfect-round streak ended. The multiplier returned to ×1.';

  @override
  String itemPurchasedNotice(String name) {
    return '$name purchased!';
  }

  @override
  String itemPurchasedCountNotice(String name, int count) {
    return '$name purchased. You now have $count.';
  }

  @override
  String get itemMissingNotice => 'This item is not in your inventory.';

  @override
  String get itemCatalogMissingNotice =>
      'This item is no longer in the catalog.';

  @override
  String itemWrongClassNotice(String name) {
    return '$name cannot be used by your class.';
  }

  @override
  String itemEquippedNotice(String name) {
    return '$name equipped.';
  }

  @override
  String itemEquippedReplacedNotice(String name, String replaced) {
    return '$name equipped; $replaced unequipped.';
  }

  @override
  String itemRemovedNotice(String name) {
    return '$name unequipped.';
  }

  @override
  String itemSoldNotice(String name, int value) {
    return '$name sold. +$value coins.';
  }

  @override
  String itemRemovedSoldNotice(String name, int value) {
    return '$name unequipped and sold. +$value coins.';
  }

  @override
  String get reincarnationNeededNotice =>
      'You need a Reincarnation Potion to change your character.';

  @override
  String get reincarnationCompleteNotice =>
      'Reincarnation complete. One potion was consumed.';

  @override
  String levelUpUpper(int level) {
    return 'LEVEL $level!';
  }

  @override
  String levelsGainedNotice(int count) {
    return 'You gained $count levels at once. Your steps are paying off!';
  }

  @override
  String get nextLevelEncouragement =>
      'Keep walking; the next level is getting closer.';

  @override
  String get revivalDoneNotice =>
      'Walk of Life complete. You have revived! These 500 steps awarded no XP.';

  @override
  String get revivalRequiredNotice =>
      'Complete the 500-step Walk of Life before starting a new adventure.';

  @override
  String revivalRemainingNotice(int count) {
    return 'Take $count more steps in the Walk of Life to return to your adventures.';
  }

  @override
  String streakFreezeUsedNotice(String remaining) {
    return 'Your streak was protected and 1 freeze was used. $remaining';
  }

  @override
  String freezeRemaining(int count) {
    return '$count remaining.';
  }

  @override
  String get noFreezesRemaining => 'No freezes remaining.';

  @override
  String streakMilestoneFreeze(int days) {
    return '$days-day streak! Milestone reward: 1 streak freeze.';
  }

  @override
  String streakMilestoneStockFull(int days) {
    return '$days-day streak! Milestone reached, but your freeze stock is already full.';
  }

  @override
  String streakBonusLostNotice(String rate) {
    return 'Your streak ended. Your accumulated +$rate% combat bonus was reset.';
  }

  @override
  String freezeStockFullNotice(int count) {
    return 'Your freeze stock is full ($count). No coins were spent.';
  }

  @override
  String wheelStockFullNotice(int count) {
    return 'Your extra wheel-spin stock is full ($count). No coins were spent.';
  }

  @override
  String get doubleXpAlreadyActiveNotice =>
      '2× XP is already active. No coins were spent.';

  @override
  String get storeReincarnationName => 'Reincarnation Potion';

  @override
  String get storeReincarnationDescription =>
      'Lets you choose your character and class again once. The potion is consumed when editing is complete.';

  @override
  String get storeDoubleXpName => '2× XP Boost (1 day)';

  @override
  String get storeDoubleXpDescription =>
      'Doubles all XP earned until the end of the day, including steps, enemies, and the wheel.';

  @override
  String get storeExtraSpinName => 'Extra Wheel Spin';

  @override
  String storeExtraSpinDescription(int count) {
    return 'Spin the wheel once more after using your daily spin. You can store up to $count.';
  }

  @override
  String get storeStreakFreezeName => 'Streak Freeze';

  @override
  String storeStreakFreezeDescription(int count) {
    return 'Automatically protects your streak if you miss a day. You can store up to $count.';
  }

  @override
  String get statAttack => 'attack';

  @override
  String get statDefense => 'defense';

  @override
  String get statMaxHealth => 'combat HP';

  @override
  String get statCritChance => 'critical chance';

  @override
  String get statCritDamage => 'critical damage';

  @override
  String get statLifeSteal => 'life steal';

  @override
  String get statDodge => 'dodge';

  @override
  String get statSpeed => 'speed';

  @override
  String get statLuck => 'luck';

  @override
  String get statStepCoin => 'step coins';

  @override
  String get statStepXp => 'step XP';

  @override
  String get statWheelXp => 'wheel XP';

  @override
  String get statEnemyXp => 'enemy XP';

  @override
  String get statDailyCoinCap => 'daily coin limit';

  @override
  String get statStreakFreezeCap => 'freeze capacity';

  @override
  String get statWheelSpinCap => 'wheel-spin capacity';

  @override
  String get statStreakRelief => 'streak threshold';

  @override
  String effectAlways(String stat, String value) {
    return '$stat $value';
  }

  @override
  String effectLowHealth(String threshold, String stat, String value) {
    return 'while below $threshold% HP, $stat $value';
  }

  @override
  String effectHighHealth(String threshold, String stat, String value) {
    return 'while above $threshold% HP, $stat $value';
  }

  @override
  String effectOnHit(String chance, String stat, String value) {
    return '$chance% chance on hit: $stat $value';
  }

  @override
  String effectOnKill(String stat, String value) {
    return 'after defeating an enemy, $stat $value';
  }

  @override
  String effectUntouchedRounds(String rounds, String stat, String value) {
    return 'after $rounds damage-free rounds, $stat $value';
  }

  @override
  String effectNightWalk(String stat, String value) {
    return 'during night walks, $stat $value';
  }

  @override
  String effectStreakActive(String stat, String value) {
    return 'while your streak is active, $stat $value';
  }

  @override
  String get signatureItemLore =>
      'A signature item with a unique combat trait.';

  @override
  String get adventurePhaseCombat => 'Combat Phase';

  @override
  String get adventurePhaseWalk => 'Walking Phase';

  @override
  String get adventurePhaseCompleted => 'Adventure Complete';

  @override
  String get adventurePhaseRevival => 'Walk of Life';

  @override
  String get adventurePhaseRevivalCompleted => 'Walk of Life Complete';

  @override
  String titleLoreAchievement(String name) {
    return '$name is proof of a hard-earned feat.';
  }

  @override
  String titleLorePurchase(String name) {
    return '$name is a mark chosen for the road ahead.';
  }

  @override
  String titleLoreWheel(String name) {
    return '$name was granted by a fortunate turn of the wheel.';
  }

  @override
  String titleLoreMilestone(String name) {
    return '$name commemorates lasting dedication.';
  }

  @override
  String titleUnlockPurchase(int cost) {
    return 'Buy it from the Store for $cost coins.';
  }

  @override
  String get titleUnlockWheel => 'May be won from the Daily Wheel.';

  @override
  String titleUnlockMilestone(int days) {
    return 'Reward for reaching a $days-day streak milestone.';
  }

  @override
  String get titleUnlockPlaying => 'Earned by playing.';

  @override
  String titleConditionLevel(int count) {
    return 'Reach level $count';
  }

  @override
  String titleConditionSteps(String count) {
    return 'Take $count total steps';
  }

  @override
  String titleConditionStreak(int count) {
    return 'Build a $count-day streak';
  }

  @override
  String titleConditionEnemies(int count) {
    return 'Defeat $count enemies';
  }

  @override
  String titleConditionAdventures(int count) {
    return 'Complete $count adventures';
  }

  @override
  String titleConditionItems(int count) {
    return 'Collect $count items';
  }

  @override
  String titleConditionItemLevel(int count) {
    return 'Upgrade an item to Lv. $count';
  }

  @override
  String titleConditionWheelSpins(int count) {
    return 'Spin the wheel $count times';
  }

  @override
  String titleConditionMerges(int count) {
    return 'Merge $count items';
  }

  @override
  String titleConditionCoins(String count) {
    return 'Earn $count coins in total';
  }

  @override
  String wheelCoinsLabel(int count) {
    return '+$count coins';
  }

  @override
  String wheelXpLabel(int count) {
    return '+$count XP';
  }

  @override
  String streakStatBonusNotice(
    int day,
    String gain,
    String stat,
    String total,
  ) {
    return 'Day $day: +$gain% $stat ($total% total from your streak)';
  }

  @override
  String streakCycleRestarted(String gain) {
    return ' · The cycle restarted! Daily gain is back to +$gain%.';
  }

  @override
  String upgradeBlockedRarity(String rarity, int cap) {
    return 'Rarity limit reached ($rarity: $cap). Merge copies to raise its rarity.';
  }

  @override
  String upgradeBlockedLevel(int level) {
    return 'An item cannot exceed your level (Lv. $level). It can grow again when you level up.';
  }

  @override
  String coinsRequired(int count) {
    return '$count coins required.';
  }

  @override
  String mergeBlockedMaxRarity(String rarity) {
    return '$rarity is the highest rarity and cannot be merged.';
  }

  @override
  String mergeBlockedCopies(int required, int available) {
    return 'Merging requires $required copies; you have $available.';
  }

  @override
  String mergeCompletedNotice(int count, String name, String rarity) {
    return '$count copies of $name merged: now $rarity, Lv. 1.';
  }

  @override
  String mergeCompletedUnequippedNotice(String name, int count, String rarity) {
    return '$name was unequipped and $count copies were merged: now $rarity, Lv. 1.';
  }

  @override
  String durationSecondsLong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seconds',
      one: '1 second',
    );
    return '$_temp0';
  }

  @override
  String durationMinutesLong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String get shadowDragonName => 'Shadow Dragon';

  @override
  String get shadowDragonDescription =>
      'Defeat the dragon by taking 20,000 steps and claim your reward.';

  @override
  String get youMemberName => 'You';

  @override
  String dragonStepsProgress(int current, int target) {
    return '$current / $target steps';
  }

  @override
  String itemUpgradedNotice(String name, int level, int cost) {
    return '$name reached Lv. $level. -$cost coins.';
  }

  @override
  String get classBat => 'Nightwing';

  @override
  String get classLancer => 'Storm Lancer';

  @override
  String get classNecromancer => 'Soul Caller';

  @override
  String get classOrcRider => 'Steppe Rider';
}
