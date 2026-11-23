import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/particles_network.dart';
import 'package:particles_network/src/rendering/line_budget_controller.dart';
import 'package:particles_network/src/rendering/line_style_palette.dart';

import 'golden_characterization_test.dart';

void main() {
  group('Phase 1: Inconsistencies Confirmation Tests', () {
    test(
        '1. Radius consistency: cellSize >= scanRadius across ALL combinations + brute force equivalence',
        () {
      final budgets = <int?>[null, 2, 50];
      final caps = <int?>[null, 2, 5];
      final factors = <double>[0.35, 0.7, 1.0];
      final floors = <double>[4.0, 10.0, 20.0];

      final particles = [
        Particle(
            position: const Offset(10, 10),
            velocity: Offset.zero,
            size: 1.0,
            color: const Color(0xFFFFFFFF)),
        Particle(
            position: const Offset(25, 10),
            velocity: Offset.zero,
            size: 1.0,
            color: const Color(0xFFFFFFFF)),
        Particle(
            position: const Offset(40, 10),
            velocity: Offset.zero,
            size: 1.0,
            color: const Color(0xFFFFFFFF)),
        Particle(
            position: const Offset(55, 10),
            velocity: Offset.zero,
            size: 1.0,
            color: const Color(0xFFFFFFFF)),
      ];

      for (final budget in budgets) {
        for (final cap in caps) {
          for (final factor in factors) {
            for (final floor in floors) {
              final painter = OptimizedNetworkPainter(
                particles: particles,
                particleCount: particles.length,
                touchPoint: null,
                lineDistance: 50.0,
                particleColor: const Color(0xFFFFFFFF),
                lineColor: const Color(0x80FFFFFF),
                lineWidth: 1.0,
                fill: true,
                drawNetwork: true,
                gridTuning: GridTuning(minCellFloor: floor),
                performance: PerformanceFeatures(
                  maxLinesPerFrame: budget,
                  maxConnectionsPerParticle: cap,
                  cappedDistanceFactor: factor,
                ),
              );

              final canvas = RecordingCanvas();
              painter.paint(canvas, const Size(500, 500));

              final double cellSize = painter.spatialGrid.cellSize;
              final double scanRadius = painter.lastFrameLineDistance;

              expect(
                cellSize,
                greaterThanOrEqualTo(scanRadius),
                reason:
                    'cellSize ($cellSize) must be >= scanRadius ($scanRadius) for budget=$budget, cap=$cap, factor=$factor, floor=$floor',
              );

              // Brute-force equivalence: All emitted lines must have distance <= scanRadius
              for (final line in canvas.lineCalls) {
                final double d = (line.p1 - line.p2).distance;
                expect(d, lessThanOrEqualTo(scanRadius + 0.001));
              }
            }
          }
        }
      }
    });

    test(
        '2. Alpha consistency: separate alphaRadius preserves 1.9.7 floor semantics across r in {2.5, 5, 10, 25}',
        () {
      final controller = LineBudgetController();
      const double baseDistance = 100.0;
      const size = Size(500, 500);

      // Verify FrameRadii alphaRadius preserves 1.9.7 20px floor semantics
      // For budgeted distances r in {2.5, 5, 10, 25}:
      // - At r=2.5: activeDist clamps to 4.0, but alphaRadius must clamp to 20.0
      // - At r=5.0: activeDist=5.0, alphaRadius must clamp to 20.0
      // - At r=10.0: activeDist=10.0, alphaRadius must clamp to 20.0
      // - At r=25.0: activeDist=25.0, alphaRadius=25.0 (since r >= 20.0)
      final expectedAlphaRadii = {
        2.5: 20.0,
        5.0: 20.0,
        10.0: 20.0,
        25.0: 25.0,
      };

      for (final entry in expectedAlphaRadii.entries) {
        final double targetR = entry.key;
        final double expectedAlpha = entry.value;

        // Calculate maxLinesPerFrame that analytically produces targetR:
        // r = sqrt(2 * A * M / (pi * N^2)) => M = (r^2 * pi * N^2) / (2 * A)
        const int n = 100;
        const double area = 500.0 * 500.0;
        final int maxLines =
            ((targetR * targetR * math.pi * n * n) / (2.0 * area)).round();

        final radii = controller.computeFrameRadii(
          baseDistance: baseDistance,
          size: size,
          visibleCount: n,
          maxLinesPerFrame: maxLines,
          maxConnectionsPerParticle: null,
          cappedDistanceFactor: 1.0,
        );

        expect(radii.alphaRadius, closeTo(expectedAlpha, 0.5),
            reason:
                'For budgeted r=$targetR, alphaRadius must match 1.9.7 floor ($expectedAlpha)');
      }
    });

    test(
        '3. lastFrameLineDistance holds scanRadius and lastFrameScanRadius is exposed',
        () {
      final particles = [
        Particle(
            position: const Offset(10, 10),
            velocity: Offset.zero,
            size: 1.0,
            color: const Color(0xFFFFFFFF)),
        Particle(
            position: const Offset(30, 10),
            velocity: Offset.zero,
            size: 1.0,
            color: const Color(0xFFFFFFFF)),
      ];
      final painter = OptimizedNetworkPainter(
        particles: particles,
        particleCount: particles.length,
        touchPoint: null,
        lineDistance: 80.0,
        particleColor: const Color(0xFFFFFFFF),
        lineColor: const Color(0x80FFFFFF),
        lineWidth: 1.0,
        fill: true,
        drawNetwork: true,
      );

      final canvas = RecordingCanvas();
      painter.paint(canvas, const Size(500, 500));

      expect(painter.lastFrameLineDistance, equals(80.0));
      expect(painter.lastFrameScanRadius, equals(80.0));
    });

    test(
        '4. TouchInteractionHandler lineRenderer: verified intentional default to LineRenderer.vertices',
        () {
      final List<Particle> particles = [
        Particle(
            position: const Offset(10, 10),
            velocity: Offset.zero,
            size: 1.0,
            color: const Color(0xFFFFFFFF)),
      ];

      final painter = OptimizedNetworkPainter(
        particles: particles,
        particleCount: particles.length,
        touchPoint: null,
        lineDistance: 100.0,
        particleColor: const Color(0xFFFFFFFF),
        lineColor: const Color(0x80FFFFFF),
        lineWidth: 1.0,
        fill: true,
        drawNetwork: true,
        lineRenderer: LineRenderer.stroke,
      );

      // Confirmed rejected: Touch lines intentionally default to LineRenderer.vertices
      // as tested and asserted by touch_interaction_handler_test.dart and optimizednetworkpainter_test.dart.
      expect(painter.touchHandler.lineRenderer, equals(LineRenderer.vertices));
    });

    test(
        '5. shouldRepaint should detect changes in fill, drawNetwork, lineWidth, devicePixelRatio',
        () {
      final List<Particle> particles = [
        Particle(
            position: const Offset(10, 10),
            velocity: Offset.zero,
            size: 1.0,
            color: const Color(0xFFFFFFFF)),
      ];

      final painter1 = OptimizedNetworkPainter(
        particles: particles,
        particleCount: particles.length,
        touchPoint: null,
        lineDistance: 100.0,
        particleColor: const Color(0xFFFFFFFF),
        lineColor: const Color(0x80FFFFFF),
        lineWidth: 1.0,
        fill: true,
        drawNetwork: true,
        devicePixelRatio: 1.0,
      );

      final painter2 = OptimizedNetworkPainter(
        particles: particles,
        particleCount: particles.length,
        touchPoint: null,
        lineDistance: 100.0,
        particleColor: const Color(0xFFFFFFFF),
        lineColor: const Color(0x80FFFFFF),
        lineWidth: 2.0, // changed
        fill: true,
        drawNetwork: true,
        devicePixelRatio: 1.0,
      );

      final painter3 = OptimizedNetworkPainter(
        particles: particles,
        particleCount: particles.length,
        touchPoint: null,
        lineDistance: 100.0,
        particleColor: const Color(0xFFFFFFFF),
        lineColor: const Color(0x80FFFFFF),
        lineWidth: 1.0,
        fill: false, // changed
        drawNetwork: true,
        devicePixelRatio: 1.0,
      );

      final painter4 = OptimizedNetworkPainter(
        particles: particles,
        particleCount: particles.length,
        touchPoint: null,
        lineDistance: 100.0,
        particleColor: const Color(0xFFFFFFFF),
        lineColor: const Color(0x80FFFFFF),
        lineWidth: 1.0,
        fill: true,
        drawNetwork: false, // changed
        devicePixelRatio: 1.0,
      );

      final painter5 = OptimizedNetworkPainter(
        particles: particles,
        particleCount: particles.length,
        touchPoint: null,
        lineDistance: 100.0,
        particleColor: const Color(0xFFFFFFFF),
        lineColor: const Color(0x80FFFFFF),
        lineWidth: 1.0,
        fill: true,
        drawNetwork: true,
        devicePixelRatio: 2.0, // changed
      );

      expect(painter2.shouldRepaint(painter1), isTrue,
          reason: 'lineWidth changed');
      expect(painter3.shouldRepaint(painter1), isTrue, reason: 'fill changed');
      expect(painter4.shouldRepaint(painter1), isTrue,
          reason: 'drawNetwork changed');
      expect(painter5.shouldRepaint(painter1), isTrue,
          reason: 'devicePixelRatio changed');
    });

    test('6. updateLineDistance does not recompute distBucketTable', () {
      final initialTable = LineStylePalette.distBucketTable;
      final particles = [
        Particle(
            position: const Offset(10, 10),
            velocity: Offset.zero,
            size: 1.0,
            color: const Color(0xFFFFFFFF)),
      ];
      final painter = OptimizedNetworkPainter(
        particles: particles,
        particleCount: particles.length,
        touchPoint: null,
        lineDistance: 50.0,
        particleColor: const Color(0xFFFFFFFF),
        lineColor: const Color(0x80FFFFFF),
        lineWidth: 1.0,
        fill: true,
        drawNetwork: true,
      );

      painter.updateLineDistance(80.0);
      expect(painter.lineDistance, equals(80.0));
      expect(identical(LineStylePalette.distBucketTable, initialTable), isTrue,
          reason:
              'distBucketTable must remain identical static final instance');
    });

    test('7. updatePerformance does not execute redundant isComplex assignment',
        () {
      final particles = [
        Particle(
            position: const Offset(10, 10),
            velocity: Offset.zero,
            size: 1.0,
            color: const Color(0xFFFFFFFF)),
      ];
      final painter = OptimizedNetworkPainter(
        particles: particles,
        particleCount: particles.length,
        touchPoint: null,
        lineDistance: 50.0,
        particleColor: const Color(0xFFFFFFFF),
        lineColor: const Color(0x80FFFFFF),
        lineWidth: 1.0,
        fill: true,
        drawNetwork: true,
        performance: const PerformanceFeatures(complex: ComplexConfig(enabled: false)),
      );

      painter.updatePerformance(const PerformanceFeatures(complex: ComplexConfig(enabled: true)));
      expect(painter.isComplex, isTrue);
      expect(painter.performance.isComplex, isTrue);
    });

    test(
        '8. Variable c in _drawIndividualConnections does not shadow cell index',
        () {
      final particles = [
        Particle(
            position: const Offset(10, 10),
            velocity: Offset.zero,
            size: 1.0,
            color: const Color(0xFFFFFFFF)),
        Particle(
            position: const Offset(20, 10),
            velocity: Offset.zero,
            size: 1.0,
            color: const Color(0xFFFFFFFF)),
      ];
      final painter = OptimizedNetworkPainter(
        particles: particles,
        particleCount: particles.length,
        touchPoint: null,
        lineDistance: 50.0,
        particleColor: const Color(0xFFFFFFFF),
        lineColor: const Color(0x80FFFFFF),
        lineWidth: 1.0,
        fill: true,
        drawNetwork: true,
      );

      final canvas = RecordingCanvas();
      // N=2 runs individual connections path
      painter.paint(canvas, const Size(100, 100));
      expect(canvas.lineCalls.length, equals(1));
    });
  });
}
