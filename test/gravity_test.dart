import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/particles_network.dart';

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
        direction: Offset(0, 1), // Down
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
        center: Offset(200, 100),
      );

      updater.updateParticles([particle], bounds, gravity: config);
      expect(particle.velocity.dx, closeTo(0.25, 0.001));
      expect(particle.position.dx, closeTo(100.25, 0.001));
    });

    test('Point gravity repulsion with negative strength', () {
      const config = GravityConfig(
        type: GravityType.point,
        strength: -1.0,
        center: Offset(200, 100),
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

    test('ParticleGravity applies global force correctly', () {
      const gravity = ParticleGravity.global(
        strength: 1.0,
        direction: Offset(0, 1),
      );
      updater.updateParticles([particle], bounds, gravity: gravity);
      expect(particle.velocity.dy, closeTo(0.25, 0.001));
      expect(particle.position.dy, closeTo(100.25, 0.001));
    });

    test('ParticleGravity applies point attraction correctly', () {
      const gravity = ParticleGravity.point(
        strength: 1.0,
        center: Offset(200, 100),
      );
      updater.updateParticles([particle], bounds, gravity: gravity);
      expect(particle.velocity.dx, closeTo(0.25, 0.001));
      expect(particle.position.dx, closeTo(100.25, 0.001));
    });
  });

  group('ParticleGravity API Unit Tests', () {
    test('Default constructor sets expected defaults', () {
      const gravity = ParticleGravity();
      expect(gravity.type, GravityType.none);
      expect(gravity.gravityType, GravityType.none);
      expect(gravity.strength, 0.1);
      expect(gravity.gravityStrength, 0.1);
      expect(gravity.direction, const Offset(0, 1));
      expect(gravity.gravityDirection, const Offset(0, 1));
      expect(gravity.center, isNull);
      expect(gravity.gravityCenter, isNull);
    });

    test('Accepts explicit gravityType, gravityStrength, etc. parameters', () {
      const gravity = ParticleGravity(
        gravityType: GravityType.point,
        gravityStrength: 0.8,
        gravityDirection: Offset(1, 0),
        gravityCenter: Offset(150, 150),
      );
      expect(gravity.type, GravityType.point);
      expect(gravity.gravityType, GravityType.point);
      expect(gravity.strength, 0.8);
      expect(gravity.gravityStrength, 0.8);
      expect(gravity.direction, const Offset(1, 0));
      expect(gravity.gravityDirection, const Offset(1, 0));
      expect(gravity.center, const Offset(150, 150));
      expect(gravity.gravityCenter, const Offset(150, 150));
    });

    test('Named constructors create proper instances', () {
      const none = ParticleGravity.none();
      expect(none.type, GravityType.none);
      expect(none.strength, 0.0);

      const global = ParticleGravity.global(
        strength: 0.5,
        direction: Offset(0, -1),
      );
      expect(global.type, GravityType.global);
      expect(global.strength, 0.5);
      expect(global.direction, const Offset(0, -1));

      const point = ParticleGravity.point(
        strength: 0.7,
        center: Offset(50, 50),
      );
      expect(point.type, GravityType.point);
      expect(point.strength, 0.7);
      expect(point.center, const Offset(50, 50));
    });

    test('copyWith creates modified copy', () {
      const initial = ParticleGravity(type: GravityType.none, strength: 0.2);
      final updated = initial.copyWith(
        type: GravityType.global,
        strength: 0.9,
        center: const Offset(10, 10),
      );
      expect(updated.type, GravityType.global);
      expect(updated.strength, 0.9);
      expect(updated.direction, const Offset(0, 1));
      expect(updated.center, const Offset(10, 10));
    });

    test('Equality, hashCode, and toString work as expected', () {
      const g1 = ParticleGravity(
        type: GravityType.global,
        strength: 0.5,
        direction: Offset(0, 1),
      );
      const g2 = ParticleGravity(
        gravityType: GravityType.global,
        gravityStrength: 0.5,
        gravityDirection: Offset(0, 1),
      );
      const g3 = ParticleGravity(
        type: GravityType.point,
        strength: 0.5,
      );

      expect(g1, equals(g2));
      expect(g1.hashCode, equals(g2.hashCode));
      expect(g1, isNot(equals(g3)));
      expect(g1.toString(), contains('ParticleGravity('));
    });
  });
}
