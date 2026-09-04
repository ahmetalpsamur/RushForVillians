import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/localization/locale_preference.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/l10n/app_localizations.dart';
import 'package:rush_for_villains/widgets/language_selector_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final locale in const [Locale('tr'), Locale('en')]) {
    for (final width in [320.0, 390.0]) {
      testWidgets(
        'golden: dil seçici ${locale.languageCode} ${width.toInt()} dp',
        (tester) async {
          tester.view.physicalSize = Size(width, 250);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            MaterialApp(
              debugShowCheckedModeBanner: false,
              locale: locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              theme: AppTheme.dark,
              home: Scaffold(
                body: SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        height: 215,
                        child: LanguageSelectorCard(
                          value:
                              locale.languageCode == 'en'
                                  ? LocalePreference.english
                                  : LocalePreference.turkish,
                          onChanged: ignoreLocalePreference,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();

          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              'goldens/language_selector_${locale.languageCode}_${width.toInt()}.png',
            ),
          );
        },
      );
    }
  }
}
