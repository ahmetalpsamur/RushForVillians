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
import 'package:rush_for_villains/features/inventory/blacksmith_screen.dart';
import 'package:rush_for_villains/features/inventory/inventory_screen.dart';
import 'package:rush_for_villains/features/root/root_shell.dart';
import 'package:rush_for_villains/l10n/app_localizations.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_progress.dart';
import 'package:rush_for_villains/models/game_state.dart';
import 'package:rush_for_villains/models/item.dart';
import 'package:rush_for_villains/models/owned_item.dart';
import 'package:rush_for_villains/models/reward_rarity.dart';
import 'package:rush_for_villains/models/user_profile.dart';
import 'package:rush_for_villains/services/item_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bölüm E / Faz 3: demircide süzgeç, sıralama ve buff özeti.
const _avatar = AvatarProfile(
  name: 'Barca',
  age: 28,
  weight: 74,
  gender: 'Erkek',
  characterClass: 'Greatsword Skeleton',
  characterAsset: 'lib/Characters/test.png',
);

ForgeGroupFacts _facts(
  String key, {
  RewardRarity rarity = RewardRarity.common,
  ItemCategory category = ItemCategory.swords,
  String? name,
  int level = 1,
  bool equipped = false,
  bool canUpgrade = false,
  bool mergeable = false,
  int? cost = 100,
}) => ForgeGroupFacts(
  key: key,
  rarity: rarity,
  category: category,
  name: name ?? key,
  bestLevel: level,
  anyEquipped: equipped,
  canUpgrade: canUpgrade,
  hasMergeCopies: mergeable,
  nextUpgradeCost: cost,
);

List<String> _keys(Iterable<ForgeGroupFacts> facts) => [
  for (final fact in facts) fact.key,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('saf kurallar', () {
    final groups = [
      _facts('a', rarity: RewardRarity.common, name: 'Çekiç', level: 3),
      _facts(
        'b',
        rarity: RewardRarity.epic,
        category: ItemCategory.scythes,
        name: 'Ayaz',
        level: 1,
        equipped: true,
        cost: 900,
      ),
      _facts(
        'c',
        rarity: RewardRarity.rare,
        name: 'Balta',
        level: 7,
        canUpgrade: true,
        mergeable: true,
        cost: 300,
      ),
      _facts('d', rarity: RewardRarity.epic, name: 'Zırh', level: 9, cost: null),
    ];

    test('varsayılan sıra eski sırayla aynı: nadirlik, seviye, ad', () {
      expect(_keys(const ForgeFilter().apply(groups)), ['d', 'b', 'c', 'a']);
    });

    test('aynı türden ölçütler VEYA, farklı türler VE', () {
      final epicOrRare = const ForgeFilter().copyWith(
        rarities: {RewardRarity.epic, RewardRarity.rare},
      );
      expect(_keys(epicOrRare.apply(groups)), ['d', 'b', 'c']);

      final epicScythes = epicOrRare.copyWith(
        categories: {ItemCategory.scythes},
      );
      expect(_keys(epicScythes.apply(groups)), ['b']);
    });

    test('kuşanma, yükseltilebilir ve birleştirilebilir süzgeçleri', () {
      const base = ForgeFilter();
      expect(
        _keys(base.copyWith(equip: ForgeEquipFilter.equipped).apply(groups)),
        ['b'],
      );
      expect(
        _keys(base.copyWith(equip: ForgeEquipFilter.unequipped).apply(groups)),
        ['d', 'c', 'a'],
      );
      expect(_keys(base.copyWith(upgradableOnly: true).apply(groups)), ['c']);
      expect(_keys(base.copyWith(mergeableOnly: true).apply(groups)), ['c']);
    });

    test('dört sıralama ölçütü', () {
      const base = ForgeFilter();
      expect(
        _keys(base.copyWith(sort: ForgeSort.level).apply(groups)),
        ['d', 'c', 'a', 'b'],
      );
      // Gösterilen ad: "Ayaz", "Balta", "Çekiç", "Zırh".
      expect(
        _keys(base.copyWith(sort: ForgeSort.name).apply(groups)),
        ['b', 'c', 'a', 'd'],
      );
      // Ucuzdan pahalıya; tavana ulaşmış (maliyetsiz) en sonda.
      expect(
        _keys(base.copyWith(sort: ForgeSort.upgradeCost).apply(groups)),
        ['a', 'c', 'b', 'd'],
      );
    });

    test('düğmedeki sayı çip sayısıyla aynı', () {
      final filter = const ForgeFilter().copyWith(
        rarities: {RewardRarity.epic, RewardRarity.rare},
        equip: ForgeEquipFilter.equipped,
        mergeableOnly: true,
      );
      expect(filter.criteria, hasLength(4));
      expect(filter.activeCount, 4);
    });

    test('temizle süzgeçleri siler, sıralamayı korur', () {
      final filter = const ForgeFilter(
        sort: ForgeSort.name,
      ).copyWith(rarities: {RewardRarity.epic}, upgradableOnly: true);
      final cleared = filter.cleared();
      expect(cleared.isActive, isFalse);
      expect(cleared.sort, ForgeSort.name);
    });

    test('bir çipi kaldırmak yalnızca onu kaldırır', () {
      final filter = const ForgeFilter().copyWith(
        rarities: {RewardRarity.epic, RewardRarity.rare},
        upgradableOnly: true,
      );
      final next = filter.without(const RarityCriterion(RewardRarity.epic));
      expect(next.rarities, {RewardRarity.rare});
      expect(next.upgradableOnly, isTrue);
    });

    test('boş sonucu hangi ölçütün boşalttığı bulunur', () {
      final legendary = const ForgeFilter().copyWith(
        rarities: {RewardRarity.legendary},
        upgradableOnly: true,
      );
      expect(legendary.apply(groups), isEmpty);
      expect(
        legendary.blockingCriterion(groups),
        isA<RarityCriterion>().having(
          (c) => c.rarity,
          'rarity',
          RewardRarity.legendary,
        ),
      );

      // Her ölçüt tek başına bir şey geçiriyor, birleşim boş: tek suçlu yok.
      final combined = const ForgeFilter().copyWith(
        equip: ForgeEquipFilter.equipped,
        upgradableOnly: true,
      );
      expect(combined.apply(groups), isEmpty);
      expect(combined.blockingCriterion(groups), isNull);
    });
  });

  group('ekran', () {
    final paths = Directory('lib/Items')
        .listSync(recursive: true)
        .whereType<File>()
        .map((file) => file.path.replaceAll(r'\', '/'))
        .where((path) => path.endsWith('.png'));
    final catalog = ItemCatalog.fromAssetPaths(paths);
    Item byId(String id) => catalog.firstWhere((item) => item.id == id);

    final items = <OwnedItem>[
      const OwnedItem(instanceId: 1, itemId: 'swords/sword_variant_01'),
      const OwnedItem(instanceId: 2, itemId: 'swords/sword_variant_01'),
      const OwnedItem(instanceId: 3, itemId: 'swords/sword_variant_01'),
      const OwnedItem(
        instanceId: 4,
        itemId: 'scythes/reapers_scythe',
        equipped: true,
        level: 3,
      ),
      const OwnedItem(instanceId: 5, itemId: 'scythes/scythe_variant_14@epic'),
    ];

    InventoryState stateFor(List<OwnedItem> owned, {int coins = 99999}) {
      final profile = UserProfile(
        avatar: _avatar,
        level: 50,
        coins: coins,
        ownedItems: owned,
        nextItemInstanceId: owned.length + 1,
      );
      final entries = [
        for (final instance in owned)
          InventoryEntry(
            instance,
            resolveOwnedItem(
              flavorForClass(byId(instance.itemId), _avatar.characterClass),
              instance,
              characterClass: _avatar.characterClass,
            ),
          ),
      ];
      return InventoryState(
        profile: profile,
        entries: entries,
        equippedItems: [
          for (final entry in entries)
            if (entry.equipped) entry.item,
        ],
        buffs: EquippedBuffs.from(const []),
      );
    }

    Future<ValueNotifier<ForgeFilter>> pumpForge(
      WidgetTester tester, {
      List<OwnedItem>? owned,
      ValueNotifier<ForgeFilter>? filter,
      Locale locale = const Locale('tr'),
      int coins = 99999,
    }) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final notifier = filter ?? ValueNotifier(const ForgeFilter());
      final state = stateFor(owned ?? items, coins: coins);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlacksmithScreen(
            revision: ValueNotifier(0),
            readState: () => state,
            onUpgrade: (_) {},
            onMerge: (_, _) {},
            filter: notifier,
          ),
        ),
      );
      await tester.pumpAndSettle();
      return notifier;
    }

    testWidgets('süzgeç penceresinden epik seçilince yalnızca epikler', (
      tester,
    ) async {
      await pumpForge(tester);
      expect(find.text('Filtrele'), findsOneWidget);
      expect(find.byKey(const ValueKey('forge-active-chips')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('forge-filter-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('forge-filter-rarity-epic')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('forge-sheet-done')));
      await tester.pumpAndSettle();

      // Düğme sayıyı, çip satırı seçimi, sayaç sonucu söylüyor.
      expect(find.text('Filtrele (1)'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('forge-active-chips')),
          matching: find.text('Epik'),
        ),
        findsOneWidget,
      );
      expect(find.text('1 / 3 eşya gösteriliyor'), findsOneWidget);
      expect(find.text('Ayaz Tırpanı'), findsOneWidget);
      expect(find.text('Azrailin Tırpanı'), findsNothing);
    });

    testWidgets('boş sonuçta boşaltan süzgeç söylenir, tek dokunuşla temizlenir', (
      tester,
    ) async {
      final filter = await pumpForge(tester);
      filter.value = const ForgeFilter().copyWith(
        rarities: {RewardRarity.uncommon},
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('forge-empty-result')), findsOneWidget);
      expect(
        find.text('"Az Bulunur" süzgecine uyan hiç eşyan yok.'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('forge-empty-clear')));
      await tester.pumpAndSettle();
      expect(filter.value.isActive, isFalse);
      expect(find.byKey(const ValueKey('forge-empty-result')), findsNothing);
      expect(find.text('Azrailin Tırpanı'), findsOneWidget);
    });

    testWidgets('birleşim boşsa birleşim söylenir', (tester) async {
      final filter = await pumpForge(tester);
      // Kuşanılı tek eşya efsanevi; birleştirilebilir tek eşya sıradan.
      filter.value = const ForgeFilter().copyWith(
        equip: ForgeEquipFilter.equipped,
        mergeableOnly: true,
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Seçili süzgeçlerin hepsine birden uyan eşya yok: '
          'Kuşanılı + Birleştirilebilir.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('çip kaldırılınca liste geri gelir; temizle çipi hepsini siler', (
      tester,
    ) async {
      final filter = await pumpForge(tester);
      filter.value = const ForgeFilter().copyWith(
        rarities: {RewardRarity.epic},
        mergeableOnly: true,
      );
      await tester.pumpAndSettle();
      expect(find.text('Filtrele (2)'), findsOneWidget);

      // Çip satırı yatay kayıyor; ikinci çip görünür alanın dışında olabilir.
      await tester.ensureVisible(find.byKey(const ValueKey('forge-chip-1')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('forge-chip-1')),
          matching: find.byIcon(Icons.close),
        ),
      );
      await tester.pumpAndSettle();
      expect(filter.value.mergeableOnly, isFalse);
      expect(filter.value.rarities, {RewardRarity.epic});

      await tester.tap(find.byKey(const ValueKey('forge-clear-filters')));
      await tester.pumpAndSettle();
      expect(filter.value.isActive, isFalse);
      expect(find.text('Filtrele'), findsOneWidget);
    });

    testWidgets('sıralama menüsü İngilizce adlara göre sıralar', (tester) async {
      final filter = await pumpForge(tester, locale: const Locale('en'));
      await tester.tap(find.byKey(const ValueKey('forge-sort-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('forge-sort-name')).last);
      await tester.pumpAndSettle();
      expect(filter.value.sort, ForgeSort.name);
      expect(find.text('Sort: Name'), findsOneWidget);

      final reaper = tester.getTopLeft(find.text("Reaper's Scythe")).dy;
      final rime = tester.getTopLeft(find.text('Rime Scythe')).dy;
      expect(reaper, lessThan(rime));
    });

    testWidgets('seçim ekran yeniden açılınca korunur', (tester) async {
      final filter = await pumpForge(tester);
      filter.value = const ForgeFilter(
        sort: ForgeSort.level,
      ).copyWith(rarities: {RewardRarity.legendary});
      await tester.pumpAndSettle();

      // Ekranı sök, aynı oturum nesnesiyle yeniden kur.
      await tester.pumpWidget(const SizedBox());
      await pumpForge(tester, filter: filter);
      expect(find.text('Filtrele (1)'), findsOneWidget);
      expect(find.text('Sırala: Eşya seviyesi'), findsOneWidget);
      expect(find.text('Azrailin Tırpanı'), findsOneWidget);
      expect(find.text('Ayaz Tırpanı'), findsNothing);
    });

    testWidgets('yükseltilebilir süzgeci kartın düğmesiyle aynı kararı verir', (
      tester,
    ) async {
      // Parası olmayan oyuncu: hiçbir şey yükseltilemez.
      final filter = await pumpForge(tester, coins: 0);
      filter.value = const ForgeFilter(upgradableOnly: true);
      await tester.pumpAndSettle();
      expect(
        find.text('"Yükseltilebilir" süzgecine uyan hiç eşyan yok.'),
        findsOneWidget,
      );
    });

    testWidgets('buff özeti: imza önde ve rozetli, bedel ayrı', (tester) async {
      await pumpForge(
        tester,
        owned: const [
          OwnedItem(instanceId: 1, itemId: 'scythes/reapers_scythe'),
        ],
      );
      final reaper = byId('scythes/reapers_scythe');
      expect(signatureCoreCount(reaper), 4);
      // Dört imzalı etkinin dördünde de rozet var; bedel (−savunma) ayrıca.
      expect(find.text('İmza'), findsNWidgets(4));
      expect(find.text('Bedel'), findsOneWidget);
      expect(find.text('Etkiler (4)'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('forge-buffs-toggle')));
      await tester.pumpAndSettle();
      expect(find.text('İmza'), findsNothing);
    });

    testWidgets('kuraldan türeyen altı etkili efsanevi: hepsi görünür', (
      tester,
    ) async {
      await pumpForge(
        tester,
        owned: const [
          OwnedItem(
            instanceId: 1,
            itemId: 'swords/sword_variant_01',
            rarity: RewardRarity.legendary,
          ),
        ],
      );
      expect(find.text('Etkiler (6)'), findsOneWidget);
      for (var i = 0; i < 6; i++) {
        expect(find.byKey(ValueKey('forge-buff-row-$i')), findsOneWidget);
      }
      expect(find.text('İmza'), findsNothing);
    });
  });

  group('RootShell', () {
    testWidgets('demirci kapanıp açılınca süzgeç oturum boyunca korunur', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final sword = buildItemFromAsset('lib/Items/swords/sword.png')!;
      ItemCatalog.reset([sword]);
      addTearDown(ItemCatalog.reset);
      const avatar = AvatarProfile(
        name: 'Barca',
        age: 28,
        weight: 74,
        gender: 'Erkek',
        characterClass: 'SwordMan',
        characterAsset: 'lib/Characters/SwordMan/test.png',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: RootShell(
            avatar: avatar,
            initialState: GameState(
              profile: UserProfile(
                avatar: avatar,
                level: 10,
                coins: 500,
                ownedItems: [OwnedItem(instanceId: 1, itemId: sword.id)],
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

      Future<void> openForge() async {
        await tester.tap(find.text('Profil').last);
        await tester.pumpAndSettle();
        final entry = find.byKey(const ValueKey('profile-blacksmith-entry'));
        await tester.ensureVisible(entry);
        await tester.tap(entry);
        await tester.pumpAndSettle();
      }

      await openForge();
      await tester.tap(find.byKey(const ValueKey('forge-filter-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('forge-filter-upgradable')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('forge-sheet-done')));
      await tester.pumpAndSettle();
      expect(find.text('Filtrele (1)'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await openForge();
      expect(find.text('Filtrele (1)'), findsOneWidget);
      expect(find.text('Yükseltilebilir'), findsOneWidget);
    });
  });

  test('yükseltme maliyeti sıralaması gerçek maliyet fonksiyonunu kullanır', () {
    // Ekranın ürettiği maliyet `upgradeCostFor` ile aynı kaynaktan.
    expect(
      upgradeCostFor(100, RewardRarity.common, 1),
      greaterThan(0),
    );
  });
}
