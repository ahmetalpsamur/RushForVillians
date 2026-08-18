import 'dart:async';

/// Adım sayısı kaynağı.
///
/// **Sözleşme:** [cumulativeSteps] kümülatif ve azalmayan bir sayaçtır.
/// Günlük değeri ve kazanılacak parayı bu sayaçtan türetmek çağıranın işidir.
///
/// Gerçek sensör bu sözleşmeyi kendiliğinden **ihlal eder** (Android'de sayaç
/// cihaz yeniden başlayınca sıfırlanır). İhlali emmek uygulamanın işidir, bkz.
/// [PedometerStepSource]; çağıran taraf hiçbir zaman azalan bir değer görmez.
abstract class StepSource {
  /// Kümülatif adım sayısı.
  int get cumulativeSteps;

  /// Sayaç her arttığında yeni kümülatif değeri yayınlar.
  Stream<int> get changes;

  /// Kaynağın gerçek dünya hızına tabi olup olmadığı.
  ///
  /// `false` olan kaynaklar hız kontrolünden (`limitStepBatch`) geçirilmez:
  /// emülatörde tek dokunuşla 20.000 adım üretebilmek geliştirme için şart.
  bool get isPhysical;

  /// Diske yazılması gereken ham sensör offset'i. Yalnızca fiziksel kaynakta
  /// anlamlıdır; kapat-aç sonrası sayacın kaldığı yerden devam etmesi buna
  /// bağlıdır.
  int? get lastSensorReading;

  void dispose();
}

/// Elle beslenen adım kaynağı: demo kontrolleri ve testler.
///
/// Gerçek pedometer geldikten sonra da **korunuyor**: emülatörde ve widget
/// testlerinde adım üretmenin tek yolu bu.
class ManualStepSource implements StepSource {
  ManualStepSource({int initialSteps = 0}) : _steps = initialSteps;

  int _steps;
  final StreamController<int> _controller = StreamController<int>.broadcast();

  @override
  int get cumulativeSteps => _steps;

  @override
  Stream<int> get changes => _controller.stream;

  @override
  bool get isPhysical => false;

  @override
  int? get lastSensorReading => null;

  /// Sayaca [amount] adım ekler ve yeni kümülatif değeri yayınlar.
  void add(int amount) {
    if (amount <= 0) return;
    _steps += amount;
    _controller.add(_steps);
  }

  @override
  void dispose() {
    unawaited(_controller.close());
  }
}
