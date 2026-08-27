import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/game_constants.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/game_clock.dart';
import 'package:rush_for_villains/data/enemy_catalog.dart';
import 'package:rush_for_villains/features/adventure/adventure_screen.dart';
import 'package:rush_for_villains/models/adventure_quest.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_progress.dart';

/// Yürüyüş fazının görsel denetimi (Bölüm A.4).
///
/// Emülatör bu makinede çalışmıyor; "savaş fazı ile yürüyüş fazı görsel
/// olarak net ayrışsın" şartı ancak golden ile görülebiliyor. İki genişlik
/// üretiliyor çünkü dar ekranda (320 dp) taşma riski en yüksek.
///
/// `pumpAndSettle` **kullanılmıyor**: sahnedeki yürüyüş animasyonu sonsuz
/// tekrar ediyor. Sabit kare dizisi hem takılmayı önlüyor hem golden'ı
/// tekrarlanabilir kılıyor.
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

  final enemy = EnemyCatalog.byId('night_oath')!;

  setUp(() {
    GameClock.reset();
    GameClock.useSource(() => DateTime(2026, 9, 1, 12));
  });
  tearDown(GameClock.reset);

  AdventureQuest walkingQuest() {
    final quest = AdventureQuest(
      enemy: enemy,
      stepGoal: 5000,
      battleOutcome: AdventureBattleOutcome.victory,
      enemyHealth: 0,
      deathAnimationPlayed: true,
      xpAwarded: true,
      victoryCoinReward: 62,
      walkCoinReward: 53,
      victoryXpReward: 220,
      victorySteps: 1000,
      victoryRounds: 1,
      walkSteps: 1600,
      startedAt: GameClock.now(),
    );
    return quest;
  }

  Future<void> pumpWalkPhase(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final quest = walkingQuest();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: AdventureScreen(
          adventure: quest,
          roundSerial: 0,
          avatar: _avatar,
          today: DailyProgress(
            date: GameClock.now(),
            steps: 2600,
            stepGoal: 5000,
          ),
          onAdventureSelected: (_) {},
          onStartRevival: () {},
          onChooseNewAdventure: () {},
          onAdventureUpdated: () {},
        ),
      ),
    );
    // GIF çözümlemesi **gerçek** asenkron iş: sahte saat onu ilerletmiyor.
    // Isınma olmadan karakter kimi koşuda henüz çözülmemiş oluyor ve golden
    // rastgele kırmızıya dönüyordu (ölçülen fark %12). `runAsync` sırasında
    // animasyon denetleyicisi ilerlemez, yani konum determinizmi bozulmaz.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 320)),
    );
    // Sabit kare dizisi: sonsuz yürüyüş animasyonu `pumpAndSettle`'ı
    // takıyor, ama kare sayısı sabit olduğu için golden tekrarlanabilir.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  Future<void> pumpGoldCollectionCompleted(
    WidgetTester tester,
    double width,
  ) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final quest = walkingQuest()..walkSteps = 4000;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: AdventureScreen(
          adventure: quest,
          roundSerial: 0,
          avatar: _avatar,
          today: DailyProgress(
            date: GameClock.now(),
            steps: 5000,
            stepGoal: 5000,
          ),
          onAdventureSelected: (_) {},
          onStartRevival: () {},
          onChooseNewAdventure: () {},
          onAdventureUpdated: () {},
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 320)),
    );
    await tester.pump(const Duration(milliseconds: 250));
  }

  testWidgets('yürüyüş fazı savaş fazından ayrışıyor', (tester) async {
    await pumpWalkPhase(tester, 390);

    // Yürüyüş fazının kendi işaretleri var...
    expect(find.byKey(const ValueKey('walk-phase-scene')), findsOneWidget);
    expect(find.byKey(const ValueKey('walk-phase-banner')), findsOneWidget);
    expect(
      find.text(
        'Yürüyüş fazı · ${GameConstants.walkPhaseStepsPerCoin} adım = 1 altın',
      ),
      findsOneWidget,
    );
    expect(find.text('1.600 / 4.000 adım — kalan 2.400'), findsOneWidget);
    expect(find.text('+53 EK ALTIN'), findsOneWidget);
    expect(
      find.text('Zafer +62 · yürüyüş +53 altın · toplam +115 altın · +220 XP'),
      findsOneWidget,
    );
    expect(
      find.text('1 round · 1.000 adımda devirdin — hız ödülü ×1.02'),
      findsOneWidget,
    );

    // ...ve savaşın hiçbir göstergesi kalmıyor.
    expect(find.text('Canavar Canı'), findsNothing);
    expect(find.text('Senin Canın'), findsNothing);
    expect(find.byKey(const ValueKey('round-progress-bar')), findsNothing);
    expect(find.byKey(const ValueKey('quest-progress-bar')), findsNothing);
  });

  testWidgets('golden: yürüyüş fazı (320 dp)', (tester) async {
    await pumpWalkPhase(tester, 320);
    await expectLater(
      find.byType(AdventureScreen),
      matchesGoldenFile('goldens/walk_phase_320.png'),
    );
  });

  testWidgets('golden: yürüyüş fazı (390 dp)', (tester) async {
    await pumpWalkPhase(tester, 390);
    await expectLater(
      find.byType(AdventureScreen),
      matchesGoldenFile('goldens/walk_phase_390.png'),
    );
  });

  testWidgets('golden: altın toplama tamamlandı (390 dp)', (tester) async {
    await pumpGoldCollectionCompleted(tester, 390);

    expect(find.text('+53 EK ALTIN'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('gold-collection-large-coin')),
      findsOneWidget,
    );
    expect(find.textContaining(enemy.name), findsNothing);
    expect(find.textContaining('XP'), findsNothing);
    await expectLater(
      find.byType(AdventureScreen),
      matchesGoldenFile('goldens/gold_collection_completed_390.png'),
    );
  });
}
