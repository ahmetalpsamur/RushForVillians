import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/game_constants.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/game_clock.dart';
import 'package:rush_for_villains/data/enemy_catalog.dart';
import 'package:rush_for_villains/features/adventure/adventure_screen.dart';
import 'package:rush_for_villains/models/adventure_quest.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/features/home/home_screen.dart';
import 'package:rush_for_villains/features/root/root_shell.dart';
import 'package:rush_for_villains/models/daily_progress.dart';
import 'package:rush_for_villains/models/game_state.dart';
import 'package:rush_for_villains/models/user_profile.dart';
import 'package:rush_for_villains/services/game_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Macera ekranındaki ilerleme göstergeleri.
///
/// Kart #2'nin (BÖLÜM 2) korunan sözü: **ana bar macera ilerlemesini gösterir
/// ve round başına sıfırlanmaz.** Round içi ilerleme kaybolmaz ama ikincil
/// kalır. Ayrıca eski bir hata bir daha geri gelmesin: "Adım İlerlemesi" barı
/// günlük sayacı gösterip macera hedefiyle etiketliyordu.
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

  final enemy = EnemyCatalog.enemies.firstWhere(
    (e) => e.minimumDailySteps >= 2000,
  );

  /// Maceralı ekranı kurar.
  ///
  /// [startingSteps] macera başlarken günlük sayacın değeri; [steps] o anki
  /// günlük sayaç. Macera ilerlemesi ikisinin farkıdır.
  Future<void> pumpAdventure(
    WidgetTester tester, {
    required int stepGoal,
    required int steps,
    int startingSteps = 0,
    int? roundStartingSteps,
    Size size = const Size(390, 1400),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final quest = AdventureQuest(
      enemy: enemy,
      stepGoal: stepGoal,
      startingSteps: startingSteps,
      roundStartingSteps: roundStartingSteps,
      startedAt: GameClock.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: AdventureScreen(
            adventure: quest,
            roundSerial: 0,
            avatar: _avatar,
            today: DailyProgress(
              date: GameClock.now(),
              steps: steps,
              stepGoal: stepGoal,
            ),
            onAdventureSelected: (_) {},
            onChooseNewAdventure: () {},
            onAdventureUpdated: () {},
          ),
        ),
      ),
    );
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Geri sayım kartındaki **ana** ilerleme çubuğunun değeri.
  double barValue(WidgetTester tester, String key) {
    final finder = find.byKey(ValueKey(key));
    expect(finder, findsOneWidget, reason: '$key bulunamadı');
    return tester.widget<LinearProgressIndicator>(finder).value!;
  }

  double mainBarValue(WidgetTester tester) =>
      barValue(tester, 'quest-progress-bar');

  group('ana bar macera ilerlemesini gösterir', () {
    testWidgets('sıfırdan başlayan macerada ilerleme adımdan çıkar', (
      tester,
    ) async {
      await pumpAdventure(tester, stepGoal: 2000, steps: 500);

      expect(find.text('500 / 2000 adım — macera ilerlemesi'), findsOneWidget);
      expect(mainBarValue(tester), closeTo(0.25, 0.001));
    });

    testWidgets('macera başlangıç adımı düşülür', (tester) async {
      // Oyuncu maceradan önce 3000 adım atmış; macera 500 adım ilerlemiş.
      await pumpAdventure(
        tester,
        stepGoal: 2000,
        steps: 3500,
        startingSteps: 3000,
      );

      expect(find.text('500 / 2000 adım — macera ilerlemesi'), findsOneWidget);
      expect(mainBarValue(tester), closeTo(0.25, 0.001));
    });

    testWidgets('ana bar round sınırında sıfırlanmaz', (tester) async {
      // 1000 adım = bir round. İkinci roundun başındayız ama macera
      // ilerlemesi %50'de olmalı, sıfırda değil.
      await pumpAdventure(tester, stepGoal: 2000, steps: 1000);

      expect(mainBarValue(tester), closeTo(0.5, 0.001));
      expect(find.text('1000 / 2000 adım — macera ilerlemesi'), findsOneWidget);
    });

    testWidgets('macera bitince bar dolu', (tester) async {
      await pumpAdventure(tester, stepGoal: 2000, steps: 2000);
      expect(mainBarValue(tester), closeTo(1.0, 0.001));
    });
  });

  group('round ilerlemesi ikincil olarak duruyor', () {
    testWidgets('round adımı yazıyla gösteriliyor', (tester) async {
      await pumpAdventure(
        tester,
        stepGoal: 2000,
        steps: 1200,
        roundStartingSteps: 1000,
      );
      expect(find.text('Bu round: 200 / 1000 adım'), findsOneWidget);
    });

    testWidgets('round çubuğu ana çubuktan ince', (tester) async {
      await pumpAdventure(
        tester,
        stepGoal: 2000,
        steps: 1200,
        roundStartingSteps: 1000,
      );
      final main = tester.widget<LinearProgressIndicator>(
        find.byKey(const ValueKey('quest-progress-bar')),
      );
      final round = tester.widget<LinearProgressIndicator>(
        find.byKey(const ValueKey('round-progress-bar')),
      );
      expect(round.minHeight!, lessThan(main.minHeight!));
    });

    testWidgets('round çubuğu round içi ilerlemeyi gösterir', (tester) async {
      // 2. round: ilk 1000 adım geride, 200 adım atılmış, hedef 1000 → %20.
      await pumpAdventure(
        tester,
        stepGoal: 2000,
        steps: 1200,
        roundStartingSteps: 1000,
      );
      expect(barValue(tester, 'round-progress-bar'), closeTo(0.2, 0.001));
      // Ana bar aynı anda %60'ta: round sıfırlansa da macera ilerlemesi durmaz.
      expect(mainBarValue(tester), closeTo(0.6, 0.001));
    });
  });

  group('"Günlük Adım" barı dürüst etiketli', () {
    testWidgets('macera hedefiyle değil günlük hedefle etiketlenir', (
      tester,
    ) async {
      await pumpAdventure(
        tester,
        stepGoal: 2000,
        steps: 3500,
        startingSteps: 3000,
      );

      // Eski hata: etiket "Adım İlerlemesi" idi ve `3500 / 2000` yazıyordu —
      // hem hedefi aşan bir sayı hem de macera ilerlemesiyle çelişen bir değer.
      expect(find.text('Günlük Adım'), findsOneWidget);
      expect(find.text('3500 / 2000 adım'), findsOneWidget);
      expect(find.text('Adım İlerlemesi'), findsNothing);
    });
  });

  group('hasar mesajı savaş sahnesini örtmez', () {
    // Bulunan hata (Bölüm 6): "Düşmanın N canını aldın" mesajı `titleLarge`
    // ile ve satır sınırı olmadan çiziliyordu. 320 dp'de sahne genişliği
    // ~256 px; mesaj **altı satıra** çıkıp oyuncuyu da düşmanı da örtüyordu
    // (bkz. `golden/goldens/adventure_320.png`). Sahne 260 px yüksekliğinde,
    // yani mesaj tek başına yarısını kaplıyordu.
    for (final width in const [320.0, 390.0]) {
      testWidgets('${width.toInt()} dp: mesaj sahnenin dörtte birini aşmaz', (
        tester,
      ) async {
        await pumpAdventure(
          tester,
          stepGoal: 2000,
          steps: 1342,
          startingSteps: 0,
          size: Size(width, 1500),
        );

        final message = find.textContaining('canını aldın');
        expect(message, findsOneWidget);
        final height = tester.getSize(message).height;
        expect(
          height,
          lessThanOrEqualTo(65),
          reason:
              'Sahne 260 px; hasar mesajı 65 px üstüne çıkarsa karakterlerin '
              'üstüne biniyor (ölçülen: $height)',
        );
      });
    }
  });

  group('golden', () {
    for (final width in const [320.0, 390.0]) {
      testWidgets('golden: macera ilerlemesi (${width.toInt()} dp)', (
        tester,
      ) async {
        await pumpAdventure(
          tester,
          stepGoal: 2000,
          steps: 1342,
          startingSteps: 0,
          size: Size(width, 1500),
        );
        await expectLater(
          find.byType(AdventureScreen),
          matchesGoldenFile('golden/goldens/adventure_${width.toInt()}.png'),
        );
      });
    }
  });

  group('macera seçimi günlük kazanç sayaçlarını yakmaz', () {
    // Eski hata: `_selectAdventure` ve `_chooseNewAdventure` yeni bir
    // `DailyProgress` kurup `coinsEarned` / `xpEarned` alanlarını taşımıyordu.
    // `coinsEarned` günlük para tavanının sayacı olduğu için macera seçmek
    // tavanı sıfırlıyordu: oyuncu macera değiştirerek günde sınırsız coin
    // kazanabiliyordu.
    const storageKey = 'game_state_v1';

    Future<void> pumpShell(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: RootShell(
            avatar: _avatar,
            initialState: GameState(
              profile: UserProfile(avatar: _avatar, level: 50),
              today: DailyProgress(date: GameClock.now()),
            ),
            onAvatarChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    Future<void> simulateSteps(WidgetTester tester, int amount) async {
      await tester.tap(
        find.descendant(
          of: find.byType(HomeScreen),
          matching: find.text('+$amount adım'),
        ),
      );
      await tester.pump();
    }

    /// Diske yazılmış oyun durumunu okur.
    ///
    /// `GameStorage.scheduleSave` yazmayı [GameStorage.writeInterval] kadar
    /// geciktiriyor; okumadan önce zamanı ilerletip bekleyen yazmayı
    /// tetiklemek gerekiyor.
    Future<Map<String, dynamic>> savedState(WidgetTester tester) async {
      await tester.pump(GameStorage.writeInterval + const Duration(seconds: 1));
      await tester.pump();
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      expect(raw, isNotNull, reason: 'oyun durumu diske yazılmalı');
      final envelope = jsonDecode(raw!) as Map<String, dynamic>;
      return envelope['state'] as Map<String, dynamic>;
    }

    Future<DailyProgress> savedToday(WidgetTester tester) async {
      final state = await savedState(tester);
      return DailyProgress.fromJson(state['today'] as Map<String, dynamic>);
    }

    Future<int> savedCoins(WidgetTester tester) async {
      final state = await savedState(tester);
      return (state['profile'] as Map<String, dynamic>)['coins'] as int;
    }

    /// Macera sekmesindeki ekranın seçim geri çağrısını doğrudan tetikler.
    Future<void> selectAdventure(WidgetTester tester) async {
      await tester.tap(find.text('Macera').last);
      await tester.pumpAndSettle();
      final screen = tester.widget<AdventureScreen>(
        find.byType(AdventureScreen),
      );
      screen.onAdventureSelected(
        AdventureQuest(
          enemy: enemy,
          stepGoal: enemy.minimumDailySteps,
          startingSteps: 20000,
          startedAt: GameClock.now(),
        ),
      );
      await tester.pump();
    }

    testWidgets('macera seçmek kazanılan coin sayacını korur', (tester) async {
      await pumpShell(tester);
      await simulateSteps(tester, 20000);

      final before = await savedToday(tester);
      expect(before.coinsEarned, GameConstants.maxDailyStepCoins);

      await selectAdventure(tester);

      final after = await savedToday(tester);
      expect(
        after.coinsEarned,
        before.coinsEarned,
        reason: 'macera seçmek günlük para sayacını sıfırlamamalı',
      );
      expect(after.xpEarned, before.xpEarned);
      expect(after.steps, before.steps, reason: 'adımlar da korunmalı');
    });

    testWidgets('macera seçerek günlük para tavanı aşılamaz', (tester) async {
      await pumpShell(tester);
      await simulateSteps(tester, 20000);
      await selectAdventure(tester);

      final atCap = await savedToday(tester);
      final coinsAtCap = await savedCoins(tester);

      // Tavan dolu; macera seçildikten sonra atılan adımlar para vermemeli.
      await tester.tap(find.text('Ana Sayfa').last);
      await tester.pumpAndSettle();
      await simulateSteps(tester, 20000);

      final after = await savedToday(tester);
      final coinsAfter = await savedCoins(tester);

      expect(after.coinsEarned, atCap.coinsEarned);
      expect(
        coinsAfter,
        coinsAtCap,
        reason: 'tavan dolduktan sonra macera seçmek yeni para açmamalı',
      );
    });

    testWidgets('macerayı bırakmak da sayaçları korur', (tester) async {
      await pumpShell(tester);
      await simulateSteps(tester, 20000);
      await selectAdventure(tester);

      final screen = tester.widget<AdventureScreen>(
        find.byType(AdventureScreen),
      );
      screen.onChooseNewAdventure();
      await tester.pump();

      final after = await savedToday(tester);
      expect(after.coinsEarned, GameConstants.maxDailyStepCoins);
    });
  });
}
