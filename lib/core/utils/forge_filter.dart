/// Demirci listesinin **saf** süzme ve sıralama kuralları (Bölüm E / Faz 3).
///
/// Projedeki desen: kural ekrandan ve state'ten ayrı, test edilebilir bir
/// fonksiyonda yaşar. Ekran her grubu bir [ForgeGroupFacts]'e çevirir ve
/// buradan geçirir; ikinci bir süzme hesabı yazılmaz.
///
/// Seçim **oturum** boyunca hatırlanır (`RootShell` bir `ValueNotifier`
/// tutuyor) ama diske yazılmaz: bu bir oyun ilerlemesi değil, bir görünüm
/// tercihi — GD86'daki dil tercihiyle aynı ayrım, şemaya girmez.
library;

import '../../models/item.dart';
import '../../models/reward_rarity.dart';

/// Ad sıralaması için alfabe anahtarı.
///
/// `toLowerCase().compareTo` kod noktasına göre sıralıyor ve Türkçe
/// harfleri alfabenin sonuna atıyordu: "Çekiç" "Zırh"tan **sonra**
/// geliyordu (eski demirci sırası da böyleydi, ölçüldü). Burada her Türkçe
/// harf, temel harfinin hemen arkasına düşen bir anahtara çevriliyor:
/// `ç` → `c{` (c'li bütün adlardan sonra, d'den önce), `ı` → `h{` (ı, i'den
/// önce gelir). İngilizce adlarda bu harfler geçmediği için sıra değişmez.
///
/// Büyük `I` **i** sayılıyor: anahtar dili bilmiyor ve İngilizce "Iron"
/// bozulmamalı. Takas: Türkçede `I` ile başlayan nadir bir ad ı'lı değil
/// i'li adların arasına düşer.
String forgeNameSortKey(String name) {
  final buffer = StringBuffer();
  for (final rune in name.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(switch (char) {
      'I' || 'İ' || 'i' => 'i',
      'ı' => 'h{',
      'Ç' || 'ç' => 'c{',
      'Ğ' || 'ğ' => 'g{',
      'Ö' || 'ö' => 'o{',
      'Ş' || 'ş' => 's{',
      'Ü' || 'ü' => 'u{',
      _ => char.toLowerCase(),
    });
  }
  return buffer.toString();
}

/// Kuşanma süzgeci.
enum ForgeEquipFilter {
  /// Süzgeç yok.
  any,

  /// Grubun en az bir adedi kuşanılı.
  equipped,

  /// Grubun hiçbir adedi kuşanılı değil.
  unequipped,
}

/// Sıralama ölçütü.
enum ForgeSort {
  /// Nadirlik (yüksekten alçağa) — varsayılan; ekranın eski sırası.
  rarity,

  /// En gelişmiş adedin seviyesi (yüksekten alçağa).
  level,

  /// Gösterilen ad (A→Z). Ham alan değil, `l10n.itemName` (GD92).
  name,

  /// Bir sonraki yükseltmenin maliyeti (ucuzdan pahalıya); tavana ulaşmış
  /// gruplar sona.
  upgradeCost,
}

/// Bir grubun süzme ve sıralama için gereken gerçekleri. Ekran üretir.
class ForgeGroupFacts {
  /// Kararlı anahtar (`<itemId>|<nadirlik>`): eşitlikte son söz.
  final String key;
  final RewardRarity rarity;
  final ItemCategory category;

  /// Gösterilen (yerelleştirilmiş) ad.
  final String name;
  final int bestLevel;
  final bool anyEquipped;

  /// Yükseltilebilir: yeterli altın var ve hiçbir tavana ulaşılmamış.
  final bool canUpgrade;

  /// Birleştirilebilir: yeterli kopya var (altından bağımsız).
  final bool hasMergeCopies;

  /// Bir sonraki yükseltmenin maliyeti; tavana ulaşılmışsa `null`.
  final int? nextUpgradeCost;

  const ForgeGroupFacts({
    required this.key,
    required this.rarity,
    required this.category,
    required this.name,
    required this.bestLevel,
    required this.anyEquipped,
    required this.canUpgrade,
    required this.hasMergeCopies,
    required this.nextUpgradeCost,
  });
}

/// Ekranda görünen **tek** süzgeç ölçütü — bir çip.
///
/// Çiplerin sayısı "Filtrele (n)" düğmesindeki sayıdır; ikisi aynı
/// kaynaktan gelir ki düğme ile çip satırı asla çelişmesin.
sealed class ForgeCriterion {
  const ForgeCriterion();

  bool matches(ForgeGroupFacts facts);
}

class RarityCriterion extends ForgeCriterion {
  final RewardRarity rarity;
  const RarityCriterion(this.rarity);

  // Seçili nadirliklerden **biri** yeter; asıl birleşim [ForgeFilter]'da.
  @override
  bool matches(ForgeGroupFacts facts) => facts.rarity == rarity;
}

class CategoryCriterion extends ForgeCriterion {
  final ItemCategory category;
  const CategoryCriterion(this.category);

  @override
  bool matches(ForgeGroupFacts facts) => facts.category == category;
}

class EquipCriterion extends ForgeCriterion {
  final ForgeEquipFilter equip;
  const EquipCriterion(this.equip);

  @override
  bool matches(ForgeGroupFacts facts) => switch (equip) {
    ForgeEquipFilter.any => true,
    ForgeEquipFilter.equipped => facts.anyEquipped,
    ForgeEquipFilter.unequipped => !facts.anyEquipped,
  };
}

class UpgradableCriterion extends ForgeCriterion {
  const UpgradableCriterion();

  @override
  bool matches(ForgeGroupFacts facts) => facts.canUpgrade;
}

class MergeableCriterion extends ForgeCriterion {
  const MergeableCriterion();

  @override
  bool matches(ForgeGroupFacts facts) => facts.hasMergeCopies;
}

/// Demirci listesinin süzgeç + sıralama seçimi. Değişmez.
class ForgeFilter {
  /// Boş = hepsi.
  final Set<RewardRarity> rarities;

  /// Boş = hepsi.
  final Set<ItemCategory> categories;
  final ForgeEquipFilter equip;
  final bool upgradableOnly;
  final bool mergeableOnly;
  final ForgeSort sort;

  const ForgeFilter({
    this.rarities = const {},
    this.categories = const {},
    this.equip = ForgeEquipFilter.any,
    this.upgradableOnly = false,
    this.mergeableOnly = false,
    this.sort = ForgeSort.rarity,
  });

  /// Süzgeçleri temizler, **sıralamayı korur**: sıralama bir süzgeç değil,
  /// "neden az eşya görüyorum" sorusunun cevabı değil.
  ForgeFilter cleared() => ForgeFilter(sort: sort);

  ForgeFilter copyWith({
    Set<RewardRarity>? rarities,
    Set<ItemCategory>? categories,
    ForgeEquipFilter? equip,
    bool? upgradableOnly,
    bool? mergeableOnly,
    ForgeSort? sort,
  }) => ForgeFilter(
    rarities: rarities ?? this.rarities,
    categories: categories ?? this.categories,
    equip: equip ?? this.equip,
    upgradableOnly: upgradableOnly ?? this.upgradableOnly,
    mergeableOnly: mergeableOnly ?? this.mergeableOnly,
    sort: sort ?? this.sort,
  );

  /// Bir çipi kaldırır.
  ForgeFilter without(ForgeCriterion criterion) => switch (criterion) {
    RarityCriterion(:final rarity) => copyWith(
      rarities: {...rarities}..remove(rarity),
    ),
    CategoryCriterion(:final category) => copyWith(
      categories: {...categories}..remove(category),
    ),
    EquipCriterion() => copyWith(equip: ForgeEquipFilter.any),
    UpgradableCriterion() => copyWith(upgradableOnly: false),
    MergeableCriterion() => copyWith(mergeableOnly: false),
  };

  /// Etkin ölçütler, ekrandaki çip sırasıyla. Sıra sabit: nadirlik, tür,
  /// kuşanma, durum.
  List<ForgeCriterion> get criteria => [
    for (final rarity in RewardRarity.values)
      if (rarities.contains(rarity)) RarityCriterion(rarity),
    for (final category in ItemCategory.values)
      if (categories.contains(category)) CategoryCriterion(category),
    if (equip != ForgeEquipFilter.any) EquipCriterion(equip),
    if (upgradableOnly) const UpgradableCriterion(),
    if (mergeableOnly) const MergeableCriterion(),
  ];

  /// "Filtrele (n)" düğmesindeki sayı.
  int get activeCount => criteria.length;

  bool get isActive => activeCount > 0;

  /// Bir grup bütün süzgeçlerden geçiyor mu.
  ///
  /// Aynı türden ölçütler **veya**, farklı türler **ve** ile birleşir:
  /// "Nadir + Epik" iki nadirliği de gösterir; "Nadir + Kılıç" yalnızca nadir
  /// kılıçları.
  bool accepts(ForgeGroupFacts facts) {
    if (rarities.isNotEmpty && !rarities.contains(facts.rarity)) return false;
    if (categories.isNotEmpty && !categories.contains(facts.category)) {
      return false;
    }
    if (!EquipCriterion(equip).matches(facts)) return false;
    if (upgradableOnly && !facts.canUpgrade) return false;
    if (mergeableOnly && !facts.hasMergeCopies) return false;
    return true;
  }

  /// Süzer ve sıralar. Girdi değişmez; yeni liste döner.
  List<ForgeGroupFacts> apply(Iterable<ForgeGroupFacts> groups) {
    final result = groups.where(accepts).toList()..sort(_compare);
    return result;
  }

  int _compare(ForgeGroupFacts a, ForgeGroupFacts b) {
    int byRarity() => b.rarity.index.compareTo(a.rarity.index);
    int byLevel() => b.bestLevel.compareTo(a.bestLevel);
    int byName() => forgeNameSortKey(a.name).compareTo(forgeNameSortKey(b.name));
    int byCost() {
      final aCost = a.nextUpgradeCost;
      final bCost = b.nextUpgradeCost;
      if (aCost == null && bCost == null) return 0;
      if (aCost == null) return 1;
      if (bCost == null) return -1;
      return aCost.compareTo(bCost);
    }

    final order = switch (sort) {
      ForgeSort.rarity => [byRarity, byLevel, byName],
      ForgeSort.level => [byLevel, byRarity, byName],
      ForgeSort.name => [byName, byRarity, byLevel],
      ForgeSort.upgradeCost => [byCost, byRarity, byName],
    };
    for (final compare in order) {
      final result = compare();
      if (result != 0) return result;
    }
    return a.key.compareTo(b.key);
  }

  /// Sonuç boşsa **hangi** ölçüt boşalttı.
  ///
  /// Tek başına hiçbir grubu geçirmeyen ilk ölçüt döner ("hiç epik eşyan
  /// yok"). Her ölçüt tek başına bir şey geçiriyor ama birleşimleri
  /// boşsa `null` döner; ekran o zaman birleşimi söyler.
  ForgeCriterion? blockingCriterion(Iterable<ForgeGroupFacts> groups) {
    final all = groups.toList();
    for (final criterion in criteria) {
      final alone = switch (criterion) {
        RarityCriterion() => all.where(
          (facts) => rarities.contains(facts.rarity),
        ),
        CategoryCriterion() => all.where(
          (facts) => categories.contains(facts.category),
        ),
        _ => all.where(criterion.matches),
      };
      if (alone.isEmpty) return criterion;
    }
    return null;
  }
}
