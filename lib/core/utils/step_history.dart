import '../../models/daily_progress.dart';
import '../../models/daily_step_record.dart';
import '../constants/game_constants.dart';
import 'game_day.dart';

/// Tamamlanan bir günü adım halkası geçmişine yazar.
///
/// Saf fonksiyon: verilen listeyi değiştirmez, yenisini döner. `RootShell`
/// gün değişimini yakaladığında ([_refreshDayCycle]) buradan geçer.
///
/// Üç iş yapar:
/// 1. Kaydı **oyun gününe** göre anahtarlar ([GameDay.startOf]). Gün sınırı
///    gece yarısı değil; ham tarih kullanılsaydı, sınırdan sonra ama gece
///    yarısından önce açılmış bir günlük ilerleme bir sonraki takvim gününe
///    yazılır ve halka yanlış güne düşerdi.
/// 2. Aynı güne ait eski bir kayıt varsa onu değiştirir — gün iki kez
///    arşivlenirse (uygulama açılıp kapanırsa) çift satır oluşmaz.
/// 3. Geçmişi [maxDays] ile sınırlar. Kayıt tek bir SharedPreferences
///    anahtarında duruyor; sınırsız büyüyen liste hem her açılış okumasını
///    hem her yazmayı yavaşlatır.
List<DailyStepRecord> archiveStepDay({
  required List<DailyStepRecord> history,
  required DailyProgress completedDay,
  int maxDays = GameConstants.maxStepHistoryDays,
}) {
  final record = DailyStepRecord(
    date: GameDay.startOf(completedDay.date),
    steps: completedDay.steps,
    stepGoal: completedDay.stepGoal,
  );

  final updated =
      history.where((item) => item.dateKey != record.dateKey).toList()
        ..add(record)
        ..sort((a, b) => a.calendarDay.compareTo(b.calendarDay));

  return pruneStepHistory(updated, maxDays: maxDays);
}

/// Geçmişi en yeni [maxDays] günle sınırlar; en eski günler düşer.
///
/// Arşivleme dışında bir yerde daha çağrılır: diskten okunan kayıt sınır
/// konmadan önce yazılmış (ya da elle düzenlenmiş) olabilir.
List<DailyStepRecord> pruneStepHistory(
  List<DailyStepRecord> history, {
  int maxDays = GameConstants.maxStepHistoryDays,
}) {
  if (maxDays <= 0) return const [];
  if (history.length <= maxDays) return history;
  return history.sublist(history.length - maxDays);
}
