import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/item_leveling.dart';
import 'package:rush_for_villains/core/utils/item_merging.dart';
import 'package:rush_for_villains/core/utils/item_rules.dart';
import 'package:rush_for_villains/features/store/xp_store_screen.dart';
import 'package:rush_for_villains/models/item.dart';
import 'package:rush_for_villains/models/reward_rarity.dart';
import 'package:rush_for_villains/models/xp_store_item.dart';

/// Mağazanın iki sözü var: kilitli bir kart **sessiz kalmaz** (CLAUDE.md —
/// Model Kuralları #4) ve kilit gerçekten tutar (#10/#11).
void main() {
  /// Gerçek sanat klasöründen üretilmiş katalogun tamamı. Düzen testleri
  /// gerçek (uzun) Türkçe adlarla çalışsın diye dosya sisteminden okunuyor —
  /// `item_catalog_test.dart` de aynı deseni kullanıyor.
  final allItems =
      [
        for (final entity in Directory('lib/Items').listSync(recursive: true))
          if (entity is File)
            buildItemFromAsset(
              entity.path.replaceAll(Platform.pathSeparator, '/'),
            ),
      ].nonNulls.toList();

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
    int extraWheelSpins = 0,
    bool xpBoostActive = false,
    Map<String, int> ownedEquipment = const {},
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
          ownedUpgradeIds: owned,
          ownedEquipmentCounts: {
            for (final id in ownedEquipment.keys) id: ownedEquipment[id]!,
          },
          streakFreezes: streakFreezes,
          extraWheelSpins: extraWheelSpins,
          xpBoostActive: xpBoostActive,
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

      // Kart "Yükseltilebilir · Maks Sv. N" satırıyla uzadı (4.5); varsayılan
      // 800x600 test görüntüsünde düğme ekran dışına düşebiliyor.
      final button = find.byType(FilledButton).last;
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
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

    testWidgets('sahip olunan item tekrar alınabilir, adet gösterilir', (
      tester,
    ) async {
      // Davranış Bölüm 4.1'de **bilerek** değişti (GD39): birleştirme aynı
      // eşyadan birkaç adet istiyor, dolayısıyla mağaza aynı eşyayı tekrar
      // satabilmeli. Kart "Sahipsin" yerine adet gösteriyor.
      final purchased = <Item>[];
      await pumpStore(
        tester,
        equipment: [cheapItem],
        level: 50,
        ownedEquipment: {cheapItem.id: 3},
        onPurchaseEquipment: purchased.add,
      );

      expect(find.text('Sahipsin'), findsNothing);
      expect(find.text('3 adet'), findsOneWidget);

      await tester.tap(find.byType(FilledButton).last);
      await tester.pump();

      expect(purchased, [cheapItem]);
    });
  });

  group('yatırım duyurusu (4.5)', () {
    testWidgets('kart eşyanın nereye kadar gideceğini söyler', (tester) async {
      // Amaç: oyuncu satın almayı **kalıcı bir yatırım** olarak görsün.
      await pumpStore(tester, equipment: [cheapItem], level: 50);

      expect(
        find.textContaining('Maks Sv. ${itemLevelCap(cheapItem.rarity)}'),
        findsOneWidget,
      );
      expect(find.textContaining('Yükseltilebilir'), findsOneWidget);
    });

    testWidgets('gereken birleştirme adedi nadirliğe göre yazılır', (
      tester,
    ) async {
      // Sayı sabit yazılmamalı: nadirliğe göre 3/4/5/6 değişiyor.
      await pumpStore(tester, equipment: [cheapItem], level: 50);

      final needed = mergeCountFor(cheapItem.rarity)!;
      final target = nextRarity(cheapItem.rarity)!;
      expect(
        find.textContaining('$needed tanesini birleştirince ${target.label}'),
        findsOneWidget,
      );
    });

    testWidgets('efsanevi kartta "en üst nadirlik" yazar', (tester) async {
      // lockedItem efsanevi; birleştirilemez ve bu söylenmeli.
      await pumpStore(tester, equipment: [lockedItem], level: 50);

      expect(find.textContaining('en üst nadirlik'), findsOneWidget);
      expect(
        find.textContaining('Maks Sv. ${itemLevelCap(lockedItem.rarity)}'),
        findsOneWidget,
      );
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

    testWidgets('"Alabileceklerim" sahip olunan itemi de gösterir', (
      tester,
    ) async {
      // GD14 güncellendi: sahiplik artık satın almayı engellemediği için
      // sahip olunan bir eşya da "bugün alabileceklerim" listesine ait —
      // ikinci adedi birleştirme için oradan alacaksın.
      await pumpStore(
        tester,
        equipment: [cheapItem],
        level: 50,
        coins: 100000,
        ownedEquipment: {cheapItem.id: 1},
      );

      expect(find.text(cheapItem.name), findsOneWidget);
      await tester.tap(find.text('Alabileceklerim'));
      await tester.pump();

      expect(find.text(cheapItem.name), findsOneWidget);
      expect(find.text('1 adet'), findsOneWidget);
    });

    testWidgets('süzgeç sonucu boşsa açıklayıcı metin çıkar', (tester) async {
      await pumpStore(tester, equipment: [lockedItem], level: 1, coins: 0);

      await tester.tap(find.text('Alabileceklerim'));
      await tester.pump();

      expect(find.textContaining('gösterilecek ekipman yok'), findsOneWidget);
      expect(find.text('0 ekipman'), findsOneWidget);
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

  group('tüketilen yükseltmelerin stok satırı', () {
    const wheelSpin = XpStoreItem(
      id: 'wheel_extra_spin',
      name: 'Ekstra Çark Hakkı',
      description: 'Bir kez daha çevir.',
      cost: 100,
      icon: Icons.replay_circle_filled,
      repeatable: true,
    );
    const boost = XpStoreItem(
      id: 'boost_double_xp',
      name: '2x XP Boost (1 gün)',
      description: 'XP ikiye katlanır.',
      cost: 100,
      icon: Icons.flash_on,
      repeatable: true,
    );

    testWidgets('dondurma stoğu gösterilir', (tester) async {
      await pumpStore(tester, upgrades: const [freeze], streakFreezes: 2);

      expect(find.text('Elinde 2 hak var'), findsOneWidget);
    });

    testWidgets('ekstra çark stoğu gösterilir', (tester) async {
      await pumpStore(tester, upgrades: const [wheelSpin], extraWheelSpins: 1);

      expect(find.text('Elinde 1 hak var'), findsOneWidget);
    });

    testWidgets('2x XP etkinken söylenir, değilken satır çıkmaz', (
      tester,
    ) async {
      await pumpStore(tester, upgrades: const [boost], xpBoostActive: true);
      expect(find.textContaining('Şu an etkin'), findsOneWidget);

      await pumpStore(tester, upgrades: const [boost]);
      expect(find.textContaining('Şu an etkin'), findsNothing);
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

  group('dar ekran düzeni', () {
    // Kart yüksekliği `childAspectRatio` ile ekran genişliğinden türetiliyordu:
    // 360 dp'de 40 px, 320 dp'de 67 px dikey taşma oluyor ve Column'un son
    // çocuğu — **satın alma düğmesi** — kartın dışında kalıyordu. Ayrıca
    // nadirlik rozeti + "Sv. N" satırı her genişlikte yatay taşıyordu.
    //
    // En kötü durum: **sınıfa uyarlanmış** (lakaplı, yani en uzun) adlar ve
    // üç bonus taşıyan itemler. Mağaza itemleri her zaman uyarlanmış gösterir.
    // 'Kutsanmış' katalogdaki en uzun sınıf lakabı.
    final worst = [for (final item in allItems) flavorForClass(item, 'Paladin')]
      ..sort((a, b) {
        final byBuff = b.buff.count.compareTo(a.buff.count);
        if (byBuff != 0) return byBuff;
        return b.name.length.compareTo(a.name.length);
      });
    final sample = worst.take(20).toList();

    testWidgets('az içerikli ekipman kartı gereksiz boşluk bırakmaz', (
      tester,
    ) async {
      await pumpStore(tester, equipment: [cheapItem]);

      final card = find.ancestor(
        of: find.text(cheapItem.name),
        matching: find.byType(Card),
      );

      // Ölçüt, GD12'nin kaldırdığı **sabit** yükseklikten (302 px) küçük
      // olmak: az bonuslu bir item, en uzun item için ayrılan boşluğu
      // taşımamalı. Kart 4.5'te bir yatırım satırıyla uzadı.
      expect(tester.getSize(card).height, lessThan(302));
    });

    for (final width in [320.0, 360.0, 390.0, 412.0, 480.0, 800.0]) {
      testWidgets('$width dp genişlikte ekipman kartı taşmıyor', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 4000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final errors = <String>[];
        final previous = FlutterError.onError;
        FlutterError.onError = (details) {
          errors.add(details.exceptionAsString());
        };
        addTearDown(() => FlutterError.onError = previous);

        await pumpStore(tester, equipment: sample, coins: 10, level: 1);

        // Yalnızca ilk birkaç hata raporlanıyor: taşan bir düzen her karede
        // yüzlerce hata üretiyor ve hepsini birleştirmek test koşucusunu
        // dakikalarca meşgul ediyordu (10 dakikalık zaman aşımına kadar).
        expect(
          errors,
          isEmpty,
          reason:
              '${errors.length} hata; ilk ikisi: '
              '${errors.take(2).join(" || ")}',
        );
      });
    }

    testWidgets('kilitli kartta seviye etiketi görünür', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpStore(tester, equipment: [lockedItem], level: 1);

      expect(find.text('Sv. ${lockedItem.requiredLevel}'), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsOneWidget);
    });
  });
}
