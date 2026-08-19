/// Oyun gününün tek doğruluk kaynağı.
///
/// Günlük adım sıfırlaması, çark hakkı, streak ve ileride eklenecek tüm
/// gün bazlı kurallar buradan hesaplanır. Hiçbir yerde ikinci bir gün
/// karşılaştırması (`a.day == b.day` gibi) yazılmaz.
///
/// Gün sınırını değiştirmek için yalnızca [dayStartHour] güncellenir;
/// adım sıfırlaması, çark geri sayımı ve streak otomatik olarak uyar.
class GameDay {
  GameDay._();

  /// Oyun gününün başladığı saat (0-23).
  ///
  /// Adım halkası takvim günüyle birlikte gece 00:00'da kapanır ve arşivlenir.
  static const int dayStartHour = 0;

  /// [moment]'in ait olduğu oyun gününün başlangıç anı.
  static DateTime startOf(DateTime moment) {
    final candidate = DateTime(
      moment.year,
      moment.month,
      moment.day,
      dayStartHour,
    );
    if (moment.isBefore(candidate)) {
      // Gün sınırı gece yarısından sonraysa, sınırdan önceki saatler hâlâ
      // bir önceki oyun gününe aittir.
      return DateTime(moment.year, moment.month, moment.day - 1, dayStartHour);
    }
    return candidate;
  }

  /// İki anın aynı oyun gününe düşüp düşmediği.
  static bool isSameGameDay(DateTime a, DateTime b) => startOf(a) == startOf(b);

  /// [a] ile [b] arasındaki oyun günü farkı ([b] ileriyse pozitif).
  ///
  /// Fark takvim günü üzerinden sayılır: yaz saati geçişlerinde bir gün 23 ya
  /// da 25 saat sürebildiği için saat farkını güne bölmek yanlış sonuç verir.
  static int daysBetween(DateTime a, DateTime b) {
    final startA = startOf(a);
    final startB = startOf(b);
    return DateTime.utc(
      startB.year,
      startB.month,
      startB.day,
    ).difference(DateTime.utc(startA.year, startA.month, startA.day)).inDays;
  }

  /// [moment]'ten sonraki ilk gün sıfırlamasının anı.
  static DateTime nextResetAfter(DateTime moment) {
    final start = startOf(moment);
    return DateTime(start.year, start.month, start.day + 1, dayStartHour);
  }

  /// Gün sıfırlamasına kalan süre.
  static Duration timeUntilReset(DateTime now) =>
      nextResetAfter(now).difference(now);

  /// Geri sayımı kısa biçimde yazar: "5s 12dk", "12dk", "1dk'dan az".
  static String formatRemaining(Duration remaining) {
    if (remaining.isNegative || remaining < const Duration(minutes: 1)) {
      return '1dk\'dan az';
    }
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    if (hours == 0) return '${minutes}dk';
    return '${hours}s ${minutes}dk';
  }
}
