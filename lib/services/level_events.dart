import 'dart:async';

/// Bir seviye atlama olayı.
class LevelUpEvent {
  /// Atlamadan önceki seviye.
  final int previousLevel;

  /// Atlamadan sonraki seviye.
  final int newLevel;

  const LevelUpEvent({required this.previousLevel, required this.newLevel});

  /// Tek seferde kaç seviye atlandı. Büyük bir XP ödülü (düşman, çark) birden
  /// fazla seviye atlatabilir.
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
/// Yayını seviye motoruyla aynı işte kurmak, sonradan `addXp` çağıran her
/// noktayı tek tek gezmekten ucuz.
///
/// Olay yalnızca [RootShell] içindeki tek noktadan (`_awardXp`) üretilir;
/// XP veren her yol oradan geçer.
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
