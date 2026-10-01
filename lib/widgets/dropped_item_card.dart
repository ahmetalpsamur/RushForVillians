import 'package:flutter/material.dart';

import '../l10n/content_localizations.dart';
import '../l10n/l10n_context.dart';
import '../models/reward_rarity.dart';
import '../services/item_catalog.dart';
import 'rarity_badge.dart';

/// Savaştan düşen eşyanın tek gösterim dili (Bölüm D / Faz 1).
///
/// Normal macera zaferi de Sonsuz Koşu sonucu da **bunu** kullanır; iki ayrı
/// tasarım olmaz. Garanti düşen eşya (GD93) bir dönem hiçbir ekranda
/// görünmüyordu: kayda yazılıyordu (`AdventureQuest.droppedItemId`) ama
/// oyuncuya söylenmiyordu, yani ödülün varlığı envanteri açıp saymaya
/// bağlıydı. Sonsuz koşu tarafında ise ham asset kimliği basılıyordu
/// ("Item dropped: fire_sword_variant_03") — iki dilde de bozuktu.
///
/// Kimlik katalogdan çözülür: ad [AppLocalizationsContent.itemName] ile
/// yerelleşir, nadirlik hem yazıyla hem renkle söylenir (§10 #8 ile aynı
/// fikir: bilgi tek kanala bırakılmaz).
///
/// Katalog henüz yüklenmediyse ya da kimlik katalogdan kalktıysa widget
/// **hiçbir şey çizmez** — uydurma bir ad göstermektense susmak yeğ.
class DroppedItemCard extends StatelessWidget {
  /// Düşen eşyanın katalog kimliği (`Item.id`).
  final String itemId;

  /// Üstte görünen başlık; çağıran taraf kendi bağlamını verir.
  final String label;

  const DroppedItemCard({
    super.key,
    required this.itemId,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final item = ItemCatalog.byId(itemId);
    if (item == null) return const SizedBox.shrink();
    final color = item.rarity.color;

    return DecoratedBox(
      key: const ValueKey('dropped-item-card'),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.65)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Nadirlik rengi çerçevede de tekrar ediyor: rozet metni küçük,
            // kutu uzaktan okunuyor.
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                item.assetPath,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                errorBuilder: (_, _, _) =>
                    Icon(Icons.inventory_2, size: 22, color: color),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.itemName(item),
                    key: const ValueKey('dropped-item-name'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            RarityBadge(rarity: item.rarity),
          ],
        ),
      ),
    );
  }
}
