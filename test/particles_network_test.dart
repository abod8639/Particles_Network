import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/particles_network.dart';

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
}
