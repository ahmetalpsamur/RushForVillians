import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/game_day.dart';
import '../../models/adventure_quest.dart';
import '../../models/daily_progress.dart';
import '../../core/utils/equipped_buffs.dart';
import '../../models/daily_step_record.dart';
import '../../models/item.dart';
import '../../models/game_title.dart';
import '../../models/user_profile.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/daily_step_ring.dart';
import '../../widgets/section_card.dart';
import '../../widgets/title_badge.dart';
import '../../widgets/stat_bar.dart';
import '../inventory/inventory_screen.dart';
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
  final bool canEditCharacter;

  /// Kuşanılan itemler ve toplam etkileri. Profilde yalnızca **özet**
  /// gösterilir; ayrıntı ve kuşanma envanter ekranında.
  final List<Item> equippedItems;
  final EquippedBuffs buffs;

  final VoidCallback onOpenInventory;
  final VoidCallback onOpenBlacksmith;
  final VoidCallback onOpenTitles;

  /// Takılı ünvan (Bölüm C.2). Oyuncu adının hemen altında gösterilir.
  final GameTitle? equippedTitle;

  /// Kazanılmış ünvan sayısı; "Ünvanlar" kartındaki özet satırı.
  final int ownedTitleCount;

  const ProfileScreen({
    super.key,
    required this.profile,
    required this.today,
    required this.stepHistory,
    required this.onEditCharacter,
    required this.canEditCharacter,
    required this.onOpenInventory,
    required this.onOpenBlacksmith,
    required this.onOpenTitles,
    this.equippedTitle,
    this.ownedTitleCount = 0,
    this.equippedItems = const [],
    this.buffs = EquippedBuffs.none,
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

  /// Kuşanmanın tek satırlık özeti. Ayrıntı envanterdeki karakter panelinde.
  static String _buffSummary(EquippedBuffs buffs) {
    String rate(String label, double value) =>
        '$label +%${(value * 100).round()}';
    final parts = <String>[
      if (buffs.stepCoinBonus > 0) rate('adım parası', buffs.stepCoinBonus),
      if (buffs.stepXpBonus > 0) rate('adım XP', buffs.stepXpBonus),
      if (buffs.wheelXpBonus > 0) rate('çark XP', buffs.wheelXpBonus),
      if (buffs.enemyXpBonus > 0) rate('düşman XP', buffs.enemyXpBonus),
      if (buffs.streakFreezeCapBonus > 0)
        'dondurma stoğu +${buffs.streakFreezeCapBonus}',
      if (buffs.wheelSpinCapBonus > 0) 'çark stoğu +${buffs.wheelSpinCapBonus}',
      if (buffs.streakStepRelief > 0) 'seri eşiği -${buffs.streakStepRelief}',
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 245,
                    child: Center(
                      child: AvatarView(
                        avatar: profile.avatar,
                        size: 245,
                        showBackground: false,
                        combatLoop: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  // Takılı ünvan adın hemen altında: görünmeyen bir ünvan
                  // yalnızca gizli bir buff olur ve "hangisini takayım"
                  // sorusu anlamını yitirir (Bölüm C.2).
                  if (equippedTitle != null) ...[
                    const SizedBox(height: 4),
                    TitleBadge(title: equippedTitle),
                  ],
                  const SizedBox(height: 2),
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
                    onPressed: canEditCharacter ? onEditCharacter : null,
                    icon: const Icon(Icons.science),
                    label: Text(
                      canEditCharacter
                          ? 'Reenkarnasyon İksirini Kullan'
                          : 'Reenkarnasyon İksiri Gerekli',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Ekipman',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  equippedItems.isEmpty
                      ? 'Hiçbir şey kuşanmadın.'
                      : '${equippedItems.length} item kuşanılı: '
                          '${equippedItems.map((item) => item.name).join(', ')}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (!buffs.isEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    _buffSummary(buffs),
                    style: const TextStyle(color: AppColors.xp, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onOpenInventory,
                    icon: const Icon(Icons.backpack),
                    label: const Text('Envanteri Aç'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: const ValueKey('profile-titles-entry'),
                onTap: onOpenTitles,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white10,
                        child: Icon(
                          Icons.military_tech,
                          color: AppColors.streak,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ünvanlar',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              equippedTitle == null
                                  ? '$ownedTitleCount ünvan kazandın. Birini '
                                      'tak, adının yanında görünsün.'
                                  : 'Takılı: ${equippedTitle!.name} · '
                                      '$ownedTitleCount ünvan kazandın.',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white54),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: const ValueKey('profile-blacksmith-entry'),
                onTap: onOpenBlacksmith,
                borderRadius: BorderRadius.circular(14),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white10,
                        child: Icon(Icons.hardware, color: AppColors.streak),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Demirci',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Silahlarını birleştir, gücüne güç kat.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.white54),
                    ],
                  ),
                ),
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
                        '${adventure!.playerMaxHealth}',
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
          CharacterPowerPanel(
            buffs: buffs,
            streakBonuses: profile.streakStatBonuses,
            streakDays: profile.streakDays,
            level: profile.level,
            equippedCount: equippedItems.length,
            slotCount:
                ItemCategory.values
                    .where(
                      (category) => category.characterClasses.contains(
                        profile.avatar.characterClass,
                      ),
                    )
                    .length,
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
