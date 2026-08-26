import '../../models/item.dart';
import '../../models/item_effect.dart';
import '../constants/game_constants.dart';

/// Kuşanılan itemlerin **toplam** etkisi.
///
/// Projedeki desen: saf fonksiyon / saf sınıf, `core/utils/` altında
/// ([calculateStepCoins], [calculateStepXp], [limitStepBatch],
/// [archiveStepDay] hepsi böyle). Ekran ve state buradan okur; ikinci bir
/// toplama mantığı yazılmaz.
///
/// ## Tavanlar burada uygulanır
///
/// Item tasarımı ne yaparsa yapsın, oyuncunun kuşanılan ekipmandan aldığı
/// oyun dışı bonus [GameConstants.maxEquippedEconomyBonus] (%50) üstüne
/// çıkamaz. Kırpma tek tek itemlerde değil **burada** yapılıyor: item başına
/// tavan (%15) bir tasarım disiplini, bu ise bir garanti.
///
/// Hesap: bir sınıf en çok 5 kategori (slot) görüyor (bkz. GD15). Beş
/// efsanevi item'in beşi de aynı statı %15 verirse ham toplam %75 olurdu;
/// kırpma onu %50'de tutar. Gerçekçi senaryoda (sınıf imzası tek bir statı
/// birincil yapıyor, diğerleri paya bölünüyor) toplam zaten %25–%35 bandında
/// kalıyor — kırpma yalnızca uç durumu kapatıyor.
///
/// ## Koşullu ve savaş etkileri toplanmaz
///
/// Yalnızca [ItemEffect.isPassive] etkiler çarpana girer. Koşullu bir etki
/// ("can %30 altındayken +%40 saldırı") kuşanıldığı anda pasif bir bonusa
/// dönüşmemeli; [conditionalEffects] içinde gösterim için taşınır.
/// Savaş statları da [combatEffects] içinde durur — savaş motoru Aşama 4a'da
/// yazılacak, bugün hiçbiri uygulanmıyor.
class EquippedBuffs {
  /// Adım parası oran bonusu (0.12 = +%12). Tavana kırpılmış.
  final double stepCoinBonus;

  /// Adım XP oran bonusu. Tavana kırpılmış.
  final double stepXpBonus;

  /// Çark XP oran bonusu. Tavana kırpılmış.
  final double wheelXpBonus;

  /// Düşman XP oran bonusu. Tavana kırpılmış.
  final double enemyXpBonus;

  /// Kaldırılan günlük coin tavanı API'si için korunur; her zaman sıfırdır.
  final int dailyCoinCapBonus;

  /// Dondurma stok tavanına eklenen hak. Tavana kırpılmış.
  final int streakFreezeCapBonus;

  /// Ekstra çark hakkı stok tavanına eklenen hak. Tavana kırpılmış.
  final int wheelSpinCapBonus;

  /// Seri eşiğinden düşülen adım. Tavana kırpılmış.
  final int streakStepRelief;

  /// Koşullu/tetiklenen etkiler; gösterim için taşınır, çarpana girmez.
  final List<ItemEffect> conditionalEffects;

  /// Savaş etkileri (Aşama 4a'da canlanacak).
  final List<ItemEffect> combatEffects;

  const EquippedBuffs._({
    this.stepCoinBonus = 0,
    this.stepXpBonus = 0,
    this.wheelXpBonus = 0,
    this.enemyXpBonus = 0,
    this.dailyCoinCapBonus = 0,
    this.streakFreezeCapBonus = 0,
    this.wheelSpinCapBonus = 0,
    this.streakStepRelief = 0,
    this.conditionalEffects = const [],
    this.combatEffects = const [],
  });

  /// Hiçbir şey kuşanılmamış hâl.
  static const none = EquippedBuffs._();

  /// Kuşanılan itemlerden toplam etkiyi hesaplar.
  ///
  /// [equipped] listesi **oyuncunun sınıfına uyarlanmış** itemler olmalı
  /// ([ItemCatalog.byId] `characterClass` ile ya da
  /// [ItemCatalog.forCharacterClass]); yoksa temel buff toplanır ve sınıfa
  /// özel buff'lar (GD16) anlamını yitirir.
  factory EquippedBuffs.from(
    Iterable<Item> equipped, {
    Iterable<ItemEffect> titleEffects = const [],
  }) {
    var stepCoin = 0.0;
    var stepXp = 0.0;
    var wheelXp = 0.0;
    var enemyXp = 0.0;
    var freezeCap = 0;
    var spinCap = 0;
    var relief = 0;
    final conditional = <ItemEffect>[];
    final combat = <ItemEffect>[];

    // Takılı ünvanın etkileri (Bölüm C) **aynı** toplama noktasından geçer.
    //
    // Neden ayrı bir hesap yok: ekonomi tavanı (`_cap`) ve stok tavanları
    // burada uygulanıyor. Ünvan ayrı toplansaydı, ünvan + eşya birlikte
    // tavanı aşabilirdi — GD25'in "tavan toplama noktasında, item başına
    // değil" kararının doğrudan sonucu.
    final effectSources = <Iterable<ItemEffect>>[
      for (final item in equipped) item.buff.effects,
      titleEffects,
    ];

    for (final effects in effectSources) {
      for (final effect in effects) {
        if (effect.stat.isCombat) {
          combat.add(effect);
          continue;
        }
        if (!effect.isPassive) {
          conditional.add(effect);
          continue;
        }
        switch (effect.stat) {
          case ItemStat.stepCoin:
            stepCoin += effect.value;
          case ItemStat.stepXp:
            stepXp += effect.value;
          case ItemStat.wheelXp:
            wheelXp += effect.value;
          case ItemStat.enemyXp:
            enemyXp += effect.value;
          case ItemStat.dailyCoinCap:
            // Eski/kullanıcı yapımı itemlerde kalmış tavan bonusu boşa
            // gitmez. Eski taban tavana oranı kadar adım-parası bonusuna
            // çevrilir; tek item ekonomi tavanı yine uygulanır.
            final converted = effect.value / GameConstants.maxDailyStepCoins;
            stepCoin += converted.clamp(
              0,
              GameConstants.maxSingleItemEconomyBonus,
            );
          case ItemStat.streakFreezeCap:
            freezeCap += effect.value.round();
          case ItemStat.wheelSpinCap:
            spinCap += effect.value.round();
          case ItemStat.streakRelief:
            relief += effect.value.round();
          // Savaş statları yukarıda ayrıldı; buraya düşmez.
          default:
            break;
        }
      }
    }

    return EquippedBuffs._(
      stepCoinBonus: _cap(stepCoin),
      stepXpBonus: _cap(stepXp),
      wheelXpBonus: _cap(wheelXp),
      enemyXpBonus: _cap(enemyXp),
      dailyCoinCapBonus: 0,
      streakFreezeCapBonus: freezeCap.clamp(
        0,
        GameConstants.maxEquippedStockBonus,
      ),
      wheelSpinCapBonus: spinCap.clamp(0, GameConstants.maxEquippedStockBonus),
      streakStepRelief: relief.clamp(0, GameConstants.maxEquippedStreakRelief),
      conditionalEffects: List.unmodifiable(conditional),
      combatEffects: List.unmodifiable(combat),
    );
  }

  static double _cap(double value) {
    if (value <= 0) return 0;
    return value > GameConstants.maxEquippedEconomyBonus
        ? GameConstants.maxEquippedEconomyBonus
        : value;
  }

  /// Hiçbir bonus yoksa `true`. Koşullu/savaş etkileri sayılmaz — onlar
  /// bugün bir çarpan üretmiyor.
  bool get isEmpty =>
      stepCoinBonus == 0 &&
      stepXpBonus == 0 &&
      wheelXpBonus == 0 &&
      enemyXpBonus == 0 &&
      dailyCoinCapBonus == 0 &&
      streakFreezeCapBonus == 0 &&
      wheelSpinCapBonus == 0 &&
      streakStepRelief == 0;

  /// [calculateStepCoins] çarpanı.
  double get stepCoinMultiplier => 1 + stepCoinBonus;

  /// [calculateStepXp] çarpanı.
  double get stepXpMultiplier => 1 + stepXpBonus;

  double get wheelXpMultiplier => 1 + wheelXpBonus;

  double get enemyXpMultiplier => 1 + enemyXpBonus;

  /// Kaldırılan günlük tavan API'sinin eski taban değeri.
  /// Coin hesaplayıcı bu değeri uygulamaz.
  int get dailyCoinCap => GameConstants.maxDailyStepCoins + dailyCoinCapBonus;

  /// Bu oyuncunun dondurma stok tavanı.
  int get streakFreezeCap =>
      GameConstants.maxStreakFreezes + streakFreezeCapBonus;

  /// Bu oyuncunun ekstra çark hakkı stok tavanı.
  int get wheelSpinCap => GameConstants.maxExtraWheelSpins + wheelSpinCapBonus;

  /// Bu oyuncunun seri eşiği. Kırpma sayesinde tabanın yarısının altına
  /// inmez.
  int get streakStepThreshold =>
      GameConstants.streakStepThreshold - streakStepRelief;

  /// [stat] için kuşanılan itemlerden gelen **sabit** katkı toplamı.
  /// Karakter panelinde "item katkısı" satırı bunu gösterir.
  double flatBonusFor(ItemStat stat) {
    var total = 0.0;
    for (final effect in combatEffects) {
      if (effect.stat == stat &&
          effect.isPassive &&
          effect.mode == ItemEffectMode.flat) {
        total += effect.value;
      }
    }
    return total;
  }

  /// [stat] için kuşanılan itemlerden gelen **oransal** katkı toplamı.
  double rateBonusFor(ItemStat stat) {
    if (!stat.isCombat) {
      return switch (stat) {
        ItemStat.stepCoin => stepCoinBonus,
        ItemStat.stepXp => stepXpBonus,
        ItemStat.wheelXp => wheelXpBonus,
        ItemStat.enemyXp => enemyXpBonus,
        _ => 0,
      };
    }
    var total = 0.0;
    for (final effect in combatEffects) {
      if (effect.stat == stat &&
          effect.isPassive &&
          effect.mode == ItemEffectMode.percent) {
        total += effect.value;
      }
    }
    return total;
  }

  /// Savaş etkilerinin dokunduğu statlar (panelde gösterim sırası
  /// [ItemStat.values] sırasıdır, böylece her açılışta aynı).
  List<ItemStat> get touchedCombatStats {
    final seen = <ItemStat>{};
    for (final effect in combatEffects) {
      seen.add(effect.stat);
    }
    return ItemStat.values.where(seen.contains).toList();
  }
}
