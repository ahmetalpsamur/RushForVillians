import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/features/daily_progress/daily_progress_dialog.dart';
import 'package:rush_for_villains/l10n/app_localizations.dart';
import '../../test/daily_engagement_test.dart' show avatar;

void main() {
  for (final wheel in [false, true]) {
    testWidgets('preview wheel=$wheel', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.runAsync(() async {
        final font = await File(r'C:\Windows\Fonts\segoeui.ttf').readAsBytes();
        await (FontLoader('Roboto')..addFont(Future.value(ByteData.sublistView(font)))).load();
        final icons = ByteData.sublistView(await File('C:/Users/ASUS/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf').readAsBytes());
        await (FontLoader('MaterialIcons')..addFont(Future.value(icons))).load();
      });
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(key: key, child: MaterialApp(
        debugShowCheckedModeBanner: false, theme: AppTheme.dark, locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(appBar: AppBar(title: const Text('Rush for Villains')),
          body: Builder(builder: (context) => Center(child: FilledButton(
            onPressed: () => showDailyProgressDialog(context, wheel: wheel, streakDays: 7, avatar: avatar),
            child: const Text('Preview'))))))));
      await tester.tap(find.text('Preview'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      for (var i = 0; i < 8; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.runAsync(() async {
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('output/daily-progress/${wheel ? 'wheel' : 'streak'}-tr.png').writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
