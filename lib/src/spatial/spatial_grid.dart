/// High-performance 2D Uniform Spatial Hash Grid for particle neighbor queries.
///
/// This library provides the [SpatialGrid] class, an alternative spatial
/// partitioning structure designed for fixed-radius particle queries with zero
/// heap allocations per frame.
library;

import 'dart:typed_data';

import 'package:particles_network/src/core/particle.dart';

/// A 2D uniform spatial grid for efficient neighbor queries.
///
/// Mathematical Foundations:
/// - Divides 2D space into uniform square cells of size [cellSize].
/// - Any two particles within Euclidean distance $R \le \text{cellSize}$ must
///   reside in the same cell or in immediately adjacent neighbor cells (at most 9 cells).
///
/// Performance Characteristics:
/// - Grid build time: $O(N)$ with zero allocations per frame.
/// - Neighbor queries: $O(1)$ cell lookups (checking at most 9 cells).
/// - Memory footprint: Flat contiguous [Int32List] memory.
class SpatialGrid {
  /// The size of each grid cell (typically set to `lineDistance`).
  double cellSize;

  /// Cached inverse cell size to replace division with multiplication.
  double invCellSize;

  /// Number of columns in the grid.
  int cols = 0;

  /// Number of rows in the grid.
  int rows = 0;

  /// Head pointers for each cell's linked list of particle indices.
  Int32List cellHeads = Int32List(0);

  /// Next pointers linking particles belonging to the same cell.
  Int32List particleNext = Int32List(0);

  /// Indices of currently populated cells for O(N) clearing and direct traversal.
  Int32List activeCells = Int32List(0);

  /// Number of active populated cells in the current frame.
  int activeCellsCount = 0;

  /// Creates a [SpatialGrid] with the specified [cellSize].
  SpatialGrid({required this.cellSize})
      : invCellSize = cellSize > 0 ? 1.0 / cellSize : 0.0;

  /// Updates the cell size and recomputes the inverse cell size.
  void updateCellSize(double size) {
    cellSize = size;
    invCellSize = size > 0 ? 1.0 / size : 0.0;
  }

  /// Builds or rebuilds the spatial grid from visible particles.
  ///
  /// Reuses existing [Int32List] buffers without allocating objects on the heap.
  /// Achieves O(N) build and reset complexity by tracking active cells.
  void build(
    List<Particle> particles,
    List<int> visibleIndices,
    double width,
    double height,
  ) {
    if (width <= 0 || height <= 0 || cellSize <= 0) return;

    final int newCols = (width * invCellSize).ceil() + 1;
    final int newRows = (height * invCellSize).ceil() + 1;
    final int totalCells = newCols * newRows;

    final bool dimensionChanged =
        newCols != cols || newRows != rows || cellHeads.length < totalCells;
    cols = newCols;
    rows = newRows;

    if (dimensionChanged) {
      if (cellHeads.length < totalCells) {
        // Over-allocate by 20% to amortize reallocation cost during resize
        cellHeads = Int32List((totalCells * 1.2).ceil());
      }
      cellHeads.fillRange(0, totalCells, -1);
      activeCellsCount = 0;
    } else {
      // Fast O(N) reset: only clear cells that had particles in the previous frame
      for (int i = 0; i < activeCellsCount; i++) {
        cellHeads[activeCells[i]] = -1;
      }
      activeCellsCount = 0;
    }

    final int visibleCount = visibleIndices.length;
    if (activeCells.length < visibleCount) {
      // Over-allocate by 25% to amortize growth on particle count increase
      activeCells = Int32List((visibleCount * 1.25).ceil());
    }

    // Grow particle next pointers buffer if needed
    final int n = particles.length;
    if (particleNext.length < n) {
      particleNext = Int32List(n);
    }

    for (int i = 0; i < visibleCount; i++) {
      final int idx = visibleIndices[i];
      final Particle p = particles[idx];

      int cx = (p.x * invCellSize).toInt();
      int cy = (p.y * invCellSize).toInt();

      if (cx < 0) {
        cx = 0;
      } else if (cx >= cols) {
        cx = cols - 1;
      }

      if (cy < 0) {
        cy = 0;
      } else if (cy >= rows) {
        cy = rows - 1;
      }

      final int cell = cy * cols + cx;
      final int currentHead = cellHeads[cell];
      if (currentHead == -1) {
        activeCells[activeCellsCount++] = cell;
      }
      particleNext[idx] = currentHead;
      cellHeads[cell] = idx;
    }
  }

  /// Finds nearby particle indices within [radius] of point ([x], [y])
  /// and writes them to [output].
  void findNearbyParticlesToOutput(
    double x,
    double y,
    double radius,
    List<int> output,
  ) {
    output.clear();
    if (cols <= 0 || rows <= 0) return;

    int cx = (x * invCellSize).toInt();
    int cy = (y * invCellSize).toInt();
    if (cx < 0) cx = 0;
    if (cx >= cols) cx = cols - 1;
    if (cy < 0) cy = 0;
    if (cy >= rows) cy = rows - 1;

    final int cellRadius = (radius * invCellSize).ceil();
    final int minCx = (cx - cellRadius).clamp(0, cols - 1);
    final int maxCx = (cx + cellRadius).clamp(0, cols - 1);
    final int minCy = (cy - cellRadius).clamp(0, rows - 1);
    final int maxCy = (cy + cellRadius).clamp(0, rows - 1);

    for (int cy = minCy; cy <= maxCy; cy++) {
      final int rowOffset = cy * cols;
      for (int cx = minCx; cx <= maxCx; cx++) {
        int idx = cellHeads[rowOffset + cx];
        while (idx != -1) {
          output.add(idx);
          idx = particleNext[idx];
        }
      }
    }
  }

  /// Clears the grid state.
  void clear() {
    if (cellHeads.isNotEmpty) {
      if (activeCellsCount > 0) {
        for (int i = 0; i < activeCellsCount; i++) {
          cellHeads[activeCells[i]] = -1;
        }
        activeCellsCount = 0;
      } else {
        cellHeads.fillRange(0, cellHeads.length, -1);
      }
    }
    cols = 0;
    rows = 0;
  }
}
