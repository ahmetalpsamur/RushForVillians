import 'item_effect.dart';

/// Demircide **yeniden atılmış** tek bir etki (Bölüm E / Faz 4).
///
/// Eşyanın buff'ları bir dönem hiç diske yazılmıyordu: her açılışta
/// katalogdan türüyordu. Yeniden atma örnek başına bir sonuç ürettiği için o
/// sonuç saklanmak zorunda. Saklanan şey üç sayı: stat, kademe, değer.
///
/// **Model Kuralları #1 temiz:** Flutter tipi yok; stat kendi enum adıyla
/// yazılıyor. Değer **Sv. 1** değeridir — eşya seviyesinin savaş statlarına
/// verdiği büyüme her çözümlemede ayrıca uygulanır (`scaleForLevel`), yani
/// yükseltme yeniden atılmış etkiyi de büyütür.
class ForgedEffect {
  final ItemStat stat;

  /// Kademe, 1'den başlar (`data/forge_tiers.dart`).
  final int tier;

  /// Kademe aralığından çekilen değer: yüzdeli statlarda oran (0.04 = %4),
  /// sabit statlarda sayı.
  final double value;

  const ForgedEffect({
    required this.stat,
    required this.tier,
    required this.value,
  });

  /// Keşif havuzundaki anahtarı: `<stat>:<kademe>`. Oyuncu çapında saklanır
  /// (`UserProfile.discoveredAffixes`).
  String get affixKey => forgeAffixKey(stat, tier);

  Map<String, dynamic> toJson() => {
    'stat': stat.name,
    'tier': tier,
    'value': value,
  };

  /// Bozuk satır `null` döner; çağıran taraf onu atar.
  static ForgedEffect? fromJson(Object? json) {
    if (json is! Map) return null;
    final stat = statFromName(json['stat']);
    final tier = json['tier'];
    final value = json['value'];
    if (stat == null || tier is! int || tier < 1 || value is! num) return null;
    return ForgedEffect(stat: stat, tier: tier, value: value.toDouble());
  }

  static ItemStat? statFromName(Object? name) {
    if (name is! String) return null;
    for (final stat in ItemStat.values) {
      if (stat.name == name) return stat;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is ForgedEffect &&
      other.stat == stat &&
      other.tier == tier &&
      other.value == value;

  @override
  int get hashCode => Object.hash(stat, tier, value);

  @override
  String toString() => 'ForgedEffect(${stat.name} K$tier $value)';
}

/// Atılmış ama henüz **karar verilmemiş** bir sonuç.
///
/// Para atışta ödeniyor (aksi hâlde sonucu görüp bedava vazgeçmek mümkün
/// olurdu); oyuncu yeni etkiyi alır ya da eskisini korur. Karar verilene
/// kadar sonuç diskte durur: uygulama arada kapanırsa ödenmiş atış
/// kaybolmaz, demirci açılınca karar yeniden sorulur.
class PendingForge {
  /// Yeniden atılabilir yuvalar içindeki sıra (imzalı etkiler hariç).
  final int slot;
  final ForgedEffect effect;

  const PendingForge({required this.slot, required this.effect});

  Map<String, dynamic> toJson() => {'slot': slot, 'effect': effect.toJson()};

  static PendingForge? fromJson(Object? json) {
    if (json is! Map) return null;
    final slot = json['slot'];
    final effect = ForgedEffect.fromJson(json['effect']);
    if (slot is! int || slot < 0 || effect == null) return null;
    return PendingForge(slot: slot, effect: effect);
  }
}

/// Keşif anahtarı.
String forgeAffixKey(ItemStat stat, int tier) => '${stat.name}:$tier';
