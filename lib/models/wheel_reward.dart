import 'item.dart';

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

  /// Item ödülüyse item, XP ödülüyse `null`.
  final Item? item;

  const WheelReward.xp(this.xp) : item = null;

  const WheelReward.item(Item this.item) : xp = 0;

  bool get isItem => item != null;

  /// Dilim üzerinde ve sonuç kartında görünen kısa metin.
  String get label => item?.name ?? '+$xp XP';

  @override
  String toString() => 'WheelReward(${isItem ? item!.id : '$xp XP'})';
}
