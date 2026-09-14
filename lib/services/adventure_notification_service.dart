import 'dart:io';
import 'dart:math';

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
      await _notifications.initialize(settings);
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
