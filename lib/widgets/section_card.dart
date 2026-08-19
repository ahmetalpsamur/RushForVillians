import 'package:flutter/material.dart';

/// Ekranlarda tekrar eden, başlıklı kart bölümü.
class SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final VoidCallback? onTap;

  const SectionCard({super.key, this.title, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
      ),
    );

    if (onTap == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: card,
    );
  }
}
