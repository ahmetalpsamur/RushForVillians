import '../core/constants/game_constants.dart';
import '../core/utils/game_clock.dart';
import '../core/utils/game_day.dart';
import 'avatar_profile.dart';

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
  /// paylaşsaydı, günlük para tavanı dolduğunda o işaretçi bekleyen tüm
  /// adımları tükettiği için XP de dururdu. İki ekonominin oranı, tavanı ve
  /// artık-adım davranışı farklı.
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

  /// Mağazadan satın alınmış öğelerin kimlikleri. Item sistemi gelene kadar
  /// yalnızca sahiplik kaydı tutar.
  final List<String> ownedItemIds;

  /// Günlük çarkın en son çevrildiği an. Gün başına tek hak kontrolü ve
  /// kalıcılık için kullanılır.
  DateTime? lastWheelSpinAt;

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
    List<String>? ownedItemIds,
    this.lastWheelSpinAt,
  }) : hp = hp ?? GameConstants.baseHp,
       maxHp = maxHp ?? GameConstants.baseHp,
       ownedItemIds = ownedItemIds ?? <String>[];

  String get name => avatar.name;

  /// Günlük çark bu oyun gününde çevrildi mi? Gün sınırı [GameDay],
  /// şimdiki zaman [GameClock] üzerinden gelir; ayrı bir gün ya da saat
  /// hesabı yapılmaz.
  bool get wheelSpunToday {
    final lastSpin = lastWheelSpinAt;
    return lastSpin != null && GameDay.isSameGameDay(lastSpin, GameClock.now());
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
  int grantStreakFreeze([int amount = 1]) {
    if (amount <= 0) return 0;
    final granted =
        (streakFreezes + amount).clamp(0, GameConstants.maxStreakFreezes) -
        streakFreezes;
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
    streakDays = days;
    lastActiveDay = now;
    if (streakDays > longestStreak) longestStreak = streakDays;
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
    'ownedItemIds': ownedItemIds,
    'lastWheelSpinAt': lastWheelSpinAt?.toIso8601String(),
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
      streakFreezes: (json['streakFreezes'] as int? ?? 0).clamp(
        0,
        GameConstants.maxStreakFreezes,
      ),
      lastFreezeUsedOn: _parseDate(json['lastFreezeUsedOn']),
      lastSeenAt: _parseDate(json['lastSeenAt']),
      totalSteps: json['totalSteps'] as int? ?? 0,
      lastRewardedStepCount: json['lastRewardedStepCount'] as int? ?? 0,
      lastXpRewardedStepCount: json['lastXpRewardedStepCount'] as int? ?? 0,
      lastReportedStepCount: json['lastReportedStepCount'] as int? ?? 0,
      lastSensorReading: json['lastSensorReading'] as int?,
      lastStepReportAt: _parseDate(json['lastStepReportAt']),
      ownedItemIds:
          (json['ownedItemIds'] as List?)?.whereType<String>().toList() ??
          <String>[],
      lastWheelSpinAt: _parseDate(json['lastWheelSpinAt']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }
}
