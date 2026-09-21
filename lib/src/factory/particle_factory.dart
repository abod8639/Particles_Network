/// Abstract factory interface for creating particle instances.
library;

import 'dart:ui';

import 'package:particles_network/src/core/particle.dart';

/// Abstract factory interface for creating particle instances.
///
/// This follows the Factory Method design pattern, allowing different
/// particle creation strategies to be implemented while maintaining
/// a consistent interface.
///
/// Implementations can control:
/// - Initial position distribution
/// - Velocity ranges
/// - Size variations
/// - Color schemes
abstract class IParticleFactory {
  /// Creates a new particle within specified bounds.
  ///
  /// [size] - The available space where particles can be placed.
  /// Returns: A new Particle instance with randomized properties.
  Particle createParticle(Size size);
}
