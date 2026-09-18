import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/game_clock.dart';
import 'package:rush_for_villains/features/daily_progress/daily_progress_dialog.dart';
import 'package:rush_for_villains/features/root/root_shell.dart';
import 'package:rush_for_villains/features/wheel/daily_wheel_screen.dart';
import 'package:rush_for_villains/l10n/app_localizations.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_engagement.dart';
import 'package:rush_for_villains/models/daily_progress.dart';
import 'package:rush_for_villains/models/game_state.dart';
import 'package:rush_for_villains/models/user_profile.dart';
import 'package:rush_for_villains/services/adventure_notification_service.dart';

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
  var now = DateTime(2026, 9, 18, 10);
  setUp(() {
    now = DateTime(2026, 9, 18, 10);
    GameClock.useSource(() => now);
    SharedPreferences.setMockInitialValues({});
    AdventureNotificationService.tappedPayload.value = null;
  });
  tearDown(GameClock.reset);
  Future<void> pump(
    WidgetTester tester,
    GameState state, {
    String locale = 'en',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        locale: Locale(locale),
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
    await tester.pump(const Duration(milliseconds: 400));
  }

  test(
    'noon reminder skips a day the player visited, including before noon',
    () {
      expect(
        AdventureNotificationService.nextNoon(now, openedToday: true),
        DateTime(2026, 9, 19, 12),
      );
      expect(
        AdventureNotificationService.nextNoon(now, openedToday: false),
        DateTime(2026, 9, 18, 12),
      );
      expect(
        AdventureNotificationService.nextNoon(
          DateTime(2026, 12, 31, 23),
          openedToday: true,
        ),
        DateTime(2027, 1, 1, 12),
      );
    },
  );
  test(
    'daily acknowledgement survives storage and expires at game-day reset',
    () {
      final state = DailyEngagement(
        streakCelebratedOn: now,
        wheelPromptedOn: now,
      );
      final restored = DailyEngagement.fromJson(state.toJson());
      expect(
        DailyEngagement.matches(
          restored.wheelPromptedOn,
          DateTime(2026, 9, 19, 3),
        ),
        isTrue,
      );
      expect(
        DailyEngagement.matches(
          restored.wheelPromptedOn,
          DateTime(2026, 9, 19, 4),
        ),
        isFalse,
      );
      expect(DailyEngagement.fromJson(null).streakCelebratedOn, isNull);
    },
  );
  testWidgets(
    'streak requires Continue then wheel Later persists through restart',
    (tester) async {
      final engagement = DailyEngagement();
      final profile = UserProfile(
        avatar: avatar,
        streakDays: 7,
        lastActiveDay: now,
      );
      final state = GameState(
        profile: profile,
        today: DailyProgress(date: now, steps: 3000),
        engagement: engagement,
      );
      await pump(tester, state);
      expect(find.text('7-day streak!'), findsOneWidget);
      await tester.tapAt(const Offset(2, 2));
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        find.byKey(const ValueKey('streak-complete-dialog')),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(
        find.byKey(const ValueKey('streak-complete-dialog')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('daily-progress-primary')));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const ValueKey('wheel-ready-dialog')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('daily-progress-later')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        DailyEngagement.matches(engagement.streakCelebratedOn, now),
        isTrue,
      );
      expect(DailyEngagement.matches(engagement.wheelPromptedOn, now), isTrue);
      final saved = state.toJson();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await pump(tester, GameState.fromJson(saved, avatar: avatar));
      expect(find.byType(DailyProgressDialog), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
  testWidgets(
    'Go to wheel navigates and an old notification does not reopen it',
    (tester) async {
      final engagement = DailyEngagement(streakCelebratedOn: now);
      final profile = UserProfile(
        avatar: avatar,
        streakDays: 2,
        lastActiveDay: now,
      );
      await pump(
        tester,
        GameState(
          profile: profile,
          today: DailyProgress(date: now, enemyDefeated: true),
          engagement: engagement,
        ),
      );
      expect(find.byKey(const ValueKey('wheel-ready-dialog')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('daily-progress-primary')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(DailyWheelScreen), findsOneWidget);
      Navigator.of(tester.element(find.byType(DailyWheelScreen))).pop();
      await tester.pump(const Duration(milliseconds: 400));
      AdventureNotificationService
          .tappedPayload
          .value = AdventureNotificationService.dailyPayload(
        'daily-wheel',
        now.subtract(const Duration(days: 1)),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DailyProgressDialog), findsNothing);
      AdventureNotificationService.tappedPayload.value =
          AdventureNotificationService.dailyPayload('daily-wheel', now);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const ValueKey('wheel-ready-dialog')), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
  for (final locale in ['en', 'tr']) {
    for (final wheel in [false, true]) {
      testWidgets(
        'dialog fits small screen and large text $locale wheel=$wheel',
        (tester) async {
          tester.view.physicalSize = const Size(320, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.dark,
              locale: Locale(locale),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder:
                  (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: const TextScaler.linear(1.5)),
                    child: child!,
                  ),
              home: Scaffold(
                body: DailyProgressDialog(
                  wheel: wheel,
                  streakDays: 365,
                  avatar: avatar,
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 500));
          await tester.ensureVisible(
            find.byKey(const ValueKey('daily-progress-primary')),
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }
}
