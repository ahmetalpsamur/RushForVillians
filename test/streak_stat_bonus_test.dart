import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/game_constants.dart';
import 'package:rush_for_villains/core/utils/game_clock.dart';
import 'package:rush_for_villains/core/utils/streak_bonus.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/item_effect.dart';
import 'package:rush_for_villains/models/streak_stat_bonuses.dart';
import 'package:rush_for_villains/models/user_profile.dart';

AvatarProfile _avatar({String name = 'Deneme'}) => AvatarProfile(
  name: name,
  age: 30,
  weight: 70,
  gender: 'Erkek',
  characterClass: 'Soldier',
  characterAsset: AvatarProfile.walkAssetForClass('Soldier'),
);

UserProfile _profile({String name = 'Deneme'}) =>
    UserProfile(avatar: _avatar(name: name));

DateTime _day(int day, {int hour = 12}) => DateTime(2026, 9, day, hour);

/// Seriyi [days] gün üst üste ilerletir ve her günün kazandığı statı döner.
List<ItemStat?> _walkDays(UserProfile profile, int days, {int from = 1}) {
  final gained = <ItemStat?>[];
  for (var i = 0; i < days; i++) {
    final now = _day(from + i);
    profile.registerStreakDay(now);
    gained.add(profile.grantStreakStatBonus(now));
  }
  return gained;
}

void main() {
  tearDown(GameClock.reset);

  group('havuz', () {
    test('yalnızca savaş statlarını içerir', () {
      expect(StreakStatBonuses.pool, isNotEmpty);
      for (final stat in StreakStatBonuses.pool) {
        expect(stat.isCombat, isTrue, reason: '${stat.name} savaş statı değil');
      }
    });

    test('ekonomi statları havuzda yok', () {
      const economy = [
        ItemStat.stepCoin,
        ItemStat.stepXp,
        ItemStat.wheelXp,
        ItemStat.enemyXp,
        ItemStat.dailyCoinCap,
        ItemStat.streakFreezeCap,
        ItemStat.wheelSpinCap,
        ItemStat.streakRelief,
      ];
      for (final stat in economy) {
        expect(StreakStatBonuses.pool, isNot(contains(stat)));
      }
    });

    test('havuz canlı stat listesinden türer, elle yazılmaz', () {
      final expected = ItemStat.values.where((stat) => stat.isCombat).toList();
      expect(StreakStatBonuses.pool, expected);
    });
  });

  group('determinizm', () {
    test('aynı tohum ve aynı birikim aynı statı verir', () {
      final first = drawStreakStatBonus(
        current: StreakStatBonuses.empty,
        seed: 12345,
      );
      final second = drawStreakStatBonus(
        current: StreakStatBonuses.empty,
        seed: 12345,
      );
      expect(first!.stat, second!.stat);
      expect(first.nextSeed, second.nextSeed);
    });

    test('aynı oyun gününde ikinci çağrı bonus vermez', () {
      final profile = _profile();
      final now = _day(1);
      profile.registerStreakDay(now);
      final first = profile.grantStreakStatBonus(now);
      expect(first, isNotNull);
      final beforeSecond = profile.streakStatBonuses.totalDays;

      // Aynı gün, farklı saat: gün sınırı 04:00 olduğu için hâlâ aynı gün.
      expect(profile.grantStreakStatBonus(_day(1, hour: 22)), isNull);
      expect(profile.streakStatBonuses.totalDays, beforeSecond);
    });

    test('kapat-aç turu aynı birikimi ve aynı sırayı korur', () {
      final profile = _profile();
      _walkDays(profile, 3);
      final saved = profile.toJson();

      final restored = UserProfile.fromJson(
        Map<String, dynamic>.from(saved),
        avatar: _avatar(),
      );
      expect(
        restored.streakStatBonuses.toJson(),
        profile.streakStatBonuses.toJson(),
      );
      expect(restored.streakBonusSeed, profile.streakBonusSeed);

      // Dördüncü gün her iki tarafta da aynı statı vermeli.
      final continuedOriginal = _walkDays(profile, 1, from: 4).single;
      restored.registerStreakDay(_day(4));
      final continuedRestored = restored.grantStreakStatBonus(_day(4));
      expect(continuedRestored, continuedOriginal);
    });

    test('farklı oyuncular farklı dizi görür', () {
      final a = _profile(name: 'Ada');
      final b = _profile(name: 'Bora');
      final seriesA = _walkDays(a, 6);
      final seriesB = _walkDays(b, 6);
      expect(seriesA, isNot(equals(seriesB)));
    });

    test('tohum her günde ilerler, aynı yerde saymaz', () {
      final profile = _profile();
      final seeds = <int>{};
      for (var i = 0; i < 10; i++) {
        _walkDays(profile, 1, from: i + 1);
        seeds.add(profile.streakBonusSeed);
      }
      expect(seeds.length, 10);
    });

    test('seri günü ilerlemeyen gün bonus vermez', () {
      final profile = _profile();
      profile.registerStreakDay(_day(1));
      profile.grantStreakStatBonus(_day(1));
      final total = profile.streakStatBonuses.totalDays;

      // Aynı gün ikinci kez "yürüdü" sayılmaz.
      expect(profile.registerStreakDay(_day(1, hour: 20)), isFalse);
      expect(profile.grantStreakStatBonus(_day(1, hour: 20)), isNull);
      expect(profile.streakStatBonuses.totalDays, total);
    });
  });

  group('tavanlar', () {
    test('stat başına tavan aşılmaz', () {
      var bonuses = StreakStatBonuses.empty;
      for (var i = 0; i < StreakStatBonuses.maxDaysPerStat + 10; i++) {
        bonuses = bonuses.withGrant(ItemStat.attack);
      }
      expect(
        bonuses.daysFor(ItemStat.attack),
        StreakStatBonuses.maxDaysPerStat,
      );
      expect(
        bonuses.bonusFor(ItemStat.attack),
        closeTo(GameConstants.maxStreakStatBonus, 1e-9),
      );
      expect(bonuses.isAtCap(ItemStat.attack), isTrue);
    });

    test('tavandaki stat havuzdan çıkar', () {
      var bonuses = StreakStatBonuses.empty;
      for (var i = 0; i < StreakStatBonuses.maxDaysPerStat; i++) {
        bonuses = bonuses.withGrant(ItemStat.attack);
      }
      expect(bonuses.eligibleStats, isNot(contains(ItemStat.attack)));
      expect(bonuses.eligibleStats.length, StreakStatBonuses.pool.length - 1);

      // Havuz daraldığı hâlde gün boşa gitmez: çekiliş hâlâ bir stat veriyor.
      final draw = drawStreakStatBonus(current: bonuses, seed: 7);
      expect(draw, isNotNull);
      expect(draw!.stat, isNot(ItemStat.attack));
    });

    test('toplam tavan dolunca yeni gün bonus üretmez', () {
      final profile = _profile();
      // Uzun seri: toplam tavanı geçecek kadar gün yürü.
      _walkDays(profile, StreakStatBonuses.maxTotalDays + 15);
      expect(
        profile.streakStatBonuses.totalDays,
        StreakStatBonuses.maxTotalDays,
      );
      expect(
        profile.streakStatBonuses.totalBonus,
        closeTo(GameConstants.maxStreakTotalBonus, 1e-9),
      );
      expect(profile.streakStatBonuses.isFull, isTrue);
    });

    test('toplam tavan dolduktan sonra seri yine ilerler', () {
      final profile = _profile();
      final days = StreakStatBonuses.maxTotalDays + 5;
      _walkDays(profile, days);
      expect(profile.streakDays, days);
    });

    test('hiçbir stat toplam tavanı tek başına dolduramaz', () {
      // Stat başına tavan × stat sayısı toplam tavandan büyük olmalı ki
      // toplam tavan gerçekten bağlayıcı olsun.
      expect(
        StreakStatBonuses.maxDaysPerStat * StreakStatBonuses.pool.length,
        greaterThan(StreakStatBonuses.maxTotalDays),
      );
      expect(
        StreakStatBonuses.maxDaysPerStat,
        lessThan(StreakStatBonuses.maxTotalDays),
      );
    });
  });

  group('dağılım', () {
    test('uzun seri bonusu tek stata yığmaz', () {
      final profile = _profile();
      _walkDays(profile, 40);
      expect(
        profile.streakStatBonuses.days.length,
        greaterThanOrEqualTo(3),
        reason: '40 gün en az üç ayrı stata dağılmalı',
      );
    });

    test('toplam gün, yürünen gün sayısına eşit (tavan altında)', () {
      final profile = _profile();
      _walkDays(profile, 20);
      expect(profile.streakStatBonuses.totalDays, 20);
      expect(
        profile.streakStatBonuses.totalBonus,
        closeTo(20 * GameConstants.streakStatBonusPerDay, 1e-9),
      );
    });
  });

  group('seri kırılınca', () {
    test('birikim sıfırlanır', () {
      final profile = _profile();
      _walkDays(profile, 5);
      expect(profile.streakStatBonuses.isEmpty, isFalse);

      // İki gün atla: dondurma hakkı yok, seri kırılır.
      expect(profile.refreshStreak(_day(9)), StreakDayOutcome.broken);
      expect(profile.streakStatBonuses.isEmpty, isTrue);
      expect(profile.streakStatBonuses.totalBonus, 0);
    });

    test('yeniden başlayan seri sıfırdan birikir', () {
      final profile = _profile();
      _walkDays(profile, 5);
      profile.registerStreakDay(_day(9));
      expect(profile.streakDays, 1);
      expect(profile.streakStatBonuses.totalDays, 0);

      profile.grantStreakStatBonus(_day(9));
      expect(profile.streakStatBonuses.totalDays, 1);
    });

    test('dondurma hakkı serinin bonusunu korur', () {
      final profile = _profile();
      _walkDays(profile, 5);
      final before = profile.streakStatBonuses.toJson();
      profile.grantStreakFreeze();

      // Tek gün kaçırıldı: jeton köprüler, bonus durur.
      expect(profile.refreshStreak(_day(7)), StreakDayOutcome.frozen);
      expect(profile.streakStatBonuses.toJson(), before);
    });

    test('tohum kırılmada sıfırlanmaz', () {
      final profile = _profile();
      _walkDays(profile, 3);
      final seed = profile.streakBonusSeed;
      profile.refreshStreak(_day(9));
      expect(profile.streakBonusSeed, seed);
    });
  });

  group('ekonomi etkilenmez', () {
    test('bonus hiçbir ekonomi statına yazılmaz', () {
      final profile = _profile();
      _walkDays(profile, 60);
      for (final stat in ItemStat.values) {
        if (stat.isCombat) continue;
        expect(
          profile.streakStatBonuses.bonusFor(stat),
          0,
          reason: '${stat.name} ekonomi statı, seriden bonus almamalı',
        );
      }
    });

    test('bozuk kayıttaki ekonomi statı okunurken atılır', () {
      final restored = StreakStatBonuses.fromJson({
        'attack': 3,
        'stepCoin': 50,
        'bilinmeyenStat': 4,
        'defense': 'metin',
      });
      expect(restored.daysFor(ItemStat.attack), 3);
      expect(restored.bonusFor(ItemStat.stepCoin), 0);
      expect(restored.totalDays, 3);
    });

    test('tavan üstü kayıt okunurken kırpılır', () {
      final restored = StreakStatBonuses.fromJson({'attack': 9999});
      expect(
        restored.daysFor(ItemStat.attack),
        StreakStatBonuses.maxDaysPerStat,
      );
    });
  });

  group('kalıcılık', () {
    test('v12 kaydı temiz varsayılana düşer', () {
      final profile = UserProfile.fromJson(<String, dynamic>{
        'level': 4,
        'coins': 100,
        'streakDays': 6,
      }, avatar: _avatar());
      expect(profile.streakStatBonuses.isEmpty, isTrue);
      expect(profile.streakBonusSeed, 0);
      expect(profile.lastStreakBonusDay, isNull);
    });

    test('kayıt turu gün işaretini de taşır', () {
      final profile = _profile();
      _walkDays(profile, 2);
      final restored = UserProfile.fromJson(
        Map<String, dynamic>.from(profile.toJson()),
        avatar: _avatar(),
      );
      expect(restored.lastStreakBonusDay, isNotNull);
      // Kapat-aç sonrası aynı gün yeniden zar atılamaz.
      expect(restored.grantStreakStatBonus(_day(2, hour: 23)), isNull);
    });
  });
}
