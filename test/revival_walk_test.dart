import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/game_clock.dart';
import 'package:rush_for_villains/data/enemy_catalog.dart';
import 'package:rush_for_villains/features/adventure/adventure_screen.dart';
import 'package:rush_for_villains/features/root/root_shell.dart';
import 'package:rush_for_villains/models/adventure_quest.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_progress.dart';
import 'package:rush_for_villains/models/game_state.dart';
import 'package:rush_for_villains/models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _avatar = AvatarProfile(
  name: 'Barca',
  age: 28,
  weight: 74,
  gender: 'Erkek',
  characterClass: 'Swordsman',
  characterAsset:
      'lib/All_Assets/Avatars/Classes/Characters(100x100 split)/Swordsman/Swordsman/Swordsman_Walk.gif',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('yenilgi yeni macera yerine Hayat Yürüyüşünü başlatır', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});

    final adventure = AdventureQuest(
      enemy: EnemyCatalog.enemies.first,
      stepGoal: 500,
      battleOutcome: AdventureBattleOutcome.defeat,
      playerHealth: 0,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: RootShell(
          avatar: _avatar,
          initialState: GameState(
            profile: UserProfile(avatar: _avatar),
            today: DailyProgress(date: GameClock.now()),
            adventure: adventure,
          ),
          onAvatarChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Macera').last);
    await tester.pump();
    expect(find.byKey(const ValueKey('start-revival-walk')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('start-revival-walk')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(adventure.revivalStarted, isFalse);
    await tester.tap(
      find.byKey(const ValueKey('walking-safety-acknowledgement')),
    );
    await tester.pump();
    await tester.tap(find.text('Güvendeyim, Maceraya Başla'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Hayat Yürüyüşü'), findsOneWidget);
    expect(find.text('0 / 500 adım'), findsOneWidget);
    expect(find.text('Macera Seçimine Dön'), findsNothing);
  });

  testWidgets('500 adımlık Hayat Yürüyüşü XP vermeden yeniden doğurur', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});

    final adventure = AdventureQuest(
      enemy: EnemyCatalog.enemies.first,
      stepGoal: 500,
      battleOutcome: AdventureBattleOutcome.defeat,
      playerHealth: 0,
      revivalStarted: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: RootShell(
          avatar: _avatar,
          initialState: GameState(
            profile: UserProfile(avatar: _avatar),
            today: DailyProgress(date: GameClock.now()),
            adventure: adventure,
          ),
          onAvatarChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    final adventureScreen = tester.widget<AdventureScreen>(
      find.byType(AdventureScreen),
    );
    adventureScreen.onSimulateSteps!(500);
    await tester.pump();
    await tester.pump();

    expect(find.text('Yeniden doğdun!'), findsOneWidget);
    expect(find.textContaining('Bu yürüyüş XP vermedi'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('acknowledge-revival')));
    await tester.pump();
    expect(find.text('Bugünkü maceranı seç'), findsOneWidget);
  });
}
