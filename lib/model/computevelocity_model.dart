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
  // Calculate the magnitude (speed) of the current and default velocity vectors
  final currentSpeed = currentVelocity.distance;
  final defaultSpeed = defaultVelocity.distance;

  // If the difference in speed is less than the threshold, snap to the default velocity
  if ((currentSpeed - defaultSpeed).abs() < speedThreshold) {
    return defaultVelocity;
  } else {
    // Decay factor controls how quickly the velocity returns to default (closer to 1.0 = slower)
    const decayFactor = 0.985; //
    // Scale factor adjusts the default velocity to match the current speed's direction
    final scaleFactor = defaultSpeed / currentSpeed;

    // Target velocity is the default velocity scaled to match the current speed
    final targetVelocity = defaultVelocity * scaleFactor;
    // Interpolation amount determines how much to blend between current and target velocity
    const powrFactor = 0.989;
    const interpolationAmount = powrFactor - decayFactor;

    // Smoothly interpolate from currentVelocity to targetVelocity
    return Offset.lerp(currentVelocity, targetVelocity, interpolationAmount) ??
        currentVelocity;
  }
}
