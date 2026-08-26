/// Bir saldırının değişmeyen beş yürüyüş yoğunluğu.
///
/// Sıra bu enumun sırasıdır ve oyun kuralıdır; kayıtta ordinal yerine [name]
/// kullanılırsa ileride okunabilir kalır.
enum AttackPhase { warmUp, attack, rush, recovery, finalRush }

extension AttackPhaseLabel on AttackPhase {
  String get label => switch (this) {
    AttackPhase.warmUp => 'WARM-UP',
    AttackPhase.attack => 'ATTACK',
    AttackPhase.rush => 'RUSH',
    AttackPhase.recovery => 'RECOVERY',
    AttackPhase.finalRush => 'FINAL RUSH',
  };

  String get fitnessDescription => switch (this) {
    AttackPhase.warmUp => 'Düşük tempoda yürüyüşe hazırlan.',
    AttackPhase.attack => 'Normal tempoda yürümeye devam et.',
    AttackPhase.rush => 'Temponu artır.',
    AttackPhase.recovery => 'Durma; daha düşük tempoda yürümeyi sürdür.',
    AttackPhase.finalRush => 'Son kez yüksek tempoya çık.',
  };
}

/// Beş rounddan birinin saldırı süresindeki payı.
class AttackRoundConfig {
  final AttackPhase phase;
  final double percentage;

  const AttackRoundConfig({required this.phase, required this.percentage})
    : assert(percentage > 0 && percentage <= 1);

  /// Round süresi yalnızca toplam saldırı süresi × round yüzdesidir.
  Duration durationFor(Duration totalAttackDuration) =>
      Duration(seconds: (totalAttackDuration.inSeconds * percentage).round());

  /// Roundun toplam adım hedefindeki payı.
  ///
  /// Mevcut combat motoru round tamamlanmasını `yürünen / hedef` oranıyla
  /// ölçüyor. Süre payını adım payı olarak da kullanmak, bütün roundlarda aynı
  /// hedef kadansı korur ve beş round hedefinin toplamını seçilen hedefe eşitler.
  int stepTargetFor(int totalStepTarget) =>
      (totalStepTarget * percentage).round();
}

/// Seçilebilir tek bir saldırı hedefi ve ona bağlı denge değerleri.
class AttackTargetConfig {
  final int stepTarget;
  final Duration totalAttackDuration;
  final double enemyPowerMultiplier;

  const AttackTargetConfig({
    required this.stepTarget,
    required this.totalAttackDuration,
    required this.enemyPowerMultiplier,
  }) : assert(stepTarget > 0),
       assert(enemyPowerMultiplier > 0);

  List<Duration> get roundDurations => List.unmodifiable(
    AttackConfig.rounds.map((round) => round.durationFor(totalAttackDuration)),
  );

  Duration roundDuration(int zeroBasedRoundIndex) {
    RangeError.checkValidIndex(
      zeroBasedRoundIndex,
      AttackConfig.rounds,
      'zeroBasedRoundIndex',
    );
    return AttackConfig.rounds[zeroBasedRoundIndex].durationFor(
      totalAttackDuration,
    );
  }

  int roundStepTarget(int zeroBasedRoundIndex) {
    RangeError.checkValidIndex(
      zeroBasedRoundIndex,
      AttackConfig.rounds,
      'zeroBasedRoundIndex',
    );
    return AttackConfig.rounds[zeroBasedRoundIndex].stepTargetFor(stepTarget);
  }
}

/// Attack UI, round zamanlaması ve düşman ölçeklemesinin tek doğruluk kaynağı.
abstract final class AttackConfig {
  static const int version = 1;
  static const int roundCount = 5;

  static const List<AttackRoundConfig> rounds = [
    AttackRoundConfig(phase: AttackPhase.warmUp, percentage: 0.15),
    AttackRoundConfig(phase: AttackPhase.attack, percentage: 0.25),
    AttackRoundConfig(phase: AttackPhase.rush, percentage: 0.20),
    AttackRoundConfig(phase: AttackPhase.recovery, percentage: 0.15),
    AttackRoundConfig(phase: AttackPhase.finalRush, percentage: 0.25),
  ];

  static const List<AttackTargetConfig> targets = [
    AttackTargetConfig(
      stepTarget: 500,
      totalAttackDuration: Duration(minutes: 5),
      enemyPowerMultiplier: 1.00,
    ),
    AttackTargetConfig(
      stepTarget: 1000,
      totalAttackDuration: Duration(minutes: 8),
      enemyPowerMultiplier: 1.15,
    ),
    AttackTargetConfig(
      stepTarget: 2000,
      totalAttackDuration: Duration(minutes: 12),
      enemyPowerMultiplier: 1.35,
    ),
    AttackTargetConfig(
      stepTarget: 3000,
      totalAttackDuration: Duration(minutes: 15),
      enemyPowerMultiplier: 1.55,
    ),
    AttackTargetConfig(
      stepTarget: 5000,
      totalAttackDuration: Duration(minutes: 20),
      enemyPowerMultiplier: 1.85,
    ),
    AttackTargetConfig(
      stepTarget: 10000,
      totalAttackDuration: Duration(minutes: 30),
      enemyPowerMultiplier: 2.40,
    ),
  ];

  static List<int> get supportedStepTargets =>
      List.unmodifiable(targets.map((target) => target.stepTarget));

  static double get roundPercentageTotal =>
      rounds.fold(0, (total, round) => total + round.percentage);

  static bool get hasValidRoundPercentages =>
      rounds.length == roundCount &&
      (roundPercentageTotal - 1).abs() < 0.000000001;

  static AttackTargetConfig forStepTarget(int stepTarget) {
    if (!hasValidRoundPercentages) {
      throw StateError('Attack round percentages must total exactly 100%.');
    }
    for (final target in targets) {
      if (target.stepTarget == stepTarget) return target;
    }
    throw ArgumentError.value(
      stepTarget,
      'stepTarget',
      'Supported values: ${supportedStepTargets.join(', ')}',
    );
  }

  static bool supportsStepTarget(int stepTarget) =>
      targets.any((target) => target.stepTarget == stepTarget);

  /// Eski kayıtlardaki artık seçilemeyen 500'lük hedefleri veri kaybetmeden
  /// yeni tabloya taşımak için en yakın üst hedef. Yeni saldırılar [forStepTarget]
  /// ile katı doğrulanır; bu yalnızca deserialize/migration sınırında kullanılır.
  static int migrateLegacyStepTarget(int legacyStepTarget) {
    for (final target in targets) {
      if (legacyStepTarget <= target.stepTarget) return target.stepTarget;
    }
    return targets.last.stepTarget;
  }
}
