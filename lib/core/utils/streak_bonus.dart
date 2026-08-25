import 'dart:math';

import '../../models/item_effect.dart';
import '../../models/streak_stat_bonuses.dart';
import 'item_rules.dart';

/// Seri gününün hangi savaş statını büyüteceğini seçen **saf** kurallar
/// (Bölüm 5C).
///
/// ## Neden hem tohum hem kalıcı birikim var
///
/// CLAUDE.md §4.4: kalıcı oyun sonucunu etkileyen rastgelelik tohumlu olmalı.
/// Ama burada tohum **tek başına yetmez**, çünkü çekiliş yol bağımlı: tavana
/// ulaşan stat havuzdan çıkıyor, yani N. günün havuzu önceki N-1 günün
/// sonucuna bağlı. Saf bir `f(tohum, günIndeksi)` bunu ancak bütün geçmişi
/// yeniden oynatarak üretebilirdi.
///
/// Bu yüzden **birikimin kendisi kalıcı** ([StreakStatBonuses] diske yazılır)
/// ve tohum yalnızca o günün çekilişini tekrarlanabilir kılar. Oyuncu
/// uygulamayı kapatıp açarak zar atamaz: gün [UserProfile.lastStreakBonusDay]
/// ile işaretleniyor, aynı oyun gününde ikinci çekiliş yapılmıyor.
///
/// Tohum oyuncuya özel ve `String.hashCode` **kullanılmıyor** (GD8): sürümler
/// arası sabit değil.

/// Tohumu bir sonraki güne ilerletir.
///
/// Çarkınkiyle (`nextWheelSeed`) aynı LCG adımı, ama **ayrı** bir akış:
/// aynı sayacı paylaşsalardı çark çevirmek ertesi günün stat çekilişini
/// değiştirirdi ve oyuncuya sıra üzerinden bir zar atma yolu açardı.
int nextStreakSeed(int seed) => (seed * 1103515245 + 12345) & 0x7FFFFFFF;

/// Oyuncuya özel başlangıç tohumu. Sıfır dönmez; `0` "henüz kurulmadı".
int initialStreakSeed(String salt) =>
    stableSpread('streak|$salt', 0x7FFFFFF0) + 1;

/// Bir seri gününün sonucu.
class StreakBonusDraw {
  /// Bu gün büyüyen stat.
  final ItemStat stat;

  /// Bonus eklendikten sonraki birikim.
  final StreakStatBonuses bonuses;

  /// Bir sonraki gün için ilerletilmiş tohum.
  final int nextSeed;

  const StreakBonusDraw({
    required this.stat,
    required this.bonuses,
    required this.nextSeed,
  });
}

/// Bir seri günü için stat çeker.
///
/// Tavanı dolmuş statlar havuza girmez; toplam tavan dolduysa `null` döner
/// (gün bonus üretmez, ama seri yine ilerler).
StreakBonusDraw? drawStreakStatBonus({
  required StreakStatBonuses current,
  required int seed,
}) {
  if (current.isFull) return null;
  final candidates = current.eligibleStats;
  if (candidates.isEmpty) return null;
  final stat = candidates[Random(seed).nextInt(candidates.length)];
  return StreakBonusDraw(
    stat: stat,
    bonuses: current.withGrant(stat),
    nextSeed: nextStreakSeed(seed),
  );
}
