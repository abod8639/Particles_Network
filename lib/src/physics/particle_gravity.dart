/// Physics configuration for gravity effects in particle network visualizations.
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

/// Configuration class for gravity effects applied to particles.
///
/// Gravity can be disabled ([GravityType.none]), directional across the canvas
/// ([GravityType.global]), or radial towards/away from a specific point
/// ([GravityType.point]).
class ParticleGravity {
  /// The type of gravity effect to apply.
  final GravityType type;

  /// The intensity of the gravity force.
  final double strength;

  /// The direction vector for [GravityType.global].
  final Offset direction;

  /// The center point coordinates for [GravityType.point].
  ///
  /// If `null` when used with `ParticleNetwork`, defaults to the center of the canvas.
  final Offset? center;

  /// Compatibility alias for [type].
  GravityType get gravityType => type;

  /// Compatibility alias for [strength].
  double get gravityStrength => strength;

  /// Compatibility alias for [direction].
  Offset get gravityDirection => direction;

  /// Compatibility alias for [center].
  Offset? get gravityCenter => center;

  /// Creates a [ParticleGravity] configuration.
  ///
  /// Supports both standard property names ([type], [strength], [direction], [center])
  /// and explicit property names ([gravityType], [gravityStrength], [gravityDirection], [gravityCenter]).
  const ParticleGravity({
    GravityType? type,
    GravityType? gravityType,
    double? strength,
    double? gravityStrength,
    Offset? direction,
    Offset? gravityDirection,
    Offset? center,
    Offset? gravityCenter,
  })  : type = gravityType ?? type ?? GravityType.none,
        strength = gravityStrength ?? strength ?? 0.1,
        direction = gravityDirection ?? direction ?? const Offset(0, 1),
        center = gravityCenter ?? center;

  /// Creates a disabled gravity configuration (no gravity effect).
  const ParticleGravity.none()
      : type = GravityType.none,
        strength = 0.0,
        direction = const Offset(0, 1),
        center = null;

  /// Creates a global directional gravity configuration.
  const ParticleGravity.global({
    this.strength = 0.1,
    this.direction = const Offset(0, 1),
  })  : type = GravityType.global,
        center = null;

  /// Creates a point-based gravity configuration (attraction or repulsion).
  const ParticleGravity.point({
    this.strength = 0.1,
    this.center,
  })  : type = GravityType.point,
        direction = const Offset(0, 1);

  /// Creates a copy of this [ParticleGravity] with updated fields.
  ParticleGravity copyWith({
    GravityType? type,
    double? strength,
    Offset? direction,
    Offset? center,
  }) {
    return ParticleGravity(
      type: type ?? this.type,
      strength: strength ?? this.strength,
      direction: direction ?? this.direction,
      center: center ?? this.center,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParticleGravity &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          strength == other.strength &&
          direction == other.direction &&
          center == other.center;

  @override
  int get hashCode => Object.hash(type, strength, direction, center);

  @override
  String toString() =>
      'ParticleGravity(type: $type, strength: $strength, direction: $direction, center: $center)';
}
