// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Rush for Villains';

  @override
  String get language => 'Dil';

  @override
  String get languageDescription =>
      'Uygulamanın dilini seç. Değişiklik hemen uygulanır.';

  @override
  String get languageSystem => 'Sistem';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageEnglish => 'İngilizce';

  @override
  String get fallbackSafetyMessage => 'Türkçe yedek metin';

  @override
  String get commonClose => 'Kapat';

  @override
  String get scrollToTop => 'Başa dön';

  @override
  String get tavernTitle => 'Taverna';

  @override
  String get tavernComingSoon => 'Taverna daha açılmadı';

  @override
  String get tavernPreview => 'Aşağıdaki takım şimdilik bir önizleme.';

  @override
  String get teamWalkingBonusActive =>
      'Takım şu anda yan yana yürüyor! Bonus XP aktif.';

  @override
  String get teamWalkingBonusRequirement =>
      'Bonus için tüm üyelerin aynı anda yürümesi gerekir.';

  @override
  String teamTotalSteps(int count) {
    return 'Toplam Takım Adımı: $count';
  }

  @override
  String stepCount(int count) {
    return '$count adım';
  }

  @override
  String get chooseCompanionEyebrow => 'YOL ARKADAŞINI SEÇ';

  @override
  String get chooseCompanionTitle => 'İlk maceranda yanında kim yürüsün?';

  @override
  String get chooseCompanionDescription =>
      'Seçtiğin yol arkadaşı eğitim boyunca seni yönlendirecek.';

  @override
  String get chooseMyCompanion => 'Yol Arkadaşımı Seç';

  @override
  String get stepsRingLabel => 'ADIM';

  @override
  String stepsTaken(int count) {
    return '$count adım attın';
  }

  @override
  String dailyGoalSteps(int count) {
    return 'Günlük hedef: $count adım';
  }

  @override
  String completedRounds(int count) {
    return '$count tur';
  }

  @override
  String roundBadge(int count) {
    return '$count TUR';
  }

  @override
  String get combatHealth => 'Savaş Canı';

  @override
  String levelNumber(int level) {
    return 'Seviye $level';
  }

  @override
  String stepProgress(int steps, int goal, String distance) {
    return '$steps / $goal adım ($distance km)';
  }

  @override
  String get dismissPet => 'Peti kapat';

  @override
  String get summonPet => 'Peti çağır';

  @override
  String dayCount(int count) {
    return '$count gün';
  }

  @override
  String helloPlayer(String name) {
    return 'Merhaba, $name';
  }

  @override
  String get adventure => 'Macera';

  @override
  String get adventureStartPrompt =>
      'Günlük hedefini ve düşmanını seçerek maceraya başla.';

  @override
  String enemyWaiting(String name) {
    return '$name seni bekliyor. Ritmini koru!';
  }

  @override
  String get monsterHealth => 'Canavar Canı';

  @override
  String get dailyWheel => 'Günlük Çark';

  @override
  String wheelUnlockRequirement(int goal, int remaining) {
    return 'Günlük çarkı açmak için bugün bir düşmanı yen ya da $goal adım at. Zaferden sonra bonus yürüyüşü bitirmen gerekmez. $remaining adım kaldı.';
  }

  @override
  String get newWheelPrefix => 'Yeni çark: ';

  @override
  String get myRewards => 'Ödüllerim';

  @override
  String get store => 'Mağaza';

  @override
  String get inventory => 'Envanter';

  @override
  String get stepCounter => 'Adım Sayacı';

  @override
  String get openSettings => 'Ayarları Aç';

  @override
  String get permissionUnknown => 'Adım sayacı izni henüz kontrol edilmedi.';

  @override
  String get permissionGranted => 'Adım sayacı çalışıyor.';

  @override
  String get permissionDenied =>
      'Adımlarını sayabilmemiz için hareket verisi iznine ihtiyacımız var. İzin vermeden oyunun geri kalanı çalışmaya devam eder, ama adımların kaydedilmez.';

  @override
  String get permissionPermanentlyDenied =>
      'Hareket verisi izni kapalı. Adımların sayılabilmesi için sistem ayarlarından “Fiziksel aktivite” iznini açman gerekiyor.';

  @override
  String get permissionUnavailable =>
      'Bu cihazda adım sayacı bulunamadı. Oyunun geri kalanı çalışır; adımları demo kontrollerinden simüle edebilirsin.';

  @override
  String get stepSource => 'Adım Kaynağı';

  @override
  String get realPedometer => 'Pedometer (gerçek sensör)';

  @override
  String get manualStepSource => 'Manuel (demo kontrolleri)';

  @override
  String get realPedometerDescription =>
      'Adımlar cihazın sensöründen geliyor. Demo butonları kapalı; açmak için kaynağı manuele al.';

  @override
  String get manualStepSourceDescription =>
      'Adımları buradan simüle edebilirsin.';

  @override
  String coinsEarnedToday(int count) {
    return 'Bugün adımlarından $count coin kazandın.';
  }

  @override
  String xpEarnedToday(int count) {
    return 'Bugün adımlarından $count XP kazandın.';
  }

  @override
  String stepsPerReward(int count) {
    return '$count adım = 1';
  }

  @override
  String get dailyStreak => 'Günlük Seri';

  @override
  String get completedToday => 'Bugün tamamlandı';

  @override
  String get pendingToday => 'Bugün bekliyor';

  @override
  String streakContinueTomorrow(int count) {
    return 'Seri sürüyor. Yarın bir düşman devir ya da $count adım at.';
  }

  @override
  String secureStreak(int count) {
    return 'Seriyi güvenceye almak için bir düşman devir — ya da $count adım daha at.';
  }

  @override
  String nextMilestone(int milestone, int remaining) {
    return 'Sonraki kilometre taşı: $milestone gün ($remaining gün kaldı)';
  }

  @override
  String streakBonusSummary(String rate) {
    return 'Seri bonusu: +%$rate savaş statı (profilde stat stat görülür).';
  }

  @override
  String streakFreezeSummary(int count) {
    return '$count dondurma hakkın var. Bir gün kaçırırsan otomatik kullanılır.';
  }

  @override
  String streakEndingSoon(String remaining) {
    return 'Gün bitmesine $remaining kaldı, serini kaybetme!';
  }

  @override
  String streakEndingSoonWithBonus(String remaining, String rate) {
    return 'Gün bitmesine $remaining kaldı, serini kaybetme! Biriken +%$rate savaş bonusun gider.';
  }

  @override
  String simulateSteps(int count) {
    return '+$count adım';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours sa $minutes dk';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes dk';
  }

  @override
  String get profile => 'Profil';

  @override
  String profileDetails(int age, int weight, String gender) {
    return '$age yaş • $weight kg • $gender';
  }

  @override
  String get useReincarnationPotion => 'Reenkarnasyon İksirini Kullan';

  @override
  String get reincarnationPotionRequired => 'Reenkarnasyon İksiri Gerekli';

  @override
  String get equipment => 'Ekipman';

  @override
  String get nothingEquipped => 'Hiçbir şey kuşanmadın.';

  @override
  String equippedItemsSummary(int count, String names) {
    return '$count item kuşanılı: $names';
  }

  @override
  String get openInventory => 'Envanteri Aç';

  @override
  String get titles => 'Ünvanlar';

  @override
  String earnedTitlesPrompt(int count) {
    return '$count ünvan kazandın. Birini tak, adının yanında görünsün.';
  }

  @override
  String equippedTitleSummary(String name, int count) {
    return 'Takılı: $name · $count ünvan kazandın.';
  }

  @override
  String get blacksmith => 'Demirci';

  @override
  String get blacksmithProfileDescription =>
      'Silahlarını birleştir, gücüne güç kat.';

  @override
  String get lastThreeDays => 'Son 3 Gün';

  @override
  String get viewAllStepRings => 'Bütün adım halkalarını gör';

  @override
  String get statistics => 'İstatistikler';

  @override
  String get combatHealthAdventureOnly =>
      'Savaş canı yalnızca macera sırasında takip edilir.';

  @override
  String get dailyStreakProfile => 'Günlük Streak';

  @override
  String longestStreak(int count) {
    return 'En uzun seri: $count gün';
  }

  @override
  String get coin => 'Coin';

  @override
  String get stepRings => 'Adım Halkaları';

  @override
  String get buffStepCoins => 'adım parası';

  @override
  String get buffStepXp => 'adım XP';

  @override
  String get buffWheelXp => 'çark XP';

  @override
  String get buffEnemyXp => 'düşman XP';

  @override
  String buffFreezeStock(int count) {
    return 'dondurma stoğu +$count';
  }

  @override
  String buffWheelStock(int count) {
    return 'çark stoğu +$count';
  }

  @override
  String buffStreakThreshold(int count) {
    return 'seri eşiği -$count';
  }

  @override
  String buffRate(String label, int rate) {
    return '$label +%$rate';
  }

  @override
  String get wheelAlreadySpun => 'Bugün çarkı zaten çevirdin.';

  @override
  String get wheelResetCountdownPrefix => 'Yeni çark hakkına kalan süre: ';

  @override
  String get gearsSpinning => 'Dişliler dönüyor...';

  @override
  String get spinWheel => 'Çarkı Çevir';

  @override
  String extraSpinNotice(int count) {
    return 'Bu çevirme ekstra hakkından düşecek ($count hak kaldı).';
  }

  @override
  String get titleWon => 'Ünvan kazandın! 🎉';

  @override
  String get equipTitleFromProfile =>
      'Profildeki Ünvanlar ekranından takabilirsin.';

  @override
  String coinsWon(int count) {
    return 'Kazandın: $count altın 🎉';
  }

  @override
  String rewardWon(String reward) {
    return 'Kazandın: $reward 🎉';
  }

  @override
  String get equipmentWon => 'Ekipman kazandın! 🎉';

  @override
  String rewardTier(String rarity) {
    return '$rarity ÖDÜL';
  }

  @override
  String titleTier(String rarity) {
    return '$rarity ÜNVAN';
  }

  @override
  String get goldWonHeader => 'ALTIN KAZANDIN';

  @override
  String get xpWonHeader => 'XP KAZANDIN';

  @override
  String get rewardAddedToInventory => 'Ödül envanterine işlendi';

  @override
  String get chanceMechanismRunning => 'ŞANS MEKANİZMASI ÇALIŞIYOR';

  @override
  String get wakeTheGears => 'DİŞLİLERİ UYANDIR';

  @override
  String get equippedTitle => 'Takılı ünvan';

  @override
  String get noEquippedTitle =>
      'Şu an takılı ünvanın yok. Bir ünvan tak; adının yanında görünsün ve etkisi açılsın.';

  @override
  String get unequipTitle => 'ÜNVANI ÇIKAR';

  @override
  String get singleTitleExplanation =>
      'Aynı anda yalnızca bir ünvan takılır: ünvan bir kimlik, bir liste değil. Diğerleri sende kalır, istediğin zaman değiştirebilirsin.';

  @override
  String get noTitlesForFilters => 'Bu süzgeçle gösterilecek ünvan yok.';

  @override
  String get clearFilters => 'SÜZGEÇLERİ TEMİZLE';

  @override
  String get clear => 'TEMİZLE';

  @override
  String titlesEarnedProgress(int owned, int total) {
    return '$owned / $total ünvan kazanıldı';
  }

  @override
  String get titleSearchHint => 'Ünvan, hikâye ya da etki ara…';

  @override
  String get filterAll => 'Tümü';

  @override
  String get filterOwned => 'Sende';

  @override
  String get filterLocked => 'Kilitli';

  @override
  String get anyRarity => 'Her nadirlik';

  @override
  String get anySource => 'Her yol';

  @override
  String get sourceAchievement => 'Başarım';

  @override
  String get sourceStore => 'Mağaza';

  @override
  String get sourceWheel => 'Çark';

  @override
  String get sourceMilestone => 'Kilometre taşı';

  @override
  String get sortDefault => 'Varsayılan';

  @override
  String get sortRarity => 'Nadirlik';

  @override
  String get sortNearlyThere => 'Az kaldı';

  @override
  String get sortName => 'A→Z';

  @override
  String titlesShown(int count) {
    return '$count ünvan listede';
  }

  @override
  String get equippedBadge => 'TAKILI';

  @override
  String completionPercent(int percent) {
    return '%$percent tamamlandı';
  }

  @override
  String get equipAction => 'TAK';

  @override
  String showcasePinLimit(int count) {
    return 'Vitrine en fazla $count ödül sabitlenebilir.';
  }

  @override
  String get allRewards => 'Tüm Ödüller';

  @override
  String get showcase => 'Vitrin';

  @override
  String get noRewardsForFilters => 'Bu filtrelerle eşleşen ödül yok.';

  @override
  String get rewardSearchHint => 'Ödül veya kazanma şartı ara';

  @override
  String get clearSearch => 'Aramayı temizle';

  @override
  String get category => 'Kategori';

  @override
  String get rarity => 'Nadirlik';

  @override
  String get filterEarned => 'Kazanılan';

  @override
  String get noRewardsYet =>
      'Henüz ödül kazanmadın. İlk düşmanını yenerek veya yürüyüş hedefini tamamlayarak koleksiyonunu başlat.';

  @override
  String get pinnedRewards => 'Sabitlenenler';

  @override
  String get collection => 'Koleksiyon';

  @override
  String get closeRewardDetails => 'Ödül detayını kapat';

  @override
  String rewardsEarnedProgress(int earned, int total) {
    return '$earned / $total ödül kazanıldı';
  }

  @override
  String get earned => 'Kazanıldı';

  @override
  String filterMenuAll(String label) {
    return '$label: Tümü';
  }

  @override
  String get removeFromShowcase => 'Vitrinden çıkar';

  @override
  String get pinToShowcase => 'Vitrine sabitle';

  @override
  String rewardEarnedForRequirement(String requirement) {
    return '$requirement şartını tamamladığın için kazanıldı.';
  }

  @override
  String rewardWithDate(String rarity, String date) {
    return '$rarity Ödül • $date';
  }

  @override
  String progressValue(int progress, int target) {
    return 'İlerleme: $progress / $target';
  }

  @override
  String rewardEarnedSemantics(String name) {
    return '$name, kazanıldı';
  }

  @override
  String rewardLockedSemantics(String name, int progress, int target) {
    return '$name, kilitli, $progress / $target';
  }

  @override
  String dragonLoot(String name) {
    return '$name Ganimeti';
  }

  @override
  String get dragonLootDescription => 'Ejderhayı yenerek kazanılan ödül.';

  @override
  String get dragonDefeatedCelebration => 'Ejderha Yenildi! 🐉';

  @override
  String get great => 'Harika!';

  @override
  String get dragonHealthSteps => 'Ejderha Canı (adım ile azalır)';

  @override
  String get dragonDefeated => 'Ejderha yenildi!';

  @override
  String stepsRemaining(int count) {
    return '$count adım daha kaldı.';
  }

  @override
  String get rewardRarityExplanation => 'Ödül Nadirliği Nasıl Belirlenir?';

  @override
  String get rarityBelow75 => '< %75 hedef';

  @override
  String get rarity75To99 => '%75 - %99 hedef';

  @override
  String get rarityMeetGoal => 'Hedefi tuttur';

  @override
  String get rarity125 => 'Hedefin %125\'i';

  @override
  String get rarity150 => 'Hedefin %150\'si';

  @override
  String get rewardClaimed => 'Ödül Alındı';

  @override
  String get claimReward => 'Ödülü Talep Et';

  @override
  String get home => 'Ana Sayfa';

  @override
  String get characterCatalogEmpty =>
      'All_Assets avatar klasöründe karakter bulunamadı.';

  @override
  String get characterCatalogLoadFailed => 'Karakter dosyaları yüklenemedi.';

  @override
  String get heroNameTooShort => 'Kahramanın adı en az 2 karakter olmalı.';

  @override
  String get fateSecondLine => 'KADERİNİN İKİNCİ SATIRI';

  @override
  String get ageQuestion => 'Kaç yaşındasın?';

  @override
  String get ageDescription => 'Yaş, kahramanının hikâyesine yön verir.';

  @override
  String get ageSuffix => 'yaş';

  @override
  String get defineBody => 'BEDENİNİ TANIMLA';

  @override
  String get weightQuestion => 'Kilon kaç?';

  @override
  String get weightDescription =>
      'Bu bilgi karakter profilinin bir parçası olacak.';

  @override
  String get fateFirstLine => 'KADERİNİN İLK SATIRI';

  @override
  String get nameQuestion => 'Sana nasıl hitap edelim?';

  @override
  String get nameDescription => 'Bu isim düşmanlarının hafızasına kazınacak.';

  @override
  String get heroNameHint => 'Kahramanının adı';

  @override
  String get genderFemale => 'Kadın';

  @override
  String get genderMale => 'Erkek';

  @override
  String get genderOther => 'Diğer';

  @override
  String get defineIdentity => 'KİMLİĞİNİ BELİRLE';

  @override
  String get identityQuestion => 'Kahramanın kim?';

  @override
  String get identityDescription => 'Seni en iyi ifade eden seçeneği seç.';

  @override
  String get choosePower => 'GÜCÜNÜ SEÇ';

  @override
  String get classQuestion => 'Hangi sınıfa aitsin?';

  @override
  String get classDescription => 'Yürüyüşünü ve savaş yolunu birlikte seç.';

  @override
  String get classSelectionHint =>
      'Devam etmek için bir sınıfa dokun, tanıt ekranında incele ve “BU SINIFI SEÇ”e bas.';

  @override
  String get fateSealed => 'KADERİN MÜHÜRLENİYOR';

  @override
  String heroReadyQuestion(String name) {
    return '$name, hazır mısın?';
  }

  @override
  String get confirmHeroDescription =>
      'Seçimlerini onayla ve Rush for Villains dünyasına adım at.';

  @override
  String get scrollToChangeValue =>
      'Değeri değiştirmek için yukarı veya aşağı kaydır';

  @override
  String get backToClassList => 'Sınıf listesine dön';

  @override
  String get usableItemTypes => 'KULLANABİLDİĞİ EŞYA TÜRLERİ';

  @override
  String get chooseThisClass => 'BU SINIFI SEÇ';

  @override
  String get back => 'Geri';

  @override
  String get sealChanges => 'DEĞİŞİKLİKLERİ MÜHÜRLE';

  @override
  String get startAdventureAction => 'MACERAYA BAŞLA';

  @override
  String get continueAction => 'DEVAM ET';

  @override
  String get retry => 'Tekrar dene';

  @override
  String stockRights(int count) {
    return 'Elinde $count hak var';
  }

  @override
  String get activeUntilEndOfDay => 'Şu an etkin — gün sonuna kadar';

  @override
  String get titleStore => 'Ünvan Mağazası';

  @override
  String get noTitlesForSale => 'Şu anda mağazada satılık ünvan bulunmuyor.';

  @override
  String get firstWeapon => 'İLK SİLAHIN';

  @override
  String get companionChoseWeapon =>
      'Yol arkadaşın bu silahı senin için seçti.';

  @override
  String get upgrades => 'Yükseltmeler';

  @override
  String get noClassEquipment => 'Sınıfın için ekipman bulunamadı.';

  @override
  String get affordableOnly => 'Alabileceklerim';

  @override
  String equipmentCount(int count) {
    return '$count ekipman';
  }

  @override
  String get noEquipmentForFilters =>
      'Bu süzgeçle gösterilecek ekipman yok. Yürümeye devam et; seviyen yükseldikçe yenileri açılır.';

  @override
  String get adventureStore => 'Macera Mağazası';

  @override
  String get titleStoreExplanation =>
      'Ünvan bir kimlik: adının yanında görünür ve kendine has bir etki taşır. Aynı anda yalnızca birini takarsın; hepsi sende kalır.';

  @override
  String titleStoreSummary(int owned, int total, int shown) {
    return '$owned / $total ünvan sende · $shown tanesi listede';
  }

  @override
  String get hideOwned => 'Sendekileri gizle';

  @override
  String get noStoreTitlesForFilters =>
      'Bu süzgeçle gösterilecek ünvan yok. Süzgeci gevşet ya da biraz daha altın biriktir.';

  @override
  String titleAlreadyOwned(String name) {
    return '“$name” ünvanı zaten sende. Profilden takabilirsin.';
  }

  @override
  String moreGoldNeeded(int count) {
    return '$count altın daha gerekiyor.';
  }

  @override
  String get ownedUpper => 'SENDE';

  @override
  String goldPrice(int count) {
    return '$count ALTIN';
  }

  @override
  String get owned => 'Sahipsin';

  @override
  String itemAlreadyOwned(String name) {
    return '$name zaten sende.';
  }

  @override
  String itemCoinsNeeded(String name, int count) {
    return '$name için $count coin daha gerekiyor.';
  }

  @override
  String maxRarityInvestment(int level) {
    return 'Yükseltilebilir · Maks Sv. $level · en üst nadirlik';
  }

  @override
  String mergeInvestment(int level, int count, String rarity) {
    return 'Yükseltilebilir · Maks Sv. $level · $count tanesini birleştirince $rarity olur';
  }

  @override
  String itemLevelNeeded(String name, int required, int current) {
    return '$name için $required. seviye gerekiyor. Şu an $current. seviyedesin.';
  }

  @override
  String levelShort(int level) {
    return 'Sv. $level';
  }

  @override
  String ownedCount(int count) {
    return '$count adet';
  }

  @override
  String get sellItemQuestion => 'Item satılsın mı?';

  @override
  String sellItemWarning(String name, String levelSuffix, int value, int cost) {
    return '$name$levelSuffix envanterinden çıkacak ve +$value coin kazanacaksın. Bu işlem geri alınamaz; itemi tekrar istersen $cost coin ödemen gerekir ve yükseltmelerini baştan yapman gerekir.';
  }

  @override
  String get cancel => 'Vazgeç';

  @override
  String sellWithValue(int value) {
    return 'Sat (+$value)';
  }

  @override
  String emptySlotPrompt(String category) {
    return '$category slotu boş. Aşağıdan bir item seç.';
  }

  @override
  String get noItemsOwned =>
      'Henüz item\'in yok. Mağazadan ekipman alabilir ya da günlük çarkı çevirebilirsin.';

  @override
  String get usableOnly => 'Kuşanabildiklerim';

  @override
  String get noInventoryItemsForFilters => 'Bu süzgeçle gösterilecek item yok.';

  @override
  String get tutorialWeaponMissing => 'Eğitim silahı bulunamadı.';

  @override
  String get firstWeaponTitle => 'İlk silahın';

  @override
  String get equippedAction => 'Kuşanıldı';

  @override
  String get equip => 'Kuşan';

  @override
  String get noEquippedItems => 'Henüz kuşanılmış eşya yok';

  @override
  String get noEffect => 'Etki yok';

  @override
  String get characterPower => 'Karakter Gücü';

  @override
  String filledSlots(int filled, int total) {
    return '$filled / $total slot dolu';
  }

  @override
  String get combatStats => 'Savaş İstatistikleri';

  @override
  String get combatStatsDescription =>
      'Maceradaki savaşta kullanılır: taban seviyeden, bonus ekipman ve seriden gelir.';

  @override
  String get conditionalEffects => 'Koşullu Etkiler';

  @override
  String get columnBase => 'TABAN';

  @override
  String get columnEquipment => 'EKİPMAN';

  @override
  String get columnBonus => 'BONUS';

  @override
  String get columnTotal => 'TOPLAM';

  @override
  String get columnShare => 'PAY';

  @override
  String get columnStatus => 'DURUM';

  @override
  String get streakBonus => 'Seri Bonusu';

  @override
  String streakBonusTotal(String rate) {
    return 'toplam +%$rate';
  }

  @override
  String streakCombatGrowth(int days) {
    return '$days günlük serin savaş statlarını büyüttü. Seri kırılırsa tamamı gider.';
  }

  @override
  String streakCurrentRate(String rate, int tier, int cycle) {
    return 'Şu an: gün başına +%$rate. Kazanç her $tier günde bir azalır, $cycle. günden sonra başa döner.';
  }

  @override
  String get equippedItems => 'Kuşanılanlar';

  @override
  String get empty => 'Boş';

  @override
  String get equippedTag => 'Kuşanılı';

  @override
  String levelRequirement(int required, int current) {
    return '$required. seviye gerekiyor. Şu an $current. seviyedesin.';
  }

  @override
  String get effects => 'Etkiler';

  @override
  String get dormantCombatEffects =>
      'Soluk satırlar savaş istatistikleri; savaş sistemiyle birlikte etkinleşecek.';

  @override
  String equipIntoEmptySlot(String category) {
    return '$category slotu boş — kuşanınca:';
  }

  @override
  String replaceEquippedItem(String name) {
    return '$name yerine kuşanınca:';
  }

  @override
  String get noNumericDifference => 'Sayısal olarak fark yok.';

  @override
  String get unequip => 'Çıkar';

  @override
  String sellValue(int value) {
    return 'Sat +$value';
  }

  @override
  String blacksmithLevel(int level, int cap) {
    return 'Demirci — Sv. $level / $cap';
  }

  @override
  String get upgradeCombatOnly =>
      'Yükseltmek yalnızca savaş istatistiklerini büyütür; ekonomi bonusları sabit kalır.';

  @override
  String nextLevelPreview(int level, String preview) {
    return 'Sv. $level: $preview';
  }

  @override
  String upgradeToLevel(int level, int cost) {
    return 'Sv. $level\'e yükselt — $cost coin';
  }

  @override
  String get cannotUpgrade => 'Yükseltilemiyor';

  @override
  String get emptyForge =>
      'Örs boş. Mağazadan ekipman aldığında burada yükseltebilir, aynı eşyadan birkaç adet biriktirince birleştirebilirsin.';

  @override
  String get mergeQuestion => 'Birleştirilsin mi?';

  @override
  String mergeCostWarning(int count, String name, int cost) {
    return '$count adet $name ve $cost coin harcanacak.';
  }

  @override
  String mergeResult(String rarity, String name, int cap) {
    return 'Karşılığında 1 adet $rarity $name alacaksın — Sv. 1, nadirlik tavanı $cap.';
  }

  @override
  String consumedItemLevels(String levels) {
    return 'Harcanan eşyaların seviyeleri: $levels.';
  }

  @override
  String get equippedItemConsumed =>
      'Kuşanılı bir adet harcanacak; önce çıkarılacak.';

  @override
  String get irreversibleAction => 'Bu işlem geri alınamaz.';

  @override
  String get merge => 'Birleştir';

  @override
  String upgradeBestItem(int level, int cap, String suffix) {
    return 'Yükselt — Sv. $level / $cap$suffix';
  }

  @override
  String get mostAdvancedSuffix => ' (en gelişmiş adet)';

  @override
  String get cannotUpgradeNow => 'Şu an yükseltilemiyor.';

  @override
  String get mergeHighestRarity => 'Birleştirme — en üst nadirlik';

  @override
  String get cannotMerge => 'Birleştirilemiyor';

  @override
  String mergeProgressTitle(int owned, int required, String rarity) {
    return 'Birleştirme — $owned/$required adet → $rarity';
  }

  @override
  String mergeResetDetail(int cap) {
    return 'Sonuç Sv. 1\'e döner, nadirlik tavanı $cap olur';
  }

  @override
  String mergeWithCost(int cost) {
    return 'Birleştir — $cost coin';
  }

  @override
  String get cannotMergeNow => 'Şu an birleştirilemiyor.';

  @override
  String get chooseDailyGoal => 'GÜNLÜK HEDEFİNİ SEÇ';

  @override
  String get goalPickerHint =>
      '500 adımlık aralıklarla yukarı veya aşağı kaydır';

  @override
  String selectStepGoal(String count) {
    return '$count ADIMI SEÇ';
  }

  @override
  String roundNumberUpper(int round) {
    return '$round. ROUND';
  }

  @override
  String get victoryUpper => 'ZAFER!';

  @override
  String get roundYoursUpper => 'ROUND SENİN!';

  @override
  String enemyDefeatedNamed(String name) {
    return '$name yenildi!';
  }

  @override
  String get roundCompletedEarly => 'Round için gereken adımları tamamladın';

  @override
  String speedRewardSummary(int rounds, String steps, String multiplier) {
    return '$rounds round · $steps adım — savaş verimi ×$multiplier';
  }

  @override
  String walkPhaseRemainingNotice(String steps, int rate) {
    return 'Macera bitmedi: $steps adımlık yürüyüş fazı kaldı. Bu fazda $rate adım = 1 altın.';
  }

  @override
  String get hitUpper => 'VURUŞ!';

  @override
  String healthDamageUpper(int count) {
    return '-$count CAN';
  }

  @override
  String get continueWalkingUpper => 'YÜRÜYÜŞE DEVAM ET';

  @override
  String get chooseNewAdventureUpper => 'YENİ MACERA SEÇ';

  @override
  String get finalBlow => 'Son darbe!';

  @override
  String attackSequence(int current, int total) {
    return 'Saldırı $current / $total';
  }

  @override
  String get enemyRoundUpper => 'DÜŞMAN SALDIRDI!';

  @override
  String enemyKilledBeforeCounter(String enemy) {
    return '$enemy, sen vuramadan seni öldürdü.';
  }

  @override
  String get restTime => 'Dinlenme zamanı';

  @override
  String revivalIntro(String name) {
    return '$name karşısında canın tükendi. Yeni maceralara açılmak için 500 adımlık Hayat Yürüyüşünü tamamlamalısın.';
  }

  @override
  String get revivalNoXp =>
      'Bu özel yürüyüş boyunca XP kazanılmaz; yürümeye devam ettiğinde yeniden doğarsın.';

  @override
  String get startLifeWalk => 'Hayat Yürüyüşüne Çık';

  @override
  String get lifeWalk => 'Hayat Yürüyüşü';

  @override
  String get lifeWalkDescription =>
      'Durma; yeniden doğmak için düşük tempoda yürümeye devam et. Bu 500 adım XP kazandırmaz.';

  @override
  String get revived => 'Yeniden doğdun!';

  @override
  String get revivalCompleted =>
      'Hayat Yürüyüşünü tamamladın. Bu yürüyüş XP vermedi; şimdi yeniden maceraya açılabilirsin.';

  @override
  String get backToAdventures => 'Maceralara Dön';

  @override
  String extraGold(int count) {
    return '+$count EK ALTIN';
  }

  @override
  String get congratulations => 'Tebrikler!';

  @override
  String xpWonNextAdventure(int xp) {
    return '$xp XP kazandın. Yeni bir macera seni bekliyor.';
  }

  @override
  String get chooseNewAdventure => 'Yeni Macera Seç';

  @override
  String get chooseTodaysAdventure => 'Bugünkü maceranı seç';

  @override
  String get adventureSelectionDescription =>
      'Hedefini belirle, meydan okuyabileceğin düşmanı seç ve yürüyüşe başla.';

  @override
  String get chooseEnemy => 'Düşmanını seç';

  @override
  String get tapEnemyForDetails =>
      'Düşmanın ayrıntılarını görmek ve macerayı başlatmak için karta dokun.';

  @override
  String get victoryIsYours => 'Zafer senin';

  @override
  String enemyFelledRoadYours(String name) {
    return '$name devrildi. Yolun geri kalanı senin.';
  }

  @override
  String walkPhaseRate(int rate) {
    return 'Yürüyüş fazı · $rate adım = 1 altın';
  }

  @override
  String walkProgressRemaining(
    String current,
    String target,
    String remaining,
  ) {
    return '$current / $target adım — kalan $remaining';
  }

  @override
  String walkPhaseExplanation(int normal, int bonus) {
    return 'Macera adım taahhüdün dolunca biter. O ana kadar attığın her adım normalden değerli: oran $normal yerine $bonus. Faz bitince oran $normal adım = 1 altına döner. XP oranı değişmez.';
  }

  @override
  String get victorySummary => 'Zafer özeti';

  @override
  String get streakAndWheelSecured =>
      'Serin ve çark hakkın bu zaferle güvence altında.';

  @override
  String get abandonWalkUpper => 'YÜRÜYÜŞÜ BIRAK, YENİ MACERA SEÇ';

  @override
  String get abandonWalkWarning =>
      'Bırakırsan bonuslu oran biter; zafer ödülün sende kalır.';

  @override
  String get defeated => 'Yenildi';

  @override
  String get waitingForYou => 'Seni bekliyor';

  @override
  String get missionMessage => 'Görev mesajın';

  @override
  String get adventureStatus => 'Macera durumu';

  @override
  String get yourHealth => 'Senin Canın';

  @override
  String get dailySteps => 'Günlük Adım';

  @override
  String victoryRewardXp(int xp) {
    return 'Zafer ödülü: $xp XP';
  }

  @override
  String get leaveAdventure => 'Maceradan Ayrıl';

  @override
  String roundProgress(int current, int total) {
    return 'Round $current/$total';
  }

  @override
  String get chooseGoalUpper => 'HEDEF SEÇ';

  @override
  String get tapToChange => 'Değiştirmek için dokun';

  @override
  String get enemyEncounterUpper => 'DÜŞMAN KARŞILAŞMASI';

  @override
  String get enemyAboutUpper => 'DÜŞMAN HAKKINDA';

  @override
  String attackStat(int value) {
    return '$value saldırı';
  }

  @override
  String defenseStat(int value) {
    return '$value savunma';
  }

  @override
  String get startAdventure => 'Maceraya Başla';

  @override
  String get goalSuitable => 'Bu hedef için uygun';

  @override
  String unlocksAtSteps(String steps) {
    return '$steps adımda açılır';
  }

  @override
  String victoryMissionMessage(String name, int xp) {
    return '$name yenildi. $xp XP kazandın; bu zaferi adım adım hak ettin!';
  }

  @override
  String totalDuration(String duration) {
    return '$duration toplam';
  }

  @override
  String enemyCombatExplanation(int rounds, int steps, String duration) {
    return '$rounds round; her round $steps adım ve $duration. Hedefe süre dolmadan ulaşırsan mükemmel round serisi hasarını büyütür; kaçırırsan seri kırılır ve düşman eksik oranının eğrisine göre saldırır.';
  }

  @override
  String get storageUnavailable =>
      'Kayıtlı ilerlemene şu an ulaşılamadı. Oyun geçici bir kayıtla açıldı; uygulamayı yeniden başlatmayı dene.';

  @override
  String get studioSplashSemantics => 'Heapchi Studios açılış ekranı';

  @override
  String get enemyAshGuardianName => 'Kül Muhafızı';

  @override
  String get enemyAshGuardianQuest =>
      'Kül Muhafızı sessiz geçidi tuttu. İlk 500 adımınla zırhındaki mührü parçala!';

  @override
  String get enemyNightOathName => 'Gece Yeminlisi';

  @override
  String get enemyNightOathQuest =>
      'Gece Yeminlisi kılıcını ay ışığında kaldırdı. 1.000 adımlık ritmini bozmadan onu geride bırak!';

  @override
  String get enemyVoidKnightName => 'Hiçlik Şövalyesi';

  @override
  String get enemyVoidKnightQuest =>
      'Hiçlik Şövalyesi yolun üzerine karanlık bir yarık açtı. 1.500 adımla mührü kapat!';

  @override
  String get enemyBloodWeaverName => 'Kan Dokuyan';

  @override
  String get enemyBloodWeaverQuest =>
      'Kan Dokuyan ağının başında bekliyor. 2.000 adımı kendi temponda tamamla, sonra güvenle savaş.';

  @override
  String get enemyCrimsonWingName => 'Kızıl Kanat';

  @override
  String get enemyCrimsonWingQuest =>
      'Kızıl Kanat gökyüzünü kana boyadı. 2.500 adım at, gölgesinin dışına çık!';

  @override
  String get enemyEmberSirenName => 'Kor Sireni';

  @override
  String get enemyEmberSirenQuest =>
      'Kor Sireni ateşli ezgisiyle adımlarını yavaşlatıyor. 3.000 adımla büyüyü sustur!';

  @override
  String get enemyDuskTemptressName => 'Alacakaranlık Cadısı';

  @override
  String get enemyDuskTemptressQuest =>
      'Alacakaranlık Cadısı patikayı sahte hayallerle kapladı. 3.500 gerçek adımla sisini dağıt!';

  @override
  String get enemyHornedExecutionerName => 'Boynuzlu Cellat';

  @override
  String get enemyHornedExecutionerQuest =>
      'Boynuzlu Cellat baltasını yol taşına vurdu. 4.000 adımla meydan okumasını kabul et!';

  @override
  String get enemyInfernalSentinelName => 'Cehennem Nöbetçisi';

  @override
  String get enemyInfernalSentinelQuest =>
      'Cehennem Nöbetçisi köprüyü ateşle çevirdi. 4.500 adımla alev çemberini yar!';

  @override
  String get enemyBlackClawName => 'Kara Pençe';

  @override
  String get enemyBlackClawQuest =>
      'Kara Pençe seni bekliyor. 5.000 adımı kendi temponda tamamla ve güvenli bir yerde savaş.';

  @override
  String get enemyEmberHeirName => 'Alev Tahtının Varisi';

  @override
  String get enemyEmberHeirQuest =>
      'Alev Tahtının Varisi tacını savunuyor. 5.500 adımla krallığını sars!';

  @override
  String get enemyAbyssOverlordName => 'Uçurum Hükümdarı';

  @override
  String get enemyAbyssOverlordQuest =>
      'Uçurum Hükümdarı dönüş yolunu yuttu. 6.000 adımla kendi geçidini aç!';

  @override
  String get enemyEyeOfNothingName => 'Hiçliğin Gözü';

  @override
  String get enemyEyeOfNothingQuest =>
      'Hiçliğin Gözü her adımını izliyor. 6.500 adımla bakışını yere indir!';

  @override
  String get enemyCinderColossusName => 'Köz Devi';

  @override
  String get enemyCinderColossusQuest =>
      'Köz Devi her darbede dağı uyandırıyor. 7.000 adımla taş kalbini soğut!';

  @override
  String get enemySpiritFlameName => 'Ruh Alevi';

  @override
  String get enemySpiritFlameQuest =>
      'Ruh Alevi sönmeyen bir iz gibi peşinde. 7.500 adımla lanetli ateşi tüket!';

  @override
  String get enemyHellWingName => 'Cehennem Kanadı';

  @override
  String get enemyHellWingQuest =>
      'Cehennem Kanadı göğü kararttı. 8.000 adımla kanatlarının altından şafağa ulaş!';

  @override
  String get enemyAshFangName => 'Kül Diş';

  @override
  String get enemyAshFangQuest =>
      'Kül Diş kokunu aldı ve av başladı. 8.500 adımla cehennem tazısını yıprat!';

  @override
  String get enemyMagmaDevourerName => 'Magma Yutan';

  @override
  String get enemyMagmaDevourerQuest =>
      'Magma Yutan bastığın zemini eritiyor. 9.000 adımla lav denizinin önüne geç!';

  @override
  String get enemyMazeButcherName => 'Labirent Kasabı';

  @override
  String get enemyMazeButcherQuest =>
      'Labirent Kasabı çıkışını bekliyor. 9.500 adımla duvarlardan önce iradesini yık!';

  @override
  String get enemyLordOfLastSealName => 'Son Mührün Efendisi';

  @override
  String get enemyLordOfLastSealQuest =>
      'Son Mührün Efendisi yolculuğunun sonuna karanlık imzasını attı. 10.000 adımla mührü sonsuza dek kır!';

  @override
  String get enemyArchetypeBruiser => 'Dengeli';

  @override
  String get enemyArchetypeBruiserDescription =>
      'Dengeli dövüşür; sürprizi yoktur.';

  @override
  String get enemyArchetypeTank => 'Dayanıklı';

  @override
  String get enemyArchetypeTankDescription =>
      'Yavaş ama çok dayanıklı; canını eritmek zaman ister.';

  @override
  String get enemyArchetypeSwift => 'Çevik';

  @override
  String get enemyArchetypeSwiftDescription =>
      'Genelde önce vurur ve vuruşlarını sıyırır.';

  @override
  String get enemyArchetypeCaster => 'Büyücü';

  @override
  String get enemyArchetypeCasterDescription =>
      'Kırılgan ama sert vurur; kritiği yüksektir.';

  @override
  String get guideMaviliName => 'Mavili';

  @override
  String get guideMaviliDescription => 'Sakin, cesur ve güvenilir.';

  @override
  String get guidePinkyName => 'Pinky';

  @override
  String get guidePinkyDescription => 'Neşeli, hızlı ve meraklı.';

  @override
  String get guideKupkuzuName => 'Küpkuzu';

  @override
  String get guideKupkuzuDescription => 'Küçük, bilge ve gözü pek.';

  @override
  String get petTavernTeaser =>
      'Çevrimiçi çok yakında — hadi git git, sen yürümene bak!';

  @override
  String get petHome1 => 'Bugün de yürüyoruz, değil mi? Ben hazırım.';

  @override
  String get petHome2 => 'Adımların birikiyor. Sonu güzel bitecek.';

  @override
  String get petHome3 => 'Şu halkanın dolmasına bayılıyorum.';

  @override
  String get petHome4 => 'Bir tur daha atsak fena olmaz bence.';

  @override
  String get petHome5 => 'Sessiz duruyorum ama seni izliyorum.';

  @override
  String get petHomeNoStreak1 =>
      'Serini bugün henüz güvenceye almadın. Acele yok ama unutma.';

  @override
  String get petHomeNoStreak2 =>
      'Bir düşman devirsen seri bu akşam garanti olur.';

  @override
  String get petHomeWheelReady1 => 'Çark hâlâ dönmeyi bekliyor, haberin olsun.';

  @override
  String get petHomeWheelReady2 =>
      'Bugünün çark hakkı duruyor. Bedava şey sevmez misin?';

  @override
  String get petAdventure1 =>
      'Şu düşmanın gözlerine bakma, cesareti kırılıyor.';

  @override
  String get petAdventure2 =>
      'Adımlarını biriktir, güvenli olduğunda savaşa başla.';

  @override
  String get petAdventure3 => 'Canavar bekleyebilir. Kendi temponda yürü.';

  @override
  String get petAdventureIdle1 =>
      'Macera seçmemişsin. Hangi rakibi kızdıralım?';

  @override
  String get petAdventureIdle2 => 'Boş duran bir kahraman görmek beni geriyor.';

  @override
  String get petStore1 => 'Bakmak bedava. Almak değil.';

  @override
  String get petStore2 => 'Şu kalkanı alsan bir daha canını dert etmezdin.';

  @override
  String get petStore3 => 'Altınını biriktir derdim ama beni dinlemiyorsun.';

  @override
  String get petTavern2 =>
      'Burası dolduğunda masaları kapmak zor olacak, şimdiden söyleyeyim.';

  @override
  String get petTavern3 =>
      'Takım kuracağız, düşmanları paylaşacağız. Ama daha değil.';

  @override
  String get petProfile1 => 'Ünvanını değiştirdin mi? Yeni birini denesen?';

  @override
  String get petProfile2 => 'Buradaki sayılara bakınca gurur duyuyorum.';

  @override
  String get petProfile3 => 'Seri bonusun her gün biraz daha birikiyor.';

  @override
  String get tutorialWelcome =>
      'Selam! Maceranda yanında olacağım. Hazırsan başlayalım.';

  @override
  String get tutorialAdventurePrompt => 'Gel, ilk maceranı seçelim.';

  @override
  String get tutorialEnemyChoice =>
      'İlk rakibini seç. Acele etme, burada seni bekliyorum.';

  @override
  String get tutorialEnemySelected =>
      'İyi seçim! İlk maceranda senin yerine ben yürürüm. Sen vuruşumu izle.';

  @override
  String get tutorialCombatDemo =>
      'Bu ilk savaş benden! Adımlarını ve vuruşlarını senin için tamamlıyorum.';

  @override
  String get tutorialCombatWaiting =>
      'Şimdi sıra sende. Adımlarını tamamla; savaşı burada izleyeceğim.';

  @override
  String get tutorialEnemyReaction => 'Gördün mü? Düşmanlar da karşılık verir.';

  @override
  String get tutorialVictoryCelebration => 'İşte bu! İlk zaferin.';

  @override
  String get tutorialRewardCoins =>
      'Düşmanları yenerek rastgele altın kazanırsın.';

  @override
  String get tutorialRewardXp => 'Deneyim de seni seviye seviye güçlendirir.';

  @override
  String get tutorialShopPrompt =>
      'Şimdi altınını güce çevirelim. Mağazaya gitmek için düğmeye dokun.';

  @override
  String get tutorialShopWaiting =>
      'Eğitim altınınla gösterdiğim ilk silahı satın al.';

  @override
  String get tutorialItemBought => 'İşte şimdi güçleniyoruz!';

  @override
  String get tutorialEquipWaiting =>
      'Yeni eşyanı bul ve Kuşan düğmesine dokun.';

  @override
  String get tutorialItemEquipped => 'Çok daha iyi!';

  @override
  String get tutorialBlacksmithPrompt =>
      'Biraz daha güç lazım. Demirciye gidelim.';

  @override
  String get tutorialUpgradeWaiting =>
      'Yükselt düğmesi eşyanın seviyesini artırır.';

  @override
  String get tutorialUpgradeCompleted =>
      'Şimdi oldu! Eşyan artık çok daha güçlü.';

  @override
  String get tutorialWheelPrompt =>
      'Son durak: Günlük Çark. Şansını deneyelim.';

  @override
  String get tutorialWheelWaiting => 'Çevir ve sonucu birlikte izleyelim.';

  @override
  String get tutorialWheelReward => 'Şans bugün senden yana!';

  @override
  String get tutorialFinalReady => 'Artık hazırsın.';

  @override
  String get tutorialFinalMotto => 'Yürü. Güçlen. Düşmanlarını yen.';

  @override
  String get tutorialOnlineTeaser =>
      'Ama bu daha başlangıç... Yakında Online Maceralar da burada olacak.';

  @override
  String get tutorialRatingRequest =>
      'Ben gitmeden önce küçük bir ricam var. Maceranı sevdiysen bizi değerlendirmeyi unutma!';

  @override
  String get tutorialFarewellWorkDone => 'Benim işim burada bitti.';

  @override
  String get tutorialFarewellYourTurn =>
      'Artık buralar sana emanet. Seninle dövüşmemi istersen ana sayfadaki adım çemberinin sol altındaki pet butonuna basabilirsin.';

  @override
  String get tutorialFarewell =>
      'Şimdilik gidiyorum. Beni çağırırsan yine yanında olacağım!';

  @override
  String get tutorialBegin => 'Başlayalım';

  @override
  String get tutorialStartAdventure => 'Macerayı başlat';

  @override
  String get tutorialUnderstood => 'Anladım';

  @override
  String get tutorialViewRewards => 'Ödüllere bak';

  @override
  String get tutorialContinue => 'Devam';

  @override
  String get tutorialGoToStore => 'Mağazaya git';

  @override
  String get tutorialOpenInventory => 'Envanteri aç';

  @override
  String get tutorialGoToWheel => 'Çarka git';

  @override
  String get tutorialOpenBlacksmith => 'Demirciyi aç';

  @override
  String get tutorialOpenWheel => 'Çarkı aç';

  @override
  String get tutorialLater => 'Sonra';

  @override
  String get tutorialRate => 'Değerlendir';

  @override
  String get tutorialFinish => 'Eğitimi Bitir';

  @override
  String adventureReminder1(int round, String steps, String enemy) {
    return '$round. round: $enemy için $steps adım kaldı.';
  }

  @override
  String adventureReminder2(int round, String steps) {
    return '$round. round devam ediyor! Kalan $steps adımı tamamla.';
  }

  @override
  String adventureReminder3(int round, String steps) {
    return 'Ritmini koru! $round. roundda $steps adımın kaldı.';
  }

  @override
  String adventureReminder4(int round, String steps, String enemy) {
    return '$round. round: $steps adım daha at ve $enemy gücünü kaybetsin!';
  }

  @override
  String get adventureReminderChannel => 'Macera Hatırlatmaları';

  @override
  String get adventureReminderChannelDescription =>
      'Devam eden macera ve adım hatırlatmaları';

  @override
  String get rarityCommon => 'Sıradan';

  @override
  String get rarityUncommon => 'Az Bulunur';

  @override
  String get rarityRare => 'Nadir';

  @override
  String get rarityEpic => 'Epik';

  @override
  String get rarityLegendary => 'Efsanevi';

  @override
  String get itemCategorySwords => 'Kılıçlar';

  @override
  String get itemCategoryAxesHalberds => 'Baltalar ve Teberler';

  @override
  String get itemCategoryMacesHammers => 'Topuzlar ve Çekiçler';

  @override
  String get itemCategorySpears => 'Mızraklar';

  @override
  String get itemCategoryScythes => 'Tırpanlar';

  @override
  String get itemCategoryMagic => 'Büyü';

  @override
  String get itemCategoryShields => 'Kalkanlar';

  @override
  String get itemCategoryArch => 'Yay ve Ok';

  @override
  String get itemCategoryRangedOther => 'Fırlatma Silahları';

  @override
  String get itemCategorySpecialOther => 'Özel';

  @override
  String get itemArchetypeStriker => 'Vurucu';

  @override
  String get itemArchetypeStrikerDescription =>
      'ham vuruş gücüne yatırım yapar';

  @override
  String get itemArchetypeGuardian => 'Muhafız';

  @override
  String get itemArchetypeGuardianDescription => 'dayanıklılığa yatırım yapar';

  @override
  String get itemArchetypeDuelist => 'Düellocu';

  @override
  String get itemArchetypeDuelistDescription => 'kritik vuruşa yatırım yapar';

  @override
  String get itemArchetypeSwift => 'Çevik';

  @override
  String get itemArchetypeSwiftDescription =>
      'kaçınma ve tempoya yatırım yapar';

  @override
  String get titleSourcePurchase => 'Mağaza';

  @override
  String get titleSourceAchievement => 'Başarım';

  @override
  String get titleSourceWheel => 'Çark';

  @override
  String get titleSourceMilestone => 'Kilometre taşı';

  @override
  String get classArcher => 'Şahin Okçu';

  @override
  String get classArmoredAxeman => 'Demir Cellat';

  @override
  String get classArmoredOrc => 'Zırhlı Yaban';

  @override
  String get classArmoredSkeleton => 'Kemik Muhafız';

  @override
  String get classEliteOrc => 'Kızıl Savaş Şefi';

  @override
  String get classGreatswordSkeleton => 'Mezar Kılıçlısı';

  @override
  String get classKnight => 'Kraliyet Şövalyesi';

  @override
  String get classKnightTemplar => 'Şafak Tapınakçısı';

  @override
  String get classOrc => 'Yaban Akıncı';

  @override
  String get classPriest => 'Işık Rahibi';

  @override
  String get classSkeleton => 'Kemik Savaşçı';

  @override
  String get classSkeletonArcher => 'Mezar Okçusu';

  @override
  String get classSlime => 'İlginç Slime';

  @override
  String get classSoldier => 'Sınır Muhafızı';

  @override
  String get classSwordsman => 'Kılıç Üstadı';

  @override
  String get classWerebear => 'Ayı Ruhlu';

  @override
  String get classWerewolf => 'Ay Kurdu';

  @override
  String get classWizard => 'Gök Büyücüsü';

  @override
  String get classSelectionSloganFallback =>
      'İyi seçim. Birlikte zafere yürüyeceğiz!';

  @override
  String get rewardConditionTotalDistance => 'Toplam mesafe';

  @override
  String get rewardConditionSingleWalkDistance => 'Tek yürüyüş mesafesi';

  @override
  String get rewardConditionDailyStepGoals => 'Günlük hedef';

  @override
  String get rewardConditionStreakDays => 'Hedef serisi';

  @override
  String get rewardConditionCompletedDays => 'Tamamlanan gün';

  @override
  String get rewardConditionMonstersDefeated => 'Canavar avı';

  @override
  String get rewardConditionSpecificVillain => 'Villain avı';

  @override
  String get rewardConditionVillainsDefeated => 'Villain zaferi';

  @override
  String get rewardConditionFlawlessWins => 'Hasarsız zafer';

  @override
  String get rewardConditionWinStreak => 'Galibiyet serisi';

  @override
  String get rewardConditionQuestsCompleted => 'Görev tamamlama';

  @override
  String get rewardConditionLevel => 'Seviye';

  @override
  String get rewardConditionXpEarned => 'XP toplama';

  @override
  String get rewardConditionBossesDefeated => 'Boss avı';

  @override
  String get rewardConditionRareVillainsDefeated => 'Nadir villain avı';

  @override
  String get rewardConditionVillainsDiscovered => 'Villain keşfi';

  @override
  String get rewardConditionActiveDays => 'Düzenli devam';

  @override
  String generatedRewardName(String condition, int series) {
    return '$condition Hatırası · $series';
  }

  @override
  String rewardRequirementTotalDistance(String distance) {
    return '$distance km yürü';
  }

  @override
  String rewardRequirementSingleWalkDistance(String distance) {
    return 'Tek yürüyüşte $distance km ilerle';
  }

  @override
  String rewardRequirementDailyGoals(int count) {
    return 'Günlük adım hedefini $count gün tamamla';
  }

  @override
  String rewardRequirementStreak(int count) {
    return 'Hedefini $count gün üst üste tuttur';
  }

  @override
  String rewardRequirementCompletedDays(int count) {
    return '$count hedef günü tamamla';
  }

  @override
  String rewardRequirementMonsters(int count) {
    return '$count canavar yen';
  }

  @override
  String rewardRequirementSpecificVillain(String enemy, int count) {
    return '$enemy villain’ını $count kez yen';
  }

  @override
  String rewardRequirementVillains(int count) {
    return '$count villain yen';
  }

  @override
  String rewardRequirementFlawless(int count) {
    return 'Hasar almadan $count savaş kazan';
  }

  @override
  String rewardRequirementWinStreak(int count) {
    return '$count savaşlık galibiyet serisine ulaş';
  }

  @override
  String rewardRequirementQuests(int count) {
    return '$count görev tamamla';
  }

  @override
  String rewardRequirementLevel(int count) {
    return '$count. seviyeye ulaş';
  }

  @override
  String rewardRequirementXp(int count) {
    return 'Toplam $count XP kazan';
  }

  @override
  String rewardRequirementBosses(int count) {
    return '$count boss yen';
  }

  @override
  String rewardRequirementRareVillains(int count) {
    return '$count nadir villain yen';
  }

  @override
  String rewardRequirementDiscovered(int count) {
    return '$count farklı villain keşfet';
  }

  @override
  String rewardRequirementActiveDays(int count) {
    return 'Uygulamaya $count farklı gün devam et';
  }

  @override
  String rewardDescription(String requirement) {
    return '$requirement ve bu hatırayı koleksiyonuna kat.';
  }

  @override
  String thisRoundSteps(String current, String target) {
    return 'Bu round: $current / $target adım';
  }

  @override
  String roundRules(String steps, String duration, String enemy) {
    return 'Bu round $steps adım · $duration. Hedefi süre dolmadan bitirirsen mükemmel round ve erken bitirme bonusu kazanırsın. Kaçırırsan seri sıfırlanır; $enemy eksik oranının eğrisine göre saldırır.';
  }

  @override
  String roundGoalSummary(int rounds, String steps, String duration) {
    return '$rounds round · $steps adım/round · $duration/round';
  }

  @override
  String healthValue(String value) {
    return '$value can';
  }

  @override
  String stepsLabel(String value) {
    return '$value adım';
  }

  @override
  String enemyAttackedAfterTimeout(String enemy) {
    return '$enemy saldırdı';
  }

  @override
  String enemyAttackingCycle(String enemy, int current, int total) {
    return '$enemy saldırıyor · $current / $total';
  }

  @override
  String victoryCoinsTotal(String total, String base, String bonus) {
    return 'toplam +$total altın · taban $base + savaş verimi bonusu $bonus';
  }

  @override
  String damageDealt(int damage) {
    return 'Düşmanın $damage canını aldın!';
  }

  @override
  String dailyStepProgressValue(String current, String goal) {
    return '$current / $goal adım';
  }

  @override
  String adventureProgressValue(String current, String goal) {
    return '$current / $goal adım — macera ilerlemesi';
  }

  @override
  String walkRewardBreakdown(
    String victory,
    String walk,
    String total,
    String xp,
  ) {
    return 'Zafer +$victory · yürüyüş +$walk altın · toplam +$total altın · +$xp XP';
  }

  @override
  String perfectStreakNextCap(String cap) {
    return 'Mükemmel seri: — · sıradaki tavan ×$cap';
  }

  @override
  String perfectStreakCap(int count, String cap) {
    return 'MÜKEMMEL SERİ $count · tavan ×$cap';
  }

  @override
  String get streakBrokenUpper => 'SERİ KIRILDI · ×1.0';

  @override
  String perfectStreakUpper(int count) {
    return 'MÜKEMMEL · SERİ $count';
  }

  @override
  String get newRoundStartedUpper => 'YENİ ROUND BAŞLADI';

  @override
  String get walkingPhaseUpper => 'YÜRÜYÜŞ FAZI';

  @override
  String get titleUnequippedNotice => 'Ünvanın çıkarıldı.';

  @override
  String titleEquippedNotice(String name) {
    return '“$name” ünvanını taktın.';
  }

  @override
  String titleOwnedNotice(String name) {
    return '“$name” ünvanı zaten sende.';
  }

  @override
  String coinsStillNeeded(int count) {
    return '$count altın daha gerekiyor.';
  }

  @override
  String titlePurchasedNotice(String name) {
    return '“$name” ünvanı alındı. Profilden takabilirsin.';
  }

  @override
  String newTitleNotice(String names) {
    return 'Yeni ünvan: $names — profilden takabilirsin.';
  }

  @override
  String newTitlesNotice(String names) {
    return 'Yeni ünvanlar: $names';
  }

  @override
  String newRewardNotice(String name) {
    return 'Yeni ödül: $name';
  }

  @override
  String newRewardsNotice(int count) {
    return '$count yeni ödül koleksiyonuna eklendi!';
  }

  @override
  String enemyAttackNotice(String enemy, int damage) {
    return '$enemy senin $damage canını aldı.';
  }

  @override
  String perfectRoundNotice(int streak, String multiplier) {
    return 'Mükemmel round! Seri $streak · hasar ×$multiplier';
  }

  @override
  String get perfectRoundBrokenNotice =>
      'Mükemmel round serin kırıldı. Çarpan ×1’e döndü.';

  @override
  String itemPurchasedNotice(String name) {
    return '$name satın alındı!';
  }

  @override
  String itemPurchasedCountNotice(String name, int count) {
    return '$name satın alındı. Artık $count adet.';
  }

  @override
  String get itemMissingNotice => 'Bu eşya envanterinde yok.';

  @override
  String get itemCatalogMissingNotice => 'Bu eşya artık katalogda yok.';

  @override
  String itemWrongClassNotice(String name) {
    return '$name senin sınıfın için değil.';
  }

  @override
  String itemEquippedNotice(String name) {
    return '$name kuşanıldı.';
  }

  @override
  String itemEquippedReplacedNotice(String name, String replaced) {
    return '$name kuşanıldı, $replaced çıkarıldı.';
  }

  @override
  String itemRemovedNotice(String name) {
    return '$name çıkarıldı.';
  }

  @override
  String itemSoldNotice(String name, int value) {
    return '$name satıldı. +$value coin.';
  }

  @override
  String itemRemovedSoldNotice(String name, int value) {
    return '$name çıkarılıp satıldı. +$value coin.';
  }

  @override
  String get reincarnationNeededNotice =>
      'Karakterini değiştirmek için Reenkarnasyon İksiri gerekli.';

  @override
  String get reincarnationCompleteNotice =>
      'Reenkarnasyon tamamlandı. İksir tüketildi.';

  @override
  String levelUpUpper(int level) {
    return 'SEVİYE $level!';
  }

  @override
  String levelsGainedNotice(int count) {
    return '$count seviye birden atladın. Adımların karşılığını veriyor!';
  }

  @override
  String get nextLevelEncouragement =>
      'Yürümeye devam et, sıradaki seviye yaklaşıyor.';

  @override
  String get revivalDoneNotice =>
      'Hayat Yürüyüşü tamamlandı. Yeniden doğdun! Bu 500 adım XP kazandırmadı.';

  @override
  String get revivalRequiredNotice =>
      'Yeni bir macera için önce 500 adımlık Hayat Yürüyüşünü tamamla.';

  @override
  String revivalRemainingNotice(int count) {
    return 'Maceralara dönmek için Hayat Yürüyüşünde $count adım daha atmalısın.';
  }

  @override
  String streakFreezeUsedNotice(String remaining) {
    return 'Serin korundu, 1 dondurma hakkı kullanıldı. $remaining';
  }

  @override
  String freezeRemaining(int count) {
    return 'Kalan hak: $count.';
  }

  @override
  String get noFreezesRemaining => 'Hakkın kalmadı.';

  @override
  String streakMilestoneFreeze(int days) {
    return '$days günlük seri! Kilometre taşı ödülün: 1 dondurma hakkı.';
  }

  @override
  String streakMilestoneStockFull(int days) {
    return '$days günlük seri! Kilometre taşına ulaştın (dondurma stoğun zaten dolu).';
  }

  @override
  String streakBonusLostNotice(String rate) {
    return 'Serin kırıldı. Biriktirdiğin +%$rate savaş bonusu sıfırlandı.';
  }

  @override
  String freezeStockFullNotice(int count) {
    return 'Dondurma hakkı stoğun dolu ($count). Para harcanmadı.';
  }

  @override
  String wheelStockFullNotice(int count) {
    return 'Ekstra çark hakkı stoğun dolu ($count). Para harcanmadı.';
  }

  @override
  String get doubleXpAlreadyActiveNotice =>
      '2× XP zaten etkin. Para harcanmadı.';

  @override
  String get storeReincarnationName => 'Reenkarnasyon İksiri';

  @override
  String get storeReincarnationDescription =>
      'Karakterini ve sınıfını bir kez yeniden seçmeni sağlar. Düzenleme tamamlandığında tüketilir.';

  @override
  String get storeDoubleXpName => '2× XP Boost (1 gün)';

  @override
  String get storeDoubleXpDescription =>
      'Gün sonuna kadar kazandığın tüm XP’yi ikiye katlar (adım, düşman ve çark dahil).';

  @override
  String get storeExtraSpinName => 'Ekstra Çark Hakkı';

  @override
  String storeExtraSpinDescription(int count) {
    return 'Günlük hakkın bittikten sonra çarkı bir kez daha çevir. Stok en fazla $count.';
  }

  @override
  String get storeStreakFreezeName => 'Seri Dondurma Hakkı';

  @override
  String storeStreakFreezeDescription(int count) {
    return 'Bir günü kaçırırsan serin otomatik korunur. Stok en fazla $count.';
  }

  @override
  String get statAttack => 'saldırı';

  @override
  String get statDefense => 'savunma';

  @override
  String get statMaxHealth => 'savaş canı';

  @override
  String get statCritChance => 'kritik şansı';

  @override
  String get statCritDamage => 'kritik hasarı';

  @override
  String get statLifeSteal => 'can çalma';

  @override
  String get statDodge => 'sıyrılma';

  @override
  String get statSpeed => 'hız';

  @override
  String get statLuck => 'şans';

  @override
  String get statStepCoin => 'adım parası';

  @override
  String get statStepXp => 'adım XP';

  @override
  String get statWheelXp => 'çark XP';

  @override
  String get statEnemyXp => 'düşman XP';

  @override
  String get statDailyCoinCap => 'günlük coin sınırı';

  @override
  String get statStreakFreezeCap => 'dondurma stoğu';

  @override
  String get statWheelSpinCap => 'çark hakkı stoğu';

  @override
  String get statStreakRelief => 'seri eşiği';

  @override
  String effectAlways(String stat, String value) {
    return '$stat $value';
  }

  @override
  String effectLowHealth(String threshold, String stat, String value) {
    return 'can %$threshold altındayken $stat $value';
  }

  @override
  String effectHighHealth(String threshold, String stat, String value) {
    return 'can %$threshold üstündeyken $stat $value';
  }

  @override
  String effectOnHit(String chance, String stat, String value) {
    return 'vuruşta %$chance ihtimalle $stat $value';
  }

  @override
  String effectOnKill(String stat, String value) {
    return 'düşman yenince $stat $value';
  }

  @override
  String effectUntouchedRounds(String rounds, String stat, String value) {
    return '$rounds tur hasarsız kalınca $stat $value';
  }

  @override
  String effectNightWalk(String stat, String value) {
    return 'gece yapılan savaşlarda $stat $value';
  }

  @override
  String effectStreakActive(String stat, String value) {
    return 'serin ayaktayken $stat $value';
  }

  @override
  String get signatureItemLore =>
      'Kendine özgü bir savaş özelliği taşıyan imzalı eşya.';

  @override
  String get adventurePhaseCombat => 'Savaş fazı';

  @override
  String get adventurePhaseWalk => 'Yürüyüş fazı';

  @override
  String get adventurePhaseCompleted => 'Macera tamamlandı';

  @override
  String get adventurePhaseRevival => 'Hayat Yürüyüşü';

  @override
  String get adventurePhaseRevivalCompleted => 'Hayat Yürüyüşü tamamlandı';

  @override
  String titleLoreAchievement(String name) {
    return '$name, güç kazanılmış bir başarımın kanıtıdır.';
  }

  @override
  String titleLorePurchase(String name) {
    return '$name, önündeki yol için seçilmiş bir işarettir.';
  }

  @override
  String titleLoreWheel(String name) {
    return '$name, çarkın talihli bir dönüşüyle kazanıldı.';
  }

  @override
  String titleLoreMilestone(String name) {
    return '$name, uzun süreli bağlılığı simgeler.';
  }

  @override
  String titleUnlockPurchase(int cost) {
    return 'Mağazadan $cost altına satın al.';
  }

  @override
  String get titleUnlockWheel => 'Günlük çarktan çıkabilir.';

  @override
  String titleUnlockMilestone(int days) {
    return '$days günlük seri kilometre taşı ödülü.';
  }

  @override
  String get titleUnlockPlaying => 'Oynayarak kazanılır.';

  @override
  String titleConditionLevel(int count) {
    return '$count. seviyeye ulaş';
  }

  @override
  String titleConditionSteps(String count) {
    return 'Toplam $count adım at';
  }

  @override
  String titleConditionStreak(int count) {
    return '$count günlük seri yap';
  }

  @override
  String titleConditionEnemies(int count) {
    return '$count düşman devir';
  }

  @override
  String titleConditionAdventures(int count) {
    return '$count macerayı tamamla';
  }

  @override
  String titleConditionItems(int count) {
    return '$count eşya topla';
  }

  @override
  String titleConditionItemLevel(int count) {
    return 'Bir eşyayı Sv. $count yap';
  }

  @override
  String titleConditionWheelSpins(int count) {
    return 'Çarkı $count kez çevir';
  }

  @override
  String titleConditionMerges(int count) {
    return '$count eşya birleştir';
  }

  @override
  String titleConditionCoins(String count) {
    return 'Toplam $count altın kazan';
  }

  @override
  String wheelCoinsLabel(int count) {
    return '+$count altın';
  }

  @override
  String wheelXpLabel(int count) {
    return '+$count XP';
  }

  @override
  String streakStatBonusNotice(
    int day,
    String gain,
    String stat,
    String total,
  ) {
    return '$day. gün: +%$gain $stat (seriden toplam +%$total)';
  }

  @override
  String streakCycleRestarted(String gain) {
    return ' · Döngü başa döndü! Gün başına kazanç yeniden +%$gain.';
  }

  @override
  String upgradeBlockedRarity(String rarity, int cap) {
    return 'Nadirlik sınırı ($rarity: $cap). Daha ileri gitmek için birleştirerek nadirliğini yükseltmelisin.';
  }

  @override
  String upgradeBlockedLevel(int level) {
    return 'Eşya kendi seviyeni geçemez (Sv. $level). Sen yükseldikçe eşyan da yükselebilir.';
  }

  @override
  String coinsRequired(int count) {
    return '$count coin gerekiyor.';
  }

  @override
  String mergeBlockedMaxRarity(String rarity) {
    return '$rarity en üst nadirlik; birleştirilemez.';
  }

  @override
  String mergeBlockedCopies(int required, int available) {
    return 'Birleştirmek için $required adet gerekiyor, elinde $available adet var.';
  }

  @override
  String mergeCompletedNotice(int count, String name, String rarity) {
    return '$count adet $name birleştirildi: artık $rarity, Sv. 1.';
  }

  @override
  String mergeCompletedUnequippedNotice(String name, int count, String rarity) {
    return '$name çıkarıldı ve $count adet birleştirildi: artık $rarity, Sv. 1.';
  }

  @override
  String durationSecondsLong(int count) {
    return '$count saniye';
  }

  @override
  String durationMinutesLong(int count) {
    return '$count dakika';
  }

  @override
  String get shadowDragonName => 'Gölge Ejderhası';

  @override
  String get shadowDragonDescription =>
      '20.000 adım atarak ejderhayı yen, ödülünü kap.';

  @override
  String get youMemberName => 'Sen';

  @override
  String dragonStepsProgress(int current, int target) {
    return '$current / $target adım';
  }

  @override
  String itemUpgradedNotice(String name, int level, int cost) {
    return '$name Sv. $level oldu. -$cost coin.';
  }

  @override
  String get classBat => 'Gece Kanadı';

  @override
  String get classLancer => 'Fırtına Mızrakçısı';

  @override
  String get classNecromancer => 'Ruh Çağıran';

  @override
  String get classOrcRider => 'Bozkır Binicisi';

  @override
  String get leaveAdventureTitle => 'Maceradan ayrılmak istiyor musun?';

  @override
  String get leaveAdventureWalkWarning =>
      'Zaferi kazandın! Bonus yürüyüşü bırakırsan zafer ödüllerin, kazandığın altın ve günlük çark hakkın korunur. Yalnızca bu maceranın bonus altın oranı sona erer. Yeni macera seçmek istiyor musun?';

  @override
  String get leaveAdventureWarning =>
      'Düşmanı yenmeden ayrılırsan macera ilerlemen kaybolur ve bu maceradan ödül kazanamazsın. Günlük adımların ve yürüyüşten kazandıkların korunur. Emin misin?';

  @override
  String get stayInAdventure => 'Maceraya devam et';

  @override
  String get dailyStepsExplanation =>
      'Günlük adımların macera hedefinden ayrıdır. Yürüyüş ödüllerinde günlük üst sınır yoktur.';

  @override
  String get dailyNotificationChannel => 'Günlük seri ve çark';

  @override
  String get streakReminderTitle => 'Kahramanın seni bekliyor!';

  @override
  String get streakReminderBody =>
      'Hadi ama, bugünkü serimizi de tamamlayalım! Biraz yürüyüş ya da bir zafer yeter. Ben burada seni bekliyorum!';

  @override
  String get streakCompleteTitle => 'Günlük seri tamamlandı!';

  @override
  String streakCompleteBody(int days) {
    return 'Serin $days güne ulaştı. Böyle devam et!';
  }

  @override
  String streakCelebrationTitle(int days) {
    return '$days günlük seri!';
  }

  @override
  String get streakCelebrationBody =>
      'Bugün de kendin için bir adım attın. Kahramanın seninle gurur duyuyor. Böyle devam et!';

  @override
  String get dailyContinue => 'Devam et';

  @override
  String get wheelReadyTitle => 'Çark tamir edildi!';

  @override
  String get wheelReadyBody =>
      'Günlük çarkın hazır. Çarkı çevirmek ister misin?';

  @override
  String get wheelReadyNotification =>
      'Günlük çarkın açıldı! Ödülün seni bekliyor.';

  @override
  String get goToWheel => 'Çarka git';

  @override
  String get wheelLater => 'Daha sonra bakacağım';
}
