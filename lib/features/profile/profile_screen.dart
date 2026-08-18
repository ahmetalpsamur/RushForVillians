import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/adventure_quest.dart';
import '../../models/user_profile.dart';
import '../../widgets/section_card.dart';
import '../../widgets/stat_bar.dart';
import '../../widgets/avatar_view.dart';

/// Oyuncu profili: seviye, XP, streak ve genel istatistikler.
class ProfileScreen extends StatelessWidget {
  final UserProfile profile;

  /// Savaş canının gerçek kaynağı. Macera yokken can çubuğu gösterilmez;
  /// [UserProfile.hp] hiç azalmadığı için "can" diye gösterilmesi yanlıştı.
  final AdventureQuest? adventure;

  final VoidCallback onEditCharacter;

  const ProfileScreen({
    super.key,
    required this.profile,
    required this.onEditCharacter,
    this.adventure,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            onPressed: onEditCharacter,
            tooltip: 'Karakteri düzenle',
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            child: Column(
              children: [
                AvatarView(avatar: profile.avatar, size: 170),
                const SizedBox(height: 12),
                Text(
                  profile.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text('Seviye ${profile.level}'),
                const SizedBox(height: 8),
                Chip(
                  avatar: const Icon(Icons.auto_awesome, size: 18),
                  label: Text(profile.avatar.characterClassLabel),
                ),
                const SizedBox(height: 4),
                Text(
                  '${profile.avatar.age} yaş • ${profile.avatar.weight} kg • ${profile.avatar.gender}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onEditCharacter,
                  icon: const Icon(Icons.tune),
                  label: const Text('Karakteri Düzenle'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'İstatistikler',
            child: Column(
              children: [
                if (adventure != null) ...[
                  StatBar(
                    label: 'Savaş Canı',
                    icon: Icons.favorite,
                    color: AppColors.hp,
                    progress:
                        adventure!.playerHealth /
                        AdventureQuest.maxPlayerHealth,
                    valueText:
                        '${adventure!.playerHealth} / '
                        '${AdventureQuest.maxPlayerHealth}',
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  const Text(
                    'Savaş canı yalnızca macera sırasında takip edilir.',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                ],
                StatBar(
                  label: 'XP',
                  icon: Icons.bolt,
                  color: AppColors.xp,
                  progress: profile.xpProgress,
                  valueText: '${profile.xp} / ${profile.xpToNextLevel}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: ListTile(
              leading: const Icon(
                Icons.local_fire_department,
                color: AppColors.streak,
              ),
              title: const Text('Günlük Streak'),
              subtitle: Text('En uzun seri: ${profile.longestStreak} gün'),
              trailing: Text(
                '${profile.streakDays} gün',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SectionCard(
            child: ListTile(
              leading: const Icon(
                Icons.monetization_on,
                color: AppColors.streak,
              ),
              title: const Text('Coin'),
              trailing: Text(
                '${profile.coins}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
