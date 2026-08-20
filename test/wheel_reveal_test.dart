import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/item_rules.dart';
import 'package:rush_for_villains/core/utils/wheel_rewards.dart';
import 'package:rush_for_villains/features/wheel/daily_wheel_screen.dart';
import 'package:rush_for_villains/models/item.dart';
import 'package:rush_for_villains/models/reward_rarity.dart';
import 'package:rush_for_villains/models/wheel_reward.dart';
import 'package:rush_for_villains/widgets/reward_reveal.dart';

/// Çarkın **açılış** tarafı: kademe kuralları, gösterim ve atlanabilirlik.
///
/// Hak yönetimi ve havuz kuralları `daily_wheel_test.dart` ile
/// `wheel_rewards_test.dart` içinde; burada oyuncunun hissettiği şey test
/// ediliyor.
void main() {
  final common = buildItemFromAsset('lib/Items/swords/sword.png')!;
  final uncommon = buildItemFromAsset('lib/Items/swords/pine_sword.png')!;
  final rare = buildItemFromAsset('lib/Items/swords/aqua_sword.png')!;
  final epic = buildItemFromAsset('lib/Items/swords/holy_greatsword.png')!;
  final legendary = buildItemFromAsset('lib/Items/swords/dragons_hook.png')!;

  group('açılış kademesi', () {
    test('nadirlik kademeyi belirler', () {
      expect(revealTierFor(const WheelReward.xp(50)), WheelRevealTier.plain);
      expect(revealTierFor(WheelReward.item(common)), WheelRevealTier.plain);
      expect(revealTierFor(WheelReward.item(uncommon)), WheelRevealTier.bright);
      expect(
        revealTierFor(WheelReward.item(rare)),
        WheelRevealTier.spectacular,
      );
      // Çark bugün epik/efsanevi vermiyor (GD19) ama kural onları da
      // kapsıyor: ödül havuzu genişlerse kademe kendiliğinden doğru çalışır.
      expect(
        revealTierFor(WheelReward.item(epic)),
        WheelRevealTier.spectacular,
      );
      expect(
        revealTierFor(WheelReward.item(legendary)),
        WheelRevealTier.spectacular,
      );
    });

    test('kademe yükseldikçe bekleme uzar', () {
      final plain = spinDurationFor(WheelRevealTier.plain);
      final bright = spinDurationFor(WheelRevealTier.bright);
      final spectacular = spinDurationFor(WheelRevealTier.spectacular);

      expect(bright, greaterThan(plain));
      expect(spectacular, greaterThan(bright));
      // Beklenti inşası hoş, ama oyuncuyu bekletmek değil: en uzun çevirme
      // beş saniyenin altında kalmalı.
      expect(spectacular.inMilliseconds, lessThan(5000));
    });

    test('kademe yükseldikçe açılış uzar', () {
      expect(
        revealDurationFor(WheelRevealTier.spectacular),
        greaterThan(revealDurationFor(WheelRevealTier.bright)),
      );
      expect(
        revealDurationFor(WheelRevealTier.bright),
        greaterThan(revealDurationFor(WheelRevealTier.plain)),
      );
    });

    test('parçacık sayısı sınırlı ve sıradan ödülde sıfır', () {
      expect(particleCountFor(WheelRevealTier.plain), 0);
      expect(particleCountFor(WheelRevealTier.bright), greaterThan(0));
      for (final tier in WheelRevealTier.values) {
        expect(
          particleCountFor(tier),
          lessThanOrEqualTo(48),
          reason: 'düşük seviye telefonda kare süresi şişmemeli',
        );
      }
    });
  });

  group('açılış katmanı', () {
    Future<AnimationController> pumpOverlay(
      WidgetTester tester, {
      required WheelReward reward,
      VoidCallback? onTap,
      double progress = 1,
    }) async {
      final controller = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 400),
      )..value = progress;
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: RewardRevealOverlay(
              reward: reward,
              tier: revealTierFor(reward),
              animation: controller,
              seed: 42,
              onTap: onTap ?? () {},
            ),
          ),
        ),
      );
      await tester.pump();
      return controller;
    }

    testWidgets('item ödülü adını, nadirliğini ve etkilerini gösterir', (
      tester,
    ) async {
      await pumpOverlay(tester, reward: WheelReward.item(rare));

      expect(find.text(rare.name), findsOneWidget);
      expect(find.text(rare.rarity.label), findsOneWidget);
      // Etkiler okunabilir olmalı; oyuncu ne kazandığını görsün.
      expect(find.text(rare.buff.labels.first), findsOneWidget);
    });

    testWidgets('imzalı itemin kural cümlesi de açılışta görünür', (
      tester,
    ) async {
      expect(rare.lore, isNotNull, reason: 'test verisi imzalı olmalı');
      await pumpOverlay(tester, reward: WheelReward.item(rare));

      expect(find.text(rare.lore!), findsOneWidget);
    });

    testWidgets('XP ödülü miktarıyla gösterilir', (tester) async {
      await pumpOverlay(tester, reward: const WheelReward.xp(150));

      expect(find.text('+150 XP'), findsOneWidget);
    });

    testWidgets('nadirlik kademesi başlığa yansır', (tester) async {
      await pumpOverlay(tester, reward: WheelReward.item(common));
      expect(find.text('Kazandın'), findsOneWidget);

      await pumpOverlay(tester, reward: WheelReward.item(rare));
      expect(find.text('NADİR ÖDÜL!'), findsOneWidget);
    });

    testWidgets('dokunmak geri çağrıyı tetikler', (tester) async {
      var taps = 0;
      await pumpOverlay(
        tester,
        reward: WheelReward.item(rare),
        onTap: () => taps++,
      );

      await tester.tap(find.byType(RewardRevealOverlay));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('animasyon başındayken de çökmez', (tester) async {
      // 0 ilerlemede ölçek ve opaklık sıfıra yakın; hesapların hiçbiri
      // taşmamalı.
      await pumpOverlay(tester, reward: WheelReward.item(rare), progress: 0);

      expect(tester.takeException(), isNull);
    });
  });

  group('çark akışı', () {
    Future<List<WheelReward>> pumpWheel(
      WidgetTester tester, {
      int seed = 12345,
      int level = 1,
      List<Item> equipment = const [],
    }) async {
      final results = <WheelReward>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: DailyWheelScreen(
            key: UniqueKey(),
            alreadySpunToday: false,
            seed: seed,
            level: level,
            equipment: equipment,
            onSpinResult: results.add,
          ),
        ),
      );
      await tester.pump();
      return results;
    }

    testWidgets('sonuç kartı ancak açılış kapatılınca çıkar', (tester) async {
      await pumpWheel(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Çarkı Çevir'));
      await tester.pumpAndSettle();

      // Açılış ekranda, kalıcı kayıt henüz yok.
      expect(find.byType(RewardRevealOverlay), findsOneWidget);
      expect(find.textContaining('Kazandın:'), findsNothing);

      await tester.tap(find.byType(RewardRevealOverlay));
      await tester.pumpAndSettle();

      expect(find.byType(RewardRevealOverlay), findsNothing);
      expect(find.textContaining('Kazandın:'), findsOneWidget);
    });

    testWidgets('dönerken dokunmak animasyonu geçer', (tester) async {
      final results = await pumpWheel(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Çarkı Çevir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      // Dönerken atlama ipucu görünür ve düğme kilitlidir.
      expect(find.text('Dokunarak geçebilirsin'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Çevriliyor...'),
      );
      expect(button.onPressed, isNull);

      await tester.tap(find.text('Dokunarak geçebilirsin'));
      await tester.pumpAndSettle();

      // Atlama sonucu değiştirmez, yalnızca bekleyişi kısaltır.
      expect(results, hasLength(1));
      expect(find.byType(RewardRevealOverlay), findsOneWidget);
    });

    testWidgets('atlanan çevirme ile beklenen çevirme aynı sonucu verir', (
      tester,
    ) async {
      final patient = await pumpWheel(tester, seed: 8080);
      await tester.tap(find.widgetWithText(FilledButton, 'Çarkı Çevir'));
      await tester.pumpAndSettle();

      final skipped = await pumpWheel(tester, seed: 8080);
      await tester.tap(find.widgetWithText(FilledButton, 'Çarkı Çevir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tap(find.text('Dokunarak geçebilirsin'));
      await tester.pumpAndSettle();

      expect(skipped.single.label, patient.single.label);
    });

    testWidgets('çark yüzeyi RepaintBoundary içinde', (tester) async {
      // Dönme sırasında yüzeyin yeniden boyanmaması buna bağlı.
      await pumpWheel(tester);

      expect(
        find.descendant(
          of: find.byType(DailyWheelScreen),
          matching: find.byType(RepaintBoundary),
        ),
        findsWidgets,
      );
    });
  });
}
