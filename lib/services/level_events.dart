import 'dart:async';

/// Bir seviye atlama olayı.
class LevelUpEvent {
  /// Atlamadan önceki seviye.
  final int previousLevel;

  /// Atlamadan sonraki seviye.
  final int newLevel;

  const LevelUpEvent({required this.previousLevel, required this.newLevel});

  /// A single accepted step batch may grant multiple levels.
  int get levelsGained => newLevel - previousLevel;

  @override
  String toString() => 'LevelUpEvent($previousLevel → $newLevel)';
}

/// Seviye atlama yayını.
///
/// [GameStorage] / [CharacterCatalog] ile aynı desen: private constructor'lı
/// statik servis. Amacı, seviyeye bağlı sistemlerin `RootShell`'e callback
/// bağlamadan haberdar olabilmesi.
///
/// **Neden şimdi var:** Aşama 3'te item seviye kilidi (#10) ve mağaza seviye
/// kilidi (#11) geliyor; ikisi de "seviye değişti" anını bilmek isteyecek.
/// Yayını seviye motoruyla aynı işte kurmak, sonradan `creditLevelStepsThrough` çağıran her
/// noktayı tek tek gezmekten ucuz.
///
/// Emitted only by RootShell._awardLevelSteps after validated walking progress.
class LevelEvents {
  LevelEvents._();

  static final StreamController<LevelUpEvent> _controller =
      StreamController<LevelUpEvent>.broadcast();

  /// Seviye atlandığında yayınlanır. Dinleyici yoksa olay sessizce düşer —
  /// yayın `broadcast` olduğu için tamponlanmaz.
  static Stream<LevelUpEvent> get stream => _controller.stream;

  static void emit(LevelUpEvent event) {
    if (_controller.isClosed) return;
    _controller.add(event);
  }
}
