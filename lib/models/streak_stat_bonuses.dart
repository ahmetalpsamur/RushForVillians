import '../core/constants/game_constants.dart';
import 'item_effect.dart';

/// Günlük serinin biriktirdiği **savaş** stat bonusları.
///
/// Her seri günü havuzdan bir stat seçilir ve o stata o günün basamak
/// kazancı eklenir. Kazanç sabit değil: her [GameConstants.streakBonusTierLength]
/// günde bir azalır, tablonun sonunda başa döner (Bölüm B).
///
/// **Birikim binde cinsinden tam sayı tutulur, oran değil.** 0.005'i yüz kez
/// toplamak 0.5 etmiyor; tur attıkça sapma büyüyordu ve tavan/eşik
/// karşılaştırmaları kayıyordu. Aynı gerekçeyle Bölüm 5C'de gün sayısı
/// tutuluyordu — gün başına kazanç artık sabit olmadığı için gün sayısı
/// yetmiyor.
///
/// **Tavan yok** (Bölüm B): ne stat başına ne toplamda. Tek bir statın uçup
/// gitmesini engelleyen şey, çekilişin geride kalan statı kayırması
/// ([drawWeights]). Sert bir stat tavanı, toplam tavan kalkınca uzun seride
/// bütün statları tavana oturtur ve her günü boşa çıkarırdı.
///
/// Model Kuralları #1 temiz: yalnızca `String` anahtar ve `int` tutulur,
/// [ItemStat] bir düz Dart enum'u ve diske adıyla yazılır.
class StreakStatBonuses {
  /// Stat -> o stata birikmiş bonus, **binde** cinsinden (5 = +%0,5).
  final Map<ItemStat, int> tenths;

  const StreakStatBonuses._(this.tenths);

  static const StreakStatBonuses empty = StreakStatBonuses._({});

  factory StreakStatBonuses(Map<ItemStat, int> tenths) {
    final cleaned = <ItemStat, int>{};
    for (final entry in tenths.entries) {
      if (!entry.key.isCombat) continue;
      if (entry.value > 0) cleaned[entry.key] = entry.value;
    }
    return StreakStatBonuses._(Map.unmodifiable(cleaned));
  }

  /// Seri bonusunun dağıtıldığı havuz: **savaş** statlarının tamamı.
  ///
  /// Ekonomi statları (adım parası, adım XP, çark XP...) bilerek dışarıda:
  /// ekonomi ölçülmüş bir dengeye bağlı ve tavansız büyüyen bir para çarpanı
  /// onu tamamen çökertir. Havuz `isCombat`'tan türetiliyor, elle yazılmıyor
  /// — savaş motoru yeni bir stat eklerse havuz kendiliğinden genişler.
  static final List<ItemStat> pool = List.unmodifiable([
    for (final stat in ItemStat.values)
      if (stat.isCombat) stat,
  ]);

  /// Bir seri gününün kazancı, binde cinsinden.
  ///
  /// [streakDay] 1'den başlar. Basamak tablosu tur attığı için 501. gün
  /// yeniden ilk basamağa döner — 500 günü geçmek bir ödül.
  static int tenthsForDay(int streakDay) {
    final tiers = GameConstants.streakBonusTierTenths;
    if (streakDay < 1 || tiers.isEmpty) return 0;
    final length = GameConstants.streakBonusTierLength;
    if (length < 1) return tiers.first;
    return tiers[((streakDay - 1) ~/ length) % tiers.length];
  }

  /// [streakDay] hangi basamakta (0 tabanlı).
  static int tierIndexForDay(int streakDay) {
    final tiers = GameConstants.streakBonusTierTenths;
    if (streakDay < 1 || tiers.isEmpty) return 0;
    final length = GameConstants.streakBonusTierLength;
    if (length < 1) return 0;
    return ((streakDay - 1) ~/ length) % tiers.length;
  }

  /// [streakDay] döngünün başa döndüğü gün mü ("501. günde %0,5'e döndü").
  ///
  /// İlk turun 1. günü kutlanmaz: kutlanacak şey **geri dönmek**.
  static bool isCycleRestartDay(int streakDay) {
    final tiers = GameConstants.streakBonusTierTenths;
    final length = GameConstants.streakBonusTierLength;
    if (streakDay < 1 || tiers.isEmpty || length < 1) return false;
    final cycle = length * tiers.length;
    return streakDay > cycle && (streakDay - 1) % cycle == 0;
  }

  /// Oranı kullanıcıya görünen biçimde yazar: 0.005 -> "0,5", 0.03 -> "3".
  ///
  /// Tam sayıya yuvarlamak gün başına kazancı (+%0,5) sıfır ya da 1
  /// gösterirdi; basamak tablosunun tamamı binde mertebesinde.
  static String formatRate(double rate) {
    final percent = rate * 100;
    final rounded = (percent * 10).round() / 10;
    if (rounded == rounded.roundToDouble()) return rounded.toStringAsFixed(0);
    return rounded.toStringAsFixed(1).replaceAll('.', ',');
  }

  /// [stat]'a birikmiş binde.
  int tenthsFor(ItemStat stat) => tenths[stat] ?? 0;

  /// [stat]'ın seriden gelen oran bonusu (0.03 = +%3).
  double bonusFor(ItemStat stat) => tenthsFor(stat) / 1000;

  /// Dağıtılmış toplam binde.
  int get totalTenths => tenths.values.fold(0, (sum, value) => sum + value);

  /// Seriden gelen toplam oran.
  double get totalBonus => totalTenths / 1000;

  bool get isEmpty => tenths.isEmpty;

  /// Çekiliş ağırlıkları: [pool] ile aynı sırada, hepsi >= 1.
  ///
  /// Geride kalan stat kayrılır ama lider hiçbir zaman çekilişten düşmez;
  /// üstünlük [GameConstants.streakBonusBalanceWeight] ile sınırlı.
  List<int> get drawWeights {
    var highest = 0;
    for (final stat in pool) {
      final value = tenthsFor(stat);
      if (value > highest) highest = value;
    }
    final boostCap = GameConstants.streakBonusBalanceWeight;
    return [
      for (final stat in pool)
        1 + (highest - tenthsFor(stat)).clamp(0, boostCap < 0 ? 0 : boostCap),
    ];
  }

  /// [stat]'a [amount] binde ekleyip yeni birikimi döner.
  StreakStatBonuses withGrant(ItemStat stat, int amount) {
    if (!stat.isCombat || amount <= 0) return this;
    return StreakStatBonuses({...tenths, stat: tenthsFor(stat) + amount});
  }

  /// Kayıt biçimi: `{statAdı: binde}`. Bilinmeyen ya da savaş dışı anahtarlar
  /// okuma sırasında sessizce atılır (elle düzenlenmiş kayda karşı savunma).
  Map<String, Object?> toJson() => {
    for (final entry in tenths.entries) entry.key.name: entry.value,
  };

  factory StreakStatBonuses.fromJson(Object? json) {
    if (json is! Map) return empty;
    final parsed = <ItemStat, int>{};
    for (final entry in json.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String || value is! int) continue;
      final stat = _statByName(key);
      if (stat == null) continue;
      parsed[stat] = value;
    }
    return StreakStatBonuses(parsed);
  }

  static ItemStat? _statByName(String name) {
    for (final stat in ItemStat.values) {
      if (stat.name == name) return stat;
    }
    return null;
  }
}
