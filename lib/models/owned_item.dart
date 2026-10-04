import 'forged_effect.dart';
import 'reward_rarity.dart';

/// Envanterdeki **tek bir eşya örneği**.
///
/// Envanter artık bir kimlik listesi değil: aynı eşyadan birden fazla adet
/// bulunabiliyor ve her adedin kendi seviyesi, kendi nadirliği ve kendi
/// kuşanma durumu var. Birleştirme (demirci) aynı eşyanın birkaç adedini
/// tüketip bir üst nadirlikte tek bir örnek ürettiği için bu şart.
///
/// **Model Kuralları #1 temiz:** burada hiçbir Flutter tipi yok. Kalıcı olan
/// tek şey [itemId] + sayılar; item'ın kendisi (ad, görsel, buff) her açılışta
/// katalogdan çözülüyor ve oyuncunun sınıfına uyarlanıyor.
///
/// Serileştirme elle yazıldı (proje `build_runner` kullanmıyor).
class OwnedItem {
  /// Bu örneğin benzersiz kimliği.
  ///
  /// Aynı eşyadan üç adet varsa üçü de aynı [itemId]'yi taşır; "hangisini
  /// yükselt / sat / kuşan" sorusunun cevabı bu sayı. Liste indeksi
  /// kullanılamazdı: envanter ekranı her çizimde durumu yeniden okuyor
  /// (GD27) ve indeks aradaki bir değişiklikte kayabilir.
  ///
  /// [UserProfile.nextItemInstanceId] sayacından geliyor — rastgele değil,
  /// böylece kayıt tekrarlanabilir ve tohum gerektirmiyor.
  final int instanceId;

  /// Katalog kimliği: `<kategori klasörü>/<dosya adı>`.
  final String itemId;

  /// Eşya seviyesi. Her örnek **1**'de başlar; oyuncu coin harcayarak
  /// yükseltir. Otomatik seviye atlama yok.
  final int level;

  /// Birleştirmeyle **yükseltilmiş** nadirlik.
  ///
  /// `null` = "katalog nadirliği", yani başlangıç nadirliği. Bilerek
  /// nullable: eski kayıtların taşınması katalogu okumadan yapılabiliyor
  /// (taşıma anında `AssetManifest` yok) ve katalog nadirliği ileride
  /// dengelenirse birleştirilmemiş örnekler onu izliyor.
  final RewardRarity? rarity;

  /// Bu örnek kuşanılı mı.
  ///
  /// Slot, [itemId]'nin kategorisinden çıkıyor; "slot başına tek örnek"
  /// kuralını `RootShell._refreshEquipment` normalleştiriyor.
  final bool equipped;

  /// Demircide yeniden atılmış etkiler (Bölüm E / Faz 4).
  ///
  /// **`null` = türetilmiş**: eşya hiç yeniden atılmadı ve buff'ı her
  /// açılışta katalogdan çözülüyor — E1'in geriye dönük düzeltmesi bu
  /// eşyalara olduğu gibi ulaşmaya devam ediyor. Dolu olduğunda imzalı
  /// etkiler **hariç**, yeniden atılabilir yuvaların sırasıyla aynı uzunlukta.
  final List<ForgedEffect>? forgedEffects;

  /// Bu **örneğe** yapılmış yeniden atma sayısı. Maliyet bununla artıyor ve
  /// sıfırlanmıyor; eşya türüne değil örneğe bağlı.
  final int rerollCount;

  /// Atılmış ama karar verilmemiş sonuç; yoksa `null`.
  final PendingForge? pendingForge;

  const OwnedItem({
    required this.instanceId,
    required this.itemId,
    this.level = 1,
    this.rarity,
    this.equipped = false,
    this.forgedEffects,
    this.rerollCount = 0,
    this.pendingForge,
  });

  /// Bu örneğin geçerli nadirliği: birleştirilmişse yükseltilmiş nadirlik,
  /// değilse katalogdan gelen başlangıç nadirliği.
  RewardRarity effectiveRarity(RewardRarity catalogRarity) =>
      rarity ?? catalogRarity;

  /// [clearPending] karar verilmiş atışı siler (`null` ile "değiştirme"
  /// ayırt edilemediği için ayrı bayrak).
  OwnedItem copyWith({
    int? level,
    RewardRarity? rarity,
    bool? equipped,
    List<ForgedEffect>? forgedEffects,
    int? rerollCount,
    PendingForge? pendingForge,
    bool clearPending = false,
  }) => OwnedItem(
    instanceId: instanceId,
    itemId: itemId,
    level: level ?? this.level,
    rarity: rarity ?? this.rarity,
    equipped: equipped ?? this.equipped,
    forgedEffects: forgedEffects ?? this.forgedEffects,
    rerollCount: rerollCount ?? this.rerollCount,
    pendingForge: clearPending ? null : (pendingForge ?? this.pendingForge),
  );

  /// Yeni alanlar **yalnızca doluysa** yazılır: hiç yeniden atılmamış bir
  /// örneğin satırı Bölüm E öncesiyle bit bit aynı kalır.
  Map<String, dynamic> toJson() => {
    'instanceId': instanceId,
    'itemId': itemId,
    'level': level,
    'rarity': rarity?.name,
    'equipped': equipped,
    if (forgedEffects case final effects?)
      'forgedEffects': [for (final effect in effects) effect.toJson()],
    if (rerollCount > 0) 'rerollCount': rerollCount,
    if (pendingForge case final pending?) 'pendingForge': pending.toJson(),
  };

  /// Bozuk bir satır `null` döner; çağıran taraf onu atar ve sağlam
  /// satırları korur (elle düzenlenmiş kayıt bütün envanteri yakmamalı).
  static OwnedItem? fromJson(Object? json) {
    if (json is! Map) return null;
    final itemId = json['itemId'];
    final instanceId = json['instanceId'];
    if (itemId is! String || itemId.isEmpty) return null;
    if (instanceId is! int) return null;

    final level = json['level'];
    final forged = json['forgedEffects'];
    final parsedForged =
        forged is List
            ? [
              for (final row in forged)
                if (ForgedEffect.fromJson(row) case final effect?) effect,
            ]
            : null;
    final rerolls = json['rerollCount'];
    return OwnedItem(
      instanceId: instanceId,
      itemId: itemId,
      // Seviye hiçbir koşulda 1'in altına düşmez.
      level: level is int && level >= 1 ? level : 1,
      rarity: rarityFromName(json['rarity']),
      equipped: json['equipped'] == true,
      // Bozuk bir satır listeyi kısaltırsa çözümleme uzunluk uyuşmazlığını
      // görüp türetilmiş buff'a düşer; eşya kaybolmaz.
      forgedEffects:
          parsedForged != null && parsedForged.length == (forged as List).length
              ? parsedForged
              : null,
      rerollCount: rerolls is int && rerolls > 0 ? rerolls : 0,
      pendingForge: PendingForge.fromJson(json['pendingForge']),
    );
  }

  /// Kayıttaki nadirlik adını çözer. Tanınmayan ad `null` döner: örnek
  /// katalog nadirliğine düşer, kayıt reddedilmez.
  static RewardRarity? rarityFromName(Object? name) {
    if (name is! String) return null;
    for (final rarity in RewardRarity.values) {
      if (rarity.name == name) return rarity;
    }
    return null;
  }

  @override
  String toString() =>
      'OwnedItem(#$instanceId $itemId Sv.$level'
      '${rarity == null ? '' : ' ${rarity!.name}'}'
      '${equipped ? ' kuşanılı' : ''})';
}
