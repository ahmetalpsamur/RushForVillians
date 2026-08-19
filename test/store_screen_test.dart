import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/item_rules.dart';
import 'package:rush_for_villains/features/store/xp_store_screen.dart';
import 'package:rush_for_villains/models/item.dart';
import 'package:rush_for_villains/models/xp_store_item.dart';

/// Mağazanın iki sözü var: kilitli bir kart **sessiz kalmaz** (CLAUDE.md —
/// Model Kuralları #4) ve kilit gerçekten tutar (#10/#11).
void main() {
  // Sıradan, ilk seviyelerde açılan ucuz item.
  final cheapItem = buildItemFromAsset('lib/Items/swords/sword.png')!;
  // Efsanevi, 22+ seviye isteyen pahalı item.
  final lockedItem = buildItemFromAsset('lib/Items/swords/dragons_hook.png')!;

  const upgrade = XpStoreItem(
    id: 'title_villain_hunter',
    name: 'Unvan',
    description: 'Profilinde görünen özel unvan.',
    cost: 100,
    icon: Icons.military_tech,
  );
  const freeze = XpStoreItem(
    id: 'upgrade_streak_freeze',
    name: 'Seri Dondurma Hakkı',
    description: 'Bir günü kaçırırsan serin korunur.',
    cost: 100,
    icon: Icons.ac_unit,
    repeatable: true,
  );

  Future<void> pumpStore(
    WidgetTester tester, {
    List<Item> equipment = const [],
    List<XpStoreItem> upgrades = const [],
    int coins = 100000,
    int level = 50,
    List<String> owned = const [],
    int streakFreezes = 0,
    void Function(Item)? onPurchaseEquipment,
    void Function(XpStoreItem)? onPurchase,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: XpStoreScreen(
          items: upgrades,
          equipment: equipment,
          coins: coins,
          level: level,
          ownedItemIds: owned,
          streakFreezes: streakFreezes,
          onPurchase: onPurchase ?? (_) {},
          onPurchaseEquipment: onPurchaseEquipment ?? (_) {},
        ),
      ),
    );
    await tester.pump();
  }

  group('ekipman seviye kilidi (#10/#11)', () {
    testWidgets('seviyesi yetmeyen item kilit ikonu gösterir', (tester) async {
      await pumpStore(tester, equipment: [lockedItem], level: 1);

      expect(find.byIcon(Icons.lock), findsOneWidget);
      expect(find.textContaining('Sv. ${lockedItem.requiredLevel}'), findsOne);
    });

    testWidgets('seviyesi yeten item kilit göstermez', (tester) async {
      await pumpStore(tester, equipment: [lockedItem], level: 50);

      expect(find.byIcon(Icons.lock), findsNothing);
    });

    testWidgets('kilitli item satın alınamaz ve nedeni söylenir', (
      tester,
    ) async {
      final purchased = <Item>[];
      await pumpStore(
        tester,
        equipment: [lockedItem],
        level: 1,
        onPurchaseEquipment: purchased.add,
      );

      await tester.tap(find.byType(FilledButton).last);
      await tester.pump();

      expect(purchased, isEmpty, reason: 'kilit gerçekten tutmalı');
      expect(
        find.textContaining('${lockedItem.requiredLevel}. seviye gerekiyor'),
        findsOneWidget,
      );
    });

    testWidgets('parası yetmeyen item satın alınamaz ve eksik para söylenir', (
      tester,
    ) async {
      final purchased = <Item>[];
      await pumpStore(
        tester,
        equipment: [cheapItem],
        level: 50,
        coins: 0,
        onPurchaseEquipment: purchased.add,
      );

      await tester.tap(find.byType(FilledButton).last);
      await tester.pump();

      expect(purchased, isEmpty);
      expect(
        find.textContaining('${cheapItem.cost} coin daha gerekiyor'),
        findsOneWidget,
      );
    });

    testWidgets('alınabilir item satın alma çağrısını tetikler', (
      tester,
    ) async {
      final purchased = <Item>[];
      await pumpStore(
        tester,
        equipment: [cheapItem],
        level: 50,
        onPurchaseEquipment: purchased.add,
      );

      await tester.tap(find.byType(FilledButton).last);
      await tester.pump();

      expect(purchased.single.id, cheapItem.id);
    });

    testWidgets('sahip olunan item tekrar alınamaz', (tester) async {
      final purchased = <Item>[];
      await pumpStore(
        tester,
        equipment: [cheapItem],
        level: 50,
        owned: [cheapItem.id],
        onPurchaseEquipment: purchased.add,
      );

      expect(find.text('Sahipsin'), findsOneWidget);

      await tester.tap(find.byType(FilledButton).last);
      await tester.pump();

      expect(purchased, isEmpty);
      expect(find.textContaining('zaten sende'), findsOneWidget);
    });
  });

  group('süzgeçler', () {
    testWidgets('kilitli itemler varsayılan olarak listede kalır', (
      tester,
    ) async {
      await pumpStore(tester, equipment: [cheapItem, lockedItem], level: 1);

      expect(find.text('2 ekipman'), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsWidgets);
    });

    testWidgets('"Alabileceklerim" kilitli ve pahalı itemleri gizler', (
      tester,
    ) async {
      await pumpStore(
        tester,
        equipment: [cheapItem, lockedItem],
        level: cheapItem.requiredLevel,
        coins: 100000,
      );

      await tester.tap(find.widgetWithText(FilterChip, 'Alabileceklerim'));
      await tester.pump();

      expect(find.text('1 ekipman'), findsOneWidget);
      expect(find.text(cheapItem.name), findsOneWidget);
    });

    testWidgets('kategori süzgeci yalnızca o kategoriyi bırakır', (
      tester,
    ) async {
      final bow = buildItemFromAsset('lib/Items/arch/longbow.png')!;
      await pumpStore(tester, equipment: [cheapItem, bow], level: 50);

      await tester.tap(
        find.widgetWithText(ChoiceChip, ItemCategory.arch.label),
      );
      await tester.pump();

      expect(find.text('1 ekipman'), findsOneWidget);
      expect(find.text(bow.name), findsOneWidget);
      expect(find.text(cheapItem.name), findsNothing);
    });

    testWidgets('ekipman yoksa açıklayıcı metin çıkar', (tester) async {
      await pumpStore(tester);

      expect(find.textContaining('ekipman bulunamadı'), findsOneWidget);
    });
  });

  group('yükseltmeler', () {
    testWidgets('sahip olunan tekrarlanamaz yükseltme yeniden alınamaz', (
      tester,
    ) async {
      final purchased = <XpStoreItem>[];
      await pumpStore(
        tester,
        upgrades: const [upgrade],
        owned: const ['title_villain_hunter'],
        onPurchase: purchased.add,
      );

      expect(find.text('Sahipsin'), findsOneWidget);

      await tester.tap(find.byType(FilledButton).first);
      await tester.pump();

      expect(purchased, isEmpty);
    });

    testWidgets('tekrarlanabilir yükseltme sahipken de alınabilir', (
      tester,
    ) async {
      final purchased = <XpStoreItem>[];
      await pumpStore(
        tester,
        upgrades: const [freeze],
        owned: const ['upgrade_streak_freeze'],
        streakFreezes: 1,
        onPurchase: purchased.add,
      );

      expect(find.text('Sahipsin'), findsNothing);
      expect(find.textContaining('Elinde 1 hak var'), findsOneWidget);

      await tester.tap(find.byType(FilledButton).first);
      await tester.pump();

      expect(purchased.single.id, 'upgrade_streak_freeze');
    });

    testWidgets('parası yetmeyen yükseltme eksik parayı söyler', (
      tester,
    ) async {
      final purchased = <XpStoreItem>[];
      await pumpStore(
        tester,
        upgrades: const [upgrade],
        coins: 40,
        onPurchase: purchased.add,
      );

      await tester.tap(find.byType(FilledButton).first);
      await tester.pump();

      expect(purchased, isEmpty);
      expect(find.textContaining('60 coin daha gerekiyor'), findsOneWidget);
    });
  });

  group('para birimi', () {
    testWidgets('fiyat XP değil coin olarak gösterilir (triaj A4)', (
      tester,
    ) async {
      await pumpStore(tester, equipment: [cheapItem], level: 50, coins: 1234);

      expect(find.text('${cheapItem.cost} XP'), findsNothing);
      expect(find.text('${cheapItem.cost}'), findsOneWidget);
      expect(find.text('1234'), findsOneWidget);
      expect(find.byIcon(Icons.monetization_on), findsWidgets);
    });
  });
}
