// The ParticleUpdater class handles the logic for updating particles and applying touch interactions.
// It separates the logic from the rendering code to make it more testable.
import 'dart:ui';

import 'package:particles_network/model/particlemodel.dart';

class ParticleUpdater {
  // Updates the position and velocity of a particle based on the bounds.
  void updateParticle(Particle particle, Size bounds) {
    particle.update(bounds);
  }

  // Applies touch interaction logic to the particles within a certain distance from the touch point.
  void applyTouchInteraction({
    required Offset touch,
    required double lineDistance,
    required List<Particle> particles,
    required List<int> visibleIndices,
  }) {
    const force = 0.00115;

    for (final i in visibleIndices) {
      final p = particles[i];
      final distance = (p.position - touch).distance;

      if (distance < lineDistance) {
        final pull = (touch - p.position) * force;
        p.velocity += pull;
        p.wasAccelerated = true;
      }
    }
  }
}
