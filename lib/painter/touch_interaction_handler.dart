// Importing Dart's UI library for Canvas and Paint classes
import 'dart:math' as math;
import 'dart:ui';

// Importing the particle model
import 'package:particles_network/model/particlemodel.dart';

/// Class that handles touch interactions with particles
/// 
/// Optimizations:
/// - Combines physics and rendering in single pass
/// - Batched rendering using opacity buckets
/// - Eliminates duplicate distance calculations
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

  /// Handles both touch physics and rendering in a single optimized pass
  /// 
  /// This method:
  /// 1. Calculates distance once per particle
  /// 2. Applies physics to nearby particles
  /// 3. Batches rendering into opacity buckets
  /// 
  /// [canvas] - The canvas to draw on
  /// [visibleParticles] - List of indices of currently visible particles
  void handleTouchInteraction(Canvas canvas, List<int> visibleParticles) {
    final Offset? touch = touchPoint;
    if (touch == null) return;

    // Pre-calculate touch position components for faster access
    final double touchX = touch.dx;
    final double touchY = touch.dy;

    // Buckets for batched rendering (10 opacity levels)
    final List<List<Offset>> opacityBuckets = List.generate(10, (_) => []);

    for (final int i in visibleParticles) {
      final Particle p = particles[i];

      // Calculate distance once using inline math (avoids intermediate Offset)
      final double dx = p.position.dx - touchX;
      final double dy = p.position.dy - touchY;
      final double distance = math.sqrt(dx * dx + dy * dy);

      if (distance < lineDistance) {
        // Apply physics: pull particle towards touch point
        const double force = 0.00111;
        final double pullX = -dx * force;
        final double pullY = -dy * force;
        p.velocity += Offset(pullX, pullY);
        p.wasAccelerated = true;

        // Prepare for batched rendering
        final double opacity = 1.0 - (distance / lineDistance);
        if (opacity > 0) {
          final int bucketIndex = (opacity * 9).floor().clamp(0, 9);
          opacityBuckets[bucketIndex].add(p.position);
          opacityBuckets[bucketIndex].add(touch);
        }
      }
    }

    // Batch render all touch lines by opacity level
    for (int i = 0; i < 10; i++) {
      final List<Offset> points = opacityBuckets[i];
      if (points.isNotEmpty) {
        final double bucketOpacity = (i + 1) / 10.0;
        linePaint.color = touchColor.withOpacity(bucketOpacity);
        canvas.drawPoints(PointMode.lines, points, linePaint);
      }
    }
  }

  /// Legacy method for applying touch physics (deprecated)
  /// Use handleTouchInteraction instead for better performance
  @Deprecated('Use handleTouchInteraction for combined physics and rendering')
  void applyTouchPhysics(List<int> visibleParticles) {
    final Offset? touch = touchPoint;
    if (touch == null) return;

    final double touchX = touch.dx;
    final double touchY = touch.dy;

    for (final int i in visibleParticles) {
      final Particle p = particles[i];
      final double dx = p.position.dx - touchX;
      final double dy = p.position.dy - touchY;
      final double distance = math.sqrt(dx * dx + dy * dy);

      if (distance < lineDistance) {
        const double force = 0.00111;
        final double pullX = -dx * force;
        final double pullY = -dy * force;
        p.velocity += Offset(pullX, pullY);
        p.wasAccelerated = true;
      }
    }
  }

  /// Legacy method for drawing touch lines (deprecated)
  /// Use handleTouchInteraction instead for better performance
  @Deprecated('Use handleTouchInteraction for combined physics and rendering')
  void drawTouchLines(Canvas canvas, List<int> visibleParticles) {
    final Offset? touch = touchPoint;
    if (touch == null) return;

    final double touchX = touch.dx;
    final double touchY = touch.dy;

    for (final int i in visibleParticles) {
      final Particle p = particles[i];
      final double dx = p.position.dx - touchX;
      final double dy = p.position.dy - touchY;
      final double distance = math.sqrt(dx * dx + dy * dy);

      if (distance < lineDistance) {
        final int opacity = ((1 - distance / lineDistance) * 255).toInt();
        linePaint.color = touchColor.withAlpha(opacity.clamp(0, 255));
        canvas.drawLine(p.position, touch, linePaint);
      }
    }
  }
}
