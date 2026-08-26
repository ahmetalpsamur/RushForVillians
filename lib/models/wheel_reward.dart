import 'game_title.dart';
import 'item.dart';
import 'reward_rarity.dart';

/// Günlük çarkın bir diliminde duran ödül (#16).
///
/// **Kalıcı değildir:** çevirir çevirmez tüketilir — XP profile eklenir, item
/// [UserProfile.ownedItemIds] içine kimliğiyle yazılır. Bu yüzden burada bir
/// [Item] tutmak Model Kuralları #1'i ihlal etmiyor; diske giden şey yalnızca
/// `item.id`.
///
/// Çarkta **boş dilim yoktur**: her dilim ya XP ya item verir.
class WheelReward {
  /// XP ödülüyse miktarı, item ödülüyse 0.
  final int xp;

  /// Item ödülüyse item, değilse `null`.
  final Item? item;

  /// Ünvan ödülüyse ünvan, değilse `null` (Bölüm C.4).
  ///
  /// [Item] ile aynı gerekçeyle burada tutulabiliyor: ödül çevirir çevirmez
  /// tüketiliyor ve diske giden tek şey `title.id`.
  final GameTitle? title;

  const WheelReward.xp(this.xp) : item = null, title = null;

  const WheelReward.item(Item this.item) : xp = 0, title = null;

  const WheelReward.title(GameTitle this.title) : xp = 0, item = null;

  bool get isItem => item != null;

  bool get isTitle => title != null;

  /// Ödülün nadirliği; XP diliminde `null`.
  RewardRarity? get rarity => item?.rarity ?? title?.rarity;

  /// Dilim üzerinde ve sonuç kartında görünen kısa metin.
  String get label => item?.name ?? title?.name ?? '+$xp XP';

  @override
  String toString() =>
      'WheelReward(${item?.id ?? title?.id ?? '$xp XP'})';
}
