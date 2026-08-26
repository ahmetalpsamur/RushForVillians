import '../constants/game_constants.dart';

/// Bir adım partisinin XP'ye çevrilmesinin sonucu.
class StepXpReward {
  /// Oyuncuya verilen XP.
  final int xp;

  /// XP'ye çevrilmiş sayılan adım. Bekleyen adım işaretçisi bu kadar
  /// ilerletilir; bir XP'ye yetmeyen artık adımlar bir sonraki hesaba kalır.
  final int consumedSteps;

  const StepXpReward({required this.xp, required this.consumedSteps});

  static const none = StepXpReward(xp: 0, consumedSteps: 0);
}

/// Henüz XP'ye çevrilmemiş [pendingSteps] adımı XP'ye çevirir.
///
/// [calculateStepCoins] ile aynı desende saf bir domain fonksiyonu, ama iki
/// bilinçli farkı var:
///
/// 1. **Günlük tavan yok.** Adım parası gibi XP de fiziksel hız denetimini
///    geçen tüm yürüyüş boyunca kazanılmaya devam eder. Sahte adıma karşı
///    koruma `limitStepBatch` içinde, akışın daha yukarısında yapılıyor.
/// 2. **Ayrı işaretçi kullanır.** Para ve XP aynı `lastRewardedStepCount`
///    üzerinden yürüseydi, farklı dönüşüm oranları bir işaretçinin diğer
///    ödüle ait artık adımları tüketmesine ve XP'nin kaybolmasına yol açardı.
///
/// [multiplier] kuşanılan itemlerin adım-XP bonusudur
/// ([EquippedBuffs.stepXpMultiplier]). Yalnızca ödemeyi büyütür, tüketilen
/// adımı değiştirmez.
StepXpReward calculateStepXp({
  required int pendingSteps,
  double multiplier = 1.0,
}) {
  if (pendingSteps <= 0) return StepXpReward.none;

  final rawXp = pendingSteps ~/ GameConstants.stepsPerXp;
  if (rawXp == 0) return StepXpReward.none;

  return StepXpReward(
    xp: (rawXp * multiplier).floor(),
    consumedSteps: rawXp * GameConstants.stepsPerXp,
  );
}
