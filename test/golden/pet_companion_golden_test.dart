import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/data/mock_data.dart';
import 'package:rush_for_villains/data/pet_sayings.dart';
import 'package:rush_for_villains/features/team/team_screen.dart';
import 'package:rush_for_villains/features/tutorial/pet_companion.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_progress.dart';
import 'package:rush_for_villains/models/tutorial_guide_variant.dart';
import 'package:rush_for_villains/models/user_profile.dart';
import 'package:rush_for_villains/services/character_catalog.dart';
import 'package:rush_for_villains/widgets/hero_progress_rings.dart';

/// Dolaşan rehberin ve Taverna karşılamasının görsel denetimi (Bölüm D).
///
/// Emülatör bu makinede çalışmıyor; baloncuğun dar ekranda taşıp taşmadığı,
/// rehberin alt gezinme çubuğunun üstünde kalıp kalmadığı ve Taverna
/// kartının sığıp sığmadığı ancak golden ile görülebiliyor.
///
/// Test ortamında gerçek font yok, yazılar dolu kutu çiziliyor — hizalama
/// denetimi için **en kötü durum**.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpCompanion(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Color(0xFF14101F)),
              const PetCompanionOverlay(
                // En uzun cümlenin çıktığı bağlam: baloncuk en kötü
                // genişliğinde ölçülüyor.
                situation: PetSituation(context: PetContext.tavern),
                initialDelay: Duration.zero,
                bottomInset: 40,
              ),
            ],
          ),
        ),
      ),
    );
    // GIF çözümü **gerçek** asenkron iş; sahte saat onu ilerletmiyor.
    // Kısa bir gerçek zaman ısınması golden'ı kararlı kılıyor.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 320)),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  for (final width in [320.0, 390.0]) {
    testWidgets('dolaşan rehber ${width.toInt()} dp', (tester) async {
      await pumpCompanion(tester, width);

      expect(
        find.byKey(const ValueKey('pet-companion-bubble')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('pet-companion-sprite')),
        findsOneWidget,
      );

      await expectLater(
        find.byType(PetCompanionOverlay),
        matchesGoldenFile('goldens/pet_companion_${width.toInt()}.png'),
      );
    });
  }

  testWidgets('taverna karşılaması 320 dp', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: TeamScreen(team: MockData.defaultTeam()),
      ),
    );
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(find.text('Taverna'), findsOneWidget);
    expect(find.text(PetSayings.tavernTeaser), findsOneWidget);

    await expectLater(
      find.byType(TeamScreen),
      matchesGoldenFile('goldens/tavern_320.png'),
    );
  });

  for (final enabled in [true, false]) {
    testWidgets('ana çember pet düğmesi ${enabled ? 'açık' : 'kapalı'}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 620);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final profile = UserProfile(
        avatar: const AvatarProfile(
          name: 'Gakai',
          age: 24,
          weight: 72,
          gender: 'Erkek',
          characterClass: 'Knight',
          characterAsset:
              'lib/All_Assets/Avatars/Classes/Characters(100x100 split)/Knight/Knight/Knight_Walk.gif',
        ),
        level: 1,
      );
      CharacterCatalog.reset(const []);
      addTearDown(CharacterCatalog.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: HeroProgressRings(
                  profile: profile,
                  today: DailyProgress(
                    date: DateTime(2026, 8, 27),
                    stepGoal: 20000,
                  ),
                  petGuide: TutorialGuideVariant.kupkuzu,
                  petEnabled: enabled,
                  onTogglePet: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 260)),
      );
      await tester.pump();

      await expectLater(
        find.byType(HeroProgressRings),
        matchesGoldenFile(
          'goldens/home_pet_toggle_${enabled ? 'active' : 'inactive'}_390.png',
        ),
      );
    });
  }
}
