import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/l10n_context.dart';
import '../../l10n/content_localizations.dart';
import '../../models/tutorial_guide_variant.dart';

class GuideSelectionScreen extends StatefulWidget {
  final ValueChanged<TutorialGuideVariant> onSelected;

  const GuideSelectionScreen({super.key, required this.onSelected});

  @override
  State<GuideSelectionScreen> createState() => _GuideSelectionScreenState();
}

class _GuideSelectionScreenState extends State<GuideSelectionScreen> {
  TutorialGuideVariant? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF171224), Color(0xFF090810)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            child: Column(
              children: [
                Text(
                  context.l10n.chooseCompanionEyebrow,
                  style: const TextStyle(
                    color: AppColors.streak,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  context.l10n.chooseCompanionTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.chooseCompanionDescription,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white60, height: 1.35),
                ),
                const SizedBox(height: 22),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final horizontal = constraints.maxWidth >= 620;
                      final cards = [
                        for (final guide in TutorialGuideVariant.values)
                          _GuideChoiceCard(
                            guide: guide,
                            selected: _selected == guide,
                            onTap: () => setState(() => _selected = guide),
                          ),
                      ];
                      if (horizontal) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < cards.length; i++) ...[
                              Expanded(child: cards[i]),
                              if (i != cards.length - 1)
                                const SizedBox(width: 12),
                            ],
                          ],
                        );
                      }
                      return ListView.separated(
                        itemCount: cards.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder:
                            (_, index) =>
                                SizedBox(height: 128, child: cards[index]),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('confirm-guide-selection'),
                    onPressed:
                        _selected == null
                            ? null
                            : () => widget.onSelected(_selected!),
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(context.l10n.chooseMyCompanion),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuideChoiceCard extends StatelessWidget {
  final TutorialGuideVariant guide;
  final bool selected;
  final VoidCallback onTap;

  const _GuideChoiceCard({
    required this.guide,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      key: ValueKey('guide-${guide.id}'),
      color: selected ? const Color(0xFF302250) : const Color(0xFF1B1825),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? const Color(0xFF8D6BFF) : Colors.white12,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF100D18),
                  border: Border.all(
                    color: selected ? AppColors.streak : Colors.white10,
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  guide.idleAsset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.guideName(guide),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      context.l10n.guideDescription(guide),
                      style: const TextStyle(
                        color: Colors.white60,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? AppColors.streak : Colors.white24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
