/// Oyunun zaman kaynağı. Gün, streak ve çark hesapları `DateTime.now()`
/// yerine buradan okur.
///
/// İki işi var:
///
/// 1. **Enjekte edilebilirlik.** Testler sahte bir kaynak verebilir; Aşama 6a'da
///    Firestore server timestamp'e geçilirken yalnızca [useSource] çağrısı
///    değişecek, çağıran hiçbir kod değişmeyecek.
///
/// 2. **Geriye alınan cihaz saatini yakalamak.** Sunucu saati yokken tek
///    savunma bu: en son güvenilen okuma hatırlanır, cihaz saati ondan geriye
///    giderse okuma o zamana **sabitlenir** (dondurma). Böylece kullanıcı saati
///    geri alarak streak biriktiremez veya çarkı ikinci kez çeviremez.
///
/// Karşılaştırma **UTC** üzerinden yapılır. Saat dilimi değiştiren (seyahat
/// eden) kullanıcının yerel saati saatlerce geri gidebilir ama UTC'si geri
/// gitmez — bu yüzden seyahat şüpheli sayılmaz. Oyun günü sınırı ise yerel
/// saate göre hesaplanmaya devam eder: 04:00, nerede olursan ol 04:00'tür.
///
/// Not: [now] bir "okuma" olmasına rağmen son güvenilen zamanı günceller;
/// monotonluk garantisinin doğası bu.
class GameClock {
  GameClock._();

  /// NTP düzeltmeleri ve küçük sapmalar için tolerans. Bunun altındaki geri
  /// gidişler normal kabul edilir.
  static const Duration backwardTolerance = Duration(minutes: 5);

  static DateTime Function() _source = DateTime.now;
  static DateTime? _lastTrustedUtc;

  /// Güvenilir kabul edilen şimdiki zaman (yerel).
  static DateTime now() {
    final reading = _source();
    final lastTrusted = _lastTrustedUtc;
    if (lastTrusted != null &&
        reading.toUtc().isBefore(lastTrusted.subtract(backwardTolerance))) {
      // Cihaz saati geriye alınmış: ilerlemeyi dondur.
      return lastTrusted.toLocal();
    }
    _lastTrustedUtc = reading.toUtc();
    return reading;
  }

  /// Diskten okunan son güvenilir zamanı yükler. Uygulama açılışında bir kez
  /// çağrılır; olmazsa kapat-aç ile geri alınan saat yakalanamaz.
  static void restore(DateTime? lastSeenAt) {
    _lastTrustedUtc = lastSeenAt?.toUtc();
  }

  /// Kalıcılaştırılacak son güvenilir zaman (UTC).
  static DateTime? get lastSeenAt => _lastTrustedUtc;

  /// Zaman kaynağını değiştirir (test; ileride sunucu saati).
  static void useSource(DateTime Function() source) {
    _source = source;
  }

  /// Kaynağı sistem saatine döndürür ve hatırlanan zamanı siler.
  static void reset() {
    _source = DateTime.now;
    _lastTrustedUtc = null;
  }
}
