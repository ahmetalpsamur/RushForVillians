import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/attack_config.dart';
import 'package:rush_for_villains/core/utils/enemy_stats.dart';
import 'package:rush_for_villains/models/combat_stats.dart';

void main() {
  group('AttackConfig tek doğruluk kaynağı', () {
    test('altı hedefin toplam süresi round sürelerinin toplamıdır', () {
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

    // --- Bölüm B.1: sabit kademe tablosunun dokuz örneği ---
    //
    // Her satır ayrı ayrı doğrulanıyor: doğru round adımı, doğru round süresi,
    // doğru round sayısı. Tablo elle yazılı; hiçbiri formülle türetilmiyor.
    const beklenen = <(int, int, int, int)>[
      // (toplam adım, round adımı, round süresi (saniye), round sayısı)
      (500, 250, 150, 2),
      (1000, 500, 300, 2),
      (1500, 500, 300, 3),
      (2000, 500, 300, 4),
      (2500, 500, 300, 5),
      (3000, 1000, 600, 3),
      (9000, 1000, 600, 9),
      (10000, 2000, 1200, 5),
      (20000, 2000, 1200, 10),
    ];

    for (final (toplam, roundAdimi, roundSaniye, roundSayisi) in beklenen) {
      test('$toplam adım → $roundSayisi × $roundAdimi adım', () {
        expect(
          AttackConfig.roundStepsForSteps(toplam),
          roundAdimi,
          reason: '$toplam adımın round adımı',
        );
        expect(
          AttackConfig.roundDurationForTier(toplam).inSeconds,
          roundSaniye,
          reason: '$toplam adımın round süresi',
        );
        expect(
          AttackConfig.roundCountForSteps(toplam),
          roundSayisi,
          reason: '$toplam adımın round sayısı',
        );
        expect(
          AttackConfig.roundStepTargetsForSteps(toplam),
          List.filled(roundSayisi, roundAdimi),
        );
        expect(
          AttackConfig.roundDurationsForSteps(
            toplam,
          ).map((duration) => duration.inSeconds),
          List.filled(roundSayisi, roundSaniye),
        );
        // Tempo tablodan geliyor ama 100 adım/dk kadansı bozulmuyor.
        expect(
          AttackConfig.totalDurationForSteps(toplam).inSeconds,
          toplam * 60 ~/ 100,
        );
      });
    }

    test('kademe eşiklerinin iki yanı ayrışır', () {
      expect(AttackConfig.roundStepsForSteps(999), 250);
      expect(AttackConfig.roundStepsForSteps(1000), 500);
      expect(AttackConfig.roundStepsForSteps(2999), 500);
      expect(AttackConfig.roundStepsForSteps(3000), 1000);
      expect(AttackConfig.roundStepsForSteps(9999), 1000);
      expect(AttackConfig.roundStepsForSteps(10000), 2000);

      expect(AttackConfig.roundDurationForTier(999).inSeconds, 150);
      expect(AttackConfig.roundDurationForTier(1000).inMinutes, 5);
      expect(AttackConfig.roundDurationForTier(2999).inMinutes, 5);
      expect(AttackConfig.roundDurationForTier(3000).inMinutes, 10);
      expect(AttackConfig.roundDurationForTier(9999).inMinutes, 10);
      expect(AttackConfig.roundDurationForTier(10000).inMinutes, 20);
    });

    test('artan bölüm kısa bir son round olur, süresi de orantılı kısalır', () {
      // 1200 = 2 × 500 + 200
      expect(AttackConfig.roundStepTargetsForSteps(1200), [500, 500, 200]);
      expect(
        AttackConfig.roundDurationsForSteps(
          1200,
        ).map((duration) => duration.inSeconds),
        [300, 300, 120],
      );
      // 1750 = 3 × 500 + 250
      expect(AttackConfig.roundStepTargetsForSteps(1750), [500, 500, 500, 250]);
      expect(
        AttackConfig.roundDurationsForSteps(
          1750,
        ).map((duration) => duration.inSeconds),
        [300, 300, 300, 150],
      );
      // 4500 = 4 × 1000 + 500
      expect(AttackConfig.roundStepTargetsForSteps(4500), [
        1000,
        1000,
        1000,
        1000,
        500,
      ]);
      expect(
        AttackConfig.roundDurationsForSteps(
          4500,
        ).map((duration) => duration.inSeconds),
        [600, 600, 600, 600, 300],
      );
    });

    test('yuvarlama artığı ayrı round olmaz, son rounda katılır', () {
      // 1010 = 2 × 500 + 10; 10 adımlık bir round round değil, artıktır.
      expect(AttackConfig.roundCountForSteps(1010), 2);
      expect(AttackConfig.roundStepTargetsForSteps(1010), [500, 510]);
      // Bir rounddan küçük hedef tek round olur.
      expect(AttackConfig.roundCountForSteps(200), 1);
      expect(AttackConfig.roundStepTargetsForSteps(200), [200]);
      expect(AttackConfig.roundCountForSteps(0), 0);
      expect(AttackConfig.roundStepTargetsForSteps(0), isEmpty);
    });

    test('round adımları toplam hedefi her zaman eksiksiz paylaşır', () {
      for (var steps = 100; steps <= 20000; steps += 50) {
        final parts = AttackConfig.roundStepTargetsForSteps(steps);
        expect(
          parts.reduce((a, b) => a + b),
          steps,
          reason: '$steps adım round adımlarına eksiksiz bölünmeli',
        );
        expect(parts.every((part) => part > 0), isTrue, reason: '$steps');
        expect(
          AttackConfig.totalDurationForSteps(steps).inMilliseconds,
          steps * 600,
          reason: '$steps adım 100 adım/dk kadansını korumalı',
        );
      }
    });

    test('round ağırlığı 250 adımlık referans rounda göre ölçülür', () {
      expect(AttackConfig.roundWeightForSteps(250), 1);
      expect(AttackConfig.roundWeightForSteps(500), 2);
      expect(AttackConfig.roundWeightForSteps(1000), 4);
      expect(AttackConfig.roundWeightForSteps(2000), 8);
      // Toplam ağırlık her zaman toplamAdım / 250 — kademeden bağımsız.
      for (final steps in [500, 1500, 3000, 9000, 10000, 20000]) {
        expect(
          AttackConfig.totalRoundWeightForSteps(steps),
          closeTo(steps / 250, 0.0000001),
        );
        expect(
          AttackConfig.roundStepTargetsForSteps(
            steps,
          ).fold<double>(0, (t, s) => t + AttackConfig.roundWeightForSteps(s)),
          closeTo(steps / 250, 0.0000001),
        );
      }
    });

    test('beş faz uzun saldırılara da dağılır, taşma yok', () {
      expect(AttackConfig.rounds, hasLength(5));
      expect(AttackConfig.hasValidRoundPercentages, isTrue);
      expect(AttackConfig.roundPercentageTotal, closeTo(1, 0.000000001));
      expect(AttackConfig.roundConfig(0, 2).phase, AttackPhase.attack);
      expect(AttackConfig.roundConfig(1, 2).phase, AttackPhase.finalRush);
      // 10 roundluk saldırıda uçlar korunur, orta roundlar üç fazı paylaşır.
      expect(AttackConfig.roundConfig(0, 10).phase, AttackPhase.warmUp);
      expect(AttackConfig.roundConfig(9, 10).phase, AttackPhase.finalRush);
      for (var count = 1; count <= 12; count++) {
        for (var index = 0; index < count; index++) {
          expect(
            () => AttackConfig.roundConfig(index, count),
            returnsNormally,
            reason: '$count roundun $index. fazı',
          );
        }
      }
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
