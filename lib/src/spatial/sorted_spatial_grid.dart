/// Cell-sorted, structure-of-arrays spatial grid for fixed-radius pair search.
///
/// This library provides [SortedSpatialGrid], the data layout used by the
/// painter's hot connection loops.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:particles_network/src/core/particle.dart';
import 'package:particles_network/src/spatial/grid_tuning.dart';
import 'package:particles_network/src/spatial/scan_stats.dart';

const bool kReleaseMode = bool.fromEnvironment('dart.vm.product');

/// A uniform grid whose particles are counting-sorted by cell into flat
/// structure-of-arrays buffers.
///
/// Compared to traditional spatial grids (per-cell linked lists over `List<Particle>`),
/// every cell here is a contiguous range `[cellStart[c], cellStart[c + 1])`
/// of [xs] / [ys] / [indices]. Pair loops therefore scan sequential typed
/// memory instead of chasing `next` pointers and dereferencing `Particle`
/// objects, which is what dominates CPU time in dense networks.
///
/// Build cost: O(N + C) for N particles and C cells, with no allocations
/// once buffers have grown to size.
class SortedSpatialGrid {
  /// Tuning parameters governing cell density, safety floor, and bounds fitting.
  final GridTuning tuning;

  /// Creates a spatial grid with optional [tuning] configuration.
  SortedSpatialGrid({GridTuning? tuning})
      : tuning = tuning ?? const GridTuning();

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
  Int32List _validIndices = Int32List(0);

  /// Default cell density multiplier k = 4.0.
  static const double defaultCellMultiplierK =
      GridTuning.defaultCellMultiplierK;

  /// Default cell size floor (4.0 px) when line budgeting shrinks effective distance.
  static const double defaultMinCellFloor = GridTuning.defaultMinCellFloor;

  /// Absolute maximum total cells permitted in the grid to prevent memory explosion.
  static const int maxTotalCells = GridTuning.defaultMaxTotalCells;

  /// Maximum cell count multiplier relative to particle count (cells <= 4 * N).
  static const double maxCellsPerParticleFactor = 4.0;

  /// Profiling statistics container for spatial grid operations.
  static ScanStats get stats => ScanStats.instance;

  /// Number of candidate pairs visited in the inner scan loop before early rejection.
  static int get candidateChecks => stats.candidateChecks;
  static set candidateChecks(int value) => stats.candidateChecks = value;

  /// Dedicated counter for raw loop iterations visited across stencil cells.
  static int get loopIterations => stats.loopIterations;
  static set loopIterations(int value) => stats.loopIterations = value;

  /// Number of pairs/candidates within radius.
  static int get acceptedPairs => stats.acceptedPairs;
  static set acceptedPairs(int value) => stats.acceptedPairs = value;

  /// Cumulative stopwatch microseconds for profiling.
  static int get scanLoopMicros => stats.scanLoopMicros;
  static set scanLoopMicros(int value) => stats.scanLoopMicros = value;

  static int get gridBuildMicros => stats.gridBuildMicros;
  static set gridBuildMicros(int value) => stats.gridBuildMicros = value;

  static int get physicsMicros => stats.physicsMicros;
  static set physicsMicros(int value) => stats.physicsMicros = value;

  static int get emissionMicros => stats.emissionMicros;
  static set emissionMicros(int value) => stats.emissionMicros = value;

  static int get frameCount => stats.frameCount;
  static set frameCount(int value) => stats.frameCount = value;

  static Float64List get frameScanTimes => stats.frameScanTimes;
  static int get frameScanCount => stats.frameScanCount;
  static set frameScanCount(int value) => stats.frameScanCount = value;

  /// Ratio of candidate checks to accepted pairs.
  static double get ratio => stats.ratio;

  /// Resets instrumentation counters.
  static void resetCounters() => stats.reset();

  /// For testing: allows forcing profiling on in debug mode without `--dart-define`.
  @visibleForTesting
  static bool debugEnableProfiling = false;

  @pragma('vm:prefer-inline')
  static bool get _shouldProfile =>
      kParticlesProfile || (!kReleaseMode && debugEnableProfiling);

  /// Instance accessors forwarding to instrumentation counters.
  bool get isInstrumentationEnabled => _shouldProfile;
  int get currentCandidateChecks => stats.candidateChecks;
  int get currentLoopIterations => stats.loopIterations;
  int get currentAcceptedPairs => stats.acceptedPairs;
  double get currentRatio => stats.ratio;

  /// Sorts the [visible] subset of [particles] into cells for pair queries
  /// up to [radius] within a [width] × [height] area.
  ///
  /// If [visible] is null, all [particles] are indexed without extra list allocation.
  ///
  /// The cell size is `max(radius, sqrt(area / count))`: never smaller than
  /// the radius (so neighbours are always in adjacent cells), and coarse
  /// enough that the number of cells stays around the particle count even
  /// when the radius is tiny.
  /// An optional [cellMultiplier] scales the base cell size when fine-tuning,
  /// clamped so `cellSize` never falls below [radius].
  void build(
    List<Particle> particles,
    List<int>? visible,
    double width,
    double height,
    double radius, [
    double? cellMultiplier,
  ]) {
    final int rawCount = visible != null ? visible.length : particles.length;
    if (width <= 0 ||
        height <= 0 ||
        radius <= 0 ||
        rawCount == 0 ||
        particles.isEmpty) {
      cols = 0;
      rows = 0;
      count = 0;
      cellSize = 0;
      return;
    }

    double area = width * height;
    if (tuning.fitToBoundingBox && rawCount > 1) {
      double minX = double.infinity;
      double maxX = -double.infinity;
      double minY = double.infinity;
      double maxY = -double.infinity;
      for (int i = 0; i < rawCount; i++) {
        final int idx = visible != null ? visible[i] : i;
        if (idx < 0 || idx >= particles.length) continue;
        final Particle p = particles[idx];
        if (p.x < minX) minX = p.x;
        if (p.x > maxX) maxX = p.x;
        if (p.y < minY) minY = p.y;
        if (p.y > maxY) maxY = p.y;
      }
      if (maxX > minX && maxY > minY) {
        area = (maxX - minX) * (maxY - minY);
      }
    }
    final double k = tuning.cellMultiplierK > 0
        ? tuning.cellMultiplierK
        : GridTuning.defaultCellMultiplierK;
    final double densityCell = math.sqrt(area / (rawCount * k));
    final double minCell =
        densityCell > tuning.minCellFloor ? densityCell : tuning.minCellFloor;
    final double baseCell = radius > minCell ? radius : minCell;
    final double mult = (cellMultiplier != null &&
            cellMultiplier.isFinite &&
            cellMultiplier > 0)
        ? cellMultiplier
        : 1.0;
    final double scaledCell = baseCell * mult;
    double finalCell = scaledCell < radius ? radius : scaledCell;
    final double floorVal = tuning.minCellFloor;
    if (finalCell < floorVal) {
      finalCell = floorVal;
    }

    // Guard against cell-count blowup (Condition 4):
    // Cap total cells to min(maxTotalCells, max(4 * N, 1024)).
    final int cellCap = math.min(
      tuning.maxTotalCells,
      math.max((rawCount * maxCellsPerParticleFactor).toInt(), 1024),
    );
    final double minCellForCap = math.sqrt(area / cellCap);
    if (finalCell < minCellForCap) {
      finalCell = minCellForCap;
    }
    // Fundamental half-stencil invariant: cellSize must never fall below query radius.
    if (finalCell < radius) {
      finalCell = radius;
    }

    cellSize = finalCell;
    double inv = 1.0 / cellSize;
    int cCols = (width * inv).ceil() + 1;
    int cRows = (height * inv).ceil() + 1;
    int cells = cCols * cRows;

    // In case ceil() + 1 pushed cell count slightly over the cap:
    while (cells > cellCap && cellSize < math.max(width, height)) {
      final double ratio = math.sqrt(cells / cellCap) * 1.02;
      cellSize *= ratio;
      if (cellSize < radius) cellSize = radius;
      inv = 1.0 / cellSize;
      cCols = (width * inv).ceil() + 1;
      cRows = (height * inv).ceil() + 1;
      final int newCells = cCols * cRows;
      if (newCells >= cells) break; // Clamped by radius
      cells = newCells;
    }

    cols = cCols;
    rows = cRows;

    if (cellStart.length < cells + 1) {
      cellStart = Int32List(((cells + 1) * 1.25).ceil());
    }
    if (xs.length < rawCount) {
      final int cap = (rawCount * 1.25).ceil();
      xs = Float64List(cap);
      ys = Float64List(cap);
      indices = Int32List(cap);
      _cellOf = Int32List(cap);
      _validIndices = Int32List(cap);
    }

    final Int32List start = cellStart;
    final Int32List cellOf = _cellOf;
    final Int32List validIndices = _validIndices;
    start.fillRange(0, cells + 1, 0);

    // Pass 1: validate indices, compute cell of each particle and per-cell counts (stored at c + 1).
    final int maxCx = cols - 1;
    final int maxCy = rows - 1;
    int validCount = 0;
    for (int i = 0; i < rawCount; i++) {
      final int idx = visible != null ? visible[i] : i;
      if (idx < 0 || idx >= particles.length) continue;
      final Particle p = particles[idx];
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
      cellOf[validCount] = c;
      validIndices[validCount] = idx;
      start[c + 1]++;
      validCount++;
    }
    count = validCount;

    if (validCount == 0) {
      cols = 0;
      rows = 0;
      cellSize = 0;
      return;
    }

    // Pass 2: exclusive prefix sum -> start offsets.
    for (int c = 1; c <= cells; c++) {
      start[c] += start[c - 1];
    }

    // Pass 3: scatter. Uses start[c] as a write cursor, then shifts back.
    for (int i = 0; i < validCount; i++) {
      final int c = cellOf[i];
      final int dst = start[c]++;
      final int idx = validIndices[i];
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

  /// Whether the grid has been successfully initialized and populated with at least one particle.
  bool get isInitialized => cols > 0 && rows > 0 && count > 0 && cellSize > 0;

  /// Returns the number of particles contained in grid cell ([cx], [cy]).
  ///
  /// Returns 0 if coordinates are out of bounds or the grid is uninitialized.
  int particleCountInCell(int cx, int cy) {
    if (cx < 0 || cx >= cols || cy < 0 || cy >= rows) return 0;
    final int c = cy * cols + cx;
    return cellStart[c + 1] - cellStart[c];
  }

  /// Returns the number of particles contained in the cell corresponding to world coordinates ([x], [y]).
  ///
  /// Returns 0 if coordinates are non-finite or out of bounds.
  int particleCountAt(double x, double y) {
    if (!isInitialized || !x.isFinite || !y.isFinite) return 0;
    final int cx = (x / cellSize).floor();
    final int cy = (y / cellSize).floor();
    return particleCountInCell(cx, cy);
  }

  /// Finds all particles within Euclidean distance [radius] of point ([x], [y])
  /// and invokes [visitor] for each matching candidate.
  ///
  /// [visitor] receives:
  /// - `particleIndex`: The original index in the source particle list.
  /// - `px`: The x-coordinate of the particle.
  /// - `py`: The y-coordinate of the particle.
  /// - `distSq`: The squared Euclidean distance between ([x], [y]) and (`px`, `py`).
  void queryRadius(
    double x,
    double y,
    double radius,
    void Function(int particleIndex, double px, double py, double distSq)
        visitor,
  ) {
    if (!isInitialized ||
        !x.isFinite ||
        !y.isFinite ||
        !radius.isFinite ||
        radius <= 0) {
      return;
    }

    final double inv = 1.0 / cellSize;
    int minCx = ((x - radius) * inv).floor();
    int maxCx = ((x + radius) * inv).floor();
    int minCy = ((y - radius) * inv).floor();
    int maxCy = ((y + radius) * inv).floor();

    if (maxCx < 0 || minCx >= cols || maxCy < 0 || minCy >= rows) {
      return;
    }

    if (minCx < 0) minCx = 0;
    if (maxCx >= cols) maxCx = cols - 1;
    if (minCy < 0) minCy = 0;
    if (maxCy >= rows) maxCy = rows - 1;

    final double radiusSq = radius * radius;
    final Int32List start = cellStart;
    final Float64List pXs = xs;
    final Float64List pYs = ys;
    final Int32List pIndices = indices;
    final int cCols = cols;

    for (int cy = minCy; cy <= maxCy; cy++) {
      final int rowStart = cy * cCols;
      for (int cx = minCx; cx <= maxCx; cx++) {
        final int c = rowStart + cx;
        final int cellEnd = start[c + 1];
        for (int k = start[c]; k < cellEnd; k++) {
          if (_shouldProfile) {
            stats.candidateChecks++;
            stats.loopIterations++;
          }
          final double px = pXs[k];
          final double dx = x - px;
          if (dx > radius || dx < -radius) continue;

          final double py = pYs[k];
          final double dy = y - py;
          if (dy > radius || dy < -radius) continue;

          final double distSq = dx * dx + dy * dy;
          if (distSq <= radiusSq) {
            if (_shouldProfile) {
              stats.acceptedPairs++;
            }
            visitor(pIndices[k], px, py, distSq);
          }
        }
      }
    }
  }

  /// Finds all particles whose positions lie inside the axis-aligned bounding box
  /// `[minX, maxX] x [minY, maxY]`, invoking [visitor] for each matching particle.
  void queryRect(
    double minX,
    double minY,
    double maxX,
    double maxY,
    void Function(int particleIndex, double px, double py) visitor,
  ) {
    if (!isInitialized ||
        !minX.isFinite ||
        !minY.isFinite ||
        !maxX.isFinite ||
        !maxY.isFinite ||
        minX > maxX ||
        minY > maxY) {
      return;
    }

    final double inv = 1.0 / cellSize;
    int minCx = (minX * inv).floor();
    int maxCx = (maxX * inv).floor();
    int minCy = (minY * inv).floor();
    int maxCy = (maxY * inv).floor();

    if (maxCx < 0 || minCx >= cols || maxCy < 0 || minCy >= rows) {
      return;
    }

    if (minCx < 0) minCx = 0;
    if (maxCx >= cols) maxCx = cols - 1;
    if (minCy < 0) minCy = 0;
    if (maxCy >= rows) maxCy = rows - 1;

    final Int32List start = cellStart;
    final Float64List pXs = xs;
    final Float64List pYs = ys;
    final Int32List pIndices = indices;
    final int cCols = cols;

    for (int cy = minCy; cy <= maxCy; cy++) {
      final int rowStart = cy * cCols;
      for (int cx = minCx; cx <= maxCx; cx++) {
        final int c = rowStart + cx;
        final int cellEnd = start[c + 1];
        for (int k = start[c]; k < cellEnd; k++) {
          final double px = pXs[k];
          if (px < minX || px > maxX) continue;

          final double py = pYs[k];
          if (py < minY || py > maxY) continue;

          visitor(pIndices[k], px, py);
        }
      }
    }
  }

  /// Iterates all unique particle pairs within Euclidean distance [maxDistance]
  /// across the grid in O(N) time with zero allocations.
  ///
  /// Prunes duplicate pairs by searching strictly within the cell and its
  /// 4 forward neighbors: East, South-East, South, and South-West.
  void forEachPair(
    double maxDistance,
    void Function(int i1, int i2, double distSq) visitor,
  ) {
    if (!isInitialized || !maxDistance.isFinite || maxDistance <= 0) return;

    final double maxDistSq = maxDistance * maxDistance;
    final Int32List start = cellStart;
    final Float64List pXs = xs;
    final Float64List pYs = ys;
    final Int32List pIndices = indices;
    final int cCols = cols;
    final int cRows = rows;

    for (int cy = 0; cy < cRows; cy++) {
      final int rowOffset = cy * cCols;
      final bool hasSouth = cy + 1 < cRows;
      final int southRowOffset = (cy + 1) * cCols;

      for (int cx = 0; cx < cCols; cx++) {
        final int c = rowOffset + cx;
        final int cellEnd = start[c + 1];
        final int cellBegin = start[c];
        if (cellBegin >= cellEnd) continue;

        // Intra-cell pairs (k1 < k2)
        for (int k1 = cellBegin; k1 < cellEnd; k1++) {
          final double x1 = pXs[k1];
          final double y1 = pYs[k1];
          final int idx1 = pIndices[k1];

          for (int k2 = k1 + 1; k2 < cellEnd; k2++) {
            if (_shouldProfile) {
              stats.candidateChecks++;
              stats.loopIterations++;
            }
            final double dx = x1 - pXs[k2];
            if (dx > maxDistance || dx < -maxDistance) continue;
            final double dy = y1 - pYs[k2];
            if (dy > maxDistance || dy < -maxDistance) continue;

            final double distSq = dx * dx + dy * dy;
            if (distSq <= maxDistSq) {
              if (_shouldProfile) {
                stats.acceptedPairs++;
              }
              visitor(idx1, pIndices[k2], distSq);
            }
          }
        }

        // Neighbor cell 1: East (cx + 1, cy)
        if (cx + 1 < cCols) {
          _pairWithCell(cellBegin, cellEnd, rowOffset + cx + 1, maxDistance,
              maxDistSq, visitor);
        }

        if (hasSouth) {
          // Neighbor cell 2: South-West (cx - 1, cy + 1)
          if (cx > 0) {
            _pairWithCell(cellBegin, cellEnd, southRowOffset + cx - 1,
                maxDistance, maxDistSq, visitor);
          }
          // Neighbor cell 3: South (cx, cy + 1)
          _pairWithCell(cellBegin, cellEnd, southRowOffset + cx, maxDistance,
              maxDistSq, visitor);
          // Neighbor cell 4: South-East (cx + 1, cy + 1)
          if (cx + 1 < cCols) {
            _pairWithCell(cellBegin, cellEnd, southRowOffset + cx + 1,
                maxDistance, maxDistSq, visitor);
          }
        }
      }
    }
  }

  void _pairWithCell(
    int cellBegin,
    int cellEnd,
    int neighborCell,
    double maxDist,
    double maxDistSq,
    void Function(int i1, int i2, double distSq) visitor,
  ) {
    final int nEnd = cellStart[neighborCell + 1];
    final int nBegin = cellStart[neighborCell];
    if (nBegin >= nEnd) return;

    final Float64List pXs = xs;
    final Float64List pYs = ys;
    final Int32List pIndices = indices;

    for (int k1 = cellBegin; k1 < cellEnd; k1++) {
      final double x1 = pXs[k1];
      final double y1 = pYs[k1];
      final int idx1 = pIndices[k1];

      for (int k2 = nBegin; k2 < nEnd; k2++) {
        if (_shouldProfile) {
          stats.candidateChecks++;
          stats.loopIterations++;
        }
        final double dx = x1 - pXs[k2];
        if (dx > maxDist || dx < -maxDist) continue;
        final double dy = y1 - pYs[k2];
        if (dy > maxDist || dy < -maxDist) continue;

        final double distSq = dx * dx + dy * dy;
        if (distSq <= maxDistSq) {
          if (_shouldProfile) {
            stats.acceptedPairs++;
          }
          visitor(idx1, pIndices[k2], distSq);
        }
      }
    }
  }

  /// Iterates all particles currently stored in the grid in contiguous SoA memory order.
  void forEachParticle(
      void Function(int particleIndex, double px, double py) visitor) {
    if (!isInitialized) return;
    final int n = count;
    final Float64List pXs = xs;
    final Float64List pYs = ys;
    final Int32List pIndices = indices;
    for (int i = 0; i < n; i++) {
      visitor(pIndices[i], pXs[i], pYs[i]);
    }
  }

  /// Finds nearby particle indices within [radius] of point ([x], [y])
  /// and writes them to [output]. Drop-in replacement for legacy spatial APIs.
  void findNearbyParticlesToOutput(
    double x,
    double y,
    double radius,
    List<int> output,
  ) {
    output.clear();
    queryRadius(x, y, radius, (particleIndex, px, py, distSq) {
      output.add(particleIndex);
    });
  }

  /// Clears the grid state.
  void clear() {
    cols = 0;
    rows = 0;
    count = 0;
    cellSize = 0;
    if (cellStart.isNotEmpty) {
      cellStart[0] = 0;
    }
  }
}
