import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'Rush for Villains'**
  String get appTitle;

  /// No description provided for @language.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get language;

  /// No description provided for @languageDescription.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamanın dilini seç. Değişiklik hemen uygulanır.'**
  String get languageDescription;

  /// No description provided for @languageSystem.
  ///
  /// In tr, this message translates to:
  /// **'Sistem'**
  String get languageSystem;

  /// No description provided for @languageTurkish.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get languageTurkish;

  /// No description provided for @languageEnglish.
  ///
  /// In tr, this message translates to:
  /// **'İngilizce'**
  String get languageEnglish;

  /// No description provided for @fallbackSafetyMessage.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe yedek metin'**
  String get fallbackSafetyMessage;

  /// No description provided for @commonClose.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get commonClose;

  /// No description provided for @scrollToTop.
  ///
  /// In tr, this message translates to:
  /// **'Başa dön'**
  String get scrollToTop;

  /// No description provided for @tavernTitle.
  ///
  /// In tr, this message translates to:
  /// **'Taverna'**
  String get tavernTitle;

  /// No description provided for @tavernComingSoon.
  ///
  /// In tr, this message translates to:
  /// **'Taverna daha açılmadı'**
  String get tavernComingSoon;

  /// No description provided for @tavernPreview.
  ///
  /// In tr, this message translates to:
  /// **'Aşağıdaki takım şimdilik bir önizleme.'**
  String get tavernPreview;

  /// No description provided for @teamWalkingBonusActive.
  ///
  /// In tr, this message translates to:
  /// **'Takım şu anda yan yana yürüyor! Bonus XP aktif.'**
  String get teamWalkingBonusActive;

  /// No description provided for @teamWalkingBonusRequirement.
  ///
  /// In tr, this message translates to:
  /// **'Bonus için tüm üyelerin aynı anda yürümesi gerekir.'**
  String get teamWalkingBonusRequirement;

  /// No description provided for @teamTotalSteps.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Takım Adımı: {count}'**
  String teamTotalSteps(int count);

  /// No description provided for @stepCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} adım'**
  String stepCount(int count);

  /// No description provided for @chooseCompanionEyebrow.
  ///
  /// In tr, this message translates to:
  /// **'YOL ARKADAŞINI SEÇ'**
  String get chooseCompanionEyebrow;

  /// No description provided for @chooseCompanionTitle.
  ///
  /// In tr, this message translates to:
  /// **'İlk maceranda yanında kim yürüsün?'**
  String get chooseCompanionTitle;

  /// No description provided for @chooseCompanionDescription.
  ///
  /// In tr, this message translates to:
  /// **'Seçtiğin yol arkadaşı eğitim boyunca seni yönlendirecek.'**
  String get chooseCompanionDescription;

  /// No description provided for @chooseMyCompanion.
  ///
  /// In tr, this message translates to:
  /// **'Yol Arkadaşımı Seç'**
  String get chooseMyCompanion;

  /// No description provided for @stepsRingLabel.
  ///
  /// In tr, this message translates to:
  /// **'ADIM'**
  String get stepsRingLabel;

  /// No description provided for @stepsTaken.
  ///
  /// In tr, this message translates to:
  /// **'{count} adım attın'**
  String stepsTaken(int count);

  /// No description provided for @dailyGoalSteps.
  ///
  /// In tr, this message translates to:
  /// **'Günlük hedef: {count} adım'**
  String dailyGoalSteps(int count);

  /// No description provided for @completedRounds.
  ///
  /// In tr, this message translates to:
  /// **'{count} tur'**
  String completedRounds(int count);

  /// No description provided for @roundBadge.
  ///
  /// In tr, this message translates to:
  /// **'{count} TUR'**
  String roundBadge(int count);

  /// No description provided for @combatHealth.
  ///
  /// In tr, this message translates to:
  /// **'Savaş Canı'**
  String get combatHealth;

  /// No description provided for @levelNumber.
  ///
  /// In tr, this message translates to:
  /// **'Seviye {level}'**
  String levelNumber(int level);

  /// No description provided for @stepProgress.
  ///
  /// In tr, this message translates to:
  /// **'{steps} / {goal} adım ({distance} km)'**
  String stepProgress(int steps, int goal, String distance);

  /// No description provided for @dismissPet.
  ///
  /// In tr, this message translates to:
  /// **'Peti kapat'**
  String get dismissPet;

  /// No description provided for @summonPet.
  ///
  /// In tr, this message translates to:
  /// **'Peti çağır'**
  String get summonPet;

  /// No description provided for @dayCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} gün'**
  String dayCount(int count);

  /// No description provided for @helloPlayer.
  ///
  /// In tr, this message translates to:
  /// **'Merhaba, {name}'**
  String helloPlayer(String name);

  /// No description provided for @adventure.
  ///
  /// In tr, this message translates to:
  /// **'Macera'**
  String get adventure;

  /// No description provided for @adventureStartPrompt.
  ///
  /// In tr, this message translates to:
  /// **'Günlük hedefini ve düşmanını seçerek maceraya başla.'**
  String get adventureStartPrompt;

  /// No description provided for @enemyWaiting.
  ///
  /// In tr, this message translates to:
  /// **'{name} seni bekliyor. Ritmini koru!'**
  String enemyWaiting(String name);

  /// No description provided for @monsterHealth.
  ///
  /// In tr, this message translates to:
  /// **'Canavar Canı'**
  String get monsterHealth;

  /// No description provided for @dailyWheel.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Çark'**
  String get dailyWheel;

  /// No description provided for @wheelUnlockRequirement.
  ///
  /// In tr, this message translates to:
  /// **'Günlük çarkı açmak için bugün bir düşmanı yen ya da {goal} adım at. Zaferden sonra bonus yürüyüşü bitirmen gerekmez. {remaining} adım kaldı.'**
  String wheelUnlockRequirement(int goal, int remaining);

  /// No description provided for @newWheelPrefix.
  ///
  /// In tr, this message translates to:
  /// **'Yeni çark: '**
  String get newWheelPrefix;

  /// No description provided for @myRewards.
  ///
  /// In tr, this message translates to:
  /// **'Ödüllerim'**
  String get myRewards;

  /// No description provided for @store.
  ///
  /// In tr, this message translates to:
  /// **'Mağaza'**
  String get store;

  /// No description provided for @inventory.
  ///
  /// In tr, this message translates to:
  /// **'Envanter'**
  String get inventory;

  /// No description provided for @stepCounter.
  ///
  /// In tr, this message translates to:
  /// **'Adım Sayacı'**
  String get stepCounter;

  /// No description provided for @openSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarları Aç'**
  String get openSettings;

  /// No description provided for @permissionUnknown.
  ///
  /// In tr, this message translates to:
  /// **'Adım sayacı izni henüz kontrol edilmedi.'**
  String get permissionUnknown;

  /// No description provided for @permissionGranted.
  ///
  /// In tr, this message translates to:
  /// **'Adım sayacı çalışıyor.'**
  String get permissionGranted;

  /// No description provided for @permissionDenied.
  ///
  /// In tr, this message translates to:
  /// **'Adımlarını sayabilmemiz için hareket verisi iznine ihtiyacımız var. İzin vermeden oyunun geri kalanı çalışmaya devam eder, ama adımların kaydedilmez.'**
  String get permissionDenied;

  /// No description provided for @permissionPermanentlyDenied.
  ///
  /// In tr, this message translates to:
  /// **'Hareket verisi izni kapalı. Adımların sayılabilmesi için sistem ayarlarından “Fiziksel aktivite” iznini açman gerekiyor.'**
  String get permissionPermanentlyDenied;

  /// No description provided for @permissionUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Bu cihazda adım sayacı bulunamadı. Oyunun geri kalanı çalışır; adımları demo kontrollerinden simüle edebilirsin.'**
  String get permissionUnavailable;

  /// No description provided for @stepSource.
  ///
  /// In tr, this message translates to:
  /// **'Adım Kaynağı'**
  String get stepSource;

  /// No description provided for @realPedometer.
  ///
  /// In tr, this message translates to:
  /// **'Pedometer (gerçek sensör)'**
  String get realPedometer;

  /// No description provided for @manualStepSource.
  ///
  /// In tr, this message translates to:
  /// **'Manuel (demo kontrolleri)'**
  String get manualStepSource;

  /// No description provided for @realPedometerDescription.
  ///
  /// In tr, this message translates to:
  /// **'Adımlar cihazın sensöründen geliyor. Demo butonları kapalı; açmak için kaynağı manuele al.'**
  String get realPedometerDescription;

  /// No description provided for @manualStepSourceDescription.
  ///
  /// In tr, this message translates to:
  /// **'Adımları buradan simüle edebilirsin.'**
  String get manualStepSourceDescription;

  /// No description provided for @coinsEarnedToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün adımlarından {count} coin kazandın.'**
  String coinsEarnedToday(int count);

  /// No description provided for @xpEarnedToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün adımlarından {count} XP kazandın.'**
  String xpEarnedToday(int count);

  /// No description provided for @stepsPerReward.
  ///
  /// In tr, this message translates to:
  /// **'{count} adım = 1'**
  String stepsPerReward(int count);

  /// No description provided for @dailyStreak.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Seri'**
  String get dailyStreak;

  /// No description provided for @completedToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün tamamlandı'**
  String get completedToday;

  /// No description provided for @pendingToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün bekliyor'**
  String get pendingToday;

  /// No description provided for @streakContinueTomorrow.
  ///
  /// In tr, this message translates to:
  /// **'Seri sürüyor. Yarın bir düşman devir ya da {count} adım at.'**
  String streakContinueTomorrow(int count);

  /// No description provided for @secureStreak.
  ///
  /// In tr, this message translates to:
  /// **'Seriyi güvenceye almak için bir düşman devir — ya da {count} adım daha at.'**
  String secureStreak(int count);

  /// No description provided for @nextMilestone.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki kilometre taşı: {milestone} gün ({remaining} gün kaldı)'**
  String nextMilestone(int milestone, int remaining);

  /// No description provided for @streakBonusSummary.
  ///
  /// In tr, this message translates to:
  /// **'Seri bonusu: +%{rate} savaş statı (profilde stat stat görülür).'**
  String streakBonusSummary(String rate);

  /// No description provided for @streakFreezeSummary.
  ///
  /// In tr, this message translates to:
  /// **'{count} dondurma hakkın var. Bir gün kaçırırsan otomatik kullanılır.'**
  String streakFreezeSummary(int count);

  /// No description provided for @streakEndingSoon.
  ///
  /// In tr, this message translates to:
  /// **'Gün bitmesine {remaining} kaldı, serini kaybetme!'**
  String streakEndingSoon(String remaining);

  /// No description provided for @streakEndingSoonWithBonus.
  ///
  /// In tr, this message translates to:
  /// **'Gün bitmesine {remaining} kaldı, serini kaybetme! Biriken +%{rate} savaş bonusun gider.'**
  String streakEndingSoonWithBonus(String remaining, String rate);

  /// No description provided for @simulateSteps.
  ///
  /// In tr, this message translates to:
  /// **'+{count} adım'**
  String simulateSteps(int count);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In tr, this message translates to:
  /// **'{hours} sa {minutes} dk'**
  String durationHoursMinutes(int hours, int minutes);

  /// No description provided for @durationMinutes.
  ///
  /// In tr, this message translates to:
  /// **'{minutes} dk'**
  String durationMinutes(int minutes);

  /// No description provided for @profile.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @profileDetails.
  ///
  /// In tr, this message translates to:
  /// **'{age} yaş • {weight} kg • {gender}'**
  String profileDetails(int age, int weight, String gender);

  /// No description provided for @useReincarnationPotion.
  ///
  /// In tr, this message translates to:
  /// **'Reenkarnasyon İksirini Kullan'**
  String get useReincarnationPotion;

  /// No description provided for @reincarnationPotionRequired.
  ///
  /// In tr, this message translates to:
  /// **'Reenkarnasyon İksiri Gerekli'**
  String get reincarnationPotionRequired;

  /// No description provided for @equipment.
  ///
  /// In tr, this message translates to:
  /// **'Ekipman'**
  String get equipment;

  /// No description provided for @nothingEquipped.
  ///
  /// In tr, this message translates to:
  /// **'Hiçbir şey kuşanmadın.'**
  String get nothingEquipped;

  /// No description provided for @equippedItemsSummary.
  ///
  /// In tr, this message translates to:
  /// **'{count} item kuşanılı: {names}'**
  String equippedItemsSummary(int count, String names);

  /// No description provided for @openInventory.
  ///
  /// In tr, this message translates to:
  /// **'Envanteri Aç'**
  String get openInventory;

  /// No description provided for @titles.
  ///
  /// In tr, this message translates to:
  /// **'Ünvanlar'**
  String get titles;

  /// No description provided for @earnedTitlesPrompt.
  ///
  /// In tr, this message translates to:
  /// **'{count} ünvan kazandın. Birini tak, adının yanında görünsün.'**
  String earnedTitlesPrompt(int count);

  /// No description provided for @equippedTitleSummary.
  ///
  /// In tr, this message translates to:
  /// **'Takılı: {name} · {count} ünvan kazandın.'**
  String equippedTitleSummary(String name, int count);

  /// No description provided for @blacksmith.
  ///
  /// In tr, this message translates to:
  /// **'Demirci'**
  String get blacksmith;

  /// No description provided for @blacksmithProfileDescription.
  ///
  /// In tr, this message translates to:
  /// **'Silahlarını birleştir, gücüne güç kat.'**
  String get blacksmithProfileDescription;

  /// No description provided for @lastThreeDays.
  ///
  /// In tr, this message translates to:
  /// **'Son 3 Gün'**
  String get lastThreeDays;

  /// No description provided for @viewAllStepRings.
  ///
  /// In tr, this message translates to:
  /// **'Bütün adım halkalarını gör'**
  String get viewAllStepRings;

  /// No description provided for @statistics.
  ///
  /// In tr, this message translates to:
  /// **'İstatistikler'**
  String get statistics;

  /// No description provided for @combatHealthAdventureOnly.
  ///
  /// In tr, this message translates to:
  /// **'Savaş canı yalnızca macera sırasında takip edilir.'**
  String get combatHealthAdventureOnly;

  /// No description provided for @dailyStreakProfile.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Streak'**
  String get dailyStreakProfile;

  /// No description provided for @longestStreak.
  ///
  /// In tr, this message translates to:
  /// **'En uzun seri: {count} gün'**
  String longestStreak(int count);

  /// No description provided for @coin.
  ///
  /// In tr, this message translates to:
  /// **'Coin'**
  String get coin;

  /// No description provided for @stepRings.
  ///
  /// In tr, this message translates to:
  /// **'Adım Halkaları'**
  String get stepRings;

  /// No description provided for @buffStepCoins.
  ///
  /// In tr, this message translates to:
  /// **'adım parası'**
  String get buffStepCoins;

  /// No description provided for @buffStepXp.
  ///
  /// In tr, this message translates to:
  /// **'adım XP'**
  String get buffStepXp;

  /// No description provided for @buffWheelXp.
  ///
  /// In tr, this message translates to:
  /// **'çark XP'**
  String get buffWheelXp;

  /// No description provided for @buffEnemyXp.
  ///
  /// In tr, this message translates to:
  /// **'düşman XP'**
  String get buffEnemyXp;

  /// No description provided for @buffFreezeStock.
  ///
  /// In tr, this message translates to:
  /// **'dondurma stoğu +{count}'**
  String buffFreezeStock(int count);

  /// No description provided for @buffWheelStock.
  ///
  /// In tr, this message translates to:
  /// **'çark stoğu +{count}'**
  String buffWheelStock(int count);

  /// No description provided for @buffStreakThreshold.
  ///
  /// In tr, this message translates to:
  /// **'seri eşiği -{count}'**
  String buffStreakThreshold(int count);

  /// No description provided for @buffRate.
  ///
  /// In tr, this message translates to:
  /// **'{label} +%{rate}'**
  String buffRate(String label, int rate);

  /// No description provided for @wheelAlreadySpun.
  ///
  /// In tr, this message translates to:
  /// **'Bugün çarkı zaten çevirdin.'**
  String get wheelAlreadySpun;

  /// No description provided for @wheelResetCountdownPrefix.
  ///
  /// In tr, this message translates to:
  /// **'Yeni çark hakkına kalan süre: '**
  String get wheelResetCountdownPrefix;

  /// No description provided for @gearsSpinning.
  ///
  /// In tr, this message translates to:
  /// **'Dişliler dönüyor...'**
  String get gearsSpinning;

  /// No description provided for @spinWheel.
  ///
  /// In tr, this message translates to:
  /// **'Çarkı Çevir'**
  String get spinWheel;

  /// No description provided for @extraSpinNotice.
  ///
  /// In tr, this message translates to:
  /// **'Bu çevirme ekstra hakkından düşecek ({count} hak kaldı).'**
  String extraSpinNotice(int count);

  /// No description provided for @titleWon.
  ///
  /// In tr, this message translates to:
  /// **'Ünvan kazandın! 🎉'**
  String get titleWon;

  /// No description provided for @equipTitleFromProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profildeki Ünvanlar ekranından takabilirsin.'**
  String get equipTitleFromProfile;

  /// No description provided for @coinsWon.
  ///
  /// In tr, this message translates to:
  /// **'Kazandın: {count} altın 🎉'**
  String coinsWon(int count);

  /// No description provided for @rewardWon.
  ///
  /// In tr, this message translates to:
  /// **'Kazandın: {reward} 🎉'**
  String rewardWon(String reward);

  /// No description provided for @equipmentWon.
  ///
  /// In tr, this message translates to:
  /// **'Ekipman kazandın! 🎉'**
  String get equipmentWon;

  /// No description provided for @rewardTier.
  ///
  /// In tr, this message translates to:
  /// **'{rarity} ÖDÜL'**
  String rewardTier(String rarity);

  /// No description provided for @titleTier.
  ///
  /// In tr, this message translates to:
  /// **'{rarity} ÜNVAN'**
  String titleTier(String rarity);

  /// No description provided for @goldWonHeader.
  ///
  /// In tr, this message translates to:
  /// **'ALTIN KAZANDIN'**
  String get goldWonHeader;

  /// No description provided for @xpWonHeader.
  ///
  /// In tr, this message translates to:
  /// **'XP KAZANDIN'**
  String get xpWonHeader;

  /// No description provided for @rewardAddedToInventory.
  ///
  /// In tr, this message translates to:
  /// **'Ödül envanterine işlendi'**
  String get rewardAddedToInventory;

  /// No description provided for @chanceMechanismRunning.
  ///
  /// In tr, this message translates to:
  /// **'ŞANS MEKANİZMASI ÇALIŞIYOR'**
  String get chanceMechanismRunning;

  /// No description provided for @wakeTheGears.
  ///
  /// In tr, this message translates to:
  /// **'DİŞLİLERİ UYANDIR'**
  String get wakeTheGears;

  /// No description provided for @equippedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Takılı ünvan'**
  String get equippedTitle;

  /// No description provided for @noEquippedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Şu an takılı ünvanın yok. Bir ünvan tak; adının yanında görünsün ve etkisi açılsın.'**
  String get noEquippedTitle;

  /// No description provided for @unequipTitle.
  ///
  /// In tr, this message translates to:
  /// **'ÜNVANI ÇIKAR'**
  String get unequipTitle;

  /// No description provided for @singleTitleExplanation.
  ///
  /// In tr, this message translates to:
  /// **'Aynı anda yalnızca bir ünvan takılır: ünvan bir kimlik, bir liste değil. Diğerleri sende kalır, istediğin zaman değiştirebilirsin.'**
  String get singleTitleExplanation;

  /// No description provided for @noTitlesForFilters.
  ///
  /// In tr, this message translates to:
  /// **'Bu süzgeçle gösterilecek ünvan yok.'**
  String get noTitlesForFilters;

  /// No description provided for @clearFilters.
  ///
  /// In tr, this message translates to:
  /// **'SÜZGEÇLERİ TEMİZLE'**
  String get clearFilters;

  /// No description provided for @clear.
  ///
  /// In tr, this message translates to:
  /// **'TEMİZLE'**
  String get clear;

  /// No description provided for @titlesEarnedProgress.
  ///
  /// In tr, this message translates to:
  /// **'{owned} / {total} ünvan kazanıldı'**
  String titlesEarnedProgress(int owned, int total);

  /// No description provided for @titleSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Ünvan, hikâye ya da etki ara…'**
  String get titleSearchHint;

  /// No description provided for @filterAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get filterAll;

  /// No description provided for @filterOwned.
  ///
  /// In tr, this message translates to:
  /// **'Sende'**
  String get filterOwned;

  /// No description provided for @filterLocked.
  ///
  /// In tr, this message translates to:
  /// **'Kilitli'**
  String get filterLocked;

  /// No description provided for @anyRarity.
  ///
  /// In tr, this message translates to:
  /// **'Her nadirlik'**
  String get anyRarity;

  /// No description provided for @anySource.
  ///
  /// In tr, this message translates to:
  /// **'Her yol'**
  String get anySource;

  /// No description provided for @sourceAchievement.
  ///
  /// In tr, this message translates to:
  /// **'Başarım'**
  String get sourceAchievement;

  /// No description provided for @sourceStore.
  ///
  /// In tr, this message translates to:
  /// **'Mağaza'**
  String get sourceStore;

  /// No description provided for @sourceWheel.
  ///
  /// In tr, this message translates to:
  /// **'Çark'**
  String get sourceWheel;

  /// No description provided for @sourceMilestone.
  ///
  /// In tr, this message translates to:
  /// **'Kilometre taşı'**
  String get sourceMilestone;

  /// No description provided for @sortDefault.
  ///
  /// In tr, this message translates to:
  /// **'Varsayılan'**
  String get sortDefault;

  /// No description provided for @sortRarity.
  ///
  /// In tr, this message translates to:
  /// **'Nadirlik'**
  String get sortRarity;

  /// No description provided for @sortNearlyThere.
  ///
  /// In tr, this message translates to:
  /// **'Az kaldı'**
  String get sortNearlyThere;

  /// No description provided for @sortName.
  ///
  /// In tr, this message translates to:
  /// **'A→Z'**
  String get sortName;

  /// No description provided for @titlesShown.
  ///
  /// In tr, this message translates to:
  /// **'{count} ünvan listede'**
  String titlesShown(int count);

  /// No description provided for @equippedBadge.
  ///
  /// In tr, this message translates to:
  /// **'TAKILI'**
  String get equippedBadge;

  /// No description provided for @completionPercent.
  ///
  /// In tr, this message translates to:
  /// **'%{percent} tamamlandı'**
  String completionPercent(int percent);

  /// No description provided for @equipAction.
  ///
  /// In tr, this message translates to:
  /// **'TAK'**
  String get equipAction;

  /// No description provided for @showcasePinLimit.
  ///
  /// In tr, this message translates to:
  /// **'Vitrine en fazla {count} ödül sabitlenebilir.'**
  String showcasePinLimit(int count);

  /// No description provided for @allRewards.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Ödüller'**
  String get allRewards;

  /// No description provided for @showcase.
  ///
  /// In tr, this message translates to:
  /// **'Vitrin'**
  String get showcase;

  /// No description provided for @noRewardsForFilters.
  ///
  /// In tr, this message translates to:
  /// **'Bu filtrelerle eşleşen ödül yok.'**
  String get noRewardsForFilters;

  /// No description provided for @rewardSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Ödül veya kazanma şartı ara'**
  String get rewardSearchHint;

  /// No description provided for @clearSearch.
  ///
  /// In tr, this message translates to:
  /// **'Aramayı temizle'**
  String get clearSearch;

  /// No description provided for @category.
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get category;

  /// No description provided for @rarity.
  ///
  /// In tr, this message translates to:
  /// **'Nadirlik'**
  String get rarity;

  /// No description provided for @filterEarned.
  ///
  /// In tr, this message translates to:
  /// **'Kazanılan'**
  String get filterEarned;

  /// No description provided for @noRewardsYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz ödül kazanmadın. İlk düşmanını yenerek veya yürüyüş hedefini tamamlayarak koleksiyonunu başlat.'**
  String get noRewardsYet;

  /// No description provided for @pinnedRewards.
  ///
  /// In tr, this message translates to:
  /// **'Sabitlenenler'**
  String get pinnedRewards;

  /// No description provided for @collection.
  ///
  /// In tr, this message translates to:
  /// **'Koleksiyon'**
  String get collection;

  /// No description provided for @closeRewardDetails.
  ///
  /// In tr, this message translates to:
  /// **'Ödül detayını kapat'**
  String get closeRewardDetails;

  /// No description provided for @rewardsEarnedProgress.
  ///
  /// In tr, this message translates to:
  /// **'{earned} / {total} ödül kazanıldı'**
  String rewardsEarnedProgress(int earned, int total);

  /// No description provided for @earned.
  ///
  /// In tr, this message translates to:
  /// **'Kazanıldı'**
  String get earned;

  /// No description provided for @filterMenuAll.
  ///
  /// In tr, this message translates to:
  /// **'{label}: Tümü'**
  String filterMenuAll(String label);

  /// No description provided for @removeFromShowcase.
  ///
  /// In tr, this message translates to:
  /// **'Vitrinden çıkar'**
  String get removeFromShowcase;

  /// No description provided for @pinToShowcase.
  ///
  /// In tr, this message translates to:
  /// **'Vitrine sabitle'**
  String get pinToShowcase;

  /// No description provided for @rewardEarnedForRequirement.
  ///
  /// In tr, this message translates to:
  /// **'{requirement} şartını tamamladığın için kazanıldı.'**
  String rewardEarnedForRequirement(String requirement);

  /// No description provided for @rewardWithDate.
  ///
  /// In tr, this message translates to:
  /// **'{rarity} Ödül • {date}'**
  String rewardWithDate(String rarity, String date);

  /// No description provided for @progressValue.
  ///
  /// In tr, this message translates to:
  /// **'İlerleme: {progress} / {target}'**
  String progressValue(int progress, int target);

  /// No description provided for @rewardEarnedSemantics.
  ///
  /// In tr, this message translates to:
  /// **'{name}, kazanıldı'**
  String rewardEarnedSemantics(String name);

  /// No description provided for @rewardLockedSemantics.
  ///
  /// In tr, this message translates to:
  /// **'{name}, kilitli, {progress} / {target}'**
  String rewardLockedSemantics(String name, int progress, int target);

  /// No description provided for @dragonLoot.
  ///
  /// In tr, this message translates to:
  /// **'{name} Ganimeti'**
  String dragonLoot(String name);

  /// No description provided for @dragonLootDescription.
  ///
  /// In tr, this message translates to:
  /// **'Ejderhayı yenerek kazanılan ödül.'**
  String get dragonLootDescription;

  /// No description provided for @dragonDefeatedCelebration.
  ///
  /// In tr, this message translates to:
  /// **'Ejderha Yenildi! 🐉'**
  String get dragonDefeatedCelebration;

  /// No description provided for @great.
  ///
  /// In tr, this message translates to:
  /// **'Harika!'**
  String get great;

  /// No description provided for @dragonHealthSteps.
  ///
  /// In tr, this message translates to:
  /// **'Ejderha Canı (adım ile azalır)'**
  String get dragonHealthSteps;

  /// No description provided for @dragonDefeated.
  ///
  /// In tr, this message translates to:
  /// **'Ejderha yenildi!'**
  String get dragonDefeated;

  /// No description provided for @stepsRemaining.
  ///
  /// In tr, this message translates to:
  /// **'{count} adım daha kaldı.'**
  String stepsRemaining(int count);

  /// No description provided for @rewardRarityExplanation.
  ///
  /// In tr, this message translates to:
  /// **'Ödül Nadirliği Nasıl Belirlenir?'**
  String get rewardRarityExplanation;

  /// No description provided for @rarityBelow75.
  ///
  /// In tr, this message translates to:
  /// **'< %75 hedef'**
  String get rarityBelow75;

  /// No description provided for @rarity75To99.
  ///
  /// In tr, this message translates to:
  /// **'%75 - %99 hedef'**
  String get rarity75To99;

  /// No description provided for @rarityMeetGoal.
  ///
  /// In tr, this message translates to:
  /// **'Hedefi tuttur'**
  String get rarityMeetGoal;

  /// No description provided for @rarity125.
  ///
  /// In tr, this message translates to:
  /// **'Hedefin %125\'i'**
  String get rarity125;

  /// No description provided for @rarity150.
  ///
  /// In tr, this message translates to:
  /// **'Hedefin %150\'si'**
  String get rarity150;

  /// No description provided for @rewardClaimed.
  ///
  /// In tr, this message translates to:
  /// **'Ödül Alındı'**
  String get rewardClaimed;

  /// No description provided for @claimReward.
  ///
  /// In tr, this message translates to:
  /// **'Ödülü Talep Et'**
  String get claimReward;

  /// No description provided for @home.
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfa'**
  String get home;

  /// No description provided for @characterCatalogEmpty.
  ///
  /// In tr, this message translates to:
  /// **'All_Assets avatar klasöründe karakter bulunamadı.'**
  String get characterCatalogEmpty;

  /// No description provided for @characterCatalogLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Karakter dosyaları yüklenemedi.'**
  String get characterCatalogLoadFailed;

  /// No description provided for @heroNameTooShort.
  ///
  /// In tr, this message translates to:
  /// **'Kahramanın adı en az 2 karakter olmalı.'**
  String get heroNameTooShort;

  /// No description provided for @fateSecondLine.
  ///
  /// In tr, this message translates to:
  /// **'KADERİNİN İKİNCİ SATIRI'**
  String get fateSecondLine;

  /// No description provided for @ageQuestion.
  ///
  /// In tr, this message translates to:
  /// **'Kaç yaşındasın?'**
  String get ageQuestion;

  /// No description provided for @ageDescription.
  ///
  /// In tr, this message translates to:
  /// **'Yaş, kahramanının hikâyesine yön verir.'**
  String get ageDescription;

  /// No description provided for @ageSuffix.
  ///
  /// In tr, this message translates to:
  /// **'yaş'**
  String get ageSuffix;

  /// No description provided for @defineBody.
  ///
  /// In tr, this message translates to:
  /// **'BEDENİNİ TANIMLA'**
  String get defineBody;

  /// No description provided for @weightQuestion.
  ///
  /// In tr, this message translates to:
  /// **'Kilon kaç?'**
  String get weightQuestion;

  /// No description provided for @weightDescription.
  ///
  /// In tr, this message translates to:
  /// **'Bu bilgi karakter profilinin bir parçası olacak.'**
  String get weightDescription;

  /// No description provided for @fateFirstLine.
  ///
  /// In tr, this message translates to:
  /// **'KADERİNİN İLK SATIRI'**
  String get fateFirstLine;

  /// No description provided for @nameQuestion.
  ///
  /// In tr, this message translates to:
  /// **'Sana nasıl hitap edelim?'**
  String get nameQuestion;

  /// No description provided for @nameDescription.
  ///
  /// In tr, this message translates to:
  /// **'Bu isim düşmanlarının hafızasına kazınacak.'**
  String get nameDescription;

  /// No description provided for @heroNameHint.
  ///
  /// In tr, this message translates to:
  /// **'Kahramanının adı'**
  String get heroNameHint;

  /// No description provided for @genderFemale.
  ///
  /// In tr, this message translates to:
  /// **'Kadın'**
  String get genderFemale;

  /// No description provided for @genderMale.
  ///
  /// In tr, this message translates to:
  /// **'Erkek'**
  String get genderMale;

  /// No description provided for @genderOther.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get genderOther;

  /// No description provided for @defineIdentity.
  ///
  /// In tr, this message translates to:
  /// **'KİMLİĞİNİ BELİRLE'**
  String get defineIdentity;

  /// No description provided for @identityQuestion.
  ///
  /// In tr, this message translates to:
  /// **'Kahramanın kim?'**
  String get identityQuestion;

  /// No description provided for @identityDescription.
  ///
  /// In tr, this message translates to:
  /// **'Seni en iyi ifade eden seçeneği seç.'**
  String get identityDescription;

  /// No description provided for @choosePower.
  ///
  /// In tr, this message translates to:
  /// **'GÜCÜNÜ SEÇ'**
  String get choosePower;

  /// No description provided for @classQuestion.
  ///
  /// In tr, this message translates to:
  /// **'Hangi sınıfa aitsin?'**
  String get classQuestion;

  /// No description provided for @classDescription.
  ///
  /// In tr, this message translates to:
  /// **'Yürüyüşünü ve savaş yolunu birlikte seç.'**
  String get classDescription;

  /// No description provided for @classSelectionHint.
  ///
  /// In tr, this message translates to:
  /// **'Devam etmek için bir sınıfa dokun, tanıt ekranında incele ve “BU SINIFI SEÇ”e bas.'**
  String get classSelectionHint;

  /// No description provided for @fateSealed.
  ///
  /// In tr, this message translates to:
  /// **'KADERİN MÜHÜRLENİYOR'**
  String get fateSealed;

  /// No description provided for @heroReadyQuestion.
  ///
  /// In tr, this message translates to:
  /// **'{name}, hazır mısın?'**
  String heroReadyQuestion(String name);

  /// No description provided for @confirmHeroDescription.
  ///
  /// In tr, this message translates to:
  /// **'Seçimlerini onayla ve Rush for Villains dünyasına adım at.'**
  String get confirmHeroDescription;

  /// No description provided for @scrollToChangeValue.
  ///
  /// In tr, this message translates to:
  /// **'Değeri değiştirmek için yukarı veya aşağı kaydır'**
  String get scrollToChangeValue;

  /// No description provided for @backToClassList.
  ///
  /// In tr, this message translates to:
  /// **'Sınıf listesine dön'**
  String get backToClassList;

  /// No description provided for @usableItemTypes.
  ///
  /// In tr, this message translates to:
  /// **'KULLANABİLDİĞİ EŞYA TÜRLERİ'**
  String get usableItemTypes;

  /// No description provided for @chooseThisClass.
  ///
  /// In tr, this message translates to:
  /// **'BU SINIFI SEÇ'**
  String get chooseThisClass;

  /// No description provided for @back.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get back;

  /// No description provided for @sealChanges.
  ///
  /// In tr, this message translates to:
  /// **'DEĞİŞİKLİKLERİ MÜHÜRLE'**
  String get sealChanges;

  /// No description provided for @startAdventureAction.
  ///
  /// In tr, this message translates to:
  /// **'MACERAYA BAŞLA'**
  String get startAdventureAction;

  /// No description provided for @continueAction.
  ///
  /// In tr, this message translates to:
  /// **'DEVAM ET'**
  String get continueAction;

  /// No description provided for @retry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get retry;

  /// No description provided for @stockRights.
  ///
  /// In tr, this message translates to:
  /// **'Elinde {count} hak var'**
  String stockRights(int count);

  /// No description provided for @activeUntilEndOfDay.
  ///
  /// In tr, this message translates to:
  /// **'Şu an etkin — gün sonuna kadar'**
  String get activeUntilEndOfDay;

  /// No description provided for @titleStore.
  ///
  /// In tr, this message translates to:
  /// **'Ünvan Mağazası'**
  String get titleStore;

  /// No description provided for @noTitlesForSale.
  ///
  /// In tr, this message translates to:
  /// **'Şu anda mağazada satılık ünvan bulunmuyor.'**
  String get noTitlesForSale;

  /// No description provided for @firstWeapon.
  ///
  /// In tr, this message translates to:
  /// **'İLK SİLAHIN'**
  String get firstWeapon;

  /// No description provided for @companionChoseWeapon.
  ///
  /// In tr, this message translates to:
  /// **'Yol arkadaşın bu silahı senin için seçti.'**
  String get companionChoseWeapon;

  /// No description provided for @upgrades.
  ///
  /// In tr, this message translates to:
  /// **'Yükseltmeler'**
  String get upgrades;

  /// No description provided for @noClassEquipment.
  ///
  /// In tr, this message translates to:
  /// **'Sınıfın için ekipman bulunamadı.'**
  String get noClassEquipment;

  /// No description provided for @affordableOnly.
  ///
  /// In tr, this message translates to:
  /// **'Alabileceklerim'**
  String get affordableOnly;

  /// No description provided for @equipmentCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} ekipman'**
  String equipmentCount(int count);

  /// No description provided for @noEquipmentForFilters.
  ///
  /// In tr, this message translates to:
  /// **'Bu süzgeçle gösterilecek ekipman yok. Yürümeye devam et; seviyen yükseldikçe yenileri açılır.'**
  String get noEquipmentForFilters;

  /// No description provided for @adventureStore.
  ///
  /// In tr, this message translates to:
  /// **'Macera Mağazası'**
  String get adventureStore;

  /// No description provided for @titleStoreExplanation.
  ///
  /// In tr, this message translates to:
  /// **'Ünvan bir kimlik: adının yanında görünür ve kendine has bir etki taşır. Aynı anda yalnızca birini takarsın; hepsi sende kalır.'**
  String get titleStoreExplanation;

  /// No description provided for @titleStoreSummary.
  ///
  /// In tr, this message translates to:
  /// **'{owned} / {total} ünvan sende · {shown} tanesi listede'**
  String titleStoreSummary(int owned, int total, int shown);

  /// No description provided for @hideOwned.
  ///
  /// In tr, this message translates to:
  /// **'Sendekileri gizle'**
  String get hideOwned;

  /// No description provided for @noStoreTitlesForFilters.
  ///
  /// In tr, this message translates to:
  /// **'Bu süzgeçle gösterilecek ünvan yok. Süzgeci gevşet ya da biraz daha altın biriktir.'**
  String get noStoreTitlesForFilters;

  /// No description provided for @titleAlreadyOwned.
  ///
  /// In tr, this message translates to:
  /// **'“{name}” ünvanı zaten sende. Profilden takabilirsin.'**
  String titleAlreadyOwned(String name);

  /// No description provided for @moreGoldNeeded.
  ///
  /// In tr, this message translates to:
  /// **'{count} altın daha gerekiyor.'**
  String moreGoldNeeded(int count);

  /// No description provided for @ownedUpper.
  ///
  /// In tr, this message translates to:
  /// **'SENDE'**
  String get ownedUpper;

  /// No description provided for @goldPrice.
  ///
  /// In tr, this message translates to:
  /// **'{count} ALTIN'**
  String goldPrice(int count);

  /// No description provided for @owned.
  ///
  /// In tr, this message translates to:
  /// **'Sahipsin'**
  String get owned;

  /// No description provided for @itemAlreadyOwned.
  ///
  /// In tr, this message translates to:
  /// **'{name} zaten sende.'**
  String itemAlreadyOwned(String name);

  /// No description provided for @itemCoinsNeeded.
  ///
  /// In tr, this message translates to:
  /// **'{name} için {count} coin daha gerekiyor.'**
  String itemCoinsNeeded(String name, int count);

  /// No description provided for @maxRarityInvestment.
  ///
  /// In tr, this message translates to:
  /// **'Yükseltilebilir · Maks Sv. {level} · en üst nadirlik'**
  String maxRarityInvestment(int level);

  /// No description provided for @mergeInvestment.
  ///
  /// In tr, this message translates to:
  /// **'Yükseltilebilir · Maks Sv. {level} · {count} tanesini birleştirince {rarity} olur'**
  String mergeInvestment(int level, int count, String rarity);

  /// No description provided for @itemLevelNeeded.
  ///
  /// In tr, this message translates to:
  /// **'{name} için {required}. seviye gerekiyor. Şu an {current}. seviyedesin.'**
  String itemLevelNeeded(String name, int required, int current);

  /// No description provided for @levelShort.
  ///
  /// In tr, this message translates to:
  /// **'Sv. {level}'**
  String levelShort(int level);

  /// No description provided for @ownedCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} adet'**
  String ownedCount(int count);

  /// No description provided for @sellItemQuestion.
  ///
  /// In tr, this message translates to:
  /// **'Item satılsın mı?'**
  String get sellItemQuestion;

  /// No description provided for @sellItemWarning.
  ///
  /// In tr, this message translates to:
  /// **'{name}{levelSuffix} envanterinden çıkacak ve +{value} coin kazanacaksın. Bu işlem geri alınamaz; itemi tekrar istersen {cost} coin ödemen gerekir ve yükseltmelerini baştan yapman gerekir.'**
  String sellItemWarning(String name, String levelSuffix, int value, int cost);

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get cancel;

  /// No description provided for @sellWithValue.
  ///
  /// In tr, this message translates to:
  /// **'Sat (+{value})'**
  String sellWithValue(int value);

  /// No description provided for @emptySlotPrompt.
  ///
  /// In tr, this message translates to:
  /// **'{category} slotu boş. Aşağıdan bir item seç.'**
  String emptySlotPrompt(String category);

  /// No description provided for @noItemsOwned.
  ///
  /// In tr, this message translates to:
  /// **'Henüz item\'in yok. Mağazadan ekipman alabilir ya da günlük çarkı çevirebilirsin.'**
  String get noItemsOwned;

  /// No description provided for @usableOnly.
  ///
  /// In tr, this message translates to:
  /// **'Kuşanabildiklerim'**
  String get usableOnly;

  /// No description provided for @noInventoryItemsForFilters.
  ///
  /// In tr, this message translates to:
  /// **'Bu süzgeçle gösterilecek item yok.'**
  String get noInventoryItemsForFilters;

  /// No description provided for @tutorialWeaponMissing.
  ///
  /// In tr, this message translates to:
  /// **'Eğitim silahı bulunamadı.'**
  String get tutorialWeaponMissing;

  /// No description provided for @firstWeaponTitle.
  ///
  /// In tr, this message translates to:
  /// **'İlk silahın'**
  String get firstWeaponTitle;

  /// No description provided for @equippedAction.
  ///
  /// In tr, this message translates to:
  /// **'Kuşanıldı'**
  String get equippedAction;

  /// No description provided for @equip.
  ///
  /// In tr, this message translates to:
  /// **'Kuşan'**
  String get equip;

  /// No description provided for @noEquippedItems.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kuşanılmış eşya yok'**
  String get noEquippedItems;

  /// No description provided for @noEffect.
  ///
  /// In tr, this message translates to:
  /// **'Etki yok'**
  String get noEffect;

  /// No description provided for @characterPower.
  ///
  /// In tr, this message translates to:
  /// **'Karakter Gücü'**
  String get characterPower;

  /// No description provided for @filledSlots.
  ///
  /// In tr, this message translates to:
  /// **'{filled} / {total} slot dolu'**
  String filledSlots(int filled, int total);

  /// No description provided for @combatStats.
  ///
  /// In tr, this message translates to:
  /// **'Savaş İstatistikleri'**
  String get combatStats;

  /// No description provided for @combatStatsDescription.
  ///
  /// In tr, this message translates to:
  /// **'Maceradaki savaşta kullanılır: taban seviyeden, bonus ekipman ve seriden gelir.'**
  String get combatStatsDescription;

  /// No description provided for @conditionalEffects.
  ///
  /// In tr, this message translates to:
  /// **'Koşullu Etkiler'**
  String get conditionalEffects;

  /// No description provided for @columnBase.
  ///
  /// In tr, this message translates to:
  /// **'TABAN'**
  String get columnBase;

  /// No description provided for @columnEquipment.
  ///
  /// In tr, this message translates to:
  /// **'EKİPMAN'**
  String get columnEquipment;

  /// No description provided for @columnBonus.
  ///
  /// In tr, this message translates to:
  /// **'BONUS'**
  String get columnBonus;

  /// No description provided for @columnTotal.
  ///
  /// In tr, this message translates to:
  /// **'TOPLAM'**
  String get columnTotal;

  /// No description provided for @columnShare.
  ///
  /// In tr, this message translates to:
  /// **'PAY'**
  String get columnShare;

  /// No description provided for @columnStatus.
  ///
  /// In tr, this message translates to:
  /// **'DURUM'**
  String get columnStatus;

  /// No description provided for @streakBonus.
  ///
  /// In tr, this message translates to:
  /// **'Seri Bonusu'**
  String get streakBonus;

  /// No description provided for @streakBonusTotal.
  ///
  /// In tr, this message translates to:
  /// **'toplam +%{rate}'**
  String streakBonusTotal(String rate);

  /// No description provided for @streakCombatGrowth.
  ///
  /// In tr, this message translates to:
  /// **'{days} günlük serin savaş statlarını büyüttü. Seri kırılırsa tamamı gider.'**
  String streakCombatGrowth(int days);

  /// No description provided for @streakCurrentRate.
  ///
  /// In tr, this message translates to:
  /// **'Şu an: gün başına +%{rate}. Kazanç her {tier} günde bir azalır, {cycle}. günden sonra başa döner.'**
  String streakCurrentRate(String rate, int tier, int cycle);

  /// No description provided for @equippedItems.
  ///
  /// In tr, this message translates to:
  /// **'Kuşanılanlar'**
  String get equippedItems;

  /// No description provided for @empty.
  ///
  /// In tr, this message translates to:
  /// **'Boş'**
  String get empty;

  /// No description provided for @equippedTag.
  ///
  /// In tr, this message translates to:
  /// **'Kuşanılı'**
  String get equippedTag;

  /// No description provided for @levelRequirement.
  ///
  /// In tr, this message translates to:
  /// **'{required}. seviye gerekiyor. Şu an {current}. seviyedesin.'**
  String levelRequirement(int required, int current);

  /// No description provided for @effects.
  ///
  /// In tr, this message translates to:
  /// **'Etkiler'**
  String get effects;

  /// No description provided for @dormantCombatEffects.
  ///
  /// In tr, this message translates to:
  /// **'Soluk satırlar savaş istatistikleri; savaş sistemiyle birlikte etkinleşecek.'**
  String get dormantCombatEffects;

  /// No description provided for @equipIntoEmptySlot.
  ///
  /// In tr, this message translates to:
  /// **'{category} slotu boş — kuşanınca:'**
  String equipIntoEmptySlot(String category);

  /// No description provided for @replaceEquippedItem.
  ///
  /// In tr, this message translates to:
  /// **'{name} yerine kuşanınca:'**
  String replaceEquippedItem(String name);

  /// No description provided for @noNumericDifference.
  ///
  /// In tr, this message translates to:
  /// **'Sayısal olarak fark yok.'**
  String get noNumericDifference;

  /// No description provided for @unequip.
  ///
  /// In tr, this message translates to:
  /// **'Çıkar'**
  String get unequip;

  /// No description provided for @sellValue.
  ///
  /// In tr, this message translates to:
  /// **'Sat +{value}'**
  String sellValue(int value);

  /// No description provided for @blacksmithLevel.
  ///
  /// In tr, this message translates to:
  /// **'Demirci — Sv. {level} / {cap}'**
  String blacksmithLevel(int level, int cap);

  /// No description provided for @upgradeCombatOnly.
  ///
  /// In tr, this message translates to:
  /// **'Yükseltmek yalnızca savaş istatistiklerini büyütür; ekonomi bonusları sabit kalır.'**
  String get upgradeCombatOnly;

  /// No description provided for @nextLevelPreview.
  ///
  /// In tr, this message translates to:
  /// **'Sv. {level}: {preview}'**
  String nextLevelPreview(int level, String preview);

  /// No description provided for @upgradeToLevel.
  ///
  /// In tr, this message translates to:
  /// **'Sv. {level}\'e yükselt — {cost} coin'**
  String upgradeToLevel(int level, int cost);

  /// No description provided for @cannotUpgrade.
  ///
  /// In tr, this message translates to:
  /// **'Yükseltilemiyor'**
  String get cannotUpgrade;

  /// No description provided for @emptyForge.
  ///
  /// In tr, this message translates to:
  /// **'Örs boş. Mağazadan ekipman aldığında burada yükseltebilir, aynı eşyadan birkaç adet biriktirince birleştirebilirsin.'**
  String get emptyForge;

  /// No description provided for @mergeQuestion.
  ///
  /// In tr, this message translates to:
  /// **'Birleştirilsin mi?'**
  String get mergeQuestion;

  /// No description provided for @mergeCostWarning.
  ///
  /// In tr, this message translates to:
  /// **'{count} adet {name} ve {cost} coin harcanacak.'**
  String mergeCostWarning(int count, String name, int cost);

  /// No description provided for @mergeResult.
  ///
  /// In tr, this message translates to:
  /// **'Karşılığında 1 adet {rarity} {name} alacaksın — Sv. 1, nadirlik tavanı {cap}.'**
  String mergeResult(String rarity, String name, int cap);

  /// No description provided for @consumedItemLevels.
  ///
  /// In tr, this message translates to:
  /// **'Harcanan eşyaların seviyeleri: {levels}.'**
  String consumedItemLevels(String levels);

  /// No description provided for @equippedItemConsumed.
  ///
  /// In tr, this message translates to:
  /// **'Kuşanılı bir adet harcanacak; önce çıkarılacak.'**
  String get equippedItemConsumed;

  /// No description provided for @irreversibleAction.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem geri alınamaz.'**
  String get irreversibleAction;

  /// No description provided for @merge.
  ///
  /// In tr, this message translates to:
  /// **'Birleştir'**
  String get merge;

  /// No description provided for @upgradeBestItem.
  ///
  /// In tr, this message translates to:
  /// **'Yükselt — Sv. {level} / {cap}{suffix}'**
  String upgradeBestItem(int level, int cap, String suffix);

  /// No description provided for @mostAdvancedSuffix.
  ///
  /// In tr, this message translates to:
  /// **' (en gelişmiş adet)'**
  String get mostAdvancedSuffix;

  /// No description provided for @cannotUpgradeNow.
  ///
  /// In tr, this message translates to:
  /// **'Şu an yükseltilemiyor.'**
  String get cannotUpgradeNow;

  /// No description provided for @mergeHighestRarity.
  ///
  /// In tr, this message translates to:
  /// **'Birleştirme — en üst nadirlik'**
  String get mergeHighestRarity;

  /// No description provided for @cannotMerge.
  ///
  /// In tr, this message translates to:
  /// **'Birleştirilemiyor'**
  String get cannotMerge;

  /// No description provided for @mergeProgressTitle.
  ///
  /// In tr, this message translates to:
  /// **'Birleştirme — {owned}/{required} adet → {rarity}'**
  String mergeProgressTitle(int owned, int required, String rarity);

  /// No description provided for @mergeResetDetail.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç Sv. 1\'e döner, nadirlik tavanı {cap} olur'**
  String mergeResetDetail(int cap);

  /// No description provided for @mergeWithCost.
  ///
  /// In tr, this message translates to:
  /// **'Birleştir — {cost} coin'**
  String mergeWithCost(int cost);

  /// No description provided for @cannotMergeNow.
  ///
  /// In tr, this message translates to:
  /// **'Şu an birleştirilemiyor.'**
  String get cannotMergeNow;

  /// No description provided for @chooseDailyGoal.
  ///
  /// In tr, this message translates to:
  /// **'GÜNLÜK HEDEFİNİ SEÇ'**
  String get chooseDailyGoal;

  /// No description provided for @goalPickerHint.
  ///
  /// In tr, this message translates to:
  /// **'500 adımlık aralıklarla yukarı veya aşağı kaydır'**
  String get goalPickerHint;

  /// No description provided for @selectStepGoal.
  ///
  /// In tr, this message translates to:
  /// **'{count} ADIMI SEÇ'**
  String selectStepGoal(String count);

  /// No description provided for @roundNumberUpper.
  ///
  /// In tr, this message translates to:
  /// **'{round}. ROUND'**
  String roundNumberUpper(int round);

  /// No description provided for @victoryUpper.
  ///
  /// In tr, this message translates to:
  /// **'ZAFER!'**
  String get victoryUpper;

  /// No description provided for @roundYoursUpper.
  ///
  /// In tr, this message translates to:
  /// **'ROUND SENİN!'**
  String get roundYoursUpper;

  /// No description provided for @enemyDefeatedNamed.
  ///
  /// In tr, this message translates to:
  /// **'{name} yenildi!'**
  String enemyDefeatedNamed(String name);

  /// No description provided for @roundCompletedEarly.
  ///
  /// In tr, this message translates to:
  /// **'Round için gereken adımları tamamladın'**
  String get roundCompletedEarly;

  /// No description provided for @speedRewardSummary.
  ///
  /// In tr, this message translates to:
  /// **'{rounds} round · {steps} adım — savaş verimi ×{multiplier}'**
  String speedRewardSummary(int rounds, String steps, String multiplier);

  /// No description provided for @walkPhaseRemainingNotice.
  ///
  /// In tr, this message translates to:
  /// **'Macera bitmedi: {steps} adımlık yürüyüş fazı kaldı. Bu fazda {rate} adım = 1 altın.'**
  String walkPhaseRemainingNotice(String steps, int rate);

  /// No description provided for @hitUpper.
  ///
  /// In tr, this message translates to:
  /// **'VURUŞ!'**
  String get hitUpper;

  /// No description provided for @healthDamageUpper.
  ///
  /// In tr, this message translates to:
  /// **'-{count} CAN'**
  String healthDamageUpper(int count);

  /// No description provided for @continueWalkingUpper.
  ///
  /// In tr, this message translates to:
  /// **'YÜRÜYÜŞE DEVAM ET'**
  String get continueWalkingUpper;

  /// No description provided for @chooseNewAdventureUpper.
  ///
  /// In tr, this message translates to:
  /// **'YENİ MACERA SEÇ'**
  String get chooseNewAdventureUpper;

  /// No description provided for @finalBlow.
  ///
  /// In tr, this message translates to:
  /// **'Son darbe!'**
  String get finalBlow;

  /// No description provided for @attackSequence.
  ///
  /// In tr, this message translates to:
  /// **'Saldırı {current} / {total}'**
  String attackSequence(int current, int total);

  /// No description provided for @enemyRoundUpper.
  ///
  /// In tr, this message translates to:
  /// **'DÜŞMAN SALDIRDI!'**
  String get enemyRoundUpper;

  /// No description provided for @enemyKilledBeforeCounter.
  ///
  /// In tr, this message translates to:
  /// **'{enemy}, sen vuramadan seni öldürdü.'**
  String enemyKilledBeforeCounter(String enemy);

  /// No description provided for @restTime.
  ///
  /// In tr, this message translates to:
  /// **'Dinlenme zamanı'**
  String get restTime;

  /// No description provided for @revivalIntro.
  ///
  /// In tr, this message translates to:
  /// **'{name} karşısında canın tükendi. Yeni maceralara açılmak için 500 adımlık Hayat Yürüyüşünü tamamlamalısın.'**
  String revivalIntro(String name);

  /// No description provided for @revivalNoXp.
  ///
  /// In tr, this message translates to:
  /// **'Bu özel yürüyüş boyunca XP kazanılmaz; yürümeye devam ettiğinde yeniden doğarsın.'**
  String get revivalNoXp;

  /// No description provided for @startLifeWalk.
  ///
  /// In tr, this message translates to:
  /// **'Hayat Yürüyüşüne Çık'**
  String get startLifeWalk;

  /// No description provided for @lifeWalk.
  ///
  /// In tr, this message translates to:
  /// **'Hayat Yürüyüşü'**
  String get lifeWalk;

  /// No description provided for @lifeWalkDescription.
  ///
  /// In tr, this message translates to:
  /// **'Durma; yeniden doğmak için düşük tempoda yürümeye devam et. Bu 500 adım XP kazandırmaz.'**
  String get lifeWalkDescription;

  /// No description provided for @revived.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden doğdun!'**
  String get revived;

  /// No description provided for @revivalCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Hayat Yürüyüşünü tamamladın. Bu yürüyüş XP vermedi; şimdi yeniden maceraya açılabilirsin.'**
  String get revivalCompleted;

  /// No description provided for @backToAdventures.
  ///
  /// In tr, this message translates to:
  /// **'Maceralara Dön'**
  String get backToAdventures;

  /// No description provided for @extraGold.
  ///
  /// In tr, this message translates to:
  /// **'+{count} EK ALTIN'**
  String extraGold(int count);

  /// No description provided for @congratulations.
  ///
  /// In tr, this message translates to:
  /// **'Tebrikler!'**
  String get congratulations;

  /// No description provided for @xpWonNextAdventure.
  ///
  /// In tr, this message translates to:
  /// **'{xp} XP kazandın. Yeni bir macera seni bekliyor.'**
  String xpWonNextAdventure(int xp);

  /// No description provided for @chooseNewAdventure.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Macera Seç'**
  String get chooseNewAdventure;

  /// No description provided for @chooseTodaysAdventure.
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü maceranı seç'**
  String get chooseTodaysAdventure;

  /// No description provided for @adventureSelectionDescription.
  ///
  /// In tr, this message translates to:
  /// **'Hedefini belirle, meydan okuyabileceğin düşmanı seç ve yürüyüşe başla.'**
  String get adventureSelectionDescription;

  /// No description provided for @chooseEnemy.
  ///
  /// In tr, this message translates to:
  /// **'Düşmanını seç'**
  String get chooseEnemy;

  /// No description provided for @tapEnemyForDetails.
  ///
  /// In tr, this message translates to:
  /// **'Düşmanın ayrıntılarını görmek ve macerayı başlatmak için karta dokun.'**
  String get tapEnemyForDetails;

  /// No description provided for @victoryIsYours.
  ///
  /// In tr, this message translates to:
  /// **'Zafer senin'**
  String get victoryIsYours;

  /// No description provided for @enemyFelledRoadYours.
  ///
  /// In tr, this message translates to:
  /// **'{name} devrildi. Yolun geri kalanı senin.'**
  String enemyFelledRoadYours(String name);

  /// No description provided for @walkPhaseRate.
  ///
  /// In tr, this message translates to:
  /// **'Yürüyüş fazı · {rate} adım = 1 altın'**
  String walkPhaseRate(int rate);

  /// No description provided for @walkProgressRemaining.
  ///
  /// In tr, this message translates to:
  /// **'{current} / {target} adım — kalan {remaining}'**
  String walkProgressRemaining(String current, String target, String remaining);

  /// No description provided for @walkPhaseExplanation.
  ///
  /// In tr, this message translates to:
  /// **'Macera adım taahhüdün dolunca biter. O ana kadar attığın her adım normalden değerli: oran {normal} yerine {bonus}. Faz bitince oran {normal} adım = 1 altına döner. XP oranı değişmez.'**
  String walkPhaseExplanation(int normal, int bonus);

  /// No description provided for @victorySummary.
  ///
  /// In tr, this message translates to:
  /// **'Zafer özeti'**
  String get victorySummary;

  /// No description provided for @streakAndWheelSecured.
  ///
  /// In tr, this message translates to:
  /// **'Serin ve çark hakkın bu zaferle güvence altında.'**
  String get streakAndWheelSecured;

  /// No description provided for @abandonWalkUpper.
  ///
  /// In tr, this message translates to:
  /// **'YÜRÜYÜŞÜ BIRAK, YENİ MACERA SEÇ'**
  String get abandonWalkUpper;

  /// No description provided for @abandonWalkWarning.
  ///
  /// In tr, this message translates to:
  /// **'Bırakırsan bonuslu oran biter; zafer ödülün sende kalır.'**
  String get abandonWalkWarning;

  /// No description provided for @defeated.
  ///
  /// In tr, this message translates to:
  /// **'Yenildi'**
  String get defeated;

  /// No description provided for @waitingForYou.
  ///
  /// In tr, this message translates to:
  /// **'Seni bekliyor'**
  String get waitingForYou;

  /// No description provided for @missionMessage.
  ///
  /// In tr, this message translates to:
  /// **'Görev mesajın'**
  String get missionMessage;

  /// No description provided for @adventureStatus.
  ///
  /// In tr, this message translates to:
  /// **'Macera durumu'**
  String get adventureStatus;

  /// No description provided for @yourHealth.
  ///
  /// In tr, this message translates to:
  /// **'Senin Canın'**
  String get yourHealth;

  /// No description provided for @dailySteps.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Adım'**
  String get dailySteps;

  /// No description provided for @victoryRewardXp.
  ///
  /// In tr, this message translates to:
  /// **'Zafer ödülü: {xp} XP'**
  String victoryRewardXp(int xp);

  /// No description provided for @leaveAdventure.
  ///
  /// In tr, this message translates to:
  /// **'Maceradan Ayrıl'**
  String get leaveAdventure;

  /// No description provided for @roundProgress.
  ///
  /// In tr, this message translates to:
  /// **'Round {current}/{total}'**
  String roundProgress(int current, int total);

  /// No description provided for @chooseGoalUpper.
  ///
  /// In tr, this message translates to:
  /// **'HEDEF SEÇ'**
  String get chooseGoalUpper;

  /// No description provided for @tapToChange.
  ///
  /// In tr, this message translates to:
  /// **'Değiştirmek için dokun'**
  String get tapToChange;

  /// No description provided for @enemyEncounterUpper.
  ///
  /// In tr, this message translates to:
  /// **'DÜŞMAN KARŞILAŞMASI'**
  String get enemyEncounterUpper;

  /// No description provided for @enemyAboutUpper.
  ///
  /// In tr, this message translates to:
  /// **'DÜŞMAN HAKKINDA'**
  String get enemyAboutUpper;

  /// No description provided for @attackStat.
  ///
  /// In tr, this message translates to:
  /// **'{value} saldırı'**
  String attackStat(int value);

  /// No description provided for @defenseStat.
  ///
  /// In tr, this message translates to:
  /// **'{value} savunma'**
  String defenseStat(int value);

  /// No description provided for @startAdventure.
  ///
  /// In tr, this message translates to:
  /// **'Maceraya Başla'**
  String get startAdventure;

  /// No description provided for @goalSuitable.
  ///
  /// In tr, this message translates to:
  /// **'Bu hedef için uygun'**
  String get goalSuitable;

  /// No description provided for @unlocksAtSteps.
  ///
  /// In tr, this message translates to:
  /// **'{steps} adımda açılır'**
  String unlocksAtSteps(String steps);

  /// No description provided for @victoryMissionMessage.
  ///
  /// In tr, this message translates to:
  /// **'{name} yenildi. {xp} XP kazandın; bu zaferi adım adım hak ettin!'**
  String victoryMissionMessage(String name, int xp);

  /// No description provided for @totalDuration.
  ///
  /// In tr, this message translates to:
  /// **'{duration} toplam'**
  String totalDuration(String duration);

  /// No description provided for @enemyCombatExplanation.
  ///
  /// In tr, this message translates to:
  /// **'{rounds} round; her round {steps} adım ve {duration}. Hedefe süre dolmadan ulaşırsan mükemmel round serisi hasarını büyütür; kaçırırsan seri kırılır ve düşman eksik oranının eğrisine göre saldırır.'**
  String enemyCombatExplanation(int rounds, int steps, String duration);

  /// No description provided for @storageUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Kayıtlı ilerlemene şu an ulaşılamadı. Oyun geçici bir kayıtla açıldı; uygulamayı yeniden başlatmayı dene.'**
  String get storageUnavailable;

  /// No description provided for @studioSplashSemantics.
  ///
  /// In tr, this message translates to:
  /// **'Heapchi Studios açılış ekranı'**
  String get studioSplashSemantics;

  /// No description provided for @enemyAshGuardianName.
  ///
  /// In tr, this message translates to:
  /// **'Kül Muhafızı'**
  String get enemyAshGuardianName;

  /// No description provided for @enemyAshGuardianQuest.
  ///
  /// In tr, this message translates to:
  /// **'Kül Muhafızı sessiz geçidi tuttu. İlk 500 adımınla zırhındaki mührü parçala!'**
  String get enemyAshGuardianQuest;

  /// No description provided for @enemyNightOathName.
  ///
  /// In tr, this message translates to:
  /// **'Gece Yeminlisi'**
  String get enemyNightOathName;

  /// No description provided for @enemyNightOathQuest.
  ///
  /// In tr, this message translates to:
  /// **'Gece Yeminlisi kılıcını ay ışığında kaldırdı. 1.000 adımlık ritmini bozmadan onu geride bırak!'**
  String get enemyNightOathQuest;

  /// No description provided for @enemyVoidKnightName.
  ///
  /// In tr, this message translates to:
  /// **'Hiçlik Şövalyesi'**
  String get enemyVoidKnightName;

  /// No description provided for @enemyVoidKnightQuest.
  ///
  /// In tr, this message translates to:
  /// **'Hiçlik Şövalyesi yolun üzerine karanlık bir yarık açtı. 1.500 adımla mührü kapat!'**
  String get enemyVoidKnightQuest;

  /// No description provided for @enemyBloodWeaverName.
  ///
  /// In tr, this message translates to:
  /// **'Kan Dokuyan'**
  String get enemyBloodWeaverName;

  /// No description provided for @enemyBloodWeaverQuest.
  ///
  /// In tr, this message translates to:
  /// **'Kan Dokuyan ağının başında bekliyor. 2.000 adımı kendi temponda tamamla, sonra güvenle savaş.'**
  String get enemyBloodWeaverQuest;

  /// No description provided for @enemyCrimsonWingName.
  ///
  /// In tr, this message translates to:
  /// **'Kızıl Kanat'**
  String get enemyCrimsonWingName;

  /// No description provided for @enemyCrimsonWingQuest.
  ///
  /// In tr, this message translates to:
  /// **'Kızıl Kanat gökyüzünü kana boyadı. 2.500 adım at, gölgesinin dışına çık!'**
  String get enemyCrimsonWingQuest;

  /// No description provided for @enemyEmberSirenName.
  ///
  /// In tr, this message translates to:
  /// **'Kor Sireni'**
  String get enemyEmberSirenName;

  /// No description provided for @enemyEmberSirenQuest.
  ///
  /// In tr, this message translates to:
  /// **'Kor Sireni ateşli ezgisiyle adımlarını yavaşlatıyor. 3.000 adımla büyüyü sustur!'**
  String get enemyEmberSirenQuest;

  /// No description provided for @enemyDuskTemptressName.
  ///
  /// In tr, this message translates to:
  /// **'Alacakaranlık Cadısı'**
  String get enemyDuskTemptressName;

  /// No description provided for @enemyDuskTemptressQuest.
  ///
  /// In tr, this message translates to:
  /// **'Alacakaranlık Cadısı patikayı sahte hayallerle kapladı. 3.500 gerçek adımla sisini dağıt!'**
  String get enemyDuskTemptressQuest;

  /// No description provided for @enemyHornedExecutionerName.
  ///
  /// In tr, this message translates to:
  /// **'Boynuzlu Cellat'**
  String get enemyHornedExecutionerName;

  /// No description provided for @enemyHornedExecutionerQuest.
  ///
  /// In tr, this message translates to:
  /// **'Boynuzlu Cellat baltasını yol taşına vurdu. 4.000 adımla meydan okumasını kabul et!'**
  String get enemyHornedExecutionerQuest;

  /// No description provided for @enemyInfernalSentinelName.
  ///
  /// In tr, this message translates to:
  /// **'Cehennem Nöbetçisi'**
  String get enemyInfernalSentinelName;

  /// No description provided for @enemyInfernalSentinelQuest.
  ///
  /// In tr, this message translates to:
  /// **'Cehennem Nöbetçisi köprüyü ateşle çevirdi. 4.500 adımla alev çemberini yar!'**
  String get enemyInfernalSentinelQuest;

  /// No description provided for @enemyBlackClawName.
  ///
  /// In tr, this message translates to:
  /// **'Kara Pençe'**
  String get enemyBlackClawName;

  /// No description provided for @enemyBlackClawQuest.
  ///
  /// In tr, this message translates to:
  /// **'Kara Pençe seni bekliyor. 5.000 adımı kendi temponda tamamla ve güvenli bir yerde savaş.'**
  String get enemyBlackClawQuest;

  /// No description provided for @enemyEmberHeirName.
  ///
  /// In tr, this message translates to:
  /// **'Alev Tahtının Varisi'**
  String get enemyEmberHeirName;

  /// No description provided for @enemyEmberHeirQuest.
  ///
  /// In tr, this message translates to:
  /// **'Alev Tahtının Varisi tacını savunuyor. 5.500 adımla krallığını sars!'**
  String get enemyEmberHeirQuest;

  /// No description provided for @enemyAbyssOverlordName.
  ///
  /// In tr, this message translates to:
  /// **'Uçurum Hükümdarı'**
  String get enemyAbyssOverlordName;

  /// No description provided for @enemyAbyssOverlordQuest.
  ///
  /// In tr, this message translates to:
  /// **'Uçurum Hükümdarı dönüş yolunu yuttu. 6.000 adımla kendi geçidini aç!'**
  String get enemyAbyssOverlordQuest;

  /// No description provided for @enemyEyeOfNothingName.
  ///
  /// In tr, this message translates to:
  /// **'Hiçliğin Gözü'**
  String get enemyEyeOfNothingName;

  /// No description provided for @enemyEyeOfNothingQuest.
  ///
  /// In tr, this message translates to:
  /// **'Hiçliğin Gözü her adımını izliyor. 6.500 adımla bakışını yere indir!'**
  String get enemyEyeOfNothingQuest;

  /// No description provided for @enemyCinderColossusName.
  ///
  /// In tr, this message translates to:
  /// **'Köz Devi'**
  String get enemyCinderColossusName;

  /// No description provided for @enemyCinderColossusQuest.
  ///
  /// In tr, this message translates to:
  /// **'Köz Devi her darbede dağı uyandırıyor. 7.000 adımla taş kalbini soğut!'**
  String get enemyCinderColossusQuest;

  /// No description provided for @enemySpiritFlameName.
  ///
  /// In tr, this message translates to:
  /// **'Ruh Alevi'**
  String get enemySpiritFlameName;

  /// No description provided for @enemySpiritFlameQuest.
  ///
  /// In tr, this message translates to:
  /// **'Ruh Alevi sönmeyen bir iz gibi peşinde. 7.500 adımla lanetli ateşi tüket!'**
  String get enemySpiritFlameQuest;

  /// No description provided for @enemyHellWingName.
  ///
  /// In tr, this message translates to:
  /// **'Cehennem Kanadı'**
  String get enemyHellWingName;

  /// No description provided for @enemyHellWingQuest.
  ///
  /// In tr, this message translates to:
  /// **'Cehennem Kanadı göğü kararttı. 8.000 adımla kanatlarının altından şafağa ulaş!'**
  String get enemyHellWingQuest;

  /// No description provided for @enemyAshFangName.
  ///
  /// In tr, this message translates to:
  /// **'Kül Diş'**
  String get enemyAshFangName;

  /// No description provided for @enemyAshFangQuest.
  ///
  /// In tr, this message translates to:
  /// **'Kül Diş kokunu aldı ve av başladı. 8.500 adımla cehennem tazısını yıprat!'**
  String get enemyAshFangQuest;

  /// No description provided for @enemyMagmaDevourerName.
  ///
  /// In tr, this message translates to:
  /// **'Magma Yutan'**
  String get enemyMagmaDevourerName;

  /// No description provided for @enemyMagmaDevourerQuest.
  ///
  /// In tr, this message translates to:
  /// **'Magma Yutan bastığın zemini eritiyor. 9.000 adımla lav denizinin önüne geç!'**
  String get enemyMagmaDevourerQuest;

  /// No description provided for @enemyMazeButcherName.
  ///
  /// In tr, this message translates to:
  /// **'Labirent Kasabı'**
  String get enemyMazeButcherName;

  /// No description provided for @enemyMazeButcherQuest.
  ///
  /// In tr, this message translates to:
  /// **'Labirent Kasabı çıkışını bekliyor. 9.500 adımla duvarlardan önce iradesini yık!'**
  String get enemyMazeButcherQuest;

  /// No description provided for @enemyLordOfLastSealName.
  ///
  /// In tr, this message translates to:
  /// **'Son Mührün Efendisi'**
  String get enemyLordOfLastSealName;

  /// No description provided for @enemyLordOfLastSealQuest.
  ///
  /// In tr, this message translates to:
  /// **'Son Mührün Efendisi yolculuğunun sonuna karanlık imzasını attı. 10.000 adımla mührü sonsuza dek kır!'**
  String get enemyLordOfLastSealQuest;

  /// No description provided for @enemyArchetypeBruiser.
  ///
  /// In tr, this message translates to:
  /// **'Dengeli'**
  String get enemyArchetypeBruiser;

  /// No description provided for @enemyArchetypeBruiserDescription.
  ///
  /// In tr, this message translates to:
  /// **'Dengeli dövüşür; sürprizi yoktur.'**
  String get enemyArchetypeBruiserDescription;

  /// No description provided for @enemyArchetypeTank.
  ///
  /// In tr, this message translates to:
  /// **'Dayanıklı'**
  String get enemyArchetypeTank;

  /// No description provided for @enemyArchetypeTankDescription.
  ///
  /// In tr, this message translates to:
  /// **'Yavaş ama çok dayanıklı; canını eritmek zaman ister.'**
  String get enemyArchetypeTankDescription;

  /// No description provided for @enemyArchetypeSwift.
  ///
  /// In tr, this message translates to:
  /// **'Çevik'**
  String get enemyArchetypeSwift;

  /// No description provided for @enemyArchetypeSwiftDescription.
  ///
  /// In tr, this message translates to:
  /// **'Genelde önce vurur ve vuruşlarını sıyırır.'**
  String get enemyArchetypeSwiftDescription;

  /// No description provided for @enemyArchetypeCaster.
  ///
  /// In tr, this message translates to:
  /// **'Büyücü'**
  String get enemyArchetypeCaster;

  /// No description provided for @enemyArchetypeCasterDescription.
  ///
  /// In tr, this message translates to:
  /// **'Kırılgan ama sert vurur; kritiği yüksektir.'**
  String get enemyArchetypeCasterDescription;

  /// No description provided for @guideMaviliName.
  ///
  /// In tr, this message translates to:
  /// **'Mavili'**
  String get guideMaviliName;

  /// No description provided for @guideMaviliDescription.
  ///
  /// In tr, this message translates to:
  /// **'Sakin, cesur ve güvenilir.'**
  String get guideMaviliDescription;

  /// No description provided for @guidePinkyName.
  ///
  /// In tr, this message translates to:
  /// **'Pinky'**
  String get guidePinkyName;

  /// No description provided for @guidePinkyDescription.
  ///
  /// In tr, this message translates to:
  /// **'Neşeli, hızlı ve meraklı.'**
  String get guidePinkyDescription;

  /// No description provided for @guideKupkuzuName.
  ///
  /// In tr, this message translates to:
  /// **'Küpkuzu'**
  String get guideKupkuzuName;

  /// No description provided for @guideKupkuzuDescription.
  ///
  /// In tr, this message translates to:
  /// **'Küçük, bilge ve gözü pek.'**
  String get guideKupkuzuDescription;

  /// No description provided for @petTavernTeaser.
  ///
  /// In tr, this message translates to:
  /// **'Çevrimiçi çok yakında — hadi git git, sen yürümene bak!'**
  String get petTavernTeaser;

  /// No description provided for @petHome1.
  ///
  /// In tr, this message translates to:
  /// **'Bugün de yürüyoruz, değil mi? Ben hazırım.'**
  String get petHome1;

  /// No description provided for @petHome2.
  ///
  /// In tr, this message translates to:
  /// **'Adımların birikiyor. Sonu güzel bitecek.'**
  String get petHome2;

  /// No description provided for @petHome3.
  ///
  /// In tr, this message translates to:
  /// **'Şu halkanın dolmasına bayılıyorum.'**
  String get petHome3;

  /// No description provided for @petHome4.
  ///
  /// In tr, this message translates to:
  /// **'Bir tur daha atsak fena olmaz bence.'**
  String get petHome4;

  /// No description provided for @petHome5.
  ///
  /// In tr, this message translates to:
  /// **'Sessiz duruyorum ama seni izliyorum.'**
  String get petHome5;

  /// No description provided for @petHomeNoStreak1.
  ///
  /// In tr, this message translates to:
  /// **'Serini bugün henüz güvenceye almadın. Acele yok ama unutma.'**
  String get petHomeNoStreak1;

  /// No description provided for @petHomeNoStreak2.
  ///
  /// In tr, this message translates to:
  /// **'Bir düşman devirsen seri bu akşam garanti olur.'**
  String get petHomeNoStreak2;

  /// No description provided for @petHomeWheelReady1.
  ///
  /// In tr, this message translates to:
  /// **'Çark hâlâ dönmeyi bekliyor, haberin olsun.'**
  String get petHomeWheelReady1;

  /// No description provided for @petHomeWheelReady2.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün çark hakkı duruyor. Bedava şey sevmez misin?'**
  String get petHomeWheelReady2;

  /// No description provided for @petAdventure1.
  ///
  /// In tr, this message translates to:
  /// **'Şu düşmanın gözlerine bakma, cesareti kırılıyor.'**
  String get petAdventure1;

  /// No description provided for @petAdventure2.
  ///
  /// In tr, this message translates to:
  /// **'Adımlarını biriktir, güvenli olduğunda savaşa başla.'**
  String get petAdventure2;

  /// No description provided for @petAdventure3.
  ///
  /// In tr, this message translates to:
  /// **'Canavar bekleyebilir. Kendi temponda yürü.'**
  String get petAdventure3;

  /// No description provided for @petAdventureIdle1.
  ///
  /// In tr, this message translates to:
  /// **'Macera seçmemişsin. Hangi rakibi kızdıralım?'**
  String get petAdventureIdle1;

  /// No description provided for @petAdventureIdle2.
  ///
  /// In tr, this message translates to:
  /// **'Boş duran bir kahraman görmek beni geriyor.'**
  String get petAdventureIdle2;

  /// No description provided for @petStore1.
  ///
  /// In tr, this message translates to:
  /// **'Bakmak bedava. Almak değil.'**
  String get petStore1;

  /// No description provided for @petStore2.
  ///
  /// In tr, this message translates to:
  /// **'Şu kalkanı alsan bir daha canını dert etmezdin.'**
  String get petStore2;

  /// No description provided for @petStore3.
  ///
  /// In tr, this message translates to:
  /// **'Altınını biriktir derdim ama beni dinlemiyorsun.'**
  String get petStore3;

  /// No description provided for @petTavern2.
  ///
  /// In tr, this message translates to:
  /// **'Burası dolduğunda masaları kapmak zor olacak, şimdiden söyleyeyim.'**
  String get petTavern2;

  /// No description provided for @petTavern3.
  ///
  /// In tr, this message translates to:
  /// **'Takım kuracağız, düşmanları paylaşacağız. Ama daha değil.'**
  String get petTavern3;

  /// No description provided for @petProfile1.
  ///
  /// In tr, this message translates to:
  /// **'Ünvanını değiştirdin mi? Yeni birini denesen?'**
  String get petProfile1;

  /// No description provided for @petProfile2.
  ///
  /// In tr, this message translates to:
  /// **'Buradaki sayılara bakınca gurur duyuyorum.'**
  String get petProfile2;

  /// No description provided for @petProfile3.
  ///
  /// In tr, this message translates to:
  /// **'Seri bonusun her gün biraz daha birikiyor.'**
  String get petProfile3;

  /// No description provided for @tutorialWelcome.
  ///
  /// In tr, this message translates to:
  /// **'Selam! Maceranda yanında olacağım. Hazırsan başlayalım.'**
  String get tutorialWelcome;

  /// No description provided for @tutorialAdventurePrompt.
  ///
  /// In tr, this message translates to:
  /// **'Gel, ilk maceranı seçelim.'**
  String get tutorialAdventurePrompt;

  /// No description provided for @tutorialEnemyChoice.
  ///
  /// In tr, this message translates to:
  /// **'İlk rakibini seç. Acele etme, burada seni bekliyorum.'**
  String get tutorialEnemyChoice;

  /// No description provided for @tutorialEnemySelected.
  ///
  /// In tr, this message translates to:
  /// **'İyi seçim! İlk maceranda senin yerine ben yürürüm. Sen vuruşumu izle.'**
  String get tutorialEnemySelected;

  /// No description provided for @tutorialCombatDemo.
  ///
  /// In tr, this message translates to:
  /// **'Bu ilk savaş benden! Adımlarını ve vuruşlarını senin için tamamlıyorum.'**
  String get tutorialCombatDemo;

  /// No description provided for @tutorialCombatWaiting.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi sıra sende. Adımlarını tamamla; savaşı burada izleyeceğim.'**
  String get tutorialCombatWaiting;

  /// No description provided for @tutorialEnemyReaction.
  ///
  /// In tr, this message translates to:
  /// **'Gördün mü? Düşmanlar da karşılık verir.'**
  String get tutorialEnemyReaction;

  /// No description provided for @tutorialVictoryCelebration.
  ///
  /// In tr, this message translates to:
  /// **'İşte bu! İlk zaferin.'**
  String get tutorialVictoryCelebration;

  /// No description provided for @tutorialRewardCoins.
  ///
  /// In tr, this message translates to:
  /// **'Düşmanları yenerek rastgele altın kazanırsın.'**
  String get tutorialRewardCoins;

  /// No description provided for @tutorialRewardXp.
  ///
  /// In tr, this message translates to:
  /// **'Deneyim de seni seviye seviye güçlendirir.'**
  String get tutorialRewardXp;

  /// No description provided for @tutorialShopPrompt.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi altınını güce çevirelim. Mağazaya gitmek için düğmeye dokun.'**
  String get tutorialShopPrompt;

  /// No description provided for @tutorialShopWaiting.
  ///
  /// In tr, this message translates to:
  /// **'Eğitim altınınla gösterdiğim ilk silahı satın al.'**
  String get tutorialShopWaiting;

  /// No description provided for @tutorialItemBought.
  ///
  /// In tr, this message translates to:
  /// **'İşte şimdi güçleniyoruz!'**
  String get tutorialItemBought;

  /// No description provided for @tutorialEquipWaiting.
  ///
  /// In tr, this message translates to:
  /// **'Yeni eşyanı bul ve Kuşan düğmesine dokun.'**
  String get tutorialEquipWaiting;

  /// No description provided for @tutorialItemEquipped.
  ///
  /// In tr, this message translates to:
  /// **'Çok daha iyi!'**
  String get tutorialItemEquipped;

  /// No description provided for @tutorialBlacksmithPrompt.
  ///
  /// In tr, this message translates to:
  /// **'Biraz daha güç lazım. Demirciye gidelim.'**
  String get tutorialBlacksmithPrompt;

  /// No description provided for @tutorialUpgradeWaiting.
  ///
  /// In tr, this message translates to:
  /// **'Yükselt düğmesi eşyanın seviyesini artırır.'**
  String get tutorialUpgradeWaiting;

  /// No description provided for @tutorialUpgradeCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi oldu! Eşyan artık çok daha güçlü.'**
  String get tutorialUpgradeCompleted;

  /// No description provided for @tutorialWheelPrompt.
  ///
  /// In tr, this message translates to:
  /// **'Son durak: Günlük Çark. Şansını deneyelim.'**
  String get tutorialWheelPrompt;

  /// No description provided for @tutorialWheelWaiting.
  ///
  /// In tr, this message translates to:
  /// **'Çevir ve sonucu birlikte izleyelim.'**
  String get tutorialWheelWaiting;

  /// No description provided for @tutorialWheelReward.
  ///
  /// In tr, this message translates to:
  /// **'Şans bugün senden yana!'**
  String get tutorialWheelReward;

  /// No description provided for @tutorialFinalReady.
  ///
  /// In tr, this message translates to:
  /// **'Artık hazırsın.'**
  String get tutorialFinalReady;

  /// No description provided for @tutorialFinalMotto.
  ///
  /// In tr, this message translates to:
  /// **'Yürü. Güçlen. Düşmanlarını yen.'**
  String get tutorialFinalMotto;

  /// No description provided for @tutorialOnlineTeaser.
  ///
  /// In tr, this message translates to:
  /// **'Ama bu daha başlangıç... Yakında Online Maceralar da burada olacak.'**
  String get tutorialOnlineTeaser;

  /// No description provided for @tutorialRatingRequest.
  ///
  /// In tr, this message translates to:
  /// **'Ben gitmeden önce küçük bir ricam var. Maceranı sevdiysen bizi değerlendirmeyi unutma!'**
  String get tutorialRatingRequest;

  /// No description provided for @tutorialFarewellWorkDone.
  ///
  /// In tr, this message translates to:
  /// **'Benim işim burada bitti.'**
  String get tutorialFarewellWorkDone;

  /// No description provided for @tutorialFarewellYourTurn.
  ///
  /// In tr, this message translates to:
  /// **'Artık buralar sana emanet. Seninle dövüşmemi istersen ana sayfadaki adım çemberinin sol altındaki pet butonuna basabilirsin.'**
  String get tutorialFarewellYourTurn;

  /// No description provided for @tutorialFarewell.
  ///
  /// In tr, this message translates to:
  /// **'Şimdilik gidiyorum. Beni çağırırsan yine yanında olacağım!'**
  String get tutorialFarewell;

  /// No description provided for @tutorialBegin.
  ///
  /// In tr, this message translates to:
  /// **'Başlayalım'**
  String get tutorialBegin;

  /// No description provided for @tutorialStartAdventure.
  ///
  /// In tr, this message translates to:
  /// **'Macerayı başlat'**
  String get tutorialStartAdventure;

  /// No description provided for @tutorialUnderstood.
  ///
  /// In tr, this message translates to:
  /// **'Anladım'**
  String get tutorialUnderstood;

  /// No description provided for @tutorialViewRewards.
  ///
  /// In tr, this message translates to:
  /// **'Ödüllere bak'**
  String get tutorialViewRewards;

  /// No description provided for @tutorialContinue.
  ///
  /// In tr, this message translates to:
  /// **'Devam'**
  String get tutorialContinue;

  /// No description provided for @tutorialGoToStore.
  ///
  /// In tr, this message translates to:
  /// **'Mağazaya git'**
  String get tutorialGoToStore;

  /// No description provided for @tutorialOpenInventory.
  ///
  /// In tr, this message translates to:
  /// **'Envanteri aç'**
  String get tutorialOpenInventory;

  /// No description provided for @tutorialGoToWheel.
  ///
  /// In tr, this message translates to:
  /// **'Çarka git'**
  String get tutorialGoToWheel;

  /// No description provided for @tutorialOpenBlacksmith.
  ///
  /// In tr, this message translates to:
  /// **'Demirciyi aç'**
  String get tutorialOpenBlacksmith;

  /// No description provided for @tutorialOpenWheel.
  ///
  /// In tr, this message translates to:
  /// **'Çarkı aç'**
  String get tutorialOpenWheel;

  /// No description provided for @tutorialLater.
  ///
  /// In tr, this message translates to:
  /// **'Sonra'**
  String get tutorialLater;

  /// No description provided for @tutorialRate.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendir'**
  String get tutorialRate;

  /// No description provided for @tutorialFinish.
  ///
  /// In tr, this message translates to:
  /// **'Eğitimi Bitir'**
  String get tutorialFinish;

  /// No description provided for @adventureReminder1.
  ///
  /// In tr, this message translates to:
  /// **'{round}. round: {enemy} için {steps} adım kaldı.'**
  String adventureReminder1(int round, String steps, String enemy);

  /// No description provided for @adventureReminder2.
  ///
  /// In tr, this message translates to:
  /// **'{round}. round devam ediyor! Kalan {steps} adımı tamamla.'**
  String adventureReminder2(int round, String steps);

  /// No description provided for @adventureReminder3.
  ///
  /// In tr, this message translates to:
  /// **'Ritmini koru! {round}. roundda {steps} adımın kaldı.'**
  String adventureReminder3(int round, String steps);

  /// No description provided for @adventureReminder4.
  ///
  /// In tr, this message translates to:
  /// **'{round}. round: {steps} adım daha at ve {enemy} gücünü kaybetsin!'**
  String adventureReminder4(int round, String steps, String enemy);

  /// No description provided for @adventureReminderChannel.
  ///
  /// In tr, this message translates to:
  /// **'Macera Hatırlatmaları'**
  String get adventureReminderChannel;

  /// No description provided for @adventureReminderChannelDescription.
  ///
  /// In tr, this message translates to:
  /// **'Devam eden macera ve adım hatırlatmaları'**
  String get adventureReminderChannelDescription;

  /// No description provided for @rarityCommon.
  ///
  /// In tr, this message translates to:
  /// **'Sıradan'**
  String get rarityCommon;

  /// No description provided for @rarityUncommon.
  ///
  /// In tr, this message translates to:
  /// **'Az Bulunur'**
  String get rarityUncommon;

  /// No description provided for @rarityRare.
  ///
  /// In tr, this message translates to:
  /// **'Nadir'**
  String get rarityRare;

  /// No description provided for @rarityEpic.
  ///
  /// In tr, this message translates to:
  /// **'Epik'**
  String get rarityEpic;

  /// No description provided for @rarityLegendary.
  ///
  /// In tr, this message translates to:
  /// **'Efsanevi'**
  String get rarityLegendary;

  /// No description provided for @itemCategorySwords.
  ///
  /// In tr, this message translates to:
  /// **'Kılıçlar'**
  String get itemCategorySwords;

  /// No description provided for @itemCategoryAxesHalberds.
  ///
  /// In tr, this message translates to:
  /// **'Baltalar ve Teberler'**
  String get itemCategoryAxesHalberds;

  /// No description provided for @itemCategoryMacesHammers.
  ///
  /// In tr, this message translates to:
  /// **'Topuzlar ve Çekiçler'**
  String get itemCategoryMacesHammers;

  /// No description provided for @itemCategorySpears.
  ///
  /// In tr, this message translates to:
  /// **'Mızraklar'**
  String get itemCategorySpears;

  /// No description provided for @itemCategoryScythes.
  ///
  /// In tr, this message translates to:
  /// **'Tırpanlar'**
  String get itemCategoryScythes;

  /// No description provided for @itemCategoryMagic.
  ///
  /// In tr, this message translates to:
  /// **'Büyü'**
  String get itemCategoryMagic;

  /// No description provided for @itemCategoryShields.
  ///
  /// In tr, this message translates to:
  /// **'Kalkanlar'**
  String get itemCategoryShields;

  /// No description provided for @itemCategoryArch.
  ///
  /// In tr, this message translates to:
  /// **'Yay ve Ok'**
  String get itemCategoryArch;

  /// No description provided for @itemCategoryRangedOther.
  ///
  /// In tr, this message translates to:
  /// **'Fırlatma Silahları'**
  String get itemCategoryRangedOther;

  /// No description provided for @itemCategorySpecialOther.
  ///
  /// In tr, this message translates to:
  /// **'Özel'**
  String get itemCategorySpecialOther;

  /// No description provided for @itemArchetypeStriker.
  ///
  /// In tr, this message translates to:
  /// **'Vurucu'**
  String get itemArchetypeStriker;

  /// No description provided for @itemArchetypeStrikerDescription.
  ///
  /// In tr, this message translates to:
  /// **'ham vuruş gücüne yatırım yapar'**
  String get itemArchetypeStrikerDescription;

  /// No description provided for @itemArchetypeGuardian.
  ///
  /// In tr, this message translates to:
  /// **'Muhafız'**
  String get itemArchetypeGuardian;

  /// No description provided for @itemArchetypeGuardianDescription.
  ///
  /// In tr, this message translates to:
  /// **'dayanıklılığa yatırım yapar'**
  String get itemArchetypeGuardianDescription;

  /// No description provided for @itemArchetypeDuelist.
  ///
  /// In tr, this message translates to:
  /// **'Düellocu'**
  String get itemArchetypeDuelist;

  /// No description provided for @itemArchetypeDuelistDescription.
  ///
  /// In tr, this message translates to:
  /// **'kritik vuruşa yatırım yapar'**
  String get itemArchetypeDuelistDescription;

  /// No description provided for @itemArchetypeSwift.
  ///
  /// In tr, this message translates to:
  /// **'Çevik'**
  String get itemArchetypeSwift;

  /// No description provided for @itemArchetypeSwiftDescription.
  ///
  /// In tr, this message translates to:
  /// **'kaçınma ve tempoya yatırım yapar'**
  String get itemArchetypeSwiftDescription;

  /// No description provided for @titleSourcePurchase.
  ///
  /// In tr, this message translates to:
  /// **'Mağaza'**
  String get titleSourcePurchase;

  /// No description provided for @titleSourceAchievement.
  ///
  /// In tr, this message translates to:
  /// **'Başarım'**
  String get titleSourceAchievement;

  /// No description provided for @titleSourceWheel.
  ///
  /// In tr, this message translates to:
  /// **'Çark'**
  String get titleSourceWheel;

  /// No description provided for @titleSourceMilestone.
  ///
  /// In tr, this message translates to:
  /// **'Kilometre taşı'**
  String get titleSourceMilestone;

  /// No description provided for @classArcher.
  ///
  /// In tr, this message translates to:
  /// **'Şahin Okçu'**
  String get classArcher;

  /// No description provided for @classArmoredAxeman.
  ///
  /// In tr, this message translates to:
  /// **'Demir Cellat'**
  String get classArmoredAxeman;

  /// No description provided for @classArmoredOrc.
  ///
  /// In tr, this message translates to:
  /// **'Zırhlı Yaban'**
  String get classArmoredOrc;

  /// No description provided for @classArmoredSkeleton.
  ///
  /// In tr, this message translates to:
  /// **'Kemik Muhafız'**
  String get classArmoredSkeleton;

  /// No description provided for @classEliteOrc.
  ///
  /// In tr, this message translates to:
  /// **'Kızıl Savaş Şefi'**
  String get classEliteOrc;

  /// No description provided for @classGreatswordSkeleton.
  ///
  /// In tr, this message translates to:
  /// **'Mezar Kılıçlısı'**
  String get classGreatswordSkeleton;

  /// No description provided for @classKnight.
  ///
  /// In tr, this message translates to:
  /// **'Kraliyet Şövalyesi'**
  String get classKnight;

  /// No description provided for @classKnightTemplar.
  ///
  /// In tr, this message translates to:
  /// **'Şafak Tapınakçısı'**
  String get classKnightTemplar;

  /// No description provided for @classOrc.
  ///
  /// In tr, this message translates to:
  /// **'Yaban Akıncı'**
  String get classOrc;

  /// No description provided for @classPriest.
  ///
  /// In tr, this message translates to:
  /// **'Işık Rahibi'**
  String get classPriest;

  /// No description provided for @classSkeleton.
  ///
  /// In tr, this message translates to:
  /// **'Kemik Savaşçı'**
  String get classSkeleton;

  /// No description provided for @classSkeletonArcher.
  ///
  /// In tr, this message translates to:
  /// **'Mezar Okçusu'**
  String get classSkeletonArcher;

  /// No description provided for @classSlime.
  ///
  /// In tr, this message translates to:
  /// **'İlginç Slime'**
  String get classSlime;

  /// No description provided for @classSoldier.
  ///
  /// In tr, this message translates to:
  /// **'Sınır Muhafızı'**
  String get classSoldier;

  /// No description provided for @classSwordsman.
  ///
  /// In tr, this message translates to:
  /// **'Kılıç Üstadı'**
  String get classSwordsman;

  /// No description provided for @classWerebear.
  ///
  /// In tr, this message translates to:
  /// **'Ayı Ruhlu'**
  String get classWerebear;

  /// No description provided for @classWerewolf.
  ///
  /// In tr, this message translates to:
  /// **'Ay Kurdu'**
  String get classWerewolf;

  /// No description provided for @classWizard.
  ///
  /// In tr, this message translates to:
  /// **'Gök Büyücüsü'**
  String get classWizard;

  /// No description provided for @classSelectionSloganFallback.
  ///
  /// In tr, this message translates to:
  /// **'İyi seçim. Birlikte zafere yürüyeceğiz!'**
  String get classSelectionSloganFallback;

  /// No description provided for @rewardConditionTotalDistance.
  ///
  /// In tr, this message translates to:
  /// **'Toplam mesafe'**
  String get rewardConditionTotalDistance;

  /// No description provided for @rewardConditionSingleWalkDistance.
  ///
  /// In tr, this message translates to:
  /// **'Tek yürüyüş mesafesi'**
  String get rewardConditionSingleWalkDistance;

  /// No description provided for @rewardConditionDailyStepGoals.
  ///
  /// In tr, this message translates to:
  /// **'Günlük hedef'**
  String get rewardConditionDailyStepGoals;

  /// No description provided for @rewardConditionStreakDays.
  ///
  /// In tr, this message translates to:
  /// **'Hedef serisi'**
  String get rewardConditionStreakDays;

  /// No description provided for @rewardConditionCompletedDays.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlanan gün'**
  String get rewardConditionCompletedDays;

  /// No description provided for @rewardConditionMonstersDefeated.
  ///
  /// In tr, this message translates to:
  /// **'Canavar avı'**
  String get rewardConditionMonstersDefeated;

  /// No description provided for @rewardConditionSpecificVillain.
  ///
  /// In tr, this message translates to:
  /// **'Villain avı'**
  String get rewardConditionSpecificVillain;

  /// No description provided for @rewardConditionVillainsDefeated.
  ///
  /// In tr, this message translates to:
  /// **'Villain zaferi'**
  String get rewardConditionVillainsDefeated;

  /// No description provided for @rewardConditionFlawlessWins.
  ///
  /// In tr, this message translates to:
  /// **'Hasarsız zafer'**
  String get rewardConditionFlawlessWins;

  /// No description provided for @rewardConditionWinStreak.
  ///
  /// In tr, this message translates to:
  /// **'Galibiyet serisi'**
  String get rewardConditionWinStreak;

  /// No description provided for @rewardConditionQuestsCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Görev tamamlama'**
  String get rewardConditionQuestsCompleted;

  /// No description provided for @rewardConditionLevel.
  ///
  /// In tr, this message translates to:
  /// **'Seviye'**
  String get rewardConditionLevel;

  /// No description provided for @rewardConditionXpEarned.
  ///
  /// In tr, this message translates to:
  /// **'XP toplama'**
  String get rewardConditionXpEarned;

  /// No description provided for @rewardConditionBossesDefeated.
  ///
  /// In tr, this message translates to:
  /// **'Boss avı'**
  String get rewardConditionBossesDefeated;

  /// No description provided for @rewardConditionRareVillainsDefeated.
  ///
  /// In tr, this message translates to:
  /// **'Nadir villain avı'**
  String get rewardConditionRareVillainsDefeated;

  /// No description provided for @rewardConditionVillainsDiscovered.
  ///
  /// In tr, this message translates to:
  /// **'Villain keşfi'**
  String get rewardConditionVillainsDiscovered;

  /// No description provided for @rewardConditionActiveDays.
  ///
  /// In tr, this message translates to:
  /// **'Düzenli devam'**
  String get rewardConditionActiveDays;

  /// No description provided for @generatedRewardName.
  ///
  /// In tr, this message translates to:
  /// **'{condition} Hatırası · {series}'**
  String generatedRewardName(String condition, int series);

  /// No description provided for @rewardRequirementTotalDistance.
  ///
  /// In tr, this message translates to:
  /// **'{distance} km yürü'**
  String rewardRequirementTotalDistance(String distance);

  /// No description provided for @rewardRequirementSingleWalkDistance.
  ///
  /// In tr, this message translates to:
  /// **'Tek yürüyüşte {distance} km ilerle'**
  String rewardRequirementSingleWalkDistance(String distance);

  /// No description provided for @rewardRequirementDailyGoals.
  ///
  /// In tr, this message translates to:
  /// **'Günlük adım hedefini {count} gün tamamla'**
  String rewardRequirementDailyGoals(int count);

  /// No description provided for @rewardRequirementStreak.
  ///
  /// In tr, this message translates to:
  /// **'Hedefini {count} gün üst üste tuttur'**
  String rewardRequirementStreak(int count);

  /// No description provided for @rewardRequirementCompletedDays.
  ///
  /// In tr, this message translates to:
  /// **'{count} hedef günü tamamla'**
  String rewardRequirementCompletedDays(int count);

  /// No description provided for @rewardRequirementMonsters.
  ///
  /// In tr, this message translates to:
  /// **'{count} canavar yen'**
  String rewardRequirementMonsters(int count);

  /// No description provided for @rewardRequirementSpecificVillain.
  ///
  /// In tr, this message translates to:
  /// **'{enemy} villain’ını {count} kez yen'**
  String rewardRequirementSpecificVillain(String enemy, int count);

  /// No description provided for @rewardRequirementVillains.
  ///
  /// In tr, this message translates to:
  /// **'{count} villain yen'**
  String rewardRequirementVillains(int count);

  /// No description provided for @rewardRequirementFlawless.
  ///
  /// In tr, this message translates to:
  /// **'Hasar almadan {count} savaş kazan'**
  String rewardRequirementFlawless(int count);

  /// No description provided for @rewardRequirementWinStreak.
  ///
  /// In tr, this message translates to:
  /// **'{count} savaşlık galibiyet serisine ulaş'**
  String rewardRequirementWinStreak(int count);

  /// No description provided for @rewardRequirementQuests.
  ///
  /// In tr, this message translates to:
  /// **'{count} görev tamamla'**
  String rewardRequirementQuests(int count);

  /// No description provided for @rewardRequirementLevel.
  ///
  /// In tr, this message translates to:
  /// **'{count}. seviyeye ulaş'**
  String rewardRequirementLevel(int count);

  /// No description provided for @rewardRequirementXp.
  ///
  /// In tr, this message translates to:
  /// **'Toplam {count} XP kazan'**
  String rewardRequirementXp(int count);

  /// No description provided for @rewardRequirementBosses.
  ///
  /// In tr, this message translates to:
  /// **'{count} boss yen'**
  String rewardRequirementBosses(int count);

  /// No description provided for @rewardRequirementRareVillains.
  ///
  /// In tr, this message translates to:
  /// **'{count} nadir villain yen'**
  String rewardRequirementRareVillains(int count);

  /// No description provided for @rewardRequirementDiscovered.
  ///
  /// In tr, this message translates to:
  /// **'{count} farklı villain keşfet'**
  String rewardRequirementDiscovered(int count);

  /// No description provided for @rewardRequirementActiveDays.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamaya {count} farklı gün devam et'**
  String rewardRequirementActiveDays(int count);

  /// No description provided for @rewardDescription.
  ///
  /// In tr, this message translates to:
  /// **'{requirement} ve bu hatırayı koleksiyonuna kat.'**
  String rewardDescription(String requirement);

  /// No description provided for @thisRoundSteps.
  ///
  /// In tr, this message translates to:
  /// **'Bu round: {current} / {target} adım'**
  String thisRoundSteps(String current, String target);

  /// No description provided for @roundRules.
  ///
  /// In tr, this message translates to:
  /// **'Bu round {steps} adım · {duration}. Hedefi süre dolmadan bitirirsen mükemmel round ve erken bitirme bonusu kazanırsın. Kaçırırsan seri sıfırlanır; {enemy} eksik oranının eğrisine göre saldırır.'**
  String roundRules(String steps, String duration, String enemy);

  /// No description provided for @roundGoalSummary.
  ///
  /// In tr, this message translates to:
  /// **'{rounds} round · {steps} adım/round · {duration}/round'**
  String roundGoalSummary(int rounds, String steps, String duration);

  /// No description provided for @healthValue.
  ///
  /// In tr, this message translates to:
  /// **'{value} can'**
  String healthValue(String value);

  /// No description provided for @stepsLabel.
  ///
  /// In tr, this message translates to:
  /// **'{value} adım'**
  String stepsLabel(String value);

  /// No description provided for @enemyAttackedAfterTimeout.
  ///
  /// In tr, this message translates to:
  /// **'{enemy} saldırdı'**
  String enemyAttackedAfterTimeout(String enemy);

  /// No description provided for @enemyAttackingCycle.
  ///
  /// In tr, this message translates to:
  /// **'{enemy} saldırıyor · {current} / {total}'**
  String enemyAttackingCycle(String enemy, int current, int total);

  /// No description provided for @victoryCoinsTotal.
  ///
  /// In tr, this message translates to:
  /// **'toplam +{total} altın · taban {base} + savaş verimi bonusu {bonus}'**
  String victoryCoinsTotal(String total, String base, String bonus);

  /// No description provided for @damageDealt.
  ///
  /// In tr, this message translates to:
  /// **'Düşmanın {damage} canını aldın!'**
  String damageDealt(int damage);

  /// No description provided for @dailyStepProgressValue.
  ///
  /// In tr, this message translates to:
  /// **'{current} / {goal} adım'**
  String dailyStepProgressValue(String current, String goal);

  /// No description provided for @adventureProgressValue.
  ///
  /// In tr, this message translates to:
  /// **'{current} / {goal} adım — macera ilerlemesi'**
  String adventureProgressValue(String current, String goal);

  /// No description provided for @walkRewardBreakdown.
  ///
  /// In tr, this message translates to:
  /// **'Zafer +{victory} · yürüyüş +{walk} altın · toplam +{total} altın · +{xp} XP'**
  String walkRewardBreakdown(
    String victory,
    String walk,
    String total,
    String xp,
  );

  /// No description provided for @perfectStreakNextCap.
  ///
  /// In tr, this message translates to:
  /// **'Mükemmel seri: — · sıradaki tavan ×{cap}'**
  String perfectStreakNextCap(String cap);

  /// No description provided for @perfectStreakCap.
  ///
  /// In tr, this message translates to:
  /// **'MÜKEMMEL SERİ {count} · tavan ×{cap}'**
  String perfectStreakCap(int count, String cap);

  /// No description provided for @streakBrokenUpper.
  ///
  /// In tr, this message translates to:
  /// **'SERİ KIRILDI · ×1.0'**
  String get streakBrokenUpper;

  /// No description provided for @perfectStreakUpper.
  ///
  /// In tr, this message translates to:
  /// **'MÜKEMMEL · SERİ {count}'**
  String perfectStreakUpper(int count);

  /// No description provided for @newRoundStartedUpper.
  ///
  /// In tr, this message translates to:
  /// **'YENİ ROUND BAŞLADI'**
  String get newRoundStartedUpper;

  /// No description provided for @walkingPhaseUpper.
  ///
  /// In tr, this message translates to:
  /// **'YÜRÜYÜŞ FAZI'**
  String get walkingPhaseUpper;

  /// No description provided for @titleUnequippedNotice.
  ///
  /// In tr, this message translates to:
  /// **'Ünvanın çıkarıldı.'**
  String get titleUnequippedNotice;

  /// No description provided for @titleEquippedNotice.
  ///
  /// In tr, this message translates to:
  /// **'“{name}” ünvanını taktın.'**
  String titleEquippedNotice(String name);

  /// No description provided for @titleOwnedNotice.
  ///
  /// In tr, this message translates to:
  /// **'“{name}” ünvanı zaten sende.'**
  String titleOwnedNotice(String name);

  /// No description provided for @coinsStillNeeded.
  ///
  /// In tr, this message translates to:
  /// **'{count} altın daha gerekiyor.'**
  String coinsStillNeeded(int count);

  /// No description provided for @titlePurchasedNotice.
  ///
  /// In tr, this message translates to:
  /// **'“{name}” ünvanı alındı. Profilden takabilirsin.'**
  String titlePurchasedNotice(String name);

  /// No description provided for @newTitleNotice.
  ///
  /// In tr, this message translates to:
  /// **'Yeni ünvan: {names} — profilden takabilirsin.'**
  String newTitleNotice(String names);

  /// No description provided for @newTitlesNotice.
  ///
  /// In tr, this message translates to:
  /// **'Yeni ünvanlar: {names}'**
  String newTitlesNotice(String names);

  /// No description provided for @newRewardNotice.
  ///
  /// In tr, this message translates to:
  /// **'Yeni ödül: {name}'**
  String newRewardNotice(String name);

  /// No description provided for @newRewardsNotice.
  ///
  /// In tr, this message translates to:
  /// **'{count} yeni ödül koleksiyonuna eklendi!'**
  String newRewardsNotice(int count);

  /// No description provided for @enemyAttackNotice.
  ///
  /// In tr, this message translates to:
  /// **'{enemy} senin {damage} canını aldı.'**
  String enemyAttackNotice(String enemy, int damage);

  /// No description provided for @perfectRoundNotice.
  ///
  /// In tr, this message translates to:
  /// **'Mükemmel round! Seri {streak} · hasar ×{multiplier}'**
  String perfectRoundNotice(int streak, String multiplier);

  /// No description provided for @perfectRoundBrokenNotice.
  ///
  /// In tr, this message translates to:
  /// **'Mükemmel round serin kırıldı. Çarpan ×1’e döndü.'**
  String get perfectRoundBrokenNotice;

  /// No description provided for @itemPurchasedNotice.
  ///
  /// In tr, this message translates to:
  /// **'{name} satın alındı!'**
  String itemPurchasedNotice(String name);

  /// No description provided for @itemPurchasedCountNotice.
  ///
  /// In tr, this message translates to:
  /// **'{name} satın alındı. Artık {count} adet.'**
  String itemPurchasedCountNotice(String name, int count);

  /// No description provided for @itemMissingNotice.
  ///
  /// In tr, this message translates to:
  /// **'Bu eşya envanterinde yok.'**
  String get itemMissingNotice;

  /// No description provided for @itemCatalogMissingNotice.
  ///
  /// In tr, this message translates to:
  /// **'Bu eşya artık katalogda yok.'**
  String get itemCatalogMissingNotice;

  /// No description provided for @itemWrongClassNotice.
  ///
  /// In tr, this message translates to:
  /// **'{name} senin sınıfın için değil.'**
  String itemWrongClassNotice(String name);

  /// No description provided for @itemEquippedNotice.
  ///
  /// In tr, this message translates to:
  /// **'{name} kuşanıldı.'**
  String itemEquippedNotice(String name);

  /// No description provided for @itemEquippedReplacedNotice.
  ///
  /// In tr, this message translates to:
  /// **'{name} kuşanıldı, {replaced} çıkarıldı.'**
  String itemEquippedReplacedNotice(String name, String replaced);

  /// No description provided for @itemRemovedNotice.
  ///
  /// In tr, this message translates to:
  /// **'{name} çıkarıldı.'**
  String itemRemovedNotice(String name);

  /// No description provided for @itemSoldNotice.
  ///
  /// In tr, this message translates to:
  /// **'{name} satıldı. +{value} coin.'**
  String itemSoldNotice(String name, int value);

  /// No description provided for @itemRemovedSoldNotice.
  ///
  /// In tr, this message translates to:
  /// **'{name} çıkarılıp satıldı. +{value} coin.'**
  String itemRemovedSoldNotice(String name, int value);

  /// No description provided for @reincarnationNeededNotice.
  ///
  /// In tr, this message translates to:
  /// **'Karakterini değiştirmek için Reenkarnasyon İksiri gerekli.'**
  String get reincarnationNeededNotice;

  /// No description provided for @reincarnationCompleteNotice.
  ///
  /// In tr, this message translates to:
  /// **'Reenkarnasyon tamamlandı. İksir tüketildi.'**
  String get reincarnationCompleteNotice;

  /// No description provided for @levelUpUpper.
  ///
  /// In tr, this message translates to:
  /// **'SEVİYE {level}!'**
  String levelUpUpper(int level);

  /// No description provided for @levelsGainedNotice.
  ///
  /// In tr, this message translates to:
  /// **'{count} seviye birden atladın. Adımların karşılığını veriyor!'**
  String levelsGainedNotice(int count);

  /// No description provided for @nextLevelEncouragement.
  ///
  /// In tr, this message translates to:
  /// **'Yürümeye devam et, sıradaki seviye yaklaşıyor.'**
  String get nextLevelEncouragement;

  /// No description provided for @revivalDoneNotice.
  ///
  /// In tr, this message translates to:
  /// **'Hayat Yürüyüşü tamamlandı. Yeniden doğdun! Bu 500 adım XP kazandırmadı.'**
  String get revivalDoneNotice;

  /// No description provided for @revivalRequiredNotice.
  ///
  /// In tr, this message translates to:
  /// **'Yeni bir macera için önce 500 adımlık Hayat Yürüyüşünü tamamla.'**
  String get revivalRequiredNotice;

  /// No description provided for @revivalRemainingNotice.
  ///
  /// In tr, this message translates to:
  /// **'Maceralara dönmek için Hayat Yürüyüşünde {count} adım daha atmalısın.'**
  String revivalRemainingNotice(int count);

  /// No description provided for @streakFreezeUsedNotice.
  ///
  /// In tr, this message translates to:
  /// **'Serin korundu, 1 dondurma hakkı kullanıldı. {remaining}'**
  String streakFreezeUsedNotice(String remaining);

  /// No description provided for @freezeRemaining.
  ///
  /// In tr, this message translates to:
  /// **'Kalan hak: {count}.'**
  String freezeRemaining(int count);

  /// No description provided for @noFreezesRemaining.
  ///
  /// In tr, this message translates to:
  /// **'Hakkın kalmadı.'**
  String get noFreezesRemaining;

  /// No description provided for @streakMilestoneFreeze.
  ///
  /// In tr, this message translates to:
  /// **'{days} günlük seri! Kilometre taşı ödülün: 1 dondurma hakkı.'**
  String streakMilestoneFreeze(int days);

  /// No description provided for @streakMilestoneStockFull.
  ///
  /// In tr, this message translates to:
  /// **'{days} günlük seri! Kilometre taşına ulaştın (dondurma stoğun zaten dolu).'**
  String streakMilestoneStockFull(int days);

  /// No description provided for @streakBonusLostNotice.
  ///
  /// In tr, this message translates to:
  /// **'Serin kırıldı. Biriktirdiğin +%{rate} savaş bonusu sıfırlandı.'**
  String streakBonusLostNotice(String rate);

  /// No description provided for @freezeStockFullNotice.
  ///
  /// In tr, this message translates to:
  /// **'Dondurma hakkı stoğun dolu ({count}). Para harcanmadı.'**
  String freezeStockFullNotice(int count);

  /// No description provided for @wheelStockFullNotice.
  ///
  /// In tr, this message translates to:
  /// **'Ekstra çark hakkı stoğun dolu ({count}). Para harcanmadı.'**
  String wheelStockFullNotice(int count);

  /// No description provided for @doubleXpAlreadyActiveNotice.
  ///
  /// In tr, this message translates to:
  /// **'2× XP zaten etkin. Para harcanmadı.'**
  String get doubleXpAlreadyActiveNotice;

  /// No description provided for @storeReincarnationName.
  ///
  /// In tr, this message translates to:
  /// **'Reenkarnasyon İksiri'**
  String get storeReincarnationName;

  /// No description provided for @storeReincarnationDescription.
  ///
  /// In tr, this message translates to:
  /// **'Karakterini ve sınıfını bir kez yeniden seçmeni sağlar. Düzenleme tamamlandığında tüketilir.'**
  String get storeReincarnationDescription;

  /// No description provided for @storeDoubleXpName.
  ///
  /// In tr, this message translates to:
  /// **'2× XP Boost (1 gün)'**
  String get storeDoubleXpName;

  /// No description provided for @storeDoubleXpDescription.
  ///
  /// In tr, this message translates to:
  /// **'Gün sonuna kadar kazandığın tüm XP’yi ikiye katlar (adım, düşman ve çark dahil).'**
  String get storeDoubleXpDescription;

  /// No description provided for @storeExtraSpinName.
  ///
  /// In tr, this message translates to:
  /// **'Ekstra Çark Hakkı'**
  String get storeExtraSpinName;

  /// No description provided for @storeExtraSpinDescription.
  ///
  /// In tr, this message translates to:
  /// **'Günlük hakkın bittikten sonra çarkı bir kez daha çevir. Stok en fazla {count}.'**
  String storeExtraSpinDescription(int count);

  /// No description provided for @storeStreakFreezeName.
  ///
  /// In tr, this message translates to:
  /// **'Seri Dondurma Hakkı'**
  String get storeStreakFreezeName;

  /// No description provided for @storeStreakFreezeDescription.
  ///
  /// In tr, this message translates to:
  /// **'Bir günü kaçırırsan serin otomatik korunur. Stok en fazla {count}.'**
  String storeStreakFreezeDescription(int count);

  /// No description provided for @statAttack.
  ///
  /// In tr, this message translates to:
  /// **'saldırı'**
  String get statAttack;

  /// No description provided for @statDefense.
  ///
  /// In tr, this message translates to:
  /// **'savunma'**
  String get statDefense;

  /// No description provided for @statMaxHealth.
  ///
  /// In tr, this message translates to:
  /// **'savaş canı'**
  String get statMaxHealth;

  /// No description provided for @statCritChance.
  ///
  /// In tr, this message translates to:
  /// **'kritik şansı'**
  String get statCritChance;

  /// No description provided for @statCritDamage.
  ///
  /// In tr, this message translates to:
  /// **'kritik hasarı'**
  String get statCritDamage;

  /// No description provided for @statLifeSteal.
  ///
  /// In tr, this message translates to:
  /// **'can çalma'**
  String get statLifeSteal;

  /// No description provided for @statDodge.
  ///
  /// In tr, this message translates to:
  /// **'sıyrılma'**
  String get statDodge;

  /// No description provided for @statSpeed.
  ///
  /// In tr, this message translates to:
  /// **'hız'**
  String get statSpeed;

  /// No description provided for @statLuck.
  ///
  /// In tr, this message translates to:
  /// **'şans'**
  String get statLuck;

  /// No description provided for @statStepCoin.
  ///
  /// In tr, this message translates to:
  /// **'adım parası'**
  String get statStepCoin;

  /// No description provided for @statStepXp.
  ///
  /// In tr, this message translates to:
  /// **'adım XP'**
  String get statStepXp;

  /// No description provided for @statWheelXp.
  ///
  /// In tr, this message translates to:
  /// **'çark XP'**
  String get statWheelXp;

  /// No description provided for @statEnemyXp.
  ///
  /// In tr, this message translates to:
  /// **'düşman XP'**
  String get statEnemyXp;

  /// No description provided for @statDailyCoinCap.
  ///
  /// In tr, this message translates to:
  /// **'günlük coin sınırı'**
  String get statDailyCoinCap;

  /// No description provided for @statStreakFreezeCap.
  ///
  /// In tr, this message translates to:
  /// **'dondurma stoğu'**
  String get statStreakFreezeCap;

  /// No description provided for @statWheelSpinCap.
  ///
  /// In tr, this message translates to:
  /// **'çark hakkı stoğu'**
  String get statWheelSpinCap;

  /// No description provided for @statStreakRelief.
  ///
  /// In tr, this message translates to:
  /// **'seri eşiği'**
  String get statStreakRelief;

  /// No description provided for @effectAlways.
  ///
  /// In tr, this message translates to:
  /// **'{stat} {value}'**
  String effectAlways(String stat, String value);

  /// No description provided for @effectLowHealth.
  ///
  /// In tr, this message translates to:
  /// **'can %{threshold} altındayken {stat} {value}'**
  String effectLowHealth(String threshold, String stat, String value);

  /// No description provided for @effectHighHealth.
  ///
  /// In tr, this message translates to:
  /// **'can %{threshold} üstündeyken {stat} {value}'**
  String effectHighHealth(String threshold, String stat, String value);

  /// No description provided for @effectOnHit.
  ///
  /// In tr, this message translates to:
  /// **'vuruşta %{chance} ihtimalle {stat} {value}'**
  String effectOnHit(String chance, String stat, String value);

  /// No description provided for @effectOnKill.
  ///
  /// In tr, this message translates to:
  /// **'düşman yenince {stat} {value}'**
  String effectOnKill(String stat, String value);

  /// No description provided for @effectUntouchedRounds.
  ///
  /// In tr, this message translates to:
  /// **'{rounds} tur hasarsız kalınca {stat} {value}'**
  String effectUntouchedRounds(String rounds, String stat, String value);

  /// No description provided for @effectNightWalk.
  ///
  /// In tr, this message translates to:
  /// **'gece yapılan savaşlarda {stat} {value}'**
  String effectNightWalk(String stat, String value);

  /// No description provided for @effectStreakActive.
  ///
  /// In tr, this message translates to:
  /// **'serin ayaktayken {stat} {value}'**
  String effectStreakActive(String stat, String value);

  /// No description provided for @signatureItemLore.
  ///
  /// In tr, this message translates to:
  /// **'Kendine özgü bir savaş özelliği taşıyan imzalı eşya.'**
  String get signatureItemLore;

  /// No description provided for @adventurePhaseCombat.
  ///
  /// In tr, this message translates to:
  /// **'Savaş fazı'**
  String get adventurePhaseCombat;

  /// No description provided for @adventurePhaseWalk.
  ///
  /// In tr, this message translates to:
  /// **'Yürüyüş fazı'**
  String get adventurePhaseWalk;

  /// No description provided for @adventurePhaseCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Macera tamamlandı'**
  String get adventurePhaseCompleted;

  /// No description provided for @adventurePhaseRevival.
  ///
  /// In tr, this message translates to:
  /// **'Hayat Yürüyüşü'**
  String get adventurePhaseRevival;

  /// No description provided for @adventurePhaseRevivalCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Hayat Yürüyüşü tamamlandı'**
  String get adventurePhaseRevivalCompleted;

  /// No description provided for @titleLoreAchievement.
  ///
  /// In tr, this message translates to:
  /// **'{name}, güç kazanılmış bir başarımın kanıtıdır.'**
  String titleLoreAchievement(String name);

  /// No description provided for @titleLorePurchase.
  ///
  /// In tr, this message translates to:
  /// **'{name}, önündeki yol için seçilmiş bir işarettir.'**
  String titleLorePurchase(String name);

  /// No description provided for @titleLoreWheel.
  ///
  /// In tr, this message translates to:
  /// **'{name}, çarkın talihli bir dönüşüyle kazanıldı.'**
  String titleLoreWheel(String name);

  /// No description provided for @titleLoreMilestone.
  ///
  /// In tr, this message translates to:
  /// **'{name}, uzun süreli bağlılığı simgeler.'**
  String titleLoreMilestone(String name);

  /// No description provided for @titleUnlockPurchase.
  ///
  /// In tr, this message translates to:
  /// **'Mağazadan {cost} altına satın al.'**
  String titleUnlockPurchase(int cost);

  /// No description provided for @titleUnlockWheel.
  ///
  /// In tr, this message translates to:
  /// **'Günlük çarktan çıkabilir.'**
  String get titleUnlockWheel;

  /// No description provided for @titleUnlockMilestone.
  ///
  /// In tr, this message translates to:
  /// **'{days} günlük seri kilometre taşı ödülü.'**
  String titleUnlockMilestone(int days);

  /// No description provided for @titleUnlockPlaying.
  ///
  /// In tr, this message translates to:
  /// **'Oynayarak kazanılır.'**
  String get titleUnlockPlaying;

  /// No description provided for @titleConditionLevel.
  ///
  /// In tr, this message translates to:
  /// **'{count}. seviyeye ulaş'**
  String titleConditionLevel(int count);

  /// No description provided for @titleConditionSteps.
  ///
  /// In tr, this message translates to:
  /// **'Toplam {count} adım at'**
  String titleConditionSteps(String count);

  /// No description provided for @titleConditionStreak.
  ///
  /// In tr, this message translates to:
  /// **'{count} günlük seri yap'**
  String titleConditionStreak(int count);

  /// No description provided for @titleConditionEnemies.
  ///
  /// In tr, this message translates to:
  /// **'{count} düşman devir'**
  String titleConditionEnemies(int count);

  /// No description provided for @titleConditionAdventures.
  ///
  /// In tr, this message translates to:
  /// **'{count} macerayı tamamla'**
  String titleConditionAdventures(int count);

  /// No description provided for @titleConditionItems.
  ///
  /// In tr, this message translates to:
  /// **'{count} eşya topla'**
  String titleConditionItems(int count);

  /// No description provided for @titleConditionItemLevel.
  ///
  /// In tr, this message translates to:
  /// **'Bir eşyayı Sv. {count} yap'**
  String titleConditionItemLevel(int count);

  /// No description provided for @titleConditionWheelSpins.
  ///
  /// In tr, this message translates to:
  /// **'Çarkı {count} kez çevir'**
  String titleConditionWheelSpins(int count);

  /// No description provided for @titleConditionMerges.
  ///
  /// In tr, this message translates to:
  /// **'{count} eşya birleştir'**
  String titleConditionMerges(int count);

  /// No description provided for @titleConditionCoins.
  ///
  /// In tr, this message translates to:
  /// **'Toplam {count} altın kazan'**
  String titleConditionCoins(String count);

  /// No description provided for @wheelCoinsLabel.
  ///
  /// In tr, this message translates to:
  /// **'+{count} altın'**
  String wheelCoinsLabel(int count);

  /// No description provided for @wheelXpLabel.
  ///
  /// In tr, this message translates to:
  /// **'+{count} XP'**
  String wheelXpLabel(int count);

  /// No description provided for @streakStatBonusNotice.
  ///
  /// In tr, this message translates to:
  /// **'{day}. gün: +%{gain} {stat} (seriden toplam +%{total})'**
  String streakStatBonusNotice(int day, String gain, String stat, String total);

  /// No description provided for @streakCycleRestarted.
  ///
  /// In tr, this message translates to:
  /// **' · Döngü başa döndü! Gün başına kazanç yeniden +%{gain}.'**
  String streakCycleRestarted(String gain);

  /// No description provided for @upgradeBlockedRarity.
  ///
  /// In tr, this message translates to:
  /// **'Nadirlik sınırı ({rarity}: {cap}). Daha ileri gitmek için birleştirerek nadirliğini yükseltmelisin.'**
  String upgradeBlockedRarity(String rarity, int cap);

  /// No description provided for @upgradeBlockedLevel.
  ///
  /// In tr, this message translates to:
  /// **'Eşya kendi seviyeni geçemez (Sv. {level}). Sen yükseldikçe eşyan da yükselebilir.'**
  String upgradeBlockedLevel(int level);

  /// No description provided for @coinsRequired.
  ///
  /// In tr, this message translates to:
  /// **'{count} coin gerekiyor.'**
  String coinsRequired(int count);

  /// No description provided for @mergeBlockedMaxRarity.
  ///
  /// In tr, this message translates to:
  /// **'{rarity} en üst nadirlik; birleştirilemez.'**
  String mergeBlockedMaxRarity(String rarity);

  /// No description provided for @mergeBlockedCopies.
  ///
  /// In tr, this message translates to:
  /// **'Birleştirmek için {required} adet gerekiyor, elinde {available} adet var.'**
  String mergeBlockedCopies(int required, int available);

  /// No description provided for @mergeCompletedNotice.
  ///
  /// In tr, this message translates to:
  /// **'{count} adet {name} birleştirildi: artık {rarity}, Sv. 1.'**
  String mergeCompletedNotice(int count, String name, String rarity);

  /// No description provided for @mergeCompletedUnequippedNotice.
  ///
  /// In tr, this message translates to:
  /// **'{name} çıkarıldı ve {count} adet birleştirildi: artık {rarity}, Sv. 1.'**
  String mergeCompletedUnequippedNotice(String name, int count, String rarity);

  /// No description provided for @durationSecondsLong.
  ///
  /// In tr, this message translates to:
  /// **'{count} saniye'**
  String durationSecondsLong(int count);

  /// No description provided for @durationMinutesLong.
  ///
  /// In tr, this message translates to:
  /// **'{count} dakika'**
  String durationMinutesLong(int count);

  /// No description provided for @shadowDragonName.
  ///
  /// In tr, this message translates to:
  /// **'Gölge Ejderhası'**
  String get shadowDragonName;

  /// No description provided for @shadowDragonDescription.
  ///
  /// In tr, this message translates to:
  /// **'20.000 adım atarak ejderhayı yen, ödülünü kap.'**
  String get shadowDragonDescription;

  /// No description provided for @youMemberName.
  ///
  /// In tr, this message translates to:
  /// **'Sen'**
  String get youMemberName;

  /// No description provided for @dragonStepsProgress.
  ///
  /// In tr, this message translates to:
  /// **'{current} / {target} adım'**
  String dragonStepsProgress(int current, int target);

  /// No description provided for @itemUpgradedNotice.
  ///
  /// In tr, this message translates to:
  /// **'{name} Sv. {level} oldu. -{cost} coin.'**
  String itemUpgradedNotice(String name, int level, int cost);

  /// No description provided for @classBat.
  ///
  /// In tr, this message translates to:
  /// **'Gece Kanadı'**
  String get classBat;

  /// No description provided for @classLancer.
  ///
  /// In tr, this message translates to:
  /// **'Fırtına Mızrakçısı'**
  String get classLancer;

  /// No description provided for @classNecromancer.
  ///
  /// In tr, this message translates to:
  /// **'Ruh Çağıran'**
  String get classNecromancer;

  /// No description provided for @classOrcRider.
  ///
  /// In tr, this message translates to:
  /// **'Bozkır Binicisi'**
  String get classOrcRider;

  /// No description provided for @leaveAdventureTitle.
  ///
  /// In tr, this message translates to:
  /// **'Maceradan ayrılmak istiyor musun?'**
  String get leaveAdventureTitle;

  /// No description provided for @leaveAdventureWalkWarning.
  ///
  /// In tr, this message translates to:
  /// **'Zaferi kazandın! Bonus yürüyüşü bırakırsan zafer ödüllerin, kazandığın altın ve günlük çark hakkın korunur. Yalnızca bu maceranın bonus altın oranı sona erer. Yeni macera seçmek istiyor musun?'**
  String get leaveAdventureWalkWarning;

  /// No description provided for @leaveAdventureWarning.
  ///
  /// In tr, this message translates to:
  /// **'Düşmanı yenmeden ayrılırsan macera ilerlemen kaybolur ve bu maceradan ödül kazanamazsın. Günlük adımların ve yürüyüşten kazandıkların korunur. Emin misin?'**
  String get leaveAdventureWarning;

  /// No description provided for @stayInAdventure.
  ///
  /// In tr, this message translates to:
  /// **'Maceraya devam et'**
  String get stayInAdventure;

  /// No description provided for @dailyStepsExplanation.
  ///
  /// In tr, this message translates to:
  /// **'Günlük adımların macera hedefinden ayrıdır. Yürüyüş ödüllerinde günlük üst sınır yoktur.'**
  String get dailyStepsExplanation;

  /// No description provided for @dailyNotificationChannel.
  ///
  /// In tr, this message translates to:
  /// **'Günlük seri ve çark'**
  String get dailyNotificationChannel;

  /// No description provided for @streakReminderTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kahramanın seni bekliyor!'**
  String get streakReminderTitle;

  /// No description provided for @streakReminderBody.
  ///
  /// In tr, this message translates to:
  /// **'Hadi ama, bugünkü serimizi de tamamlayalım! Biraz yürüyüş ya da bir zafer yeter. Ben burada seni bekliyorum!'**
  String get streakReminderBody;

  /// No description provided for @streakCompleteTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günlük seri tamamlandı!'**
  String get streakCompleteTitle;

  /// No description provided for @streakCompleteBody.
  ///
  /// In tr, this message translates to:
  /// **'Serin {days} güne ulaştı. Böyle devam et!'**
  String streakCompleteBody(int days);

  /// No description provided for @streakCelebrationTitle.
  ///
  /// In tr, this message translates to:
  /// **'{days} günlük seri!'**
  String streakCelebrationTitle(int days);

  /// No description provided for @streakCelebrationBody.
  ///
  /// In tr, this message translates to:
  /// **'Bugün de kendin için bir adım attın. Kahramanın seninle gurur duyuyor. Böyle devam et!'**
  String get streakCelebrationBody;

  /// No description provided for @dailyContinue.
  ///
  /// In tr, this message translates to:
  /// **'Devam et'**
  String get dailyContinue;

  /// No description provided for @wheelReadyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Çark tamir edildi!'**
  String get wheelReadyTitle;

  /// No description provided for @wheelReadyBody.
  ///
  /// In tr, this message translates to:
  /// **'Günlük çarkın hazır. Çarkı çevirmek ister misin?'**
  String get wheelReadyBody;

  /// No description provided for @wheelReadyNotification.
  ///
  /// In tr, this message translates to:
  /// **'Günlük çarkın açıldı! Ödülün seni bekliyor.'**
  String get wheelReadyNotification;

  /// No description provided for @goToWheel.
  ///
  /// In tr, this message translates to:
  /// **'Çarka git'**
  String get goToWheel;

  /// No description provided for @wheelLater.
  ///
  /// In tr, this message translates to:
  /// **'Daha sonra bakacağım'**
  String get wheelLater;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
