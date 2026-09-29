import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/attack_config.dart';
import 'package:rush_for_villains/core/constants/game_constants.dart';
import 'package:rush_for_villains/core/utils/enemy_stats.dart';
import 'package:rush_for_villains/models/combat_stats.dart';

void main() {
  group('AttackConfig tek doğruluk kaynağı', () {
    test('altı hedef tempo tablosunun verdiği rounda bölünür', () {
      expect(
        AttackConfig.targets
            .map(
              (config) => (
                config.stepTarget,
                config.roundCount,
                config.totalAttackDuration.inMinutes,
                config.enemyPowerMultiplier,
              ),
            )
            .toList(),
        [
          (500, 2, 5, 1.00),
          (1000, 2, 10, 1.15),
          (2000, 4, 20, 1.35),
          (3000, 3, 30, 1.55),
          (5000, 5, 50, 1.85),
          (10000, 5, 100, 2.40),
        ],
      );
    });

    test('kadans bütün bantlarda stepsPerMinute ile aynı', () {
      // Tablonun asıl vaadi bu: bant değişince round büyür ama oyuncudan
      // istenen tempo değişmez.
      for (final row in GameConstants.combatRoundPacing) {
        expect(
          row.roundSteps / (row.roundSeconds / 60),
          closeTo(GameConstants.stepsPerMinute, 0.001),
          reason: 'bant ${row.minGoal}',
        );
      }
    });

    test('round sayısı tempo tablosundan türetilir ve tavanla sınırlı', () {
      expect(AttackConfig.rounds, hasLength(5));
      expect(AttackConfig.hasValidRoundPercentages, isTrue);
      expect(AttackConfig.roundPercentageTotal, closeTo(1, 0.000000001));
      expect(AttackConfig.roundCountForSteps(500), 2);
      expect(AttackConfig.roundCountForSteps(1000), 2);
      expect(AttackConfig.roundCountForSteps(1500), 3);
      expect(AttackConfig.roundCountForSteps(10000), 5);
      // Hiçbir hedef tavanı aşamaz; eski kayıttan gelen devasa hedefte round
      // sayısı tavanda kalır, roundun kendisi büyür.
      for (final steps in [500, 1500, 10000, 15000, 100000]) {
        expect(
          AttackConfig.roundCountForSteps(steps),
          lessThanOrEqualTo(GameConstants.maxCombatRounds),
        );
      }
      expect(AttackConfig.roundStepsFor(100000), greaterThan(2000));
    });

    test('round adımları ve süreleri toplam hedefi eksiksiz paylaşır', () {
      final short = AttackConfig.forStepTarget(500);
      expect(short.roundStepTargets, [250, 250]);
      expect(short.roundDurations.map((d) => d.inSeconds), [150, 150]);
      final medium = AttackConfig.forStepTarget(1000);
      expect(medium.roundStepTargets, [500, 500]);
      expect(medium.roundDurations.map((d) => d.inMinutes), [5, 5]);
      for (final target in AttackConfig.targets) {
        expect(
          target.roundStepTargets.reduce((a, b) => a + b),
          target.stepTarget,
        );
        expect(
          target.roundDurations.fold<int>(
            0,
            (sum, value) => sum + value.inSeconds,
          ),
          target.totalAttackDuration.inSeconds,
        );
      }
    });

    test('faz sırası round sayısına göre sabittir', () {
      expect(AttackConfig.roundConfig(0, 2).phase, AttackPhase.attack);
      expect(AttackConfig.roundConfig(1, 2).phase, AttackPhase.finalRush);
      // Beş roundda bütün fazlar sırayla geçer.
      expect(
        [for (var i = 0; i < 5; i++) AttackConfig.roundConfig(i, 5).phase],
        AttackPhase.values,
      );
    });

    test('desteklenmeyen yeni hedef reddedilir, eski kayıt taşınır', () {
      expect(() => AttackConfig.forStepTarget(1500), throwsArgumentError);
      expect(AttackConfig.migrateLegacyStepTarget(1500), 2000);
      expect(AttackConfig.migrateLegacyStepTarget(9000), 10000);
    });
  });

  test('düşman çarpanı taban statlara bir kez uygulanır', () {
    const base = CombatStats(attack: 20, defense: 8, maxHealth: 100);
    final scaled = scaleEnemyCombatStats(base, 1.85);

    expect(scaled.attack, 37);
    expect(scaled.maxHealth, 185);
    expect(scaled.defense, base.defense);

    // Roundlar ölçeklenmiş sonucu yeniden ölçeklemez; çağrı noktası her zaman
    // katalog tabanını verir.
    final nextRound = scaleEnemyCombatStats(base, 1.85);
    expect(nextRound.attack, scaled.attack);
    expect(nextRound.maxHealth, scaled.maxHealth);
  });
}
