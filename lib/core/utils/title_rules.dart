import '../../data/title_catalog.dart';
import '../../models/game_title.dart';
import '../../models/owned_item.dart';

/// Başarım ünvanlarının baktığı sayaçların **anlık görüntüsü**.
///
/// Saf bir kap: `UserProfile`'a bağımlı değil, bu yüzden kural motoru testte
/// tek satırla kurulabiliyor. Proje deseni `calculateStepCoins`,
/// `limitStepBatch`, `archiveStepDay` ile aynı.
class TitleProgress {
  final int level;
  final int totalSteps;
  final int longestStreak;
  final int enemiesDefeated;
  final int adventuresCompleted;
  final int ownedItemCount;
  final int maxItemLevel;
  final int wheelSpins;
  final int itemsMerged;
  final int lifetimeCoins;

  const TitleProgress({
    this.level = 1,
    this.totalSteps = 0,
    this.longestStreak = 0,
    this.enemiesDefeated = 0,
    this.adventuresCompleted = 0,
    this.ownedItemCount = 0,
    this.maxItemLevel = 0,
    this.wheelSpins = 0,
    this.itemsMerged = 0,
    this.lifetimeCoins = 0,
  });

  /// Envanterden türeyen iki sayacı listeden okur.
  ///
  /// Bunlar kalıcı sayaç **değil**: envanterin kendisi zaten diske yazılıyor
  /// ve ikinci bir sayaç tutmak iki doğruluk kaynağı üretirdi (satılan eşya
  /// sayacı düşürmeyi unutursa ünvan haksız yere açılırdı).
  factory TitleProgress.fromCounters({
    required int level,
    required int totalSteps,
    required int longestStreak,
    required int enemiesDefeated,
    required int adventuresCompleted,
    required int wheelSpins,
    required int itemsMerged,
    required int lifetimeCoins,
    required List<OwnedItem> ownedItems,
  }) {
    var highest = 0;
    for (final item in ownedItems) {
      if (item.level > highest) highest = item.level;
    }
    return TitleProgress(
      level: level,
      totalSteps: totalSteps,
      longestStreak: longestStreak,
      enemiesDefeated: enemiesDefeated,
      adventuresCompleted: adventuresCompleted,
      ownedItemCount: ownedItems.length,
      maxItemLevel: highest,
      wheelSpins: wheelSpins,
      itemsMerged: itemsMerged,
      lifetimeCoins: lifetimeCoins,
    );
  }

  int valueFor(TitleCondition condition) => switch (condition) {
    TitleCondition.level => level,
    TitleCondition.totalSteps => totalSteps,
    TitleCondition.longestStreak => longestStreak,
    TitleCondition.enemiesDefeated => enemiesDefeated,
    TitleCondition.adventuresCompleted => adventuresCompleted,
    TitleCondition.ownedItemCount => ownedItemCount,
    TitleCondition.maxItemLevel => maxItemLevel,
    TitleCondition.wheelSpins => wheelSpins,
    TitleCondition.itemsMerged => itemsMerged,
    TitleCondition.lifetimeCoins => lifetimeCoins,
  };
}

/// [title] başarım koşulunu sağlıyor mu.
///
/// Başarım olmayan ünvanlar (satın alma, çark, kilometre taşı) burada
/// **hiçbir zaman** açılmaz: onların kendi kapıları var ve iki kapı, ünvanın
/// hangi yoldan geldiğini anlamsız kılardı.
bool isAchievementUnlocked(GameTitle title, TitleProgress progress) {
  if (title.source != TitleSource.achievement) return false;
  final condition = title.condition;
  if (condition == null) return false;
  return progress.valueFor(condition) >= title.conditionThreshold;
}

/// [progress] ile açılan ama henüz sahip olunmayan başarım ünvanları.
///
/// Katalog sırasını korur; böylece aynı partide birden çok ünvan açılırsa
/// bildirim sırası kararlı olur.
List<GameTitle> newlyEarnedTitles({
  required TitleProgress progress,
  required Set<String> ownedTitleIds,
}) => [
  for (final title in TitleCatalog.all)
    if (!ownedTitleIds.contains(title.id) &&
        isAchievementUnlocked(title, progress))
      title,
];

/// Bir başarım ünvanının ilerleme oranı (0..1). Kilitli kartta çubuk olur.
double achievementProgress(GameTitle title, TitleProgress progress) {
  if (title.source != TitleSource.achievement) return 0;
  final condition = title.condition;
  if (condition == null || title.conditionThreshold <= 0) return 0;
  return (progress.valueFor(condition) / title.conditionThreshold).clamp(
    0.0,
    1.0,
  );
}
