import 'dart:math' as math;
import 'dart:ui';

// Importing the particle model
import 'package:particles_network/model/particlemodel.dart';
import 'package:particles_network/painter/performance_utils.dart';

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

  // Constructor for the touch interaction handler
  TouchInteractionHandler({
    required this.particles,
    required this.touchPoint,
    required this.lineDistance,
    required this.touchColor,
    required this.linePaint,
  });

  // Test variable (kept for API compatibility)
  final int test = 0;

  // Applies touch physics to visible particles
  // [visibleParticles] - List of indices of currently visible particles
  // [tracker] - Acceleration tracker to record accelerated particles
  void applyTouchPhysics(
    List<int> visibleParticles,
    AccelerationTracker tracker,
  ) {
    final Offset? touch = touchPoint;
    if (touch == null) return; // Exit if no current touch

    final double maxDistSq = lineDistance * lineDistance;

    for (final int i in visibleParticles) {
      final Particle p = particles[i];
      final double dx = touch.dx - p.position.dx;
      final double dy = touch.dy - p.position.dy;
      final double distSq = dx * dx + dy * dy;

      // Only affect particles within the interaction distance (avoid sqrt if out of range)
      if (distSq < maxDistSq) {
        const double force = 0.00111; // Strength of the pull effect
        p.velocity = Offset(
          p.velocity.dx + dx * force,
          p.velocity.dy + dy * force,
        );
        // Mark particle as accelerated for visual feedback
        p.wasAccelerated = true;
        // Record acceleration for efficient shouldRepaint
        tracker.recordAcceleration();
      }
    }
  }

  // Draws lines between touch point and nearby particles
  // [canvas] - The canvas to draw on
  // [visibleParticles] - List of indices of currently visible particles
  void drawTouchLines(Canvas canvas, List<int> visibleParticles) {
    final Offset? touch = touchPoint;
    if (touch == null) return; // Exit if no current touch

    final double maxDistSq = lineDistance * lineDistance;

    for (final int i in visibleParticles) {
      final Particle p = particles[i];
      final double dx = touch.dx - p.position.dx;
      final double dy = touch.dy - p.position.dy;
      final double distSq = dx * dx + dy * dy;

      // Only draw lines for particles within the connection distance
      if (distSq < maxDistSq) {
        final double distance = math.sqrt(distSq);
        // Calculate line opacity based on distance (further = more transparent)
        final int opacity = ((1.0 - distance / lineDistance) * 255).toInt();
        // Update paint color with calculated opacity
        linePaint.color = touchColor.withAlpha(opacity.clamp(0, 255));
        // Draw line from particle to touch point
        canvas.drawLine(p.position, touch, linePaint);
      }
    }
  }
}
