import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/widgets/scroll_to_top_button.dart';

void main() {
  testWidgets('aşağı kaydırınca görünür ve sayfa başına yumuşak döner', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          floatingActionButton: ScrollToTopButton(controller: controller),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          body: ListView.builder(
            key: const ValueKey('long-list'),
            controller: controller,
            itemExtent: 72,
            itemCount: 40,
            itemBuilder: (context, index) => Text('Satır $index'),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Başa dön'), findsNothing);

    await tester.drag(
      find.byKey(const ValueKey('long-list')),
      const Offset(0, -600),
    );
    await tester.pump();

    expect(controller.offset, greaterThan(200));
    expect(find.byTooltip('Başa dön'), findsOneWidget);
    final button = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );
    expect(button.shape, isA<CircleBorder>());

    final offsetBeforeTap = controller.offset;
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(controller.offset, lessThan(offsetBeforeTap));
    expect(controller.offset, greaterThan(0));

    await tester.pumpAndSettle();

    expect(controller.offset, closeTo(0, 0.1));
    expect(find.byTooltip('Başa dön'), findsNothing);
  });
}
