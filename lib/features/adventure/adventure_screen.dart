import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/enemy_catalog.dart';
import '../../models/adventure_quest.dart';
import '../../models/avatar_profile.dart';
import '../../models/daily_progress.dart';
import '../../models/enemy.dart';
import '../../widgets/section_card.dart';
import '../../widgets/stat_bar.dart';

class AdventureScreen extends StatefulWidget {
  final AdventureQuest? adventure;
  final int attackSerial;
  final AvatarProfile avatar;
  final DailyProgress today;
  final ValueChanged<AdventureQuest> onAdventureSelected;
  final VoidCallback onChooseNewAdventure;

  const AdventureScreen({
    super.key,
    required this.adventure,
    required this.attackSerial,
    required this.avatar,
    required this.today,
    required this.onAdventureSelected,
    required this.onChooseNewAdventure,
  });

  @override
  State<AdventureScreen> createState() => _AdventureScreenState();
}

class _AdventureScreenState extends State<AdventureScreen>
    with TickerProviderStateMixin {
  int _stepGoal = 2000;
  Enemy? _selectedEnemy;
  late final AnimationController _damageMessageController;
  late final Animation<double> _damageMessageOpacity;
  late final AnimationController _walkController;
  late final Animation<double> _walkAmount;
  Timer? _enemyAnimationTimer;
  int _pendingDamage = 0;
  int _playerDamage = 0;
  bool _showHurt = false;
  bool _showAttack = false;
  bool _showDeath = false;
  bool _showCongratulations = false;

  @override
  void initState() {
    super.initState();
    _damageMessageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _damageMessageOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 35),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 65,
      ),
    ]).animate(_damageMessageController);
    _walkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    )..repeat(reverse: true);
    _walkAmount = Tween<double>(begin: -1, end: 1).animate(
      CurvedAnimation(parent: _walkController, curve: Curves.easeInOut),
    );
    _prepareDamageFeedback();
  }

  void _prepareDamageFeedback() {
    final adventure = widget.adventure;
    _pendingDamage = 0;
    _playerDamage = 0;
    _showHurt = false;
    _showAttack = false;
    _showDeath = false;
    _showCongratulations = false;
    if (adventure == null) return;

    _pendingDamage = adventure.takePendingDamage(widget.today.steps);
    if (adventure.isDefeated(widget.today.steps)) {
      if (adventure.deathAnimationPlayed) {
        _showCongratulations = true;
        return;
      }

      adventure.deathAnimationPlayed = true;
      _showDeath = true;
      if (_pendingDamage > 0) {
        _damageMessageController.forward(from: 0);
      }
      _enemyAnimationTimer = Timer(
        Duration(milliseconds: adventure.enemy.deathAnimationDurationMs),
        () {
          if (!mounted) return;
          setState(() {
            _showDeath = false;
            _showCongratulations = true;
          });
        },
      );
      return;
    }

    if (_pendingDamage <= 0) return;

    _showHurt = true;
    _damageMessageController.forward(from: 0);
    _enemyAnimationTimer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) setState(() => _showHurt = false);
    });
  }

  @override
  void didUpdateWidget(covariant AdventureScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.adventure != widget.adventure) {
      _enemyAnimationTimer?.cancel();
      _prepareDamageFeedback();
    } else if (oldWidget.attackSerial != widget.attackSerial) {
      _playEnemyAttack();
    }
  }

  void _playEnemyAttack() {
    final adventure = widget.adventure;
    if (adventure == null || adventure.lastEnemyDamage <= 0) return;
    _enemyAnimationTimer?.cancel();
    _pendingDamage = 0;
    _playerDamage = adventure.lastEnemyDamage;
    _showHurt = false;
    _showAttack = true;
    _damageMessageController.forward(from: 0);
    _enemyAnimationTimer = Timer(
      Duration(milliseconds: adventure.enemy.attackAnimationDurationMs),
      () {
        if (mounted) setState(() => _showAttack = false);
      },
    );
  }

  @override
  void dispose() {
    _enemyAnimationTimer?.cancel();
    _damageMessageController.dispose();
    _walkController.dispose();
    super.dispose();
  }

  void _selectGoal(int value) {
    setState(() {
      _stepGoal = value;
      if (_selectedEnemy != null &&
          _stepGoal < _selectedEnemy!.minimumDailySteps) {
        _selectedEnemy = null;
      }
    });
  }

  void _startAdventure() {
    final enemy = _selectedEnemy;
    if (enemy == null) return;
    widget.onAdventureSelected(
      AdventureQuest(enemy: enemy, stepGoal: _stepGoal),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adventure = widget.adventure;
    return Scaffold(
      appBar: AppBar(title: const Text('Macera')),
      body:
          adventure == null
              ? _buildSelection(context)
              : _showCongratulations
              ? _buildCongratulations(context, adventure)
              : adventure.playerHealth <= 0 && !_showAttack
              ? _buildPlayerDefeat(context, adventure)
              : _buildAdventure(context, adventure),
    );
  }

  Widget _buildPlayerDefeat(BuildContext context, AdventureQuest adventure) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: SectionCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.heart_broken, color: AppColors.hp, size: 76),
              const SizedBox(height: 16),
              Text(
                'Dinlenme zamanı',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${adventure.enemy.name} karşısında canın tükendi. '
                'Yeni ve daha dengeli bir macera seçebilirsin.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: widget.onChooseNewAdventure,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Macera Seçimine Dön'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCongratulations(BuildContext context, AdventureQuest adventure) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: SectionCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, color: AppColors.xp, size: 82),
              const SizedBox(height: 16),
              Text(
                'Tebrikler!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.xp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${adventure.enemy.name} yenildi!',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${adventure.enemy.xpReward} XP kazandın. Yeni bir macera '
                'seni bekliyor.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: widget.onChooseNewAdventure,
                  icon: const Icon(Icons.explore),
                  label: const Text('Yeni Macera Seç'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelection(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Bugünkü maceranı seç',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Hedefini belirle, meydan okuyabileceğin düşmanı seç ve yürüyüşe başla.',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Günlük adım hedefin',
          child: Column(
            children: [
              Text(
                '$_stepGoal adım',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children:
                    [2000, 5000, 7000, 10000].map((goal) {
                      return ChoiceChip(
                        label: Text('${goal ~/ 1000}.000'),
                        selected: _stepGoal == goal,
                        onSelected: (_) => _selectGoal(goal),
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Düşmanını seç',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...EnemyCatalog.enemies.map((enemy) {
          final unlocked = _stepGoal >= enemy.minimumDailySteps;
          final selected = _selectedEnemy?.id == enemy.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _EnemyChoiceCard(
              enemy: enemy,
              unlocked: unlocked,
              selected: selected,
              onTap:
                  unlocked
                      ? () => setState(() {
                        _selectedEnemy = enemy;
                        _stepGoal = enemy.minimumDailySteps;
                      })
                      : null,
            ),
          );
        }),
        FilledButton.icon(
          onPressed: _selectedEnemy == null ? null : _startAdventure,
          icon: const Icon(Icons.explore),
          label: const Text('Maceraya Başla'),
        ),
      ],
    );
  }

  Widget _buildAdventure(BuildContext context, AdventureQuest adventure) {
    final defeated = adventure.isDefeated(widget.today.steps);
    final remaining = adventure.remainingHealth(widget.today.steps);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          child: Column(
            children: [
              SizedBox(
                height: 260,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      bottom: 4,
                      width: 135,
                      height: 180,
                      child: AnimatedBuilder(
                        animation: _walkAmount,
                        child: Image.asset(
                          widget.avatar.characterAsset,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                        builder: (context, child) {
                          final amount = _walkAmount.value;
                          return Transform.translate(
                            offset: Offset(amount * 6, -3 * (1 - amount.abs())),
                            child: Transform.rotate(
                              angle: amount * 0.018,
                              child: child,
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      right: -8,
                      bottom: 0,
                      width: 210,
                      height: 230,
                      child: ClipRect(
                        child: Transform.scale(
                          scale: 3,
                          child: Image.asset(
                            _showDeath
                                ? adventure.enemy.deathAsset
                                : _showAttack
                                ? adventure.enemy.attackAsset
                                : _showHurt
                                ? adventure.enemy.hurtAsset
                                : adventure.enemy.walkAsset,
                            key: ValueKey(
                              _showDeath
                                  ? 'death'
                                  : _showAttack
                                  ? 'attack-${widget.attackSerial}'
                                  : _showHurt
                                  ? 'hurt'
                                  : 'walk',
                            ),
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                          ),
                        ),
                      ),
                    ),
                    if (_pendingDamage > 0)
                      Positioned(
                        left: 8,
                        right: 8,
                        top: 8,
                        child: FadeTransition(
                          opacity: _damageMessageOpacity,
                          child: Text(
                            'Düşmanın $_pendingDamage canını aldın. '
                            'Böyle devam et!',
                            textAlign: TextAlign.center,
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              color: AppColors.xp,
                              fontWeight: FontWeight.w900,
                              shadows: const [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (_playerDamage > 0)
                      Positioned(
                        left: 8,
                        width: 135,
                        top: 40,
                        child: FadeTransition(
                          opacity: _damageMessageOpacity,
                          child: Text(
                            '-$_playerDamage CAN',
                            textAlign: TextAlign.center,
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              color: AppColors.hp,
                              fontWeight: FontWeight.w900,
                              shadows: const [
                                Shadow(color: Colors.black, blurRadius: 8),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                adventure.enemy.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                defeated ? 'Yenildi' : 'Seni bekliyor',
                style: TextStyle(
                  color: defeated ? AppColors.xp : AppColors.streak,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildCountdownCard(context, adventure),
        const SizedBox(height: 12),
        SectionCard(
          title: defeated ? 'Zafer senin!' : 'Görev mesajın',
          child: Text(
            defeated
                ? '${adventure.enemy.name} yenildi. ${adventure.enemy.xpReward} XP kazandın; bu zaferi adım adım hak ettin!'
                : adventure.enemy.questText,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Macera durumu',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatBar(
                label: 'Canavar Canı',
                icon: Icons.favorite,
                color: AppColors.hp,
                progress: adventure.healthProgress(widget.today.steps),
                valueText: '$remaining / ${adventure.stepGoal}',
              ),
              const SizedBox(height: 14),
              StatBar(
                label: 'Senin Canın',
                icon: Icons.shield,
                color: AppColors.xp,
                progress:
                    adventure.playerHealth / AdventureQuest.maxPlayerHealth,
                valueText:
                    '${adventure.playerHealth} / ${AdventureQuest.maxPlayerHealth}',
              ),
              const SizedBox(height: 14),
              StatBar(
                label: 'Adım İlerlemesi',
                icon: Icons.directions_walk,
                color: AppColors.primary,
                progress: widget.today.stepProgress,
                valueText: '${widget.today.steps} / ${adventure.stepGoal} adım',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.xp),
                  const SizedBox(width: 8),
                  Text('Zafer ödülü: ${adventure.enemy.xpReward} XP'),
                ],
              ),
            ],
          ),
        ),
        if (defeated) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: widget.onChooseNewAdventure,
            icon: const Icon(Icons.refresh),
            label: const Text('Yeni Macera Seç'),
          ),
        ],
      ],
    );
  }

  Widget _buildCountdownCard(BuildContext context, AdventureQuest adventure) {
    final remaining = adventure.countdownRemaining(DateTime.now());
    final roundSteps = adventure.stepsThisRound(widget.today.steps);
    final minutes = remaining.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = remaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return SectionCard(
      title: 'Düşman saldırısına kalan süre',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$minutes:$seconds',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppColors.streak,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value:
                adventure.roundTargetSteps == 0
                    ? 1
                    : (roundSteps / adventure.roundTargetSteps).clamp(0, 1),
            minHeight: 9,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 8),
          Text('$roundSteps / ${adventure.roundTargetSteps} tur adımı'),
          const SizedBox(height: 4),
          Text(
            'Tempolu yürüyüş için ${adventure.roundDurationMinutes - 1} dk '
            '+ 1 dk adım senkronizasyon payı. Hedef eksik kalırsa '
            '${adventure.enemy.name}, eksik oranına göre en fazla '
            '${adventure.enemy.attackDamage} can vurur.',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _EnemyChoiceCard extends StatelessWidget {
  final Enemy enemy;
  final bool unlocked;
  final bool selected;
  final VoidCallback? onTap;

  const _EnemyChoiceCard({
    required this.enemy,
    required this.unlocked,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: unlocked ? 1 : 0.45,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  width: 132,
                  height: 132,
                  child: ClipRect(
                    child: Transform.scale(
                      scale: 3,
                      child: Image.asset(
                        enemy.idleAsset,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        enemy.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text('Ödül: ${enemy.xpReward} XP'),
                      const SizedBox(height: 4),
                      Text(
                        unlocked
                            ? 'Bu hedef için uygun'
                            : 'En az ${enemy.minimumDailySteps} adım gerekli',
                        style: TextStyle(
                          color: unlocked ? AppColors.xp : Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle
                      : unlocked
                      ? Icons.radio_button_unchecked
                      : Icons.lock,
                  color: selected ? AppColors.primary : Colors.white54,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
