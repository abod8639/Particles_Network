// computeVelocity smoothly interpolates the particle's velocity back to its default value after acceleration.
//
// This function is used to gradually restore a particle's speed and direction to its original state
// after it has been affected by an external force (e.g., user interaction).
//
// Parameters:
//   - currentVelocity: The particle's current velocity vector.
//   - defaultVelocity: The velocity vector to return to.
//   - speedThreshold: The minimum difference in speed before snapping to defaultVelocity.
//
// Returns:
//   - An Offset representing the new velocity, smoothly interpolated toward defaultVelocity.
import 'dart:ui';

// Computes a new velocity for a particle by smoothly interpolating its current velocity back toward a default velocity.
// This is typically used to restore a particle's motion after it has been disturbed by an external force.
Offset computeVelocity(
  Offset currentVelocity,
  Offset defaultVelocity,
  double speedThreshold,
) {
  final currentSpeed = currentVelocity.distance;
  final defaultSpeed = defaultVelocity.distance;

  if ((currentSpeed - defaultSpeed).abs() < speedThreshold) {
    return defaultVelocity;
  } else {
    const decayFactor = 0.95;
    final scaleFactor = currentSpeed != 0 ? defaultSpeed / currentSpeed : 1.0;
    final targetVelocity = Offset(
      defaultVelocity.dx * scaleFactor,
      defaultVelocity.dy * scaleFactor,
    );
    return Offset.lerp(currentVelocity, targetVelocity, 0.955 - decayFactor) ??
        currentVelocity;
  }
}
