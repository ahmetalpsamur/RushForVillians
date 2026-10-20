import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/services/adventure_notification_service.dart';

void main() {
  AndroidFlutterLocalNotificationsPlugin.registerWith();
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];
  const platform = MethodChannel('dexterous.com/flutter/local_notifications');
  const configuration = MethodChannel('rush_for_villains/daily_notifications');
  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platform, (call) async {
          calls.add(call);
          if (call.method == 'initialize') return true;
          if (call.method == 'getNotificationAppLaunchDetails') {
            return {'notificationLaunchedApp': false};
          }
          return null;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          configuration,
          (_) async => {'timeZone': 'Europe/Istanbul'},
        );
    await AdventureNotificationService.initialize();
    calls.clear();
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platform, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(configuration, null);
  });
  test(
    'opening before noon replaces reminders with 30 local-noon dates starting tomorrow',
    () async {
      // Tarih gerçek saate bağlı: `zonedSchedule` geçmiş bir anı reddediyor
      // (ArgumentError, servis bunu sessizce yutuyor). Sabit 2026-09-18
      // yazıldığı gün gelecekteydi; o tarih geçince test 0 çağrı görüyordu.
      final real = DateTime.now();
      final opened = DateTime(real.year, real.month, real.day + 1, 9);
      String noonOn(int dayOffset) {
        final day = DateTime(opened.year, opened.month, opened.day + dayOffset);
        final mm = day.month.toString().padLeft(2, '0');
        final dd = day.day.toString().padLeft(2, '0');
        return '${day.year}-$mm-${dd}T12:00:00';
      }

      await AdventureNotificationService.scheduleNoonReminder(
        now: opened,
        title: 'Hero',
        body: 'Come walk!',
        channelName: 'Daily progress',
        characterAsset: 'missing.gif',
      );
      final scheduled =
          calls.where((c) => c.method == 'zonedSchedule').toList();
      expect(scheduled, hasLength(30));
      expect(calls.where((c) => c.method == 'cancel'), hasLength(30));
      final first = scheduled.first.arguments as Map;
      expect(first['scheduledDateTime'], startsWith(noonOn(1)));
      expect(first['timeZoneName'], 'Europe/Istanbul');
      expect(first['matchDateTimeComponents'], isNull);
      expect(
        (scheduled.last.arguments as Map)['scheduledDateTime'],
        startsWith(noonOn(30)),
      );
      expect(
        scheduled.map((c) => (c.arguments as Map)['id']).toSet(),
        hasLength(30),
      );
    },
  );
  test('daily alerts use separate IDs and date-bound tap payloads', () async {
    final day = DateTime(2026, 9, 18, 14);
    await AdventureNotificationService.notifyDaily(
      id: AdventureNotificationService.wheelUnlockedId,
      title: 'Wheel repaired',
      body: 'Spin?',
      channelName: 'Daily progress',
      payload: AdventureNotificationService.dailyPayload('daily-wheel', day),
    );
    final shown = calls.singleWhere((c) => c.method == 'show').arguments as Map;
    expect(shown['id'], AdventureNotificationService.wheelUnlockedId);
    expect(shown['payload'], contains('daily-wheel|2026-09-18'));
    await AdventureNotificationService.dismissDailyNotification(
      AdventureNotificationService.streakCompletedId,
    );
    expect(
      (calls.last.arguments as Map)['id'],
      AdventureNotificationService.streakCompletedId,
    );
  });
  test(
    'platform failure does not block later notification operations',
    () async {
      var failed = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform, (call) async {
            if (!failed) {
              failed = true;
              throw PlatformException(code: 'permission_denied');
            }
            calls.add(call);
            return null;
          });
      await AdventureNotificationService.dismissDailyNotification(4201);
      await AdventureNotificationService.notifyDaily(
        id: 4202,
        title: 'Ready',
        body: 'Hello',
        channelName: 'Daily',
        payload: 'daily-wheel',
      );
      expect(calls.where((c) => c.method == 'show'), hasLength(1));
    },
  );
}
