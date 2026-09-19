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
  Offset? touchPoint;

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

  // Precomputed color look-up table for touch lines (zero allocation)
  late final List<Color> _touchColorLut = List<Color>.generate(
    256,
    (int a) => touchColor.withAlpha(a),
    growable: false,
  );

  // Applies touch physics to visible particles
  // [visibleParticles] - List of indices of currently visible particles
  // [tracker] - Acceleration tracker to record accelerated particles
  void applyTouchPhysics(
    List<int> visibleParticles,
    AccelerationTracker tracker,
  ) {
    final Offset? touch = touchPoint;
    if (touch == null) return; // Exit if no current touch

    final double maxDist = lineDistance;
    final double maxDistSq = maxDist * maxDist;
    const double force = 0.00111; // Strength of the pull effect

    for (final int i in visibleParticles) {
      final Particle p = particles[i];
      final double dx = touch.dx - p.position.dx;
      if (dx > maxDist || dx < -maxDist) continue;
      final double dy = touch.dy - p.position.dy;
      if (dy > maxDist || dy < -maxDist) continue;
      final double distSq = dx * dx + dy * dy;

      // Only affect particles within the interaction distance (avoid sqrt if out of range)
      if (distSq < maxDistSq) {
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

    final double maxDist = lineDistance;
    final double maxDistSq = maxDist * maxDist;
    final double invLineDist = maxDist > 0 ? 255.0 / maxDist : 0.0;

    for (final int i in visibleParticles) {
      final Particle p = particles[i];
      final double dx = touch.dx - p.position.dx;
      if (dx > maxDist || dx < -maxDist) continue;
      final double dy = touch.dy - p.position.dy;
      if (dy > maxDist || dy < -maxDist) continue;
      final double distSq = dx * dx + dy * dy;

      // Only draw lines for particles within the connection distance
      if (distSq < maxDistSq) {
        final double distance = math.sqrt(distSq);
        final int opacity =
            (255 - (distance * invLineDist)).toInt().clamp(0, 255);
        linePaint.color = _touchColorLut[opacity];
        canvas.drawLine(p.position, touch, linePaint);
      }
    }
  }
}
