import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/model/particlemodel.dart';
import 'package:particles_network/painter/particle_filter.dart';
import 'dart:ui';

void main() {
  group('ParticleFilter Tests', () {
    test('getVisibleParticles returns indices of visible particles', () {
      final particles = [
        Particle(position: Offset.zero, velocity: Offset.zero, size: 1.0, color: const Color(0xFFFFFFFF))..isVisible = true,
        Particle(position: Offset.zero, velocity: Offset.zero, size: 1.0, color: const Color(0xFFFFFFFF))..isVisible = false,
        Particle(position: Offset.zero, velocity: Offset.zero, size: 1.0, color: const Color(0xFFFFFFFF))..isVisible = true,
      ];

      final result = ParticleFilter.getVisibleParticles(particles);

      expect(result, [0, 2]);
    });

    test('getVisibleParticles returns empty list if no particles are visible', () {
       final particles = [
        Particle(position: Offset.zero, velocity: Offset.zero, size: 1.0, color: const Color(0xFFFFFFFF))..isVisible = false,
        Particle(position: Offset.zero, velocity: Offset.zero, size: 1.0, color: const Color(0xFFFFFFFF))..isVisible = false,
      ];

      final result = ParticleFilter.getVisibleParticles(particles);

      expect(result, isEmpty);
    });

    test('getVisibleParticles returns all indices if all particles are visible', () {
       final particles = [
        Particle(position: Offset.zero, velocity: Offset.zero, size: 1.0, color: const Color(0xFFFFFFFF))..isVisible = true,
        Particle(position: Offset.zero, velocity: Offset.zero, size: 1.0, color: const Color(0xFFFFFFFF))..isVisible = true,
      ];

      final result = ParticleFilter.getVisibleParticles(particles);

      expect(result, [0, 1]);
    });
    
    test('getVisibleParticles handles empty list', () {
      final particles = <Particle>[];
      
      final result = ParticleFilter.getVisibleParticles(particles);
      
      expect(result, isEmpty);
    });
  });
}
