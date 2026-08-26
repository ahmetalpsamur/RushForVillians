import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/pet_sayings.dart';
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
      appBar: AppBar(title: const Text('Taverna')),
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
                    children: const [
                      Text(
                        'Taverna daha açılmadı',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 4),
                      Text(
                        PetSayings.tavernTeaser,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Aşağıdaki takım şimdilik bir önizleme.',
                        style: TextStyle(color: Colors.white38, fontSize: 11.5),
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
