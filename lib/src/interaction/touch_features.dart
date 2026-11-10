/// Configuration class for touch interaction behavior and physics.
library;

import 'dart:ui';

/// Configuration class for touch interaction behavior and physics.
class TouchFeatures {
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

  /// Highlight color for touch interactions (default: const Color(0xFFFFC107) / Colors.amber).
  final Color color;

  /// Compatibility alias for [color].
  Color get touchColor => color;

  /// Creates a [TouchFeatures] configuration.
  const TouchFeatures({
    double? speed,
    double? decayRate,
    double? force,
    double? pullForce,
    this.maxTouchSpeed = 5.5,
    this.damping = 0.985,
    this.lineDistance,
    Color? color,
    Color? touchColor,
  })  : speed = speed ?? decayRate ?? 0.42,
        force = force ?? pullForce ?? 0.42,
        color = touchColor ?? color ?? const Color(0xFFFFC107);

  /// Alias for [speed] (decay rate).
  double get decayRate => speed;

  /// Alias for [force] (pull force).
  double get pullForce => force;

  /// Creates a copy of this [TouchFeatures] with updated parameters.
  TouchFeatures copyWith({
    double? speed,
    double? force,
    double? maxTouchSpeed,
    double? damping,
    double? lineDistance,
    Color? color,
  }) {
    return TouchFeatures(
      speed: speed ?? this.speed,
      force: force ?? this.force,
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
          speed == other.speed &&
          force == other.force &&
          maxTouchSpeed == other.maxTouchSpeed &&
          damping == other.damping &&
          lineDistance == other.lineDistance &&
          color == other.color;

  @override
  int get hashCode =>
      Object.hash(speed, force, maxTouchSpeed, damping, lineDistance, color);

  @override
  String toString() =>
      'TouchFeatures(speed: $speed, force: $force, maxTouchSpeed: $maxTouchSpeed, '
      'damping: $damping, lineDistance: $lineDistance, color: $color)';
}
