import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/data/pet_sayings.dart';
import 'package:rush_for_villains/features/tutorial/pet_companion.dart';
import 'package:rush_for_villains/features/tutorial/tutorial_guide.dart';

/// Rehberin **konum ve ölçek** denetimi (Bölüm A.2).
///
/// Emülatör bu makinede çalışmıyor; pet'in alt gezinme çubuğunun üstünde
/// kalıp kalmadığı, düğmeleri kapatıp kapatmadığı ve boyutunun cihazla
/// orantılı olup olmadığı ancak golden + ölçüm ile görülebiliyor.
///
/// Kurulum **gerçek** `Scaffold` + `NavigationBar` kullanıyor: pet artık
/// `Scaffold.body` içinde yaşıyor ve konumu body'nin alt kenarından çıkıyor
/// (GD82). Sahte bir kutu yerine gerçek çubukla ölçmek, hesabın gerçekten
/// çubuğun yüksekliğini ve SafeArea'yı takip ettiğini kanıtlıyor.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Cihaz profili: genişlik, yükseklik ve jest çubuğu payı.
  const devices = <String, (double, double, double)>{
    // Küçük telefon, jest çubuğu yok (donanım tuşları).
    'small_320': (320, 568, 0),
    // Yaygın telefon, jest çubuğu var.
    'phone_390': (390, 844, 34),
    // Tablet, ince jest çubuğu.
    'tablet_800': (800, 1180, 20),
  };

  Future<void> pumpShell(
    WidgetTester tester,
    (double, double, double) device, {
    Duration rest = const Duration(seconds: 3),
    Duration edgeAction = const Duration(milliseconds: 900),
    Duration stroll = const Duration(seconds: 14),
    Duration initialDelay = Duration.zero,
  }) async {
    final (width, height, gestureBar) = device;
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = FakeViewPadding(bottom: gestureBar);
    tester.view.viewPadding = FakeViewPadding(bottom: gestureBar);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Color(0xFF14101F)),
              PetCompanionOverlay(
                situation: const PetSituation(context: PetContext.tavern),
                initialDelay: initialDelay,
                restDuration: rest,
                edgeActionDuration: edgeAction,
                strollDuration: stroll,
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: 'Ana Sayfa'),
              NavigationDestination(icon: Icon(Icons.explore), label: 'Macera'),
              NavigationDestination(
                icon: Icon(Icons.storefront),
                label: 'Mağaza',
              ),
              NavigationDestination(
                icon: Icon(Icons.sports_bar),
                label: 'Taverna',
              ),
              NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
            ],
          ),
        ),
      ),
    );
    // GIF çözümü **gerçek** asenkron iş; sahte saat onu ilerletmiyor.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 320)),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  Rect petRect(WidgetTester tester) =>
      tester.getRect(find.byKey(const ValueKey('pet-companion-sprite')));

  group('pet alt gezinme çubuğunun üstünde durur', () {
    for (final entry in devices.entries) {
      final (width, _, gestureBar) = entry.value;

      testWidgets('${entry.key}: çubuğu ve düğmelerini kapatmaz', (
        tester,
      ) async {
        await pumpShell(tester, entry.value);

        final bar = tester.getRect(find.byType(NavigationBar));
        final pet = petRect(tester);

        // Pet'in ayağı çubuğun üst kenarında; içine taşmıyor.
        expect(
          pet.bottom,
          lessThanOrEqualTo(bar.top + 0.5),
          reason: '${entry.key}: pet alt barın içine taşıyor',
        );
        // "Hemen üstünde": arada boşluk bırakmıyor.
        expect(
          pet.bottom,
          greaterThanOrEqualTo(bar.top - 1),
          reason: '${entry.key}: pet barın üstünde havada duruyor',
        );

        // Hiçbir gezinme düğmesiyle kesişmiyor.
        for (final icon in [
          Icons.home,
          Icons.explore,
          Icons.storefront,
          Icons.sports_bar,
          Icons.person,
        ]) {
          final destination = tester.getRect(find.byIcon(icon));
          expect(
            pet.overlaps(destination),
            isFalse,
            reason: '${entry.key}: pet $icon düğmesini kapatıyor',
          );
        }

        // Jest çubuğu payı çubuğun içinde kalıyor, pet onu görmüyor.
        expect(bar.bottom - bar.top, greaterThan(gestureBar));

        // Yatay sınırlar: ekran dışına çıkmıyor.
        expect(pet.left, greaterThanOrEqualTo(0));
        expect(pet.right, lessThanOrEqualTo(width));
      });

      testWidgets('${entry.key}: boyut ekranla orantılı', (tester) async {
        await pumpShell(tester, entry.value);
        final pet = petRect(tester);
        expect(pet.width, PetCompanionOverlay.spriteSizeFor(width));
        expect(pet.width, pet.height);
      });
    }

    testWidgets('boyut küçük telefondan tablete doğru büyür', (tester) async {
      expect(
        PetCompanionOverlay.spriteSizeFor(320),
        lessThan(PetCompanionOverlay.spriteSizeFor(390)),
      );
      expect(
        PetCompanionOverlay.spriteSizeFor(390),
        lessThan(PetCompanionOverlay.spriteSizeFor(800)),
      );
      // Uçlarda saçmalamıyor: küçük telefonda devasa, tablette minik değil.
      expect(PetCompanionOverlay.spriteSizeFor(240), 44);
      expect(PetCompanionOverlay.spriteSizeFor(2000), 88);
    });

    testWidgets('alt bar yokken de mantıklı bir yerde durur', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(bottom: 34);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PetCompanionOverlay(
              situation: PetSituation(context: PetContext.home),
              initialDelay: Duration(hours: 1),
            ),
          ),
        ),
      );
      await tester.pump();

      final pet = petRect(tester);
      // Çubuk yokken bile jest çubuğunun üstünde: Scaffold body'si SafeArea
      // payını zaten düşüyor.
      expect(pet.bottom, lessThanOrEqualTo(844 - 34));
      expect(pet.bottom, greaterThan(844 - 34 - 4));
    });
  });

  group('kenar animasyonları yeni sınırlarda da tetikleniyor', () {
    String spriteAsset(WidgetTester tester) {
      final image = tester.widget<Image>(
        find.descendant(
          of: find.byKey(const ValueKey('pet-companion-sprite')),
          matching: find.byType(Image),
        ),
      );
      return (image.image as AssetImage).assetName;
    }

    for (final entry in devices.entries) {
      testWidgets('${entry.key}: sol uç climb, sağ uç attack', (tester) async {
        await pumpShell(
          tester,
          entry.value,
          rest: const Duration(milliseconds: 100),
          edgeAction: const Duration(milliseconds: 100),
          stroll: const Duration(milliseconds: 200),
          initialDelay: const Duration(hours: 1),
        );
        final width = entry.value.$1;
        final margin = PetCompanionOverlay.marginFor(width);

        // Sol uçta idle ile bekliyor.
        expect(spriteAsset(tester), contains('_Idle_4.gif'));
        expect(petRect(tester).left, closeTo(margin, 0.5));

        // Sol uç gösterisi: climb.
        await tester.pump(const Duration(milliseconds: 101));
        expect(spriteAsset(tester), contains('_Climb_4.gif'));
        expect(petRect(tester).left, closeTo(margin, 0.5));

        // Karşı kenara yürüyor.
        await tester.pump(const Duration(milliseconds: 101));
        expect(spriteAsset(tester), contains('_Walk_6.gif'));

        // Sağ uçta idle.
        await tester.pump(const Duration(milliseconds: 201));
        expect(spriteAsset(tester), contains('_Idle_4.gif'));
        expect(
          petRect(tester).right,
          closeTo(width - margin, 0.5),
          reason: '${entry.key}: sağ uç sınırı ekran genişliğinden çıkmıyor',
        );

        // Sağ uç gösterisi: attack (kenar eylemi dönüşümlü).
        await tester.pump(const Duration(milliseconds: 101));
        expect(spriteAsset(tester), contains('_Attack2_6.gif'));
        expect(petRect(tester).right, closeTo(width - margin, 0.5));
      });
    }
  });

  group('golden', () {
    for (final entry in devices.entries) {
      testWidgets('${entry.key} sol uçta', (tester) async {
        await pumpShell(tester, entry.value);
        await expectLater(
          find.byType(Scaffold),
          matchesGoldenFile('goldens/pet_placement_${entry.key}_left.png'),
        );
      });
    }

    testWidgets('veda çıkışında rehber death animasyonunda', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final step = ValueNotifier(TutorialGuideStep.leaving);
      addTearDown(step.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0xFF14101F)),
                TutorialGuideOverlay(
                  step: step,
                  onPrimary: (_) {},
                  onSecondary: (_) {},
                  onLeavingCompleted: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 320)),
      );
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/tutorial_farewell_death_390.png'),
      );
    });

    testWidgets('phone_390 sağ uçta', (tester) async {
      await pumpShell(
        tester,
        devices['phone_390']!,
        rest: const Duration(milliseconds: 100),
        edgeAction: const Duration(milliseconds: 100),
        stroll: const Duration(milliseconds: 200),
        initialDelay: const Duration(hours: 1),
      );
      await tester.pump(const Duration(milliseconds: 101));
      await tester.pump(const Duration(milliseconds: 101));
      await tester.pump(const Duration(milliseconds: 201));
      await tester.pump(const Duration(milliseconds: 101));

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/pet_placement_phone_390_right.png'),
      );
    });
  });
}
