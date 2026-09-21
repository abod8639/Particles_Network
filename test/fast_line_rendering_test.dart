import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:particles_network/particles_network.dart';

import 'mocks/mock_canvas.mocks.dart';

void main() {
  group('Fast Line Rendering & Performance Governor Tests', () {
    late MockCanvas mockCanvas;

    setUp(() {
      mockCanvas = MockCanvas();
    });

    test('fastLineRendering draws lines using a single drawRawPoints call', () {
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
        fastLineRendering: true,
      );

      painter.paint(mockCanvas, const Size(200, 200));

      // In fastLineRendering, lines are batched into a single drawRawPoints call
      verify(mockCanvas.drawRawPoints(PointMode.lines, any, any)).called(1);
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
        fastLineRendering: true,
      );

      expect(() => painter.paint(mockCanvas, const Size(200, 200)), returnsNormally);
      verify(mockCanvas.drawRawPoints(PointMode.lines, any, any)).called(1);
    });

    test('adaptiveDensity scales effective line distance for dense particle sets', () {
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
        adaptiveDensity: true,
      );

      expect(() => painter.paint(mockCanvas, const Size(100, 100)), returnsNormally);
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

      expect(painter.fastLineRendering, isFalse);
      expect(painter.adaptiveDensity, isFalse);
      expect(painter.maxConnectionsPerParticle, isNull);

      painter.updatePerformanceOptions(
        fastLineRendering: true,
        adaptiveDensity: true,
        maxConnectionsPerParticle: 4,
      );

      expect(painter.fastLineRendering, isTrue);
      expect(painter.useVerticesRendering, isTrue);
      expect(painter.adaptiveDensity, isTrue);
      expect(painter.maxConnectionsPerParticle, equals(4));
    });
  });
}
