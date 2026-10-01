import '../../models/reward_rarity.dart';

/// Oyunun temel dengeleme (balance) sabitleri.
///
/// Tasarım fikrindeki sayılar burada tek noktadan yönetilir, böylece
/// ilerideki dengeleme değişiklikleri tek dosyadan yapılabilir.
class GameConstants {
  GameConstants._();

  // --- Savaş temposu ve mükemmel round (Bölüm B) ---

  /// Referans yürüyüş temposu — **arayüz etiketi ve yardımcı hesaplar için**.
  ///
  /// ⚠️ [combatRoundPacing] bu sabitten **türemiyor**. Bir dönem tablonun
  /// dört bandı da tam 100 adım/dk veriyordu ve bu "ortak kadans" tablonun
  /// asıl vaadi sayılıyordu. Cihazda oynanınca o tempo fazla bulundu: tablo
  /// 500/7dk (71 adım/dk) ve 1.000/15dk (67 adım/dk) ile değiştirildi
  /// (Bölüm D / Faz 1). Tempo artık bir **denge kararı**, bir bölme işlemi
  /// değil; iki bantın kadansı da birbirinden bağımsız.
  static const int stepsPerMinute = 100;

  /// Round temposu tablosu — **sabit, türetilmiyor, kullanıcı değiştiremez**.
  ///
  /// Her satır bir adım hedefi bandını ve o bandın round boyunu verir.
  /// Bir hedef için geçerli satır, `minGoal`'ü hedefi aşmayan **son**
  /// satırdır:
  ///
  /// ```
  ///   hedef  <  3.000 : round   500 adım /  7 dk
  ///   hedef >= 3.000  : round 1.000 adım / 15 dk
  /// ```
  ///
  /// **Neden tablo, formül değil:** tempo bir denge kararı, matematiksel bir
  /// sonuç değil. Formül her hedefte "doğru" bir sayı üretir ama hiçbirinde
  /// istenen sayıyı üretmez.
  ///
  /// ⚠️ **Round temposu iki bant, ödül çarpanı dört bant.** Tablo dört
  /// satır taşıyor çünkü 0/1.000 ve 3.000/10.000 çiftleri **aynı** round
  /// boyunu ama **farklı** ödül çarpanını paylaşıyor. Tempo Bölüm D'de
  /// değişti, ödül eğrisi Faz 2'de ölçülmüş hâliyle **korundu** — ikisi
  /// ayrı kararlar ve aynı tabloda yaşamaları onları birbirine bağlamaz.
  ///
  /// Kadans bantlar arasında artık sabit **değil** (71 vs 67 adım/dk);
  /// bkz. [stepsPerMinute].
  /// [rewardMultiplier] aynı bandın **zafer ödülü** çarpanıdır: ödül ile
  /// tempo tek tablodan okunur, ikinci bir kademe tanımı yoktur.
  static const List<
    ({int minGoal, int roundSteps, int roundSeconds, double rewardMultiplier})
  >
  combatRoundPacing = [
    (minGoal: 0, roundSteps: 500, roundSeconds: 420, rewardMultiplier: 1.0),
    (minGoal: 1000, roundSteps: 500, roundSeconds: 420, rewardMultiplier: 1.4),
    (minGoal: 3000, roundSteps: 1000, roundSeconds: 900, rewardMultiplier: 2.0),
    (
      minGoal: 10000,
      roundSteps: 1000,
      roundSeconds: 900,
      rewardMultiplier: 3.0,
    ),
  ];

  // --- Sonsuz Koşu modu (Bölüm C / Faz 3) ---
  //
  // Bu bloğun hiçbir sayısı [combatRoundPacing] ile ilişkili **değil**.
  // Sonsuz koşunun kendi sabit temposu var ve ana tablo bu modda geçerli
  // değil: round 100 adım / 2 dakika, yani **50 adım/dk** — ana tablonun
  // kadansının (100 adım/dk) tam yarısı. Bilinçli: bu mod telefona
  // bakılmadan, cepte oynanacak; affedici olmak zorunda.

  /// Sonsuz koşuda bir roundun adım hedefi. Sabit.
  static const int endlessRoundSteps = 100;

  /// Sonsuz koşuda bir roundun süresi (saniye). Sabit.
  static const int endlessRoundSeconds = 120;

  /// İlk canavarın canı — **adım cinsinden**. Tam iki round.
  static const int endlessBaseHealthSteps = 200;

  /// Kesim başına can artışı (adım).
  static const int endlessHealthStep = 20;

  /// Canın tavanı (adım). Kesim başına süre 10 dakikayı aşmasın diye:
  /// 500 adım / 50 adım-dk = 10 dk. Tavansız bırakılsaydı "her kesim bir
  /// öncekinden uzun" hissi tempoyu öldürürdü.
  static const int endlessMaxHealthSteps = 500;

  /// Çarpanın başlangıcı. İlk kesimler bilerek çok az ödül veriyor.
  static const double endlessStartMultiplier = 0.25;

  /// Kesim başına çarpan artışı.
  static const double endlessMultiplierStep = 0.15;

  /// Çarpan tavanı.
  static const double endlessMaxMultiplier = 3.0;

  /// Canavar hasar çarpanının başlangıcı.
  static const double endlessStartDamageMultiplier = 0.5;

  /// Kesim başına hasar artışı.
  ///
  /// ⚠️ **Can eğrisiyle aynı bağıl hızda seçildi.** Can `200 → 200+20n`, yani
  /// bağıl olarak `1 + 0,10n`. Hasar `0,5 → 0,5+0,05n`, yani bağıl olarak
  /// yine `1 + 0,10n`. İkisi 15. kesime kadar **birebir aynı** büyüyor;
  /// orada can tavana vuruyor (500 adım) ama hasar büyümeye devam ediyor.
  ///
  /// Sonuç tam olarak istenen sıra: **15. kesime kadar "bu uzuyor"**
  /// (kesim süresi 4 → 10 dakika), **16. kesimden sonra "bu tehlikeli"**
  /// (süre sabit, hasar artıyor). Daha dik bir hasar eğrisi (0,12) ilk
  /// kesimden itibaren tehlikeyi öne alıyordu ve mod erken bitiyordu.
  static const double endlessDamageStep = 0.05;

  /// Canavar hasar çarpanının tavanı.
  static const double endlessMaxDamageMultiplier = 2.0;

  /// Kesim başına sprite büyümesi.
  static const double endlessScaleStep = 0.04;

  /// Sprite ölçeğinin tavanı. Sahne kutusunu taşırmamak için.
  static const double endlessMaxSpriteScale = 1.6;

  /// Bir kesimin bankaya eklediği taban altın (çarpandan önce).
  static const int endlessCutBaseCoins = 15;

  /// Bir kesimin bankaya eklediği taban XP (çarpandan önce).
  static const int endlessCutBaseXp = 50;

  /// Yenilgide bankanın ödenen oranı. **Asla sıfır olmamalı.**
  static const double endlessDefeatPayoutRatio = 0.5;

  /// "Cam Top" ünvanının saldırı bonusu — **yüzde**, tam sayı.
  ///
  /// Ünvan bu tek sayıdan iki etki üretiyor: `attack +%N` ve
  /// `maxHealth -%N`. **İkisi aynı sayıdan türemek zorunda** — ayrı ayrı
  /// yazıldığında biri değişip diğeri unutuluyordu (saldırı +%70 iken can
  /// yalnızca −%30'du, yani "cam" tarafı hiç yoktu).
  ///
  /// %90 ile can normalin **onda birine** iniyor: tek vuruşta ölmek gerçek
  /// bir ihtimal. High risk, high reward — yumuşatılmadı.
  ///
  /// Tam sayı tutulmasının sebebi teknik: `const` string interpolasyonu
  /// `double` kabul etmiyor ama `int` kabul ediyor, yani etiket de aynı
  /// sabitten üretilebiliyor ve metin hiçbir zaman değerle çelişemiyor.
  static const int glassCannonPercent = 90;

  /// Beam saldırısının saldırı havuzuna katıldığı kesim.
  ///
  /// **15 seçildi çünkü eğrilerin karakteri tam orada değişiyor:** can bu
  /// kesimde tavana vuruyor ([endlessMaxHealthSteps]) ve hasar tek başına
  /// büyümeye devam ediyor — yani mod "bu uzuyor"dan "bu tehlikeli"ye
  /// geçiyor. Beam o dönüşün **görsel sinyali**: oyuncu ekrana baktığında
  /// canavarın yalnızca büyümediğini, farklı bir şey de yaptığını görüyor.
  static const int endlessBeamUnlockCut = 15;

  /// Sonsuz koşuda düşen eşyanın en yüksek kademesi.
  ///
  /// 9 seçildi çünkü Faz 2'nin düşme tablosunda 5–9 bandı **epik ve
  /// efsanevi içermiyor** (sıradan 560 · az bulunur 400 · nadir 40).
  /// Sonsuz koşu ne kadar uzarsa uzasın efsanevi düşüremez.
  static const int endlessMaxDropTier = 9;

  /// Zafer altınının kademe tabanı: `min = taban + kademe × eğim`.
  ///
  /// Eski değerler (4 + 3·kademe … 10 + 6·kademe) 1. kademede ortalama
  /// **11,5 coin** veriyordu — günlük yürüyüşün (140 coin) %8'i. Savaşmanın
  /// ekonomik karşılığı ölçülemezdi; asıl kaldıraç buydu (Faz 0 bulgusu).
  ///
  /// Yeni tabanla 1. kademe ortalama 26 coin, yani ilk günün ~%19'u.
  /// Kademe eğimi de dikleşti: 20. kademe ham ortalama 140 coin.
  static const int victoryCoinBase = 12;
  static const int victoryCoinPerTier = 4;
  static const int victoryCoinSpreadBase = 28;
  static const int victoryCoinSpreadPerTier = 8;

  /// Kısa macerada bile gerilim kurmak için gereken en az round.
  static const int minCombatRounds = 2;

  /// Round sayısının **güvenlik sınırı** — bir denge aracı değil.
  ///
  /// **Round sayısını [combatRoundPacing] belirler.** Bu sabit yalnızca
  /// tablonun karşılığı olmayan bir hedefte (yalnızca eski kayıtlardan
  /// gelebilir, ör. 20.000) round sayısının sınırsız büyümesini engeller;
  /// devreye girerse round **boyu** büyür, sayı tavanda kalır.
  ///
  /// Değeri tablonun en büyük üretimine eşit: 10.000 adım / 1.000 =
  /// **10 round**. Yani desteklenen altı hedefin hiçbirinde bağlamıyor. Bir
  /// dönem 5'ti ve 10.000'lik hedefi 5 × 2.000 adıma sıkıştırıyordu;
  /// Bölüm D'de tablo tek doğruluk kaynağı ilan edilince tavan tablonun
  /// üstüne çıkarıldı.
  ///
  /// Sabit **silinmedi**: `roundStepsFor` içindeki büyütme dalı eski
  /// kayıtların tek koruması ve onu kaldırmak 20.000 adımlık bir kaydı
  /// 20 rounda bölerdi.
  static const int maxCombatRounds = 10;

  /// Düşman canının adım ölçeği: **kaç adımlık taahhüt bir "round payı"
  /// hasar eder** (GD100).
  ///
  /// `enemyBaseStatsForGoal` canı `stepGoal / enemyHealthStepsPerRound` ile
  /// kuruyor, yani can hedefin **adım taahhüdüyle** birlikte kesin artıyor.
  /// Bir dönem can maceranın planlanan **round sayısından** geliyordu; tempo
  /// tablosu round sayısını hedefte monoton yapmadığı için 3.000 hedefinin
  /// düşmanı 2.000'inkinden zayıf çıkıyordu (ödülü ×2,0 vs ×1,4 olmasına
  /// rağmen) — 2.000'i seçmek için sebep kalmamıştı.
  ///
  /// ## Değer nasıl seçildi
  ///
  /// **Yük oranı** = düşman canı / (ölçüt oyuncunun round başına hasarı
  /// × planlanan round). Hedef bant: **çıplak 0,90–1,00** (zor bitirsin ama
  /// bitirsin) ve **ekipmanlı 0,60–0,85** (savaş maceranın büyük kısmını
  /// kaplasın, yürüyüş fazı bir ödül olsun).
  ///
  /// 1.600 ile 3.000+ hedeflerde **ikisi de tutuyor**: çıplak 0,91,
  /// ekipmanlı 0,68. 20 düşman × 6 hedef = 120 kombinasyonda taşma 0.
  ///
  /// ⚠️ **3.000'in altındaki hedefler bandin yarısında kalıyor** (çıplak
  /// 0,45 · ekipmanlı 0,34) ve bu **tek bir sabitle düzeltilemez**. Sebep
  /// [combatRoundPacing]'in kendisi: yük oranı `stepGoal / plananRound`
  /// ile doğru orantılı ve bu değer tam olarak **round boyuna** eşit —
  /// alt bantta 500, üst bantta 1.000. Yani iki bandin yükü tanımı gereği
  /// **1:2**. Alt bandi banda oturtan değer (≈800) üst bandi 1,8'e
  /// çıkarır ve oyuncu taahhüdünden fazla yürür.
  ///
  /// İkinci bir çarpan **icat edilmedi**: tek sabit kalması bilinçli.
  /// `combat_balance_test` hem bandi hem taşmayı balıyor.
  static const int enemyHealthStepsPerRound = 1600;

  /// Eksik round hasar eğrisinin üssü.
  ///
  /// `hasar ölçeği = (1 - tamamlama)^1,5`: az kaçıran oyuncu yumuşak,
  /// büyük kısmı kaçıran oyuncu belirgin biçimde daha ağır cezalandırılır.
  static const double missedRoundDamageExponent = 1.5;

  /// Mükemmel round serisinin erişebildiği hasar çarpanları.
  ///
  /// İlk, ikinci ve üçüncü mükemmel round sırasıyla ×1,2 / ×1,5 / ×2
  /// tavanını açar; sonraki roundlar son değerde kalır.
  ///
  /// **Neden ×2'ye kadar:** mağaza ve macera metni zaten "üç tane üst üste
  /// yaparsan iki kat vuruyorsun" diye yazıyor. Değerler bir dönem
  /// ×1,01/×1,015/×1,02 idi (yüze bölünmüş bir sıfır kayması); metin
  /// vaat ettiği şeyi tutmuyordu.
  static const List<double> perfectRoundStreakMultipliers = [1.2, 1.5, 2.0];

  /// Düşmanın yenilebileceği en erken noktanın planlanan roundlara oranı.
  ///
  /// Yüksek seviye ve ekipman hasarı erken zaferi hâlâ mümkün kılar, ancak
  /// canavarı maceranın ilk birkaç vuruşunda silip yürüyüşün büyük bölümünü
  /// atlamaya dönüştüremez.

  /// Oyuncunun başlangıç / taban canı (HP).
  static const int baseHp = 5000;

  /// Ejderha görevini tamamlamak için gereken adım sayısı.
  static const int dragonStepGoal = 20000;

  /// Daily walking goal, independent of adventure commitments and level costs.
  static const int dailyStepGoal = 7000;

  /// Yürüyüş özetlerinde kullanılan yaklaşık adım → mesafe dönüşümü.
  static const int stepsPerKilometer = 1250;

  /// Günlük çarkın çevrilebilmesi için gereken minimum adım sayısı.
  static const int dailyWheelUnlockSteps = 3000;

  /// Günlük serinin (streak) ilerlemesi için gereken minimum adım.
  ///
  /// Bilinçli olarak günlük hedeften bağımsız ve düşük tutuldu: seri
  /// "yürüdüm" demeli ama ulaşılamaz olmamalı. En düşük düşman eşiğiyle aynı.
  static const int streakStepThreshold = 2000;

  /// Seri kilometre taşları (gün).
  static const List<int> streakMilestones = [7, 30, 100];

  /// Aynı anda tutulabilecek en fazla seri dondurma hakkı.
  ///
  /// Stok sınırı, jetonların biriktirilip haftalarca kaçırmayı serbest
  /// bırakmasını engeller: seri hâlâ bir alışkanlık ölçüsü olmalı.
  static const int maxStreakFreezes = 2;

  /// Gün bitmeye bu kadar saat kala, seri henüz tamamlanmadıysa uyarılır.
  static const int streakWarningHours = 3;

  // --- Seri savaş stat bonusu (Bölüm 5C) ---

  /// Bir seri basamağının uzunluğu (gün).
  ///
  /// Gün başına kazanç her [streakBonusTierLength] günde bir azalır, tablonun
  /// sonunda başa döner (Bölüm B). Basamak sayısı ve azalma miktarı
  /// [streakBonusTierTenths] içinde; koda gömülü sayı yok.
  static const int streakBonusTierLength = 100;

  /// Basamak başına gün kazancı, **binde** cinsinden (5 = +%0,5).
  ///
  /// ```
  ///    1–100. gün : +%0,5
  ///  101–200. gün : +%0,4
  ///  201–300. gün : +%0,3
  ///  301–400. gün : +%0,2
  ///  401–500. gün : +%0,1
  ///  501+     gün : +%0,5 — döngü baştan başlar
  /// ```
  ///
  /// **Neden binde:** oran kayan noktada biriktirilirse tur atarken kayıyor
  /// (0.005 × 100 ≠ 0.5). Birikim tam sayı olarak tutulur, oran okurken
  /// türetilir. Aynı gerekçe Bölüm 5C'de "gün sayısı tutuluyor, oran değil"
  /// diye yazılmıştı; tek fark, gün başına kazanç artık sabit olmadığı için
  /// gün sayısı yetmiyor.
  ///
  /// **Neden azalıp sıfırlanıyor:** sabit kazanç uzun seride ya ekonomiyi
  /// uçurur ya da tavanla anlamsızlaşır. Azalan basamak ilerlemeyi
  /// yavaşlatır, sıfırlanma ise 500. günü geçmeyi bir **ödül** yapar.
  static const List<int> streakBonusTierTenths = [5, 4, 3, 2, 1];

  /// Geride kalan statın çekilişteki ağırlık üstünlüğü tavanı.
  ///
  /// Toplam tavan kalktığı için tek bir statın uçup gitmesini engelleyen tek
  /// mekanizma bu: her statın ağırlığı `1 + min(bu, ötedeki en yüksek stat −
  /// kendisi)`. Lider her zaman 1 ağırlıkla çekilişte kalır, yani
  /// rastgelelik gerçek; ama geride kalan en fazla 9 kat şanslı olur.
  ///
  /// **Neden sert bir stat tavanı yerine ağırlık:** toplam tavan kalkınca
  /// sert bir stat tavanı, uzun seride bütün statların tavana oturup her
  /// günün boşa gitmesi demekti — kaldırılan tavanın geri gelmesi.
  static const int streakBonusBalanceWeight = 8;

  /// Kaldırılan seri bonusu tavanlarının eski değerleri.
  ///
  /// Yalnızca eski kayıt/test okumaları ve tarihsel gerekçe için korunur;
  /// hesaplayıcı bunları uygulamaz (Bölüm B).
  static const double streakStatBonusPerDay = 0.01;
  static const double maxStreakStatBonus = 0.25;
  static const double maxStreakTotalBonus = 1.0;

  /// Aynı anda tutulabilecek en fazla ekstra çark hakkı.
  ///
  /// [maxStreakFreezes] ile aynı gerekçe: jeton biriktirip günlerce çark
  /// yağmuru yapmak, "günde bir kez" kuralını anlamsız kılardı.
  static const int maxExtraWheelSpins = 2;

  /// "2x XP" yükseltmesinin XP çarpanı. Yükseltme, satın alındığı oyun
  /// gününün sonuna kadar (bkz. [GameDay.nextResetAfter]) geçerlidir.
  static const int xpBoostMultiplier = 2;

  /// Kaç adımın 1 coin ettiği.
  ///
  /// Mağaza fiyatlarından türetildi (300 / 500 / 800 / 1200): günde 6.000 adım
  /// atan kullanıcı ~120 coin/gün, ~840 coin/hafta kazanır — yani haftada
  /// 1-2 anlamlı satın alma.
  static const int stepsPerCoin = 50;

  /// Yürüyüş fazında kaç adımın 1 coin ettiği (Bölüm A.3).
  ///
  /// Düşman devrildikten sonra maceranın adım taahhüdü bitene kadar süren
  /// faz boyunca oran [stepsPerCoin] yerine bu değerdir; macera tamamen
  /// bitince oran kendiliğinden 50'ye döner. Yürüyüşün asıl amacı olan
  /// "yürümeye devam et" davranışını ödüllendirir.
  ///
  /// **Neden yalnızca coin, XP değil:** iki kaldıracı birden oynatmak dengeyi
  /// ölçülemez hâle getirir. XP eğrisi (`stepsPerXp`) ayrıca gerekçelendirilmiş
  /// ve `step_xp_test.dart` ile bağlı; ona dokunmuyoruz.
  ///
  /// ⚠️ **30 → 20 (Bölüm D / Faz 1.5).** Düşmanı erken devirmek artık
  /// ölçülebilir bir başarı: yük oranı banda çekilince tek roundda devirmek
  /// gerçek bir ekipman yatırımı istiyor. Karşılığında açılan yürüyüş fazı
  /// da büyüdüğünden oranın büyümesi gerekiyordu — yoksa "erken bitir"
  /// ödülü, uzun ama zayıf bir sayaca dönüşüyordu.
  ///
  /// Normal orana göre **×2,5** (50 → 20). Kazanım yapısal olarak sınırlı
  /// kalıyor: faz en fazla `stepGoal` adım sürüyor, yani üst sınır
  /// `stepGoal / 20` coin ve bu da yalnızca hiç adım harcamadan devirmekle
  /// mümkün (GD58).
  static const int walkPhaseStepsPerCoin = 20;

  /// Zafer ödülü hız çarpanının tavanı (Bölüm A.2).
  ///
  /// Düşmanı adım taahhüdünün ne kadar erken bir noktasında devirdiysen ödül
  /// o kadar büyür: hiç adım harcamadan devirmek teorik üst sınır (×1,5), tam
  /// hedefte devirmek taban (×1). Tavan olmadan güçlü oyuncunun ödülü
  /// sınırsız büyürdü.
  ///
  /// **Neden ×1,5, ×2 değil:** zafer ödülü artık kademe bazlı büyüyor ve her
  /// savaştan garanti eşya düşüyor. Üç kaldıracın birden iki katına çıkması
  /// fazla olurdu. Eski değer ×1,02 idi — bu bir denge kararı değil,
  /// [perfectRoundStreakMultipliers] ile aynı sıfır kaymasıydı.
  static const double maxVictorySpeedMultiplier = 1.5;

  /// Walking XP remains an independent reward resource, not a level cost.
  static const int stepsPerXp = 2;

  /// Kaldırılan günlük coin tavanının eski değeri.
  ///
  /// ⚠️ **KULLANILMIYOR.** `coin_calculator.dart` bu değeri hiç okumaz ve
  /// `StepCoinReward.capReached` her zaman `false` döner. Yalnızca eski
  /// UI/API imzaları ve eski `dailyCoinCap` item etkilerini adım-parası
  /// oranına dönüştüren `equipped_buffs.dart` için korunur.
  ///
  /// Günlük tavan bilerek geri getirilmedi: ekonomi koruması
  /// [maxStepsPerMinute] fiziksel hız denetimine dayanıyor ve o daha sağlam
  /// — sabit bir tavan, çok yürüyen dürüst oyuncuyu cezalandırır.
  static const int maxDailyStepCoins = 400;

  /// Bir dakikada kabul edilen en fazla adım.
  ///
  /// Referans kadanslar: hızlı yürüyüş ~120/dk, koşu ~180/dk, yarış
  /// yürüyüşü ~200/dk. 250 bunların hepsinin üstünde güvenli bir tavan
  /// bırakır; telefonu sallamak ise kolayca 400+ üretir. Bu hızın üstündeki
  /// adımlar sensör arızası ya da hile sayılır ve **yakılır**.
  ///
  /// Günlük coin tavanı kaldırılmıştır; ekonomi koruması artık bu
  /// fiziksel hız denetimine dayanır.
  static const int maxStepsPerMinute = 250;

  /// Geçen süreye bakılmaksızın tek bir raporda kabul edilen taban adım.
  ///
  /// Sensör verisi tek tek değil, küçük partiler hâlinde gelebilir; aynı
  /// saniye içinde iki olay gelirse gerçek adımlar haksız yere kırpılmasın
  /// diye. Bilerek küçük tutuldu: uzun aradan sonra gelen büyük partiler
  /// zaten geçen süreden hak kazanır, bu taban yalnızca tek bir sensör
  /// partisini karşılamalı.
  static const int stepBurstAllowance = 100;

  /// Sensör sıfırlandığında (cihaz yeniden başlatma) telafi edilecek en fazla
  /// adım.
  ///
  /// Cihaz kapalıyken yeniden başlatılıp yürünen adımlar geri kazanılsın diye
  /// var; bozuk bir sensörün tek okumada ekonomiyi patlatmasını da engeller.
  /// 10.000 adım = 200 coin; günlük coin tavanı yoktur.
  static const int maxResetRecoverySteps = 10000;

  /// Tek bir item'ın verebileceği en yüksek **koşulsuz** oyun dışı oran
  /// bonusu (adım parası, adım XP, çark XP, düşman XP).
  ///
  /// Savaş statlarına uygulanmaz: savaş motoru Aşama 4a'da yazılacak ve
  /// denge orada yapılacak, o yüzden orada cömert olmak bedava. Oyun dışı
  /// statlar ise **bugün canlı** ve ölçülmüş bir ekonomiye bağlı
  /// (`economy_pacing_test.dart`); tek bir efsanevi item'ın ekonomiyi
  /// devirmesi mümkün olmamalı.
  static const double maxSingleItemEconomyBonus = 0.15;

  /// Kuşanılan **bütün** slotların toplamında izin verilen en yüksek oyun
  /// dışı oran bonusu.
  ///
  /// Slot sayısı sınıfa göre 3–5 arasında değişiyor (bkz. GD15). Item başına
  /// tavan %15 olduğu için beş slot teorik olarak %75'e çıkabilirdi; bu sert
  /// kırpma o ihtimali kapatıyor. Kırpma toplama noktasında yapılır
  /// (`equipped_buffs.dart`), yani item tasarımı ne olursa olsun garanti.
  static const double maxEquippedEconomyBonus = 0.50;

  /// Tek bir **ünvanın** verebileceği en yüksek koşulsuz ekonomi oranı (+%25).
  ///
  /// Item tavanından ([maxSingleItemEconomyBonus], +%15) yüksek: oyuncu aynı
  /// anda 3-5 item kuşanabiliyor ama **tek** ünvan takıyor (Bölüm C.2), yani
  /// ünvanın tek başına hissedilmesi gerekiyor.
  ///
  /// Bu bir **tasarım disiplini**, garanti değil: garantiyi toplama
  /// noktasındaki [maxEquippedEconomyBonus] kırpması veriyor (GD25). İkisi
  /// birlikte tutuluyor — ilki testle taranıyor, ikincisi kodla zorlanıyor.
  static const double maxTitleEconomyBonus = 0.25;

  /// Aynı tavanın **seyrek olay** statları için karşılığı (+%50).
  ///
  /// `wheelXp` ve `enemyXp` günde bir kez (çark) ya da macera başına bir kez
  /// (düşman) uygulanıyor; adım parası ve adım XP'si gibi her adımda değil.
  /// GD17 aynı gerekçeyle item bütçesinde bu iki statı iki katı ölçekliyor —
  /// ünvan tarafında da aynı ölçek geçerli olmalı, yoksa seyrek statlı bir
  /// ünvan etiketi kadar bile hissedilmez.
  ///
  /// Ekonomiye risk yok: ikisi de **XP** veriyor, XP'nin harcanacağı bir yer
  /// yok ve ölçülmüş coin dengesine ([stepsPerCoin]) hiç dokunmuyorlar.
  static const double maxTitleRareEventBonus = 0.50;

  /// Kaldırılan `dailyCoinCap` buff API'sinin eski toplama sınırı.
  /// Aktif katalog artık bu buff'ı üretmez.
  static const int maxEquippedCoinCapBonus = 200;

  /// Kuşanılan itemlerin stok tavanlarına ekleyebileceği en fazla hak
  /// (dondurma ve ekstra çark hakkı için ayrı ayrı).
  static const int maxEquippedStockBonus = 2;

  /// Kuşanılan itemlerin seri eşiğinden düşebileceği en fazla adım.
  ///
  /// [streakStepThreshold] 2000; yarısıyla sınırlı, yani eşik hiçbir zaman
  /// 1000 adımın altına inmez. Seri hâlâ "yürüdüm" demeli.
  static const int maxEquippedStreakRelief = 1000;

  /// Item satarken geri alınan fiyat oranı.
  ///
  /// %40: satmak bir çıkış yolu olmalı ama alım-satım döngüsüyle para
  /// üretilememeli. Tam iade olsaydı oyuncu itemleri "depo" gibi kullanır,
  /// çok düşük olsaydı yanlış alınan bir item kalıcı bir ceza olurdu.
  static const double itemSellRatio = 0.4;

  /// Takımda "yan yana yürüyor" sayılmak için, üyelerin adım atma
  /// zamanları arasında izin verilen maksimum fark (dakika).
  static const int sideBySideWindowMinutes = 5;

  /// Diskte tutulan tamamlanmış gün sayısı (adım halkası geçmişi).
  ///
  /// Geçmiş her gün bir satır büyüyor ve kayıt tek bir SharedPreferences
  /// anahtarında duruyor; sınırsız büyümek hem açılış okumasını hem her
  /// yazmayı yavaşlatır. 400 gün, takvim ekranında bir yıl geriye rahatça
  /// gitmeye yeter (~13 ay) ve ~40 KB'ın altında kalır.
  static const int maxStepHistoryDays = 400;

  // --- Demirci: eşya yükseltme (Bölüm 4) ---

  /// Nadirliğin izin verdiği en yüksek **eşya** seviyesi.
  ///
  /// Nadirlik böylece kalıcı bir üstünlük oluyor: sıradan bir eşya sonuna
  /// kadar yükseltilse bile efsanevi bir eşyaya yetişemiyor. İkinci tavan
  /// oyuncunun kendi seviyesi ([maxItemLevelFor]).
  static const Map<RewardRarity, int> itemLevelCapByRarity = {
    RewardRarity.common: 10,
    RewardRarity.uncommon: 20,
    RewardRarity.rare: 30,
    RewardRarity.epic: 40,
    RewardRarity.legendary: 50,
  };

  /// Bir eşyayı **1'den tavanına** çıkarmanın toplam maliyeti, eşyanın
  /// fiyatının katı olarak.
  ///
  /// Tek bir sayı olması bilinçli: maliyet eğrisi bütün nadirliklerde aynı
  /// şekli koruyor, yalnızca ölçeği değişiyor. Ölçülen sonuç (120 coin/gün
  /// atan referans oyuncu için) `item_leveling_test.dart` içinde bağlı —
  /// oyuncunun kendi seviyesi neredeyse her katmanda **coinden daha sıkı**
  /// bir kısıt, yani yükseltmek pahalı ama imkânsız değil.
  static const double itemUpgradeTotalMultiplier = 7.0;

  /// Nadirliğe göre yükseltme toplam maliyeti katı.
  ///
  /// ⚠️ **Kat nadirlikle monoton değil — bilerek.** Bağlayıcı ölçüt kat değil,
  /// **gün**: bağlı oyuncunun (≈300 coin/gün) bir eşyayı 1'den tavana
  /// çıkarması ne kadar sürüyor.
  ///
  /// | Nadirlik | Kat | Fiyat | Toplam | Gün |
  /// |---|---|---|---|---|
  /// | Sıradan | ×6,0 | 100 | 600 | 2 |
  /// | Az Bulunur | ×7,0 | 350 | 2.425 | 8 |
  /// | Nadir | ×8,0 | 825 | 6.575 | 22 |
  /// | Epik | ×7,0 | 3.825 | ~26.800 | ~89 |
  /// | Efsanevi | ×4,5 | 11.600 | ~52.200 | ~174 |
  ///
  /// **Neden efsanevinin katı en düşük:** fiyat zaten nadirlikle keskin
  /// artıyor (100 → 11.600, **×116**). Katı da yükseltmek aynı şeyi iki kez
  /// saymaktı ve efsaneviyi **503 güne** çıkarıyordu — bir hedef değil, bir
  /// duvar. Oyuncu o eşyayı hiç yükseltmemeye karar verdiğinde sistem ölür.
  /// Toplam maliyet ve gün sayısı **hâlâ kesin artan** (600 → 52.200,
  /// 2 → 174 gün); tersine dönen tek şey oranın kendisi.
  static const Map<RewardRarity, double> itemUpgradeMultiplierByRarity = {
    RewardRarity.common: 6.0,
    RewardRarity.uncommon: 7.0,
    RewardRarity.rare: 8.0,
    RewardRarity.epic: 7.0,
    RewardRarity.legendary: 4.5,
  };

  /// [itemUpgradeMultiplierByRarity] araması; tanımsızsa eski tek sayıya
  /// düşer, böylece yeni bir nadirlik eklenirse sessizce bozulmaz.
  static double upgradeMultiplierFor(RewardRarity rarity) =>
      itemUpgradeMultiplierByRarity[rarity] ?? itemUpgradeTotalMultiplier;

  /// Maliyet eğrisinin erken seviye ağırlığı.
  ///
  /// Bir seviyenin payı `erken ağırlık + seviye / tavan`. İlk seviyeler ucuz,
  /// son seviyeler pahalı; ağırlıkların toplamı tam olarak `tavan - 1` ettiği
  /// için toplam maliyet [itemUpgradeTotalMultiplier] ile birebir tutuyor.
  static const double itemUpgradeEarlyWeight = 0.5;

  /// Eşya seviyesi başına **savaş** statı artışı.
  ///
  /// Seviye 1 = ×1.00, seviye 10 = ×1.90, seviye 50 = ×5.90. Bir katmanın
  /// tavanı bir üst katmanın tabanının üstüne çıkıyor ama katmanların
  /// tavanları arasındaki sıra hiç bozulmuyor — "yükseltmek mi, yeni eşya mı"
  /// sorusunun gerçek bir soru olmasının sebebi bu.
  ///
  /// ⚠️ **Ekonomi bonuslarına uygulanmaz.** Ekonomi dikkatle dengelendi
  /// (`economy_pacing_test.dart`); adım→para ve adım→XP çarpanları seviyeyle
  /// büyüseydi günlük tavan katlanır ve denge çökerdi.
  static const double itemStatGrowthPerLevel = 0.10;

  // --- Demirci: eşya birleştirme (Bölüm 4.3) ---

  /// Bir üst nadirliğe geçmek için gereken **adet**.
  ///
  /// Üçten başlıyor ve her kademede bir artıyor: nadirlik yükseldikçe
  /// birleştirmek zorlaşıyor. Efsanevi anahtarı **yok** — üstünde nadirlik
  /// olmadığı için efsaneviler birleştirilemiyor.
  ///
  /// Tek config sabiti; koda gömülü sayı yok.
  /// Nadir ve epik adetleri Faz 2'de artırıldı (5→6, 6→8): her savaştan
  /// garanti eşya düştüğü için kopya biriktirmek belirgin biçimde
  /// kolaylaştı, birleştirme de aynı oranda zorlaşmalıydı.
  static const Map<RewardRarity, int> itemMergeCounts = {
    RewardRarity.common: 3,
    RewardRarity.uncommon: 4,
    RewardRarity.rare: 6,
    RewardRarity.epic: 8,
  };

  /// Birleştirme ücretinin, **hedef** nadirlikteki eşya fiyatına oranı.
  ///
  /// %50: birleştirme yoluyla bir eşyaya sahip olmak, aynı eşyayı doğrudan
  /// satın almanın kabaca iki katına mal oluyor. Karşılığında iki şey
  /// kazanılıyor: eşyanın **seviye kilidi değişmiyor** (GD40), yani
  /// erişemeyeceğin bir nadirliği erken kuşanabiliyorsun; ve nadirlik
  /// tavanı yükseldiği için eşya çok daha ileri yükseltilebiliyor.
  static const double itemMergeCostRatio = 0.5;
}
