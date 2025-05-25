// File: spatial_grid_manager.dart

// Importing the GridCell model for spatial partitioning
import 'package:particles_network/model/drid_cell.dart';
// Importing the Particle model
import 'package:particles_network/model/particlemodel.dart';

/// Class for spatial partitioning of particles using an optimized grid system
///
/// This implements a spatial hashing technique to efficiently manage particle
/// proximity checks. The grid divides space into cells of equal size, allowing
/// O(1) access to particles in specific regions.
class SpatialGridManager {
  /// Creates an optimized spatial grid mapping cells to particle indices
  ///
  /// [particles] - Complete list of all particles in the system
  /// [visibleParticles] - Indices of currently visible/active particles
  /// [cellSize] - The size of each grid cell (width and height)
  ///
  /// Returns: A map where each GridCell key contains a list of particle indices
  ///          that are in or near that cell
  ///
  /// Mathematical Basis:
  /// 1. Cell Calculation:
  ///    cellX = floor(particle.x / cellSize)
  ///    cellY = floor(particle.y / cellSize)
  ///    This discretizes continuous space into a grid structure
  ///
  /// 2. 3x3 Neighborhood Inclusion:
  ///    Each particle is added to its home cell and all 8 surrounding cells
  ///    This ensures proximity checks only need to examine adjacent cells
  ///    while maintaining O(1) access time
  static Map<GridCell, List<int>> createOptimizedSpatialGrid(
    List<Particle> particles,
    List<int> visibleParticles,
    double cellSize,
  ) {
    // Initialize empty grid using GridCell as key and List<int> as value
    final grid = <GridCell, List<int>>{};

    // Process each visible particle
    for (final i in visibleParticles) {
      final p = particles[i];

      // Calculate home cell coordinates using floor division
      // This converts continuous position to discrete grid coordinates
      final cellX = (p.position.dx / cellSize).floor();
      final cellY = (p.position.dy / cellSize).floor();

      // Add particle to 3x3 neighborhood of cells (home cell + 8 neighbors)
      // This ensures we'll find all nearby particles when checking adjacent cells
      for (int nx = -1; nx <= 1; nx++) {
        for (int ny = -1; ny <= 1; ny++) {
          // Create cell coordinate by applying neighborhood offset
          final cell = GridCell(cellX + nx, cellY + ny);

          // Add particle index to this cell's list
          // putIfAbsent creates new list if cell doesn't exist yet
          grid.putIfAbsent(cell, () => []).add(i);
        }
      }
    }

    return grid;
  }
}
