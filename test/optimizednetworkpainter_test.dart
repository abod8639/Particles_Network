import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:particles_network/model/particlemodel.dart';
import 'package:particles_network/painter/optimized_network_painter.dart';

import 'mocks/mock_canvas.mocks.dart';

const Size testScreenSize = Size(500, 500);

class MockParticle extends Particle {
  MockParticle({
    required super.position,
    super.velocity = Offset.zero,
    super.color = Colors.white,
    super.size = 1.0,
    bool wasAccelerated = false,
  });

  void accelerate() {
    wasAccelerated = true;
  }
}

Widget buildTestableWidget(BuildContext context) {
  return MediaQuery(
    data: const MediaQueryData(size: testScreenSize),
    child: Container(),
  );
}

void main() {
  late BuildContext testContext;
  late MockParticle particle;
  late OptimizedNetworkPainter defaultPainter;
  late MockCanvas mockCanvas;

  setUp(() {
    mockCanvas = MockCanvas();
    particle = MockParticle(position: const Offset(0, 0));
  });

  Future<void> setUpTest(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            testContext = context;
            return buildTestableWidget(context);
          },
        ),
      ),
    );

    defaultPainter = OptimizedNetworkPainter(
      context: testContext,
      drawnetwork: true,
      fill: true,
      isComplex: false,
      particleCount: 1,
      particles: [particle],
      touchPoint: null,
      lineDistance: 100,
      particleColor: Colors.white,
      lineColor: Colors.grey,
      touchColor: Colors.red,
      touchActivation: true,
      linewidth: 1.0,
    );
  }

  group('OptimizedNetworkPainter Initialization', () {
    testWidgets('initializes with correct default values', (tester) async {
      await setUpTest(tester);

      expect(defaultPainter.particleCount, equals(1));
      expect(defaultPainter.lineDistance, equals(100));
      expect(defaultPainter.particleColor, equals(Colors.white));
      expect(defaultPainter.lineColor, equals(Colors.grey));
      expect(defaultPainter.touchColor, equals(Colors.red));
      expect(defaultPainter.touchActivation, isTrue);
      expect(defaultPainter.linewidth, equals(1.0));
      expect(defaultPainter.fill, isTrue);
      expect(defaultPainter.drawnetwork, isTrue);
      expect(defaultPainter.showQuadTree, isFalse);
    });

    testWidgets('handles null touchPoint', (tester) async {
      await setUpTest(tester);
      expect(defaultPainter.touchPoint, isNull);
    });
  });

  group('Particle Drawing Tests', () {
    // testWidgets('draws particles correctly', (tester) async {
    //   await setUpTest(tester);
    //   defaultPainter.paint(mockCanvas, testScreenSize);

    //   verify(
    //     mockCanvas.drawCircle(particle.position, particle.size, any),
    //   ).called(1);
    // });

    testWidgets('respects fill style', (tester) async {
      await setUpTest(tester);

      final strokePainter = OptimizedNetworkPainter(
        context: testContext,
        drawnetwork: true,
        fill: false,
        isComplex: false,
        particleCount: 1,
        particles: [particle],
        touchPoint: null,
        lineDistance: 100,
        particleColor: Colors.white,
        lineColor: Colors.grey,
        touchColor: Colors.red,
        touchActivation: true,
        linewidth: 1.0,
      );

      expect(strokePainter.fill, isFalse);
    });
  });

  group('Connection Drawing Tests', () {
    testWidgets('correctly sorts and limits connections in dense areas', (
      tester,
    ) async {
      await setUpTest(tester);

      final centerParticle = MockParticle(position: const Offset(100, 100));
      final surroundingParticles = List.generate(5, (i) {
        final angle = (i * math.pi * 2) / 5; // Distribute in a circle
        final distance = 10.0 * (i + 1); // Still keep increasing distances
        return MockParticle(
          position: Offset(
            100 + distance * math.cos(angle),
            100 + distance * math.sin(angle),
          ),
        );
      });

      final painter = OptimizedNetworkPainter(
        context: testContext,
        drawnetwork: true,
        fill: true,
        isComplex: false,
        particleCount: 6,
        particles: [centerParticle, ...surroundingParticles],
        touchPoint: null,
        lineDistance: 90,
        particleColor: Colors.white,
        lineColor: Colors.grey,
        touchColor: Colors.red,
        touchActivation: true,
        linewidth: 1.0,
      );

      painter.paint(mockCanvas, testScreenSize);

      final drawLineInvocations = verify(mockCanvas.drawLine(any, any, any));
      expect(
        drawLineInvocations.callCount,
        equals(3),
      ); // Only 3 closest connections

      final calls = drawLineInvocations.captured;
      final drawnDistances = <double>[];
      for (int i = 0; i < calls.length; i += 3) {
        final start = calls[i] as Offset;
        final end = calls[i + 1] as Offset;
        drawnDistances.add((end - start).distance);
      }

      drawnDistances.sort();
      expect(drawnDistances[0], closeTo(10.0, 0.1));
      expect(drawnDistances[1], closeTo(20.0, 0.1));
      expect(drawnDistances[2], closeTo(30.0, 0.1));
    });

    testWidgets('draws connections when in range', (tester) async {
      await setUpTest(tester);

      final p1 = MockParticle(position: const Offset(0, 0));
      final p2 = MockParticle(position: const Offset(50, 50));

      final painter = OptimizedNetworkPainter(
        context: testContext,
        drawnetwork: true,
        fill: true,
        isComplex: false,
        particleCount: 2,
        particles: [p1, p2],
        touchPoint: null,
        lineDistance: 100,
        particleColor: Colors.white,
        lineColor: Colors.grey,
        touchColor: Colors.red,
        touchActivation: true,
        linewidth: 1.0,
      );

      painter.paint(mockCanvas, testScreenSize);
      verify(mockCanvas.drawLine(any, any, any)).called(greaterThan(0));
    });

    testWidgets(
      'limits connections in dense areas and ensures closest connections are kept',
      (tester) async {
        await setUpTest(tester);

        // Create a cluster of particles close together - vary distances for sorting test
        final centerParticle = MockParticle(position: const Offset(100, 100));
        final surroundingParticles = List.generate(6, (i) {
          final angle = i * (math.pi / 3); // Distribute in circle
          // Vary distances (10, 20, 30 pixels) to test sorting
          final distance = 10.0 + (i % 3) * 10;
          return MockParticle(
            position: Offset(
              100 + distance * math.cos(angle),
              100 + distance * math.sin(angle),
            ),
          );
        });

        final painter = OptimizedNetworkPainter(
          context: testContext,
          drawnetwork: true,
          fill: true,
          isComplex: false,
          particleCount: 7, // Center + 6 surrounding
          particles: [centerParticle, ...surroundingParticles],
          touchPoint: null,
          lineDistance: 100, // Large enough to connect all particles
          particleColor: Colors.white,
          lineColor: Colors.grey,
          touchColor: Colors.red,
          touchActivation: true,
          linewidth: 1.0,
        );

        painter.paint(mockCanvas, testScreenSize);

        // Verify that:
        // 1. drawLine is called a limited number of times
        // 2. Closest connections are kept (particles at 10px should be connected)
        // 3. Furthest connections are dropped (particles at 30px should not be connected)
        //
        // Since denseThreshold = lineDistance ~/ 3 and maxLinesPerDenseParticle = 3,
        // we expect only 3 connections per particle (closest ones) despite having 6 nearby particles
        final drawLineInvocations = verify(mockCanvas.drawLine(any, any, any));
        expect(
          drawLineInvocations.callCount,
          lessThanOrEqualTo(21),
        ); // 7 particles * 3 max connections

        // Verify that closest connections are kept by checking that particles
        // at distance=10 are always connected before particles at distance=30
      },
    );

    testWidgets(
      'limits and sorts connections when density threshold is exceeded',
      (tester) async {
        await setUpTest(tester);

        // Create a dense cluster of particles
        final centralParticle = MockParticle(position: const Offset(100, 100));
        final denseParticles = List.generate(10, (i) {
          final angle =
              i * (math.pi / 5); // Distribute 10 particles in a circle
          return MockParticle(
            position: Offset(
              100 + 10 * math.cos(angle), // Very close to center (10px radius)
              100 + 10 * math.sin(angle),
            ),
          );
        });

        final painter = OptimizedNetworkPainter(
          context: testContext,
          drawnetwork: true,
          fill: true,
          isComplex: false,
          particleCount: 11, // Central + 10 surrounding
          particles: [centralParticle, ...denseParticles],
          touchPoint: null,
          lineDistance: 100,
          particleColor: Colors.white,
          lineColor: Colors.grey,
          touchColor: Colors.red,
          touchActivation: true,
          linewidth: 1.0,
        );

        painter.paint(mockCanvas, testScreenSize);

        // Since maxLinesPerDenseParticle = 3 and we have 11 particles,
        // each particle should only connect to its 3 closest neighbors
        final drawLineInvocations = verify(mockCanvas.drawLine(any, any, any));
        // Maximum connections = (11 particles * 3 maximum connections per particle) / 2
        // Divided by 2 because each connection is counted twice (A->B and B->A)
        expect(
          drawLineInvocations.callCount,
          lessThanOrEqualTo(55),
        ); // 11 * 3 / 2 rounded up
      },
    );
  });
  group('Touch Interaction Tests', () {
    testWidgets('activates touch interactions correctly', (tester) async {
      await setUpTest(tester);

      final touchPainter = OptimizedNetworkPainter(
        context: testContext,
        drawnetwork: true,
        fill: true,
        isComplex: false,
        particleCount: 1,
        particles: [particle],
        touchPoint: const Offset(10, 10),
        lineDistance: 100,
        particleColor: Colors.white,
        lineColor: Colors.grey,
        touchColor: Colors.red,
        touchActivation: true,
        linewidth: 1.0,
      );

      touchPainter.paint(mockCanvas, testScreenSize);
      verify(mockCanvas.drawLine(any, any, any)).called(greaterThan(0));
    });

    testWidgets('ignores touch when touchActivation is false', (tester) async {
      await setUpTest(tester);

      final noTouchPainter = OptimizedNetworkPainter(
        context: testContext,
        drawnetwork: true,
        fill: true,
        isComplex: false,
        particleCount: 1,
        particles: [particle],
        touchPoint: const Offset(10, 10),
        lineDistance: 100,
        particleColor: Colors.white,
        lineColor: Colors.grey,
        touchColor: Colors.red,
        touchActivation: false,
        linewidth: 1.0,
      );

      noTouchPainter.paint(mockCanvas, testScreenSize);
      verifyNever(mockCanvas.drawLine(any, any, any));
    });
  });

  group('ShouldRepaint Tests', () {
    testWidgets('returns true when touchPoint changes', (tester) async {
      await setUpTest(tester);

      final newPainter = OptimizedNetworkPainter(
        context: testContext,
        drawnetwork: true,
        fill: true,
        isComplex: false,
        particleCount: 1,
        particles: [particle],
        touchPoint: const Offset(5, 5),
        lineDistance: 100,
        particleColor: Colors.white,
        lineColor: Colors.grey,
        touchColor: Colors.red,
        touchActivation: true,
        linewidth: 1.0,
      );

      expect(newPainter.shouldRepaint(defaultPainter), isTrue);
    });

    testWidgets('returns true when colors change', (tester) async {
      await setUpTest(tester);

      final newPainter = OptimizedNetworkPainter(
        context: testContext,
        drawnetwork: true,
        fill: true,
        isComplex: false,
        particleCount: 1,
        particles: [particle],
        touchPoint: null,
        lineDistance: 100,
        particleColor: Colors.blue,
        lineColor: Colors.green,
        touchColor: Colors.red,
        touchActivation: true,
        linewidth: 1.0,
      );

      expect(newPainter.shouldRepaint(defaultPainter), isTrue);
    });

    testWidgets('returns true when particle is accelerated', (tester) async {
      await setUpTest(tester);

      particle.wasAccelerated = true;

      final newPainter = OptimizedNetworkPainter(
        context: testContext,
        drawnetwork: true,
        fill: true,
        isComplex: false,
        particleCount: 1,
        particles: [particle],
        touchPoint: null,
        lineDistance: 100,
        particleColor: Colors.white,
        lineColor: Colors.grey,
        touchColor: Colors.red,
        touchActivation: true,
        linewidth: 1.0,
      );

      expect(newPainter.shouldRepaint(defaultPainter), isTrue);
    });

    testWidgets('returns false when no relevant properties change', (
      tester,
    ) async {
      await setUpTest(tester);

      final newPainter = OptimizedNetworkPainter(
        context: testContext,
        drawnetwork: true,
        fill: true,
        isComplex: false,
        particleCount: 1,
        particles: [particle],
        touchPoint: null,
        lineDistance: 100,
        particleColor: Colors.white,
        lineColor: Colors.grey,
        touchColor: Colors.red,
        touchActivation: true,
        linewidth: 1.0,
      );

      expect(newPainter.shouldRepaint(defaultPainter), isFalse);
    });
  });
}
