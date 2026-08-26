import 'item_effect.dart';
import 'reward_rarity.dart';

/// Bir ünvanın nasıl kazanıldığı (Bölüm C.4).
///
/// Dört yol bilerek farklı: satın alma parayı, başarım oynamayı, çark şansı,
/// kilometre taşı ise sadakati ödüllendiriyor. Aynı ünvan yalnızca **tek**
/// yoldan gelir; iki kaynaktan gelen ünvan, iki kaynağı da anlamsızlaştırır.
enum TitleSource {
  /// Mağazadan satın alınır.
  purchase,

  /// Bir başarım koşulu sağlanınca kendiliğinden verilir.
  achievement,

  /// Günlük çarktan çıkabilir.
  wheel,

  /// Seri kilometre taşında verilir.
  milestone,
}

/// Başarım ünvanlarının baktığı sayaç.
///
/// Hepsi ya [UserProfile] üzerinde kalıcı bir sayaç ya da ondan doğrudan
/// türetilebilen bir değer. Yeni bir koşul türü eklemek yeni bir sayaç
/// gerektirir — bu yüzden liste bilerek kısa.
enum TitleCondition {
  /// Oyuncu seviyesi.
  level,

  /// Ömür boyu atılan adım.
  totalSteps,

  /// En uzun seri (gün).
  longestStreak,

  /// Devrilen düşman sayısı.
  enemiesDefeated,

  /// Adım taahhüdü de dolarak **tamamlanan** macera sayısı.
  adventuresCompleted,

  /// Envanterdeki eşya örneği sayısı.
  ownedItemCount,

  /// Sahip olunan en yüksek eşya seviyesi.
  maxItemLevel,

  /// Çevrilen çark sayısı.
  wheelSpins,

  /// Demircide birleştirilen eşya sayısı.
  itemsMerged,

  /// Ömür boyu kazanılan altın.
  lifetimeCoins,
}

extension TitleConditionLabel on TitleCondition {
  /// "100 düşman devir" gibi bir cümlenin gövdesi. Sayı çağıran tarafta.
  String describe(int threshold) => switch (this) {
    TitleCondition.level => '$threshold. seviyeye ulaş',
    TitleCondition.totalSteps => 'toplam ${_group(threshold)} adım at',
    TitleCondition.longestStreak => '$threshold günlük seri yap',
    TitleCondition.enemiesDefeated => '$threshold düşman devir',
    TitleCondition.adventuresCompleted => '$threshold macerayı tamamla',
    TitleCondition.ownedItemCount => '$threshold eşya topla',
    TitleCondition.maxItemLevel => 'bir eşyayı Sv. $threshold yap',
    TitleCondition.wheelSpins => 'çarkı $threshold kez çevir',
    TitleCondition.itemsMerged => '$threshold eşya birleştir',
    TitleCondition.lifetimeCoins => 'toplam ${_group(threshold)} altın kazan',
  };

  static String _group(int value) {
    final digits = value.toString();
    final output = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) output.write('.');
      output.write(digits[index]);
    }
    return output.toString();
  }
}

/// Oyuncunun takabildiği kozmetik + buff paketi (Bölüm C).
///
/// Model Kuralları #1 temiz: hiçbir Flutter tipi yok ve **ünvan diske
/// yazılmaz** — kalıcı olan tek şey [id]; ünvan her açılışta katalogdan
/// çözülür. Aynı desen [Item] için de geçerli.
///
/// Efektler [ItemEffect] listesi olarak taşınır, yani koşullu / tetiklenen /
/// eşikli etkiler için ikinci bir sistem kurulmadı. Ünvanın "aşırı özgün"
/// olmasını sağlayan şey de bu: düz bir stat artışı yerine bir tetikleyici,
/// bir eşik ve [ItemEffect.customLabel] ile yazılmış kendi cümlesi.
class GameTitle {
  final String id;

  /// Oyuncu adının yanında görünen ad.
  final String name;

  /// Ünvanın karakterini anlatan tek cümle.
  final String lore;

  final RewardRarity rarity;

  final TitleSource source;

  /// Yalnızca [TitleSource.purchase] için: mağaza fiyatı.
  final int cost;

  /// Yalnızca [TitleSource.achievement] için.
  final TitleCondition? condition;
  final int conditionThreshold;

  /// Yalnızca [TitleSource.milestone] için: kaçıncı seri gününde verilir.
  final int milestoneDay;

  final List<ItemEffect> effects;

  const GameTitle({
    required this.id,
    required this.name,
    required this.lore,
    required this.rarity,
    required this.source,
    required this.effects,
    this.cost = 0,
    this.condition,
    this.conditionThreshold = 0,
    this.milestoneDay = 0,
  });

  /// Kilitli kartta gösterilen "nasıl kazanılır" satırı.
  ///
  /// Kilitli bir kart neden kilitli olduğunu söylemeli (Model Kuralları #4);
  /// "kilitli" tek başına bir cevap değil.
  String get unlockHint => switch (source) {
    TitleSource.purchase => 'Mağazadan $cost altına satın al.',
    TitleSource.achievement =>
      condition == null
          ? 'Oynayarak kazanılır.'
          : '${condition!.describe(conditionThreshold)}.',
    TitleSource.wheel => 'Günlük çarktan çıkabilir.',
    TitleSource.milestone => '$milestoneDay günlük seri kilometre taşı ödülü.',
  };

  /// Kaynağın kısa etiketi. Ünvan listesinde rozet olarak görünür.
  String get sourceLabel => switch (source) {
    TitleSource.purchase => 'Mağaza',
    TitleSource.achievement => 'Başarım',
    TitleSource.wheel => 'Çark',
    TitleSource.milestone => 'Kilometre taşı',
  };
}
