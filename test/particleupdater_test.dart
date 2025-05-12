import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/model/particlemodel.dart';
import 'package:particles_network/painter/ParticleUpdater.dart';

void main() {
  group('ParticleUpdater', () {
    late ParticleUpdater updater;
    late Particle particle;
    late Size bounds;

    setUp(() {
      updater = ParticleUpdater();
      particle = Particle(
        position: const Offset(100, 100),
        velocity: const Offset(1, 1),
        color: Colors.white,
        size: 2.0,
      );
      bounds = const Size(400, 400);
    });

    group('updateParticle', () {
      test('updates particle position based on velocity', () {
        final initialPosition = particle.position;
        updater.updateParticle(particle, bounds);
        expect(particle.position, isNot(equals(initialPosition)));
      });
    });

    group('applyTouchInteraction', () {
      test('applies force to particles within lineDistance', () {
        final particles = [particle];
        final visibleIndices = [0];
        final touch = const Offset(110, 110); // Close to particle
        final lineDistance = 20.0;

        final initialVelocity = particle.velocity;
        updater.applyTouchInteraction(
          touch: touch,
          lineDistance: lineDistance,
          particles: particles,
          visibleIndices: visibleIndices,
        );

        expect(particle.velocity, isNot(equals(initialVelocity)));
        expect(particle.wasAccelerated, isTrue);
      });

      test('does not affect particles outside lineDistance', () {
        final particles = [particle];
        final visibleIndices = [0];
        final touch = const Offset(200, 200); // Far from particle
        final lineDistance = 20.0;

        final initialVelocity = particle.velocity;
        updater.applyTouchInteraction(
          touch: touch,
          lineDistance: lineDistance,
          particles: particles,
          visibleIndices: visibleIndices,
        );

        expect(particle.velocity, equals(initialVelocity));
        expect(particle.wasAccelerated, isFalse);
      });

      test('handles multiple particles correctly', () {
        final particles = [
          Particle(
            position: const Offset(100, 100),
            velocity: const Offset(1, 1),
            color: Colors.white,
            size: 2.0,
          ),
          Particle(
            position: const Offset(200, 200),
            velocity: const Offset(1, 1),
            color: Colors.white,
            size: 2.0,
          ),
        ];
        final visibleIndices = [0, 1];
        final touch = const Offset(110, 110);
        final lineDistance = 20.0;

        updater.applyTouchInteraction(
          touch: touch,
          lineDistance: lineDistance,
          particles: particles,
          visibleIndices: visibleIndices,
        );

        // First particle should be affected
        expect(particles[0].wasAccelerated, isTrue);
        // Second particle should not be affected
        expect(particles[1].wasAccelerated, isFalse);
      });
    });
  });
}
