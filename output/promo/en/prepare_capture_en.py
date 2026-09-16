from pathlib import Path
HERE=Path(__file__).resolve().parent
source=(HERE.parent/'capture_test.dart').read_text(encoding='utf-8')
source="import 'package:rush_for_villains/l10n/app_localizations.dart';\n"+source
source=source.replace('MaterialApp(debugShowCheckedModeBanner: false,', '''MaterialApp(debugShowCheckedModeBanner: false,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,''')
source=source.replace("find.text('Profil')", "find.text('Profile')")
source=source.replace("find.text('Demirci')", "find.text('Blacksmith')")
(HERE/'screens').mkdir(exist_ok=True)
(HERE/'capture_en_test.dart').write_text(source,encoding='utf-8')
