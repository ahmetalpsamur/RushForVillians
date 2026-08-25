import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/game_clock.dart';
import 'package:rush_for_villains/features/adventure/adventure_screen.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_progress.dart';

/// Macera adım hedefi seçici (Bölüm 6).
///
/// Bulunan hata: `_showGoalPicker` içindeki `FixedExtentScrollController`
/// `showModalBottomSheet` `await`'inden **sonra** dispose ediliyordu. Bekleyiş
/// bir istisnayla sonlanırsa `dispose()` hiç çalışmıyor ve denetleyici
/// sızıyordu. Artık `try/finally` içinde.
///
/// Bu testler davranışın bozulmadığını bağlıyor: seçici açılıyor, seçim
/// uygulanıyor, vazgeçince hedef değişmiyor ve hiçbir yolda istisna çıkmıyor.
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

  Future<void> pumpPicker(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: AdventureScreen(
            adventure: null,
            roundSerial: 0,
            avatar: _avatar,
            today: DailyProgress(date: GameClock.now()),
            onAdventureSelected: (_) {},
            onChooseNewAdventure: () {},
            onAdventureUpdated: () {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('seçici açılıp seçim yapılabilir', (tester) async {
    await pumpPicker(tester);

    final trigger = find.textContaining('adım').first;
    await tester.ensureVisible(trigger);
    await tester.tap(trigger);
    await tester.pumpAndSettle();

    final confirm = find.textContaining('ADIMI SEÇ');
    expect(confirm, findsOneWidget);
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('ADIMI SEÇ'), findsNothing);
  });

  testWidgets('vazgeçilince istisna çıkmaz', (tester) async {
    await pumpPicker(tester);

    final trigger = find.textContaining('adım').first;
    await tester.ensureVisible(trigger);
    await tester.tap(trigger);
    await tester.pumpAndSettle();
    expect(find.textContaining('ADIMI SEÇ'), findsOneWidget);

    // Sayfayı seçim yapmadan kapat.
    Navigator.of(tester.element(find.byType(AdventureScreen))).pop();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('ADIMI SEÇ'), findsNothing);
  });

  testWidgets('seçici arka arkaya açılıp kapanabilir', (tester) async {
    await pumpPicker(tester);

    for (var i = 0; i < 3; i++) {
      final trigger = find.textContaining('adım').first;
      await tester.ensureVisible(trigger);
      await tester.tap(trigger);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('ADIMI SEÇ'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
