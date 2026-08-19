import 'package:flutter/material.dart';

import 'reward_rarity.dart';

/// Görev tamamlandığında oyuncuya verilen ödül.
class Reward {
  final String id;
  final String name;
  final String description;
  final RewardRarity rarity;
  final IconData icon;
  final DateTime earnedAt;

  const Reward({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.icon,
    required this.earnedAt,
  });
}
