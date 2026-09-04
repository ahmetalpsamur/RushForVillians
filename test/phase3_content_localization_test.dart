import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/data/enemy_catalog.dart';
import 'package:rush_for_villains/data/pet_sayings.dart';
import 'package:rush_for_villains/data/reward_catalog.dart';
import 'package:rush_for_villains/features/rewards/rewards_screen.dart';
import 'package:rush_for_villains/features/tutorial/guide_selection_screen.dart';
import 'package:rush_for_villains/features/tutorial/tutorial_guide.dart';
import 'package:rush_for_villains/l10n/app_localizations.dart';
import 'package:rush_for_villains/l10n/app_localizations_en.dart';
import 'package:rush_for_villains/l10n/content_localizations.dart';
import 'package:rush_for_villains/models/collection_reward.dart';
import 'package:rush_for_villains/models/tutorial_guide_variant.dart';

void main() {
  test('English content resolves from stable catalog IDs', () {
    final l10n = AppLocalizationsEn();
    final enemy = EnemyCatalog.byId('ash_guardian')!;

    expect(l10n.enemyName(enemy), 'Ash Guardian');
    expect(l10n.enemyQuest(enemy), contains('500 steps'));
    expect(l10n.enemyArchetypeName(enemy.archetype), 'Tank');
    expect(l10n.characterClassName('Knight'), 'Royal Knight');
    expect(l10n.adventureDuration(const Duration(minutes: 5)), '5 minutes');
    final reward = RewardCatalog.all.first;
    expect(l10n.collectionRewardName(reward), contains('Trophy'));
    expect(l10n.collectionRewardRequirement(reward), contains('Walk'));
    expect(
      l10n.guideDescription(TutorialGuideVariant.pinky),
      contains('quick'),
    );
    expect(
      l10n.petPool(
        const PetSituation(context: PetContext.home, wheelAvailable: true),
      ),
      contains(l10n.petHomeWheelReady1),
    );
    expect(
      TutorialGuideFrame.forStep(TutorialGuideStep.enemySelected, l10n).message,
      startsWith('Good choice!'),
    );
  });

  testWidgets('English rewards content at 390 dp', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RewardsScreen(
          rewards: RewardCatalog.all.take(6).toList(),
          statistics: const RewardStatistics(),
          earnedRewardDates: const {},
          pinnedRewardIds: const [],
          onTogglePinned: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Rewards'), findsOneWidget);
    expect(find.textContaining('Trophy'), findsWidgets);
    expect(find.textContaining('Toplam'), findsNothing);
    await expectLater(
      find.byType(RewardsScreen),
      matchesGoldenFile('golden/goldens/phase3_rewards_en_390.png'),
    );
  });

  testWidgets('English companion selection content at 390 dp', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GuideSelectionScreen(onSelected: (_) {}),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Calm, brave, and dependable.'), findsOneWidget);
    expect(find.text('Cheerful, quick, and curious.'), findsOneWidget);
    await expectLater(
      find.byType(GuideSelectionScreen),
      matchesGoldenFile('golden/goldens/phase3_guides_en_390.png'),
    );
  });
}
