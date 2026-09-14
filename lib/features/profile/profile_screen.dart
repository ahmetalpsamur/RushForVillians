import 'package:flutter/material.dart';

import '../../core/localization/app_formatters.dart';
import '../../core/localization/locale_preference.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/game_day.dart';
import '../../models/adventure_quest.dart';
import '../../models/daily_progress.dart';
import '../../core/utils/equipped_buffs.dart';
import '../../models/daily_step_record.dart';
import '../../models/item.dart';
import '../../models/game_title.dart';
import '../../models/user_profile.dart';
import '../../l10n/l10n_context.dart';
import '../../l10n/content_localizations.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/daily_step_ring.dart';
import '../../widgets/language_selector_card.dart';
import '../../widgets/section_card.dart';
import '../../widgets/title_badge.dart';
import '../../widgets/stat_bar.dart';
import '../inventory/inventory_screen.dart';
import 'step_history_screen.dart';
import '../safety/safety_screen.dart';
import '../../core/constants/safety_messages.dart';

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
  final LocalePreference localePreference;
  final ValueChanged<LocalePreference> onLocalePreferenceChanged;

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
    this.localePreference = LocalePreference.system,
    this.onLocalePreferenceChanged = ignoreLocalePreference,
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
  static String _buffSummary(BuildContext context, EquippedBuffs buffs) {
    String rate(String label, double value) =>
        context.l10n.buffRate(label, (value * 100).round());
    final parts = <String>[
      if (buffs.stepCoinBonus > 0)
        rate(context.l10n.buffStepCoins, buffs.stepCoinBonus),
      if (buffs.stepXpBonus > 0)
        rate(context.l10n.buffStepXp, buffs.stepXpBonus),
      if (buffs.wheelXpBonus > 0)
        rate(context.l10n.buffWheelXp, buffs.wheelXpBonus),
      if (buffs.enemyXpBonus > 0)
        rate(context.l10n.buffEnemyXp, buffs.enemyXpBonus),
      if (buffs.streakFreezeCapBonus > 0)
        context.l10n.buffFreezeStock(buffs.streakFreezeCapBonus),
      if (buffs.wheelSpinCapBonus > 0)
        context.l10n.buffWheelStock(buffs.wheelSpinCapBonus),
      if (buffs.streakStepRelief > 0)
        context.l10n.buffStreakThreshold(buffs.streakStepRelief),
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.profile),
        actions: [
          CompactLanguageSelector(
            value: localePreference,
            onChanged: onLocalePreferenceChanged,
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.shield_outlined),
            tooltip: SafetyMessages.of(context).pageTitle,
            onPressed:
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SafetyScreen()),
                ),
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
                  Text(context.l10n.levelNumber(profile.level)),
                  const SizedBox(height: 8),
                  Chip(
                    avatar: const Icon(Icons.auto_awesome, size: 18),
                    label: Text(
                      context.l10n.characterClassName(
                        profile.avatar.characterClass,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.profileDetails(
                      profile.avatar.age,
                      profile.avatar.weight,
                      context.l10n.genderName(profile.avatar.gender),
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: canEditCharacter ? onEditCharacter : null,
                    icon: const Icon(Icons.science),
                    label: Text(
                      canEditCharacter
                          ? context.l10n.useReincarnationPotion
                          : context.l10n.reincarnationPotionRequired,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: context.l10n.equipment,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  equippedItems.isEmpty
                      ? context.l10n.nothingEquipped
                      : context.l10n.equippedItemsSummary(
                        equippedItems.length,
                        equippedItems.map(context.l10n.itemName).join(', '),
                      ),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (!buffs.isEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    _buffSummary(context, buffs),
                    style: const TextStyle(color: AppColors.xp, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onOpenInventory,
                    icon: const Icon(Icons.backpack),
                    label: Text(context.l10n.openInventory),
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
                            Text(
                              context.l10n.titles,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              equippedTitle == null
                                  ? context.l10n.earnedTitlesPrompt(
                                    ownedTitleCount,
                                  )
                                  : context.l10n.equippedTitleSummary(
                                    equippedTitle!.name,
                                    ownedTitleCount,
                                  ),
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white10,
                        child: Icon(Icons.hardware, color: AppColors.streak),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.blacksmith,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.l10n.blacksmithProfileDescription,
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
            title: context.l10n.lastThreeDays,
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
                                centerLabel: AppFormatters.shortWeekday(
                                  context,
                                  record.date,
                                ),
                                onTap:
                                    () => showDailyStepDetails(context, record),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                AppFormatters.shortDayMonth(
                                  context,
                                  record.date,
                                ),
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
                      label: Text(context.l10n.viewAllStepRings),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: context.l10n.statistics,
            child: Column(
              children: [
                if (adventure != null) ...[
                  StatBar(
                    label: context.l10n.combatHealth,
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
                  Text(
                    context.l10n.combatHealthAdventureOnly,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
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
              title: Text(context.l10n.dailyStreakProfile),
              subtitle: Text(context.l10n.longestStreak(profile.longestStreak)),
              trailing: Text(
                context.l10n.dayCount(profile.streakDays),
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
              title: Text(context.l10n.coin),
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
