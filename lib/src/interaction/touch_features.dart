/// Configuration class for touch interaction behavior and physics.
library;

import 'package:flutter/material.dart';

/// Configuration class for touch interaction behavior and physics.
class TouchFeatures {
  /// Whether touch interactions and proximity effects are enabled (default: true).
  final bool enabled;

  /// Compatibility alias for [enabled].
  bool get touchActivation => enabled;

  /// The recovery/settling decay rate after touch release (default: 0.42).
  /// Controls how gradually particles return to cruising speed after being dragged/touched.
  final double speed;

  /// Attraction pull force towards touch point (default: 0.42).
  final double force;

  /// Maximum velocity cap for particles during touch interaction (default: 5.5).
  final double maxTouchSpeed;

  /// Fluid damping factor applied to particles inside the touch field (default: 0.985).
  final double damping;

  /// Maximum connection distance for touch interactions.
  /// If null, defaults to the network's lineDistance.
  final double? lineDistance;

  /// Highlight color for touch interactions (default: Colors.amber).
  final Color color;

  /// Creates a [TouchFeatures] configuration.
  const TouchFeatures({
    bool? enabled,
    bool? touchActivation,
    double? speed,
    @Deprecated(
      'Use speed instead. This parameter will be removed in particles_network 2.0.0.',
    )
    double? decayRate,
    double? force,
    @Deprecated(
      'Use force instead. This parameter will be removed in particles_network 2.0.0.',
    )
    double? pullForce,
    this.maxTouchSpeed = 5.5,
    this.damping = 0.985,
    this.lineDistance,
    this.color = Colors.amber,
  })  : enabled = touchActivation ?? enabled ?? true,
        speed = speed ?? decayRate ?? 0.42,
        force = force ?? pullForce ?? 0.42;

  /// Compatibility alias for [speed] (decay rate).
  ///
  /// Deprecated: Use [speed] instead. This property will be removed in particles_network 2.0.0.
  @Deprecated(
    'Use speed instead. This property will be removed in particles_network 2.0.0.',
  )
  double get decayRate => speed;

  /// Compatibility alias for [force] (pull force).
  ///
  /// Deprecated: Use [force] instead. This property will be removed in particles_network 2.0.0.
  @Deprecated(
    'Use force instead. This property will be removed in particles_network 2.0.0.',
  )
  double get pullForce => force;

  /// Creates a copy of this [TouchFeatures] with updated parameters.
  TouchFeatures copyWith({
    bool? enabled,
    double? speed,
    double? force,
    double? maxTouchSpeed,
    double? damping,
    double? lineDistance,
    Color? color,
    @Deprecated(
      'Use speed instead. This parameter will be removed in particles_network 2.0.0.',
    )
    double? decayRate,
    @Deprecated(
      'Use force instead. This parameter will be removed in particles_network 2.0.0.',
    )
    double? pullForce,
  }) {
    return TouchFeatures(
      enabled: enabled ?? this.enabled,
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
