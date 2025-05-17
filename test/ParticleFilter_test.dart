import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/model/particlemodel.dart';
import 'package:particles_network/painter/particle_filter.dart';

/// فئة اختبارية للجسيمات لتسهيل التحقق
class TestParticle extends Particle {
  TestParticle({
    required super.position,
    super.velocity = Offset.zero,
    super.color = const Color(0xFFFFFFFF),
    super.size = 1.0,
    super.isVisible,
  });
}

void main() {
  group('ParticleFilter', () {
    test('returns only indices of visible particles', () {
      final particles = [
        TestParticle(position: Offset.zero, isVisible: true), // index 0
        TestParticle(position: Offset.zero, isVisible: false), // index 1
        TestParticle(position: Offset.zero, isVisible: true), // index 2
        TestParticle(position: Offset.zero, isVisible: false), // index 3
        TestParticle(position: Offset.zero, isVisible: true), // index 4
      ];

      final visibleIndices = ParticleFilter.getVisibleParticles(particles);

      // التأكد أن النتيجة هي فقط الجسيمات الظاهرة
      expect(visibleIndices, equals([0, 2, 4]));
    });

    test('returns empty list if no particles are visible', () {
      final particles = [
        TestParticle(position: Offset.zero, isVisible: false),
        TestParticle(position: Offset.zero, isVisible: false),
      ];

      final visibleIndices = ParticleFilter.getVisibleParticles(particles);

      // التأكد أنه لا توجد جسيمات ظاهرة
      expect(visibleIndices, isEmpty);
    });

    test('returns all indices if all particles are visible', () {
      final particles = List.generate(
        5,
        (i) => TestParticle(position: Offset.zero, isVisible: true),
      );

      final visibleIndices = ParticleFilter.getVisibleParticles(particles);

      // التأكد أن جميع الجسيمات الظاهرة
      expect(visibleIndices, equals([0, 1, 2, 3, 4]));
    });
  });
}
