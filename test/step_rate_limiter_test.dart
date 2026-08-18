import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/game_constants.dart';
import 'package:rush_for_villains/core/utils/step_rate_limiter.dart';

final _burst = GameConstants.stepBurstAllowance;
final _perMinute = GameConstants.maxStepsPerMinute;

void main() {
  group('hız sınırı', () {
    test('makul hızdaki adımlar olduğu gibi geçer', () {
      final verdict = limitStepBatch(
        reportedSteps: 120,
        elapsed: const Duration(minutes: 1),
      );

      expect(verdict.accepted, 120);
      expect(verdict.discarded, 0);
      expect(verdict.rateExceeded, isFalse);
    });

    test('sınırdaki hız kabul edilir', () {
      final verdict = limitStepBatch(
        reportedSteps: _perMinute,
        elapsed: const Duration(minutes: 1),
      );

      expect(verdict.accepted, _perMinute);
      expect(verdict.discarded, 0);
    });

    test('imkânsız hız kırpılır ve fazlası yakılır', () {
      final verdict = limitStepBatch(
        reportedSteps: 5000,
        elapsed: const Duration(minutes: 1),
      );

      expect(verdict.accepted, _perMinute);
      expect(verdict.discarded, 5000 - _perMinute);
      expect(verdict.rateExceeded, isTrue);
    });

    test('uzun aradan sonra gelen gerçek yürüyüş kırpılmaz', () {
      // 3 saat kapalı kalmış uygulama, 9.000 adım: dakikada 50 adım.
      final verdict = limitStepBatch(
        reportedSteps: 9000,
        elapsed: const Duration(hours: 3),
      );

      expect(verdict.accepted, 9000);
      expect(verdict.discarded, 0);
    });

    test('süre geçmemişse taban izin uygulanır', () {
      final verdict = limitStepBatch(
        reportedSteps: 10000,
        elapsed: Duration.zero,
      );

      expect(verdict.accepted, _burst);
      expect(verdict.discarded, 10000 - _burst);
    });

    test('taban izin altındaki parti kırpılmaz', () {
      final verdict = limitStepBatch(
        reportedSteps: _burst - 1,
        elapsed: Duration.zero,
      );

      expect(verdict.accepted, _burst - 1);
      expect(verdict.discarded, 0);
    });

    test('kısa aralık milisaniye üzerinden hesaplanır', () {
      // 1,8 saniye: saniyeye yuvarlansaydı 1 saniyelik hak verilirdi.
      final verdict = limitStepBatch(
        reportedSteps: 5000,
        elapsed: const Duration(milliseconds: 1800),
      );

      // Taban izin bu aralıkta hâlâ daha cömert.
      expect(verdict.accepted, _burst);
    });

    test('negatif süre çökmez, taban izin verir', () {
      final verdict = limitStepBatch(
        reportedSteps: 500,
        elapsed: const Duration(minutes: -10),
      );

      expect(verdict.accepted, _burst);
      expect(verdict.discarded, 500 - _burst);
    });

    test('sıfır ve negatif adım hiçbir şey yapmaz', () {
      expect(
        limitStepBatch(
          reportedSteps: 0,
          elapsed: const Duration(minutes: 1),
        ).accepted,
        0,
      );
      expect(
        limitStepBatch(
          reportedSteps: -300,
          elapsed: const Duration(minutes: 1),
        ).accepted,
        0,
      );
    });
  });
}
