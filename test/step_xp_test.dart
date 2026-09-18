import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/game_constants.dart';
import 'package:rush_for_villains/core/utils/coin_calculator.dart';
import 'package:rush_for_villains/core/utils/xp_calculator.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_progress.dart';
import 'package:rush_for_villains/models/game_state.dart';
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

final _xpRate = GameConstants.stepsPerXp;
final _coinRate = GameConstants.stepsPerCoin;
final _legacyCoinCap = GameConstants.maxDailyStepCoins;

/// `RootShell._awardXp`'in test kopyası: XP verir, seviye atlandıysa yayınlar.
void awardXp(UserProfile profile, int amount) => profile.addXp(amount);

/// Adım akışının test kopyası: para ve XP aynı partiden, **ayrı**
/// işaretçilerle hesaplanır (RootShell._onStepsReported ile aynı sıra).
void walk(UserProfile profile, DailyProgress today, int steps) {
  if (steps <= 0) return;
  today.addSteps(steps);
  profile.totalSteps += steps;
  profile.creditLevelStepsThrough(profile.totalSteps);

  final coinReward = calculateStepCoins(
    pendingSteps: profile.totalSteps - profile.lastRewardedStepCount,
    coinsEarnedToday: today.coinsEarned,
  );
  profile.coins += coinReward.coins;
  profile.lastRewardedStepCount += coinReward.consumedSteps;
  today.coinsEarned += coinReward.coins;

  final xpReward = calculateStepXp(
    pendingSteps: profile.totalSteps - profile.lastXpRewardedStepCount,
  );
  profile.lastXpRewardedStepCount += xpReward.consumedSteps;
  today.xpEarned += xpReward.xp;
  awardXp(profile, xpReward.xp);
}

/// Belirli bir seviyeye ulaşmak için gereken kümülatif XP: 500·N·(N-1).
void main() {
  group('adım → XP dönüşümü', () {
    test('oran kadar adım 1 XP eder', () {
      expect(calculateStepXp(pendingSteps: _xpRate * 7).xp, 7);
    });

    test('orana yetmeyen adım XP vermez ve tüketilmez', () {
      final reward = calculateStepXp(pendingSteps: _xpRate - 1);
      expect(reward.xp, 0);
      expect(reward.consumedSteps, 0);
    });

    test('artan adımlar bir sonraki hesaba kalır', () {
      final reward = calculateStepXp(pendingSteps: _xpRate * 4 + 1);
      expect(reward.xp, 4);
      expect(reward.consumedSteps, _xpRate * 4);
    });

    test('sıfır veya negatif bekleyen adım hiçbir şey yapmaz', () {
      expect(calculateStepXp(pendingSteps: 0).xp, 0);
      expect(calculateStepXp(pendingSteps: -400).xp, 0);
    });

    test('günlük XP tavanı yok', () {
      final reward = calculateStepXp(pendingSteps: 100000);
      expect(reward.xp, 100000 ~/ _xpRate);
    });

    test('buff çarpanı ödemeyi büyütür, tüketilen adımı değiştirmez', () {
      final reward = calculateStepXp(pendingSteps: _xpRate * 10, multiplier: 2);
      expect(reward.xp, 20);
      expect(reward.consumedSteps, _xpRate * 10);
    });
  });

  group('çift sayma yasağı', () {
    test('aynı adımlar ikinci kez XP kazandırmaz', () {
      final profile = UserProfile(avatar: _avatar);
      final today = DailyProgress(date: DateTime(2026, 8, 18));

      walk(profile, today, _xpRate * 100);
      final xpAfterFirst = profile.xp;

      // Hiç yeni adım gelmedi.
      walk(profile, today, 0);

      expect(profile.xp, xpAfterFirst);
      expect(profile.lastXpRewardedStepCount, _xpRate * 100);
    });

    test('ardışık partiler yalnızca deltayı öder', () {
      final profile = UserProfile(avatar: _avatar);
      final today = DailyProgress(date: DateTime(2026, 8, 18));

      walk(profile, today, 1000);
      walk(profile, today, 1000);

      expect(today.xpEarned, 2000 ~/ _xpRate);
    });

    test('gün değişimi işaretçiyi sıfırlamaz', () {
      final profile = UserProfile(avatar: _avatar);
      var today = DailyProgress(date: DateTime(2026, 8, 18));
      walk(profile, today, 2000);
      final xpAfterFirstDay = profile.xp;

      today = DailyProgress(date: DateTime(2026, 8, 19));
      walk(profile, today, 2000);

      // Günlük sayaç sıfırlandı ama dünkü adımlar tekrar ödenmedi.
      expect(today.xpEarned, 2000 ~/ _xpRate);
      expect(profile.xp - xpAfterFirstDay, 2000 ~/ _xpRate);
    });
  });

  group('para ve XP işaretçileri bağımsız', () {
    test('yüksek günlük kazançta para da XP de akmaya devam eder', () {
      final profile = UserProfile(avatar: _avatar);
      final today = DailyProgress(date: DateTime(2026, 8, 18));

      // Eski 400 coin eşiğine ulaşacak kadar adım.
      walk(profile, today, _coinRate * _legacyCoinCap);
      expect(today.coinsEarned, _legacyCoinCap);
      expect(today.coinCapReached, isFalse);
      final xpAtLegacyCap = profile.xp;

      // Aynı gün 4.000 adım daha: iki ekonomi de ilerlemeli.
      walk(profile, today, 4000);

      expect(today.coinsEarned, _legacyCoinCap + 4000 ~/ _coinRate);
      expect(
        profile.xp - xpAtLegacyCap,
        4000 ~/ _xpRate,
        reason: 'XP de akmaya devam etmeli',
      );
    });

    test('iki işaretçi farklı hızda ilerler', () {
      final profile = UserProfile(avatar: _avatar);
      final today = DailyProgress(date: DateTime(2026, 8, 18));

      // 75 adım: XP'ye 74'ü (37 XP), paraya 50'si (1 coin) çevrilir.
      walk(profile, today, 75);

      expect(profile.lastXpRewardedStepCount, 74);
      expect(profile.lastRewardedStepCount, 50);
      expect(profile.coins, 1);
      expect(today.xpEarned, 37);
    });
  });

  group('kalıcılık', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await GameStorage.clear();
    });

    test('XP işaretçisi ve günlük XP diskten aynen döner', () async {
      final profile = UserProfile(avatar: _avatar);
      final today = DailyProgress(date: DateTime(2026, 8, 18));
      walk(profile, today, 3000);

      await GameStorage.save(GameState(profile: profile, today: today));
      final restored = (await GameStorage.load(avatar: _avatar))!;

      expect(restored.profile.lastXpRewardedStepCount, 3000);
      expect(restored.profile.xp, profile.xp);
      expect(restored.profile.level, profile.level);
      expect(restored.today.xpEarned, 3000 ~/ _xpRate);
    });

    test('kapat-aç sonrası aynı adımlar tekrar XP kazandırmaz', () async {
      final profile = UserProfile(avatar: _avatar);
      final today = DailyProgress(date: DateTime(2026, 8, 18));
      walk(profile, today, 3000);

      await GameStorage.save(GameState(profile: profile, today: today));
      final restored = (await GameStorage.load(avatar: _avatar))!;
      final xpBefore = restored.profile.xp;

      walk(restored.profile, restored.today, 0);

      expect(restored.profile.xp, xpBefore);
    });

    test('v5 kaydında XP işaretçisi toplam adıma eşitlenir', () async {
      // XP yokken atılmış adımlar geriye dönük seviye kazandırmamalı.
      SharedPreferences.setMockInitialValues({
        _storageKey: jsonEncode({
          'schemaVersion': 5,
          'state': {
            'profile': {
              'totalSteps': 90000,
              'lastRewardedStepCount': 90000,
              'lastReportedStepCount': 90000,
              'level': 1,
              'xp': 0,
            },
            'today': {'date': DateTime(2026, 8, 18, 10).toIso8601String()},
          },
        }),
      });

      final restored = (await GameStorage.load(avatar: _avatar))!;

      expect(restored.profile.lastXpRewardedStepCount, 90000);
      expect(restored.profile.level, 1);

      // Yeni adımlar normal XP kazandırır.
      walk(restored.profile, restored.today, 1000);
      expect(restored.profile.xp, 1000 ~/ _xpRate);
    });
  });
}
