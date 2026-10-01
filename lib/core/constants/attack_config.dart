import 'game_constants.dart';

/// Bir saldırının değişmeyen beş yürüyüş yoğunluğu.
///
/// Sıra bu enumun sırasıdır ve oyun kuralıdır; kayıtta ordinal yerine [name]
/// kullanılırsa ileride okunabilir kalır.
enum AttackPhase { warmUp, attack, rush, recovery, finalRush }

// `AttackPhase`'in kullanıcıya dönük etiketleri (`label`,
// `fitnessDescription`) **kaldırıldı**: hiçbir ekranda gösterilmiyorlardı ve
// sabit Türkçe taşıyorlardı. Faz enum'u duruyor — `CombatRoundResult.phase`
// üzerinden taşınıyor ve round anlatısı ileride arayüze çıkarsa metinler
// ARB'den gelmeli, buradan değil.

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

  /// Bütün roundlar aynı süreyi alır; tempo bant içinde sabit.
  List<Duration> get roundDurations => List.unmodifiable(
    List.filled(roundCount, AttackConfig.roundDurationFor(stepTarget)),
  );

  Duration roundDuration(int zeroBasedRoundIndex) {
    RangeError.checkValidIndex(
      zeroBasedRoundIndex,
      List.filled(roundCount, 0),
      'zeroBasedRoundIndex',
    );
    return AttackConfig.roundDurationFor(stepTarget);
  }

  int roundStepTarget(int zeroBasedRoundIndex) {
    RangeError.checkValidIndex(
      zeroBasedRoundIndex,
      List.filled(roundCount, 0),
      'zeroBasedRoundIndex',
    );
    final roundSteps = AttackConfig.roundStepsFor(stepTarget);
    final remaining = stepTarget - (zeroBasedRoundIndex * roundSteps);
    return remaining.clamp(1, roundSteps);
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

  /// [stepTarget] için geçerli tempo satırı: `minGoal`'ü hedefi aşmayan son
  /// satır. Tablo `minGoal: 0` ile başladığı için her zaman bir satır döner.
  static ({
    int minGoal,
    int roundSteps,
    int roundSeconds,
    double rewardMultiplier,
  })
  paceFor(int stepTarget) {
    var pace = GameConstants.combatRoundPacing.first;
    for (final row in GameConstants.combatRoundPacing) {
      if (stepTarget >= row.minGoal) pace = row;
    }
    return pace;
  }

  /// Bir roundun adım hedefi.
  ///
  /// Normalde doğrudan tablodan gelir. Yalnızca tablo değeri
  /// [GameConstants.maxCombatRounds]'tan fazla round üretecekse büyütülür —
  /// round sayısı tavanda kalsın, roundlar uzasın.
  static int roundStepsFor(int stepTarget) {
    if (stepTarget <= 0) return 0;
    final tableSteps = paceFor(stepTarget).roundSteps;
    final uncapped = (stepTarget / tableSteps).ceil();
    if (uncapped <= GameConstants.maxCombatRounds) return tableSteps;
    return (stepTarget / GameConstants.maxCombatRounds).ceil();
  }

  /// Bir roundun süresi. Bütün roundlar eşit; tempo bant içinde sabit.
  ///
  /// Round boyu tavan yüzünden büyüdüyse süre de aynı oranda büyür, yoksa
  /// kadans (adım/dakika) bozulurdu.
  static Duration roundDurationFor(int stepTarget) {
    if (stepTarget <= 0) return Duration.zero;
    final pace = paceFor(stepTarget);
    final actualSteps = roundStepsFor(stepTarget);
    final seconds = pace.roundSeconds * actualSteps / pace.roundSteps;
    return Duration(seconds: seconds.round());
  }

  /// Hedefin kaç rounda bölündüğü. [GameConstants.maxCombatRounds] ile sınırlı.
  static int roundCountForSteps(int stepTarget) {
    if (stepTarget <= 0) return 0;
    final count = (stepTarget / roundStepsFor(stepTarget)).ceil();
    return count.clamp(1, GameConstants.maxCombatRounds);
  }

  /// Maceranın **toplam** süresi: round sayısı × round süresi.
  static Duration durationForSteps(int steps) {
    if (steps <= 0) return Duration.zero;
    return roundDurationFor(steps) * roundCountForSteps(steps);
  }

  /// Hedefin bandındaki zafer ödülü çarpanı (aynı tempo tablosundan).
  static double rewardMultiplierFor(int stepTarget) =>
      stepTarget <= 0 ? 0 : paceFor(stepTarget).rewardMultiplier;

  /// Zafer altınının çekiliş aralığı: kademe tabanı × bandın ödül çarpanı.
  ///
  /// İki eksen bilinçli olarak ayrı: **kademe** hangi düşmanı devirdiğini,
  /// **bant** ne kadar yürümeyi göze aldığını ödüllendirir. Aynı düşmanı
  /// daha uzun bir taahhütle devirmek daha çok kazandırır, ama düşman da
  /// [AttackTargetConfig.enemyPowerMultiplier] ile güçlenir — ödül tek başına
  /// artmaz.
  static ({int minimum, int maximum}) victoryCoinRange({
    required int tier,
    required int stepGoal,
  }) {
    final multiplier = rewardMultiplierFor(stepGoal);
    final minimum =
        GameConstants.victoryCoinBase + tier * GameConstants.victoryCoinPerTier;
    final maximum =
        GameConstants.victoryCoinSpreadBase +
        tier * GameConstants.victoryCoinSpreadPerTier;
    return (
      minimum: (minimum * multiplier).round(),
      maximum: (maximum * multiplier).round(),
    );
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

  /// Faz yüzdeleri tam %100 ediyor mu.
  ///
  /// Ölçüt [AttackPhase.values]; bir dönem [GameConstants.maxCombatRounds]'a
  /// bağlıydı ve ikisi tesadüfen 5'ti. Round tavanı 10'a çıkınca o bağ
  /// `forStepTarget`'ı hata fırlatır hâle getirdi — faz sayısı bir **anlatı**
  /// kararı (ısınma → atak → final), round sayısı bir **tempo** kararı.
  static bool get hasValidRoundPercentages =>
      rounds.length == AttackPhase.values.length &&
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
