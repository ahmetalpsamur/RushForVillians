import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/features/adventure/adventure_screen.dart';
import 'package:rush_for_villains/l10n/app_localizations.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_progress.dart';

const _avatar = AvatarProfile(
  name: 'Hunter',
  age: 24,
  weight: 72,
  gender: 'Erkek',
  characterClass: 'Swordsman',
  characterAsset:
      'lib/All_Assets/Avatars/Classes/Characters(100x100 split)/Swordsman/Swordsman/Swordsman_Walk.gif',
);

void main() {
  for (final width in [320.0, 390.0]) {
    for (final endless in [false, true]) {
      testWidgets(
        'mode dialog fits ${width.toInt()}px: ${endless ? 'endless' : 'hunt'}',
        (tester) async {
          tester.view.physicalSize = Size(width, 620);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.dark,
              locale: const Locale('en'),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: AdventureScreen(
                adventure: null,
                roundSerial: 0,
                avatar: _avatar,
                today: DailyProgress(date: DateTime(2026, 10, 3)),
                onAdventureSelected: (_) {},
                onStartEndlessRun: () {},
                onStartRevival: () {},
                onChooseNewAdventure: () {},
                onAdventureUpdated: () {},
              ),
            ),
          );

          final card = find.byKey(
            ValueKey(endless ? 'endless-run-entry' : 'monster-hunt-entry'),
          );
          await tester.ensureVisible(card);
          await tester.tap(card);
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(AlertDialog), findsOneWidget);
          expect(find.text('Continue'), findsOneWidget);

          await tester.tap(find.text('Back'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.byType(AlertDialog), findsNothing);
        },
      );
    }
  }
}
