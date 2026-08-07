import 'package:flutter/material.dart';

/// Görev ilerlemelerini gösteren etiketli çubuk.
class StatBar extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final double progress;
  final String valueText;

  const StatBar({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.progress,
    required this.valueText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const Spacer(),
            Text(valueText, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 10,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
