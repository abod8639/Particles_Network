/// Interfaces and configuration for particle systems.
///
/// This library defines the core abstractions ([IParticleFactory], [IParticleController])
/// and configuration objects ([GravityConfig]) used by the system.
library ip_article;

import 'dart:ui';

import 'package:particles_network/model/particlemodel.dart';

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

/// Enum to define different types of gravity effects.
enum GravityType {
  /// No gravity effect applied.
  none,

  /// Constant force applied to all particles in a specific direction.
  global,

  /// Force directed towards or away from a specific center point.
  point
}

/// Configuration class for gravity effects.
class GravityConfig {
  /// The type of gravity effect to apply.
  final GravityType type;

  /// The intensity of the gravity force.
  final double strength;

  /// The direction vector for [GravityType.global].
  final Offset direction;

  /// The center point coordinates for [GravityType.point].
  final Offset center;

  /// Creates a [GravityConfig] with the specified parameters.
  const GravityConfig({
    this.type = GravityType.none,
    this.strength = 0.5,
    this.direction = const Offset(0, 1), // Default: down
    this.center = Offset.zero,
  });
}

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

// Default particle controller implementing basic Euler integration physics with gravity support
class ParticleUpdater implements IParticleController {
  @override
  void updateParticles(
    List<Particle> particles,
    Size bounds, {
    GravityConfig gravity = const GravityConfig(),
  }) {
    // Process each particle
    for (final Particle p in particles) {
      _applyGravity(p, gravity);
      p.update(bounds);
    }
  }

  void _applyGravity(Particle p, GravityConfig config) {
    if (config.type == GravityType.none || config.strength == 0) return;

    if (config.type == GravityType.global) {
      // Global gravity: constant force in a fixed direction
      p.applyForce(config.direction * config.strength);
    } else if (config.type == GravityType.point) {
      // Point gravity: force directed towards a specific center point
      final Offset delta = config.center - p.position;
      final double distance = delta.distance;

      if (distance > 0) {
        // Normalizing and applying strength
        // Note: Could use inverse-square law for more realism, but linear is often "feel" better for UI
        final Offset force = (delta / distance) * config.strength;
        p.applyForce(force);
      }
    }
  }
}
