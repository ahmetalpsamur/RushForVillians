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
    gained.add(profile.grantStreakStatBonus(now)?.stat);
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
        streakDay: 1,
      );
      final second = drawStreakStatBonus(
        current: StreakStatBonuses.empty,
        seed: 12345,
        streakDay: 1,
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
      final beforeSecond = profile.streakStatBonuses.totalTenths;

      // Aynı gün, farklı saat: gün sınırı 04:00 olduğu için hâlâ aynı gün.
      expect(profile.grantStreakStatBonus(_day(1, hour: 22)), isNull);
      expect(profile.streakStatBonuses.totalTenths, beforeSecond);
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
      final continuedRestored = restored.grantStreakStatBonus(_day(4))?.stat;
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
      final total = profile.streakStatBonuses.totalTenths;

      // Aynı gün ikinci kez "yürüdü" sayılmaz.
      expect(profile.registerStreakDay(_day(1, hour: 20)), isFalse);
      expect(profile.grantStreakStatBonus(_day(1, hour: 20)), isNull);
      expect(profile.streakStatBonuses.totalTenths, total);
    });
  });

  group('basamaklar ve döngü (Bölüm B)', () {
    test('gün başına kazanç tabloya göre azalır', () {
      final tiers = GameConstants.streakBonusTierTenths;
      const length = GameConstants.streakBonusTierLength;
      expect(tiers, [5, 4, 3, 2, 1]);
      expect(length, 100);

      for (var tier = 0; tier < tiers.length; tier++) {
        final first = tier * length + 1;
        final last = (tier + 1) * length;
        expect(StreakStatBonuses.tenthsForDay(first), tiers[tier]);
        expect(StreakStatBonuses.tenthsForDay(last), tiers[tier]);
        expect(StreakStatBonuses.tierIndexForDay(first), tier);
      }
    });

    test('şartnamedeki sınır günleri', () {
      expect(StreakStatBonuses.tenthsForDay(1), 5);
      expect(StreakStatBonuses.tenthsForDay(100), 5);
      expect(StreakStatBonuses.tenthsForDay(101), 4);
      expect(StreakStatBonuses.tenthsForDay(200), 4);
      expect(StreakStatBonuses.tenthsForDay(201), 3);
      expect(StreakStatBonuses.tenthsForDay(300), 3);
      expect(StreakStatBonuses.tenthsForDay(301), 2);
      expect(StreakStatBonuses.tenthsForDay(400), 2);
      expect(StreakStatBonuses.tenthsForDay(401), 1);
      expect(StreakStatBonuses.tenthsForDay(500), 1);
      // 501: döngü başa döner.
      expect(StreakStatBonuses.tenthsForDay(501), 5);
      expect(StreakStatBonuses.tenthsForDay(600), 5);
      expect(StreakStatBonuses.tenthsForDay(601), 4);
      // İkinci tur da aynı şekilde kapanır.
      expect(StreakStatBonuses.tenthsForDay(1000), 1);
      expect(StreakStatBonuses.tenthsForDay(1001), 5);
    });

    test('yalnızca döngünün başa döndüğü gün kutlanır', () {
      expect(StreakStatBonuses.isCycleRestartDay(1), isFalse);
      expect(StreakStatBonuses.isCycleRestartDay(500), isFalse);
      expect(StreakStatBonuses.isCycleRestartDay(501), isTrue);
      expect(StreakStatBonuses.isCycleRestartDay(502), isFalse);
      expect(StreakStatBonuses.isCycleRestartDay(1000), isFalse);
      expect(StreakStatBonuses.isCycleRestartDay(1001), isTrue);
    });

    test('basamak tablosu tek config sabitinden okunur', () {
      // Tablo değişirse hesap da değişmeli: koda gömülü sayı yok.
      final tiers = GameConstants.streakBonusTierTenths;
      const length = GameConstants.streakBonusTierLength;
      for (var day = 1; day <= length * tiers.length * 2; day += 37) {
        expect(
          StreakStatBonuses.tenthsForDay(day),
          tiers[((day - 1) ~/ length) % tiers.length],
        );
      }
    });

    test('geçersiz gün savunmalı davranır', () {
      expect(StreakStatBonuses.tenthsForDay(0), 0);
      expect(StreakStatBonuses.tenthsForDay(-5), 0);
    });

    test('çekiliş gününün kazancını taşır', () {
      final draw = drawStreakStatBonus(
        current: StreakStatBonuses.empty,
        seed: 99,
        streakDay: 250,
      );
      expect(draw, isNotNull);
      expect(draw!.grantedTenths, 3);
      expect(draw.grantedBonus, closeTo(0.003, 1e-9));
      expect(draw.bonuses.tenthsFor(draw.stat), 3);
      expect(draw.cycleRestarted, isFalse);
    });

    test('501. günün çekilişi döngü bayrağını taşır', () {
      final draw = drawStreakStatBonus(
        current: StreakStatBonuses.empty,
        seed: 99,
        streakDay: 501,
      );
      expect(draw!.grantedTenths, 5);
      expect(draw.cycleRestarted, isTrue);
    });
  });

  group('tavan yok (Bölüm B)', () {
    test('tek stat sınırsız birikebilir', () {
      var bonuses = StreakStatBonuses.empty;
      for (var i = 0; i < 500; i++) {
        bonuses = bonuses.withGrant(ItemStat.attack, 5);
      }
      expect(bonuses.tenthsFor(ItemStat.attack), 2500);
      expect(bonuses.bonusFor(ItemStat.attack), closeTo(2.5, 1e-9));
    });

    test('toplam birikim sınırsız; hiçbir gün boşa gitmez', () {
      final profile = _profile();
      // Eski toplam tavan 100 gün karşılığıydı; onun ötesine yürü.
      _walkDays(profile, 160);
      expect(profile.streakDays, 160);
      // 100 gün x 5 binde + 60 gün x 4 binde = 740 binde.
      expect(profile.streakStatBonuses.totalTenths, 740);
      expect(profile.streakStatBonuses.totalBonus, closeTo(0.74, 1e-9));
    });

    test('çekiliş hiçbir birikimde durmaz', () {
      var bonuses = StreakStatBonuses.empty;
      for (final stat in StreakStatBonuses.pool) {
        bonuses = bonuses.withGrant(stat, 5000);
      }
      final draw = drawStreakStatBonus(
        current: bonuses,
        seed: 7,
        streakDay: 900,
      );
      expect(draw, isNotNull);
      expect(draw!.grantedTenths, greaterThan(0));
    });

    test('geride kalan stat kayrılır ama lider çekilişte kalır', () {
      var bonuses = StreakStatBonuses.empty;
      bonuses = bonuses.withGrant(StreakStatBonuses.pool.first, 1000);
      final weights = bonuses.drawWeights;
      expect(
        weights.first,
        1,
        reason: 'lider en düşük ağırlıkta ama sıfır değil',
      );
      for (final weight in weights.skip(1)) {
        expect(
          weight,
          1 + GameConstants.streakBonusBalanceWeight,
          reason: 'geride kalanın üstünlüğü tavanla sınırlı',
        );
      }
    });

    test('boş birikimde ağırlıklar eşit', () {
      final weights = StreakStatBonuses.empty.drawWeights;
      expect(weights.length, StreakStatBonuses.pool.length);
      expect(weights.toSet(), {1});
    });
  });

  group('dağılım', () {
    test('uzun seri bonusu tek stata yığmaz', () {
      final profile = _profile();
      _walkDays(profile, 40);
      expect(
        profile.streakStatBonuses.tenths.length,
        greaterThanOrEqualTo(3),
        reason: '40 gün en az üç ayrı stata dağılmalı',
      );
    });

    test('toplam birikim, günlerin basamak kazancının toplamı', () {
      final profile = _profile();
      _walkDays(profile, 20);
      // İlk basamakta 20 gün x 5 binde.
      expect(profile.streakStatBonuses.totalTenths, 100);
      expect(profile.streakStatBonuses.totalBonus, closeTo(0.1, 1e-9));
    });

    test('ağırlıklı çekiliş dağılımı dengeler', () {
      final profile = _profile();
      _walkDays(profile, 90);
      final tenths = profile.streakStatBonuses.tenths;
      expect(
        tenths.length,
        StreakStatBonuses.pool.length,
        reason: '90 gün bütün statlara ulaşmalı',
      );
      final values = tenths.values.toList()..sort();
      // Lider, en geriden gelenin iki katından fazla olmamalı.
      expect(values.last, lessThanOrEqualTo(values.first * 2));
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
      expect(profile.streakStatBonuses.totalTenths, 0);

      profile.grantStreakStatBonus(_day(9));
      // Yeniden başlayan seri 1. günde: ilk basamak, +%0,5 = 5 binde.
      expect(profile.streakStatBonuses.totalTenths, 5);
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
      expect(restored.tenthsFor(ItemStat.attack), 3);
      expect(restored.bonusFor(ItemStat.stepCoin), 0);
      expect(restored.totalTenths, 3);
    });

    test('yüksek kayıt kırpılmaz: tavan kalktı', () {
      final restored = StreakStatBonuses.fromJson({'attack': 9999});
      expect(restored.tenthsFor(ItemStat.attack), 9999);
    });

    test('artı olmayan değerler okunurken atılır', () {
      final restored = StreakStatBonuses.fromJson({'attack': 0, 'defense': -5});
      expect(restored.isEmpty, isTrue);
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
