import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/game_clock.dart';
import 'package:rush_for_villains/core/utils/item_merging.dart';
import 'package:rush_for_villains/core/utils/item_rules.dart';
import 'package:rush_for_villains/features/root/root_shell.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_progress.dart';
import 'package:rush_for_villains/models/game_state.dart';
import 'package:rush_for_villains/models/owned_item.dart';
import 'package:rush_for_villains/models/reward_rarity.dart';
import 'package:rush_for_villains/models/user_profile.dart';
import 'package:rush_for_villains/services/game_storage.dart';
import 'package:rush_for_villains/services/item_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Demirci ekranının **karar tarafı** (Bölüm 4.3–4.4).
///
/// `inventory_test.dart` ile aynı gerekçe: birleştirmenin son sözü
/// `RootShell._mergeItems` içinde ve orası bir `StatefulWidget`'ın private
/// metodu. Widget testi garantiyi mevcut yapıyı bozmadan veriyor.
const _avatar = AvatarProfile(
  name: 'Barca',
  age: 28,
  weight: 74,
  gender: 'Erkek',
  characterClass: 'SwordMan',
  characterAsset: 'lib/Characters/SwordMan/test.png',
);

const _storageKey = 'game_state_v1';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sword = buildItemFromAsset('lib/Items/swords/sword.png')!;
  final shield = buildItemFromAsset('lib/Items/shields/round_shield.png')!;
  final catalog = [sword, shield];

  var shellSerial = 0;

  /// [RootShell]'i kurup envanter → demirci yolunu açar.
  Future<void> pumpForge(
    WidgetTester tester, {
    required UserProfile profile,
  }) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    ItemCatalog.reset(catalog);
    addTearDown(ItemCatalog.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: RootShell(
          key: ValueKey('forge-${shellSerial++}'),
          avatar: _avatar,
          initialState: GameState(
            profile: profile,
            today: DailyProgress(date: GameClock.now()),
          ),
          onAvatarChanged: (_) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Envanter'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Demirci'));
    await tester.pumpAndSettle();
  }

  UserProfile profileWith({
    int level = 50,
    int coins = 99999,
    required List<OwnedItem> items,
  }) => UserProfile(
    avatar: _avatar,
    level: level,
    coins: coins,
    ownedItems: items,
    nextItemInstanceId: items.length + 1,
  );

  List<OwnedItem> swords(
    int count, {
    RewardRarity? rarity,
    List<int>? levels,
    Set<int> equipped = const {},
  }) => [
    for (var i = 0; i < count; i++)
      OwnedItem(
        instanceId: i + 1,
        itemId: sword.id,
        level: levels == null ? 1 : levels[i],
        rarity: rarity,
        equipped: equipped.contains(i + 1),
      ),
  ];

  /// Kart başlığı da "Birleştirme —" ile başlıyor; hedef **düğme**.
  Future<void> tapMerge(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(FilledButton),
        matching: find.textContaining('Birleştir —'),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('demirci ekranı', () {
    testWidgets('envanterdeki örs düğmesi demirciyi açar', (tester) async {
      await pumpForge(tester, profile: profileWith(items: swords(1)));

      expect(find.text('Demirci'), findsWidgets);
      expect(find.textContaining('Yükselt — Sv. 1'), findsOneWidget);
    });

    testWidgets('envanter boşken açıklayıcı metin çıkar', (tester) async {
      await pumpForge(tester, profile: profileWith(items: const []));

      expect(find.textContaining('Örs boş'), findsOneWidget);
    });

    testWidgets('aynı eşyanın adetleri tek kartta toplanır', (tester) async {
      await pumpForge(tester, profile: profileWith(items: swords(3)));

      expect(find.text('3 adet'), findsOneWidget);
      expect(find.textContaining('3/3 adet'), findsOneWidget);
    });

    testWidgets('farklı nadirlikteki örnekler ayrı kartlara düşer', (
      tester,
    ) async {
      // Birleştirme aynı nadirliği şart koşuyor; iki grup ayrı görünmeli.
      await pumpForge(
        tester,
        profile: profileWith(
          items: [
            ...swords(2),
            OwnedItem(
              instanceId: 3,
              itemId: sword.id,
              rarity: RewardRarity.rare,
            ),
          ],
        ),
      );

      expect(find.text('2 adet'), findsOneWidget);
      expect(find.text('1 adet'), findsOneWidget);
    });
  });

  group('birleştirme', () {
    testWidgets('yeterli adetle birleşir: nadirlik yükselir, Sv. 1 olur', (
      tester,
    ) async {
      final profile = profileWith(items: swords(3, levels: const [4, 2, 7]));
      await pumpForge(tester, profile: profile);

      final cost = mergeCostFor(RewardRarity.common, sword.requiredLevel);
      final coinsBefore = profile.coins;

      await tapMerge(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Birleştir'));
      await tester.pumpAndSettle();

      expect(profile.ownedItems, hasLength(1));
      expect(profile.ownedItems.single.rarity, RewardRarity.uncommon);
      expect(profile.ownedItems.single.level, 1);
      expect(profile.coins, coinsBefore - cost);
    });

    testWidgets('fazla adet varken en gelişmiş örnek elde kalır', (
      tester,
    ) async {
      // Dört adet var, üçü gerekiyor: Sv. 9 olan elde kalmalı.
      final profile = profileWith(items: swords(4, levels: const [1, 9, 3, 2]));
      await pumpForge(tester, profile: profile);

      await tapMerge(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Birleştir'));
      await tester.pumpAndSettle();

      // Kalanlar: Sv. 9 sıradan + yeni Az Bulunur Sv. 1.
      expect(profile.ownedItems, hasLength(2));
      final kept = profile.ownedItems.firstWhere((i) => i.rarity == null);
      expect(kept.level, 9);
    });

    testWidgets('vazgeçilirse hiçbir şey değişmez', (tester) async {
      final profile = profileWith(items: swords(3));
      await pumpForge(tester, profile: profile);
      final coinsBefore = profile.coins;

      await tapMerge(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Vazgeç'));
      await tester.pumpAndSettle();

      expect(profile.ownedItems, hasLength(3));
      expect(profile.coins, coinsBefore);
    });

    testWidgets('onay ekranı ne kaybedildiğini ve geri alınamazlığı söyler', (
      tester,
    ) async {
      await pumpForge(tester, profile: profileWith(items: swords(3)));

      await tapMerge(tester);

      expect(find.textContaining('3 adet'), findsWidgets);
      expect(find.textContaining('Az Bulunur'), findsWidgets);
      expect(find.text('Bu işlem geri alınamaz.'), findsOneWidget);
    });

    testWidgets('kuşanılı adet harcanacaksa önceden söylenir ve çıkarılır', (
      tester,
    ) async {
      final profile = profileWith(items: swords(3, equipped: {1}));
      await pumpForge(tester, profile: profile);

      await tapMerge(tester);
      expect(
        find.textContaining('Kuşanılı bir adet harcanacak'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Birleştir'));
      await tester.pumpAndSettle();

      expect(profile.ownedItems, hasLength(1));
      // Yeni örnek kuşanılı gelmiyor; kuşanmayı oyuncu seçer.
      expect(profile.equippedInstances, isEmpty);
    });

    testWidgets('adet yetmezse birleştirilemez ve sebebi yazılı', (
      tester,
    ) async {
      final profile = profileWith(items: swords(2));
      await pumpForge(tester, profile: profile);

      expect(find.text('Birleştirilemiyor'), findsOneWidget);
      expect(find.textContaining('3 adet gerekiyor'), findsOneWidget);

      await tester.tap(find.text('Birleştirilemiyor'));
      await tester.pumpAndSettle();

      expect(profile.ownedItems, hasLength(2));
    });

    testWidgets('para yetmezse birleştirilemez ve sebebi yazılı', (
      tester,
    ) async {
      final profile = profileWith(coins: 0, items: swords(3));
      await pumpForge(tester, profile: profile);

      expect(find.text('Birleştirilemiyor'), findsOneWidget);
      expect(find.textContaining('coin gerekiyor'), findsWidgets);
      expect(profile.ownedItems, hasLength(3));
    });

    testWidgets('efsanevi birleştirilemez ve nedeni söylenir', (tester) async {
      final profile = profileWith(
        items: swords(6, rarity: RewardRarity.legendary),
      );
      await pumpForge(tester, profile: profile);

      expect(find.textContaining('en üst nadirlik'), findsWidgets);
      expect(profile.ownedItems, hasLength(6));
    });

    testWidgets('birleştirme diske yazılır', (tester) async {
      final profile = profileWith(items: swords(3));
      await pumpForge(tester, profile: profile);

      await tapMerge(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Birleştir'));
      await tester.pumpAndSettle();
      await GameStorage.flush();

      final raw = (await SharedPreferences.getInstance()).getString(
        _storageKey,
      );
      final envelope = jsonDecode(raw!) as Map<String, dynamic>;
      final stored =
          (envelope['state'] as Map<String, dynamic>)['profile']
              as Map<String, dynamic>;
      expect(
        (stored['ownedItems'] as List).single,
        containsPair('rarity', RewardRarity.uncommon.name),
      );

      final restored = await GameStorage.load(avatar: _avatar);
      expect(restored!.profile.ownedItems.single.rarity, RewardRarity.uncommon);
    });

    testWidgets('birleştirme para üretmez: harcanan geri gelmiyor', (
      tester,
    ) async {
      // Üç sıradan (3×100) + ücret harcanmış olacak; sonuçtaki tek örneğin
      // satış değeri bunun altında kalmalı.
      final profile = profileWith(coins: 1000, items: swords(3));
      await pumpForge(tester, profile: profile);

      await tapMerge(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Birleştir'));
      await tester.pumpAndSettle();

      final merged = withRarity(sword, RewardRarity.uncommon);
      expect(
        sellValueFor(merged.cost),
        lessThan(
          sword.cost * 3 +
              mergeCostFor(RewardRarity.common, sword.requiredLevel),
        ),
      );
    });
  });

  group('demirciden yükseltme', () {
    testWidgets('yükseltme en gelişmiş adede uygulanır', (tester) async {
      final profile = profileWith(items: swords(3, levels: const [1, 5, 2]));
      await pumpForge(tester, profile: profile);

      await tester.tap(find.textContaining('Sv. 6 —'));
      await tester.pumpAndSettle();

      final levels = [for (final i in profile.ownedItems) i.level]..sort();
      expect(levels, [1, 2, 6]);
    });

    testWidgets('yükseltme engelliyse sebebi söylenir', (tester) async {
      final profile = profileWith(level: 1, items: swords(1));
      await pumpForge(tester, profile: profile);

      expect(find.text('Yükseltilemiyor'), findsOneWidget);
      expect(find.textContaining('kendi seviyeni'), findsOneWidget);

      await tester.tap(find.text('Yükseltilemiyor'));
      await tester.pumpAndSettle();

      expect(profile.ownedItems.single.level, 1);
    });
  });
}
