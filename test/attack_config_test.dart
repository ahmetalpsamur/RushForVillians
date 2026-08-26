import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/attack_config.dart';
import 'package:rush_for_villains/core/utils/enemy_stats.dart';
import 'package:rush_for_villains/models/combat_stats.dart';

void main() {
  group('AttackConfig tek doğruluk kaynağı', () {
    test('altı hedef süre ve düşman çarpanlarıyla eşleşir', () {
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
          (1000, 8, 1.15),
          (2000, 12, 1.35),
          (3000, 15, 1.55),
          (5000, 20, 1.85),
          (10000, 30, 2.40),
        ],
      );
    });

    test('her hedef tam beş round ve yüzde 100 kullanır', () {
      expect(AttackConfig.rounds, hasLength(5));
      expect(AttackConfig.hasValidRoundPercentages, isTrue);
      expect(AttackConfig.roundPercentageTotal, closeTo(1, 0.000000001));

      for (final target in AttackConfig.targets) {
        expect(target.roundDurations, hasLength(5));
        expect(
          target.roundDurations.fold<int>(
            0,
            (total, duration) => total + duration.inSeconds,
          ),
          target.totalAttackDuration.inSeconds,
        );
      }
    });

    test('round süreleri toplam süre çarpı yüzde formülünden gelir', () {
      expect(
        AttackConfig.forStepTarget(
          500,
        ).roundDurations.map((duration) => duration.inSeconds),
        [45, 75, 60, 45, 75],
      );
      expect(
        AttackConfig.forStepTarget(
          10000,
        ).roundDurations.map((duration) => duration.inSeconds),
        [270, 450, 360, 270, 450],
      );
    });

    test('faz sırası ve aktif recovery açıklaması sabittir', () {
      expect(
        AttackConfig.rounds.map((round) => round.phase),
        AttackPhase.values,
      );
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
