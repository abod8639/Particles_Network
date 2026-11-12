import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example/main.dart';

void main() {
  testWidgets('ExampleApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(ParticleControllerScreen), findsOneWidget);
  });

  testWidgets('Performance section can be selected and manipulated',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 300));

    final performanceFinder =
        find.byKey(const ValueKey('category_chip_Performance'));
    await tester.scrollUntilVisible(
      performanceFinder,
      50.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(performanceFinder, findsOneWidget);
    await tester.tap(performanceFinder);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('PERFORMANCE & OPTIMIZATIONS'), findsOneWidget);
    expect(find.text('High FPS'), findsOneWidget);

    await tester.tap(find.text('High FPS'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Vertices'), findsOneWidget);
    await tester.tap(find.text('Stroke'));
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('Touch section can be selected and manipulated',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 300));

    final touchFinder = find.byKey(const ValueKey('category_chip_Touch'));
    await tester.scrollUntilVisible(
      touchFinder,
      50.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(touchFinder, findsOneWidget);
    await tester.tap(touchFinder);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('TOUCH INTERACTION'), findsOneWidget);
    expect(find.text('Magnetic'), findsOneWidget);

    await tester.tap(find.text('Magnetic'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Mouse Hover'), findsOneWidget);
    await tester.tap(find.text('Mouse Hover'));
    await tester.pump(const Duration(milliseconds: 300));
  });
}
