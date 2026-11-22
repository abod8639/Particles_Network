/// Configuration class for touch interaction behavior and physics.
library;

import 'package:flutter/widgets.dart';

/// Configuration class for touch interaction behavior and physics.
class TouchFeatures {
  /// Whether touch interactions and proximity effects are enabled.
  ///
  /// Defaults to `true`.
  final bool enabled;

  /// Compatibility alias for [enabled].
  @Deprecated(
    'touchActivation was renamed to enabled inside TouchFeatures. '
    'Use TouchFeatures.enabled instead. '
    'This property will be removed in particles_network 2.0.0.',
  )
  bool get touchActivation => enabled;

  /// The recovery/settling speed after touch release.
  ///
  /// Controls how gradually particles return to cruising speed after being dragged/touched.
  ///
  /// Defaults to `0.42`.
  final double speed;

  /// Compatibility alias for [speed] (decay rate).
  @Deprecated(
    'decayRate was renamed to speed inside TouchFeatures. '
    'Use TouchFeatures.speed instead. '
    'This property will be removed in particles_network 2.0.0.',
  )
  double get decayRate => speed;

  /// Attraction pull force towards touch point.
  ///
  /// Controls the gravitational or pulling intensity drawing particles toward the touch point.
  ///
  /// Defaults to `0.42`.
  final double force;

  /// Compatibility alias for [force] (pull force).
  @Deprecated(
    'pullForce was renamed to force inside TouchFeatures. '
    'Use TouchFeatures.force instead. '
    'This property will be removed in particles_network 2.0.0.',
  )
  double get pullForce => force;

  /// Maximum velocity cap for particles during touch interaction.
  ///
  /// Defaults to `5.5`.
  final double maxTouchSpeed;

  /// Fluid damping factor applied to particles inside the touch field.
  ///
  /// Defaults to `0.985`.
  final double damping;

  /// Maximum connection distance for touch interactions.
  ///
  /// If `null`, defaults to the network's `lineDistance`.
  final double? lineDistance;

  /// Highlight color for touch interactions.
  ///
  /// Defaults to `Color(0xFFFFC107)` (amber).
  final Color color;

  /// Creates a [TouchFeatures] configuration.
  const TouchFeatures({
    /// Whether touch interactions and proximity effects are enabled.
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

    /// The recovery/settling speed after touch release.
    ///
    /// Controls how gradually particles return to cruising speed after being dragged/touched.
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

    /// Attraction pull force towards touch point.
    ///
    /// Controls the gravitational or pulling intensity drawing particles toward the touch point.
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
    /// Defaults to `5.5`.
    this.maxTouchSpeed = 5.5,

    /// Fluid damping factor applied to particles inside the touch field.
    ///
    /// Defaults to `0.985`.
    this.damping = 0.985,

    /// Maximum connection distance for touch interactions.
    ///
    /// If `null`, defaults to the network's `lineDistance`.
    this.lineDistance,

    /// Highlight color for touch interactions.
    ///
    /// Defaults to `Color(0xFFFFC107)` (amber).
    this.color = const Color(0xFFFFC107), // Colors.amber
  })  : enabled = touchActivation ?? enabled ?? true,
        speed =  decayRate ?? speed ?? 0.42,
        force = force ?? pullForce ?? 0.42;

  /// Creates a copy of this [TouchFeatures] with updated parameters.
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

    /// The recovery/settling speed after touch release.
    ///
    /// Controls how gradually particles return to cruising speed after being dragged/touched.
    double? speed,

    /// Compatibility alias for [speed] (decay rate).
    @Deprecated(
      'decayRate was renamed to speed inside TouchFeatures. '
      'Use TouchFeatures.copyWith(speed: ...) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    double? decayRate,

    /// Attraction pull force towards touch point.
    ///
    /// Controls the gravitational or pulling intensity drawing particles toward the touch point.
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
