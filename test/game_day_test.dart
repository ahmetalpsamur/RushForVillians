import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/utils/game_day.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_progress.dart';
import 'package:rush_for_villains/models/user_profile.dart';

const _avatar = AvatarProfile(
  name: 'Barca',
  age: 28,
  weight: 74,
  gender: 'Erkek',
  characterClass: 'SwordMan',
  characterAsset: 'lib/Characters/SwordMan/test.png',
);

/// Gün sınırı [GameDay.dayStartHour] ile değişebildiği için testler sabit
/// saat yerine bu sabite göre yazıldı; Aşama 1a'da sınır 04:00'e alınınca
/// testlerin kırmızıya dönmesi gerekmiyor.
void main() {
  group('GameDay gün sınırı', () {
    test('gün başlangıcı dayStartHour saatine oturur', () {
      final start = GameDay.startOf(DateTime(2026, 8, 18, 13, 45));

      expect(start.hour, GameDay.dayStartHour);
      expect(start.minute, 0);
      expect(start.second, 0);
    });

    test('gün başlangıcı her zaman anın kendisinden geride veya eşittir', () {
      for (final hour in [0, 3, 4, 5, 12, 23]) {
        final moment = DateTime(2026, 8, 18, hour, 30);
        expect(
          GameDay.startOf(moment).isAfter(moment),
          isFalse,
          reason: '$hour. saatte gün başlangıcı ileri kaydı',
        );
      }
    });

    test('aynı gün içindeki farklı saatler aynı oyun günüdür', () {
      final start = GameDay.startOf(DateTime(2026, 8, 18, 12));

      expect(
        GameDay.isSameGameDay(start, start.add(const Duration(hours: 23))),
        isTrue,
      );
    });

    test('gün sıfırlamasının iki yanı farklı oyun günüdür', () {
      final moment = DateTime(2026, 8, 18, 12);
      final reset = GameDay.nextResetAfter(moment);

      expect(GameDay.isSameGameDay(moment, reset), isFalse);
      expect(
        GameDay.isSameGameDay(reset, reset.add(const Duration(minutes: 1))),
        isTrue,
      );
    });

    test('sonraki sıfırlama tam bir gün sonradır', () {
      final start = GameDay.startOf(DateTime(2026, 8, 18, 9));
      final reset = GameDay.nextResetAfter(DateTime(2026, 8, 18, 9));

      expect(reset.difference(start), const Duration(days: 1));
    });

    test('ay sonunda sonraki güne doğru geçer', () {
      final reset = GameDay.nextResetAfter(DateTime(2026, 8, 31, 23, 30));

      expect(reset.month, 9);
      expect(reset.day, 1);
    });

    test('kalan süre pozitif ve bir günden kısadır', () {
      final remaining = GameDay.timeUntilReset(DateTime(2026, 8, 18, 13, 45));

      expect(remaining, greaterThan(Duration.zero));
      expect(remaining, lessThanOrEqualTo(const Duration(days: 1)));
    });
  });

  group('GameDay.formatRemaining', () {
    test('saat ve dakikayı birlikte yazar', () {
      expect(
        GameDay.formatRemaining(const Duration(hours: 5, minutes: 12)),
        '5s 12dk',
      );
    });

    test('bir saatin altında yalnızca dakika yazar', () {
      expect(GameDay.formatRemaining(const Duration(minutes: 42)), '42dk');
    });

    test('bir dakikanın altını ve negatifi güvenli yazar', () {
      expect(
        GameDay.formatRemaining(const Duration(seconds: 30)),
        "1dk'dan az",
      );
      expect(
        GameDay.formatRemaining(const Duration(minutes: -5)),
        "1dk'dan az",
      );
    });
  });

  group('gün hesabı tek yerden okunur', () {
    test('DailyProgress gün karşılaştırmasını GameDay üzerinden yapar', () {
      final start = GameDay.startOf(DateTime(2026, 8, 18, 12));
      final progress = DailyProgress(date: start.add(const Duration(hours: 2)));

      expect(
        progress.isSameDayAs(start.add(const Duration(hours: 20))),
        isTrue,
      );
      expect(progress.isSameDayAs(start.add(const Duration(days: 1))), isFalse);
    });

    test('çark hiç çevrilmediyse bugün çevrilmemiş sayılır', () {
      final profile = UserProfile(avatar: _avatar);

      expect(profile.wheelSpunToday, isFalse);
    });

    test('bu oyun gününde çevrilen çark bugün çevrilmiş sayılır', () {
      final profile = UserProfile(
        avatar: _avatar,
        lastWheelSpinAt: DateTime.now(),
      );

      expect(profile.wheelSpunToday, isTrue);
    });

    test('önceki oyun gününde çevrilen çark hakkı yenilenir', () {
      final profile = UserProfile(
        avatar: _avatar,
        lastWheelSpinAt: GameDay.startOf(
          DateTime.now(),
        ).subtract(const Duration(minutes: 1)),
      );

      expect(profile.wheelSpunToday, isFalse);
    });
  });
}
