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

    group('precompute validation and invalidation', () {
      test('sets isValid to false when particles list is empty', () {
        buffer.precompute(
          particles: [],
          bounds: size,
          controller: controller,
        );

        expect(buffer.isValid, isFalse);
      });

      test('sets isValid to false when bounds width is <= 0', () {
        buffer.precompute(
          particles: particles,
          bounds: const Size(0, 500),
          controller: controller,
        );

        expect(buffer.isValid, isFalse);

        buffer.precompute(
          particles: particles,
          bounds: const Size(-10, 500),
          controller: controller,
        );

        expect(buffer.isValid, isFalse);
      });

      test('sets isValid to false when bounds height is <= 0', () {
        buffer.precompute(
          particles: particles,
          bounds: const Size(500, 0),
          controller: controller,
        );

        expect(buffer.isValid, isFalse);

        buffer.precompute(
          particles: particles,
          bounds: const Size(500, -10),
          controller: controller,
        );

        expect(buffer.isValid, isFalse);
      });

      test('invalidates previously valid buffer when re-precomputing with invalid parameters', () {
        buffer.precompute(
          particles: particles,
          bounds: size,
          controller: controller,
        );
        expect(buffer.isValid, isTrue);

        // Re-precompute with empty particles
        buffer.precompute(
          particles: [],
          bounds: size,
          controller: controller,
        );
        expect(buffer.isValid, isFalse);
      });
    });

    group('cached sim particles refresh (subsequent precompute)', () {
      test('refreshes existing cached simulation particle states without reallocation', () {
        // First precompute initializes the cached sim particles
        buffer.precompute(
          particles: particles,
          bounds: size,
          controller: controller,
        );
        expect(buffer.isValid, isTrue);

        // Advance a few frames
        buffer.advance(particles);
        buffer.advance(particles);

        // Modify particles state (e.g. position, velocity, wasAccelerated)
        particles[0].position = const Offset(300, 300);
        particles[0].velocity = const Offset(5, -5);
        particles[0].defaultVx = 2.0;
        particles[0].defaultVy = -2.0;
        particles[0].wasAccelerated = true;

        particles[1].position = const Offset(400, 400);
        particles[1].velocity = const Offset(-4, 4);

        // Second precompute with same particles.length triggers the refresh branch
        buffer.precompute(
          particles: particles,
          bounds: size,
          controller: controller,
        );

        expect(buffer.isValid, isTrue);
        expect(buffer.currentFrame, 0);

        // Advance 1 frame and verify it advances from the updated states
        final advanced = buffer.advance(particles);
        expect(advanced, isTrue);

        // Expected p0: 300 + 5 = 305, 300 - 5 = 295
        expect(particles[0].position.dx, closeTo(305.0, 0.001));
        expect(particles[0].position.dy, closeTo(295.0, 0.001));

        // Expected p1: 400 - 4 = 396, 400 + 4 = 404
        expect(particles[1].position.dx, closeTo(396.0, 0.001));
        expect(particles[1].position.dy, closeTo(404.0, 0.001));
      });
    });
  });
}
