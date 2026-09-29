import '../../models/item.dart';
import '../../models/reward_rarity.dart';
import 'item_rules.dart';

/// Zafer sonrası **garanti** eşya düşmesi (Bölüm C / Faz 2).
///
/// Saf ve deterministik: `Random()` yok, rastgeleliğin tamamı çağıranın
/// verdiği tohumdan geliyor ve sonuç tohumla birlikte tekrar üretilebiliyor
/// (§10 ilke 1 — kalıcı sonucu etkileyen rastgelelik tohumlu olmalı).
///
/// `calculateRewardRarity` **kullanılmıyor**: o fonksiyon adım/hedef oranına
/// bakıyor ve yalnızca ölü boss zincirinden çağrılıyor. Buradaki kural
/// farklı — düşmanın kademesi belirleyici.

/// Nadirlik dağılım tablosu: kademe bandı → binde cinsinden ağırlıklar.
///
/// **Tablo, formül değil.** Her satır `[sıradan, az bulunur, nadir, epik,
/// efsanevi]` ve toplamı tam olarak 1000. Binde kullanılıyor çünkü kayan
/// noktalı ağırlıkların toplamı 1,0 etmeyebiliyor ve tabloyu gözle
/// doğrulamak zorlaşıyor.
///
/// Okuma:
/// - **1–4. kademe** (500–2.000 adım): neredeyse hep sıradan. Nadir yok.
///   Yeni oyuncu ilk günlerinde envanterini sıradan eşyayla dolduruyor.
/// - **5–9. kademe** (2.500–4.500): az bulunur ana kaynak, nadir ilk kez
///   görünüyor (%4).
/// - **10–14. kademe** (5.000–7.000): nadir belirgin (%18), epik ilk kez.
/// - **15–19. kademe** (7.500–9.500): nadir ana kaynak, epik hissedilir.
/// - **20. kademe** (10.000): epik %20, efsanevi %4 — boss savaşının asıl
///   cazibesi para değil, **düşen eşyanın kalitesi**.
const List<({int minTier, List<int> weightsPerMille})> itemDropRarityTable = [
  (minTier: 1, weightsPerMille: [900, 100, 0, 0, 0]),
  (minTier: 5, weightsPerMille: [560, 400, 40, 0, 0]),
  (minTier: 10, weightsPerMille: [300, 480, 180, 40, 0]),
  (minTier: 15, weightsPerMille: [130, 390, 360, 110, 10]),
  (minTier: 20, weightsPerMille: [40, 240, 480, 200, 40]),
];

/// [tier] için geçerli satır: `minTier`'ı kademeyi aşmayan **son** satır.
({int minTier, List<int> weightsPerMille}) dropTableForTier(int tier) {
  var row = itemDropRarityTable.first;
  for (final candidate in itemDropRarityTable) {
    if (tier >= candidate.minTier) row = candidate;
  }
  return row;
}

/// Kademenin nadirlik çekilişi. [seed] aynıysa sonuç aynıdır.
RewardRarity rollDropRarity({required int tier, required String seed}) {
  final weights = dropTableForTier(tier).weightsPerMille;
  final total = weights.fold<int>(0, (sum, value) => sum + value);
  if (total <= 0) return RewardRarity.common;

  var point = stableSpread('drop-rarity|$seed', total);
  for (var index = 0; index < weights.length; index++) {
    point -= weights[index];
    if (point < 0) return RewardRarity.values[index];
  }
  return RewardRarity.common;
}

/// Zaferden düşen eşya. Havuz boşsa `null`.
///
/// [pool] oyuncunun **sınıfının kullanabildiği** katalog olmalı
/// (`ItemCatalog.forCharacterClass`); böylece düşen eşya kuşanılabilir bir
/// şey olur. Seviye kilidi burada **uygulanmaz**: kilit kuşanmayı engeller,
/// sahip olmayı değil — erken düşen bir epik, oyuncuya ulaşacağı seviyeyi
/// gösteren bir havuç.
///
/// Çekilen nadirlikte hiç eşya yoksa bir alt nadirliğe düşülür; en altta da
/// yoksa havuzdan herhangi biri verilir. Böylece **her zafer bir şey
/// düşürür** — bu sistemin tek sert kuralı.
Item? rollItemDrop({
  required int tier,
  required String seed,
  required List<Item> pool,
}) {
  if (pool.isEmpty) return null;

  var rarity = rollDropRarity(tier: tier, seed: seed);
  var candidates = pool.where((item) => item.rarity == rarity).toList();

  // Aşağı doğru geri çekilme: çekilen nadirlikte eşya yoksa boş dönme.
  while (candidates.isEmpty && rarity.index > 0) {
    rarity = RewardRarity.values[rarity.index - 1];
    candidates = pool.where((item) => item.rarity == rarity).toList();
  }
  if (candidates.isEmpty) candidates = pool;

  // Sıra kararlı olmalı: katalog tarama sırası platforma göre değişebilir,
  // tohumlu çekiliş ancak sabit bir sıralamada tekrarlanabilir olur.
  candidates.sort((a, b) => a.id.compareTo(b.id));
  return candidates[stableSpread('drop-item|$seed', candidates.length)];
}
