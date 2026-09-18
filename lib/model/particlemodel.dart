/// Particle data model and physics logic.
///
/// This library defines the [Particle] class and helper functions for calculating
/// velocity and simulating particle behavior.
library;

import 'package:flutter/material.dart';

/// The Particle class represents a single particle in the particle network.
/// It contains properties for position, velocity, color, size, and visibility.
class Particle {
  /// The current position of the particle.
  Offset position;

  /// The current velocity of the particle.
  Offset velocity;

  /// Accumulated acceleration from forces applied during this frame.
  Offset acceleration = Offset.zero;

  /// The mass of the particle, affects how much force is needed to move it.
  final double mass;

  /// The default velocity of the particle, used to reset its speed.
  Offset defaultVelocity;

  /// A flag indicating whether the particle was affected by touch interaction.
  bool wasAccelerated = false;

  /// A flag indicating whether the particle is visible within the viewport.
  bool isVisible = true;

  /// The color of the particle.
  Color color;

  /// The size of the particle.
  double size;

  /// Constructor to initialize the particle's properties.
  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    this.isVisible = true,
  })  : defaultVelocity = velocity,
        mass = size * size; // Mass is proportional to area (size^2)

  /// Applies a force to the particle based on F = ma (a = F/m).
  void applyForce(Offset force) {
    if (mass > 0) {
      acceleration += force / mass;
    }
  }

  /// Updates the particle's position and velocity based on its current state.
  void update(Size bounds) {
    // Apply accumulated acceleration to velocity
    velocity += acceleration;

    // Reset acceleration for the next frame
    acceleration = Offset.zero;

    // Update the position by adding the velocity.
    position += velocity;

    // If the particle was accelerated (e.g. by touch), gradually return to default.
    if (wasAccelerated) {
      velocity = computeVelocity(velocity, defaultVelocity, 0.01);
      // If velocity has returned to default, reset the accelerated flag.
      if (velocity == defaultVelocity) {
        wasAccelerated = false;
      }
    }

    // Handle collisions with the screen boundaries.
    handleScreenBoundaries(bounds);

    // Update the visibility status of the particle.
    updateVisibility(bounds);
  }

  /// Handles collisions with the screen boundaries by reversing the velocity.
  void handleScreenBoundaries(Size bounds) {
    if (position.dx < 0) {
      if (velocity.dx < 0) {
        velocity = Offset(-velocity.dx, velocity.dy);
        defaultVelocity = Offset(-defaultVelocity.dx, defaultVelocity.dy);
      }
    } else if (position.dx > bounds.width) {
      if (velocity.dx > 0) {
        velocity = Offset(-velocity.dx, velocity.dy);
        defaultVelocity = Offset(-defaultVelocity.dx, defaultVelocity.dy);
      }
    }

    if (position.dy < 0) {
      if (velocity.dy < 0) {
        velocity = Offset(velocity.dx, -velocity.dy);
        defaultVelocity = Offset(defaultVelocity.dx, -defaultVelocity.dy);
      }
    } else if (position.dy > bounds.height) {
      if (velocity.dy > 0) {
        velocity = Offset(velocity.dx, -velocity.dy);
        defaultVelocity = Offset(defaultVelocity.dx, -defaultVelocity.dy);
      }
    }
  }

  /// Updates the visibility status of the particle based on its position.
  void updateVisibility(Size bounds) {
    // Include a margin to account for particles near the edges of the viewport.
    const margin = 50.0;
    isVisible = position.dx >= -margin &&
        position.dx <= bounds.width + margin &&
        position.dy >= -margin &&
        position.dy <= bounds.height + margin;
  }
}

/// Computes the velocity with gradual decay to return to the default velocity.
Offset computeVelocity(
  Offset currentVelocity,
  Offset defaultVelocity,
  double speedThreshold,
) {
  // Use squared difference to avoid expensive sqrt calls
  final double diffSq = (currentVelocity - defaultVelocity).distanceSquared;
  if (diffSq < speedThreshold * speedThreshold) {
    return defaultVelocity;
  }

  // Smooth decay towards default velocity
  const double decayRate = 0.02;
  return Offset.lerp(currentVelocity, defaultVelocity, decayRate) ??
      defaultVelocity;
}

/// Utility function to create a mock particle for testing.
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
