import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/particles_network.dart';

void main() {
  group('TrajectoryBuffer Tests', () {
    late TrajectoryBuffer buffer;
    late List<Particle> particles;
    late ParticleUpdater controller;
    const size = Size(500, 500);

    setUp(() {
      buffer = TrajectoryBuffer(capacity: 10);
      controller = ParticleUpdater();
      particles = [
        Particle(
          position: const Offset(100, 100),
          velocity: const Offset(2, 3),
          color: Colors.white,
          size: 2.0,
        ),
        Particle(
          position: const Offset(200, 200),
          velocity: const Offset(-1, -2),
          color: Colors.white,
          size: 3.0,
        ),
      ];
    });

    test('initial state is invalid', () {
      expect(buffer.isValid, isFalse);
      expect(buffer.currentFrame, 0);
      expect(buffer.remainingFrames, 0);
    });

    test('precompute populates buffer and marks as valid', () {
      buffer.precompute(
        particles: particles,
        bounds: size,
        controller: controller,
      );

      expect(buffer.isValid, isTrue);
      expect(buffer.remainingFrames, 10);
      expect(buffer.currentFrame, 0);
    });

    test('advance updates particle positions matching simulation', () {
      // Calculate expected position after 1 step
      final expectedP0 = Offset(100 + 2, 100 + 3);
      final expectedP1 = Offset(200 - 1, 200 - 2);

      buffer.precompute(
        particles: particles,
        bounds: size,
        controller: controller,
      );

      final advanced = buffer.advance(particles);
      expect(advanced, isTrue);
      expect(buffer.currentFrame, 1);
      expect(particles[0].position, expectedP0);
      expect(particles[1].position, expectedP1);
    });

    test('buffer marks invalid after capacity is reached', () {
      buffer.precompute(
        particles: particles,
        bounds: size,
        controller: controller,
      );

      for (int i = 0; i < 10; i++) {
        expect(buffer.advance(particles), isTrue);
      }

      // 11th step should return false because buffer reached end
      expect(buffer.advance(particles), isFalse);
      expect(buffer.isValid, isFalse);
    });

    test('invalidate resets buffer state immediately', () {
      buffer.precompute(
        particles: particles,
        bounds: size,
        controller: controller,
      );
      expect(buffer.isValid, isTrue);

      buffer.invalidate();
      expect(buffer.isValid, isFalse);
      expect(buffer.advance(particles), isFalse);
    });
  });
}
