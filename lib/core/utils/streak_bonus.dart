import 'dart:math';

import '../constants/game_constants.dart';
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

  /// Bu gün eklenen bonus, **binde** cinsinden (5 = +%0,5).
  final int grantedTenths;

  /// Bonus eklendikten sonraki birikim.
  final StreakStatBonuses bonuses;

  /// Bir sonraki gün için ilerletilmiş tohum.
  final int nextSeed;

  /// Bu gün döngü başa döndü mü ("501. günde kazanç %0,5'e döndü").
  final bool cycleRestarted;

  const StreakBonusDraw({
    required this.stat,
    required this.grantedTenths,
    required this.bonuses,
    required this.nextSeed,
    required this.cycleRestarted,
  });

  /// Bu günün kazancı oran olarak (0.005 = +%0,5).
  double get grantedBonus => grantedTenths / 1000;
}

/// Bir seri günü için stat çeker.
///
/// [streakDay] 1'den başlar ve **kazancın büyüklüğünü** belirler: basamak
/// tablosu her [GameConstants.streakBonusTierLength] günde bir azalır, sonra
/// başa döner (Bölüm B).
///
/// **Tavan yok.** Tek bir statın uçmasını engelleyen şey ağırlıklı çekiliş:
/// geride kalan stat daha şanslı, ama lider de çekilişte kalıyor. Bu yüzden
/// hiçbir gün boşa gitmez ve fonksiyon asla `null` dönmez — kazanç sıfır
/// olacak tek durum bozuk bir yapılandırma (boş basamak tablosu).
StreakBonusDraw? drawStreakStatBonus({
  required StreakStatBonuses current,
  required int seed,
  required int streakDay,
}) {
  final granted = StreakStatBonuses.tenthsForDay(streakDay);
  if (granted <= 0) return null;

  final pool = StreakStatBonuses.pool;
  if (pool.isEmpty) return null;

  final weights = current.drawWeights;
  final total = weights.fold(0, (sum, weight) => sum + weight);
  if (total <= 0) return null;

  // Ağırlıklı çekiliş, tek bir tohumdan: `nextInt` bir kez çağrılıyor ve
  // kümülatif ağırlıkta yürünüyor. Aynı tohum + aynı birikim her zaman aynı
  // statı verir; kapat-aç zar attırmaz.
  var ticket = Random(seed).nextInt(total);
  var index = 0;
  for (var i = 0; i < weights.length; i++) {
    if (ticket < weights[i]) {
      index = i;
      break;
    }
    ticket -= weights[i];
  }
  final stat = pool[index];

  return StreakBonusDraw(
    stat: stat,
    grantedTenths: granted,
    bonuses: current.withGrant(stat, granted),
    nextSeed: nextStreakSeed(seed),
    cycleRestarted: StreakStatBonuses.isCycleRestartDay(streakDay),
  );
}
