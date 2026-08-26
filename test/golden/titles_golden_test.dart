import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/title_rules.dart';
import 'package:rush_for_villains/features/titles/titles_screen.dart';

/// Ünvan ekranının görsel denetimi (Bölüm C.5).
///
/// Emülatör bu makinede çalışmıyor; takılı ünvan kartının, kilitli kartların
/// ipucu satırının ve ilerleme çubuklarının dar ekranda taşıp taşmadığı
/// ancak golden ile görülebiliyor.
///
/// Test ortamında gerçek font yok, yazılar dolu kutu çiziliyor — hizalama
/// denetimi için **en kötü durum**. Metnin doğruluğu ayrıca `find.text` ile
/// bağlanıyor.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Karışık bir örneklem: takılı bir ünvan, sahip olunan ikinci bir ünvan,
  /// ve ilerleme çubuğu görünen kilitli başarımlar.
  TitlesScreenState buildState() => TitlesScreenState(
    ownedIds: const {'coin_sniffer', 'first_step', 'night_walker'},
    equippedId: 'coin_sniffer',
    progress: const TitleProgress(
      level: 12,
      totalSteps: 62000,
      longestStreak: 9,
      enemiesDefeated: 14,
      adventuresCompleted: 6,
      ownedItemCount: 11,
      maxItemLevel: 4,
      wheelSpins: 8,
      itemsMerged: 1,
      lifetimeCoins: 4200,
    ),
    coins: 3400,
  );

  Future<void> pumpTitles(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final revision = ValueNotifier<int>(0);
    addTearDown(revision.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: TitlesScreen(
          revision: revision,
          readState: buildState,
          onEquip: (_) {},
        ),
      ),
    );
    // Sabit kare dizisi: `pumpAndSettle` bu projede kullanılamıyor (sonsuz
    // tekrar eden animasyonlar var) ve sabit dizi golden'ı tekrarlanabilir
    // kılıyor.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  for (final width in [320.0, 390.0]) {
    testWidgets('ünvan ekranı ${width.toInt()} dp', (tester) async {
      await pumpTitles(tester, width);

      // Takılı ünvan en üstte, adıyla birlikte.
      expect(find.text('Bozukluk Koklayan'), findsWidgets);
      expect(find.byKey(const ValueKey('unequip-title')), findsOneWidget);
      expect(find.byKey(const ValueKey('no-equipped-title')), findsNothing);

      await expectLater(
        find.byType(TitlesScreen),
        matchesGoldenFile('goldens/titles_${width.toInt()}.png'),
      );
    });
  }

  testWidgets('hiç ünvan takılı değilken boş durum anlatılıyor', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final revision = ValueNotifier<int>(0);
    addTearDown(revision.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: TitlesScreen(
          revision: revision,
          readState:
              () => const TitlesScreenState(
                ownedIds: {},
                equippedId: null,
                progress: TitleProgress(),
                coins: 0,
              ),
          onEquip: (_) {},
        ),
      ),
    );
    await tester.pump();

    // Kilitli ünvanlar yine listeleniyor: nasıl kazanılacağını görmeden
    // ünvan sistemi oyuncu için yok hükmünde (Model Kuralları #4).
    expect(find.byKey(const ValueKey('no-equipped-title')), findsOneWidget);
    expect(find.byKey(const ValueKey('unequip-title')), findsNothing);
  });
}
