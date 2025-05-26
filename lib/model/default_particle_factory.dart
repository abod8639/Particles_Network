import 'dart:math';

import 'package:flutter/material.dart';
import 'package:particles_network/model/ip_article.dart';
import 'package:particles_network/model/particlemodel.dart';

/// Default implementation of IParticleFactory that creates randomly configured particles
///
/// This factory generates particles with:
/// - Random positions within the specified bounds
/// - Random velocities within [-maxSpeed, maxSpeed] range
/// - Random sizes between 1 and maxSize
/// - Uniform color (configurable)
///
/// Mathematical Distributions:
/// - Position: Uniform across available space
/// - Velocity: Uniform in direction, magnitude up to maxSpeed
/// - Size: Uniform between 1 and maxSize pixels
class DefaultParticleFactory implements IParticleFactory {
  final Random random; // Random number generator instance
  final double maxSpeed; // Maximum velocity magnitude (pixels/frame)
  final double maxSize; // Maximum particle radius (pixels)
  final Color color; // Base color for all particles

  /// Creates a particle factory with specified randomization parameters
  ///
  /// [random] - Shared Random instance for reproducible results
  /// [maxSpeed] - Maximum speed (velocity magnitude) in any direction
  /// [maxSize] - Maximum particle size (minimum size is always 1)
  /// [color] - Base color for generated particles
  DefaultParticleFactory({
    required this.random,
    required this.maxSpeed,
    required this.maxSize,
    required this.color,
  });

  @override
  Particle createParticle(Size size) {
    // Generate random velocity vector components:
    // (random.nextDouble() - 0.5) creates values in [-0.5, 0.5]
    // Multiplying by 2*maxSpeed gives range [-maxSpeed, maxSpeed]
    final Offset velocity = Offset(
      (random.nextDouble() - 0.5) * maxSpeed,
      (random.nextDouble() - 0.5) * maxSpeed,
    );

    // Create and return new particle with randomized properties
    return Particle(
      color: color,
      // Random position within bounds (0 to size.width/height)
      position: Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      ),
      velocity: velocity,
      // Random size between 1 and maxSize (avoiding 0-sized particles)
      size: random.nextDouble() * maxSize + 1,
    );
  }
}
