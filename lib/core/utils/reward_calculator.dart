import '../../models/reward_rarity.dart';

/// Görev performansına göre ödül nadirliğini belirler.
///
/// [stepRatio]: atılan adımın hedefe oranı (1.0 = hedef tam tutturuldu).
/// [calorieGoalReached]: günlük kalori hedefinin de tutturulup
/// tutturulmadığı; en üst nadirlik için gereklidir.
RewardRarity calculateRewardRarity({
  required double stepRatio,
  required bool calorieGoalReached,
}) {
  if (stepRatio >= 1.5 && calorieGoalReached) return RewardRarity.legendary;
  if (stepRatio >= 1.25) return RewardRarity.epic;
  if (stepRatio >= 1.0) return RewardRarity.rare;
  if (stepRatio >= 0.75) return RewardRarity.uncommon;
  return RewardRarity.common;
}
