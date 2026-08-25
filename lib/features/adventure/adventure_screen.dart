import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/game_clock.dart';
import '../../core/utils/gif_timing.dart';
import '../../data/enemy_catalog.dart';
import '../../models/adventure_quest.dart';
import '../../models/avatar_profile.dart';
import '../../models/daily_progress.dart';
import '../../models/enemy.dart';
import '../../services/character_catalog.dart';
import '../../widgets/pixel_sprite.dart';
import '../../widgets/section_card.dart';
import '../../widgets/stat_bar.dart';

class AdventureScreen extends StatefulWidget {
  final AdventureQuest? adventure;
  final int roundSerial;
  final AvatarProfile avatar;
  final DailyProgress today;
  final ValueChanged<AdventureQuest> onAdventureSelected;
  final VoidCallback onChooseNewAdventure;
  final VoidCallback onAdventureUpdated;

  const AdventureScreen({
    super.key,
    required this.adventure,
    required this.roundSerial,
    required this.avatar,
    required this.today,
    required this.onAdventureSelected,
    required this.onChooseNewAdventure,
    required this.onAdventureUpdated,
  });

  @override
  State<AdventureScreen> createState() => _AdventureScreenState();
}

class _AdventureScreenState extends State<AdventureScreen>
    with TickerProviderStateMixin {
  static const _dayBackgrounds = [
    'lib/Backgrounds/versionA_platform.png',
    'lib/Backgrounds/versionB_platform.png',
    'lib/Backgrounds/versionC_platform.png',
  ];
  static const _nightBackgrounds = [
    'lib/Backgrounds/versionA1_platform.png',
    'lib/Backgrounds/versionB1_platform.png',
    'lib/Backgrounds/versionC1_platform.png',
  ];

  int _stepGoal = 500;
  Enemy? _selectedEnemy;
  late final AnimationController _damageMessageController;
  late final Animation<double> _damageMessageOpacity;
  late final AnimationController _roundAttackController;
  late final Animation<double> _roundAttackAmount;
  late final AnimationController _roundTransitionController;
  late final Animation<double> _roundTransitionShake;
  Timer? _enemyAnimationTimer;
  int _pendingDamage = 0;
  int _playerDamage = 0;
  bool _showHurt = false;
  bool _showAttack = false;
  bool _showDeath = false;
  bool _showCongratulations = false;
  bool _showRoundVictory = false;
  bool _showEnemyRoundVictory = false;
  int _victoryRound = 0;
  int _victoryCycle = 0;
  int _enemyVictoryCycle = 0;
  bool _isFinalVictory = false;
  bool _showEnemyDeath = false;
  bool _showFrozenEnemy = false;
  bool _showDeathCongratulations = false;
  double _overlayEnemyHealth = 1;
  ui.Image? _frozenDeathFrame;
  bool _showRoundTransition = false;
  int _transitionRound = 1;
  String? _roundPlayerAttackAsset;
  String? _lastRoundPlayerAttackAsset;
  String? _roundEnemyAttackAsset;
  String? _lastRoundEnemyAttackAsset;

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
    _roundAttackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _roundAttackAmount = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 55,
      ),
    ]).animate(_roundAttackController);
    _roundTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    );
    _roundTransitionShake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -7), weight: 8),
      TweenSequenceItem(tween: Tween(begin: -7, end: 7), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 7, end: -5), weight: 8),
      TweenSequenceItem(tween: Tween(begin: -5, end: 5), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 5, end: -3), weight: 8),
      TweenSequenceItem(tween: Tween(begin: -3, end: 3), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 3, end: 0), weight: 12),
      TweenSequenceItem(tween: ConstantTween(0), weight: 40),
    ]).animate(
      CurvedAnimation(
        parent: _roundTransitionController,
        curve: Curves.easeOut,
      ),
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
    _showEnemyRoundVictory = false;
    if (adventure == null) return;

    if (adventure.roundOutcomeSerial > adventure.presentedRoundOutcomeSerial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (adventure.lastRoundWon) {
          _playRoundVictory(adventure);
        } else {
          _playEnemyRoundVictory(adventure);
        }
      });
      return;
    }

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
    } else if (oldWidget.roundSerial != widget.roundSerial) {
      final adventure = widget.adventure;
      if (adventure == null) return;
      if (adventure.lastRoundWon) {
        _playRoundVictory(adventure);
      } else {
        _playEnemyRoundVictory(adventure);
      }
    }
  }

  Future<void> _playRoundVictory(AdventureQuest adventure) async {
    _enemyAnimationTimer?.cancel();
    _roundAttackController.stop();
    final classes = await CharacterCatalog.load();
    if (!mounted) return;
    final matchingClasses = classes.where(
      (characterClass) => characterClass.id == widget.avatar.characterClass,
    );
    final attacks =
        matchingClasses.isEmpty
            ? const <String>[]
            : matchingClasses.first.attackAssets;
    final candidates =
        attacks.length > 1
            ? attacks
                .where((asset) => asset != _lastRoundPlayerAttackAsset)
                .toList()
            : attacks;
    final playerAttackAsset =
        candidates.isEmpty
            ? widget.avatar.characterAsset
            : candidates[Random().nextInt(candidates.length)];
    _lastRoundPlayerAttackAsset = playerAttackAsset;
    final playerAttackDuration = await GifTiming.cycle(playerAttackAsset);
    if (!mounted) return;
    _roundAttackController.duration = playerAttackDuration;

    final isFinalVictory = adventure.isDefeated(widget.today.steps);
    final finalRoundSteps =
        adventure.stepGoal % AdventureQuest.stageStepTarget == 0
            ? min(adventure.stepGoal, AdventureQuest.stageStepTarget)
            : adventure.stepGoal % AdventureQuest.stageStepTarget;
    final healthBeforeFinalRound = finalRoundSteps / adventure.stepGoal;
    setState(() {
      _showRoundVictory = true;
      _showEnemyRoundVictory = false;
      _victoryRound = adventure.lastResolvedRound;
      _victoryCycle = 1;
      _isFinalVictory = isFinalVictory;
      _showEnemyDeath = false;
      _showFrozenEnemy = false;
      _showDeathCongratulations = false;
      _overlayEnemyHealth =
          isFinalVictory
              ? healthBeforeFinalRound
              : adventure.healthProgress(widget.today.steps);
      _showHurt = false;
      _showAttack = false;
      _roundPlayerAttackAsset = playerAttackAsset;
    });

    try {
      for (var cycle = 1; cycle <= 2; cycle++) {
        if (!mounted || !_showRoundVictory) return;
        if (_victoryCycle != cycle) {
          setState(() => _victoryCycle = cycle);
        }
        await _roundAttackController.forward(from: 0).orCancel;
        if (isFinalVictory && mounted) {
          setState(() {
            _overlayEnemyHealth = healthBeforeFinalRound * (1 - (cycle / 2));
          });
        }
        if (cycle < 2) {
          await Future<void>.delayed(const Duration(milliseconds: 140));
        }
      }
    } on TickerCanceled {
      return;
    }

    if (!mounted) return;
    if (isFinalVictory) {
      final frozenFrameFuture = _decodeLastGifFrame(adventure.enemy.deathAsset);
      setState(() {
        _showEnemyDeath = true;
        _overlayEnemyHealth = 0;
      });
      await Future<void>.delayed(
        Duration(milliseconds: adventure.enemy.deathAnimationDurationMs),
      );
      final frozenFrame = await frozenFrameFuture;
      if (!mounted) {
        frozenFrame?.dispose();
        return;
      }
      _frozenDeathFrame?.dispose();
      _frozenDeathFrame = frozenFrame;
      setState(() {
        _showEnemyDeath = false;
        _showFrozenEnemy = frozenFrame != null;
        _showDeathCongratulations = true;
        adventure.deathAnimationPlayed = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 2200));
      if (!mounted) return;
    }

    if (isFinalVictory) {
      setState(() {
        _showRoundVictory = false;
        _showCongratulations = true;
      });
      _markRoundOutcomePresented(adventure);
      return;
    }

    _markRoundOutcomePresented(adventure);
    await _playRoundTransition(adventure.currentRound);
  }

  Future<void> _playRoundTransition(int round) async {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _showRoundVictory = false;
      _showEnemyRoundVictory = false;
      _showRoundTransition = true;
      _transitionRound = round;
    });
    try {
      await _roundTransitionController.forward(from: 0).orCancel;
    } on TickerCanceled {
      return;
    }
    if (!mounted) return;
    setState(() => _showRoundTransition = false);
  }

  Future<ui.Image?> _decodeLastGifFrame(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      ui.Image? lastFrame;
      for (var index = 0; index < codec.frameCount; index++) {
        final frame = await codec.getNextFrame();
        lastFrame?.dispose();
        lastFrame = frame.image;
      }
      codec.dispose();
      return lastFrame;
    } catch (_) {
      return null;
    }
  }

  Future<void> _playEnemyRoundVictory(AdventureQuest adventure) async {
    if (adventure.lastEnemyDamage <= 0) {
      _markRoundOutcomePresented(adventure);
      return;
    }
    _enemyAnimationTimer?.cancel();
    _roundAttackController.stop();
    final attacks = adventure.enemy.attackAssets;
    final candidates =
        attacks.length > 1
            ? attacks
                .where((asset) => asset != _lastRoundEnemyAttackAsset)
                .toList()
            : attacks;
    final attackAsset = candidates[Random().nextInt(candidates.length)];
    _lastRoundEnemyAttackAsset = attackAsset;
    final attackDuration = await GifTiming.cycle(attackAsset);
    if (!mounted) return;
    _roundAttackController.duration = attackDuration;

    setState(() {
      _showRoundVictory = false;
      _showEnemyRoundVictory = true;
      _victoryRound = adventure.lastResolvedRound;
      _enemyVictoryCycle = 1;
      _roundEnemyAttackAsset = attackAsset;
      _pendingDamage = 0;
      _playerDamage = adventure.lastEnemyDamage;
      _showHurt = false;
      _showAttack = false;
    });

    try {
      for (var cycle = 1; cycle <= 2; cycle++) {
        if (!mounted || !_showEnemyRoundVictory) return;
        if (_enemyVictoryCycle != cycle) {
          setState(() => _enemyVictoryCycle = cycle);
        }
        await _roundAttackController.forward(from: 0).orCancel;
        if (cycle < 2) {
          await Future<void>.delayed(const Duration(milliseconds: 140));
        }
      }
    } on TickerCanceled {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    setState(() {
      _showEnemyRoundVictory = false;
      _playerDamage = 0;
    });
    _markRoundOutcomePresented(adventure);
    if (adventure.playerHealth > 0) {
      await _playRoundTransition(adventure.currentRound);
    }
  }

  void _markRoundOutcomePresented(AdventureQuest adventure) {
    if (adventure.presentedRoundOutcomeSerial >= adventure.roundOutcomeSerial) {
      return;
    }
    adventure.presentedRoundOutcomeSerial = adventure.roundOutcomeSerial;
    widget.onAdventureUpdated();
  }

  @override
  void dispose() {
    _enemyAnimationTimer?.cancel();
    _damageMessageController.dispose();
    _roundAttackController.dispose();
    _roundTransitionController.dispose();
    _frozenDeathFrame?.dispose();
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

  Future<void> _showGoalPicker() async {
    const increment = 500;
    var draftGoal = _stepGoal;
    final controller = FixedExtentScrollController(
      initialItem: (_stepGoal ~/ increment) - 1,
    );

    final int? selectedGoal;
    // `try/finally`: sayfa açıkken bir istisna çıkarsa (ör. rota beklenmedik
    // şekilde kapanırsa) `controller.dispose()` hiç çalışmıyor ve denetleyici
    // sızıyordu.
    try {
      selectedGoal = await showModalBottomSheet<int>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              return Container(
                height: MediaQuery.sizeOf(context).height * 0.68,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  border: Border(
                    top: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Icon(
                        Icons.gps_fixed,
                        color: AppColors.primary,
                        size: 42,
                        shadows: [
                          Shadow(color: AppColors.primary, blurRadius: 24),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'GÜNLÜK HEDEFİNİ SEÇ',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const Text(
                        '500 adımlık aralıklarla yukarı veya aşağı kaydır',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ShaderMask(
                              shaderCallback:
                                  (bounds) => const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.white,
                                      Colors.white,
                                      Colors.transparent,
                                    ],
                                    stops: [0, 0.18, 0.82, 1],
                                  ).createShader(bounds),
                              blendMode: BlendMode.dstIn,
                              child: ListWheelScrollView.useDelegate(
                                controller: controller,
                                itemExtent: 78,
                                diameterRatio: 1.5,
                                perspective: 0.0025,
                                physics: const FixedExtentScrollPhysics(),
                                useMagnifier: true,
                                magnification: 1.12,
                                overAndUnderCenterOpacity: 0.3,
                                onSelectedItemChanged: (index) {
                                  final nextGoal = (index + 1) * increment;
                                  if (nextGoal == draftGoal) return;
                                  HapticFeedback.selectionClick();
                                  setSheetState(() => draftGoal = nextGoal);
                                },
                                childDelegate: ListWheelChildBuilderDelegate(
                                  // Negatif indeksleri tamamen kapatır; pratikte
                                  // sınırsız bir üst aralık bırakırken ilk değer
                                  // her zaman 500 adım olarak kalır.
                                  childCount: 0x7fffffff,
                                  builder: (context, index) {
                                    final goal = (index + 1) * increment;
                                    final selected = goal == draftGoal;
                                    return Center(
                                      child: AnimatedDefaultTextStyle(
                                        duration: const Duration(
                                          milliseconds: 140,
                                        ),
                                        style: TextStyle(
                                          color:
                                              selected
                                                  ? Colors.white
                                                  : Colors.white70,
                                          fontSize: selected ? 43 : 27,
                                          fontWeight:
                                              selected
                                                  ? FontWeight.w900
                                                  : FontWeight.w500,
                                          shadows:
                                              selected
                                                  ? const [
                                                    Shadow(
                                                      color: AppColors.primary,
                                                      blurRadius: 20,
                                                    ),
                                                  ]
                                                  : null,
                                        ),
                                        child: Text(
                                          '${_formatNumber(goal)} adım',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            IgnorePointer(
                              child: Container(
                                height: 82,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.symmetric(
                                    horizontal: BorderSide(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.9,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 28,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: () => Navigator.pop(context, draftGoal),
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text('${_formatNumber(draftGoal)} ADIMI SEÇ'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      controller.dispose();
    }
    if (selectedGoal != null && mounted) _selectGoal(selectedGoal);
  }

  void _startAdventure() {
    final enemy = _selectedEnemy;
    if (enemy == null) return;
    final startedAt = GameClock.now();
    final backgroundPool =
        startedAt.hour >= 6 && startedAt.hour < 18
            ? _dayBackgrounds
            : _nightBackgrounds;
    final backgroundAsset =
        backgroundPool[Random(
          startedAt.microsecondsSinceEpoch,
        ).nextInt(backgroundPool.length)];
    widget.onAdventureSelected(
      AdventureQuest(
        enemy: enemy,
        stepGoal: _stepGoal,
        backgroundAsset: backgroundAsset,
        // Günün adımları sıfırlanmaz; macera bu noktadan itibaren sayar.
        startingSteps: widget.today.steps,
        startedAt: startedAt,
      ),
    );
  }

  Future<void> _showEnemyPreview(Enemy enemy) async {
    HapticFeedback.mediumImpact();
    setState(() => _selectedEnemy = enemy);

    final shouldStart = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder:
          (context, animation, secondaryAnimation) =>
              _EnemyPreviewDialog(enemy: enemy, selectedGoal: _stepGoal),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );

    if (shouldStart == true && mounted) _startAdventure();
  }

  @override
  Widget build(BuildContext context) {
    final adventure = widget.adventure;
    final content =
        adventure == null
            ? _buildSelection(context)
            : _showCongratulations
            ? _buildCongratulations(context, adventure)
            : adventure.playerHealth <= 0 && !_showAttack
            ? _buildPlayerDefeat(context, adventure)
            : _buildAdventure(context, adventure);
    return Scaffold(
      appBar: AppBar(title: const Text('Macera')),
      body: Stack(
        children: [
          Positioned.fill(child: content),
          if (_showRoundVictory && adventure != null)
            Positioned.fill(child: _buildRoundVictoryOverlay(adventure)),
          if (_showEnemyRoundVictory && adventure != null)
            Positioned.fill(child: _buildEnemyRoundVictoryOverlay(adventure)),
        ],
      ),
    );
  }

  Widget _buildRoundVictoryOverlay(AdventureQuest adventure) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.9),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Text(
                '$_victoryRound. ROUND',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _showDeathCongratulations ? 'TEBRİKLER!' : 'ROUND SENİN!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  shadows: const [
                    Shadow(color: AppColors.primary, blurRadius: 28),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _showDeathCongratulations
                    ? '${adventure.enemy.name} yenildi!'
                    : 'Round hedefini süresi dolmadan tamamladın',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60),
              ),
              if (_isFinalVictory) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.favorite, color: AppColors.hp, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 420),
                        tween: Tween<double>(end: _overlayEnemyHealth),
                        builder: (context, health, _) {
                          return LinearProgressIndicator(
                            value: health.clamp(0, 1),
                            minHeight: 9,
                            borderRadius: BorderRadius.circular(99),
                            color: AppColors.hp,
                            backgroundColor: AppColors.hp.withValues(
                              alpha: 0.18,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${(_overlayEnemyHealth * adventure.stepGoal).round()} CAN',
                      style: const TextStyle(
                        color: AppColors.hp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
              const Spacer(),
              SizedBox(
                height: 260,
                child: AnimatedBuilder(
                  animation: _roundAttackAmount,
                  builder: (context, _) {
                    final attack = _roundAttackAmount.value;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: -12,
                          bottom: -2,
                          width: 210,
                          height: 230,
                          child: PixelSprite(
                            asset:
                                _roundPlayerAttackAsset ??
                                widget.avatar.characterAsset,
                            scale: 3,
                            imageKey: ValueKey(
                              'player-attack-$_victoryRound-$_victoryCycle',
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          width: 210,
                          height: 230,
                          child: Transform.translate(
                            offset: Offset(attack * 10, 0),
                            child: ClipRect(
                              child: Transform.scale(
                                scale: 3,
                                child:
                                    _showFrozenEnemy &&
                                            _frozenDeathFrame != null
                                        ? RawImage(
                                          image: _frozenDeathFrame,
                                          fit: BoxFit.contain,
                                          filterQuality: FilterQuality.none,
                                        )
                                        : Image.asset(
                                          _showEnemyDeath
                                              ? adventure.enemy.deathAsset
                                              : adventure.enemy.hurtAsset,
                                          key: ValueKey(
                                            _showEnemyDeath
                                                ? 'round-death-$_victoryRound'
                                                : 'round-hurt-$_victoryRound-$_victoryCycle',
                                          ),
                                          fit: BoxFit.contain,
                                          filterQuality: FilterQuality.none,
                                          gaplessPlayback: false,
                                        ),
                              ),
                            ),
                          ),
                        ),
                        if (!_showEnemyDeath &&
                            !_showFrozenEnemy &&
                            attack > 0.38 &&
                            attack < 0.9)
                          const Positioned(
                            left: 0,
                            right: 0,
                            top: 62,
                            child: Text(
                              'VURUŞ!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.streak,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                shadows: [
                                  Shadow(color: Colors.black, blurRadius: 8),
                                  Shadow(
                                    color: AppColors.streak,
                                    blurRadius: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const Spacer(),
              Text(
                _showDeathCongratulations
                    ? 'Canavar yere serildi'
                    : _showEnemyDeath
                    ? 'Son darbe!'
                    : 'Saldırı $_victoryCycle / 2',
                style: const TextStyle(
                  color: Colors.white38,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              LinearProgressIndicator(
                value:
                    _showDeathCongratulations
                        ? 1
                        : _showEnemyDeath
                        ? 0.92
                        : _victoryCycle / 2,
                minHeight: 5,
                borderRadius: BorderRadius.circular(99),
                backgroundColor: Colors.white10,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnemyRoundVictoryOverlay(AdventureQuest adventure) {
    final healthProgress =
        adventure.playerHealth / AdventureQuest.maxPlayerHealth;
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.9),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Text(
                '$_victoryRound. ROUND',
                style: const TextStyle(
                  color: AppColors.hp,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ROUND CANAVARIN!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  shadows: const [Shadow(color: AppColors.hp, blurRadius: 28)],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '${adventure.enemy.name}, süre dolunca saldırdı',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.favorite, color: AppColors.hp, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: healthProgress.clamp(0, 1),
                      minHeight: 9,
                      borderRadius: BorderRadius.circular(99),
                      color: AppColors.hp,
                      backgroundColor: AppColors.hp.withValues(alpha: 0.18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${adventure.playerHealth} CAN',
                    style: const TextStyle(
                      color: AppColors.hp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                height: 260,
                child: AnimatedBuilder(
                  animation: _roundAttackAmount,
                  builder: (context, _) {
                    final attack = _roundAttackAmount.value;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: -12,
                          bottom: -2,
                          width: 210,
                          height: 230,
                          child: Transform.translate(
                            offset: Offset(-attack * 9, attack * 3),
                            child: PixelSprite(
                              asset: widget.avatar.characterAsset,
                              scale: 3,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          width: 210,
                          height: 230,
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.diagonal3Values(-1, 1, 1),
                            child: PixelSprite(
                              asset:
                                  _roundEnemyAttackAsset ??
                                  adventure.enemy.attackAsset,
                              scale: 3,
                              offset: const Offset(-8, 0),
                              imageKey: ValueKey(
                                'enemy-round-attack-$_victoryRound-$_enemyVictoryCycle-$_roundEnemyAttackAsset',
                              ),
                            ),
                          ),
                        ),
                        if (attack > 0.35)
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 62,
                            child: Text(
                              '-${adventure.lastEnemyDamage} CAN',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.hp,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                shadows: [
                                  Shadow(color: Colors.black, blurRadius: 8),
                                  Shadow(color: AppColors.hp, blurRadius: 18),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const Spacer(),
              Text(
                '${adventure.enemy.name} saldırıyor • '
                '$_enemyVictoryCycle / 2',
                style: const TextStyle(
                  color: Colors.white38,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
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
        _GoalSelectorButton(goal: _stepGoal, onTap: _showGoalPicker),
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
              onTap: unlocked ? () => _showEnemyPreview(enemy) : null,
            ),
          );
        }),
        const Padding(
          padding: EdgeInsets.only(top: 2, bottom: 16),
          child: Text(
            'Düşmanın ayrıntılarını görmek ve macerayı başlatmak için karta dokun.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Sprite kutuları eskiden sabit 210 px'di. Dar ekranda
                      // (320 dp, sahne genişliği ~256 px) iki kutu üst üste
                      // biniyor ve sonra çizilen düşman oyuncuyu **tamamen
                      // örtüyordu**. Kutu genişliği artık sahneden türetiliyor:
                      // iki figürün merkezleri arasında en az [minGap] kalır.
                      const minGap = 110.0;
                      const playerInset = 8.0;
                      final spriteWidth = (constraints.maxWidth +
                              playerInset -
                              minGap)
                          .clamp(120.0, 210.0);
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              adventure.backgroundAsset,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.none,
                            ),
                          ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.08),
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.18),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: -playerInset,
                            // Oyuncu ve düşman aynı 100x100 GIF tuvalini
                            // kullanıyor; aynı sahne ölçeği ikisini de platforma
                            // oturtur. Yürüyüşü GIF yapar, ek sağ-sol sallanma yoktur.
                            bottom: -22,
                            width: spriteWidth,
                            height: 230,
                            child: PixelSprite(
                              asset: widget.avatar.characterAsset,
                              scale: 3,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            // Düşman GIF karelerinde altta geniş şeffaf boşluk var;
                            // kutuyu platformun altına taşıyarak görünen ayağı yüzeye oturt.
                            bottom: -22,
                            width: spriteWidth,
                            height: 230,
                            child: PixelSprite(
                              asset:
                                  _showDeath
                                      ? adventure.enemy.deathAsset
                                      : _showAttack
                                      ? adventure.enemy.attackAsset
                                      : _showHurt
                                      ? adventure.enemy.hurtAsset
                                      : adventure.enemy.walkAsset,
                              scale: 3,
                              offset: const Offset(-8, 0),
                              imageKey: ValueKey(
                                _showDeath
                                    ? 'death'
                                    : _showAttack
                                    ? 'attack-${widget.roundSerial}'
                                    : _showHurt
                                    ? 'hurt'
                                    : 'walk',
                              ),
                            ),
                          ),
                          // Hasar mesajı sahnenin **üstünde** durmalı, sahneyi
                          // kaplamamalı. Eskiden `titleLarge` ve satır sınırı
                          // yoktu: 320 dp'de altı satıra çıkıp hem oyuncuyu hem
                          // düşmanı örtüyordu (ölçülen 168 px / 260 px sahne).
                          // Artık daha küçük punto, iki satır sınırı ve okunur
                          // kalması için koyu bir şerit var.
                          if (_pendingDamage > 0)
                            Positioned(
                              left: 8,
                              right: 8,
                              top: 6,
                              child: FadeTransition(
                                opacity: _damageMessageOpacity,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    child: Text(
                                      'Düşmanın $_pendingDamage canını aldın!',
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall?.copyWith(
                                        color: AppColors.xp,
                                        fontWeight: FontWeight.w900,
                                        shadows: const [
                                          Shadow(
                                            color: Colors.black,
                                            blurRadius: 6,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
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
                                      Shadow(
                                        color: Colors.black,
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
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
              // Bu bar **günlük** sayacı gösterir, macerayı değil: macera
              // ilerlemesi geri sayım kartındaki ana barda. Eskiden etiketi
              // `adventure.stepGoal` diyordu ama değeri günlük ilerlemeydi;
              // macera başlamadan önce atılan adımlar yüzünden hemen üstteki
              // "Canavar Canı" barıyla çelişiyordu.
              StatBar(
                label: 'Günlük Adım',
                icon: Icons.calendar_today,
                color: AppColors.primary,
                progress: widget.today.stepProgress,
                valueText:
                    '${widget.today.steps} / ${widget.today.stepGoal} adım',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.xp),
                  const SizedBox(width: 8),
                  // Esnek: dar ekranda satır taşmasın, yazı sarsın.
                  Expanded(
                    child: Text('Zafer ödülü: ${adventure.enemy.xpReward} XP'),
                  ),
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
    final remaining = adventure.countdownRemaining(GameClock.now());
    final roundSteps = adventure.stepsThisRound(widget.today.steps);
    // Macera başladığından beri atılan adım. `today.steps` kullanılamaz:
    // macera başlamadan önce atılmış adımları da içerir (bkz. `startingSteps`).
    final questSteps = adventure.questSteps(widget.today.steps);
    final minutes = remaining.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = remaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final countdownCard = SectionCard(
      title: '${adventure.currentRound}. Round • Düşman saldırısına kalan süre',
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
          const SizedBox(height: 10),
          // ANA BAR: macera ilerlemesi. Round başına **sıfırlanmaz**; oyuncu
          // tek bakışta maceranın neresinde olduğunu görmeli. Eskiden burada
          // round içi ilerleme vardı ve her round sıfırlandığı için oyuncu
          // kazandığı yolu kaybetmiş gibi hissediyordu.
          LinearProgressIndicator(
            key: const ValueKey('quest-progress-bar'),
            value:
                adventure.stepGoal == 0
                    ? 1
                    : (questSteps / adventure.stepGoal).clamp(0, 1),
            minHeight: 10,
            borderRadius: BorderRadius.circular(8),
            color: AppColors.primary,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.directions_walk,
                size: 15,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$questSteps / ${adventure.stepGoal} adım — macera ilerlemesi',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // İKİNCİL: round içi ilerleme. Bilgi kaybolmuyor ama ana gösterge
          // değil — ince çizgi ve küçük yazı.
          LinearProgressIndicator(
            key: const ValueKey('round-progress-bar'),
            value:
                adventure.roundTargetSteps == 0
                    ? 1
                    : (roundSteps / adventure.roundTargetSteps).clamp(0, 1),
            minHeight: 3,
            borderRadius: BorderRadius.circular(3),
            color: AppColors.streak,
            backgroundColor: Colors.white12,
          ),
          const SizedBox(height: 5),
          Text(
            'Bu round: $roundSteps / ${adventure.roundTargetSteps} adım',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            'Her round için ${adventure.roundTargetSteps} adım ve '
            '${adventure.roundDurationLabel} süren var. '
            'Hedef eksik kalırsa '
            '${adventure.enemy.name}, eksik oranına göre en fazla '
            '${adventure.enemy.attackDamage} can vurur.',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );

    return AnimatedBuilder(
      animation: _roundTransitionController,
      child: Stack(
        children: [
          countdownCard,
          if (_showRoundTransition)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.93),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.85),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 26,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bolt,
                            color: AppColors.streak,
                            size: 38,
                            shadows: [
                              Shadow(color: AppColors.streak, blurRadius: 22),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '$_transitionRound. ROUND',
                            textAlign: TextAlign.center,
                            style: Theme.of(
                              context,
                            ).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.4,
                              shadows: const [
                                Shadow(
                                  color: AppColors.primary,
                                  blurRadius: 22,
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            'BAŞLADI',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      builder: (context, child) {
        if (!_showRoundTransition) return child!;
        final progress = _roundTransitionController.value;
        final entrance = Curves.easeOutBack.transform(
          (progress / 0.28).clamp(0, 1),
        );
        final exitOpacity =
            progress < 0.82
                ? 1.0
                : (1.0 - ((progress - 0.82) / 0.18)).clamp(0.0, 1.0);
        return Opacity(
          opacity: exitOpacity,
          child: Transform.translate(
            offset: Offset(_roundTransitionShake.value, 0),
            child: Transform.scale(scale: 0.88 + entrance * 0.12, child: child),
          ),
        );
      },
    );
  }
}

String _formatNumber(int value) {
  final digits = value.toString();
  final output = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) output.write('.');
    output.write(digits[index]);
  }
  return output.toString();
}

class _GoalSelectorButton extends StatelessWidget {
  final int goal;
  final VoidCallback onTap;

  const _GoalSelectorButton({required this.goal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          height: 210,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.24),
                AppColors.surface,
                AppColors.primary.withValues(alpha: 0.1),
              ],
            ),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.9),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.28),
                blurRadius: 28,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -22,
                top: -28,
                child: Icon(
                  Icons.gps_fixed,
                  size: 170,
                  color: AppColors.primary.withValues(alpha: 0.08),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.gps_fixed,
                      size: 54,
                      color: AppColors.primary,
                      shadows: [
                        Shadow(color: AppColors.primary, blurRadius: 24),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'HEDEF SEÇ',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_formatNumber(goal)} adım',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        shadows: const [
                          Shadow(color: AppColors.primary, blurRadius: 18),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Değiştirmek için dokun',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnemyPreviewDialog extends StatefulWidget {
  final Enemy enemy;
  final int selectedGoal;

  const _EnemyPreviewDialog({required this.enemy, required this.selectedGoal});

  @override
  State<_EnemyPreviewDialog> createState() => _EnemyPreviewDialogState();
}

class _EnemyPreviewDialogState extends State<_EnemyPreviewDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shake;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..repeat();
    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -2.5), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -2.5, end: 2.5), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 2.5, end: -1.5), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -1.5, end: 1.5), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enemy = widget.enemy;
    return Material(
      color: Colors.black.withValues(alpha: 0.94),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context, false),
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Geri',
                  ),
                  const Spacer(),
                  const Text(
                    'DÜŞMAN KARŞILAŞMASI',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.1,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                child: Column(
                  children: [
                    SizedBox(
                      height: 290,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.accent.withValues(alpha: 0.22),
                                  AppColors.primary.withValues(alpha: 0.08),
                                  Colors.transparent,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.16,
                                  ),
                                  blurRadius: 46,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _shake,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(_shake.value, 0),
                                child: child,
                              );
                            },
                            child: SizedBox(
                              width: 240,
                              height: 270,
                              child: PixelSprite(
                                asset: enemy.attackAsset,
                                scale: 3,
                                offset: const Offset(-8, 0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      enemy.name,
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        shadows: const [
                          Shadow(color: AppColors.accent, blurRadius: 18),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _EnemyInfoChip(
                          icon: Icons.directions_walk,
                          label: '${_formatNumber(widget.selectedGoal)} adım',
                          color: AppColors.primary,
                        ),
                        _EnemyInfoChip(
                          icon: Icons.auto_awesome,
                          label: '${_formatNumber(enemy.xpReward)} XP',
                          color: AppColors.xp,
                        ),
                        _EnemyInfoChip(
                          icon: Icons.flash_on,
                          label: '${enemy.attackDamage} hasar',
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DÜŞMAN HAKKINDA',
                            style: TextStyle(
                              color: AppColors.streak,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            enemy.questText,
                            style: const TextStyle(
                              color: Colors.white70,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Her round 1.000 adım ve '
                            '${AdventureQuest.configuredRoundDurationLabel}. Süreyi '
                            'kaçırırsan düşman eksik adım oranında saldırır.',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context, false),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Geri'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          Navigator.pop(context, true);
                        },
                        icon: const Icon(Icons.explore),
                        label: const Text('Maceraya Başla'),
                      ),
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
}

class _EnemyInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _EnemyInfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
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
                  child: PixelSprite(
                    asset: enemy.idleAsset,
                    scale: 3,
                    offset: const Offset(-8, 0),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.xp.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: AppColors.xp.withValues(alpha: 0.65),
                          ),
                        ),
                        child: Text(
                          '${_formatNumber(enemy.xpReward)} XP',
                          style: const TextStyle(
                            color: AppColors.xp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        unlocked
                            ? 'Bu hedef için uygun'
                            : '${_formatNumber(enemy.minimumDailySteps)} adımda açılır',
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
