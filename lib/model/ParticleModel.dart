import 'package:flutter/material.dart';

/// A model class representing a single particle in the particle network system.
/// Each particle has a position, velocity, and appearance properties, and can
/// interact with touch input and other particles.
class Particle {
  /// Current position of the particle on the screen
  Offset position;

  /// Current velocity vector of the particle
  Offset velocity;

  /// The original/default velocity that the particle should return to
  /// after being affected by touch interactions
  Offset defaultVelocity;

  /// Flag indicating if the particle was recently affected by touch interaction
  /// Used to gradually return the particle to its default velocity
  bool wasAccelerated = false;

  /// The color of the particle
  Color color;

  /// The radius/size of the particle
  double size;

  /// Creates a new particle with the specified properties
  ///
  /// [position] The initial position of the particle
  /// [velocity] The initial velocity vector
  /// [color] The color of the particle
  /// [size] The radius of the particle
  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
  }) : defaultVelocity = velocity;

  /// Updates the particle's position and handles bounds checking
  /// Also manages velocity normalization after touch interactions
  ///
  /// [bounds] The size of the container the particle is moving in
  void update(Size bounds) {
    // Update position based on current velocity
    position += velocity;

    // Handle velocity normalization after touch acceleration
    if (wasAccelerated) {
      // Calculate current speed magnitude
      final currentSpeed = velocity.distance;
      final defaultSpeed = defaultVelocity.distance;

      // If speed is close enough to default, reset to default
      if ((currentSpeed - defaultSpeed).abs() < 0.05) {
        velocity = defaultVelocity;
        wasAccelerated = false;
      } else {
        // Gradually reduce velocity toward default (5% decay per frame)
        final decayFactor = 0.95;
        final scaleFactor = defaultSpeed / currentSpeed;
        final targetVelocity = Offset(
          defaultVelocity.dx * scaleFactor,
          defaultVelocity.dy * scaleFactor,
        );
        velocity = Offset.lerp(velocity, targetVelocity, 0.955 - decayFactor)!;
      }
    }

    // Handle screen boundary collisions by reversing velocity components
    if (position.dx < 0 || position.dx > bounds.width) {
      velocity = Offset(-velocity.dx, velocity.dy);
      defaultVelocity = Offset(-defaultVelocity.dx, defaultVelocity.dy);
    }
    if (position.dy < 0 || position.dy > bounds.height) {
      velocity = Offset(velocity.dx, -velocity.dy);
      defaultVelocity = Offset(defaultVelocity.dx, -defaultVelocity.dy);
    }
  }
}
