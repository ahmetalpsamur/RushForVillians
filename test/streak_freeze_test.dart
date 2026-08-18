import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/game_constants.dart';
import 'package:rush_for_villains/core/utils/game_day.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/game_state.dart';
import 'package:rush_for_villains/models/daily_progress.dart';
import 'package:rush_for_villains/models/user_profile.dart';
import 'package:rush_for_villains/services/game_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _storageKey = 'game_state_v1';

const _avatar = AvatarProfile(
  name: 'Barca',
  age: 28,
  weight: 74,
  gender: 'Erkek',
  characterClass: 'SwordMan',
  characterAsset: 'lib/Characters/SwordMan/test.png',
);

/// Oyun gününün ortasında bir an; gün sınırından türetilir.
DateTime dayAt(int day, {int hoursAfterStart = 8}) => GameDay.startOf(
  DateTime(2026, 8, day, GameDay.dayStartHour),
).add(Duration(hours: hoursAfterStart));

/// [days] gün üst üste yürümüş, elinde [freezes] jeton olan oyuncu.
UserProfile walker({required int days, int freezes = 0, int firstDay = 10}) {
  final profile = UserProfile(avatar: _avatar, streakFreezes: freezes);
  for (var i = 0; i < days; i++) {
    profile.registerStreakDay(dayAt(firstDay + i));
  }
  return profile;
}

void main() {
  group('varsayılan davranış değişmedi', () {
    test('jeton yokken gün atlamak seriyi kırar', () {
      final profile = walker(days: 5);

      expect(profile.refreshStreak(dayAt(16)), StreakDayOutcome.broken);
      expect(profile.streakDays, 0);
    });

    test('yeni profilde jeton yok', () {
      expect(UserProfile(avatar: _avatar).streakFreezes, 0);
      expect(UserProfile(avatar: _avatar).lastFreezeUsedOn, isNull);
    });
  });

  group('tüketim — pasif kontrol (refreshStreak)', () {
    test('tek kaçırılan gün jetonla köprülenir, seri korunur', () {
      // 10-14 yürüdü (seri 5), 15'i kaçırdı, 16'da uygulama açıldı.
      final profile = walker(days: 5, freezes: 1);

      expect(profile.refreshStreak(dayAt(16)), StreakDayOutcome.frozen);
      expect(profile.streakDays, 5, reason: 'seri korunur');
      expect(profile.streakFreezes, 0, reason: 'jeton harcandı');
    });

    test('seri korunur ama ARTMAZ', () {
      final profile = walker(days: 5, freezes: 1);
      final before = profile.streakDays;

      profile.refreshStreak(dayAt(16));

      expect(profile.streakDays, before);
    });

    test('köprüden sonra bugün yürümek seriyi normal ilerletir', () {
      final profile = walker(days: 5, freezes: 1);
      profile.refreshStreak(dayAt(16));

      expect(profile.registerStreakDay(dayAt(16)), isTrue);
      expect(profile.streakDays, 6);
    });

    test('aynı boşluk için ikinci kez jeton harcanmaz', () {
      final profile = walker(days: 5, freezes: 2);

      expect(profile.refreshStreak(dayAt(16)), StreakDayOutcome.frozen);
      // Gün döngüsü saniyede bir çalışıyor; ikinci çağrı boş geçmeli.
      expect(profile.refreshStreak(dayAt(16)), StreakDayOutcome.unchanged);
      expect(profile.streakFreezes, 1);
    });
  });

  group('sınırlar', () {
    test('iki gün üst üste kaçırılırsa jeton olsa bile seri kırılır', () {
      // 10-14 yürüdü, 15 ve 16 kaçtı, 17'de açıldı (gap 3).
      final profile = walker(days: 5, freezes: 2);

      expect(profile.refreshStreak(dayAt(17)), StreakDayOutcome.broken);
      expect(profile.streakDays, 0);
      expect(profile.streakFreezes, 2, reason: 'jeton boşa harcanmaz');
    });

    test('art arda iki gün jetonla korunamaz', () {
      final profile = walker(days: 5, freezes: 2);

      // 15 kaçtı → jeton köprüledi.
      expect(profile.refreshStreak(dayAt(16)), StreakDayOutcome.frozen);
      // 16'da da yürünmedi; 17'de açıldı. Son "aktif" gün zaten jetonla
      // kapatılmıştı, ikinci jeton kullanılamaz.
      expect(profile.refreshStreak(dayAt(17)), StreakDayOutcome.broken);
      expect(profile.streakDays, 0);
      expect(profile.streakFreezes, 1, reason: 'ikinci jeton harcanmadı');
    });

    test('arada gerçek aktivite varsa jeton tekrar kullanılabilir', () {
      final profile = walker(days: 5, freezes: 2);

      profile.refreshStreak(dayAt(16)); // 15 köprülendi
      profile.registerStreakDay(dayAt(16)); // 16 gerçekten yürüdü → seri 6
      expect(profile.streakDays, 6);

      // 17 kaçtı, 18'de açıldı: son aktif gün gerçek aktivite, jeton geçerli.
      expect(profile.refreshStreak(dayAt(18)), StreakDayOutcome.frozen);
      expect(profile.streakDays, 6);
      expect(profile.streakFreezes, 0);
    });

    test('jeton bitmişse seri kırılır', () {
      final profile = walker(days: 5);

      expect(profile.refreshStreak(dayAt(16)), StreakDayOutcome.broken);
      expect(profile.streakDays, 0);
    });

    test('seri zaten kırıksa jeton harcanmaz', () {
      final profile = walker(days: 5, freezes: 1);
      profile.streakDays = 0;

      expect(profile.refreshStreak(dayAt(16)), StreakDayOutcome.unchanged);
      expect(profile.streakFreezes, 1);
    });

    test('saat geriye alınmışsa jeton harcanmaz', () {
      final profile = walker(days: 5, freezes: 1);

      expect(profile.refreshStreak(dayAt(12)), StreakDayOutcome.unchanged);
      expect(profile.streakFreezes, 1);
    });
  });

  group('tüketim — aktif yol (registerStreakDay)', () {
    test('kaçırılan günden sonra yürümek jetonla seriyi sürdürür', () {
      // Pasif kontrol hiç çalışmadı; kullanıcı doğrudan yürüdü.
      final profile = walker(days: 5, freezes: 1);

      expect(profile.registerStreakDay(dayAt(16)), isTrue);
      expect(profile.streakDays, 6, reason: '5 korundu + bugün 1');
      expect(profile.streakFreezes, 0);
    });

    test('iki gün kaçırılmışsa yürümek seriyi 1e döndürür', () {
      final profile = walker(days: 5, freezes: 2);

      expect(profile.registerStreakDay(dayAt(17)), isTrue);
      expect(profile.streakDays, 1);
      expect(profile.streakFreezes, 2);
    });

    test('iki yol aynı sonucu verir', () {
      final passive = walker(days: 5, freezes: 1);
      passive.refreshStreak(dayAt(16));
      passive.registerStreakDay(dayAt(16));

      final active = walker(days: 5, freezes: 1);
      active.registerStreakDay(dayAt(16));

      expect(passive.streakDays, active.streakDays);
      expect(passive.streakFreezes, active.streakFreezes);
    });
  });

  group('stok', () {
    test('kazanım stok sınırını aşamaz', () {
      final profile = UserProfile(avatar: _avatar);

      expect(profile.grantStreakFreeze(5), GameConstants.maxStreakFreezes);
      expect(profile.streakFreezes, GameConstants.maxStreakFreezes);
      // Stok doluyken yeni jeton eklenmez.
      expect(profile.grantStreakFreeze(), 0);
    });

    test('sıfır veya negatif kazanım hiçbir şey yapmaz', () {
      final profile = UserProfile(avatar: _avatar, streakFreezes: 1);

      expect(profile.grantStreakFreeze(0), 0);
      expect(profile.grantStreakFreeze(-3), 0);
      expect(profile.streakFreezes, 1);
    });
  });

  group('kalıcılık', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await GameStorage.clear();
    });

    test('jeton ve kullanım günü diskten aynen döner', () async {
      final profile = walker(days: 5, freezes: 2);
      profile.refreshStreak(dayAt(16));

      await GameStorage.save(
        GameState(profile: profile, today: DailyProgress(date: dayAt(16))),
      );
      final restored = (await GameStorage.load(avatar: _avatar))!;

      expect(restored.profile.streakFreezes, 1);
      expect(restored.profile.lastFreezeUsedOn, isNotNull);
      expect(restored.profile.streakDays, 5);
    });

    test('kapat-aç sonrası art arda koruma yine engellenir', () async {
      final profile = walker(days: 5, freezes: 2);
      profile.refreshStreak(dayAt(16));

      await GameStorage.save(
        GameState(profile: profile, today: DailyProgress(date: dayAt(16))),
      );
      final restored = (await GameStorage.load(avatar: _avatar))!;

      // lastFreezeUsedOn diskten geldiği için kural kapat-aç sonrası da işler.
      expect(
        restored.profile.refreshStreak(dayAt(17)),
        StreakDayOutcome.broken,
      );
      expect(restored.profile.streakFreezes, 1);
    });

    test('bozuk kayıttaki şişkin stok kırpılır', () async {
      SharedPreferences.setMockInitialValues({
        _storageKey: jsonEncode({
          'schemaVersion': 7,
          'state': {
            'profile': {'streakFreezes': 999},
            'today': {'date': dayAt(16).toIso8601String()},
          },
        }),
      });

      final restored = (await GameStorage.load(avatar: _avatar))!;

      expect(restored.profile.streakFreezes, GameConstants.maxStreakFreezes);
    });

    test('v6 kaydı jetonsuz açılır, davranış değişmez', () async {
      SharedPreferences.setMockInitialValues({
        _storageKey: jsonEncode({
          'schemaVersion': 6,
          'state': {
            'profile': {'streakDays': 5, 'longestStreak': 5},
            'today': {'date': dayAt(16).toIso8601String()},
          },
        }),
      });

      final restored = (await GameStorage.load(avatar: _avatar))!;

      expect(restored.profile.streakFreezes, 0);
      expect(restored.profile.lastFreezeUsedOn, isNull);
      expect(restored.profile.streakDays, 5);
    });
  });
}
