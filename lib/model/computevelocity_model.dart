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

Offset computeVelocity({
  required Offset currentVelocity,
  required Offset defaultVelocity,
  required double speedThreshold,
}) {
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