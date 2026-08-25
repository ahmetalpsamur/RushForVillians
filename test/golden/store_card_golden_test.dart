import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/item_rules.dart';
import 'package:rush_for_villains/features/store/xp_store_screen.dart';
import 'package:rush_for_villains/models/item.dart';

/// Mağaza ekipman kartının görsel denetimi.
///
/// Emülatör bu makinede çalışmıyor (Smart App Control), dolayısıyla arketip
/// rozetinin nadirlik rozetinin yanında düzgün durup durmadığı ancak golden
/// ile görülebiliyor. İki genişlik: en dar desteklenen telefon (320 dp) ve
/// yaygın telefon (390 dp).
///
/// Not: test ortamında gerçek font yok, yazılar dolu kutu olarak çiziliyor.
/// Hizalama ve taşma denetimi için avantaj; "yazı doğru mu" sorusunu
/// `store_screen_test.dart` içindeki `find.text` iddiaları cevaplıyor.
void main() {
  /// Aynı sınıfın, aynı kategorideki, aynı nadirlikteki dört kılıcı.
  ///
  /// Bölüm 3'ün sözü tam olarak bu kare: dördü de aynı görünmemeli.
  List<Item> sampleSwords() {
    final items =
        [
            for (final entity in Directory('lib/Items/swords').listSync())
              if (entity is File)
                buildItemFromAsset(
                  entity.path.replaceAll(Platform.pathSeparator, '/'),
                ),
          ].nonNulls.where((item) => !item.hasSignature).toList()
          ..sort((a, b) => a.id.compareTo(b.id));

    final commons =
        items
            .where((item) => item.requiredLevel <= 2)
            .map((item) => flavorForClass(item, 'Swordsman'))
            .toList();
    // Farklı arketiplerden birer örnek önce gelsin: kart karşılaştırması
    // ancak böyle anlamlı olur.
    final picked = <Item>[];
    for (final archetype in ItemArchetype.values) {
      final match = commons.where((item) => item.archetype == archetype);
      if (match.isNotEmpty) picked.add(match.first);
    }
    return picked;
  }

  Future<void> pump(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: XpStoreScreen(
          items: const [],
          equipment: sampleSwords(),
          coins: 5000,
          level: 10,
          ownedUpgradeIds: const [],
          streakFreezes: 0,
          extraWheelSpins: 0,
          xpBoostActive: false,
          onPurchase: (_) {},
          onPurchaseEquipment: (_) {},
        ),
      ),
    );
    await tester.pump();
  }

  for (final width in [320.0, 390.0]) {
    testWidgets('golden: mağaza ekipman kartı (${width.toInt()} dp)', (
      tester,
    ) async {
      await pump(tester, width);
      await expectLater(
        find.byType(XpStoreScreen),
        matchesGoldenFile('goldens/store_card_${width.toInt()}.png'),
      );
    });
  }

  testWidgets('dört arketip de örneklemde bulunuyor', (tester) async {
    // Golden'ın gerçekten dört farklı kartı gösterdiğini bağlar; örneklem
    // sessizce tek arketipe düşerse burada yakalanır.
    final picked = sampleSwords();
    expect(picked.map((item) => item.archetype).toSet(), hasLength(4));
    expect(
      picked.map((item) => item.buff.labels.join()).toSet(),
      hasLength(4),
      reason: 'aynı nadirlikteki dört kılıç aynı bonusu vermemeli',
    );
  });
}
