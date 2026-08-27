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

  /// Fazın saldırı süresindeki tarihsel payı.
  ///
  /// **Round süresi artık buradan gelmiyor** (GD85): süre kademe tablosunda
  /// elle yazılı. Yüzdeler yalnızca fazların ağırlığını ve
  /// [AttackConfig.hasValidRoundPercentages] doğrulamasını taşıyor.
  Duration durationFor(Duration totalAttackDuration) =>
      Duration(seconds: (totalAttackDuration.inSeconds * percentage).round());

  /// Fazın toplam adım hedefindeki tarihsel payı. Süre gibi, artık round
  /// hedefini **belirlemiyor**; round adımı kademe tablosundan geliyor.
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

  Duration get totalAttackDuration =>
      AttackConfig.totalDurationForSteps(stepTarget);

  int get roundCount => AttackConfig.roundCountForSteps(stepTarget);

  List<int> get roundStepTargets =>
      AttackConfig.roundStepTargetsForSteps(stepTarget);

  List<Duration> get roundDurations =>
      AttackConfig.roundDurationsForSteps(stepTarget);

  Duration roundDuration(int zeroBasedRoundIndex) =>
      AttackConfig.roundDurationAt(stepTarget, zeroBasedRoundIndex);

  int roundStepTarget(int zeroBasedRoundIndex) =>
      AttackConfig.roundStepTargetAt(stepTarget, zeroBasedRoundIndex);
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

  /// Toplam hedefin düştüğü **round büyüklüğü kademesi** (GD85).
  ///
  /// Eşiğin altında kalan hedefler ilk kademeye düşer; tablo baştan sona
  /// tarandığı için sıralaması bozulsa bile en büyük uygun kademe kazanır.
  static CombatRoundTier roundTierForSteps(int stepTarget) {
    var selected = GameConstants.combatRoundTiers.first;
    for (final tier in GameConstants.combatRoundTiers) {
      if (stepTarget >= tier.minTotalSteps &&
          tier.minTotalSteps >= selected.minTotalSteps) {
        selected = tier;
      }
    }
    return selected;
  }

  /// Toplam hedefin kademesindeki **tam** round adımı.
  static int roundStepsForSteps(int stepTarget) =>
      roundTierForSteps(stepTarget).roundSteps;

  /// Toplam hedefin kademesindeki **tam** round süresi.
  static Duration roundDurationForTier(int stepTarget) =>
      roundTierForSteps(stepTarget).roundDuration;

  /// Toplam hedeften round sayısını **sabit tablodan** okur (GD85).
  ///
  /// Tam bölünmeyen hedeflerde kalan adımlar kısa bir son round olur; kalıntı
  /// [GameConstants.minFinalRoundSteps] altındaysa ayrı round sayılmaz ve bir
  /// önceki rounda katılır.
  static int roundCountForSteps(int stepTarget) {
    if (stepTarget <= 0) return 0;
    final size = roundStepsForSteps(stepTarget);
    final full = stepTarget ~/ size;
    final remainder = stepTarget % size;
    if (full == 0) return 1;
    if (remainder == 0 || remainder < GameConstants.minFinalRoundSteps) {
      return full;
    }
    return full + 1;
  }

  /// Sıfır tabanlı [zeroBasedRoundIndex] roundunun adım hedefi.
  static int roundStepTargetAt(int stepTarget, int zeroBasedRoundIndex) {
    final count = roundCountForSteps(stepTarget);
    RangeError.checkValidIndex(
      zeroBasedRoundIndex,
      List.filled(count, 0),
      'zeroBasedRoundIndex',
    );
    final size = roundStepsForSteps(stepTarget);
    if (zeroBasedRoundIndex < count - 1) return size;
    // Son round toplamın geri kalanını taşır: tam bölünüyorsa tam boy, kalıntı
    // varsa kısa, yuvarlama artığı varsa tam boy + artık.
    return stepTarget - size * (count - 1);
  }

  /// Sıfır tabanlı [zeroBasedRoundIndex] roundunun süresi.
  ///
  /// Tam boy roundun süresi kademe tablosundan **olduğu gibi** gelir; kısalan
  /// son roundun süresi adım oranıyla ölçeklenir.
  static Duration roundDurationAt(int stepTarget, int zeroBasedRoundIndex) {
    final tier = roundTierForSteps(stepTarget);
    final steps = roundStepTargetAt(stepTarget, zeroBasedRoundIndex);
    if (steps == tier.roundSteps) return tier.roundDuration;
    return Duration(
      microseconds:
          (tier.roundDuration.inMicroseconds * steps / tier.roundSteps).round(),
    );
  }

  static List<int> roundStepTargetsForSteps(int stepTarget) => List.unmodifiable(
    List.generate(
      roundCountForSteps(stepTarget),
      (index) => roundStepTargetAt(stepTarget, index),
    ),
  );

  static List<Duration> roundDurationsForSteps(int stepTarget) =>
      List.unmodifiable(
        List.generate(
          roundCountForSteps(stepTarget),
          (index) => roundDurationAt(stepTarget, index),
        ),
      );

  /// Bir saldırının toplam süresi: round sürelerinin toplamı.
  static Duration totalDurationForSteps(int stepTarget) =>
      roundDurationsForSteps(
        stepTarget,
      ).fold(Duration.zero, (total, duration) => total + duration);

  /// Adım miktarını 100 adım/dakika temposunda geçen süreye çevirir.
  ///
  /// Round süreleri artık kademe tablosundan geliyor; bu yardımcı yalnızca
  /// "şu kadar adım şu kadar sürer" biçimindeki **anlatım** metinleri ve
  /// round dışı hesaplar için duruyor.
  static Duration durationForSteps(int steps) {
    if (steps <= 0) return Duration.zero;
    return Duration(
      seconds: (steps * 60 / GameConstants.stepsPerMinute).ceil(),
    );
  }

  /// Roundun hasar ağırlığı: kaç **referans round** (250 adım) ediyor (GD86).
  ///
  /// Oyuncunun vuruşu bu ağırlıkla ölçekleniyor; 2000 adımlık bir round
  /// 250 adımlık rounddan sekiz kat ağır bir taahhüt, sekiz kat ağır bir vuruş.
  static double roundWeightForSteps(int roundSteps) {
    if (roundSteps <= 0) return 0;
    return roundSteps / GameConstants.referenceRoundSteps;
  }

  /// Bir saldırının toplam hasar ağırlığı = `toplamAdım / 250`.
  ///
  /// Düşman canı bu birimle ölçülüyor (`enemy_stats.dart`), yani hedefi
  /// tutturan ölçüt oyuncu maceranın **sonunda** devirir; kademe tablosu
  /// değişse bile bu söz bozulmaz.
  static double totalRoundWeightForSteps(int stepTarget) =>
      stepTarget <= 0 ? 0 : roundWeightForSteps(stepTarget);

  /// Değişken round sayısında kullanılacak fitness fazını seçer.
  ///
  /// Beş faz sabit; round sayısı kademe tablosuyla 10 ve üstüne çıkabildiği
  /// için beşten uzun saldırılarda uçlar (WARM-UP / FINAL RUSH) korunur ve
  /// aradaki roundlar ATTACK · RUSH · RECOVERY üçlüsünü sırayla paylaşır.
  static AttackRoundConfig roundConfig(int index, int roundCount) {
    if (roundCount <= 5) {
      final phaseIndexes = switch (roundCount) {
        <= 1 => const [4],
        2 => const [1, 4],
        3 => const [0, 1, 4],
        4 => const [0, 1, 3, 4],
        _ => const [0, 1, 2, 3, 4],
      };
      RangeError.checkValidIndex(index, phaseIndexes, 'index');
      return rounds[phaseIndexes[index]];
    }
    RangeError.checkValidIndex(index, List.filled(roundCount, 0), 'index');
    if (index == 0) return rounds[0];
    if (index == roundCount - 1) return rounds[4];
    final middleCount = roundCount - 2;
    final middleIndex = index - 1;
    return rounds[1 + (middleIndex * 3) ~/ middleCount];
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
