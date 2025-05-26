// Added an explanation for the library
// This library provides a Particle class to simulate particles in a network. Each particle has properties like position, velocity, color, and size. The library includes methods to update particle states, handle screen boundary collisions, and compute velocity with gradual decay. Additionally, a utility function is provided to create mock particles for testing purposes.

import 'package:flutter/material.dart';

// The Particle class represents a single particle in the particle network.
// It contains properties for position, velocity, color, size, and visibility.
class Particle {
  // The current position of the particle.
  Offset position;

  // The current velocity of the particle.
  Offset velocity;

  // The default velocity of the particle, used to reset its speed.
  Offset defaultVelocity;

  // A flag indicating whether the particle was affected by touch interaction.
  bool wasAccelerated = false;

  // A flag indicating whether the particle is visible within the viewport.
  bool isVisible = true;

  // The color of the particle.
  Color color;

  // The size of the particle.
  double size;

  // Constructor to initialize the particle's properties.
  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    this.isVisible = true,
  }) : defaultVelocity = velocity;

  // Updates the particle's position and velocity based on its current state.
  void update(Size bounds) {
    // Update the position by adding the velocity.
    position += velocity;

    // If the particle was accelerated, gradually reduce its velocity to the default.
    if (wasAccelerated) {
      velocity = computeVelocity(velocity, defaultVelocity, 0.01);
    }

    // Handle collisions with the screen boundaries.
    handleScreenBoundaries(bounds);

    // Update the visibility status of the particle.
    updateVisibility(bounds);
  }

  // Handles collisions with the screen boundaries by reversing the velocity.
  void handleScreenBoundaries(Size bounds) {
    if (position.dx < 0 || position.dx > bounds.width) {
      velocity = Offset(-velocity.dx, velocity.dy);
      defaultVelocity = Offset(-defaultVelocity.dx, defaultVelocity.dy);
    }
    if (position.dy < 0 || position.dy > bounds.height) {
      velocity = Offset(velocity.dx, -velocity.dy);
      defaultVelocity = Offset(defaultVelocity.dx, -defaultVelocity.dy);
    }
  }

  // Updates the visibility status of the particle based on its position.
  void updateVisibility(Size bounds) {
    // Include a margin to account for particles near the edges of the viewport.
    const margin = 100.0;
    isVisible =
        position.dx >= -margin &&
        position.dx <= bounds.width + margin &&
        position.dy >= -margin &&
        position.dy <= bounds.height + margin;
  }
}

// Computes the velocity with gradual decay to return to the default velocity.
Offset computeVelocity(
  Offset currentVelocity,
  Offset defaultVelocity,
  double speedThreshold,
) {
  // Calculate the magnitude (speed) of the current and default velocity vectors.
  final double currentSpeed = currentVelocity.distance;
  final double defaultSpeed = defaultVelocity.distance;

  // If the difference in speed is less than the threshold, snap to the default velocity.
  if ((currentSpeed - defaultSpeed).abs() < speedThreshold) {
    return defaultVelocity;
  } else {
    // Decay factor controls how quickly the velocity returns to default.
    const decayFactor = 0.985;

    // Scale factor adjusts the default velocity to match the current speed's direction.
    final double scaleFactor = defaultSpeed / currentSpeed;

    // Target velocity is the default velocity scaled to match the current speed.
    final Offset targetVelocity = defaultVelocity * scaleFactor;

    // Interpolation amount determines how much to blend between current and target velocity.
    const double powrFactor = 0.989;
    final double interpolationAmount = powrFactor - decayFactor;

    // Smoothly interpolate from currentVelocity to targetVelocity.
    return Offset.lerp(currentVelocity, targetVelocity, interpolationAmount) ??
        currentVelocity;
  }
}

// Added a utility function to create a mock particle for testing
Particle createMockParticle({
  Offset? position,
  Offset? velocity,
  Color? color,
  double? size,
}) {
  return Particle(
    position: position ?? Offset.zero,
    velocity: velocity ?? Offset.zero,
    color: color ?? Colors.white,
    size: size ?? 1.0,
  );
}
