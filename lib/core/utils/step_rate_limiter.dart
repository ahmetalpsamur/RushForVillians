import '../constants/game_constants.dart';

/// Bir adım partisinin hız kontrolünden geçmiş hâli.
class StepBatchVerdict {
  /// Oyuna işlenecek adım.
  final int accepted;

  /// İmkânsız hız yüzünden **yakılan** adım. Bir sonraki rapora taşınmaz;
  /// aksi halde telefonu sallayan kullanıcı adımları yalnızca geciktirmiş
  /// olurdu.
  final int discarded;

  const StepBatchVerdict({required this.accepted, required this.discarded});

  static const none = StepBatchVerdict(accepted: 0, discarded: 0);

  /// Partinin bir kısmı hız sınırına takıldı mı.
  bool get rateExceeded => discarded > 0;
}

/// [reportedSteps] kadar adımın, aradan [elapsed] süre geçmişken ne kadarının
/// gerçek olabileceğine karar verir.
///
/// İzin verilen adım = geçen sürenin [GameConstants.maxStepsPerMinute] ile
/// çarpımı, en az [GameConstants.stepBurstAllowance]. Taban izin, gecikmeli
/// gelen sensör partilerinin haksız kırpılmasını önler.
///
/// Bu, [calculateStepCoins] ile aynı desende saf bir domain kuralıdır: sensör
/// ya da platform bilmez, yalnızca sayı ve süre görür. Sensörün kendi
/// arızasını (sıfırlanma) düzeltmek kaynağın işidir; burada yalnızca
/// "insan bu kadar adımı bu sürede atabilir mi" sorusu cevaplanır.
///
/// Gerçek zamana tabi olmayan kaynaklar (demo kontrolleri, bkz.
/// `StepSource.isPhysical`) bu fonksiyondan geçirilmez.
StepBatchVerdict limitStepBatch({
  required int reportedSteps,
  required Duration elapsed,
}) {
  if (reportedSteps <= 0) return StepBatchVerdict.none;

  // Negatif süre: cihaz saati geriye alınmış olabilir. Taban izin yine de
  // verilir, böylece gerçek yürüyüş tamamen durmaz.
  // Hesap milisaniye üzerinden: saniyeye yuvarlamak kısa aralıklarda gerçek
  // adımları kırpıyordu.
  final millis = elapsed.inMilliseconds < 0 ? 0 : elapsed.inMilliseconds;
  final earned = (millis * GameConstants.maxStepsPerMinute) ~/ 60000;
  final allowance =
      earned > GameConstants.stepBurstAllowance
          ? earned
          : GameConstants.stepBurstAllowance;

  if (reportedSteps <= allowance) {
    return StepBatchVerdict(accepted: reportedSteps, discarded: 0);
  }
  return StepBatchVerdict(
    accepted: allowance,
    discarded: reportedSteps - allowance,
  );
}
