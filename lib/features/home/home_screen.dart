import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/adventure_quest.dart';
import '../../models/daily_progress.dart';
import '../../models/user_profile.dart';
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
            child: HeroProgressRings(profile: profile, today: today),
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
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.casino,
                  label: 'Günlük Çark',
                  enabled: today.isWheelUnlocked,
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

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: SectionCard(
        onTap: enabled ? onTap : null,
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
