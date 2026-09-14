import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/game_constants.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/game_clock.dart';
import 'package:rush_for_villains/core/utils/item_leveling.dart';
import 'package:rush_for_villains/core/utils/item_rules.dart';
import 'package:rush_for_villains/features/home/home_screen.dart';
import 'package:rush_for_villains/features/root/root_shell.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_progress.dart';
import 'package:rush_for_villains/models/game_state.dart';
import 'package:rush_for_villains/models/item.dart';
import 'package:rush_for_villains/models/item_effect.dart';
import 'package:rush_for_villains/models/owned_item.dart';
import 'package:rush_for_villains/models/reward_rarity.dart';
import 'package:rush_for_villains/models/user_profile.dart';
import 'package:rush_for_villains/services/game_storage.dart';
import 'package:rush_for_villains/services/item_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Envanter ve kuşanmanın **karar tarafı**.
///
/// `store_purchase_test.dart` ile aynı gerekçe: kuşanmanın son sözü
/// `RootShell` içinde (`_equipItem`, `_unequipSlot`, `_sellItem`) ve orası bir
/// `StatefulWidget`'ın private metodu. Mantığı saf bir fonksiyona çıkarmak
/// çalışan mimariye dokunmak olurdu (Kural 1/3); widget testi aynı garantiyi
/// mevcut yapıyı bozmadan veriyor.
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

  // Kılıçlar SwordMan'in; kalkanlar da. İki ayrı slot demek.
  final sword = buildItemFromAsset('lib/Items/swords/sword.png')!;
  final betterSword = buildItemFromAsset('lib/Items/swords/aqua_sword.png')!;
  final lockedSword = buildItemFromAsset('lib/Items/swords/dragons_hook.png')!;
  final shield = buildItemFromAsset('lib/Items/shields/round_shield.png')!;
  // Okçuya ait, SwordMan'in kullanamadığı bir kategori.
  final bow = buildItemFromAsset('lib/Items/arch/wooden_bow.png')!;

  /// Ölçülebilir bir adım-para bonusu taşıyan sentetik item.
  ///
  /// Katalogdan gerçek bir item seçilemiyor çünkü buff **sınıfa göre**
  /// türetiliyor (GD16): SwordMan'in imzası düşman XP, dolayısıyla onun
  /// gördüğü hiçbir sıradan item birincil olarak adım parası vermiyor.
  /// [Item.lore] verildiği için bu item **imzalı** sayılır ve
  /// `flavorForClass` onu değiştirmez — testin ölçtüğü çarpan sabit kalır.
  final boostItem = Item(
    id: 'swords/test_coin_blade',
    name: 'Test Kılıcı',
    assetPath: 'lib/Items/swords/test_coin_blade.png',
    category: ItemCategory.swords,
    rarity: RewardRarity.legendary,
    requiredLevel: 1,
    cost: 1000,
    lore: 'Test için dövüldü.',
    buff: const ItemBuff([ItemEffect(stat: ItemStat.stepCoin, value: 0.5)]),
    archetype: ItemArchetype.swift,
  );

  final catalog = [sword, betterSword, lockedSword, shield, bow, boostItem];

  /// Ekranda görünen ad **sınıfa uyarlanmış** addır (GD16): paylaşılan
  /// kategorilerde sınıf lakabı öne gelir. Testler kimlikle çalışıyor ama
  /// dokunmak için görünen adı bulmak zorunda.
  String shown(Item item) => flavorForClass(item, _avatar.characterClass).name;

  /// Envanter artık **örnek** listesi (GD39). Testler hâlâ kimlikle
  /// çalışıyor; bu yardımcı kimlikleri örneklere çeviriyor.
  UserProfile makeProfile({
    int level = 50,
    int coins = 1000,
    List<String>? owned,
    Map<String, String>? equipped,
  }) {
    final equippedIds = equipped?.values.toSet() ?? const <String>{};
    final instances = <OwnedItem>[];
    var serial = 1;
    for (final id in owned ?? const <String>[]) {
      instances.add(
        OwnedItem(
          instanceId: serial++,
          itemId: id,
          equipped: equippedIds.contains(id),
        ),
      );
    }
    return UserProfile(
      avatar: _avatar,
      level: level,
      coins: coins,
      ownedItems: instances,
      nextItemInstanceId: serial,
    );
  }

  /// Kuşanılı kimlikler.
  Set<String> equippedIdsOf(UserProfile profile) => {
    for (final instance in profile.equippedInstances) instance.itemId,
  };

  /// Envanterdeki kimlikler (adetli).
  List<String> ownedIdsOf(UserProfile profile) => [
    for (final instance in profile.ownedItems) instance.itemId,
  ];

  // Aynı test içinde ikinci kez `pumpWidget` çağrıldığında Flutter aynı
  // tipteki elemanı yeniden kullanıp `initState` yerine `didUpdateWidget`
  // çalıştırıyor; `RootShell._profile` `late final` olduğu için eski profil
  // yerinde kalıyordu. Her kurulum ayrı bir anahtar alarak yeni bir state
  // zorluyor.
  var shellSerial = 0;

  /// [RootShell]'i kurup envanteri açar.
  Future<UserProfile> pumpInventory(
    WidgetTester tester, {
    required UserProfile profile,
    bool openInventory = true,
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
          key: ValueKey('shell-${shellSerial++}'),
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

    if (openInventory) {
      await tester.tap(find.text('Envanter'));
      await tester.pumpAndSettle();
    }
    return profile;
  }

  Future<void> simulateSteps(WidgetTester tester, int amount) async {
    tester.widget<HomeScreen>(find.byType(HomeScreen)).onSimulateSteps(amount);
    await tester.pumpAndSettle();
  }

  /// Envanter listesindeki bir item'ın kartını açar.
  Future<void> openItem(WidgetTester tester, Item item) async {
    await tester.tap(find.text(shown(item)).first);
    await tester.pumpAndSettle();
  }

  group('kuşanma', () {
    testWidgets('sahip olunan item kuşanılır ve slota yazılır', (tester) async {
      final profile = await pumpInventory(
        tester,
        profile: makeProfile(owned: [sword.id]),
      );

      await openItem(tester, sword);
      await tester.tap(find.text('Kuşan'));
      await tester.pumpAndSettle();

      expect(equippedIdsOf(profile), {sword.id});
    });

    testWidgets('aynı slottaki ikinci item öncekinin yerine geçer', (
      tester,
    ) async {
      final profile = await pumpInventory(
        tester,
        profile: makeProfile(
          owned: [sword.id, betterSword.id],
          equipped: {ItemCategory.swords.folder: sword.id},
        ),
      );

      await openItem(tester, betterSword);
      await tester.tap(find.text('Kuşan'));
      await tester.pumpAndSettle();

      // Slot başına tek item: harita tek anahtar taşıyor.
      expect(profile.equippedInstances, hasLength(1));
      expect(equippedIdsOf(profile).single, betterSword.id);
      expect(equippedIdsOf(profile), isNot(contains(sword.id)));
      // Yerinden edilen item **satılmaz**, sahiplikte kalır.
      expect(ownedIdsOf(profile), contains(sword.id));
    });

    testWidgets('farklı kategoriler ayrı slot işgal eder', (tester) async {
      final profile = await pumpInventory(
        tester,
        profile: makeProfile(owned: [sword.id, shield.id]),
      );

      await openItem(tester, sword);
      await tester.tap(find.text('Kuşan'));
      await tester.pumpAndSettle();
      await openItem(tester, shield);
      await tester.tap(find.text('Kuşan'));
      await tester.pumpAndSettle();

      expect(equippedIdsOf(profile), {sword.id, shield.id});
    });

    testWidgets('kuşanılan item çıkarılabilir', (tester) async {
      final profile = await pumpInventory(
        tester,
        profile: makeProfile(
          owned: [sword.id],
          equipped: {ItemCategory.swords.folder: sword.id},
        ),
      );

      await openItem(tester, sword);
      await tester.tap(find.text('Çıkar'));
      await tester.pumpAndSettle();

      expect(profile.equippedInstances, isEmpty);
    });
  });

  group('seviye kilidi', () {
    testWidgets('seviyesi yetmeyen item kuşanılamaz ve nedeni söylenir', (
      tester,
    ) async {
      final profile = await pumpInventory(
        tester,
        profile: makeProfile(level: 1, owned: [lockedSword.id]),
      );

      await openItem(tester, lockedSword);

      // Kilidin nedeni kartta yazıyor (Model Kuralları #4).
      expect(
        find.textContaining('${lockedSword.requiredLevel}. seviye gerekiyor'),
        findsOneWidget,
      );

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Kuşan'),
      );
      expect(button.onPressed, isNull, reason: 'kilitli item kuşanılamamalı');
      expect(profile.equippedInstances, isEmpty);
    });

    testWidgets('seviye tam sınırdaysa kuşanılır', (tester) async {
      final profile = await pumpInventory(
        tester,
        profile: makeProfile(
          level: lockedSword.requiredLevel,
          owned: [lockedSword.id],
        ),
      );

      await openItem(tester, lockedSword);
      await tester.tap(find.text('Kuşan'));
      await tester.pumpAndSettle();

      expect(equippedIdsOf(profile), contains(lockedSword.id));
    });
  });

  group('buff etkisi', () {
    testWidgets('kuşanma eşya etkisini karakter vitrininde anında gösterir', (
      tester,
    ) async {
      await pumpInventory(tester, profile: makeProfile(owned: [sword.id]));

      expect(find.text('Henüz kuşanılmış eşya yok'), findsOneWidget);

      await openItem(tester, sword);
      await tester.tap(find.text('Kuşan'));
      await tester.pumpAndSettle();

      final bonusLabel = sword.buff.labels.first;
      expect(bonusLabel, isNotEmpty);
      expect(find.text('Henüz kuşanılmış eşya yok'), findsNothing);
      final effectFinder = find.byKey(ValueKey('equipped-effect-${sword.id}'));
      expect(effectFinder, findsOneWidget);
      expect(tester.widget<Text>(effectFinder).data, isNotEmpty);
    });

    testWidgets('kuşanılan adım-para bonusu gerçekten para kazandırır', (
      tester,
    ) async {
      // Aynı adım sayısı, tek fark kuşanma.
      final withoutBuff = makeProfile(coins: 0, owned: [boostItem.id]);
      await pumpInventory(tester, profile: withoutBuff, openInventory: false);
      await simulateSteps(tester, 5000);
      final plainCoins = withoutBuff.coins;

      final withBuff = makeProfile(
        coins: 0,
        owned: [boostItem.id],
        equipped: {boostItem.category.folder: boostItem.id},
      );
      await pumpInventory(tester, profile: withBuff, openInventory: false);
      await simulateSteps(tester, 5000);

      // 5.000 adım = 100 coin; +%50 bonusla 150.
      expect(plainCoins, 100);
      expect(withBuff.coins, 150);
    });

    testWidgets('çıkarınca çarpan geri düşer', (tester) async {
      final profile = makeProfile(
        coins: 0,
        owned: [boostItem.id],
        equipped: {boostItem.category.folder: boostItem.id},
      );
      await pumpInventory(tester, profile: profile);

      await openItem(tester, boostItem);
      await tester.tap(find.text('Çıkar'));
      await tester.pumpAndSettle();

      expect(profile.equippedInstances, isEmpty);

      // Kuşanma kalktı: aynı adım artık bonussuz ödeniyor.
      // Envanter itilen bir rota; ana ekrana dönmek için geri gitmek gerek.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await simulateSteps(tester, 5000);

      expect(profile.coins, 100);
    });
  });

  group('satma', () {
    testWidgets('onaylanan satış parayı verir ve itemi düşürür', (
      tester,
    ) async {
      final profile = await pumpInventory(
        tester,
        profile: makeProfile(coins: 0, owned: [sword.id]),
      );

      await openItem(tester, sword);
      await tester.tap(find.textContaining('Sat +'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Sat (+'));
      await tester.pumpAndSettle();

      expect(profile.ownedItems, isEmpty);
      expect(profile.coins, sellValueFor(sword.cost));
    });

    testWidgets('vazgeçilen satış hiçbir şeyi değiştirmez', (tester) async {
      final profile = await pumpInventory(
        tester,
        profile: makeProfile(coins: 0, owned: [sword.id]),
      );

      await openItem(tester, sword);
      await tester.tap(find.textContaining('Sat +'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();

      expect(ownedIdsOf(profile), [sword.id]);
      expect(profile.coins, 0);
    });

    testWidgets('kuşanılı item satılınca önce çıkarılır', (tester) async {
      final profile = await pumpInventory(
        tester,
        profile: makeProfile(
          coins: 0,
          owned: [sword.id],
          equipped: {ItemCategory.swords.folder: sword.id},
        ),
      );

      await openItem(tester, sword);
      await tester.tap(find.textContaining('Sat +'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Sat (+'));
      await tester.pumpAndSettle();

      expect(profile.equippedInstances, isEmpty);
      expect(profile.ownedItems, isEmpty);
      expect(profile.coins, sellValueFor(sword.cost));
    });

    test('satış değeri alış fiyatının altında ve sıfırdan büyük', () {
      for (final item in catalog) {
        final value = sellValueFor(item.cost);
        expect(value, greaterThan(0));
        expect(
          value,
          lessThan(item.cost),
          reason: 'alım-satım döngüsü para üretmemeli',
        );
      }
      expect(sellValueFor(1), 5);
    });
  });

  group('temizlik', () {
    testWidgets('sahip olunmayan kimlik kuşanmadan düşer', (tester) async {
      // Elle düzenlenmiş ya da eski bir kayıt: kuşanılı ama sahip değil.
      final profile = await pumpInventory(
        tester,
        profile: makeProfile(
          owned: const [],
          equipped: {ItemCategory.swords.folder: sword.id},
        ),
      );

      expect(profile.equippedInstances, isEmpty);
    });

    testWidgets('sınıfın kullanamadığı kategori kuşanmadan düşer', (
      tester,
    ) async {
      final profile = await pumpInventory(
        tester,
        profile: makeProfile(
          owned: [bow.id],
          equipped: {ItemCategory.arch.folder: bow.id},
        ),
      );

      // Yay SwordMan'in değil: slot boşalır ama **sahiplik korunur**.
      expect(profile.equippedInstances, isEmpty);
      expect(ownedIdsOf(profile), contains(bow.id));
    });

    testWidgets('aynı slotta ikinci kuşanılı örnek düşer', (tester) async {
      // "Slot başına tek eşya" kuralı eskiden `Map` yapısıyla veri düzeyinde
      // zorlanıyordu (GD26). Envanter örnek listesine geçince (GD39) kural
      // `_refreshEquipment` içine taşındı; elle düzenlenmiş bir kayıt iki
      // kılıcı birden kuşanılı işaretleyebilir.
      final profile = UserProfile(
        avatar: _avatar,
        level: 50,
        coins: 1000,
        ownedItems: [
          OwnedItem(instanceId: 1, itemId: sword.id, equipped: true),
          OwnedItem(instanceId: 2, itemId: betterSword.id, equipped: true),
          OwnedItem(instanceId: 3, itemId: shield.id, equipped: true),
        ],
        nextItemInstanceId: 4,
      );

      await pumpInventory(tester, profile: profile);

      // Kılıç slotunda tek örnek kalır, kalkan etkilenmez.
      expect(profile.equippedInstances, hasLength(2));
      expect(equippedIdsOf(profile), contains(shield.id));
      // Sahiplik hiç değişmez (GD28).
      expect(profile.ownedItems, hasLength(3));
    });

    testWidgets('katalogdan kalkmış kimlik çökmeye yol açmaz', (tester) async {
      final profile = await pumpInventory(
        tester,
        profile: makeProfile(
          owned: const ['swords/silinmis_item'],
          equipped: {ItemCategory.swords.folder: 'swords/silinmis_item'},
        ),
      );

      expect(profile.equippedInstances, isEmpty);
      expect(find.text('Envanter'), findsWidgets);
    });
  });

  group('kalıcılık', () {
    testWidgets('kuşanma diske yazılır ve kapat-aç sonrası durur', (
      tester,
    ) async {
      final profile = await pumpInventory(
        tester,
        profile: makeProfile(owned: [sword.id, shield.id]),
      );

      await openItem(tester, sword);
      await tester.tap(find.text('Kuşan'));
      await tester.pumpAndSettle();

      await GameStorage.flush();
      final raw = (await SharedPreferences.getInstance()).getString(
        _storageKey,
      );
      expect(raw, isNotNull);

      final envelope = jsonDecode(raw!) as Map<String, dynamic>;
      expect(envelope['schemaVersion'], GameStorage.schemaVersion);
      final stored =
          (envelope['state'] as Map<String, dynamic>)['profile']
              as Map<String, dynamic>;
      final storedItems = stored['ownedItems'] as List;
      expect(storedItems, hasLength(2));
      expect(
        storedItems.where((row) => (row as Map)['equipped'] == true).single,
        containsPair('itemId', sword.id),
      );

      // Diskten geri okunduğunda aynı kuşanma geliyor.
      final restored = await GameStorage.load(avatar: _avatar);
      expect(equippedIdsOf(restored!.profile), {sword.id});
      expect(equippedIdsOf(profile), {sword.id});
    });

    test('v10 kaydı kuşanma alanı olmadan okunabilir', () async {
      SharedPreferences.setMockInitialValues({
        _storageKey: jsonEncode({
          'schemaVersion': 10,
          'savedAt': DateTime(2026, 8, 20).toIso8601String(),
          'state': {
            'profile': {'coins': 500, 'level': 4},
            'today': {'date': DateTime(2026, 8, 20).toIso8601String()},
          },
        }),
      });

      final restored = await GameStorage.load(avatar: _avatar);

      expect(restored, isNotNull);
      expect(restored!.profile.coins, 500);
      // Hiçbir şey kendiliğinden kuşanılmış sayılmaz.
      expect(restored.profile.equippedInstances, isEmpty);
      expect(restored.profile.ownedItems, isEmpty);
    });

    test('bozuk envanter satırları atılır, sağlamlar korunur', () {
      final profile = UserProfile.fromJson(const {
        'ownedItems': [
          {'instanceId': 1, 'itemId': 'swords/sword', 'equipped': true},
          // Kimliksiz, sayısal kimlikli ve boş satırlar atılır.
          {'itemId': 'swords/other'},
          {'instanceId': 2, 'itemId': 42},
          {'instanceId': 3},
          null,
          // Çakışan instanceId: ikincisi atılır, "hangisini yükselt"
          // sorusu cevapsız kalmasın.
          {'instanceId': 1, 'itemId': 'shields/round_shield'},
        ],
      }, avatar: _avatar);

      expect(profile.ownedItems, hasLength(1));
      expect(profile.ownedItems.single.itemId, 'swords/sword');
      expect(profile.ownedItems.single.equipped, isTrue);
      // Sayaç, kayıttaki en büyük kimliğin altına düşemez.
      expect(profile.nextItemInstanceId, greaterThan(1));
    });

    test('v11 kaydı örnek listesine taşınır, veri kaybolmaz', () async {
      SharedPreferences.setMockInitialValues({
        _storageKey: jsonEncode({
          'schemaVersion': 11,
          'savedAt': DateTime(2026, 8, 24).toIso8601String(),
          'state': {
            'profile': {
              'coins': 500,
              'level': 9,
              'ownedItemIds': [
                'swords/sword',
                'shields/round_shield',
                // Yükseltme kimliği: `/` içermediği için ayrı listeye gider.
                'boost_double_xp',
              ],
              'equippedItemIds': {'swords': 'swords/sword'},
            },
            'today': {'date': DateTime(2026, 8, 24).toIso8601String()},
          },
        }),
      });

      final restored = await GameStorage.load(avatar: _avatar);

      expect(restored, isNotNull);
      expect(restored!.profile.coins, 500);
      expect(ownedIdsOf(restored.profile), [
        'swords/sword',
        'shields/round_shield',
      ]);
      expect(restored.profile.ownedUpgradeIds, ['boost_double_xp']);
      expect(equippedIdsOf(restored.profile), {'swords/sword'});
      // Her örnek seviye 1 ve katalog nadirliğiyle başlar.
      for (final instance in restored.profile.ownedItems) {
        expect(instance.level, 1);
        expect(instance.rarity, isNull);
      }
      // Sayaç örneklerin üstünde: sonraki satın alma kimlik çakıştırmasın.
      expect(restored.profile.nextItemInstanceId, greaterThan(2));
    });
  });

  group('demirci — yükseltme', () {
    /// Envanterde bir örneği açıp "yükselt" düğmesine basar.
    Future<void> tapUpgrade(WidgetTester tester, Item item) async {
      await openItem(tester, item);
      await tester.tap(find.textContaining('yükselt'));
      await tester.pumpAndSettle();
    }

    testWidgets('yükseltme parayı düşürür ve seviyeyi artırır', (tester) async {
      final profile = await pumpInventory(
        tester,
        profile: makeProfile(coins: 5000, owned: [sword.id]),
      );

      final resolved = flavorForClass(sword, _avatar.characterClass);
      final cost = upgradeCostFor(resolved.cost, resolved.rarity, 1);

      await tapUpgrade(tester, sword);

      expect(profile.ownedItems.single.level, 2);
      expect(profile.coins, 5000 - cost);
    });

    testWidgets('yükseltme yalnızca seçilen örneği etkiler', (tester) async {
      // Aynı eşyadan iki adet: biri yükselirse öbürü Sv.1'de kalmalı.
      final profile = UserProfile(
        avatar: _avatar,
        level: 50,
        coins: 5000,
        ownedItems: [
          OwnedItem(instanceId: 1, itemId: sword.id),
          OwnedItem(instanceId: 2, itemId: sword.id),
        ],
        nextItemInstanceId: 3,
      );
      await pumpInventory(tester, profile: profile);

      await tapUpgrade(tester, sword);

      final levels = profile.ownedItems.map((i) => i.level).toList()..sort();
      expect(levels, [1, 2]);
    });

    testWidgets('para yetmezse yükseltme olmaz ve sebebi söylenir', (
      tester,
    ) async {
      final profile = await pumpInventory(
        tester,
        profile: makeProfile(coins: 0, owned: [sword.id]),
      );

      await openItem(tester, sword);
      expect(find.text('Yükseltilemiyor'), findsOneWidget);
      expect(find.textContaining('coin gerekiyor'), findsOneWidget);
      expect(profile.ownedItems.single.level, 1);
      expect(profile.coins, 0);
    });

    testWidgets('oyuncu seviyesi bağlıyorsa sebebi ayrı söylenir', (
      tester,
    ) async {
      // 1. seviyedeki oyuncu eşyasını yükseltemez; nadirlik tavanı dolu
      // olmadığı hâlde engel var ve bu **söylenmeli** (Model Kuralları #4).
      final profile = await pumpInventory(
        tester,
        profile: makeProfile(level: 1, coins: 99999, owned: [sword.id]),
      );

      await openItem(tester, sword);
      expect(find.textContaining('kendi seviyeni'), findsOneWidget);
      expect(profile.ownedItems.single.level, 1);
    });

    testWidgets('nadirlik tavanında sebep nadirlik sınırı olur', (
      tester,
    ) async {
      final profile = UserProfile(
        avatar: _avatar,
        level: 50,
        coins: 99999,
        ownedItems: [
          // Sıradan bir kılıç tavana (10) çıkarılmış.
          OwnedItem(instanceId: 1, itemId: sword.id, level: 10),
        ],
        nextItemInstanceId: 2,
      );
      await pumpInventory(tester, profile: profile);

      await openItem(tester, sword);
      expect(find.textContaining('Nadirlik sınırı'), findsOneWidget);
      expect(profile.ownedItems.single.level, 10);
      expect(profile.coins, 99999);
    });

    testWidgets('yükseltme savaş statını büyütür, ekonomiye dokunmaz', (
      tester,
    ) async {
      final profile = UserProfile(
        avatar: _avatar,
        level: 50,
        coins: 99999,
        ownedItems: [
          OwnedItem(instanceId: 1, itemId: sword.id, equipped: true),
        ],
        nextItemInstanceId: 2,
      );
      await pumpInventory(tester, profile: profile);

      final base = flavorForClass(sword, _avatar.characterClass);
      final before = resolveOwnedItem(base, profile.ownedItems.single);

      await tapUpgrade(tester, sword);

      final after = resolveOwnedItem(base, profile.ownedItems.single);
      expect(profile.ownedItems.single.level, 2);

      // Ekonomi bonusları **sabit**: yükseltme adım kazançlarını
      // katlamamalı (`economy_pacing_test.dart` bu dengeyi ölçüyor).
      expect(after.buff.stepCoinBonus, before.buff.stepCoinBonus);
      expect(after.buff.stepXpBonus, before.buff.stepXpBonus);
      expect(after.buff.enemyXpBonus, before.buff.enemyXpBonus);

      // Savaş statlarından en az biri büyümüş olmalı.
      final grew = [
        for (var i = 0; i < before.buff.combatEffects.length; i++)
          after.buff.combatEffects[i].value.abs() >
              before.buff.combatEffects[i].value.abs(),
      ];
      expect(grew, contains(true));
    });

    testWidgets('yükseltilmiş seviye diske yazılır', (tester) async {
      final profile = await pumpInventory(
        tester,
        profile: makeProfile(coins: 5000, owned: [sword.id]),
      );

      await tapUpgrade(tester, sword);
      await GameStorage.flush();

      final raw = (await SharedPreferences.getInstance()).getString(
        _storageKey,
      );
      final envelope = jsonDecode(raw!) as Map<String, dynamic>;
      final stored =
          (envelope['state'] as Map<String, dynamic>)['profile']
              as Map<String, dynamic>;
      expect((stored['ownedItems'] as List).single, containsPair('level', 2));

      final restored = await GameStorage.load(avatar: _avatar);
      expect(restored!.profile.ownedItems.single.level, 2);
      expect(profile.ownedItems.single.level, 2);
    });

    testWidgets('yükseltilmiş eşyanın satış değeri fiyattan hesaplanır', (
      tester,
    ) async {
      // Yükseltmeye harcanan coin geri gelmiyor (GD29): satış geri alınamaz
      // ve alım-satım-yükseltme döngüsü para üretemiyor.
      final profile = UserProfile(
        avatar: _avatar,
        level: 50,
        coins: 0,
        ownedItems: [OwnedItem(instanceId: 1, itemId: sword.id, level: 8)],
        nextItemInstanceId: 2,
      );
      await pumpInventory(tester, profile: profile);

      final resolved = flavorForClass(sword, _avatar.characterClass);
      await openItem(tester, sword);
      await tester.tap(find.textContaining('Sat +'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Sat (+'));
      await tester.pumpAndSettle();

      expect(profile.ownedItems, isEmpty);
      expect(profile.coins, sellValueFor(resolved.cost));
      expect(
        profile.coins,
        lessThan(resolved.cost),
        reason: 'satış fiyattan ucuz olmalı; döngü para üretmemeli',
      );
    });
  });

  group('tavan bonusları', () {
    test('kuşanılan stok bonusu mağaza satın almasını açar', () {
      // Stok tabanda doluyken buff'lı tavan bir hak daha veriyor.
      final profile =
          makeProfile()..streakFreezes = GameConstants.maxStreakFreezes;

      expect(profile.grantStreakFreeze(), 0);
      expect(
        profile.grantStreakFreeze(1, GameConstants.maxStreakFreezes + 1),
        1,
      );
      expect(profile.streakFreezes, GameConstants.maxStreakFreezes + 1);
    });

    test('buffsız tavan hâlâ tutuyor', () {
      final profile = makeProfile()..extraWheelSpins = 0;
      for (var i = 0; i < 10; i++) {
        profile.grantExtraWheelSpin();
      }
      expect(profile.extraWheelSpins, GameConstants.maxExtraWheelSpins);
    });
  });

  group('sayfa başına dön', () {
    testWidgets('envanter aşağı kaydırılınca kısayol görünür ve başa döner', (
      tester,
    ) async {
      await pumpInventory(
        tester,
        profile: makeProfile(owned: List.filled(20, sword.id)),
      );

      final scrollFinder = find.byKey(const ValueKey('inventory-scroll-view'));
      final scrollView = tester.widget<CustomScrollView>(scrollFinder);
      final controller = scrollView.controller!;

      expect(find.byTooltip('Başa dön'), findsNothing);

      await tester.drag(scrollFinder, const Offset(0, -1200));
      await tester.pump();

      expect(controller.offset, greaterThan(200));
      expect(find.byTooltip('Başa dön'), findsOneWidget);

      await tester.tap(find.byTooltip('Başa dön'));
      await tester.pumpAndSettle();

      expect(controller.offset, closeTo(0, 0.1));
    });
  });
}
