// ignore_for_file: deprecated_member_use
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/particles_network.dart';

class CustomTestFactory implements IParticleFactory {
  @override
  Particle createParticle(Size size) {
    return Particle(
      position: const Offset(12.3, 45.6),
      velocity: const Offset(1.0, 1.0),
      size: 2.0,
      color: const Color(0xFF123456),
    );
  }
}

class CustomTestController implements IParticleController {
  @override
  void updateParticles(
    List<Particle> particles,
    Size size, {
    ParticleGravity? gravity,
  }) {}
}

void main() {
  group('Phase 1 - Item 1: Deprecated linewidth and drawnetwork', () {
    testWidgets('linewidth and drawnetwork are honored at init',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                linewidth: 3.5,
                drawnetwork: false,
              ),
            ),
          ),
        ),
      );

      final state = tester.state<ParticleNetworkState>(
        find.byType(ParticleNetwork),
      );

      expect(state.painter.lineWidth, equals(3.5),
          reason: 'Legacy linewidth must be passed to painter at init');
      expect(state.painter.drawNetwork, isFalse,
          reason: 'Legacy drawnetwork must be passed to painter at init');
    });

    testWidgets('linewidth and drawnetwork are honored on widget update',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                lineWidth: 1.0,
                drawNetwork: true,
              ),
            ),
          ),
        ),
      );

      final state = tester.state<ParticleNetworkState>(
        find.byType(ParticleNetwork),
      );
      expect(state.painter.lineWidth, equals(1.0));
      expect(state.painter.drawNetwork, isTrue);

      // Update with legacy linewidth and drawnetwork
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                linewidth: 4.0,
                drawnetwork: false,
              ),
            ),
          ),
        ),
      );

      expect(state.painter.lineWidth, equals(4.0),
          reason: 'Legacy linewidth must update painter');
      expect(state.painter.drawNetwork, isFalse,
          reason: 'Legacy drawnetwork must update painter');
    });
  });

  group('Phase 1 - Item 2: Deprecated particleFactory and particleController',
      () {
    testWidgets('particleFactory and particleController are wired at init',
        (tester) async {
      final customFactory = CustomTestFactory();
      final customController = CustomTestController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                particleFactory: customFactory,
                particleController: customController,
              ),
            ),
          ),
        ),
      );

      final state = tester.state<ParticleNetworkState>(
        find.byType(ParticleNetwork),
      );

      expect(state.simulation.factory, same(customFactory),
          reason: 'custom particleFactory must be wired to simulation at init');
      expect(state.simulation.controller, same(customController),
          reason:
              'custom particleController must be wired to simulation at init');
    });

    testWidgets('particleFactory and particleController are wired on update',
        (tester) async {
      final initialFactory = CustomTestFactory();
      final initialController = CustomTestController();
      final updatedFactory = CustomTestFactory();
      final updatedController = CustomTestController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                particleFactory: initialFactory,
                particleController: initialController,
              ),
            ),
          ),
        ),
      );

      final state = tester.state<ParticleNetworkState>(
        find.byType(ParticleNetwork),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                particleFactory: updatedFactory,
                particleController: updatedController,
              ),
            ),
          ),
        ),
      );

      expect(state.simulation.factory, same(updatedFactory),
          reason: 'updated particleFactory must be passed on didUpdateWidget');
      expect(state.simulation.controller, same(updatedController),
          reason:
              'updated particleController must be passed on didUpdateWidget');
    });
  });

  group('Phase 1 - Item 3: Unified touch configuration', () {
    testWidgets('touch parameter configures painter touchFeatures cleanly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                touch: TouchFeatures(
                  color: Color(0xFF9C27B0), // Purple
                  enabled: false,
                ),
              ),
            ),
          ),
        ),
      );

      final state = tester.state<ParticleNetworkState>(
        find.byType(ParticleNetwork),
      );

      expect(state.painter.touchFeatures.color, const Color(0xFF9C27B0));
      expect(state.painter.touchFeatures.enabled, isFalse);
      expect(state.painter.touchActivation, isFalse);
    });

    testWidgets('touchFeatures alias configures painter touchFeatures cleanly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                touchFeatures: TouchFeatures(
                  color: Color(0xFF00BCD4), // Cyan
                  enabled: false,
                ),
              ),
            ),
          ),
        ),
      );

      final state = tester.state<ParticleNetworkState>(
        find.byType(ParticleNetwork),
      );

      expect(state.painter.touchFeatures.color, const Color(0xFF00BCD4));
      expect(state.painter.touchFeatures.enabled, isFalse);
    });

    testWidgets('changing touchFeatures at runtime updates painter',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                touchFeatures: TouchFeatures(
                  color: Color(0xFF2196F3), // Blue
                  enabled: true,
                ),
              ),
            ),
          ),
        ),
      );

      final state = tester.state<ParticleNetworkState>(
        find.byType(ParticleNetwork),
      );
      expect(state.painter.touchFeatures.color, const Color(0xFF2196F3));

      // Update touchFeatures to Amber/disabled
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                touchFeatures: TouchFeatures(
                  color: Color(0xFFFF9800), // Orange
                  enabled: false,
                ),
              ),
            ),
          ),
        ),
      );

      expect(state.painter.touchFeatures.color, const Color(0xFFFF9800));
      expect(state.painter.touchFeatures.enabled, isFalse);
    });
  });

  group('Phase 1 - Item 4: Unbounded constraints', () {
    testWidgets('renders inside Column without throwing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ParticleNetwork(),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull,
          reason: 'ParticleNetwork must not throw inside Column');
    });

    testWidgets('renders inside ListView without throwing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: const [
                ParticleNetwork(),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull,
          reason: 'ParticleNetwork must not throw inside ListView');
    });
  });

  group('Phase 1 - Item 5: CustomPaint isComplex hint', () {
    testWidgets('CustomPaint does not pass raster cache isComplex hint',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                performance: NetworkPerformance(isComplex: true),
              ),
            ),
          ),
        ),
      );

      final customPaintFinder = find.byType(CustomPaint);
      expect(customPaintFinder, findsWidgets);

      final customPaints =
          tester.widgetList<CustomPaint>(customPaintFinder).toList();
      final networkPaint = customPaints.firstWhere(
        (cp) => cp.painter is OptimizedNetworkPainter,
      );

      expect(networkPaint.isComplex, isFalse,
          reason: 'CustomPaint should not enable isComplex raster cache hint');
      expect(networkPaint.willChange, isTrue);
    });
  });

  group('Phase 1 - Item 6: Input handling with Listener and multi-touch', () {
    testWidgets('vertical drag in ListView scrolls while particle touch reacts',
        (tester) async {
      final scrollController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: ListView(
                controller: scrollController,
                children: const [
                  SizedBox(
                    height: 300,
                    child: ParticleNetwork(
                      touchFeatures: TouchFeatures(enabled: true),
                    ),
                  ),
                  SizedBox(
                    height: 600,
                    child: Text('Scroll Content'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final state = tester.state<ParticleNetworkState>(
        find.byType(ParticleNetwork),
      );

      // Drag vertically over the ParticleNetwork widget
      final center = tester.getCenter(find.byType(ParticleNetwork));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(0, -100));
      await tester.pump();

      expect(state.touchPoint, isNot(equals(Offset.infinite)),
          reason: 'Touch point should track pointer during drag');
      expect(scrollController.offset, greaterThan(0),
          reason:
              'ListView must be able to scroll despite drag over ParticleNetwork');

      await gesture.up();
      await tester.pump();
      expect(state.touchPoint, equals(Offset.infinite));
    });

    testWidgets(
        'multi-touch: lifting second pointer does not clear active touch',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: ParticleNetwork(),
            ),
          ),
        ),
      );

      final state = tester.state<ParticleNetworkState>(
        find.byType(ParticleNetwork),
      );

      final pointer1 =
          await tester.startGesture(const Offset(100, 100), pointer: 1);
      await tester.pump();
      expect(state.touchPoint, equals(const Offset(100, 100)));

      // Second pointer touches down
      final pointer2 =
          await tester.startGesture(const Offset(200, 200), pointer: 2);
      await tester.pump();
      expect(state.touchPoint, equals(const Offset(100, 100)),
          reason: 'Active pointer 1 should retain primary tracking');

      // Second pointer lifts up
      await pointer2.up();
      await tester.pump();
      expect(state.touchPoint, equals(const Offset(100, 100)),
          reason:
              'Lifting pointer 2 must not reset touchPoint while pointer 1 is still down');

      // Primary pointer lifts up
      await pointer1.up();
      await tester.pump();
      expect(state.touchPoint, equals(Offset.infinite));
    });

    testWidgets('hover updates touchPoint when hoverEffect is true',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: ParticleNetwork(
                hoverEffect: true,
              ),
            ),
          ),
        ),
      );

      final state = tester.state<ParticleNetworkState>(
        find.byType(ParticleNetwork),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: const Offset(50, 50));
      await tester.pump();

      expect(state.touchPoint, equals(const Offset(50, 50)));

      await gesture.moveTo(const Offset(150, 150));
      await tester.pump();
      expect(state.touchPoint, equals(const Offset(150, 150)));

      await gesture.removePointer();
      await tester.pump();
    });
  });

  group(
      'Phase 1 - Item 8: ParticleGravity, TouchFeatures, NetworkPerformance == and hashCode',
      () {
    test('ParticleGravity equality and hashCode', () {
      const g1 = ParticleGravity(
        type: GravityType.global,
        strength: 0.5,
        direction: Offset(0, 1),
        center: Offset(10, 10),
      );
      const g2 = ParticleGravity(
        type: GravityType.global,
        strength: 0.5,
        direction: Offset(0, 1),
        center: Offset(10, 10),
      );
      const g3 = ParticleGravity(
        type: GravityType.point,
        strength: 0.5,
        direction: Offset(0, 1),
        center: Offset(10, 10),
      );

      expect(g1, equals(g2));
      expect(g1.hashCode, equals(g2.hashCode));
      expect(g1, isNot(equals(g3)));
    });

    test('TouchFeatures equality and hashCode', () {
      const t1 = TouchFeatures(
        enabled: true,
        speed: 0.5,
        force: 0.3,
        maxTouchSpeed: 6.0,
        damping: 0.99,
        lineDistance: 80.0,
        color: Color(0xFF00FF00),
      );
      const t2 = TouchFeatures(
        enabled: true,
        speed: 0.5,
        force: 0.3,
        maxTouchSpeed: 6.0,
        damping: 0.99,
        lineDistance: 80.0,
        color: Color(0xFF00FF00),
      );
      const t3 = TouchFeatures(
        enabled: false,
        speed: 0.5,
        force: 0.3,
        maxTouchSpeed: 6.0,
        damping: 0.99,
        lineDistance: 80.0,
        color: Color(0xFF00FF00),
      );

      expect(t1, equals(t2));
      expect(t1.hashCode, equals(t2.hashCode));
      expect(t1, isNot(equals(t3)));
    });

    test('NetworkPerformance equality and hashCode', () {
      const p1 = NetworkPerformance(
        maxConnectionsPerParticle: 5,
        maxLinesPerFrame: 100,
        isComplex: true,
      );
      const p2 = NetworkPerformance(
        maxConnectionsPerParticle: 5,
        maxLinesPerFrame: 100,
        isComplex: true,
      );
      const p3 = NetworkPerformance(
        maxConnectionsPerParticle: 10,
        maxLinesPerFrame: 100,
        isComplex: true,
      );

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1, isNot(equals(p3)));
    });
  });

  group('Phase 1 - Item 9: Zero dependencies beyond Flutter SDK', () {
    test('lib/ contains no imports of package:material_ui', () {
      final libDir = Directory('lib');
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        expect(
          content.contains('package:material_ui/'),
          isFalse,
          reason:
              '${file.path} should not import package:material_ui (must use Flutter SDK widgets.dart/material.dart)',
        );
      }
    });
  });
}
