import '../constants/game_constants.dart';

/// Bir adım partisinin paraya çevrilmesinin sonucu.
class StepCoinReward {
  /// Oyuncuya verilen para.
  final int coins;

  /// Paraya çevrilmiş sayılan adım. Bekleyen adım işaretçisi bu kadar
  /// ilerletilir; bir coin'e yetmeyen artık adımlar bir sonraki hesaba kalır.
  final int consumedSteps;

  /// Eski çağrı noktaları için korunur; günlük kazanç tavanı
  /// kaldırıldığından hesaplayıcı her zaman `false` döndürür.
  final bool capReached;

  const StepCoinReward({
    required this.coins,
    required this.consumedSteps,
    required this.capReached,
  });

  static const none = StepCoinReward(
    coins: 0,
    consumedSteps: 0,
    capReached: false,
  );
}

/// Henüz paraya çevrilmemiş [pendingSteps] adımı paraya çevirir.
///
/// Günlük kazanç tavanı yoktur. Bir coin'e yetmeyen adımlar tüketilmez;
/// sonraki sensör partisinde değerlendirilmeye devam eder.
///
/// [coinsEarnedToday] ve [dailyCap] eski çağrı noktalarını bir anda
/// kırmamak için geçici olarak imzada tutulur, fakat ödemeyi kırpmaz.
/// Adım → para oranı [GameConstants] içinde; burada sabit yok.
///
/// [stepsPerCoin] verilmezse [GameConstants.stepsPerCoin] kullanılır. Macera
/// yürüyüş fazında (Bölüm A.3) çağıran taraf
/// [GameConstants.walkPhaseStepsPerCoin] geçirir; oran **yalnızca ödemeyi**
/// değil tüketilen adımı da belirler, çünkü 30 adım gerçekten 1 coin eder.
///
/// [multiplier] kuşanılan itemlerin adım-para bonusudur
/// ([EquippedBuffs.stepCoinMultiplier]). Yalnızca **ödemeyi** büyütür,
/// tüketilen adımı değiştirmez — buff, adımı daha değerli yapar, daha çok
/// adım harcatmaz.
///
StepCoinReward calculateStepCoins({
  required int pendingSteps,
  int coinsEarnedToday = 0,
  double multiplier = 1.0,
  int? dailyCap,
  int? stepsPerCoin,
}) {
  if (pendingSteps <= 0) return StepCoinReward.none;

  final rate = stepsPerCoin ?? GameConstants.stepsPerCoin;
  if (rate <= 0) return StepCoinReward.none;

  final rawCoins = pendingSteps ~/ rate;
  if (rawCoins == 0) return StepCoinReward.none;

  // Negatif/NaN bir çarpan ekonomiden para silemez. Normal oyun akışında
  // çarpan >= 1'dir; bu koruma saf fonksiyonun sınır girdileri içindir.
  final safeMultiplier = multiplier.isFinite && multiplier > 0 ? multiplier : 0;
  final grantedCoins = (rawCoins * safeMultiplier).floor();

  return StepCoinReward(
    coins: grantedCoins,
    consumedSteps: rawCoins * rate,
    capReached: false,
  );
}
