import '../constants/game_constants.dart';

/// Bir adım partisinin paraya çevrilmesinin sonucu.
class StepCoinReward {
  /// Oyuncuya verilen para.
  final int coins;

  /// Paraya çevrilmiş sayılan adım. Bekleyen adım işaretçisi bu kadar
  /// ilerletilir; bir coin'e yetmeyen artık adımlar bir sonraki hesaba kalır.
  final int consumedSteps;

  /// Bu hesapla günlük kazanç tavanı doldu mu.
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
/// [coinsEarnedToday] günün o ana kadarki **adım** kazancıdır; günlük tavan
/// buna göre uygulanır. Tavan dolduğunda kalan adımlar bilerek **taşınmaz**:
/// aksi halde adım biriktirip ertesi gün bozdurmak tavanı anlamsız kılardı.
///
/// Adım → para oranı ve tavan [GameConstants] içinde; burada sabit yok.
///
/// [multiplier] item buff'ları için bırakılmış çarpan noktasıdır. Yalnızca
/// ödemeyi büyütür, tüketilen adımı değiştirmez — buff, adımı daha değerli
/// yapar, daha çok adım harcatmaz.
// TODO(items): Aşama 3'te "adım başına +%X para" buff'ları (bkz. CLAUDE.md,
// kart #9) bu çarpandan geçecek. Şimdilik tüm çağıranlar 1.0 veriyor;
// buff sistemi henüz yok.
StepCoinReward calculateStepCoins({
  required int pendingSteps,
  required int coinsEarnedToday,
  double multiplier = 1.0,
}) {
  if (pendingSteps <= 0) return StepCoinReward.none;

  final remainingToday = (GameConstants.maxDailyStepCoins - coinsEarnedToday)
      .clamp(0, GameConstants.maxDailyStepCoins);

  if (remainingToday == 0) {
    // Tavan zaten dolu: adımlar tüketilir ama para kazandırmaz.
    return StepCoinReward(
      coins: 0,
      consumedSteps: pendingSteps,
      capReached: true,
    );
  }

  final rawCoins = pendingSteps ~/ GameConstants.stepsPerCoin;
  if (rawCoins == 0) return StepCoinReward.none;

  final grantedCoins = (rawCoins * multiplier).floor().clamp(0, remainingToday);
  final capReached = grantedCoins >= remainingToday;

  return StepCoinReward(
    coins: grantedCoins,
    // Tavana dayanıldıysa artık adımlar da tüketilir, yarına taşınmaz.
    consumedSteps:
        capReached ? pendingSteps : rawCoins * GameConstants.stepsPerCoin,
    capReached: capReached,
  );
}
