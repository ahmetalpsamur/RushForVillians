import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/game_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/game_clock.dart';
import '../../core/utils/game_day.dart';
import '../../models/adventure_quest.dart';
import '../../models/daily_progress.dart';
import '../../models/user_profile.dart';
import '../../services/step_permission_service.dart';
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
  final VoidCallback onOpenInventory;
  final ValueChanged<int> onSimulateSteps;

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
    required this.today,
    required this.adventure,
    required this.onOpenAdventure,
    required this.onOpenWheel,
    required this.onOpenRewards,
    required this.onOpenStore,
    required this.onOpenInventory,
    required this.onSimulateSteps,
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
          if (usingRealPedometer && !stepPermission.isGranted) ...[
            const SizedBox(height: 12),
            _StepPermissionCard(
              status: stepPermission,
              onOpenSettings: onOpenStepSettings,
            ),
          ],
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
                  label: 'Mağaza',
                  onTap: onOpenStore,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAction(
                  icon: Icons.backpack,
                  label: 'Envanter',
                  onTap: onOpenInventory,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _StepSourceCard(
            usingRealPedometer: usingRealPedometer,
            useManualSource: useManualSource,
            onUseManualSourceChanged: onUseManualSourceChanged,
            onSimulateSteps: onSimulateSteps,
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
      title: 'Adım Sayacı',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock, size: 18, color: AppColors.streak),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status.description,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
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
                label: const Text('Ayarları Aç'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Aktif adım kaynağını gösterir ve demo kontrollerini barındırır.
///
/// Gerçek sensör aktifken demo butonları kilitlidir; nedenini söyleyerek
/// kilitlenir. Debug derlemelerinde kaynak anahtarla değiştirilebilir —
/// emülatörde adım üretebilmek şart.
class _StepSourceCard extends StatelessWidget {
  final bool usingRealPedometer;
  final bool useManualSource;
  final ValueChanged<bool>? onUseManualSourceChanged;
  final ValueChanged<int> onSimulateSteps;

  const _StepSourceCard({
    required this.usingRealPedometer,
    required this.useManualSource,
    required this.onUseManualSourceChanged,
    required this.onSimulateSteps,
  });

  @override
  Widget build(BuildContext context) {
    final onChanged = onUseManualSourceChanged;
    return SectionCard(
      title: 'Adım Kaynağı',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                usingRealPedometer
                    ? Icons.directions_walk
                    : Icons.touch_app_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  usingRealPedometer
                      ? 'Pedometer (gerçek sensör)'
                      : 'Manuel (demo kontrolleri)',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              if (onChanged != null)
                Switch(value: useManualSource, onChanged: onChanged),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            usingRealPedometer
                ? 'Adımlar cihazın sensöründen geliyor. Demo butonları '
                    'kapalı; açmak için kaynağı manuele al.'
                : 'Adımları buradan simüle edebilirsin.',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final amount in const [1000, 5000, 20000])
                _StepButton(
                  amount: amount,
                  enabled: !usingRealPedometer,
                  onSimulateSteps: onSimulateSteps,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bugün adımlardan kazanılan para ve XP. Para tavanına ulaşıldığında bunu da
/// söyler — kazanç sessizce durmaz. XP'nin günlük tavanı yok.
class _DailyEarnings extends StatelessWidget {
  final DailyProgress today;

  const _DailyEarnings({required this.today});

  @override
  Widget build(BuildContext context) {
    final capped = today.coinCapReached;
    return Column(
      children: [
        _EarningRow(
          icon: Icons.monetization_on,
          color: AppColors.streak,
          text:
              capped
                  ? 'Bugün adımlarından ${today.coinsEarned} coin kazandın — '
                      'günlük sınır doldu.'
                  : 'Bugün adımlarından ${today.coinsEarned} coin kazandın.',
          rate: '${GameConstants.stepsPerCoin} adım = 1',
        ),
        const SizedBox(height: 6),
        _EarningRow(
          icon: Icons.bolt,
          color: AppColors.xp,
          text: 'Bugün adımlarından ${today.xpEarned} XP kazandın.',
          rate: '${GameConstants.stepsPerXp} adım = 1',
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
                    '${profile.streakFreezes} dondurma hakkın var. Bir gün '
                    'kaçırırsan otomatik kullanılır.',
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
  final bool enabled;
  final ValueChanged<int> onSimulateSteps;

  const _StepButton({
    required this.amount,
    required this.onSimulateSteps,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? () => onSimulateSteps(amount) : null,
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
