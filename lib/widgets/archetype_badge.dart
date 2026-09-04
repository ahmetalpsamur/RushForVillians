import 'package:flutter/material.dart';

import '../models/item.dart';
import '../l10n/content_localizations.dart';
import '../l10n/l10n_context.dart';

/// Item'ın **karakterini** gösteren küçük rozet: Vurucu / Muhafız / Düellocu /
/// Çevik.
///
/// Nadirlik rozetinin yanında durur ve farklı bir soruyu cevaplar: nadirlik
/// "ne kadar güçlü", arketip "hangi yöne güçlü". İkisi birlikte, aynı
/// nadirlikteki iki eşya arasında gerçek bir tercih yapılmasını sağlıyor.
///
/// Görsel dil bilerek nadirlikten **soluk**: arketip bir sıralama değil, bir
/// yön. Renk ve ikon Flutter tipi olduğu için burada duruyor; model katmanı
/// yalnızca [ItemArchetype] enum'unu tanıyor (Model Kuralları #1).
class ArchetypeBadge extends StatelessWidget {
  final ItemArchetype archetype;

  /// Yalnızca ikon göster; dar satırlarda ad yerine kullanılır.
  final bool compact;

  const ArchetypeBadge({
    super.key,
    required this.archetype,
    this.compact = false,
  });

  static IconData iconFor(ItemArchetype archetype) => switch (archetype) {
    ItemArchetype.striker => Icons.bolt,
    ItemArchetype.guardian => Icons.shield_outlined,
    ItemArchetype.duelist => Icons.gps_fixed,
    ItemArchetype.swift => Icons.air,
  };

  static Color colorFor(ItemArchetype archetype) => switch (archetype) {
    ItemArchetype.striker => const Color(0xFFFF8A65),
    ItemArchetype.guardian => const Color(0xFF64B5F6),
    ItemArchetype.duelist => const Color(0xFFBA68C8),
    ItemArchetype.swift => const Color(0xFF4DD0E1),
  };

  @override
  Widget build(BuildContext context) {
    final color = colorFor(archetype);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconFor(archetype), size: 11, color: color),
          if (!compact) ...[
            const SizedBox(width: 4),
            // Esnek: dar kartlarda (320 dp'de hücre ~106 px) ad sığmayabilir.
            // Kırpılması, RenderFlex taşması üretmesinden yeğ — mağaza
            // kartının taşma testleri altı ekran genişliğinde bunu bağlıyor.
            Flexible(
              child: Text(
                context.l10n.itemArchetypeName(archetype),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.fade,
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
