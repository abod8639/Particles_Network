// Importing the Particle model which contains the Particle class definition
import 'package:particles_network/model/particlemodel.dart';

/// A utility class for filtering and managing visible particles in the network.
///
/// This class provides static methods to process particle collections and
/// identify which particles should currently be considered "visible" or active
/// in the simulation. This is particularly useful for performance optimization
/// by avoiding calculations on particles that don't currently affect the visual output.
///
/// Visibility Concept:
/// - A particle's visibility is determined by its `isVisible` property
/// - Visibility can be used to implement:
///   * Viewport culling (particles outside visible area)
///   * Level-of-detail systems
///   * Performance optimization layers
///   * Special effect triggers
class ParticleFilter {
  /// Filters and returns a list of indices for all currently visible particles.
  ///
  /// This method implements a simple linear scan filter operation with O(n) time complexity
  /// where n is the number of particles. It's optimized for:
  /// - Minimal memory allocation (reuses the same list)
  /// - Cache efficiency (sequential memory access)
  /// - Simple branch prediction (single if condition)
  ///
  /// [particles] - The complete collection of particles to filter
  ///
  /// Returns: A List<int> containing the indices of all visible particles
  ///          in the original list. These indices can be used for efficient
  ///          access to the visible particles without creating new particle objects.
  ///
  /// Performance Characteristics:
  /// Time Complexity: O(n) - linear scan through all particles
  /// Space Complexity: O(k) - where k is number of visible particles
  /// Memory Allocations: 1 (for the result list)
  static List<int> getVisibleParticles(List<Particle> particles) {
    // Pre-allocate list for visible particle indices
    final List<int> visibleParticles = <int>[];

    // Iterate through all particles using index-based loop
    // (more efficient than iterator for List in Dart)
    for (int i = 0; i < particles.length; i++) {
      // Check visibility flag - this could represent:
      // - Actual on-screen visibility
      // - Active/inactive state
      // - Participation in current simulation frame
      if (particles[i].isVisible) {
        // Store the index rather than the particle object to:
        // - Save memory (int vs object reference)
        // - Allow direct modification of original particles
        // - Enable efficient batch processing
        visibleParticles.add(i);
      }
    }

    return visibleParticles;
  }
}
