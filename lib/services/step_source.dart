import 'dart:async';

/// Adım sayısı kaynağı.
///
/// **Sözleşme:** [cumulativeSteps] kümülatif ve azalmayan bir sayaçtır.
/// Gerçek pedometer de cihaz açılışından beri kümülatif sayar; günlük değeri
/// ve kazanılacak parayı bu sayaçtan türetmek çağıranın işidir.
///
/// Bugün tek uygulaması [ManualStepSource] (ana sayfadaki demo kontrolleri).
/// Aşama 2'de gerçek sensör eklenirken yalnızca bu arayüzün yeni bir
/// uygulaması yazılacak — kazanç, seri ve macera kodu değişmeyecek.
abstract class StepSource {
  /// Kümülatif adım sayısı.
  int get cumulativeSteps;

  /// Sayaç her arttığında yeni kümülatif değeri yayınlar.
  Stream<int> get changes;

  void dispose();
}

/// Elle beslenen adım kaynağı: demo kontrolleri ve testler.
class ManualStepSource implements StepSource {
  ManualStepSource({int initialSteps = 0}) : _steps = initialSteps;

  int _steps;
  final StreamController<int> _controller = StreamController<int>.broadcast();

  @override
  int get cumulativeSteps => _steps;

  @override
  Stream<int> get changes => _controller.stream;

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
