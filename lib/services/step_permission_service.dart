import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import 'raw_step_sensor.dart';

/// Adım sayacı izninin durumu.
enum StepPermissionStatus {
  /// Henüz sorulmadı / okunamadı.
  unknown,

  /// İzin verildi, sayaç çalışabilir.
  granted,

  /// Reddedildi ama tekrar sorulabilir.
  denied,

  /// Kalıcı olarak reddedildi; yalnızca sistem ayarlarından açılabilir.
  permanentlyDenied,

  /// Cihazda adım sayacı yok ya da platform desteklemiyor.
  unavailable,
}

extension StepPermissionStatusX on StepPermissionStatus {
  bool get isGranted => this == StepPermissionStatus.granted;

  /// Kullanıcıya gösterilecek açıklama. Devre dışı bir kontrol sessiz kalmaz.
  String get description => switch (this) {
    StepPermissionStatus.unknown => 'Adım sayacı izni henüz kontrol edilmedi.',
    StepPermissionStatus.granted => 'Adım sayacı çalışıyor.',
    StepPermissionStatus.denied =>
      'Adımlarını sayabilmemiz için hareket verisi iznine ihtiyacımız var. '
          'İzin vermeden oyunun geri kalanı çalışmaya devam eder, ama '
          'adımların kaydedilmez.',
    StepPermissionStatus.permanentlyDenied =>
      'Hareket verisi izni kapalı. Adımların sayılabilmesi için sistem '
          'ayarlarından "Fiziksel aktivite" iznini açman gerekiyor.',
    StepPermissionStatus.unavailable =>
      'Bu cihazda adım sayacı bulunamadı. Oyunun geri kalanı çalışır; '
          'adımları demo kontrollerinden simüle edebilirsin.',
  };
}

/// Adım sayacı ve bildirim izinlerini yöneten servis.
///
/// [CharacterCatalog] / [GameStorage] ile aynı desen: private constructor'lı
/// statik yardımcı sınıf. Hiçbir metodu exception fırlatmaz — izin akışındaki
/// bir hata oyunun geri kalanını durdurmamalı.
class StepPermissionService {
  StepPermissionService._();

  /// Mevcut durumu **sormadan** okur.
  static Future<StepPermissionStatus> check() async {
    if (Platform.isIOS) return _iosStatus();
    if (!Platform.isAndroid) return StepPermissionStatus.unavailable;
    try {
      return _map(await Permission.activityRecognition.status);
    } catch (error) {
      debugPrint('StepPermissionService: izin durumu okunamadı ($error)');
      return StepPermissionStatus.unknown;
    }
  }

  /// İzni ister. iOS'ta ayrı bir istek yoktur; `CMPedometer` ilk kullanımda
  /// sistem penceresini kendisi açar, bu yüzden yalnızca durum okunur.
  static Future<StepPermissionStatus> request() async {
    if (Platform.isIOS) return _iosStatus();
    if (!Platform.isAndroid) return StepPermissionStatus.unavailable;
    try {
      return _map(await Permission.activityRecognition.request());
    } catch (error) {
      debugPrint('StepPermissionService: izin istenemedi ($error)');
      return StepPermissionStatus.unknown;
    }
  }

  /// Sistem ayarlarını açar. Kalıcı reddedilmiş izin yalnızca oradan açılır.
  static Future<void> openSettings() async {
    try {
      await openAppSettings();
    } catch (error) {
      debugPrint('StepPermissionService: ayarlar açılamadı ($error)');
    }
  }

  static Future<StepPermissionStatus> _iosStatus() async {
    switch (await IosStepSensor.authorizationStatus()) {
      case 'authorized':
        return StepPermissionStatus.granted;
      case 'denied':
        return StepPermissionStatus.permanentlyDenied;
      case 'restricted':
      case 'unavailable':
        return StepPermissionStatus.unavailable;
      case 'notDetermined':
        // Henüz sorulmadı: sensör ilk kez dinlenince iOS penceresi açılır.
        return StepPermissionStatus.unknown;
      default:
        return StepPermissionStatus.unknown;
    }
  }

  static StepPermissionStatus _map(PermissionStatus status) {
    if (status.isGranted || status.isLimited) {
      return StepPermissionStatus.granted;
    }
    if (status.isPermanentlyDenied) {
      return StepPermissionStatus.permanentlyDenied;
    }
    if (status.isRestricted) return StepPermissionStatus.unavailable;
    if (status.isDenied) return StepPermissionStatus.denied;
    return StepPermissionStatus.unknown;
  }
}
