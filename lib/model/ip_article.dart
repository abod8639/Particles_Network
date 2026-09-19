/// Interfaces and configuration for particle systems.
///
/// This library defines the core abstractions ([IParticleFactory], [IParticleController])
/// and configuration objects ([GravityConfig]) used by the system.
library;

import 'dart:math' as math;
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
    final bool hasGlobalGravity =
        gravity.type == GravityType.global && gravity.strength != 0;
    final double gStrength = gravity.strength;
    final double gfx =
        hasGlobalGravity ? gravity.direction.dx * gStrength : 0.0;
    final double gfy =
        hasGlobalGravity ? gravity.direction.dy * gStrength : 0.0;
    final bool isPointGravity =
        gravity.type == GravityType.point && gStrength != 0;
    final double cx = gravity.center.dx;
    final double cy = gravity.center.dy;

    final int count = particles.length;
    for (int i = 0; i < count; i++) {
      final Particle p = particles[i];
      if (hasGlobalGravity) {
        p.applyForceRaw(gfx, gfy);
      } else if (isPointGravity) {
        final double dx = cx - p.x;
        final double dy = cy - p.y;
        final double distSq = dx * dx + dy * dy;
        if (distSq > 0) {
          final double invDist = 1.0 / math.sqrt(distSq);
          p.applyForceRaw(dx * invDist * gStrength, dy * invDist * gStrength);
        }
      }
      p.update(bounds);
    }
  }
}

