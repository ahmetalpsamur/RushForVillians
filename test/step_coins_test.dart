import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/game_constants.dart';
import 'package:rush_for_villains/core/utils/coin_calculator.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_progress.dart';
import 'package:rush_for_villains/models/game_state.dart';
import 'package:rush_for_villains/models/user_profile.dart';
import 'package:rush_for_villains/services/game_storage.dart';
import 'package:rush_for_villains/services/step_source.dart';
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

final _rate = GameConstants.stepsPerCoin;
final _legacyCap = GameConstants.maxDailyStepCoins;

/// Kazanç akışının test kopyası: RootShell'deki `_onStepsReported` ile aynı
/// sırayı izler — delta hesabı, işaretçi ilerletme ve sınırsız ödeme.
///
/// Hız kontrolü burada yok; bu dosya demo (fiziksel olmayan) kaynağın yolunu
/// test ediyor, orada raporlanan adımın tamamı kredilenir. Hız kontrolünün
/// devrede olduğu akış `pedometer_step_source_test.dart` içinde.
StepCoinReward award(UserProfile profile, DailyProgress today, int newTotal) {
  final amount = newTotal - profile.totalSteps;
  if (amount <= 0) return StepCoinReward.none;

  today.addSteps(amount);
  profile.totalSteps = newTotal;
  profile.lastReportedStepCount = newTotal;

  final reward = calculateStepCoins(
    pendingSteps: profile.totalSteps - profile.lastRewardedStepCount,
    coinsEarnedToday: today.coinsEarned,
  );
  profile.coins += reward.coins;
  profile.lastRewardedStepCount += reward.consumedSteps;
  today.coinsEarned += reward.coins;
  return reward;
}

void main() {
  group('adım → para dönüşümü', () {
    test('oran kadar adım 1 coin eder', () {
      final reward = calculateStepCoins(
        pendingSteps: _rate * 3,
        coinsEarnedToday: 0,
      );

      expect(reward.coins, 3);
      expect(reward.consumedSteps, _rate * 3);
      expect(reward.capReached, isFalse);
    });

    test('orana yetmeyen adım para vermez ve tüketilmez', () {
      final reward = calculateStepCoins(
        pendingSteps: _rate - 1,
        coinsEarnedToday: 0,
      );

      expect(reward.coins, 0);
      expect(reward.consumedSteps, 0);
    });

    test('artan adımlar bir sonraki hesaba kalır', () {
      final reward = calculateStepCoins(
        pendingSteps: _rate * 2 + 17,
        coinsEarnedToday: 0,
      );

      expect(reward.coins, 2);
      // 17 adım tüketilmedi, bir sonraki hesapta değerlendirilecek.
      expect(reward.consumedSteps, _rate * 2);
    });

    test('6.000 adım beklenen günlük kazancı verir', () {
      final reward = calculateStepCoins(
        pendingSteps: 6000,
        coinsEarnedToday: 0,
      );

      expect(reward.coins, 6000 ~/ _rate);
    });

    test('sıfır veya negatif bekleyen adım hiçbir şey yapmaz', () {
      expect(calculateStepCoins(pendingSteps: 0, coinsEarnedToday: 0).coins, 0);
      expect(
        calculateStepCoins(pendingSteps: -500, coinsEarnedToday: 0).coins,
        0,
      );
    });
  });

  group('sınırsız günlük kazanç', () {
    test('eski tavanın üstündeki kazanç da tam ödenir', () {
      final reward = calculateStepCoins(
        pendingSteps: _rate * (_legacyCap + 100),
        coinsEarnedToday: 0,
      );

      expect(reward.coins, _legacyCap + 100);
      expect(reward.capReached, isFalse);
    });

    test('yüksek kazançta coin altı artık adımlar korunur', () {
      final pending = _rate * (_legacyCap + 100) + 17;
      final reward = calculateStepCoins(
        pendingSteps: pending,
        coinsEarnedToday: 0,
      );

      expect(reward.consumedSteps, pending - 17);
    });

    test('eski günlük toplam yeni adımların kazancını durdurmaz', () {
      final reward = calculateStepCoins(
        pendingSteps: _rate * 50,
        coinsEarnedToday: _legacyCap,
      );

      expect(reward.coins, 50);
      expect(reward.capReached, isFalse);
      expect(reward.consumedSteps, _rate * 50);
    });

    test('eski dailyCap parametresi ödemeyi kırpmaz', () {
      final reward = calculateStepCoins(
        pendingSteps: _rate * 30,
        coinsEarnedToday: _legacyCap - 10,
        dailyCap: _legacyCap,
      );

      expect(reward.coins, 30);
      expect(reward.capReached, isFalse);
    });
  });

  group('item buff çarpanı (hook)', () {
    test('çarpan ödemeyi büyütür, tüketilen adımı değiştirmez', () {
      final reward = calculateStepCoins(
        pendingSteps: _rate * 10,
        coinsEarnedToday: 0,
        multiplier: 1.5,
      );

      expect(reward.coins, 15);
      expect(reward.consumedSteps, _rate * 10);
    });

    test('çarpan eski günlük tavan tarafından kırpılmaz', () {
      final reward = calculateStepCoins(
        pendingSteps: _rate * _legacyCap,
        coinsEarnedToday: 0,
        multiplier: 3,
      );

      expect(reward.coins, _legacyCap * 3);
    });

    test('varsayılan çarpan davranışı değiştirmez', () {
      expect(
        calculateStepCoins(pendingSteps: _rate * 4, coinsEarnedToday: 0).coins,
        calculateStepCoins(
          pendingSteps: _rate * 4,
          coinsEarnedToday: 0,
          multiplier: 1,
        ).coins,
      );
    });
  });

  group('çift sayma yasağı', () {
    test('aynı kümülatif değer ikinci kez para kazandırmaz', () {
      final profile = UserProfile(avatar: _avatar);
      final today = DailyProgress(date: DateTime(2026, 8, 18));

      expect(award(profile, today, _rate * 10).coins, 10);
      // Kaynak aynı değeri tekrar bildirdi (ör. yeniden bağlanma).
      expect(award(profile, today, _rate * 10).coins, 0);
      expect(profile.coins, 10);
    });

    test('sayaç geriye giderse para verilmez', () {
      final profile = UserProfile(avatar: _avatar);
      final today = DailyProgress(date: DateTime(2026, 8, 18));

      award(profile, today, _rate * 10);
      expect(award(profile, today, _rate * 5).coins, 0);
      expect(profile.coins, 10);
      expect(profile.totalSteps, _rate * 10);
    });

    test('ardışık partiler yalnızca deltayı öder', () {
      final profile = UserProfile(avatar: _avatar);
      final today = DailyProgress(date: DateTime(2026, 8, 18));

      expect(award(profile, today, _rate * 10).coins, 10);
      expect(award(profile, today, _rate * 25).coins, 15);
      expect(profile.coins, 25);
      expect(profile.lastRewardedStepCount, _rate * 25);
    });

    test('macera seçimi günlük sayacı bozmaz, para tekrar verilmez', () {
      final profile = UserProfile(avatar: _avatar);
      var today = DailyProgress(date: DateTime(2026, 8, 18));

      award(profile, today, _rate * 20);
      expect(profile.coins, 20);

      // Macera seçimi: günlük hedef değişir ama adımlar korunur
      // (RootShell._selectAdventure ile aynı davranış).
      today = DailyProgress(
        date: today.date,
        steps: today.steps,
        stepGoal: 5000,
        coinsEarned: today.coinsEarned,
      );

      expect(award(profile, today, _rate * 20).coins, 0);
      expect(profile.coins, 20);
      expect(today.steps, _rate * 20);
    });
  });

  group('gün değişimi', () {
    test('yeni günde günlük kazanç sıfırlanır, işaretçi korunur', () {
      final profile = UserProfile(avatar: _avatar);
      var today = DailyProgress(date: DateTime(2026, 8, 18));

      award(profile, today, _rate * 10);
      expect(today.coinsEarned, 10);

      // Gün değişti: RootShell._refreshDayCycle yeni bir DailyProgress kurar.
      today = DailyProgress(date: DateTime(2026, 8, 19));

      expect(today.coinsEarned, 0);
      expect(profile.lastRewardedStepCount, _rate * 10);
      // Dünkü adımlar yeniden ödenmez.
      expect(award(profile, today, _rate * 10).coins, 0);
    });

    test('dünkü sınırsız kazanç bugünün sayacını etkilemez', () {
      final profile = UserProfile(avatar: _avatar);
      var today = DailyProgress(date: DateTime(2026, 8, 18));

      award(profile, today, _rate * (_legacyCap + 100));
      expect(profile.coins, _legacyCap + 100);

      today = DailyProgress(date: DateTime(2026, 8, 19));
      award(profile, today, _rate * (_legacyCap + 100) + _rate * 5);

      expect(today.coinsEarned, 5);
      expect(profile.coins, _legacyCap + 105);
    });
  });

  group('kapat-aç turu', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await GameStorage.clear();
    });

    test('işaretçi ve günlük kazanç diskten aynen döner', () async {
      final profile = UserProfile(avatar: _avatar);
      final today = DailyProgress(date: DateTime(2026, 8, 18));
      award(profile, today, _rate * 12);

      await GameStorage.save(GameState(profile: profile, today: today));
      final restored = await GameStorage.load(avatar: _avatar);

      expect(restored!.profile.coins, 12);
      expect(restored.profile.lastRewardedStepCount, _rate * 12);
      expect(restored.profile.totalSteps, _rate * 12);
      expect(restored.today.coinsEarned, 12);
    });

    test('kapat-aç sonrası aynı adımlar tekrar para kazandırmaz', () async {
      final profile = UserProfile(avatar: _avatar);
      final today = DailyProgress(date: DateTime(2026, 8, 18));
      award(profile, today, _rate * 12);

      await GameStorage.save(GameState(profile: profile, today: today));
      final restored = (await GameStorage.load(avatar: _avatar))!;

      expect(award(restored.profile, restored.today, _rate * 12).coins, 0);
      expect(restored.profile.coins, 12);
    });

    test('v3 kaydında işaretçi toplam adıma eşitlenir', () async {
      // Ekonomi yokken atılmış adımlar geriye dönük para kazandırmamalı.
      SharedPreferences.setMockInitialValues({
        _storageKey: jsonEncode({
          'schemaVersion': 3,
          'state': {
            'profile': {'totalSteps': 42000, 'coins': 0},
          },
        }),
      });

      final restored = await GameStorage.load(avatar: _avatar);

      expect(restored!.profile.totalSteps, 42000);
      expect(restored.profile.lastRewardedStepCount, 42000);
    });
  });

  group('ManualStepSource', () {
    test('kümülatif sayar ve her artışı yayınlar', () async {
      final source = ManualStepSource(initialSteps: 1000);
      final seen = <int>[];
      final subscription = source.changes.listen(seen.add);

      source.add(500);
      source.add(250);
      await Future<void>.delayed(Duration.zero);

      expect(source.cumulativeSteps, 1750);
      expect(seen, [1500, 1750]);

      await subscription.cancel();
      source.dispose();
    });

    test('sıfır veya negatif ekleme yok sayılır', () async {
      final source = ManualStepSource(initialSteps: 100);
      final seen = <int>[];
      final subscription = source.changes.listen(seen.add);

      source.add(0);
      source.add(-50);
      await Future<void>.delayed(Duration.zero);

      expect(source.cumulativeSteps, 100);
      expect(seen, isEmpty);

      await subscription.cancel();
      source.dispose();
    });
  });
}
