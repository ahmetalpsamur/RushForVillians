import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/game_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/game_clock.dart';
import '../../core/utils/game_day.dart';
import '../../models/adventure_quest.dart';
import '../../models/daily_progress.dart';
import '../../models/user_profile.dart';
import '../../widgets/day_reset_countdown.dart';
import '../../widgets/section_card.dart';
import '../../widgets/stat_bar.dart';
import '../../widgets/hero_progress_rings.dart';

/// Ana panel: günün özeti (HP, seviye/XP, adım) ve diğer
/// bölümlere hızlı erişim.
class HomeScreen extends StatelessWidget {
  final UserProfile profile;
  final DailyProgress today;
  final AdventureQuest? adventure;
  final VoidCallback onOpenAdventure;
  final VoidCallback onOpenWheel;
  final VoidCallback onOpenRewards;
  final VoidCallback onOpenStore;
  final ValueChanged<int> onSimulateSteps;

  const HomeScreen({
    super.key,
    required this.profile,
    required this.today,
    required this.adventure,
    required this.onOpenAdventure,
    required this.onOpenWheel,
    required this.onOpenRewards,
    required this.onOpenStore,
    required this.onSimulateSteps,
  });

  /// Çarkın açılmasına kalan adım.
  int _wheelStepsLeft() => (GameConstants.dailyWheelUnlockSteps - today.steps)
      .clamp(0, GameConstants.dailyWheelUnlockSteps);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rush for Villains'),
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
                  Text('${profile.streakDays} gün'),
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
            title: 'Merhaba, ${profile.name}',
            child: Column(
              children: [
                HeroProgressRings(
                  profile: profile,
                  today: today,
                  adventure: adventure,
                ),
                const SizedBox(height: 14),
                _DailyEarnings(today: today),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Macera',
            onTap: onOpenAdventure,
            child:
                adventure == null
                    ? const Row(
                      children: [
                        Icon(Icons.explore, color: AppColors.primary),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Günlük hedefini ve düşmanını seçerek maceraya başla.',
                          ),
                        ),
                        Icon(Icons.chevron_right),
                      ],
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${adventure!.enemy.name} seni bekliyor. Ritmini koru!',
                        ),
                        const SizedBox(height: 12),
                        StatBar(
                          label: 'Canavar Canı',
                          icon: Icons.favorite,
                          color: AppColors.hp,
                          progress: adventure!.healthProgress(today.steps),
                          valueText:
                              '${adventure!.remainingHealth(today.steps)} / ${adventure!.stepGoal}',
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
                  label: 'Günlük Çark',
                  enabled: today.isWheelUnlocked,
                  disabledReason:
                      'Çark ${GameConstants.dailyWheelUnlockSteps} adımda '
                      'açılıyor. ${_wheelStepsLeft()} adım kaldı.',
                  // Çevrildiyse kart tıklanabilir kalır: çark ekranı neden
                  // çevrilemediğini ve kalan süreyi açıklar.
                  status:
                      profile.wheelSpunToday
                          ? const DayResetCountdown(
                            prefix: 'Yeni çark: ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
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
                  label: 'Ödüllerim',
                  onTap: onOpenRewards,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAction(
                  icon: Icons.storefront,
                  label: 'Mağaza',
                  onTap: onOpenStore,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Demo Kontrolleri',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gerçek adım sayacı entegrasyonu gelene kadar adımları '
                  'buradan simüle edebilirsin.',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _StepButton(amount: 1000, onSimulateSteps: onSimulateSteps),
                    _StepButton(amount: 5000, onSimulateSteps: onSimulateSteps),
                    _StepButton(
                      amount: 20000,
                      onSimulateSteps: onSimulateSteps,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bugün adımlardan kazanılan para. Tavana ulaşıldığında bunu da söyler —
/// kazanç sessizce durmaz.
class _DailyEarnings extends StatelessWidget {
  final DailyProgress today;

  const _DailyEarnings({required this.today});

  @override
  Widget build(BuildContext context) {
    final capped = today.coinCapReached;
    return Row(
      children: [
        const Icon(Icons.monetization_on, size: 18, color: AppColors.streak),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            capped
                ? 'Bugün adımlarından ${today.coinsEarned} coin kazandın — '
                    'günlük sınır doldu.'
                : 'Bugün adımlarından ${today.coinsEarned} coin kazandın.',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ),
        Text(
          '${GameConstants.stepsPerCoin} adım = 1',
          style: const TextStyle(fontSize: 11, color: Colors.white38),
        ),
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

    return SectionCard(
      title: 'Günlük Seri',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: AppColors.streak),
              const SizedBox(width: 8),
              Text(
                '${profile.streakDays} gün',
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
              Text(
                completed ? 'Bugün tamamlandı' : 'Bugün bekliyor',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            completed
                ? 'Seri sürüyor. Yarın ${GameConstants.streakStepThreshold} '
                    'adım atarak devam ettir.'
                : 'Seriyi sürdürmek için $stepsLeft adım kaldı.',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          if (nextMilestone != null) ...[
            const SizedBox(height: 4),
            Text(
              'Sonraki kilometre taşı: $nextMilestone gün '
              '(${nextMilestone - profile.streakDays} gün kaldı)',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
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
                    'Gün bitmesine ${GameDay.formatRemaining(remaining)} kaldı, '
                    'serini kaybetme!',
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

class _StepButton extends StatelessWidget {
  final int amount;
  final ValueChanged<int> onSimulateSteps;

  const _StepButton({required this.amount, required this.onSimulateSteps});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => onSimulateSteps(amount),
      child: Text('+$amount adım'),
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
