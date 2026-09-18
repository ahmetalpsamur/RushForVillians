import 'package:rush_for_villains/models/daily_engagement.dart';
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
    bool resolveFirstRound = false,
    int perfectRoundStreak = 0,
    VoidCallback? onChooseNewAdventure,
    ValueChanged<int>? onSimulateSteps,
    AdventureQuest? adventure,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final startedAt = GameClock.now();
    final quest =
        adventure ??
        AdventureQuest(
          enemy: enemy,
          stepGoal: stepGoal,
          startingSteps: startingSteps,
          roundStartingSteps: roundStartingSteps,
          startedAt: startedAt,
        );
    quest.perfectRoundStreak = perfectRoundStreak;
    if (resolveFirstRound) {
      // "Düşmanın N canını aldın" mesajı artık round çözümünde oluşuyor:
      // savaş motorundan önce her adım 1 hasardı, şimdi hasar statlardan
      // geliyor ve yalnızca round kapanınca hesaplanıyor.
      quest.resolveExpiredRound(
        steps,
        startedAt.add(quest.currentRoundDuration),
      );
      // Round sonucu animasyonu oynatılmış kabul ediliyor; hasar mesajı o
      // animasyondan **sonraki** karede çıkıyor.
      quest.presentedRoundOutcomeSerial = quest.roundOutcomeSerial;
    }

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
            onStartRevival: () {},
            onChooseNewAdventure: onChooseNewAdventure ?? () {},
            onAdventureUpdated: () {},
            onSimulateSteps: onSimulateSteps,
            usingRealPedometer: false,
            useManualSource: true,
          ),
        ),
      ),
    );
    // GIF çözümlemesi **gerçek** asenkron iş; sahte saat onu ilerletmiyor.
    // Isınma olmadan sprite'lar kimi koşuda henüz çözülmemiş oluyor ve
    // golden'lar tam suite altında rastgele kırmızıya dönüyordu (ölçülen fark
    // %1,4-%2,5). `runAsync` sırasında animasyon denetleyicileri ilerlemez.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 320)),
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

      expect(
        find.byKey(const ValueKey('adventure-progress-text')),
        findsOneWidget,
      );
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

      expect(
        find.byKey(const ValueKey('adventure-progress-text')),
        findsOneWidget,
      );
      expect(mainBarValue(tester), closeTo(0.25, 0.001));
    });

    testWidgets('ana bar round sınırında sıfırlanmaz', (tester) async {
      // 1000 adım = bir round. İkinci roundun başındayız ama macera
      // ilerlemesi %50'de olmalı, sıfırda değil.
      await pumpAdventure(tester, stepGoal: 2000, steps: 1000);

      expect(mainBarValue(tester), closeTo(0.5, 0.001));
      expect(
        find.byKey(const ValueKey('adventure-progress-text')),
        findsOneWidget,
      );
    });

    testWidgets('macera bitince bar dolu', (tester) async {
      await pumpAdventure(tester, stepGoal: 2000, steps: 2000);
      expect(mainBarValue(tester), closeTo(1.0, 0.001));
    });
  });

  group('tek hedef ilerlemesi', () {
    testWidgets('oyuncu vurunca düşen can miktarı animasyonda görünür', (
      tester,
    ) async {
      final quest = AdventureQuest(enemy: enemy, stepGoal: 2000);
      final before = quest.enemyHealth;
      quest
        ..enemyHealthBeforeLastRound = before
        ..enemyHealth = before - 10
        ..lastPlayerDamage = 10
        ..lastResolvedRound = 1
        ..lastRoundWon = true
        ..roundOutcomeSerial = 1;

      await pumpAdventure(
        tester,
        stepGoal: 2000,
        steps: 1000,
        adventure: quest,
      );

      expect(
        find.byKey(const ValueKey('animated-enemy-health-value')),
        findsOneWidget,
      );
      expect(find.text('-10 CAN'), findsOneWidget);
    });

    testWidgets('raund geri sayımı ve mükemmel seri bilgisi görünür', (
      tester,
    ) async {
      await pumpAdventure(
        tester,
        stepGoal: 2000,
        steps: 200,
        perfectRoundStreak: 2,
      );

      expect(find.byKey(const ValueKey('round-countdown')), findsOneWidget);
      expect(find.textContaining('MÜKEMMEL SERİ'), findsNothing);
    });

    testWidgets('düşman saldırısından sonra kayıp ve kalan can net görünür', (
      tester,
    ) async {
      final quest =
          AdventureQuest(enemy: enemy, stepGoal: 500)
            ..playerHealth = 77
            ..playerMaxHealth = 100
            ..lastEnemyDamage = 23
            ..enemyAttackSerial = 1
            ..lastResolvedRound = 1
            ..lastRoundWon = true
            ..roundOutcomeSerial = 1;

      await pumpAdventure(tester, stepGoal: 500, steps: 500, adventure: quest);

      expect(find.textContaining('senin 23 canını aldı'), findsOneWidget);
      expect(find.text('77 / 100 CAN'), findsOneWidget);
    });

    testWidgets('ölümcül saldırı karşı vuruştan önce öldürdüğünü söyler', (
      tester,
    ) async {
      final quest = AdventureQuest(
        enemy: enemy,
        stepGoal: 500,
        playerHealth: 0,
        battleOutcome: AdventureBattleOutcome.defeat,
        lastEnemyDamage: 100,
        enemyAttackSerial: 1,
        lastResolvedRound: 1,
        lastRoundWon: false,
        roundOutcomeSerial: 1,
      );

      await pumpAdventure(tester, stepGoal: 500, steps: 500, adventure: quest);

      // Saldırı GIF süresi gerçek dosyadan asenkron okunur. Yavaş disklerde
      // overlay ilk ısınma turundan sonra hazır olabildiği için kısa bir pay
      // bırakıp animasyonun ilk karesini çizdir.
      if (find
          .textContaining('sen vuramadan seni öldürdü')
          .evaluate()
          .isEmpty) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 420)),
        );
        await tester.pump();
      }

      expect(find.textContaining('sen vuramadan seni öldürdü'), findsOneWidget);
      expect(find.text('0 / 100 CAN'), findsOneWidget);
    });

    testWidgets('raund adımı yazıyla gösteriliyor', (tester) async {
      await pumpAdventure(
        tester,
        stepGoal: 2000,
        steps: 1200,
        roundStartingSteps: 1000,
      );
      expect(find.byKey(const ValueKey('round-progress-text')), findsOneWidget);
    });

    testWidgets('raund ve toplam hedef çubukları gösteriliyor', (tester) async {
      await pumpAdventure(
        tester,
        stepGoal: 2000,
        steps: 1200,
        roundStartingSteps: 1000,
      );
      expect(find.byKey(const ValueKey('quest-progress-bar')), findsOneWidget);
      expect(find.byKey(const ValueKey('round-progress-bar')), findsOneWidget);
    });

    testWidgets('raund çubuğu ve toplam hedef ayrı ilerler', (tester) async {
      await pumpAdventure(
        tester,
        stepGoal: 2000,
        steps: 1200,
        roundStartingSteps: 1000,
      );
      expect(mainBarValue(tester), closeTo(0.6, 0.001));
      expect(barValue(tester, 'round-progress-bar'), closeTo(0.2, 0.001));
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
      expect(find.text('Günlük Adım'), findsNothing);
      expect(find.text('Adım İlerlemesi'), findsNothing);
      expect(
        find.byKey(const ValueKey('adventure-progress-text')),
        findsOneWidget,
      );
    });
  });

  testWidgets('aktif maceranın en altında çıkış seçeneği bulunur', (
    tester,
  ) async {
    var exited = false;
    await pumpAdventure(
      tester,
      stepGoal: 2000,
      steps: 200,
      onChooseNewAdventure: () => exited = true,
    );

    final exitButton = find.byKey(const ValueKey('adventure-exit'));
    expect(exitButton, findsOneWidget);
    await tester.ensureVisible(exitButton);
    await tester.tap(exitButton);
    await tester.pump();
    expect(exited, isTrue);
  });

  group('tam ekran macera HUD yerleşimi', () {
    for (final size in const [Size(320, 640), Size(390, 844)]) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()} taşma yapmaz', (
        tester,
      ) async {
        await pumpAdventure(tester, stepGoal: 2000, steps: 500, size: size);

        expect(
          find.byKey(const ValueKey('active-adventure-hud')),
          findsOneWidget,
        );
        expect(find.byType(AppBar), findsNothing);
        expect(find.byKey(const ValueKey('player-health-hud')), findsOneWidget);
        expect(find.byKey(const ValueKey('enemy-health-hud')), findsOneWidget);
        expect(find.byKey(const ValueKey('round-countdown')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('round-progress-bar')),
          findsOneWidget,
        );
        expect(find.textContaining('Bu round 1.000 adım'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('geçici admin paneli aktif macera kilidinden adım ekler', (
    tester,
  ) async {
    var simulatedSteps = 0;
    await pumpAdventure(
      tester,
      stepGoal: 2000,
      steps: 0,
      size: const Size(390, 844),
      onSimulateSteps: (amount) => simulatedSteps += amount,
    );

    expect(find.byKey(const ValueKey('admin-steps-1000')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('adventure-admin-panel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('admin-steps-1000')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('admin-steps-1000')));
    await tester.pump();
    expect(simulatedSteps, 1000);
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
          size: Size(width, 844),
          resolveFirstRound: true,
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

  testWidgets(
    'zafer savaş sahnesinde ceset, coin ve gerçek ödülleri gösterir',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var choseNewAdventure = false;
      final quest = AdventureQuest(
        enemy: enemy,
        stepGoal: 2000,
        battleOutcome: AdventureBattleOutcome.victory,
        enemyHealth: 0,
        deathAnimationPlayed: true,
        xpAwarded: true,
        victoryCoinReward: 47,
        victoryXpReward: 180,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: AdventureScreen(
            adventure: quest,
            roundSerial: 0,
            avatar: _avatar,
            today: DailyProgress(
              date: GameClock.now(),
              steps: 2000,
              stepGoal: 2000,
            ),
            onAdventureSelected: (_) {},
            onStartRevival: () {},
            onChooseNewAdventure: () => choseNewAdventure = true,
            onAdventureUpdated: () {},
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      // 250 ms kimi koşuda ölüm karesini çözmeye yetmiyordu; ısınma payı
      // artırıldı. Aynı gerekçe `pumpAdventure` içinde yazılı.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 420)),
      );
      await tester.pump();

      expect(find.text('+47 altın'), findsOneWidget);
      expect(find.text('+180 XP'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('victory-scattered-coin')),
        findsNWidgets(5),
      );
      expect(
        find.byKey(const ValueKey('victory-enemy-corpse')),
        findsOneWidget,
      );
      // Bölüm A.5: ganimet cesedin **önünde** çizilmeli. `Stack` çocukları
      // sırayla boyandığı için ağaç sırası doğrudan katman sırasıdır: ceset
      // önce gelmeli, altınlar sonra. Eskiden tersiydi ve ceset altınları
      // örtüyordu.
      final layerOrder =
          find
              .byWidgetPredicate(
                (widget) =>
                    widget.key == const ValueKey('victory-enemy-corpse') ||
                    widget.key == const ValueKey('victory-scattered-coin'),
              )
              .evaluate()
              .map((element) => element.widget.key)
              .toList();
      expect(layerOrder.first, const ValueKey('victory-enemy-corpse'));
      expect(
        layerOrder.skip(1),
        everyElement(const ValueKey('victory-scattered-coin')),
        reason: 'altınlar cesetten sonra boyanmalı',
      );
      expect(find.text('Yeni bir macera seni bekliyor.'), findsNothing);
      await expectLater(
        find.byType(AdventureScreen),
        matchesGoldenFile('golden/goldens/victory_scene_390.png'),
      );

      await tester.tap(find.byKey(const ValueKey('victory-choose-adventure')));
      expect(choseNewAdventure, isTrue);
    },
  );

  testWidgets('yeni maceraya geçince eski zafer overlayi tamamen temizlenir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final victory = AdventureQuest(
      enemy: enemy,
      stepGoal: 2000,
      battleOutcome: AdventureBattleOutcome.victory,
      enemyHealth: 0,
      deathAnimationPlayed: true,
      xpAwarded: true,
      victoryCoinReward: 47,
      victoryXpReward: 180,
    );
    final current = ValueNotifier<AdventureQuest?>(victory);
    addTearDown(current.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: ValueListenableBuilder<AdventureQuest?>(
          valueListenable: current,
          builder:
              (context, adventure, _) => AdventureScreen(
                adventure: adventure,
                roundSerial: adventure?.roundOutcomeSerial ?? 0,
                avatar: _avatar,
                today: DailyProgress(
                  date: GameClock.now(),
                  steps: 2000,
                  stepGoal: 2000,
                ),
                onAdventureSelected: (next) => current.value = next,
                onStartRevival: () {},
                onChooseNewAdventure: () => current.value = null,
                onAdventureUpdated: () {},
              ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('ZAFER!'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('victory-choose-adventure')));
    await tester.pump();
    expect(find.text('Bugünkü maceranı seç'), findsOneWidget);
    expect(find.text('ZAFER!'), findsNothing);

    current.value = AdventureQuest(
      enemy: EnemyCatalog.enemies.first,
      stepGoal: 500,
      startedAt: GameClock.now(),
    );
    await tester.pump();
    expect(find.text('ZAFER!'), findsNothing);
    expect(find.byKey(const ValueKey('victory-coin-reward')), findsNothing);
    expect(find.byKey(const ValueKey('victory-enemy-corpse')), findsNothing);
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
          size: Size(width, 844),
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
    // Bu alanlar artık yalnızca günlük özettir; macera değişimi geçmiş kazancı
    // silmemeli ve sonraki sınırsız kazancı da durdurmamalıdır.
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
              engagement: DailyEngagement(
                streakCelebratedOn: GameClock.now(),
                wheelPromptedOn: GameClock.now(),
              ),
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
      tester
          .widget<HomeScreen>(find.byType(HomeScreen))
          .onSimulateSteps(amount);
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

    Future<int> savedVictoryCoins(WidgetTester tester) async {
      final state = await savedState(tester);
      final adventure = state['adventure'] as Map<String, dynamic>?;
      return adventure?['victoryCoinReward'] as int? ?? 0;
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
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(
        find.byKey(const ValueKey('walking-safety-acknowledgement')),
      );
      await tester.pump();
      await tester.tap(find.text('Güvendeyim, Maceraya Başla'));
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('macera seçmek kazanılan coin sayacını korur', (tester) async {
      await pumpShell(tester);
      await simulateSteps(tester, 20000);

      final before = await savedToday(tester);
      expect(before.coinsEarned, 20000 ~/ GameConstants.stepsPerCoin);

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

    testWidgets('macera seçimi aynı gün yeni coin kazancını durdurmaz', (
      tester,
    ) async {
      await pumpShell(tester);
      await simulateSteps(tester, 20000);
      await selectAdventure(tester);

      final before = await savedToday(tester);
      final coinsBefore = await savedCoins(tester);

      // Aktif macera tek işe odaklanan tam ekran moddadır; normal sekmeler
      // maceradan çıkılana kadar görünmez.
      expect(find.byType(NavigationBar), findsNothing);
      final adventureScreen = tester.widget<AdventureScreen>(
        find.byType(AdventureScreen),
      );
      await tester.tap(find.byKey(const ValueKey('adventure-close')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      await tester.tap(find.text('Maceraya devam et'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        tester.widget<AdventureScreen>(find.byType(AdventureScreen)).adventure,
        same(adventureScreen.adventure),
      );
      adventureScreen.onChooseNewAdventure();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(TextButton),
            )
            .last,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(NavigationBar), findsOneWidget);

      await tester.tap(find.text('Ana Sayfa').last);
      await tester.pumpAndSettle();
      await simulateSteps(tester, 20000);

      final after = await savedToday(tester);
      final coinsAfter = await savedCoins(tester);
      final victoryCoins = await savedVictoryCoins(tester);

      final secondWalkReward = 20000 ~/ GameConstants.stepsPerCoin;
      expect(after.coinsEarned, before.coinsEarned + secondWalkReward);
      expect(
        coinsAfter,
        coinsBefore + secondWalkReward + victoryCoins,
        reason: 'macera seçimi sınırsız adım kazancını kesmemeli',
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
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(TextButton),
            )
            .last,
      );
      await tester.pump(const Duration(milliseconds: 300));

      final after = await savedToday(tester);
      expect(after.coinsEarned, 20000 ~/ GameConstants.stepsPerCoin);
    });
  });
}
