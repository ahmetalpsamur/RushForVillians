import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_profile.dart';
import '../../widgets/section_card.dart';
import '../../widgets/stat_bar.dart';

/// Oyuncu profili: seviye, XP, streak ve genel istatistikler.
class ProfileScreen extends StatelessWidget {
  final UserProfile profile;

  const ProfileScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    profile.name.isNotEmpty ? profile.name[0] : '?',
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  profile.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text('Seviye ${profile.level}'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'İstatistikler',
            child: Column(
              children: [
                StatBar(
                  label: 'HP',
                  icon: Icons.favorite,
                  color: AppColors.hp,
                  progress: profile.hpProgress,
                  valueText: '${profile.hp} / ${profile.maxHp}',
                ),
                const SizedBox(height: 12),
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
