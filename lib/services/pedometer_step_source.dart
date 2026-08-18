import 'dart:async';

import '../core/constants/game_constants.dart';
import 'raw_step_sensor.dart';
import 'step_source.dart';

/// Gerçek sensöre dayanan adım kaynağı.
///
/// Tek işi var: ham sensörün **azalabilen** değerini, [StepSource]'un
/// azalmayan sözleşmesine çevirmek. `GameClock`'un geriye alınan cihaz saatini
/// emmesiyle birebir aynı desen — dışarıya asla ham değer sızmaz, yalnızca
/// düzeltilmiş ve monoton bir sayaç çıkar.
///
/// İçeride iki sayı yeter:
///
/// | Alan | Anlamı |
/// |---|---|
/// | [lastSensorReading] | En son görülen **ham** değer |
/// | [cumulativeSteps] | Dışarıya verilen, asla azalmayan kümülatif değer |
///
/// Artış her zaman `ham - öncekiHam` üzerinden hesaplanır. İkisi de
/// **birlikte** diske yazılır; 2 saniyelik yazma penceresinde uygulama
/// öldürülürse ikisi birlikte bayatlar ve `bayatToplam + (şimdikiHam -
/// bayatHam)` aradaki adımları doğru kapsar — ne kayıp ne çift sayım.
/// Android'de uygulama kapalıyken atılan adımlar da bu aritmetikten gelir.
///
/// **Sıfırlanma iki farklı şey olabilir**, ayrımı oturum bağlamı yapar:
///
/// - **Soğuk açılışın ilk okuması** düşükse: cihaz kapalıyken yeniden
///   başlatılmış varsayılır, mevcut ham değer (en fazla
///   [GameConstants.maxResetRecoverySteps]) telafi edilir.
/// - **Oturum içi** düşüş: sensör arızası varsayılır, hiçbir şey kredilenmez.
///   Sensör toparlanıp eski değerine sıçrarsa (8000 → 50 → 8010) o fark
///   burada değil, domain katmanındaki `limitStepBatch` içinde yanar.
class PedometerStepSource implements StepSource {
  PedometerStepSource({
    required RawStepSensor sensor,
    required int restoredTotal,
    int? restoredReading,
  }) : _sensor = sensor,
       _total = restoredTotal,
       // Oturumlar arası sürekli olmayan sensörde (iOS) sayaç her oturumda
       // sıfırdan başlar: okunan değer zaten "son rapordan beri atılan adım".
       _lastRaw = sensor.isBootCumulative ? restoredReading : 0 {
    _readingSubscription = _sensor.readings.listen(_onReading);
    _failureSubscription = _sensor.failures.listen(_failureController.add);
  }

  final RawStepSensor _sensor;
  final StreamController<int> _controller = StreamController<int>.broadcast();
  final StreamController<StepSensorFailure> _failureController =
      StreamController<StepSensorFailure>.broadcast();
  StreamSubscription<int>? _readingSubscription;
  StreamSubscription<StepSensorFailure>? _failureSubscription;

  /// Dışarıya verilen normalize toplam.
  int _total;

  /// En son görülen ham değer. `null` = referans henüz kurulmadı.
  int? _lastRaw;

  /// Bu oturumda henüz okuma gelmedi mi. Sıfırlanmanın "reboot" mu "arıza" mı
  /// olduğu ayrımı buna dayanır.
  bool _isFirstReading = true;

  @override
  int get cumulativeSteps => _total;

  @override
  Stream<int> get changes => _controller.stream;

  @override
  bool get isPhysical => true;

  /// En son görülen ham sensör değeri; diske yazılması gereken referans.
  @override
  int? get lastSensorReading => _lastRaw;

  /// Sensör kullanılamaz hâle gelirse nedeni buradan gelir.
  Stream<StepSensorFailure> get failures => _failureController.stream;

  /// Ölçümü başlatır. [lastReportedAt] son rapor anıdır; iOS'ta sayacın
  /// başlangıç noktası olarak kullanılır, böylece uygulama kapalıyken atılan
  /// adımlar da ilk okumada gelir.
  Future<void> start({DateTime? lastReportedAt}) =>
      _sensor.start(since: lastReportedAt);

  void _onReading(int raw) {
    final previous = _lastRaw;
    final wasFirstReading = _isFirstReading;
    _isFirstReading = false;
    _lastRaw = raw;

    if (previous == null) {
      // Referans yok: ham değer cihaz açılışından beri birikmiş olabilir
      // (milyonlarca adım). Hiçbiri kredilenmez, yalnızca referans kurulur.
      _emit();
      return;
    }

    if (raw < previous) {
      if (wasFirstReading) {
        // Cihaz kapalıyken yeniden başlatılmış: [raw] o andan beri atılan
        // adımdır, telafi edilir. Üst sınır, bozuk bir sensörün tek okumada
        // günlük tavanı patlatmasını engeller.
        _total += raw.clamp(0, GameConstants.maxResetRecoverySteps);
      }
      // Oturum içi düşüşte hiçbir şey kredilenmez: bu adımlar zaten
      // sayılmıştı. Toparlanma sıçraması `limitStepBatch` içinde yanar.
      _emit();
      return;
    }

    _total += raw - previous;
    _emit();
  }

  void _emit() => _controller.add(_total);

  @override
  void dispose() {
    unawaited(_readingSubscription?.cancel());
    unawaited(_failureSubscription?.cancel());
    unawaited(_sensor.dispose());
    unawaited(_controller.close());
    unawaited(_failureController.close());
  }
}
