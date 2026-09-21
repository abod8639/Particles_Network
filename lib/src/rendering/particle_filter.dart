// Importing the Particle model which contains the Particle class definition
import 'package:particles_network/src/core/particle.dart';

// A utility class for filtering and managing visible particles in the network.
class ParticleFilter {
  @Deprecated(
    'Allocates a new List<int> every call. '
    'Use getVisibleParticlesTo(particles, existingList) to reuse a pre-allocated buffer.',
  )
  static List<int> getVisibleParticles(List<Particle> particles) {
    final List<int> visibleParticles = <int>[];

    for (int i = 0; i < particles.length; i++) {
      if (particles[i].isVisible) {
        visibleParticles.add(i);
      }
    }

    return visibleParticles;
  }

  /// Populates [output] with indices of all currently visible particles without allocating a new list.
  static void getVisibleParticlesTo(List<Particle> particles, List<int> output) {
    output.clear();
    for (int i = 0; i < particles.length; i++) {
      if (particles[i].isVisible) {
        output.add(i);
      }
    }
  }
}
