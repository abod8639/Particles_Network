/// Manages the particle system simulation independently from Flutter's widget tree.
library;

import 'dart:math';
import 'dart:ui';

import 'package:particles_network/src/core/particle.dart';
import 'package:particles_network/src/factory/default_particle_factory.dart';
import 'package:particles_network/src/factory/particle_factory.dart';
import 'package:particles_network/src/physics/gravity_config.dart';
import 'package:particles_network/src/physics/particle_controller.dart';
import 'package:particles_network/src/physics/particle_updater.dart';

/// Independent simulation controller managing the particles lifecycle and physics updates.
class ParticleSimulation {
  /// The active particles in the simulation.
  final List<Particle> particles = [];

  /// The particle factory used to generate new particles.
  IParticleFactory factory;

  /// The physics controller responsible for updating positions/velocities.
  final IParticleController controller;

  /// Total particle count requested.
  int particleCount;

  /// Current container bounds.
  Size currentSize = Size.zero;

  /// Cached gravity configuration.
  GravityConfig gravityConfig;

  /// Creates a [ParticleSimulation].
  ParticleSimulation({
    required this.particleCount,
    IParticleFactory? factory,
    IParticleController? controller,
    this.gravityConfig = const GravityConfig(),
    double maxSpeed = 0.5,
    double maxSize = 1.5,
    Color particleColor = const Color(0xFFFFFFFF),
  })  : factory = factory ??
            DefaultParticleFactory(
              random: Random(),
              maxSpeed: maxSpeed,
              maxSize: maxSize,
              color: particleColor,
            ),
        controller = controller ?? ParticleUpdater();

  /// Advances the simulation by one frame with zero allocations.
  void step() {
    if (particles.isEmpty || currentSize.width <= 0 || currentSize.height <= 0) {
      return;
    }
    controller.updateParticles(
      particles,
      currentSize,
      gravity: gravityConfig,
    );
  }

  /// Updates viewport dimensions and handles particle generation or resizing.
  void updateSize(Size size) {
    if (size == currentSize) return;
    currentSize = size;
    particles.clear();

    if (size.width > 0 && size.height > 0) {
      for (int i = 0; i < particleCount; i++) {
        particles.add(factory.createParticle(size));
      }
    }
  }

  /// Updates the target particle count, adding or removing particles as needed.
  void updateParticleCount(int count) {
    if (count == particleCount) return;
    particleCount = count;

    if (currentSize.width > 0 && currentSize.height > 0) {
      if (particles.length < count) {
        final int toAdd = count - particles.length;
        for (int i = 0; i < toAdd; i++) {
          particles.add(factory.createParticle(currentSize));
        }
      } else if (particles.length > count) {
        particles.removeRange(count, particles.length);
      }
    }
  }

  /// Updates the gravity configuration.
  void updateGravity(GravityConfig config) {
    gravityConfig = config;
  }

  /// Updates the particle factory configuration.
  void updateFactory({
    required double maxSpeed,
    required double maxSize,
    required Color color,
  }) {
    factory = DefaultParticleFactory(
      random: Random(),
      maxSpeed: maxSpeed,
      maxSize: maxSize,
      color: color,
    );
  }

  /// Clears all particles and resets the simulation.
  void clear() {
    particles.clear();
    currentSize = Size.zero;
  }
}
