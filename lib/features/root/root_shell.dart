import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../models/avatar_profile.dart';
import '../../models/boss_quest.dart';
import '../../models/daily_progress.dart';
import '../../models/reward.dart';
import '../../models/user_profile.dart';
import '../../models/xp_store_item.dart';
import '../boss/boss_battle_screen.dart';
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

class _RootShellState extends State<RootShell> {
  int _tabIndex = 0;

  late final UserProfile _profile = UserProfile(avatar: widget.avatar);
  late final DailyProgress _today = DailyProgress(date: DateTime.now());
  late final BossQuest _dragon = MockData.dailyDragon();
  final List<Reward> _rewards = [];
  late final _team = MockData.defaultTeam();
  final List<XpStoreItem> _storeItems = MockData.storeItems();
  bool _wheelSpunToday = false;

  @override
  void didUpdateWidget(covariant RootShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatar != widget.avatar) {
      _profile.avatar = widget.avatar;
    }
  }

  void _simulateSteps(int amount) {
    setState(() {
      _today.addSteps(amount);
      _dragon.currentSteps = _today.steps;
      _profile.addXp((amount / 10).round());
      if (_today.stepGoalReached && _profile.streakDays == 0) {
        _profile.streakDays = 1;
      }
    });
  }

  void _claimDragonReward(Reward reward) {
    setState(() {
      _rewards.add(reward);
      _dragon.rewardClaimed = true;
      _profile.coins += 200;
    });
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

  void _openDragon() => _push(
    BossBattleScreen(
      dragon: _dragon,
      today: _today,
      onRewardClaimed: _claimDragonReward,
    ),
  );

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
        dragon: _dragon,
        onOpenDragon: _openDragon,
        onOpenWheel: _openWheel,
        onOpenRewards: _openRewards,
        onOpenStore: _openStore,
        onSimulateSteps: _simulateSteps,
      ),
      BossBattleScreen(
        dragon: _dragon,
        today: _today,
        onRewardClaimed: _claimDragonReward,
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
          NavigationDestination(
            icon: Icon(Icons.local_fire_department),
            label: 'Ejderha',
          ),
          NavigationDestination(icon: Icon(Icons.storefront), label: 'Mağaza'),
          NavigationDestination(icon: Icon(Icons.groups), label: 'Takım'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
