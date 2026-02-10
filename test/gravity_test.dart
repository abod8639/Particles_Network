import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/model/particlemodel.dart';
import 'package:particles_network/model/ip_article.dart';

void main() {
  group('Gravity Physics Tests', () {
    late Particle particle;
    late ParticleUpdater updater;
    late Size bounds;

    setUp(() {
      particle = Particle(
        position: const Offset(100, 100),
        velocity: Offset.zero,
        color: const Color(0xFFFFFFFF),
        size: 2.0, // Mass will be 4.0
      );
      updater = ParticleUpdater();
      bounds = const Size(1000, 1000);
    });

    test('Global gravity applies constant force', () {
      const config = GravityConfig(
        type: GravityType.global,
        strength: 1.0,
        direction: const Offset(0, 1), // Down
      );

      // Frame 1: Acceleration = Force / Mass = (0, 1) / 4 = (0, 0.25)
      // Velocity becomes (0, 0.25)
      // Position becomes (100, 100.25)
      updater.updateParticles([particle], bounds, gravity: config);
      expect(particle.velocity.dy, closeTo(0.25, 0.001));
      expect(particle.position.dy, closeTo(100.25, 0.001));

      // Frame 2: Velocity becomes 0.25 + 0.25 = 0.5
      // Position becomes 100.25 + 0.5 = 100.75
      updater.updateParticles([particle], bounds, gravity: config);
      expect(particle.velocity.dy, closeTo(0.5, 0.001));
      expect(particle.position.dy, closeTo(100.75, 0.001));
    });

    test('Point gravity attracts towards center', () {
      // Particle at (100, 100), Center at (200, 100)
      // Vector = (100, 0), Distance = 100
      // Unit Vector = (1, 0)
      // Force = (1, 0) * 1.0 = (1, 0)
      // Accel = (1, 0) / 4.0 = (0.25, 0)
      const config = GravityConfig(
        type: GravityType.point,
        strength: 1.0,
        center: const Offset(200, 100),
      );

      updater.updateParticles([particle], bounds, gravity: config);
      expect(particle.velocity.dx, closeTo(0.25, 0.001));
      expect(particle.position.dx, closeTo(100.25, 0.001));
    });

    test('Point gravity repulsion with negative strength', () {
      const config = GravityConfig(
        type: GravityType.point,
        strength: -1.0,
        center: const Offset(200, 100),
      );

      updater.updateParticles([particle], bounds, gravity: config);
      expect(particle.velocity.dx, closeTo(-0.25, 0.001));
    });

    test('None gravity type applies no force', () {
      const config = GravityConfig(type: GravityType.none, strength: 10.0);
      updater.updateParticles([particle], bounds, gravity: config);
      expect(particle.velocity, Offset.zero);
      expect(particle.position, const Offset(100, 100));
    });
  });
}
