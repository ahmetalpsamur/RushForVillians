import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/data/reward_catalog.dart';
import 'package:rush_for_villains/features/rewards/rewards_screen.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/collection_reward.dart';
import 'package:rush_for_villains/models/daily_progress.dart';
import 'package:rush_for_villains/models/reward_rarity.dart';
import 'package:rush_for_villains/models/user_profile.dart';
import 'package:rush_for_villains/services/reward_engine.dart';

const _avatar = AvatarProfile(
  name: 'Test',
  age: 25,
  weight: 70,
  gender: 'Erkek',
  characterClass: 'SwordMan',
  characterAsset: 'lib/Characters/SwordMan/test.png',
);

void main() {
  test('1.244 PNG bire bir, benzersiz katalog kaydına bağlı', () {
    final files =
        Directory('lib/Rewards')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.toLowerCase().endsWith('.png'))
            .toList();
    final rewards = RewardCatalog.all;

    expect(files, hasLength(1244));
    expect(rewards, hasLength(1244));
    expect(rewards.map((reward) => reward.id).toSet(), hasLength(1244));
    expect(rewards.map((reward) => reward.name).toSet(), hasLength(1244));
    expect(rewards.map((reward) => reward.assetPath).toSet(), hasLength(1244));
    expect(
      rewards.every((reward) => File(reward.assetPath).existsSync()),
      isTrue,
    );
  });

  test('motor şartı ilk kez açar ve kayıt turunda tarih/favori korunur', () {
    final profile = UserProfile(avatar: _avatar, totalSteps: 2000000);
    final stats = RewardEngine.statistics(
      profile: profile,
      today: DailyProgress(date: DateTime(2026, 8, 27)),
      history: const [],
    );
    final now = DateTime.utc(2026, 8, 27, 12);

    final first = RewardEngine.evaluate(
      profile: profile,
      statistics: stats,
      now: now,
    );
    final second = RewardEngine.evaluate(
      profile: profile,
      statistics: stats,
      now: now.add(const Duration(minutes: 1)),
    );

    expect(first, isNotEmpty);
    expect(second, isEmpty);
    final id = first.first.id;
    expect(RewardEngine.togglePinned(profile, id), isTrue);

    final restored = UserProfile.fromJson(profile.toJson(), avatar: _avatar);
    expect(restored.earnedRewardDates[id], now);
    expect(restored.pinnedRewardIds, contains(id));
  });

  testWidgets('ekran özet, kilit, vitrin ve detay deneyimini gösterir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final rewards = RewardCatalog.all.take(2).toList();
    final earnedAt = DateTime.utc(2026, 8, 24);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: RewardsScreen(
          rewards: rewards,
          statistics: const RewardStatistics(),
          earnedRewardDates: {rewards.first.id: earnedAt},
          pinnedRewardIds: const [],
          onTogglePinned: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('1 / 2 ödül kazanıldı'), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsOneWidget);

    await tester.tap(find.text(rewards.first.name));
    await tester.pumpAndSettle();
    expect(find.textContaining('24 Ağustos 2026'), findsOneWidget);
    await tester.tap(find.byTooltip('Kapat'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Vitrin'));
    await tester.pumpAndSettle();
    expect(find.text(rewards.first.name), findsOneWidget);
    expect(find.text(rewards.last.name), findsNothing);
  });

  testWidgets('yüklenemeyen ödül görseli vitrini çökertmez', (tester) async {
    // Görsel yüklenemeyince Flutter `Image`'ı **boyutsuz bir `Stack`**'e
    // sarıyor; `ListTile.leading` o zaman bütün genişliği yiyor ve
    // "Leading widget consumes the entire tile width" assertion'ı atıyor.
    // Cihazda bozuk/eksik bir asset bütün Vitrin sekmesini kırmızıya çevirir.
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const broken = CollectionReward(
      id: 'broken_asset_reward',
      name: 'Kayıp Ödül',
      description: 'Görseli bulunamayan ödül.',
      requirement: '1 villain yen',
      conditionType: RewardConditionType.villainsDefeated,
      target: 1,
      assetPath: 'lib/Rewards/Unsorted/__bulunmayan_dosya__.png',
      category: 'Unsorted',
      subcategory: 'Unsorted',
      rarity: RewardRarity.common,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: RewardsScreen(
          rewards: const [broken],
          statistics: const RewardStatistics(),
          earnedRewardDates: {broken.id: DateTime.utc(2026, 8, 24)},
          pinnedRewardIds: const [],
          onTogglePinned: (_) {},
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Vitrin'));
    await tester.pumpAndSettle();

    expect(find.text('Kayıp Ödül'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('boş vitrinde yönlendirici mesaj bulunur', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: RewardsScreen(
          rewards: RewardCatalog.all.take(2).toList(),
          statistics: const RewardStatistics(),
          earnedRewardDates: const {},
          pinnedRewardIds: const [],
          onTogglePinned: (_) {},
        ),
      ),
    );
    await tester.tap(find.text('Vitrin'));
    await tester.pumpAndSettle();
    expect(find.textContaining('İlk villain’ını yenerek'), findsOneWidget);
  });

  testWidgets('1.244 kart aynı anda render edilmez ve dar ekranda taşmaz', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final errors = <FlutterErrorDetails>[];
    final oldHandler = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = oldHandler);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: RewardsScreen(
          rewards: RewardCatalog.all,
          statistics: const RewardStatistics(),
          earnedRewardDates: const {},
          pinnedRewardIds: const [],
          onTogglePinned: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Image).evaluate().length, lessThan(30));
    expect(errors, isEmpty);
  });
}
