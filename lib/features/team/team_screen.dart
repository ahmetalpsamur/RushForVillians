import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/team.dart';
import '../../widgets/section_card.dart';

/// Takım ekranı: üyeler ve "yan yana yürüme" (aynı anda yürüyor olma)
/// durumunun takibi.
class TeamScreen extends StatelessWidget {
  final Team team;

  const TeamScreen({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(team.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            child: Row(
              children: [
                Icon(
                  team.isWalkingSideBySide
                      ? Icons.groups
                      : Icons.groups_outlined,
                  color:
                      team.isWalkingSideBySide ? AppColors.xp : Colors.white54,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    team.isWalkingSideBySide
                        ? 'Takım şu anda yan yana yürüyor! Bonus XP aktif.'
                        : 'Bonus için tüm üyelerin aynı anda yürümesi gerekir.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Toplam Takım Adımı: ${team.totalSteps}',
            child: Column(
              children:
                  team.members
                      .map(
                        (m) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              CircleAvatar(child: Text(m.name[0])),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.name),
                                    Text(
                                      '${m.steps} adım',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.directions_walk,
                                size: 18,
                                color:
                                    m.isWalkingNow
                                        ? AppColors.xp
                                        : Colors.white24,
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
