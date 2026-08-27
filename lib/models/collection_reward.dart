import 'reward_rarity.dart';

enum RewardConditionType {
  totalDistance,
  singleWalkDistance,
  dailyStepGoals,
  streakDays,
  completedDays,
  monstersDefeated,
  specificVillain,
  villainsDefeated,
  flawlessWins,
  winStreak,
  questsCompleted,
  level,
  xpEarned,
  bossesDefeated,
  rareVillainsDefeated,
  villainsDiscovered,
  activeDays,
}

extension RewardConditionTypeX on RewardConditionType {
  String get label => switch (this) {
    RewardConditionType.totalDistance => 'Toplam mesafe',
    RewardConditionType.singleWalkDistance => 'Tek yürüyüş mesafesi',
    RewardConditionType.dailyStepGoals => 'Günlük hedef',
    RewardConditionType.streakDays => 'Hedef serisi',
    RewardConditionType.completedDays => 'Tamamlanan gün',
    RewardConditionType.monstersDefeated => 'Canavar avı',
    RewardConditionType.specificVillain => 'Villain avı',
    RewardConditionType.villainsDefeated => 'Villain zaferi',
    RewardConditionType.flawlessWins => 'Hasarsız zafer',
    RewardConditionType.winStreak => 'Galibiyet serisi',
    RewardConditionType.questsCompleted => 'Görev tamamlama',
    RewardConditionType.level => 'Seviye',
    RewardConditionType.xpEarned => 'XP toplama',
    RewardConditionType.bossesDefeated => 'Boss avı',
    RewardConditionType.rareVillainsDefeated => 'Nadir villain avı',
    RewardConditionType.villainsDiscovered => 'Villain keşfi',
    RewardConditionType.activeDays => 'Düzenli devam',
  };
}

/// Ödül koşullarının uygulamanın geri kalanından bağımsız veri sözleşmesi.
/// Yeni bir istatistik kaynağı eklendiğinde katalog veya ekran değişmez.
class RewardStatistics {
  final int totalSteps;
  final int longestSingleWalkSteps;
  final int dailyGoalsCompleted;
  final int longestStreak;
  final int completedDays;
  final int monstersDefeated;
  final Map<String, int> villainDefeats;
  final int villainsDefeated;
  final int flawlessWins;
  final int bestWinStreak;
  final int questsCompleted;
  final int level;
  final int totalXpEarned;
  final int bossesDefeated;
  final int rareVillainsDefeated;
  final int villainsDiscovered;
  final int activeDays;

  const RewardStatistics({
    this.totalSteps = 0,
    this.longestSingleWalkSteps = 0,
    this.dailyGoalsCompleted = 0,
    this.longestStreak = 0,
    this.completedDays = 0,
    this.monstersDefeated = 0,
    this.villainDefeats = const {},
    this.villainsDefeated = 0,
    this.flawlessWins = 0,
    this.bestWinStreak = 0,
    this.questsCompleted = 0,
    this.level = 1,
    this.totalXpEarned = 0,
    this.bossesDefeated = 0,
    this.rareVillainsDefeated = 0,
    this.villainsDiscovered = 0,
    this.activeDays = 0,
  });
}

class CollectionReward {
  final String id;
  final String name;
  final String description;
  final String requirement;
  final RewardConditionType conditionType;
  final int target;
  final String? villainId;
  final String assetPath;
  final String category;
  final String subcategory;
  final RewardRarity rarity;
  final bool hidden;

  const CollectionReward({
    required this.id,
    required this.name,
    required this.description,
    required this.requirement,
    required this.conditionType,
    required this.target,
    required this.assetPath,
    required this.category,
    required this.subcategory,
    required this.rarity,
    this.villainId,
    this.hidden = false,
  });

  int progress(RewardStatistics stats) => switch (conditionType) {
    RewardConditionType.totalDistance => stats.totalSteps,
    RewardConditionType.singleWalkDistance => stats.longestSingleWalkSteps,
    RewardConditionType.dailyStepGoals => stats.dailyGoalsCompleted,
    RewardConditionType.streakDays => stats.longestStreak,
    RewardConditionType.completedDays => stats.completedDays,
    RewardConditionType.monstersDefeated => stats.monstersDefeated,
    RewardConditionType.specificVillain => stats.villainDefeats[villainId] ?? 0,
    RewardConditionType.villainsDefeated => stats.villainsDefeated,
    RewardConditionType.flawlessWins => stats.flawlessWins,
    RewardConditionType.winStreak => stats.bestWinStreak,
    RewardConditionType.questsCompleted => stats.questsCompleted,
    RewardConditionType.level => stats.level,
    RewardConditionType.xpEarned => stats.totalXpEarned,
    RewardConditionType.bossesDefeated => stats.bossesDefeated,
    RewardConditionType.rareVillainsDefeated => stats.rareVillainsDefeated,
    RewardConditionType.villainsDiscovered => stats.villainsDiscovered,
    RewardConditionType.activeDays => stats.activeDays,
  };

  bool isComplete(RewardStatistics stats) => progress(stats) >= target;
}

class EarnedReward {
  final CollectionReward reward;
  final DateTime earnedAt;
  final bool pinned;

  const EarnedReward({
    required this.reward,
    required this.earnedAt,
    required this.pinned,
  });
}
