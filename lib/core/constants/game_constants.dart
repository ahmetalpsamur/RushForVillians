import '../../models/reward_rarity.dart';

/// Oyunun temel dengeleme (balance) sabitleri.
///
/// Tasarım fikrindeki sayılar burada tek noktadan yönetilir, böylece
/// ilerideki dengeleme değişiklikleri tek dosyadan yapılabilir.
class GameConstants {
  GameConstants._();

  // --- Savaş temposu ve mükemmel round (Bölüm B) ---

  /// Yürüyüş temposunun **anlatım** değeri: 100 adım/dakika.
  ///
  /// Round süreleri artık bu sayıdan **türetilmiyor**; her kademenin süresi
  /// [combatRoundTiers] içinde elle yazılı (GD85). Sayı yine de doğru: tablodaki
  /// dört kademenin hepsi tam olarak 100 adım/dk kadansını tutuyor. Arayüz
  /// oyuncuya tempoyu bu sabitle anlatıyor, kısalan son round süresi de bu
  /// oranla ölçekleniyor.
  static const int stepsPerMinute = 100;

  /// Round büyüklüğü kademeleri — **sabit tablo, formül değil** (GD85).
  ///
  /// Düşmanın **toplam** adım hedefi hangi kademeye düşüyorsa, roundun adımı ve
  /// süresi o kademenin elle yazılmış iki değeridir. İkisi birbirinden
  /// türetilmez; ayrı ayrı yazılır ki tablo okunduğu gibi olsun.
  ///
  /// ```
  /// | Toplam adım      | Round adımı | Round süresi |
  /// | 1000'den az      |     250     |    2,5 dk    |
  /// | 1000 – 2999      |     500     |      5 dk    |
  /// | 3000 – 9999      |    1000     |     10 dk    |
  /// | 10000 ve üstü    |    2000     |     20 dk    |
  /// ```
  ///
  /// Bu bir ayar değil: oyuncuya açılmıyor, seçenek sunulmuyor.
  static const List<CombatRoundTier> combatRoundTiers = [
    CombatRoundTier(
      minTotalSteps: 0,
      roundSteps: 250,
      roundDuration: Duration(seconds: 150),
    ),
    CombatRoundTier(
      minTotalSteps: 1000,
      roundSteps: 500,
      roundDuration: Duration(minutes: 5),
    ),
    CombatRoundTier(
      minTotalSteps: 3000,
      roundSteps: 1000,
      roundDuration: Duration(minutes: 10),
    ),
    CombatRoundTier(
      minTotalSteps: 10000,
      roundSteps: 2000,
      roundDuration: Duration(minutes: 20),
    ),
  ];

  /// Hasar ölçeğinin **birim** roundu: en küçük kademenin round adımı.
  ///
  /// Bir round bir yürüyüş taahhüdüdür; 2000 adımlık bir round 250 adımlık
  /// rounddan sekiz kat daha fazla yürümek demektir ve vuruşu da o oranda
  /// büyüktür (GD86). Düşman canı da aynı birimle ölçüldüğü için kademe tablosu
  /// değişse bile "hedefi tutturan oyuncu maceranın sonunda devirir" sözü
  /// bozulmaz.
  static const int referenceRoundSteps = 250;

  /// Son roundun ayrı bir round sayılabilmesi için gereken en az adım.
  ///
  /// Tam bölünmeyen hedeflerde kalan adımlar kısa bir **son round** olur
  /// (GD85). Bundan küçük bir kalıntı round değil, yuvarlama artığıdır: bir
  /// önceki rounda katılır ki 1 adımlık, 1 saniyelik round oluşmasın. Mağaza
  /// çarkı 500'ün katlarını verdiği için bu dal pratikte yalnızca eski
  /// kayıtlarda ve testlerde çalışır.
  static const int minFinalRoundSteps = 50;

  /// Kısa macerada bile gerilim kurmak için gereken en az round.
  ///
  /// Kademe tablosu bunu kendiliğinden sağlıyor (en küçük hedef 500 adım =
  /// 2 × 250). Sabit, eski kayıtları okuyan kod yolları ve tablo doğrulaması
  /// için duruyor; round sayısını artık **kırpmıyor**.
  static const int minCombatRounds = 2;

  /// Saldırının fitness fazı sayısı (`AttackConfig.rounds`).
  ///
  /// Round **sayısının** tavanı değil: kademe tablosuyla bir macera 10 ve daha
  /// fazla round sürebilir. Beş faz o roundlara dağıtılır.
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
  static const List<double> perfectRoundStreakMultipliers = [1.2, 1.5, 2.0];

  /// Oyuncunun başlangıç / taban canı (HP).
  static const int baseHp = 5000;

  /// Ejderha görevini tamamlamak için gereken adım sayısı.
  static const int dragonStepGoal = 20000;

  /// Yürüyüş özetlerinde kullanılan yaklaşık adım → mesafe dönüşümü.
  static const int stepsPerKilometer = 1250;

  /// Bir seviye atlamak için gereken taban XP. Her seviyede artar.
  ///
  /// Eğri `baseXpPerLevel * level`: seviye başına maliyet **doğrusal** artar,
  /// kümülatif maliyet karesel olur (N. seviyeye ulaşmak `500·N·(N-1)` XP).
  /// Günlük girdisi kabaca sabit olan bir oyuncu için seviye numarası
  /// `√gün` hızında ilerler — erken seviyeler hızlı, sonrakiler anlamlı.
  ///
  /// **Üstel eğri bilerek seçilmedi:** girdisi gerçek hayattan gelen bir
  /// oyunda üstel maliyet, bir noktada "aylarca sürecek seviye" üretir ve
  /// sayı durmuş gibi görünür. Doğrusal artış, sonraki seviyeyi her zaman
  /// makul bir ufukta tutar.
  static const int baseXpPerLevel = 1000;

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
  /// o kadar büyür: hiç adım harcamadan devirmek teorik üst sınır (×2), tam
  /// hedefte devirmek taban (×1). Tavan olmadan güçlü oyuncunun ödülü
  /// sınırsız büyürdü.
  static const double maxVictorySpeedMultiplier = 2.0;

  /// Kaç adımın 1 XP ettiği.
  ///
  /// Seviye eğrisinden ([baseXpPerLevel]) türetildi: 10. seviyeye ulaşmak
  /// 45.000 XP istiyor. Günde 6.000 adım atan kullanıcı bu oranla 3.000 XP/gün
  /// kazanır ve 10. seviyeye **yalnızca adımla 15 günde** ulaşır; düşman ve
  /// çark XP'si bunu ~12 güne indirir. Erken seviyeler günler değil saatler
  /// sürer, bu da ilk oturumda ilerleme hissi verir.
  ///
  /// XP'nin günlük tavanı yoktur. Sahte adıma karşı koruma
  /// [maxStepsPerMinute] ile yapılır.
  static const int stepsPerXp = 2;

  /// Kaldırılan günlük coin tavanının eski değeri.
  ///
  /// Yalnızca eski UI/API ve eski `dailyCoinCap` item etkilerini adım-parası
  /// oranına dönüştürmek için korunur. Coin hesaplayıcı bunu uygulamaz.
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
  static const Map<RewardRarity, int> itemMergeCounts = {
    RewardRarity.common: 3,
    RewardRarity.uncommon: 4,
    RewardRarity.rare: 5,
    RewardRarity.epic: 6,
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

/// Tek bir round büyüklüğü kademesi.
///
/// [roundSteps] ve [roundDuration] birbirinden **türetilmez**; ikisi de
/// [GameConstants.combatRoundTiers] içinde elle yazılır (GD85).
class CombatRoundTier {
  /// Kademenin geçerli olduğu en küçük **toplam** adım hedefi.
  final int minTotalSteps;

  /// Bu kademede bir roundun adım hedefi.
  final int roundSteps;

  /// Bu kademede bir roundun süresi.
  final Duration roundDuration;

  const CombatRoundTier({
    required this.minTotalSteps,
    required this.roundSteps,
    required this.roundDuration,
  }) : assert(minTotalSteps >= 0),
       assert(roundSteps > 0);
}
