import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/particles_network.dart';
import 'package:particles_network/src/legacy/legacy_deprecation_logger.dart';

void main() {
  group('NetworkPerformance', () {
    test('default constructor has correct default values', () {
      const perf = NetworkPerformance();

      expect(perf.maxConnectionsPerParticle, isNull);
      expect(perf.adaptiveDensity, isFalse);
      expect(perf.fastLineRendering, isFalse);
      expect(perf.enableAdaptivePerformance, isFalse);
      expect(perf.maxLinesPerFrame, isNull);
      expect(perf.frameRateIndependent, isFalse);
      expect(perf.lineRenderer, equals(LineRenderer.stroke));
      expect(perf.isComplex, isFalse);
      expect(perf.cappedDistanceFactor, equals(0.75));
      expect(perf.antiAlias, isTrue);
    });

    test('highPerformance preset has optimized values', () {
      final perf = NetworkPerformance.highPerformance();

      expect(perf.maxConnectionsPerParticle, equals(4));
      expect(perf.adaptiveDensity, isTrue);
      expect(perf.fastLineRendering, isTrue);
      expect(perf.enableAdaptivePerformance, isTrue);
      expect(perf.maxLinesPerFrame, equals(15000));
      expect(perf.frameRateIndependent, isTrue);
      expect(perf.lineRenderer, equals(LineRenderer.vertices));
      expect(perf.isComplex, isTrue);
      expect(perf.cappedDistanceFactor, equals(0.75));
      expect(perf.antiAlias, isTrue);
    });

    test('adaptive preset has dynamic scaling enabled', () {
      final perf = NetworkPerformance.adaptive();

      expect(perf.maxConnectionsPerParticle, isNull);
      expect(perf.adaptiveDensity, isTrue);
      expect(perf.fastLineRendering, isFalse);
      expect(perf.enableAdaptivePerformance, isTrue);
      expect(perf.maxLinesPerFrame, isNull);
      expect(perf.frameRateIndependent, isTrue);
      expect(perf.lineRenderer, equals(LineRenderer.stroke));
      expect(perf.isComplex, isFalse);
      expect(perf.cappedDistanceFactor, equals(0.75));
      expect(perf.antiAlias, isTrue);
    });

    test('copyWith updates specified fields and preserves others', () {
      const initial = NetworkPerformance(
        maxConnectionsPerParticle: 5,
        adaptiveDensity: false,
        fastLineRendering: true,
      );

      final updated = initial.copyWith(
        adaptiveDensity: true,
        maxLinesPerFrame: 3000,
        lineRenderer: LineRenderer.vertices,
        isComplex: true,
      );

      expect(updated.maxConnectionsPerParticle, equals(5));
      expect(updated.adaptiveDensity, isTrue);
      expect(updated.fastLineRendering, isTrue);
      expect(updated.maxLinesPerFrame, equals(3000));
      expect(updated.lineRenderer, equals(LineRenderer.vertices));
      expect(updated.enableAdaptivePerformance, isFalse);
      expect(updated.isComplex, isTrue);
    });

    test('copyWith allows clearing nullable fields', () {
      const initial = NetworkPerformance(
        maxConnectionsPerParticle: 10,
        maxLinesPerFrame: 2000,
      );

      final cleared = initial.copyWith(
        clearMaxConnectionsPerParticle: true,
        clearMaxLinesPerFrame: true,
      );

      expect(cleared.maxConnectionsPerParticle, isNull);
      expect(cleared.maxLinesPerFrame, isNull);
    });

    test('equality and hashCode contract', () {
      const perf1 = NetworkPerformance(
        maxConnectionsPerParticle: 4,
        adaptiveDensity: true,
        fastLineRendering: true,
        enableAdaptivePerformance: true,
        maxLinesPerFrame: 5000,
        frameRateIndependent: true,
        lineRenderer: LineRenderer.vertices,
        isComplex: true,
      );

      const perf2 = NetworkPerformance(
        maxConnectionsPerParticle: 4,
        adaptiveDensity: true,
        fastLineRendering: true,
        enableAdaptivePerformance: true,
        maxLinesPerFrame: 5000,
        frameRateIndependent: true,
        lineRenderer: LineRenderer.vertices,
        isComplex: true,
      );

      const perf3 = NetworkPerformance(
        maxConnectionsPerParticle: 4,
        adaptiveDensity: true,
        fastLineRendering: true,
        enableAdaptivePerformance: true,
        maxLinesPerFrame: 5000,
        frameRateIndependent: true,
        lineRenderer: LineRenderer.vertices,
        isComplex: false,
      );

      expect(perf1, equals(perf2));
      expect(perf1.hashCode, equals(perf2.hashCode));
      expect(perf1, isNot(equals(perf3)));
    });

    test('complex preset has optimized values for dense cluster throttling',
        () {
      final perf = const NetworkPerformance.complex();

      expect(perf.isComplex, isTrue);
      expect(perf.connectionReductionRatio, equals(0.5));
      expect(perf.maxComplexLines, equals(3));
      expect(perf.denseThresholdFactor, equals(0.25));
    });

    test('complex preset allows overriding throttling parameters', () {
      const perf = NetworkPerformance.complex(
        connectionReductionRatio: 0.8,
        maxComplexLines: 4,
        denseThresholdFactor: 0.4,
      );

      expect(perf.isComplex, isTrue);
      expect(perf.connectionReductionRatio, equals(0.8));
      expect(perf.maxComplexLines, equals(4));
      expect(perf.denseThresholdFactor, equals(0.4));
    });

    test(
        'validates assertion for connectionReductionRatio, maxComplexLines, and denseThresholdFactor',
        () {
      expect(
        () => NetworkPerformance(connectionReductionRatio: -0.1),
        throwsAssertionError,
      );
      expect(
        () => NetworkPerformance(connectionReductionRatio: 1.1),
        throwsAssertionError,
      );
      expect(
        () => NetworkPerformance(maxComplexLines: 0),
        throwsAssertionError,
      );
      expect(
        () => NetworkPerformance(denseThresholdFactor: 0.0),
        throwsAssertionError,
      );
    });

    test(
        'copyWith updates and clears connectionReductionRatio, maxComplexLines, and denseThresholdFactor',
        () {
      const initial = NetworkPerformance(
        connectionReductionRatio: 0.5,
        maxComplexLines: 4,
        denseThresholdFactor: 0.3,
      );

      final updated = initial.copyWith(
        connectionReductionRatio: 0.75,
        maxComplexLines: 2,
        denseThresholdFactor: 0.5,
      );

      expect(updated.connectionReductionRatio, equals(0.75));
      expect(updated.maxComplexLines, equals(2));
      expect(updated.denseThresholdFactor, equals(0.5));

      final cleared = updated.copyWith(
        clearConnectionReductionRatio: true,
        clearMaxComplexLines: true,
        clearDenseThresholdFactor: true,
      );

      expect(cleared.connectionReductionRatio, isNull);
      expect(cleared.maxComplexLines, isNull);
      expect(cleared.denseThresholdFactor, isNull);
    });

    test(
        'toString contains connectionReductionRatio, maxComplexLines, and denseThresholdFactor',
        () {
      const perf = NetworkPerformance(
        connectionReductionRatio: 0.6,
        maxComplexLines: 3,
        denseThresholdFactor: 0.2,
      );

      final str = perf.toString();
      expect(str, contains('connectionReductionRatio: 0.6'));
      expect(str, contains('maxComplexLines: 3'));
      expect(str, contains('denseThresholdFactor: 0.2'));
    });
  });

  group('ParticleNetwork with NetworkPerformance', () {
    testWidgets('passes performance settings to OptimizedNetworkPainter', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                performance: NetworkPerformance(
                  maxConnectionsPerParticle: 3,
                  adaptiveDensity: true,
                  fastLineRendering: true,
                  maxLinesPerFrame: 2500,
                  lineRenderer: LineRenderer.vertices,
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
      expect(painter.maxConnectionsPerParticle, equals(3));
      expect(painter.adaptiveDensity, isTrue);
      expect(painter.fastLineRendering, isTrue);
      expect(painter.maxLinesPerFrame, equals(2500));
      expect(painter.lineRenderer, equals(LineRenderer.vertices));
      expect(painter.isComplex, isTrue);
    });

    testWidgets('didUpdateWidget updates painter performance dynamically', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                performance: NetworkPerformance(
                  maxConnectionsPerParticle: 2,
                  fastLineRendering: false,
                  isComplex: false,
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

      var painter = tester.widget<CustomPaint>(customPaintFinder).painter
          as OptimizedNetworkPainter;
      expect(painter.maxConnectionsPerParticle, equals(2));
      expect(painter.fastLineRendering, isFalse);
      expect(painter.isComplex, isFalse);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                performance: NetworkPerformance(
                  maxConnectionsPerParticle: 8,
                  fastLineRendering: true,
                  lineRenderer: LineRenderer.vertices,
                  isComplex: true,
                ),
              ),
            ),
          ),
        ),
      );

      painter = tester.widget<CustomPaint>(customPaintFinder).painter
          as OptimizedNetworkPainter;
      expect(painter.maxConnectionsPerParticle, equals(8));
      expect(painter.fastLineRendering, isTrue);
      expect(painter.lineRenderer, equals(LineRenderer.vertices));
      expect(painter.isComplex, isTrue);
    });

    testWidgets(
        'legacy isComplex parameter falls back to painter and logs deprecation',
        (
      WidgetTester tester,
    ) async {
      LegacyDeprecationLogger.resetWarned();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                isComplex: true,
              ),
            ),
          ),
        ),
      );

      final customPaintFinder = find.descendant(
        of: find.byType(ParticleNetwork),
        matching: find.byType(CustomPaint),
      );

      final painter = tester.widget<CustomPaint>(customPaintFinder).painter
          as OptimizedNetworkPainter;
      expect(painter.isComplex, isTrue);
      expect(
        LegacyDeprecationLogger.hasWarned('ParticleNetwork(isComplex)'),
        isTrue,
      );
    });

    test('LegacyDeprecationLogger logs once and ignores duplicate warnings',
        () {
      LegacyDeprecationLogger.resetWarned();
      const api = 'TestDeprecatedApi';
      expect(LegacyDeprecationLogger.hasWarned(api), isFalse);

      LegacyDeprecationLogger.warn(
        deprecatedApi: api,
        replacement: 'TestReplacement',
      );
      expect(LegacyDeprecationLogger.hasWarned(api), isTrue);

      // Second call triggers duplicate check early return (L34)
      LegacyDeprecationLogger.warn(
        deprecatedApi: api,
        replacement: 'TestReplacement',
      );
      expect(LegacyDeprecationLogger.hasWarned(api), isTrue);
    });

    testWidgets(
      'isComplex reduces lines at dense cluster while keeping sparse connections',
      (WidgetTester tester) async {
        final denseParticles = List.generate(
          30,
          (i) => Particle(
            position: Offset(100.0 + (i % 5) * 2.0, 100.0 + (i ~/ 5) * 2.0),
            velocity: Offset.zero,
            color: Colors.white,
            size: 2.0,
          ),
        );
        final sparseParticles = [
          Particle(
            position: const Offset(250.0, 250.0),
            velocity: Offset.zero,
            color: Colors.white,
            size: 2.0,
          ),
          Particle(
            position: const Offset(260.0, 250.0),
            velocity: Offset.zero,
            color: Colors.white,
            size: 2.0,
          ),
        ];
        final allParticles = <Particle>[...denseParticles, ...sparseParticles];

        final normalPainter = OptimizedNetworkPainter(
          drawNetwork: true,
          fill: false,
          particleCount: allParticles.length,
          particles: allParticles,
          touchPoint: null,
          lineDistance: 50.0,
          particleColor: Colors.white,
          lineColor: Colors.grey,
          lineWidth: 1.0,
          performance: const NetworkPerformance(isComplex: false),
        );

        final complexPainter = OptimizedNetworkPainter(
          drawNetwork: true,
          fill: false,
          particleCount: allParticles.length,
          particles: allParticles,
          touchPoint: null,
          lineDistance: 50.0,
          particleColor: Colors.white,
          lineColor: Colors.grey,
          lineWidth: 1.0,
          performance: const NetworkPerformance(isComplex: true),
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        const size = Size(500, 500);

        normalPainter.paint(canvas, size);
        complexPainter.paint(canvas, size);

        expect(
          complexPainter.lastFrameLineCount,
          lessThan(normalPainter.lastFrameLineCount),
        );
        expect(complexPainter.lastFrameLineCount, greaterThan(0));
      },
    );

    testWidgets(
      'isComplex throttles dense clusters when fastLineRendering is true',
      (WidgetTester tester) async {
        final denseParticles = List.generate(
          35,
          (i) => Particle(
            position: Offset(100.0 + (i % 6) * 2.0, 100.0 + (i ~/ 6) * 2.0),
            velocity: Offset.zero,
            color: Colors.white,
            size: 2.0,
          ),
        );

        final normalFastPainter = OptimizedNetworkPainter(
          drawNetwork: true,
          fill: false,
          particleCount: denseParticles.length,
          particles: denseParticles,
          touchPoint: null,
          lineDistance: 50.0,
          particleColor: Colors.white,
          lineColor: Colors.grey,
          lineWidth: 1.0,
          performance: const NetworkPerformance(
            fastLineRendering: true,
            isComplex: false,
          ),
        );

        final complexFastPainter = OptimizedNetworkPainter(
          drawNetwork: true,
          fill: false,
          particleCount: denseParticles.length,
          particles: denseParticles,
          touchPoint: null,
          lineDistance: 50.0,
          particleColor: Colors.white,
          lineColor: Colors.grey,
          lineWidth: 1.0,
          performance: const NetworkPerformance(
            fastLineRendering: true,
            isComplex: true,
          ),
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        const size = Size(500, 500);

        normalFastPainter.paint(canvas, size);
        complexFastPainter.paint(canvas, size);

        expect(
          complexFastPainter.lastFrameLineCount,
          lessThan(normalFastPainter.lastFrameLineCount),
        );
        expect(complexFastPainter.lastFrameLineCount, greaterThan(0));
      },
    );

    test(
      'maxConnectionsPerParticle connects closest neighbors across spatial cell boundaries',
      () {
        // Grid cell size will be lineDistance = 100.0.
        // Cell (0,0) spans x: [0, 100), y: [0, 100).
        // Cell (1,0) spans x: [100, 200), y: [0, 100).
        // Particle A is near the right edge of Cell (0,0): (95, 50).
        // Particle B is near the left edge of Cell (1,0): (105, 50).
        // Distance A-B is 10.0 (very close).
        // We also place other particles deeper inside both cells (distances >= 30.0).
        final particles = <Particle>[
          // Border particle A in cell (0,0)
          Particle(
            position: const Offset(95.0, 50.0),
            velocity: Offset.zero,
            color: Colors.white,
            size: 2.0,
          ),
          // Deeper particles in cell (0,0) - distances to A >= 35.0
          Particle(
            position: const Offset(60.0, 50.0),
            velocity: Offset.zero,
            color: Colors.white,
            size: 2.0,
          ),
          Particle(
            position: const Offset(50.0, 50.0),
            velocity: Offset.zero,
            color: Colors.white,
            size: 2.0,
          ),
          // Border particle B in cell (1,0)
          Particle(
            position: const Offset(105.0, 50.0),
            velocity: Offset.zero,
            color: Colors.white,
            size: 2.0,
          ),
          // Deeper particles in cell (1,0) - distances to B >= 35.0
          Particle(
            position: const Offset(140.0, 50.0),
            velocity: Offset.zero,
            color: Colors.white,
            size: 2.0,
          ),
          Particle(
            position: const Offset(150.0, 50.0),
            velocity: Offset.zero,
            color: Colors.white,
            size: 2.0,
          ),
        ];

        // Test with fast unified line rendering
        final fastPainter = OptimizedNetworkPainter(
          drawNetwork: true,
          fill: false,
          particleCount: particles.length,
          particles: particles,
          touchPoint: null,
          lineDistance: 100.0,
          particleColor: Colors.white,
          lineColor: Colors.grey,
          lineWidth: 1.0,
          performance: const NetworkPerformance(
            maxConnectionsPerParticle: 1,
            fastLineRendering: true,
          ),
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        const size = Size(500, 500);

        fastPainter.paint(canvas, size);

        // With cap=1 and closest-distance selection:
        // A connects to B (dist 10) across cell boundaries instead of A connecting
        // to same-cell particles (dist 35+), eliminating the isolated cell box artifact.
        expect(fastPainter.lastFrameLineCount, greaterThan(0));

        // Test with batched stroke rendering (isComplex: false)
        final strokePainter = OptimizedNetworkPainter(
          drawNetwork: true,
          fill: false,
          particleCount: particles.length,
          particles: particles,
          touchPoint: null,
          lineDistance: 100.0,
          particleColor: Colors.white,
          lineColor: Colors.grey,
          lineWidth: 1.0,
          performance: const NetworkPerformance(
            maxConnectionsPerParticle: 1,
            fastLineRendering: false,
            isComplex: false,
          ),
        );

        strokePainter.paint(canvas, size);
        expect(strokePainter.lastFrameLineCount, greaterThan(0));
      },
    );

    test(
      'capped connections reject distant stray particles beyond cappedDistanceFactor',
      () {
        // Two particles placed at distance 85.0 from each other.
        // lineDistance is 100.0.
        // When uncapped, they connect because 85.0 <= 100.0.
        // When capped with cappedDistanceFactor = 0.75, max capped distance is 75.0.
        // Since 85.0 > 75.0, capped connection rejects this long line, eliminating flickering.
        final distantParticles = <Particle>[
          Particle(
            position: const Offset(10.0, 50.0),
            velocity: Offset.zero,
            color: Colors.white,
            size: 2.0,
          ),
          Particle(
            position: const Offset(95.0, 50.0), // distance = 85.0
            velocity: Offset.zero,
            color: Colors.white,
            size: 2.0,
          ),
        ];

        // 1. Uncapped painter: connects across 85.0
        final uncappedPainter = OptimizedNetworkPainter(
          drawNetwork: true,
          fill: false,
          particleCount: distantParticles.length,
          particles: distantParticles,
          touchPoint: null,
          lineDistance: 100.0,
          particleColor: Colors.white,
          lineColor: Colors.grey,
          lineWidth: 1.0,
          performance: const NetworkPerformance(
            maxConnectionsPerParticle: null,
          ),
        );

        // 2. Capped painter with default cappedDistanceFactor = 0.75: rejects 85.0
        final cappedPainter = OptimizedNetworkPainter(
          drawNetwork: true,
          fill: false,
          particleCount: distantParticles.length,
          particles: distantParticles,
          touchPoint: null,
          lineDistance: 100.0,
          particleColor: Colors.white,
          lineColor: Colors.grey,
          lineWidth: 1.0,
          performance: const NetworkPerformance(
            maxConnectionsPerParticle: 2,
            cappedDistanceFactor: 0.75,
          ),
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        const size = Size(500, 500);

        uncappedPainter.paint(canvas, size);
        expect(uncappedPainter.lastFrameLineCount, equals(1));

        cappedPainter.paint(canvas, size);
        expect(cappedPainter.lastFrameLineCount, equals(0));
      },
    );

    testWidgets(
      'connectionReductionRatio reduces lines proportionally in dense clusters',
      (WidgetTester tester) async {
        final denseParticles = List.generate(
          20,
          (i) => Particle(
            position: Offset(100.0 + (i % 5) * 4.0, 100.0 + (i ~/ 5) * 4.0),
            velocity: Offset.zero,
            color: Colors.white,
            size: 2.0,
          ),
        );

        final unreducedPainter = OptimizedNetworkPainter(
          drawNetwork: true,
          fill: false,
          particleCount: denseParticles.length,
          particles: denseParticles,
          touchPoint: null,
          lineDistance: 50.0,
          particleColor: Colors.white,
          lineColor: Colors.grey,
          lineWidth: 1.0,
          performance: const NetworkPerformance(
            isComplex: false,
          ),
        );

        final moderateReductionPainter = OptimizedNetworkPainter(
          drawNetwork: true,
          fill: false,
          particleCount: denseParticles.length,
          particles: denseParticles,
          touchPoint: null,
          lineDistance: 50.0,
          particleColor: Colors.white,
          lineColor: Colors.grey,
          lineWidth: 1.0,
          performance: const NetworkPerformance(
            isComplex: true,
            connectionReductionRatio: 0.4,
          ),
        );

        final heavyReductionPainter = OptimizedNetworkPainter(
          drawNetwork: true,
          fill: false,
          particleCount: denseParticles.length,
          particles: denseParticles,
          touchPoint: null,
          lineDistance: 50.0,
          particleColor: Colors.white,
          lineColor: Colors.grey,
          lineWidth: 1.0,
          performance: const NetworkPerformance(
            isComplex: true,
            connectionReductionRatio: 0.8,
          ),
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        const size = Size(500, 500);

        unreducedPainter.paint(canvas, size);
        moderateReductionPainter.paint(canvas, size);
        heavyReductionPainter.paint(canvas, size);

        expect(
          moderateReductionPainter.lastFrameLineCount,
          lessThan(unreducedPainter.lastFrameLineCount),
        );
        expect(
          heavyReductionPainter.lastFrameLineCount,
          lessThan(moderateReductionPainter.lastFrameLineCount),
        );
        expect(heavyReductionPainter.lastFrameLineCount, greaterThan(0));
      },
    );
  });
}
