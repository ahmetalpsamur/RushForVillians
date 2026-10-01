import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/widgets/coin_rain.dart';

/// Yürüyüş fazının para yağmuru (Bölüm D / Faz 1.5).
///
/// Bileşen `widgets/` altına **test edilebilmek için** çıkarıldı (GD48 ile
/// aynı gerekçe): `_WalkPhaseScene` private ve onun golden'ları Bölüm D'den
/// önce de kırmızı, yani yağmuru oradan gözle doğrulamak mümkün değil.
///
/// ⚠️ `pumpAndSettle` **kullanılmıyor**: yağmur sonsuz tekrarlı bir
/// controller ile sürüyor (GD76). Sabit kare dizisi hem golden'ı
/// tekrarlanabilir kılıyor hem testi kilitlemiyor.
void main() {
  Future<void> pump(
    WidgetTester tester,
    double width,
    AnimationController controller,
  ) async {
    tester.view.physicalSize = Size(width, 260);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: ColoredBox(
            color: AppColors.surface,
            child: CoinRain(
              key: const ValueKey('coin-rain'),
              controller: controller,
            ),
          ),
        ),
      ),
    );
    // ⚠️ Varlıkların çözülmesi beklenmeli. `Image.asset` kareyi sonraki
    // frame'de bağlıyor; ilk testte GIF henüz yüklenmemiş oluyor ve
    // `errorBuilder`'daki `Icon` devreye giriyor — test ortamında ikon
    // fontu da olmadığı için **hiçbir şey çizilmiyor** ve golden bomboş
    // çıkıyor. Ölçüldü: 320 dp karesi boş, 390 dp (ikinci test, önbellek
    // sıcak) doluydu.
    // ⚠️ Varlık yüklenmemişse `errorBuilder` devreye giriyor; o yüzden
    // yedek **çizilen** bir disk (bkz. [CoinRain]). Golden böylece GIF'in
    // o anda çözülüp çözülmediğinden bağımsız olarak yerleşimi ölçüyor.
    // `runAsync` + `precacheImage` denendi: animasyonlu GIF çözümü
    // süiti 10 dakikaya çıkarıyor, ölçtüğü şeye değmiyor.
    // Döngünün ortasına sabit bir noktadan gidiliyor: her para kendi
    // fazında olduğu için bu kare yağmurun tamamını temsil ediyor.
    controller.value = 0.37;
    await tester.pump();
  }

  for (final width in const [320.0, 390.0]) {
    testWidgets('golden: para yağmuru (${width.toInt()} dp)', (tester) async {
      final controller = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 2600),
      );
      addTearDown(controller.dispose);
      await pump(tester, width, controller);
      await expectLater(
        find.byType(CoinRain),
        matchesGoldenFile('goldens/coin_rain_${width.toInt()}.png'),
      );
    });
  }

  testWidgets('yağmur dokunmayı engellemez', (tester) async {
    // En sert kural: faz boyunca ekranda duran bir katman hiçbir düğmeyi
    // yutmamalı (GD77 ile aynı fikir).
    final controller = AnimationController(
      vsync: tester,
      duration: const Duration(milliseconds: 2600),
    );
    addTearDown(controller.dispose);

    var tapped = 0;
    tester.view.physicalSize = const Size(390, 260);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => tapped++,
                  child: const ColoredBox(color: AppColors.surface),
                ),
              ),
              Positioned.fill(child: CoinRain(controller: controller)),
            ],
          ),
        ),
      ),
    );
    controller.value = 0.37;
    await tester.pump();

    await tester.tapAt(const Offset(195, 130));
    await tester.pump();
    expect(tapped, 1, reason: 'yağmur dokunuşu yutmamalı');
  });

  testWidgets('aynı kare her çalıştırmada aynı', (tester) async {
    // Konumlar `stableSpread` ile kimlikten türüyor; `Random()` yok.
    // Determinizm olmasaydı golden her koşuda farklı çıkardı.
    Future<List<double>> positionsAt(double value) async {
      final controller = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 2600),
      );
      addTearDown(controller.dispose);
      await pump(tester, 390, controller);
      controller.value = value;
      await tester.pump();
      return tester
          .widgetList<Positioned>(
            find.descendant(
              of: find.byType(CoinRain),
              matching: find.byType(Positioned),
            ),
          )
          .map((p) => p.top ?? -1)
          .toList();
    }

    final first = await positionsAt(0.42);
    final second = await positionsAt(0.42);
    expect(first, hasLength(CoinRain.coinCount));
    expect(first, second);
  });
}
