import '../data/reward_catalog.dart';
import '../models/collection_reward.dart';
import '../models/daily_progress.dart';
import '../models/daily_step_record.dart';
import '../models/user_profile.dart';

abstract final class RewardEngine {
  static const int maxPinnedRewards = 6;

  static RewardStatistics statistics({
    required UserProfile profile,
    required DailyProgress today,
    required List<DailyStepRecord> history,
  }) {
    final completedHistory =
        history
            .where((day) => day.stepGoal > 0 && day.steps >= day.stepGoal)
            .length;
    final todayCompleted = today.stepGoalReached ? 1 : 0;
    final activeHistory = history.where((day) => day.steps > 0).length;

    return RewardStatistics(
      totalSteps: profile.totalSteps,
      longestSingleWalkSteps: profile.longestSingleWalkSteps,
      dailyGoalsCompleted: completedHistory + todayCompleted,
      longestStreak: profile.longestStreak,
      completedDays: completedHistory + todayCompleted,
      monstersDefeated: profile.enemiesDefeated,
      villainDefeats: profile.villainDefeatCounts,
      villainsDefeated: profile.enemiesDefeated,
      flawlessWins: profile.flawlessWins,
      bestWinStreak: profile.bestWinStreak,
      questsCompleted: profile.adventuresCompleted,
      level: profile.level,
      totalXpEarned: profile.totalXpEarned,
      bossesDefeated: profile.bossesDefeated,
      rareVillainsDefeated: profile.rareVillainsDefeated,
      villainsDiscovered: profile.villainDefeatCounts.keys.length,
      activeDays: activeHistory + (today.steps > 0 ? 1 : 0),
    );
  }

  /// Tamamlanan koşulları yalnızca ilk kez damgalar ve yeni açılanları döner.
  static List<CollectionReward> evaluate({
    required UserProfile profile,
    required RewardStatistics statistics,
    required DateTime now,
  }) {
    final unlocked = <CollectionReward>[];
    for (final reward in RewardCatalog.all) {
      if (profile.earnedRewardDates.containsKey(reward.id)) continue;
      if (!reward.isComplete(statistics)) continue;
      profile.earnedRewardDates[reward.id] = now.toUtc();
      unlocked.add(reward);
    }
    return unlocked;
  }

  static bool togglePinned(UserProfile profile, String rewardId) {
    if (!profile.earnedRewardDates.containsKey(rewardId)) return false;
    if (profile.pinnedRewardIds.remove(rewardId)) return true;
    if (profile.pinnedRewardIds.length >= maxPinnedRewards) return false;
    profile.pinnedRewardIds.add(rewardId);
    return true;
  }
}
