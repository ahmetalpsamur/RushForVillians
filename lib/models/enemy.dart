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
  final int attackDamage;
  final String questText;
  final int minimumDailySteps;
  final int xpReward;

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
  });

  String get attackAsset => attackAssets.first;
}
