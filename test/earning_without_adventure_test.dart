import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/game_constants.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/game_clock.dart';
import 'package:rush_for_villains/data/enemy_catalog.dart';
import 'package:rush_for_villains/features/adventure/adventure_screen.dart';
import 'package:rush_for_villains/features/root/root_shell.dart';
import 'package:rush_for_villains/models/adventure_quest.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_progress.dart';
import 'package:rush_for_villains/models/game_state.dart';
import 'package:rush_for_villains/models/user_profile.dart';
import 'package:rush_for_villains/services/item_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **Adım kazancı macera durumundan tamamen bağımsızdır.**
///
/// Bugün de öyle çalışıyor: `_onStepsReported` içinde para ve XP, macera
/// dalından **önce** işleniyor. Bu dosyanın işi o bağımsızlığı kilitlemek —
/// Aşama 4a savaş motorunu yeniden yazacak ve `_onStepsReported`'ın macera
/// dalına dokunacak; kazanç oraya kayarsa burası alarm verir.
///
/// Ayrıca macera seçmenin/bırakmanın günlük sayaçları sıfırlamadığını
/// doğruluyor: `_selectAdventure` eskiden elle yeni bir [DailyProgress]
/// kuruyordu ve `coinsEarned` 0'a düşüyordu — yani günlük coin tavanına
/// dayanan oyuncu macera seçerek tavanı sıfırlayabiliyordu.
const _avatar = AvatarProfile(
  name: 'Barca',
  age: 28,
  weight: 74,
  gender: 'Erkek',
  characterClass: 'SwordMan',
  characterAsset:
      'lib/Characters/SwordMan/'
      'Meshy_AI_image_674aae04-7cc0-4fa6-9009-620e1b9b800d_0.png',
);

/// Macera ekranı avatar ve düşman görsellerini çiziyor. Test paketinde
/// çözülemeyen bir görsel `ImageResourceService` üzerinden hata fırlatıp
/// testi düşürüyor; asıl ölçtüğümüz şey görsel değil, bu yüzden yalnızca
/// **görsel yükleme** hataları yutuluyor. Diğer hatalar olduğu gibi geçiyor.
void _ignoreImageErrors() {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    final library = details.library ?? '';
    if (library.contains('image resource service')) return;
    original?.call(details);
  };
  addTearDown(() => FlutterError.onError = original);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var shellSerial = 0;

  UserProfile makeProfile() => UserProfile(avatar: _avatar, level: 1);

  /// Macera ekranı sürekli animasyon içeriyor (düşman GIF'leri, geri sayım),
  /// bu yüzden `pumpAndSettle` orada hiçbir zaman durmuyor. Sabit sayıda kare
  /// ilerletmek yeterli ve deterministik.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  Future<void> pumpShell(
    WidgetTester tester, {
    required UserProfile profile,
    AdventureQuest? adventure,
  }) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    _ignoreImageErrors();
    SharedPreferences.setMockInitialValues({});
    ItemCatalog.reset(const []);
    addTearDown(() => ItemCatalog.reset());

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: RootShell(
          // Aynı test içinde ikinci kurulumun yeni bir state alması için;
          // gerekçe `inventory_test.dart` içinde.
          key: ValueKey('shell-${shellSerial++}'),
          avatar: _avatar,
          initialState: GameState(
            profile: profile,
            today: DailyProgress(date: GameClock.now()),
            adventure: adventure,
          ),
          onAvatarChanged: (_) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> walk(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await settle(tester);
  }

  Future<void> openAdventureTab(WidgetTester tester) async {
    await tester.tap(find.text('Macera').last);
    await settle(tester);
  }

  Future<void> openHomeTab(WidgetTester tester) async {
    await tester.tap(find.text('Ana Sayfa').last);
    await settle(tester);
  }

  /// [RootShell] macera seçimini ekranın geri çağrısı üzerinden tetikler.
  ///
  /// Düşman seçim akışını (hedef kaydırıcısı + kart + başlat düğmesi) elle
  /// sürmek yerine geri çağrı doğrudan çağrılıyor: burada test edilen şey
  /// **[RootShell]'in günün sayaçlarına ne yaptığı**, ekranın düzeni değil.
  Future<void> selectAdventure(
    WidgetTester tester, {
    int stepGoal = 20000,
    int startingSteps = 0,
  }) async {
    await openAdventureTab(tester);
    tester
        .widget<AdventureScreen>(find.byType(AdventureScreen))
        .onAdventureSelected(
          AdventureQuest(
            enemy: EnemyCatalog.enemies.first,
            stepGoal: stepGoal,
            startingSteps: startingSteps,
          ),
        );
    await settle(tester);
  }

  Future<void> dropAdventure(WidgetTester tester) async {
    await openAdventureTab(tester);
    tester
        .widget<AdventureScreen>(find.byType(AdventureScreen))
        .onChooseNewAdventure();
    await settle(tester);
  }

  group('macera yokken kazanç', () {
    testWidgets('macera olmadan adım para ve XP kazandırır', (tester) async {
      final profile = makeProfile();
      await pumpShell(tester, profile: profile);

      await walk(tester, '+5000 adım');

      expect(profile.coins, 5000 ~/ GameConstants.stepsPerCoin);
      expect(profile.totalSteps, 5000);
      // 5.000 adım = 2.500 XP; 1. seviyede 1.000 XP seviye atlatır.
      expect(profile.level, greaterThan(1));
    });

    testWidgets('macera varken kazanç aynı kalır', (tester) async {
      final without = makeProfile();
      await pumpShell(tester, profile: without);
      await walk(tester, '+5000 adım');

      final withQuest = makeProfile();
      await pumpShell(
        tester,
        profile: withQuest,
        // Hedef bilerek yüksek: düşman yenilirse ayrıca düşman XP'si gelir ve
        // karşılaştırma anlamını yitirir.
        adventure: AdventureQuest(
          enemy: EnemyCatalog.enemies.first,
          stepGoal: 20000,
        ),
      );
      await walk(tester, '+5000 adım');

      expect(withQuest.coins, without.coins);
      expect(withQuest.xp, without.xp);
      expect(withQuest.level, without.level);
    });

    testWidgets('macera yokken de seri ilerler', (tester) async {
      final profile = makeProfile();
      await pumpShell(tester, profile: profile);

      await walk(tester, '+5000 adım');

      expect(profile.streakDays, 1);
      expect(profile.lastActiveDay, isNotNull);
    });

    testWidgets('macera yokken de çark açılır', (tester) async {
      final profile = makeProfile();
      await pumpShell(tester, profile: profile);

      expect(
        5000,
        greaterThanOrEqualTo(GameConstants.dailyWheelUnlockSteps),
        reason: 'test verisi çark eşiğini geçmeli',
      );
      await walk(tester, '+5000 adım');

      await tester.tap(find.text('Günlük Çark'));
      await tester.pumpAndSettle();
      expect(find.text('Çarkı Çevir'), findsOneWidget);
    });
  });

  group('macera seçmek kazancı bozmaz', () {
    testWidgets('macera seçmek günlük coin sayacını sıfırlamaz', (
      tester,
    ) async {
      final profile = makeProfile();
      await pumpShell(tester, profile: profile);

      await walk(tester, '+5000 adım');
      final coinsBefore = profile.coins;
      expect(coinsBefore, greaterThan(0));

      await selectAdventure(tester, startingSteps: 5000);

      expect(profile.coins, coinsBefore);
    });

    testWidgets('macera seçmek günün adımlarını ve XP sayacını korur', (
      tester,
    ) async {
      final profile = makeProfile();
      await pumpShell(tester, profile: profile);

      await walk(tester, '+5000 adım');
      final steps = profile.totalSteps;
      final xp = profile.xp;
      final level = profile.level;

      await selectAdventure(tester, startingSteps: 5000);

      expect(profile.totalSteps, steps);
      expect(profile.xp, xp);
      expect(profile.level, level);
    });

    testWidgets('macera seçtikten sonra atılan adım da kazandırır', (
      tester,
    ) async {
      final profile = makeProfile();
      await pumpShell(tester, profile: profile);

      await selectAdventure(tester);
      await openHomeTab(tester);
      await walk(tester, '+5000 adım');

      expect(profile.coins, 5000 ~/ GameConstants.stepsPerCoin);
    });
  });

  group('çift sayma yok', () {
    testWidgets('macera seçip bırakmak aynı adımı ikinci kez ödemez', (
      tester,
    ) async {
      final profile = makeProfile();
      await pumpShell(tester, profile: profile);

      await walk(tester, '+5000 adım');
      final coins = profile.coins;
      final xp = profile.xp;
      final level = profile.level;
      final rewarded = profile.lastRewardedStepCount;

      await selectAdventure(tester, startingSteps: 5000);
      await dropAdventure(tester);

      expect(profile.coins, coins);
      expect(profile.xp, xp);
      expect(profile.level, level);
      expect(profile.lastRewardedStepCount, rewarded);
      expect(profile.totalSteps, 5000);
    });

    testWidgets('günlük coin tavanı macera seçilerek aşılamaz', (tester) async {
      final profile = makeProfile();
      await pumpShell(tester, profile: profile);

      // 20.000 adım = 400 coin, yani tavan.
      await walk(tester, '+20000 adım');
      expect(profile.coins, GameConstants.maxDailyStepCoins);

      await selectAdventure(tester, startingSteps: 20000);
      await openHomeTab(tester);
      await walk(tester, '+20000 adım');

      expect(
        profile.coins,
        GameConstants.maxDailyStepCoins,
        reason: 'macera seçmek günlük tavanı sıfırlamamalı',
      );
    });
  });

  group('günün sayaçları', () {
    test('withStepGoal ilerlemenin tamamını taşır', () {
      final today = DailyProgress(
        date: DateTime(2026, 8, 20, 10),
        steps: 4200,
        stepGoal: 6000,
        coinsEarned: 84,
        xpEarned: 2100,
      );

      final updated = today.withStepGoal(12000);

      expect(updated.stepGoal, 12000);
      expect(updated.steps, 4200);
      expect(updated.date, today.date);
      expect(updated.coinsEarned, 84);
      expect(updated.xpEarned, 2100);
    });

    test('tavan doluluğu verilen tavana göre ölçülür', () {
      final today = DailyProgress(
        date: DateTime(2026, 8, 20, 10),
        coinsEarned: GameConstants.maxDailyStepCoins,
      );

      expect(today.coinCapReached, isTrue);
      // Kuşanılan ekipman tavanı büyütmüşse henüz dolmamış demektir.
      expect(
        today.coinCapReachedAt(GameConstants.maxDailyStepCoins + 50),
        isFalse,
      );
    });
  });
}
