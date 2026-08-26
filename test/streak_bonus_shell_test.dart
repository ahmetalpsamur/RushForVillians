import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/game_constants.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/game_clock.dart';
import 'package:rush_for_villains/features/root/root_shell.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_progress.dart';
import 'package:rush_for_villains/models/game_state.dart';
import 'package:rush_for_villains/models/item_effect.dart';
import 'package:rush_for_villains/models/streak_stat_bonuses.dart';
import 'package:rush_for_villains/models/user_profile.dart';
import 'package:rush_for_villains/services/game_storage.dart';
import 'package:rush_for_villains/services/item_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Seri stat bonusunun **bağlantı** tarafı (Bölüm 5C).
///
/// Birim kuralları `streak_stat_bonus_test.dart` içinde. Burada ölçülen şey
/// farklı: `RootShell` gerçekten çekilişi yapıyor mu, sonucu kullanıcıya
/// söylüyor mu ve diske yazıyor mu. Bu ancak gerçek widget ağacında
/// görülebilir — `_onStepsReported` bir `StatefulWidget`'ın private metodu.
const _avatar = AvatarProfile(
  name: 'Barca',
  age: 28,
  weight: 74,
  gender: 'Erkek',
  characterClass: 'SwordMan',
  characterAsset: 'lib/Characters/SwordMan/test.png',
);

const _storageKey = 'game_state_v1';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var shellSerial = 0;

  Future<UserProfile> pumpShell(
    WidgetTester tester, {
    required UserProfile profile,
  }) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    ItemCatalog.reset(const []);
    addTearDown(ItemCatalog.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: RootShell(
          key: ValueKey('streak-shell-${shellSerial++}'),
          avatar: _avatar,
          initialState: GameState(
            profile: profile,
            today: DailyProgress(date: GameClock.now()),
          ),
          onAvatarChanged: (_) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return profile;
  }

  /// Demo kontrolüyle adım üretir (manuel kaynak hız kontrolünden muaf).
  Future<void> addSteps(WidgetTester tester, int amount) async {
    await tester.ensureVisible(find.text('+$amount adım'));
    await tester.tap(find.text('+$amount adım'));
    await tester.pump();
  }

  testWidgets('seri eşiği geçilince bonus verilir ve duyurulur', (
    tester,
  ) async {
    final profile = await pumpShell(
      tester,
      profile: UserProfile(avatar: _avatar, level: 10),
    );
    expect(profile.streakStatBonuses.isEmpty, isTrue);

    // Seri eşiğini rahatça geçen tek parti.
    expect(GameConstants.streakStepThreshold, lessThanOrEqualTo(5000));
    await addSteps(tester, 5000);
    // Bildirim frame sonunda kuyruğa giriyor, sonra açılış animasyonu oynuyor.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));

    expect(profile.streakDays, 1);
    // Bölüm B: 1. gün ilk basamakta, +%0,5 = 5 binde.
    expect(profile.streakStatBonuses.totalTenths, 5);
    expect(profile.streakBonusSeed, isNot(0));

    // Kazanılan stat kullanıcıya söylenir.
    final stat = profile.streakStatBonuses.tenths.keys.single;
    expect(find.textContaining('1. gün:'), findsOneWidget);
    expect(find.textContaining(stat.label), findsOneWidget);
  });

  testWidgets('aynı partide seviye atlansa bile bildirim yutulmaz', (
    tester,
  ) async {
    // 1. seviyede 5000 adım = 2500 XP, yani birkaç seviye birden atlanır.
    // `_showLevelUp` `hideCurrentSnackBar()` çağırdığı için seri bildirimi
    // eskiden kayboluyordu; artık kuyruğa seviye kutlamasının arkasına
    // giriyor.
    final profile = await pumpShell(
      tester,
      profile: UserProfile(avatar: _avatar),
    );

    await addSteps(tester, 5000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
    expect(profile.level, greaterThan(1));
    expect(find.textContaining('SEVİYE'), findsOneWidget);

    // Seviye kutlaması 5 saniye; ardından seri bildirimi kuyruktan gelir.
    // Tek büyük `pump` yerine kare kare ilerletiliyor: SnackBar kuyruğu
    // kapanma animasyonunu tamamlamak için ara karelere ihtiyaç duyuyor.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.textContaining('1. gün:').evaluate().isNotEmpty) break;
    }
    expect(find.textContaining('1. gün:'), findsOneWidget);
  });

  testWidgets('kilometre taşı bildirimi de yutulmaz', (tester) async {
    // Aynı partide üç bildirim birden çıkıyor: seviye kutlaması, günün seri
    // bonusu ve 7 günlük kilometre taşı. `_showLevelUp` `hideCurrentSnackBar()`
    // çağırdığı için senkron gösterilen kilometre taşı bildirimi hiç
    // görülmeden kapanıyordu.
    final yesterday = GameClock.now().subtract(const Duration(days: 1));
    await pumpShell(
      tester,
      profile: UserProfile(
        avatar: _avatar,
        streakDays: 6,
        lastActiveDay: yesterday,
      ),
    );

    await addSteps(tester, 5000);

    final seen = <String>{};
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.textContaining('SEVİYE').evaluate().isNotEmpty) {
        seen.add('level');
      }
      if (find.textContaining('7. gün:').evaluate().isNotEmpty) {
        seen.add('stat');
      }
      if (find.textContaining('7 günlük seri').evaluate().isNotEmpty) {
        seen.add('milestone');
      }
      if (seen.length == 3) break;
    }
    expect(seen, {'level', 'stat', 'milestone'});
  });

  testWidgets('aynı gün ikinci parti yeni bonus vermez', (tester) async {
    final profile = await pumpShell(
      tester,
      profile: UserProfile(avatar: _avatar, level: 10),
    );

    await addSteps(tester, 5000);
    await tester.pump();
    final afterFirst = profile.streakStatBonuses.toJson();

    await addSteps(tester, 5000);
    await tester.pump();

    expect(profile.streakStatBonuses.toJson(), afterFirst);
    expect(profile.streakStatBonuses.totalTenths, 5);
  });

  testWidgets('bonus diske yazılır', (tester) async {
    final profile = await pumpShell(
      tester,
      profile: UserProfile(avatar: _avatar, level: 10),
    );
    await addSteps(tester, 5000);
    await tester.pump();

    await GameStorage.flush();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    expect(raw, isNotNull);

    final envelope = jsonDecode(raw!) as Map<String, dynamic>;
    expect(envelope['schemaVersion'], GameStorage.schemaVersion);
    final state = envelope['state'] as Map<String, dynamic>;
    final saved = state['profile'] as Map<String, dynamic>;
    expect(saved['streakStatBonuses'], profile.streakStatBonuses.toJson());
    expect(saved['streakBonusSeed'], profile.streakBonusSeed);
    expect(saved['lastStreakBonusDay'], isNotNull);
  });

  testWidgets('kayıttan dönen birikim profilde gösterilir', (tester) async {
    // 9 gün x +%0,5 = +%4,5 (45 binde).
    final bonuses = StreakStatBonuses.empty.withGrant(
      StreakStatBonuses.pool.first,
      45,
    );
    final profile = UserProfile(
      avatar: _avatar,
      streakDays: 9,
      streakStatBonuses: bonuses,
    );
    await pumpShell(tester, profile: profile);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    expect(find.text('Seri Bonusu'), findsOneWidget);
    expect(find.text('toplam +%4,5'), findsOneWidget);
    // Bölüm B: tavan yerine **güncel basamak** gösteriliyor.
    expect(
      find.byKey(const ValueKey('streak-bonus-current-rate')),
      findsOneWidget,
    );
    expect(find.textContaining('Şu an: gün başına +%0,5'), findsOneWidget);
  });

  testWidgets('basamak düşünce panel güncel oranı gösterir', (tester) async {
    // 150. gün: ikinci basamak, gün başına +%0,4.
    final profile = UserProfile(
      avatar: _avatar,
      streakDays: 150,
      streakStatBonuses: StreakStatBonuses.empty.withGrant(
        StreakStatBonuses.pool.first,
        700,
      ),
    );
    await pumpShell(tester, profile: profile);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Şu an: gün başına +%0,4'), findsOneWidget);
    expect(find.text('toplam +%70'), findsOneWidget);
  });

  testWidgets('döngü başa dönünce kutlanır', (tester) async {
    // 500 günlük seri: bir sonraki gün 501, yani kazanç +%0,1'den +%0,5'e
    // geri döner ve bu kullanıcıya söylenmeli (Bölüm B).
    final profile = await pumpShell(
      tester,
      profile: UserProfile(
        avatar: _avatar,
        level: 10,
        streakDays: 500,
        lastActiveDay: GameClock.now().subtract(const Duration(days: 1)),
        streakStatBonuses: StreakStatBonuses.empty.withGrant(
          StreakStatBonuses.pool.first,
          1500,
        ),
      ),
    );

    await addSteps(tester, 5000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));

    expect(profile.streakDays, 501);
    expect(find.textContaining('501. gün: +%0,5'), findsOneWidget);
    expect(find.textContaining('Döngü başa döndü!'), findsOneWidget);
  });

  testWidgets('döngü dışındaki gün kutlanmaz', (tester) async {
    final profile = await pumpShell(
      tester,
      profile: UserProfile(
        avatar: _avatar,
        level: 10,
        streakDays: 150,
        lastActiveDay: GameClock.now().subtract(const Duration(days: 1)),
        streakStatBonuses: StreakStatBonuses.empty.withGrant(
          StreakStatBonuses.pool.first,
          700,
        ),
      ),
    );

    await addSteps(tester, 5000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));

    expect(profile.streakDays, 151);
    // İkinci basamak: gün başına +%0,4.
    expect(find.textContaining('151. gün: +%0,4'), findsOneWidget);
    expect(find.textContaining('Döngü başa döndü!'), findsNothing);
  });

  testWidgets('ana ekrandaki seri kartı birikimi özetler', (tester) async {
    // 4 gün x +%0,5 = +%2 (20 binde).
    final bonuses = StreakStatBonuses.empty.withGrant(
      StreakStatBonuses.pool.first,
      20,
    );
    await pumpShell(
      tester,
      profile: UserProfile(
        avatar: _avatar,
        streakDays: 4,
        streakStatBonuses: bonuses,
      ),
    );

    expect(find.textContaining('Seri bonusu: +%2'), findsOneWidget);
  });
}
