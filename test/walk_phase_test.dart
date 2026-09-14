import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/game_constants.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/coin_calculator.dart';
import 'package:rush_for_villains/core/utils/game_clock.dart';
import 'package:rush_for_villains/data/enemy_catalog.dart';
import 'package:rush_for_villains/features/adventure/adventure_screen.dart';
import 'package:rush_for_villains/features/home/home_screen.dart';
import 'package:rush_for_villains/features/root/root_shell.dart';
import 'package:rush_for_villains/models/adventure_quest.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_progress.dart';
import 'package:rush_for_villains/models/game_state.dart';
import 'package:rush_for_villains/models/user_profile.dart';
import 'package:rush_for_villains/services/game_storage.dart';
import 'package:rush_for_villains/services/item_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Macera iki fazlı: **savaş** düşman devrilene kadar, **yürüyüş** ondan sonra
/// adım taahhüdü bitene kadar (Bölüm A).
///
/// Burada ölçülen: faz geçişi, hız ödülü ve tavanı, yürüyüş fazının 30/1
/// oranı ve faz bitince 50/1'e dönüş, çift sayma olmaması, seri/çark
/// tetikleyicisi ve kalıcılık.
const _avatar = AvatarProfile(
  name: 'Barca',
  age: 28,
  weight: 74,
  gender: 'Erkek',
  characterClass: 'Swordsman',
  characterAsset:
      'lib/All_Assets/Avatars/Classes/Characters(100x100 split)/Swordsman/Swordsman/Swordsman_Walk.gif',
);

const _storageKey = 'game_state_v1';

AdventureQuest _quest({
  int stepGoal = 2000,
  int startingSteps = 0,
  DateTime? startedAt,
}) => AdventureQuest(
  enemy: EnemyCatalog.byId('night_oath')!,
  stepGoal: stepGoal,
  startingSteps: startingSteps,
  startedAt: startedAt ?? DateTime(2026, 9, 1, 12),
);

/// Zaferi elle damgalar: motoru çalıştırmadan faz kurallarını ölçmek için.
AdventureQuest _victorious({
  int stepGoal = 2000,
  required int victorySteps,
  int round = 1,
  bool alreadyRewarded = false,
}) {
  final quest = _quest(stepGoal: stepGoal);
  quest.battleOutcome = AdventureBattleOutcome.victory;
  quest.stampVictory(questStepsAtVictory: victorySteps, round: round);
  // Kabuk testlerinde zafer ödülü ölçümün dışında tutulur: para hesabı
  // yalnızca yürüyüş oranını ölçmeli. Ödülün kendisi
  // `combat_persistence_test.dart` içinde ölçülüyor.
  quest.xpAwarded = alreadyRewarded;
  return quest;
}

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

  group('A.1 faz yapısı', () {
    test('savaş sürerken faz combat', () {
      final quest = _quest();
      expect(quest.phase, AdventureQuestPhase.combat);
      expect(quest.isWalkPhaseActive, isFalse);
      expect(quest.isAdventureCompleted, isFalse);
      expect(quest.hasVictoryStamp, isFalse);
    });

    test('erken zafer yürüyüş fazını açar, macera bitmez', () {
      final quest = _victorious(stepGoal: 2000, victorySteps: 800);

      expect(quest.isEnemyDefeated, isTrue);
      expect(quest.phase, AdventureQuestPhase.walk);
      expect(quest.walkTargetSteps, 1200);
      expect(quest.walkRemainingSteps, 1200);
      expect(
        quest.isAdventureCompleted,
        isFalse,
        reason: 'düşman öldü diye macera bitmez; adım taahhüdü sürüyor',
      );
    });

    test('taahhüt dolduktan sonraki zafer yürüyüş fazı açmaz', () {
      final quest = _victorious(stepGoal: 2000, victorySteps: 2000, round: 2);

      expect(quest.walkTargetSteps, 0);
      expect(quest.phase, AdventureQuestPhase.completed);
      expect(quest.isAdventureCompleted, isTrue);
    });

    test('yürüyüş adımları hedefe kadar birikir, sonra macera tamamlanır', () {
      final quest = _victorious(stepGoal: 2000, victorySteps: 500);

      expect(quest.addWalkSteps(400), 400);
      expect(quest.walkProgress, closeTo(400 / 1500, 0.0001));
      expect(quest.phase, AdventureQuestPhase.walk);

      // Hedefin üstünü kabul etmez; artan adım yürüyüşe yazılmaz.
      expect(quest.addWalkSteps(5000), 1100);
      expect(quest.walkSteps, 1500);
      expect(quest.walkRemainingSteps, 0);
      expect(quest.phase, AdventureQuestPhase.completed);
      expect(quest.addWalkSteps(100), 0);
    });

    test('savaş sürerken yürüyüş adımı kabul edilmez', () {
      final quest = _quest();
      expect(quest.addWalkSteps(500), 0);
      expect(quest.walkSteps, 0);
    });

    test('yenilgi kendi fazlarını korur, yürüyüş fazına düşmez', () {
      final quest = _quest();
      quest.battleOutcome = AdventureBattleOutcome.defeat;
      expect(quest.phase, AdventureQuestPhase.revival);
      expect(quest.isWalkPhaseActive, isFalse);
      quest.startRevival();
      quest.addRevivalSteps(AdventureQuest.revivalStepTarget);
      expect(quest.phase, AdventureQuestPhase.revivalCompleted);
    });

    test('zafer damgası ikinci kez yazılmaz', () {
      final quest = _victorious(stepGoal: 2000, victorySteps: 400);
      quest.stampVictory(questStepsAtVictory: 1900, round: 5);
      expect(quest.victorySteps, 400);
      expect(quest.victoryRounds, 1);
    });
  });

  group('A.2 hız ödülü', () {
    test('tam hedefte devirmek taban çarpanı verir', () {
      final quest = _victorious(stepGoal: 2000, victorySteps: 2000, round: 2);
      expect(quest.speedRewardMultiplier, 1.0);
    });

    test('hiç adım harcamadan devirmek tavana dayanır', () {
      final quest = _victorious(stepGoal: 2000, victorySteps: 0);
      expect(
        quest.speedRewardMultiplier,
        GameConstants.maxVictorySpeedMultiplier,
      );
    });

    test('çarpan tavanı hiçbir girdide aşmaz', () {
      for (final steps in [-500, 0, 1, 999, 2000, 999999]) {
        final quest = _victorious(stepGoal: 2000, victorySteps: steps);
        expect(
          quest.speedRewardMultiplier,
          inInclusiveRange(1.0, GameConstants.maxVictorySpeedMultiplier),
        );
      }
    });

    test('erken devirmek çarpanı doğrusal büyütür', () {
      double multiplierAt(int steps) =>
          _victorious(
            stepGoal: 2000,
            victorySteps: steps,
          ).speedRewardMultiplier;

      // Bonus aralığı artık dar: en erken zafer bile en fazla ×1,02.
      expect(multiplierAt(400), closeTo(1.016, 0.0001));
      expect(multiplierAt(1000), closeTo(1.01, 0.0001));
      expect(multiplierAt(1600), closeTo(1.004, 0.0001));
      expect(multiplierAt(400), greaterThan(multiplierAt(1000)));
    });

    test('zafer altını tohumlu ve tekrarlanabilir', () {
      final a = _quest();
      final b = _quest();
      expect(
        a.victoryCoinRoll(minimum: 10, maximum: 40),
        b.victoryCoinRoll(minimum: 10, maximum: 40),
        reason: 'aynı macera her zaman aynı çekilişi vermeli',
      );
      expect(
        a.victoryCoinRoll(minimum: 10, maximum: 40),
        inInclusiveRange(10, 40),
      );
      // Farklı maceralar farklı çekiliş üretebilmeli; sabit bir sayı değil.
      final rolls = {
        for (var i = 0; i < 40; i++)
          _quest(
            startingSteps: i * 37,
          ).victoryCoinRoll(minimum: 10, maximum: 40),
      };
      expect(rolls.length, greaterThan(1));
    });
  });

  group('A.3 yürüyüş fazı kazanç oranı', () {
    test('yürüyüş oranı normal orandan yüksek', () {
      expect(
        GameConstants.walkPhaseStepsPerCoin,
        lessThan(GameConstants.stepsPerCoin),
      );
    });

    test('30 adım = 1 coin, artık adımlar tüketilmez', () {
      final reward = calculateStepCoins(
        pendingSteps: 95,
        stepsPerCoin: GameConstants.walkPhaseStepsPerCoin,
      );
      expect(reward.coins, 3);
      expect(reward.consumedSteps, 90);
    });

    test('oran verilmezse normal oran kullanılır', () {
      final reward = calculateStepCoins(pendingSteps: 95);
      expect(reward.coins, 1);
      expect(reward.consumedSteps, 50);
    });

    test('aynı adım yürüyüş oranında daha çok coin eder', () {
      final normal = calculateStepCoins(pendingSteps: 3000).coins;
      final walking =
          calculateStepCoins(
            pendingSteps: 3000,
            stepsPerCoin: GameConstants.walkPhaseStepsPerCoin,
          ).coins;
      expect(normal, 60);
      expect(walking, 100);
      expect(walking, greaterThan(normal));
    });
  });

  group('A.6 seri ve çark tetikleyicisi', () {
    test('zafer çarkı adım eşiğine ulaşmadan açar', () {
      final today = DailyProgress(date: now, steps: 10);
      expect(today.isWheelUnlocked, isFalse);
      today.enemyDefeated = true;
      expect(today.isWheelUnlocked, isTrue);
    });

    test('adım eşiği hâlâ tek başına yeter', () {
      final today = DailyProgress(
        date: now,
        steps: GameConstants.dailyWheelUnlockSteps,
      );
      expect(today.enemyDefeated, isFalse);
      expect(today.isWheelUnlocked, isTrue);
    });

    test('zafer bayrağı kayıt turunda korunur', () {
      final today = DailyProgress(date: now, steps: 120, enemyDefeated: true);
      final restored = DailyProgress.fromJson(
        jsonDecode(jsonEncode(today.toJson())) as Map<String, dynamic>,
      );
      expect(restored.enemyDefeated, isTrue);
      expect(restored.isWheelUnlocked, isTrue);
    });

    test('eski kayıtta bayrak yoksa varsayılan false', () {
      final restored = DailyProgress.fromJson({
        'date': now.toIso8601String(),
        'steps': 10,
      });
      expect(restored.enemyDefeated, isFalse);
    });
  });

  group('kalıcılık', () {
    test('yürüyüş fazı kayıt turunda korunur', () {
      final quest = _victorious(stepGoal: 3000, victorySteps: 900, round: 2);
      quest.addWalkSteps(700);

      final restored = AdventureQuest.fromJson(
        jsonDecode(jsonEncode(quest.toJson())) as Map<String, dynamic>,
        enemy: quest.enemy,
      );
      expect(restored.victorySteps, 900);
      expect(restored.victoryRounds, 2);
      expect(restored.walkSteps, 700);
      expect(restored.walkRemainingSteps, 1400);
      expect(restored.phase, AdventureQuestPhase.walk);
      expect(restored.speedRewardMultiplier, quest.speedRewardMultiplier);
    });

    test(
      'zafer damgası olmayan eski kayıt yürüyüş fazına geriye dönük sokulmaz',
      () {
        // v16 ve öncesi: `victorySteps` / `walkSteps` anahtarları yok.
        final legacy =
            _quest(stepGoal: 5000).toJson()
              ..['battleOutcome'] = AdventureBattleOutcome.victory.name
              ..remove('victorySteps')
              ..remove('victoryRounds')
              ..remove('walkSteps');

        final restored = AdventureQuest.fromJson(
          jsonDecode(jsonEncode(legacy)) as Map<String, dynamic>,
          enemy: EnemyCatalog.byId('night_oath')!,
        );
        expect(restored.isEnemyDefeated, isTrue);
        expect(restored.victorySteps, 5000);
        expect(restored.walkTargetSteps, 0);
        expect(restored.isAdventureCompleted, isTrue);
        expect(restored.speedRewardMultiplier, 1.0);
      },
    );

    test('aktif macerada zafer alanları sıfır kalır', () {
      final quest = _quest();
      final restored = AdventureQuest.fromJson(
        jsonDecode(jsonEncode(quest.toJson())) as Map<String, dynamic>,
        enemy: quest.enemy,
      );
      expect(restored.hasVictoryStamp, isFalse);
      expect(restored.walkSteps, 0);
    });
  });

  group('RootShell akışı', () {
    Future<UserProfile> pumpShell(
      WidgetTester tester, {
      required UserProfile profile,
      AdventureQuest? adventure,
      DailyProgress? today,
    }) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      ItemCatalog.reset(const []);
      addTearDown(ItemCatalog.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: RootShell(
            key: ValueKey('walk-shell-${shellSerial++}'),
            avatar: _avatar,
            initialState: GameState(
              profile: profile,
              today:
                  today ??
                  DailyProgress(
                    date: GameClock.now(),
                    stepGoal: adventure?.stepGoal ?? 6000,
                  ),
              adventure: adventure,
            ),
            onAvatarChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      return profile;
    }

    Future<void> addSteps(WidgetTester tester, int amount) async {
      final adventureScreen = find.byType(AdventureScreen);
      if (adventureScreen.evaluate().isNotEmpty) {
        tester.widget<AdventureScreen>(adventureScreen).onSimulateSteps!(
          amount,
        );
      } else {
        tester
            .widget<HomeScreen>(find.byType(HomeScreen))
            .onSimulateSteps(amount);
      }
      await tester.pump();
      await tester.pump();
    }

    testWidgets('yürüyüş fazında adımlar 30/1 oranıyla paraya döner', (
      tester,
    ) async {
      final quest = _victorious(
        stepGoal: 20000,
        victorySteps: 0,
        alreadyRewarded: true,
      );
      final profile = await pumpShell(
        tester,
        profile: UserProfile(avatar: _avatar, level: 4),
        adventure: quest,
      );
      final coinsBefore = profile.coins;

      await addSteps(tester, 1000);

      expect(quest.walkSteps, 1000);
      expect(
        profile.coins - coinsBefore,
        1000 ~/ GameConstants.walkPhaseStepsPerCoin,
        reason: 'yürüyüş fazında 30 adım 1 coin etmeli',
      );
      expect(
        quest.walkCoinReward,
        profile.coins - coinsBefore,
        reason: 'fazda kazanılan ek altın macera özetinde izlenmeli',
      );
    });

    testWidgets('faz bitince oran 50/1e döner', (tester) async {
      // Yürüyüş hedefi tam 1000 adım: ilk parti fazı bitirir, ikincisi normal.
      final quest = _victorious(
        stepGoal: 20000,
        victorySteps: 19000,
        round: 5,
        alreadyRewarded: true,
      );
      final profile = await pumpShell(
        tester,
        profile: UserProfile(avatar: _avatar, level: 4),
        adventure: quest,
      );

      final beforeWalk = profile.coins;
      await addSteps(tester, 1000);
      expect(quest.isAdventureCompleted, isTrue);
      expect(
        profile.coins - beforeWalk,
        1000 ~/ GameConstants.walkPhaseStepsPerCoin,
      );

      final afterWalk = profile.coins;
      await addSteps(tester, 1000);
      expect(
        profile.coins - afterWalk,
        1000 ~/ GameConstants.stepsPerCoin,
        reason: 'macera bitince oran normale dönmeli',
      );
    });

    testWidgets('faz sınırını geçen parti çift saymaz', (tester) async {
      // Yürüyüş hedefi 1000; parti 5000. 1000 adım bonuslu, 4000 normal.
      final quest = _victorious(
        stepGoal: 20000,
        victorySteps: 19000,
        round: 5,
        alreadyRewarded: true,
      );
      final profile = await pumpShell(
        tester,
        profile: UserProfile(avatar: _avatar, level: 4),
        adventure: quest,
      );
      final before = profile.coins;

      await addSteps(tester, 5000);

      expect(quest.walkSteps, 1000);
      expect(
        profile.coins - before,
        (1000 ~/ GameConstants.walkPhaseStepsPerCoin) +
            (4000 ~/ GameConstants.stepsPerCoin),
      );
      // İşaretçi yalnızca **tüketilen** adım kadar ilerler, raporlanan kadar
      // değil: bonuslu geçiş 990 adım (33 x 30), normal geçiş 4000 adım
      // (80 x 50) tüketti. Kalan 10 adım yanmaz, sonraki hesaba devreder.
      expect(profile.lastRewardedStepCount, 4990);
      expect(profile.totalSteps, 5000);
    });

    testWidgets('aynı adım ikinci kez paraya çevrilmez', (tester) async {
      final quest = _victorious(
        stepGoal: 20000,
        victorySteps: 0,
        alreadyRewarded: true,
      );
      final profile = await pumpShell(
        tester,
        profile: UserProfile(avatar: _avatar, level: 4),
        adventure: quest,
      );

      await addSteps(tester, 1000);
      final afterFirst = profile.coins;
      await tester.pump();
      await tester.pump();
      expect(profile.coins, afterFirst);
      expect(quest.walkSteps, 1000);
    });

    testWidgets('yürüyüş fazı diske yazılır', (tester) async {
      final quest = _victorious(
        stepGoal: 20000,
        victorySteps: 0,
        alreadyRewarded: true,
      );
      await pumpShell(
        tester,
        profile: UserProfile(avatar: _avatar, level: 4),
        adventure: quest,
      );
      await addSteps(tester, 1000);
      await tester.pump(GameStorage.writeInterval);
      await tester.pump();

      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_storageKey);
      expect(raw, isNotNull);
      final envelope = jsonDecode(raw!) as Map<String, dynamic>;
      final adventure =
          (envelope['state'] as Map<String, dynamic>)['adventure']
              as Map<String, dynamic>;
      expect(adventure['walkSteps'], 1000);
      expect(
        adventure['walkCoinReward'],
        1000 ~/ GameConstants.walkPhaseStepsPerCoin,
      );
      expect(adventure['victorySteps'], 0);
      expect(envelope['schemaVersion'], GameStorage.schemaVersion);
    });

    testWidgets('yürüyüş fazı ekranı savaş ekranından ayrışır', (tester) async {
      final quest = _victorious(
        stepGoal: 20000,
        victorySteps: 0,
        alreadyRewarded: true,
      );
      await pumpShell(
        tester,
        profile: UserProfile(avatar: _avatar, level: 4),
        adventure: quest,
      );
      expect(find.byKey(const ValueKey('walk-phase-scene')), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.byKey(const ValueKey('walk-phase-banner')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('walk-phase-progress-bar')),
        findsOneWidget,
      );
      expect(
        find.text(
          'Yürüyüş fazı · ${GameConstants.walkPhaseStepsPerCoin} adım = 1 altın',
        ),
        findsOneWidget,
      );
      // Savaş kartları yürüyüş fazında görünmemeli.
      expect(find.text('Canavar Canı'), findsNothing);
      expect(find.byKey(const ValueKey('round-progress-bar')), findsNothing);
    });

    testWidgets('yürüyüş fazı bitince savaş ekranı geri gelmez', (
      tester,
    ) async {
      final quest = _victorious(
        stepGoal: 20000,
        victorySteps: 19000,
        round: 5,
        alreadyRewarded: true,
      );
      await pumpShell(
        tester,
        profile: UserProfile(avatar: _avatar, level: 4),
        adventure: quest,
      );
      await addSteps(tester, 1000);

      expect(quest.isAdventureCompleted, isTrue);
      expect(find.byKey(const ValueKey('walk-phase-scene')), findsNothing);
      expect(
        find.byKey(const ValueKey('gold-collection-completed')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('gold-collection-large-coin')),
        findsOneWidget,
      );
      expect(find.text('+33 EK ALTIN'), findsOneWidget);
      expect(find.textContaining('XP'), findsNothing);
      expect(find.textContaining(quest.enemy.name), findsNothing);
    });
  });
}
