import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/attack_config.dart';
import '../../core/constants/game_constants.dart';
import '../../core/localization/app_formatters.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/game_clock.dart';
import '../../l10n/l10n_context.dart';
import '../../l10n/content_localizations.dart';
import '../../core/utils/gif_timing.dart';
import '../../data/enemy_catalog.dart';
import '../../models/adventure_quest.dart';
import '../../models/avatar_profile.dart';
import '../../models/daily_progress.dart';
import '../../models/enemy.dart';
import '../../services/character_catalog.dart';
import '../../widgets/pixel_sprite.dart';
import '../../widgets/scroll_to_top_button.dart';
import '../../widgets/section_card.dart';
import '../../widgets/stat_bar.dart';
import '../tutorial/tutorial_guide.dart';

class AdventureScreen extends StatefulWidget {
  final AdventureQuest? adventure;
  final int roundSerial;
  final AvatarProfile avatar;
  final DailyProgress today;
  final ValueChanged<AdventureQuest> onAdventureSelected;
  final VoidCallback onStartRevival;
  final VoidCallback onChooseNewAdventure;
  final VoidCallback onAdventureUpdated;
  final bool tutorialMode;

  const AdventureScreen({
    super.key,
    required this.adventure,
    required this.roundSerial,
    required this.avatar,
    required this.today,
    required this.onAdventureSelected,
    required this.onStartRevival,
    required this.onChooseNewAdventure,
    required this.onAdventureUpdated,
    this.tutorialMode = false,
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
  final ScrollController _scrollController = ScrollController();
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
  bool _showEnemyDeath = false;
  bool _showFrozenEnemy = false;
  bool _showDeathCongratulations = false;
  double _overlayEnemyHealth = 1;
  int _displayedEnemyDamage = 0;
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
    _roundAttackController.stop();
    _roundTransitionController.stop();
    _damageMessageController.stop();
    _frozenDeathFrame?.dispose();
    _frozenDeathFrame = null;
    _pendingDamage = 0;
    _playerDamage = 0;
    _showHurt = false;
    _showAttack = false;
    _showDeath = false;
    _showCongratulations = false;
    _showRoundVictory = false;
    _showEnemyRoundVictory = false;
    _showRoundTransition = false;
    _showEnemyDeath = false;
    _showFrozenEnemy = false;
    _showDeathCongratulations = false;
    _victoryCycle = 0;
    _enemyVictoryCycle = 0;
    _overlayEnemyHealth = 1;
    _displayedEnemyDamage = 0;
    _roundPlayerAttackAsset = null;
    _roundEnemyAttackAsset = null;
    if (adventure == null) return;

    if (adventure.roundOutcomeSerial > adventure.presentedRoundOutcomeSerial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || widget.adventure != adventure) return;
        if (adventure.lastRoundWon) {
          _playRoundVictory(adventure);
        } else {
          _playEnemyRoundVictory(adventure);
        }
      });
      return;
    }

    _pendingDamage = adventure.takePendingDamage();
    if (adventure.isEnemyDefeated) {
      // Altın toplama tamamlandıktan sonra ilk zafer perdesi yeniden açılmaz.
      // Bu durumun düşmansız, yalnızca ek altını gösteren ayrı sonucu var.
      if (adventure.isGoldCollectionCompleted) return;
      // Zafer kutlaması **bir kez** oynar. Yürüyüş fazı açıldıysa ve kutlama
      // zaten gösterildiyse ekran doğrudan yürüyüş sahnesine düşer; aksi
      // hâlde oyuncu Macera sekmesine her dönüşünde aynı kutlamayla
      // karşılaşır ve yürüyüşe geçemezdi (Bölüm A.1).
      if (adventure.deathAnimationPlayed && adventure.isWalkPhaseActive) {
        return;
      }
      if (adventure.deathAnimationPlayed) {
        _showRoundVictory = true;
        _showEnemyDeath = true;
        _showDeathCongratulations = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _restoreVictoryCorpse(adventure);
        });
        return;
      }

      adventure.deathAnimationPlayed = true;
      _showRoundVictory = true;
      _showEnemyDeath = true;
      _showDeathCongratulations = true;
      _enemyAnimationTimer = Timer(
        Duration(milliseconds: adventure.enemy.deathAnimationDurationMs),
        () {
          if (!mounted) return;
          _restoreVictoryCorpse(adventure);
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

  Future<void> _restoreVictoryCorpse(AdventureQuest adventure) async {
    final frame = await _decodeLastGifFrame(adventure.enemy.deathAsset);
    if (!mounted || widget.adventure != adventure) {
      frame?.dispose();
      return;
    }
    _frozenDeathFrame?.dispose();
    _frozenDeathFrame = frame;
    setState(() {
      _showEnemyDeath = false;
      _showFrozenEnemy = frame != null;
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
    if (widget.adventure != adventure) return;
    _enemyAnimationTimer?.cancel();
    _roundAttackController.stop();
    final classes = await CharacterCatalog.load();
    if (!mounted || widget.adventure != adventure) return;
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
    if (!mounted || widget.adventure != adventure) return;
    _roundAttackController.duration = playerAttackDuration;

    final isFinalVictory = adventure.isEnemyDefeated;
    final maxEnemyHealth = max(1, adventure.scaledEnemyMaxHealth);
    final healthAfter = adventure.remainingEnemyHealth.clamp(0, maxEnemyHealth);
    final fallbackHealthBefore = (healthAfter + adventure.lastPlayerDamage)
        .clamp(0, maxEnemyHealth);
    final healthBefore =
        adventure.enemyHealthBeforeLastRound > 0
            ? adventure.enemyHealthBeforeLastRound.clamp(0, maxEnemyHealth)
            : fallbackHealthBefore;
    final healthBeforeProgress = healthBefore / maxEnemyHealth;
    final healthAfterProgress = healthAfter / maxEnemyHealth;
    final displayedDamage = (healthBefore - healthAfter).clamp(
      0,
      maxEnemyHealth,
    );
    setState(() {
      _showRoundVictory = true;
      _showEnemyRoundVictory = false;
      _victoryRound = adventure.lastResolvedRound;
      _victoryCycle = 1;
      _showEnemyDeath = false;
      _showFrozenEnemy = false;
      _showDeathCongratulations = false;
      _overlayEnemyHealth = healthBeforeProgress;
      _displayedEnemyDamage = displayedDamage;
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
        if (mounted) {
          setState(() {
            _overlayEnemyHealth =
                ui.lerpDouble(
                  healthBeforeProgress,
                  healthAfterProgress,
                  cycle / 2,
                )!;
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
        final pixels = await frame.image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        var visiblePixels = 0;
        if (pixels != null) {
          for (var offset = 3; offset < pixels.lengthInBytes; offset += 4) {
            if (pixels.getUint8(offset) > 8 && ++visiblePixels >= 12) break;
          }
        }
        if (visiblePixels >= 12) {
          lastFrame?.dispose();
          lastFrame = frame.image;
        } else {
          frame.image.dispose();
        }
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
    _scrollController.dispose();
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
                        context.l10n.chooseDailyGoal,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
                      Text(
                        context.l10n.goalPickerHint,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
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
                                          fontSize: selected ? 39 : 25,
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
                                          context.l10n.stepsLabel(
                                            AppFormatters.integer(
                                              context,
                                              goal,
                                            ),
                                          ),
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
                          label: Text(
                            context.l10n.selectStepGoal(
                              AppFormatters.integer(context, draftGoal),
                            ),
                          ),
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
            : adventure.isPlayerDefeated && adventure.revivalCompleted
            ? _buildRevivalCompleted(context, adventure)
            : adventure.isPlayerDefeated && adventure.isRevivalActive
            ? _buildRevivalWalk(context, adventure)
            : adventure.isPlayerDefeated
            ? _buildPlayerDefeat(context, adventure)
            : adventure.isGoldCollectionCompleted
            ? _buildGoldCollectionCompleted(context, adventure)
            : adventure.isEnemyDefeated && _showCongratulations
            ? _buildCongratulations(context, adventure)
            : _buildAdventure(context, adventure);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.adventure)),
      floatingActionButton: ScrollToTopButton(controller: _scrollController),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Stack(
        children: [
          Positioned.fill(child: content),
          if (_showRoundVictory &&
              adventure != null &&
              !adventure.isGoldCollectionCompleted)
            Positioned.fill(child: _buildRoundVictoryOverlay(adventure)),
          if (_showEnemyRoundVictory && adventure != null)
            Positioned.fill(child: _buildEnemyRoundVictoryOverlay(adventure)),
        ],
      ),
    );
  }

  Widget _buildRoundVictoryOverlay(AdventureQuest adventure) {
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
          child: ColoredBox(color: Colors.black.withValues(alpha: 0.68)),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                Text(
                  context.l10n.roundNumberUpper(_victoryRound),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _showDeathCongratulations
                      ? context.l10n.victoryUpper
                      : context.l10n.roundYoursUpper,
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
                      ? context.l10n.enemyDefeatedNamed(
                        context.l10n.enemyName(adventure.enemy),
                      )
                      : context.l10n.roundCompletedEarly,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white60),
                ),
                if (_showDeathCongratulations) ...[
                  const SizedBox(height: 12),
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 700),
                    tween: Tween(begin: 0.72, end: 1),
                    curve: Curves.elasticOut,
                    builder:
                        (context, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                    child: Column(
                      children: [
                        Text(
                          context.l10n.wheelCoinsLabel(
                            adventure.victoryCoinReward,
                          ),
                          key: const ValueKey('victory-coin-reward'),
                          style: const TextStyle(
                            color: AppColors.streak,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 8),
                              Shadow(color: AppColors.streak, blurRadius: 24),
                            ],
                          ),
                        ),
                        Text(
                          '+${adventure.victoryXpReward} XP',
                          key: const ValueKey('victory-xp-reward'),
                          style: const TextStyle(
                            color: AppColors.xp,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 8),
                              Shadow(color: AppColors.xp, blurRadius: 22),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Hız ödülü (Bölüm A.2): oyuncu neyi neden kazandığını
                  // görmeli, yoksa çarpan görünmez bir kural olur.
                  if (adventure.speedRewardMultiplier > 1.001) ...[
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.speedRewardSummary(
                        adventure.victoryRounds,
                        AppFormatters.integer(context, adventure.victorySteps),
                        adventure.speedRewardMultiplier.toStringAsFixed(2),
                      ),
                      key: const ValueKey('victory-speed-bonus'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.xp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                  if (adventure.isWalkPhaseActive) ...[
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.walkPhaseRemainingNotice(
                        AppFormatters.integer(
                          context,
                          adventure.walkRemainingSteps,
                        ),
                        GameConstants.walkPhaseStepsPerCoin,
                      ),
                      key: const ValueKey('victory-walk-phase-note'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ],
                if (_displayedEnemyDamage > 0) ...[
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
                        context.l10n
                            .healthValue(
                              AppFormatters.integer(
                                context,
                                (_overlayEnemyHealth *
                                        adventure.scaledEnemyMaxHealth)
                                    .round(),
                              ),
                            )
                            .toUpperCase(),
                        key: const ValueKey('animated-enemy-health-value'),
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
                                            key: const ValueKey(
                                              'victory-enemy-corpse',
                                            ),
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
                                                  ? 'victory-enemy-corpse'
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
                          // Altınlar düşmanın **önünde** çizilmeli: ganimet
                          // cesedin üstüne düşer, altına değil. `Stack`
                          // çocukları sırayla boyandığı için bu blok düşman
                          // sprite'ından **sonra** gelmek zorunda; eskiden
                          // önce geliyordu ve ceset altınları örtüyordu.
                          if (_showDeathCongratulations) ..._coinScatter(),
                          if (!_showEnemyDeath &&
                              !_showFrozenEnemy &&
                              attack > 0.38 &&
                              attack < 0.9)
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 62,
                              child: Text(
                                context.l10n.hitUpper,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
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
                          if (!_showEnemyDeath &&
                              !_showFrozenEnemy &&
                              _displayedEnemyDamage > 0)
                            Positioned(
                              right: 14,
                              top: 96,
                              child: Opacity(
                                opacity: (1 - (attack - 0.62).abs() / 0.62)
                                    .clamp(0.0, 1.0),
                                child: Transform.scale(
                                  scale: 0.88 + attack * 0.2,
                                  child: Text(
                                    context.l10n.healthDamageUpper(
                                      _displayedEnemyDamage,
                                    ),
                                    key: const ValueKey(
                                      'animated-enemy-damage',
                                    ),
                                    style: const TextStyle(
                                      color: AppColors.hp,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black,
                                          blurRadius: 8,
                                        ),
                                        Shadow(
                                          color: AppColors.hp,
                                          blurRadius: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                const Spacer(),
                if (_showDeathCongratulations)
                  SizedBox(
                    width: double.infinity,
                    child:
                        adventure.isWalkPhaseActive
                            // Düşman devrildi ama macera bitmedi: adım
                            // taahhüdü sürüyor (Bölüm A.1). Buton oyuncuyu
                            // yeni macera seçmeye değil, bonuslu yürüyüşe
                            // yönlendirir.
                            ? FilledButton.icon(
                              key: const ValueKey('victory-continue-walk'),
                              onPressed:
                                  () =>
                                      setState(() => _showRoundVictory = false),
                              icon: const Icon(Icons.directions_walk),
                              label: Text(context.l10n.continueWalkingUpper),
                            )
                            : FilledButton.icon(
                              key: const ValueKey('victory-choose-adventure'),
                              onPressed: widget.onChooseNewAdventure,
                              icon: const Icon(Icons.explore),
                              label: Text(context.l10n.chooseNewAdventureUpper),
                            ),
                  )
                else ...[
                  Text(
                    _showEnemyDeath
                        ? context.l10n.finalBlow
                        : context.l10n.attackSequence(_victoryCycle, 2),
                    style: const TextStyle(
                      color: Colors.white38,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  LinearProgressIndicator(
                    value: _showEnemyDeath ? 0.92 : _victoryCycle / 2,
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(99),
                    backgroundColor: Colors.white10,
                  ),
                ],
                const Spacer(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _coinScatter() => const [
    _ScatteredCoin(left: 156, top: 150, size: 34, angle: -0.25),
    _ScatteredCoin(left: 202, top: 174, size: 26, angle: 0.18),
    _ScatteredCoin(right: 8, top: 128, size: 38, angle: 0.3),
    _ScatteredCoin(right: 52, top: 202, size: 29, angle: -0.12),
    _ScatteredCoin(right: 98, top: 214, size: 23, angle: 0.42),
  ];

  Widget _buildEnemyRoundVictoryOverlay(AdventureQuest adventure) {
    final healthProgress = adventure.playerHealthProgress;
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.9),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Text(
                context.l10n.roundNumberUpper(_victoryRound),
                style: const TextStyle(
                  color: AppColors.hp,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.enemyRoundUpper,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  shadows: const [Shadow(color: AppColors.hp, blurRadius: 28)],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                context.l10n.enemyAttackedAfterTimeout(
                  context.l10n.enemyName(adventure.enemy),
                ),
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
                    context.l10n
                        .healthValue(
                          AppFormatters.integer(
                            context,
                            adventure.playerHealth,
                          ),
                        )
                        .toUpperCase(),
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
                          child: Transform.flip(
                            flipX: true,
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
                              context.l10n.healthDamageUpper(
                                adventure.lastEnemyDamage,
                              ),
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
                context.l10n.enemyAttackingCycle(
                  context.l10n.enemyName(adventure.enemy),
                  _enemyVictoryCycle,
                  2,
                ),
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
        key: const ValueKey('adventure-scroll-view'),
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 88),
        child: SectionCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.heart_broken, color: AppColors.hp, size: 76),
              const SizedBox(height: 16),
              Text(
                context.l10n.restTime,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.revivalIntro(
                  context.l10n.enemyName(adventure.enemy),
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.revivalNoXp,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.streak, fontSize: 12),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('start-revival-walk'),
                  onPressed: widget.onStartRevival,
                  icon: const Icon(Icons.directions_walk),
                  label: Text(context.l10n.startLifeWalk),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevivalWalk(BuildContext context, AdventureQuest adventure) {
    return Center(
      child: SingleChildScrollView(
        key: const ValueKey('adventure-scroll-view'),
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 88),
        child: SectionCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.directions_walk,
                color: AppColors.streak,
                size: 76,
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.lifeWalk,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.lifeWalkDescription,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                key: const ValueKey('revival-progress-bar'),
                value: adventure.revivalProgress,
                minHeight: 12,
                borderRadius: BorderRadius.circular(8),
                color: AppColors.streak,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.dailyStepProgressValue(
                  AppFormatters.integer(context, adventure.revivalSteps),
                  AppFormatters.integer(
                    context,
                    AdventureQuest.revivalStepTarget,
                  ),
                ),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.stepsRemaining(adventure.revivalRemainingSteps),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevivalCompleted(
    BuildContext context,
    AdventureQuest adventure,
  ) {
    return Center(
      child: SingleChildScrollView(
        key: const ValueKey('adventure-scroll-view'),
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 88),
        child: SectionCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite, color: AppColors.hp, size: 82),
              const SizedBox(height: 16),
              Text(
                context.l10n.revived,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.streak,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.revivalCompleted,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('acknowledge-revival'),
                  onPressed: widget.onChooseNewAdventure,
                  icon: const Icon(Icons.explore),
                  label: Text(context.l10n.backToAdventures),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoldCollectionCompleted(
    BuildContext context,
    AdventureQuest adventure,
  ) {
    return Stack(
      key: const ValueKey('gold-collection-completed'),
      children: [
        Positioned.fill(
          child: Image.asset(
            adventure.backgroundAsset,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.none,
          ),
        ),
        Positioned.fill(
          child: ColoredBox(color: Colors.black.withValues(alpha: 0.74)),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 88),
            child: Column(
              children: [
                const Spacer(),
                Image.asset(
                  'lib/All_Assets/coins/coin_gold_large_shine.gif',
                  key: const ValueKey('gold-collection-large-coin'),
                  width: 210,
                  height: 210,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                ),
                const SizedBox(height: 20),
                Text(
                  context.l10n.extraGold(adventure.walkCoinReward),
                  key: const ValueKey('gold-collection-earned-coins'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.streak,
                    fontWeight: FontWeight.w900,
                    shadows: const [
                      Shadow(color: Colors.black, blurRadius: 10),
                      Shadow(color: AppColors.streak, blurRadius: 28),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const ValueKey('gold-collection-choose-adventure'),
                    onPressed: widget.onChooseNewAdventure,
                    icon: const Icon(Icons.explore),
                    label: Text(context.l10n.chooseNewAdventureUpper),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCongratulations(BuildContext context, AdventureQuest adventure) {
    return Center(
      child: SingleChildScrollView(
        key: const ValueKey('adventure-scroll-view'),
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 88),
        child: SectionCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'lib/All_Assets/coins/coin_gold_large_shine.gif',
                key: const ValueKey('final-victory-gold-coin'),
                width: 64,
                height: 64,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
              ),
              const SizedBox(height: 8),
              const Icon(Icons.emoji_events, color: AppColors.xp, size: 82),
              const SizedBox(height: 16),
              Text(
                context.l10n.congratulations,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.xp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.enemyDefeatedNamed(
                  context.l10n.enemyName(adventure.enemy),
                ),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.xpWonNextAdventure(adventure.enemy.xpReward),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: widget.onChooseNewAdventure,
                  icon: const Icon(Icons.explore),
                  label: Text(context.l10n.chooseNewAdventure),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelection(BuildContext context) {
    final visibleEnemies =
        widget.tutorialMode
            ? EnemyCatalog.enemies.take(1)
            : EnemyCatalog.enemies;
    return ListView(
      key: const ValueKey('adventure-scroll-view'),
      controller: _scrollController,
      physics:
          widget.tutorialMode ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      children: [
        Text(
          context.l10n.chooseTodaysAdventure,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.adventureSelectionDescription,
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 16),
        _GoalSelectorButton(goal: _stepGoal, onTap: _showGoalPicker),
        const SizedBox(height: 16),
        Text(
          context.l10n.chooseEnemy,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...visibleEnemies.map((enemy) {
          final unlocked = _stepGoal >= enemy.minimumDailySteps;
          final selected = _selectedEnemy?.id == enemy.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _EnemyChoiceCard(
              key:
                  widget.tutorialMode && enemy == EnemyCatalog.enemies.first
                      ? TutorialGuideTargetKeys.enemy
                      : null,
              enemy: enemy,
              unlocked: unlocked,
              selected: selected,
              onTap:
                  unlocked
                      ? () {
                        if (widget.tutorialMode &&
                            enemy == EnemyCatalog.enemies.first) {
                          setState(() => _selectedEnemy = enemy);
                          _startAdventure();
                        } else {
                          _showEnemyPreview(enemy);
                        }
                      }
                      : null,
            ),
          );
        }),
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 16),
          child: Text(
            context.l10n.tapEnemyForDetails,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ),
      ],
    );
  }

  /// Yürüyüş fazı ekranı (Bölüm A.1/A.3/A.4).
  ///
  /// Savaş sahnesinden **net biçimde ayrışır**: düşman yok, oyuncu sahneyi
  /// baştan sona yürüyor, kart savaş yerine kalan taahhüdü ve bonuslu oranı
  /// anlatıyor. Sahne, savaştaki 260 px'lik kutuyu ve aynı ölçeği kullanır ki
  /// iki faz arasında geçiş sıçramasın.
  Widget _buildWalkPhase(BuildContext context, AdventureQuest adventure) {
    return ListView(
      key: const ValueKey('adventure-scroll-view'),
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      children: [
        SectionCard(
          child: Column(
            children: [
              SizedBox(
                height: 260,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _WalkPhaseScene(
                    key: const ValueKey('walk-phase-scene'),
                    backgroundAsset: adventure.backgroundAsset,
                    walkAsset: widget.avatar.characterAsset,
                    earnedCoins: adventure.walkCoinReward,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.victoryIsYours,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.enemyFelledRoadYours(
                  context.l10n.enemyName(adventure.enemy),
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: context.l10n.adventurePhaseName(AdventureQuestPhase.walk),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.monetization_on,
                    color: AppColors.streak,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.walkPhaseRate(
                        GameConstants.walkPhaseStepsPerCoin,
                      ),
                      key: const ValueKey('walk-phase-rate'),
                      style: const TextStyle(
                        color: AppColors.streak,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                key: const ValueKey('walk-phase-progress-bar'),
                value: adventure.walkProgress,
                minHeight: 10,
                borderRadius: BorderRadius.circular(8),
                color: AppColors.streak,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.directions_walk,
                    size: 15,
                    color: AppColors.streak,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      context.l10n.walkProgressRemaining(
                        AppFormatters.integer(context, adventure.walkSteps),
                        AppFormatters.integer(
                          context,
                          adventure.walkTargetSteps,
                        ),
                        AppFormatters.integer(
                          context,
                          adventure.walkRemainingSteps,
                        ),
                      ),
                      key: const ValueKey('walk-phase-remaining'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.walkPhaseExplanation(
                  GameConstants.stepsPerCoin,
                  GameConstants.walkPhaseStepsPerCoin,
                ),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: context.l10n.victorySummary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt, color: AppColors.xp, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.speedRewardSummary(
                        adventure.victoryRounds,
                        AppFormatters.integer(context, adventure.victorySteps),
                        AppFormatters.decimal(
                          context,
                          adventure.speedRewardMultiplier,
                          digits: 2,
                        ),
                      ),
                      key: const ValueKey('walk-phase-speed-bonus'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.monetization_on,
                    color: AppColors.streak,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.walkRewardBreakdown(
                        AppFormatters.integer(
                          context,
                          adventure.victoryCoinReward,
                        ),
                        AppFormatters.integer(
                          context,
                          adventure.walkCoinReward,
                        ),
                        AppFormatters.integer(
                          context,
                          adventure.totalCoinReward,
                        ),
                        AppFormatters.integer(
                          context,
                          adventure.victoryXpReward,
                        ),
                      ),
                      key: const ValueKey('walk-phase-reward-total'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: AppColors.streak,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(context.l10n.streakAndWheelSecured)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const ValueKey('walk-phase-abandon'),
            onPressed: widget.onChooseNewAdventure,
            icon: const Icon(Icons.explore),
            label: Text(context.l10n.abandonWalkUpper),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.abandonWalkWarning,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildAdventure(BuildContext context, AdventureQuest adventure) {
    // Yürüyüş fazı savaş ekranını paylaşmaz (Bölüm A.4): düşman sahneden
    // çıkar, oyuncu yürür, kart bonuslu oranı gösterir. İki fazın görsel
    // olarak karışmaması şartın kendisi.
    if (adventure.isWalkPhaseActive) {
      return _buildWalkPhase(context, adventure);
    }
    final defeated = adventure.isEnemyDefeated;
    final remaining = adventure.remainingEnemyHealth;
    return ListView(
      key: const ValueKey('adventure-scroll-view'),
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
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
                                      context.l10n.damageDealt(_pendingDamage),
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
                                  context.l10n.healthDamageUpper(_playerDamage),
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
                context.l10n.enemyName(adventure.enemy),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                defeated ? context.l10n.defeated : context.l10n.waitingForYou,
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
          title:
              defeated
                  ? context.l10n.victoryIsYours
                  : context.l10n.missionMessage,
          child: Text(
            defeated
                ? context.l10n.victoryMissionMessage(
                  context.l10n.enemyName(adventure.enemy),
                  adventure.enemy.xpReward,
                )
                : context.l10n.enemyQuest(adventure.enemy),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: context.l10n.adventureStatus,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatBar(
                label: context.l10n.monsterHealth,
                icon: Icons.favorite,
                color: AppColors.hp,
                progress: adventure.enemyHealthProgress,
                valueText: '$remaining / ${adventure.scaledEnemyMaxHealth}',
              ),
              const SizedBox(height: 14),
              StatBar(
                label: context.l10n.yourHealth,
                icon: Icons.shield,
                color: AppColors.xp,
                progress: adventure.playerHealthProgress,
                valueText:
                    '${adventure.playerHealth} / ${adventure.playerMaxHealth}',
              ),
              const SizedBox(height: 14),
              // Bu bar **günlük** sayacı gösterir, macerayı değil: macera
              // ilerlemesi geri sayım kartındaki ana barda. Eskiden etiketi
              // `adventure.stepGoal` diyordu ama değeri günlük ilerlemeydi;
              // macera başlamadan önce atılan adımlar yüzünden hemen üstteki
              // "Canavar Canı" barıyla çelişiyordu.
              StatBar(
                label: context.l10n.dailySteps,
                icon: Icons.calendar_today,
                color: AppColors.primary,
                progress: widget.today.stepProgress,
                valueText: context.l10n.dailyStepProgressValue(
                  AppFormatters.integer(context, widget.today.steps),
                  AppFormatters.integer(context, widget.today.stepGoal),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.xp),
                  const SizedBox(width: 8),
                  // Esnek: dar ekranda satır taşmasın, yazı sarsın.
                  Expanded(
                    child: Text(
                      context.l10n.victoryRewardXp(adventure.enemy.xpReward),
                    ),
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
            label: Text(context.l10n.chooseNewAdventure),
          ),
        ] else ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              key: const ValueKey('adventure-exit'),
              onPressed: widget.onChooseNewAdventure,
              icon: const Icon(Icons.logout),
              label: Text(context.l10n.leaveAdventure),
            ),
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
      title: context.l10n.roundProgress(
        adventure.currentRound,
        adventure.totalRounds,
      ),
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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 420),
            transitionBuilder:
                (child, animation) => ScaleTransition(
                  scale: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                  ),
                  child: FadeTransition(opacity: animation, child: child),
                ),
            child: Container(
              key: ValueKey(adventure.perfectRoundStreak),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.streak.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.streak.withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    size: 18,
                    color: AppColors.streak,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      adventure.perfectRoundStreak == 0
                          ? context.l10n.perfectStreakNextCap(
                            AppFormatters.decimal(
                              context,
                              adventure.nextPerfectStreakCap,
                            ),
                          )
                          : context.l10n.perfectStreakCap(
                            adventure.perfectRoundStreak,
                            AppFormatters.decimal(
                              context,
                              adventure.perfectStreakCap,
                              digits: 2,
                            ),
                          ),
                      style: const TextStyle(
                        color: AppColors.streak,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
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
                  context.l10n.adventureProgressValue(
                    AppFormatters.integer(context, questSteps),
                    AppFormatters.integer(context, adventure.stepGoal),
                  ),
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
            context.l10n.thisRoundSteps(
              AppFormatters.integer(context, roundSteps),
              AppFormatters.integer(context, adventure.roundTargetSteps),
            ),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.roundRules(
              AppFormatters.integer(context, adventure.roundTargetSteps),
              context.l10n.adventureDuration(adventure.currentRoundDuration),
              context.l10n.enemyName(adventure.enemy),
            ),
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
                          Icon(
                            widget.adventure?.lastPerfectStreakBroken == true
                                ? Icons.heart_broken
                                : widget.adventure?.lastRoundPerfect == true
                                ? Icons.local_fire_department
                                : Icons.bolt,
                            color: AppColors.streak,
                            size: 38,
                            shadows: const [
                              Shadow(color: AppColors.streak, blurRadius: 22),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            context.l10n.roundNumberUpper(_transitionRound),
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
                          Text(
                            widget.adventure?.lastPerfectStreakBroken == true
                                ? context.l10n.streakBrokenUpper
                                : widget.adventure?.lastRoundPerfect == true
                                ? context.l10n.perfectStreakUpper(
                                  widget.adventure!.perfectRoundStreak,
                                )
                                : context.l10n.newRoundStartedUpper,
                            style: const TextStyle(
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

/// Yürüyüş fazının sahnesi (Bölüm A.4).
///
/// Savaş sahnesinden ayrıştıran üç şey: düşman yok, karakter sahnede
/// **yürüyor** ve üstte fazı söyleyen bir şerit var.
///
/// Karakter sahneden çıkmaz: uçtan uca gidip geri dönüyor ve dönüşte yatay
/// olarak aynalanıyor. Tek yönlü sonsuz bir geçiş "yol" duygusu verirdi ama
/// karakteri zamanın yarısında ekran dışında bırakırdı — kullanıcı yürüyüş
/// fazına baktığında birini yürürken görmeli.
///
/// Performans: tek bir [AnimationController] var ve yalnızca bir
/// [Transform.translate] sürüyor — yeniden çizilen alt ağaç `child` olarak
/// dışarıda tutuluyor, yani her karede yeniden **inşa** edilmiyor. Yürüyüşün
/// kendisi zaten GIF; ek bir kare üretimi yok.
class _WalkPhaseScene extends StatefulWidget {
  final String backgroundAsset;
  final String walkAsset;
  final int earnedCoins;

  const _WalkPhaseScene({
    super.key,
    required this.backgroundAsset,
    required this.walkAsset,
    required this.earnedCoins,
  });

  @override
  State<_WalkPhaseScene> createState() => _WalkPhaseSceneState();
}

class _WalkPhaseSceneState extends State<_WalkPhaseScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _travel = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _travel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spriteWidth = 180.0;
        const edgeInset = 6.0;
        // Sprite tuvalinin iki yanında şeffaf boşluk var; kutuyu tamamen
        // içeride tutmak yerine biraz taşırmak figürü kenara yaslamıyor.
        final travelSpan = (constraints.maxWidth - spriteWidth + 40).clamp(
          0.0,
          400.0,
        );
        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                widget.backgroundAsset,
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
            AnimatedBuilder(
              animation: _travel,
              // `child` sabit: her karede yeniden inşa edilmez, yalnızca
              // taşınır. 60 FPS'i düşüren şey animasyon değil, her karede
              // yeniden kurulan alt ağaç olurdu.
              child: SizedBox(
                width: spriteWidth,
                height: 230,
                child: PixelSprite(asset: widget.walkAsset, scale: 3),
              ),
              builder: (context, child) {
                final headingBack = _travel.status == AnimationStatus.reverse;
                return Positioned(
                  left: edgeInset - 20 + travelSpan * _travel.value,
                  bottom: -22,
                  child: Transform.flip(flipX: headingBack, child: child),
                );
              },
            ),
            Positioned(
              left: 8,
              right: 8,
              top: 6,
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
                    context.l10n.walkingPhaseUpper,
                    key: const ValueKey('walk-phase-banner'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.streak,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6,
                      shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        size: 18,
                        color: AppColors.streak,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        context.l10n.extraGold(widget.earnedCoins),
                        key: const ValueKey('walk-phase-earned-coins'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScatteredCoin extends StatelessWidget {
  final double? left;
  final double? right;
  final double top;
  final double size;
  final double angle;

  const _ScatteredCoin({
    this.left,
    this.right,
    required this.top,
    required this.size,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) => Positioned(
    left: left,
    right: right,
    top: top,
    child: Transform.rotate(
      angle: angle,
      child: Image.asset(
        'lib/All_Assets/coins/coin_gold_medium_shine.gif',
        key: const ValueKey('victory-scattered-coin'),
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        errorBuilder:
            (context, error, stackTrace) => Icon(
              Icons.monetization_on,
              size: size,
              color: AppColors.streak,
            ),
      ),
    ),
  );
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
                    Text(
                      context.l10n.chooseGoalUpper,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      context.l10n.stepsLabel(
                        AppFormatters.integer(context, goal),
                      ),
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
                    Text(
                      context.l10n.roundGoalSummary(
                        AttackConfig.roundCountForSteps(goal),
                        AppFormatters.integer(
                          context,
                          GameConstants.combatRoundStepTarget,
                        ),
                        context.l10n.adventureDuration(
                          GameConstants.combatRoundDuration,
                        ),
                      ),
                      style: const TextStyle(
                        color: AppColors.streak,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.tapToChange,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
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
    final scaledStats = enemy.stats;
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
                    tooltip: context.l10n.back,
                  ),
                  const Spacer(),
                  Text(
                    context.l10n.enemyEncounterUpper,
                    style: const TextStyle(
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
                      context.l10n.enemyName(enemy),
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
                          label: context.l10n.stepsLabel(
                            AppFormatters.integer(context, widget.selectedGoal),
                          ),
                          color: AppColors.primary,
                        ),
                        _EnemyInfoChip(
                          icon: Icons.auto_awesome,
                          label:
                              '${AppFormatters.integer(context, enemy.xpReward)} XP',
                          color: AppColors.xp,
                        ),
                        _EnemyInfoChip(
                          icon: Icons.favorite,
                          label: context.l10n.healthValue(
                            AppFormatters.integer(
                              context,
                              scaledStats.maxHealth.round(),
                            ),
                          ),
                          color: AppColors.hp,
                        ),
                        _EnemyInfoChip(
                          icon: Icons.flash_on,
                          label: context.l10n.attackStat(
                            scaledStats.attack.round(),
                          ),
                          color: AppColors.accent,
                        ),
                        _EnemyInfoChip(
                          icon: Icons.timer_outlined,
                          label: context.l10n.totalDuration(
                            context.l10n.adventureDuration(
                              AttackConfig.durationForSteps(
                                widget.selectedGoal,
                              ),
                            ),
                          ),
                          color: AppColors.streak,
                        ),
                        _EnemyInfoChip(
                          icon: Icons.shield_moon,
                          label: context.l10n.defenseStat(
                            enemy.stats.defense.round(),
                          ),
                          color: AppColors.primary,
                        ),
                        _EnemyInfoChip(
                          icon: Icons.speed,
                          label: context.l10n.enemyArchetypeName(
                            enemy.archetype,
                          ),
                          color: AppColors.streak,
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
                          Text(
                            context.l10n.enemyAboutUpper,
                            style: const TextStyle(
                              color: AppColors.streak,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.l10n.enemyQuest(enemy),
                            style: const TextStyle(
                              color: Colors.white70,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Arketip savaşta gerçekten fark yaratıyor; oyuncu
                          // neyle karşılaştığını önceden bilmeli.
                          Text(
                            context.l10n.enemyArchetypeDetails(enemy.archetype),
                            style: const TextStyle(
                              color: AppColors.streak,
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            context.l10n.enemyCombatExplanation(
                              AttackConfig.roundCountForSteps(
                                widget.selectedGoal,
                              ),
                              GameConstants.combatRoundStepTarget,
                              context.l10n.adventureDuration(
                                GameConstants.combatRoundDuration,
                              ),
                            ),
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
                        label: Text(context.l10n.back),
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
                        label: Text(context.l10n.startAdventure),
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
    super.key,
    required this.enemy,
    required this.unlocked,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Opacity(
        opacity: unlocked ? 1 : 0.45,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
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
                        context.l10n.enemyName(enemy),
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
                          '${AppFormatters.integer(context, enemy.xpReward)} XP',
                          style: const TextStyle(
                            color: AppColors.xp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        unlocked
                            ? context.l10n.goalSuitable
                            : context.l10n.unlocksAtSteps(
                              AppFormatters.integer(
                                context,
                                enemy.minimumDailySteps,
                              ),
                            ),
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
