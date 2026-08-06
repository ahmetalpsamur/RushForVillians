import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/xp_store_item.dart';
import '../../widgets/section_card.dart';

/// XP/coin ile satın alınabilecek öğelerin listelendiği mağaza.
class XpStoreScreen extends StatelessWidget {
  final List<XpStoreItem> items;
  final int coins;
  final void Function(XpStoreItem item) onPurchase;

  const XpStoreScreen({
    super.key,
    required this.items,
    required this.coins,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('XP Mağazası'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: AppColors.streak),
                  const SizedBox(width: 4),
                  Text('$coins'),
                ],
              ),
            ),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final affordable = coins >= item.cost;
          return SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.icon, size: 32, color: AppColors.primary),
                const SizedBox(height: 8),
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: affordable ? () => onPurchase(item) : null,
                    child: Text('${item.cost} XP'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
