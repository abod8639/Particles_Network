/// Configuration class for touch interaction behavior and physics.
library;

import 'package:flutter/widgets.dart';

/// Configuration class for touch, mouse hover, and drag interaction physics.
///
/// Encapsulates all physics rules, velocity limits, and visual styling for user interactions.
/// When enabled, touching or hovering over the canvas creates an interactive gravitational
/// field that draws nearby particles toward the pointer, connects them with glowing lines,
/// and settles them smoothly back to cruising speed upon release.
///
/// Physics Model:
/// * **Proximity Pull**: Particles within [lineDistance] experience an attraction force
///   proportional to [force] with smooth distance falloff.
/// * **Fluid Resistance**: Velocities are softened by [damping] per frame to prevent jitter.
/// * **Speed Clamping**: Peak particle velocity is capped at [maxTouchSpeed] to prevent runaway acceleration.
/// * **Decay & Settling**: Once the touch is released, particles smoothly decelerate back
///   to their natural speed using [speed].
///
/// Example:
/// ```dart
/// // Strong magnetic drag effect:
/// const touch = TouchFeatures(
///   enabled: true,
///   force: 0.85,
///   speed: 0.50,
///   maxTouchSpeed: 7.0,
///   damping: 0.970,
///   lineDistance: 180.0,
///   color: Color(0xFFF43F5E), // Rose red
/// );
/// ```
class TouchFeatures {
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
  /// strongest at the center and tapering off smoothly at [lineDistance].
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
  final double maxTouchSpeed;

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
  /// If `null`, automatically defaults to the general `lineDistance` configured on the network widget.
  ///
  /// Defaults to `null`.
  final double? lineDistance;

  /// The highlight color for touch connections and particle proximity lines.
  ///
  /// Connection lines fade smoothly from full opacity near the touch point to transparent
  /// at the outer edge of [lineDistance].
  ///
  /// Defaults to `const Color(0xFFFFC107)` (amber).
  final Color color;

  /// Creates a [TouchFeatures] configuration with customizable physics and styling parameters.
  ///
  /// Parameters:
  /// * [enabled]: Whether touch interaction is active. Defaults to `true`.
  /// * [speed]: Recovery velocity deceleration rate after release. Defaults to `0.42`.
  /// * [force]: Attraction pull intensity. Defaults to `0.42`.
  /// * [maxTouchSpeed]: Velocity ceiling during touch. Defaults to `5.5`.
  /// * [damping]: Fluid drag factor applied inside the field. Defaults to `0.985`.
  /// * [lineDistance]: Interaction radius. Defaults to `null` (uses network `lineDistance`).
  /// * [color]: Highlight line color. Defaults to `const Color(0xFFFFC107)` (amber).
  const TouchFeatures({
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
    this.maxTouchSpeed = 5.5,

    /// Fluid damping factor applied to particles inside the touch field.
    ///
    /// Prevents excessive slingshot oscillations around the pointer.
    ///
    /// Defaults to `0.985`.
    this.damping = 0.985,

    /// Maximum connection distance and radius for touch interactions.
    ///
    /// If `null`, defaults to the network's general `lineDistance`.
    ///
    /// Defaults to `null`.
    this.lineDistance,

    /// Highlight color for touch interaction lines and effects.
    ///
    /// Defaults to `const Color(0xFFFFC107)` (amber).
    this.color = const Color(0xFFFFC107), // Colors.amber
  })  : enabled = touchActivation ?? enabled ?? true,
        speed =  decayRate ?? speed ?? 0.42,
        force = force ?? pullForce ?? 0.42;

  /// Creates a copy of this [TouchFeatures] configuration with updated parameters.
  ///
  /// Calling `copyWith` without arguments returns an identical [TouchFeatures] instance.
  TouchFeatures copyWith({
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
    double? maxTouchSpeed,

    /// Fluid damping factor applied to particles inside the touch field.
    double? damping,

    /// Maximum connection distance for touch interactions.
    double? lineDistance,

    /// Highlight color for touch interactions.
    Color? color,
  }) {
    return TouchFeatures(
      enabled: touchActivation ?? enabled ?? this.enabled,
      speed: speed ?? decayRate ?? this.speed,
      force: force ?? pullForce ?? this.force,
      maxTouchSpeed: maxTouchSpeed ?? this.maxTouchSpeed,
      damping: damping ?? this.damping,
      lineDistance: lineDistance ?? this.lineDistance,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TouchFeatures &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          speed == other.speed &&
          force == other.force &&
          maxTouchSpeed == other.maxTouchSpeed &&
          damping == other.damping &&
          lineDistance == other.lineDistance &&
          color == other.color;

  @override
  int get hashCode => Object.hash(
        enabled,
        speed,
        force,
        maxTouchSpeed,
        damping,
        lineDistance,
        color,
      );

  @override
  String toString() =>
      'TouchFeatures(enabled: $enabled, speed: $speed, force: $force, '
      'maxTouchSpeed: $maxTouchSpeed, damping: $damping, '
      'lineDistance: $lineDistance, color: $color)';
}
