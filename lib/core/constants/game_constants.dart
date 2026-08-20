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

  /// Kaç adımın 1 XP ettiği.
  ///
  /// Seviye eğrisinden ([baseXpPerLevel]) türetildi: 10. seviyeye ulaşmak
  /// 45.000 XP istiyor. Günde 6.000 adım atan kullanıcı bu oranla 3.000 XP/gün
  /// kazanır ve 10. seviyeye **yalnızca adımla 15 günde** ulaşır; düşman ve
  /// çark XP'si bunu ~12 güne indirir. Erken seviyeler günler değil saatler
  /// sürer, bu da ilk oturumda ilerleme hissi verir.
  ///
  /// **Günlük XP tavanı bilerek yok.** Para tavanı ([maxDailyStepCoins]) bir
  /// ekonomi koruması; XP'nin harcanacağı bir yer olmadığı için aynı gerekçe
  /// geçerli değil. Sahte adıma karşı koruma zaten yukarıda,
  /// [maxStepsPerMinute] ile yapılıyor — gerçekten 20.000 adım atan kullanıcı
  /// ilerlemesinin kesilmesini hak etmiyor.
  static const int stepsPerXp = 2;

  /// Adımlardan bir günde kazanılabilecek en fazla para.
  ///
  /// 400 coin = 20.000 adım, yani [dragonStepGoal] ile aynı: gerçekten o kadar
  /// yürüyen kullanıcı cezalanmaz, telefon sallayan da günde bundan fazlasını
  /// alamaz. Adım hızı kontrolü ayrıca [maxStepsPerMinute] ile yapılır.
  static const int maxDailyStepCoins = 400;

  /// Bir dakikada kabul edilen en fazla adım.
  ///
  /// Referans kadanslar: hızlı yürüyüş ~120/dk, koşu ~180/dk, yarış
  /// yürüyüşü ~200/dk. 250 bunların hepsinin üstünde güvenli bir tavan
  /// bırakır; telefonu sallamak ise kolayca 400+ üretir. Bu hızın üstündeki
  /// adımlar sensör arızası ya da hile sayılır ve **yakılır**.
  ///
  /// Günlük coin tavanının ([maxDailyStepCoins]) yerine geçmez, üstünde
  /// çalışır: burada "kaç adım", orada "kaç para" sorusu cevaplanır.
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
  /// var; bozuk bir sensörün tek okumada günlük tavanı patlatmasını da
  /// engeller. 10.000 adım = 200 coin, yani günlük tavanın yarısı.
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

  /// Kuşanılan itemlerin günlük coin tavanına ekleyebileceği en fazla coin.
  ///
  /// [maxDailyStepCoins] üstüne gelir; yarısıyla sınırlı tutuldu ki tavan
  /// hâlâ bir tavan olsun.
  static const int maxEquippedCoinCapBonus = 200;

  /// Kuşanılan itemlerin stok tavanlarına ekleyebileceği en fazla hak
  /// (dondurma ve ekstra çark hakkı için ayrı ayrı).
  static const int maxEquippedStockBonus = 2;

  /// Kuşanılan itemlerin seri eşiğinden düşebileceği en fazla adım.
  ///
  /// [streakStepThreshold] 2000; yarısıyla sınırlı, yani eşik hiçbir zaman
  /// 1000 adımın altına inmez. Seri hâlâ "yürüdüm" demeli.
  static const int maxEquippedStreakRelief = 1000;

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
}
