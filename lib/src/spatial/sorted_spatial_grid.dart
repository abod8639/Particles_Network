/// Cell-sorted, structure-of-arrays spatial grid for fixed-radius pair search.
///
/// This library provides [SortedSpatialGrid], the data layout used by the
/// painter's hot connection loops.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:particles_network/src/core/particle.dart';

/// A uniform grid whose particles are counting-sorted by cell into flat
/// structure-of-arrays buffers.
///
/// Compared to [SpatialGrid] (per-cell linked lists over `List<Particle>`),
/// every cell here is a contiguous range `[cellStart[c], cellStart[c + 1])`
/// of [xs] / [ys] / [indices]. Pair loops therefore scan sequential typed
/// memory instead of chasing `next` pointers and dereferencing `Particle`
/// objects, which is what dominates CPU time in dense networks.
///
/// Build cost: O(N + C) for N particles and C cells, with no allocations
/// once buffers have grown to size.
class SortedSpatialGrid {
  /// Edge length of a cell; always >= the query radius passed to [build].
  double cellSize = 0;

  /// Number of columns in the grid.
  int cols = 0;

  /// Number of rows in the grid.
  int rows = 0;

  /// Number of particles stored in the grid.
  int count = 0;

  /// Prefix offsets: particles of cell `c` occupy
  /// `[cellStart[c], cellStart[c + 1])`. Length is at least `cols * rows + 1`.
  Int32List cellStart = Int32List(1);

  /// X coordinate of each sorted particle.
  Float64List xs = Float64List(0);

  /// Y coordinate of each sorted particle.
  Float64List ys = Float64List(0);

  /// Index into the source particle list of each sorted particle.
  Int32List indices = Int32List(0);

  Int32List _cellOf = Int32List(0);

  /// Sorts the [visible] subset of [particles] into cells for pair queries
  /// up to [radius] within a [width] × [height] area.
  ///
  /// The cell size is `max(radius, sqrt(area / count))`: never smaller than
  /// the radius (so neighbours are always in adjacent cells), and coarse
  /// enough that the number of cells stays around the particle count even
  /// when the radius is tiny.
  void build(
    List<Particle> particles,
    List<int> visible,
    double width,
    double height,
    double radius,
  ) {
    final int n = visible.length;
    count = n;
    if (width <= 0 || height <= 0 || radius <= 0 || n == 0) {
      cols = 0;
      rows = 0;
      return;
    }

    final double minCell = math.sqrt(width * height / n);
    cellSize = radius > minCell ? radius : minCell;
    final double inv = 1.0 / cellSize;
    cols = (width * inv).ceil() + 1;
    rows = (height * inv).ceil() + 1;
    final int cells = cols * rows;

    if (cellStart.length < cells + 1) {
      cellStart = Int32List(((cells + 1) * 1.25).ceil());
    }
    if (xs.length < n) {
      final int cap = (n * 1.25).ceil();
      xs = Float64List(cap);
      ys = Float64List(cap);
      indices = Int32List(cap);
      _cellOf = Int32List(cap);
    }

    final Int32List start = cellStart;
    final Int32List cellOf = _cellOf;
    start.fillRange(0, cells + 1, 0);

    // Pass 1: cell of each particle and per-cell counts (stored at c + 1).
    final int maxCx = cols - 1;
    final int maxCy = rows - 1;
    for (int i = 0; i < n; i++) {
      final Particle p = particles[visible[i]];
      int cx = (p.x * inv).toInt();
      int cy = (p.y * inv).toInt();
      if (cx < 0) {
        cx = 0;
      } else if (cx > maxCx) {
        cx = maxCx;
      }
      if (cy < 0) {
        cy = 0;
      } else if (cy > maxCy) {
        cy = maxCy;
      }
      final int c = cy * cols + cx;
      cellOf[i] = c;
      start[c + 1]++;
    }

    // Pass 2: exclusive prefix sum -> start offsets.
    for (int c = 1; c <= cells; c++) {
      start[c] += start[c - 1];
    }

    // Pass 3: scatter. Uses start[c] as a write cursor, then shifts back.
    for (int i = 0; i < n; i++) {
      final int c = cellOf[i];
      final int dst = start[c]++;
      final int idx = visible[i];
      final Particle p = particles[idx];
      xs[dst] = p.x;
      ys[dst] = p.y;
      indices[dst] = idx;
    }
    for (int c = cells; c > 0; c--) {
      start[c] = start[c - 1];
    }
    start[0] = 0;
  }
}
