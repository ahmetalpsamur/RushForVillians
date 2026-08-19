import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/game_constants.dart';
import 'package:rush_for_villains/core/utils/coin_calculator.dart';
import 'package:rush_for_villains/core/utils/step_rate_limiter.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_progress.dart';
import 'package:rush_for_villains/models/game_state.dart';
import 'package:rush_for_villains/models/user_profile.dart';
import 'package:rush_for_villains/services/game_storage.dart';
import 'package:rush_for_villains/services/pedometer_step_source.dart';
import 'package:rush_for_villains/services/raw_step_sensor.dart';
import 'package:rush_for_villains/services/step_source.dart';
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

final _rate = GameConstants.stepsPerCoin;
final _burst = GameConstants.stepBurstAllowance;

/// Testin sürdüğü ham sensör. Gerçek platform kanalı yerine geçer.
class FakeRawSensor implements RawStepSensor {
  FakeRawSensor({this.isBootCumulative = true});

  @override
  final bool isBootCumulative;

  final StreamController<int> _readings = StreamController<int>.broadcast();
  final StreamController<StepSensorFailure> _failures =
      StreamController<StepSensorFailure>.broadcast();

  bool started = false;
  DateTime? startedSince;

  @override
  Future<void> start({DateTime? since}) async {
    started = true;
    startedSince = since;
  }

  @override
  Stream<int> get readings => _readings.stream;

  @override
  Stream<StepSensorFailure> get failures => _failures.stream;

  void emit(int raw) => _readings.add(raw);

  void fail(StepSensorFailure failure) => _failures.add(failure);

  @override
  Future<void> dispose() async {
    await _readings.close();
    await _failures.close();
  }
}

/// `RootShell._onStepsReported`'in test kopyası: hız kontrolü, kredileme ve
/// para hesabı aynı sırada.
StepBatchVerdict report(
  UserProfile profile,
  DailyProgress today,
  StepSource source,
  int cumulativeSteps,
  DateTime now,
) {
  final elapsed = now.difference(profile.lastStepReportAt ?? now);
  final reported = cumulativeSteps - profile.lastReportedStepCount;

  profile.lastStepReportAt = now;
  profile.lastSensorReading = source.lastSensorReading;
  if (reported <= 0) return StepBatchVerdict.none;

  final verdict =
      source.isPhysical
          ? limitStepBatch(reportedSteps: reported, elapsed: elapsed)
          : StepBatchVerdict(accepted: reported, discarded: 0);

  profile.lastReportedStepCount = cumulativeSteps;
  final amount = verdict.accepted;
  if (amount <= 0) return verdict;

  today.addSteps(amount);
  profile.totalSteps += amount;

  final reward = calculateStepCoins(
    pendingSteps: profile.totalSteps - profile.lastRewardedStepCount,
    coinsEarnedToday: today.coinsEarned,
  );
  profile.coins += reward.coins;
  profile.lastRewardedStepCount += reward.consumedSteps;
  today.coinsEarned += reward.coins;
  return verdict;
}

/// Kaynak + akış + kalıcı durumu bir arada tutan test düzeneği.
class Harness {
  Harness({
    bool bootCumulative = true,
    int restoredTotal = 0,
    int? restoredReading,
    UserProfile? profile,
    DailyProgress? today,
    DateTime? startAt,
  }) : sensor = FakeRawSensor(isBootCumulative: bootCumulative),
       profile = profile ?? UserProfile(avatar: _avatar),
       today = today ?? DailyProgress(date: DateTime(2026, 8, 18, 10)),
       now = startAt ?? DateTime(2026, 8, 18, 10) {
    source = PedometerStepSource(
      sensor: sensor,
      restoredTotal: restoredTotal,
      restoredReading: restoredReading,
    );
    _subscription = source.changes.listen(
      (total) => report(this.profile, this.today, source, total, now),
    );
  }

  final FakeRawSensor sensor;
  late final PedometerStepSource source;
  final UserProfile profile;
  DailyProgress today;
  DateTime now;
  StreamSubscription<int>? _subscription;

  /// [advance] kadar zaman geçtikten sonra sensörden [raw] okur ve akışın
  /// işlenmesini bekler.
  Future<void> emit(
    int raw, {
    Duration advance = const Duration(seconds: 1),
  }) async {
    now = now.add(advance);
    sensor.emit(raw);
    await Future<void>.delayed(Duration.zero);
  }

  void dispose() {
    unawaited(_subscription?.cancel());
    source.dispose();
  }
}

void main() {
  group('ilk kurulum', () {
    test('cihaz açılışından beri birikmiş ham değer kredilenmez', () async {
      final harness = Harness();
      addTearDown(harness.dispose);

      // Telefon aylardır açık: sayaç 1,2 milyonda.
      await harness.emit(1200000);

      expect(harness.profile.totalSteps, 0);
      expect(harness.profile.coins, 0);
      expect(harness.profile.lastRewardedStepCount, 0);
      expect(harness.today.steps, 0);
      // Referans kuruldu, bundan sonraki artışlar sayılacak.
      expect(harness.profile.lastSensorReading, 1200000);
    });

    test('referans kurulduktan sonra artışlar normal sayılır', () async {
      final harness = Harness();
      addTearDown(harness.dispose);

      await harness.emit(1200000);
      await harness.emit(1200500, advance: const Duration(minutes: 5));

      expect(harness.profile.totalSteps, 500);
      expect(harness.today.steps, 500);
      expect(harness.profile.coins, 500 ~/ _rate);
    });
  });

  group('sensör sıfırlanması', () {
    test('oturum içi düşüş (8000 → 50) hiçbir değeri bozmaz', () async {
      final harness = Harness();
      addTearDown(harness.dispose);

      await harness.emit(0);
      await harness.emit(8000, advance: const Duration(hours: 1));

      expect(harness.profile.totalSteps, 8000);
      expect(harness.profile.coins, 8000 ~/ _rate);
      expect(harness.profile.lastRewardedStepCount, 8000);

      // Sensör arızası: değer 50'ye düştü.
      await harness.emit(50, advance: const Duration(seconds: 2));

      // CLAUDE.md'deki senaryonun cevabı: hiçbiri değişmez.
      expect(harness.profile.totalSteps, 8000);
      expect(harness.profile.coins, 8000 ~/ _rate);
      expect(harness.profile.lastRewardedStepCount, 8000);
      expect(harness.today.steps, 8000);
      // Kaynak dışarıya azalan bir değer vermez.
      expect(harness.source.cumulativeSteps, 8000);
      // Yeni referans diske yazılacak.
      expect(harness.profile.lastSensorReading, 50);
    });

    test('toparlanma sıçraması hız kontrolünde yanar', () async {
      final harness = Harness();
      addTearDown(harness.dispose);

      await harness.emit(0);
      await harness.emit(8000, advance: const Duration(hours: 1));
      await harness.emit(50, advance: const Duration(seconds: 2));
      // Sensör toparlandı: 7960'lık sahte sıçrama.
      await harness.emit(8010, advance: const Duration(seconds: 2));

      // Sıçramanın yalnızca taban izin kadarı geçer, gerisi yakılır.
      expect(harness.profile.totalSteps, 8000 + _burst);
      expect(harness.today.steps, 8000 + _burst);
    });

    test('yakılan adımlar sonraki raporda geri gelmez', () async {
      final harness = Harness();
      addTearDown(harness.dispose);

      await harness.emit(0);
      await harness.emit(8000, advance: const Duration(hours: 1));
      await harness.emit(50, advance: const Duration(seconds: 2));
      await harness.emit(8010, advance: const Duration(seconds: 2));
      final afterRecovery = harness.profile.totalSteps;

      // Sensör normal ilerliyor: yalnızca gerçek 10 adım eklenmeli.
      await harness.emit(8020, advance: const Duration(minutes: 1));

      expect(harness.profile.totalSteps, afterRecovery + 10);
    });

    test('soğuk açılışta reboot telafi edilir', () async {
      // Kayıt: 8.000 kredilenmiş adım, sensör 50.000'de kalmıştı.
      final harness = Harness(
        restoredTotal: 8000,
        restoredReading: 50000,
        profile: UserProfile(
          avatar: _avatar,
          totalSteps: 8000,
          lastRewardedStepCount: 8000,
          lastReportedStepCount: 8000,
          lastSensorReading: 50000,
          lastStepReportAt: DateTime(2026, 8, 18, 10),
        ),
      );
      addTearDown(harness.dispose);

      // Cihaz kapalıyken yeniden başlatılmış, o gün 300 adım atılmış.
      await harness.emit(300, advance: const Duration(hours: 6));

      expect(harness.profile.totalSteps, 8300);
      expect(harness.profile.lastSensorReading, 300);
    });

    test('reboot telafisi üst sınırla kısıtlı', () async {
      final harness = Harness(
        restoredTotal: 8000,
        restoredReading: 500000,
        profile: UserProfile(
          avatar: _avatar,
          totalSteps: 8000,
          lastRewardedStepCount: 8000,
          lastReportedStepCount: 8000,
          lastSensorReading: 500000,
          lastStepReportAt: DateTime(2026, 8, 18, 10),
        ),
      );
      addTearDown(harness.dispose);

      // Bozuk sensör soğuk açılışta absürt bir değer verdi.
      await harness.emit(90000, advance: const Duration(hours: 10));

      expect(
        harness.profile.totalSteps,
        8000 + GameConstants.maxResetRecoverySteps,
      );
    });

    test('reboot sonrası sayaç normal ilerlemeye devam eder', () async {
      final harness = Harness(
        restoredTotal: 8000,
        restoredReading: 50000,
        profile: UserProfile(
          avatar: _avatar,
          totalSteps: 8000,
          lastRewardedStepCount: 8000,
          lastReportedStepCount: 8000,
          lastSensorReading: 50000,
          lastStepReportAt: DateTime(2026, 8, 18, 10),
        ),
      );
      addTearDown(harness.dispose);

      await harness.emit(300, advance: const Duration(hours: 6));
      await harness.emit(800, advance: const Duration(minutes: 30));

      expect(harness.profile.totalSteps, 8800);
    });
  });

  group('uygulama kapalıyken atılan adımlar', () {
    test('Android kümülatif sayacı farkı olduğu gibi getirir', () async {
      final harness = Harness(
        restoredTotal: 8000,
        restoredReading: 50000,
        profile: UserProfile(
          avatar: _avatar,
          totalSteps: 8000,
          lastRewardedStepCount: 8000,
          lastReportedStepCount: 8000,
          lastSensorReading: 50000,
          lastStepReportAt: DateTime(2026, 8, 18, 10),
        ),
      );
      addTearDown(harness.dispose);

      // 3 saat kapalı kaldı, bu sürede 3.000 adım atıldı.
      await harness.emit(53000, advance: const Duration(hours: 3));

      expect(harness.profile.totalSteps, 11000);
      expect(harness.profile.lastSensorReading, 53000);
    });

    test(
      'iOS sayacı her oturumda sıfırdan sayar, sıfırlanma sayılmaz',
      () async {
        final harness = Harness(
          bootCumulative: false,
          restoredTotal: 8000,
          // Kayıtta eski bir offset olsa bile iOS'ta yok sayılır.
          restoredReading: 50000,
          profile: UserProfile(
            avatar: _avatar,
            totalSteps: 8000,
            lastRewardedStepCount: 8000,
            lastReportedStepCount: 8000,
            lastSensorReading: 50000,
            lastStepReportAt: DateTime(2026, 8, 18, 10),
          ),
        );
        addTearDown(harness.dispose);

        // Değer doğrudan "son rapordan beri atılan adım".
        await harness.emit(1500, advance: const Duration(hours: 3));

        expect(harness.profile.totalSteps, 9500);
      },
    );
  });

  group('hile koruması akışta', () {
    test('sallanan telefon günlük tavanı dolduramaz', () async {
      final harness = Harness();
      addTearDown(harness.dispose);

      await harness.emit(0);
      // 10 saniyede 50.000 adım.
      await harness.emit(50000, advance: const Duration(seconds: 10));

      expect(harness.profile.totalSteps, lessThan(1000));
      expect(harness.profile.coins, lessThan(GameConstants.maxDailyStepCoins));
    });

    test('gerçek yürüyüş hız kontrolünden etkilenmez', () async {
      final harness = Harness();
      addTearDown(harness.dispose);

      await harness.emit(0);
      // 1 saatte 6.000 adım: dakikada 100.
      await harness.emit(6000, advance: const Duration(hours: 1));

      expect(harness.profile.totalSteps, 6000);
      expect(harness.profile.coins, 6000 ~/ _rate);
    });

    test('demo kaynağı hız kontrolüne tabi değil', () {
      final profile = UserProfile(avatar: _avatar);
      final today = DailyProgress(date: DateTime(2026, 8, 18));
      final source = ManualStepSource();
      addTearDown(source.dispose);

      final verdict = report(
        profile,
        today,
        source,
        20000,
        DateTime(2026, 8, 18, 10),
      );

      expect(verdict.accepted, 20000);
      expect(verdict.discarded, 0);
      expect(profile.totalSteps, 20000);
    });
  });

  group('gün değişimi', () {
    test(
      'gün değişince günlük sayaç sıfırlanır, işaretçiler korunur',
      () async {
        final harness = Harness();
        addTearDown(harness.dispose);

        await harness.emit(0);
        await harness.emit(3000, advance: const Duration(hours: 1));
        expect(harness.today.steps, 3000);

        // RootShell._refreshDayCycle yeni bir DailyProgress kurar.
        harness.today = DailyProgress(date: DateTime(2026, 8, 19, 10));

        await harness.emit(3500, advance: const Duration(hours: 20));

        expect(harness.today.steps, 500);
        expect(harness.today.coinsEarned, 500 ~/ _rate);
        // Ömür boyu sayaç ve işaretçiler gün değişiminden etkilenmez.
        expect(harness.profile.totalSteps, 3500);
        expect(harness.profile.lastReportedStepCount, 3500);
      },
    );
  });

  group('sensör kullanılamadığında', () {
    test('hata akışı çökmez, neden yukarı bildirilir', () async {
      final harness = Harness();
      addTearDown(harness.dispose);

      final failures = <StepSensorFailure>[];
      harness.source.failures.listen(failures.add);
      harness.sensor.fail(StepSensorFailure.permissionDenied);
      await Future<void>.delayed(Duration.zero);

      expect(failures, [StepSensorFailure.permissionDenied]);
      // Oyun durumu bozulmadı.
      expect(harness.profile.totalSteps, 0);
      expect(harness.profile.coins, 0);
    });

    test('izin verilmediğinde sensör hiç başlatılmaz', () {
      final harness = Harness();
      addTearDown(harness.dispose);

      // RootShell izin reddedilirse start() çağırmaz.
      expect(harness.sensor.started, isFalse);
      expect(harness.profile.totalSteps, 0);
    });

    test('start son rapor anını sensöre taşır', () async {
      final harness = Harness();
      addTearDown(harness.dispose);

      final lastReport = DateTime(2026, 8, 18, 9);
      await harness.source.start(lastReportedAt: lastReport);

      expect(harness.sensor.started, isTrue);
      expect(harness.sensor.startedSince, lastReport);
    });
  });

  group('kalıcılık', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await GameStorage.clear();
    });

    test('raporlanmış sayaç ve offset birlikte diske gider', () async {
      final harness = Harness();
      addTearDown(harness.dispose);

      await harness.emit(1200000);
      await harness.emit(1200600, advance: const Duration(minutes: 10));

      await GameStorage.save(
        GameState(profile: harness.profile, today: harness.today),
      );
      final restored = (await GameStorage.load(avatar: _avatar))!;

      expect(restored.profile.lastReportedStepCount, 600);
      expect(restored.profile.lastSensorReading, 1200600);
      expect(restored.profile.totalSteps, 600);
      expect(restored.profile.lastStepReportAt, isNotNull);
    });

    test('kapat-aç sonrası aynı ham değer tekrar kredilenmez', () async {
      final first = Harness();
      await first.emit(1200000);
      await first.emit(1200600, advance: const Duration(minutes: 10));
      first.dispose();

      final second = Harness(
        restoredTotal: first.profile.lastReportedStepCount,
        restoredReading: first.profile.lastSensorReading,
        profile: first.profile,
        today: first.today,
      );
      addTearDown(second.dispose);

      await second.emit(1200600, advance: const Duration(minutes: 5));

      expect(second.profile.totalSteps, 600);
      expect(second.profile.coins, 600 ~/ _rate);
    });

    test('v4 kaydında offset null kalır, ham değer kredilenmez', () async {
      SharedPreferences.setMockInitialValues({
        _storageKey: jsonEncode({
          'schemaVersion': 4,
          'state': {
            'profile': {
              'totalSteps': 12000,
              'lastRewardedStepCount': 12000,
              'coins': 40,
            },
            'today': {'date': DateTime(2026, 8, 18, 10).toIso8601String()},
          },
        }),
      });

      final restored = (await GameStorage.load(avatar: _avatar))!;

      expect(restored.profile.lastReportedStepCount, 12000);
      expect(restored.profile.lastSensorReading, isNull);
      expect(restored.profile.lastStepReportAt, isNull);

      // Offset null olduğu için ilk gerçek okuma yalnızca referans kurar.
      final harness = Harness(
        restoredTotal: restored.profile.lastReportedStepCount,
        restoredReading: restored.profile.lastSensorReading,
        profile: restored.profile,
        today: restored.today,
      );
      addTearDown(harness.dispose);

      await harness.emit(980000);

      expect(harness.profile.totalSteps, 12000);
      expect(harness.profile.coins, 40);
    });
  });
}
