import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/app.dart';
import 'package:rush_for_villains/features/safety/safety_screen.dart';
import 'package:rush_for_villains/services/safety_notice_storage.dart';
import 'package:rush_for_villains/core/constants/safety_messages.dart';
import 'package:rush_for_villains/features/start/start_screen.dart';
import 'package:rush_for_villains/features/tutorial/guide_selection_screen.dart';
import 'package:rush_for_villains/l10n/app_localizations.dart';
import 'package:rush_for_villains/services/game_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Açılış akışı hiçbir koşulda ekranı kilitlememeli.
///
/// Kayıt okuma (SharedPreferences) ve bildirim servisi platform kanalına
/// dayanıyor. Kanal düşerse `_initializeApp` yarıda kalıyor, `_isLoading`
/// sonsuza kadar `true` kalıyor ve kullanıcı açılış görselinde asılı
/// kalıyordu — ne hata mesajı vardı ne de çıkış yolu.
///
/// Not: platform kanalı cevapları `testWidgets`'in sahte saatiyle teslim
/// edilmiyor. Bu yüzden açılış hem gerçek zamanda ([WidgetTester.runAsync])
/// hem de sahte saatte ilerletiliyor; hangi yolun kullanıldığı kanalın mock
/// olup olmadığına göre değişiyor.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Açılışın (minimum açılış süresi dahil) bitmesini bekler.
  ///
  /// Açılış artık birden çok **ardışık** kanal çağrısı yapıyor
  /// (`GameSettings.load`, sonra `CharacterStorage.load`, ...). Her cevap
  /// gerçek zamanda geliyor ama arkasından gelen kod sahte saatin
  /// mikro görev kuyruğunda bekliyor ve ancak `pump` ile ilerliyor. Tek bir
  /// gerçek bekleyiş + tek `pump` yalnızca **ilk** gidiş-dönüşü tamamlıyordu;
  /// açılış ikinci çağrıda asılı görünüyordu. İkisi sırayla tekrarlanıyor.
  Future<void> settleBoot(WidgetTester tester) async {
    // Toplam sahte süre eskisiyle aynı (3 sn): kayıt uyarısı 6 sn ekranda
    // kalıyor ve sonraki iddialar onu hâlâ görebilmeli.
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump(const Duration(milliseconds: 250));
    }
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  }

  /// Kayıt okunabilen bir cihaz kurar.
  ///
  /// "Okunamayan kayıt" testleri [GameStorage]'ın yazma korumasını açıyor ve
  /// bu bayrak **statik**: aynı test sürecinde sonraki açılışa sızıyor ve
  /// okunabilen bir kaydı da "okunamadı" gösteriyordu. Gerçek uygulamada her
  /// açılış yeni bir süreç, yani sızıntı yalnızca testte var. Bayrağı sıfırlayan
  /// tek yol `GameStorage.clear` (yalnızca debug).
  Future<void> mockReadableStorage(
    WidgetTester tester,
    Map<String, Object> values,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(GameStorage.clear);
    SharedPreferences.setMockInitialValues(values);
  }

  Future<void> bootApp(WidgetTester tester) async {
    await tester.pumpWidget(const RushForVilliansApp());
    await settleBoot(tester);
  }

  group('açılış dayanıklılığı', () {
    testWidgets('kayıt okunamazsa açılış ekranında asılı kalınmaz', (
      tester,
    ) async {
      // Mock kurulmadığı için SharedPreferences kanalı hata fırlatır.
      await bootApp(tester);

      expect(find.byType(StartScreen), findsNothing);
      expect(find.byType(SafetyScreen), findsOneWidget);
    });

    testWidgets('kayıt okunamazsa kullanıcı sessizce geçiştirilmez', (
      tester,
    ) async {
      await bootApp(tester);
      await tester.pump();

      // Metin ARB'de ve bir dönem dürüstleştirildi ("kayıt korunuyor, bu
      // oturum üzerine yazmayacak"); sabit Türkçe cümle aramak yerine o anki
      // dildeki ARB değeri aranıyor.
      final l10n = AppLocalizations.of(
        tester.element(find.byType(SafetyScreen)),
      );
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text(l10n.storageUnavailable), findsOneWidget);
    });

    testWidgets('kayıt okunabiliyorsa uyarı gösterilmez', (tester) async {
      await mockReadableStorage(tester, {});

      await bootApp(tester);
      await tester.pump();

      expect(find.byType(SafetyScreen), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('second launch skips the accepted full notice', (tester) async {
      await mockReadableStorage(tester, {
        SafetyNoticeStorage.key: SafetyMessages.noticeVersion,
      });
      await bootApp(tester);
      expect(find.byType(SafetyScreen), findsNothing);
      expect(find.byType(GuideSelectionScreen), findsOneWidget);
    });

    testWidgets('notice version update gates launch again', (tester) async {
      await mockReadableStorage(tester, {
        SafetyNoticeStorage.key: SafetyMessages.noticeVersion - 1,
      });
      await bootApp(tester);
      expect(find.byType(SafetyScreen), findsOneWidget);
      expect(find.byType(GuideSelectionScreen), findsNothing);
    });
    testWidgets('açılış görseli hemen kaybolmaz', (tester) async {
      await mockReadableStorage(tester, {});

      await tester.pumpWidget(const RushForVilliansApp());
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(StartScreen), findsOneWidget);

      // Bekleyen zamanlayıcı kalmasın diye açılış tamamlanır.
      await settleBoot(tester);
    });
  });
}
