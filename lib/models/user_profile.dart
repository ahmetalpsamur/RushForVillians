import '../core/constants/game_constants.dart';
import '../core/utils/game_clock.dart';
import '../core/utils/game_day.dart';
import '../core/utils/streak_bonus.dart';
import 'avatar_profile.dart';
import 'owned_item.dart';
import 'reward_rarity.dart';
import 'streak_stat_bonuses.dart';

/// Gün döngüsü kontrolünün seri açısından sonucu.
enum StreakDayOutcome {
  /// Seride görünür bir değişiklik yok.
  unchanged,

  /// Gün atlandı, seri sıfırlandı.
  broken,

  /// Gün atlandı ama dondurma hakkı harcanarak seri korundu.
  frozen,
}

/// Oyuncunun genel ilerlemesi: can, seviye, XP, streak ve para birimi.
class UserProfile {
  AvatarProfile avatar;
  int hp;
  int maxHp;
  int level;
  int xp;
  int coins;
  int streakDays;

  /// Serinin en son ilerlediği oyun günü. Seri hesabının dayanağı budur.
  DateTime? lastActiveDay;

  /// Şimdiye kadar ulaşılan en uzun seri. Seri kırılsa da korunur.
  int longestStreak;

  /// Elde tutulan seri dondurma hakkı (jeton).
  ///
  /// Seri kırılacakken **otomatik** harcanır: kaçırılan tek günü köprüler,
  /// seri korunur ama artmaz. Varsayılan 0 olduğu için bugün hiçbir davranış
  /// değişmiyor — kazanım yolları Aşama 3'te geliyor.
  int streakFreezes;

  /// Dondurma hakkının kapattığı son oyun günü.
  ///
  /// "Art arda en fazla 1 gün korunur" kuralının dayanağı: son aktif gün
  /// zaten bir dondurma ile kapatılmışsa ikinci jeton kullanılamaz.
  DateTime? lastFreezeUsedOn;

  /// En son güvenilir kabul edilen zaman (UTC). [GameClock] geriye alınan
  /// cihaz saatini bununla yakalar; kapat-aç sonrası da geçerli olsun diye
  /// diske yazılır.
  DateTime? lastSeenAt;

  /// Oyun boyunca atılan toplam adım. Günlük ilerlemeden bağımsız birikir.
  int totalSteps;

  /// [totalSteps]'in paraya çevrilmiş olduğu nokta.
  ///
  /// Para **delta**dan kazanılır: `totalSteps - lastRewardedStepCount` kadar
  /// adım bekliyor demektir. Böylece aynı adım ikinci kez para kazandıramaz —
  /// uygulama kapanıp açılsa, gün değişse, macera seçilse de.
  int lastRewardedStepCount;

  /// [totalSteps]'in XP'ye çevrilmiş olduğu nokta.
  ///
  /// [lastRewardedStepCount]'tan **bilerek ayrı**: ikisi aynı işaretçiyi
  /// paylaşsaydı, farklı dönüşüm oranları bir işaretçinin diğer ödüle ait
  /// artık adımları tüketmesine ve XP'nin kaybolmasına yol açardı.
  int lastXpRewardedStepCount;

  /// Adım kaynağından **raporlanmış** son kümülatif değer.
  ///
  /// [totalSteps]'ten ayrıdır ve ondan büyük olabilir: hız kontrolüne
  /// (`limitStepBatch`) takılan adımlar raporlanmış sayılır ama kredilenmez.
  /// İşaretçi her raporda ilerlediği için yakılan adım bir sonraki raporda
  /// geri sızmaz.
  int lastReportedStepCount;

  /// Ham sensör sayacının, [lastReportedStepCount] anındaki değeri.
  ///
  /// Kapat-aç sonrası sayacın kaldığı yerden devam etmesi buna bağlı.
  /// **Nullable olması şart:** varsayılan 0 olsaydı, cihaz açılışından beri
  /// birikmiş ham değer (milyonlarca adım) ilk okumada tek seferde
  /// kredilenirdi. `null` = referans henüz kurulmadı.
  int? lastSensorReading;

  /// Son adım raporunun anı (UTC). Hız kontrolünün "aradan ne kadar süre
  /// geçti" hesabı buradan gelir; kapat-aç sonrası da geçerli olsun diye
  /// diske yazılır.
  DateTime? lastStepReportAt;

  /// Envanterdeki ekipman **örnekleri**.
  ///
  /// Kimlik listesi değil: aynı eşyadan birden fazla adet bulunabiliyor ve
  /// her adedin kendi seviyesi, kendi nadirliği ve kendi kuşanma durumu var
  /// (bkz. [OwnedItem], GD39). Birleştirme aynı eşyanın birkaç adedini
  /// tüketip bir üst nadirlikte tek örnek ürettiği için bu şart.
  ///
  /// Model Kuralları #1: yalnızca `String` ve sayı tutulur; item'ın kendisi
  /// her açılışta katalogdan çözülür ve sınıfa uyarlanır — kimliğe sınıf
  /// gömülmediği için (GD16) sınıf değişse de sahiplik kaybolmaz.
  final List<OwnedItem> ownedItems;

  /// Mağazadan alınmış **yükseltmelerin** kimlikleri (kozmetik, unvan,
  /// dondurma hakkı, 2x XP...).
  ///
  /// Ekipmandan ayrı bir liste: ikisi farklı kavram ve eskiden aynı listede
  /// duruyorlardı. Yükseltme kimlikleri (`boost_double_xp`) hiç `/`
  /// içermiyor, katalog kimlikleri (`swords/fire_sword`) her zaman içeriyor —
  /// v11 → v12 taşıması bu ayrımı kullanıyor.
  final List<String> ownedUpgradeIds;

  /// Bir sonraki [OwnedItem.instanceId] için sayaç.
  ///
  /// Rastgele değil, kalıcı ve tekdüze artan: kayıt tekrarlanabilir kalıyor
  /// ve tohum gerektirmiyor.
  int nextItemInstanceId;

  /// Günlük çarkın en son çevrildiği an. Gün başına tek hak kontrolü ve
  /// kalıcılık için kullanılır.
  DateTime? lastWheelSpinAt;

  /// Mağazadan alınmış ekstra çark hakkı (jeton).
  ///
  /// Günlük hak kullanıldıktan sonra çevirmeyi mümkün kılar. Stok
  /// [GameConstants.maxExtraWheelSpins] ile sınırlı.
  int extraWheelSpins;

  /// Günlük çarkın tohumu (#16).
  ///
  /// Çark ödülü kalıcı bir sonuç üretiyor (XP ya da item), bu yüzden
  /// rastgeleliği tohumlu ve **saklanan** olmak zorunda — CLAUDE.md §4.4.
  /// Her çevirmeden sonra bir adım ilerletilir; `0` = henüz kurulmadı.
  int wheelSeed;

  /// "2x XP" yükseltmesinin bitiş anı (UTC). `null` = etkin değil.
  ///
  /// Satın alındığı oyun gününün sonunda ([GameDay.nextResetAfter]) düşer;
  /// ayrı bir gün hesabı yapılmaz.
  DateTime? xpBoostUntil;

  /// Serinin biriktirdiği savaş stat bonusları (Bölüm 5C).
  ///
  /// Her seri günü havuzdan bir stat seçilip büyür. Birikim **kalıcı**:
  /// çekiliş yol bağımlı olduğu için (tavana ulaşan stat havuzdan çıkar)
  /// tohumdan yeniden üretilemez. Seri kırılınca tamamen sıfırlanır.
  StreakStatBonuses streakStatBonuses;

  /// Seri stat çekilişinin tohumu. `0` = henüz kurulmadı.
  ///
  /// Çark tohumundan ([wheelSeed]) **ayrı** tutuluyor: aynı sayacı
  /// paylaşsalardı çarkı çevirmek ertesi günün stat çekilişini değiştirir,
  /// yani oyuncuya sıra üzerinden bir zar atma yolu açardı.
  int streakBonusSeed;

  /// Seri stat bonusunun verildiği son oyun günü.
  ///
  /// Aynı gün ikinci kez çekiliş yapılmamasının dayanağı: uygulamayı kapatıp
  /// açmak yeni bir zar attırmaz.
  DateTime? lastStreakBonusDay;

  /// Tutorial bir kez tamamlandıktan sonra yeniden açılmaz.
  bool hasCompletedTutorial;

  /// Yarım kalan tutorialın kaldığı merkezi adım indeksi.
  int tutorialStep;

  /// İlk kurulumda seçilen yol arkadaşının kalıcı kimliği.
  String tutorialGuideId;

  /// Eğitimin satın aldıracağı, sınıfa uygun ilk silahın kimliği.
  String? tutorialStarterItemId;

  // --- Ünvanlar (Bölüm C) ---

  /// Kazanılmış ünvanların kimlikleri.
  ///
  /// Model Kuralları #1: yalnızca `String` tutulur; ünvanın adı, nadirliği ve
  /// etkileri her açılışta [TitleCatalog] üzerinden çözülür.
  /// Rehber eğitim bittikten sonra ekranda dolaşsın mı (Bölüm D).
  ///
  /// Varsayılan açık: rehber oyunun anlatıcısı ve eğitimden sonra kaybolması
  /// bir kayıp olurdu. Kapatmak isteyen profilden kapatabiliyor — sürekli
  /// görünen bir eşlikçi herkese göre değil.
  bool petCompanionEnabled;

  List<String> ownedTitleIds;

  /// Şu an takılı ünvanın kimliği. `null` = hiçbiri takılı değil.
  ///
  /// **Tek ünvan kuralı veri düzeyinde:** tek bir alan olduğu için iki ünvan
  /// aynı anda takılamaz. Liste tutup "sadece biri aktif" demek, kuralı her
  /// yazma noktasında elle korumak olurdu (aynı gerekçe GD26'da slotlar için
  /// verilmişti).
  String? equippedTitleId;

  // --- Başarım sayaçları (Bölüm C.4) ---
  //
  // Hepsi ömür boyu, hiç sıfırlanmıyor. Envanterden türetilebilenler
  // (eşya sayısı, en yüksek eşya seviyesi) bilerek **sayaç değil**: envanter
  // zaten kalıcı ve ikinci bir sayaç, satış anında düşürülmeyi unutunca
  // ünvanı haksız yere açardı.

  /// Devrilen düşman sayısı.
  int enemiesDefeated;

  /// Adım taahhüdü de dolarak **tamamlanan** macera sayısı.
  int adventuresCompleted;

  /// Çevrilen çark sayısı.
  int wheelSpins;

  /// Demircide birleştirilen eşya sayısı.
  int itemsMerged;

  /// Ömür boyu kazanılan altın. Harcama bunu **düşürmez**.
  int lifetimeCoins;

  UserProfile({
    required this.avatar,
    int? hp,
    int? maxHp,
    this.level = 1,
    this.xp = 0,
    this.coins = 0,
    this.streakDays = 0,
    this.lastActiveDay,
    this.longestStreak = 0,
    this.streakFreezes = 0,
    this.lastFreezeUsedOn,
    this.lastSeenAt,
    this.totalSteps = 0,
    this.lastRewardedStepCount = 0,
    this.lastXpRewardedStepCount = 0,
    this.lastReportedStepCount = 0,
    this.lastSensorReading,
    this.lastStepReportAt,
    List<OwnedItem>? ownedItems,
    List<String>? ownedUpgradeIds,
    this.nextItemInstanceId = 1,
    this.lastWheelSpinAt,
    this.extraWheelSpins = 0,
    this.wheelSeed = 0,
    this.xpBoostUntil,
    this.streakStatBonuses = StreakStatBonuses.empty,
    this.streakBonusSeed = 0,
    this.lastStreakBonusDay,
    this.hasCompletedTutorial = false,
    this.tutorialStep = 0,
    this.tutorialGuideId = 'mavili',
    this.tutorialStarterItemId,
    List<String>? ownedTitleIds,
    this.equippedTitleId,
    this.petCompanionEnabled = true,
    this.enemiesDefeated = 0,
    this.adventuresCompleted = 0,
    this.wheelSpins = 0,
    this.itemsMerged = 0,
    this.lifetimeCoins = 0,
  }) : hp = hp ?? GameConstants.baseHp,
       maxHp = maxHp ?? GameConstants.baseHp,
       ownedItems = ownedItems ?? <OwnedItem>[],
       ownedUpgradeIds = ownedUpgradeIds ?? <String>[],
       ownedTitleIds = ownedTitleIds ?? <String>[];

  String get name => avatar.name;

  /// Bu kimlikten kaç adet var. Mağazadaki "N adet" etiketi buradan geliyor.
  int ownedCountOf(String itemId) {
    var count = 0;
    for (final instance in ownedItems) {
      if (instance.itemId == itemId) count++;
    }
    return count;
  }

  /// Envanterdeki bir örneği kimliğiyle bulur; yoksa `null`.
  OwnedItem? instanceById(int instanceId) {
    for (final instance in ownedItems) {
      if (instance.instanceId == instanceId) return instance;
    }
    return null;
  }

  /// Bu kimlikten en az bir adet var mı.
  bool ownsItem(String itemId) => ownedCountOf(itemId) > 0;

  /// Envantere yeni bir örnek ekler ve eklenen örneği döner.
  ///
  /// Sahiplik kontrolü **yok**: aynı eşya birden fazla kez alınabiliyor
  /// (birleştirme aynı eşyadan birkaç adet istiyor).
  OwnedItem addItem(String itemId, {RewardRarity? rarity, int level = 1}) {
    final instance = OwnedItem(
      instanceId: nextItemInstanceId++,
      itemId: itemId,
      level: level < 1 ? 1 : level,
      rarity: rarity,
    );
    ownedItems.add(instance);
    return instance;
  }

  /// Bir örneği envanterden çıkarır. Çıkarıldıysa o örnek, yoksa `null`.
  OwnedItem? removeInstance(int instanceId) {
    for (var i = 0; i < ownedItems.length; i++) {
      if (ownedItems[i].instanceId == instanceId) {
        return ownedItems.removeAt(i);
      }
    }
    return null;
  }

  /// Bir örneği yerinde günceller. Örnek yoksa hiçbir şey yapmaz.
  void updateInstance(
    int instanceId, {
    int? level,
    RewardRarity? rarity,
    bool? equipped,
  }) {
    for (var i = 0; i < ownedItems.length; i++) {
      if (ownedItems[i].instanceId == instanceId) {
        ownedItems[i] = ownedItems[i].copyWith(
          level: level,
          rarity: rarity,
          equipped: equipped,
        );
        return;
      }
    }
  }

  /// Kuşanılı örnekler.
  List<OwnedItem> get equippedInstances => [
    for (final instance in ownedItems)
      if (instance.equipped) instance,
  ];

  /// Bütün örneklerin kuşanmasını kaldırır — çağıran taraf hangilerinin
  /// yeniden kuşanılacağına karar verir (`RootShell._refreshEquipment`).
  void unequipAll() {
    for (var i = 0; i < ownedItems.length; i++) {
      if (ownedItems[i].equipped) {
        ownedItems[i] = ownedItems[i].copyWith(equipped: false);
      }
    }
  }

  /// Günlük çark bu oyun gününde çevrildi mi? Gün sınırı [GameDay],
  /// şimdiki zaman [GameClock] üzerinden gelir; ayrı bir gün ya da saat
  /// hesabı yapılmaz.
  bool get wheelSpunToday {
    final lastSpin = lastWheelSpinAt;
    return lastSpin != null && GameDay.isSameGameDay(lastSpin, GameClock.now());
  }

  /// Çark şu an çevrilebilir mi: ya günlük hak duruyordur ya da elde ekstra
  /// jeton vardır.
  bool get canSpinWheel => !wheelSpunToday || extraWheelSpins > 0;

  /// Çark çevrildi. Günlük hak duruyorsa o kullanılır; kullanılmışsa bir
  /// ekstra jeton düşer. Hiç hak yoksa hiçbir şey yapmaz ve `false` döner.
  bool consumeWheelSpin(DateTime now) {
    if (!wheelSpunToday) {
      lastWheelSpinAt = now;
      return true;
    }
    if (extraWheelSpins <= 0) return false;
    extraWheelSpins--;
    return true;
  }

  /// Ekstra çark hakkı verir; stok tavanına ([GameConstants.maxExtraWheelSpins])
  /// takılırsa **verilen kadarını** döner. Sıfır dönmesi "stok dolu" demektir
  /// ve çağıran para harcamamalıdır — [grantStreakFreeze] ile aynı sözleşme.
  int grantExtraWheelSpin([int amount = 1, int? cap]) {
    if (amount <= 0) return 0;
    final limit = cap ?? GameConstants.maxExtraWheelSpins;
    final granted =
        (extraWheelSpins + amount).clamp(0, limit) - extraWheelSpins;
    if (granted <= 0) return 0;
    extraWheelSpins += granted;
    return granted;
  }

  /// "2x XP" yükseltmesi şu an etkin mi.
  bool get isXpBoostActive {
    final until = xpBoostUntil;
    return until != null && GameClock.now().toUtc().isBefore(until);
  }

  /// "2x XP" yükseltmesini bu oyun gününün sonuna kadar etkinleştirir.
  /// Zaten etkinse hiçbir şey yapmaz ve `false` döner — çağıran para
  /// harcamamalıdır.
  bool activateXpBoost(DateTime now) {
    if (isXpBoostActive) return false;
    xpBoostUntil = GameDay.nextResetAfter(now).toUtc();
    return true;
  }

  /// Serinin bu oyun gününde tamamlanıp tamamlanmadığı.
  bool streakCompletedOn(DateTime now) {
    final last = lastActiveDay;
    return last != null && GameDay.isSameGameDay(last, now);
  }

  /// Gün atlanmışsa seriyi sıfırlar. Aktivite gerektirmez; gün döngüsü
  /// kontrolünde çağrılır.
  ///
  /// Üç sonuçtan biri döner; bool yetmiyor çünkü "gün atlandı ama dondurma
  /// hakkıyla kurtarıldı" ayrı bir durum ve kullanıcıya söylenmesi gerekiyor.
  ///
  /// [lastActiveDay] bilerek silinmez: bir sonraki [registerStreakDay]
  /// aradaki boşluğu buradan görüp seriyi 1'den başlatır.
  StreakDayOutcome refreshStreak(DateTime now) {
    final last = lastActiveDay;
    if (last == null || streakDays == 0) return StreakDayOutcome.unchanged;
    final gap = GameDay.daysBetween(last, now);
    // gap 0 = bugün tamamlandı, 1 = dün tamamlandı (seri hâlâ ayakta),
    // negatif = saat geriye alınmış (dokunma).
    if (gap < 2) return StreakDayOutcome.unchanged;
    if (_bridgeWithFreeze(gap)) return StreakDayOutcome.frozen;
    streakDays = 0;
    // Seri kırılınca biriken savaş bonusu da gider. Bilerek: seriyi değerli
    // kılan ve dondurma hakkının fiyatını haklı çıkaran şey bu.
    resetStreakStatBonuses();
    return StreakDayOutcome.broken;
  }

  /// Kaçırılan **tek** günü bir dondurma hakkıyla köprüler.
  ///
  /// Harcandıysa `true` döner. Seri korunur ama **artmaz**: jeton kaçırılan
  /// günün yerine geçer, o gün yürünmüş sayılmaz.
  ///
  /// Üç sınır:
  /// - Yalnızca `gap == 2`, yani tam bir gün kaçırıldıysa. İki gün üst üste
  ///   kaçıran, stokta iki jeton olsa bile serisini kaybeder.
  /// - Stok bitmişse çalışmaz.
  /// - Son aktif gün zaten bir dondurma ile kapatılmışsa çalışmaz —
  ///   "art arda en fazla 1 gün korunur" kuralı bu dala dayanıyor.
  ///
  /// **Otomatik ve geriye dönük** olması bilinçli: manuel bir kurtarma
  /// penceresi koyulsaydı, o pencereyi kaçıran kullanıcı iki kez cezalanırdı.
  /// Serinin amacı alışkanlık, ceza değil.
  bool _bridgeWithFreeze(int gap) {
    if (gap != 2 || streakFreezes <= 0) return false;
    final last = lastActiveDay;
    if (last == null) return false;

    final lastFreeze = lastFreezeUsedOn;
    if (lastFreeze != null && GameDay.isSameGameDay(lastFreeze, last)) {
      return false;
    }

    // Köprülenen gün: son aktif günden sonraki oyun günü.
    final bridged = GameDay.nextResetAfter(last);
    streakFreezes--;
    lastFreezeUsedOn = bridged;
    lastActiveDay = bridged;
    return true;
  }

  /// Dondurma hakkı verir; stok [GameConstants.maxStreakFreezes] ile sınırlı.
  /// Gerçekten eklenen jeton sayısını döner (stok doluysa 0).
  // Kazanım yolları (Aşama 3'te bağlandı): seri kilometre taşları
  // (`RootShell._onStepsReported`) ve mağazadaki "Seri Dondurma Hakkı"
  // yükseltmesi (`RootShell._purchase`). İkisi de buradan geçer; ikinci bir
  // stok mantığı yazılmamalı.
  ///
  /// [cap] kuşanılan itemlerin büyüttüğü stok tavanıdır
  /// ([EquippedBuffs.streakFreezeCap]); verilmezse taban değer kullanılır.
  int grantStreakFreeze([int amount = 1, int? cap]) {
    if (amount <= 0) return 0;
    final limit = cap ?? GameConstants.maxStreakFreezes;
    final granted = (streakFreezes + amount).clamp(0, limit) - streakFreezes;
    if (granted <= 0) return 0;
    streakFreezes += granted;
    return granted;
  }

  /// Günün seri koşulu sağlandığında çağrılır. Aynı oyun gününde ikinci kez
  /// çağrılırsa hiçbir şey yapmaz. Seri ilerlediyse `true` döner.
  bool registerStreakDay(DateTime now) {
    final last = lastActiveDay;
    if (last == null) {
      _startStreakDay(now, 1);
      return true;
    }
    if (GameDay.isSameGameDay(last, now)) return false;

    final gap = GameDay.daysBetween(last, now);
    if (gap < 0) return false; // saat geriye alınmış; seriyi ilerletme.

    // Kaçırılan tek gün dondurma hakkıyla köprülenebiliyorsa seri kırılmaz.
    // Köprü kurulunca boşluk 1 güne indiği için bugünün aktivitesi seriyi
    // normal şekilde ilerletir. Aynı mantığın iki kopyası olmasın diye
    // [refreshStreak] de aynı yardımcıyı kullanıyor.
    if (_bridgeWithFreeze(gap)) {
      _startStreakDay(now, streakDays + 1);
      return true;
    }

    // gap 1 = dün de yürünmüş, seri devam ediyor; daha büyükse baştan başlar.
    _startStreakDay(now, gap == 1 ? streakDays + 1 : 1);
    return true;
  }

  void _startStreakDay(DateTime now, int days) {
    // Seri 1'e dönüyorsa (yeni seri ya da kırılmanın ardından yeniden
    // başlama) biriken savaş bonusu da sıfırlanır. Köprülenen gün buraya
    // `streakDays + 1` ile geldiği için jeton birikimi korur.
    if (days <= 1) resetStreakStatBonuses();
    streakDays = days;
    lastActiveDay = now;
    if (streakDays > longestStreak) longestStreak = streakDays;
  }

  // --- Ünvanlar (Bölüm C) ---

  /// Bu ünvana sahip mi.
  bool ownsTitle(String id) => ownedTitleIds.contains(id);

  /// Ünvanı envantere ekler; **yeni** kazanıldıysa `true` döner.
  ///
  /// İkinci kez kazanmak sessizce yutulur: aynı ünvan hem çarktan hem
  /// başarımdan gelebilirdi ve mükerrer bildirim gürültü olurdu.
  bool grantTitle(String id) {
    if (ownedTitleIds.contains(id)) return false;
    ownedTitleIds.add(id);
    return true;
  }

  /// Ünvanı takar. Sahip olunmayan ünvan takılamaz.
  ///
  /// [id] `null` ise takılı ünvan çıkarılır. Tek ünvan kuralı burada değil,
  /// **alanın kendisinde**: [equippedTitleId] tek bir değer tutuyor.
  bool equipTitle(String? id) {
    if (id != null && !ownedTitleIds.contains(id)) return false;
    if (equippedTitleId == id) return false;
    equippedTitleId = id;
    return true;
  }

  /// Sahip olunmayan ya da katalogda karşılığı kalmamış takılı ünvanı düşürür.
  ///
  /// Sahipliğe **dokunmaz** — GD28'in kuşanma temizliğiyle aynı kural:
  /// çözülemeyen bir takı yalnızca slotu boşaltır, envanteri değil.
  bool normalizeEquippedTitle(bool Function(String id) exists) {
    final current = equippedTitleId;
    if (current == null) return false;
    if (ownedTitleIds.contains(current) && exists(current)) return false;
    equippedTitleId = null;
    return true;
  }

  // --- Seri savaş stat bonusu (Bölüm 5C) ---

  /// Biriken bonusu ve gün işaretini temizler.
  ///
  /// Tohum **sıfırlanmaz**: oyuncuya özel kalması gerekiyor ve serinin
  /// kırılması yeni bir kimlik anlamına gelmiyor. Tohumu da sıfırlamak,
  /// her kırılıştan sonra aynı stat dizisini tekrarlatırdı.
  void resetStreakStatBonuses() {
    streakStatBonuses = StreakStatBonuses.empty;
    lastStreakBonusDay = null;
  }

  /// Bu oyun gününün seri stat bonusunu verir; çekilişin sonucunu döner.
  ///
  /// `null` dönerse bonus verilmedi: aynı gün zaten verilmiş. Aynı gün ikinci
  /// çağrı **her zaman** `null` döner — uygulamayı kapatıp açmak yeni bir zar
  /// attırmaz.
  ///
  /// Kazancın büyüklüğü [streakDays]'e bağlı: basamak tablosu her 100 günde
  /// bir azalır, 500'ün ardından başa döner (Bölüm B). Tavan yok.
  ///
  /// [registerStreakDay]'den **sonra** çağrılmalı: hem seri o gün
  /// ilerlemediyse bonus verilmemeli, hem de basamak güncel gün sayısından
  /// okunuyor.
  StreakBonusDraw? grantStreakStatBonus(DateTime now) {
    final last = lastStreakBonusDay;
    if (last != null && GameDay.isSameGameDay(last, now)) return null;

    if (streakBonusSeed == 0) {
      streakBonusSeed = initialStreakSeed(
        '${avatar.name}|${avatar.characterClass}',
      );
    }
    final draw = drawStreakStatBonus(
      current: streakStatBonuses,
      seed: streakBonusSeed,
      streakDay: streakDays,
    );
    // Çekiliş sonuçsuz kalsa bile gün işaretlenir: aynı gün tekrar tekrar
    // denemenin bir anlamı yok.
    lastStreakBonusDay = now;
    if (draw == null) return null;
    streakStatBonuses = draw.bonuses;
    streakBonusSeed = draw.nextSeed;
    return draw;
  }

  /// Serinin şu anda denk geldiği kilometre taşı (yoksa null).
  ///
  /// Ödül üretimi bilinçli olarak buraya bağlanmadı: ödül altyapısı
  /// Aşama 3d/4b'de kurulacak (bkz. CLAUDE.md, kart #14). Burası yalnızca
  /// "hangi kilometre taşına ulaşıldı" bilgisini verir.
  int? get reachedStreakMilestone =>
      GameConstants.streakMilestones.contains(streakDays) ? streakDays : null;

  /// Bir sonraki kilometre taşı (hepsi geçildiyse null).
  int? get nextStreakMilestone {
    for (final milestone in GameConstants.streakMilestones) {
      if (streakDays < milestone) return milestone;
    }
    return null;
  }

  /// Bir sonraki seviyeye geçmek için gereken toplam XP.
  int get xpToNextLevel => GameConstants.baseXpPerLevel * level;

  double get xpProgress => (xp / xpToNextLevel).clamp(0, 1);

  double get hpProgress => (hp / maxHp).clamp(0, 1);

  /// XP ekler, gerekiyorsa seviye atlatır. Kaç seviye atlandığını döner.
  int addXp(int amount) {
    xp += amount;
    var levelsGained = 0;
    while (xp >= xpToNextLevel) {
      xp -= xpToNextLevel;
      level++;
      levelsGained++;
    }
    return levelsGained;
  }

  /// Avatar bilgisi ayrıca [CharacterStorage] tarafından saklandığı için
  /// burada tekrar yazılmaz; okurken dışarıdan verilir.
  ///
  /// [hp] / [maxHp] bilinçli olarak yazılmaz: bu alanları azaltan hiçbir kod
  /// yok, yani kalıcılaştırılırsa her kayda sabit 5000/5000 gider. Savaş canı
  /// şu an [AdventureQuest.playerHealth] üzerinde tutuluyor. İki can kavramı
  /// Aşama 4a'da birleştirilecek; birleşene kadar hiçbiri buradan yazılmaz.
  Map<String, Object?> toJson() => {
    'level': level,
    'xp': xp,
    'coins': coins,
    'streakDays': streakDays,
    'lastActiveDay': lastActiveDay?.toIso8601String(),
    'longestStreak': longestStreak,
    'streakFreezes': streakFreezes,
    'lastFreezeUsedOn': lastFreezeUsedOn?.toIso8601String(),
    'lastSeenAt': lastSeenAt?.toUtc().toIso8601String(),
    'totalSteps': totalSteps,
    'lastRewardedStepCount': lastRewardedStepCount,
    'lastXpRewardedStepCount': lastXpRewardedStepCount,
    'lastReportedStepCount': lastReportedStepCount,
    'lastSensorReading': lastSensorReading,
    'lastStepReportAt': lastStepReportAt?.toUtc().toIso8601String(),
    'ownedItems': [for (final instance in ownedItems) instance.toJson()],
    'ownedUpgradeIds': ownedUpgradeIds,
    'nextItemInstanceId': nextItemInstanceId,
    'lastWheelSpinAt': lastWheelSpinAt?.toIso8601String(),
    'extraWheelSpins': extraWheelSpins,
    'wheelSeed': wheelSeed,
    'xpBoostUntil': xpBoostUntil?.toUtc().toIso8601String(),
    'streakStatBonuses': streakStatBonuses.toJson(),
    'streakBonusSeed': streakBonusSeed,
    'lastStreakBonusDay': lastStreakBonusDay?.toIso8601String(),
    'hasCompletedTutorial': hasCompletedTutorial,
    'tutorialStep': tutorialStep,
    'tutorialGuideId': tutorialGuideId,
    'tutorialStarterItemId': tutorialStarterItemId,
    'ownedTitleIds': ownedTitleIds,
    'equippedTitleId': equippedTitleId,
    'petCompanionEnabled': petCompanionEnabled,
    'enemiesDefeated': enemiesDefeated,
    'adventuresCompleted': adventuresCompleted,
    'wheelSpins': wheelSpins,
    'itemsMerged': itemsMerged,
    'lifetimeCoins': lifetimeCoins,
  };

  /// Eksik alanlar varsayılana düşer; böylece eski kayıtlar okunabilir kalır.
  factory UserProfile.fromJson(
    Map<String, dynamic> json, {
    required AvatarProfile avatar,
  }) {
    return UserProfile(
      avatar: avatar,
      level: json['level'] as int? ?? 1,
      xp: json['xp'] as int? ?? 0,
      coins: json['coins'] as int? ?? 0,
      streakDays: json['streakDays'] as int? ?? 0,
      lastActiveDay: _parseDate(json['lastActiveDay']),
      longestStreak: json['longestStreak'] as int? ?? 0,
      // Stok savunma amaçlı kırpılır: bozuk ya da elle düzenlenmiş bir kayıt
      // sınırsız jeton getirmemeli.
      // Kırpma **buff'lı** tavana göre: kuşanılan bir item stoğu büyütmüş
      // olabilir ve o jetonlar okurken sessizce yakılmamalı. Yine de üst
      // sınır var; elle düzenlenmiş kayıt sınırsız jeton getiremez.
      streakFreezes: (json['streakFreezes'] as int? ?? 0).clamp(
        0,
        GameConstants.maxStreakFreezes + GameConstants.maxEquippedStockBonus,
      ),
      lastFreezeUsedOn: _parseDate(json['lastFreezeUsedOn']),
      lastSeenAt: _parseDate(json['lastSeenAt']),
      totalSteps: json['totalSteps'] as int? ?? 0,
      lastRewardedStepCount: json['lastRewardedStepCount'] as int? ?? 0,
      lastXpRewardedStepCount: json['lastXpRewardedStepCount'] as int? ?? 0,
      lastReportedStepCount: json['lastReportedStepCount'] as int? ?? 0,
      lastSensorReading: json['lastSensorReading'] as int?,
      lastStepReportAt: _parseDate(json['lastStepReportAt']),
      ownedItems: _parseOwnedItems(json['ownedItems']),
      ownedUpgradeIds:
          (json['ownedUpgradeIds'] as List?)?.whereType<String>().toList() ??
          <String>[],
      nextItemInstanceId: _parseNextInstanceId(json),
      lastWheelSpinAt: _parseDate(json['lastWheelSpinAt']),
      // Dondurma stoğuyla aynı savunma: elle düzenlenmiş kayıt sınırsız
      // ekstra çark hakkı getirmemeli.
      extraWheelSpins: (json['extraWheelSpins'] as int? ?? 0).clamp(
        0,
        GameConstants.maxExtraWheelSpins + GameConstants.maxEquippedStockBonus,
      ),
      wheelSeed: json['wheelSeed'] as int? ?? 0,
      // Bozuk/elle düzenlenmiş kayıt: bilinmeyen stat adları ve tavan üstü
      // günler [StreakStatBonuses] içinde sessizce kırpılır.
      streakStatBonuses: StreakStatBonuses.fromJson(json['streakStatBonuses']),
      streakBonusSeed: json['streakBonusSeed'] as int? ?? 0,
      lastStreakBonusDay: _parseDate(json['lastStreakBonusDay']),
      xpBoostUntil: _parseDate(json['xpBoostUntil']),
      // Alanın eksik olması eski bir kaydı gösterir; mevcut oyunculara tutorialı
      // zorla yeniden oynatmayız. Yeni profiller constructor varsayılanıyla false.
      hasCompletedTutorial: json['hasCompletedTutorial'] as bool? ?? true,
      tutorialStep: switch (json['tutorialStep']) {
        final int value when value >= 0 => value,
        _ => 0,
      },
      tutorialGuideId: json['tutorialGuideId'] as String? ?? 'mavili',
      tutorialStarterItemId: json['tutorialStarterItemId'] as String?,
      ownedTitleIds: _stringList(json['ownedTitleIds']),
      // Katalogda karşılığı olmayan ya da sahip olunmayan bir kimlik takılı
      // gelirse sessizce düşer: elle düzenlenmiş kayıt bilinmeyen bir ünvanın
      // buff'ını uygulayamaz.
      equippedTitleId: json['equippedTitleId'] as String?,
      petCompanionEnabled: json['petCompanionEnabled'] as bool? ?? true,
      enemiesDefeated: _nonNegative(json['enemiesDefeated']),
      adventuresCompleted: _nonNegative(json['adventuresCompleted']),
      wheelSpins: _nonNegative(json['wheelSpins']),
      itemsMerged: _nonNegative(json['itemsMerged']),
      lifetimeCoins: _nonNegative(json['lifetimeCoins']),
    );
  }

  /// Envanteri okur. Bozuk satırlar **sessizce atılır**; tek bozuk kayıt
  /// yüzünden bütün envanter kaybolmasın.
  ///
  /// Çakışan `instanceId` değerleri de eleniyor: elle düzenlenmiş bir kayıt
  /// iki örneğe aynı kimliği verirse "hangisini yükselt" sorusu cevapsız
  /// kalırdı.
  static List<OwnedItem> _parseOwnedItems(Object? value) {
    if (value is! List) return <OwnedItem>[];
    final seen = <int>{};
    final result = <OwnedItem>[];
    for (final row in value) {
      final instance = OwnedItem.fromJson(row);
      if (instance == null) continue;
      if (!seen.add(instance.instanceId)) continue;
      result.add(instance);
    }
    return result;
  }

  /// Sayaç, kayıttaki en büyük örnek kimliğinin **altına düşemez**: düşerse
  /// bir sonraki satın alma var olan bir örneğin kimliğini yeniden kullanır.
  static int _parseNextInstanceId(Map<String, dynamic> json) {
    final stored = json['nextItemInstanceId'];
    var next = stored is int && stored > 0 ? stored : 1;
    final items = json['ownedItems'];
    if (items is List) {
      for (final row in items) {
        if (row is Map) {
          final id = row['instanceId'];
          if (id is int && id >= next) next = id + 1;
        }
      }
    }
    return next;
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }

  /// Bozuk ya da eksik listeyi boş listeye düşürür; `String` olmayan
  /// elemanları atar (elle düzenlenmiş kayda karşı savunma).
  static List<String> _stringList(Object? value) =>
      (value as List?)?.whereType<String>().toList() ?? <String>[];

  /// Eksi ya da sayı olmayan sayacı sıfıra düşürür. Başarım sayaçları geriye
  /// gitmemeli: eksi bir sayaç ünvanı kalıcı olarak kilitleyebilirdi.
  static int _nonNegative(Object? value) {
    if (value is! int || value < 0) return 0;
    return value;
  }
}
