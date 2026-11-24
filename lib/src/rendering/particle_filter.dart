import 'dart:ui';

import 'package:particles_network/src/core/particle.dart';
import 'package:particles_network/src/spatial/sorted_spatial_grid.dart';

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
  static void getVisibleParticlesTo(
    List<Particle> particles,
    List<int> output,
  ) {
    output.clear();
    for (int i = 0; i < particles.length; i++) {
      if (particles[i].isVisible) {
        output.add(i);
      }
    }
  }

  /// Populates [output] with indices of particles within [viewport] using [grid]
  /// with O(K_viewport) complexity instead of scanning all particles linearly.
  static void getVisibleParticlesUsingGrid(
    SortedSpatialGrid grid,
    Rect viewport,
    List<int> output,
  ) {
    output.clear();
    if (!grid.isInitialized) return;
    grid.queryRect(
      viewport.left,
      viewport.top,
      viewport.right,
      viewport.bottom,
      (idx, px, py) {
        output.add(idx);
      },
    );
  }
}
