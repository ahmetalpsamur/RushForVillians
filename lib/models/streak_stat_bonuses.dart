import '../core/constants/game_constants.dart';
import 'item_effect.dart';

/// Günlük serinin biriktirdiği **savaş** stat bonusları.
///
/// Her seri günü havuzdan bir stat seçilir ve o stata
/// [GameConstants.streakStatBonusPerDay] kadar oran eklenir. Bu sınıf o
/// birikimi taşır: stat başına kaç gün kazanıldığını tutar, oranı türetir.
///
/// **Gün sayısı tutuluyor, oran değil.** Kayıt turunda kayan nokta birikmesin
/// ve tavan karşılaştırmaları tam olsun diye: `0.01` yirmi beş kez toplanınca
/// `0.25` etmiyor, `0.2499999…` ediyor ve stat tavana hiç oturmuyordu.
///
/// Model Kuralları #1 temiz: yalnızca `String` anahtar ve `int` tutulur,
/// [ItemStat] bir düz Dart enum'u ve diske adıyla yazılır.
class StreakStatBonuses {
  /// Stat -> o stata kazandırılmış seri günü sayısı. Yalnızca artı değerler.
  final Map<ItemStat, int> days;

  const StreakStatBonuses._(this.days);

  static const StreakStatBonuses empty = StreakStatBonuses._({});

  factory StreakStatBonuses(Map<ItemStat, int> days) {
    final cleaned = <ItemStat, int>{};
    for (final entry in days.entries) {
      if (!entry.key.isCombat) continue;
      final capped = entry.value.clamp(0, maxDaysPerStat);
      if (capped > 0) cleaned[entry.key] = capped;
    }
    return StreakStatBonuses._(Map.unmodifiable(cleaned));
  }

  /// Seri bonusunun dağıtıldığı havuz: **savaş** statlarının tamamı.
  ///
  /// Ekonomi statları (adım parası, adım XP, çark XP...) bilerek dışarıda:
  /// ekonomi ölçülmüş bir dengeye bağlı ve seriyle büyürse günlük tavan
  /// katlanır. Havuz `isCombat`'tan türetiliyor, elle yazılmıyor — savaş
  /// motoru yeni bir stat eklerse havuz kendiliğinden genişler.
  static final List<ItemStat> pool = List.unmodifiable([
    for (final stat in ItemStat.values)
      if (stat.isCombat) stat,
  ]);

  /// Tek bir statın alabileceği en fazla gün.
  static int get maxDaysPerStat =>
      (GameConstants.maxStreakStatBonus / GameConstants.streakStatBonusPerDay)
          .round();

  /// Bütün statlara dağıtılabilecek en fazla gün.
  static int get maxTotalDays =>
      (GameConstants.maxStreakTotalBonus / GameConstants.streakStatBonusPerDay)
          .round();

  /// [stat]'a kazandırılmış gün sayısı.
  int daysFor(ItemStat stat) => days[stat] ?? 0;

  /// [stat]'ın seriden gelen oran bonusu (0.03 = +%3).
  double bonusFor(ItemStat stat) =>
      daysFor(stat) * GameConstants.streakStatBonusPerDay;

  /// Dağıtılmış toplam gün.
  int get totalDays => days.values.fold(0, (sum, value) => sum + value);

  /// Seriden gelen toplam oran.
  double get totalBonus => totalDays * GameConstants.streakStatBonusPerDay;

  bool get isEmpty => days.isEmpty;

  /// [stat] kendi tavanına ulaştı mı.
  bool isAtCap(ItemStat stat) => daysFor(stat) >= maxDaysPerStat;

  /// Toplam tavan doldu mu. Dolduysa yeni gün bonus üretmez.
  bool get isFull => totalDays >= maxTotalDays;

  /// Bugün çekilişe girebilecek statlar: tavana ulaşanlar havuzdan çıkar,
  /// böylece kazanılan gün boşa gitmez.
  List<ItemStat> get eligibleStats => [
    for (final stat in pool)
      if (!isAtCap(stat)) stat,
  ];

  /// [stat]'a bir gün ekleyip yeni birikimi döner. Tavandaysa kendini döner.
  StreakStatBonuses withGrant(ItemStat stat) {
    if (!stat.isCombat || isAtCap(stat) || isFull) return this;
    return StreakStatBonuses({...days, stat: daysFor(stat) + 1});
  }

  /// Kayıt biçimi: `{statAdı: gün}`. Bilinmeyen ya da savaş dışı anahtarlar
  /// okuma sırasında sessizce atılır (elle düzenlenmiş kayda karşı savunma).
  Map<String, Object?> toJson() => {
    for (final entry in days.entries) entry.key.name: entry.value,
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
