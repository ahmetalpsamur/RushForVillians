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
        LayoutBuilder(
          builder: (context, constraints) {
            final style = Theme.of(context).textTheme.labelMedium;
            final value = Text(
              valueText,
              textAlign: TextAlign.end,
              style: style,
            );
            final painter = TextPainter(
              text: TextSpan(text: valueText, style: style),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
            )..layout();
            final needsWrap = painter.width > constraints.maxWidth - 30;
            painter.dispose();
            return Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                // Etiket esner; uzun sayılar dar ekranda kırpılmadan alt satıra geçer.
                // Eskiden ikisi de sabit genişlikteydi ve `Spacer` aradaki boşluğu
                // doldurmaya çalıştığı için dar ekranda satır taşıyordu.
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                const SizedBox(width: 8),
                if (needsWrap) Flexible(flex: 2, child: value) else value,
              ],
            );
          },
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
