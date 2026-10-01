import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/game_clock.dart';
import 'package:rush_for_villains/features/adventure/endless_run_screen.dart';
import 'package:rush_for_villains/features/root/root_shell.dart';
import 'package:rush_for_villains/l10n/app_localizations.dart';
import 'package:rush_for_villains/data/enemy_catalog.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_progress.dart';
import 'package:rush_for_villains/models/endless_run.dart';
import 'package:rush_for_villains/models/game_state.dart';
import 'package:rush_for_villains/models/user_profile.dart';
import 'package:rush_for_villains/services/item_catalog.dart';
import 'package:rush_for_villains/widgets/combat_hud.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sonsuz Koşu savaş ekranı (Bölüm D / Faz 2).
///
/// Ölçülen üç şey:
/// 1. Ekran normal macera savaş ekranıyla **aynı bileşenleri** kullanıyor
///    (iki taraflı can çubuğu, alt panel, arka plan katmanı).
/// 2. Koşu sürerken **sekme değiştirilemiyor** — alt gezinme çubuğu hiç
///    çizilmiyor, normal maceradaki `fullscreenAdventure` mekanizmasının
///    aynısı.
/// 3. Geri sayan süre **görünmüyor** (GD106); mantık aynen işliyor ama
///    sayaç çizilmiyor. Normal macerada görünmeye devam ediyor.
const _avatar = AvatarProfile(
  name: 'Barca',
  age: 28,
  weight: 74,
  gender: 'Erkek',
  characterClass: 'Swordsman',
  characterAsset:
      'lib/All_Assets/Avatars/Classes/Characters(100x100 split)/Swordsman/Swordsman/Swordsman_Walk.gif',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var shellSerial = 0;
  late DateTime now;

  setUp(() {
    GameClock.reset();
    now = DateTime(2026, 9, 1, 12);
    GameClock.useSource(() => now);
  });
  tearDown(GameClock.reset);

  EndlessRun activeRun({int cutCount = 3}) {
    return EndlessRun(
      enemy: EnemyCatalog.byId(EndlessRun.enemyId)!,
      startedAt: now,
      cutCount: cutCount,
      bankedCoins: 140,
      bankedXp: 320,
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    required EndlessRun run,
    double width = 390,
    Locale locale = const Locale('tr'),
  }) async {
    tester.view.physicalSize = Size(width, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: EndlessRunScreen(
          run: run,
          avatar: _avatar,
          onFinish: () {},
          onClose: () {},
        ),
      ),
    );
    await tester.pump();
  }

  group('savaş HUD\'u normal macerayla paylaşılıyor', () {
    testWidgets('iki taraflı can çubuğu ve alt panel var', (tester) async {
      await pumpScreen(tester, run: activeRun());

      expect(find.byType(CombatHudBackdrop), findsOneWidget);
      expect(find.byType(CombatHudPanel), findsOneWidget);
      // Oyuncu **ve** canavar: eskiden yalnızca oyuncu çubuğu vardı.
      expect(find.byType(CombatHudHealthBar), findsNWidgets(2));
      expect(
        find.byKey(const ValueKey('endless-player-health')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('endless-monster-health')),
        findsOneWidget,
      );
    });

    testWidgets('kesim başlığı ve çarpan HUD içinde', (tester) async {
      await pumpScreen(tester, run: activeRun(cutCount: 7));

      expect(find.byKey(const ValueKey('endless-cut-header')), findsOneWidget);
      expect(find.byKey(const ValueKey('endless-multiplier')), findsOneWidget);
      // Çarpan ayrı bir şerit değil, üst şeridin içinde — normal maceranın
      // geri sayımıyla aynı yerde.
      expect(find.byKey(const ValueKey('endless-cut-progress')), findsOneWidget);
    });

    testWidgets('aktif koşuda AppBar yok', (tester) async {
      await pumpScreen(tester, run: activeRun());
      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('biten koşunun sonuç perdesinde AppBar geri gelir', (
      tester,
    ) async {
      final run = activeRun();
      run.bank();
      await pumpScreen(tester, run: run);
      expect(find.byType(AppBar), findsOneWidget);
    });
  });

  group('geri sayım gizli (GD106)', () {
    testWidgets('sonsuz koşuda sayaç çizilmiyor', (tester) async {
      final run = activeRun();
      await pumpScreen(tester, run: run);

      expect(find.byKey(const ValueKey('round-countdown')), findsNothing);
      // Mantık aynen duruyor: model hâlâ geri sayımı hesaplıyor.
      expect(
        run.countdownRemaining(now).inSeconds,
        greaterThan(0),
        reason: 'süre mantığı değişmemeli, yalnızca gösterilmemeli',
      );
    });

    testWidgets('görünen tek ilerleme adım', (tester) async {
      await pumpScreen(tester, run: activeRun());
      expect(find.byKey(const ValueKey('endless-cut-text')), findsOneWidget);
      expect(find.byKey(const ValueKey('endless-cut-progress')), findsOneWidget);
    });
  });

  group('navigasyon kilidi', () {
    Future<void> pumpShell(
      WidgetTester tester, {
      EndlessRun? run,
    }) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      ItemCatalog.reset(const []);
      addTearDown(ItemCatalog.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: RootShell(
            key: ValueKey('endless-shell-${shellSerial++}'),
            avatar: _avatar,
            initialState: GameState(
              profile: UserProfile(avatar: _avatar, level: 6),
              today: DailyProgress(date: GameClock.now(), stepGoal: 6000),
              endlessRun: run,
            ),
            onAvatarChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('koşu sürerken alt gezinme çubuğu yok', (tester) async {
      await pumpShell(tester, run: activeRun());
      expect(
        find.byType(NavigationBar),
        findsNothing,
        reason: 'sekme değiştirilememeli',
      );
      expect(find.byType(EndlessRunScreen), findsOneWidget);
    });

    testWidgets('koşu yokken çubuk duruyor', (tester) async {
      await pumpShell(tester);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('koşu bitince çubuk geri gelir', (tester) async {
      final run = activeRun();
      run.bank();
      await pumpShell(tester, run: run);
      expect(
        find.byType(NavigationBar),
        findsOneWidget,
        reason: 'sonuç perdesinden çıkış olmalı',
      );
    });
  });

  group('golden: iki dilde 320 ve 390 dp', () {
    // §5.3: bu makinede uygulama çalıştırılamıyor, görsel doğrulama
    // yalnızca golden ile mümkün.
    for (final locale in const [Locale('tr'), Locale('en')]) {
      for (final width in const [320.0, 390.0]) {
        testWidgets(
          'golden (${locale.languageCode} ${width.toInt()} dp)',
          (tester) async {
            await pumpScreen(
              tester,
              run: activeRun(cutCount: 18),
              width: width,
              locale: locale,
            );
            await expectLater(
              find.byType(EndlessRunScreen),
              matchesGoldenFile(
                'golden/goldens/endless_hud_'
                '${locale.languageCode}_${width.toInt()}.png',
              ),
            );
          },
        );
      }
    }
  });

  group('iki dilde 320 ve 390 dp', () {
    for (final locale in const [Locale('tr'), Locale('en')]) {
      for (final width in const [320.0, 390.0]) {
        testWidgets(
          'taşma yok (${locale.languageCode} ${width.toInt()} dp)',
          (tester) async {
            final errors = <String>[];
            final previous = FlutterError.onError;
            FlutterError.onError = (details) {
              if (errors.length < 2) errors.add(details.exceptionAsString());
            };
            addTearDown(() => FlutterError.onError = previous);

            await pumpScreen(
              tester,
              run: activeRun(cutCount: 18),
              width: width,
              locale: locale,
            );

            expect(find.byType(CombatHudPanel), findsOneWidget);
            expect(errors, isEmpty, reason: errors.join(' | '));
          },
        );
      }
    }
  });
}
