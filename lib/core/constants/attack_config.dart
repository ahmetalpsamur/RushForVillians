import 'game_constants.dart';

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
    AttackPhase.warmUp => '100 adım/dk ritmini yakala.',
    AttackPhase.attack => 'Ritmini koru ve hedefe odaklan.',
    AttackPhase.rush => 'Erken bitirme bonusu için ritmi aksatma.',
    AttackPhase.recovery => 'Durma; 100 adım/dk ritmini koru.',
    AttackPhase.finalRush => 'Seriyi korumak için son hedefi tamamla.',
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
  final double enemyPowerMultiplier;

  const AttackTargetConfig({
    required this.stepTarget,
    required this.enemyPowerMultiplier,
  }) : assert(stepTarget > 0),
       assert(enemyPowerMultiplier > 0);

  Duration get totalAttackDuration => AttackConfig.durationForSteps(stepTarget);

  int get roundCount => AttackConfig.roundCountForSteps(stepTarget);

  List<int> get roundStepTargets => List.unmodifiable(
    List.generate(roundCount, (index) => roundStepTarget(index)),
  );

  List<Duration> get roundDurations =>
      List.unmodifiable(roundStepTargets.map(AttackConfig.durationForSteps));

  Duration roundDuration(int zeroBasedRoundIndex) {
    RangeError.checkValidIndex(
      zeroBasedRoundIndex,
      List.filled(roundCount, 0),
      'zeroBasedRoundIndex',
    );
    return AttackConfig.durationForSteps(roundStepTarget(zeroBasedRoundIndex));
  }

  int roundStepTarget(int zeroBasedRoundIndex) {
    RangeError.checkValidIndex(
      zeroBasedRoundIndex,
      List.filled(roundCount, 0),
      'zeroBasedRoundIndex',
    );
    final remaining =
        stepTarget -
        (zeroBasedRoundIndex * GameConstants.combatRoundStepTarget);
    return remaining.clamp(1, GameConstants.combatRoundStepTarget);
  }
}

/// Attack UI, round zamanlaması ve düşman ölçeklemesinin tek doğruluk kaynağı.
abstract final class AttackConfig {
  static const int version = 2;

  static const List<AttackRoundConfig> rounds = [
    AttackRoundConfig(phase: AttackPhase.warmUp, percentage: 0.15),
    AttackRoundConfig(phase: AttackPhase.attack, percentage: 0.25),
    AttackRoundConfig(phase: AttackPhase.rush, percentage: 0.20),
    AttackRoundConfig(phase: AttackPhase.recovery, percentage: 0.15),
    AttackRoundConfig(phase: AttackPhase.finalRush, percentage: 0.25),
  ];

  static const List<AttackTargetConfig> targets = [
    AttackTargetConfig(stepTarget: 500, enemyPowerMultiplier: 1.00),
    AttackTargetConfig(stepTarget: 1000, enemyPowerMultiplier: 1.15),
    AttackTargetConfig(stepTarget: 2000, enemyPowerMultiplier: 1.35),
    AttackTargetConfig(stepTarget: 3000, enemyPowerMultiplier: 1.55),
    AttackTargetConfig(stepTarget: 5000, enemyPowerMultiplier: 1.85),
    AttackTargetConfig(stepTarget: 10000, enemyPowerMultiplier: 2.40),
  ];

  /// Toplam hedeften sabit 1000 adımlık round sayısını türetir.
  static int roundCountForSteps(int stepTarget) {
    if (stepTarget <= 0) return 0;
    return (stepTarget / GameConstants.combatRoundStepTarget).ceil();
  }

  /// Verilen adım hedefinin kaç sabit round sürdüğünü döndürür.
  ///
  /// Son round 1000 adımdan kısa olsa bile eski sistemde süresi 15 dakikadır.
  static Duration durationForSteps(int steps) {
    if (steps <= 0) return Duration.zero;
    return GameConstants.combatRoundDuration * roundCountForSteps(steps);
  }

  /// Değişken round sayısında kullanılacak fitness fazını seçer.
  static AttackRoundConfig roundConfig(int index, int roundCount) {
    if (roundCount > rounds.length) {
      RangeError.checkValidIndex(index, List.filled(roundCount, 0), 'index');
      return rounds[index.clamp(0, rounds.length - 1)];
    }
    final phaseIndexes = switch (roundCount) {
      1 => const [4],
      2 => const [1, 4],
      3 => const [0, 1, 4],
      4 => const [0, 1, 3, 4],
      _ => const [0, 1, 2, 3, 4],
    };
    RangeError.checkValidIndex(index, phaseIndexes, 'index');
    return rounds[phaseIndexes[index]];
  }

  static List<int> get supportedStepTargets =>
      List.unmodifiable(targets.map((target) => target.stepTarget));

  static double get roundPercentageTotal =>
      rounds.fold(0, (total, round) => total + round.percentage);

  static bool get hasValidRoundPercentages =>
      rounds.length == GameConstants.maxCombatRounds &&
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
