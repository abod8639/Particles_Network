/// Particle controller interface for behavior and physics.
library;

import 'dart:ui';

import 'package:particles_network/src/core/particle.dart';
import 'package:particles_network/src/physics/gravity_config.dart';

/// Abstract interface for controlling particle behavior and physics.
///
/// This enables different physics models to be applied to the particle
/// system while maintaining consistent update behavior.
abstract class IParticleController {
  /// Updates all particles' state based on the current simulation frame.
  ///
  /// [particles] - List of all active particles.
  /// [bounds] - Current container size for boundary checking.
  /// [gravity] - Optional gravity configuration.
  void updateParticles(
    List<Particle> particles,
    Size bounds, {
    GravityConfig gravity = const GravityConfig(),
  });
}
