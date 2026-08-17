import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../models/adventure_quest.dart';
import '../../models/avatar_profile.dart';
import '../../models/daily_progress.dart';
import '../../models/reward.dart';
import '../../models/user_profile.dart';
import '../../models/xp_store_item.dart';
import '../../services/adventure_notification_service.dart';
import '../adventure/adventure_screen.dart';
import '../character/character_creation_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../rewards/rewards_screen.dart';
import '../store/xp_store_screen.dart';
import '../team/team_screen.dart';
import '../wheel/daily_wheel_screen.dart';

/// Uygulamanın kök iskeleti: alt gezinme çubuğu ve tüm oyun durumunun
/// (state) tutulduğu yer. Şimdilik yerel state kullanır; ileride bir
/// state-management çözümüne (Riverpod/Bloc) veya kalıcı depolamaya
/// (Hive/SharedPreferences) taşınabilir.
class RootShell extends StatefulWidget {
  final AvatarProfile avatar;
  final ValueChanged<AvatarProfile> onAvatarChanged;

  const RootShell({
    super.key,
    required this.avatar,
    required this.onAvatarChanged,
  });

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> with WidgetsBindingObserver {
  int _tabIndex = 0;

  late final UserProfile _profile = UserProfile(avatar: widget.avatar);
  DailyProgress _today = DailyProgress(date: DateTime.now());
  AdventureQuest? _adventure;
  final List<Reward> _rewards = [];
  late final _team = MockData.defaultTeam();
  final List<XpStoreItem> _storeItems = MockData.storeItems();
  bool _wheelSpunToday = false;
  Timer? _adventureClock;
  bool _isForeground = true;
  final Random _random = Random();

  static const _reminderMessages = [
    'Çabuk ol! {enemy} için {steps} adım kaldı.',
    '{enemy} yaklaşıyor! {steps} adım daha atmalısın.',
    'Ritmini kaybetme; {enemy} için kalan adım: {steps}.',
    'Harekete geç! {enemy} gücünü koruyor, {steps} adım kaldı.',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _adventureClock = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateAdventureClock(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _adventureClock?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isForeground = true;
      unawaited(AdventureNotificationService.cancelAdventureReminders());
      final adventure = _adventure;
      if (adventure != null) {
        adventure.nextReminderAt = DateTime.now().add(
          AdventureQuest.reminderInterval,
        );
      }
      _updateAdventureClock();
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _isForeground = false;
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
      _profile.avatar = widget.avatar;
    }
  }

  void _simulateSteps(int amount) {
    var enemyDefeated = false;
    setState(() {
      _today.addSteps(amount);
      final adventure = _adventure;
      if (adventure != null &&
          adventure.isDefeated(_today.steps) &&
          !adventure.xpAwarded) {
        adventure.xpAwarded = true;
        _profile.addXp(adventure.enemy.xpReward);
        enemyDefeated = true;
      }
      if (_today.stepGoalReached && _profile.streakDays == 0) {
        _profile.streakDays = 1;
      }
    });
    if (enemyDefeated) {
      unawaited(AdventureNotificationService.cancelAdventureReminders());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_adventure!.enemy.name} yenildi! '
            '${_adventure!.enemy.xpReward} XP kazandın.',
          ),
        ),
      );
    }
  }

  void _selectAdventure(AdventureQuest adventure) {
    setState(() {
      _adventure = adventure;
      _today = DailyProgress(
        date: DateTime.now(),
        stepGoal: adventure.stepGoal,
      );
    });
    unawaited(AdventureNotificationService.requestPermission());
  }

  void _chooseNewAdventure() {
    setState(() {
      _adventure = null;
      _today = DailyProgress(date: DateTime.now());
    });
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

    final now = DateTime.now();
    final result = adventure.resolveExpiredRound(_today.steps, now);
    final reminderDue = _isForeground && adventure.takeDueReminder(now);
    setState(() {});

    if (result != null && result.playerDamage > 0) {
      _showEnemyAttackNotice(adventure, result.playerDamage);
      if (adventure.playerHealth <= 0) {
        unawaited(AdventureNotificationService.cancelAdventureReminders());
      }
    }
    if (reminderDue) _showAdventureReminder(adventure);
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
        .replaceAll('{steps}', '${adventure.remainingHealth(_today.steps)}');
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

  void _spinWheel(int xpWon) {
    setState(() {
      _wheelSpunToday = true;
      _profile.addXp(xpWon);
    });
  }

  void _purchase(XpStoreItem item) {
    if (_profile.coins < item.cost) return;
    setState(() => _profile.coins -= item.cost);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${item.name} satın alındı!')));
  }

  void _openAdventure() => setState(() => _tabIndex = 1);

  void _openWheel() => _push(
    DailyWheelScreen(
      alreadySpunToday: _wheelSpunToday,
      onSpinResult: _spinWheel,
    ),
  );

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

  void _openStore() => _push(
    XpStoreScreen(
      items: _storeItems,
      coins: _profile.coins,
      onPurchase: _purchase,
    ),
  );

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
        onSimulateSteps: _simulateSteps,
      ),
      AdventureScreen(
        adventure: _adventure,
        attackSerial: _adventure?.enemyAttackSerial ?? 0,
        avatar: _profile.avatar,
        today: _today,
        onAdventureSelected: _selectAdventure,
        onChooseNewAdventure: _chooseNewAdventure,
      ),
      XpStoreScreen(
        items: _storeItems,
        coins: _profile.coins,
        onPurchase: _purchase,
      ),
      TeamScreen(team: _team),
      ProfileScreen(profile: _profile, onEditCharacter: _editCharacter),
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
