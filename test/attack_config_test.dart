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
          (500, 1, 7, 1.00),
          (1000, 2, 14, 1.15),
          (2000, 4, 28, 1.35),
          (3000, 3, 45, 1.55),
          (5000, 5, 75, 1.85),
          (10000, 10, 150, 2.40),
        ],
      );
    });

    test('tempo iki bant: 500/7dk ve 1.000/15dk', () {
      // Bölüm D: kadans artık bantlar arasında sabit **değil** (71 vs 67
      // adım/dk) — tempo bir denge kararı, bir bölme işlemi değil. Test
      // sabit kopyalamıyor, tablonun kendisini okuyor.
      for (final row in GameConstants.combatRoundPacing) {
        final expected = row.minGoal < 3000
            ? (steps: 500, seconds: 420)
            : (steps: 1000, seconds: 900);
        expect(row.roundSteps, expected.steps, reason: 'bant ${row.minGoal}');
        expect(
          row.roundSeconds,
          expected.seconds,
          reason: 'bant ${row.minGoal}',
        );
      }
      // Kadans insan temposunun altında kalsın: yürüyen oyuncu roundu
      // erken bitirebilmeli, koşmak zorunda kalmamalı.
      for (final row in GameConstants.combatRoundPacing) {
        expect(
          row.roundSteps / (row.roundSeconds / 60),
          lessThan(GameConstants.stepsPerMinute),
          reason: 'bant ${row.minGoal} kadansı referans tempoyu aşıyor',
        );
      }
    });

    test('round sayısı tempo tablosundan türetilir ve tavanla sınırlı', () {
      expect(AttackConfig.rounds, hasLength(5));
      expect(AttackConfig.hasValidRoundPercentages, isTrue);
      expect(AttackConfig.roundPercentageTotal, closeTo(1, 0.000000001));
      expect(AttackConfig.roundCountForSteps(500), 1);
      expect(AttackConfig.roundCountForSteps(1000), 2);
      expect(AttackConfig.roundCountForSteps(1500), 3);
      // Tavan tabloya eşit: 10.000 / 1.000 = 10, yani bağlamıyor.
      expect(AttackConfig.roundCountForSteps(10000), 10);
      // Hiçbir hedef tavanı aşamaz; eski kayıttan gelen devasa hedefte round
      // sayısı tavanda kalır, roundun kendisi büyür.
      for (final steps in [500, 1500, 10000, 15000, 100000]) {
        expect(
          AttackConfig.roundCountForSteps(steps),
          lessThanOrEqualTo(GameConstants.maxCombatRounds),
        );
      }
      expect(AttackConfig.roundStepsFor(100000), greaterThan(1000));
    });

    test('round adımları ve süreleri toplam hedefi eksiksiz paylaşır', () {
      final short = AttackConfig.forStepTarget(500);
      expect(short.roundStepTargets, [500]);
      expect(short.roundDurations.map((d) => d.inMinutes), [7]);
      final medium = AttackConfig.forStepTarget(1000);
      expect(medium.roundStepTargets, [500, 500]);
      expect(medium.roundDurations.map((d) => d.inMinutes), [7, 7]);
      final long = AttackConfig.forStepTarget(10000);
      expect(long.roundStepTargets, List.filled(10, 1000));
      expect(long.roundDurations.map((d) => d.inMinutes), List.filled(10, 15));
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

  // [scaleEnemyCombatStats] yardımcısı değişmedi: hem saldırıyı hem canı
  // ölçekliyor. Değişen şey **çağrı noktası**: `enemyStatsForGoal` artık
  // çarpanı yalnızca saldırıya uyguluyor (GD101), canı adım taahhüdünden
  // kuruyor. Yardımcının kendi sözleşmesi burada bozulmadan duruyor.
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
