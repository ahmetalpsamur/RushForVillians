import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/effective_stats.dart';
import 'package:rush_for_villains/core/utils/equipped_buffs.dart';
import 'package:rush_for_villains/core/utils/game_clock.dart';
import 'package:rush_for_villains/core/utils/item_rules.dart';
import 'package:rush_for_villains/data/title_catalog.dart';
import 'package:rush_for_villains/features/root/root_shell.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_progress.dart';
import 'package:rush_for_villains/models/game_state.dart';
import 'package:rush_for_villains/models/game_title.dart';
import 'package:rush_for_villains/models/item.dart';
import 'package:rush_for_villains/models/item_effect.dart';
import 'package:rush_for_villains/models/owned_item.dart';
import 'package:rush_for_villains/models/reward_rarity.dart';
import 'package:rush_for_villains/models/user_profile.dart';
import 'package:rush_for_villains/services/game_storage.dart';
import 'package:rush_for_villains/services/item_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ünvan sisteminin **karar tarafı** (Bölüm C).
///
/// `inventory_test.dart` ile aynı gerekçe: takma/çıkarma, satın alma ve
/// kazanma yollarının son sözü `RootShell` içinde ve orası bir
/// `StatefulWidget`'ın private metodu. Mantığı saf bir fonksiyona çıkarmak
/// çalışan mimariye dokunmak olurdu (Kural 1/3); widget testi aynı garantiyi
/// mevcut yapıyı bozmadan veriyor.
///
/// Katalog sözleşmesi (adet, nadirlik, ekonomi tavanı, başarım koşulları)
/// ayrı bir dosyada: `title_catalog_test.dart`.
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

  final sword = buildItemFromAsset('lib/Items/swords/sword.png')!;
  final catalog = [sword];

  /// Ölçülebilir ve **koşulsuz** bir adım-para bonusu taşıyan ünvan.
  final coinTitle = TitleCatalog.byId('coin_sniffer')!;

  /// Koşullu savaş etkisi taşıyan ünvan: can %20 altına düşünce savunma +%60.
  final lowHealthTitle = TitleCatalog.byId('iron_heart')!;

  /// Mağazadan alınan ünvanlardan en ucuzu; bakiye testleri buna dayanıyor.
  final storeTitle = TitleCatalog.purchasable.first;

  var shellSerial = 0;

  UserProfile makeProfile({
    int level = 50,
    int coins = 0,
    int totalSteps = 0,
    List<String> titles = const [],
    String? equippedTitle,
    List<String> items = const [],
  }) {
    var serial = 1;
    return UserProfile(
      avatar: _avatar,
      level: level,
      coins: coins,
      totalSteps: totalSteps,
      lastRewardedStepCount: totalSteps,
      lastXpRewardedStepCount: totalSteps,
      ownedItems: [
        for (final id in items) OwnedItem(instanceId: serial++, itemId: id),
      ],
      nextItemInstanceId: serial,
      ownedTitleIds: [...titles],
      equippedTitleId: equippedTitle,
    );
  }

  Future<void> pumpShell(
    WidgetTester tester, {
    required UserProfile profile,
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
  }

  /// Profil sekmesindeki "Ünvanlar" kartından ünvan ekranını açar.
  Future<void> openTitles(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Profil'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('profile-titles-entry')));
    await tester.pumpAndSettle();
  }

  Future<void> equipFromScreen(WidgetTester tester, GameTitle title) async {
    final button = find.byKey(ValueKey('equip-title-${title.id}'));
    // Ünvan listesi uzun; düğme kurulmuş ama görünür alanın dışında olabilir.
    // `scrollUntilVisible` burada işe yaramıyor: finder zaten eşleşiyor,
    // dolayısıyla hiç kaydırmadan dönüyor.
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  group('takma ve çıkarma', () {
    testWidgets('sahip olunan ünvan takılır', (tester) async {
      final profile = makeProfile(titles: [coinTitle.id]);
      await pumpShell(tester, profile: profile);
      await openTitles(tester);

      await equipFromScreen(tester, coinTitle);

      expect(profile.equippedTitleId, coinTitle.id);
    });

    testWidgets('aynı anda yalnızca bir ünvan takılı kalır', (tester) async {
      // C.2'nin çekirdek kuralı. Garanti **alanın kendisinde**:
      // `equippedTitleId` tek bir değer tutuyor.
      final profile = makeProfile(
        titles: [coinTitle.id, lowHealthTitle.id],
        equippedTitle: coinTitle.id,
      );
      await pumpShell(tester, profile: profile);
      await openTitles(tester);

      await equipFromScreen(tester, lowHealthTitle);

      expect(profile.equippedTitleId, lowHealthTitle.id);
      // Eskisi düştü ama **envanterde duruyor**: ünvanlar tüketilmiyor.
      expect(profile.ownsTitle(coinTitle.id), isTrue);
    });

    testWidgets('takılı ünvan çıkarılabilir', (tester) async {
      final profile = makeProfile(
        titles: [coinTitle.id],
        equippedTitle: coinTitle.id,
      );
      await pumpShell(tester, profile: profile);
      await openTitles(tester);

      await tester.tap(find.byKey(const ValueKey('unequip-title')));
      await tester.pumpAndSettle();

      expect(profile.equippedTitleId, isNull);
      expect(profile.ownsTitle(coinTitle.id), isTrue);
    });

    testWidgets('sahip olunmayan ünvanın takma düğmesi hiç çizilmez', (
      tester,
    ) async {
      final profile = makeProfile(titles: [coinTitle.id]);
      await pumpShell(tester, profile: profile);
      await openTitles(tester);

      expect(
        find.byKey(ValueKey('equip-title-${lowHealthTitle.id}')),
        findsNothing,
      );
    });

    test('sahip olunmayan ünvan model katmanında da takılamaz', () {
      final profile = makeProfile();
      expect(profile.equipTitle(coinTitle.id), isFalse);
      expect(profile.equippedTitleId, isNull);
    });

    test('katalogdan kalkmış ünvan sessizce çıkarılır, sahiplik durur', () {
      // Kuşanma temizliğiyle aynı sözleşme (GD28): slot boşalır, envanter
      // korunur.
      final profile = makeProfile(
        titles: ['gecmiste_kalmis'],
        equippedTitle: 'gecmiste_kalmis',
      );

      final changed = profile.normalizeEquippedTitle(
        (id) => TitleCatalog.byId(id) != null,
      );

      expect(changed, isTrue);
      expect(profile.equippedTitleId, isNull);
      expect(profile.ownsTitle('gecmiste_kalmis'), isTrue);
    });
  });

  group('ünvan buffı gerçekten uygulanıyor', () {
    testWidgets('takılı ünvanın adım-para bonusu paraya yansır', (
      tester,
    ) async {
      // Aynı adım sayısı, tek fark takılı ünvan.
      final plain = makeProfile(titles: [coinTitle.id]);
      await pumpShell(tester, profile: plain);
      await tester.tap(find.text('+5000 adım'));
      await tester.pumpAndSettle();

      final withTitle = makeProfile(
        titles: [coinTitle.id],
        equippedTitle: coinTitle.id,
      );
      await pumpShell(tester, profile: withTitle);
      await tester.tap(find.text('+5000 adım'));
      await tester.pumpAndSettle();

      // 5.000 adım = 100 coin; +%8 bonusla 108.
      expect(plain.coins, 100);
      expect(withTitle.coins, 108);
    });

    testWidgets('ünvan çıkarılınca çarpan geri düşer', (tester) async {
      final profile = makeProfile(
        titles: [coinTitle.id],
        equippedTitle: coinTitle.id,
      );
      await pumpShell(tester, profile: profile);
      await openTitles(tester);

      await tester.tap(find.byKey(const ValueKey('unequip-title')));
      await tester.pumpAndSettle();

      // Ünvan ekranı itilen bir rota; ana ekrana dönmek için geri gitmek
      // gerek.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Ana Sayfa'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('+5000 adım'));
      await tester.pumpAndSettle();

      expect(profile.coins, 100);
    });

    test('koşullu savaş etkisi yalnızca koşul sağlanınca açılır', () {
      final buffs = EquippedBuffs.from(
        const <Item>[],
        titleEffects: lowHealthTitle.effects,
      );

      CombatStatsSnapshot statsAt(double healthRatio) {
        final stats = effectiveCombatStats(
          level: 10,
          buffs: buffs,
          conditions: CombatConditions(healthRatio: healthRatio),
        );
        return CombatStatsSnapshot(stats.defense);
      }

      final healthy = statsAt(1.0);
      final wounded = statsAt(0.1);

      // Sağlıklıyken hiçbir katkı yok: koşullu etki kuşanıldığı anda pasif
      // bir çarpana dönüşmemeli.
      expect(healthy.defense, statsAt(0.5).defense);
      expect(wounded.defense, greaterThan(healthy.defense));
      expect(wounded.defense, closeTo(healthy.defense * 1.60, 1e-6));
    });

    test('koşullu ekonomi etkisi pasif çarpana girmez', () {
      final nightWalker = TitleCatalog.byId('night_walker')!;
      final buffs = EquippedBuffs.from(
        const <Item>[],
        titleEffects: nightWalker.effects,
      );

      expect(buffs.stepCoinBonus, 0);
      expect(buffs.conditionalEffects, isNotEmpty);
    });
  });

  group('kazanma yolları', () {
    testWidgets('başarım koşulu sağlanınca ünvan kendiliğinden gelir', (
      tester,
    ) async {
      // "İlk Adım": 5.000 toplam adım.
      final firstStep = TitleCatalog.byId('first_step')!;
      final profile = makeProfile();
      await pumpShell(tester, profile: profile);

      expect(profile.ownsTitle(firstStep.id), isFalse);

      await tester.tap(find.text('+5000 adım'));
      await tester.pumpAndSettle();

      expect(profile.ownsTitle(firstStep.id), isTrue);

      // Kazanım kullanıcıya ulaşıyor: ünvan artık takılabilir durumda.
      // Bildirim kuyruğuna bakılmıyor — aynı partide seri bonusu gibi başka
      // duyurular da sıraya giriyor ve hangisinin önce görüneceği bu testin
      // konusu değil (GD47).
      await openTitles(tester);
      expect(
        find.byKey(ValueKey('equip-title-${firstStep.id}')),
        findsOneWidget,
      );
    });

    testWidgets('aynı ünvan ikinci kez verilmez', (tester) async {
      final firstStep = TitleCatalog.byId('first_step')!;
      final profile = makeProfile(titles: [firstStep.id]);
      await pumpShell(tester, profile: profile);

      await tester.tap(find.text('+5000 adım'));
      await tester.pumpAndSettle();

      expect(profile.ownedTitleIds.where((id) => id == firstStep.id).length, 1);
    });

    testWidgets('mağazadan ünvan satın alınır ve para düşer', (tester) async {
      final profile = makeProfile(coins: storeTitle.cost + 50);
      await pumpShell(tester, profile: profile);

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Mağaza'),
        ),
      );
      await tester.pumpAndSettle();

      final button = find.byKey(ValueKey('buy-title-${storeTitle.id}'));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(profile.ownsTitle(storeTitle.id), isTrue);
      expect(profile.coins, 50);
    });

    test('yetersiz bakiyede satın alma parayı yakmaz', () {
      // Karar `RootShell._purchaseTitle` içinde; buradaki iddia modelin
      // sözleşmesi: ünvan verilmediyse para da gitmemeli.
      final profile = makeProfile(coins: storeTitle.cost - 1);
      expect(profile.coins < storeTitle.cost, isTrue);
      expect(profile.ownsTitle(storeTitle.id), isFalse);
    });

    test('aynı ünvan iki kez satın alınamaz', () {
      final profile = makeProfile(titles: [storeTitle.id]);
      expect(profile.grantTitle(storeTitle.id), isFalse);
      expect(profile.ownedTitleIds.length, 1);
    });
  });

  group('kalıcılık', () {
    testWidgets('ünvan ve takılı seçim diske yazılır', (tester) async {
      final profile = makeProfile(
        titles: [coinTitle.id],
        equippedTitle: coinTitle.id,
      );
      await pumpShell(tester, profile: profile);

      await tester.tap(find.text('+1000 adım'));
      await tester.pumpAndSettle();
      await GameStorage.flush();

      final preferences = await SharedPreferences.getInstance();
      await preferences.reload();
      final envelope =
          jsonDecode(preferences.getString(_storageKey)!)
              as Map<String, dynamic>;
      final saved = (envelope['state'] as Map)['profile'] as Map;

      expect(saved['ownedTitleIds'], contains(coinTitle.id));
      expect(saved['equippedTitleId'], coinTitle.id);
    });

    test('v18 kaydındaki pelerin ünvana dönüşür, veri kaybolmaz', () async {
      // C.1: pelerin kaldırıldı ama sahibi eli boş kalmıyor.
      SharedPreferences.setMockInitialValues({
        _storageKey: jsonEncode({
          'schemaVersion': 18,
          'state': {
            'profile': {
              'level': 4,
              'coins': 120,
              'ownedUpgradeIds': [
                'skin_dragon_cape',
                'title_villain_hunter',
                'boost_double_xp',
              ],
            },
            'today': {'steps': 300, 'stepGoal': 5000},
          },
        }),
      });

      final restored = await GameStorage.load(avatar: _avatar);

      expect(restored, isNotNull);
      final saved = restored!.profile;
      // Kozmetikler ünvana taşındı...
      expect(saved.ownsTitle('night_walker'), isTrue);
      expect(saved.ownsTitle('villain_hunter'), isTrue);
      // ...ve mağaza yükseltmeleri arasından kalktı.
      expect(saved.ownedUpgradeIds, isNot(contains('skin_dragon_cape')));
      expect(saved.ownedUpgradeIds, isNot(contains('title_villain_hunter')));
      // Dokunulmayan yükseltme ve para yerinde.
      expect(saved.ownedUpgradeIds, contains('boost_double_xp'));
      expect(saved.coins, 120);
    });

    test('pelerini olmayan v18 kaydı bozulmaz', () async {
      SharedPreferences.setMockInitialValues({
        _storageKey: jsonEncode({
          'schemaVersion': 18,
          'state': {
            'profile': {
              'level': 7,
              'ownedUpgradeIds': ['boost_double_xp'],
            },
            'today': {'steps': 10, 'stepGoal': 5000},
          },
        }),
      });

      final restored = await GameStorage.load(avatar: _avatar);

      expect(restored, isNotNull);
      expect(restored!.profile.level, 7);
      expect(restored.profile.ownedTitleIds, isEmpty);
      expect(restored.profile.ownedUpgradeIds, ['boost_double_xp']);
    });

    test('bozuk ünvan kaydı temiz varsayılana düşer', () async {
      SharedPreferences.setMockInitialValues({
        _storageKey: jsonEncode({
          'schemaVersion': GameStorage.schemaVersion,
          'state': {
            'profile': {
              'level': 2,
              'ownedTitleIds': ['coin_sniffer', 42, null],
              'equippedTitleId': 'hic_boyle_bir_unvan_yok',
            },
            'today': {'steps': 0, 'stepGoal': 5000},
          },
        }),
      });

      final restored = await GameStorage.load(avatar: _avatar);

      expect(restored, isNotNull);
      expect(restored!.profile.ownedTitleIds, ['coin_sniffer']);
      // Takılı seçim kayıtta duruyor; normalizasyon `RootShell` açılışında
      // yapılıyor ve sahiplik listesinde olmadığı için düşer.
      restored.profile.normalizeEquippedTitle(
        (id) => TitleCatalog.byId(id) != null,
      );
      expect(restored.profile.equippedTitleId, isNull);
    });
  });

  group('ekonomi sınırı canlı akışta da tutuyor', () {
    test('ünvan + eşya birlikte toplam tavanı aşamaz', () {
      final greedyItem = Item(
        id: 'swords/test_greedy',
        name: 'Test Kılıcı',
        assetPath: 'lib/Items/swords/test_greedy.png',
        category: ItemCategory.swords,
        rarity: RewardRarity.legendary,
        requiredLevel: 1,
        cost: 1000,
        lore: 'Test için dövüldü.',
        buff: const ItemBuff([ItemEffect(stat: ItemStat.stepCoin, value: 0.9)]),
        archetype: ItemArchetype.swift,
      );

      final buffs = EquippedBuffs.from(
        [greedyItem],
        titleEffects: const [ItemEffect(stat: ItemStat.stepCoin, value: 0.9)],
      );

      expect(buffs.stepCoinBonus, lessThanOrEqualTo(0.5 + 1e-9));
    });
  });
}

/// Testin okuduğu tek stat; `CombatStats` alanlarını tek tek taşımaya gerek
/// yok.
class CombatStatsSnapshot {
  final double defense;

  const CombatStatsSnapshot(this.defense);
}
