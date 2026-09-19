/// Particle data model and physics logic.
///
/// This library defines the [Particle] class and helper functions for calculating
/// velocity and simulating particle behavior.
library;

import 'package:flutter/material.dart';

/// The Particle class represents a single particle in the particle network.
/// It contains properties for position, velocity, color, size, and visibility.
///
/// Uses primitive doubles internally for zero-allocation per-frame physics updates
/// while providing [Offset] accessors for 100% API compatibility.
class Particle {
  /// Raw X position coordinate.
  double x;

  /// Raw Y position coordinate.
  double y;

  /// Raw X velocity component.
  double vx;

  /// Raw Y velocity component.
  double vy;

  /// Accumulated acceleration on X axis.
  double ax = 0.0;

  /// Accumulated acceleration on Y axis.
  double ay = 0.0;

  /// The mass of the particle, affects how much force is needed to move it.
  final double mass;

  /// Precomputed inverse mass (1/mass) to replace per-call division with multiplication.
  final double _invMass;

  /// Default X velocity component, used to reset its speed.
  double defaultVx;

  /// Default Y velocity component, used to reset its speed.
  double defaultVy;

  /// A flag indicating whether the particle was affected by touch interaction.
  bool wasAccelerated = false;

  /// The decay rate used when returning to default velocity after touch acceleration.
  double decayRate = 0.012;

  /// A flag indicating whether the particle is visible within the viewport.
  bool isVisible = true;

  /// The color of the particle.
  Color color;

  /// The size of the particle.
  double size;

  /// The current position of the particle as an [Offset].
  Offset get position => Offset(x, y);
  set position(Offset pos) {
    x = pos.dx;
    y = pos.dy;
  }

  /// The current velocity of the particle as an [Offset].
  Offset get velocity => Offset(vx, vy);
  set velocity(Offset vel) {
    vx = vel.dx;
    vy = vel.dy;
  }

  /// Accumulated acceleration from forces applied during this frame as an [Offset].
  Offset get acceleration => Offset(ax, ay);
  set acceleration(Offset acc) {
    ax = acc.dx;
    ay = acc.dy;
  }

  /// The default velocity of the particle as an [Offset], used to reset its speed.
  Offset get defaultVelocity => Offset(defaultVx, defaultVy);
  set defaultVelocity(Offset vel) {
    defaultVx = vel.dx;
    defaultVy = vel.dy;
  }

  /// Constructor to initialize the particle's properties.
  Particle({
    required Offset position,
    required Offset velocity,
    required this.color,
    required this.size,
    this.isVisible = true,
  })  : x = position.dx,
        y = position.dy,
        vx = velocity.dx,
        vy = velocity.dy,
        defaultVx = velocity.dx,
        defaultVy = velocity.dy,
        mass = size * size, // Mass is proportional to area (size^2)
        _invMass = size > 0 ? 1.0 / (size * size) : 0.0;

  /// Applies a force to the particle based on F = ma (a = F/m).
  void applyForce(Offset force) {
    applyForceRaw(force.dx, force.dy);
  }

  /// Applies a force using primitive scalar components with zero heap allocations.
  @pragma('vm:prefer-inline')
  void applyForceRaw(double fx, double fy) {
    ax += fx * _invMass;
    ay += fy * _invMass;
  }

  /// Updates the particle's position and velocity based on its current state with zero allocations.
  void update(Size bounds) {
    // Apply accumulated acceleration to velocity
    vx += ax;
    vy += ay;

    // Reset acceleration for the next frame
    ax = 0.0;
    ay = 0.0;

    // Update the position by adding the velocity.
    x += vx;
    y += vy;

    // If the particle was accelerated (e.g. by touch), gradually return to default.
    if (wasAccelerated) {
      final double diffX = vx - defaultVx;
      final double diffY = vy - defaultVy;
      final double diffSq = diffX * diffX + diffY * diffY;
      const double speedThreshold = 0.01;
      if (diffSq < speedThreshold * speedThreshold) {
        vx = defaultVx;
        vy = defaultVy;
        wasAccelerated = false;
      } else {
        vx = vx + (defaultVx - vx) * decayRate;
        vy = vy + (defaultVy - vy) * decayRate;
      }
    }

    // Handle collisions with the screen boundaries.
    handleScreenBoundaries(bounds);

    // Update the visibility status of the particle.
    updateVisibility(bounds);
  }

  /// Handles collisions with the screen boundaries by reversing the velocity.
  void handleScreenBoundaries(Size bounds) {
    if (x < 0) {
      if (vx < 0) {
        vx = -vx;
        defaultVx = -defaultVx;
      }
    } else if (x > bounds.width) {
      if (vx > 0) {
        vx = -vx;
        defaultVx = -defaultVx;
      }
    }

    if (y < 0) {
      if (vy < 0) {
        vy = -vy;
        defaultVy = -defaultVy;
      }
    } else if (y > bounds.height) {
      if (vy > 0) {
        vy = -vy;
        defaultVy = -defaultVy;
      }
    }
  }

  /// Updates the visibility status of the particle based on its position.
  void updateVisibility(Size bounds) {
    // Include a margin to account for particles near the edges of the viewport.
    const double margin = 50.0;
    isVisible = x >= -margin &&
        x <= bounds.width + margin &&
        y >= -margin &&
        y <= bounds.height + margin;
  }
}

/// Computes the velocity with gradual decay to return to the default velocity.
Offset computeVelocity(
  Offset currentVelocity,
  Offset defaultVelocity,
  double speedThreshold, [
  double decayRate = 0.012,
]) {
  // Use squared difference to avoid expensive sqrt calls
  final double diffSq = (currentVelocity - defaultVelocity).distanceSquared;
  if (diffSq < speedThreshold * speedThreshold) {
    return defaultVelocity;
  }

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
