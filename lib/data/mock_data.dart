import 'package:flutter/material.dart';

import '../core/constants/game_constants.dart';
import '../models/boss_quest.dart';
import '../models/team.dart';
import '../models/xp_store_item.dart';

/// Demo/taslak amaçlı sabit veriler. İleride bir backend veya yerel
/// veritabanı (ör. Hive/SharedPreferences) ile değiştirilecek.
class MockData {
  MockData._();

  static BossQuest dailyDragon() => BossQuest(
    name: 'Gölge Ejderhası',
    description: '20.000 adım atarak ejderhayı yen, ödülünü kap.',
    requiredSteps: 20000,
  );

  static Team defaultTeam() => Team(
    name: 'Kızıl Yürüyüşçüler',
    members: [
      TeamMember(name: 'Sen', steps: 0, isWalkingNow: false),
      TeamMember(name: 'Ayşe', steps: 4200, isWalkingNow: true),
      TeamMember(name: 'Mehmet', steps: 3100, isWalkingNow: false),
    ],
  );

  static List<XpStoreItem> storeItems() => const [
    XpStoreItem(
      id: 'reincarnation_potion',
      name: 'Reenkarnasyon İksiri',
      description:
          'Karakterini ve sınıfını bir kez yeniden seçmeni sağlar. '
          'Düzenleme tamamlandığında tüketilir.',
      cost: 2000,
      icon: Icons.science,
    ),
    // Tüketilen iki yükseltme: `repeatable`, çünkü etkileri bir kerelik.
    // Kalıcı sahiplik yerine profildeki sayaçlara/süreye yazılırlar.
    XpStoreItem(
      id: 'boost_double_xp',
      name: '2x XP Boost (1 gün)',
      description:
          'Gün sonuna kadar kazandığın tüm XP\'yi ikiye katlar '
          '(adım, düşman ve çark dahil).',
      cost: 800,
      icon: Icons.flash_on,
      repeatable: true,
    ),
    XpStoreItem(
      id: 'wheel_extra_spin',
      name: 'Ekstra Çark Hakkı',
      description:
          'Günlük hakkın bittikten sonra çarkı bir kez daha çevir. '
          'Stok en fazla ${GameConstants.maxExtraWheelSpins}.',
      cost: 300,
      icon: Icons.replay_circle_filled,
      repeatable: true,
    ),
    XpStoreItem(
      id: 'upgrade_streak_freeze',
      name: 'Seri Dondurma Hakkı',
      description:
          'Bir günü kaçırırsan serin otomatik korunur. '
          'Stok en fazla ${GameConstants.maxStreakFreezes}.',
      cost: 600,
      icon: Icons.ac_unit,
      repeatable: true,
    ),
  ];

  /// Günlük çarkta çıkabilecek ödüller (XP miktarı).
  static const List<int> wheelXpOptions = [50, 100, 150, 200, 300, 500];
}
