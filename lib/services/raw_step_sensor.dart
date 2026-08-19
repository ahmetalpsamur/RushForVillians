import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pedometer/pedometer.dart';

/// Sensörün neden kullanılamadığı.
enum StepSensorFailure {
  /// Cihazda adım sayacı donanımı/servisi yok.
  unavailable,

  /// Kullanıcı hareket verisi iznini vermedi.
  permissionDenied,

  /// Platform beklenmedik bir hata döndürdü.
  unknown,
}

/// Ham platform adım sensörü.
///
/// **Sözleşme:** [readings] kümülatif bir sayaç yayınlar ama bu sayaç
/// [StepSource]'un aksine **azalabilir** — Android'de `TYPE_STEP_COUNTER`
/// cihaz yeniden başlayınca sıfırlanır. Bu ihlali düzeltmek
/// [PedometerStepSource]'un işidir; buradan yukarıya ham veri çıkar.
///
/// Ölçümün başlangıç noktası platforma göre değişir; [isBootCumulative] bunu
/// söyler ve düzeltme aritmetiği buna göre seçilir.
abstract class RawStepSensor {
  /// Sayacın oturumlar arasında sürekli olup olmadığı.
  ///
  /// - `true` (Android): cihaz açılışından beri sayar, uygulama kapalıyken de
  ///   artar, yeniden başlatmada sıfırlanır. Offset diske yazılmalıdır.
  /// - `false` (iOS): her oturumda [start] ile verilen andan itibaren sayar,
  ///   yani değerin kendisi zaten "son rapordan beri atılan adım"dır.
  bool get isBootCumulative;

  /// Ölçümü başlatır.
  ///
  /// [since] yalnızca [isBootCumulative] `false` olan platformlarda
  /// anlamlıdır: sayaç bu andan itibaren sayar, böylece uygulama kapalıyken
  /// atılan adımlar da ilk okumada gelir.
  Future<void> start({DateTime? since});

  /// Ham kümülatif okumalar.
  Stream<int> get readings;

  /// Sensör kullanılamaz hâle gelirse nedeni buradan yayınlanır. Akış
  /// hatasında oyun çökmez; çağıran taraf açıklayıcı bir ekran gösterir.
  Stream<StepSensorFailure> get failures;

  Future<void> dispose();
}

/// Android: `pedometer` paketi üzerinden `TYPE_STEP_COUNTER`.
///
/// Değer cihaz açılışından beri kümülatiftir ve yeniden başlatmada sıfırlanır.
class AndroidStepSensor implements RawStepSensor {
  final StreamController<int> _readings = StreamController<int>.broadcast();
  final StreamController<StepSensorFailure> _failures =
      StreamController<StepSensorFailure>.broadcast();
  StreamSubscription<StepCount>? _subscription;

  @override
  bool get isBootCumulative => true;

  @override
  Stream<int> get readings => _readings.stream;

  @override
  Stream<StepSensorFailure> get failures => _failures.stream;

  @override
  Future<void> start({DateTime? since}) async {
    if (_subscription != null) return;
    _subscription = Pedometer.stepCountStream.listen(
      (event) => _readings.add(event.steps),
      // Sensör hatası uygulamayı çökertmez; nedeni yukarı bildirilir.
      onError: (Object error) => _failures.add(_classify(error)),
      cancelOnError: false,
    );
  }

  StepSensorFailure _classify(Object error) {
    if (error is PlatformException) {
      final text = '${error.code} ${error.message}'.toLowerCase();
      if (text.contains('permission') || text.contains('denied')) {
        return StepSensorFailure.permissionDenied;
      }
      return StepSensorFailure.unavailable;
    }
    return StepSensorFailure.unknown;
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _readings.close();
    await _failures.close();
  }
}

/// iOS: `CMPedometer`, uygulamanın kendi platform kanalı üzerinden.
///
/// `pedometer` paketi iOS'ta sayacı **son cihaz açılışından** başlatıyor.
/// `CMPedometer` yalnızca 7 günlük geçmiş tuttuğu için, uzun süre yeniden
/// başlatılmamış bir cihazda o başlangıç noktası kayar ve değer oturumlar
/// arasında düşebilir — sahte bir "sıfırlanma" üretir. Bu yüzden iOS'ta
/// başlangıç anını **biz** veriyoruz: son rapor anı.
///
/// Böylece okunan değer doğrudan "son rapordan beri atılan adım" olur;
/// hem uygulama kapalıyken atılan adımları (geçmiş sorgusu) hem canlı akışı
/// tek kanaldan getirir.
class IosStepSensor implements RawStepSensor {
  static const _events = EventChannel('rush_for_villains/step_count');
  static const _methods = MethodChannel('rush_for_villains/step_sensor');

  final StreamController<int> _readings = StreamController<int>.broadcast();
  final StreamController<StepSensorFailure> _failures =
      StreamController<StepSensorFailure>.broadcast();
  StreamSubscription<dynamic>? _subscription;

  @override
  bool get isBootCumulative => false;

  @override
  Stream<int> get readings => _readings.stream;

  @override
  Stream<StepSensorFailure> get failures => _failures.stream;

  /// Hareket verisi izninin durumu. iOS'ta ayrı bir izin isteği yoktur;
  /// `CMPedometer` ilk kullanımda sistem penceresini kendisi açar.
  static Future<String> authorizationStatus() async {
    try {
      return await _methods.invokeMethod<String>('authorizationStatus') ??
          'unknown';
    } on PlatformException catch (error) {
      debugPrint('IosStepSensor: izin durumu okunamadı ($error)');
      return 'unknown';
    } on MissingPluginException {
      // Kanal kayıtlı değil (ör. eski bir iOS derlemesi).
      return 'unavailable';
    }
  }

  @override
  Future<void> start({DateTime? since}) async {
    if (_subscription != null) return;
    final from = (since ?? DateTime.now()).toUtc().millisecondsSinceEpoch;
    _subscription = _events
        .receiveBroadcastStream({'fromEpochMs': from})
        .listen(
          (event) {
            if (event is int) _readings.add(event);
          },
          onError: (Object error) => _failures.add(_classify(error)),
          cancelOnError: false,
        );
  }

  StepSensorFailure _classify(Object error) {
    if (error is PlatformException) {
      switch (error.code) {
        case 'permission_denied':
          return StepSensorFailure.permissionDenied;
        case 'unavailable':
          return StepSensorFailure.unavailable;
      }
    }
    if (error is MissingPluginException) return StepSensorFailure.unavailable;
    return StepSensorFailure.unknown;
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _readings.close();
    await _failures.close();
  }
}

/// Bu cihaz için uygun ham sensörü verir; desteklenmeyen platformda `null`.
RawStepSensor? createPlatformStepSensor() {
  if (Platform.isAndroid) return AndroidStepSensor();
  if (Platform.isIOS) return IosStepSensor();
  return null;
}
