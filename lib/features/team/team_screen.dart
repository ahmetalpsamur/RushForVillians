import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/l10n_context.dart';
import '../../models/team.dart';
import '../../widgets/section_card.dart';

/// Taverna: takımların buluşacağı yer (Bölüm D).
///
/// **İşlevi henüz yok.** Bu birimde yalnızca ad ve çerçeve değişti; takım
/// modeli, "yan yana yürüme" hesabı ve üye listesi olduğu gibi duruyor
/// (Kural 7/8). Çevrimiçi mod geldiğinde (Aşama 6 — arkadaşımın işi) bu
/// ekran gerçek takımları gösterecek.
///
/// Sınıf adı [TeamScreen] olarak **korundu**: GD10 ile aynı gerekçe —
/// yeniden adlandırma çağrı noktalarını gezmek demek ve kullanıcıya görünen
/// tek şey başlık.
class TeamScreen extends StatelessWidget {
  final Team team;

  const TeamScreen({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.tavernTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            key: const ValueKey('tavern-coming-soon'),
            child: Row(
              children: [
                const Icon(Icons.sports_bar, color: AppColors.streak),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.tavernComingSoon,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.petTavernTeaser,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.tavernPreview,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
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
                        ? context.l10n.teamWalkingBonusActive
                        : context.l10n.teamWalkingBonusRequirement,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: context.l10n.teamTotalSteps(team.totalSteps),
            child: Column(
              children:
                  team.members
                      .map(
                        (m) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              CircleAvatar(
                                child: Text(
                                  (m.name == 'Sen'
                                      ? context.l10n.youMemberName
                                      : m.name)[0],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m.name == 'Sen'
                                          ? context.l10n.youMemberName
                                          : m.name,
                                    ),
                                    Text(
                                      context.l10n.stepCount(m.steps),
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
