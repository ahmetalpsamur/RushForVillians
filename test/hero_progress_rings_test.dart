import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_progress.dart';
import 'package:rush_for_villains/models/user_profile.dart';
import 'package:rush_for_villains/widgets/hero_progress_rings.dart';
import 'package:rush_for_villains/widgets/stat_bar.dart';

const _avatar = AvatarProfile(
  name: 'Barca',
  age: 28,
  weight: 74,
  gender: 'Erkek',
  characterClass: 'Knight',
  characterAsset:
      'lib/All_Assets/Avatars/Classes/Characters(100x100 split)/Knight/Knight/Knight_Walk.gif',
);

void main() {
  Future<void> pumpRings(WidgetTester tester, int steps) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: HeroProgressRings(
              profile: UserProfile(avatar: _avatar),
              today: DailyProgress(
                date: DateTime(2026, 8, 27),
                steps: steps,
                stepGoal: 20000,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('adımın yanında Türkçe biçimli günlük mesafe gösterilir', (
    tester,
  ) async {
    await pumpRings(tester, 625);
    expect(find.text('625 / 20000 adım (0,5 km)'), findsOneWidget);

    await pumpRings(tester, 14000);
    expect(find.text('14000 / 20000 adım (11,2 km)'), findsOneWidget);
  });

  testWidgets('adım kapsülü halka ve stat barı arasında boşlukla durur', (
    tester,
  ) async {
    await pumpRings(tester, 1000);

    final ring = tester.getRect(
      find.byKey(const ValueKey('home-progress-ring-stack')),
    );
    final label = tester.getRect(
      find.byKey(const ValueKey('home-step-progress-label')),
    );
    final className = tester.getRect(find.text(_avatar.characterClassLabel));
    final firstBar = tester.getRect(find.byType(StatBar).first);

    expect(label.top - ring.bottom, greaterThanOrEqualTo(10));
    expect(className.top - label.bottom, greaterThanOrEqualTo(14));
    expect(firstBar.top - className.bottom, greaterThanOrEqualTo(22));
  });
}
