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
  characterClass: 'SwordMan',
  characterAsset: 'lib/Characters/SwordMan/test.png',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sword = buildItemFromAsset('lib/Items/swords/sword.png')!;
  final shield = buildItemFromAsset('lib/Items/shields/round_shield.png')!;

  Future<void> openForge(WidgetTester tester, double width) async {
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

    final openInventory = find.text('Envanter');
    await tester.ensureVisible(openInventory);
    await tester.pumpAndSettle();
    await tester.tap(openInventory);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Demirci'));
    await tester.pumpAndSettle();
  }

  for (final width in [320.0, 390.0]) {
    testWidgets('golden: demirci ekranı (${width.toInt()} dp)', (tester) async {
      await openForge(tester, width);

      // Golden boş bir ekranı doğrulamasın: üç grubun üçü de görünmeli.
      expect(find.textContaining('3/3 adet'), findsOneWidget);
      expect(find.textContaining('1/3 adet'), findsOneWidget);
      expect(find.textContaining('en üst nadirlik'), findsWidgets);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/forge_${width.toInt()}.png'),
      );
    });
  }
}
