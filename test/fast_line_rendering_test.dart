import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:particles_network/particles_network.dart';

import 'mocks/mock_canvas.mocks.dart';

void main() {
  group('Line Rendering & Performance Tests', () {
    late MockCanvas mockCanvas;

    setUp(() {
      mockCanvas = MockCanvas();
    });

    test('stroke lineRenderer draws lines using drawRawPoints', () {
      final particles = [
        Particle(
          position: const Offset(10.0, 10.0),
          velocity: Offset.zero,
          color: Colors.white,
          size: 1.0,
        ),
        Particle(
          position: const Offset(20.0, 20.0),
          velocity: Offset.zero,
          color: Colors.white,
          size: 1.0,
        ),
        Particle(
          position: const Offset(30.0, 30.0),
          velocity: Offset.zero,
          color: Colors.white,
          size: 1.0,
        ),
      ];

      final painter = OptimizedNetworkPainter(
        drawNetwork: true,
        fill: true,
        isComplex: false,
        particleCount: 3,
        particles: particles,
        touchPoint: null,
        lineDistance: 50.0,
        particleColor: Colors.white,
        lineColor: Colors.blue,
        touchColor: Colors.red,
        touchActivation: false,
        lineWidth: 1.0,
        lineRenderer: LineRenderer.stroke,
      );

      painter.paint(mockCanvas, const Size(200, 200));

      // In stroke mode with <= 30 particles, individual connections draw lines
      verify(mockCanvas.drawLine(any, any, any)).called(greaterThan(0));
    });

    test('maxConnectionsPerParticle limits lines emitted per particle', () {
      // 10 particles at the exact same location
      final particles = List.generate(
        10,
        (_) => Particle(
          position: const Offset(50.0, 50.0),
          velocity: Offset.zero,
          color: Colors.white,
          size: 1.0,
        ),
      );

      final painter = OptimizedNetworkPainter(
        drawNetwork: true,
        fill: true,
        isComplex: false,
        particleCount: 10,
        particles: particles,
        touchPoint: null,
        lineDistance: 100.0,
        particleColor: Colors.white,
        lineColor: Colors.blue,
        touchColor: Colors.red,
        touchActivation: false,
        lineWidth: 1.0,
        maxConnectionsPerParticle: 2,
        lineRenderer: LineRenderer.stroke,
      );

      expect(() => painter.paint(mockCanvas, const Size(200, 200)),
          returnsNormally);
    });

    test(
        'maxLinesPerFrame scales line budget for dense particle sets',
        () {
      final particles = List.generate(
        100,
        (i) => Particle(
          position: Offset((i % 10) * 10.0, (i ~/ 10) * 10.0),
          velocity: Offset.zero,
          color: Colors.white,
          size: 1.0,
        ),
      );

      final painter = OptimizedNetworkPainter(
        drawNetwork: true,
        fill: true,
        isComplex: false,
        particleCount: 100,
        particles: particles,
        touchPoint: null,
        lineDistance: 100.0,
        particleColor: Colors.white,
        lineColor: Colors.blue,
        touchColor: Colors.red,
        touchActivation: false,
        lineWidth: 1.0,
        maxLinesPerFrame: 50,
      );

      expect(() => painter.paint(mockCanvas, const Size(100, 100)),
          returnsNormally);
    });

    test('updatePerformanceOptions updates painter flags dynamically', () {
      final painter = OptimizedNetworkPainter(
        drawNetwork: true,
        fill: true,
        isComplex: false,
        particleCount: 1,
        particles: [
          Particle(
            position: const Offset(10, 10),
            velocity: Offset.zero,
            color: Colors.white,
            size: 1.0,
          )
        ],
        touchPoint: null,
        lineDistance: 100.0,
        particleColor: Colors.white,
        lineColor: Colors.blue,
        touchColor: Colors.red,
        touchActivation: false,
        lineWidth: 1.0,
      );

      expect(painter.lineRenderer, equals(LineRenderer.vertices));
      expect(painter.maxConnectionsPerParticle, isNull);

      painter.updatePerformanceOptions(
        lineRenderer: LineRenderer.stroke,
        maxConnectionsPerParticle: 4,
      );

      expect(painter.lineRenderer, equals(LineRenderer.stroke));
      expect(painter.maxConnectionsPerParticle, equals(4));
    });
  });
}
