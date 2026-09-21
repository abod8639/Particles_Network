/// Particle updater implementing basic Euler integration physics with gravity support.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:particles_network/src/core/particle.dart';
import 'package:particles_network/src/physics/gravity_config.dart';
import 'package:particles_network/src/physics/particle_controller.dart';

/// Default particle controller implementing basic Euler integration physics with gravity support.
class ParticleUpdater implements IParticleController {
  @override
  void updateParticles(
    List<Particle> particles,
    Size bounds, {
    GravityConfig gravity = const GravityConfig(),
  }) {
    final bool hasGlobalGravity =
        gravity.type == GravityType.global && gravity.strength != 0;
    final double gStrength = gravity.strength;
    final double gfx =
        hasGlobalGravity ? gravity.direction.dx * gStrength : 0.0;
    final double gfy =
        hasGlobalGravity ? gravity.direction.dy * gStrength : 0.0;
    final bool isPointGravity =
        gravity.type == GravityType.point && gStrength != 0;
    final double cx = gravity.center.dx;
    final double cy = gravity.center.dy;

    final int count = particles.length;
    for (int i = 0; i < count; i++) {
      final Particle p = particles[i];
      if (hasGlobalGravity) {
        p.applyForceRaw(gfx, gfy);
      } else if (isPointGravity) {
        final double dx = cx - p.x;
        final double dy = cy - p.y;
        final double distSq = dx * dx + dy * dy;
        if (distSq > 0) {
          // Precompute scale = strength/dist in one step (saves one multiply vs invDist * gStrength)
          final double scale = gStrength / math.sqrt(distSq);
          p.applyForceRaw(dx * scale, dy * scale);
        }
      }
      p.update(bounds);
    }
  }
}
