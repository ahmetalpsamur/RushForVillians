import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/item_rules.dart';
import 'package:rush_for_villains/l10n/app_localizations.dart';
import 'package:rush_for_villains/l10n/content_localizations.dart';
import 'package:rush_for_villains/models/item.dart';
import 'package:rush_for_villains/services/item_catalog.dart';
import 'package:rush_for_villains/widgets/dropped_item_card.dart';

/// Düşen eşya kartının görsel denetimi (Bölüm D / Faz 1).
///
/// Kart iki yerde birden kullanılıyor — normal macera zaferi ve Sonsuz Koşu
/// sonucu — ve ikisinin de tek dili olması isteniyordu. Buradaki soru: ad
/// uzadığında kart taşıyor mu, nadirlik rozeti adı eziyor mu.
///
/// Dört kare: 320 ve 390 dp × Türkçe ve İngilizce. En uzun ad kasıtlı olarak
/// seçiliyor; ortalama bir ad hiçbir şey kanıtlamaz.
///
/// Not: test ortamında gerçek font yok, yazılar dolu kutu çiziliyor. Taşma
/// ve hizalama için avantaj; metnin doğruluğunu `find.text` ayrıca bağlıyor.
void main() {
  /// Katalog `AssetManifest` istiyor ve test ortamında kurulu değil;
  /// dosya sisteminden okunup `ItemCatalog.reset` ile besleniyor.
  List<Item> loadItems() {
    final items = <Item>[];
    for (final dir in Directory('lib/Items').listSync()) {
      if (dir is! Directory) continue;
      for (final file in dir.listSync()) {
        if (file is! File || !file.path.endsWith('.png')) continue;
        final item = buildItemFromAsset(
          file.path.replaceAll(Platform.pathSeparator, '/'),
        );
        if (item != null) items.add(item);
      }
    }
    return items;
  }

  late List<Item> catalog;

  setUp(() {
    catalog = loadItems();
    ItemCatalog.reset(catalog);
    addTearDown(ItemCatalog.reset);
  });

  /// Seçilen dildeki **en uzun** eşya adını taşıyan item.
  Future<Item> longestNamed(Locale locale) async {
    final l10n = await AppLocalizations.delegate.load(locale);
    var best = catalog.first;
    var bestLength = 0;
    for (final item in catalog) {
      final length = l10n.itemName(item).length;
      if (length > bestLength) {
        bestLength = length;
        best = item;
      }
    }
    return best;
  }

  Future<void> pump(
    WidgetTester tester,
    double width,
    Locale locale,
    Item item,
  ) async {
    tester.view.physicalSize = Size(width, 220);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Builder(
                builder: (context) => DroppedItemCard(
                  itemId: item.id,
                  label: AppLocalizations.of(context).droppedItemLabel,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  for (final locale in const [Locale('tr'), Locale('en')]) {
    for (final width in const [320.0, 390.0]) {
      testWidgets(
        'golden: düşen eşya kartı (${locale.languageCode} ${width.toInt()} dp)',
        (tester) async {
          final item = await longestNamed(locale);
          await pump(tester, width, locale, item);
          await expectLater(
            find.byType(DroppedItemCard),
            matchesGoldenFile(
              'goldens/dropped_item_${locale.languageCode}_${width.toInt()}.png',
            ),
          );
        },
      );

      testWidgets(
        'taşma yok (${locale.languageCode} ${width.toInt()} dp)',
        (tester) async {
          final errors = <String>[];
          final previous = FlutterError.onError;
          FlutterError.onError = (details) {
            // Taşan bir düzen her karede yüzlerce hata üretir; yalnızca ilk
            // ikisi raporlanır (§9 test deseni).
            if (errors.length < 2) errors.add(details.exceptionAsString());
          };
          addTearDown(() => FlutterError.onError = previous);

          final item = await longestNamed(locale);
          await pump(tester, width, locale, item);

          expect(errors, isEmpty, reason: errors.join(' | '));
        },
      );
    }
  }

  testWidgets('katalogda olmayan kimlik hiçbir şey çizmez', (tester) async {
    // Katalogdan kalkmış bir kimlikte uydurma ad göstermektense susmak yeğ.
    await pump(tester, 390, const Locale('tr'), catalog.first);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: const [AppLocalizations.delegate],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: DroppedItemCard(itemId: 'yok/boyle_bir_sey', label: 'X'),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('dropped-item-card')), findsNothing);
  });
}
