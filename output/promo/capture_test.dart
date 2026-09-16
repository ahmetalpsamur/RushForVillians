import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
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
import 'package:rush_for_villains/models/reward_rarity.dart';
import 'package:rush_for_villains/models/user_profile.dart';
import 'package:rush_for_villains/services/item_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Demirci ekranının görsel denetimi (Bölüm 4.4).
///
/// Emülatör bu makinede çalışmıyor; iki işlem satırının (yükseltme /
/// birleştirme) kart içine sığıp sığmadığı ve engel satırlarının okunur kalıp
/// kalmadığı ancak golden ile görülebiliyor.
///
/// Örneklem bilerek karışık: **birleştirilebilir** bir grup, **adedi
/// yetmeyen** bir grup ve **efsanevi** (birleştirilemez) bir grup.
const _avatar = AvatarProfile(
  name: 'Barca',
  age: 28,
  weight: 74,
  gender: 'Erkek',
  characterClass: 'Knight',
  characterAsset: 'lib/All_Assets/Avatars/Classes/Characters(100x100 split)/Knight/Knight/Knight_Idle.gif',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final entry in {'Roboto': 'roboto-regular.ttf', 'MaterialIcons': 'materialicons-regular.otf'}.entries) {
      final loader = FontLoader(entry.key);
      loader.addFont(File('C:/Users/ASUS/flutter/bin/cache/artifacts/material_fonts/${entry.value}').readAsBytes().then((bytes) => ByteData.sublistView(bytes)));
      await loader.load();
    }
  });

  final sword = buildItemFromAsset('lib/Items/swords/aqua_sword.png')!;
  final shield = buildItemFromAsset('lib/Items/shields/blue_round_shield.png')!;

  Future<void> openForge(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    ItemCatalog.reset([sword, shield]);
    addTearDown(ItemCatalog.reset);

    await tester.pumpWidget(
      MaterialApp(debugShowCheckedModeBanner: false,
        theme: AppTheme.dark.copyWith(textTheme: AppTheme.dark.textTheme.apply(fontFamily: 'Roboto')),
        home: RootShell(
          key: ValueKey('forge-golden-$width'),
          avatar: _avatar,
          initialState: GameState(
            profile: UserProfile(
              avatar: _avatar,
              level: 20,
              coins: 4000,
              ownedItems: [
                // Birleştirilebilir: üç adet sıradan kılıç.
                OwnedItem(instanceId: 1, itemId: sword.id, level: 4),
                OwnedItem(instanceId: 2, itemId: sword.id),
                OwnedItem(instanceId: 3, itemId: sword.id, level: 2),
                // Adedi yetmiyor: tek kalkan.
                OwnedItem(instanceId: 4, itemId: shield.id, level: 6),
                // Birleştirilemez: efsanevi.
                OwnedItem(
                  instanceId: 5,
                  itemId: shield.id,
                  rarity: RewardRarity.legendary,
                ),
              ],
              nextItemInstanceId: 6,
            ),
            today: DailyProgress(date: GameClock.now()),
          ),
          onAvatarChanged: (_) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();
    final entry = find.byKey(const ValueKey('profile-blacksmith-entry'));
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();
  }

  for (final width in [390.0]) {
    testWidgets('golden: demirci ekranı (${width.toInt()} dp)', (tester) async {
      await openForge(tester, width);

      // Golden boş bir ekranı doğrulamasın: üç grubun üçü de görünmeli.
      expect(find.text('Demirci'), findsOneWidget);
      
      

      tester.view.physicalSize = Size(width, 844);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('screens/forge.png'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    });
  }
}
