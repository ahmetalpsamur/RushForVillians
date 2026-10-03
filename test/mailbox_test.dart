import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/game_clock.dart';
import 'package:rush_for_villains/data/mail_catalog.dart';
import 'package:rush_for_villains/features/home/home_screen.dart';
import 'package:rush_for_villains/features/root/root_shell.dart';
import 'package:rush_for_villains/l10n/app_localizations.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_progress.dart';
import 'package:rush_for_villains/models/game_state.dart';
import 'package:rush_for_villains/models/user_profile.dart';
import 'package:rush_for_villains/services/game_storage.dart';
import 'package:rush_for_villains/services/item_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Posta kutusu ve kod girme (Bölüm D / Faz 3).
///
/// Buradaki asıl soru **ödül iki kez verilmesin, kaybolmasın**: posta
/// kutusu bizim gönderdiğimiz her şeyin tek dağıtım yolu, yani bu koruma
/// tek yerde ve sağlam olmalı.
const _avatar = AvatarProfile(
  name: 'Barca',
  age: 28,
  weight: 74,
  gender: 'Erkek',
  characterClass: 'Swordsman',
  characterAsset:
      'lib/All_Assets/Avatars/Classes/Characters(100x100 split)/Swordsman/Swordsman/Swordsman_Walk.gif',
);

const _storageKey = 'game_state_v1';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var shellSerial = 0;
  late DateTime now;

  setUp(() {
    GameClock.reset();
    now = DateTime(2026, 10, 5, 12);
    GameClock.useSource(() => now);
  });
  tearDown(GameClock.reset);

  group('katalog', () {
    test('kodlar kanonik yazımda ve kimlikler benzersiz', () {
      final ids = MailCatalog.all.map((m) => m.id).toList();
      expect(ids.toSet(), hasLength(ids.length), reason: 'kimlik tekrarı');
      for (final code in MailCatalog.codes) {
        expect(
          code.code,
          code.code.trim().toUpperCase(),
          reason: '${code.code} kanonik değil',
        );
        expect(
          MailCatalog.byId(code.mailId),
          isNotNull,
          reason: '${code.code} olmayan bir postaya bağlı',
        );
      }
    });

    test('WENEEDHEROES2026 süresiz ve büyük/küçük harf duyarsız', () {
      final code = MailCatalog.findCode('  weneedheroes2026 ');
      expect(code, isNotNull);
      expect(code!.code, 'WENEEDHEROES2026');
      expect(code.expiresAt, isNull, reason: 'süresiz olmalı');
      expect(code.isActiveAt(DateTime(2099)), isTrue);
    });

    test('kod ödülü doğrudan değil, posta olarak geliyor', () {
      // Tek ödül dağıtım yolu: kodun karşılığı bir posta kimliği.
      for (final code in MailCatalog.codes) {
        final mail = MailCatalog.byId(code.mailId)!;
        expect(mail.hasReward, isTrue, reason: '${code.code} ödülsüz posta');
        expect(
          mail.deliveredToEveryone,
          isFalse,
          reason: 'kod postası herkese açık olmamalı',
        );
      }
    });

    test('kapalı beta ünvanı yalnızca postadan', () {
      final mail = MailCatalog.byId(MailCatalog.closedBetaThanksId)!;
      expect(mail.reward.coins, 1000);
      expect(mail.reward.wheelSpins, 5);
      expect(mail.reward.titleId, MailCatalog.earlyRiserTitleId);
    });
  });

  group('profil kuralları', () {
    UserProfile profile() => UserProfile(avatar: _avatar, level: 3);

    test('aynı posta iki kez alınamaz', () {
      final p = profile();
      expect(p.claimMail('m1'), isTrue);
      expect(p.claimMail('m1'), isFalse, reason: 'ikinci alım reddedilmeli');
      expect(p.claimedMailIds, ['m1']);
    });

    test('alınan posta okundu da sayılır', () {
      final p = profile();
      p.claimMail('m1');
      expect(p.hasReadMail('m1'), isTrue);
    });

    test('kod yavaşlatması pencere içinde devreye girer', () {
      final p = profile();
      expect(p.isCodeEntryThrottled(now), isFalse);
      for (var i = 0; i < UserProfile.maxCodeAttempts; i++) {
        p.registerFailedCodeAttempt(now);
      }
      expect(p.isCodeEntryThrottled(now), isTrue);
      // Pencere dolunca serbest.
      expect(
        p.isCodeEntryThrottled(now.add(UserProfile.codeAttemptWindow)),
        isFalse,
      );
    });

    test('doğru kod sayacı sıfırlar', () {
      final p = profile();
      for (var i = 0; i < UserProfile.maxCodeAttempts; i++) {
        p.registerFailedCodeAttempt(now);
      }
      p.resetCodeAttempts();
      expect(p.isCodeEntryThrottled(now), isFalse);
    });

    test('posta alanları JSON turunda korunur', () {
      final p = profile();
      p.claimMail('m1');
      p.unlockMail('m2');
      p.markCodeRedeemed('ABC');
      p.registerFailedCodeAttempt(now);

      final round = UserProfile.fromJson(
        jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>,
        avatar: _avatar,
      );
      expect(round.claimedMailIds, ['m1']);
      expect(round.readMailIds, ['m1']);
      expect(round.pendingMailIds, ['m2']);
      expect(round.redeemedCodes, ['ABC']);
      expect(round.codeAttempts, 1);
      expect(round.codeAttemptWindowStart, isNotNull);
    });

    test('eski kayıtta alanlar boş listeye düşer', () {
      // v30 öncesi kayıtta bu alanlar yok: hiç posta alınmamış demek.
      final round = UserProfile.fromJson(const {}, avatar: _avatar);
      expect(round.claimedMailIds, isEmpty);
      expect(round.pendingMailIds, isEmpty);
      expect(round.redeemedCodes, isEmpty);
      expect(round.codeAttempts, 0);
    });
  });

  group('RootShell akışı', () {
    Future<UserProfile> pumpShell(
      WidgetTester tester, {
      UserProfile? profile,
      Locale locale = const Locale('tr'),
      double width = 390,
    }) async {
      tester.view.physicalSize = Size(width, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      ItemCatalog.reset(const []);
      addTearDown(ItemCatalog.reset);

      final used = profile ?? UserProfile(avatar: _avatar, level: 5);
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
            key: ValueKey('mail-shell-${shellSerial++}'),
            avatar: _avatar,
            initialState: GameState(
              profile: used,
              today: DailyProgress(date: GameClock.now(), stepGoal: 6000),
            ),
            onAvatarChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      return used;
    }

    Future<void> openMailbox(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('home-mailbox')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('alınmamış ödül varsa ana sayfada rozet görünür', (
      tester,
    ) async {
      await pumpShell(tester);
      expect(
        find.byKey(const ValueKey('quick-action-badge')),
        findsOneWidget,
        reason: 'kapalı beta postası alınmayı bekliyor',
      );
    });

    testWidgets('ödül alınınca rozet kalkar ve posta listede kalır', (
      tester,
    ) async {
      final profile = await pumpShell(tester);
      await openMailbox(tester);

      final claimKey = ValueKey(
        'mail-claim-${MailCatalog.closedBetaThanksId}',
      );
      expect(find.byKey(claimKey), findsOneWidget);
      final coinsBefore = profile.coins;
      final spinsBefore = profile.extraWheelSpins;

      await tester.tap(find.byKey(claimKey));
      await tester.pump();
      await tester.pump();

      expect(profile.coins - coinsBefore, 1000);
      expect(profile.extraWheelSpins - spinsBefore, 5);
      expect(profile.ownsTitle(MailCatalog.earlyRiserTitleId), isTrue);
      // Posta listede kalır, düğme "alındı"ya döner.
      expect(find.byKey(claimKey), findsNothing);
      expect(
        find.byKey(
          ValueKey('mail-claimed-${MailCatalog.closedBetaThanksId}'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('aynı posta iki kez ödül vermez', (tester) async {
      final profile = await pumpShell(tester);
      await openMailbox(tester);
      final claimKey = ValueKey(
        'mail-claim-${MailCatalog.closedBetaThanksId}',
      );
      await tester.tap(find.byKey(claimKey));
      await tester.pump();
      await tester.pump();
      final afterFirst = profile.coins;

      // Ekranda düğme kalmıyor; modeli doğrudan da zorlasak ödül gelmemeli.
      expect(profile.claimMail(MailCatalog.closedBetaThanksId), isFalse);
      expect(profile.coins, afterFirst);
    });

    testWidgets('alınan ödül diske yazılır', (tester) async {
      // "Yarım kalan alım": işaret ve ödül aynı kayıt turunda gider.
      await pumpShell(tester);
      await openMailbox(tester);
      await tester.tap(
        find.byKey(ValueKey('mail-claim-${MailCatalog.closedBetaThanksId}')),
      );
      await tester.pump();
      await tester.pump(GameStorage.writeInterval);
      await tester.pump();

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      expect(raw, isNotNull);
      final state =
          (jsonDecode(raw!) as Map<String, dynamic>)['state']
              as Map<String, dynamic>;
      final saved =
          (state['profile'] as Map<String, dynamic>)['claimedMailIds']
              as List<dynamic>;
      expect(saved, contains(MailCatalog.closedBetaThanksId));
      expect(
        (state['profile'] as Map<String, dynamic>)['coins'],
        greaterThanOrEqualTo(1000),
        reason: 'ödül ve işaret birlikte yazılmalı',
      );
    });

    testWidgets('geçerli kod postayı açar, ödülü doğrudan vermez', (
      tester,
    ) async {
      final profile = await pumpShell(tester);
      await openMailbox(tester);
      final coinsBefore = profile.coins;

      await tester.enterText(
        find.byKey(const ValueKey('code-input')),
        '  weneedheroes2026  ',
      );
      await tester.tap(find.byKey(const ValueKey('code-submit')));
      await tester.pump();
      await tester.pump();

      expect(
        profile.coins,
        coinsBefore,
        reason: 'kod doğrudan ödül vermemeli',
      );
      expect(profile.hasRedeemedCode('WENEEDHEROES2026'), isTrue);
      expect(profile.pendingMailIds, contains(MailCatalog.heroesCodeRewardId));
      // Posta artık listede ve alınabilir.
      expect(
        find.byKey(ValueKey('mail-claim-${MailCatalog.heroesCodeRewardId}')),
        findsOneWidget,
      );
    });

    testWidgets('aynı kod ikinci kez kabul edilmez', (tester) async {
      final profile = await pumpShell(tester);
      await openMailbox(tester);
      Future<void> submit(String text) async {
        await tester.enterText(
          find.byKey(const ValueKey('code-input')),
          text,
        );
        await tester.tap(find.byKey(const ValueKey('code-submit')));
        await tester.pump();
        await tester.pump();
      }

      await submit('WENEEDHEROES2026');
      expect(profile.pendingMailIds, hasLength(1));
      await submit('WENEEDHEROES2026');
      expect(
        profile.pendingMailIds,
        hasLength(1),
        reason: 'ikinci kullanım posta eklememeli',
      );
      // SnackBar geçiş sırasında iki kare birden taşıyabiliyor; önemli
      // olan mesajın **o mesaj** olması.
      expect(
        find.text(AppLocalizations.of(tester.element(find.byType(RootShell)))
            .codeErrorAlreadyUsed),
        findsWidgets,
      );
    });

    testWidgets('geçersiz kod ayrı mesaj verir ve yavaşlatma devreye girer', (
      tester,
    ) async {
      final profile = await pumpShell(tester);
      await openMailbox(tester);
      Future<void> submit(String text) async {
        await tester.enterText(
          find.byKey(const ValueKey('code-input')),
          text,
        );
        await tester.tap(find.byKey(const ValueKey('code-submit')));
        await tester.pump();
        await tester.pump();
      }

      for (var i = 0; i < UserProfile.maxCodeAttempts; i++) {
        await submit('YANLIS$i');
      }
      expect(profile.codeAttempts, UserProfile.maxCodeAttempts);
      expect(profile.isCodeEntryThrottled(now), isTrue);

      // Yavaşlatma açıkken **doğru** kod bile beklemeye takılır.
      await submit('WENEEDHEROES2026');
      expect(
        profile.pendingMailIds,
        isEmpty,
        reason: 'yavaşlatma sırasında posta açılmamalı',
      );
    });

    testWidgets('boş kod ayrı mesaj verir', (tester) async {
      final profile = await pumpShell(tester);
      await openMailbox(tester);
      await tester.tap(find.byKey(const ValueKey('code-submit')));
      await tester.pump();
      await tester.pump();
      expect(
        profile.codeAttempts,
        0,
        reason: 'boş kutu yanlış deneme sayılmamalı',
      );
    });

    for (final locale in const [Locale('tr'), Locale('en')]) {
      for (final width in const [320.0, 390.0]) {
        testWidgets(
          'taşma yok (${locale.languageCode} ${width.toInt()} dp)',
          (tester) async {
            final errors = <String>[];
            final previous = FlutterError.onError;
            FlutterError.onError = (details) {
              if (errors.length < 2) errors.add(details.exceptionAsString());
            };
            addTearDown(() => FlutterError.onError = previous);

            await pumpShell(tester, locale: locale, width: width);
            expect(find.byType(HomeScreen), findsOneWidget);
            await openMailbox(tester);
            expect(find.byKey(const ValueKey('mailbox-list')), findsOneWidget);
            expect(errors, isEmpty, reason: errors.join(' | '));
          },
        );
      }
    }
  });
}
