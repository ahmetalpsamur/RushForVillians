import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/features/wheel/daily_wheel_screen.dart';

/// Çark ekranının hak yönetimi.
///
/// Mağazadaki "Ekstra Çark Hakkı" yükseltmesi (bkz. `store_purchase_test.dart`)
/// tüketimini buradan yapıyor: günlük hak bittiğinde jeton harcanır.
/// Ekran itilen bir rotada durduğu için kalan hakkı **kendisi** sayar;
/// `RootShell` aynı kuralı `UserProfile.consumeWheelSpin` içinde uyguluyor.
void main() {
  Future<List<int>> pumpWheel(
    WidgetTester tester, {
    required bool alreadySpunToday,
    int extraSpins = 0,
  }) async {
    final results = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: DailyWheelScreen(
          alreadySpunToday: alreadySpunToday,
          extraSpins: extraSpins,
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
    await tester.pumpAndSettle();
  }

  group('günlük hak', () {
    testWidgets('hak duruyorsa çevirme düğmesi çıkar', (tester) async {
      await pumpWheel(tester, alreadySpunToday: false);

      expect(find.widgetWithText(FilledButton, 'Çarkı Çevir'), findsOneWidget);
      expect(find.textContaining('ekstra hakkından'), findsNothing);
    });

    testWidgets('hak bittiyse ve jeton yoksa çevrilemez', (tester) async {
      await pumpWheel(tester, alreadySpunToday: true);

      expect(find.widgetWithText(FilledButton, 'Çarkı Çevir'), findsNothing);
      expect(find.text('Bugün çarkı zaten çevirdin.'), findsOneWidget);
    });

    testWidgets('çevirme sonucu bildirilir ve tekrar çevrilemez', (
      tester,
    ) async {
      final results = await pumpWheel(tester, alreadySpunToday: false);

      await spin(tester);

      expect(results, hasLength(1));
      expect(find.textContaining('Kazandın: +${results.single} XP'), findsOne);
      expect(find.widgetWithText(FilledButton, 'Çarkı Çevir'), findsNothing);
    });
  });

  group('ekstra hak', () {
    testWidgets(
      'günlük hak bittiyse jetonla çevrilebilir ve önceden söylenir',
      (tester) async {
        await pumpWheel(tester, alreadySpunToday: true, extraSpins: 2);

        expect(
          find.widgetWithText(FilledButton, 'Çarkı Çevir'),
          findsOneWidget,
        );
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
      // Bir jeton kaldığı için düğme hâlâ duruyor.
      expect(find.widgetWithText(FilledButton, 'Çarkı Çevir'), findsOneWidget);
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
      expect(find.widgetWithText(FilledButton, 'Çarkı Çevir'), findsNothing);
      expect(find.textContaining('Kazandın:'), findsOneWidget);
    });

    testWidgets('günlük hak dururken jeton harcanmaz', (tester) async {
      await pumpWheel(tester, alreadySpunToday: false, extraSpins: 1);

      // Ücretsiz hak var: uyarı satırı çıkmamalı.
      expect(find.textContaining('ekstra hakkından'), findsNothing);

      await spin(tester);

      // Ücretsiz hak harcandı; şimdi jetona geçilir.
      expect(find.widgetWithText(FilledButton, 'Çarkı Çevir'), findsOneWidget);
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
      expect(find.widgetWithText(FilledButton, 'Çarkı Çevir'), findsNothing);
    });
  });
}
