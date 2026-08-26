import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/game_clock.dart';
import 'package:rush_for_villains/data/pet_sayings.dart';
import 'package:rush_for_villains/features/root/root_shell.dart';
import 'package:rush_for_villains/features/tutorial/pet_companion.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_progress.dart';
import 'package:rush_for_villains/models/game_state.dart';
import 'package:rush_for_villains/models/user_profile.dart';
import 'package:rush_for_villains/services/game_storage.dart';
import 'package:rush_for_villains/services/item_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dolaşan rehber (Bölüm D).
///
/// Üç sert kural testle bağlı: hiçbir düğmeyi engellemez, sık konuşmaz,
/// arka arkaya aynı şeyi söylemez. Ayrıca eğitim sürerken hiç kurulmaz ve
/// oyuncu kapatabilir.
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

  const home = PetSituation(context: PetContext.home);
  const tavern = PetSituation(context: PetContext.tavern);

  group('sözler tek dosyada ve bağlama duyarlı', () {
    test('her bağlamın kendi havuzu var ve hiçbiri boş değil', () {
      for (final context in PetContext.values) {
        final pool = PetSayings.poolFor(PetSituation(context: context));
        expect(pool, isNotEmpty, reason: context.name);
        for (final line in pool) {
          expect(line.trim(), isNotEmpty);
        }
      }
    });

    test('bağlamlar birbirinin sözünü söylemez', () {
      // Aynı cümle iki bağlamda birden çıkarsa "bağlam duyarlılığı" lafta
      // kalır. Taverna teaser'ı bilerek yalnızca tavernada.
      final seen = <String, PetContext>{};
      for (final context in PetContext.values) {
        for (final line in PetSayings.poolFor(PetSituation(context: context))) {
          expect(
            seen[line],
            anyOf(isNull, equals(context)),
            reason: '"$line" hem ${seen[line]?.name} hem ${context.name}',
          );
          seen[line] = context;
        }
      }
    });

    test('aynı sekmede oyuncunun durumu havuzu değiştirir', () {
      const secured = PetSituation(
        context: PetContext.home,
        streakSecured: true,
        wheelAvailable: false,
      );
      const open = PetSituation(
        context: PetContext.home,
        streakSecured: false,
        wheelAvailable: true,
      );

      final securedPool = PetSayings.poolFor(secured);
      final openPool = PetSayings.poolFor(open);

      expect(openPool.length, greaterThan(securedPool.length));
      expect(
        openPool.any((line) => line.contains('çark')),
        isTrue,
        reason: 'çark hakkı dururken bunu söyleyen bir cümle olmalı',
      );
      expect(securedPool.any((line) => line.contains('çark')), isFalse);
    });

    test('macera varken ve yokken farklı konuşuyor', () {
      const idle = PetSituation(context: PetContext.adventure);
      const busy = PetSituation(
        context: PetContext.adventure,
        hasAdventure: true,
      );

      expect(PetSayings.poolFor(idle), isNot(PetSayings.poolFor(busy)));
    });

    test('seçim tohumlu ve tekrarlanabilir', () {
      final first = PetSayings.pick(home, seed: 7);
      final second = PetSayings.pick(home, seed: 7);
      expect(first, second);
    });

    test('arka arkaya aynı sözü söylemez', () {
      // Havuzun her tohumunda `avoid` gerçekten eleniyor mu.
      final pool = PetSayings.poolFor(home);
      for (final avoid in pool) {
        for (var seed = 0; seed < 12; seed++) {
          expect(PetSayings.pick(home, seed: seed, avoid: avoid), isNot(avoid));
        }
      }
    });

    test('sekme indeksi bağlama doğru eşleniyor', () {
      expect(PetContext.fromTabIndex(0), PetContext.home);
      expect(PetContext.fromTabIndex(1), PetContext.adventure);
      expect(PetContext.fromTabIndex(2), PetContext.store);
      expect(PetContext.fromTabIndex(3), PetContext.tavern);
      expect(PetContext.fromTabIndex(4), PetContext.profile);
      // Bilinmeyen indeks ana sayfaya düşer; boş bağlam olmaz.
      expect(PetContext.fromTabIndex(99), PetContext.home);
    });
  });

  group('katman davranışı', () {
    Future<void> pumpOverlay(
      WidgetTester tester, {
      PetSituation situation = home,
      VoidCallback? onButtonTap,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: FilledButton(
                    onPressed: onButtonTap ?? () {},
                    child: const Text('ALTTAKİ DÜĞME'),
                  ),
                ),
                PetCompanionOverlay(
                  situation: situation,
                  silence: const Duration(seconds: 30),
                  bubbleDuration: const Duration(seconds: 5),
                  bottomInset: 24,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('açılır açılmaz bir şey söyler', (tester) async {
      await pumpOverlay(tester);
      expect(
        find.byKey(const ValueKey('pet-companion-bubble')),
        findsOneWidget,
      );
    });

    testWidgets('baloncuk süresi dolunca susar, sessizlik payı kadar susar', (
      tester,
    ) async {
      await pumpOverlay(tester);

      await tester.pump(const Duration(seconds: 6));
      expect(find.byKey(const ValueKey('pet-companion-bubble')), findsNothing);

      // Sessizlik payı dolmadan konuşmaz.
      await tester.pump(const Duration(seconds: 20));
      expect(find.byKey(const ValueKey('pet-companion-bubble')), findsNothing);

      // Dolunca tekrar konuşur.
      await tester.pump(const Duration(seconds: 11));
      expect(
        find.byKey(const ValueKey('pet-companion-bubble')),
        findsOneWidget,
      );
    });

    testWidgets('arka arkaya aynı cümleyi kurmaz', (tester) async {
      await pumpOverlay(tester);
      final first = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('pet-companion-bubble')),
          matching: find.byType(Text),
        ),
      );

      await tester.pump(const Duration(seconds: 6));
      await tester.pump(const Duration(seconds: 31));

      final second = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('pet-companion-bubble')),
          matching: find.byType(Text),
        ),
      );
      expect(second.data, isNot(first.data));
    });

    testWidgets('altındaki düğmeyi engellemez', (tester) async {
      var tapped = 0;
      await pumpOverlay(tester, onButtonTap: () => tapped++);

      // Katman bütün ekranı kaplıyor; dokunuş altındaki düğmeye geçmeli.
      await tester.tap(find.text('ALTTAKİ DÜĞME'));
      await tester.pump();

      expect(tapped, 1);
      expect(find.byType(IgnorePointer), findsWidgets);
    });

    testWidgets('bağlam değişince sessizlik payını beklemeden konuşur', (
      tester,
    ) async {
      await pumpOverlay(tester);
      await tester.pump(const Duration(seconds: 6));
      expect(find.byKey(const ValueKey('pet-companion-bubble')), findsNothing);

      await pumpOverlay(tester, situation: tavern);
      await tester.pump();

      expect(
        find.byKey(const ValueKey('pet-companion-bubble')),
        findsOneWidget,
      );
    });
  });

  group('RootShell ile bütünleşme', () {
    var shellSerial = 0;

    Future<UserProfile> pumpShell(
      WidgetTester tester, {
      bool petEnabled = true,
      bool startTutorial = false,
    }) async {
      tester.view.physicalSize = const Size(1000, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      ItemCatalog.reset(const []);
      addTearDown(() => ItemCatalog.reset());

      final profile = UserProfile(
        avatar: _avatar,
        level: 5,
        coins: 500,
        petCompanionEnabled: petEnabled,
        hasCompletedTutorial: !startTutorial,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: RootShell(
            key: ValueKey('shell-${shellSerial++}'),
            avatar: _avatar,
            startTutorial: startTutorial,
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

    Finder tab(String label) => find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    );

    testWidgets('ayar açıkken rehber dolaşıyor', (tester) async {
      await pumpShell(tester);
      expect(find.byType(PetCompanionOverlay), findsOneWidget);
    });

    testWidgets('ayar kapalıyken katman hiç kurulmuyor', (tester) async {
      await pumpShell(tester, petEnabled: false);
      expect(find.byType(PetCompanionOverlay), findsNothing);
    });

    testWidgets('eğitim sürerken rehber dolaşmıyor', (tester) async {
      // İki anlatıcı aynı anda konuşmamalı.
      await pumpShell(tester, startTutorial: true);
      expect(find.byType(PetCompanionOverlay), findsNothing);
    });

    testWidgets('profildeki anahtar ayarı kapatır ve diske yazar', (
      tester,
    ) async {
      final profile = await pumpShell(tester);

      await tester.tap(tab('Profil'));
      await tester.pumpAndSettle();

      final toggle = find.byKey(const ValueKey('pet-companion-toggle'));
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(profile.petCompanionEnabled, isFalse);
      expect(find.byType(PetCompanionOverlay), findsNothing);

      await GameStorage.flush();
      final preferences = await SharedPreferences.getInstance();
      await preferences.reload();
      final envelope =
          jsonDecode(preferences.getString(_storageKey)!)
              as Map<String, dynamic>;
      final saved = (envelope['state'] as Map)['profile'] as Map;
      expect(saved['petCompanionEnabled'], isFalse);
    });

    testWidgets('Taverna sekmesi çevrimiçi teaser`ını gösterir', (
      tester,
    ) async {
      await pumpShell(tester);

      expect(tab('Taverna'), findsOneWidget);
      expect(tab('Takım'), findsNothing);

      await tester.tap(tab('Taverna'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('tavern-coming-soon')), findsOneWidget);
      expect(find.text(PetSayings.tavernTeaser), findsWidgets);
      // Taverna'nın **işlevi yok**: mevcut takım önizlemesi olduğu gibi
      // duruyor, yeni bir özellik eklenmedi.
      expect(find.textContaining('önizleme'), findsOneWidget);
    });
  });

  group('kalıcılık', () {
    test('v19 kaydı rehber ayarı olmadan açık geliyor', () async {
      SharedPreferences.setMockInitialValues({
        _storageKey: jsonEncode({
          'schemaVersion': 19,
          'state': {
            'profile': {'level': 6},
            'today': {'steps': 200, 'stepGoal': 5000},
          },
        }),
      });

      final restored = await GameStorage.load(avatar: _avatar);

      expect(restored, isNotNull);
      expect(restored!.profile.level, 6);
      // Varsayılan açık: rehber oyunun anlatıcısı, güncelleme onu susturmamalı.
      expect(restored.profile.petCompanionEnabled, isTrue);
    });

    test('kapatılmış ayar kayıt turunda korunuyor', () {
      final profile = UserProfile(avatar: _avatar, petCompanionEnabled: false);
      final restored = UserProfile.fromJson(profile.toJson(), avatar: _avatar);
      expect(restored.petCompanionEnabled, isFalse);
    });
  });
}
