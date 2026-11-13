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
    });

    test('highPerformance preset has optimized values', () {
      const perf = NetworkPerformance.highPerformance();

      expect(perf.maxConnectionsPerParticle, equals(4));
      expect(perf.adaptiveDensity, isTrue);
      expect(perf.fastLineRendering, isTrue);
      expect(perf.enableAdaptivePerformance, isTrue);
      expect(perf.maxLinesPerFrame, equals(15000));
      expect(perf.frameRateIndependent, isTrue);
      expect(perf.lineRenderer, equals(LineRenderer.vertices));
      expect(perf.isComplex, isTrue);
    });

    test('adaptive preset has dynamic scaling enabled', () {
      const perf = NetworkPerformance.adaptive();

      expect(perf.maxConnectionsPerParticle, isNull);
      expect(perf.adaptiveDensity, isTrue);
      expect(perf.fastLineRendering, isFalse);
      expect(perf.enableAdaptivePerformance, isTrue);
      expect(perf.maxLinesPerFrame, isNull);
      expect(perf.frameRateIndependent, isTrue);
      expect(perf.lineRenderer, equals(LineRenderer.stroke));
      expect(perf.isComplex, isFalse);
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

    test('toString contains all configuration fields', () {
      const perf = NetworkPerformance(
        maxConnectionsPerParticle: 6,
        fastLineRendering: true,
        isComplex: true,
      );

      final str = perf.toString();
      expect(str, contains('maxConnectionsPerParticle: 6'));
      expect(str, contains('fastLineRendering: true'));
      expect(str, contains('lineRenderer: LineRenderer.stroke'));
      expect(str, contains('isComplex: true'));
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

      var painter =
          tester.widget<CustomPaint>(customPaintFinder).painter
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

      painter =
          tester.widget<CustomPaint>(customPaintFinder).painter
              as OptimizedNetworkPainter;
      expect(painter.maxConnectionsPerParticle, equals(8));
      expect(painter.fastLineRendering, isTrue);
      expect(painter.lineRenderer, equals(LineRenderer.vertices));
      expect(painter.isComplex, isTrue);
    });

    testWidgets('legacy isComplex parameter falls back to painter and logs deprecation', (
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

      final painter =
          tester.widget<CustomPaint>(customPaintFinder).painter
              as OptimizedNetworkPainter;
      expect(painter.isComplex, isTrue);
      expect(
        LegacyDeprecationLogger.hasWarned('ParticleNetwork(isComplex)'),
        isTrue,
      );
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
  });
}

