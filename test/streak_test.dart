import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/game_constants.dart';
import 'package:rush_for_villains/core/utils/game_clock.dart';
import 'package:rush_for_villains/core/utils/game_day.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/user_profile.dart';

const _avatar = AvatarProfile(
  name: 'Barca',
  age: 28,
  weight: 74,
  gender: 'Erkek',
  characterClass: 'SwordMan',
  characterAsset: 'lib/Characters/SwordMan/test.png',
);

/// Oyun gününün ortasında bir an — gün sınırı [GameDay.dayStartHour] ile
/// değişebildiği için sabit saat yazmak yerine sınırdan türetiliyor.
DateTime dayAt(int day, {int hoursAfterStart = 8}) => GameDay.startOf(
  DateTime(2026, 8, day, GameDay.dayStartHour),
).add(Duration(hours: hoursAfterStart));

void main() {
  group('streak ilerlemesi', () {
    test('5 gün üst üste tetiklenirse seri 5 olur', () {
      final profile = UserProfile(avatar: _avatar);

      for (var day = 10; day < 15; day++) {
        expect(profile.registerStreakDay(dayAt(day)), isTrue);
      }

      expect(profile.streakDays, 5);
      expect(profile.longestStreak, 5);
    });

    test('aynı oyun gününde ikinci tetikleme seriyi artırmaz', () {
      final profile = UserProfile(avatar: _avatar);

      expect(profile.registerStreakDay(dayAt(10, hoursAfterStart: 2)), isTrue);
      expect(profile.registerStreakDay(dayAt(10, hoursAfterStart: 9)), isFalse);
      expect(
        profile.registerStreakDay(dayAt(10, hoursAfterStart: 19)),
        isFalse,
      );

      expect(profile.streakDays, 1);
    });

    test('bir gün atlanırsa seri 1e döner', () {
      final profile = UserProfile(avatar: _avatar);

      profile.registerStreakDay(dayAt(10));
      profile.registerStreakDay(dayAt(11));
      expect(profile.streakDays, 2);

      // 12. gün atlandı.
      expect(profile.registerStreakDay(dayAt(13)), isTrue);
      expect(profile.streakDays, 1);
    });

    test('refreshStreak atlanan günü aktivite olmadan da yakalar', () {
      final profile = UserProfile(avatar: _avatar);

      profile.registerStreakDay(dayAt(10));
      profile.registerStreakDay(dayAt(11));

      // Ertesi gün: seri hâlâ ayakta, henüz tamamlanmadı.
      expect(profile.refreshStreak(dayAt(12)), isFalse);
      expect(profile.streakDays, 2);

      // Bir gün daha geçti, hiç yürünmedi.
      expect(profile.refreshStreak(dayAt(13)), isTrue);
      expect(profile.streakDays, 0);
    });

    test('seri kırılsa da en uzun seri korunur', () {
      final profile = UserProfile(avatar: _avatar);

      for (var day = 10; day < 15; day++) {
        profile.registerStreakDay(dayAt(day));
      }
      profile.refreshStreak(dayAt(20));

      expect(profile.streakDays, 0);
      expect(profile.longestStreak, 5);
    });

    test('bugün tamamlandı mı doğru bildirilir', () {
      final profile = UserProfile(avatar: _avatar);

      expect(profile.streakCompletedOn(dayAt(10)), isFalse);
      profile.registerStreakDay(dayAt(10, hoursAfterStart: 5));
      expect(profile.streakCompletedOn(dayAt(10, hoursAfterStart: 15)), isTrue);
      expect(profile.streakCompletedOn(dayAt(11)), isFalse);
    });
  });

  group('gün sınırı', () {
    test('sınırdan bir dakika önce hâlâ önceki oyun günü', () {
      final profile = UserProfile(avatar: _avatar);
      final dayStart = GameDay.startOf(
        DateTime(2026, 8, 18, GameDay.dayStartHour),
      );

      // Aynı oyun gününün akşamı.
      expect(
        profile.registerStreakDay(dayStart.add(const Duration(hours: 16))),
        isTrue,
      );
      // Sınıra bir dakika kala — hâlâ aynı oyun günü, seri artmamalı.
      expect(
        profile.registerStreakDay(
          dayStart.add(const Duration(hours: 24) - const Duration(minutes: 1)),
        ),
        isFalse,
      );
      expect(profile.streakDays, 1);
    });

    test('sınırdan bir dakika sonra yeni oyun günü', () {
      final profile = UserProfile(avatar: _avatar);
      final dayStart = GameDay.startOf(
        DateTime(2026, 8, 18, GameDay.dayStartHour),
      );

      profile.registerStreakDay(dayStart.add(const Duration(hours: 16)));
      expect(
        profile.registerStreakDay(
          dayStart.add(const Duration(hours: 24) + const Duration(minutes: 1)),
        ),
        isTrue,
      );
      expect(profile.streakDays, 2);
    });
  });

  group('kilometre taşları', () {
    test('7 güne ulaşınca kilometre taşı bildirilir', () {
      final profile = UserProfile(avatar: _avatar);

      for (var day = 10; day < 17; day++) {
        profile.registerStreakDay(dayAt(day));
      }

      expect(profile.streakDays, 7);
      expect(profile.reachedStreakMilestone, 7);
    });

    test('kilometre taşı olmayan günlerde null döner', () {
      final profile = UserProfile(avatar: _avatar);
      profile.registerStreakDay(dayAt(10));

      expect(profile.reachedStreakMilestone, isNull);
    });

    test('sonraki kilometre taşı sırayla ilerler', () {
      final profile = UserProfile(avatar: _avatar);

      expect(profile.nextStreakMilestone, GameConstants.streakMilestones.first);

      for (var day = 10; day < 17; day++) {
        profile.registerStreakDay(dayAt(day));
      }
      expect(profile.nextStreakMilestone, 30);
    });
  });

  group('GameClock — zaman güvenliği', () {
    tearDown(GameClock.reset);

    setUp(GameClock.reset);

    test('normal ilerleyen saat olduğu gibi okunur', () {
      var reading = DateTime(2026, 8, 18, 12);
      GameClock.useSource(() => reading);

      expect(GameClock.now(), reading);

      reading = DateTime(2026, 8, 18, 13);
      expect(GameClock.now(), reading);
    });

    test('cihaz saati geriye alınırsa son güvenilir zamana sabitlenir', () {
      var reading = DateTime(2026, 8, 18, 12);
      GameClock.useSource(() => reading);
      GameClock.now();

      // Kullanıcı saati bir gün geri aldı.
      reading = DateTime(2026, 8, 17, 12);

      expect(GameClock.now(), DateTime(2026, 8, 18, 12));
      // Saat geri kaldığı sürece okuma donmuş kalır.
      expect(GameClock.now(), DateTime(2026, 8, 18, 12));
    });

    test('küçük geri sapmalar (NTP düzeltmesi) tolere edilir', () {
      var reading = DateTime(2026, 8, 18, 12);
      GameClock.useSource(() => reading);
      GameClock.now();

      reading = DateTime(2026, 8, 18, 11, 58);

      expect(GameClock.now(), reading);
    });

    test('saat dilimi değişse de UTC ilerlediği sürece dondurmaz', () {
      // Seyahat eden kullanıcıda yerel saat geri kayabilir ama UTC kaymaz;
      // karşılaştırma UTC üzerinden yapıldığı için mağdur olmaz.
      var reading = DateTime.utc(2026, 8, 18, 12).toLocal();
      GameClock.useSource(() => reading);
      expect(GameClock.now(), reading);

      reading = DateTime.utc(2026, 8, 18, 13).toLocal();
      expect(GameClock.now(), reading);

      reading = DateTime.utc(2026, 8, 18, 14).toLocal();
      expect(GameClock.now(), reading);
    });

    test('diskten yüklenen son zaman kapat-aç sonrası da korur', () {
      // Uygulama kapalıyken saat geri alındı; açılışta restore edilen zaman
      // geri gidişi yakalamalı.
      GameClock.restore(DateTime.utc(2026, 8, 18, 12));
      GameClock.useSource(() => DateTime.utc(2026, 8, 17, 12).toLocal());

      expect(GameClock.now(), DateTime.utc(2026, 8, 18, 12).toLocal());
    });

    test('kaydedilecek son güvenilir zaman UTC olarak tutulur', () {
      final reading = DateTime(2026, 8, 18, 12);
      GameClock.useSource(() => reading);
      GameClock.now();

      expect(GameClock.lastSeenAt, reading.toUtc());
      expect(GameClock.lastSeenAt!.isUtc, isTrue);
    });
  });

  group('geriye alınan saat seriyi ve çarkı dondurur', () {
    tearDown(GameClock.reset);

    setUp(GameClock.reset);

    test('donmuş zamanda seri ikinci kez ilerlemez', () {
      final profile = UserProfile(avatar: _avatar);
      var reading = dayAt(18);
      GameClock.useSource(() => reading);

      expect(profile.registerStreakDay(GameClock.now()), isTrue);
      expect(profile.streakDays, 1);

      // Kullanıcı saati bir gün geri aldı: GameClock donuk zaman döner,
      // dolayısıyla aynı oyun günü sayılır ve seri artmaz.
      reading = dayAt(17);
      expect(profile.registerStreakDay(GameClock.now()), isFalse);
      expect(profile.streakDays, 1);
    });

    test('donmuş zamanda çark hakkı yenilenmez', () {
      var reading = dayAt(18);
      GameClock.useSource(() => reading);

      final profile = UserProfile(
        avatar: _avatar,
        lastWheelSpinAt: GameClock.now(),
      );
      expect(profile.wheelSpunToday, isTrue);

      reading = dayAt(17);
      expect(profile.wheelSpunToday, isTrue);
    });

    test('saat ileri giderse çark hakkı normal şekilde yenilenir', () {
      var reading = dayAt(18);
      GameClock.useSource(() => reading);

      final profile = UserProfile(
        avatar: _avatar,
        lastWheelSpinAt: GameClock.now(),
      );
      expect(profile.wheelSpunToday, isTrue);

      reading = dayAt(19);
      expect(profile.wheelSpunToday, isFalse);
    });
  });
}
