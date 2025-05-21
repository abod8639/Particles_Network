// File: spatial_grid_manager.dart

import 'package:particles_network/model/drid_cell.dart';
import 'package:particles_network/model/particlemodel.dart';

/// Class for spatial partitioning of particles using a grid-based approach
class SpatialGridManager {
  /// Creates an optimized spatial grid using GridCell as key
  ///
  /// [particles]: Complete list of all particles
  /// [visibleParticles]: Indices of currently visible particles
  /// [cellSize]: Size of each grid cell (uniform in x and y dimensions)
  ///
  /// Returns: A map where keys are grid cells and values are lists of particle indices
  static Map<GridCell, List<int>> createOptimizedSpatialGrid(
    List<Particle> particles,
    List<int> visibleParticles,
    double cellSize,
  ) {
    // Initialize empty spatial grid
    final grid = <GridCell, List<int>>{};

    // Process only visible particles (optimization)
    for (final i in visibleParticles) {
      final p = particles[i];

      // Calculate home cell coordinates using floor division
      // Computational operation: 2 divisions + 2 floor operations (O(1) per particle)
      final cellX = (p.position.dx / cellSize).floor();
      final cellY = (p.position.dy / cellSize).floor();

      // Add particle to a 3x3 neighborhood around its home cell
      // This creates overlapping regions for easier spatial queries later
      // Computational operation: 9 cell checks/inserts per particle (O(1) each)
      for (int nx = -1; nx <= 1; nx++) {
        for (int ny = -1; ny <= 1; ny++) {
          final cell = GridCell(cellX + nx, cellY + ny);

          // Efficient map insertion: creates list if absent, then appends index
          grid.putIfAbsent(cell, () => []).add(i);
        }
      }
    }

    return grid;
  }
}
