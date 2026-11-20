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

    // التحقق من وجود GestureDetector للتعامل مع اللمس
    expect(
      find.descendant(
        of: find.byType(ParticleNetwork),
        matching: find.byType(GestureDetector),
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
              touchActivation: false,
            ),
          ),
        ),
      ),
    );

    final widget = tester.widget<ParticleNetwork>(find.byType(ParticleNetwork));
    expect(widget.particleCount, 10);
    expect(widget.particleColor, testColor);
    expect(widget.touchActivation, false);
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
            child: ParticleNetwork(touchActivation: true),
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
              touchColor: Colors.yellow,
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
              touchColor: Colors.orange,
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
              touchActivation: false,
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
              touchActivation: true,
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
    expect(network.touchColor, Colors.amber);
    expect(network.touchActivation, isTrue);
    expect(network.isComplex, isFalse);
    expect(network.fill, isTrue);
    expect(network.drawNetwork, isTrue);
    expect(network.gravityType, GravityType.none);
    expect(network.gravityStrength, 0.1);
    expect(network.gravityDirection, const Offset(0, 1));
    expect(network.gravityCenter, isNull);
    expect(network.hoverEffect, isFalse);
    expect(network.touchFeatures, const TouchFeatures());
    expect(network.performance, const NetworkPerformance());
  });

  test('ParticleNetwork constructor handles NetworkPerformance', () {
    const network1 = ParticleNetwork(
      performance: NetworkPerformance(isComplex: true),
    );
    expect(network1.performance.isComplex, isTrue);

    const network2 = ParticleNetwork(
      performance: NetworkPerformance(isComplex: false),
    );
    expect(network2.performance.isComplex, isFalse);

    const network4 = ParticleNetwork(
      performance: NetworkPerformance(
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
    'ParticleNetwork didUpdateWidget updates simulation gravity using ParticleGravity',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                gravity: ParticleGravity.none(),
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
                gravity: ParticleGravity(
                  gravityType: GravityType.point,
                  gravityStrength: 0.9,
                  gravityDirection: Offset(0, -1),
                  gravityCenter: Offset(120, 120),
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
      gravity: ParticleGravity(gravityType: GravityType.global),
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

  test('ParticleNetwork detects usedLegacyTouchColor correctly', () {
    const modern = ParticleNetwork(
      touchFeatures: TouchFeatures(color: Colors.blue),
    );
    expect(modern.usedLegacyTouchColor, isFalse);
    expect(modern.touchColor, Colors.blue);

    const defaultWidget = ParticleNetwork();
    expect(defaultWidget.usedLegacyTouchColor, isFalse);
    expect(defaultWidget.touchColor, Colors.amber);

    const legacyWidget = ParticleNetwork(
      touchColor: Colors.purple,
    );
    expect(legacyWidget.usedLegacyTouchColor, isTrue);
    expect(legacyWidget.touchColor, Colors.purple);
  });

  test('TouchFeatures color property and copyWith', () {
    const defaultFeatures = TouchFeatures();
    expect(defaultFeatures.color, Colors.amber);
    expect(defaultFeatures.enabled, isTrue);
    expect(defaultFeatures.touchActivation, isTrue);

    const custom = TouchFeatures(color: Colors.teal, enabled: false);
    expect(custom.color, Colors.teal);
    expect(custom.enabled, isFalse);
    expect(custom.touchActivation, isFalse);

    final copied = custom.copyWith(color: Colors.deepOrange, enabled: true);
    expect(copied.color, Colors.deepOrange);
    expect(copied.enabled, isTrue);
    expect(copied.speed, custom.speed);
  });

  test('ParticleNetwork detects usedLegacyTouchActivation correctly', () {
    const modern = ParticleNetwork(
      touchFeatures: TouchFeatures(enabled: false),
    );
    expect(modern.usedLegacyTouchActivation, isFalse);
    expect(modern.touchActivation, isFalse);

    const defaultWidget = ParticleNetwork();
    expect(defaultWidget.usedLegacyTouchActivation, isFalse);
    expect(defaultWidget.touchActivation, isTrue);

    const legacyWidget = ParticleNetwork(
      touchActivation: false,
    );
    expect(legacyWidget.usedLegacyTouchActivation, isTrue);
    expect(legacyWidget.touchActivation, isFalse);
  });

  testWidgets(
    'GestureDetector onPanCancel updates touchPoint to Offset.infinite',
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

      final gestureDetector = tester.widget<GestureDetector>(
        find.descendant(
          of: find.byType(ParticleNetwork),
          matching: find.byType(GestureDetector),
        ),
      );
      gestureDetector.onPanCancel?.call();
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
                performance: NetworkPerformance(
                  maxConnectionsPerParticle: null,
                  lineRenderer: LineRenderer.stroke,
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
                performance: NetworkPerformance(
                  maxConnectionsPerParticle: 3,
                  lineRenderer: LineRenderer.vertices,
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
                performance: NetworkPerformance(
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
                performance: NetworkPerformance(
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
                performance: NetworkPerformance(
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
                performance: NetworkPerformance(
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
                performance: NetworkPerformance(
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
                performance: NetworkPerformance(
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
                performance: NetworkPerformance(
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
    'effectiveDrawNetwork and usedLegacyDrawnetwork reflect legacy and modern parameter (L105-L110)',
    () {
      // Modern parameter
      const modern = ParticleNetwork(drawNetwork: false);
      expect(modern.drawNetwork, isFalse);
      expect(modern.effectiveDrawNetwork, isFalse);
      expect(modern.usedLegacyDrawnetwork, isFalse);

      // Legacy parameter (drawnetwork)
      const legacy = ParticleNetwork(drawnetwork: false);
      expect(legacy.effectiveDrawNetwork, isFalse);
      expect(legacy.usedLegacyDrawnetwork, isTrue);
    },
  );

  test(
    'effectiveLineWidth and usedLegacyLinewidth reflect legacy and modern parameter (L114-L119)',
    () {
      // Modern parameter
      const modern = ParticleNetwork(lineWidth: 2.5);
      expect(modern.lineWidth, equals(2.5));
      expect(modern.effectiveLineWidth, equals(2.5));
      expect(modern.usedLegacyLinewidth, isFalse);

      // Legacy parameter (linewidth)
      const legacy = ParticleNetwork(linewidth: 3.0);
      expect(legacy.effectiveLineWidth, equals(3.0));
      expect(legacy.usedLegacyLinewidth, isTrue);
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
                performance: NetworkPerformance(
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
                performance: NetworkPerformance(
                  autoBoost: true,
                  maxConnectionsPerParticle: 10,
                  isComplex: true,
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
    'ParticleNetwork with NetworkPerformance.auto dynamically adapts connections and lines according to frame performance',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                lineDistance: 100.0,
                performance: NetworkPerformance.auto(),
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
      expect(painter.performance.isComplex, isFalse);
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
    'ParticleNetwork with NetworkPerformance.auto can scale connections beyond 15 on high performance',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                lineDistance: 100.0,
                performance: NetworkPerformance.auto(),
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
      expect(painter.performance.isComplex, isFalse);

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
}
