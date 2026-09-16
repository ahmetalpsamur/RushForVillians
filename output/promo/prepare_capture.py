from pathlib import Path

root = Path(__file__).resolve().parents[2]
source = (root/'test/golden/forge_golden_test.dart').read_text(encoding='utf-8')
source = "import 'dart:io';\nimport 'dart:typed_data';\nimport 'package:flutter/services.dart';\n" + source
source = source.replace("characterClass: 'SwordMan'", "characterClass: 'Knight'")
source = source.replace('lib/Items/swords/sword.png', 'lib/Items/swords/aqua_sword.png').replace('lib/Items/shields/round_shield.png', 'lib/Items/shields/blue_round_shield.png')
source = source.replace("lib/Characters/SwordMan/test.png", "lib/All_Assets/Avatars/Classes/Characters(100x100 split)/Knight/Knight/Knight_Idle.gif")
source = source.replace('await expectLater(', 'tester.view.physicalSize = Size(width, 844);\n      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));\n      await tester.pumpAndSettle();\n      await expectLater(')
source = source.replace('[320.0, 390.0]', '[390.0]')
source = source.replace("'goldens/forge_${width.toInt()}.png'", "'screens/forge.png'")
source = source.replace("matchesGoldenFile('screens/forge.png'),\n      );", "matchesGoldenFile('screens/forge.png'),\n      );\n      await tester.pumpWidget(const SizedBox.shrink());\n      await tester.pump(const Duration(seconds: 3));")
source = source.replace('theme: AppTheme.dark,', "theme: AppTheme.dark.copyWith(textTheme: AppTheme.dark.textTheme.apply(fontFamily: 'Roboto')),")
source = source.replace('MaterialApp(', 'MaterialApp(debugShowCheckedModeBanner: false,')
source = source.replace("expect(find.textContaining('3/3 adet'), findsOneWidget);", "expect(find.text('Demirci'), findsOneWidget);")
source = source.replace("expect(find.textContaining('1/3 adet'), findsOneWidget);", '')
source = source.replace("expect(find.textContaining('en üst nadirlik'), findsWidgets);", '')
source = source.replace('TestWidgetsFlutterBinding.ensureInitialized();', '''TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final entry in {'Roboto': 'roboto-regular.ttf', 'MaterialIcons': 'materialicons-regular.otf'}.entries) {
      final loader = FontLoader(entry.key);
      loader.addFont(File('C:/Users/ASUS/flutter/bin/cache/artifacts/material_fonts/${entry.value}').readAsBytes().then((bytes) => ByteData.sublistView(bytes)));
      await loader.load();
    }
  });''')
(root/'output/promo/capture_test.dart').write_text(source, encoding='utf-8')
(root/'output/promo/screens').mkdir(exist_ok=True)
