import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/utils/game_clock.dart';
import '../models/adventure_quest.dart';

class AdventureNotificationService {
  AdventureNotificationService._();

  static const int _firstNotificationId = 4100;
  static const int _notificationCount = 16;
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static String? _attachmentPath;
  static bool _initialized = false;

  static const _messages = [
    '{round}. round: {enemy} için {steps} adım kaldı.',
    '{round}. round devam ediyor! Kalan {steps} adımı tamamla.',
    'Ritmini koru! {round}. roundda {steps} adımın kaldı.',
    '{round}. round: {steps} adım daha at ve {enemy} gücünü kaybetsin!',
  ];

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
    } catch (_) {
      _initialized = false;
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
  ) async {
    if (!_initialized) return;
    await cancelAdventureReminders();
    if (adventure.isBattleCompleted) return;

    final gifPath = await _copyAttackGif(adventure);
    final remainingSteps = adventure.roundStepsRemaining(currentSteps);
    // `nextEnemyAttackAt` GameClock ile yazılıyor; karşılaştırma da aynı
    // kaynaktan yapılmalı, yoksa saat geriye alınmış cihazda kalan süre
    // olduğundan kısa görünür ve hiç hatırlatma planlanmaz.
    final timeLeft = adventure.countdownRemaining(GameClock.now());
    final reminders = min(_notificationCount, timeLeft.inMinutes ~/ 5);
    final random = Random(adventure.enemy.id.hashCode + currentSteps);

    for (var i = 0; i < reminders; i++) {
      final template = _messages[random.nextInt(_messages.length)];
      final body = template
          .replaceAll('{enemy}', adventure.enemy.name)
          .replaceAll('{steps}', '$remainingSteps')
          .replaceAll('{round}', '${adventure.currentRound}');
      final androidStyle =
          gifPath == null
              ? null
              : BigPictureStyleInformation(
                FilePathAndroidBitmap(gifPath),
                contentTitle: adventure.enemy.name,
                summaryText: body,
              );

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          'adventure_reminders',
          'Macera Hatırlatmaları',
          channelDescription: 'Devam eden macera ve adım hatırlatmaları',
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
