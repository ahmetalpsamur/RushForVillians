import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/features/wheel/daily_wheel_screen.dart';

/// Çark dişlilerinin durağan karesi (triaj A6).
///
/// Eski hata: `rootBundle.load` ve `instantiateImageCodec` çağrıları
/// `try/catch` içinde değildi. Asset eksik ya da bozuksa yakalanmayan bir
/// asenkron istisna çıkıyordu; üstelik `_load` bir `Future` olarak
/// bekletilmediği için hata çark ekranını açan **başka** bir yere düşüyordu.
///
/// Doğru davranış: hata loglanır, widget boş çizer, uygulama akmaya devam
/// eder. `GifTiming._measure` aynı dosyada bu deseni zaten gösteriyordu.
///
/// **Test notu:** `rootBundle.load` ve `instantiateImageCodec` gerçek asenkron
/// iş yapıyor; `testWidgets`'in sahte saati onları ilerletmiyor. Bu yüzden
/// yükleme `runAsync` içinde gerçek zamanda çalıştırılıyor.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpAsset(WidgetTester tester, String asset) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 60,
            height: 60,
            child: StillGifFrame(asset: asset),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      // Yüklemenin tamamlanması için gerçek zamanda kısa bir pencere.
      await Future<void>.delayed(const Duration(milliseconds: 120));
    });
    await tester.pump();
  }

  testWidgets('eksik asset istisna fırlatmaz, boş çizer', (tester) async {
    await pumpAsset(tester, 'lib/ChanceWheel/olmayan_disli.gif');

    expect(tester.takeException(), isNull);
    expect(find.byType(StillGifFrame), findsOneWidget);
    // Kare yüklenemediği için görüntü çizilmez ama widget ayakta.
    expect(find.byType(RawImage), findsNothing);
  });

  testWidgets('var olan asset ilk kareyi çizer', (tester) async {
    await pumpAsset(tester, 'lib/ChanceWheel/normal_gear_1.gif');

    expect(tester.takeException(), isNull);
    expect(find.byType(RawImage), findsOneWidget);
  });

  testWidgets('hatalı assettan sağlam assete geçiş çalışır', (tester) async {
    await pumpAsset(tester, 'lib/ChanceWheel/olmayan_disli.gif');
    expect(tester.takeException(), isNull);
    expect(find.byType(RawImage), findsNothing);

    await pumpAsset(tester, 'lib/ChanceWheel/silver_gear_1.gif');
    expect(tester.takeException(), isNull);
    expect(find.byType(RawImage), findsOneWidget);
  });
}
