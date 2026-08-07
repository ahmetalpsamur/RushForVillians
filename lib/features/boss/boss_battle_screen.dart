import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/reward_calculator.dart';
import '../../models/boss_quest.dart';
import '../../models/daily_progress.dart';
import '../../models/reward.dart';
import '../../models/reward_rarity.dart';
import '../../widgets/rarity_badge.dart';
import '../../widgets/section_card.dart';
import '../../widgets/stat_bar.dart';

/// Ejderha savaş ekranı: adım ilerlemesi ejderhanın canını azaltır.
/// Görev tamamlanınca performansa göre nadirlikte bir ödül verilir.
class BossBattleScreen extends StatelessWidget {
  final BossQuest dragon;
  final DailyProgress today;
  final ValueChanged<Reward> onRewardClaimed;

  const BossBattleScreen({
    super.key,
    required this.dragon,
    required this.today,
    required this.onRewardClaimed,
  });

  Reward _buildReward(BuildContext context) {
    final rarity = calculateRewardRarity(
      stepRatio: dragon.currentSteps / dragon.requiredSteps,
    );
    return Reward(
      id: 'dragon_${DateTime.now().millisecondsSinceEpoch}',
      name: '${dragon.name} Ganimeti',
      description: 'Ejderhayı yenerek kazanılan ödül.',
      rarity: rarity,
      icon: Icons.diamond,
      earnedAt: DateTime.now(),
    );
  }

  void _claim(BuildContext context) {
    final reward = _buildReward(context);
    onRewardClaimed(reward);
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Ejderha Yenildi! 🐉'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward.name),
                const SizedBox(height: 8),
                RarityBadge(rarity: reward.rarity),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Harika!'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remaining = (dragon.requiredSteps - dragon.currentSteps).clamp(
      0,
      dragon.requiredSteps,
    );
    return Scaffold(
      appBar: AppBar(title: Text(dragon.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.local_fire_department,
                  size: 64,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 12),
                Text(
                  dragon.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                StatBar(
                  label: 'Ejderha Canı (adım ile azalır)',
                  icon: Icons.favorite_border,
                  color: AppColors.hp,
                  progress: 1 - dragon.progress,
                  valueText:
                      '${dragon.currentSteps} / ${dragon.requiredSteps} adım',
                ),
                const SizedBox(height: 8),
                Text(
                  dragon.isDefeated
                      ? 'Ejderha yenildi!'
                      : '$remaining adım daha kaldı.',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Ödül Nadirliği Nasıl Belirlenir?',
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RarityRow(rarity: RewardRarity.common, hint: '< %75 hedef'),
                _RarityRow(
                  rarity: RewardRarity.uncommon,
                  hint: '%75 - %99 hedef',
                ),
                _RarityRow(rarity: RewardRarity.rare, hint: 'Hedefi tuttur'),
                _RarityRow(rarity: RewardRarity.epic, hint: 'Hedefin %125\'i'),
                _RarityRow(
                  rarity: RewardRarity.legendary,
                  hint: 'Hedefin %150\'si',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed:
                dragon.isDefeated && !dragon.rewardClaimed
                    ? () => _claim(context)
                    : null,
            icon: const Icon(Icons.card_giftcard),
            label: Text(
              dragon.rewardClaimed ? 'Ödül Alındı' : 'Ödülü Talep Et',
            ),
          ),
        ],
      ),
    );
  }
}

class _RarityRow extends StatelessWidget {
  final RewardRarity rarity;
  final String hint;

  const _RarityRow({required this.rarity, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          RarityBadge(rarity: rarity),
          const SizedBox(width: 12),
          Expanded(child: Text(hint)),
        ],
      ),
    );
  }
}
