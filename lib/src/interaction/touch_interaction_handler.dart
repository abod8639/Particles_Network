import 'dart:math' as math;
import 'dart:ui';

import 'package:particles_network/src/core/particle.dart';
import 'package:particles_network/src/interaction/touch_features.dart';
import 'package:particles_network/src/rendering/performance_utils.dart';

export 'package:particles_network/src/interaction/touch_features.dart';

/// Class that handles touch interactions with particles
class TouchInteractionHandler {
  // List of all particles in the network
  final List<Particle> particles;

  // Current touch position (null when not touching)
  Offset? touchPoint;

  // Base maximum distance for touch interactions (fallback if not specified in touchFeatures)
  double lineDistance;

  /// Effective distance for touch interactions
  double get effectiveLineDistance => touchFeatures.lineDistance ?? lineDistance;

  // Color to use for touch interactions
  Color touchColor;

  // Paint object for drawing touch interaction lines
  final Paint linePaint;

  // Configuration for touch features and physics
  TouchFeatures touchFeatures;

  // Constructor for the touch interaction handler
  TouchInteractionHandler({
    required this.particles,
    required this.touchPoint,
    required this.lineDistance,
    required this.touchColor,
    required this.linePaint,
    this.touchFeatures = const TouchFeatures(),
  });

  // Test variable (kept for API compatibility)
  final int test = 0;
  final double force = 0.00111;
  // Precomputed color look-up table for touch lines (zero allocation)
  late List<Color> _touchColorLut = List<Color>.generate(
    256,
    (int a) => touchColor.withAlpha(a),
    growable: false,
  );

  /// Rebuilds the touch color LUT with a new color — called by the painter
  /// to avoid full reconstruction when only the touch color changes.
  void rebuildTouchColorLut(Color newColor) {
    touchColor = newColor;
    _touchColorLut = List<Color>.generate(
      256,
      (int a) => newColor.withAlpha(a),
      growable: false,
    );
  }

  // Applies touch physics to visible particles
  // [visibleParticles] - List of indices of currently visible particles
  // [tracker] - Acceleration tracker to record accelerated particles
  void applyTouchPhysics(
    List<int> visibleParticles,
    AccelerationTracker tracker,
  ) {
    final Offset? touch = touchPoint;
    if (touch == null) return; // Exit if no current touch

    final double tx = touch.dx;
    final double ty = touch.dy;
    final double maxDist = effectiveLineDistance;
    final double maxDistSq = maxDist * maxDist;
    final double pullForce = touchFeatures.force;
    final double touchDamping = touchFeatures.damping;
    final double maxTouchSpeed = touchFeatures.maxTouchSpeed;
    final double maxTouchSpeedSq = maxTouchSpeed * maxTouchSpeed;
    final double touchSpeed = touchFeatures.speed;

    final int count = visibleParticles.length;
    for (int idx = 0; idx < count; idx++) {
      final Particle p = particles[visibleParticles[idx]];
      final double dx = tx - p.x;
      if (dx > maxDist || dx < -maxDist) continue;
      final double dy = ty - p.y;
      if (dy > maxDist || dy < -maxDist) continue;
      final double distSq = dx * dx + dy * dy;

      // Only affect particles within the interaction distance (avoid sqrt if out of range)
      if (distSq < maxDistSq) {
        p.vx += dx * force;
        p.vy += dy * force;

        final double dist = math.sqrt(distSq);
        // Linear falloff: responsive attraction that smoothly reaches 0 at maxDist
        final double falloff = 1.0 - (dist / maxDist);

        // Normalized direction vector towards touch point
        final double invDist = dist > 0.001 ? 1.0 / dist : 0.0;
        final double nx = dx * invDist;
        final double ny = dy * invDist;

        // Stronger, responsive pull force for fluid drag response
        double vx = (p.vx + nx * (pullForce * falloff)) * touchDamping;
        double vy = (p.vy + ny * (pullForce * falloff)) * touchDamping;

        // Terminal speed limit from touchFeatures
        final double speedSq = vx * vx + vy * vy;
        if (speedSq > maxTouchSpeedSq) {
          final double scale = maxTouchSpeed / math.sqrt(speedSq);
          vx *= scale;
          vy *= scale;
        }

        p.vx = vx;
        p.vy = vy;

        // Mark particle as accelerated and apply configured recovery speed
        p.decayRate = touchSpeed;
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

    final double tx = touch.dx;
    final double ty = touch.dy;
    final double maxDist = effectiveLineDistance;
    final double maxDistSq = maxDist * maxDist;
    final double invMaxDist = maxDist > 0 ? 1.0 / maxDist : 0.0;

    final int count = visibleParticles.length;
    for (int idx = 0; idx < count; idx++) {
      final Particle p = particles[visibleParticles[idx]];
      final double dx = tx - p.x;
      if (dx > maxDist || dx < -maxDist) continue;
      final double dy = ty - p.y;
      if (dy > maxDist || dy < -maxDist) continue;
      final double distSq = dx * dx + dy * dy;

      // Only draw lines for particles within the connection distance
      if (distSq < maxDistSq) {
        final double distance = math.sqrt(distSq);
        // Smooth linear falloff: 1.0 at touch, 0.0 at maxDist
        final double opacity = 1.0 - (distance * invMaxDist);
        final int alpha = (255 * opacity).toInt().clamp(0, 255);
        linePaint.color = _touchColorLut[alpha];
        canvas.drawLine(Offset(p.x, p.y), touch, linePaint);
      }
    }
  }
}
