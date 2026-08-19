import 'package:flutter/material.dart';

import '../../models/reward.dart';
import '../../widgets/rarity_badge.dart';
import '../../widgets/section_card.dart';

/// Kazanılan tüm ödüllerin listesi.
class RewardsScreen extends StatelessWidget {
  final List<Reward> rewards;

  const RewardsScreen({super.key, required this.rewards});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ödüllerim')),
      body: rewards.isEmpty
          ? const Center(
              child: Text(
                'Henüz ödül kazanmadın.\nEjderhayı yenmeyi dene!',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rewards.length,
              itemBuilder: (context, index) {
                final reward = rewards[rewards.length - 1 - index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SectionCard(
                    child: Row(
                      children: [
                        Icon(reward.icon, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reward.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                reward.description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        RarityBadge(rarity: reward.rarity),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
