import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/features/character/character_creation_screen.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/services/character_catalog.dart';

/// Karakter yaratma sihirbazı — sınıf seçimi.
///
/// Üç davranış korunuyor:
///  1. Tanıtım ekranından çıkış yolu var (buton + donanım geri tuşu),
///  2. onay **tek** ve tanıtım ekranında veriliyor,
///  3. onaylanmadan devam edilemiyor ve nedeni yazılı.
void main() {
  /// Sabit adımlarla ilerletir.
  ///
  /// `pumpAndSettle` kullanılamıyor: ekipman salınımı sonsuz tekrar eden bir
  /// animasyon (`_equipmentBobController.repeat()`), dolayısıyla ağaç asla
  /// durulmuyor. Sabit kare dizisi hem bekleyişi çözüyor hem golden'ları
  /// tekrarlanabilir kılıyor.
  Future<void> settle(WidgetTester tester, {int frames = 18}) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Sihirbazı sınıf adımına (4) kadar ilerletir.
  Future<void> pumpToClassStep(
    WidgetTester tester, {
    AvatarProfile? initialAvatar,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: CharacterCreationScreen(
          initialAvatar: initialAvatar,
          onCompleted: (_) {},
        ),
      ),
    );
    await settle(tester);

    if (initialAvatar == null) {
      await tester.enterText(find.byType(TextField).first, 'Barca');
      await tester.pump();
    }
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('DEVAM ET'));
      await settle(tester);
    }
  }

  /// Izgaradaki ilk sınıf kartına dokunup tanıtım ekranını açar.
  Future<void> openFirstReveal(WidgetTester tester) async {
    final classes = await CharacterCatalog.load();
    await tester.tap(find.text(classes.first.name).first);
    await settle(tester);
  }

  group('sınıf tanıtım ekranı', () {
    testWidgets('katalog yüklenir ve sınıf adımına ulaşılır', (tester) async {
      await pumpToClassStep(tester);
      expect(find.text('Hangi sınıfa aitsin?'), findsOneWidget);
    });

    testWidgets('kart dokununca tanıtım ekranı açılır', (tester) async {
      await pumpToClassStep(tester);
      await openFirstReveal(tester);
      expect(find.text('BU SINIFI SEÇ'), findsOneWidget);
    });

    testWidgets('geri butonu tanıtım ekranını kapatır, seçim yapmaz', (
      tester,
    ) async {
      await pumpToClassStep(tester);
      await openFirstReveal(tester);

      await tester.tap(find.byTooltip('Sınıf listesine dön'));
      await settle(tester);

      expect(find.text('BU SINIFI SEÇ'), findsNothing);
      expect(find.text('Hangi sınıfa aitsin?'), findsOneWidget);
    });

    testWidgets('donanım geri tuşu tanıtım ekranını kapatır', (tester) async {
      await pumpToClassStep(tester);
      await openFirstReveal(tester);

      await tester.binding.handlePopRoute();
      await settle(tester);

      expect(find.text('BU SINIFI SEÇ'), findsNothing);
      expect(find.text('Hangi sınıfa aitsin?'), findsOneWidget);
    });

    testWidgets('donanım geri tuşu tanıtım kapalıyken bir adım geri alır', (
      tester,
    ) async {
      await pumpToClassStep(tester);
      expect(find.text('Hangi sınıfa aitsin?'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await settle(tester);

      expect(find.text('Hangi sınıfa aitsin?'), findsNothing);
    });
  });

  group('tek onay', () {
    testWidgets('onaylanmadan DEVAM ET kapalı ve nedeni yazılı', (
      tester,
    ) async {
      await pumpToClassStep(tester);

      expect(
        find.textContaining('BU SINIFI SEÇ”e bas', findRichText: true),
        findsOneWidget,
      );
      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('DEVAM ET'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('tanıtımda seçmek doğrudan özet adımına geçirir', (
      tester,
    ) async {
      await pumpToClassStep(tester);
      await openFirstReveal(tester);

      await tester.tap(find.text('BU SINIFI SEÇ'));
      await settle(tester);

      // İkinci bir onay istenmiyor: ızgara geride kaldı, özet adımı açık.
      expect(find.text('Hangi sınıfa aitsin?'), findsNothing);
      expect(find.text('MACERAYA BAŞLA'), findsOneWidget);
    });

    testWidgets('düzenleme modunda kayıtlı sınıf onaylı sayılır', (
      tester,
    ) async {
      final classes = await CharacterCatalog.load();
      final existing = classes.first;
      await pumpToClassStep(
        tester,
        initialAvatar: AvatarProfile(
          name: 'Barca',
          age: 24,
          weight: 72,
          gender: 'Erkek',
          characterClass: existing.id,
          characterAsset: existing.walkingAsset,
        ),
      );

      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('DEVAM ET'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNotNull);
    });
  });

  group('tanıtım ekranı düzeni', () {
    // Eşya şeridi eskiden yatay bir ListView'du ve içerik sığsa bile sola
    // yaslanıyordu. Şerit artık ortalanmalı.
    for (final size in const [
      Size(320, 640), // en dar destek
      Size(360, 800), // en yaygın Android
      Size(390, 844), // normal
      Size(412, 915),
      Size(800, 1280), // tablet
    ]) {
      testWidgets('eşya şeridi ${size.width.toInt()} dp genişlikte ortalı', (
        tester,
      ) async {
        await pumpToClassStep(tester, size: size);
        await openFirstReveal(tester);

        final strip = find.byType(SingleChildScrollView);
        expect(strip, findsWidgets);

        final viewport = tester.getRect(strip.first);
        final row = tester.getRect(
          find.descendant(of: strip.first, matching: find.byType(Row)).first,
        );

        if (row.width <= viewport.width + 0.5) {
          // Sığıyorsa ortalanmalı. Eski yatay ListView burada sola yaslıyordu.
          expect(
            (row.center.dx - viewport.center.dx).abs(),
            lessThan(1.0),
            reason: 'sığan eşya şeridi ortalanmalı',
          );
        } else {
          // Sığmıyorsa kaydırılabilir olmalı; kırpma değil kaydırma.
          expect(
            row.left,
            closeTo(viewport.left, 1.0),
            reason: 'taşan şerit baştan başlamalı',
          );
        }
      });
    }

    testWidgets('golden: sınıf ızgarası (360 dp)', (tester) async {
      await pumpToClassStep(tester, size: const Size(360, 800));
      await expectLater(
        find.byType(CharacterCreationScreen),
        matchesGoldenFile('golden/goldens/class_grid_360.png'),
      );
    });

    testWidgets('golden: sınıf ızgarası (320 dp)', (tester) async {
      await pumpToClassStep(tester, size: const Size(320, 640));
      await expectLater(
        find.byType(CharacterCreationScreen),
        matchesGoldenFile('golden/goldens/class_grid_320.png'),
      );
    });

    testWidgets('golden: tanıtım ekranı (360 dp)', (tester) async {
      await pumpToClassStep(tester, size: const Size(360, 800));
      await openFirstReveal(tester);
      await expectLater(
        find.byType(CharacterCreationScreen),
        matchesGoldenFile('golden/goldens/class_reveal_360.png'),
      );
    });

    testWidgets('golden: tanıtım ekranı (320 dp)', (tester) async {
      await pumpToClassStep(tester, size: const Size(320, 640));
      await openFirstReveal(tester);
      await expectLater(
        find.byType(CharacterCreationScreen),
        matchesGoldenFile('golden/goldens/class_reveal_320.png'),
      );
    });

    testWidgets('golden: tanıtım ekranı (800 dp tablet)', (tester) async {
      await pumpToClassStep(tester, size: const Size(800, 1280));
      await openFirstReveal(tester);
      await expectLater(
        find.byType(CharacterCreationScreen),
        matchesGoldenFile('golden/goldens/class_reveal_800.png'),
      );
    });
  });
}
