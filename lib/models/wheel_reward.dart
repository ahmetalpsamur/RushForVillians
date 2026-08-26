import 'game_title.dart';
import 'item.dart';
import 'reward_rarity.dart';

/// Günlük çarkın bir diliminde duran ödül (#16).
///
/// **Kalıcı değildir:** çevirir çevirmez tüketilir — XP ve altın profile
/// eklenir, item ve ünvan kimliğiyle yazılır. Bu yüzden burada bir [Item]
/// tutmak Model Kuralları #1'i ihlal etmiyor; diske giden şey yalnızca
/// `item.id` / `title.id`.
///
/// Çarkta **boş dilim yoktur**: her dilim ya XP, ya altın, ya ekipman ya da
/// ünvan verir. Hangi dilimin hangi türde olacağı ve değerlerin dağılımı
/// `data/wheel_odds.dart` içindeki ağırlık tablolarından çıkar.
class WheelReward {
  /// XP ödülüyse miktarı, değilse 0.
  final int xp;

  /// Altın ödülüyse miktarı, değilse 0.
  final int coins;

  /// Item ödülüyse item, değilse `null`.
  final Item? item;

  /// Ünvan ödülüyse ünvan, değilse `null` (Bölüm C.4).
  final GameTitle? title;

  const WheelReward.xp(this.xp) : coins = 0, item = null, title = null;

  const WheelReward.coins(this.coins) : xp = 0, item = null, title = null;

  const WheelReward.item(Item this.item) : xp = 0, coins = 0, title = null;

  const WheelReward.title(GameTitle this.title)
    : xp = 0,
      coins = 0,
      item = null;

  bool get isItem => item != null;

  bool get isTitle => title != null;

  bool get isCoins => coins > 0;

  bool get isXp => xp > 0;

  /// Ödülün nadirliği; XP ve altın diliminde `null`.
  RewardRarity? get rarity => item?.rarity ?? title?.rarity;

  /// Dilim üzerinde ve sonuç kartında görünen kısa metin.
  String get label =>
      item?.name ?? title?.name ?? (isCoins ? '+$coins altın' : '+$xp XP');

  @override
  String toString() =>
      'WheelReward(${item?.id ?? title?.id ?? (isCoins ? '$coins altın' : '$xp XP')})';
}
