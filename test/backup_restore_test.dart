import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/game_constants.dart';
import 'package:rush_for_villains/core/utils/game_clock.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/services/game_storage.dart';
import 'package:rush_for_villains/services/install_identity.dart';
import 'package:rush_for_villains/services/pedometer_step_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pedometer_step_source_test.dart' show FakeRawSensor;

/// Android Auto Backup ile yedekten dönen kayıt (Bölüm F / Faz 4).
///
/// Sunucu yok; oyuncunun ilerlemesini telefon değişiminde ya da yeniden
/// kurulumda taşıyan tek şey Auto Backup. Burada üç şey bağlanıyor:
///
///  1. Yedekten gelen **eski şemalı** bir kayıt göçten geçiyor ve ilerleme
///     bozulmuyor.
///  2. Kayıttaki tek cihaza bağlı alan, ham adım sayacı referansı
///     ([UserProfile.lastSensorReading]), yeni telefonda düşürülüyor; yoksa
///     önceki telefonun sayacıyla yapılan fark bedava adım üretiyordu.
///  3. Yedek kuralları yalnızca oyun kaydını alıyor, cihaza bağlı kimliği
///     dışarıda bırakıyor.
const _avatar = AvatarProfile(
  name: 'Barca',
  age: 28,
  weight: 74,
  gender: 'Erkek',
  characterClass: 'SwordMan',
  characterAsset: 'lib/Characters/SwordMan/test.png',
);

class _MemoryDeviceStore implements DeviceLocalStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

/// Hiç cevap vermeyen platform kanalı.
class _SilentDeviceStore implements DeviceLocalStore {
  @override
  Future<String?> read(String key) => Completer<String?>().future;

  @override
  Future<void> write(String key, String value) => Completer<void>().future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MemoryDeviceStore device;
  late DeviceLocalStore original;

  setUp(() async {
    GameClock.useSource(() => DateTime(2026, 10, 20, 12));
    original = InstallIdentity.deviceStore;
    device = _MemoryDeviceStore();
    InstallIdentity.deviceStore = device;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    InstallIdentity.deviceStore = original;
    debugDefaultTargetPlatformOverride = null;
    GameClock.reset();
  });

  /// Eski telefonda yazılmış ilerleme. v24: seviyenin adımdan geldiği
  /// göçten (24 → 25) önceki son sürüm, yani yedekten dönen kayıt bütün
  /// sonraki göçlerden geçiyor.
  Map<String, dynamic> oldPhoneProfile() => {
    'level': 14,
    'xp': 4200,
    'coins': 1875,
    'lifetimeCoins': 9400,
    'totalSteps': 96000,
    'lastReportedStepCount': 96000,
    'lastRewardedStepCount': 96000,
    'lastXpRewardedStepCount': 96000,
    'lastSensorReading': 4850000,
    'lastStepReportAt': '2026-10-18T19:00:00.000Z',
    'streakDays': 23,
    'longestStreak': 31,
    'streakFreezes': 1,
    'ownedItems': [
      {
        'instanceId': 1,
        'itemId': 'swords/fire_sword',
        'level': 6,
        'rarity': 'rare',
        'equipped': true,
      },
      {
        'instanceId': 2,
        'itemId': 'shields/frost_shield',
        'level': 2,
        'rarity': 'epic',
        'equipped': false,
      },
    ],
    'nextItemInstanceId': 3,
    'ownedTitleIds': ['first_step', 'iron_heart'],
    'equippedTitleId': 'iron_heart',
  };

  /// Yedekten dönen depo: kayıt + yedeklenen kimlik var, cihaz kimliği yok.
  void seedRestoredBackup({String? backedUpId = 'old-phone-id'}) {
    SharedPreferences.setMockInitialValues({
      'game_state_v1': jsonEncode({
        'schemaVersion': 24,
        'savedAt': '2026-10-18T19:00:00.000',
        'state': {
          'profile': oldPhoneProfile(),
          'today': {'steps': 0, 'stepGoal': 7000},
        },
      }),
      if (backedUpId != null) InstallIdentity.backedUpKey: backedUpId,
    });
  }

  Future<Map<String, dynamic>> savedEnvelope() async {
    final preferences = await SharedPreferences.getInstance();
    return jsonDecode(preferences.getString('game_state_v1')!)
        as Map<String, dynamic>;
  }

  group('karar', () {
    test('iki kopya aynıysa aynı kurulum, değilse yedekten dönmüş', () {
      expect(
        InstallIdentity.classify(backedUp: 'a', device: 'a'),
        InstallOrigin.sameInstall,
      );
      expect(
        InstallIdentity.classify(backedUp: 'a', device: null),
        InstallOrigin.restoredOrUnknown,
      );
      expect(
        InstallIdentity.classify(backedUp: 'a', device: 'b'),
        InstallOrigin.restoredOrUnknown,
      );
      // Kimliği hiç olmayan kayıt: bu sürümden önce alınmış bir yedek ile
      // güncelleyen oyuncu ayırt edilemiyor; güvenli taraf seçiliyor.
      expect(
        InstallIdentity.classify(backedUp: null, device: null),
        InstallOrigin.restoredOrUnknown,
      );
    });
  });

  group('yedekten dönen kayıt', () {
    test('göçten geçer ve ilerleme bozulmaz', () async {
      seedRestoredBackup();

      final state = await GameStorage.load(avatar: _avatar);
      expect(state, isNotNull);
      await InstallIdentity.reconcile(state);

      final profile = state!.profile;
      expect(profile.level, greaterThanOrEqualTo(14));
      expect(profile.coins, 1875);
      expect(profile.lifetimeCoins, 9400);
      expect(profile.totalSteps, 96000);
      expect(profile.lastReportedStepCount, 96000);
      expect(profile.streakDays, 23);
      expect(profile.longestStreak, 31);
      expect(profile.streakFreezes, 1);
      expect([for (final i in profile.ownedItems) i.itemId], [
        'swords/fire_sword',
        'shields/frost_shield',
      ]);
      expect(profile.ownedItems.first.level, 6);
      expect(profile.ownedItems.first.equipped, isTrue);
      expect(profile.equippedTitleId, 'iron_heart');

      // Kayıt güncel şemayla diske yazıldı.
      final envelope = await savedEnvelope();
      expect(envelope['schemaVersion'], GameStorage.schemaVersion);
      final saved =
          (envelope['state'] as Map<String, dynamic>)['profile']
              as Map<String, dynamic>;
      expect(saved['coins'], 1875);
      expect(saved['totalSteps'], 96000);
    });

    test('önceki telefonun sensör referansı düşer ve diske de yazılır', () async {
      seedRestoredBackup();
      final state = await GameStorage.load(avatar: _avatar);
      expect(state!.profile.lastSensorReading, 4850000);

      final origin = await InstallIdentity.reconcile(state);

      expect(origin, InstallOrigin.restoredOrUnknown);
      expect(state.profile.lastSensorReading, isNull);
      final saved =
          ((await savedEnvelope())['state'] as Map<String, dynamic>)['profile']
              as Map<String, dynamic>;
      expect(saved['lastSensorReading'], isNull);
      // Kimlik yalnızca kayıt yazıldıktan sonra yazıldı ve iki kopya eşit.
      final preferences = await SharedPreferences.getInstance();
      final id = preferences.getString(InstallIdentity.backedUpKey);
      expect(id, isNot('old-phone-id'));
      expect(device.values[InstallIdentity.deviceKey], id);
    });

    test('ikinci açılışta aynı kurulum: hiçbir şey sıfırlanmaz', () async {
      seedRestoredBackup();
      final first = await GameStorage.load(avatar: _avatar);
      await InstallIdentity.reconcile(first);

      final second = await GameStorage.load(avatar: _avatar);
      second!.profile.lastSensorReading = 12345;
      expect(
        await InstallIdentity.reconcile(second),
        InstallOrigin.sameInstall,
      );
      expect(second.profile.lastSensorReading, 12345);
    });

    test('yeni telefonun sayacı bedava adım üretmez', () async {
      seedRestoredBackup();
      final state = await GameStorage.load(avatar: _avatar);
      final profile = state!.profile;

      // Düzeltme olmadan: önceki telefonun referansı (4.850.000) ile yeni
      // telefonun açılıştan beri sayacı karşılaştırılıyordu.
      final leakySensor = FakeRawSensor();
      final leakySource = PedometerStepSource(
        sensor: leakySensor,
        restoredTotal: profile.lastReportedStepCount,
        restoredReading: profile.lastSensorReading,
      );
      leakySensor.emit(6200); // yeni telefon: düşük → "yeniden başlatma"
      await Future<void>.delayed(Duration.zero);
      expect(
        leakySource.cumulativeSteps - 96000,
        6200.clamp(0, GameConstants.maxResetRecoverySteps),
        reason: 'eski referansla yürünmemiş adım kredileniyordu',
      );
      leakySource.dispose();

      await InstallIdentity.reconcile(state);
      final sensor = FakeRawSensor();
      final source = PedometerStepSource(
        sensor: sensor,
        restoredTotal: profile.lastReportedStepCount,
        restoredReading: profile.lastSensorReading,
      );
      sensor.emit(6200);
      await Future<void>.delayed(Duration.zero);
      expect(source.cumulativeSteps, 96000, reason: 'yalnızca referans kurulur');
      sensor.emit(6450);
      await Future<void>.delayed(Duration.zero);
      expect(source.cumulativeSteps, 96250, reason: 'gerçek adım sayılır');
      source.dispose();
    });

    test('okunamayan kayıtta kimliğe dokunulmaz', () async {
      SharedPreferences.setMockInitialValues({
        'game_state_v1': '{bozuk',
        InstallIdentity.backedUpKey: 'old-phone-id',
      });
      final state = await GameStorage.load(avatar: _avatar);
      expect(state, isNull);
      expect(GameStorage.writeBlocked, isTrue);

      expect(await InstallIdentity.reconcile(state), isNull);
      expect(device.values, isEmpty);
      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString(InstallIdentity.backedUpKey),
        'old-phone-id',
      );
      await GameStorage.clear();
    });

    test('cevap vermeyen kanal açılışı kilitlemez', () async {
      // Hata fırlatan kanal en başından yakalanıyordu; **hiç cevap
      // vermeyen** kanal yakalanmıyordu ve açılış kontrolü beklediği için
      // oyun açılış ekranında asılı kalırdı.
      seedRestoredBackup();
      final state = await GameStorage.load(avatar: _avatar);
      InstallIdentity.deviceStore = _SilentDeviceStore();
      final previousTimeout = InstallIdentity.timeout;
      InstallIdentity.timeout = const Duration(milliseconds: 50);
      addTearDown(() => InstallIdentity.timeout = previousTimeout);

      final origin = await InstallIdentity.reconcile(
        state,
      ).timeout(const Duration(seconds: 5));

      expect(origin, isNull);
      // Okuma bitmeden zaman aşımı: hiçbir şeye dokunulmadı.
      expect(state!.profile.lastSensorReading, 4850000);
      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString(InstallIdentity.backedUpKey),
        'old-phone-id',
      );
    });

    test('yalnızca Android: iOS\'ta iki dosya da iCloud\'a gider', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      seedRestoredBackup();
      final state = await GameStorage.load(avatar: _avatar);
      expect(await InstallIdentity.reconcile(state), isNull);
      expect(state!.profile.lastSensorReading, 4850000);
    });
  });

  group('yedek kuralları', () {
    // Eklentinin eski API'si kaydı bu dosyaya yazıyor
    // (`SharedPreferencesPlugin.kt`: SHARED_PREFERENCES_NAME).
    const saveFile = 'FlutterSharedPreferences.xml';

    String read(String path) => File(path).readAsStringSync();

    test('manifest yedeği açar ve iki kural dosyasını bağlar', () {
      final manifest = read('android/app/src/main/AndroidManifest.xml');
      expect(manifest, contains('android:allowBackup="true"'));
      expect(
        manifest,
        contains('android:fullBackupContent="@xml/backup_rules"'),
      );
      expect(
        manifest,
        contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
      );
    });

    test('Android 11 ve altı: yalnızca oyun kaydı', () {
      final rules = read('android/app/src/main/res/xml/backup_rules.xml');
      final includes = RegExp(
        r'<include\s+domain="(\w+)"\s+path="([^"]+)"',
      ).allMatches(rules).map((m) => '${m[1]}:${m[2]}').toList();
      expect(includes, ['sharedpref:$saveFile']);
    });

    test('Android 12+: bulut yedeği ve cihaz aktarımı aynı kural', () {
      final rules = read(
        'android/app/src/main/res/xml/data_extraction_rules.xml',
      );
      for (final section in ['cloud-backup', 'device-transfer']) {
        final body =
            RegExp(
              '<$section>(.*?)</$section>',
              dotAll: true,
            ).firstMatch(rules)?.group(1);
        expect(body, isNotNull, reason: section);
        final includes = RegExp(
          r'<include\s+domain="(\w+)"\s+path="([^"]+)"',
        ).allMatches(body!).map((m) => '${m[1]}:${m[2]}').toList();
        expect(includes, ['sharedpref:$saveFile'], reason: section);
      }
    });
  });
}
