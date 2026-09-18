import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/game_clock.dart';
import 'package:rush_for_villains/features/home/home_screen.dart';
import 'package:rush_for_villains/features/root/root_shell.dart';
import 'package:rush_for_villains/models/daily_engagement.dart';
import 'package:rush_for_villains/models/daily_progress.dart';
import 'package:rush_for_villains/models/game_state.dart';
import 'package:rush_for_villains/models/user_profile.dart';
import 'package:rush_for_villains/services/game_storage.dart';
import 'package:rush_for_villains/services/level_events.dart';
import 'daily_engagement_test.dart' show avatar;

void main() {
  testWidgets(
    'accepted steps drive real level events, daily target and restart',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await GameStorage.clear();
      var now = DateTime(2026, 9, 18, 12);
      GameClock.useSource(() => now);
      addTearDown(GameClock.reset);
      final profile = UserProfile(avatar: avatar);
      final state = GameState(
        profile: profile,
        today: DailyProgress(date: now),
        engagement: DailyEngagement(
          streakCelebratedOn: now,
          wheelPromptedOn: now,
        ),
      );
      final events = <LevelUpEvent>[];
      final sub = LevelEvents.stream.listen(events.add);
      addTearDown(sub.cancel);
      Future<void> mount(GameState data) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: RootShell(
              avatar: avatar,
              initialState: data,
              onAvatarChanged: (_) {},
            ),
          ),
        );
        await tester.pump();
      }

      HomeScreen home() => tester.widget<HomeScreen>(find.byType(HomeScreen));
      await mount(state);
      home().onSimulateSteps(499);
      await tester.pump();
      expect(profile.level, 1);
      expect(profile.levelStepProgress, 499);
      expect(events, isEmpty);
      home().onSimulateSteps(-100);
      await tester.pump();
      expect(profile.levelStepProgress, 499);
      home().onSimulateSteps(1);
      await tester.pump();
      await tester.pump();
      expect(profile.level, 2);
      expect(profile.levelStepProgress, 0);
      expect(events.single.newLevel, 2);
      expect(home().today.stepGoal, 7000);
      home().onSimulateSteps(500);
      await tester.pump();
      expect(profile.levelStepProgress, 500);
      expect(profile.xp, 500);
      await GameStorage.flush();
      final raw =
          (await SharedPreferences.getInstance()).getString('game_state_v1')!;
      final saved = GameState.fromJson(
        (jsonDecode(raw) as Map<String, dynamic>)['state']
            as Map<String, dynamic>,
        avatar: avatar,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await mount(saved);
      expect(home().profile.level, 2);
      expect(home().profile.levelStepProgress, 500);
      now = now.add(const Duration(days: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(home().today.steps, 0);
      expect(home().today.stepGoal, 7000);
      expect(home().profile.levelStepProgress, 500);
      home().onSimulateSteps(0);
      await tester.pump();
      expect(home().profile.totalSteps, 1000);
      home().onSimulateSteps(7000);
      await tester.pump();
      await tester.pump();
      expect(home().today.stepGoalReached, isTrue);
      expect(home().today.isWheelUnlocked, isTrue);
      expect(home().profile.totalSteps, 8000);
      expect(events.last.levelsGained, greaterThan(1));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
