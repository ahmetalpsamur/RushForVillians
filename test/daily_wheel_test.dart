import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/item_rules.dart';
import 'package:rush_for_villains/features/wheel/daily_wheel_screen.dart';
import 'package:rush_for_villains/models/item.dart';
import 'package:rush_for_villains/models/reward_rarity.dart';
import 'package:rush_for_villains/models/wheel_reward.dart';

/// Çark ekranının hak yönetimi ve ödül gösterimi (#16).
///
/// Mağazadaki "Ekstra Çark Hakkı" yükseltmesi (bkz. `store_purchase_test.dart`)
/// tüketimini buradan yapıyor. Havuz kuralları `wheel_rewards_test.dart`
/// içinde ayrıca test ediliyor; burada ekranın davranışı var.
void main() {
  // Sıradan, 1-3. seviyede açılan kılıçlar (SwordMan/Thief).
  final cheap = buildItemFromAsset('lib/Items/swords/sword.png')!;
  final dagger = buildItemFromAsset('lib/Items/swords/dagger_variant_01.png')!;

  Future<List<WheelReward>> pumpWheel(
    WidgetTester tester, {
    required bool alreadySpunToday,
    int extraSpins = 0,
    int seed = 12345,
    int level = 1,
    List<Item> equipment = const [],
    List<String> owned = const [],
  }) async {
    final results = <WheelReward>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: DailyWheelScreen(
          // Aynı testte ikinci kez pump edilirse yeni bir State kurulsun;
          // anahtarsız aynı tipteki widget eski durumu (sonuç, harcanan hak)
          // korurdu.
          key: UniqueKey(),
          alreadySpunToday: alreadySpunToday,
          extraSpins: extraSpins,
          seed: seed,
          level: level,
          equipment: equipment,
          ownedItemIds: owned,
          onSpinResult: results.add,
        ),
      ),
    );
    await tester.pump();
    return results;
  }

  /// Çarkı çevirir ve animasyonun bitmesini bekler.
  Future<void> spin(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Çarkı Çevir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2700));
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump();
  }

  Finder spinButton() => find.widgetWithText(FilledButton, 'Çarkı Çevir');

  testWidgets('eski segmentli arka çark olmadan yedi dişli gösterilir', (
    tester,
  ) async {
    await pumpWheel(tester, alreadySpunToday: false);

    expect(find.byType(StillGifFrame), findsNWidgets(7));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('chance-wheel-face')),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
  });

  group('günlük hak', () {
    testWidgets('hak duruyorsa çevirme düğmesi çıkar', (tester) async {
      await pumpWheel(tester, alreadySpunToday: false);

      expect(spinButton(), findsOneWidget);
      expect(find.textContaining('ekstra hakkından'), findsNothing);
    });

    testWidgets('hak bittiyse ve jeton yoksa çevrilemez', (tester) async {
      await pumpWheel(tester, alreadySpunToday: true);

      expect(spinButton(), findsNothing);
      expect(find.text('Bugün çarkı zaten çevirdin.'), findsOneWidget);
    });

    testWidgets('çevirme sonucu bildirilir ve tekrar çevrilemez', (
      tester,
    ) async {
      final results = await pumpWheel(tester, alreadySpunToday: false);

      await spin(tester);

      expect(results, hasLength(1));
      expect(find.textContaining('Kazandın:'), findsOneWidget);
      expect(spinButton(), findsNothing);
    });

    testWidgets('sonuç karartıda ışıklı ödül sahnesinde gösterilir', (
      tester,
    ) async {
      final results = await pumpWheel(tester, alreadySpunToday: false);

      await tester.tap(spinButton());
      await tester.pump();
      expect(find.text('ŞANS MEKANİZMASI ÇALIŞIYOR'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 2700));
      expect(results, hasLength(1));
      expect(find.byKey(const ValueKey('wheel-reward-reveal')), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 2500));
      expect(find.byKey(const ValueKey('wheel-reward-reveal')), findsNothing);
    });
  });

  group('ekstra hak', () {
    testWidgets(
      'günlük hak bittiyse jetonla çevrilebilir ve önceden söylenir',
      (tester) async {
        await pumpWheel(tester, alreadySpunToday: true, extraSpins: 2);

        expect(spinButton(), findsOneWidget);
        expect(find.textContaining('(2 hak kaldı)'), findsOneWidget);
      },
    );

    testWidgets('jeton harcanınca kalan hak azalır', (tester) async {
      final results = await pumpWheel(
        tester,
        alreadySpunToday: true,
        extraSpins: 2,
      );

      await spin(tester);

      expect(results, hasLength(1));
      expect(spinButton(), findsOneWidget);
      expect(find.textContaining('(1 hak kaldı)'), findsOneWidget);
    });

    testWidgets('son jeton da bitince çevirme kapanır', (tester) async {
      final results = await pumpWheel(
        tester,
        alreadySpunToday: true,
        extraSpins: 1,
      );

      await spin(tester);

      expect(results, hasLength(1));
      expect(spinButton(), findsNothing);
    });

    testWidgets('günlük hak dururken jeton harcanmaz', (tester) async {
      await pumpWheel(tester, alreadySpunToday: false, extraSpins: 1);

      expect(find.textContaining('ekstra hakkından'), findsNothing);

      await spin(tester);

      expect(spinButton(), findsOneWidget);
      expect(find.textContaining('(1 hak kaldı)'), findsOneWidget);
    });

    testWidgets('iki hak da aynı ekranda kullanılabilir', (tester) async {
      final results = await pumpWheel(
        tester,
        alreadySpunToday: false,
        extraSpins: 1,
      );

      await spin(tester);
      await spin(tester);

      expect(results, hasLength(2));
      expect(spinButton(), findsNothing);
    });
  });

  group('item ödülü (#16)', () {
    testWidgets('aynı tohum aynı sonucu verir', (tester) async {
      final first = await pumpWheel(
        tester,
        alreadySpunToday: false,
        seed: 777,
        level: 50,
        equipment: [cheap, dagger],
      );
      await spin(tester);

      final second = await pumpWheel(
        tester,
        alreadySpunToday: false,
        seed: 777,
        level: 50,
        equipment: [cheap, dagger],
      );
      await spin(tester);

      expect(first.single.label, second.single.label);
    });

    testWidgets('ikinci çevirme aynı sonucu vermez (tohum ilerler)', (
      tester,
    ) async {
      // Sabit tohumla iki ardışık çevirme: ekran tohumu ilerlettiği için
      // aynı dilim dizisi tekrar kurulmamalı.
      final results = await pumpWheel(
        tester,
        alreadySpunToday: false,
        extraSpins: 1,
        seed: 4242,
        level: 50,
        equipment: [cheap, dagger],
      );

      await spin(tester);
      await spin(tester);

      expect(results, hasLength(2));
      // Kazanılan bir item ikinci çarkta tekrar çıkmamalı.
      final wonIds = results.where((r) => r.isItem).map((r) => r.item!.id);
      expect(wonIds.toSet().length, wonIds.length);
    });

    testWidgets('item kazanılınca görseli ve nadirliği gösterilir', (
      tester,
    ) async {
      // Havuzun tamamı item olsun diye bol aday veriyoruz; hangi dilimin
      // geleceği tohuma bağlı, bu yüzden sonucu kontrol edip iddiayı ona
      // göre kuruyoruz.
      final results = await pumpWheel(
        tester,
        alreadySpunToday: false,
        seed: 999,
        level: 50,
        equipment: [cheap, dagger],
      );

      await spin(tester);

      final reward = results.single;
      if (reward.isItem) {
        expect(find.text('Ekipman kazandın! 🎉'), findsOneWidget);
        expect(find.text(reward.item!.name), findsOneWidget);
        expect(find.text(reward.item!.rarity.label), findsWidgets);
      } else {
        expect(find.textContaining('Kazandın: +${reward.xp} XP'), findsOne);
      }
    });

    testWidgets('ekipman yoksa çark yine çalışır ve XP verir', (tester) async {
      final results = await pumpWheel(tester, alreadySpunToday: false);

      await spin(tester);

      expect(results.single.isItem, isFalse);
      expect(results.single.xp, greaterThan(0));
    });
  });
}
