import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/game_constants.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
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

/// Savaş motorunun **bağlantı** ve **kalıcılık** tarafı (Bölüm 7).
///
/// Motorun kuralları `combat_engine_test.dart`, dengesi
/// `combat_balance_test.dart` içinde. Burada ölçülen: `RootShell` motoru
/// gerçekten çalıştırıyor mu, savaş durumu diske yazılıyor mu ve eski
/// kayıtlar veri kaybetmeden taşınıyor mu.
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final enemy = EnemyCatalog.byId('night_oath')!;
  var shellSerial = 0;
  late DateTime now;

  setUp(() {
    GameClock.reset();
    now = DateTime(2026, 9, 1, 12);
    GameClock.useSource(() => now);
  });
  tearDown(GameClock.reset);

  Future<UserProfile> pumpShell(
    WidgetTester tester, {
    required UserProfile profile,
    AdventureQuest? adventure,
    int steps = 0,
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
          key: ValueKey('combat-shell-${shellSerial++}'),
          avatar: _avatar,
          initialState: GameState(
            profile: profile,
            today: DailyProgress(
              date: GameClock.now(),
              steps: steps,
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
      tester.widget<AdventureScreen>(adventureScreen).onSimulateSteps!(amount);
    } else {
      tester
          .widget<HomeScreen>(find.byType(HomeScreen))
          .onSimulateSteps(amount);
    }
    await tester.pump();
    await tester.pump();
  }

  AdventureQuest questFor({int startingSteps = 0}) => AdventureQuest(
    enemy: enemy,
    stepGoal: 2000,
    startingSteps: startingSteps,
    startedAt: GameClock.now(),
  );

  group('savaş RootShell üzerinden çalışıyor', () {
    testWidgets('açılışta can tavanı güncel statlara göre tazelenir', (
      tester,
    ) async {
      // Kayıttan gelen macera eski tavanı (100) taşıyor; oyuncu 8. seviye.
      final quest = questFor();
      expect(quest.playerMaxHealth, AdventureQuest.maxPlayerHealth);

      await pumpShell(
        tester,
        profile: UserProfile(avatar: _avatar, level: 8),
        adventure: quest,
      );

      // 8. seviye tabanı: 100 + 10 * 7 = 170.
      expect(quest.playerMaxHealth, 170);
      expect(quest.enemyHealth, quest.scaledEnemyMaxHealth);
    });

    testWidgets('tohum kurulmadan round çözülürse deterministik yedek kurulur', (
      tester,
    ) async {
      final quest = questFor();
      expect(quest.combatSeed, 0);

      await pumpShell(
        tester,
        profile: UserProfile(avatar: _avatar, level: 4),
        adventure: quest,
      );
      now = quest.nextEnemyAttackAt;
      await addSteps(tester, 1000);

      expect(quest.combatSeed, isNot(0));
      // Aynı düşman ve aynı başlangıç adımı her zaman aynı yedek tohumu verir.
      expect(
        AdventureQuest.fallbackCombatSeed(enemy.id, 0),
        AdventureQuest.fallbackCombatSeed(enemy.id, 0),
      );
      expect(
        AdventureQuest.fallbackCombatSeed(enemy.id, 0),
        isNot(AdventureQuest.fallbackCombatSeed(enemy.id, 500)),
      );
    });

    testWidgets('adım atmak roundu çözer ve düşman canını düşürür', (
      tester,
    ) async {
      final quest = questFor();
      await pumpShell(
        tester,
        profile: UserProfile(avatar: _avatar, level: 4),
        adventure: quest,
      );

      expect(quest.enemyHealth, quest.scaledEnemyMaxHealth);
      final healthBefore = quest.playerHealth;
      now = quest.nextEnemyAttackAt;
      await addSteps(tester, 1000);

      expect(quest.enemyHealth, lessThan(quest.scaledEnemyMaxHealth));
      expect(quest.playerHealth, healthBefore);
      expect(quest.lastPlayerDamage, greaterThan(0));
    });

    testWidgets('düşman canı bitince zafer ve XP verilir', (tester) async {
      // İki raundluk macera her 1.000 adımda ayrı savaş açar.
      final profile = UserProfile(avatar: _avatar, level: 40);
      final quest = questFor();
      await pumpShell(tester, profile: profile, adventure: quest);

      final xpBefore = profile.xp;
      final coinsBefore = profile.coins;
      final levelBefore = profile.level;
      now = now.add(quest.totalAttackDuration);
      await addSteps(tester, 1000);
      expect(quest.isEnemyDefeated, isFalse);
      await addSteps(tester, 1000);
      await tester.pump(const Duration(seconds: 1));

      expect(quest.isEnemyDefeated, isTrue);
      expect(quest.xpAwarded, isTrue);
      expect(quest.victoryXpReward, greaterThan(0));
      final minimumCoins = 4 + (quest.enemy.tier * 3);
      final maximumCoins = 10 + (quest.enemy.tier * 6);
      // Bölüm A.2: zafer altını artık hız çarpanıyla büyüyebilir. Üst sınır
      // bu yüzden kademe tavanının [maxVictorySpeedMultiplier] katı.
      expect(
        quest.victoryCoinReward,
        inInclusiveRange(
          minimumCoins,
          (maximumCoins * GameConstants.maxVictorySpeedMultiplier).floor(),
        ),
      );
      expect(
        quest.speedRewardMultiplier,
        inInclusiveRange(1.0, GameConstants.maxVictorySpeedMultiplier),
      );
      expect(
        profile.coins,
        coinsBefore +
            quest.victoryCoinReward +
            (2000 ~/ GameConstants.stepsPerCoin),
      );
      expect(
        profile.level > levelBefore || profile.xp > xpBefore,
        isTrue,
        reason: 'zafer XP kazandırmalı',
      );
    });

    testWidgets('seviye atlamak can tavanını büyütür', (tester) async {
      final profile = UserProfile(avatar: _avatar, level: 1);
      final quest = questFor();
      await pumpShell(tester, profile: profile, adventure: quest);

      expect(quest.playerMaxHealth, 100);

      // Adım XP'si seviye atlatır; can tavanı da büyümeli.
      await addSteps(tester, 20000);
      expect(profile.level, greaterThan(1));
      expect(quest.playerMaxHealth, greaterThan(100));
    });
  });

  group('kalıcılık', () {
    testWidgets('savaş durumu diske yazılır ve geri okunur', (tester) async {
      final quest = questFor();
      await pumpShell(
        tester,
        profile: UserProfile(avatar: _avatar, level: 4),
        adventure: quest,
      );
      now = quest.nextEnemyAttackAt;
      await addSteps(tester, 1000);
      await GameStorage.flush();

      final prefs = await SharedPreferences.getInstance();
      final envelope =
          jsonDecode(prefs.getString(_storageKey)!) as Map<String, dynamic>;
      expect(envelope['schemaVersion'], GameStorage.schemaVersion);
      final saved =
          (envelope['state'] as Map)['adventure'] as Map<String, dynamic>;

      expect(saved['enemyHealth'], quest.enemyHealth);
      expect(saved['playerMaxHealth'], quest.playerMaxHealth);
      expect(saved['combatSeed'], quest.combatSeed);
      expect(saved['untouchedRounds'], quest.untouchedRounds);

      final restored = await GameStorage.load(avatar: _avatar);
      expect(restored!.adventure!.enemyHealth, quest.enemyHealth);
      expect(restored.adventure!.combatSeed, quest.combatSeed);
      expect(restored.adventure!.playerMaxHealth, quest.playerMaxHealth);
    });

    test('kapat-aç zar attırmaz: aynı tohum aynı sonucu verir', () async {
      final startedAt = DateTime(2026, 9, 1, 12);
      AdventureQuest fresh() => AdventureQuest(
        enemy: enemy,
        stepGoal: 5000,
        startedAt: startedAt,
        combatSeed: 777,
      );

      final direct = fresh();
      direct.resolveExpiredRound(
        500,
        startedAt.add(const Duration(seconds: 180)),
      );

      // Aynı macera diske gidip geri gelirse round aynı çıkmalı.
      final saved = jsonDecode(jsonEncode(fresh().toJson()));
      final reloaded = AdventureQuest.fromJson(
        Map<String, dynamic>.from(saved as Map),
        enemy: enemy,
      );
      reloaded.resolveExpiredRound(
        500,
        startedAt.add(const Duration(seconds: 180)),
      );

      expect(reloaded.enemyHealth, direct.enemyHealth);
      expect(reloaded.playerHealth, direct.playerHealth);
      expect(reloaded.combatSeed, direct.combatSeed);
    });

    test('v13 kaydındaki yarım macera sadakatle taşınır', () async {
      // Eski modelde düşman canı = kalan adım hedefi. Macera yarılanmış:
      // 2000 hedefli macerada 1000 adım atılmış.
      SharedPreferences.setMockInitialValues({
        _storageKey: jsonEncode({
          'schemaVersion': 13,
          'state': {
            'profile': {'level': 6, 'coins': 100},
            'today': {'steps': 1000, 'stepGoal': 2000},
            'adventure': {
              'enemyId': enemy.id,
              'stepGoal': 2000,
              'startingSteps': 0,
              'playerHealth': 80,
              'acknowledgedDamage': 1000,
              'roundOutcomeSerial': 2,
            },
          },
        }),
      });

      final restored = await GameStorage.load(avatar: _avatar);
      final adventure = restored!.adventure!;

      // Düşman canının yarısı gitmiş olmalı, tam canla geri gelmemeli.
      expect(
        adventure.enemyHealth,
        (adventure.scaledEnemyMaxHealth * 0.5).round(),
      );
      expect(adventure.isEnemyDefeated, isFalse);

      // Oyuncunun canı oranı korunarak yeni tavana taşınır: 6. seviye = 150.
      expect(adventure.playerMaxHealth, 150);
      expect(adventure.playerHealth, 120);

      // `acknowledgedDamage` artık round serisi; açılışta sahte hasar mesajı
      // çıkmamalı.
      expect(adventure.takePendingDamage(), 0);
    });

    test('v13 kaydında bitmiş macera düşmanı ölü gelir', () async {
      SharedPreferences.setMockInitialValues({
        _storageKey: jsonEncode({
          'schemaVersion': 13,
          'state': {
            'profile': {'level': 3},
            'today': {'steps': 2000, 'stepGoal': 2000},
            'adventure': {
              'enemyId': enemy.id,
              'stepGoal': 2000,
              'startingSteps': 0,
              'playerHealth': 100,
            },
          },
        }),
      });

      final restored = await GameStorage.load(avatar: _avatar);
      expect(restored!.adventure!.enemyHealth, 0);
      expect(restored.adventure!.isEnemyDefeated, isTrue);
    });
  });
}
