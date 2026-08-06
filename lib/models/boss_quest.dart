/// "Ejderha" görevi: günlük adım hedefine ulaşarak yenilen boss.
class BossQuest {
  final String name;
  final String description;
  final int requiredSteps;
  int currentSteps;
  bool rewardClaimed;

  BossQuest({
    required this.name,
    required this.description,
    required this.requiredSteps,
    this.currentSteps = 0,
    this.rewardClaimed = false,
  });

  double get progress => (currentSteps / requiredSteps).clamp(0, 1);

  bool get isDefeated => currentSteps >= requiredSteps;
}
