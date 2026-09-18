import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../core/utils/game_day.dart';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/utils/game_clock.dart';
import '../models/adventure_quest.dart';

class AdventureNotificationCopy {
  final String enemyName;
  final List<String> reminderBodies;
  final String channelName;
  final String channelDescription;

  const AdventureNotificationCopy({
    required this.enemyName,
    required this.reminderBodies,
    required this.channelName,
    required this.channelDescription,
  });
}

class AdventureNotificationService {
  AdventureNotificationService._();

  static const int _firstNotificationId = 4100;
  static const int _notificationCount = 16;
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static String? _attachmentPath;
  static bool _initialized = false;

  static final ValueNotifier<String?> tappedPayload = ValueNotifier(null);
  static const noonReminderId = 4300;
  static const noonReminderCount = 30;
  static const streakCompletedId = 4201;
  static const wheelUnlockedId = 4202;
  static const _dailyChannel = MethodChannel(
    'rush_for_villains/daily_notifications',
  );
  static Future<void> _dailyQueue = Future.value();

  static String dailyPayload(String kind, DateTime day) =>
      '$kind|${GameDay.startOf(day).toIso8601String()}';

  /// Device-local noon; calendar construction also handles DST boundaries.
  static DateTime nextNoon(DateTime now, {required bool openedToday}) {
    final noon = DateTime(now.year, now.month, now.day, 12);
    return !openedToday && now.isBefore(noon)
        ? noon
        : DateTime(now.year, now.month, now.day + 1, 12);
  }

  static Future<void> _dailyOperation(Future<void> Function() operation) {
    final next = _dailyQueue.then((_) async {
      if (!_initialized) return;
      try {
        await operation();
      } catch (_) {
        // Permission denial, unavailable platform, or artwork must never block play.
      }
    });
    _dailyQueue = next;
    return next;
  }

  static Future<Map<Object?, Object?>> _dailyConfiguration() async {
    final config =
        await _dailyChannel.invokeMethod<Map<Object?, Object?>>(
          'configuration',
        ) ??
        {};
    final name = config['timeZone'];
    if (name is String) tz.setLocalLocation(tz.getLocation(name));
    return config;
  }

  static Future<String?> _dailyArtwork(
    String asset,
    Map<Object?, Object?> config,
  ) async {
    try {
      final root = config['directory'];
      if (root is! String) return null;
      final directory = await Directory(
        '$root/daily_notifications',
      ).create(recursive: true);
      final file = File('${directory.path}/character.png');
      final data = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        targetWidth: 512,
      );
      try {
        final frame = await codec.getNextFrame();
        try {
          final png = await frame.image.toByteData(
            format: ui.ImageByteFormat.png,
          );
          if (png == null) return null;
          await file.writeAsBytes(
            png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes),
            flush: true,
          );
        } finally {
          frame.image.dispose();
        }
      } finally {
        codec.dispose();
      }
      return file.path;
    } catch (_) {
      return null;
    }
  }

  static NotificationDetails _dailyDetails(
    String channelName,
    String body, {
    String? artwork,
  }) => NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_progress',
      channelName,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation:
          artwork == null
              ? BigTextStyleInformation(body)
              : BigPictureStyleInformation(
                FilePathAndroidBitmap(artwork),
                summaryText: body,
              ),
      largeIcon: artwork == null ? null : FilePathAndroidBitmap(artwork),
    ),
    iOS: DarwinNotificationDetails(
      attachments:
          artwork == null ? null : [DarwinNotificationAttachment(artwork)],
    ),
  );

  /// Opening the app removes today's reminder and starts daily repetition tomorrow.
  static Future<void> scheduleNoonReminder({
    required DateTime now,
    required String title,
    required String body,
    required String channelName,
    required String characterAsset,
  }) => _dailyOperation(() async {
    for (var i = 0; i < noonReminderCount; i++) {
      await _notifications.cancel(noonReminderId + i);
    }
    final config = await _dailyConfiguration();
    final artwork = await _dailyArtwork(characterAsset, config);
    final noon = nextNoon(now, openedToday: true);
    // Date-only requests avoid iOS time-only repetition firing again today.
    // Refill 30 days at each visit, below the shared 64-request iOS limit.
    for (var i = 0; i < noonReminderCount; i++) {
      await _notifications.zonedSchedule(
        noonReminderId + i,
        title,
        body,
        tz.TZDateTime(tz.local, noon.year, noon.month, noon.day + i, 12),
        _dailyDetails(channelName, body, artwork: artwork),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'daily-reminder',
      );
    }
  });

  static Future<void> notifyDaily({
    required int id,
    required String title,
    required String body,
    required String channelName,
    required String payload,
  }) => _dailyOperation(() async {
    await _notifications.show(
      id,
      title,
      body,
      _dailyDetails(channelName, body),
      payload: payload,
    );
  });

  static Future<void> dismissDailyNotification(int id) =>
      _dailyOperation(() => _notifications.cancel(id));

  static Future<void> initialize() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: darwin);
    try {
      await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: (response) {
          tappedPayload.value = response.payload;
        },
      );
      final launch = await _notifications.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true) {
        tappedPayload.value = launch?.notificationResponse?.payload;
      }
      _initialized = true;
      await cancelAdventureReminders();
    } catch (_) {
      _initialized = false;
    }
  }

  /// One event per ready round. No new permissions or background tracking.
  static Future<void> notifyReady(
    AdventureNotificationCopy copy,
    String body, {
    required bool foreground,
  }) async {
    try {
      if (foreground) {
        await HapticFeedback.mediumImpact();
        await SystemSound.play(SystemSoundType.alert);
      } else if (_initialized) {
        await _notifications.show(
          _firstNotificationId,
          'Rush for Villains',
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'adventure_ready',
              copy.channelName,
              channelDescription: copy.channelDescription,
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          payload: 'adventure',
        );
      }
    } catch (_) {
      // Denied notifications or unavailable audio never block progression.
    }
  }

  static Future<void> requestPermission() async {
    if (!_initialized) return;
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<void> cancelAdventureReminders() async {
    if (!_initialized) return;
    for (var i = 0; i < _notificationCount; i++) {
      await _notifications.cancel(_firstNotificationId + i);
    }
    final attachmentPath = _attachmentPath;
    _attachmentPath = null;
    if (attachmentPath != null) {
      try {
        final directory = File(attachmentPath).parent;
        if (await directory.exists()) await directory.delete(recursive: true);
      } catch (_) {
        // Bildirim iptal edilmişse geçici görselin temizlenememesi akışı bozmaz.
      }
    }
  }

  static Future<void> scheduleAdventureReminders(
    AdventureQuest adventure,
    int currentSteps,
    AdventureNotificationCopy copy,
  ) async {
    if (!_initialized) return;
    await cancelAdventureReminders();
    if (adventure.isBattleCompleted) return;

    final gifPath = await _copyAttackGif(adventure);
    // `nextEnemyAttackAt` GameClock ile yazılıyor; karşılaştırma da aynı
    // kaynaktan yapılmalı, yoksa saat geriye alınmış cihazda kalan süre
    // olduğundan kısa görünür ve hiç hatırlatma planlanmaz.
    final timeLeft = adventure.countdownRemaining(GameClock.now());
    final reminders = min(_notificationCount, timeLeft.inMinutes ~/ 5);
    final random = Random(adventure.enemy.id.hashCode + currentSteps);

    for (var i = 0; i < reminders; i++) {
      final body =
          copy.reminderBodies[random.nextInt(copy.reminderBodies.length)];
      final androidStyle =
          gifPath == null
              ? null
              : BigPictureStyleInformation(
                FilePathAndroidBitmap(gifPath),
                contentTitle: copy.enemyName,
                summaryText: body,
              );

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          'adventure_reminders',
          copy.channelName,
          channelDescription: copy.channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: androidStyle,
          largeIcon: gifPath == null ? null : FilePathAndroidBitmap(gifPath),
        ),
        iOS: DarwinNotificationDetails(
          threadIdentifier: 'adventure_reminders',
          attachments:
              gifPath == null ? null : [DarwinNotificationAttachment(gifPath)],
        ),
      );

      await _notifications.zonedSchedule(
        _firstNotificationId + i,
        'Rush for Villains',
        body,
        tz.TZDateTime.now(tz.UTC).add(Duration(minutes: (i + 1) * 5)),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'adventure',
      );
    }
  }

  static Future<String?> _copyAttackGif(AdventureQuest adventure) async {
    try {
      final data = await rootBundle.load(adventure.enemy.attackAsset);
      final directory = Directory.systemTemp.createTempSync(
        'rush_adventure_notification_',
      );
      final file = File(
        '${directory.path}${Platform.pathSeparator}${adventure.enemy.id}_attack.gif',
      );
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      _attachmentPath = file.path;
      return file.path;
    } catch (_) {
      return null;
    }
  }
}
