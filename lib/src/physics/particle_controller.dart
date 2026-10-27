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

/// A [IParticleController] that can advance the simulation by a fractional
/// number of 60 Hz reference frames, enabling frame-rate independent motion.
///
/// [ParticleSimulation] uses [updateParticlesScaled] when the controller
/// implements this interface, and falls back to
/// [IParticleController.updateParticles] (one reference frame per tick)
/// otherwise, so existing custom controllers keep working unchanged.
abstract class ITimeScaledParticleController implements IParticleController {
  /// Advances all particles by [timeScale] reference frames (1.0 = 1/60 s).
  void updateParticlesScaled(
    List<Particle> particles,
    Size bounds,
    double timeScale, {
    GravityConfig gravity = const GravityConfig(),
  });
}
