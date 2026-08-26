import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../../core/constants/game_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/coin_calculator.dart';
import '../../core/utils/effective_stats.dart';
import '../../core/utils/equipped_buffs.dart';
import '../../core/utils/game_clock.dart';
import '../../core/utils/item_leveling.dart';
import '../../core/utils/item_merging.dart';
import '../../core/utils/item_rules.dart';
import '../../core/utils/step_history.dart';
import '../../core/utils/step_rate_limiter.dart';
import '../../core/utils/wheel_rewards.dart';
import '../../core/utils/xp_calculator.dart';
import '../../data/mock_data.dart';
import '../../models/adventure_quest.dart';
import '../../models/avatar_profile.dart';
import '../../models/combat_stats.dart';
import '../../models/daily_progress.dart';
import '../../models/daily_step_record.dart';
import '../../models/game_state.dart';
import '../../models/item.dart';
import '../../models/item_effect.dart';
import '../../models/owned_item.dart';
import '../../models/reward.dart';
import '../../models/reward_rarity.dart';
import '../../models/tutorial_guide_variant.dart';
import '../../models/user_profile.dart';
import '../../models/wheel_reward.dart';
import '../../models/xp_store_item.dart';
import '../../services/adventure_notification_service.dart';
import '../../services/game_storage.dart';
import '../../services/item_catalog.dart';
import '../../services/level_events.dart';
import '../../services/pedometer_step_source.dart';
import '../../services/raw_step_sensor.dart';
import '../../services/step_permission_service.dart';
import '../../services/step_source.dart';
import '../adventure/adventure_screen.dart';
import '../character/character_creation_screen.dart';
import '../home/home_screen.dart';
import '../inventory/blacksmith_screen.dart';
import '../inventory/inventory_screen.dart';
import '../profile/profile_screen.dart';
import '../rewards/rewards_screen.dart';
import '../store/xp_store_screen.dart';
import '../team/team_screen.dart';
import '../tutorial/tutorial_guide.dart';
import '../wheel/daily_wheel_screen.dart';

/// Uygulamanın kök iskeleti: alt gezinme çubuğu ve tüm oyun durumunun
/// (state) tutulduğu yer. Şimdilik setState ile yerel state kullanır;
/// ileride bir state-management çözümüne (Riverpod/Bloc) taşınabilir.
///
/// Durum [GameStorage] ile diske yazılır: her değişimde [_persist] çağrılır,
/// uygulama arka plana alınırken veya kapanırken bekleyen yazma tamamlanır.
class RootShell extends StatefulWidget {
  final AvatarProfile avatar;

  /// Diskten okunan oyun durumu. Yeni oyuncuda veya kayıt bozuksa null gelir.
  final GameState? initialState;

  final ValueChanged<AvatarProfile> onAvatarChanged;

  /// Uygulama girişinde tutorial sistemini etkinleştirir. Widget testleri ve
  /// bağımsız ekran kullanımları varsayılan olarak mevcut davranışı korur.
  final bool startTutorial;

  /// Store review entegrasyonu eklendiğinde bağlanacak isteğe bağlı çıkış.
  final VoidCallback? onRequestReview;
  final TutorialGuideVariant? initialTutorialGuide;

  const RootShell({
    super.key,
    required this.avatar,
    required this.onAvatarChanged,
    this.initialState,
    this.startTutorial = false,
    this.onRequestReview,
    this.initialTutorialGuide,
  });

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> with WidgetsBindingObserver {
  int _tabIndex = 0;

  late final UserProfile _profile;
  late DailyProgress _today;
  AdventureQuest? _adventure;
  late List<DailyStepRecord> _stepHistory;
  final List<Reward> _rewards = [];
  late final _team = MockData.defaultTeam();
  final List<XpStoreItem> _storeItems = MockData.storeItems();

  /// Oyuncunun sınıfının kuşanabileceği ekipman. Katalog asset taramasıyla
  /// üretildiği için asenkron gelir; okunana kadar mağazanın ekipman bölümü
  /// boş görünür, geri kalanı çalışır.
  List<Item> _equipment = const [];

  /// Kuşanılan itemlerin toplam etkisi. Kuşanma her değiştiğinde yeniden
  /// hesaplanır; sekiz uygulama noktası **yalnızca** buradan okur.
  EquippedBuffs _buffs = EquippedBuffs.none;

  /// İtilen ekranların (envanter) kendini tazelemesi için sayaç.
  ///
  /// [_push] ile açılan bir rota kök Navigator'ın overlay'inde durur, yani
  /// [RootShell]'in alt ağacında değildir ve `setState` onu tazelemez
  /// (bkz. GD11). Envanter canlı state göstermek zorunda olduğu için bu
  /// sayacı dinliyor; [_persist] her anlamlı değişimde artırıyor.
  final ValueNotifier<int> _revision = ValueNotifier(0);

  /// Adım kaynağı: gerçek pedometer ya da demo kontrolleri.
  ///
  /// Kaynak kim olursa olsun akış tek yerden geçer ([_onStepsReported]).
  /// Sensörün sıfırlanması [PedometerStepSource] içinde emildiği için burada
  /// hiçbir zaman azalan bir kümülatif değer görülmez.
  late StepSource _stepSource;
  StreamSubscription<int>? _stepSubscription;
  StreamSubscription<StepSensorFailure>? _sensorFailureSubscription;

  /// Demo kaynağı debug'da varsayılan: emülatörde adım üretebilmek şart.
  /// Release'de her zaman gerçek sensör kullanılır.
  bool _useManualSource = kDebugMode;

  StepPermissionStatus _stepPermission = StepPermissionStatus.unknown;

  Timer? _adventureClock;
  bool _isForeground = true;
  final Random _random = Random();
  final ValueNotifier<TutorialGuideStep> _tutorialStep = ValueNotifier(
    TutorialGuideStep.welcome,
  );
  bool _tutorialBattleRunning = false;

  bool get _tutorialActive =>
      widget.startTutorial && !_profile.hasCompletedTutorial;

  /// Dondurma hakkı yükseltmesinin kimliği ([MockData.storeItems]).
  /// Satın alma stoğu [UserProfile.grantStreakFreeze] üzerinden büyütür.
  static const _streakFreezeItemId = 'upgrade_streak_freeze';

  /// Ekstra çark hakkı yükseltmesinin kimliği ([MockData.storeItems]).
  static const _extraWheelSpinItemId = 'wheel_extra_spin';

  /// "2x XP" yükseltmesinin kimliği ([MockData.storeItems]).
  static const _xpBoostItemId = 'boost_double_xp';
  static const _reincarnationPotionId = 'reincarnation_potion';

  static const _reminderMessages = [
    '{round}. round: {enemy} için {steps} adım kaldı.',
    '{round}. round devam ediyor! {steps} adım daha atmalısın.',
    'Ritmini kaybetme; {round}. roundda kalan adım: {steps}.',
    '{round}. round: {enemy} gücünü koruyor, {steps} adım kaldı.',
  ];

  @override
  void initState() {
    super.initState();
    _restoreState();
    _attachStepSource();
    unawaited(_loadItemCatalog());
    WidgetsBinding.instance.addObserver(this);
    _adventureClock = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tick(),
    );
  }

  /// Item kataloğunu yükler ve oyuncunun sınıfına göre süzer.
  ///
  /// Katalog okunamazsa [ItemCatalog.load] boş liste döner ve loglar; mağaza
  /// ekipmansız açılır, oyunun geri kalanı etkilenmez.
  Future<void> _loadItemCatalog() async {
    await ItemCatalog.load();
    if (!mounted) return;
    setState(() {
      _equipment = ItemCatalog.forCharacterClass(
        _profile.avatar.characterClass,
      );
      // Kuşanma ancak katalog geldikten sonra çözülebilir; buff'lar da o
      // ana kadar boş kalır. Ekonomi bu yüzden bir süre buff'sız çalışır —
      // katalog okunması milisaniyeler sürüyor ve buff'sız hesap **eksik**
      // değil, yalnızca bonussuz. Sessiz bir hata değil.
      _refreshEquipment();
    });
    if (_tutorialStep.value == TutorialGuideStep.combatDemo) {
      unawaited(_completeFirstTutorialAdventure());
    }
  }

  Item? get _tutorialStarterWeapon {
    final storedId = _profile.tutorialStarterItemId;
    if (storedId != null) {
      for (final item in _equipment) {
        if (item.id == storedId) return item;
      }
    }
    for (final item in _equipment) {
      if (item.isUnlockedAt(_profile.level) &&
          item.category.role != ItemRole.defense) {
        _profile.tutorialStarterItemId = item.id;
        return item;
      }
    }
    return null;
  }

  /// Savaş motoruna verilecek anlık koşullar.
  ///
  /// Koşullu item etkileri (`lowHealth`, `untouchedRounds`, `nightWalk`,
  /// `streakActive`) buradan açılıp kapanıyor.
  CombatConditions _combatConditions(AdventureQuest? adventure) {
    final now = GameClock.now();
    return CombatConditions(
      healthRatio: adventure?.playerHealthProgress ?? 1,
      untouchedRounds: adventure?.untouchedRounds ?? 0,
      // Gece yürüyüşü: gün ışığı dışındaki saatler.
      nightWalk: now.hour < 6 || now.hour >= 18,
      streakActive: _profile.streakDays > 0,
    );
  }

  /// Oyuncunun o andaki savaş statları: taban + ekipman + seri + koşullu.
  ///
  /// Tek toplama noktası [effectiveCombatStats]; burada ikinci bir hesap yok.
  CombatStats _playerCombatStats([AdventureQuest? adventure]) =>
      effectiveCombatStats(
        level: _profile.level,
        buffs: _buffs,
        streak: _profile.streakStatBonuses,
        conditions: _combatConditions(adventure),
      );

  /// Maceradaki can tavanını güncel statlara göre tazeler.
  ///
  /// Seviye atlamak ya da ekipman değiştirmek can tavanını büyütür/küçültür;
  /// mevcut can tavanı aşamaz. Macera nesnesi tek doğruluk kaynağı olduğu
  /// için ekranlar bunu ayrıca hesaplamıyor.
  void _syncAdventureStats() {
    final adventure = _adventure;
    if (adventure == null) return;
    final maxHealth = _playerCombatStats(adventure).maxHealth.round();
    if (maxHealth <= 0) return;
    adventure.playerMaxHealth = maxHealth;
    if (adventure.playerHealth > maxHealth) {
      adventure.playerHealth = maxHealth;
    }
  }

  /// Kuşanılan örnekleri katalogdan çözer ve toplam buff'ı yeniden hesaplar.
  ///
  /// Dört şeyi birden temizler:
  /// - katalogdan kalkmış kimlikler (kuşanma düşer),
  /// - oyuncunun sınıfının kullanamadığı kategoriler (sınıf değişimi),
  /// - seviye kilidi artık tutmayan örnekler,
  /// - **aynı slotta ikinci bir örnek** — slot başına tek eşya kuralı
  ///   eskiden `Map` yapısıyla veri düzeyinde zorlanıyordu (GD26); envanter
  ///   örnek listesine geçince (GD39) kural buraya taşındı.
  ///
  /// **Sahiplik kaydına dokunmaz**: yalnızca kuşanma düşer (GD28).
  /// `setState` içinden çağrılabilsin diye kendisi `setState` çağırmaz.
  void _refreshEquipment() {
    final characterClass = _profile.avatar.characterClass;
    final resolved = <Item>[];
    final usedSlots = <String>{};

    for (var i = 0; i < _profile.ownedItems.length; i++) {
      final instance = _profile.ownedItems[i];
      if (!instance.equipped) continue;

      final item = _resolveInstance(instance);
      if (item == null ||
          !item.isUsableBy(characterClass) ||
          !usedSlots.add(item.category.folder)) {
        _profile.ownedItems[i] = instance.copyWith(equipped: false);
        continue;
      }
      resolved.add(item);
    }
    _buffs = EquippedBuffs.from(resolved);
    // Kuşanma can tavanını değiştirmiş olabilir.
    _syncAdventureStats();
  }

  /// Bir envanter örneğini katalogdan çözer: sınıfa uyarlanmış item +
  /// örneğin nadirliği + örneğin seviyesi. Katalogda yoksa `null`.
  Item? _resolveInstance(OwnedItem instance) {
    final characterClass = _profile.avatar.characterClass;
    final base = ItemCatalog.byId(
      instance.itemId,
      characterClass: characterClass,
    );
    if (base == null) return null;
    return resolveOwnedItem(base, instance, characterClass: characterClass);
  }

  /// Kuşanılan itemler, sınıfa uyarlanmış ve seviyesi uygulanmış hâlleriyle.
  List<Item> get _equippedItems => [
    for (final instance in _profile.equippedInstances)
      if (_resolveInstance(instance) case final item?) item,
  ];

  /// Seçili adım kaynağını kurar ve dinlemeye başlar.
  ///
  /// Kaynak, kalıcı sayaçtan tohumlanır: [UserProfile.lastReportedStepCount]
  /// ile [UserProfile.lastSensorReading] birlikte yazıldığı için kapat-aç
  /// sonrasında sayaç kaldığı yerden devam eder — Android'de uygulama
  /// kapalıyken atılan adımlar da bu aritmetikten gelir.
  void _attachStepSource() {
    final source = _createStepSource();
    _stepSource = source;
    _stepSubscription = source.changes.listen(_onStepsReported);
    if (source is PedometerStepSource) {
      _sensorFailureSubscription = source.failures.listen(_onSensorFailure);
      unawaited(_startPhysicalSource(source));
    }
  }

  StepSource _createStepSource() {
    if (_useManualSource) {
      return ManualStepSource(initialSteps: _profile.lastReportedStepCount);
    }
    final sensor = createPlatformStepSensor();
    if (sensor == null) {
      // Desteklenmeyen platform: oyun çalışmaya devam eder, adım gelmez.
      _stepPermission = StepPermissionStatus.unavailable;
      return ManualStepSource(initialSteps: _profile.lastReportedStepCount);
    }
    return PedometerStepSource(
      sensor: sensor,
      restoredTotal: _profile.lastReportedStepCount,
      restoredReading: _profile.lastSensorReading,
    );
  }

  /// İzni kontrol eder, gerekiyorsa ister ve sensörü başlatır.
  ///
  /// İzin verilmezse hiçbir şey çökmez: sensör başlatılmaz, ana ekranda
  /// açıklayıcı bir kart çıkar, oyunun geri kalanı çalışmaya devam eder.
  Future<void> _startPhysicalSource(PedometerStepSource source) async {
    var status = await StepPermissionService.check();
    if (status == StepPermissionStatus.denied) {
      status = await StepPermissionService.request();
    }
    if (!mounted) return;
    setState(() => _stepPermission = status);

    // iOS'ta izin ayrı istenmez; CMPedometer ilk dinlemede sistem penceresini
    // kendisi açar. Bu yüzden `unknown` durumunda da başlatılır.
    if (status == StepPermissionStatus.permanentlyDenied ||
        status == StepPermissionStatus.unavailable) {
      return;
    }
    await source.start(lastReportedAt: _profile.lastStepReportAt);
  }

  /// Sensör kullanılamaz hâle geldiğinde nedenini ekrana taşır.
  void _onSensorFailure(StepSensorFailure failure) {
    if (!mounted) return;
    setState(() {
      _stepPermission = switch (failure) {
        StepSensorFailure.permissionDenied =>
          StepPermissionStatus.permanentlyDenied,
        StepSensorFailure.unavailable => StepPermissionStatus.unavailable,
        StepSensorFailure.unknown => StepPermissionStatus.unknown,
      };
    });
  }

  /// Debug'da adım kaynağını değiştirir. Release'de çağrılmaz.
  void _setManualSource(bool useManual) {
    if (_useManualSource == useManual) return;
    unawaited(_stepSubscription?.cancel());
    unawaited(_sensorFailureSubscription?.cancel());
    _sensorFailureSubscription = null;
    _stepSource.dispose();
    setState(() {
      _useManualSource = useManual;
      _stepPermission = StepPermissionStatus.unknown;
      _attachStepSource();
    });
  }

  /// Kalıcı reddedilmiş izni açmak için sistem ayarlarına gider.
  Future<void> _openStepPermissionSettings() async {
    await StepPermissionService.openSettings();
    if (!mounted) return;
    // Kullanıcı ayarlardan dönünce durum değişmiş olabilir.
    final status = await StepPermissionService.check();
    if (!mounted) return;
    setState(() => _stepPermission = status);
  }

  /// Saniyelik nabız: önce gün döngüsü (gün değişimi + seri), sonra macera
  /// saati. Gün döngüsü görünür bir şey değiştirmedikçe yeniden çizim yok.
  void _tick() {
    if (!mounted) return;
    if (_refreshDayCycle()) {
      setState(() {});
      _persist();
    }
    _updateAdventureClock();
  }

  /// Gün döngüsünü işler: oyun günü değiştiyse günlük ilerlemeyi sıfırlar ve
  /// seriyi tazeler. Görünür bir değişiklik olduysa `true` döner.
  ///
  /// Cihaz saati geriye alınmışsa [GameClock] okumayı en son güvenilen zamana
  /// sabitler; bu yüzden burada ayrı bir "şüpheli saat" dalı yoktur — gün de,
  /// seri de, çark hakkı da kendiliğinden donar.
  bool _refreshDayCycle() {
    final now = GameClock.now();
    var changed = false;

    if (!_today.isSameDayAs(now)) {
      _archiveDailySteps(_today);
      _today = DailyProgress(date: now);
      // Aktif/zaferle bitmiş günlük macera yenilenir. Otoriter yenilgi ise
      // Hayat Yürüyüşü tamamlanana ve oyuncu yeniden doğuşu görene kadar
      // korunur; gün değişimi bu gereksinimi atlatamaz.
      if (_adventure?.isPlayerDefeated != true) {
        _adventure = null;
      }
      unawaited(AdventureNotificationService.cancelAdventureReminders());
      changed = true;
    }
    // Kırılma bonusu sıfırlıyor; kaybedileni söyleyebilmek için önce ölç.
    final bonusBeforeRefresh = _profile.streakStatBonuses.totalBonus;
    final streakOutcome = _profile.refreshStreak(now);
    if (streakOutcome != StreakDayOutcome.unchanged) changed = true;
    if (streakOutcome == StreakDayOutcome.frozen) {
      // Otomatik harcanan jeton sessiz kalmaz. Bu metot initState içinden de
      // çağrıldığı için bildirim frame sonuna bırakılır.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showStreakFrozen();
      });
    }
    if (streakOutcome == StreakDayOutcome.broken && bonusBeforeRefresh > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showStreakBonusLost(bonusBeforeRefresh);
      });
    }
    return changed;
  }

  /// Tamamlanan günü adım halkası geçmişine yazar.
  /// Kural ve gerekçeler [archiveStepDay] içinde.
  void _archiveDailySteps(DailyProgress progress) {
    _stepHistory = archiveStepDay(
      history: _stepHistory,
      completedDay: progress,
    );
  }

  /// Kayıtlı durumu geri yükler. Kayıt yoksa ya da kayıt başka bir güne aitse
  /// günlük ilerleme (adım + macera) sıfırdan başlar; seviye, XP, para ve
  /// streak gibi kalıcı ilerleme her durumda korunur.
  void _restoreState() {
    final restored = widget.initialState;
    _profile =
        restored?.profile ??
        UserProfile(
          avatar: widget.avatar,
          tutorialGuideId:
              (widget.initialTutorialGuide ?? TutorialGuideVariant.mavili).id,
        );
    _tutorialStep.value = TutorialGuideStep.fromStoredIndex(
      _profile.tutorialStep,
    );
    // Kapat-aç sonrası da geriye alınan saati yakalayabilmek için en son
    // güvenilen zaman diskten yüklenir.
    GameClock.restore(_profile.lastSeenAt);
    _today = restored?.today ?? DailyProgress(date: GameClock.now());
    // Eski (sınır konmadan önce yazılmış) kayıtlar açılışta da kırpılır.
    _stepHistory = pruneStepHistory(
      List<DailyStepRecord>.of(restored?.stepHistory ?? const []),
    );
    _adventure = restored?.adventure;
    // Gün değişimi ve seri tazeleme tek yerden: _refreshDayCycle.
    if (_refreshDayCycle()) _persist();
  }

  /// Güncel durumu kalıcı depoya gönderir. Yazma sıklığını [GameStorage]
  /// kendi içinde sınırladığı için her state değişiminde çağrılabilir.
  void _persist() {
    _profile.lastSeenAt = GameClock.lastSeenAt;
    // İtilen ekranlar (envanter) bu sayacı dinliyor; bkz. [_revision].
    _revision.value++;
    GameStorage.scheduleSave(
      GameState(
        profile: _profile,
        today: _today,
        adventure: _adventure,
        stepHistory: _stepHistory,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_stepSubscription?.cancel());
    unawaited(_sensorFailureSubscription?.cancel());
    _stepSource.dispose();
    _adventureClock?.cancel();
    _persist();
    _revision.dispose();
    _tutorialStep.dispose();
    unawaited(GameStorage.flush());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isForeground = true;
      unawaited(AdventureNotificationService.cancelAdventureReminders());
      final adventure = _adventure;
      if (adventure != null && !adventure.isBattleCompleted) {
        adventure.nextReminderAt = GameClock.now().add(
          AdventureQuest.reminderInterval,
        );
      }
      if (_refreshDayCycle()) setState(() {});
      _updateAdventureClock();
      _persist();
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _isForeground = false;
      // Arka plana geçerken bekleyen yazma hemen tamamlanır.
      _persist();
      unawaited(GameStorage.flush());
      final adventure = _adventure;
      if (adventure != null && !adventure.isBattleCompleted) {
        unawaited(
          AdventureNotificationService.scheduleAdventureReminders(
            adventure,
            _today.steps,
          ),
        );
      }
    }
  }

  @override
  void didUpdateWidget(covariant RootShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatar != widget.avatar) {
      final classChanged =
          oldWidget.avatar.characterClass != widget.avatar.characterClass;
      _profile.avatar = widget.avatar;
      if (classChanged) {
        // Sınıf değişti: yeni sınıfın kullanamadığı kategoriler kuşanmadan
        // düşer (sahiplik korunur, bkz. GD16) ve mağaza listesi yenilenir.
        setState(() {
          _equipment = ItemCatalog.forCharacterClass(
            widget.avatar.characterClass,
          );
          _refreshEquipment();
        });
        _persist();
      }
    }
  }

  /// XP veren **tek** nokta: adım, düşman ve çark hep buradan geçer.
  ///
  /// Seviye atlandığında hem uygulama içi kutlamayı tetikler hem de
  /// [LevelEvents] üzerinden yayınlar. Yayını tek noktada tutmak, Aşama 3'teki
  /// seviye kilitlerinin (#10, #11) `addXp` çağıran her yeri gezmesini
  /// gereksiz kılar.
  ///
  /// `setState` içinden de çağrılabilsin diye kendisi `setState` çağırmaz;
  /// kutlama bir sonraki frame'e bırakılır.
  ///
  /// **Gerçekten verilen** XP'yi döner: "2x XP" yükseltmesi etkinse çarpan
  /// burada uygulanır. Çarpanın tek noktası burası, çünkü yükseltmenin sözü
  /// "kazandığın XP" — adım, düşman ve çark, hepsi.
  int _awardXp(int amount) {
    if (amount <= 0) return 0;
    final granted =
        _profile.isXpBoostActive
            ? amount * GameConstants.xpBoostMultiplier
            : amount;
    final previousLevel = _profile.level;
    _profile.addXp(granted);
    // Seviye savaş canı tavanını büyütebilir. Adım/zafer/çark kaynağı fark
    // etmeden aynı XP kapısından geçtiği için senkronizasyon da burada yapılır.
    _syncAdventureStats();
    if (_profile.level == previousLevel) return granted;

    final event = LevelUpEvent(
      previousLevel: previousLevel,
      newLevel: _profile.level,
    );
    LevelEvents.emit(event);
    // Kutlama build sırasında gösterilemez; frame sonuna bırakılır.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showLevelUp(event);
    });
    return granted;
  }

  /// Seviye atlama kutlaması.
  void _showLevelUp(LevelUpEvent event) {
    final gained = event.levelsGained;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          backgroundColor: const Color(0xFF171521),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.xp, width: 1.5),
          ),
          content: Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.xp, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SEVİYE ${event.newLevel}!',
                      style: const TextStyle(
                        color: AppColors.xp,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      gained > 1
                          ? '$gained seviye birden atladın. Adımların '
                              'karşılığını veriyor!'
                          : 'Yürümeye devam et, sıradaki seviye '
                              '${_profile.xpToNextLevel} XP.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }

  /// Demo kontrollerinin girişi. Kaynağı besler; işi [_onStepsReported] yapar.
  /// Gerçek sensör aktifken demo butonları kilitli olduğu için burası
  /// yalnızca manuel kaynakta çalışır.
  void _simulateSteps(int amount) {
    final source = _stepSource;
    if (source is ManualStepSource) source.add(amount);
  }

  /// Kesinleşmiş zaferin XP ve kademe bazlı rastgele altınını en fazla bir kez verir.
  ///
  /// Geçici düşman görünürlüğü, ara round animasyonu veya ileride eklenecek
  /// Walking Phase bu kapıyı açamaz; tek ölçüt otoriter battle sonucudur.
  int? _grantAdventureVictoryXpIfNeeded(
    AdventureQuest adventure, {
    int? forcedCoins,
  }) {
    if (!adventure.isEnemyDefeated || adventure.xpAwarded) return null;
    adventure.xpAwarded = true;
    final xp = _awardXp(
      (adventure.enemy.xpReward * _buffs.enemyXpMultiplier).floor(),
    );
    final tier = adventure.enemy.tier;
    final minimumCoins = 4 + (tier * 3);
    final maximumCoins = 10 + (tier * 6);
    final coins =
        forcedCoins ??
        minimumCoins + Random().nextInt(maximumCoins - minimumCoins + 1);
    adventure.victoryXpReward = xp;
    adventure.victoryCoinReward = coins;
    _profile.coins += coins;
    return xp;
  }

  Future<void> _completeFirstTutorialAdventure() async {
    if (_tutorialBattleRunning ||
        _tutorialStep.value != TutorialGuideStep.combatDemo) {
      return;
    }
    _tutorialBattleRunning = true;
    try {
      if (_equipment.isEmpty) await _loadItemCatalog();
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (!mounted ||
          _tutorialStep.value != TutorialGuideStep.combatDemo ||
          _adventure == null) {
        return;
      }
      final adventure = _adventure!;
      final starter = _tutorialStarterWeapon;
      final educationCoins =
          starter == null ? 0 : max(0, starter.cost - _profile.coins);
      setState(() {
        adventure.completeTutorialVictory(GameClock.now());
        _grantAdventureVictoryXpIfNeeded(
          adventure,
          forcedCoins: educationCoins,
        );
      });
      _persist();
      unawaited(AdventureNotificationService.cancelAdventureReminders());
      await Future<void>.delayed(
        Duration(milliseconds: adventure.enemy.deathAnimationDurationMs + 350),
      );
      if (!mounted || _tutorialStep.value != TutorialGuideStep.combatDemo) {
        return;
      }
      _setTutorialStep(TutorialGuideStep.victoryCelebration);
    } finally {
      _tutorialBattleRunning = false;
    }
  }

  /// Adım kaynağından gelen **kümülatif** sayacı işler.
  ///
  /// Kaynak kim olursa olsun (demo butonları ya da pedometer) akış buradan
  /// geçer: hız kontrolü, günlük ilerleme, para, seri ve macera tek yerde.
  ///
  /// İki sayaç bilerek ayrıdır:
  /// - [UserProfile.lastReportedStepCount] kaynağın **raporladığı** yer;
  ///   her raporda ilerler, böylece hız kontrolünde yakılan adım bir sonraki
  ///   raporda geri sızmaz.
  /// - [UserProfile.totalSteps] **kredilenen** adım; para, seri ve macera
  ///   buna bakar. 1b'deki çift-sayma koruması değişmeden çalışmaya devam eder.
  void _onStepsReported(int cumulativeSteps) {
    final now = GameClock.now();
    final elapsed = now.difference(_profile.lastStepReportAt ?? now);
    final reported = cumulativeSteps - _profile.lastReportedStepCount;

    _profile.lastStepReportAt = now;
    _profile.lastSensorReading = _stepSource.lastSensorReading;
    if (reported <= 0) {
      // Sensör referansı kurulmuş ya da aynı değer tekrar gelmiş olabilir;
      // ikisi de diske yazılmalı ama oyunda bir şey değiştirmez.
      _persist();
      return;
    }

    // İmkânsız hızlar yalnızca fiziksel kaynağa uygulanır: demo butonlarının
    // +20.000'i emülatörde çalışmaya devam etmeli.
    final verdict =
        _stepSource.isPhysical
            ? limitStepBatch(reportedSteps: reported, elapsed: elapsed)
            : StepBatchVerdict(accepted: reported, discarded: 0);

    _profile.lastReportedStepCount = cumulativeSteps;
    final amount = verdict.accepted;
    if (amount <= 0) {
      _persist();
      return;
    }

    var enemyDefeated = false;
    var playerDefeated = false;
    var revivalCompleted = false;
    CombatRoundResult? roundResult;
    int? milestoneReached;
    var milestoneFreezeGranted = false;
    ItemStat? streakStatGained;
    final revivalAdventure = _adventure;
    final revivalStepsWithoutXp =
        revivalAdventure?.isRevivalActive == true
            ? min(amount, revivalAdventure!.revivalRemainingSteps)
            : 0;
    setState(() {
      _today.addSteps(amount);
      _profile.totalSteps += amount;

      // Hayat Yürüyüşünün kendi 500 adımı XP üretmez. İşaretçiyi yalnızca
      // gerçekten kabul edilen recovery adımı kadar ilerletmek, partide 500'ü
      // aşan normal adımların ve önceki küsuratın XP kazanmasını korur.
      if (revivalStepsWithoutXp > 0) {
        final accepted = revivalAdventure!.addRevivalSteps(
          revivalStepsWithoutXp,
        );
        _profile.lastXpRewardedStepCount += accepted;
        revivalCompleted = revivalAdventure.revivalCompleted;
      }

      // Para adım deltasından kazanılır: işaretçi yalnızca paraya çevrilen
      // adım kadar ilerler, artan adımlar bir sonraki hesaba kalır.
      final coinReward = calculateStepCoins(
        pendingSteps: _profile.totalSteps - _profile.lastRewardedStepCount,
        // Günlük tavan yoktur; ekipman yalnızca adım başına kazancı büyütür.
        multiplier: _buffs.stepCoinMultiplier,
      );
      _profile.coins += coinReward.coins;
      _profile.lastRewardedStepCount += coinReward.consumedSteps;
      _today.coinsEarned += coinReward.coins;

      // XP'nin kendi işaretçisi var; iki ödül ekonomisi birbirine karışmaz.
      final xpReward = calculateStepXp(
        pendingSteps: _profile.totalSteps - _profile.lastXpRewardedStepCount,
        multiplier: _buffs.stepXpMultiplier,
      );
      _profile.lastXpRewardedStepCount += xpReward.consumedSteps;
      // Ana ekrandaki "adımdan kazandığın XP" satırı gerçekten verileni
      // göstermeli: "2x XP" etkinse [_awardXp] çarpanı uygulayıp döner.
      _today.xpEarned += _awardXp(xpReward.xp);

      final adventure = _adventure;
      if (adventure != null && !adventure.isBattleCompleted) {
        final wasActive = !adventure.isBattleCompleted;
        // Adımlar savaş yoğunluğunu belirler; round geçişini yalnız deadline
        // yapar. Süre dolmadıysa bu çağrı state değiştirmeden null döner.
        roundResult = adventure.resolveRound(
          _today.steps,
          now,
          playerStats: _playerCombatStats(adventure),
          onHitEffects: triggeredEffects(_buffs, ItemEffectTrigger.onHit),
          onKillEffects: triggeredEffects(_buffs, ItemEffectTrigger.onKill),
        );
        playerDefeated = wasActive && adventure.isPlayerDefeated;
      }
      if (adventure != null) {
        final granted = _grantAdventureVictoryXpIfNeeded(adventure);
        if (granted != null) {
          enemyDefeated = true;
        }
      }
      // Seri günlük hedefe değil, düşük ve sabit bir eşiğe bağlı. Kuşanılan
      // ekipman bu eşiği düşürebilir (`streakRelief`); eşik yalnızca **o an**
      // kontrol ediliyor, yani kuşanmayı çıkarmak geçmiş günleri bozmaz.
      if (_today.steps >= _buffs.streakStepThreshold &&
          _profile.registerStreakDay(now)) {
        // Günün savaş stat bonusu: seri ilerledikten **sonra** çekilir.
        // Aynı oyun gününde ikinci çağrı null döner, yani kapat-aç ile
        // yeniden zar atılamaz (bkz. `streak_bonus.dart`).
        streakStatGained = _profile.grantStreakStatBonus(now);
        milestoneReached = _profile.reachedStreakMilestone;
        // Her kilometre taşı bir dondurma hakkı verir (stok sınırlı).
        // Aşama 2c'de bilerek boş bırakılan kazanım yolu bu.
        if (milestoneReached != null) {
          milestoneFreezeGranted =
              _profile.grantStreakFreeze(1, _buffs.streakFreezeCap) > 0;
        }
      }
    });
    _persist();

    // Bu partinin bildirimleri **frame sonuna** bırakılır ve tek bir
    // callback'te sıraya girer.
    //
    // Gerekçe: [_showLevelUp] `hideCurrentSnackBar()` çağırıyor (seviye
    // kutlaması manşet olmalı) ve kendisi frame sonunda gösteriliyor. Senkron
    // gösterilen bildirimler kuyruğa **önce** girip seviye kutlaması gelir
    // gelmez, hiç görülmeden kapanıyordu. Frame sonu callback'leri kayıt
    // sırasıyla çalıştığı için burada kaydedilenler kutlamanın arkasına
    // düşüyor ve sırayla gösteriliyor.
    final statGained = streakStatGained;
    final milestone = milestoneReached;
    if (statGained != null || milestone != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (statGained != null) _showStreakStatBonus(statGained);
        if (milestone != null) {
          _showStreakMilestone(
            milestone,
            freezeGranted: milestoneFreezeGranted,
          );
        }
      });
    }
    if (enemyDefeated) {
      unawaited(AdventureNotificationService.cancelAdventureReminders());
      if (_tutorialStep.value == TutorialGuideStep.combatWaiting ||
          _tutorialStep.value == TutorialGuideStep.enemyReaction) {
        _setTutorialStep(TutorialGuideStep.victoryCelebration);
      }
    } else if (playerDefeated) {
      unawaited(AdventureNotificationService.cancelAdventureReminders());
    } else if (roundResult?.playerDamage case final damage? when damage > 0) {
      if (_tutorialStep.value == TutorialGuideStep.combatWaiting) {
        _setTutorialStep(TutorialGuideStep.enemyReaction);
      }
    }
    if (revivalCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hayat Yürüyüşü tamamlandı. Yeniden doğdun! Bu 500 adım XP '
            'kazandırmadı.',
          ),
        ),
      );
    }
    if (roundResult != null) _persist();
  }

  void _selectAdventure(AdventureQuest adventure) {
    final current = _adventure;
    if (current?.isPlayerDefeated == true && !current!.revivalCompleted) {
      _showStoreNotice(
        'Yeni bir macera için önce 500 adımlık Hayat Yürüyüşünü tamamla.',
      );
      return;
    }
    setState(() {
      _adventure = adventure;
      // Savaş canı ve tohum macera başlarken damgalanır: ekran statları
      // bilmiyor, `RootShell` biliyor.
      final stats = _playerCombatStats(adventure);
      adventure.playerMaxHealth = stats.maxHealth.round();
      adventure.playerHealth = adventure.playerMaxHealth;
      if (adventure.combatSeed == 0) {
        adventure.combatSeed = AdventureQuest.fallbackCombatSeed(
          '${_profile.avatar.name}|${adventure.enemy.id}',
          adventure.startingSteps,
        );
      }
      // Günün adımları korunur; macera kendi başlangıç adımını taşır
      // (AdventureQuest.startingSteps). Yalnızca günlük hedef güncellenir.
      //
      // `coinsEarned` / `xpEarned` de taşınır: ikisi de günün yürüyüş
      // kazancını gösteren sayaçlardır; macera seçmek geçmişi silmemeli.
      _today = DailyProgress(
        date: _today.date,
        steps: _today.steps,
        stepGoal: adventure.stepGoal,
        coinsEarned: _today.coinsEarned,
        xpEarned: _today.xpEarned,
      );
    });
    _persist();
    if (_tutorialStep.value == TutorialGuideStep.enemyChoice) {
      _setTutorialStep(TutorialGuideStep.enemySelected);
    }
    unawaited(AdventureNotificationService.requestPermission());
  }

  void _startRevival() {
    final adventure = _adventure;
    if (adventure == null || !adventure.startRevival()) return;
    setState(() {});
    _persist();
    unawaited(AdventureNotificationService.cancelAdventureReminders());
  }

  void _chooseNewAdventure() {
    final adventure = _adventure;
    if (adventure?.isPlayerDefeated == true && !adventure!.revivalCompleted) {
      _showStoreNotice(
        'Maceralara dönmek için Hayat Yürüyüşünde '
        '${adventure.revivalRemainingSteps} adım daha atmalısın.',
      );
      return;
    }
    setState(() {
      _adventure = null;
      // Macera bırakılınca da günün adımları yanmaz; yalnızca günlük hedef
      // varsayılana döner. Günlük kazanç sayaçları aynı gerekçeyle taşınır.
      _today = DailyProgress(
        date: _today.date,
        steps: _today.steps,
        coinsEarned: _today.coinsEarned,
        xpEarned: _today.xpEarned,
      );
    });
    _persist();
    unawaited(AdventureNotificationService.cancelAdventureReminders());
  }

  void _updateAdventureClock() {
    if (!mounted) return;
    final adventure = _adventure;
    if (adventure == null || adventure.isBattleCompleted) return;

    final now = GameClock.now();
    // Biriken turların hepsi çözülür; arka planda geçen süre affedilmez.
    CombatRoundResult? result;
    setState(() {
      result = adventure.resolveExpiredRounds(
        _today.steps,
        now,
        playerStats: _playerCombatStats(adventure),
        onHitEffects: triggeredEffects(_buffs, ItemEffectTrigger.onHit),
        onKillEffects: triggeredEffects(_buffs, ItemEffectTrigger.onKill),
      );
      _grantAdventureVictoryXpIfNeeded(adventure);
    });
    final reminderDue =
        _isForeground &&
        !adventure.isBattleCompleted &&
        adventure.takeDueReminder(now);

    final resolvedResult = result;
    if (resolvedResult != null) _persist();

    if (resolvedResult != null && resolvedResult.playerDamage > 0) {
      _showEnemyAttackNotice(adventure, resolvedResult.playerDamage);
    }
    if (adventure.isBattleCompleted) {
      unawaited(AdventureNotificationService.cancelAdventureReminders());
    }
    if (reminderDue) _showAdventureReminder(adventure);
  }

  /// Seri, otomatik harcanan bir dondurma hakkıyla kurtarıldığında gösterilir.
  void _showStreakFrozen() {
    final left = _profile.streakFreezes;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            const Icon(Icons.ac_unit, color: AppColors.xp),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Serin korundu, 1 dondurma hakkı kullanıldı. '
                '${left > 0 ? "Kalan hak: $left." : "Hakkın kalmadı."}',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TODO(rewards): Kilometre taşı **item** ödülü henüz üretilmiyor; ödül
  // altyapısı (kart #14) Aşama 4b'de kurulunca buraya bağlanacak. Dondurma
  // hakkı ödülü Aşama 3'te bağlandı.
  void _showStreakMilestone(int days, {required bool freezeGranted}) {
    final message =
        freezeGranted
            ? '$days günlük seri! Kilometre taşı ödülün: 1 dondurma hakkı.'
            : '$days günlük seri! Kilometre taşına ulaştın '
                '(dondurma stoğun zaten dolu).';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            const Icon(Icons.local_fire_department, color: AppColors.streak),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  /// Günün seri stat bonusunu duyurur: "3. gün: +%1 kritik şansı".
  ///
  /// Stat tavana oturduysa bunu da söyler; oyuncu neden bir daha o statın
  /// çıkmayacağını bilmeli (Model Kuralları #4).
  void _showStreakStatBonus(ItemStat stat) {
    final bonuses = _profile.streakStatBonuses;
    final percent = (GameConstants.streakStatBonusPerDay * 100).round();
    final total = (bonuses.bonusFor(stat) * 100).round();
    final buffer = StringBuffer(
      '${_profile.streakDays}. gün: +%$percent ${stat.label} '
      '(seriden toplam +%$total)',
    );
    if (bonuses.isAtCap(stat)) {
      buffer.write(' · bu stat tavana ulaştı');
    } else if (bonuses.isFull) {
      buffer.write(' · seri bonusu tavana ulaştı');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.streak),
            const SizedBox(width: 8),
            Expanded(child: Text(buffer.toString())),
          ],
        ),
      ),
    );
  }

  /// Seri kırılınca kaybedilen savaş bonusunu söyler. Sessiz kalmamalı:
  /// oyuncu neyi kaybettiğini bilmezse dondurma hakkının değerini de
  /// anlamaz.
  void _showStreakBonusLost(double lostBonus) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            const Icon(Icons.heart_broken, color: AppColors.streak),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Serin kırıldı. Biriktirdiğin +%${(lostBonus * 100).round()} '
                'savaş bonusu sıfırlandı.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEnemyAttackNotice(AdventureQuest adventure, int damage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            _NotificationEnemyGif(asset: adventure.enemy.attackAsset),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${adventure.enemy.name} saldırdı! $damage can kaybettin.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdventureReminder(AdventureQuest adventure) {
    final template =
        _reminderMessages[_random.nextInt(_reminderMessages.length)];
    final message = template
        .replaceAll('{enemy}', adventure.enemy.name)
        .replaceAll('{steps}', '${adventure.roundStepsRemaining(_today.steps)}')
        .replaceAll('{round}', '${adventure.currentRound}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        content: Row(
          children: [
            _NotificationEnemyGif(asset: adventure.enemy.attackAsset),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  /// Çark sonucu geldi (#16). Hak tüketimi [UserProfile.consumeWheelSpin]
  /// üzerinden: günlük hak duruyorsa o, kullanılmışsa bir ekstra jeton düşer.
  ///
  /// Ödül XP ya da ekipman olabilir. Ekipmanın seviye kilidi ve sahiplik
  /// süzgeci havuz kurulurken uygulanıyor (`buildWheelSlices`); burada ikinci
  /// bir kontrol **yok** — kilidin tek kaynağı [Item.isUnlockedAt].
  void _spinWheel(WheelReward reward) {
    setState(() {
      _profile.consumeWheelSpin(GameClock.now());
      // Tohum ilerletilir: bir sonraki çevirme aynı sonucu vermesin.
      // Çark ekranı da aynı adımı kendi içinde uyguluyor.
      _profile.wheelSeed = nextWheelSeed(_profile.wheelSeed);

      final item = reward.item;
      if (item == null) {
        // Çark XP bonusu: kuşanılan ekipmandan gelir.
        _awardXp((reward.xp * _buffs.wheelXpMultiplier).floor());
      } else {
        // Çark havuzu sahip olunanları zaten eliyor (GD19); yine de örnek
        // olarak ekleniyor, kimlik olarak değil.
        _profile.addItem(item.id);
      }
    });
    _persist();
    if (_tutorialStep.value == TutorialGuideStep.wheelWaiting) {
      _setTutorialStep(TutorialGuideStep.wheelReward);
    }
  }

  /// Yükseltme satın alır (kozmetik, unvan, dondurma hakkı).
  ///
  /// Tekrarlanamayan bir öğe zaten sahipliyse **para düşülmez**: eski kod
  /// coin'i alıyor ama kimliği ikinci kez eklemediği için oyuncu bedavaya
  /// ödüyordu.
  void _purchase(XpStoreItem item) {
    final alreadyOwned = _profile.ownedUpgradeIds.contains(item.id);
    if (alreadyOwned && !item.repeatable) return;
    if (_profile.coins < item.cost) return;

    // Tüketilen yükseltmeler: etkiyi **önce** uygula, veremiyorsan sat.
    // Stok doluysa / zaten etkinse satış yapılmaz, para boşa gitmemeli.
    switch (item.id) {
      case _streakFreezeItemId:
        // Stok tavanı kuşanılan ekipmanla büyüyebilir.
        if (_profile.grantStreakFreeze(1, _buffs.streakFreezeCap) == 0) {
          _showStoreNotice(
            'Dondurma hakkı stoğun dolu '
            '(${_buffs.streakFreezeCap}). Para harcanmadı.',
          );
          return;
        }
      case _extraWheelSpinItemId:
        if (_profile.grantExtraWheelSpin(1, _buffs.wheelSpinCap) == 0) {
          _showStoreNotice(
            'Ekstra çark hakkı stoğun dolu '
            '(${_buffs.wheelSpinCap}). Para harcanmadı.',
          );
          return;
        }
      case _xpBoostItemId:
        if (!_profile.activateXpBoost(GameClock.now())) {
          _showStoreNotice('2x XP zaten etkin. Para harcanmadı.');
          return;
        }
    }

    setState(() {
      _profile.coins -= item.cost;
      if (!alreadyOwned) _profile.ownedUpgradeIds.add(item.id);
    });
    _persist();
    if (_tutorialStep.value == TutorialGuideStep.shopWaiting) {
      _setTutorialStep(TutorialGuideStep.itemBought);
    }
    _showStoreNotice('${item.name} satın alındı!');
  }

  /// Ekipman satın alır. Seviye kilidi (#10/#11) ve para kontrolü burada da
  /// yapılır: ekran devre dışı görünse bile son söz state'in.
  ///
  /// **Aynı eşya birden fazla kez alınabilir** (GD39): birleştirme aynı
  /// eşyadan birkaç adet istiyor. Her satın alma envantere **yeni bir örnek**
  /// ekliyor; eskiden ikinci satın alma sessizce reddediliyordu.
  void _purchaseEquipment(Item item) {
    if (_tutorialActive &&
        _tutorialStep.value == TutorialGuideStep.shopWaiting &&
        item.id != _tutorialStarterWeapon?.id) {
      return;
    }
    if (!item.isUnlockedAt(_profile.level)) return;
    if (_profile.coins < item.cost) return;

    final count = _profile.ownedCountOf(item.id) + 1;
    setState(() {
      _profile.coins -= item.cost;
      _profile.addItem(item.id);
    });
    _persist();
    if (_tutorialStep.value == TutorialGuideStep.shopWaiting) {
      _setTutorialStep(TutorialGuideStep.itemBought);
    }
    _showStoreNotice(
      count == 1
          ? '${item.name} satın alındı!'
          : '${item.name} satın alındı. Artık $count adet.',
    );
  }

  /// Item'ı kategorisine karşılık gelen slota kuşandırır.
  ///
  /// Üç kontrol de **burada** yeniden yapılır: ekran devre dışı görünse bile
  /// son söz state'in (mağaza satın almasında olduğu gibi). Kilidin tek
  /// kaynağı [Item.isUnlockedAt] (#10); ikinci bir seviye mantığı yok.
  ///
  /// Engellenen her durum **sessiz kalmaz** (Model Kuralları #4): nedeni
  /// söylenir.
  void _equipItem(int instanceId) {
    final instance = _profile.instanceById(instanceId);
    if (instance == null) {
      _showStoreNotice('Bu eşya envanterinde yok.');
      return;
    }
    final item = _resolveInstance(instance);
    if (item == null) {
      _showStoreNotice('Bu eşya artık katalogda yok.');
      return;
    }
    if (!item.isUnlockedAt(_profile.level)) {
      _showStoreNotice(
        '${item.name} için ${item.requiredLevel}. seviye gerekiyor. '
        'Şu an ${_profile.level}. seviyedesin.',
      );
      return;
    }
    if (!item.isUsableBy(_profile.avatar.characterClass)) {
      _showStoreNotice('${item.name} senin sınıfın için değil.');
      return;
    }
    if (instance.equipped) return;

    // Aynı slottaki önceki örnek çıkarılır; adı bildirimde söylenmeli
    // (Model Kuralları #4 — sessizce yer değiştirmesin).
    String? replacedName;
    for (final other in _profile.equippedInstances) {
      final resolved = _resolveInstance(other);
      if (resolved != null && resolved.category == item.category) {
        replacedName = resolved.name;
        _profile.updateInstance(other.instanceId, equipped: false);
      }
    }
    _profile.updateInstance(instanceId, equipped: true);
    setState(_refreshEquipment);
    _persist();
    if (_tutorialStep.value == TutorialGuideStep.equipWaiting) {
      _setTutorialStep(TutorialGuideStep.itemEquipped);
    }

    _showStoreNotice(
      replacedName == null
          ? '${item.name} kuşanıldı.'
          : '${item.name} kuşanıldı, $replacedName çıkarıldı.',
    );
  }

  /// Slotu boşaltır.
  void _unequipSlot(ItemCategory category) {
    OwnedItem? target;
    for (final instance in _profile.equippedInstances) {
      final resolved = _resolveInstance(instance);
      if (resolved != null && resolved.category == category) {
        target = instance;
        break;
      }
    }
    if (target == null) return;

    final name = _resolveInstance(target)?.name ?? 'Item';
    _profile.updateInstance(target.instanceId, equipped: false);
    setState(_refreshEquipment);
    _persist();
    _showStoreNotice('$name çıkarıldı.');
  }

  /// Bir eşya örneğini bir seviye yükseltir (demirci).
  ///
  /// İki tavan ve para kontrolü **burada da** yapılır: ekran devre dışı
  /// görünse bile son söz state'in. Engel sessiz kalmaz (Model Kuralları #4).
  void _upgradeItem(int instanceId) {
    final instance = _profile.instanceById(instanceId);
    if (instance == null) {
      _showStoreNotice('Bu eşya envanterinde yok.');
      return;
    }
    final resolved = _resolveInstance(instance);
    if (resolved == null) {
      _showStoreNotice('Bu eşya artık katalogda yok.');
      return;
    }

    final quote = quoteUpgrade(
      resolved: resolved,
      instance: instance,
      playerLevel: _profile.level,
      coins: _profile.coins,
    );
    if (!quote.canUpgrade) {
      final rarity = instance.effectiveRarity(resolved.rarity);
      _showStoreNotice(
        quote.reason(rarity, _profile.level) ?? 'Şu an yükseltilemiyor.',
      );
      return;
    }

    setState(() {
      _profile.coins -= quote.cost;
      _profile.updateInstance(instanceId, level: quote.nextLevel);
      // Kuşanılıysa buff'lar hemen büyümeli.
      _refreshEquipment();
    });
    _persist();
    if (_tutorialStep.value == TutorialGuideStep.upgradeWaiting) {
      _setTutorialStep(TutorialGuideStep.upgradeCompleted);
    }
    _showStoreNotice(
      '${resolved.name} Sv. ${quote.nextLevel} oldu. -${quote.cost} coin.',
    );
  }

  /// Aynı eşyanın birkaç adedini birleştirip bir üst nadirlikte tek örnek
  /// üretir (demirci, Bölüm 4.3).
  ///
  /// Onay ekranını çağıran taraf (demirci) gösterir; burası kararı uygular ve
  /// **bütün kontrolleri yeniden yapar**: ekran devre dışı görünse bile son
  /// söz state'in.
  ///
  /// Tüketilen örnekler en düşük seviyelilerden seçilir
  /// ([selectMergeInstances]); kuşanılı bir örnek tüketilecekse önce çıkarılır
  /// ve bu kullanıcıya **söylenir** (sessizce kaybolmasın).
  void _mergeItems(String itemId, RewardRarity rarity) {
    final group = _mergeGroup(itemId, rarity);
    if (group.isEmpty) return;

    final resolved = _resolveInstance(group.first);
    if (resolved == null) {
      _showStoreNotice('Bu eşya artık katalogda yok.');
      return;
    }

    final quote = quoteMerge(
      resolved: resolved,
      rarity: rarity,
      group: group,
      coins: _profile.coins,
    );
    if (!quote.canMerge) {
      _showStoreNotice(quote.reason(rarity) ?? 'Şu an birleştirilemiyor.');
      return;
    }
    final target = quote.target;
    if (target == null) return;

    final unequipped = quote.consumesEquipped;
    setState(() {
      _profile.coins -= quote.cost;
      for (final instanceId in quote.consumedInstanceIds) {
        _profile.removeInstance(instanceId);
      }
      // Sonuç **Sv. 1**'e döner (GD42); nadirlik yükselir.
      _profile.addItem(itemId, rarity: target);
      _refreshEquipment();
    });
    _persist();

    _showStoreNotice(
      unequipped
          ? '${resolved.name} çıkarıldı ve ${quote.requiredCount} adet '
              'birleştirildi: artık ${target.label}, Sv. 1.'
          : '${quote.requiredCount} adet ${resolved.name} birleştirildi: '
              'artık ${target.label}, Sv. 1.',
    );
  }

  /// Aynı kimliğe ve aynı nadirliğe sahip örnekler.
  List<OwnedItem> _mergeGroup(String itemId, RewardRarity rarity) {
    final characterClass = _profile.avatar.characterClass;
    return [
      for (final instance in _profile.ownedItems)
        if (instance.itemId == itemId)
          if (ItemCatalog.byId(itemId, characterClass: characterClass)
              case final base?)
            if (instance.effectiveRarity(base.rarity) == rarity) instance,
    ];
  }

  /// Item'ı satar: sahiplikten düşer, kuşanılıysa önce çıkarılır ve
  /// [sellValueFor] kadar coin geri verilir.
  ///
  /// Onay ekranını çağıran taraf (envanter) gösterir; burası kararı uygular.
  void _sellItem(int instanceId) {
    final instance = _profile.instanceById(instanceId);
    if (instance == null) return;
    final item = _resolveInstance(instance);
    if (item == null) return;

    // Satış değeri **çözülmüş** fiyattan: birleştirilmiş bir örnek yeni
    // nadirliğinin fiyatı üzerinden değerleniyor. Yükseltmeye harcanan coin
    // geri gelmiyor — satış geri alınamaz (GD29).
    final value = sellValueFor(item.cost);
    final wasEquipped = instance.equipped;

    setState(() {
      _profile.removeInstance(instanceId);
      _profile.coins += value;
      _refreshEquipment();
    });
    _persist();

    _showStoreNotice(
      wasEquipped
          ? '${item.name} çıkarılıp satıldı. +$value coin.'
          : '${item.name} satıldı. +$value coin.',
    );
  }

  /// Envanteri açar.
  ///
  /// İtilen bir rota [RootShell]'in alt ağacında değil (GD11), bu yüzden
  /// ekran [_revision] sayacını dinliyor: adım gelip para değiştiğinde ya da
  /// seviye atlandığında envanter de tazeleniyor.
  void _openInventory() => _push(
    InventoryScreen(
      revision: _revision,
      readState: _readInventoryState,
      tutorialItemId:
          _tutorialActive &&
                  _tutorialStep.value == TutorialGuideStep.equipWaiting
              ? _profile.tutorialStarterItemId
              : null,
      onEquip: _equipItem,
      onUnequip: _unequipSlot,
      onSell: _sellItem,
      onUpgrade: _upgradeItem,
      onMerge: _mergeItems,
    ),
  );

  /// Demirciyi profildeki kendi girişinden açar. Envanterle aynı canlı state
  /// kaynağını kullanır; yükseltme ve birleştirme sonuçları anında saklanır.
  void _openBlacksmith() => _push(
    BlacksmithScreen(
      revision: _revision,
      readState: _readInventoryState,
      onUpgrade: _upgradeItem,
      onMerge: _mergeItems,
    ),
  );

  InventoryState _readInventoryState() {
    final entries = <InventoryEntry>[];
    for (final instance in _profile.ownedItems) {
      final item = _resolveInstance(instance);
      if (item != null) entries.add(InventoryEntry(instance, item));
    }
    return InventoryState(
      profile: _profile,
      entries: entries,
      equippedItems: _equippedItems,
      buffs: _buffs,
    );
  }

  /// Mağazadaki "N adet" etiketinin kaynağı: kimlik → sahip olunan adet.
  Map<String, int> get _ownedEquipmentCounts {
    final counts = <String, int>{};
    for (final instance in _profile.ownedItems) {
      counts[instance.itemId] = (counts[instance.itemId] ?? 0) + 1;
    }
    return counts;
  }

  void _showStoreNotice(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
      );
  }

  void _setTutorialStep(TutorialGuideStep step) {
    if (!_tutorialActive || _tutorialStep.value == step) return;
    _profile.tutorialStep = step.index;
    _tutorialStep.value = step;
    _persist();
  }

  void _completeTutorial() {
    if (_profile.hasCompletedTutorial) return;
    _returnToTutorialRoot();
    _profile.hasCompletedTutorial = true;
    _profile.tutorialStep = TutorialGuideStep.completed.index;
    _tutorialStep.value = TutorialGuideStep.completed;
    _persist();
    if (mounted) setState(() {});
  }

  void _returnToTutorialRoot() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _onTutorialPrimary(TutorialGuideStep step) {
    switch (step) {
      case TutorialGuideStep.welcome:
        _setTutorialStep(TutorialGuideStep.adventurePrompt);
      case TutorialGuideStep.enemySelected:
        _setTutorialStep(TutorialGuideStep.combatDemo);
        unawaited(_completeFirstTutorialAdventure());
      case TutorialGuideStep.combatDemo:
        _setTutorialStep(TutorialGuideStep.combatWaiting);
      case TutorialGuideStep.enemyReaction:
        _setTutorialStep(TutorialGuideStep.combatWaiting);
      case TutorialGuideStep.victoryCelebration:
        _setTutorialStep(TutorialGuideStep.rewardCoins);
      case TutorialGuideStep.rewardCoins:
        _setTutorialStep(TutorialGuideStep.rewardXp);
      case TutorialGuideStep.rewardXp:
        _setTutorialStep(TutorialGuideStep.shopPrompt);
      case TutorialGuideStep.itemBought:
        _setTutorialStep(TutorialGuideStep.equipWaiting);
        _openInventory();
      case TutorialGuideStep.itemEquipped:
        _setTutorialStep(TutorialGuideStep.wheelPrompt);
        _returnToTutorialRoot();
      case TutorialGuideStep.blacksmithPrompt:
        _setTutorialStep(TutorialGuideStep.upgradeWaiting);
        _openBlacksmith();
      case TutorialGuideStep.upgradeCompleted:
        _setTutorialStep(TutorialGuideStep.wheelPrompt);
      case TutorialGuideStep.wheelPrompt:
        _setTutorialStep(TutorialGuideStep.wheelWaiting);
        _openWheel();
      case TutorialGuideStep.wheelReward:
        _setTutorialStep(TutorialGuideStep.finalReady);
        _returnToTutorialRoot();
      case TutorialGuideStep.finalReady:
        _setTutorialStep(TutorialGuideStep.finalMotto);
      case TutorialGuideStep.finalMotto:
        _setTutorialStep(TutorialGuideStep.onlineTeaser);
      case TutorialGuideStep.onlineTeaser:
        _setTutorialStep(TutorialGuideStep.ratingRequest);
      case TutorialGuideStep.ratingRequest:
        _setTutorialStep(TutorialGuideStep.farewellWorkDone);
      case TutorialGuideStep.farewellWorkDone:
        _setTutorialStep(TutorialGuideStep.farewellYourTurn);
      case TutorialGuideStep.farewellYourTurn:
        _setTutorialStep(TutorialGuideStep.farewell);
      case TutorialGuideStep.farewell:
        _setTutorialStep(TutorialGuideStep.leaving);
      case TutorialGuideStep.adventurePrompt:
      case TutorialGuideStep.enemyChoice:
      case TutorialGuideStep.combatWaiting:
      case TutorialGuideStep.shopPrompt:
      case TutorialGuideStep.shopWaiting:
      case TutorialGuideStep.equipWaiting:
      case TutorialGuideStep.upgradeWaiting:
      case TutorialGuideStep.wheelWaiting:
      case TutorialGuideStep.leaving:
      case TutorialGuideStep.completed:
        break;
    }
  }

  void _onTutorialSecondary(TutorialGuideStep step) {
    switch (step) {
      case TutorialGuideStep.combatWaiting:
        _setTutorialStep(TutorialGuideStep.shopPrompt);
      case TutorialGuideStep.shopWaiting:
        _setTutorialStep(TutorialGuideStep.itemBought);
      case TutorialGuideStep.equipWaiting:
        _setTutorialStep(TutorialGuideStep.itemEquipped);
      case TutorialGuideStep.upgradeWaiting:
        _setTutorialStep(TutorialGuideStep.upgradeCompleted);
      case TutorialGuideStep.wheelWaiting:
        _setTutorialStep(TutorialGuideStep.wheelReward);
      case TutorialGuideStep.ratingRequest:
        widget.onRequestReview?.call();
        _setTutorialStep(TutorialGuideStep.farewellWorkDone);
      default:
        break;
    }
  }

  Widget _tutorialOverlay() => TutorialGuideOverlay(
    step: _tutorialStep,
    guide: TutorialGuideVariant.fromId(_profile.tutorialGuideId),
    onPrimary: _onTutorialPrimary,
    onSecondary: _onTutorialSecondary,
    onLeavingCompleted: _completeTutorial,
  );

  void _selectTab(int index) {
    setState(() => _tabIndex = index);
    final step = _tutorialStep.value;
    if (index == 1 && step == TutorialGuideStep.adventurePrompt) {
      _setTutorialStep(TutorialGuideStep.enemyChoice);
    } else if (index == 2 && step == TutorialGuideStep.shopPrompt) {
      _setTutorialStep(TutorialGuideStep.shopWaiting);
    }
  }

  void _openAdventure() => _selectTab(1);

  void _openWheel() {
    // Tohum ilk kullanımda oyuncuya özel kurulur; `0` "henüz kurulmadı"
    // demek. Böylece herkes aynı çarkı görmez ama çark yine deterministik
    // kalır (CLAUDE.md §4.4).
    if (_profile.wheelSeed == 0) {
      _profile.wheelSeed = initialWheelSeed(
        '${_profile.avatar.name}|${_profile.avatar.characterClass}',
      );
      _persist();
    }
    final tutorialWheel =
        _tutorialActive &&
        _tutorialStep.value == TutorialGuideStep.wheelWaiting;
    _push(
      DailyWheelScreen(
        alreadySpunToday: tutorialWheel ? false : _profile.wheelSpunToday,
        extraSpins: _profile.extraWheelSpins,
        level: _profile.level,
        equipment: _equipment,
        ownedItemIds: [
          for (final instance in _profile.ownedItems) instance.itemId,
        ],
        seed: _profile.wheelSeed,
        tutorialMode: tutorialWheel,
        onSpinResult: _spinWheel,
      ),
    );
  }

  void _openRewards() => _push(RewardsScreen(rewards: _rewards));

  void _editCharacter() {
    if (!_profile.ownedUpgradeIds.contains(_reincarnationPotionId)) {
      _showStoreNotice(
        'Karakterini değiştirmek için Reenkarnasyon İksiri gerekli.',
      );
      return;
    }
    _push(
      CharacterCreationScreen(
        initialAvatar: _profile.avatar,
        onCompleted: (avatar) {
          setState(() {
            _profile.avatar = avatar;
            _profile.ownedUpgradeIds.remove(_reincarnationPotionId);
            _equipment = ItemCatalog.forCharacterClass(avatar.characterClass);
            _refreshEquipment();
          });
          widget.onAvatarChanged(avatar);
          _persist();
          Navigator.of(context).pop();
          _showStoreNotice('Reenkarnasyon tamamlandı. İksir tüketildi.');
        },
      ),
    );
  }

  /// Mağazayı açar.
  ///
  /// **Sekmeye geçilir, ekran itilmez.** [_push] önceden inşa edilmiş bir
  /// widget örneğini rotaya veriyor; itilen rota kök Navigator'da durduğu için
  /// [RootShell]'in alt ağacında değil ve `setState` onu tazelemiyordu.
  /// Sonuç: itilen mağazada satın alma sonrası para düşüyor ama ekranda eski
  /// bakiye kalıyor, kart "Sahipsin" demiyor ve ikinci dokunuş sessizce
  /// düşüyordu. Sekme gövdesi her `setState`'te yeniden kurulduğu için bu
  /// sorun orada hiç yoktu — [_openAdventure] de aynı deseni kullanıyor.
  void _openStore() => _selectTab(2);

  void _push(Widget screen) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder:
                (_) => Stack(
                  fit: StackFit.expand,
                  children: [screen, if (_tutorialActive) _tutorialOverlay()],
                ),
          ),
        )
        .then((_) {
          // Alt ekranlardan dönünce güncel state'i yansıtmak için yeniden çiz.
          setState(() {});
        });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeScreen(
        profile: _profile,
        today: _today,
        adventure: _adventure,
        onOpenAdventure: _openAdventure,
        onOpenWheel: _openWheel,
        onOpenRewards: _openRewards,
        onOpenStore: _openStore,
        onOpenInventory: _openInventory,
        onSimulateSteps: _simulateSteps,
        usingRealPedometer: _stepSource.isPhysical,
        stepPermission: _stepPermission,
        onOpenStepSettings: _openStepPermissionSettings,
        // Kaynak değiştirme yalnızca debug'da; release'de anahtar çıkmaz.
        onUseManualSourceChanged: kDebugMode ? _setManualSource : null,
        useManualSource: _useManualSource,
      ),
      AdventureScreen(
        adventure: _adventure,
        roundSerial: _adventure?.roundOutcomeSerial ?? 0,
        avatar: _profile.avatar,
        today: _today,
        onAdventureSelected: _selectAdventure,
        onStartRevival: _startRevival,
        onChooseNewAdventure: _chooseNewAdventure,
        onAdventureUpdated: _persist,
        tutorialMode:
            _tutorialActive &&
            _tutorialStep.value == TutorialGuideStep.enemyChoice,
      ),
      XpStoreScreen(
        items: _storeItems,
        equipment: _equipment,
        coins: _profile.coins,
        level: _profile.level,
        ownedUpgradeIds: _profile.ownedUpgradeIds,
        ownedEquipmentCounts: _ownedEquipmentCounts,
        streakFreezes: _profile.streakFreezes,
        extraWheelSpins: _profile.extraWheelSpins,
        xpBoostActive: _profile.isXpBoostActive,
        tutorialItemId:
            _tutorialActive &&
                    _tutorialStep.value == TutorialGuideStep.shopWaiting
                ? _tutorialStarterWeapon?.id
                : null,
        onPurchase: _purchase,
        onPurchaseEquipment: _purchaseEquipment,
      ),
      TeamScreen(team: _team),
      ProfileScreen(
        profile: _profile,
        adventure: _adventure,
        today: _today,
        stepHistory: _stepHistory,
        equippedItems: _equippedItems,
        buffs: _buffs,
        canEditCharacter: _profile.ownedUpgradeIds.contains(
          _reincarnationPotionId,
        ),
        onEditCharacter: _editCharacter,
        onOpenInventory: _openInventory,
        onOpenBlacksmith: _openBlacksmith,
      ),
    ];

    return Stack(
      fit: StackFit.expand,
      children: [
        Scaffold(
          body: tabs[_tabIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tabIndex,
            onDestinationSelected: _selectTab,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: 'Ana Sayfa'),
              NavigationDestination(icon: Icon(Icons.explore), label: 'Macera'),
              NavigationDestination(
                icon: Icon(Icons.storefront),
                label: 'Mağaza',
              ),
              NavigationDestination(icon: Icon(Icons.groups), label: 'Takım'),
              NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
            ],
          ),
        ),
        if (_tutorialActive) _tutorialOverlay(),
      ],
    );
  }
}

class _NotificationEnemyGif extends StatelessWidget {
  final String asset;

  const _NotificationEnemyGif({required this.asset});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: ClipRect(
        child: Transform.scale(
          scale: 2.8,
          child: Image.asset(asset, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
