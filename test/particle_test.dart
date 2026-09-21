import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/particles_network.dart';

void main() {
  group('Particle', () {
    group('Getters and Setters', () {
      test('position getter and setter should update x and y coordinates', () {
        final particle = createMockParticle(
          position: const Offset(10, 20),
        );

        expect(particle.position, const Offset(10, 20));
        expect(particle.x, 10);
        expect(particle.y, 20);

        particle.position = const Offset(35, 45);

        expect(particle.position, const Offset(35, 45));
        expect(particle.x, 35);
        expect(particle.y, 45);
      });

      test('velocity getter and setter should update vx and vy', () {
        final particle = createMockParticle(
          velocity: const Offset(1, 2),
        );

        expect(particle.velocity, const Offset(1, 2));
        expect(particle.vx, 1);
        expect(particle.vy, 2);

        particle.velocity = const Offset(-3, 4);

        expect(particle.velocity, const Offset(-3, 4));
        expect(particle.vx, -3);
        expect(particle.vy, 4);
      });

      test('acceleration getter and setter should update ax and ay', () {
        final particle = createMockParticle();

        expect(particle.acceleration, Offset.zero);
        expect(particle.ax, 0.0);
        expect(particle.ay, 0.0);

        particle.acceleration = const Offset(2.5, -1.5);

        expect(particle.acceleration, const Offset(2.5, -1.5));
        expect(particle.ax, 2.5);
        expect(particle.ay, -1.5);
      });

      test('defaultVelocity getter and setter should update defaultVx and defaultVy', () {
        final particle = createMockParticle(
          velocity: const Offset(1, 2),
        );

        expect(particle.defaultVelocity, const Offset(1, 2));
        expect(particle.defaultVx, 1);
        expect(particle.defaultVy, 2);

        particle.defaultVelocity = const Offset(5, -5);

        expect(particle.defaultVelocity, const Offset(5, -5));
        expect(particle.defaultVx, 5);
        expect(particle.defaultVy, -5);
      });
    });

    group('Forces', () {
      test('applyForce should update acceleration based on particle mass', () {
        // size = 2.0 => mass = 4.0, invMass = 0.25
        final particle = createMockParticle(size: 2.0);

        particle.applyForce(const Offset(8.0, 12.0));

        expect(particle.ax, 2.0);
        expect(particle.ay, 3.0);
        expect(particle.acceleration, const Offset(2.0, 3.0));
      });

      test('applyForce should accumulate multiple forces', () {
        final particle = createMockParticle(size: 1.0); // mass = 1.0, invMass = 1.0

        particle.applyForce(const Offset(2.0, 3.0));
        particle.applyForce(const Offset(-1.0, 4.0));

        expect(particle.acceleration, const Offset(1.0, 7.0));
      });
    });

    group('Screen Boundaries', () {
      test('handleScreenBoundaries should reverse vx and defaultVx at left boundary (x < 0)', () {
        final particle = createMockParticle(
          position: const Offset(-5, 50),
          velocity: const Offset(-2, 3),
        );
        particle.defaultVelocity = const Offset(-2, 3);

        particle.handleScreenBoundaries(const Size(100, 100));

        expect(particle.vx, 2);
        expect(particle.defaultVx, 2);
        expect(particle.vy, 3);
        expect(particle.defaultVy, 3);
      });

      test('handleScreenBoundaries should not reverse vx if already moving inwards from left (vx > 0)', () {
        final particle = createMockParticle(
          position: const Offset(-5, 50),
          velocity: const Offset(2, 3),
        );
        particle.defaultVelocity = const Offset(2, 3);

        particle.handleScreenBoundaries(const Size(100, 100));

        expect(particle.vx, 2);
        expect(particle.defaultVx, 2);
      });

      test('handleScreenBoundaries should reverse vx and defaultVx at right boundary (x > width)', () {
        final particle = createMockParticle(
          position: const Offset(105, 50),
          velocity: const Offset(2, 3),
        );
        particle.defaultVelocity = const Offset(2, 3);

        particle.handleScreenBoundaries(const Size(100, 100));

        expect(particle.vx, -2);
        expect(particle.defaultVx, -2);
      });

      test('handleScreenBoundaries should not reverse vx if already moving inwards from right (vx < 0)', () {
        final particle = createMockParticle(
          position: const Offset(105, 50),
          velocity: const Offset(-2, 3),
        );
        particle.defaultVelocity = const Offset(-2, 3);

        particle.handleScreenBoundaries(const Size(100, 100));

        expect(particle.vx, -2);
        expect(particle.defaultVx, -2);
      });

      test('handleScreenBoundaries should reverse vy and defaultVy at top boundary (y < 0)', () {
        final particle = createMockParticle(
          position: const Offset(50, -5),
          velocity: const Offset(3, -2),
        );
        particle.defaultVelocity = const Offset(3, -2);

        particle.handleScreenBoundaries(const Size(100, 100));

        expect(particle.vy, 2);
        expect(particle.defaultVy, 2);
        expect(particle.vx, 3);
        expect(particle.defaultVx, 3);
      });

      test('handleScreenBoundaries should not reverse vy if already moving inwards from top (vy > 0)', () {
        final particle = createMockParticle(
          position: const Offset(50, -5),
          velocity: const Offset(3, 2),
        );
        particle.defaultVelocity = const Offset(3, 2);

        particle.handleScreenBoundaries(const Size(100, 100));

        expect(particle.vy, 2);
        expect(particle.defaultVy, 2);
      });

      test('handleScreenBoundaries should reverse vy and defaultVy at bottom boundary (y > height)', () {
        final particle = createMockParticle(
          position: const Offset(50, 105),
          velocity: const Offset(3, 2),
        );
        particle.defaultVelocity = const Offset(3, 2);

        particle.handleScreenBoundaries(const Size(100, 100));

        expect(particle.vy, -2);
        expect(particle.defaultVy, -2);
      });

      test('handleScreenBoundaries should not reverse vy if already moving inwards from bottom (vy < 0)', () {
        final particle = createMockParticle(
          position: const Offset(50, 105),
          velocity: const Offset(3, -2),
        );
        particle.defaultVelocity = const Offset(3, -2);

        particle.handleScreenBoundaries(const Size(100, 100));

        expect(particle.vy, -2);
        expect(particle.defaultVy, -2);
      });

      test('handleScreenBoundaries should leave velocities unchanged when within bounds', () {
        final particle = createMockParticle(
          position: const Offset(50, 50),
          velocity: const Offset(3, 4),
        );
        particle.defaultVelocity = const Offset(3, 4);

        particle.handleScreenBoundaries(const Size(100, 100));

        expect(particle.vx, 3);
        expect(particle.vy, 4);
        expect(particle.defaultVx, 3);
        expect(particle.defaultVy, 4);
      });
    });

    group('Visibility', () {
      const Size bounds = Size(200, 200);
      const double margin = 50.0;

      test('should mark particle as visible when within viewport bounds', () {
        final particle = createMockParticle(position: const Offset(100, 100));
        particle.updateVisibility(bounds);
        expect(particle.isVisible, isTrue);
      });

      test('should mark particle as visible on the margin boundaries', () {
        // -margin <= x <= width + margin, -margin <= y <= height + margin
        final particle1 = createMockParticle(position: const Offset(-50.0, -50.0));
        particle1.updateVisibility(bounds);
        expect(particle1.isVisible, isTrue);

        final particle2 = createMockParticle(
          position: Offset(bounds.width + margin, bounds.height + margin),
        );
        particle2.updateVisibility(bounds);
        expect(particle2.isVisible, isTrue);
      });

      test('should mark particle as not visible when exceeding margin limits', () {
        final particleLeft = createMockParticle(position: Offset(-margin - 0.1, 100));
        particleLeft.updateVisibility(bounds);
        expect(particleLeft.isVisible, isFalse);

        final particleRight = createMockParticle(position: Offset(bounds.width + margin + 0.1, 100));
        particleRight.updateVisibility(bounds);
        expect(particleRight.isVisible, isFalse);

        final particleTop = createMockParticle(position: Offset(100, -margin - 0.1));
        particleTop.updateVisibility(bounds);
        expect(particleTop.isVisible, isFalse);

        final particleBottom = createMockParticle(position: Offset(100, bounds.height + margin + 0.1));
        particleBottom.updateVisibility(bounds);
        expect(particleBottom.isVisible, isFalse);
      });
    });

    group('Update and Motion', () {
      test(
        'should reset wasAccelerated to false when velocity equals defaultVelocity',
        () {
          final particle = createMockParticle(
            position: const Offset(0, 0),
            velocity: const Offset(5, 5),
          );
          particle.defaultVelocity = const Offset(5, 5);
          particle.wasAccelerated = true;

          particle.update(const Size(100, 100));

          expect(particle.wasAccelerated, isFalse);
        },
      );

      test('should update position based on velocity', () {
        final particle = createMockParticle(
          position: const Offset(10, 10),
          velocity: const Offset(2, 3),
        );

        particle.update(const Size(100, 100));

        expect(particle.position.dx, 12);
        expect(particle.position.dy, 13);
      });

      test('should reverse velocity on horizontal boundary collision', () {
        final particle = createMockParticle(
          position: const Offset(1, 50), // خارج الحدود
          velocity: const Offset(1, 0),
        );

        particle.update(const Size(100, 100));

        expect(particle.velocity.dx, 1);
      });

      test('should reverse velocity on vertical boundary collision', () {
        final particle = createMockParticle(
          position: const Offset(50, 101),
          velocity: const Offset(0, 1),
        );

        particle.update(const Size(100, 100));

        expect(particle.velocity.dy, -1);
      });

      test('should mark particle as not visible when far outside bounds', () {
        final particle = createMockParticle(position: const Offset(1000, 1000));

        particle.updateVisibility(const Size(500, 500));

        expect(particle.isVisible, false);
      });

      test('should gradually return velocity to default when accelerated', () {
        final particle = createMockParticle(
          position: const Offset(10, 0),
          velocity: const Offset(12, 0), // سرعة مبدئية أسرع من الافتراضية
        );
        particle.defaultVelocity = const Offset(10, 0); // سرعة افتراضية
        particle.wasAccelerated = true;

        final initialVelocity = particle.velocity;

        particle.update(const Size(500, 500));

        // يجب أن تبدأ السرعة بالتباطؤ نحو السرعة الافتراضية
        expect(particle.velocity.dx < initialVelocity.dx, isTrue);
        expect(particle.velocity.dy, equals(0)); // لا يوجد تسارع على محور Y
      });
    });
  });

  group('computeVelocity', () {
    const Offset defaultVel = Offset(2.0, 3.0);

    test('returns defaultVelocity when difference is within speedThreshold', () {
      const Offset currentVel = Offset(2.02, 3.02);
      // distance is sqrt(0.02^2 + 0.02^2) = sqrt(0.0008) ≈ 0.02828 < 0.05
      final result = computeVelocity(currentVel, defaultVel, 0.05);

      expect(result, equals(defaultVel));
    });

    test('returns lerped velocity when difference is greater than speedThreshold', () {
      const Offset currentVel = Offset(10.0, 15.0);
      const double decayRate = 0.1;
      final expected = Offset.lerp(currentVel, defaultVel, decayRate)!;

      final result = computeVelocity(currentVel, defaultVel, 0.05, decayRate);

      expect(result, equals(expected));
    });

    test('uses default decayRate of 0.012 when not specified', () {
      const Offset currentVel = Offset(10.0, 15.0);
      final expected = Offset.lerp(currentVel, defaultVel, 0.012)!;

      final result = computeVelocity(currentVel, defaultVel, 0.05);

      expect(result, equals(expected));
    });
  });
}
