/// Physics configuration for gravity effects.
library;

import 'dart:ui';

/// Enum to define different types of gravity effects.
enum GravityType {
  /// No gravity effect applied.
  none,

  /// Constant force applied to all particles in a specific direction.
  global,

  /// Force directed towards or away from a specific center point.
  point,
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
