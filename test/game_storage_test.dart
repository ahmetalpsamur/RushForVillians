import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/game_constants.dart';
import 'package:rush_for_villains/data/enemy_catalog.dart';
import 'package:rush_for_villains/models/adventure_quest.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_progress.dart';
import 'package:rush_for_villains/models/daily_step_record.dart';
import 'package:rush_for_villains/models/game_state.dart';
import 'package:rush_for_villains/models/item_effect.dart';
import 'package:rush_for_villains/models/user_profile.dart';
import 'package:rush_for_villains/services/game_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _storageKey = 'game_state_v1';

const _avatar = AvatarProfile(
  name: 'Barca',
  age: 28,
  weight: 74,
  gender: 'Erkek',
  characterClass: 'SwordMan',
  characterAsset: 'lib/Characters/SwordMan/test.png',
);

/// Testlerde kullanılan, tüm alanları doldurulmuş örnek durum.
GameState _sampleState() {
  final profile = UserProfile(
    avatar: _avatar,
    level: 4,
    xp: 250,
    coins: 1300,
    streakDays: 6,
    lastActiveDay: DateTime(2026, 8, 18),
    totalSteps: 42000,
    ownedUpgradeIds: ['skin_dragon_cape'],
    lastWheelSpinAt: DateTime(2026, 8, 18, 9, 30),
  );
  final adventure = AdventureQuest(
    enemy: EnemyCatalog.enemies[1],
    stepGoal: 5000,
    backgroundAsset: 'lib/Backgrounds/versionB1_platform.png',
    startingSteps: 800,
    startedAt: DateTime(2026, 8, 18, 12),
  );
  adventure.playerHealth = 73;
  adventure.roundStartingSteps = 1000;
  adventure.enemyAttackSerial = 2;
  adventure.lastEnemyDamage = 9;
  adventure.acknowledgedDamage = 1000;
  adventure.currentRound = 3;
  adventure.roundTargetSteps = 1000;
  adventure.lastResolvedRound = 2;
  adventure.roundOutcomeSerial = 2;
  adventure.presentedRoundOutcomeSerial = 1;
  adventure.lastRoundWon = true;
  adventure.perfectRoundStreak = 2;
  adventure.lastRoundPerfect = true;
  adventure.lastPerfectDamageMultiplier = 1.4;

  return GameState(
    profile: profile,
    today: DailyProgress(
      date: DateTime(2026, 8, 18, 13),
      steps: 1200,
      stepGoal: 5000,
    ),
    adventure: adventure,
    stepHistory: [
      DailyStepRecord(date: DateTime(2026, 8, 16), steps: 4321, stepGoal: 5000),
      DailyStepRecord(
        date: DateTime(2026, 8, 17),
        steps: 8765,
        stepGoal: 10000,
      ),
    ],
  );
}

Future<GameState?> _saveAndLoad(GameState state) async {
  await GameStorage.save(state);
  return GameStorage.load(avatar: _avatar);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GameStorage.clear();
  });

  group('yazma/okuma turu', () {
    test('kayıt yoksa null döner', () async {
      expect(await GameStorage.load(avatar: _avatar), isNull);
    });

    test('oyuncu ilerlemesi aynen geri okunur', () async {
      final restored = await _saveAndLoad(_sampleState());

      expect(restored, isNotNull);
      final profile = restored!.profile;
      expect(profile.level, 4);
      expect(profile.xp, 250);
      expect(profile.coins, 1300);
      expect(profile.streakDays, 6);
      expect(profile.totalSteps, 42000);
      expect(profile.ownedUpgradeIds, ['skin_dragon_cape']);
      expect(profile.lastActiveDay, DateTime(2026, 8, 18));
      expect(profile.lastWheelSpinAt, DateTime(2026, 8, 18, 9, 30));
      // Avatar ayrı saklandığı için dışarıdan verilen kullanılır.
      expect(profile.avatar.name, 'Barca');
    });

    test('günlük adım ilerlemesi aynen geri okunur', () async {
      final restored = await _saveAndLoad(_sampleState());

      expect(restored!.today.steps, 1200);
      expect(restored.today.stepGoal, 5000);
      expect(restored.today.date, DateTime(2026, 8, 18, 13));
    });

    test('tamamlanan günlerin adım halkaları aynen geri okunur', () async {
      final restored = await _saveAndLoad(_sampleState());

      expect(restored!.stepHistory, hasLength(2));
      expect(restored.stepHistory.first.date, DateTime(2026, 8, 16));
      expect(restored.stepHistory.first.steps, 4321);
      expect(restored.stepHistory.first.stepGoal, 5000);
      expect(restored.stepHistory.last.steps, 8765);
    });

    test('macera ve geri sayım aynen geri okunur', () async {
      final original = _sampleState();
      final restored = await _saveAndLoad(original);

      final adventure = restored!.adventure;
      expect(adventure, isNotNull);
      expect(adventure!.enemy.id, EnemyCatalog.enemies[1].id);
      expect(adventure.stepGoal, 5000);
      expect(
        adventure.backgroundAsset,
        'lib/Backgrounds/versionB1_platform.png',
      );
      expect(adventure.startingSteps, 800);
      expect(adventure.playerHealth, 73);
      expect(adventure.roundStartingSteps, 1000);
      expect(adventure.acknowledgedDamage, 1000);
      expect(adventure.enemyAttackSerial, 2);
      expect(adventure.lastEnemyDamage, 9);
      expect(adventure.currentRound, 3);
      expect(adventure.lastResolvedRound, 2);
      expect(adventure.roundOutcomeSerial, 2);
      expect(adventure.presentedRoundOutcomeSerial, 1);
      expect(adventure.lastRoundWon, isTrue);
      expect(adventure.perfectRoundStreak, 2);
      expect(adventure.lastRoundPerfect, isTrue);
      expect(adventure.lastPerfectDamageMultiplier, 1.4);
      // Geri sayım kurucuda yeniden hesaplanmamalı, kayıttan gelmeli.
      expect(
        adventure.nextEnemyAttackAt,
        original.adventure!.nextEnemyAttackAt,
      );
      expect(adventure.roundTargetSteps, original.adventure!.roundTargetSteps);
    });

    test('macera seçilmemişse null olarak geri okunur', () async {
      final state = GameState(
        profile: UserProfile(avatar: _avatar),
        today: DailyProgress(date: DateTime(2026, 8, 18)),
      );

      final restored = await _saveAndLoad(state);

      expect(restored!.adventure, isNull);
    });
  });

  group('şema versiyonlama', () {
    test('kayıt güncel sürüm numarasıyla yazılır', () async {
      await GameStorage.save(_sampleState());
      final preferences = await SharedPreferences.getInstance();
      final envelope =
          jsonDecode(preferences.getString(_storageKey)!)
              as Map<String, dynamic>;

      expect(envelope['schemaVersion'], GameStorage.schemaVersion);
      expect(envelope['savedAt'], isA<String>());
      expect(envelope['state'], isA<Map<String, dynamic>>());
    });

    test('sürümsüz (v0) eski kayıt taşınarak okunur', () async {
      // Zarf yokken durum doğrudan kökte tutuluyordu.
      SharedPreferences.setMockInitialValues({
        _storageKey: jsonEncode({
          'profile': {'level': 3, 'coins': 500},
          'today': {'steps': 700, 'stepGoal': 5000},
        }),
      });

      final restored = await GameStorage.load(avatar: _avatar);

      expect(restored, isNotNull);
      expect(restored!.profile.level, 3);
      expect(restored.profile.coins, 500);
      expect(restored.today.steps, 700);
    });

    test('v1 kaydındaki hp/maxHp taşınırken düşürülür', () async {
      SharedPreferences.setMockInitialValues({
        _storageKey: jsonEncode({
          'schemaVersion': 1,
          'state': {
            'profile': {'level': 3, 'coins': 500, 'hp': 12, 'maxHp': 34},
          },
        }),
      });

      final restored = await GameStorage.load(avatar: _avatar);

      expect(restored!.profile.level, 3);
      expect(restored.profile.coins, 500);
      // Kayıttan gelmez, varsayılana düşer.
      expect(restored.profile.hp, GameConstants.baseHp);
      expect(restored.profile.maxHp, GameConstants.baseHp);
    });

    test('hp/maxHp artık kayda yazılmaz', () async {
      await GameStorage.save(_sampleState());
      final preferences = await SharedPreferences.getInstance();
      final envelope =
          jsonDecode(preferences.getString(_storageKey)!)
              as Map<String, dynamic>;
      final profile = (envelope['state'] as Map)['profile'] as Map;

      expect(profile.containsKey('hp'), isFalse);
      expect(profile.containsKey('maxHp'), isFalse);
    });

    test('v7 kaydı boş adım geçmişiyle güncellenir', () async {
      SharedPreferences.setMockInitialValues({
        _storageKey: jsonEncode({
          'schemaVersion': 7,
          'state': {
            'profile': {'level': 3},
            'today': {'steps': 900, 'stepGoal': 5000},
          },
        }),
      });

      final restored = await GameStorage.load(avatar: _avatar);

      expect(restored, isNotNull);
      expect(restored!.stepHistory, isEmpty);
      expect(restored.today.steps, 900);
    });

    test('v17 kaydındaki seri bonusu gün sayıları bindeye taşınır', () async {
      // Bölüm B öncesi kayıt gün sayısı tutuyordu ve bir gün +%1 ediyordu.
      // Yeni biçim binde tutuyor: 1 gün = 10 binde. Birikim birebir korunmalı,
      // yoksa uzun serili oyuncunun savaş bonusu güncelleme sonrası onda
      // birine düşerdi.
      SharedPreferences.setMockInitialValues({
        _storageKey: jsonEncode({
          'schemaVersion': 17,
          'state': {
            'profile': {
              'level': 3,
              'streakDays': 6,
              'streakStatBonuses': {'attack': 4, 'defense': 2},
            },
            'today': {'steps': 900, 'stepGoal': 5000},
          },
        }),
      });

      final restored = await GameStorage.load(avatar: _avatar);

      expect(restored, isNotNull);
      final bonuses = restored!.profile.streakStatBonuses;
      expect(bonuses.tenthsFor(ItemStat.attack), 40);
      expect(bonuses.tenthsFor(ItemStat.defense), 20);
      // 4 gün x %1 + 2 gün x %1 = +%6.
      expect(bonuses.totalBonus, closeTo(0.06, 1e-9));
    });

    test('v17 taşıması seri bonusu olmayan kaydı bozmaz', () async {
      SharedPreferences.setMockInitialValues({
        _storageKey: jsonEncode({
          'schemaVersion': 17,
          'state': {
            'profile': {'level': 3},
            'today': {'steps': 120, 'stepGoal': 5000},
          },
        }),
      });

      final restored = await GameStorage.load(avatar: _avatar);

      expect(restored, isNotNull);
      expect(restored!.profile.level, 3);
      expect(restored.profile.streakStatBonuses.isEmpty, isTrue);
    });

    test('uygulamadan yeni sürümdeki kayıt yok sayılır', () async {
      SharedPreferences.setMockInitialValues({
        _storageKey: jsonEncode({
          'schemaVersion': GameStorage.schemaVersion + 1,
          'state': {
            'profile': {'level': 9},
          },
        }),
      });

      expect(await GameStorage.load(avatar: _avatar), isNull);
    });
  });

  group('bozuk veri dayanıklılığı', () {
    test('geçersiz JSON çökmeden null döner', () async {
      SharedPreferences.setMockInitialValues({
        _storageKey: '{bu gecerli bir json degil',
      });

      expect(await GameStorage.load(avatar: _avatar), isNull);
    });

    test('JSON bir nesne değilse null döner', () async {
      SharedPreferences.setMockInitialValues({
        _storageKey: jsonEncode([1, 2, 3]),
      });

      expect(await GameStorage.load(avatar: _avatar), isNull);
    });

    test('alan tipleri bozuksa null döner, çökmez', () async {
      SharedPreferences.setMockInitialValues({
        _storageKey: jsonEncode({
          'schemaVersion': GameStorage.schemaVersion,
          'state': {
            'profile': {'level': 'dört', 'coins': 'çok'},
          },
        }),
      });

      expect(await GameStorage.load(avatar: _avatar), isNull);
    });

    test('bozuk kayıttan sonra temiz kayıt yazılabilir', () async {
      SharedPreferences.setMockInitialValues({_storageKey: 'bozuk'});
      expect(await GameStorage.load(avatar: _avatar), isNull);

      final restored = await _saveAndLoad(_sampleState());

      expect(restored!.profile.level, 4);
    });
  });

  group('eksik alanlar', () {
    test('tamamen boş durum varsayılanlara düşer', () async {
      SharedPreferences.setMockInitialValues({
        _storageKey: jsonEncode({
          'schemaVersion': GameStorage.schemaVersion,
          'state': <String, dynamic>{},
        }),
      });

      final restored = await GameStorage.load(avatar: _avatar);

      expect(restored, isNotNull);
      expect(restored!.profile.level, 1);
      expect(restored.profile.xp, 0);
      expect(restored.profile.coins, 0);
      expect(restored.profile.totalSteps, 0);
      expect(restored.profile.ownedItems, isEmpty);
      expect(restored.profile.lastWheelSpinAt, isNull);
      expect(restored.today.steps, 0);
    });

    test('eksik alanlar diğer alanları bozmaz', () async {
      SharedPreferences.setMockInitialValues({
        _storageKey: jsonEncode({
          'schemaVersion': GameStorage.schemaVersion,
          'state': {
            'profile': {'level': 7},
          },
        }),
      });

      final restored = await GameStorage.load(avatar: _avatar);

      expect(restored!.profile.level, 7);
      expect(restored.profile.coins, 0);
    });

    test('katalogda olmayan düşman kaydı maceradan düşer', () async {
      SharedPreferences.setMockInitialValues({
        _storageKey: jsonEncode({
          'schemaVersion': GameStorage.schemaVersion,
          'state': {
            'profile': {'level': 5},
            'adventure': {'enemyId': 'artik_olmayan_dusman', 'stepGoal': 5000},
          },
        }),
      });

      final restored = await GameStorage.load(avatar: _avatar);

      // Macera düşer ama kalıcı ilerleme korunur.
      expect(restored!.adventure, isNull);
      expect(restored.profile.level, 5);
    });
  });

  group('yazma sıklığı', () {
    test('scheduleSave hemen yazmaz, flush anında yazar', () async {
      GameStorage.scheduleSave(_sampleState());

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(_storageKey), isNull);

      await GameStorage.flush();

      expect(await GameStorage.load(avatar: _avatar), isNotNull);
    });

    test('aralık içindeki ardışık isteklerden sonuncusu yazılır', () async {
      final second = GameState(
        profile: UserProfile(avatar: _avatar, coins: 99),
        today: DailyProgress(date: DateTime(2026, 8, 18)),
      );

      GameStorage.scheduleSave(_sampleState());
      GameStorage.scheduleSave(second);
      await GameStorage.flush();

      final restored = await GameStorage.load(avatar: _avatar);

      expect(restored!.profile.coins, 99);
    });

    test('bekleyen yazma yoksa flush sorun çıkarmaz', () async {
      await GameStorage.flush();

      expect(await GameStorage.load(avatar: _avatar), isNull);
    });
  });
}
