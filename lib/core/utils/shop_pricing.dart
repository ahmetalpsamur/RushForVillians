/// Mağaza fiyatının **tek** hesaplanma noktası (Bölüm D / Faz 3 kapanışı).
///
/// İndirim birden çok yerde görünüyor: ekipman kartı, ünvan kartı,
/// yükseltme kartı, "şu kadar altın daha gerek" satırı ve `RootShell`'deki
/// satın alma kontrolü. Her biri kendi çarpanını yazsaydı bir tanesi
/// unutulduğunda oyuncu **gördüğünden farklı bir fiyat** öderdi.
///
/// §10 #3 ile aynı fikir: ikinci bir hesap yazma.
library;

/// [baseCost]'un [rate] oranında indirimli hâli.
///
/// - [rate] 0 ise fiyat **birebir** döner; hiçbir yuvarlama yapılmaz.
/// - Sonuç aşağı yuvarlanır (oyuncunun lehine) ve **en az 1**: bedava
///   satın alma ekonomiyi delecek bir kapı olurdu.
/// - [rate] savunma amaçlı `[0, 0.9]` aralığına kırpılıyor; katalogdan
///   gelen bozuk bir değer fiyatı sıfırlayamasın.
int discountedCost(int baseCost, double rate) {
  if (baseCost <= 0) return baseCost;
  if (rate <= 0 || rate.isNaN) return baseCost;
  final safe = rate > 0.9 ? 0.9 : rate;
  final discounted = (baseCost * (1 - safe)).floor();
  return discounted < 1 ? 1 : discounted;
}
