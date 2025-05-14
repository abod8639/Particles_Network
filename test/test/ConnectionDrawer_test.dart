// test/connection_drawer_test.dart

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:particles_network/model/GridCell.dart';
import 'package:particles_network/model/particlemodel.dart';
import 'package:particles_network/painter/ConnectionDrawer.dart';
import 'package:particles_network/painter/DistanceCalculator.dart';

import 'mocks/mock_canvas.mocks.dart';

class MockParticle extends Particle {
  MockParticle({
    required super.position,
    super.velocity = Offset.zero,
    super.color = const Color(0xFFFFFFFF),
    super.size = 1.0,
    bool wasAccelerated = false,
  });
}

void main() {
  group('ConnectionDrawer', () {
    test('should draw line between two close particles', () {
      // Arrange
      final canvas = MockCanvas();
      final particle1 = MockParticle(position: Offset(0, 0));
      final particle2 = MockParticle(position: Offset(3, 4)); // Distance = 5
      final particles = [particle1, particle2];
      final cell = GridCell(0, 0);
      final grid = {
        cell: [0, 1],
      };

      final linePaint = Paint();
      final distanceCalculator = DistanceCalculator(10);
      final drawer = ConnectionDrawer(
        particles: particles,
        particleCount: 2,
        lineDistance: 10.0,
        lineColor: const Color(0xFF000000),
        linePaint: linePaint,
        distanceCalculator: distanceCalculator,
      );

      // Act
      drawer.drawConnections(canvas, grid);

      // Assert
      verify(
        canvas.drawLine(particle1.position, particle2.position, any),
      ).called(1);
    });

    test('should not draw line if particles are far apart', () {
      final canvas = MockCanvas();
      final particle1 = MockParticle(position: Offset(0, 0));
      final particle2 = MockParticle(position: Offset(100, 100)); // Far apart
      final particles = [particle1, particle2];
      final grid = {
        GridCell(0, 0): [0, 1],
      };

      final linePaint = Paint();
      final distanceCalculator = DistanceCalculator(10);
      final drawer = ConnectionDrawer(
        particles: particles,
        particleCount: 2,
        lineDistance: 10.0,
        lineColor: const Color(0xFF000000),
        linePaint: linePaint,
        distanceCalculator: distanceCalculator,
      );

      drawer.drawConnections(canvas, grid);

      verifyNever(canvas.drawLine(any, any, any));
    });
  });
}
