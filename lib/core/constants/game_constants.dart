import '../../models/reward_rarity.dart';

/// Oyunun temel dengeleme (balance) sabitleri.
///
/// Tasarım fikrindeki sayılar burada tek noktadan yönetilir, böylece
/// ilerideki dengeleme değişiklikleri tek dosyadan yapılabilir.
class GameConstants {
  GameConstants._();

  // --- Savaş temposu ve mükemmel round (Bölüm B) ---

  /// Referans yürüyüş temposu — ve [combatRoundPacing]'in **ortak kadansı**.
  ///
  /// Tablonun dört bandının hepsi tam olarak bu hızı verir:
  /// 250/2,5dk · 500/5dk · 1.000/10dk · 2.000/20dk = **100 adım/dk**.
  /// Yani bant değiştikçe roundun boyu ve süresi birlikte iki katına çıkıyor,
  /// oyuncudan istenen tempo hiç değişmiyor. Bir dönem bu sabit yalnızca
  /// arayüz etiketiydi ve round hesabına hiç girmiyordu.
  static const int stepsPerMinute = 100;

  /// Round temposu tablosu — **sabit, türetilmiyor, kullanıcı değiştiremez**.
  ///
  /// Her satır bir adım hedefi bandını ve o bandın round boyunu verir.
  /// Bir hedef için geçerli satır, `minGoal`'ü hedefi aşmayan **son**
  /// satırdır:
  ///
  /// ```
  ///   hedef  <  1.000 : round  250 adım /  2,5 dk
  ///   1.000–  2.999   : round  500 adım /  5   dk
  ///   3.000–  9.999   : round 1.000 adım / 10  dk
  ///   hedef >= 10.000 : round 2.000 adım / 20  dk
  /// ```
  ///
  /// **Neden tablo, formül değil:** tempo bir denge kararı, matematiksel bir
  /// sonuç değil. Formül her hedefte "doğru" bir sayı üretir ama hiçbirinde
  /// istenen sayıyı üretmez. Bant sayısı dört; her bandın round boyu bir
  /// öncekinin iki katı, süresi de öyle — yani kadans bant içinde sabit,
  /// bantlar arasında iki katına çıkıyor.
  ///
  /// Bu tablo **sabit 1.000 adım / 15 dakika** düzeninin yerine geçti; eski
  /// düzende 500 adımlık macera tek roundluk gerilimsiz bir sayaçtı,
  /// 10.000'lik macera ise 10 rounda dağılıyordu.
  /// [rewardMultiplier] aynı bandın **zafer ödülü** çarpanıdır: ödül ile
  /// tempo tek tablodan okunur, ikinci bir kademe tanımı yoktur.
  static const List<
    ({int minGoal, int roundSteps, int roundSeconds, double rewardMultiplier})
  >
  combatRoundPacing = [
    (minGoal: 0, roundSteps: 250, roundSeconds: 150, rewardMultiplier: 1.0),
    (minGoal: 1000, roundSteps: 500, roundSeconds: 300, rewardMultiplier: 1.4),
    (minGoal: 3000, roundSteps: 1000, roundSeconds: 600, rewardMultiplier: 2.0),
    (
      minGoal: 10000,
      roundSteps: 2000,
      roundSeconds: 1200,
      rewardMultiplier: 3.0,
    ),
  ];

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

  /// Uzun maceraların tekrar hissine dönüşmemesi için round tavanı.
  ///
  /// [combatRoundPacing] altı seçilebilir hedefin hepsinde zaten en fazla 5
  /// round üretiyor; bu tavan **eski kayıtlardan** gelen ya da tabloda
  /// karşılığı olmayan hedefler için bağlayıcı bir güvence. Tavan devreye
  /// girerse round boyu büyür, round sayısı 5'te kalır.
  static const int maxCombatRounds = 5;

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
  static const int walkPhaseStepsPerCoin = 30;

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

  /// Nadirliğe göre yükseltme toplam maliyeti katı (güç enflasyonu freni).
  ///
  /// Eskiden bütün nadirliklerde tek bir sayıydı (×7). Artık yükseldikçe
  /// sertleşiyor: sıradan bir eşyayı sonuna kadar götürmek ucuzladı (×6),
  /// efsaneviyi götürmek neredeyse iki katına çıktı (×13). Nadirlik böylece
  /// yalnızca **tavanı** değil, o tavana çıkmanın **maliyetini** de
  /// belirliyor.
  static const Map<RewardRarity, double> itemUpgradeMultiplierByRarity = {
    RewardRarity.common: 6.0,
    RewardRarity.uncommon: 7.0,
    RewardRarity.rare: 8.0,
    RewardRarity.epic: 10.0,
    RewardRarity.legendary: 13.0,
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
