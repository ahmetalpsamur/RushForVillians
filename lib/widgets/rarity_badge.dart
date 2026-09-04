import 'package:flutter/material.dart';

import '../models/reward_rarity.dart';
import '../l10n/content_localizations.dart';
import '../l10n/l10n_context.dart';

/// Ödül nadirliğini renkli bir rozet olarak gösterir.
class RarityBadge extends StatelessWidget {
  final RewardRarity rarity;

  const RarityBadge({super.key, required this.rarity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: rarity.color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: rarity.color),
      ),
      child: Text(
        context.l10n.rarityName(rarity),
        style: TextStyle(
          color: rarity.color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
