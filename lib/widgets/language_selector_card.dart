import 'package:flutter/material.dart';

import '../core/localization/locale_preference.dart';
import '../l10n/l10n_context.dart';
import 'section_card.dart';

class LanguageSelectorCard extends StatelessWidget {
  final LocalePreference value;
  final ValueChanged<LocalePreference> onChanged;

  const LanguageSelectorCard({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final labels = {
      LocalePreference.system: strings.languageSystem,
      LocalePreference.turkish: strings.languageTurkish,
      LocalePreference.english: strings.languageEnglish,
    };

    return SectionCard(
      title: strings.language,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.languageDescription,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 10),
          InputDecorator(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.language),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<LocalePreference>(
                key: const ValueKey('language-selector'),
                value: value,
                isExpanded: true,
                isDense: true,
                items: [
                  for (final preference in LocalePreference.values)
                    DropdownMenuItem(
                      value: preference,
                      child: Text(labels[preference]!),
                    ),
                ],
                onChanged: (preference) {
                  if (preference != null) onChanged(preference);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact profile toolbar control using the existing locale preference callback.
class CompactLanguageSelector extends StatelessWidget {
  final LocalePreference value;
  final ValueChanged<LocalePreference> onChanged;

  const CompactLanguageSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final english =
        value == LocalePreference.english ||
        (value == LocalePreference.system && context.l10n.localeName == 'en');
    return ToggleButtons(
      key: const ValueKey('compact-language-selector'),
      isSelected: [!english, english],
      onPressed:
          (index) => onChanged(
            index == 0 ? LocalePreference.turkish : LocalePreference.english,
          ),
      constraints: const BoxConstraints(minWidth: 42, minHeight: 34),
      borderRadius: BorderRadius.circular(10),
      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      children: [
        Tooltip(message: context.l10n.languageTurkish, child: const Text('TR')),
        Tooltip(
          message: context.l10n.languageEnglish,
          child: const Text('ENG'),
        ),
      ],
    );
  }
}
