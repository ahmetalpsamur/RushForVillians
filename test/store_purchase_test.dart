import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/game_constants.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/game_clock.dart';
import 'package:rush_for_villains/core/utils/game_day.dart';
import 'package:rush_for_villains/core/utils/item_rules.dart';
import 'package:rush_for_villains/features/home/home_screen.dart';
import 'package:rush_for_villains/features/root/root_shell.dart';
import 'package:rush_for_villains/features/store/xp_store_screen.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_progress.dart';
import 'package:rush_for_villains/models/game_state.dart';
import 'package:rush_for_villains/models/item.dart';
import 'package:rush_for_villains/models/owned_item.dart';
import 'package:rush_for_villains/models/user_profile.dart';
import 'package:rush_for_villains/services/game_storage.dart';
import 'package:rush_for_villains/services/item_catalog.dart';
import 'package:rush_for_villains/widgets/section_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mağazanın **satın alma tarafı**: para, sahiplik, seviye kilidi, tüketilen
/// yükseltmeler ve kalıcılık.
///
/// `store_screen_test.dart` yalnızca ekranın ne gösterdiğini doğruluyor;
/// burada asıl karar merciini — `RootShell._purchase` /
/// `_purchaseEquipment` — gerçek widget ağacı üzerinden sürüyoruz. Aşama 4'te
/// savaş sistemi item buff'larına dokunacak ve mağazayı dolaylı etkileyebilir;
/// bu testlerin görevi o anda alarm vermek.
const _avatar = AvatarProfile(
  name: 'Barca',
  age: 28,
  weight: 74,
  gender: 'Erkek',
  characterClass: 'SwordMan',
  characterAsset: 'lib/Characters/SwordMan/test.png',
);

const _storageKey = 'game_state_v1';

/// Oyun gününün ortasında bir an; sabit saat yazmak yerine gün sınırından
/// türetiliyor (bkz. `streak_test.dart`).
DateTime _dayAt(int day, {int hoursAfterStart = 8}) => GameDay.startOf(
  DateTime(2026, 8, day, GameDay.dayStartHour),
).add(Duration(hours: hoursAfterStart));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Kılıç kategorisi SwordMan'in; üçü de farklı nadirlik/seviye bandında.
  final cheapItem = buildItemFromAsset('lib/Items/swords/sword.png')!;
  final midItem = buildItemFromAsset('lib/Items/swords/aqua_sword.png')!;
  final lockedItem = buildItemFromAsset('lib/Items/swords/dragons_hook.png')!;

  UserProfile makeProfile({
    int coins = 100000,
    int level = 50,
    int streakFreezes = 0,
    int extraWheelSpins = 0,
    DateTime? xpBoostUntil,
    List<String>? owned,
    List<String>? ownedUpgrades,
  }) {
    // Envanter artık **örnek** listesi (GD39); testler kimlikle çalışmaya
    // devam ediyor ve bu yardımcı çeviriyi yapıyor.
    final instances = <OwnedItem>[];
    var serial = 1;
    for (final id in owned ?? const <String>[]) {
      instances.add(OwnedItem(instanceId: serial++, itemId: id));
    }
    return UserProfile(
      avatar: _avatar,
      coins: coins,
      level: level,
      streakFreezes: streakFreezes,
      extraWheelSpins: extraWheelSpins,
      xpBoostUntil: xpBoostUntil,
      ownedItems: instances,
      ownedUpgradeIds: ownedUpgrades,
      nextItemInstanceId: serial,
    );
  }

  /// Envanterdeki kimlikler (adetli).
  List<String> ownedIdsOf(UserProfile profile) => [
    for (final instance in profile.ownedItems) instance.itemId,
  ];

  /// [RootShell]'i mağaza sekmesi açık şekilde kurar ve profili döner.
  ///
  /// Ekran geniş tutuluyor ki ekipman ızgarası gerçekten inşa edilsin;
  /// dar ekran davranışı `store_screen_test.dart` içinde ayrıca test ediliyor.
  Future<UserProfile> pumpShell(
    WidgetTester tester, {
    required UserProfile profile,
    List<Item> catalog = const [],
    bool openStoreTab = true,
  }) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    ItemCatalog.reset(catalog);
    addTearDown(() => ItemCatalog.reset());

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: RootShell(
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

    if (openStoreTab) {
      await tester.tap(find.text('Mağaza').last);
      await tester.pumpAndSettle();
    }
    return profile;
  }

  /// Ekipman kartındaki düğmeye dokunur. Kart adından bulunuyor: satın alma
  /// sonrası düğmenin yazısı fiyattan "Sahipsin"e döndüğü için fiyata göre
  /// aramak ikinci dokunuşta kartı bulamazdı.
  ///
  /// Mağaza itemleri **sınıfa uyarlanmış** hâlde gösterir (ad sınıf lakabını
  /// alır), bu yüzden aranan ad da uyarlanmış addır.
  Future<void> tapEquipment(WidgetTester tester, Item item) async {
    final shown = flavorForClass(item, _avatar.characterClass);
    final card = find.ancestor(
      of: find.text(shown.name),
      matching: find.byType(SectionCard),
    );
    final button = find.descendant(
      of: card.first,
      matching: find.byType(FilledButton),
    );
    await tester.tap(button.first, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  /// Yükseltme satırındaki düğmeye ada göre dokunur.
  Future<void> tapUpgrade(WidgetTester tester, String name) async {
    final row = find.ancestor(of: find.text(name), matching: find.byType(Row));
    final button = find.descendant(
      of: row.first,
      matching: find.byType(FilledButton),
    );
    await tester.tap(button.first, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  /// Demo kontrolüyle adım üretir (manuel kaynak hız kontrolünden muaf).
  Future<void> simulateSteps(WidgetTester tester, int amount) async {
    await tester.tap(
      find.descendant(
        of: find.byType(HomeScreen),
        matching: find.text('+$amount adım'),
      ),
    );
    await tester.pump();
  }

  group('ekipman satın alma', () {
    testWidgets('yeterli parayla alınır: para düşer, envantere girer', (
      tester,
    ) async {
      final profile = await pumpShell(
        tester,
        profile: makeProfile(coins: 5000),
        catalog: [cheapItem],
      );

      await tapEquipment(tester, cheapItem);

      expect(profile.coins, 5000 - cheapItem.cost);
      expect(ownedIdsOf(profile), [cheapItem.id]);
    });

    testWidgets('satın alma sonrası ekran tazelenir (M1 regresyonu)', (
      tester,
    ) async {
      await pumpShell(
        tester,
        profile: makeProfile(coins: 5000),
        catalog: [cheapItem],
      );

      expect(find.text('5000'), findsOneWidget);

      await tapEquipment(tester, cheapItem);

      // Bakiye ve adet ekranda görünmeli; itilen rota kullanıldığında
      // ikisi de eski değerde kalıyordu.
      expect(find.text('5000'), findsNothing);
      expect(find.text('${5000 - cheapItem.cost}'), findsOneWidget);
      expect(find.text('1 adet'), findsOneWidget);
    });

    testWidgets('yetersiz bakiyede para değişmez ve sebebi söylenir', (
      tester,
    ) async {
      final short = cheapItem.cost - 10;
      final profile = await pumpShell(
        tester,
        profile: makeProfile(coins: short),
        catalog: [cheapItem],
      );

      await tapEquipment(tester, cheapItem);

      expect(profile.coins, short);
      expect(profile.ownedItems, isEmpty);
      expect(find.textContaining('10 coin daha gerekiyor'), findsOneWidget);
    });

    testWidgets('coin hiçbir koşulda negatife düşmez', (tester) async {
      final profile = await pumpShell(
        tester,
        profile: makeProfile(coins: 0),
        catalog: [cheapItem, midItem],
      );

      await tapEquipment(tester, cheapItem);
      await tapEquipment(tester, midItem);

      expect(profile.coins, 0);
      expect(profile.ownedItems, isEmpty);
    });

    testWidgets('aynı öğe ikinci kez alınır, ikinci örnek envantere girer', (
      tester,
    ) async {
      // Davranış Bölüm 4.1'de **bilerek** değişti (GD39): birleştirme aynı
      // eşyadan birkaç adet istiyor. İkinci satın alma parayı yakmıyor,
      // gerçekten ikinci bir örnek veriyor.
      final profile = await pumpShell(
        tester,
        profile: makeProfile(coins: 5000),
        catalog: [cheapItem],
      );

      await tapEquipment(tester, cheapItem);
      final afterFirst = profile.coins;
      await tapEquipment(tester, cheapItem);

      expect(profile.coins, afterFirst - cheapItem.cost);
      expect(ownedIdsOf(profile), [cheapItem.id, cheapItem.id]);
      // İki örneğin kimliği farklı: "hangisini yükselt" sorusu cevaplanabilir.
      expect(
        profile.ownedItems.map((instance) => instance.instanceId).toSet(),
        hasLength(2),
      );
    });

    testWidgets('parası yetmeyen ikinci satın alma reddedilir', (tester) async {
      // Çoklu satın alma açıldı ama para kontrolü yerinde: bakiye bir
      // adede yetiyorsa ikincisi alınamaz ve para negatife düşmez.
      final profile = await pumpShell(
        tester,
        profile: makeProfile(coins: cheapItem.cost),
        catalog: [cheapItem],
      );

      await tapEquipment(tester, cheapItem);
      await tapEquipment(tester, cheapItem);

      expect(profile.coins, 0);
      expect(ownedIdsOf(profile), [cheapItem.id]);
    });

    testWidgets('hızlı çift dokunma iki satın alma sayılır', (tester) async {
      // Ekipmanda "aynı kareyi beklemeden iki dokunuş" artık iki adet
      // demek; para iki kez düşüyor ve iki örnek geliyor. Tüketilen
      // yükseltmelerde (dondurma hakkı, 2x XP) muhafızlar duruyor.
      final profile = await pumpShell(
        tester,
        profile: makeProfile(coins: 5000),
        catalog: [cheapItem],
      );

      final button = find.descendant(
        of: find.byType(XpStoreScreen),
        matching: find.widgetWithText(FilledButton, '${cheapItem.cost}'),
      );
      await tester.tap(button.first, warnIfMissed: false);
      await tester.tap(button.first, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(profile.coins, 5000 - cheapItem.cost * 2);
      expect(ownedIdsOf(profile), [cheapItem.id, cheapItem.id]);
    });

    testWidgets('satın alma atomik: para ve sahiplik birlikte değişir', (
      tester,
    ) async {
      final profile = await pumpShell(
        tester,
        profile: makeProfile(coins: cheapItem.cost),
        catalog: [cheapItem],
      );

      await tapEquipment(tester, cheapItem);

      expect(profile.coins, 0);
      expect(ownedIdsOf(profile), [cheapItem.id]);
    });
  });

  group('seviye kilidi', () {
    testWidgets('kilitli item satın alınamaz', (tester) async {
      final profile = await pumpShell(
        tester,
        profile: makeProfile(coins: 100000, level: 1),
        catalog: [lockedItem],
      );

      await tapEquipment(tester, lockedItem);

      expect(profile.coins, 100000);
      expect(profile.ownedItems, isEmpty);
      expect(find.textContaining('seviye gerekiyor'), findsOneWidget);
    });

    testWidgets('tam sınırda alınabilir (Sv. N item, Sv. N oyuncu)', (
      tester,
    ) async {
      final profile = await pumpShell(
        tester,
        profile: makeProfile(coins: 100000, level: lockedItem.requiredLevel),
        catalog: [lockedItem],
      );

      await tapEquipment(tester, lockedItem);

      expect(ownedIdsOf(profile), [lockedItem.id]);
    });

    testWidgets('bir seviye eksikken alınamaz', (tester) async {
      final profile = await pumpShell(
        tester,
        profile: makeProfile(
          coins: 100000,
          level: lockedItem.requiredLevel - 1,
        ),
        catalog: [lockedItem],
      );

      await tapEquipment(tester, lockedItem);

      expect(profile.ownedItems, isEmpty);
    });

    testWidgets('seviye atlayınca kilit açılır ve ekran güncellenir', (
      tester,
    ) async {
      final profile = await pumpShell(
        tester,
        profile: makeProfile(coins: 100000, level: 1),
        catalog: [lockedItem],
        openStoreTab: false,
      );

      // Ana ekrandaki demo kontrolüyle seviye atlat.
      for (var i = 0; i < 60 && profile.level < lockedItem.requiredLevel; i++) {
        await simulateSteps(tester, 20000);
      }
      expect(profile.level, greaterThanOrEqualTo(lockedItem.requiredLevel));

      await tester.tap(find.text('Mağaza').last);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock), findsNothing);
      await tapEquipment(tester, lockedItem);
      expect(ownedIdsOf(profile), [lockedItem.id]);
    });
  });

  group('tüketilen yükseltmeler', () {
    testWidgets('seri dondurma alınınca stok artar', (tester) async {
      final profile = await pumpShell(tester, profile: makeProfile());

      await tapUpgrade(tester, 'Seri Dondurma Hakkı');

      expect(profile.streakFreezes, 1);
    });

    testWidgets('dondurma stoğu doluyken para harcanmaz', (tester) async {
      final profile = await pumpShell(
        tester,
        profile: makeProfile(
          coins: 5000,
          streakFreezes: GameConstants.maxStreakFreezes,
        ),
      );

      await tapUpgrade(tester, 'Seri Dondurma Hakkı');

      expect(profile.coins, 5000);
      expect(profile.streakFreezes, GameConstants.maxStreakFreezes);
      expect(find.textContaining('stoğun dolu'), findsOneWidget);
    });

    testWidgets('ekstra çark hakkı alınınca stok artar', (tester) async {
      final profile = await pumpShell(tester, profile: makeProfile());

      await tapUpgrade(tester, 'Ekstra Çark Hakkı');

      expect(profile.extraWheelSpins, 1);
    });

    testWidgets('çark stoğu doluyken para harcanmaz', (tester) async {
      final profile = await pumpShell(
        tester,
        profile: makeProfile(
          coins: 5000,
          extraWheelSpins: GameConstants.maxExtraWheelSpins,
        ),
      );

      await tapUpgrade(tester, 'Ekstra Çark Hakkı');

      expect(profile.coins, 5000);
      expect(profile.extraWheelSpins, GameConstants.maxExtraWheelSpins);
      expect(find.textContaining('stoğun dolu'), findsOneWidget);
    });

    testWidgets('2x XP alınınca etkinleşir', (tester) async {
      final profile = await pumpShell(tester, profile: makeProfile());

      await tapUpgrade(tester, '2x XP Boost (1 gün)');

      expect(profile.isXpBoostActive, isTrue);
    });

    testWidgets('2x XP zaten etkinken para harcanmaz', (tester) async {
      final profile = await pumpShell(
        tester,
        profile: makeProfile(
          coins: 5000,
          xpBoostUntil: DateTime.now().toUtc().add(const Duration(hours: 5)),
        ),
      );

      await tapUpgrade(tester, '2x XP Boost (1 gün)');

      expect(profile.coins, 5000);
      expect(find.textContaining('zaten etkin'), findsOneWidget);
    });

    testWidgets('2x XP etkinken adımdan gelen XP ikiye katlanır', (
      tester,
    ) async {
      final boosted = await pumpShell(
        tester,
        profile: makeProfile(
          xpBoostUntil: DateTime.now().toUtc().add(const Duration(hours: 5)),
        ),
        openStoreTab: false,
      );
      await simulateSteps(tester, 1000);

      // 1.000 adım / stepsPerXp = 500 XP; çarpanla 1.000.
      final expected =
          (1000 ~/ GameConstants.stepsPerXp) * GameConstants.xpBoostMultiplier;
      expect(boosted.xp, expected);
    });
  });

  group('çark ödülü (#16)', () {
    // Çarkın havuz kuralları `wheel_rewards_test.dart`, ekran davranışı
    // `daily_wheel_test.dart` içinde. Burada tek soru var: ödül gerçekten
    // profile işliyor mu? Harness bu dosyada olduğu için buraya alındı.
    testWidgets('kazanılan item envantere girer, XP profile eklenir', (
      tester,
    ) async {
      final profile = await pumpShell(
        tester,
        profile: makeProfile(level: 50),
        catalog: [cheapItem, midItem],
        openStoreTab: false,
      );

      // Çark 3.000 adımda açılıyor.
      await simulateSteps(tester, 5000);
      final xpBeforeSpin = profile.xp;

      await tester.tap(
        find.descendant(
          of: find.byType(HomeScreen),
          matching: find.text('Günlük Çark'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Çarkı Çevir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2700));
      await tester.pump(const Duration(milliseconds: 2500));

      // Ödül ya item ya XP; ikisi de profile işlemeli.
      final gotItem = profile.ownedItems.isNotEmpty;
      final gotXp = profile.xp > xpBeforeSpin;
      expect(
        gotItem || gotXp,
        isTrue,
        reason: 'çark ödülü profile hiç işlemedi',
      );
      expect(profile.wheelSpunToday, isTrue);
    });

    testWidgets('tohum çevirdikten sonra ilerler', (tester) async {
      final profile = await pumpShell(
        tester,
        profile: makeProfile(level: 50),
        catalog: [cheapItem],
        openStoreTab: false,
      );

      await simulateSteps(tester, 5000);
      await tester.tap(
        find.descendant(
          of: find.byType(HomeScreen),
          matching: find.text('Günlük Çark'),
        ),
      );
      await tester.pumpAndSettle();

      // Tohum ekran açılırken oyuncuya özel kuruluyor.
      final seedBefore = profile.wheelSeed;
      expect(seedBefore, isNot(0));

      await tester.tap(find.widgetWithText(FilledButton, 'Çarkı Çevir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2700));
      await tester.pump(const Duration(milliseconds: 2500));

      expect(profile.wheelSeed, isNot(seedBefore));
    });
  });

  group('kalıcılık', () {
    testWidgets('satın alma diske yazılır', (tester) async {
      final profile = await pumpShell(
        tester,
        profile: makeProfile(coins: 5000),
        catalog: [cheapItem],
      );

      await tapEquipment(tester, cheapItem);
      // Yazma [GameStorage.writeInterval] kadar gecikmeli.
      await tester.pump(GameStorage.writeInterval + const Duration(seconds: 1));

      String? raw;
      await tester.runAsync(() async {
        final preferences = await SharedPreferences.getInstance();
        raw = preferences.getString(_storageKey);
      });

      expect(raw, isNotNull);
      final envelope = jsonDecode(raw!) as Map<String, dynamic>;
      final state = envelope['state'] as Map<String, dynamic>;
      final saved = state['profile'] as Map<String, dynamic>;

      expect(envelope['schemaVersion'], GameStorage.schemaVersion);
      expect(saved['coins'], profile.coins);
      expect(
        (saved['ownedItems'] as List).single,
        containsPair('itemId', cheapItem.id),
      );
    });

    testWidgets('tüketilen yükseltmeler de diske yazılır', (tester) async {
      await pumpShell(tester, profile: makeProfile());

      await tapUpgrade(tester, 'Ekstra Çark Hakkı');
      await tapUpgrade(tester, '2x XP Boost (1 gün)');
      await tester.pump(GameStorage.writeInterval + const Duration(seconds: 1));

      String? raw;
      await tester.runAsync(() async {
        final preferences = await SharedPreferences.getInstance();
        raw = preferences.getString(_storageKey);
      });

      final envelope = jsonDecode(raw!) as Map<String, dynamic>;
      final state = envelope['state'] as Map<String, dynamic>;
      final saved = state['profile'] as Map<String, dynamic>;

      expect(saved['extraWheelSpins'], 1);
      expect(saved['xpBoostUntil'], isA<String>());
    });
  });

  group('model: tüketilen yükseltme kuralları', () {
    tearDown(GameClock.reset);

    test('ekstra çark hakkı stok tavanını aşmaz', () {
      final profile = makeProfile();

      expect(profile.grantExtraWheelSpin(), 1);
      expect(
        profile.grantExtraWheelSpin(5),
        GameConstants.maxExtraWheelSpins - 1,
      );
      expect(profile.grantExtraWheelSpin(), 0);
      expect(profile.extraWheelSpins, GameConstants.maxExtraWheelSpins);
    });

    test('günlük hak duruyorsa jeton harcanmaz', () {
      final now = _dayAt(10);
      GameClock.useSource(() => now);
      final profile = makeProfile(extraWheelSpins: 2);

      expect(profile.consumeWheelSpin(now), isTrue);
      expect(profile.extraWheelSpins, 2);
      expect(profile.wheelSpunToday, isTrue);
    });

    test('günlük hak bittiyse jeton harcanır', () {
      final now = _dayAt(10);
      GameClock.useSource(() => now);
      final profile = makeProfile(extraWheelSpins: 2);

      profile.consumeWheelSpin(now);
      expect(profile.consumeWheelSpin(now), isTrue);
      expect(profile.extraWheelSpins, 1);
      expect(profile.canSpinWheel, isTrue);
    });

    test('hak kalmayınca çevirme reddedilir', () {
      final now = _dayAt(10);
      GameClock.useSource(() => now);
      final profile = makeProfile(extraWheelSpins: 1);

      profile.consumeWheelSpin(now); // günlük
      profile.consumeWheelSpin(now); // jeton
      expect(profile.canSpinWheel, isFalse);
      expect(profile.consumeWheelSpin(now), isFalse);
      expect(profile.extraWheelSpins, 0);
    });

    test('gün değişince günlük hak geri gelir, jeton korunur', () {
      var now = _dayAt(10);
      GameClock.useSource(() => now);
      final profile = makeProfile(extraWheelSpins: 1);
      profile.consumeWheelSpin(now);

      now = _dayAt(11);
      expect(profile.wheelSpunToday, isFalse);
      expect(profile.extraWheelSpins, 1);
    });

    test('2x XP gün sonunda düşer', () {
      var now = _dayAt(10, hoursAfterStart: 2);
      GameClock.useSource(() => now);
      final profile = makeProfile();

      expect(profile.activateXpBoost(now), isTrue);
      expect(profile.isXpBoostActive, isTrue);

      // Aynı oyun gününün sonuna doğru hâlâ etkin.
      now = _dayAt(10, hoursAfterStart: 20);
      expect(profile.isXpBoostActive, isTrue);

      // Gün sınırının ötesinde düşmüş olmalı.
      now = _dayAt(11, hoursAfterStart: 1);
      expect(profile.isXpBoostActive, isFalse);
    });

    test('etkinken ikinci kez etkinleştirilemez', () {
      final now = _dayAt(10);
      GameClock.useSource(() => now);
      final profile = makeProfile();

      expect(profile.activateXpBoost(now), isTrue);
      expect(profile.activateXpBoost(now), isFalse);
    });

    test('kayıt turu: yeni alanlar korunur', () {
      final now = _dayAt(10);
      GameClock.useSource(() => now);
      final profile = makeProfile(extraWheelSpins: 2)..activateXpBoost(now);

      final restored = UserProfile.fromJson(
        jsonDecode(jsonEncode(profile.toJson())) as Map<String, dynamic>,
        avatar: _avatar,
      );

      expect(restored.extraWheelSpins, 2);
      expect(restored.xpBoostUntil, profile.xpBoostUntil);
      expect(restored.isXpBoostActive, isTrue);
    });

    test('bozuk kayıttaki şişkin stok kırpılır', () {
      final profile = UserProfile.fromJson(const {
        'extraWheelSpins': 999,
      }, avatar: _avatar);

      // Üst sınır **buff'lı** tavan; gerekçe [UserProfile.fromJson] içinde.
      expect(
        profile.extraWheelSpins,
        GameConstants.maxExtraWheelSpins + GameConstants.maxEquippedStockBonus,
      );
    });

    test('v8 kaydı v9 alanları olmadan okunabilir', () async {
      SharedPreferences.setMockInitialValues({
        _storageKey: jsonEncode({
          'schemaVersion': 8,
          'savedAt': DateTime(2026, 8, 19).toIso8601String(),
          'state': {
            'profile': {'coins': 700, 'level': 3},
            'today': DailyProgress(date: _dayAt(10)).toJson(),
            'stepHistory': <Object>[],
          },
        }),
      });

      final restored = await GameStorage.load(avatar: _avatar);

      expect(restored, isNotNull);
      expect(restored!.profile.coins, 700);
      expect(restored.profile.extraWheelSpins, 0);
      expect(restored.profile.xpBoostUntil, isNull);
      expect(restored.profile.isXpBoostActive, isFalse);
    });
  });
}
