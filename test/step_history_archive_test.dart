import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/game_constants.dart';
import 'package:rush_for_villains/core/utils/game_day.dart';
import 'package:rush_for_villains/core/utils/step_history.dart';
import 'package:rush_for_villains/models/daily_progress.dart';
import 'package:rush_for_villains/models/daily_step_record.dart';

/// Adım halkası geçmişi arşivlenirken iki şey doğru olmalı: kayıt **oyun
/// gününe** düşmeli (gün sınırı gece yarısı değil) ve geçmiş sınırsız
/// büyümemeli.
void main() {
  DailyProgress dayAt(DateTime date, {int steps = 0, int goal = 6000}) =>
      DailyProgress(date: date, steps: steps, stepGoal: goal);

  group('arşivleme oyun gününe düşer', () {
    test('gün ortasında açılmış gün kendi gününe yazılır', () {
      final history = archiveStepDay(
        history: const [],
        completedDay: dayAt(DateTime(2026, 8, 19, 9, 30), steps: 7200),
      );

      expect(history, hasLength(1));
      expect(history.single.dateKey, '2026-08-19');
      expect(history.single.steps, 7200);
    });

    test('gün sınırından önceki saatler bir sonraki takvim gününe kaymaz', () {
      // 20 Ağustos 01:00 hâlâ 19 Ağustos oyun günü (sınır 04:00).
      final history = archiveStepDay(
        history: const [],
        completedDay: dayAt(DateTime(2026, 8, 20, 1, 0), steps: 4500),
      );

      expect(
        GameDay.dayStartHour,
        greaterThan(0),
        reason: 'test bu varsayıma dayanıyor',
      );
      expect(history.single.dateKey, '2026-08-19');
    });

    test('gün sınırından sonraki saatler yeni güne yazılır', () {
      final history = archiveStepDay(
        history: const [],
        completedDay: dayAt(
          DateTime(2026, 8, 20, GameDay.dayStartHour + 1),
          steps: 100,
        ),
      );

      expect(history.single.dateKey, '2026-08-20');
    });

    test('aynı gün iki kez arşivlenirse çift satır oluşmaz', () {
      var history = archiveStepDay(
        history: const [],
        completedDay: dayAt(DateTime(2026, 8, 19, 9), steps: 1000),
      );
      history = archiveStepDay(
        history: history,
        completedDay: dayAt(DateTime(2026, 8, 19, 22), steps: 8000),
      );

      expect(history, hasLength(1));
      expect(history.single.steps, 8000, reason: 'son değer kazanır');
    });

    test('geçmiş eskiden yeniye sıralı kalır', () {
      var history = archiveStepDay(
        history: const [],
        completedDay: dayAt(DateTime(2026, 8, 19, 9)),
      );
      history = archiveStepDay(
        history: history,
        completedDay: dayAt(DateTime(2026, 8, 17, 9)),
      );
      history = archiveStepDay(
        history: history,
        completedDay: dayAt(DateTime(2026, 8, 18, 9)),
      );

      expect(history.map((record) => record.dateKey), [
        '2026-08-17',
        '2026-08-18',
        '2026-08-19',
      ]);
    });

    test('gelen liste değiştirilmez', () {
      const original = <DailyStepRecord>[];
      final history = archiveStepDay(
        history: original,
        completedDay: dayAt(DateTime(2026, 8, 19, 9)),
      );

      expect(original, isEmpty);
      expect(history, hasLength(1));
    });
  });

  group('geçmiş sınırı', () {
    List<DailyStepRecord> historyOf(int days) => List.generate(
      days,
      (index) => DailyStepRecord(
        date: DateTime(2026, 1, 1).add(Duration(days: index)),
        steps: index,
        stepGoal: 6000,
      ),
    );

    test('sınırın altındaki geçmişe dokunulmaz', () {
      final history = historyOf(10);

      expect(pruneStepHistory(history, maxDays: 400), hasLength(10));
    });

    test('sınırı aşan geçmişte en eski günler düşer', () {
      final pruned = pruneStepHistory(historyOf(12), maxDays: 5);

      expect(pruned, hasLength(5));
      expect(pruned.first.steps, 7, reason: 'ilk 7 gün düştü');
      expect(pruned.last.steps, 11, reason: 'en yeni gün korundu');
    });

    test('arşivleme sınırı kendi başına uygular', () {
      final history = archiveStepDay(
        history: historyOf(5),
        completedDay: dayAt(DateTime(2026, 8, 19, 9), steps: 999),
        maxDays: 3,
      );

      expect(history, hasLength(3));
      expect(history.last.steps, 999);
    });

    test('sıfır ya da negatif sınır boş geçmiş verir', () {
      expect(pruneStepHistory(historyOf(4), maxDays: 0), isEmpty);
      expect(pruneStepHistory(historyOf(4), maxDays: -1), isEmpty);
    });

    test('varsayılan sınır bir yıldan uzun geçmişi kapsar', () {
      expect(GameConstants.maxStepHistoryDays, greaterThan(365));
    });
  });

  group('gün sınırı — çark ve seri', () {
    test('gece yarısının iki yanı aynı oyun günü', () {
      final before = DateTime(2026, 8, 19, 23, 59);
      final after = DateTime(2026, 8, 20, 0, 1);

      expect(
        GameDay.isSameGameDay(before, after),
        isTrue,
        reason: "23:59'da çevrilen çark 00:01'de bedava yenilenmemeli",
      );
    });

    test('gün sınırının iki yanı ayrı oyun günü', () {
      final before = DateTime(2026, 8, 20, GameDay.dayStartHour - 1, 59);
      final after = DateTime(2026, 8, 20, GameDay.dayStartHour, 1);

      expect(GameDay.isSameGameDay(before, after), isFalse);
      expect(GameDay.daysBetween(before, after), 1);
    });
  });
}
