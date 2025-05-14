import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/model/particlemodel.dart';

void main() {
  group('Particle', () {
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
}
