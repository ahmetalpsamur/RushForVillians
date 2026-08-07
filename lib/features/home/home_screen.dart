import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/boss_quest.dart';
import '../../models/daily_progress.dart';
import '../../models/user_profile.dart';
import '../../widgets/section_card.dart';
import '../../widgets/stat_bar.dart';
import '../../widgets/avatar_view.dart';

/// Ana panel: günün özeti (HP, seviye/XP, kalori, adım) ve diğer
/// bölümlere hızlı erişim.
class HomeScreen extends StatelessWidget {
  final UserProfile profile;
  final DailyProgress today;
  final BossQuest dragon;
  final VoidCallback onOpenDragon;
  final VoidCallback onOpenWheel;
  final VoidCallback onOpenRewards;
  final VoidCallback onOpenStore;
  final ValueChanged<int> onSimulateSteps;

  const HomeScreen({
    super.key,
    required this.profile,
    required this.today,
    required this.dragon,
    required this.onOpenDragon,
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
            child: Column(
              children: [
                AvatarView(avatar: profile.avatar, size: 165),
                const SizedBox(height: 8),
                Text(
                  profile.avatar.characterClassLabel,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                StatBar(
                  label: 'HP',
                  icon: Icons.favorite,
                  color: AppColors.hp,
                  progress: profile.hpProgress,
                  valueText: '${profile.hp} / ${profile.maxHp}',
                ),
                const SizedBox(height: 12),
                StatBar(
                  label: 'Seviye ${profile.level}',
                  icon: Icons.bolt,
                  color: AppColors.xp,
                  progress: profile.xpProgress,
                  valueText: '${profile.xp} / ${profile.xpToNextLevel} XP',
                ),
                const SizedBox(height: 12),
                StatBar(
                  label: 'Günlük Kalori',
                  icon: Icons.local_fire_department,
                  color: AppColors.calorie,
                  progress: today.calorieProgress,
                  valueText:
                      '${today.caloriesBurned.toStringAsFixed(0)} / ${today.calorieGoal.toStringAsFixed(0)} kcal',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: '🐉 Ejderha Görevi',
            onTap: onOpenDragon,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dragon.description),
                const SizedBox(height: 12),
                StatBar(
                  label: 'Adım İlerlemesi',
                  icon: Icons.directions_walk,
                  color: AppColors.primary,
                  progress: dragon.progress,
                  valueText: '${dragon.currentSteps} / ${dragon.requiredSteps}',
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
