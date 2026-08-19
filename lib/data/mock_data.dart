import 'package:flutter/material.dart';

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
      id: 'skin_dragon_cape',
      name: 'Ejderha Pelerini',
      description: 'Karakterin için kozmetik pelerin.',
      cost: 500,
      icon: Icons.checkroom,
    ),
    XpStoreItem(
      id: 'boost_double_xp',
      name: '2x XP Boost (1 gün)',
      description: 'Bir günlüğüne kazandığın XP\'yi ikiye katlar.',
      cost: 800,
      icon: Icons.flash_on,
    ),
    XpStoreItem(
      id: 'wheel_extra_spin',
      name: 'Ekstra Çark Hakkı',
      description: 'Günlük çarkı bir kez daha çevir.',
      cost: 300,
      icon: Icons.replay_circle_filled,
    ),
    XpStoreItem(
      id: 'title_villain_hunter',
      name: '"Kötü Ruh Avcısı" Unvanı',
      description: 'Profilinde görünen özel unvan.',
      cost: 1200,
      icon: Icons.military_tech,
    ),
  ];

  /// Günlük çarkta çıkabilecek ödüller (XP miktarı).
  static const List<int> wheelXpOptions = [50, 100, 150, 200, 300, 500];
}
