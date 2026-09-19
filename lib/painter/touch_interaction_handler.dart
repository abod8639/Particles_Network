import 'dart:math' as math;
import 'dart:ui';

// Importing the particle model
import 'package:particles_network/model/particlemodel.dart';
import 'package:particles_network/painter/performance_utils.dart';

/// Configuration class for touch interaction behavior and physics.
class TouchFeatures {
  /// The recovery/settling decay rate after touch release [default: 0.012].
  /// Controls how gradually particles return to cruising speed after being dragged/touched.
  final double speed;

  /// Attraction pull force towards touch point [default: 0.42].
  final double force;

  /// Maximum velocity cap for particles during touch interaction [default: 5.5].
  final double maxTouchSpeed;

  /// Fluid damping factor applied to particles inside the touch field [default: 0.985].
  final double damping;

  /// Creates a [TouchFeatures] configuration.
  const TouchFeatures({
    double? speed,
    double? decayRate,
    double? force,
    double? pullForce,
    this.maxTouchSpeed = 5.5,
    this.damping = 0.985,
  })  : speed = speed ?? decayRate ?? 0.012,
        force = force ?? pullForce ?? 0.42;

  /// Alias for [speed] (decay rate).
  double get decayRate => speed;

  /// Alias for [force] (pull force).
  double get pullForce => force;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TouchFeatures &&
          runtimeType == other.runtimeType &&
          speed == other.speed &&
          force == other.force &&
          maxTouchSpeed == other.maxTouchSpeed &&
          damping == other.damping;

  @override
  int get hashCode => Object.hash(speed, force, maxTouchSpeed, damping);
}

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

  // Configuration for touch features and physics
  final TouchFeatures touchFeatures;

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

    final double tx = touch.dx;
    final double ty = touch.dy;
    final double maxDist = lineDistance;
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
    final double maxDist = lineDistance;
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
