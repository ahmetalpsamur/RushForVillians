import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/equipped_buffs.dart';
import 'package:rush_for_villains/features/inventory/inventory_screen.dart';
import 'package:rush_for_villains/models/item_effect.dart';
import 'package:rush_for_villains/models/streak_stat_bonuses.dart';

/// Seri bonusu bölümünün görsel denetimi (Bölüm 5C).
///
/// Emülatör bu makinede çalışmıyor; bölümün kart içine sığıp sığmadığı,
/// "tavan" etiketinin okunur kalıp kalmadığı ve satırların dar ekranda
/// taşmadığı ancak golden ile görülebiliyor.
///
/// Test ortamında gerçek font yok, yazılar dolu kutu çiziliyor — bu hizalama
/// denetimi için **en kötü durum**. Metnin doğruluğu ayrıca `find.text` ile
/// bağlanıyor.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Uzun bir serinin tipik birikimi: dört stat, biri tavanda.
  StreakStatBonuses buildBonuses() {
    var bonuses = StreakStatBonuses.empty;
    for (var i = 0; i < StreakStatBonuses.maxDaysPerStat; i++) {
      bonuses = bonuses.withGrant(ItemStat.critDamage);
    }
    for (var i = 0; i < 11; i++) {
      bonuses = bonuses.withGrant(ItemStat.attack);
    }
    for (var i = 0; i < 7; i++) {
      bonuses = bonuses.withGrant(ItemStat.defense);
    }
    for (var i = 0; i < 3; i++) {
      bonuses = bonuses.withGrant(ItemStat.dodge);
    }
    return bonuses;
  }

  Future<void> pumpPanel(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: CharacterPowerPanel(
              buffs: EquippedBuffs.from(const []),
              equippedCount: 2,
              slotCount: 4,
              streakBonuses: buildBonuses(),
              streakDays: 46,
            ),
          ),
        ),
      ),
    );
    // Sonsuz tekrar eden animasyon yok ama sabit kare dizisi golden'ı
    // tekrarlanabilir kılıyor (proje deseni).
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  for (final width in [320.0, 390.0]) {
    testWidgets('seri bonusu paneli ${width.toInt()} dp', (tester) async {
      await pumpPanel(tester, width);

      expect(find.text('Seri Bonusu'), findsOneWidget);
      // 25 + 11 + 7 + 3 = 46 gün → +%46
      expect(find.text('toplam +%46'), findsOneWidget);
      // Tavana ulaşan stat işaretli olmalı.
      expect(find.text('tavan'), findsOneWidget);

      await expectLater(
        find.byType(CharacterPowerPanel),
        matchesGoldenFile('goldens/streak_bonus_${width.toInt()}.png'),
      );
    });
  }

  testWidgets('bonus yokken bölüm hiç çıkmaz', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: SingleChildScrollView(
            child: CharacterPowerPanel(
              buffs: EquippedBuffs.from(const []),
              equippedCount: 0,
              slotCount: 4,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Seri Bonusu'), findsNothing);
  });
}
