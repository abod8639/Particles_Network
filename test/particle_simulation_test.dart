import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/src/core/particle.dart';
import 'package:particles_network/src/factory/default_particle_factory.dart';
import 'package:particles_network/src/physics/gravity_config.dart';
import 'package:particles_network/src/physics/particle_controller.dart';
import 'package:particles_network/src/simulation/particle_simulation.dart';

class _LegacyTestController implements IParticleController {
  GravityFeatures? receivedGravity;
  int updateCallCount = 0;

  @override
  void updateParticles(
    List<Particle> particles,
    Size bounds, {
    covariant GravityFeatures gravity = const GravityFeatures(),
  }) {
    updateCallCount++;
    receivedGravity = gravity;
  }
}

void main() {
  group('ParticleSimulation Tests', () {
    test(
      'initializes with correct particleCount and empty particles before updateSize',
      () {
        final sim = ParticleSimulation(particleCount: 20);

        expect(sim.particleCount, equals(20));
        expect(sim.particles, isEmpty);
        expect(sim.currentSize, equals(Size.zero));
      },
    );

    test(
      'updateSize generates particles matching particleCount when size > 0',
      () {
        final sim = ParticleSimulation(particleCount: 15);
        sim.updateSize(const Size(500, 500));

        expect(sim.particles.length, equals(15));
        expect(sim.currentSize, equals(const Size(500, 500)));
      },
    );

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

    test(
      'updateGravity updates gravityConfig and is exposed via gravity getter',
      () {
        final sim = ParticleSimulation(particleCount: 5);
        expect(sim.gravity, equals(const GravityFeatures()));

        const newGravity = GravityConfig(
          type: GravityType.point,
          strength: 2.5,
          center: Offset(100, 100),
        );

        sim.updateGravity(newGravity);
        expect(sim.gravityConfig, equals(newGravity));
        expect(sim.gravity, equals(newGravity));
      },
    );

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

    test(
      'buildSpatialGrid clears grid and returns when particles empty or size <= 0 (L152-L153)',
      () {
        final sim = ParticleSimulation(particleCount: 5);
        // Case 1: particles empty and currentSize is zero
        sim.buildSpatialGrid();
        expect(sim.spatialGrid.count, equals(0));

        // Case 2: particles populated then cleared
        sim.updateSize(const Size(200, 200));
        expect(sim.particles.isNotEmpty, isTrue);

        sim.clear();
        sim.buildSpatialGrid();
        expect(sim.spatialGrid.count, equals(0));
      },
    );

    test(
      'step converts GravityFeatures to GravityConfig for non-timescaled controllers (L83-L84)',
      () {
        final legacyController = _LegacyTestController();

        // Case 1 (L84): gravityConfig is a canonical GravityFeatures (not GravityConfig)
        final sim = ParticleSimulation(
          particleCount: 5,
          controller: legacyController,
          gravityConfig: const GravityFeatures(
            type: GravityType.point,
            strength: 1.5,
            direction: Offset(1, 0),
            center: Offset(50, 50),
          ),
        );
        sim.updateSize(const Size(200, 200));

        sim.step(1.0);
        expect(legacyController.updateCallCount, equals(1));
        expect(legacyController.receivedGravity, isA<GravityConfig>());
        expect(
          legacyController.receivedGravity!.type,
          equals(GravityType.point),
        );
        expect(legacyController.receivedGravity!.strength, equals(1.5));
        expect(
          legacyController.receivedGravity!.direction,
          equals(const Offset(1, 0)),
        );
        expect(
          legacyController.receivedGravity!.center,
          equals(const Offset(50, 50)),
        );

        // Case 2 (L83): gravityConfig is already a GravityConfig instance
        const existingConfig = GravityConfig(
          type: GravityType.global,
          strength: 0.8,
          direction: Offset(0, 1),
        );
        sim.updateGravity(existingConfig);

        sim.step(1.0);
        expect(legacyController.updateCallCount, equals(2));
        expect(
          identical(legacyController.receivedGravity, existingConfig),
          isTrue,
        );
      },
    );
  });
}
