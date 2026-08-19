import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/game_day.dart';
import '../../models/adventure_quest.dart';
import '../../models/daily_progress.dart';
import '../../models/daily_step_record.dart';
import '../../models/user_profile.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/daily_step_ring.dart';
import '../../widgets/section_card.dart';
import '../../widgets/stat_bar.dart';
import 'step_history_screen.dart';

/// Oyuncu profili: seviye, XP, adım geçmişi ve genel istatistikler.
class ProfileScreen extends StatelessWidget {
  final UserProfile profile;
  final DailyProgress today;
  final List<DailyStepRecord> stepHistory;

  /// Savaş canının gerçek kaynağı. Macera yokken can çubuğu gösterilmez;
  /// [UserProfile.hp] hiç azalmadığı için "can" diye gösterilmesi yanlıştı.
  final AdventureQuest? adventure;

  final VoidCallback onEditCharacter;

  const ProfileScreen({
    super.key,
    required this.profile,
    required this.today,
    required this.stepHistory,
    required this.onEditCharacter,
    this.adventure,
  });

  List<DailyStepRecord> get _recentRecords {
    // Halka oyun gününe göre anahtarlanıyor (bkz. GameDay.dayStartHour);
    // takvim gününe düşmek gün sınırından önceki saatleri kaydırırdı.
    final todayDate = GameDay.startOf(today.date);
    final recordsByDay = {
      for (final record in stepHistory) record.dateKey: record,
    };

    return List.generate(3, (index) {
      final date = todayDate.subtract(Duration(days: index + 1));
      final emptyRecord = DailyStepRecord(
        date: date,
        steps: 0,
        stepGoal: today.stepGoal,
      );
      return recordsByDay[emptyRecord.dateKey] ?? emptyRecord;
    }).reversed.toList();
  }

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
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AvatarView(avatar: profile.avatar, size: 170),
                  const SizedBox(height: 12),
                  Text(
                    profile.name,
                    textAlign: TextAlign.center,
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
                    textAlign: TextAlign.center,
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
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Son 3 Gün',
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children:
                        _recentRecords.map((record) {
                          return Column(
                            children: [
                              DailyStepRing(
                                record: record,
                                size: 76,
                                centerLabel: shortWeekday(record.date),
                                onTap:
                                    () => showDailyStepDetails(context, record),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${record.date.day}.${record.date.month.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder:
                                (_) => StepHistoryScreen(
                                  today: today,
                                  history: stepHistory,
                                ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.calendar_month),
                      label: const Text('Bütün adım halkalarını gör'),
                    ),
                  ),
                ],
              ),
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
