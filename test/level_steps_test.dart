import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rush_for_villains/core/utils/level_steps.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_progress.dart';
import 'package:rush_for_villains/models/game_state.dart';
import 'package:rush_for_villains/models/user_profile.dart';
import 'package:rush_for_villains/services/game_storage.dart';

const avatar = AvatarProfile(
  name: 'Saved hero',
  age: 28,
  weight: 74,
  gender: 'Male',
  characterClass: 'Swordsman',
  characterAsset: 'test.gif',
);
const key = 'game_state_v1';
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GameStorage.clear();
  });
  test('formula matches reference values and is finite beyond level 80', () {
    const expected = {
      1: 500,
      2: 1100,
      3: 1500,
      4: 1850,
      5: 2100,
      10: 3000,
      12: 3250,
      20: 4000,
      30: 4600,
      40: 5100,
      49: 5400,
      50: 5450,
      80: 6250,
    };
    for (final entry in expected.entries) {
      expect(calculateRequiredSteps(entry.key), entry.value);
    }
    expect(calculateRequiredSteps(0), 500);
    expect(calculateRequiredSteps(-1), 500);
    for (var level = 1; level <= 10000; level++) {
      expect(calculateRequiredSteps(level), greaterThan(0));
      expect(calculateRequiredSteps(level) % 50, 0);
    }
    expect(calculateRequiredSteps(0x7fffffffffffffff), greaterThan(0));
  });
  test('499 is insufficient; the 500th step grants level two', () {
    final p = UserProfile(avatar: avatar);
    expect(p.level, 1);
    expect(p.creditLevelStepsThrough(499), 0);
    expect(p.levelStepProgress, 499);
    expect(p.creditLevelStepsThrough(500), 1);
    expect(p.level, 2);
    expect(p.levelStepProgress, 0);
  });
  test(
    'overflow carries, batches grant every level, duplicate and negative totals do nothing',
    () {
      final p = UserProfile(avatar: avatar);
      p.creditLevelStepsThrough(1000);
      expect(p.level, 2);
      expect(p.levelStepProgress, 500);
      p.creditLevelStepsThrough(1000);
      p.creditLevelStepsThrough(-20);
      p.creditLevelStepsThrough(900);
      expect(p.levelStepProgress, 500);
      expect(p.lastLevelRewardedStepCount, 1000);
      expect(p.creditLevelStepsThrough(3200), 2);
      expect(p.level, 4);
      expect(p.levelStepProgress, 100);
    },
  );
  test(
    'XP stays independent and cannot grant levels or consume step progress',
    () {
      final p = UserProfile(
        avatar: avatar,
        level: 12,
        levelStepProgress: 2100,
        xp: 19,
      );
      p.addXp(100000);
      p.addXp(-500);
      expect(p.level, 12);
      expect(p.levelStepProgress, 2100);
      expect(p.xp, 100019);
      expect(p.totalXpEarned, 100000);
    },
  );
  test('level 80 takes 371850 steps and 75 days at 5000 steps', () {
    var total = 0;
    for (var level = 1; level < 80; level++) {
      total += calculateRequiredSteps(level);
    }
    expect(total, 371850);
    final p = UserProfile(avatar: avatar);
    var days = 0;
    while (p.level < 80) {
      days++;
      p.creditLevelStepsThrough(days * 5000);
      expect(days, lessThan(100));
    }
    expect(days, 75);
    expect(p.level, 80);
    expect(p.levelStepProgress, 3150);
  });
  test(
    'new state round trips progress; daily reset never resets levels',
    () async {
      final p = UserProfile(avatar: avatar, totalSteps: 0, xp: 100, coins: 35);
      p.totalSteps = 1000;
      p.creditLevelStepsThrough(p.totalSteps);
      final today = DailyProgress(date: DateTime(2026, 9, 18), steps: 1000);
      expect(today.stepGoal, 7000);
      await GameStorage.save(GameState(profile: p, today: today));
      final saved = await GameStorage.load(avatar: avatar);
      expect(saved!.profile.level, 2);
      expect(saved.profile.levelStepProgress, 500);
      expect(saved.profile.creditLevelStepsThrough(1000), 0);
      final tomorrow = GameState(
        profile: saved.profile,
        today: DailyProgress(date: DateTime(2026, 9, 19)),
      );
      expect(tomorrow.today.steps, 0);
      expect(tomorrow.today.stepGoal, 7000);
      expect(tomorrow.profile.levelStepProgress, 500);
    },
  );
  test(
    'v24 migration preserves every existing profile field, history and other keys',
    () async {
      final p = UserProfile(
        avatar: avatar,
        level: 49,
        xp: 23456,
        totalSteps: 900001,
        coins: 890,
        lastReportedStepCount: 900001,
        lastSensorReading: 999999,
        hasCompletedTutorial: true,
        tutorialStep: 17,
        tutorialGuideId: 'pinky',
        ownedUpgradeIds: ['xp_boost', 'skin'],
        ownedTitleIds: ['hero'],
        equippedTitleId: 'hero',
        wheelSpins: 17,
        adventuresCompleted: 30,
        earnedRewardDates: {'reward': DateTime(2026, 9, 1)},
        pinnedRewardIds: ['reward'],
        villainDefeatCounts: {'ash_guardian': 11},
        extraWheelSpins: 2,
        petCompanionEnabled: false,
      );
      p.addItem('saved_sword', level: 3);
      final before =
          Map<String, dynamic>.from(p.toJson())
            ..remove('levelStepProgress')
            ..remove('lastLevelRewardedStepCount');
      final raw = jsonEncode({
        'schemaVersion': 24,
        'state': {
          'profile': before,
          'today': {
            'date': '2026-09-18T12:00:00.000',
            'steps': 4250,
            'stepGoal': 20000,
            'coinsEarned': 85,
            'xpEarned': 2125,
            'enemyDefeated': true,
          },
          'stepHistory': [
            {
              'date': '2026-09-17T12:00:00.000',
              'steps': 10000,
              'stepGoal': 5000,
            },
          ],
        },
      });
      SharedPreferences.setMockInitialValues({
        key: raw,
        'player_avatar_v1': 'unchanged-avatar',
        'locale_preference_v1': 'tr',
      });
      final migrated = await GameStorage.load(avatar: avatar);
      expect(migrated, isNotNull);
      final after =
          Map<String, dynamic>.from(migrated!.profile.toJson())
            ..remove('levelStepProgress')
            ..remove('lastLevelRewardedStepCount');
      expect(after, before);
      expect(migrated.profile.levelStepProgress, 0);
      expect(migrated.profile.lastLevelRewardedStepCount, 900001);
      expect(migrated.profile.creditLevelStepsThrough(900001), 0);
      expect(migrated.today.steps, 4250);
      expect(migrated.today.stepGoal, 7000);
      expect(migrated.today.coinsEarned, 85);
      expect(migrated.today.xpEarned, 2125);
      expect(migrated.today.enemyDefeated, isTrue);
      expect(migrated.stepHistory.single.stepGoal, 5000);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(GameStorage.migrationBackupKey), raw);
      expect(prefs.getString('player_avatar_v1'), 'unchanged-avatar');
      expect(prefs.getString('locale_preference_v1'), 'tr');
      final committed = prefs.getString(key);
      expect((jsonDecode(committed!) as Map)['schemaVersion'], 25);
      await GameStorage.load(avatar: avatar);
      expect(
        prefs.getString(key),
        committed,
        reason: 'migration must commit only once',
      );
    },
  );
  for (final raw in [
    'broken-json',
    jsonEncode({'schemaVersion': 999, 'state': {}}),
    jsonEncode({
      'schemaVersion': 24,
      'state': {
        'profile': {'level': 'bad'},
      },
    }),
  ]) {
    test('failed read prevents defaults overwriting original: $raw', () async {
      SharedPreferences.setMockInitialValues({key: raw});
      expect(await GameStorage.load(avatar: avatar), isNull);
      expect(GameStorage.writeBlocked, isTrue);
      final empty = GameState(
        profile: UserProfile(avatar: avatar),
        today: DailyProgress(date: DateTime(2026, 9, 18)),
      );
      await GameStorage.save(empty);
      GameStorage.scheduleSave(empty);
      await GameStorage.flush();
      expect((await SharedPreferences.getInstance()).getString(key), raw);
    });
  }
}
