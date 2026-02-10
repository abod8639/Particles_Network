import 'dart:ui';

import 'package:particles_network/model/particlemodel.dart';

// Abstract factory interface for creating particle instances
//
// This follows the Factory Method design pattern, allowing different
// particle creation strategies to be implemented while maintaining
// a consistent interface.
//
// Implementations can control:
// - Initial position distribution
// - Velocity ranges
// - Size variations
// - Color schemes
abstract class IParticleFactory {
  // Creates a new particle within specified bounds
  //
  // [size] - The available space where particles can be placed
  // Returns: A new Particle instance with randomized properties
  Particle createParticle(Size size);
}

// Abstract interface for controlling particle behavior and physics
//
// This enables different physics models to be applied to the particle
// system while maintaining consistent update behavior.
//
// Common implementations might include:
// - Basic Euler integration
// - Verlet integration
// - Physics with constraints
// - Special effect behaviors
// Enum to define different types of gravity effects
enum GravityType { none, global, point }

// Configuration class for gravity effects
class GravityConfig {
  final GravityType type;
  final double strength;
  final Offset direction; // For global gravity
  final Offset center; // For point gravity

  const GravityConfig({
    this.type = GravityType.none,
    this.strength = 0.5,
    this.direction = const Offset(0, 1), // Default: down
    this.center = Offset.zero,
  });
}

abstract class IParticleController {
  // Updates all particles' state based on the current simulation frame
  //
  // [particles] - List of all active particles
  // [bounds] - Current container size for boundary checking
  // [gravity] - Optional gravity configuration
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
