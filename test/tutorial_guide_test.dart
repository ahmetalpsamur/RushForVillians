import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/features/inventory/inventory_screen.dart';
import 'package:rush_for_villains/features/root/root_shell.dart';
import 'package:rush_for_villains/features/tutorial/guide_selection_screen.dart';
import 'package:rush_for_villains/features/tutorial/tutorial_guide.dart';
import 'package:rush_for_villains/features/wheel/daily_wheel_screen.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_progress.dart';
import 'package:rush_for_villains/models/game_state.dart';
import 'package:rush_for_villains/models/user_profile.dart';
import 'package:rush_for_villains/models/tutorial_guide_variant.dart';
import 'package:rush_for_villains/services/item_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('guide state gerçek assetlere merkezi olarak eşlenir', () {
    expect(
      TutorialGuideAssets.forAnimation(TutorialGuideAnimation.idle),
      endsWith('Dude_Monster_Idle_4.gif'),
    );
    expect(
      TutorialGuideAssets.forAnimation(TutorialGuideAnimation.walking),
      endsWith('Dude_Monster_Walk_6.gif'),
    );
    expect(
      TutorialGuideAssets.forAnimation(TutorialGuideAnimation.pointing),
      endsWith('Dude_Monster_Push_6.gif'),
    );
    expect(
      TutorialGuideAssets.forAnimation(TutorialGuideAnimation.attacking),
      endsWith('Dude_Monster_Attack2_6.gif'),
    );
    expect(
      TutorialGuideAssets.forAnimation(TutorialGuideAnimation.reacting),
      endsWith('Dude_Monster_Hurt_4.gif'),
    );
    expect(
      TutorialGuideAssets.forAnimation(TutorialGuideAnimation.celebrating),
      endsWith('Dude_Monster_Jump_8.gif'),
    );
    expect(
      TutorialGuideAssets.forAnimation(
        TutorialGuideAnimation.attacking,
        TutorialGuideVariant.pinky,
      ),
      endsWith('Pinky/Pink_Monster_Attack2_6.gif'),
    );
    expect(
      TutorialGuideAssets.forAnimation(
        TutorialGuideAnimation.walking,
        TutorialGuideVariant.kupkuzu,
      ),
      endsWith('Kupkuzu/Owlet_Monster_Walk_6.gif'),
    );
  });

  test('tutorial sonunda pet çağırma düğmesini anlatır', () {
    final frame = TutorialGuideFrame.forStep(
      TutorialGuideStep.farewellYourTurn,
    );
    expect(
      frame.message,
      contains('adım çemberinin sol altındaki pet butonuna'),
    );
  });

  test(
    'tutorial ilerlemesi kaydedilir ve eski kayıtlar tamamlanmış sayılır',
    () {
      const avatar = AvatarProfile(
        name: 'GuideTest',
        age: 25,
        weight: 70,
        gender: 'Erkek',
        characterClass: 'Knight',
        characterAsset: 'avatar.gif',
      );
      final fresh =
          UserProfile(avatar: avatar)
            ..tutorialStep = TutorialGuideStep.rewardXp.index
            ..tutorialGuideId = TutorialGuideVariant.pinky.id
            ..tutorialStarterItemId = 'swords/tutorial_sword';
      final restored = UserProfile.fromJson(fresh.toJson(), avatar: avatar);

      expect(restored.hasCompletedTutorial, isFalse);
      expect(restored.tutorialStep, TutorialGuideStep.rewardXp.index);
      expect(restored.tutorialGuideId, TutorialGuideVariant.pinky.id);
      expect(restored.tutorialStarterItemId, 'swords/tutorial_sword');

      final legacy = UserProfile.fromJson(
        const <String, dynamic>{},
        avatar: avatar,
      );
      expect(legacy.hasCompletedTutorial, isTrue);
    },
  );

  testWidgets('ilk kurulumda üç guide arasından seçim yapılır', (tester) async {
    TutorialGuideVariant? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: GuideSelectionScreen(onSelected: (guide) => selected = guide),
      ),
    );

    expect(find.byKey(const ValueKey('guide-mavili')), findsOneWidget);
    expect(find.byKey(const ValueKey('guide-pinky')), findsOneWidget);
    expect(find.byKey(const ValueKey('guide-kupkuzu')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('guide-pinky')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm-guide-selection')));
    expect(selected, TutorialGuideVariant.pinky);
  });

  testWidgets('spotlight hedefin dokunmasını engellemez', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final step = ValueNotifier(TutorialGuideStep.adventurePrompt);
    addTearDown(step.dispose);
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => taps++,
              ),
            ),
            TutorialGuideOverlay(
              step: step,
              onPrimary: (_) {},
              onSecondary: (_) {},
              onLeavingCompleted: () {},
            ),
          ],
        ),
      ),
    );

    await tester.tapAt(const Offset(110, 815));
    expect(taps, 1);
    await tester.tapAt(const Offset(20, 400));
    expect(taps, 1, reason: 'Spotlight dışı dokunma alttaki UI’a geçmemeli.');
  });

  testWidgets('yeni profilde guide gerçek Adventure sekmesine kadar yürür', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const avatar = AvatarProfile(
      name: 'Yeni Oyuncu',
      age: 24,
      weight: 68,
      gender: 'Kadın',
      characterClass: 'Knight',
      characterAsset:
          'lib/All_Assets/Avatars/Classes/Characters(100x100 split)/Knight/Knight/Knight_Idle.gif',
    );
    final profile = UserProfile(avatar: avatar);
    await tester.runAsync(ItemCatalog.load);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: RootShell(
          avatar: avatar,
          initialState: GameState(
            profile: profile,
            today: DailyProgress(date: DateTime(2026, 8, 26)),
          ),
          startTutorial: true,
          onAvatarChanged: (_) {},
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Maceranda yanında olacağım'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tutorial-primary-action')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.text('Gel, ilk maceranı seçelim.'), findsOneWidget);

    await tester.tap(find.text('Macera').last);
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.textContaining('İlk rakibini seç'), findsOneWidget);
    expect(profile.tutorialStep, TutorialGuideStep.enemyChoice.index);
    expect(
      tester
          .widget<ListView>(find.byKey(const ValueKey('adventure-scroll-view')))
          .physics,
      isA<NeverScrollableScrollPhysics>(),
    );

    await tester.tap(find.byKey(TutorialGuideTargetKeys.enemy));
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.textContaining('senin yerine ben yürürüm'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tutorial-primary-action')));
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump(const Duration(milliseconds: 1200));
    final starter = ItemCatalog.byId(
      profile.tutorialStarterItemId!,
      characterClass: avatar.characterClass,
    );
    expect(profile.tutorialStep, TutorialGuideStep.victoryCelebration.index);
    expect(starter, isNotNull);
    expect(profile.coins, starter!.cost);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('tutorial-primary-action')));
      await tester.pump(const Duration(milliseconds: 650));
    }
    expect(profile.tutorialStep, TutorialGuideStep.shopPrompt.index);

    await tester.tap(find.text('Mağaza').last);
    await tester.pump(const Duration(milliseconds: 650));
    final tutorialCard = find.byKey(
      ValueKey('tutorial-store-item-${starter.id}'),
    );
    expect(tutorialCard, findsOneWidget);
    expect(
      tester
          .widget<CustomScrollView>(
            find.byKey(const ValueKey('store-scroll-view')),
          )
          .physics,
      isA<NeverScrollableScrollPhysics>(),
    );
    final price = find.descendant(
      of: tutorialCard,
      matching: find.text('${starter.cost}'),
    );
    await tester.tap(price);
    await tester.pump(const Duration(milliseconds: 650));
    expect(profile.coins, 0);
    expect(profile.ownsItem(starter.id), isTrue);
    expect(profile.tutorialStep, TutorialGuideStep.itemBought.index);

    await tester.tap(find.byKey(const Key('tutorial-primary-action')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.byType(InventoryScreen), findsOneWidget);
    expect(find.text('İlk silahın'), findsOneWidget);
    expect(find.text('Eğitim silahı bulunamadı.'), findsNothing);
    expect(find.byKey(const ValueKey('inventory-scroll-view')), findsNothing);
    final equipButton = find.byKey(TutorialGuideTargetKeys.inventoryItem);
    await tester.tap(equipButton);
    await tester.pump(const Duration(milliseconds: 650));
    expect(profile.equippedInstances.single.itemId, starter.id);
    expect(profile.tutorialStep, TutorialGuideStep.itemEquipped.index);

    await tester.tap(find.byKey(const Key('tutorial-primary-action')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(profile.tutorialStep, TutorialGuideStep.wheelPrompt.index);
    expect(find.byType(InventoryScreen), findsNothing);

    await tester.tap(find.byKey(const Key('tutorial-primary-action')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(profile.tutorialStep, TutorialGuideStep.wheelWaiting.index);
    expect(find.byType(DailyWheelScreen), findsOneWidget);
    expect(
      tester
          .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .physics,
      isA<NeverScrollableScrollPhysics>(),
    );

    await tester.tap(find.byKey(TutorialGuideTargetKeys.wheel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2700));
    await tester.pump();
    expect(profile.tutorialStep, TutorialGuideStep.wheelReward.index);
    expect(profile.wheelSpunToday, isTrue);
    final wheelReward = find.byKey(TutorialGuideTargetKeys.wheelReward);
    expect(wheelReward, findsOneWidget);
    expect(
      tester.getBottomLeft(find.byKey(const Key('tutorial-speech-bubble'))).dy,
      lessThan(tester.getTopLeft(wheelReward).dy),
    );

    await tester.tap(find.byKey(const Key('tutorial-primary-action')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(profile.tutorialStep, TutorialGuideStep.finalReady.index);
    expect(find.byType(DailyWheelScreen), findsNothing);

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byKey(const Key('tutorial-primary-action')));
      await tester.pump(const Duration(milliseconds: 650));
    }
    expect(profile.tutorialStep, TutorialGuideStep.farewellYourTurn.index);
    expect(find.byKey(const ValueKey('home-pet-toggle')), findsOneWidget);

    await tester.tap(find.byKey(const Key('tutorial-primary-action')));
    await tester.pump(const Duration(milliseconds: 650));
    expect(profile.tutorialStep, TutorialGuideStep.farewell.index);
    expect(find.text('Eğitimi Bitir'), findsOneWidget);
    await tester.tap(find.text('Eğitimi Bitir'));
    await tester.pump();
    // Veda ölümü oynarken eğitim henüz kapanmamalı (GD83).
    await tester.pump(TutorialGuideOverlay.farewellDeathHold);
    expect(profile.hasCompletedTutorial, isFalse);
    await tester.pump(TutorialGuideOverlay.farewellFade);
    expect(profile.hasCompletedTutorial, isTrue);
    expect(profile.petCompanionEnabled, isFalse);
    expect(find.byType(InventoryScreen), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('dar ekranda konuşma balonu taşmaz ve final death ile biter', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final step = ValueNotifier(TutorialGuideStep.onlineTeaser);
    addTearDown(step.dispose);
    var completed = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: TutorialGuideOverlay(
          step: step,
          onPrimary: (_) {},
          onSecondary: (_) {},
          onLeavingCompleted: () => completed++,
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('COMING SOON'), findsOneWidget);
    expect(tester.takeException(), isNull);

    step.value = TutorialGuideStep.leaving;
    await tester.pump();
    await tester.pump(TutorialGuideOverlay.farewellExit);
    expect(completed, 1);
    expect(tester.takeException(), isNull);
  });

  group('veda çıkışı death animasyonuyla biter (GD83)', () {
    Future<ValueNotifier<TutorialGuideStep>> pumpFarewell(
      WidgetTester tester, {
      VoidCallback? onUnderlyingTap,
      VoidCallback? onCompleted,
    }) async {
      final step = ValueNotifier(TutorialGuideStep.farewell);
      addTearDown(step.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: FilledButton(
                    onPressed: onUnderlyingTap ?? () {},
                    child: const Text('ALTTAKİ DÜĞME'),
                  ),
                ),
                TutorialGuideOverlay(
                  step: step,
                  onPrimary: (_) {},
                  onSecondary: (_) {},
                  onLeavingCompleted: onCompleted ?? () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      return step;
    }

    String guideAsset(WidgetTester tester) {
      final image = tester.widget<Image>(find.byType(Image).first);
      return (image.image as AssetImage).assetName;
    }

    testWidgets('rehber yürüyüp kaybolmaz, death GIF oynar', (tester) async {
      final step = await pumpFarewell(tester);
      expect(guideAsset(tester), isNot(contains('_Death_8.gif')));

      step.value = TutorialGuideStep.leaving;
      await tester.pump();

      expect(guideAsset(tester), contains('_Death_8.gif'));
    });

    testWidgets('animasyon bitmeden rehber kaldırılmaz', (tester) async {
      var completed = 0;
      final step = await pumpFarewell(tester, onCompleted: () => completed++);

      step.value = TutorialGuideStep.leaving;
      await tester.pump();

      // Death çevrimi boyunca hâlâ ekranda ve eğitim kapanmamış.
      await tester.pump(
        TutorialGuideOverlay.farewellDeathHold - const Duration(milliseconds: 1),
      );
      expect(completed, 0);
      expect(guideAsset(tester), contains('_Death_8.gif'));

      await tester.pump(const Duration(milliseconds: 1));
      // Solma başladı ama daha bitmedi.
      expect(completed, 0);

      await tester.pump(TutorialGuideOverlay.farewellFade);
      expect(completed, 1);
    });

    testWidgets('animasyon oynarken arayüz kilitli kalmaz', (tester) async {
      var taps = 0;
      final step = await pumpFarewell(tester, onUnderlyingTap: () => taps++);

      // Veda adımında bariyer hâlâ görevde: eğitim bitmedi.
      await tester.tap(find.text('ALTTAKİ DÜĞME'), warnIfMissed: false);
      await tester.pump();
      expect(taps, 0);

      step.value = TutorialGuideStep.leaving;
      await tester.pump();

      // Çıkış animasyonu oynarken oyuncu oynamaya devam edebilir.
      await tester.tap(find.text('ALTTAKİ DÜĞME'));
      await tester.pump();
      expect(taps, 1);

      await tester.pump(TutorialGuideOverlay.farewellExit);
    });

    testWidgets('üç rehberin de death süresi aynı sabitle örtüşür', (
      tester,
    ) async {
      // Üç varyantın `*_Death_8.gif` dosyası da 8 kare × 120 ms = 960 ms.
      // Sabit bu ölçüme dayanıyor; asset değişirse burası uyarır.
      expect(TutorialGuideOverlay.farewellDeathHold.inMilliseconds, 960);
      expect(
        TutorialGuideOverlay.farewellExit,
        TutorialGuideOverlay.farewellDeathHold +
            TutorialGuideOverlay.farewellFade,
      );
      for (final guide in TutorialGuideVariant.values) {
        expect(
          TutorialGuideAssets.forAnimation(
            TutorialGuideAnimation.dying,
            guide,
          ),
          endsWith('_Death_8.gif'),
        );
      }
    });
  });
}
