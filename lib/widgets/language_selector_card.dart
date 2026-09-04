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
