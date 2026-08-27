import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/attack_config.dart';
import 'package:rush_for_villains/core/utils/enemy_stats.dart';
import 'package:rush_for_villains/models/combat_stats.dart';

void main() {
  group('AttackConfig tek doğruluk kaynağı', () {
    test('altı hedef süreyi tek 100 adım/dk sabitinden türetir', () {
      expect(
        AttackConfig.targets
            .map(
              (config) => (
                config.stepTarget,
                config.totalAttackDuration.inMinutes,
                config.enemyPowerMultiplier,
              ),
            )
            .toList(),
        [
          (500, 5, 1.00),
          (1000, 10, 1.15),
          (2000, 20, 1.35),
          (3000, 30, 1.55),
          (5000, 50, 1.85),
          (10000, 100, 2.40),
        ],
      );
    });

    test('round sayısı 250 hedefine göre 2–5 arasında türetilir', () {
      expect(AttackConfig.rounds, hasLength(5));
      expect(AttackConfig.hasValidRoundPercentages, isTrue);
      expect(AttackConfig.roundPercentageTotal, closeTo(1, 0.000000001));
      expect(AttackConfig.roundCountForSteps(500), 2);
      expect(AttackConfig.roundCountForSteps(1000), 4);
      expect(AttackConfig.roundCountForSteps(1500), 5);
      expect(AttackConfig.roundCountForSteps(10000), 5);
    });

    test('round adımları ve süreleri toplam hedefi eksiksiz paylaşır', () {
      final short = AttackConfig.forStepTarget(500);
      expect(short.roundStepTargets, [250, 250]);
      expect(short.roundDurations.map((duration) => duration.inSeconds), [
        150,
        150,
      ]);
      final medium = AttackConfig.forStepTarget(1000);
      expect(medium.roundStepTargets, [250, 250, 250, 250]);
      expect(medium.roundDurations.map((duration) => duration.inSeconds), [
        150,
        150,
        150,
        150,
      ]);
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

    test('faz sırası ve aktif recovery açıklaması sabittir', () {
      expect(AttackConfig.roundConfig(0, 2).phase, AttackPhase.attack);
      expect(AttackConfig.roundConfig(1, 2).phase, AttackPhase.finalRush);
      expect(
        AttackPhase.recovery.fitnessDescription.toLowerCase(),
        contains('durma'),
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
