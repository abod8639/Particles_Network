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

  testWidgets('Display section can be selected and manipulated',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 300));

    final displayFinder = find.byKey(const ValueKey('category_chip_Display'));
    await tester.scrollUntilVisible(
      displayFinder,
      50.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(displayFinder);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('PALETTE & DISPLAY OPTIONS'), findsOneWidget);
    expect(find.text('Network'), findsOneWidget);
    expect(find.text('Fill'), findsOneWidget);
    expect(find.text('Anti-Alias'), findsOneWidget);

    // Toggle Fill
    await tester.tap(find.text('Fill'));
    await tester.pump(const Duration(milliseconds: 300));

    // Tap theme chip
    expect(find.text('Cyber'), findsOneWidget);
    await tester.tap(find.text('Cyber'));
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('Lines section can be selected and manipulated',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 300));

    final linesFinder = find.byKey(const ValueKey('category_chip_Lines'));
    await tester.scrollUntilVisible(
      linesFinder,
      50.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(linesFinder);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('LINE DYNAMICS'), findsOneWidget);
    expect(find.text('Hairline'), findsOneWidget);
    expect(find.text('Bold'), findsOneWidget);

    await tester.tap(find.text('Bold'));
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('Engine section can be selected and manipulated',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 300));

    final engineFinder = find.byKey(const ValueKey('category_chip_Engine'));
    await tester.scrollUntilVisible(
      engineFinder,
      50.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(engineFinder);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('ENGINE PARAMETERS (*REBUILDS)'), findsOneWidget);
    expect(find.text('Re-seed'), findsOneWidget);
    expect(find.text('150'), findsOneWidget);

    await tester.tap(find.text('150'));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Re-seed'));
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('Gravity section can be selected and manipulated',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 300));

    final gravityFinder = find.byKey(const ValueKey('category_chip_Gravity'));
    await tester.scrollUntilVisible(
      gravityFinder,
      50.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(-80, 0));
    await tester.pump(const Duration(milliseconds: 300));

    expect(gravityFinder, findsOneWidget);
    await tester.tap(gravityFinder);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('GRAVITY SETTINGS'), findsOneWidget);
    expect(find.text('Global'), findsOneWidget);
    expect(find.text('Point'), findsOneWidget);

    await tester.tap(find.text('Global'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Earth ⬇️'), findsOneWidget);
    await tester.tap(find.text('Earth ⬇️'));
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('Showcase Presets can be selected and applied',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 300));

    final presetsFinder = find.byKey(const ValueKey('category_chip_Presets'));
    await tester.scrollUntilVisible(
      presetsFinder,
      50.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(-80, 0));
    await tester.pump(const Duration(milliseconds: 300));

    expect(presetsFinder, findsOneWidget);
    await tester.tap(presetsFinder);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('SHOWCASE PRESETS'), findsOneWidget);
    expect(find.text('Cosmic Web'), findsOneWidget);
    expect(find.text('Cyberpunk Matrix'), findsOneWidget);

    // Apply Cyberpunk Matrix preset
    await tester.tap(find.text('Cyberpunk Matrix'));
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('Code export dialog opens and displays generated code',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byTooltip('Export Dart Code'), findsOneWidget);
    await tester.tap(find.byTooltip('Export Dart Code'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Generated Dart Code'), findsOneWidget);
    expect(find.text('Copy Code'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('Mobile responsive layout renders correctly and collapses/expands',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ParticleControllerScreen), findsOneWidget);
    expect(find.byTooltip('Hide Panel'), findsOneWidget);

    // Collapse panel on mobile
    await tester.tap(find.byTooltip('Hide Panel'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Open Engine Controls'), findsOneWidget);

    // Expand panel again
    await tester.tap(find.text('Open Engine Controls'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('ENGINE CONTROLS'), findsOneWidget);
  });

  testWidgets('Landscape mobile renders without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(640, 310);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ParticleControllerScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ultra-compact mobile portrait renders without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ParticleControllerScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Short viewport height renders safely without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 300);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ParticleControllerScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Point gravity interactive placement and reset works',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 300));

    final gravityFinder = find.byKey(const ValueKey('category_chip_Gravity'));
    await tester.scrollUntilVisible(
      gravityFinder,
      50.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(-80, 0));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(gravityFinder);
    await tester.pump(const Duration(milliseconds: 300));

    // Switch to Point Gravity
    await tester.tap(find.text('Point'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Singularity: Canvas Center'), findsOneWidget);
    expect(find.text('Place on Canvas'), findsOneWidget);

    // Tap "Place on Canvas"
    await tester.tap(find.text('Place on Canvas'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Tap canvas to place singularity'), findsOneWidget);

    // Tap on the canvas at (150, 150)
    await tester.tapAt(const Offset(150, 150));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Singularity: (150, 150)'), findsOneWidget);
    expect(find.text('Reset Center'), findsOneWidget);

    // Tap "Reset Center"
    await tester.tap(find.text('Reset Center'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Singularity: Canvas Center'), findsOneWidget);
  });
}
