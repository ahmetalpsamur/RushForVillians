import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../../core/constants/game_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/coin_calculator.dart';
import '../../core/utils/equipped_buffs.dart';
import '../../core/utils/game_clock.dart';
import '../../core/utils/item_rules.dart';
import '../../core/utils/step_history.dart';
import '../../core/utils/step_rate_limiter.dart';
import '../../core/utils/wheel_rewards.dart';
import '../../core/utils/xp_calculator.dart';
import '../../data/mock_data.dart';
import '../../models/adventure_quest.dart';
import '../../models/avatar_profile.dart';
import '../../models/daily_progress.dart';
import '../../models/daily_step_record.dart';
import '../../models/game_state.dart';
import '../../models/item.dart';
import '../../models/reward.dart';
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
import '../inventory/inventory_screen.dart';
import '../profile/profile_screen.dart';
import '../rewards/rewards_screen.dart';
import '../store/xp_store_screen.dart';
import '../team/team_screen.dart';
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

  const RootShell({
    super.key,
    required this.avatar,
    required this.onAvatarChanged,
    this.initialState,
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

  /// Dondurma hakkı yükseltmesinin kimliği ([MockData.storeItems]).
  /// Satın alma stoğu [UserProfile.grantStreakFreeze] üzerinden büyütür.
  static const _streakFreezeItemId = 'upgrade_streak_freeze';

  /// Ekstra çark hakkı yükseltmesinin kimliği ([MockData.storeItems]).
  static const _extraWheelSpinItemId = 'wheel_extra_spin';

  /// "2x XP" yükseltmesinin kimliği ([MockData.storeItems]).
  static const _xpBoostItemId = 'boost_double_xp';

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
  }

  /// Kuşanılan itemleri katalogdan çözer ve toplam buff'ı yeniden hesaplar.
  ///
  /// Üç şeyi birden temizler:
  /// - katalogdan kalkmış kimlikler (slot boşalır),
  /// - artık sahip olunmayan kimlikler (satılmış item kuşanılı kalmasın),
  /// - oyuncunun sınıfının kullanamadığı kategoriler (sınıf değişimi).
  ///
  /// **Sahiplik kaydına dokunmaz**: yalnızca kuşanma boşaltılır.
  /// `setState` içinden çağrılabilsin diye kendisi `setState` çağırmaz.
  void _refreshEquipment() {
    final characterClass = _profile.avatar.characterClass;
    final resolved = <Item>[];
    final staleSlots = <String>[];

    _profile.equippedItemIds.forEach((slot, id) {
      final item = ItemCatalog.byId(id, characterClass: characterClass);
      if (item == null ||
          !_profile.ownedItemIds.contains(id) ||
          !item.isUsableBy(characterClass) ||
          item.category.folder != slot) {
        staleSlots.add(slot);
        return;
      }
      resolved.add(item);
    });

    for (final slot in staleSlots) {
      _profile.unequipSlot(slot);
    }
    _buffs = EquippedBuffs.from(resolved);
  }

  /// Kuşanılan itemler, oyuncunun sınıfına uyarlanmış hâlleriyle.
  List<Item> get _equippedItems {
    final characterClass = _profile.avatar.characterClass;
    return [
      for (final id in _profile.equippedItemIds.values)
        if (ItemCatalog.byId(id, characterClass: characterClass)
            case final item?)
          item,
    ];
  }

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
      // Macera günlük adım hedefine bağlı olduğu için gün değişiminde düşer.
      // (Bilinen sorun; bkz. CLAUDE.md — Aşama 5a.)
      _adventure = null;
      unawaited(AdventureNotificationService.cancelAdventureReminders());
      changed = true;
    }
    final streakOutcome = _profile.refreshStreak(now);
    if (streakOutcome != StreakDayOutcome.unchanged) changed = true;
    if (streakOutcome == StreakDayOutcome.frozen) {
      // Otomatik harcanan jeton sessiz kalmaz. Bu metot initState içinden de
      // çağrıldığı için bildirim frame sonuna bırakılır.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showStreakFrozen();
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
    _profile = restored?.profile ?? UserProfile(avatar: widget.avatar);
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
    unawaited(GameStorage.flush());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isForeground = true;
      unawaited(AdventureNotificationService.cancelAdventureReminders());
      final adventure = _adventure;
      if (adventure != null) {
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
      if (adventure != null) {
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
    var enemyXpGranted = 0;
    CombatRoundResult? roundResult;
    int? milestoneReached;
    var milestoneFreezeGranted = false;
    var capJustReached = false;
    // Tavan kontrolü oyuncunun **gerçek** tavanına göre: kuşanılan ekipman
    // günlük sınırı büyütmüş olabilir.
    final capWasReached = _today.coinCapReachedAt(_buffs.dailyCoinCap);
    setState(() {
      _today.addSteps(amount);
      _profile.totalSteps += amount;

      // Para adım deltasından kazanılır: işaretçi yalnızca paraya çevrilen
      // adım kadar ilerler, artan adımlar bir sonraki hesaba kalır.
      final coinReward = calculateStepCoins(
        pendingSteps: _profile.totalSteps - _profile.lastRewardedStepCount,
        coinsEarnedToday: _today.coinsEarned,
        // Kuşanılan ekipmanın adım-para bonusu ve büyütülmüş günlük tavanı.
        // Çarpan tavanı aşamaz; kırpma [calculateStepCoins] içinde.
        multiplier: _buffs.stepCoinMultiplier,
        dailyCap: _buffs.dailyCoinCap,
      );
      _profile.coins += coinReward.coins;
      _profile.lastRewardedStepCount += coinReward.consumedSteps;
      _today.coinsEarned += coinReward.coins;
      capJustReached = coinReward.capReached && !capWasReached;

      // XP'nin kendi işaretçisi var: para tavanı dolduğunda XP durmamalı.
      final xpReward = calculateStepXp(
        pendingSteps: _profile.totalSteps - _profile.lastXpRewardedStepCount,
        multiplier: _buffs.stepXpMultiplier,
      );
      _profile.lastXpRewardedStepCount += xpReward.consumedSteps;
      // Ana ekrandaki "adımdan kazandığın XP" satırı gerçekten verileni
      // göstermeli: "2x XP" etkinse [_awardXp] çarpanı uygulayıp döner.
      _today.xpEarned += _awardXp(xpReward.xp);

      final adventure = _adventure;
      if (adventure != null) {
        // 1.000 adım süre dolmadan tamamlandıysa round anında kazanılır.
        roundResult = adventure.resolveRound(_today.steps, now);
      }
      if (adventure != null &&
          adventure.isDefeated(_today.steps) &&
          !adventure.xpAwarded) {
        adventure.xpAwarded = true;
        // Düşman XP bonusu: kuşanılan ekipmandan gelir.
        enemyXpGranted = _awardXp(
          (adventure.enemy.xpReward * _buffs.enemyXpMultiplier).floor(),
        );
        enemyDefeated = true;
      }
      // Seri günlük hedefe değil, düşük ve sabit bir eşiğe bağlı. Kuşanılan
      // ekipman bu eşiği düşürebilir (`streakRelief`); eşik yalnızca **o an**
      // kontrol ediliyor, yani kuşanmayı çıkarmak geçmiş günleri bozmaz.
      if (_today.steps >= _buffs.streakStepThreshold &&
          _profile.registerStreakDay(now)) {
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
    if (capJustReached) _showCoinCapNotice();
    final milestone = milestoneReached;
    if (milestone != null) {
      _showStreakMilestone(milestone, freezeGranted: milestoneFreezeGranted);
    }
    if (enemyDefeated) {
      unawaited(AdventureNotificationService.cancelAdventureReminders());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_adventure!.enemy.name} yenildi! $enemyXpGranted XP kazandın.',
          ),
        ),
      );
    }
    if (roundResult != null) _persist();
  }

  void _selectAdventure(AdventureQuest adventure) {
    setState(() {
      _adventure = adventure;
      // Günün ilerlemesi **bütünüyle** korunur; macera kendi başlangıç adımını
      // taşır (AdventureQuest.startingSteps). Yalnızca günlük hedef değişir.
      //
      // Eskiden burada elle yeni bir DailyProgress kuruluyordu ve
      // `coinsEarned` / `xpEarned` varsayılan 0'a düşüyordu: macera seçmek
      // **günlük coin tavanını sıfırlıyordu** (tavana dayanan oyuncu macera
      // seçip 400 coin daha kazanabiliyordu) ve ana ekrandaki "bugün
      // adımlarından kazandığın XP" satırı yanlış gösteriyordu.
      _today = _today.withStepGoal(adventure.stepGoal);
    });
    _persist();
    unawaited(AdventureNotificationService.requestPermission());
  }

  void _chooseNewAdventure() {
    setState(() {
      _adventure = null;
      // Macera bırakılınca da günün ilerlemesi yanmaz; yalnızca günlük hedef
      // varsayılana döner. Kazanç sayaçları için bkz. [_selectAdventure].
      _today = _today.withStepGoal(GameConstants.dragonStepGoal);
    });
    _persist();
    unawaited(AdventureNotificationService.cancelAdventureReminders());
  }

  void _updateAdventureClock() {
    if (!mounted) return;
    final adventure = _adventure;
    if (adventure == null ||
        adventure.isDefeated(_today.steps) ||
        adventure.playerHealth <= 0) {
      return;
    }

    final now = GameClock.now();
    // Biriken turların hepsi çözülür; arka planda geçen süre affedilmez.
    final result = adventure.resolveExpiredRounds(_today.steps, now);
    final reminderDue = _isForeground && adventure.takeDueReminder(now);
    setState(() {});

    if (result != null) _persist();

    if (result != null && result.playerDamage > 0) {
      _showEnemyAttackNotice(adventure, result.playerDamage);
      if (adventure.playerHealth <= 0) {
        unawaited(AdventureNotificationService.cancelAdventureReminders());
      }
    }
    if (reminderDue) _showAdventureReminder(adventure);
  }

  /// Günlük adım-para tavanına ulaşıldığında bir kez gösterilir; kazanç
  /// sessizce durmaz.
  void _showCoinCapNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.monetization_on, color: AppColors.streak),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Günlük kazanç sınırına ulaştın '
                '(${_buffs.dailyCoinCap} coin). Bugünkü adımlar '
                'artık para kazandırmıyor.',
              ),
            ),
          ],
        ),
      ),
    );
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
      } else if (!_profile.ownedItemIds.contains(item.id)) {
        _profile.ownedItemIds.add(item.id);
      }
    });
    _persist();
  }

  /// Yükseltme satın alır (kozmetik, unvan, dondurma hakkı).
  ///
  /// Tekrarlanamayan bir öğe zaten sahipliyse **para düşülmez**: eski kod
  /// coin'i alıyor ama kimliği ikinci kez eklemediği için oyuncu bedavaya
  /// ödüyordu.
  void _purchase(XpStoreItem item) {
    final alreadyOwned = _profile.ownedItemIds.contains(item.id);
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
      if (!alreadyOwned) _profile.ownedItemIds.add(item.id);
    });
    _persist();
    _showStoreNotice('${item.name} satın alındı!');
  }

  /// Ekipman satın alır. Seviye kilidi (#10/#11) ve para kontrolü burada da
  /// yapılır: ekran devre dışı görünse bile son söz state'in.
  void _purchaseEquipment(Item item) {
    if (_profile.ownedItemIds.contains(item.id)) return;
    if (!item.isUnlockedAt(_profile.level)) return;
    if (_profile.coins < item.cost) return;

    setState(() {
      _profile.coins -= item.cost;
      _profile.ownedItemIds.add(item.id);
    });
    _persist();
    _showStoreNotice('${item.name} satın alındı!');
  }

  /// Item'ı kategorisine karşılık gelen slota kuşandırır.
  ///
  /// Üç kontrol de **burada** yeniden yapılır: ekran devre dışı görünse bile
  /// son söz state'in (mağaza satın almasında olduğu gibi). Kilidin tek
  /// kaynağı [Item.isUnlockedAt] (#10); ikinci bir seviye mantığı yok.
  ///
  /// Engellenen her durum **sessiz kalmaz** (Model Kuralları #4): nedeni
  /// söylenir.
  void _equipItem(Item item) {
    if (!_profile.ownedItemIds.contains(item.id)) {
      _showStoreNotice('${item.name} sende yok.');
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
    if (_profile.equippedIdInSlot(item.category.folder) == item.id) return;

    final replacedId = _profile.equipInSlot(item.category.folder, item.id);
    setState(_refreshEquipment);
    _persist();

    final replaced =
        replacedId == null
            ? null
            : ItemCatalog.byId(
              replacedId,
              characterClass: _profile.avatar.characterClass,
            );
    _showStoreNotice(
      replaced == null
          ? '${item.name} kuşanıldı.'
          : '${item.name} kuşanıldı, ${replaced.name} çıkarıldı.',
    );
  }

  /// Slotu boşaltır.
  void _unequipSlot(ItemCategory category) {
    final removedId = _profile.unequipSlot(category.folder);
    if (removedId == null) return;
    setState(_refreshEquipment);
    _persist();

    final removed = ItemCatalog.byId(
      removedId,
      characterClass: _profile.avatar.characterClass,
    );
    _showStoreNotice('${removed?.name ?? 'Item'} çıkarıldı.');
  }

  /// Item'ı satar: sahiplikten düşer, kuşanılıysa önce çıkarılır ve
  /// [sellValueFor] kadar coin geri verilir.
  ///
  /// Onay ekranını çağıran taraf (envanter) gösterir; burası kararı uygular.
  void _sellItem(Item item) {
    if (!_profile.ownedItemIds.contains(item.id)) return;
    final value = sellValueFor(item.cost);
    final wasEquipped = _profile.isEquipped(item.id);

    setState(() {
      _profile.unequipItem(item.id);
      _profile.ownedItemIds.remove(item.id);
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
      onEquip: _equipItem,
      onUnequip: _unequipSlot,
      onSell: _sellItem,
    ),
  );

  InventoryState _readInventoryState() => InventoryState(
    profile: _profile,
    ownedItems: [
      for (final id in _profile.ownedItemIds)
        if (ItemCatalog.byId(id, characterClass: _profile.avatar.characterClass)
            case final item?)
          item,
    ],
    equippedItems: _equippedItems,
    buffs: _buffs,
  );

  void _showStoreNotice(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
      );
  }

  void _openAdventure() => setState(() => _tabIndex = 1);

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
    _push(
      DailyWheelScreen(
        alreadySpunToday: _profile.wheelSpunToday,
        extraSpins: _profile.extraWheelSpins,
        level: _profile.level,
        equipment: _equipment,
        ownedItemIds: _profile.ownedItemIds,
        seed: _profile.wheelSeed,
        onSpinResult: _spinWheel,
      ),
    );
  }

  void _openRewards() => _push(RewardsScreen(rewards: _rewards));

  void _editCharacter() => _push(
    CharacterCreationScreen(
      initialAvatar: _profile.avatar,
      onCompleted: (avatar) {
        _profile.avatar = avatar;
        widget.onAvatarChanged(avatar);
        Navigator.of(context).pop();
      },
    ),
  );

  /// Mağazayı açar.
  ///
  /// **Sekmeye geçilir, ekran itilmez.** [_push] önceden inşa edilmiş bir
  /// widget örneğini rotaya veriyor; itilen rota kök Navigator'da durduğu için
  /// [RootShell]'in alt ağacında değil ve `setState` onu tazelemiyordu.
  /// Sonuç: itilen mağazada satın alma sonrası para düşüyor ama ekranda eski
  /// bakiye kalıyor, kart "Sahipsin" demiyor ve ikinci dokunuş sessizce
  /// düşüyordu. Sekme gövdesi her `setState`'te yeniden kurulduğu için bu
  /// sorun orada hiç yoktu — [_openAdventure] de aynı deseni kullanıyor.
  void _openStore() => setState(() => _tabIndex = 2);

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)).then((
      _,
    ) {
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
        dailyCoinCap: _buffs.dailyCoinCap,
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
        onChooseNewAdventure: _chooseNewAdventure,
        onAdventureUpdated: _persist,
      ),
      XpStoreScreen(
        items: _storeItems,
        equipment: _equipment,
        coins: _profile.coins,
        level: _profile.level,
        ownedItemIds: _profile.ownedItemIds,
        streakFreezes: _profile.streakFreezes,
        extraWheelSpins: _profile.extraWheelSpins,
        xpBoostActive: _profile.isXpBoostActive,
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
        onEditCharacter: _editCharacter,
        onOpenInventory: _openInventory,
      ),
    ];

    return Scaffold(
      body: tabs[_tabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          NavigationDestination(icon: Icon(Icons.explore), label: 'Macera'),
          NavigationDestination(icon: Icon(Icons.storefront), label: 'Mağaza'),
          NavigationDestination(icon: Icon(Icons.groups), label: 'Takım'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
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
