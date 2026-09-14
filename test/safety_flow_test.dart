import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rush_for_villains/core/constants/safety_messages.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/game_clock.dart';
import 'package:rush_for_villains/data/enemy_catalog.dart';
import 'package:rush_for_villains/features/adventure/adventure_screen.dart';
import 'package:rush_for_villains/features/home/home_screen.dart';
import 'package:rush_for_villains/features/root/root_shell.dart';
import 'package:rush_for_villains/features/safety/safety_screen.dart';
import 'package:rush_for_villains/models/adventure_quest.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_progress.dart';
import 'package:rush_for_villains/models/game_state.dart';
import 'package:rush_for_villains/models/user_profile.dart';
import 'package:rush_for_villains/services/game_storage.dart';
import 'package:rush_for_villains/services/item_catalog.dart';
import 'package:rush_for_villains/services/safety_notice_storage.dart';

const avatar = AvatarProfile(
  name: 'Safe Walker',
  characterClass: 'Swordsman',
  age: 28,
  weight: 74,
  gender: 'Erkek',
  characterAsset:
      'lib/All_Assets/Avatars/Classes/Characters(100x100 split)/Swordsman/Swordsman/Swordsman_Walk.gif',
);
const copy = SafetyMessages();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DateTime now;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GameClock.reset();
    now = DateTime(2026, 9, 14, 12);
    GameClock.useSource(() => now);
    ItemCatalog.reset(const []);
  });
  tearDown(() async {
    await GameStorage.flush();
    GameClock.reset();
    ItemCatalog.reset();
  });

  test(
    'notice persists and a previous version requires acknowledgement',
    () async {
      expect(await SafetyNoticeStorage.isAccepted(), isFalse);
      await SafetyNoticeStorage.accept();
      expect(await SafetyNoticeStorage.isAccepted(), isTrue);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        SafetyNoticeStorage.key,
        SafetyMessages.noticeVersion - 1,
      );
      expect(await SafetyNoticeStorage.isAccepted(), isFalse);
    },
  );

  testWidgets('checkbox gates continue and acceptance persists', (
    tester,
  ) async {
    var continued = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: SafetyScreen(onAccepted: () => continued = true),
      ),
    );
    await tester.scrollUntilVisible(find.byType(FilledButton), 250);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.scrollUntilVisible(find.byType(FilledButton), 250);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(continued, isTrue);
    expect(await SafetyNoticeStorage.isAccepted(), isTrue);
  });

  testWidgets('read-only safety page does not alter consent', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const SafetyScreen()),
    );
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(find.text(copy.fullNotice), findsOneWidget);
    expect(await SafetyNoticeStorage.isAccepted(), isFalse);
  });

  testWidgets('small screen and large text safety content remains scrollable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.8)),
              child: child!,
            ),
        home: SafetyScreen(onAccepted: () {}),
      ),
    );
    await tester.scrollUntilVisible(find.byType(FilledButton), 250);
    expect(tester.takeException(), isNull);
  });

  Future<UserProfile> shell(
    WidgetTester tester, {
    AdventureQuest? quest,
    int steps = 0,
    DateTime? savedDay,
  }) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final profile = UserProfile(avatar: avatar, level: 40);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: RootShell(
          avatar: avatar,
          onAvatarChanged: (_) {},
          initialState: GameState(
            profile: profile,
            today: DailyProgress(date: savedDay ?? now, steps: steps),
            adventure: quest,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return profile;
  }

  Future<void> openAdventure(WidgetTester tester) async {
    final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
    nav.onDestinationSelected!(1);
    await tester.pump();
    await tester.pump();
  }

  Future<void> confirm(WidgetTester tester, String text) async {
    await tester.pump(const Duration(milliseconds: 300));
    if (text == copy.startAdventure) {
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, text).last)
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('walking-safety-acknowledgement')),
      );
      await tester.tap(
        find.byKey(const ValueKey('walking-safety-acknowledgement')),
      );
      await tester.pump();
    }
    await tester.tap(find.widgetWithText(FilledButton, text).last);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  }

  testWidgets(
    'every adventure is gated; cancelled selection never starts; steps during modal excluded',
    (tester) async {
      await shell(tester);
      final beforeSelectionHome = tester.widget<HomeScreen>(
        find.byType(HomeScreen),
      );
      await SafetyNoticeStorage.accept();
      await openAdventure(tester);
      var screen = tester.widget<AdventureScreen>(find.byType(AdventureScreen));
      final selected = AdventureQuest(
        enemy: EnemyCatalog.byId('tense_soldier')!,
        stepGoal: 500,
        startedAt: now,
      );
      screen.onAdventureSelected(selected);
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester.widget<AdventureScreen>(find.byType(AdventureScreen)).adventure,
        isNull,
      );
      await tester.tap(find.text(copy.later));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester.widget<AdventureScreen>(find.byType(AdventureScreen)).adventure,
        isNull,
      );
      screen.onAdventureSelected(selected);
      beforeSelectionHome.onSimulateSteps(1000);
      await tester.pump();
      await confirm(tester, copy.startAdventure);
      screen = tester.widget<AdventureScreen>(find.byType(AdventureScreen));
      expect(screen.adventure, isNotNull);
      expect(screen.adventure!.startingSteps, 1000);
      screen.onChooseNewAdventure();
      await tester.pump();
      screen = tester.widget<AdventureScreen>(find.byType(AdventureScreen));
      screen.onAdventureSelected(selected);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(copy.adventureNotice), findsOneWidget);
      await tester.tap(find.text(copy.later));
      await tester.pump(const Duration(milliseconds: 300));
    },
  );

  testWidgets(
    'completed round resolves automatically and reward remains single-shot',
    (tester) async {
      final quest = AdventureQuest(
        enemy: EnemyCatalog.byId('tense_soldier')!,
        stepGoal: 500,
        startedAt: now,
      );
      final profile = await shell(tester, quest: quest);
      final adventureScreen = tester.widget<AdventureScreen>(
        find.byType(AdventureScreen),
      );
      adventureScreen.onSimulateSteps!(1000);
      await tester.pump();
      expect(quest.roundOutcomeSerial, 1);
      expect(quest.isEnemyDefeated, isTrue);
      expect(quest.xpAwarded, isTrue);
      expect(profile.enemiesDefeated, 1);
      final coins = profile.coins;
      now = now.add(const Duration(days: 2));
      await tester.pump(const Duration(seconds: 2));
      expect(profile.coins, coins);
      await GameStorage.flush();
      final restored = await GameStorage.load(avatar: avatar);
      expect(restored!.adventure!.isEnemyDefeated, isTrue);
      expect(restored.adventure!.xpAwarded, isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    },
  );

  test('expired rounds deal damage while early completion earns a bonus', () {
    AdventureQuest fresh() => AdventureQuest(
      enemy: EnemyCatalog.byId('tense_soldier')!,
      stepGoal: 2000,
      combatSeed: 77,
      startedAt: now,
    );
    final early = fresh(), late = fresh();
    final missed = late.resolveRound(0, now.add(const Duration(days: 20)));
    expect(missed, isNotNull);
    expect(missed!.playerDamage, greaterThan(0));
    expect(late.playerHealth, lessThan(AdventureQuest.maxPlayerHealth));
    final a = early.resolveRound(1000, now.add(const Duration(seconds: 1)));
    final b = late.resolveRound(1000, now.add(const Duration(days: 20)));
    expect(a!.perfect, isTrue);
    expect(a.perfectDamageMultiplier, greaterThan(1));
    expect(b!.perfect, isFalse);
    expect(b.perfectDamageMultiplier, 1);
  });

  testWidgets('revival walking requires a fresh safety acknowledgement', (
    tester,
  ) async {
    final quest = AdventureQuest(
      enemy: EnemyCatalog.byId('tense_soldier')!,
      stepGoal: 500,
      battleOutcome: AdventureBattleOutcome.defeat,
    );
    await shell(tester, quest: quest);
    await openAdventure(tester);
    tester
        .widget<AdventureScreen>(find.byType(AdventureScreen))
        .onStartRevival();
    await tester.pump(const Duration(milliseconds: 300));
    expect(quest.revivalStarted, isFalse);
    await confirm(tester, copy.startAdventure);
    expect(quest.revivalStarted, isTrue);
  });
  test(
    'banked steps preserve round sizes and waiting never reduces reward',
    () {
      AdventureQuest fresh() => AdventureQuest(
        enemy: EnemyCatalog.byId('ash_guardian')!,
        stepGoal: 2500,
        combatSeed: 77,
        startedAt: now,
      );
      final banked = fresh();
      banked.resolveRound(2500, now);
      expect(banked.roundTargetSteps, 500);
      banked.resolveRound(2500, now);
      if (!banked.isBattleCompleted) expect(banked.roundTargetSteps, 500);
    },
  );

  for (final width in [320.0, 390.0]) {
    testWidgets('safety notice golden ${width.toInt()}', (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: SafetyScreen(onAccepted: () {}),
        ),
      );
      await tester.pump();
      await expectLater(
        find.byType(SafetyScreen),
        matchesGoldenFile('goldens/safety_notice_${width.toInt()}.png'),
      );
      expect(tester.takeException(), isNull);
    });
  }
  for (final battle in [false, true]) {
    testWidgets('short safety reminder fits small screen battle=$battle', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.4)),
                child: child!,
              ),
          home: Builder(
            builder:
                (context) => Scaffold(
                  body: TextButton(
                    onPressed:
                        () => showSafetyReminder(context, battle: battle),
                    child: const Text('open'),
                  ),
                ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.text(battle ? copy.battleNotice : copy.adventureNotice),
        findsOneWidget,
      );
      await tester.tap(find.text(copy.later));
      await tester.pumpAndSettle();
    });
  }
}
