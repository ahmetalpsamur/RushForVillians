import 'dart:math' as math;

import '../../models/enemy.dart';
import '../constants/game_constants.dart';

/// Sonsuz Koşu modunun **saf** kuralları (Bölüm C / Faz 3).
///
/// Mod, normal maceranın yerine geçmez — yanına eklenir. Bu yüzden hiçbir şey
/// `AttackConfig`'ten okunmuyor: tempo tablosu bu modda **geçerli değil**,
/// round sabit 100 adım / 2 dakika.
///
/// Bütün eğriler **tavanlı ve deterministik**: aynı kesim numarası her zaman
/// aynı sonucu verir, `Random()` yok.

/// Kesim numarasından çarpan.
///
/// `0,25` ile başlar ve kesim başına [GameConstants.endlessMultiplierStep]
/// kadar **doğrusal** büyür, [GameConstants.endlessMaxMultiplier] ile
/// tavanlanır.
///
/// **Neden doğrusal, hızlanan değil:** risk de doğrusal büyüyor (düşman
/// hasarı). Hızlanan bir ödül eğrisi çok uzun koşuları her şeyin önüne
/// geçirir ve "sonsuz koşu = para modu, boss = eşya modu" ayrımını bozar.
/// **Neden tavan var:** tavansız bir çarpan, yeterince uzun yürüyen oyuncu
/// için diğer bütün ekonomiyi anlamsız kılardı. Tavan aynı zamanda doğal bir
/// durma noktası veriyor — oyuncu bankasını almak için bitiriyor.
double endlessMultiplierAt(int cutCount) {
  final raw =
      GameConstants.endlessStartMultiplier +
      GameConstants.endlessMultiplierStep * cutCount;
  return math.min(raw, GameConstants.endlessMaxMultiplier);
}

/// Kesim *n* için canavarın canı — **adım cinsinden**.
///
/// 200 adımla başlar (tam iki round), kesim başına
/// [GameConstants.endlessHealthStep] adım büyür,
/// [GameConstants.endlessMaxHealth] ile tavanlanır.
///
/// **Neden adım, savaş canı değil:** bu modun tek ölçüsü yürümek. Canı adımla
/// ifade etmek "bir eyeball iki roundda ölür" sözünü birebir tutar ve kesim
/// başına süreyi tahmin edilebilir kılar.
int endlessMonsterHealthAt(int cutCount) {
  final raw =
      GameConstants.endlessBaseHealthSteps +
      GameConstants.endlessHealthStep * cutCount;
  return math.min(raw, GameConstants.endlessMaxHealthSteps);
}

/// Kesim *n* için canavarın hasar çarpanı.
///
/// ⚠️ **Can eğrisinin altında kalmak zorunda** (erken kesimlerde): oyuncu
/// önce "bu uzuyor" hissetmeli, sonra "bu tehlikeli". Tersi olursa mod çok
/// erken biter. Ölçülen kesişim ~17. kesim.
double endlessDamageMultiplierAt(int cutCount) {
  final raw =
      GameConstants.endlessStartDamageMultiplier +
      GameConstants.endlessDamageStep * cutCount;
  return math.min(raw, GameConstants.endlessMaxDamageMultiplier);
}

/// Kesim *n* için sprite ölçeği çarpanı.
///
/// Güçlenmenin **görsel** karşılığı. Tavan ekranı taşırmamak için;
/// `PixelSprite` zaten `ClipRect` içinde ve `FilterQuality.none` korunuyor.
double endlessSpriteScaleAt(int cutCount) {
  final raw = 1 + GameConstants.endlessScaleStep * cutCount;
  return math.min(raw, GameConstants.endlessMaxSpriteScale);
}

/// Kesim *n*'in bankaya eklediği altın.
///
/// Ödül **kesim anında** o kesimin çarpanıyla bankaya yazılır, koşu sonunda
/// tek bir çarpanla çarpılmaz. İki sebep: (1) "şimdi bitir mi, devam mı"
/// sorusu ancak birikmiş bir banka varsa gerçek bir soru olur; (2) sondaki
/// tek çarpan, çarpan da kesimle büyüdüğü için ödülü karesel büyütürdü.
int endlessCutCoins(int cutCount) =>
    (GameConstants.endlessCutBaseCoins * endlessMultiplierAt(cutCount))
        .floor();

/// Kesim *n*'in bankaya eklediği XP. [endlessCutCoins] ile aynı desen.
int endlessCutXp(int cutCount) =>
    (GameConstants.endlessCutBaseXp * endlessMultiplierAt(cutCount)).floor();

/// Yenilgide bankanın ödenen oranı.
///
/// **Asla sıfır değil** — sıfır olsaydı oyuncu canını takip etmek için
/// telefona bakardı, ki bu modun varlık sebebine aykırı. Normal macera
/// yenilgide ödülü tamamen siliyor; bu mod **bilerek ayrışıyor**.
///
/// Kural kodla zorlanıyor: bankada bir şey varsa ödeme en az **1**. Yalnızca
/// oranı uygulamak yetmiyordu — `floor(1 × 0,5)` sıfır ediyor ve tek kesimlik
/// bir koşu eli boş kapanıyordu.
int endlessDefeatPayout(int bankedAmount) {
  if (bankedAmount <= 0) return 0;
  final paid = (bankedAmount * GameConstants.endlessDefeatPayoutRatio).floor();
  return paid < 1 ? 1 : paid;
}

/// Kesim *n*'in tamamlanması için gereken round sayısı.
///
/// Kesim, round sınırında değil **adım eşiğinde** oluyor; bu sayı yalnızca
/// "kaç round sürer" tahmini (süre tablosu ve testler için).
int endlessRoundsForCut(int cutCount) =>
    (endlessMonsterHealthAt(cutCount) / GameConstants.endlessRoundSteps)
        .ceil();

/// Kesim *n*'in beklenen süresi.
///
/// Kadans sabit: [GameConstants.endlessRoundSteps] adım /
/// [GameConstants.endlessRoundSeconds] saniye.
Duration endlessCutDuration(int cutCount) => Duration(
  seconds:
      (endlessMonsterHealthAt(cutCount) *
              GameConstants.endlessRoundSeconds /
              GameConstants.endlessRoundSteps)
          .round(),
);

/// Sonsuz koşuda düşen eşyanın **kademe** karşılığı.
///
/// Kesim sayısından türer ama [GameConstants.endlessMaxDropTier] ile
/// kırpılır: Faz 2'nin nadirlik tablosunda bu kademe epik/efsanevi bandına
/// ulaşmıyor. **Sonsuz koşu para modu, boss savaşı nadir eşya modu** — çarpan
/// bankayı büyütür, eşyanın kalitesini değil.
int endlessDropTierFor(int cutCount) =>
    (1 + cutCount ~/ 2).clamp(1, GameConstants.endlessMaxDropTier);

/// Kesim *n*'de kullanılabilecek saldırı animasyonları.
///
/// Erken kesimlerde katalogdaki `Attack01-03`;
/// [GameConstants.endlessBeamUnlockCut]'tan sonra havuza **Beam** de
/// katılıyor. Yeni bir gösterim yazılmadı — seçim, `GifTiming.cycle` ve
/// `imageKey` mantığı normal maceradakiyle aynı.
List<String> endlessAttackAssets(Enemy enemy, int cutCount) {
  if (cutCount < GameConstants.endlessBeamUnlockCut) return enemy.attackAssets;
  final beam = enemy.attackAssets.first.replaceFirst(
    RegExp(r'_Attack\d+\.gif$'),
    '_Beam.gif',
  );
  if (beam == enemy.attackAssets.first) return enemy.attackAssets;
  return [...enemy.attackAssets, beam];
}
