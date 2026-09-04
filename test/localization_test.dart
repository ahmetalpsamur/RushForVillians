import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/localization/app_formatters.dart';
import 'package:rush_for_villains/core/localization/locale_preference.dart';
import 'package:rush_for_villains/l10n/app_localizations.dart';
import 'package:rush_for_villains/widgets/language_selector_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('dil tercihi kaydedilir ve yeniden okunur', () async {
    SharedPreferences.setMockInitialValues({});

    expect(await LocalePreferenceStorage.load(), LocalePreference.system);
    await LocalePreferenceStorage.save(LocalePreference.english);
    expect(await LocalePreferenceStorage.load(), LocalePreference.english);
  });

  test('cihaz dili İngilizceyi algılar, desteklenmeyende Türkçeye düşer', () {
    expect(resolveSystemLocale(const [Locale('en', 'US')]), const Locale('en'));
    expect(resolveSystemLocale(const [Locale('de', 'DE')]), const Locale('tr'));
  });

  testWidgets('eksik İngilizce çeviri Türkçe şablon metnini kullanır', (
    tester,
  ) async {
    late String fallback;
    await tester.pumpWidget(
      _localizedApp(
        locale: const Locale('en'),
        child: Builder(
          builder: (context) {
            fallback = AppLocalizations.of(context).fallbackSafetyMessage;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(fallback, 'Türkçe yedek metin');
  });

  testWidgets('dil seçici seçimi anında bildirir', (tester) async {
    var selected = LocalePreference.system;
    await tester.pumpWidget(
      _localizedApp(
        locale: const Locale('en'),
        child: StatefulBuilder(
          builder:
              (context, setState) => Scaffold(
                body: LanguageSelectorCard(
                  value: selected,
                  onChanged: (value) => setState(() => selected = value),
                ),
              ),
        ),
      ),
    );

    expect(find.text('Language'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('language-selector')));
    await tester.pump();
    await tester.tap(find.text('Turkish').last);
    await tester.pump();

    expect(selected, LocalePreference.turkish);
  });

  testWidgets('sayı, tarih ve saat seçili dile göre biçimlenir', (
    tester,
  ) async {
    Future<List<String>> render(Locale locale) async {
      late List<String> values;
      await tester.pumpWidget(
        _localizedApp(
          locale: locale,
          child: Builder(
            builder: (context) {
              final date = DateTime(2026, 9, 4, 18, 5);
              values = [
                AppFormatters.integer(context, 1234),
                AppFormatters.longDate(context, date),
                AppFormatters.time(context, date),
              ];
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return values;
    }

    final turkish = await render(const Locale('tr'));
    final english = await render(const Locale('en'));

    expect(turkish.first, '1.234');
    expect(english.first, '1,234');
    expect(turkish[1], contains('Eylül'));
    expect(english[1], contains('September'));
    expect(turkish[2], '18:05');
    expect(english[2], contains('6:05'));
  });
}

Widget _localizedApp({required Locale locale, required Widget child}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: child,
  );
}
