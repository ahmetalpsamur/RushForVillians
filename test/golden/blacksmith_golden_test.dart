import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/game_clock.dart';
import 'package:rush_for_villains/core/utils/item_rules.dart';
import 'package:rush_for_villains/features/root/root_shell.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_progress.dart';
import 'package:rush_for_villains/models/game_state.dart';
import 'package:rush_for_villains/models/owned_item.dart';
import 'package:rush_for_villains/models/user_profile.dart';
import 'package:rush_for_villains/services/item_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Demirci panelinin görsel denetimi (Bölüm 4.2).
///
/// Emülatör bu makinede çalışmıyor; panelin kart içine sığıp sığmadığı ve
/// engel satırının okunur kalıp kalmadığı ancak golden ile görülebiliyor.
///
/// İki durum: **yükseltilebilir** (maliyet + stat önizlemesi) ve
/// **engelli** (oyuncu seviyesi bağlıyor). İki genişlik: 320 ve 390 dp.
const _avatar = AvatarProfile(
  name: 'Barca',
  age: 28,
  weight: 74,
  gender: 'Erkek',
  characterClass: 'SwordMan',
  characterAsset: 'lib/Characters/SwordMan/test.png',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sword = buildItemFromAsset('lib/Items/swords/sword.png')!;
  final shield = buildItemFromAsset('lib/Items/shields/round_shield.png')!;

  Future<void> openSheet(
    WidgetTester tester, {
    required double width,
    required int playerLevel,
    required int coins,
    required int itemLevel,
  }) async {
    // Yüksek tutuluyor: profil ekranındaki "Envanter" kartı dar ekranda
    // kaydırma gerektiriyor ve golden'ın konusu dikey kaydırma değil.
    tester.view.physicalSize = Size(width, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    ItemCatalog.reset([sword, shield]);
    addTearDown(ItemCatalog.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: RootShell(
          key: ValueKey('blacksmith-$width-$playerLevel-$itemLevel'),
          avatar: _avatar,
          initialState: GameState(
            profile: UserProfile(
              avatar: _avatar,
              level: playerLevel,
              coins: coins,
              ownedItems: [
                OwnedItem(instanceId: 1, itemId: sword.id, level: itemLevel),
              ],
              nextItemInstanceId: 2,
            ),
            today: DailyProgress(date: GameClock.now()),
          ),
          onAvatarChanged: (_) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final openInventory = find.text('Envanter');
    await tester.ensureVisible(openInventory);
    await tester.pumpAndSettle();
    await tester.tap(openInventory);
    await tester.pumpAndSettle();

    final row = find.text(flavorForClass(sword, _avatar.characterClass).name);
    await tester.ensureVisible(row.first);
    await tester.pumpAndSettle();
    await tester.tap(row.first);
    await tester.pumpAndSettle();
  }

  for (final width in [320.0, 390.0]) {
    testWidgets(
      'golden: demirci paneli yükseltilebilir (${width.toInt()} dp)',
      (tester) async {
        await openSheet(
          tester,
          width: width,
          playerLevel: 20,
          coins: 5000,
          itemLevel: 3,
        );

        // Panel gerçekten yükseltilebilir durumda olmalı; golden boş bir
        // "yükseltilemiyor" kutusunu doğrulamasın.
        expect(find.textContaining('yükselt —'), findsOneWidget);

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/blacksmith_${width.toInt()}.png'),
        );
      },
    );
  }

  testWidgets('golden: demirci paneli engelli (320 dp)', (tester) async {
    await openSheet(
      tester,
      width: 320,
      playerLevel: 3,
      coins: 5000,
      itemLevel: 3,
    );

    // Engel sessiz kalmamalı (Model Kuralları #4).
    expect(find.text('Yükseltilemiyor'), findsOneWidget);
    expect(find.textContaining('kendi seviyeni'), findsOneWidget);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/blacksmith_blocked_320.png'),
    );
  });
}
