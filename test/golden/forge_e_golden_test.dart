import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/equipped_buffs.dart';
import 'package:rush_for_villains/core/utils/forge_filter.dart';
import 'package:rush_for_villains/core/utils/game_clock.dart';
import 'package:rush_for_villains/core/utils/item_leveling.dart';
import 'package:rush_for_villains/core/utils/item_rules.dart';
import 'package:rush_for_villains/data/mail_catalog.dart';
import 'package:rush_for_villains/features/inventory/blacksmith_screen.dart';
import 'package:rush_for_villains/features/inventory/inventory_screen.dart';
import 'package:rush_for_villains/features/mail/mailbox_screen.dart';
import 'package:rush_for_villains/l10n/app_localizations.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/forged_effect.dart';
import 'package:rush_for_villains/models/item_effect.dart';
import 'package:rush_for_villains/models/mail_message.dart';
import 'package:rush_for_villains/models/owned_item.dart';
import 'package:rush_for_villains/models/reward_rarity.dart';
import 'package:rush_for_villains/models/user_profile.dart';
import 'package:rush_for_villains/services/item_catalog.dart';

/// Bölüm E görsel denetimi: demirci (süzgeç + buff özeti + karar paneli),
/// yeniden atma penceresi ve posta kutusu — TR/EN × 320/390 dp.
///
/// Altı etkili efsanevi kasıtlı: kartın en uzun hâli. `pumpAndSettle`
/// kullanılmıyor (§5.3); sabit kare dizisi.
const _avatar = AvatarProfile(
  name: 'Barca',
  age: 28,
  weight: 74,
  gender: 'Erkek',
  characterClass: 'Greatsword Skeleton',
  characterAsset: 'lib/Characters/test.png',
);

void main() {
  final catalog = ItemCatalog.fromAssetPaths(
    Directory('lib/Items')
        .listSync(recursive: true)
        .whereType<File>()
        .map((file) => file.path.replaceAll(r'\', '/'))
        .where((path) => path.endsWith('.png')),
  );

  final owned = <OwnedItem>[
    // Altı etkili, birleştirilmiş efsanevi; bekleyen bir atışı var.
    const OwnedItem(
      instanceId: 1,
      itemId: 'swords/sword_variant_01',
      rarity: RewardRarity.legendary,
      level: 30,
      rerollCount: 2,
      pendingForge: PendingForge(
        slot: 3,
        effect: ForgedEffect(stat: ItemStat.attack, tier: 5, value: 34),
      ),
    ),
    // İmzalı, bedelli efsanevi.
    const OwnedItem(instanceId: 2, itemId: 'scythes/reapers_scythe'),
    // Ara basamak eşyası.
    const OwnedItem(instanceId: 3, itemId: 'scythes/scythe_variant_14@epic'),
  ];

  InventoryState state() {
    final profile = UserProfile(
      avatar: _avatar,
      level: 50,
      coins: 12000,
      ownedItems: owned,
      nextItemInstanceId: 4,
      discoveredAffixes: const ['attack:5', 'critDamage:4', 'stepXp:3'],
    );
    final byId = {for (final item in catalog) item.id: item};
    final entries = [
      for (final instance in owned)
        InventoryEntry(
          instance,
          resolveOwnedItem(
            flavorForClass(byId[instance.itemId]!, _avatar.characterClass),
            instance,
            characterClass: _avatar.characterClass,
          ),
        ),
    ];
    return InventoryState(
      profile: profile,
      entries: entries,
      equippedItems: const [],
      buffs: EquippedBuffs.from(const []),
    );
  }

  Widget app(Locale locale, Widget home) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );

  /// Taşma hatalarını toplar; rapor kısa tutulur (§9: yüzlerce hata
  /// birleştirmek koşucuyu kilitler).
  List<String> captureOverflows() {
    final errors = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final text = details.exceptionAsString();
      if (text.contains('overflowed')) {
        if (errors.length < 2) errors.add(text.split('\n').first);
      } else {
        previous?.call(details);
      }
    };
    addTearDown(() => FlutterError.onError = previous);
    return errors;
  }

  Future<void> frames(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  setUp(() {
    ItemCatalog.reset(catalog);
  });
  tearDown(ItemCatalog.reset);

  for (final locale in const [Locale('tr'), Locale('en')]) {
    for (final width in const [320.0, 390.0]) {
      final tag = '${locale.languageCode}_${width.round()}';

      testWidgets('demirci $tag', (tester) async {
        tester.view.physicalSize = Size(width, 2000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final errors = captureOverflows();

        await tester.pumpWidget(
          app(
            locale,
            BlacksmithScreen(
              revision: ValueNotifier(0),
              readState: state,
              onUpgrade: (_) {},
              onMerge: (_, _) {},
              filter: ValueNotifier(
                const ForgeFilter(sort: ForgeSort.upgradeCost).copyWith(
                  rarities: {RewardRarity.legendary, RewardRarity.epic},
                  equip: ForgeEquipFilter.unequipped,
                ),
              ),
              onReroll: (_, _, {stat, tier}) {},
              onRerollDecision: (_, _) {},
            ),
          ),
        );
        await frames(tester);

        expect(errors, isEmpty, reason: errors.join(' | '));
        expect(find.byKey(const ValueKey('forge-decision-panel')), findsOneWidget);
        await expectLater(
          find.byType(BlacksmithScreen),
          matchesGoldenFile('goldens/forge_e_$tag.png'),
        );
      });

      testWidgets('yeniden atma penceresi $tag', (tester) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final errors = captureOverflows();

        // Karar verilmiş hâl: pencere bekleyen atış yokken açılır.
        final pendingFree = state();
        final instance = pendingFree.entries.first.instance;
        final clean = InventoryState(
          profile: pendingFree.profile,
          entries: [
            InventoryEntry(
              instance.copyWith(clearPending: true),
              pendingFree.entries.first.item,
            ),
          ],
          equippedItems: const [],
          buffs: pendingFree.buffs,
        );
        await tester.pumpWidget(
          app(
            locale,
            BlacksmithScreen(
              revision: ValueNotifier(0),
              readState: () => clean,
              onUpgrade: (_) {},
              onMerge: (_, _) {},
              filter: ValueNotifier(const ForgeFilter()),
              onReroll: (_, _, {stat, tier}) {},
              onRerollDecision: (_, _) {},
            ),
          ),
        );
        await frames(tester);
        await tester.tap(find.byKey(const ValueKey('forge-reroll-slot-3')));
        await frames(tester);
        await tester.tap(find.byKey(const ValueKey('forge-pick-attack:5')));
        await frames(tester);

        expect(errors, isEmpty, reason: errors.join(' | '));
        expect(find.byKey(const ValueKey('forge-reroll-sheet')), findsOneWidget);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/forge_reroll_$tag.png'),
        );
      });

      testWidgets('posta kutusu $tag', (tester) async {
        tester.view.physicalSize = Size(width, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        GameClock.useSource(() => DateTime(2026, 10, 5, 12));
        addTearDown(GameClock.reset);
        final errors = captureOverflows();

        final messages = [
          for (final mail in MailCatalog.all)
            if (mail.deliveredToEveryone) mail,
        ]..sort((a, b) => b.sentAt.compareTo(a.sentAt));
        await tester.pumpWidget(
          app(
            locale,
            MailboxScreen(
              messages: messages,
              claimedIds: {MailCatalog.closedBetaThanksId},
              onClaim: (_) {},
              onRead: (_) {},
              onRedeemCode: (_) => CodeRedemptionResult.invalid,
            ),
          ),
        );
        await frames(tester);

        expect(errors, isEmpty, reason: errors.join(' | '));
        await expectLater(
          find.byType(MailboxScreen),
          matchesGoldenFile('goldens/mailbox_e_$tag.png'),
        );
      });
    }
  }
}
