/// Physics configuration for gravity effects in particle network visualizations.
library;

import 'dart:ui';

/// Enum defining the gravitational physics models available for the particle network.
enum GravityType {
  /// Disables gravity simulation.
  ///
  /// Particles move freely according to their initial velocity and Brownian motion
  /// without experiencing external gravitational forces.
  none,

  /// Applies a constant, uniform directional gravitational force across the entire canvas.
  ///
  /// All particles accelerate along the vector specified by [GravityFeatures.direction]
  /// (e.g., simulating natural downward gravity, snowfall, or horizontal wind drift).
  global,

  /// Applies a radial, distance-dependent gravitational force centered on a specific point.
  ///
  /// Forces emanate from or pull toward [GravityFeatures.center] (e.g., simulating
  /// black holes, orbital vortexes, magnets, or radial explosive repulsion).
  point,
}

/// Configuration class for gravity effects applied to particles.
///
/// Supports three modes through [GravityType]:
/// * [GravityType.none]: Particles drift freely with zero gravity.
/// * [GravityType.global]: Constant directional pull across the entire canvas via [direction].
/// * [GravityType.point]: Radial attraction or repulsion around a focal [center] point.
///
/// Positive [strength] values accelerate particles in the designated direction or pull
/// them toward the focal center. Negative [strength] values invert the force (e.g., creating
/// an anti-gravity or repulsive field).
///
/// Example:
/// ```dart
/// // Directional gravity (falling downward like rain):
/// const gravity = GravityFeatures.global(
///   strength: 0.15,
///   direction: Offset(0, 1),
/// );
///
/// // Point-based vortex (pulling inward toward the center):
/// const blackHole = GravityFeatures.point(
///   strength: 0.50,
/// );
/// ```
class GravityFeatures {
  /// The gravitational physics model to apply.
  ///
  /// * [GravityType.none]: Disables gravity entirely.
  /// * [GravityType.global]: Uniform directional force across the whole canvas.
  /// * [GravityType.point]: Radial force radiating toward or away from [center].
  ///
  /// Defaults to [GravityType.none].
  final GravityType type;

  /// The magnitude or intensity of the gravitational acceleration force.
  ///
  /// * In [GravityType.global] mode: scales the acceleration vector applied along [direction].
  /// * In [GravityType.point] mode: positive values attract particles inward toward [center]
  ///   (black hole / vortex effect), while negative values repel particles outward away from [center]
  ///   (anti-gravity / explosion shield effect).
  ///
  /// Defaults to `0.1`.
  final double strength;

  /// The directional acceleration vector used when [type] is [GravityType.global].
  ///
  /// Determines the orientation of the uniform gravity field across the canvas:
  /// * `Offset(0, 1)` pulls particles downwards (natural Earth gravity).
  /// * `Offset(0, -1)` pulls particles upwards (rising smoke or helium).
  /// * `Offset(1, 0)` pulls particles toward the right (horizontal wind).
  /// * `Offset(-1, 0)` pulls particles toward the left.
  ///
  /// This property is ignored when [type] is [GravityType.point] or [GravityType.none].
  ///
  /// Defaults to `const Offset(0, 1)` (downward).
  final Offset direction;

  /// The focal coordinates `(x, y)` on the canvas used when [type] is [GravityType.point].
  ///
  /// Particles accelerate radially toward this point when [strength] is positive,
  /// or radially away from this point when [strength] is negative.
  ///
  /// If `null`, the particle system automatically defaults to the center of the canvas
  /// (`size.center(Offset.zero)`).
  ///
  /// This property is ignored when [type] is [GravityType.global] or [GravityType.none].
  ///
  /// Defaults to `null` (canvas center).
  final Offset? center;

  /// Creates a [GravityFeatures] configuration with customizable parameters.
  ///
  /// Parameters:
  /// * [type]: Gravitational model to apply. Defaults to [GravityType.none].
  /// * [strength]: Intensity of acceleration. Defaults to `0.1`.
  /// * [direction]: Directional vector for global gravity. Defaults to `const Offset(0, 1)`.
  /// * [center]: Focal coordinates for point gravity. Defaults to `null` (canvas center).
  const GravityFeatures({
    this.type = GravityType.none,
    this.strength = 0.1,
    this.direction = const Offset(0, 1),
    this.center,
  });

  /// Creates a disabled gravity configuration (zero gravitational forces).
  ///
  /// Particles move according to their initial velocity and boundary collisions only.
  /// * Sets [type] to [GravityType.none].
  /// * Sets [strength] to `0.0`.
  /// * Sets [direction] to `const Offset(0, 1)`.
  /// * Sets [center] to `null`.
  const GravityFeatures.none()
      : type = GravityType.none,
        strength = 0.0,
        direction = const Offset(0, 1),
        center = null;

  /// Creates a global directional gravity configuration.
  ///
  /// Applies a uniform gravitational pull across the canvas along [direction].
  ///
  /// Parameters:
  /// * [strength]: Intensity of directional acceleration. Defaults to `0.1`.
  /// * [direction]: Directional vector for the uniform pull. Defaults to `const Offset(0, 1)` (downwards).
  ///
  /// Example:
  /// ```dart
  /// const rainGravity = GravityFeatures.global(
  ///   strength: 0.25,
  ///   direction: Offset(0, 1),
  /// );
  /// ```
  const GravityFeatures.global({
    this.strength = 0.1,
    this.direction = const Offset(0, 1),
  })  : type = GravityType.global,
        center = null;

  /// Creates a point-based radial gravity configuration (attraction or repulsion).
  ///
  /// Particles accelerate radially toward or away from [center].
  ///
  /// Parameters:
  /// * [strength]: Attraction intensity when positive, or repulsion intensity when negative.
  ///   Defaults to `0.1`.
  /// * [center]: Focal point coordinates `(x, y)`. If `null`, defaults to the center of the canvas.
  ///
  /// Example:
  /// ```dart
  /// // Black hole pulling particles toward screen center:
  /// const blackHole = GravityFeatures.point(
  ///   strength: 0.60,
  /// );
  ///
  /// // Repulsive force pushing particles away from a focal point:
  /// const repulsor = GravityFeatures.point(
  ///   strength: -0.40,
  ///   center: Offset(150, 150),
  /// );
  /// ```
  const GravityFeatures.point({
    this.strength = 0.1,
    this.center,
  })  : type = GravityType.point,
        direction = const Offset(0, 1);

  /// Creates a copy of this [GravityFeatures] configuration with the given fields replaced with new values.
  GravityFeatures copyWith({
    GravityType? type,
    double? strength,
    Offset? direction,
    Offset? center,
  }) {
    return GravityFeatures(
      type: type ?? this.type,
      strength: strength ?? this.strength,
      direction: direction ?? this.direction,
      center: center ?? this.center,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GravityFeatures &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          strength == other.strength &&
          direction == other.direction &&
          center == other.center;

  @override
  int get hashCode => Object.hash(type, strength, direction, center);

  @override
  String toString() =>
      'GravityFeatures(type: $type, strength: $strength, direction: $direction, center: $center)';
}
