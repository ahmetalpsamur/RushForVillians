import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/game_clock.dart';
import 'package:rush_for_villains/data/mail_catalog.dart';
import 'package:rush_for_villains/features/root/root_shell.dart';
import 'package:rush_for_villains/l10n/app_localizations_en.dart';
import 'package:rush_for_villains/l10n/app_localizations_tr.dart';
import 'package:rush_for_villains/l10n/content_localizations.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/game_state.dart';
import 'package:rush_for_villains/services/game_storage.dart';
import 'package:rush_for_villains/services/item_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bölüm E / Faz 5: özür postası **eski posta ve kod durumlarını bozmaz**.
///
/// Bu patch şemayı v32'den v33'e taşıyor ve kataloğa yeni bir posta
/// ekliyor. Kapalı beta teşekkür postası, `WENEEDHEROES2026` kodu, Erken
/// Kalkan ünvanı ve indirim penceresi göçten önce neyse sonra da o olmalı.
const _avatar = AvatarProfile(
  name: 'Barca',
  age: 28,
  weight: 74,
  gender: 'Erkek',
  characterClass: 'SwordMan',
  characterAsset: 'lib/Characters/SwordMan/test.png',
);

const _code = 'WENEEDHEROES2026';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;
  setUp(() {
    now = DateTime(2026, 10, 5, 12);
    GameClock.useSource(() => now);
  });
  tearDown(GameClock.reset);

  /// Bölüm E'den önce yazılmış bir v32 kaydı.
  void seedV32(Map<String, dynamic> profile) {
    SharedPreferences.setMockInitialValues({
      'game_state_v1': jsonEncode({
        'schemaVersion': 32,
        'savedAt': '2026-10-03T10:00:00.000',
        'state': {
          'profile': {'level': 12, 'coins': 300, ...profile},
          'today': {'steps': 0, 'stepGoal': 7000},
        },
      }),
    });
  }

  /// A oyuncusu: kapalı beta postasını almış, kodu kullanıp kod postasını
  /// almış, ünvanı takmış ve indirim penceresi açık.
  Map<String, dynamic> usedEverything() => {
    'claimedMailIds': [
      MailCatalog.closedBetaThanksId,
      MailCatalog.heroesCodeRewardId,
    ],
    'readMailIds': [
      MailCatalog.closedBetaThanksId,
      MailCatalog.heroesCodeRewardId,
    ],
    'pendingMailIds': [MailCatalog.heroesCodeRewardId],
    'redeemedCodes': [_code],
    'ownedTitleIds': [MailCatalog.earlyRiserTitleId],
    'equippedTitleId': MailCatalog.earlyRiserTitleId,
    'shopDiscountUntil':
        now.toUtc().add(const Duration(minutes: 20)).toIso8601String(),
  };

  group('göç: kayıt alanları aynen korunur', () {
    test('alınmış posta alınmış, kullanılmış kod kullanılmış kalır', () async {
      seedV32(usedEverything());
      final restored = await GameStorage.load(avatar: _avatar);
      expect(restored, isNotNull);
      final profile = restored!.profile;

      expect(profile.claimedMailIds, [
        MailCatalog.closedBetaThanksId,
        MailCatalog.heroesCodeRewardId,
      ]);
      expect(profile.pendingMailIds, [MailCatalog.heroesCodeRewardId]);
      expect(profile.redeemedCodes, [_code]);
      expect(profile.hasRedeemedCode(_code), isTrue);
      // Alınmış postalar ikinci kez alınamaz.
      expect(profile.claimMail(MailCatalog.closedBetaThanksId), isFalse);
      expect(profile.claimMail(MailCatalog.heroesCodeRewardId), isFalse);
      // Özür postası **yeni** kimlik: alınabilir.
      expect(profile.hasClaimedMail(MailCatalog.mergeBuffApologyId), isFalse);

      // Kapalı beta ünvanı ve indirim penceresi.
      expect(profile.ownedTitleIds, [MailCatalog.earlyRiserTitleId]);
      expect(profile.equippedTitleId, MailCatalog.earlyRiserTitleId);
      expect(profile.isShopDiscountActive(GameClock.now()), isTrue);

      // Göç diske v33 olarak yazıldı ve alanlar aynı.
      final prefs = await SharedPreferences.getInstance();
      final saved =
          jsonDecode(prefs.getString('game_state_v1')!) as Map<String, dynamic>;
      expect(saved['schemaVersion'], GameStorage.schemaVersion);
      final savedProfile =
          (saved['state'] as Map<String, dynamic>)['profile']
              as Map<String, dynamic>;
      for (final entry in usedEverything().entries) {
        expect(savedProfile[entry.key], entry.value, reason: entry.key);
      }
    });

    test('alınmamış posta alınabilir, kullanılmamış kod kullanılabilir kalır', () async {
      seedV32(const {});
      final restored = await GameStorage.load(avatar: _avatar);
      final profile = restored!.profile;

      expect(profile.claimedMailIds, isEmpty);
      expect(profile.redeemedCodes, isEmpty);
      expect(profile.hasRedeemedCode(_code), isFalse);
      expect(MailCatalog.findCode(_code), isNotNull);
      expect(profile.claimMail(MailCatalog.closedBetaThanksId), isTrue);
      expect(profile.claimMail(MailCatalog.mergeBuffApologyId), isTrue);
    });

    test('özür postası katalogda: 750 altın, 3 çark hakkı, herkese açık', () {
      final mail = MailCatalog.byId(MailCatalog.mergeBuffApologyId)!;
      expect(mail.reward.coins, 750);
      expect(mail.reward.wheelSpins, 3);
      expect(mail.reward.titleId, isNull);
      expect(mail.deliveredToEveryone, isTrue);
      expect(mail.isAvailableAt(GameClock.now()), isTrue);
      // Eski postalar ve kod olduğu gibi duruyor.
      expect(MailCatalog.byId(MailCatalog.closedBetaThanksId), isNotNull);
      expect(MailCatalog.findCode(_code)!.mailId, MailCatalog.heroesCodeRewardId);
    });

    test('metin iki dilde var ve uzun tire içermiyor', () {
      for (final l10n in [AppLocalizationsTr(), AppLocalizationsEn()]) {
        final title = l10n.mailTitle(MailCatalog.mergeBuffApologyId);
        final body = l10n.mailBody(MailCatalog.mergeBuffApologyId);
        expect(title, isNotEmpty);
        expect(body, contains('750'));
        expect(body, contains('3'));
        expect('$title$body', isNot(contains('—')));
        expect('$title$body', isNot(contains('–')));
      }
    });
  });

  group('göç sonrası oyun içinde', () {
    Future<GameState> pumpMigrated(
      WidgetTester tester,
      Map<String, dynamic> profile,
    ) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      seedV32(profile);
      ItemCatalog.reset(const []);
      addTearDown(ItemCatalog.reset);

      GameState? restored;
      await tester.runAsync(() async {
        restored = await GameStorage.load(avatar: _avatar);
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: RootShell(
            avatar: _avatar,
            initialState: restored!,
            onAvatarChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('home-mailbox')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      return restored!;
    }

    Future<void> submitCode(WidgetTester tester) async {
      await tester.enterText(find.byKey(const ValueKey('code-input')), _code);
      await tester.tap(find.byKey(const ValueKey('code-submit')));
      await tester.pump();
      await tester.pump();
    }

    testWidgets('A: eski postalar alınmış görünür, kod reddedilir, özür alınır', (
      tester,
    ) async {
      final state = await pumpMigrated(tester, usedEverything());
      final profile = state.profile;

      expect(
        find.byKey(ValueKey('mail-claim-${MailCatalog.closedBetaThanksId}')),
        findsNothing,
      );
      final apology = find.byKey(
        ValueKey('mail-claim-${MailCatalog.mergeBuffApologyId}'),
      );
      expect(apology, findsOneWidget);

      final coins = profile.coins;
      final spins = profile.extraWheelSpins;
      await tester.ensureVisible(apology);
      await tester.tap(apology);
      await tester.pump();
      await tester.pump();
      expect(profile.coins, coins + 750);
      expect(profile.extraWheelSpins, spins + 3);
      expect(profile.hasClaimedMail(MailCatalog.mergeBuffApologyId), isTrue);
      expect(apology, findsNothing);

      // Kod ikinci kez kullanılamaz; posta eklenmez, para gelmez.
      await submitCode(tester);
      expect(profile.pendingMailIds, [MailCatalog.heroesCodeRewardId]);
      expect(profile.coins, coins + 750);

      // Ünvan takılı kaldı, indirim penceresi açık.
      expect(profile.equippedTitleId, MailCatalog.earlyRiserTitleId);
      expect(profile.isShopDiscountActive(GameClock.now()), isTrue);
    });

    testWidgets('B: kapalı beta postası ve kod hâlâ kullanılabilir', (
      tester,
    ) async {
      final state = await pumpMigrated(tester, const {});
      final profile = state.profile;

      final beta = find.byKey(
        ValueKey('mail-claim-${MailCatalog.closedBetaThanksId}'),
      );
      expect(beta, findsOneWidget);
      await tester.ensureVisible(beta);
      await tester.tap(beta);
      await tester.pump();
      await tester.pump();
      expect(profile.hasClaimedMail(MailCatalog.closedBetaThanksId), isTrue);
      expect(profile.ownedTitleIds, contains(MailCatalog.earlyRiserTitleId));

      await submitCode(tester);
      expect(profile.hasRedeemedCode(_code), isTrue);
      expect(profile.pendingMailIds, [MailCatalog.heroesCodeRewardId]);
    });
  });
}
