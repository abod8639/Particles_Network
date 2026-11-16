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
  ///
  /// Deprecated: Redundant with [type]. Use [type] instead:
  /// ```dart
  /// ParticleGravity(type: GravityType.global)
  /// ```
  /// This property will be removed in particles_network 2.0.0.
  @Deprecated(
    'gravityType inside ParticleGravity is redundant with type. '
    'Use type instead. This property will be removed in particles_network 2.0.0.',
  )
  GravityType get gravityType => type;

  /// Compatibility alias for [strength].
  ///
  /// Deprecated: Redundant with [strength]. Use [strength] instead:
  /// ```dart
  /// ParticleGravity(strength: 0.2)
  /// ```
  /// This property will be removed in particles_network 2.0.0.
  @Deprecated(
    'gravityStrength inside ParticleGravity is redundant with strength. '
    'Use strength instead. This property will be removed in particles_network 2.0.0.',
  )
  double get gravityStrength => strength;

  /// Compatibility alias for [direction].
  ///
  /// Deprecated: Redundant with [direction]. Use [direction] instead:
  /// ```dart
  /// ParticleGravity(direction: Offset(0, 1))
  /// ```
  /// This property will be removed in particles_network 2.0.0.
  @Deprecated(
    'gravityDirection inside ParticleGravity is redundant with direction. '
    'Use direction instead. This property will be removed in particles_network 2.0.0.',
  )
  Offset get gravityDirection => direction;

  /// Compatibility alias for [center].
  ///
  /// Deprecated: Redundant with [center]. Use [center] instead:
  /// ```dart
  /// ParticleGravity(center: Offset(100, 100))
  /// ```
  /// This property will be removed in particles_network 2.0.0.
  @Deprecated(
    'gravityCenter inside ParticleGravity is redundant with center. '
    'Use center instead. This property will be removed in particles_network 2.0.0.',
  )
  Offset? get gravityCenter => center;

  /// Creates a [ParticleGravity] configuration.
  ///
  /// Canonical parameters are [type], [strength], [direction], and [center].
  /// The explicit prefix parameters ([gravityType], [gravityStrength], [gravityDirection], [gravityCenter])
  /// are deprecated aliases.
  const ParticleGravity({
    GravityType? type,
    @Deprecated(
      'gravityType is redundant with type. Use type instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    GravityType? gravityType,
    double? strength,
    @Deprecated(
      'gravityStrength is redundant with strength. Use strength instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    double? gravityStrength,
    Offset? direction,
    @Deprecated(
      'gravityDirection is redundant with direction. Use direction instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    Offset? gravityDirection,
    Offset? center,
    @Deprecated(
      'gravityCenter is redundant with center. Use center instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
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
