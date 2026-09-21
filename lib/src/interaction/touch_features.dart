/// Configuration class for touch interaction behavior and physics.
library;

/// Configuration class for touch interaction behavior and physics.
class TouchFeatures {
  /// The recovery/settling decay rate after touch release [default: 0.012].
  /// Controls how gradually particles return to cruising speed after being dragged/touched.
  final double speed;

  /// Attraction pull force towards touch point [default: 0.42].
  final double force;

  /// Maximum velocity cap for particles during touch interaction [default: 5.5].
  final double maxTouchSpeed;

  /// Fluid damping factor applied to particles inside the touch field [default: 0.985].
  final double damping;

  /// Creates a [TouchFeatures] configuration.
  const TouchFeatures({
    double? speed,
    double? decayRate,
    double? force,
    double? pullForce,
    this.maxTouchSpeed = 5.5,
    this.damping = 0.985,
  })  : speed = speed ?? decayRate ?? 0.012,
        force = force ?? pullForce ?? 0.42;

  /// Alias for [speed] (decay rate).
  double get decayRate => speed;

  /// Alias for [force] (pull force).
  double get pullForce => force;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TouchFeatures &&
          runtimeType == other.runtimeType &&
          speed == other.speed &&
          force == other.force &&
          maxTouchSpeed == other.maxTouchSpeed &&
          damping == other.damping;

  @override
  int get hashCode => Object.hash(speed, force, maxTouchSpeed, damping);
}
