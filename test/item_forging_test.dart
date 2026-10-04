import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/constants/game_constants.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/game_clock.dart';
import 'package:rush_for_villains/core/utils/item_forging.dart';
import 'package:rush_for_villains/core/utils/item_leveling.dart';
import 'package:rush_for_villains/core/utils/item_merging.dart';
import 'package:rush_for_villains/core/utils/item_rules.dart';
import 'package:rush_for_villains/data/forge_tiers.dart';
import 'package:rush_for_villains/features/root/root_shell.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_progress.dart';
import 'package:rush_for_villains/models/forged_effect.dart';
import 'package:rush_for_villains/models/game_state.dart';
import 'package:rush_for_villains/models/item.dart';
import 'package:rush_for_villains/models/item_effect.dart';
import 'package:rush_for_villains/models/owned_item.dart';
import 'package:rush_for_villains/models/reward_rarity.dart';
import 'package:rush_for_villains/models/user_profile.dart';
import 'package:rush_for_villains/services/game_storage.dart';
import 'package:rush_for_villains/services/item_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bölüm E / Faz 4: yeniden atma ve keşfedilen buff havuzu (GD112).
const _avatar = AvatarProfile(
  name: 'Barca',
  age: 28,
  weight: 74,
  gender: 'Erkek',
  characterClass: 'SwordMan',
  characterAsset: 'lib/Characters/SwordMan/test.png',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final catalog = ItemCatalog.fromAssetPaths(
    Directory('lib/Items')
        .listSync(recursive: true)
        .whereType<File>()
        .map((file) => file.path.replaceAll(r'\', '/'))
        .where((path) => path.endsWith('.png')),
  );
  Item byId(String id) => catalog.firstWhere((item) => item.id == id);
  Item flavored(String id) => flavorForClass(byId(id), _avatar.characterClass);

  group('maliyet', () {
    test('artan maliyet: 1× · 1,5× · 2× · 2,5× · 3× ve sonra 3×', () {
      final base = GameConstants.forgeRerollBaseCost[RewardRarity.rare]!;
      expect(
        [for (var n = 0; n < 8; n++) rerollCost(RewardRarity.rare, n)],
        [
          base,
          (base * 1.5).round(),
          base * 2,
          (base * 2.5).round(),
          base * 3,
          base * 3,
          base * 3,
          base * 3,
        ],
      );
    });

    test('keşiften seçmek o anki maliyetin 4 katı: n=0 4×, tavanda 12×', () {
      final base = GameConstants.forgeRerollBaseCost[RewardRarity.epic]!;
      expect(pickCost(RewardRarity.epic, 0), base * 4);
      expect(pickCost(RewardRarity.epic, 20), base * 12);
    });

    test('taban nadirlikle artar', () {
      final costs = [
        for (final rarity in RewardRarity.values) rerollCost(rarity, 0),
      ];
      for (var i = 1; i < costs.length; i++) {
        expect(costs[i], greaterThan(costs[i - 1]));
      }
    });
  });

  group('kademe kilidi', () {
    test('kademe nadirlikten, seviye tavanın yarısında en üst kademe açılır', () {
      expect(maxForgeTier(RewardRarity.common, 1), 1);
      expect(maxForgeTier(RewardRarity.common, 10), 1);
      expect(maxForgeTier(RewardRarity.rare, 14), 2);
      expect(maxForgeTier(RewardRarity.rare, 15), 3);
      expect(maxForgeTier(RewardRarity.legendary, 1), 4);
      expect(maxForgeTier(RewardRarity.legendary, 25), 5);
    });

    test('rastgele atış eşyanın en yüksek kademesinden çıkar', () {
      final sword = withRarity(
        flavored('swords/sword_variant_01'),
        RewardRarity.legendary,
        characterClass: _avatar.characterClass,
      );
      for (var seed = 1; seed < 200; seed++) {
        final low = rollForge(
          seed: seed,
          item: sword,
          slot: 0,
          rarity: RewardRarity.legendary,
          level: 1,
          characterClass: _avatar.characterClass,
        );
        expect(low.effect.tier, 4);
        final high = rollForge(
          seed: seed,
          item: sword,
          slot: 0,
          rarity: RewardRarity.legendary,
          level: 30,
          characterClass: _avatar.characterClass,
        );
        expect(high.effect.tier, 5);
      }
    });
  });

  group('atış', () {
    final sword = withRarity(
      flavored('swords/sword_variant_01'),
      RewardRarity.epic,
      characterClass: _avatar.characterClass,
    );

    test('deterministik: aynı tohum aynı sonuç, tohum ilerler', () {
      ForgeRoll roll(int seed) => rollForge(
        seed: seed,
        item: sword,
        slot: 1,
        rarity: RewardRarity.epic,
        level: 20,
        characterClass: _avatar.characterClass,
      );
      expect(roll(12345).effect, roll(12345).effect);
      expect(roll(12345).nextSeed, nextForgeSeed(12345));
      expect(nextForgeSeed(12345), isNot(12345));
      // Dizi bir döngüye hemen düşmüyor: 50 atışta birden fazla sonuç.
      final seen = <ForgedEffect>{};
      var seed = 777;
      for (var i = 0; i < 50; i++) {
        final next = roll(seed);
        seen.add(next.effect);
        seed = next.nextSeed;
      }
      expect(seen.length, greaterThan(10));
    });

    test('değer aralığın içinde ve adıma oturuyor; uçlar çekilebiliyor', () {
      for (var slot = 0; slot < forgeSlotCount(sword); slot++) {
        final seenLow = <ItemStat>{};
        final seenHigh = <ItemStat>{};
        var seed = 1;
        for (var i = 0; i < 3000; i++) {
          final roll = rollForge(
            seed: seed,
            item: sword,
            slot: slot,
            rarity: RewardRarity.epic,
            level: 20,
            characterClass: _avatar.characterClass,
          );
          seed = roll.nextSeed;
          final effect = roll.effect;
          final (low, high) = ForgeTiers.rangeFor(effect.stat, effect.tier)!;
          expect(effect.value, inInclusiveRange(low - 1e-9, high + 1e-9));
          final steps = (effect.value - low) / ForgeTiers.stepFor(effect.stat);
          expect((steps - steps.round()).abs(), lessThan(1e-6));
          if ((effect.value - low).abs() < 1e-9) seenLow.add(effect.stat);
          if ((effect.value - high).abs() < 1e-9) seenHigh.add(effect.stat);
        }
        expect(seenLow, isNotEmpty, reason: 'yuva $slot');
        expect(seenHigh, isNotEmpty, reason: 'yuva $slot');
      }
    });

    test('yuvanın türü korunur ve başka yuvadaki stat gelmez', () {
      for (var slot = 0; slot < forgeSlotCount(sword); slot++) {
        final current = forgeSlotEffect(sword, slot).stat;
        final others = {
          for (var i = 0; i < sword.buff.effects.length; i++)
            if (i != slot) sword.buff.effects[i].stat,
        };
        var seed = 99;
        for (var i = 0; i < 500; i++) {
          final roll = rollForge(
            seed: seed,
            item: sword,
            slot: slot,
            rarity: RewardRarity.epic,
            level: 20,
            characterClass: _avatar.characterClass,
          );
          seed = roll.nextSeed;
          expect(roll.effect.stat.isCombat, current.isCombat);
          expect(others, isNot(contains(roll.effect.stat)));
        }
      }
    });

    test('savaş havuzu eşyanın arketipinden: kalkana saldırı kurgusu yok', () {
      // Muhafız arketipinin savaş statları: savunma, can, saldırı.
      final shields = [
        for (final item in catalog)
          if (item.category == ItemCategory.shields &&
              item.archetype == ItemArchetype.guardian &&
              !item.hasSignature)
            item,
      ];
      final shield = shields.first;
      for (var slot = 0; slot < forgeSlotCount(shield); slot++) {
        if (!forgeSlotEffect(shield, slot).stat.isCombat) continue;
        expect(
          forgeSlotPool(shield, slot).keys,
          everyElement(
            isIn([ItemStat.defense, ItemStat.maxHealth, ItemStat.attack]),
          ),
        );
      }
    });

    test('seçilen tür ve kademe kesin, değer yine rastgele', () {
      final values = <double>{};
      var seed = 5;
      for (var i = 0; i < 200; i++) {
        final roll = rollForge(
          seed: seed,
          item: sword,
          slot: 0,
          rarity: RewardRarity.epic,
          level: 20,
          characterClass: _avatar.characterClass,
          chosenStat: ItemStat.stepXp,
          chosenTier: 3,
        );
        seed = roll.nextSeed;
        expect(roll.effect.stat, ItemStat.stepXp);
        expect(roll.effect.tier, 3);
        values.add(roll.effect.value);
      }
      expect(values.length, greaterThan(5));
    });
  });

  group('imzalı etki', () {
    test('imzalı etkiler yeniden atılamaz: yuvalar yalnızca dolgu', () {
      final reaper = flavored('scythes/reapers_scythe');
      expect(signatureCoreCount(reaper), 4);
      expect(forgeSlotCount(reaper), 0);

      final meteor = flavored('arch/meteor_strike_arrow');
      expect(signatureCoreCount(meteor), 3);
      expect(forgeSlotCount(meteor), 1);
      // Tek yuva, imzanın **arkasındaki** dolgu.
      expect(forgeSlotEffect(meteor, 0), meteor.buff.effects[3]);
    });

    test('atılmış dolgu imzayı değiştirmez', () {
      final meteor = flavored('arch/meteor_strike_arrow');
      final instance = OwnedItem(
        instanceId: 1,
        itemId: meteor.id,
        forgedEffects: const [
          ForgedEffect(stat: ItemStat.attack, tier: 5, value: 25),
        ],
      );
      final resolved = resolveOwnedItem(
        meteor,
        instance,
        characterClass: _avatar.characterClass,
      );
      expect(resolved.buff.effects.take(3).toList(), meteor.buff.effects.take(3));
      expect(resolved.buff.effects[3].stat, ItemStat.attack);
      expect(resolved.buff.effects[3].value, 25);
    });
  });

  group('çözümleme', () {
    final dagger = flavored('swords/dagger_variant_01');

    test('null = türetilmiş: atılmamış eşya eskisi gibi çözülür', () {
      const instance = OwnedItem(instanceId: 1, itemId: 'swords/dagger_variant_01');
      expect(
        resolveOwnedItem(dagger, instance).buff.labels,
        dagger.buff.labels,
      );
    });

    test('atılmış savaş etkisi seviyeyle büyür', () {
      final combatSlot = [
        for (var slot = 0; slot < forgeSlotCount(dagger); slot++)
          if (forgeSlotEffect(dagger, slot).stat.isCombat) slot,
      ].first;
      final forged = [
        for (var slot = 0; slot < forgeSlotCount(dagger); slot++)
          forgedFromEffect(forgeSlotEffect(dagger, slot)),
      ];
      final instance = OwnedItem(
        instanceId: 1,
        itemId: dagger.id,
        level: 10,
        forgedEffects: forged,
      );
      final resolved = resolveOwnedItem(dagger, instance);
      expect(
        resolved.buff.effects[combatSlot].value,
        greaterThan(forged[combatSlot].value),
      );
    });

    test('uzunluk uyuşmazsa türetilmiş buff\'a düşer, eşya kaybolmaz', () {
      const instance = OwnedItem(
        instanceId: 1,
        itemId: 'swords/dagger_variant_01',
        forgedEffects: [ForgedEffect(stat: ItemStat.attack, tier: 1, value: 5)],
      );
      expect(
        resolveOwnedItem(dagger, instance).buff.labels,
        dagger.buff.labels,
      );
    });

    test('%15 tek eşya tavanı atılmış etkilere de uygulanır', () {
      final legendary = withRarity(dagger, RewardRarity.legendary);
      final slots = forgeSlotCount(legendary);
      final forged = [
        for (var slot = 0; slot < slots; slot++)
          slot == 0
              ? const ForgedEffect(stat: ItemStat.stepCoin, tier: 5, value: 0.091)
              : forgedFromEffect(forgeSlotEffect(legendary, slot)),
      ];
      // Elle bozulmuş bir kayıt aynı stata ikinci bir pay koymuş olsun.
      forged[1] = const ForgedEffect(
        stat: ItemStat.stepCoin,
        tier: 5,
        value: 0.091,
      );
      final instance = OwnedItem(
        instanceId: 1,
        itemId: dagger.id,
        rarity: RewardRarity.legendary,
        forgedEffects: forged,
      );
      final resolved = resolveOwnedItem(dagger, instance);
      expect(
        resolved.buff.stepCoinBonus,
        lessThanOrEqualTo(GameConstants.maxSingleItemEconomyBonus + 1e-9),
      );
    });
  });

  group('kayıt', () {
    test('örnek kayıt turu atılmış etkiyi, sayacı ve bekleyen kararı korur', () {
      const instance = OwnedItem(
        instanceId: 3,
        itemId: 'swords/dagger_variant_01',
        forgedEffects: [
          ForgedEffect(stat: ItemStat.attack, tier: 2, value: 12),
          ForgedEffect(stat: ItemStat.stepXp, tier: 2, value: 0.021),
        ],
        rerollCount: 4,
        pendingForge: PendingForge(
          slot: 1,
          effect: ForgedEffect(stat: ItemStat.wheelXp, tier: 2, value: 0.04),
        ),
      );
      final restored = OwnedItem.fromJson(
        jsonDecode(jsonEncode(instance.toJson())),
      )!;
      expect(restored.forgedEffects, instance.forgedEffects);
      expect(restored.rerollCount, 4);
      expect(restored.pendingForge!.slot, 1);
      expect(restored.pendingForge!.effect, instance.pendingForge!.effect);
    });

    test('hiç atılmamış örneğin satırı Bölüm E öncesiyle aynı', () {
      const instance = OwnedItem(instanceId: 1, itemId: 'swords/sword');
      expect(instance.toJson().keys.toSet(), {
        'instanceId',
        'itemId',
        'level',
        'rarity',
        'equipped',
      });
    });

    test('v32 kaydı v33\'e göçer: eşyalar türetilmiş kalır, keşif boş', () async {
      final rows = [
        {
          'instanceId': 1,
          'itemId': 'swords/dagger_variant_01',
          'level': 4,
          'rarity': 'rare',
          'equipped': true,
        },
      ];
      SharedPreferences.setMockInitialValues({
        'game_state_v1': jsonEncode({
          'schemaVersion': 32,
          'savedAt': '2026-10-02T10:00:00.000',
          'state': {
            'profile': {
              'level': 20,
              'coins': 900,
              'ownedItems': rows,
              'nextItemInstanceId': 2,
              'wheelSeed': 4242,
            },
            'today': {'steps': 0, 'stepGoal': 7000},
          },
        }),
      });
      final restored = await GameStorage.load(avatar: _avatar);
      expect(restored, isNotNull);
      expect(GameStorage.schemaVersion, 33);
      final profile = restored!.profile;
      expect(profile.ownedItems.single.forgedEffects, isNull);
      expect(profile.ownedItems.single.rerollCount, 0);
      expect(profile.ownedItems.single.toJson(), rows.single);
      expect(profile.discoveredAffixes, isEmpty);
      expect(profile.forgeSeed, 0);
      // Çark tohumu ayrı akış: dokunulmadı.
      expect(profile.wheelSeed, 4242);

      final prefs = await SharedPreferences.getInstance();
      final saved =
          jsonDecode(prefs.getString('game_state_v1')!) as Map<String, dynamic>;
      expect(saved['schemaVersion'], 33);
    });
  });

  group('RootShell üzerinden', () {
    final sword = buildItemFromAsset('lib/Items/swords/sword.png')!;
    var shellSerial = 0;

    Future<UserProfile> pumpForge(
      WidgetTester tester, {
      int coins = 5000,
      List<String> discovered = const [],
      int forgeSeed = 0,
    }) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      ItemCatalog.reset([sword]);
      addTearDown(ItemCatalog.reset);
      final profile = UserProfile(
        avatar: _avatar,
        level: 20,
        coins: coins,
        ownedItems: [OwnedItem(instanceId: 1, itemId: sword.id)],
        nextItemInstanceId: 2,
        discoveredAffixes: [...discovered],
        forgeSeed: forgeSeed,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: RootShell(
            key: ValueKey('reroll-${shellSerial++}'),
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
      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
      final entry = find.byKey(const ValueKey('profile-blacksmith-entry'));
      await tester.ensureVisible(entry);
      await tester.tap(entry);
      await tester.pumpAndSettle();
      return profile;
    }

    Future<void> rollRandom(WidgetTester tester, {int slot = 0}) async {
      await tester.tap(find.byKey(ValueKey('forge-reroll-slot-$slot')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('forge-roll-random')));
      await tester.pumpAndSettle();
    }

    testWidgets('atış parayı alır, sonucu yan yana gösterir, onaysız uygulamaz', (
      tester,
    ) async {
      final profile = await pumpForge(tester);
      final before = resolveOwnedItem(sword, profile.ownedItems.single);

      await rollRandom(tester);

      final base = rerollCost(RewardRarity.common, 0);
      expect(profile.coins, 5000 - base);
      expect(profile.ownedItems.single.rerollCount, 1);
      expect(profile.ownedItems.single.pendingForge, isNotNull);
      // Onay yokken eşya değişmedi.
      expect(profile.ownedItems.single.forgedEffects, isNull);
      expect(
        resolveOwnedItem(sword, profile.ownedItems.single).buff.labels,
        before.buff.labels,
      );
      expect(find.byKey(const ValueKey('forge-decision-panel')), findsOneWidget);
      // Keşif kaydedildi.
      expect(profile.discoveredAffixes, [
        profile.ownedItems.single.pendingForge!.effect.affixKey,
      ]);

      // Karar verilmeden ikinci atış yok.
      await tester.tap(find.byKey(const ValueKey('forge-reroll-slot-0')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('forge-reroll-sheet')), findsNothing);
      expect(profile.coins, 5000 - base);

      await tester.tap(find.byKey(const ValueKey('forge-take-new')));
      await tester.pumpAndSettle();
      final instance = profile.ownedItems.single;
      expect(instance.pendingForge, isNull);
      expect(instance.forgedEffects, isNotNull);
      expect(instance.forgedEffects, hasLength(forgeSlotCount(sword)));
    });

    testWidgets('eskisini korumak eşyayı değiştirmez ama parayı geri vermez', (
      tester,
    ) async {
      final profile = await pumpForge(tester);
      final labels = resolveOwnedItem(sword, profile.ownedItems.single).buff.labels;

      await rollRandom(tester);
      await tester.tap(find.byKey(const ValueKey('forge-keep-old')));
      await tester.pumpAndSettle();

      expect(profile.ownedItems.single.pendingForge, isNull);
      expect(profile.ownedItems.single.forgedEffects, isNull);
      expect(
        resolveOwnedItem(sword, profile.ownedItems.single).buff.labels,
        labels,
      );
      expect(profile.coins, 5000 - rerollCost(RewardRarity.common, 0));
      // Sayaç yine arttı: maliyet örneğe bağlı ve geri dönmüyor.
      expect(profile.ownedItems.single.rerollCount, 1);
    });

    testWidgets('maliyet aynı örnekte artar ve pencerede görünür', (tester) async {
      final profile = await pumpForge(tester);
      await rollRandom(tester);
      await tester.tap(find.byKey(const ValueKey('forge-take-new')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('forge-reroll-slot-0')));
      await tester.pumpAndSettle();
      expect(
        find.text('Rastgele at · ${rerollCost(RewardRarity.common, 1)} altın'),
        findsOneWidget,
      );
      expect(find.text('Bu eşyada 1 kez yeniden atıldı'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('forge-roll-random')));
      await tester.pumpAndSettle();
      expect(
        profile.coins,
        5000 -
            rerollCost(RewardRarity.common, 0) -
            rerollCost(RewardRarity.common, 1),
      );
    });

    testWidgets('aynı tohum iki ayrı oturumda aynı sonucu verir', (tester) async {
      final first = await pumpForge(tester, forgeSeed: 31337);
      await rollRandom(tester);
      final a = first.ownedItems.single.pendingForge!.effect;

      // İlk oturumu (itilmiş demirci rotasıyla birlikte) tamamen sök.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      final second = await pumpForge(tester, forgeSeed: 31337);
      await rollRandom(tester);
      final b = second.ownedItems.single.pendingForge!.effect;

      expect(b, a);
      expect(second.forgeSeed, first.forgeSeed);
    });

    testWidgets('keşif yoksa pahalı seçenek kapalı ve nedenini söyler', (
      tester,
    ) async {
      await pumpForge(tester);
      await tester.tap(find.byKey(const ValueKey('forge-reroll-slot-0')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('forge-pick-none')), findsOneWidget);
      expect(find.byKey(const ValueKey('forge-roll-pick')), findsNothing);
    });

    testWidgets('keşiften seç: iki adım, 4 kat fiyat, tür ve kademe kesin', (
      tester,
    ) async {
      // Sıradan kılıç: kademe I. Başka eşyada öğrenilmiş bir keşif (oyuncu
      // çapında) bu yuvada da seçilebilir.
      final economySlot = [
        for (var slot = 0; slot < forgeSlotCount(sword); slot++)
          if (!forgeSlotEffect(flavorForClass(sword, _avatar.characterClass), slot)
              .stat
              .isCombat)
            slot,
      ].first;
      final profile = await pumpForge(
        tester,
        discovered: [forgeAffixKey(ItemStat.wheelXp, 1)],
      );

      await tester.tap(find.byKey(ValueKey('forge-reroll-slot-$economySlot')));
      await tester.pumpAndSettle();

      // Önce seçim yapılmadan düğme kapalı.
      final pickButton = find.byKey(const ValueKey('forge-roll-pick'));
      await tester.ensureVisible(pickButton);
      expect(tester.widget<OutlinedButton>(pickButton).onPressed, isNull);

      await tester.tap(find.byKey(const ValueKey('forge-pick-wheelXp:1')));
      await tester.pumpAndSettle();
      await tester.tap(pickButton);
      await tester.pumpAndSettle();
      // İkinci adım: onay penceresi.
      expect(find.byKey(const ValueKey('forge-pick-confirm')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('forge-pick-confirm')));
      await tester.pumpAndSettle();

      expect(profile.coins, 5000 - pickCost(RewardRarity.common, 0));
      final pending = profile.ownedItems.single.pendingForge!;
      expect(pending.slot, economySlot);
      expect(pending.effect.stat, ItemStat.wheelXp);
      expect(pending.effect.tier, 1);
    });

    testWidgets('kesif listesi oyuncu çapında ve görünür', (tester) async {
      await pumpForge(
        tester,
        discovered: [
          forgeAffixKey(ItemStat.attack, 2),
          forgeAffixKey(ItemStat.stepXp, 1),
        ],
      );
      await tester.tap(find.byKey(const ValueKey('forge-discoveries')));
      await tester.pumpAndSettle();
      expect(find.text('2 keşif'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('forge-discovery-attack:2')),
        findsOneWidget,
      );
      expect(find.text('Kademe II · 8-18'), findsOneWidget);
    });

    testWidgets('yeniden atma kaydedilir ve geri okunur', (tester) async {
      final profile = await pumpForge(tester);
      await rollRandom(tester);
      await tester.tap(find.byKey(const ValueKey('forge-take-new')));
      await tester.pumpAndSettle();
      await tester.pump(GameStorage.writeInterval + const Duration(seconds: 1));

      String? raw;
      await tester.runAsync(() async {
        final prefs = await SharedPreferences.getInstance();
        raw = prefs.getString('game_state_v1');
      });
      final state =
          (jsonDecode(raw!) as Map<String, dynamic>)['state']
              as Map<String, dynamic>;
      final restored = UserProfile.fromJson(
        state['profile'] as Map<String, dynamic>,
        avatar: _avatar,
      );
      expect(
        restored.ownedItems.single.forgedEffects,
        profile.ownedItems.single.forgedEffects,
      );
      expect(restored.discoveredAffixes, profile.discoveredAffixes);
      expect(restored.forgeSeed, profile.forgeSeed);
      expect(restored.ownedItems.single.rerollCount, 1);
    });
  });

  test('birleştirme sonucu yeni örnek: atılmış etkiler taşınmaz', () {
    final profile = UserProfile(avatar: _avatar);
    final merged = profile.addItem('swords/sword', rarity: RewardRarity.uncommon);
    expect(merged.forgedEffects, isNull);
    expect(merged.rerollCount, 0);
    expect(nextRarity(RewardRarity.common), RewardRarity.uncommon);
  });
}
