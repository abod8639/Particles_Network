import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/src/core/particle.dart';
import 'package:particles_network/src/factory/default_particle_factory.dart';
import 'package:particles_network/src/physics/gravity_config.dart';
import 'package:particles_network/src/simulation/particle_simulation.dart';

void main() {
  group('ParticleSimulation Tests', () {
    test('initializes with correct particleCount and empty particles before updateSize', () {
      final sim = ParticleSimulation(particleCount: 20);

      expect(sim.particleCount, equals(20));
      expect(sim.particles, isEmpty);
      expect(sim.currentSize, equals(Size.zero));
    });

    test('updateSize generates particles matching particleCount when size > 0', () {
      final sim = ParticleSimulation(particleCount: 15);
      sim.updateSize(const Size(500, 500));

      expect(sim.particles.length, equals(15));
      expect(sim.currentSize, equals(const Size(500, 500)));
    });

    test('updateSize does not regenerate if same size is passed', () {
      final sim = ParticleSimulation(particleCount: 10);
      sim.updateSize(const Size(300, 300));
      final firstParticle = sim.particles.first;

      sim.updateSize(const Size(300, 300));
      expect(sim.particles.first, same(firstParticle));
    });

    test('updateParticleCount increases particle count when size is set', () {
      final sim = ParticleSimulation(particleCount: 5);
      sim.updateSize(const Size(400, 400));
      expect(sim.particles.length, equals(5));

      sim.updateParticleCount(12);

      expect(sim.particleCount, equals(12));
      expect(sim.particles.length, equals(12));
    });

    test('updateParticleCount decreases particle count when size is set', () {
      final sim = ParticleSimulation(particleCount: 10);
      sim.updateSize(const Size(400, 400));
      expect(sim.particles.length, equals(10));

      sim.updateParticleCount(4);

      expect(sim.particleCount, equals(4));
      expect(sim.particles.length, equals(4));
    });

    test('updateParticleCount does nothing if count is identical', () {
      final sim = ParticleSimulation(particleCount: 5);
      sim.updateSize(const Size(400, 400));

      sim.updateParticleCount(5);
      expect(sim.particleCount, equals(5));
      expect(sim.particles.length, equals(5));
    });

    test('updateParticleCount only updates count property if size is zero', () {
      final sim = ParticleSimulation(particleCount: 5);
      expect(sim.currentSize, equals(Size.zero));

      sim.updateParticleCount(15);
      expect(sim.particleCount, equals(15));
      expect(sim.particles, isEmpty);
    });

    test('updateFactory replaces particle factory', () {
      final sim = ParticleSimulation(particleCount: 5);
      sim.updateSize(const Size(200, 200));

      sim.updateFactory(
        maxSpeed: 2.0,
        maxSize: 5.0,
        color: const Color(0xFFFF0000),
      );

      expect(sim.factory, isA<DefaultParticleFactory>());
      final defaultFactory = sim.factory as DefaultParticleFactory;
      expect(defaultFactory.maxSpeed, equals(2.0));
      expect(defaultFactory.maxSize, equals(5.0));
      expect(defaultFactory.color, equals(const Color(0xFFFF0000)));
    });

    test('updateGravity updates gravityConfig', () {
      final sim = ParticleSimulation(particleCount: 5);
      const newGravity = GravityConfig(
        type: GravityType.point,
        strength: 2.5,
        center: Offset(100, 100),
      );

      sim.updateGravity(newGravity);
      expect(sim.gravityConfig, equals(newGravity));
    });

    test('step does nothing when particles empty or size is zero', () {
      final sim = ParticleSimulation(particleCount: 5);
      expect(() => sim.step(), returnsNormally);

      sim.updateSize(const Size(200, 200));
      sim.particles.clear();
      expect(() => sim.step(), returnsNormally);
    });

    test('step advances particle positions via controller when initialized', () {
      final sim = ParticleSimulation(particleCount: 5);
      sim.updateSize(const Size(500, 500));
      final initialPositions = sim.particles.map((p) => p.position).toList();

      sim.step();

      // At least some particles with non-zero velocity will have changed position
      final changed = sim.particles.where((p) {
        final original = initialPositions[sim.particles.indexOf(p)];
        return p.position != original;
      });
      expect(changed.isNotEmpty, isTrue);
    });

    test('clear resets particles list and currentSize to zero', () {
      final sim = ParticleSimulation(particleCount: 8);
      sim.updateSize(const Size(300, 300));
      expect(sim.particles.length, equals(8));
      expect(sim.currentSize, equals(const Size(300, 300)));

      sim.clear();

      expect(sim.particles, isEmpty);
      expect(sim.currentSize, equals(Size.zero));
    });
  });
}
