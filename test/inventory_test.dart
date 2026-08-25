import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/game_constants.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/game_clock.dart';
import 'package:rush_for_villains/core/utils/item_rules.dart';
import 'package:rush_for_villains/features/root/root_shell.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_progress.dart';
import 'package:rush_for_villains/models/game_state.dart';
import 'package:rush_for_villains/models/item.dart';
import 'package:rush_for_villains/models/item_effect.dart';
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
  );

  final catalog = [sword, betterSword, lockedSword, shield, bow, boostItem];

  /// Ekranda görünen ad **sınıfa uyarlanmış** addır (GD16): paylaşılan
  /// kategorilerde sınıf lakabı öne gelir. Testler kimlikle çalışıyor ama
  /// dokunmak için görünen adı bulmak zorunda.
  String shown(Item item) => flavorForClass(item, _avatar.characterClass).name;

  UserProfile makeProfile({
    int level = 50,
    int coins = 1000,
    List<String>? owned,
    Map<String, String>? equipped,
  }) => UserProfile(
    avatar: _avatar,
    level: level,
    coins: coins,
    ownedItemIds: owned,
    equippedItemIds: equipped,
  );

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

      expect(profile.equippedItemIds[ItemCategory.swords.folder], sword.id);
      expect(profile.isEquipped(sword.id), isTrue);
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
      expect(profile.equippedItemIds, hasLength(1));
      expect(
        profile.equippedItemIds[ItemCategory.swords.folder],
        betterSword.id,
      );
      expect(profile.isEquipped(sword.id), isFalse);
      // Yerinden edilen item **satılmaz**, sahiplikte kalır.
      expect(profile.ownedItemIds, contains(sword.id));
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

      expect(profile.equippedItemIds, hasLength(2));
      expect(profile.isEquipped(sword.id), isTrue);
      expect(profile.isEquipped(shield.id), isTrue);
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

      expect(profile.equippedItemIds, isEmpty);
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
      expect(profile.equippedItemIds, isEmpty);
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

      expect(profile.isEquipped(lockedSword.id), isTrue);
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
      await tester.tap(find.text('+5000 adım'));
      await tester.pumpAndSettle();
      final plainCoins = withoutBuff.coins;

      final withBuff = makeProfile(
        coins: 0,
        owned: [boostItem.id],
        equipped: {boostItem.category.folder: boostItem.id},
      );
      await pumpInventory(tester, profile: withBuff, openInventory: false);
      await tester.tap(find.text('+5000 adım'));
      await tester.pumpAndSettle();

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

      expect(profile.equippedItemIds, isEmpty);

      // Kuşanma kalktı: aynı adım artık bonussuz ödeniyor.
      // Envanter itilen bir rota; ana ekrana dönmek için geri gitmek gerek.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('+5000 adım'));
      await tester.pumpAndSettle();

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

      expect(profile.ownedItemIds, isEmpty);
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

      expect(profile.ownedItemIds, [sword.id]);
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

      expect(profile.equippedItemIds, isEmpty);
      expect(profile.ownedItemIds, isEmpty);
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

      expect(profile.equippedItemIds, isEmpty);
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
      expect(profile.equippedItemIds, isEmpty);
      expect(profile.ownedItemIds, contains(bow.id));
    });

    testWidgets('yanlış slota yazılmış kimlik düşer', (tester) async {
      final profile = await pumpInventory(
        tester,
        profile: makeProfile(
          owned: [sword.id],
          equipped: {ItemCategory.shields.folder: sword.id},
        ),
      );

      expect(profile.equippedItemIds, isEmpty);
      expect(profile.ownedItemIds, contains(sword.id));
    });

    testWidgets('katalogdan kalkmış kimlik çökmeye yol açmaz', (tester) async {
      final profile = await pumpInventory(
        tester,
        profile: makeProfile(
          owned: const ['swords/silinmis_item'],
          equipped: {ItemCategory.swords.folder: 'swords/silinmis_item'},
        ),
      );

      expect(profile.equippedItemIds, isEmpty);
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
      expect(stored['equippedItemIds'], {ItemCategory.swords.folder: sword.id});

      // Diskten geri okunduğunda aynı kuşanma geliyor.
      final restored = await GameStorage.load(avatar: _avatar);
      expect(
        restored!.profile.equippedItemIds[ItemCategory.swords.folder],
        sword.id,
      );
      expect(profile.isEquipped(sword.id), isTrue);
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
      expect(restored.profile.equippedItemIds, isEmpty);
    });

    test('bozuk kuşanma satırları atılır, sağlamlar korunur', () {
      final profile = UserProfile.fromJson(const {
        'equippedItemIds': {
          'swords': 'swords/sword',
          'shields': 42,
          '': 'swords/other',
          'spears': null,
        },
      }, avatar: _avatar);

      expect(profile.equippedItemIds, {'swords': 'swords/sword'});
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
}
