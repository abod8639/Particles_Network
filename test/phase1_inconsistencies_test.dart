import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/particles_network.dart';

import 'golden_characterization_test.dart';

void main() {
  group('Phase 1: Inconsistencies Confirmation Tests', () {
    test(
        '1. Radius consistency: cellSize must be >= scanRadius with budget + cap',
        () {
      final particles = [
        Particle(
            position: const Offset(1, 100),
            velocity: Offset.zero,
            size: 1.0,
            color: const Color(0xFFFFFFFF)),
        Particle(
            position: const Offset(31, 100),
            velocity: Offset.zero,
            size: 1.0,
            color: const Color(0xFFFFFFFF)),
      ];

      final painter = OptimizedNetworkPainter(
        particles: particles,
        particleCount: particles.length,
        touchPoint: null,
        lineDistance: 40.0,
        particleColor: const Color(0xFFFFFFFF),
        lineColor: const Color(0x80FFFFFF),
        lineWidth: 1.0,
        fill: true,
        drawNetwork: true,
        performance: const NetworkPerformance(
          maxLinesPerFrame: 2, // effectiveDistance will be set
          maxConnectionsPerParticle: 2,
          cappedDistanceFactor: 0.35, // gridRadius = 40 * 0.35 = 14.0 px!
        ),
      );

      final canvas = RecordingCanvas();
      painter.paint(canvas, const Size(500, 500));

      // With FrameRadii, gridRadius and scanRadius are ALWAYS identical.
      expect(painter.spatialGrid.cellSize,
          greaterThanOrEqualTo(painter.lastFrameLineDistance));
    });

    test(
        '4. TouchInteractionHandler lineRenderer: verified that touch lines intentionally default to LineRenderer.vertices',
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
        performance: const NetworkPerformance(
          lineRenderer: LineRenderer.stroke,
        ),
      );

      // Confirmed rejected: Touch lines intentionally default to LineRenderer.vertices
      // as tested and asserted by touch_interaction_handler_test.dart (L896) and
      // optimizednetworkpainter_test.dart (L372).
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

      // Prior to fix, shouldRepaint returns false for lineWidth, fill, drawNetwork, devicePixelRatio:
      expect(painter2.shouldRepaint(painter1), isTrue,
          reason: 'lineWidth changed');
      expect(painter3.shouldRepaint(painter1), isTrue, reason: 'fill changed');
      expect(painter4.shouldRepaint(painter1), isTrue,
          reason: 'drawNetwork changed');
      expect(painter5.shouldRepaint(painter1), isTrue,
          reason: 'devicePixelRatio changed');
    });
  });
}
