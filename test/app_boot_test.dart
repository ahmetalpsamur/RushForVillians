import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/app.dart';
import 'package:rush_for_villains/features/character/character_creation_screen.dart';
import 'package:rush_for_villains/features/start/start_screen.dart';
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
  Future<void> settleBoot(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2400)),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
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
      expect(find.byType(CharacterCreationScreen), findsOneWidget);
    });

    testWidgets('kayıt okunamazsa kullanıcı sessizce geçiştirilmez', (
      tester,
    ) async {
      await bootApp(tester);
      await tester.pump();

      expect(
        find.textContaining('Kayıtlı ilerlemene şu an ulaşılamadı'),
        findsOneWidget,
      );
    });

    testWidgets('kayıt okunabiliyorsa uyarı gösterilmez', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await bootApp(tester);
      await tester.pump();

      expect(find.byType(CharacterCreationScreen), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('açılış görseli hemen kaybolmaz', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const RushForVilliansApp());
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(StartScreen), findsOneWidget);

      // Bekleyen zamanlayıcı kalmasın diye açılış tamamlanır.
      await settleBoot(tester);
    });
  });
}
