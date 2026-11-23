/// Configuration class for touch interaction behavior and physics.
library;

import 'package:flutter/widgets.dart';

/// Defines the physics interaction mode of particles with the touch or mouse pointer.
enum TouchType {
  /// Particles are attracted toward the pointer location (gravity well effect).
  pull,

  /// Particles are repelled and pushed away from the pointer location (forcefield / scatter effect).
  push,
}

/// Configuration class for touch, mouse hover, and drag interaction physics.
///
/// Encapsulates all physics rules, velocity limits, and visual styling for user interactions.
/// When enabled, touching or hovering over the canvas creates an interactive field
/// that influences nearby particles ([TouchType.push] repels or [TouchType.pull] attracts),
/// connects them with glowing lines, and settles them smoothly back to cruising speed upon release.
///
/// Physics Model:
/// * **Proximity Interaction**: Particles within [distance] experience an attraction or repulsion
///   force ([TouchType.push] or [TouchType.pull]) proportional to [force] with smooth distance falloff.
/// * **Fluid Resistance**: Velocities are softened by [damping] per frame to prevent jitter.
/// * **Speed Clamping**: Peak particle velocity is capped at [maxSpeed] to prevent runaway acceleration.
/// * **Decay & Settling**: Once the touch is released, particles smoothly decelerate back
///   to their natural speed using [speed].
///
/// Example:
/// ```dart
/// // Strong repulsive scatter effect:
/// const touch = TouchFeatures(
///   type: TouchType.push,
///   enabled: true,
///   force: 0.85,
///   speed: 0.50,
///   maxSpeed: 7.0,
///   damping: 0.970,
///   distance: 180.0,
///   color: Color(0xFFF43F5E), // Rose red
/// );
/// ```
class TouchFeatures {
  /// The interaction physics mode applied to particles near the touch or mouse cursor.
  ///
  /// * [TouchType.pull]: Attracts particles toward the pointer location.
  /// * [TouchType.push]: Repels and pushes particles away from the pointer location.
  ///
  /// Defaults to [TouchType.push].
  final TouchType type;

  /// Whether touch interactions and mouse hover effects are enabled.
  ///
  /// When `true`, touching, dragging, or hovering draws nearby particles toward
  /// the pointer and renders connecting lines in [color].
  /// When `false`, user interactions are completely ignored and particles continue
  /// their natural trajectories without disturbance.
  ///
  /// Defaults to `true`.
  final bool enabled;

  /// Compatibility alias for [enabled].
  ///
  /// Deprecated: Renamed to [enabled] inside [TouchFeatures]. Use [enabled] instead.
  /// This property will be removed in particles_network 2.0.0.
  @Deprecated(
    'touchActivation was renamed to enabled inside TouchFeatures. '
    'Use TouchFeatures.enabled instead. '
    'This property will be removed in particles_network 2.0.0.',
  )
  bool get touchActivation => enabled;

  /// The recovery and settling speed of particles after touch interaction ends.
  ///
  /// Governs how rapidly an accelerated particle bleeds off excess velocity and returns
  /// to its base cruising speed once the pointer is lifted or the particle exits the touch field.
  /// Higher values result in snappier stabilization, while lower values produce a longer,
  /// floating glide.
  ///
  /// Defaults to `0.42`.
  final double speed;

  /// Compatibility alias for [speed] (decay rate).
  ///
  /// Deprecated: Renamed to [speed] inside [TouchFeatures]. Use [speed] instead.
  /// This property will be removed in particles_network 2.0.0.
  @Deprecated(
    'decayRate was renamed to speed inside TouchFeatures. '
    'Use TouchFeatures.speed instead. '
    'This property will be removed in particles_network 2.0.0.',
  )
  double get decayRate => speed;

  /// The gravitational attraction pull force directed toward the touch point.
  ///
  /// Dictates the acceleration intensity pulling nearby particles toward the cursor
  /// or touch location. The force scales linearly with distance, pulling particles
  /// strongest at the center and tapering off smoothly at [distance].
  ///
  /// Defaults to `0.42`.
  final double force;

  /// Compatibility alias for [force] (pull force).
  ///
  /// Deprecated: Renamed to [force] inside [TouchFeatures]. Use [force] instead.
  /// This property will be removed in particles_network 2.0.0.
  @Deprecated(
    'pullForce was renamed to force inside TouchFeatures. '
    'Use TouchFeatures.force instead. '
    'This property will be removed in particles_network 2.0.0.',
  )
  double get pullForce => force;

  /// The maximum velocity cap for particles while influenced by touch interaction.
  ///
  /// Clamps the peak velocity vector to prevent particles from shooting violently
  /// across the screen or tunneling through boundaries during rapid gestures or drags.
  ///
  /// Defaults to `5.5`.
  final double maxSpeed;

  /// Compatibility alias for [maxSpeed].
  ///
  /// Deprecated: Renamed to [maxSpeed] inside [TouchFeatures]. Use [maxSpeed] instead.
  /// This property will be removed in particles_network 2.0.0.
  @Deprecated(
    'maxTouchSpeed was renamed to maxSpeed inside TouchFeatures. '
    'Use TouchFeatures.maxSpeed instead. '
    'This property will be removed in particles_network 2.0.0.',
  )
  double get maxTouchSpeed => maxSpeed;

  /// The fluid damping factor applied to particles inside the touch interaction field.
  ///
  /// Acting as aerodynamic drag or fluid viscosity, this factor (typically between `0.90` and `0.99`)
  /// dampens particle velocity each frame, preventing excessive slingshot oscillations
  /// around the touch point.
  ///
  /// Defaults to `0.985`.
  final double damping;

  /// The maximum connection distance and effective radius for touch interactions.
  ///
  /// Only particles within this radius from the pointer experience gravitational pull
  /// and receive connecting lines.
  ///
  /// If `null`, automatically defaults to the general `distance` configured on the network widget.
  ///
  /// Defaults to `null`.
  final double? distance;

  /// Compatibility alias for [distance].
  ///
  /// Deprecated: Renamed to [distance] inside [TouchFeatures]. Use [distance] instead.
  /// This property will be removed in particles_network 2.0.0.
  @Deprecated(
    'lineDistance was renamed to distance inside TouchFeatures. '
    'Use TouchFeatures.distance instead. '
    'This property will be removed in particles_network 2.0.0.',
  )
  double? get lineDistance => distance;

  /// The highlight color for touch connections and particle proximity lines.
  ///
  /// Connection lines fade smoothly from full opacity near the touch point to transparent
  /// at the outer edge of [distance].
  ///
  /// Defaults to `const Color(0xFFFFC107)` (amber).
  final Color color;

  /// Whether mouse cursor movement triggers interactive proximity effects on web and desktop.
  ///
  /// When `true`, moving the mouse cursor over the canvas attracts nearby particles
  /// and renders connecting lines without requiring a pointer press or drag gesture.
  /// When `false`, interaction requires a pointer down / press gesture.
  ///
  /// Defaults to `false`.
  final bool hover;

  /// Creates a [TouchFeatures] configuration with customizable physics and styling parameters.
  ///
  /// Parameters:
  /// * [type]: Physics interaction mode ([TouchType.push] or [TouchType.pull]). Defaults to [TouchType.push].
  /// * [enabled]: Whether touch interaction is active. Defaults to `true`.
  /// * [speed]: Recovery velocity deceleration rate after release. Defaults to `0.42`.
  /// * [force]: Attraction pull intensity. Defaults to `0.42`.
  /// * [maxSpeed]: Velocity ceiling during touch. Defaults to `5.5`.
  /// * [damping]: Fluid drag factor applied inside the field. Defaults to `0.985`.
  /// * [distance]: Interaction radius. Defaults to `null` (uses network `distance`).
  /// * [color]: Highlight line color. Defaults to `const Color(0xFFFFC107)` (amber).
  /// * [hover]: Whether mouse hover triggers interactive proximity effects on web and desktop. Defaults to `false`.
  const TouchFeatures({
    /// Physics interaction mode ([TouchType.push] repels or [TouchType.pull] attracts).
    ///
    /// Defaults to [TouchType.push].
    this.type = TouchType.push,

    /// Whether touch interactions and proximity effects are enabled.
    ///
    /// When `true`, touching, dragging, or hovering draws nearby particles toward
    /// the pointer and renders connecting lines in [color].
    ///
    /// Defaults to `true`.
    bool? enabled,

    /// Compatibility alias for [enabled].
    ///
    /// Defaults to `true`.
    @Deprecated(
      'touchActivation was renamed to enabled inside TouchFeatures. '
      'Use TouchFeatures(enabled: ...) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    bool? touchActivation,

    /// The recovery and settling speed after touch release.
    ///
    /// Controls how rapidly particles return to cruising speed after being dragged or touched.
    ///
    /// Defaults to `0.42`.
    double? speed,

    /// Compatibility alias for [speed] (decay rate).
    ///
    /// Defaults to `0.42`.
    @Deprecated(
      'decayRate was renamed to speed inside TouchFeatures. '
      'Use TouchFeatures(speed: ...) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    double? decayRate,

    /// Attraction pull force towards the touch point.
    ///
    /// Controls the gravitational pulling intensity drawing particles toward the touch location.
    ///
    /// Defaults to `0.42`.
    double? force,

    /// Compatibility alias for [force] (pull force).
    ///
    /// Defaults to `0.42`.
    @Deprecated(
      'pullForce was renamed to force inside TouchFeatures. '
      'Use TouchFeatures(force: ...) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    double? pullForce,

    /// Maximum velocity cap for particles during touch interaction.
    ///
    /// Clamps peak particle speed to prevent runaway acceleration during rapid gestures.
    ///
    /// Defaults to `5.5`.
    double? maxSpeed,

    /// Compatibility alias for [maxSpeed].
    ///
    /// Defaults to `5.5`.
    @Deprecated(
      'maxTouchSpeed was renamed to maxSpeed inside TouchFeatures. '
      'Use TouchFeatures(maxSpeed: ...) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    double? maxTouchSpeed,

    /// Fluid damping factor applied to particles inside the touch field.
    ///
    /// Prevents excessive slingshot oscillations around the pointer.
    ///
    /// Defaults to `0.985`.
    this.damping = 0.985,

    /// Maximum connection distance and radius for touch interactions.
    ///
    /// If `null`, defaults to the network's general `distance`.
    ///
    /// Defaults to `null`.
    double? distance,

    /// Compatibility alias for [distance].
    ///
    /// Defaults to `null`.
    @Deprecated(
      'lineDistance was renamed to distance inside TouchFeatures. '
      'Use TouchFeatures(distance: ...) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    double? lineDistance,

    /// Highlight color for touch interaction lines and effects.
    ///
    /// Defaults to `const Color(0xFFFFC107)` (amber).
    this.color = const Color(0xFFFFC107), // Colors.amber
    this.hover = false,
  })  : enabled = touchActivation ?? enabled ?? true,
        speed =  decayRate ?? speed ?? 0.42,
        force = force ?? pullForce ?? 0.42,
        maxSpeed = maxSpeed ?? maxTouchSpeed ?? 5.5,
        distance = distance ?? lineDistance;

  /// Creates a copy of this [TouchFeatures] configuration with updated parameters.
  ///
  /// Calling `copyWith` without arguments returns an identical [TouchFeatures] instance.
  TouchFeatures copyWith({
    /// Physics interaction mode ([TouchType.push] repels or [TouchType.pull] attracts).
    TouchType? type,

    /// Whether touch interactions and proximity effects are enabled.
    bool? enabled,

    /// Compatibility alias for [enabled].
    @Deprecated(
      'touchActivation was renamed to enabled inside TouchFeatures. '
      'Use TouchFeatures.copyWith(enabled: ...) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    bool? touchActivation,

    /// The recovery and settling speed after touch release.
    double? speed,

    /// Compatibility alias for [speed] (decay rate).
    @Deprecated(
      'decayRate was renamed to speed inside TouchFeatures. '
      'Use TouchFeatures.copyWith(speed: ...) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    double? decayRate,

    /// Attraction pull force towards the touch point.
    double? force,

    /// Compatibility alias for [force] (pull force).
    @Deprecated(
      'pullForce was renamed to force inside TouchFeatures. '
      'Use TouchFeatures.copyWith(force: ...) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    double? pullForce,

    /// Maximum velocity cap for particles during touch interaction.
    double? maxSpeed,

    /// Compatibility alias for [maxSpeed].
    @Deprecated(
      'maxTouchSpeed was renamed to maxSpeed inside TouchFeatures. '
      'Use TouchFeatures.copyWith(maxSpeed: ...) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    double? maxTouchSpeed,

    /// Fluid damping factor applied to particles inside the touch field.
    double? damping,

    /// Maximum connection distance for touch interactions.
    double? distance,

    /// Compatibility alias for [distance].
    @Deprecated(
      'lineDistance was renamed to distance inside TouchFeatures. '
      'Use TouchFeatures.copyWith(distance: ...) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    double? lineDistance,

    /// Highlight color for touch interactions.
    Color? color,

    /// Whether mouse hover triggers interactive proximity effects on web and desktop.
    bool? hover,
  }) {
    return TouchFeatures(
      type: type ?? this.type,
      enabled: touchActivation ?? enabled ?? this.enabled,
      speed: speed ?? decayRate ?? this.speed,
      force: force ?? pullForce ?? this.force,
      maxSpeed: maxSpeed ?? maxTouchSpeed ?? this.maxSpeed,
      damping: damping ?? this.damping,
      distance: distance ?? lineDistance ?? this.distance,
      color: color ?? this.color,
      hover: hover ?? this.hover,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TouchFeatures &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          enabled == other.enabled &&
          speed == other.speed &&
          force == other.force &&
          maxSpeed == other.maxSpeed &&
          damping == other.damping &&
          distance == other.distance &&
          color == other.color &&
          hover == other.hover;

  @override
  int get hashCode => Object.hash(
        type,
        enabled,
        speed,
        force,
        maxSpeed,
        damping,
        distance,
        color,
        hover,
      );

  @override
  String toString() =>
      'TouchFeatures(type: $type, enabled: $enabled, speed: $speed, force: $force, '
      'maxSpeed: $maxSpeed, damping: $damping, '
      'distance: $distance, color: $color, hover: $hover)';
}
