import 'package:particles_network/model/particlemodel.dart';

/// Class to identify visible particles
class Particlefilter {
  /// Filters and returns a list of indices of visible particles
  static List<int> getVisibleParticles(List<Particle> particles) {
    // Initialize an empty list to store indices of visible particles
    final visibleParticles = <int>[];

    // Loop through all particles in the input list
    // Computational operation: Linear iteration O(n) where n is particles.length
    for (int i = 0; i < particles.length; i++) {
      // Check if the current particle is visible
      // Computational operation: Boolean check O(1)
      if (particles[i].isVisible) {
        // If visible, add its index to the result list
        // Computational operation: List append O(1) amortized
        visibleParticles.add(i);
      }
    }

    // Return the list of visible particle indices
    return visibleParticles;
  }
}
