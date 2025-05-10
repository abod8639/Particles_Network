import 'dart:ui';

// Particle class represents a single moving dot in the network.
// It holds position, velocity, color, and size information.
// It also manages its own visibility and acceleration state.

/// Represents a single particle in the network, with position, velocity, color, and size.
class Particle {
  /// The current position of the particle (x, y coordinates).
  /// Used for rendering and physics calculations.
  Offset position;

  /// The current velocity of the particle (dx, dy per frame).
  /// This determines the direction and speed of movement.
  Offset velocity;

  /// Original velocity for returning to default speed after acceleration.
  /// Used to restore the particle's speed after it is affected by touch.
  Offset defaultVelocity;

  /// Flag to track if particle was affected by touch.
  /// If true, the particle will gradually return to its default velocity.
  bool wasAccelerated = false;

  /// Flag to determine if particle is visible in viewport.
  /// Used for rendering optimization.
  bool isVisible = true;

  /// The color of the particle (used for drawing).
  Color color;

  /// The size (radius) of the particle.
  double size;

  /// Creates a [Particle] with the given position, velocity, color, and size.
  ///
  /// [defaultVelocity] is initialized to the initial velocity.
  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
  }) : defaultVelocity = velocity;

  /// Updates the particle's position, velocity, and visibility based on the given [bounds].
  /// This method is called every frame.
  void update(Size bounds) {
    // Move the particle by its velocity (Euler integration).
    // Formula: position = position + velocity
    position += velocity;

    // Gradually reduce velocity to default if particle was accelerated
    // Uses exponential decay ("Exponential Smoothing") to interpolate velocity.
    if (wasAccelerated) {
      // Calculate current speed magnitude (Euclidean norm)
      final currentSpeed = velocity.distance;
      final defaultSpeed = defaultVelocity.distance;

      // If speed is close enough to default, reset to default
      if ((currentSpeed - defaultSpeed).abs() < 0.05) {
        velocity = defaultVelocity;
        wasAccelerated = false;
      } else {
        // Gradually reduce velocity toward default (5% decay per frame)
        // Formula: v = lerp(v, v_default, alpha), where alpha = 0.005
        final decayFactor = 0.95; // 1 - decay rate
        final scaleFactor = defaultSpeed / currentSpeed;
        // Scale defaultVelocity to match direction
        final targetVelocity = Offset(
          defaultVelocity.dx * scaleFactor,
          defaultVelocity.dy * scaleFactor,
        );
        // Linear interpolation (lerp) between current and target velocity
        // Offset.lerp uses: v = v0 * (1-t) + v1 * t
        velocity = Offset.lerp(velocity, targetVelocity, 0.955 - decayFactor)!;
      }
    }

    // Handle screen boundaries (bounce effect)
    // If the particle goes out of bounds, reverse its velocity (Elastic Collision)
    if (position.dx < 0 || position.dx > bounds.width) {
      velocity = Offset(-velocity.dx, velocity.dy); // Reflect X
      defaultVelocity = Offset(-defaultVelocity.dx, defaultVelocity.dy);
    }
    if (position.dy < 0 || position.dy > bounds.height) {
      velocity = Offset(velocity.dx, -velocity.dy); // Reflect Y
      defaultVelocity = Offset(defaultVelocity.dx, -defaultVelocity.dy);
    }

    // Update visibility status (for rendering optimization)
    updateVisibility(bounds);
  }

  /// Updates the [isVisible] flag based on whether the particle is within the viewport [bounds].
  /// Adds a margin to allow for off-screen connections.
  void updateVisibility(Size bounds) {
    // Include a small margin to account for particles just outside the viewport
    // that might still have connections with visible particles
    // (Margin technique for spatial culling)
    const margin = 100.0;
    isVisible =
        position.dx >= -margin &&
        position.dx <= bounds.width + margin &&
        position.dy >= -margin &&
        position.dy <= bounds.height + margin;
  }
}
