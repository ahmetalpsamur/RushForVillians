import '../../models/reward_rarity.dart';

/// Oyunun temel dengeleme (balance) sabitleri.
///
/// Tasarım fikrindeki sayılar burada tek noktadan yönetilir, böylece
/// ilerideki dengeleme değişiklikleri tek dosyadan yapılabilir.
class GameConstants {
  GameConstants._();

  /// Oyuncunun başlangıç / taban canı (HP).
  static const int baseHp = 5000;

  /// Ejderha görevini tamamlamak için gereken adım sayısı.
  static const int dragonStepGoal = 20000;

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

  /// Her seri günü, savaş statlarından **birine** eklenen oran (0.01 = +%1).
  ///
  /// Bonus tek bir stata değil, gün gün seçilen statlara dağılır: 30 günlük
  /// bir seri oyuncuya kendine özgü bir savaş profili bırakır ve her gün
  /// "bugün ne kazandım" anı olur.
  static const double streakStatBonusPerDay = 0.01;

  /// Tek bir savaş statının seriden alabileceği en fazla oran (+%25).
  ///
  /// Tavana ulaşan stat havuzdan çıkarılır, yani gün boşa gitmez. Sınır,
  /// uzun serinin tek bir stata yığılıp diğerlerini anlamsız kılmasını
  /// engelliyor.
  static const double maxStreakStatBonus = 0.25;

  /// Seriden gelen **toplam** savaş bonusu tavanı (+%100).
  ///
  /// Gün başına +%1 ile ~100 günde dolar. Yedi stata yayıldığı için tek
  /// statlık eski tavanlar çok düşük kalırdı; buna karşılık stat başına
  /// tavan (+%25) tek bir statın uçmasını engelliyor.
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
