import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Golden altyapısının bu ortamda çalıştığını doğrulayan duman testi.
void main() {
  testWidgets('golden altyapısı çalışıyor', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Color(0xFF101020),
          body: Center(
            child: Text(
              'golden ok',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/_smoke.png'),
    );
  });
}
