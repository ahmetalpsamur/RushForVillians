import 'package:flutter/material.dart';

import '../models/game_title.dart';
import '../models/reward_rarity.dart';

/// Takılı ünvanın oyuncu adının yanında görünen rozeti (Bölüm C.2).
///
/// Ünvanın **görünmesi** sistemin yarısı: takılı ünvan görünmüyorsa oyuncu
/// için sadece gizli bir buff olur ve "hangisini takayım" sorusu anlamını
/// yitirir. Bu yüzden oyuncu adının geçtiği her yerde bu rozet kullanılır.
///
/// Rozet nadirlik rengini taşır ama ondan **soluk** çizilir: ünvan bir
/// sıralama değil, bir kimlik.
class TitleBadge extends StatelessWidget {
  final GameTitle? title;

  /// Küçük yerlerde (liste satırı, ana ekran) daha sıkı çizim.
  final bool compact;

  const TitleBadge({super.key, required this.title, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final resolved = title;
    if (resolved == null) return const SizedBox.shrink();
    final color = resolved.rarity.color;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 10,
          vertical: compact ? 2 : 3,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.military_tech, size: compact ? 12 : 14, color: color),
            SizedBox(width: compact ? 4 : 6),
            // Esnek: uzun ünvan adı dar ekranda satırı taşırmasın.
            Flexible(
              child: Text(
                resolved.name,
                key: const ValueKey('equipped-title-name'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: compact ? 11 : 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
