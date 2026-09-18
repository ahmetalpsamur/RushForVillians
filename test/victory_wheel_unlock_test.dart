import 'package:rush_for_villains/models/daily_engagement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/game_clock.dart';
import 'package:rush_for_villains/data/enemy_catalog.dart';
import 'package:rush_for_villains/features/adventure/adventure_screen.dart';
import 'package:rush_for_villains/features/home/home_screen.dart';
import 'package:rush_for_villains/features/root/root_shell.dart';
import 'package:rush_for_villains/features/wheel/daily_wheel_screen.dart';
import 'package:rush_for_villains/l10n/app_localizations.dart';
import 'package:rush_for_villains/models/adventure_quest.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_progress.dart';
import 'package:rush_for_villains/models/game_state.dart';
import 'package:rush_for_villains/models/user_profile.dart';

const avatar = AvatarProfile(
  name: 'Walker',
  age: 28,
  weight: 74,
  gender: 'Male',
  characterClass: 'Swordsman',
  characterAsset:
      'lib/All_Assets/Avatars/Classes/Characters(100x100 split)/Swordsman/Swordsman/Swordsman_Walk.gif',
);

void main() {
  for (final legacyVictory in [false, true]) {
    testWidgets(
      'wheel survives bonus walk exit and restart (legacy: $legacyVictory)',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        var now = DateTime(2026, 9, 18, 12);
        GameClock.useSource(() => now);
        addTearDown(GameClock.reset);
        tester.view.physicalSize = const Size(1000, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final profile = UserProfile(avatar: avatar, level: 50);
        final engagement = DailyEngagement(
          streakCelebratedOn: now,
          wheelPromptedOn: now,
        );
        final today = DailyProgress(date: now, steps: 250);
        final quest = AdventureQuest(
          enemy: EnemyCatalog.enemies.first,
          stepGoal: 500,
          startedAt: now,
          enemyHealth: legacyVictory ? 0 : 1,
          battleOutcome:
              legacyVictory
                  ? AdventureBattleOutcome.victory
                  : AdventureBattleOutcome.active,
          xpAwarded: legacyVictory,
          victorySteps: legacyVictory ? 250 : -1,
          deathAnimationPlayed: legacyVictory,
        );
        Future<void> mount(GameState state) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.dark,
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: RootShell(
                avatar: avatar,
                initialState: state,
                onAvatarChanged: (_) {},
              ),
            ),
          );
          await tester.pump();
        }

        await mount(
          GameState(
            profile: profile,
            today: today,
            adventure: quest,
            engagement: engagement,
          ),
        );
        if (!legacyVictory) {
          expect(today.isWheelUnlocked, isFalse);
          now = quest.nextEnemyAttackAt.add(const Duration(seconds: 1));
          await tester.pump(const Duration(seconds: 1));
        }
        expect(quest.isEnemyDefeated, isTrue);
        expect(quest.isAdventureCompleted, isFalse);
        expect(today.steps, lessThan(3000));
        expect(today.isWheelUnlocked, isTrue);
        final coins = profile.coins;
        tester
            .widget<AdventureScreen>(find.byType(AdventureScreen))
            .onChooseNewAdventure();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.textContaining('daily wheel access'), findsOneWidget);
        await tester.tap(
          find
              .descendant(
                of: find.byType(AlertDialog),
                matching: find.byType(TextButton),
              )
              .last,
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Home').last);
        await tester.pump(const Duration(milliseconds: 300));
        final home = tester.widget<HomeScreen>(find.byType(HomeScreen));
        expect(home.today.isWheelUnlocked, isTrue);
        expect(profile.coins, coins);
        await tester.pump(const Duration(seconds: 5));
        await tester.ensureVisible(find.text('Daily Wheel'));
        await tester.tap(find.text('Daily Wheel'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(DailyWheelScreen), findsOneWidget);
        final saved =
            GameState(
              profile: profile,
              today: home.today,
              engagement: engagement,
            ).toJson();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await mount(GameState.fromJson(saved, avatar: avatar));
        expect(
          tester
              .widget<HomeScreen>(find.byType(HomeScreen))
              .today
              .isWheelUnlocked,
          isTrue,
        );
        // A win unlocks only its own game day; reopening must not grant another.
        now = now.add(const Duration(days: 1));
        await tester.pump(const Duration(seconds: 1));
        expect(
          tester
              .widget<HomeScreen>(find.byType(HomeScreen))
              .today
              .isWheelUnlocked,
          isFalse,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  }
}
