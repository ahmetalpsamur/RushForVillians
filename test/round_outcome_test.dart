import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/game_clock.dart';
import 'package:rush_for_villains/data/enemy_catalog.dart';
import 'package:rush_for_villains/features/adventure/adventure_screen.dart';
import 'package:rush_for_villains/features/root/root_shell.dart';
import 'package:rush_for_villains/l10n/app_localizations.dart';
import 'package:rush_for_villains/models/adventure_quest.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_progress.dart';
import 'package:rush_for_villains/models/game_state.dart';
import 'package:rush_for_villains/models/user_profile.dart';
import 'package:rush_for_villains/services/item_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Round sonucu bildirimi (Bölüm D / Faz 1, İş 3).
///
/// Kapatılan boşluk: bir round **süresi dolarak** kazanıldığında hiçbir
/// bildirim çıkmıyordu. Mükemmel round duyurusu vardı ama o yalnızca round
/// erken bitince görünüyor; sahnedeki animasyonlu hasar sayısı ise yalnızca
/// macera ekranı açıkken oynuyor. Yani oyuncu vurduğu hasarı ve düşmanın
/// kalan canını hiçbir yerde okuyamıyordu.
///
/// Üç kural testle bağlı: bildirim **çıkıyor**, içinde hasar + kalan can
/// var, ve zafer/yenilgi roundunda **çıkmıyor** (ikisinin tam ekran perdesi
/// var, üstüne kutu koymak gürültü olurdu).
const _avatar = AvatarProfile(
  name: 'Barca',
  age: 28,
  weight: 74,
  gender: 'Erkek',
  characterClass: 'Swordsman',
  characterAsset:
      'lib/All_Assets/Avatars/Classes/Characters(100x100 split)/Swordsman/Swordsman/Swordsman_Walk.gif',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var shellSerial = 0;
  late DateTime now;

  setUp(() {
    GameClock.reset();
    now = DateTime(2026, 9, 1, 12);
    GameClock.useSource(() => now);
  });
  tearDown(GameClock.reset);

  Future<void> pumpShell(
    WidgetTester tester, {
    required UserProfile profile,
    required AdventureQuest adventure,
    Locale locale = const Locale('tr'),
  }) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    ItemCatalog.reset(const []);
    addTearDown(ItemCatalog.reset);

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
        home: RootShell(
          key: ValueKey('round-shell-${shellSerial++}'),
          avatar: _avatar,
          initialState: GameState(
            profile: profile,
            today: DailyProgress(
              date: GameClock.now(),
              stepGoal: adventure.stepGoal,
            ),
            adventure: adventure,
          ),
          onAvatarChanged: (_) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> addSteps(WidgetTester tester, int amount) async {
    tester
        .widget<AdventureScreen>(find.byType(AdventureScreen))
        .onSimulateSteps!(amount);
    await tester.pump();
    await tester.pump();
  }

  AdventureQuest quest({int stepGoal = 10000}) => AdventureQuest(
    // Yüksek kademe + uzun hedef: tek roundda devrilmesin, yoksa zafer
    // perdesi açılır ve bildirim bilerek bastırılır.
    enemy: EnemyCatalog.byId('lord_of_last_seal')!,
    stepGoal: stepGoal,
    startedAt: DateTime(2026, 9, 1, 12),
  );

  testWidgets('round kazanılınca hasar ve kalan can bildirilir', (
    tester,
  ) async {
    final adventure = quest();
    await pumpShell(
      tester,
      profile: UserProfile(avatar: _avatar, level: 5),
      adventure: adventure,
    );

    await addSteps(tester, adventure.roundTargetSteps);

    expect(
      adventure.isEnemyDefeated,
      isFalse,
      reason: 'ölçüm için savaş sürmeli',
    );
    expect(find.byKey(const ValueKey('round-outcome-notice')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('round-outcome-headline')),
      findsOneWidget,
    );
    final health = tester.widget<Text>(
      find.byKey(const ValueKey('round-outcome-enemy-health')),
    );
    // Kalan can gerçekten yazıyor: düşmanın güncel canı metinde geçmeli.
    expect(health.data, contains('${adventure.enemyHealth}'));
  });

  testWidgets('bildirim erken kaybolmuyor', (tester) async {
    // Bu oyun yürürken oynanıyor; telefona bakış gecikmeli. Varsayılan
    // 4 saniyelik SnackBar bu yüzden uzatıldı.
    final adventure = quest();
    await pumpShell(
      tester,
      profile: UserProfile(avatar: _avatar, level: 5),
      adventure: adventure,
    );
    await addSteps(tester, adventure.roundTargetSteps);

    await tester.pump(const Duration(seconds: 5));
    expect(
      find.byKey(const ValueKey('round-outcome-notice')),
      findsOneWidget,
      reason: 'beş saniye sonra hâlâ okunabilir olmalı',
    );
  });

  testWidgets('zafer roundunda bildirim bastırılır', (tester) async {
    // Zaferin kendi tam ekran perdesi var.
    final adventure = quest(stepGoal: 1000);
    await pumpShell(
      tester,
      // Yüksek seviye: ilk roundda devirsin.
      profile: UserProfile(avatar: _avatar, level: 60),
      adventure: adventure,
    );

    await addSteps(tester, adventure.roundTargetSteps);

    expect(adventure.isEnemyDefeated, isTrue);
    expect(find.byKey(const ValueKey('round-outcome-notice')), findsNothing);
  });

  testWidgets('İngilizce round bildirimi taşmıyor', (tester) async {
    final errors = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      if (errors.length < 2) errors.add(details.exceptionAsString());
    };
    addTearDown(() => FlutterError.onError = previous);

    final adventure = quest();
    await pumpShell(
      tester,
      profile: UserProfile(avatar: _avatar, level: 5),
      adventure: adventure,
      locale: const Locale('en'),
    );
    await addSteps(tester, adventure.roundTargetSteps);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const ValueKey('round-outcome-notice')), findsOneWidget);
    expect(errors, isEmpty, reason: errors.join(' | '));
  });
}
