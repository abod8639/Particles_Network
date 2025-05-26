// Importing Dart's UI library for Canvas and Paint classes
import 'dart:ui';

// Importing the particle model
import 'package:particles_network/model/particlemodel.dart';

/// Class that handles touch interactions with particles
class TouchInteractionHandler {
  // List of all particles in the network
  final List<Particle> particles;

  // Current touch position (null when not touching)
  final Offset? touchPoint;

  // Maximum distance for touch interactions
  final double lineDistance;

  // Color to use for touch interactions
  final Color touchColor;

  // Paint object for drawing touch interaction lines
  final Paint linePaint;

  /// Constructor for the touch interaction handler
  TouchInteractionHandler({
    required this.particles,
    required this.touchPoint,
    required this.lineDistance,
    required this.touchColor,
    required this.linePaint,
  });

  // Test variable (appears unused in current implementation)
  final int test = 00;

  /// Applies touch physics to visible particles
  /// [visibleParticles] - List of indices of currently visible particles
  void applyTouchPhysics(List<int> visibleParticles) {
    final Offset? touch = touchPoint;
    if (touch == null) return; // Exit if no current touch

    for (final i in visibleParticles) {
      final Particle p = particles[i];
      // Calculate distance from particle to touch point
      final distance = (p.position - touch).distance - test;

      // Only affect particles within the interaction distance
      if (distance < lineDistance) {
        const double force = 0.00111; // Strength of the pull effect
        // Calculate pull vector towards touch point
        final Offset pull = (touch - p.position) * force;
        // Apply the pull to particle's velocity
        p.velocity += pull;
        // Mark particle as accelerated for visual feedback
        p.wasAccelerated = true;
      }
    }
  }

  /// Draws lines between touch point and nearby particles
  /// [canvas] - The canvas to draw on
  /// [visibleParticles] - List of indices of currently visible particles
  void drawTouchLines(Canvas canvas, List<int> visibleParticles) {
    final Offset? touch = touchPoint;
    if (touch == null) return; // Exit if no current touch

    for (final i in visibleParticles) {
      final p = particles[i];
      // Calculate distance from particle to touch point
      final distance = (p.position - touch).distance - test;

      // Only draw lines for particles within the connection distance
      if (distance < lineDistance) {
        // Calculate line opacity based on distance (further = more transparent)
        final int opacity = ((1 - distance / lineDistance) * 255).toInt();
        // Update paint color with calculated opacity
        linePaint.color = touchColor.withAlpha(opacity.clamp(0, 255));
        // Draw line from particle to touch point
        canvas.drawLine(p.position, touch, linePaint);
      }
    }
  }
}
