import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/game_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/game_clock.dart';
import '../../core/utils/game_day.dart';
import '../../l10n/l10n_context.dart';
import '../../l10n/content_localizations.dart';
import '../../models/adventure_quest.dart';
import '../../models/daily_progress.dart';
import '../../models/game_title.dart';
import '../../models/streak_stat_bonuses.dart';
import '../../models/tutorial_guide_variant.dart';
import '../../models/user_profile.dart';
import '../../services/step_permission_service.dart';
import '../../widgets/day_reset_countdown.dart';
import '../../widgets/section_card.dart';
import '../../widgets/title_badge.dart';
import '../../widgets/stat_bar.dart';
import '../../widgets/hero_progress_rings.dart';

String _formatRemaining(BuildContext context, Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  return hours > 0
      ? context.l10n.durationHoursMinutes(hours, minutes)
      : context.l10n.durationMinutes(minutes);
}

/// Ana panel: günün özeti (HP, seviye/XP, adım) ve diğer
/// bölümlere hızlı erişim.
class HomeScreen extends StatelessWidget {
  final UserProfile profile;

  /// Takılı ünvan (Bölüm C.2). `null` ise rozet hiç çizilmez.
  final GameTitle? equippedTitle;
  final DailyProgress today;
  final AdventureQuest? adventure;
  final VoidCallback onOpenAdventure;
  final VoidCallback onOpenWheel;
  final VoidCallback onOpenRewards;
  final VoidCallback onOpenStore;
  final VoidCallback onOpenInventory;
  final ValueChanged<int> onSimulateSteps;
  final TutorialGuideVariant petGuide;
  final bool petEnabled;
  final VoidCallback onTogglePet;

  /// Adımların gerçek sensörden mi geldiği. Demo butonları yalnızca manuel
  /// kaynakta çalışır.
  final bool usingRealPedometer;

  /// Adım sayacı izninin durumu; verilmediyse ana ekranda açıklama çıkar.
  final StepPermissionStatus stepPermission;

  /// Kalıcı reddedilmiş izni açmak için sistem ayarlarına gider.
  final VoidCallback onOpenStepSettings;

  /// Debug'da kaynak değiştirme; release'de `null` gelir ve anahtar çıkmaz.
  final ValueChanged<bool>? onUseManualSourceChanged;

  final bool useManualSource;

  const HomeScreen({
    super.key,
    required this.profile,
    this.equippedTitle,
    required this.today,
    required this.adventure,
    required this.onOpenAdventure,
    required this.onOpenWheel,
    required this.onOpenRewards,
    required this.onOpenStore,
    required this.onOpenInventory,
    required this.onSimulateSteps,
    required this.petGuide,
    required this.petEnabled,
    required this.onTogglePet,
    required this.usingRealPedometer,
    required this.stepPermission,
    required this.onOpenStepSettings,
    required this.useManualSource,
    this.onUseManualSourceChanged,
  });

  /// Çarkın açılmasına kalan adım.
  int _wheelStepsLeft() => (GameConstants.dailyWheelUnlockSteps - today.steps)
      .clamp(0, GameConstants.dailyWheelUnlockSteps);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.appTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: AppColors.streak,
                  ),
                  const SizedBox(width: 4),
                  Text(context.l10n.dayCount(profile.streakDays)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: context.l10n.helloPlayer(profile.name),
            child: Column(
              children: [
                // Takılı ünvan oyuncu adının geçtiği her yerde görünür
                // (Bölüm C.2).
                if (equippedTitle != null) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TitleBadge(title: equippedTitle, compact: true),
                  ),
                  const SizedBox(height: 10),
                ],
                HeroProgressRings(
                  profile: profile,
                  today: today,
                  adventure: adventure,
                  petGuide: petGuide,
                  petEnabled: petEnabled,
                  onTogglePet: onTogglePet,
                ),
                const SizedBox(height: 14),
                _DailyEarnings(today: today),
              ],
            ),
          ),
          if (usingRealPedometer && !stepPermission.isGranted) ...[
            const SizedBox(height: 12),
            _StepPermissionCard(
              status: stepPermission,
              onOpenSettings: onOpenStepSettings,
            ),
          ],
          const SizedBox(height: 12),
          SectionCard(
            title: context.l10n.adventure,
            onTap: onOpenAdventure,
            child:
                adventure == null
                    ? Row(
                      children: [
                        const Icon(Icons.explore, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(context.l10n.adventureStartPrompt),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.enemyWaiting(
                            context.l10n.enemyName(adventure!.enemy),
                          ),
                        ),
                        const SizedBox(height: 12),
                        StatBar(
                          label: context.l10n.monsterHealth,
                          icon: Icons.favorite,
                          color: AppColors.hp,
                          progress: adventure!.enemyHealthProgress,
                          valueText:
                              '${adventure!.remainingEnemyHealth} / ${adventure!.enemy.maxHealth}',
                        ),
                      ],
                    ),
          ),
          const SizedBox(height: 12),
          _StreakCard(profile: profile, today: today),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.casino,
                  label: context.l10n.dailyWheel,
                  enabled: today.isWheelUnlocked,
                  // Bölüm A.6: iki kapıdan hangisi önce gelirse. Kilitli
                  // kart neden kilitli olduğunu **ikisini birden** söylemeli
                  // (Model Kuralları #4), yoksa oyuncu bir maceranın da çarkı
                  // açtığını hiç öğrenemez.
                  disabledReason: context.l10n.wheelUnlockRequirement(
                    GameConstants.dailyWheelUnlockSteps,
                    _wheelStepsLeft(),
                  ),
                  // Çevrildiyse kart tıklanabilir kalır: çark ekranı neden
                  // çevrilemediğini ve kalan süreyi açıklar.
                  status:
                      profile.wheelSpunToday
                          ? DayResetCountdown(
                            prefix: context.l10n.newWheelPrefix,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          )
                          : null,
                  onTap: onOpenWheel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAction(
                  icon: Icons.emoji_events,
                  label: context.l10n.myRewards,
                  onTap: onOpenRewards,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // İkinci satır: dört hızlı erişim tek satıra sığmıyor, dar
          // ekranlarda etiketler kırpılıyordu.
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.storefront,
                  label: context.l10n.store,
                  onTap: onOpenStore,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAction(
                  icon: Icons.backpack,
                  label: context.l10n.inventory,
                  onTap: onOpenInventory,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Adım sayacı izni verilmediğinde çıkan açıklama kartı.
///
/// Devre dışı kalan bir özellik sessiz kalmaz: neden çalışmadığını söyler ve
/// çözüm yolunu gösterir. Oyunun geri kalanı bu kart görünürken de çalışır.
class _StepPermissionCard extends StatelessWidget {
  final StepPermissionStatus status;
  final VoidCallback onOpenSettings;

  const _StepPermissionCard({
    required this.status,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.l10n.stepCounter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock, size: 18, color: AppColors.streak),
              const SizedBox(width: 8),
              Expanded(
                child: Text(switch (status) {
                  StepPermissionStatus.unknown =>
                    context.l10n.permissionUnknown,
                  StepPermissionStatus.granted =>
                    context.l10n.permissionGranted,
                  StepPermissionStatus.denied => context.l10n.permissionDenied,
                  StepPermissionStatus.permanentlyDenied =>
                    context.l10n.permissionPermanentlyDenied,
                  StepPermissionStatus.unavailable =>
                    context.l10n.permissionUnavailable,
                }, style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ),
            ],
          ),
          if (status == StepPermissionStatus.permanentlyDenied) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings, size: 18),
                label: Text(context.l10n.openSettings),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bugün adımlardan kazanılan para ve XP. Her iki adım kazancı da gün boyunca
/// sınırsız devam eder; sayaçlar yalnızca günlük özeti gösterir.
class _DailyEarnings extends StatelessWidget {
  final DailyProgress today;

  const _DailyEarnings({required this.today});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _EarningRow(
          icon: Icons.monetization_on,
          color: AppColors.streak,
          text: context.l10n.coinsEarnedToday(today.coinsEarned),
          rate: context.l10n.stepsPerReward(GameConstants.stepsPerCoin),
        ),
        const SizedBox(height: 6),
        _EarningRow(
          icon: Icons.bolt,
          color: AppColors.xp,
          text: context.l10n.xpEarnedToday(today.xpEarned),
          rate: context.l10n.stepsPerReward(GameConstants.stepsPerXp),
        ),
      ],
    );
  }
}

class _EarningRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final String rate;

  const _EarningRow({
    required this.icon,
    required this.color,
    required this.text,
    required this.rate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ),
        Text(rate, style: const TextStyle(fontSize: 11, color: Colors.white38)),
      ],
    );
  }
}

/// Günlük seri kartı: mevcut seri, bugünkü durum, sonraki kilometre taşı ve
/// gün bitmek üzereyken uyarı.
///
/// Kalan süreyi ve uyarıyı canlı tutmak için dakikada bir yalnızca kendini
/// tazeler; ana ekranın tamamını yeniden çizmez. Gün hesabı [GameDay],
/// şimdiki zaman [GameClock] üzerinden gelir.
class _StreakCard extends StatefulWidget {
  final UserProfile profile;
  final DailyProgress today;

  const _StreakCard({required this.profile, required this.today});

  @override
  State<_StreakCard> createState() => _StreakCardState();
}

class _StreakCardState extends State<_StreakCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final now = GameClock.now();
    final completed = profile.streakCompletedOn(now);
    final remaining = GameDay.timeUntilReset(now);
    final stepsLeft = (GameConstants.streakStepThreshold - widget.today.steps)
        .clamp(0, GameConstants.streakStepThreshold);
    final nextMilestone = profile.nextStreakMilestone;
    final endingSoon =
        !completed &&
        remaining <= const Duration(hours: GameConstants.streakWarningHours);
    // Uyarı neyin kaybedileceğini de söylemeli: biriken savaş bonusu serinin
    // asıl değeri, gün sayısı değil.
    final streakBonus = profile.streakStatBonuses.totalBonus;
    final bonusRate = StreakStatBonuses.formatRate(streakBonus);

    return SectionCard(
      title: context.l10n.dailyStreak,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: AppColors.streak),
              const SizedBox(width: 8),
              Text(
                context.l10n.dayCount(profile.streakDays),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Icon(
                completed ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18,
                color: completed ? AppColors.primary : Colors.white54,
              ),
              const SizedBox(width: 6),
              // Esnek: 320 dp'de "Bugün tamamlandı" satırı 61 px taşıyordu
              // (demirci golden'ı yakaladı). Seri sayısı asla kırpılmaz,
              // durum metni gerekirse kırpılır.
              Flexible(
                child: Text(
                  completed
                      ? context.l10n.completedToday
                      : context.l10n.pendingToday,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            completed
                ? context.l10n.streakContinueTomorrow(
                  GameConstants.streakStepThreshold,
                )
                : context.l10n.secureStreak(stepsLeft),
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          if (nextMilestone != null) ...[
            const SizedBox(height: 4),
            Text(
              context.l10n.nextMilestone(
                nextMilestone,
                nextMilestone - profile.streakDays,
              ),
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
          if (streakBonus > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: AppColors.streak,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.streakBonusSummary(bonusRate),
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ],
          // Stok 0'ken satır hiç çıkmaz: kazanım yolları Aşama 3'te gelene
          // kadar kullanıcıya boş bir sayaç göstermenin anlamı yok.
          if (profile.streakFreezes > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.ac_unit, size: 16, color: AppColors.xp),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.streakFreezeSummary(profile.streakFreezes),
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ],
          if (endingSoon) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: AppColors.streak,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    streakBonus > 0
                        ? context.l10n.streakEndingSoonWithBonus(
                          _formatRemaining(context, remaining),
                          bonusRate,
                        )
                        : context.l10n.streakEndingSoon(
                          _formatRemaining(context, remaining),
                        ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.streak,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  /// Kartın altında görünen küçük durum satırı (ör. çark geri sayımı).
  final Widget? status;

  /// Kart kilitliyken dokunulduğunda gösterilecek açıklama.
  /// Devre dışı bir kontrol sessiz kalmaz; nedenini söyler.
  final String? disabledReason;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.status,
    this.disabledReason,
  });

  void _explainDisabled(BuildContext context) {
    final reason = disabledReason;
    if (reason == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(Icons.lock, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(reason)),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final locked = !enabled;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: SectionCard(
        onTap:
            enabled
                ? onTap
                : (disabledReason == null
                    ? null
                    : () => _explainDisabled(context)),
        child: Column(
          children: [
            // Ana ikon kilitliyken de kalır; kilit köşede küçük bir rozet
            // olarak eklenir, böylece kart kimliğini kaybetmez.
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: AppColors.primary),
                if (locked)
                  const Positioned(
                    right: -6,
                    bottom: -4,
                    child: Icon(Icons.lock, size: 13, color: AppColors.primary),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center),
            if (status != null) ...[const SizedBox(height: 4), status!],
          ],
        ),
      ),
    );
  }
}
