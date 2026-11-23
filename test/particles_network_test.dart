import 'dart:ui' show FrameTiming;
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:particles_network/particles_network.dart';
import 'package:particles_network/src/legacy/legacy_deprecation_logger.dart';

void main() {
  testWidgets('ParticleNetwork builds correctly with default parameters', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 300, height: 300, child: ParticleNetwork()),
        ),
      ),
    );

    expect(find.byType(ParticleNetwork), findsOneWidget);

    expect(
      find.descendant(
        of: find.byType(ParticleNetwork),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );

    // التحقق من وجود Listener للتعامل مع اللمس
    expect(
      find.descendant(
        of: find.byType(ParticleNetwork),
        matching: find.byType(Listener),
      ),
      findsOneWidget,
    );
  });

  testWidgets('ParticleNetwork respects parameters', (
    WidgetTester tester,
  ) async {
    const testColor = Color(0xFFFF0000);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: ParticleNetwork(
              particleCount: 10,
              particleColor: testColor,
              touch: TouchFeatures(enabled: false),
            ),
          ),
        ),
      ),
    );

    final widget = tester.widget<ParticleNetwork>(find.byType(ParticleNetwork));
    expect(widget.particleCount, 10);
    expect(widget.particleColor, testColor);
    expect(widget.touch.enabled, false);
  });

  testWidgets('ParticleNetwork handles resize', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 100, height: 100, child: ParticleNetwork()),
        ),
      ),
    );

    expect(find.byType(ParticleNetwork), findsOneWidget);

    // تغيير الحجم إلى 200x200
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 200, height: 200, child: ParticleNetwork()),
        ),
      ),
    );

    expect(find.byType(ParticleNetwork), findsOneWidget);
  });

  testWidgets('ParticleNetwork handles touch interactions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: ParticleNetwork(touch: TouchFeatures(enabled: true)),
          ),
        ),
      ),
    );

    final state = tester.state<ParticleNetworkState>(
      find.byType(ParticleNetwork),
    );

    expect(state.touchPoint, equals(Offset.infinite));

    final gesture = await tester.startGesture(const Offset(150, 150));
    await tester.pump();
    expect(state.touchPoint, equals(const Offset(150, 150)));

    await gesture.moveBy(const Offset(10, 10));
    await tester.pump();
    expect(state.touchPoint, equals(const Offset(160, 160)));

    await gesture.up();
    await tester.pump();
    expect(state.touchPoint, equals(Offset.infinite));
  });

  testWidgets('ParticleNetwork handles touch interactions with show: false', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: ParticleNetwork(
              touch: TouchFeatures(enabled: true, show: false),
            ),
          ),
        ),
      ),
    );

    final state = tester.state<ParticleNetworkState>(
      find.byType(ParticleNetwork),
    );

    expect(state.widget.touch.show, isFalse);
    expect(state.painter.touchFeatures.show, isFalse);
    expect(state.painter.touchHandler.show, isFalse);
    expect(state.touchPoint, equals(Offset.infinite));

    final gesture = await tester.startGesture(const Offset(150, 150));
    await tester.pump();
    expect(state.touchPoint, equals(const Offset(150, 150)));
    expect(state.painter.touchHandler.lastLineCount, equals(0));

    await gesture.up();
    await tester.pump();
  });

  testWidgets('ParticleNetwork supports touch: TouchFeatures(show: ...) dynamic widget toggling', (
    WidgetTester tester,
  ) async {
    bool showLines = false;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 300,
                child: ParticleNetwork(
                  touch: TouchFeatures(show: showLines),
                  particles: const ParticleFeatures(count: 20),
                  network: const NetworkFeatures(distance: 200.0),
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () => setState(() => showLines = !showLines),
                child: const Icon(Icons.refresh),
              ),
            ),
          );
        },
      ),
    );

    final state = tester.state<ParticleNetworkState>(
      find.byType(ParticleNetwork),
    );

    // Initialized via touch: TouchFeatures(show: false)
    expect(state.widget.touch.show, isFalse);
    expect(state.painter.show, isFalse);
    expect(state.painter.touchHandler.show, isFalse);

    // Touch down while show is false
    final gesture = await tester.startGesture(const Offset(150, 150));
    await tester.pump(const Duration(milliseconds: 50));
    expect(state.painter.touchHandler.lastLineCount, equals(0));

    // Toggle show to true via setState rebuild
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 50));

    expect(state.widget.touch.show, isTrue);
    expect(state.painter.show, isTrue);
    expect(state.painter.touchHandler.show, isTrue);
    expect(state.painter.touchHandler.lastLineCount, greaterThan(0));

    // Toggle show back to false during continuous drag
    await gesture.moveTo(const Offset(160, 160));
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 50));

    expect(state.widget.touch.show, isFalse);
    expect(state.painter.show, isFalse);
    expect(state.painter.touchHandler.show, isFalse);
    expect(state.painter.touchHandler.lastLineCount, equals(0));

    await gesture.up();
    await tester.pump();
  });

  testWidgets('ParticleNetwork logs error when shader fails to load', (
    WidgetTester tester,
  ) async {
    final logs = <String>[];
    final originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) logs.add(message);
    };

    try {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ParticleNetwork())),
      );

      await tester.pump(const Duration(milliseconds: 200));

      logs.any(
        (log) =>
            log.toLowerCase().contains('shader') ||
            log.toLowerCase().contains('fail'),
      );

      expect(find.byType(ParticleNetwork), findsOneWidget);
    } finally {
      debugPrint = originalDebugPrint;
    }
  });

  testWidgets('ParticleNetwork handles mouse hover when hoverEffect is true', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: ParticleNetwork(hoverEffect: true),
          ),
        ),
      ),
    );

    final state = tester.state<ParticleNetworkState>(
      find.byType(ParticleNetwork),
    );

    expect(state.touchPoint, equals(Offset.infinite));

    // Simulate mouse hover
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.hover(const Offset(100, 100)));
    await tester.pump();

    expect(state.touchPoint, equals(const Offset(100, 100)));

    // Move pointer outside to trigger onExit
    await tester.sendEventToBinding(pointer.hover(const Offset(400, 400)));
    await tester.pump();
    expect(state.touchPoint, equals(Offset.infinite));
  });

  testWidgets('ParticleNetwork ignores mouse hover when hoverEffect is false', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: ParticleNetwork(hoverEffect: false),
          ),
        ),
      ),
    );

    final state = tester.state<ParticleNetworkState>(
      find.byType(ParticleNetwork),
    );

    expect(state.touchPoint, equals(Offset.infinite));

    // Simulate mouse hover
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.hover(const Offset(100, 100)));
    await tester.pump();

    // Should still be infinite because hoverEffect is false
    expect(state.touchPoint, equals(Offset.infinite));
  });

  testWidgets(
      'ParticleNetwork handles mouse hover via TouchFeatures(hover: true)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: ParticleNetwork(
              touch: TouchFeatures(hover: true),
            ),
          ),
        ),
      ),
    );

    final state = tester.state<ParticleNetworkState>(
      find.byType(ParticleNetwork),
    );

    expect(state.touchPoint, equals(Offset.infinite));

    // Simulate mouse hover
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.hover(const Offset(100, 100)));
    await tester.pump();

    expect(state.touchPoint, equals(const Offset(100, 100)));

    // Move pointer outside to trigger onExit
    await tester.sendEventToBinding(pointer.hover(const Offset(400, 400)));
    await tester.pump();
    expect(state.touchPoint, equals(Offset.infinite));
  });

  testWidgets(
      'ParticleNetwork ignores mouse hover via TouchFeatures(hover: false)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: ParticleNetwork(
              touch: TouchFeatures(hover: false),
            ),
          ),
        ),
      ),
    );

    final state = tester.state<ParticleNetworkState>(
      find.byType(ParticleNetwork),
    );

    expect(state.touchPoint, equals(Offset.infinite));

    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.hover(const Offset(100, 100)));
    await tester.pump();

    expect(state.touchPoint, equals(Offset.infinite));
  });

  testWidgets(
      'ParticleNetwork backward compatibility merges legacy hoverEffect into effectiveTouchFeatures',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: ParticleNetwork(
              hoverEffect: true,
            ),
          ),
        ),
      ),
    );

    final widget = tester.widget<ParticleNetwork>(find.byType(ParticleNetwork));
    expect(widget.hoverEffect, isTrue);
    expect(widget.effectiveTouchFeatures.hover, isTrue);
    expect(widget.usedLegacyHoverEffect, isTrue);
  });

  testWidgets('ParticleNetwork handles pan cancel', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: ParticleNetwork(),
          ),
        ),
      ),
    );

    final state = tester.state<ParticleNetworkState>(
      find.byType(ParticleNetwork),
    );

    expect(state.touchPoint, equals(Offset.infinite));

    // Start a gesture
    final gesture = await tester.startGesture(const Offset(150, 150));
    await tester.pump();
    expect(state.touchPoint, equals(const Offset(150, 150)));

    // Cancel the gesture
    await gesture.cancel();
    await tester.pump();
    expect(state.touchPoint, equals(Offset.infinite));

    final customPaint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(ParticleNetwork),
        matching: find.byType(CustomPaint),
      ),
    );
    final painter = customPaint.painter as OptimizedNetworkPainter;
    expect(painter.touchPoint, equals(Offset.infinite));
  });

  testWidgets('ParticleNetworkState exposes particles from simulation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: ParticleNetwork(particleCount: 25),
          ),
        ),
      ),
    );

    final state = tester.state<ParticleNetworkState>(
      find.byType(ParticleNetwork),
    );

    expect(state.particles, same(state.simulation.particles));
    expect(state.particles.length, 25);
  });

  testWidgets(
    'ParticleNetwork didUpdateWidget updates simulation factory on maxSpeed, maxSize, or color change',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                maxSpeed: 2.0,
                maxSize: 4.0,
                particleColor: Colors.red,
              ),
            ),
          ),
        ),
      );

      final state = tester.state<ParticleNetworkState>(
        find.byType(ParticleNetwork),
      );
      var factory = state.factory as DefaultParticleFactory;
      expect(factory.maxSpeed, 2.0);
      expect(factory.maxSize, 4.0);
      expect(factory.color, Colors.red);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                maxSpeed: 6.0,
                maxSize: 10.0,
                particleColor: Colors.blue,
              ),
            ),
          ),
        ),
      );

      factory = state.factory as DefaultParticleFactory;
      expect(factory.maxSpeed, 6.0);
      expect(factory.maxSize, 10.0);
      expect(factory.color, Colors.blue);
    },
  );

  testWidgets('ParticleNetwork didUpdateWidget updates particleCount', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: ParticleNetwork(particleCount: 20),
          ),
        ),
      ),
    );

    final state = tester.state<ParticleNetworkState>(
      find.byType(ParticleNetwork),
    );
    expect(state.particles.length, 20);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: ParticleNetwork(particleCount: 35),
          ),
        ),
      ),
    );

    expect(state.particles.length, 35);
  });

  testWidgets('ParticleNetwork didUpdateWidget updates painter colors', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: ParticleNetwork(
              particleColor: Colors.white,
              lineColor: Colors.grey,
              touch: TouchFeatures(color: Colors.yellow),
            ),
          ),
        ),
      ),
    );

    CustomPaint customPaint = tester.widget(
      find.descendant(
        of: find.byType(ParticleNetwork),
        matching: find.byType(CustomPaint),
      ),
    );
    var painter = customPaint.painter as OptimizedNetworkPainter;
    expect(painter.particleColor, Colors.white);
    expect(painter.lineColor, Colors.grey);
    expect(painter.touchColor, Colors.yellow);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: ParticleNetwork(
              particleColor: Colors.green,
              lineColor: Colors.purple,
              touch: TouchFeatures(color: Colors.orange),
            ),
          ),
        ),
      ),
    );

    customPaint = tester.widget(
      find.descendant(
        of: find.byType(ParticleNetwork),
        matching: find.byType(CustomPaint),
      ),
    );
    painter = customPaint.painter as OptimizedNetworkPainter;
    expect(painter.particleColor, Colors.green);
    expect(painter.lineColor, Colors.purple);
    expect(painter.touchColor, Colors.orange);
  });

  testWidgets('ParticleNetwork didUpdateWidget updates painter lineWidth', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: ParticleNetwork(lineWidth: 1.5),
          ),
        ),
      ),
    );

    CustomPaint customPaint = tester.widget(
      find.descendant(
        of: find.byType(ParticleNetwork),
        matching: find.byType(CustomPaint),
      ),
    );
    var painter = customPaint.painter as OptimizedNetworkPainter;
    expect(painter.lineWidth, 1.5);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: ParticleNetwork(lineWidth: 3.5),
          ),
        ),
      ),
    );

    customPaint = tester.widget(
      find.descendant(
        of: find.byType(ParticleNetwork),
        matching: find.byType(CustomPaint),
      ),
    );
    painter = customPaint.painter as OptimizedNetworkPainter;
    expect(painter.lineWidth, 3.5);
  });

  testWidgets('ParticleNetwork didUpdateWidget updates painter lineDistance', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: ParticleNetwork(lineDistance: 75.0),
          ),
        ),
      ),
    );

    CustomPaint customPaint = tester.widget(
      find.descendant(
        of: find.byType(ParticleNetwork),
        matching: find.byType(CustomPaint),
      ),
    );
    var painter = customPaint.painter as OptimizedNetworkPainter;
    expect(painter.lineDistance, 75.0);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: ParticleNetwork(lineDistance: 130.0),
          ),
        ),
      ),
    );

    customPaint = tester.widget(
      find.descendant(
        of: find.byType(ParticleNetwork),
        matching: find.byType(CustomPaint),
      ),
    );
    painter = customPaint.painter as OptimizedNetworkPainter;
    expect(painter.lineDistance, 130.0);
  });

  testWidgets('ParticleNetwork didUpdateWidget updates painter render flags', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: ParticleNetwork(
              drawNetwork: true,
              fill: true,
              isComplex: false,
              touch: TouchFeatures(enabled: false),
            ),
          ),
        ),
      ),
    );

    CustomPaint customPaint = tester.widget(
      find.descendant(
        of: find.byType(ParticleNetwork),
        matching: find.byType(CustomPaint),
      ),
    );
    var painter = customPaint.painter as OptimizedNetworkPainter;
    expect(painter.drawNetwork, isTrue);
    expect(painter.fill, isTrue);
    expect(painter.isComplex, isFalse);
    expect(painter.touchActivation, isFalse);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: ParticleNetwork(
              drawNetwork: false,
              fill: false,
              isComplex: true,
              touch: TouchFeatures(enabled: true),
            ),
          ),
        ),
      ),
    );

    customPaint = tester.widget(
      find.descendant(
        of: find.byType(ParticleNetwork),
        matching: find.byType(CustomPaint),
      ),
    );
    painter = customPaint.painter as OptimizedNetworkPainter;
    expect(painter.drawNetwork, isFalse);
    expect(painter.fill, isFalse);
    expect(painter.isComplex, isTrue);
    expect(painter.touchActivation, isTrue);
  });

  testWidgets('ParticleNetwork didUpdateWidget updates painter touchFeatures', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: ParticleNetwork(
              touchFeatures: TouchFeatures(force: 0.5, damping: 0.95),
            ),
          ),
        ),
      ),
    );

    CustomPaint customPaint = tester.widget(
      find.descendant(
        of: find.byType(ParticleNetwork),
        matching: find.byType(CustomPaint),
      ),
    );
    var painter = customPaint.painter as OptimizedNetworkPainter;
    expect(painter.touchFeatures.force, 0.5);
    expect(painter.touchFeatures.damping, 0.95);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: ParticleNetwork(
              touchFeatures: TouchFeatures(
                force: 0.8,
                damping: 0.99,
                lineDistance: 175.0,
              ),
            ),
          ),
        ),
      ),
    );

    customPaint = tester.widget(
      find.descendant(
        of: find.byType(ParticleNetwork),
        matching: find.byType(CustomPaint),
      ),
    );
    painter = customPaint.painter as OptimizedNetworkPainter;
    expect(painter.touchFeatures.force, 0.8);
    expect(painter.touchFeatures.damping, 0.99);
    expect(painter.touchFeatures.lineDistance, 175.0);
  });

  test('TouchFeatures defaults and lineDistance assignment', () {
    const featuresDefault = TouchFeatures();
    expect(featuresDefault.lineDistance, isNull);

    const customFeatures = TouchFeatures(lineDistance: 150.0);
    expect(customFeatures.lineDistance, equals(150.0));
  });

  test('ParticleNetwork constructor defaults', () {
    const network = ParticleNetwork();
    expect(network.particleCount, 60);
    expect(network.maxSpeed, 0.5);
    expect(network.maxSize, 1.5);
    expect(network.lineWidth, 0.5);
    expect(network.lineDistance, 100);
    expect(network.particleColor, Colors.white);
    expect(network.lineColor, const Color.fromARGB(255, 100, 255, 180));
    expect(network.touch.color, const Color(0xFFFFC107));
    expect(network.touch.enabled, isTrue);
    expect(network.isComplex, isFalse);
    expect(network.fill, isTrue);
    expect(network.drawNetwork, isTrue);
    expect(network.gravityType, GravityType.none);
    expect(network.gravityStrength, 0.1);
    expect(network.gravityDirection, const Offset(0, 1));
    expect(network.gravityCenter, isNull);
    expect(network.hoverEffect, isFalse);
    expect(network.touchFeatures, const TouchFeatures());
    expect(network.performance, const PerformanceFeatures());
  });

  test('ParticleNetwork constructor handles PerformanceFeatures', () {
    const network1 = ParticleNetwork(
      performance: PerformanceFeatures(complex: ComplexConfig(enabled: true)),
    );
    expect(network1.performance.isComplex, isTrue);

    const network2 = ParticleNetwork(
      performance: PerformanceFeatures(complex: ComplexConfig(enabled: false)),
    );
    expect(network2.performance.isComplex, isFalse);

    const network4 = ParticleNetwork(
      performance: PerformanceFeatures(
        maxConnectionsPerParticle: 4,
        autoBoost: true,
      ),
    );
    expect(network4.performance.maxConnectionsPerParticle, equals(4));
    expect(network4.performance.autoBoost, isTrue);
  });

  testWidgets('ParticleNetworkState factory getter and setter', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 300, height: 300, child: ParticleNetwork()),
        ),
      ),
    );

    final state = tester.state<ParticleNetworkState>(
      find.byType(ParticleNetwork),
    );
    expect(state.factory, same(state.simulation.factory));

    final customFactory = DefaultParticleFactory(
      random: Random(42),
      maxSpeed: 7.0,
      maxSize: 9.0,
      color: Colors.teal,
    );
    state.factory = customFactory;

    expect(state.factory, same(customFactory));
    expect(state.simulation.factory, same(customFactory));
  });

  testWidgets('ParticleNetworkState controller getter', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 300, height: 300, child: ParticleNetwork()),
        ),
      ),
    );

    final state = tester.state<ParticleNetworkState>(
      find.byType(ParticleNetwork),
    );
    expect(state.controller, same(state.simulation.controller));
    expect(state.controller, isA<IParticleController>());
  });

  testWidgets(
    'ParticleNetwork didUpdateWidget updates simulation gravity',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                gravityType: GravityType.none,
                gravityStrength: 0.1,
                gravityDirection: Offset(0, 1),
              ),
            ),
          ),
        ),
      );

      final state = tester.state<ParticleNetworkState>(
        find.byType(ParticleNetwork),
      );
      expect(state.simulation.gravityConfig.type, GravityType.none);
      expect(state.simulation.gravityConfig.strength, 0.1);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                gravityType: GravityType.point,
                gravityStrength: 0.8,
                gravityDirection: Offset(1, 0),
                gravityCenter: Offset(150, 150),
              ),
            ),
          ),
        ),
      );

      expect(state.simulation.gravityConfig.type, GravityType.point);
      expect(state.simulation.gravityConfig.strength, 0.8);
      expect(state.simulation.gravityConfig.direction, const Offset(1, 0));
      expect(state.simulation.gravityConfig.center, const Offset(150, 150));
    },
  );

  testWidgets(
    'ParticleNetwork didUpdateWidget updates simulation gravity using GravityFeatures',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                gravity: GravityFeatures.none(),
              ),
            ),
          ),
        ),
      );

      final state = tester.state<ParticleNetworkState>(
        find.byType(ParticleNetwork),
      );
      expect(state.simulation.gravityConfig.type, GravityType.none);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                gravity: GravityFeatures(
                  type: GravityType.point,
                  strength: 0.9,
                  direction: Offset(0, -1),
                  center: Offset(120, 120),
                ),
              ),
            ),
          ),
        ),
      );

      expect(state.simulation.gravityConfig.type, GravityType.point);
      expect(state.simulation.gravityConfig.strength, 0.9);
      expect(state.simulation.gravityConfig.direction, const Offset(0, -1));
      expect(state.simulation.gravityConfig.center, const Offset(120, 120));
    },
  );

  test('ParticleNetwork detects usedLegacyGravity correctly', () {
    const modern = ParticleNetwork(
      gravity: GravityFeatures(type: GravityType.global),
    );
    expect(modern.usedLegacyGravity, isFalse);

    const defaultWidget = ParticleNetwork();
    expect(defaultWidget.usedLegacyGravity, isFalse);

    const legacyWidget = ParticleNetwork(
      gravityType: GravityType.global,
      gravityStrength: 0.5,
    );
    expect(legacyWidget.usedLegacyGravity, isTrue);
  });

  test('ParticleNetwork touch and touchFeatures properties work correctly', () {
    const modern = ParticleNetwork(
      touch: TouchFeatures(color: Colors.blue),
    );
    expect(modern.touch.color, Colors.blue);
    expect(modern.touchFeatures.color, Colors.blue);

    const defaultWidget = ParticleNetwork();
    expect(defaultWidget.touch.color, const Color(0xFFFFC107));
    expect(defaultWidget.touch.enabled, isTrue);

    const withAlias = ParticleNetwork(
      touchFeatures: TouchFeatures(color: Colors.purple, enabled: false),
    );
    expect(withAlias.touch.color, Colors.purple);
    expect(withAlias.touch.enabled, isFalse);
  });

  test('TouchFeatures color property and copyWith', () {
    const defaultFeatures = TouchFeatures();
    expect(defaultFeatures.color, const Color(0xFFFFC107));
    expect(defaultFeatures.enabled, isTrue);

    const custom = TouchFeatures(color: Colors.teal, enabled: false);
    expect(custom.color, Colors.teal);
    expect(custom.enabled, isFalse);

    final copied = custom.copyWith(color: Colors.deepOrange, enabled: true);
    expect(copied.color, Colors.deepOrange);
    expect(copied.enabled, isTrue);
    expect(copied.speed, custom.speed);
  });

  testWidgets(
    'Listener onPointerCancel updates touchPoint to Offset.infinite',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 300, height: 300, child: ParticleNetwork()),
          ),
        ),
      );

      final state = tester.state<ParticleNetworkState>(
        find.byType(ParticleNetwork),
      );

      state.touchPoint = const Offset(120, 120);

      final listener = tester.widget<Listener>(
        find.descendant(
          of: find.byType(ParticleNetwork),
          matching: find.byType(Listener),
        ),
      );
      listener.onPointerCancel?.call(const PointerCancelEvent(pointer: 0));
      await tester.pump();

      expect(state.touchPoint, equals(Offset.infinite));

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(ParticleNetwork),
          matching: find.byType(CustomPaint),
        ),
      );
      final painter = customPaint.painter as OptimizedNetworkPainter;
      expect(painter.touchPoint, equals(Offset.infinite));
    },
  );

  testWidgets(
    'ParticleNetwork didUpdateWidget updates painter performance options',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                performance: PerformanceFeatures(
                  maxConnectionsPerParticle: null,
                ),
                network: NetworkFeatures(
                  renderer: LineRenderer.stroke,
                ),
              ),
            ),
          ),
        ),
      );

      CustomPaint customPaint = tester.widget(
        find.descendant(
          of: find.byType(ParticleNetwork),
          matching: find.byType(CustomPaint),
        ),
      );
      var painter = customPaint.painter as OptimizedNetworkPainter;
      expect(painter.maxConnectionsPerParticle, isNull);
      expect(painter.lineRenderer, equals(LineRenderer.stroke));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                performance: PerformanceFeatures(
                  maxConnectionsPerParticle: 3,
                ),
                network: NetworkFeatures(
                  renderer: LineRenderer.vertices,
                ),
              ),
            ),
          ),
        ),
      );

      customPaint = tester.widget(
        find.descendant(
          of: find.byType(ParticleNetwork),
          matching: find.byType(CustomPaint),
        ),
      );
      painter = customPaint.painter as OptimizedNetworkPainter;
      expect(painter.maxConnectionsPerParticle, equals(3));
      expect(painter.lineRenderer, equals(LineRenderer.vertices));
    },
  );

  testWidgets(
    'ParticleNetwork regulates dynamic line budget and keeps lineDistance constant when autoBoost is true',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                lineDistance: 100.0,
                performance: PerformanceFeatures(
                  maxConnectionsPerParticle: 10,
                  autoBoost: true,
                ),
              ),
            ),
          ),
        ),
      );

      final customPaintFinder = find.descendant(
        of: find.byType(ParticleNetwork),
        matching: find.byType(CustomPaint),
      );

      var customPaint = tester.widget<CustomPaint>(customPaintFinder);
      var painter = customPaint.painter as OptimizedNetworkPainter;
      expect(painter.lineDistance, equals(100.0));
      expect(painter.maxConnectionsPerParticle, equals(10));

      // Report 5 frames whose raster phase took 30ms (budget is 16.67ms).
      // Adaptivity is driven by engine FrameTiming, not tick intervals.
      final timings = List<FrameTiming>.generate(5, (int i) {
        final int start = i * 40000;
        return FrameTiming(
          vsyncStart: start,
          buildStart: start,
          buildFinish: start + 4000,
          rasterStart: start + 4000,
          rasterFinish: start + 34000,
          rasterFinishWallTime: start + 34000,
        );
      });
      tester.binding.platformDispatcher.onReportTimings!(timings);
      await tester.pump(const Duration(milliseconds: 16));

      customPaint = tester.widget<CustomPaint>(customPaintFinder);
      painter = customPaint.painter as OptimizedNetworkPainter;

      // Line distance remains constant; line budget is throttled down
      expect(painter.lineDistance, equals(100.0));
      expect(painter.effectiveMaxLines, lessThanOrEqualTo(4000));
    },
  );

  testWidgets(
    'ParticleNetwork does not adjust line distance when autoBoost is false',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                lineDistance: 100.0,
                performance: PerformanceFeatures(
                  maxConnectionsPerParticle: 10,
                  autoBoost: false,
                ),
              ),
            ),
          ),
        ),
      );

      final customPaintFinder = find.descendant(
        of: find.byType(ParticleNetwork),
        matching: find.byType(CustomPaint),
      );

      var customPaint = tester.widget<CustomPaint>(customPaintFinder);
      var painter = customPaint.painter as OptimizedNetworkPainter;
      expect(painter.lineDistance, equals(100.0));
      expect(painter.maxConnectionsPerParticle, equals(10));

      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 30));
      }

      customPaint = tester.widget<CustomPaint>(customPaintFinder);
      painter = customPaint.painter as OptimizedNetworkPainter;

      expect(painter.lineDistance, equals(100.0));
      expect(painter.maxConnectionsPerParticle, equals(10));
    },
  );

  testWidgets(
    'ParticleNetwork didUpdateWidget updates autoBoost (L392)',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                lineDistance: 100.0,
                performance: PerformanceFeatures(
                  maxConnectionsPerParticle: 10,
                  autoBoost: false,
                ),
              ),
            ),
          ),
        ),
      );

      final customPaintFinder = find.descendant(
        of: find.byType(ParticleNetwork),
        matching: find.byType(CustomPaint),
      );

      var customPaint = tester.widget<CustomPaint>(customPaintFinder);
      var painter = customPaint.painter as OptimizedNetworkPainter;
      expect(painter.lineDistance, equals(100.0));

      final timings = List<FrameTiming>.generate(5, (int i) {
        final int start = i * 40000;
        return FrameTiming(
          vsyncStart: start,
          buildStart: start,
          buildFinish: start + 4000,
          rasterStart: start + 4000,
          rasterFinish: start + 34000,
          rasterFinishWallTime: start + 34000,
        );
      });

      // While false, reporting slow timings does not throttle line distance
      tester.binding.platformDispatcher.onReportTimings!(timings);
      await tester.pump(const Duration(milliseconds: 16));

      customPaint = tester.widget<CustomPaint>(customPaintFinder);
      painter = customPaint.painter as OptimizedNetworkPainter;
      expect(painter.lineDistance, equals(100.0));

      // Toggle autoBoost from false to true via didUpdateWidget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                lineDistance: 100.0,
                performance: PerformanceFeatures(
                  maxConnectionsPerParticle: 10,
                  autoBoost: true,
                ),
              ),
            ),
          ),
        ),
      );

      // Now reporting slow timings throttles line budget
      tester.binding.platformDispatcher.onReportTimings!(timings);
      await tester.pump(const Duration(milliseconds: 16));

      customPaint = tester.widget<CustomPaint>(customPaintFinder);
      painter = customPaint.painter as OptimizedNetworkPainter;
      expect(painter.lineDistance, equals(100.0));
      expect(painter.runtimeMaxLinesOverride, isNotNull);

      // Toggle autoBoost back to false via didUpdateWidget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                lineDistance: 100.0,
                performance: PerformanceFeatures(
                  maxConnectionsPerParticle: 10,
                  autoBoost: false,
                ),
              ),
            ),
          ),
        ),
      );

      customPaint = tester.widget<CustomPaint>(customPaintFinder);
      painter = customPaint.painter as OptimizedNetworkPainter;
      expect(painter.lineDistance, equals(100.0));
      expect(painter.runtimeMaxLinesOverride, isNull);
      expect(painter.runtimeMaxConnectionsOverride, isNull);
      expect(painter.maxConnectionsPerParticle, equals(10));
    },
  );

  testWidgets(
    'didUpdateWidget preserves lineDistance when lineDistance changes',
    (WidgetTester tester) async {
      final customPaintFinder = find.descendant(
        of: find.byType(ParticleNetwork),
        matching: find.byType(CustomPaint),
      );

      final timings = List<FrameTiming>.generate(5, (int i) {
        final int start = i * 40000;
        return FrameTiming(
          vsyncStart: start,
          buildStart: start,
          buildFinish: start + 4000,
          rasterStart: start + 4000,
          rasterFinish: start + 34000,
          rasterFinishWallTime: start + 34000,
        );
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                lineDistance: 100.0,
                performance: PerformanceFeatures(
                  autoBoost: true,
                ),
              ),
            ),
          ),
        ),
      );

      tester.binding.platformDispatcher.onReportTimings!(timings);
      await tester.pump(const Duration(milliseconds: 16));

      var customPaint = tester.widget<CustomPaint>(customPaintFinder);
      var painter = customPaint.painter as OptimizedNetworkPainter;
      expect(painter.lineDistance, equals(100.0));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                lineDistance: 200.0,
                performance: PerformanceFeatures(
                  autoBoost: true,
                ),
              ),
            ),
          ),
        ),
      );

      customPaint = tester.widget<CustomPaint>(customPaintFinder);
      painter = customPaint.painter as OptimizedNetworkPainter;
      expect(painter.lineDistance, equals(200.0));
    },
  );

  test(
    'effectiveDrawNetwork reflects legacy drawNetwork and modern network.enabled',
    () {
      // Legacy parameter (drawNetwork)
      const legacy = ParticleNetwork(drawNetwork: false);
      expect(legacy.drawNetwork, isFalse);
      expect(legacy.effectiveDrawNetwork, isFalse);

      // Modern parameter
      const modern = ParticleNetwork(
        network: NetworkFeatures(enabled: false),
      );
      expect(modern.effectiveDrawNetwork, isFalse);
    },
  );

  test(
    'effectiveLineWidth reflects legacy lineWidth and modern network.width',
    () {
      // Legacy parameter (lineWidth)
      const legacy = ParticleNetwork(lineWidth: 2.5);
      expect(legacy.lineWidth, equals(2.5));
      expect(legacy.effectiveLineWidth, equals(2.5));

      // Modern parameter
      const modern = ParticleNetwork(
        network: NetworkFeatures(width: 3.0),
      );
      expect(modern.effectiveLineWidth, equals(3.0));
    },
  );

  testWidgets(
    'usedLegacyGravity logs deprecation warning in initState (L408-L412)',
    (WidgetTester tester) async {
      LegacyDeprecationLogger.resetWarned();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                gravityStrength: 0.5,
              ),
            ),
          ),
        ),
      );

      expect(
        LegacyDeprecationLogger.hasWarned(
          'ParticleNetwork(gravityType, gravityStrength, gravityDirection, gravityCenter)',
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'didUpdateWidget updates lineDistance and maxConnections when adaptive performance remains enabled (L588-L598)',
    (WidgetTester tester) async {
      final timings = List<FrameTiming>.generate(5, (int i) {
        final int start = i * 40000;
        return FrameTiming(
          vsyncStart: start,
          buildStart: start,
          buildFinish: start + 4000,
          rasterStart: start + 4000,
          rasterFinish: start + 34000,
          rasterFinishWallTime: start + 34000,
        );
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                lineDistance: 100.0,
                performance: PerformanceFeatures(
                  autoBoost: true,
                  maxConnectionsPerParticle: 10,
                ),
              ),
            ),
          ),
        ),
      );

      // Trigger throttling so scaleFactor drops below 1.0 (e.g. to 0.9)
      tester.binding.platformDispatcher.onReportTimings!(timings);
      await tester.pump(const Duration(milliseconds: 16));

      // Manually set painter lineDistance so _painter.lineDistance != targetDist in didUpdateWidget (L590-L592)
      final initialPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(ParticleNetwork),
          matching: find.byType(CustomPaint),
        ),
      );
      final initialPainter = initialPaint.painter as OptimizedNetworkPainter;
      initialPainter.updateLineDistance(50.0);
      expect(initialPainter.lineDistance, equals(50.0));

      // Re-pump with updated performance parameters while keeping autoBoost: true
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                lineDistance: 100.0,
                performance: PerformanceFeatures(
                  autoBoost: true,
                  maxConnectionsPerParticle: 10,
                  complex: ComplexConfig(enabled: true),
                ),
              ),
            ),
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(ParticleNetwork),
          matching: find.byType(CustomPaint),
        ),
      );
      final painter = customPaint.painter as OptimizedNetworkPainter;
      expect(painter.lineDistance, equals(100.0));
      expect(painter.maxConnectionsPerParticle, equals(10));
    },
  );

  testWidgets(
    'ParticleNetwork with PerformanceFeatures.auto dynamically adapts connections and lines according to frame performance',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                lineDistance: 100.0,
                performance: PerformanceFeatures.auto(),
              ),
            ),
          ),
        ),
      );

      final customPaintFinder = find.descendant(
        of: find.byType(ParticleNetwork),
        matching: find.byType(CustomPaint),
      );
      var customPaint = tester.widget<CustomPaint>(customPaintFinder);
      var painter = customPaint.painter as OptimizedNetworkPainter;

      // Safe baseline initialized for auto preset (fast-path defaults)
      expect(painter.performance.isComplex, isTrue);
      expect(painter.effectiveMaxConnections, isNull);
      expect(painter.performance.maxConnectionsPerParticle, isNull);
      expect(painter.performance.maxLinesPerFrame, isNull);

      // Feed fast frames (4ms raster time, smooth headroom)
      final smoothTimings = List<FrameTiming>.generate(16, (int i) {
        final int start = i * 20000;
        return FrameTiming(
          vsyncStart: start,
          buildStart: start,
          buildFinish: start + 2000,
          rasterStart: start + 2000,
          rasterFinish: start + 5000,
          rasterFinishWallTime: start + 5000,
        );
      });
      tester.binding.platformDispatcher.onReportTimings!(smoothTimings);
      await tester.pump(const Duration(milliseconds: 16));

      customPaint = tester.widget<CustomPaint>(customPaintFinder);
      painter = customPaint.painter as OptimizedNetworkPainter;

      // In autoBoost mode, smooth frames dynamically set line budget up to effectiveMaxCap
      expect(painter.effectiveMaxLines, equals(1800));
      expect(painter.effectiveMaxConnections, isNull);

      // Now feed dropped frames (30ms raster time) to hit floor and trigger Tier 2
      final dropTimings = List<FrameTiming>.generate(20, (int i) {
        final int start = (i + 20) * 40000;
        return FrameTiming(
          vsyncStart: start,
          buildStart: start,
          buildFinish: start + 4000,
          rasterStart: start + 4000,
          rasterFinish: start + 34000,
          rasterFinishWallTime: start + 34000,
        );
      });
      tester.binding.platformDispatcher.onReportTimings!(dropTimings);
      await tester.pump(const Duration(milliseconds: 16));

      customPaint = tester.widget<CustomPaint>(customPaintFinder);
      painter = customPaint.painter as OptimizedNetworkPainter;

      // Dropped frames cause Tier 1 to drop to floor (500) and Tier 2 to engage emergency capping
      expect(painter.effectiveMaxLines, equals(500));
      expect(painter.effectiveMaxConnections, isNotNull);
      expect(painter.lineDistance, equals(100.0));
    },
  );

  testWidgets(
    'ParticleNetwork with PerformanceFeatures.auto can scale connections beyond 15 on high performance',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                lineDistance: 100.0,
                performance: PerformanceFeatures.auto(),
              ),
            ),
          ),
        ),
      );

      final customPaintFinder = find.descendant(
        of: find.byType(ParticleNetwork),
        matching: find.byType(CustomPaint),
      );
      var customPaint = tester.widget<CustomPaint>(customPaintFinder);
      var painter = customPaint.painter as OptimizedNetworkPainter;

      // Baseline fast-path
      expect(painter.effectiveMaxConnections, isNull);
      expect(painter.performance.isComplex, isTrue);

      // Feed fast frames
      final smoothTimings = List<FrameTiming>.generate(320, (int i) {
        final int start = i * 20000;
        return FrameTiming(
          vsyncStart: start,
          buildStart: start,
          buildFinish: start + 1000,
          rasterStart: start + 1000,
          rasterFinish: start + 3000,
          rasterFinishWallTime: start + 3000,
        );
      });
      tester.binding.platformDispatcher.onReportTimings!(smoothTimings);
      await tester.pump(const Duration(milliseconds: 16));

      customPaint = tester.widget<CustomPaint>(customPaintFinder);
      painter = customPaint.painter as OptimizedNetworkPainter;

      // Connections remain uncapped on fast path
      expect(painter.effectiveMaxConnections, isNull);
      expect(painter.effectiveMaxLines, equals(1800));
      // Line distance was preserved at base distance
      expect(painter.lineDistance, equals(100.0));
    },
  );

  group('ParticleNetwork widget getters & factory update (L56-L57, L296-L306, L503-L509)', () {
    test('effectiveIsComplex returns correct value based on isComplex and performance (L56-L57)', () {
      const widgetLegacy = ParticleNetwork(isComplex: true);
      expect(widgetLegacy.effectiveIsComplex, isTrue);

      const widgetPerformance = ParticleNetwork(
        performance: PerformanceFeatures(complex: ComplexConfig(enabled: false)),
      );
      expect(widgetPerformance.effectiveIsComplex, isFalse);

      const widgetDefault = ParticleNetwork();
      expect(widgetDefault.effectiveIsComplex, equals(widgetDefault.performance.isComplex));
    });

    testWidgets(
        'ParticleNetworkState exposes painter frame statistics and limits getters (L296-L306)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                particleCount: 20,
                lineDistance: 50.0,
                performance: PerformanceFeatures(
                  maxConnectionsPerParticle: 5,
                  maxLinesPerFrame: 100,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 16));

      final state = tester.state<ParticleNetworkState>(
        find.byType(ParticleNetwork),
      );

      expect(state.lastFrameLineCount, isA<int>());
      expect(state.lastFrameLineCount, equals(state.painter.lastFrameLineCount));
      expect(state.lastFrameLineDistance, isA<double>());
      expect(state.lastFrameLineDistance, equals(state.painter.lastFrameLineDistance));
      expect(state.effectiveMaxConnections, equals(5));
      expect(state.effectiveMaxLines, equals(100));
    });

    testWidgets(
        'didUpdateWidget resets to default factory when particleFactory is set to null (L503-L509)',
        (WidgetTester tester) async {
      final customFactory = DefaultParticleFactory(
        random: Random(42),
        maxSpeed: 10.0,
        maxSize: 10.0,
        color: Colors.blue,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                particleFactory: customFactory,
                maxSpeed: 2.0,
                maxSize: 3.0,
                particleColor: Colors.white,
              ),
            ),
          ),
        ),
      );

      final state = tester.state<ParticleNetworkState>(
        find.byType(ParticleNetwork),
      );
      expect(state.simulation.factory, equals(customFactory));

      // Update widget: remove custom factory (set to null)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                particleFactory: null,
                maxSpeed: 4.5,
                maxSize: 6.5,
                particleColor: Colors.green,
              ),
            ),
          ),
        ),
      );

      // Verify that simulation factory was updated with the new parameters
      expect(state.simulation.factory, isNot(equals(customFactory)));
      expect(state.simulation.factory, isA<DefaultParticleFactory>());
      final defaultFactory = state.simulation.factory as DefaultParticleFactory;
      expect(defaultFactory.maxSpeed, equals(4.5));
      expect(defaultFactory.maxSize, equals(6.5));
      expect(defaultFactory.color, equals(Colors.green));
    });
  });
}
