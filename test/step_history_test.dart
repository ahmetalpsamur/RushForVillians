import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_step_record.dart';
import 'package:rush_for_villains/models/game_state.dart';

/// Tamamlanan günlerin adım halkaları diske yazılıyor; bozuk ya da eksik bir
/// kayıt satırının tüm geçmişi düşürmemesi gerekiyor.
void main() {
  group('DailyStepRecord', () {
    test('gün anahtarı sıfırla doldurulur', () {
      final record = DailyStepRecord(
        date: DateTime(2026, 3, 7, 21, 45),
        steps: 1200,
        stepGoal: 5000,
      );

      expect(record.dateKey, '2026-03-07');
      expect(record.calendarDay, DateTime(2026, 3, 7));
    });

    test('ilerleme 0 ile 1 arasında kalır', () {
      DailyStepRecord at(int steps, int goal) => DailyStepRecord(
        date: DateTime(2026, 3, 7),
        steps: steps,
        stepGoal: goal,
      );

      expect(at(0, 5000).progress, 0);
      expect(at(2500, 5000).progress, 0.5);
      expect(
        at(9000, 5000).progress,
        1,
        reason: 'hedefi aşmak halkayı taşırmaz',
      );
    });

    test('hedefi olmayan gün sıfır ilerleme gösterir', () {
      final record = DailyStepRecord(
        date: DateTime(2026, 3, 7),
        steps: 900,
        stepGoal: 0,
      );

      expect(record.progress, 0, reason: 'sıfıra bölme yok');
    });

    test('kayıt turu değeri korur', () {
      final original = DailyStepRecord(
        date: DateTime(2026, 3, 7),
        steps: 8421,
        stepGoal: 10000,
      );

      final restored = DailyStepRecord.fromJson(
        Map<String, dynamic>.from(original.toJson()),
      );

      expect(restored.date, DateTime(2026, 3, 7));
      expect(restored.steps, 8421);
      expect(restored.stepGoal, 10000);
    });

    test('eksik alanlar varsayılana düşer, hata fırlatmaz', () {
      final restored = DailyStepRecord.fromJson(<String, dynamic>{
        'date': '2026-03-07T00:00:00.000',
      });

      expect(restored.steps, 0);
      expect(restored.stepGoal, 0);
      expect(restored.dateKey, '2026-03-07');
    });
  });

  group('GameState adım geçmişi', () {
    Map<String, dynamic> stateWithHistory(Object? history) => <String, dynamic>{
      'profile': <String, dynamic>{'level': 1},
      'today': <String, dynamic>{'steps': 0, 'stepGoal': 6000},
      'stepHistory': history,
    };

    test('geçmiş yoksa boş liste döner', () {
      final state = GameState.fromJson(
        stateWithHistory(null),
        avatar: _avatar(),
      );

      expect(state.stepHistory, isEmpty);
    });

    test('liste olmayan geçmiş yok sayılır', () {
      final state = GameState.fromJson(
        stateWithHistory('bozuk'),
        avatar: _avatar(),
      );

      expect(state.stepHistory, isEmpty);
    });

    test('bozuk satır atılır, sağlam satırlar korunur', () {
      final state = GameState.fromJson(
        stateWithHistory(<Object?>[
          <String, dynamic>{
            'date': '2026-03-06T00:00:00.000',
            'steps': 4000,
            'stepGoal': 5000,
          },
          'bu bir kayıt değil',
          42,
          <String, dynamic>{
            'date': '2026-03-07T00:00:00.000',
            'steps': 7000,
            'stepGoal': 5000,
          },
        ]),
        avatar: _avatar(),
      );

      expect(state.stepHistory, hasLength(2));
      expect(state.stepHistory.first.dateKey, '2026-03-06');
      expect(state.stepHistory.last.steps, 7000);
    });
  });
}

AvatarProfile _avatar() => const AvatarProfile(
  name: 'Test',
  age: 24,
  weight: 72,
  gender: 'Erkek',
  characterClass: 'Archer',
  characterAsset: 'lib/Characters/Archer/a.png',
);
