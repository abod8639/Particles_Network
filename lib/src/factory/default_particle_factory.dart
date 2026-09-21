/// Default implementation of [IParticleFactory] that creates randomly configured particles.
library;

import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:particles_network/src/core/particle.dart';
import 'package:particles_network/src/factory/particle_factory.dart';

/// Default implementation of IParticleFactory that creates randomly configured particles.
///
/// This factory generates particles with:
/// - Random positions within the specified bounds
/// - Random velocities within [-maxSpeed, maxSpeed] range
/// - Random sizes between 1 and maxSize
/// - Uniform color (configurable)
class DefaultParticleFactory implements IParticleFactory {
  /// Shared Random instance for reproducible results
  final Random random;

  /// Maximum velocity magnitude (pixels/frame)
  final double maxSpeed;

  /// Maximum particle radius (pixels)
  final double maxSize;

  /// Base color for all particles
  final Color color;

  /// Creates a particle factory with specified randomization parameters.
  DefaultParticleFactory({
    required this.random,
    required this.maxSpeed,
    required this.maxSize,
    required this.color,
  });

  @override
  Particle createParticle(Size size) {
    final Offset velocity = Offset(
      (random.nextDouble() - 0.5) * maxSpeed,
      (random.nextDouble() - 0.5) * maxSpeed,
    );

    return Particle(
      color: color,
      position: Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      ),
      velocity: velocity,
      size: random.nextDouble() * maxSize + 1,
    );
  }
}
