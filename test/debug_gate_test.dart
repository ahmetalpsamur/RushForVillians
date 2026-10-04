import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/game_clock.dart';
import 'package:rush_for_villains/data/enemy_catalog.dart';
import 'package:rush_for_villains/features/adventure/adventure_screen.dart';
import 'package:rush_for_villains/models/adventure_quest.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_progress.dart';
import 'package:rush_for_villains/services/game_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bölüm E / Faz 6: geliştirici kontrolleri **yalnızca** `kDebugMode`.
///
/// İki yarı:
///
/// 1. **Debug derlemesinde** kontroller var ve çalışıyor (testler debug
///    modunda koşuyor — `kDebugMode` burada `true`).
/// 2. **Release derlemesinde** yokluklarını `flutter test` doğrudan
///    gösteremez: testler release'de koşmuyor. Bunun yerine kaynak taranıyor
///    ve her geliştirici kontrolünün **derleme zamanı sabiti** olan
///    `kDebugMode` ile kapılandığı bağlanıyor. Sabit `false` dal AOT
///    derleyicisi tarafından ağaçtan atılır; çalışma zamanında gizlemek
///    (`callback != null`) bunu sağlamazdı. Release ikilisi üzerinde
///    sembol araması ayrıca yapıldı (bkz. `ELDE_DOGRULAMA.md`).
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

  group('debug derlemesi', () {
    test('testler debug modunda koşuyor', () {
      expect(kDebugMode, isTrue);
      expect(kReleaseMode, isFalse);
    });

    testWidgets('macera panelindeki adım düğmesi var ve adım üretiyor', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var simulated = 0;
      final quest = AdventureQuest(
        enemy: EnemyCatalog.enemies.first,
        stepGoal: 2000,
        startingSteps: 0,
        startedAt: GameClock.now(),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: AdventureScreen(
              adventure: quest,
              roundSerial: 0,
              avatar: _avatar,
              today: DailyProgress(date: GameClock.now(), stepGoal: 2000),
              onAdventureSelected: (_) {},
              onStartEndlessRun: () {},
              onStartRevival: () {},
              onChooseNewAdventure: () {},
              onAdventureUpdated: () {},
              onSimulateSteps: (amount) => simulated += amount,
              usingRealPedometer: false,
              useManualSource: true,
            ),
          ),
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      final panel = find.byKey(const ValueKey('adventure-admin-panel'));
      expect(panel, findsOneWidget);
      await tester.tap(panel);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('admin-steps-1000')));
      await tester.pump();
      expect(simulated, 1000);
    });

    test('kayıt silme yalnızca debug derlemesinde çalışır', () async {
      SharedPreferences.setMockInitialValues({'game_state_v1': '{}'});
      await GameStorage.clear();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('game_state_v1'), isNull);
    });
  });

  group('kaynak: her geliştirici kontrolü derleme zamanında kapılı', () {
    String read(String path) => File(path).readAsStringSync();

    /// [marker] satırından önceki [window] satırın içinde [gate] geçiyor mu.
    bool gatedBefore(String source, String marker, String gate, int window) {
      final lines = source.split('\n');
      final index = lines.indexWhere((line) => line.contains(marker));
      if (index < 0) return false;
      final from = (index - window).clamp(0, index);
      return lines.sublist(from, index + 1).any((line) => line.contains(gate));
    }

    test('macera admin paneli', () {
      final source = read('lib/features/adventure/adventure_screen.dart');
      expect(
        gatedBefore(
          source,
          "ValueKey('adventure-admin-panel')",
          'if (kDebugMode && widget.onSimulateSteps != null)',
          8,
        ),
        isTrue,
      );
      expect(source, contains('if (!kDebugMode) return;'));
    });

    test('sonsuz koşu +200 düğmesi', () {
      final source = read('lib/features/adventure/endless_run_screen.dart');
      expect(
        gatedBefore(
          source,
          "ValueKey('endless-simulate-200')",
          'if (kDebugMode && onSimulateSteps != null)',
          8,
        ),
        isTrue,
      );
    });

    test('RootShell geliştirici kancalarını yalnızca kDebugMode ile bağlar', () {
      final source = read('lib/features/root/root_shell.dart');
      final offenders = <String>[];
      for (final line in source.split('\n')) {
        final trimmed = line.trim();
        final isHook =
            trimmed.startsWith('onSimulateSteps:') ||
            trimmed.startsWith('onUseManualSourceChanged:');
        if (!isHook) continue;
        // Değer aynı satırda ya da bir sonraki satırda başlıyor.
        if (trimmed.contains('kDebugMode')) continue;
        offenders.add(trimmed);
      }
      // Sonsuz koşunun kancası değeri bir sonraki satırda yazıyor.
      offenders.removeWhere(
        (line) =>
            line == 'onSimulateSteps:' &&
            source.contains(
              'onSimulateSteps:\n              kDebugMode && !_stepSource.isPhysical',
            ),
      );
      expect(offenders, isEmpty, reason: offenders.join('\n'));
      expect(source, contains('bool _useManualSource = kDebugMode;'));
    });

    test('kayıt silme aynı kapının arkasında', () {
      final source = read('lib/services/game_storage.dart');
      expect(source, contains('if (!kDebugMode) {'));
    });

    test('lib içinde kReleaseMode ile ikinci bir kapı yok', () {
      // Tek kapı: kDebugMode. Profile derlemesi de dahil, debug olmayan
      // her derlemede geliştirici aracı yok.
      final offenders = [
        for (final file in Directory('lib').listSync(recursive: true))
          if (file is File &&
              file.path.endsWith('.dart') &&
              file.readAsStringSync().contains('kReleaseMode'))
            file.path,
      ];
      expect(offenders, isEmpty);
    });
  });
}
