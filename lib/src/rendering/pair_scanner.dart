import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:particles_network/src/spatial/scan_stats.dart';
import 'package:particles_network/src/spatial/sorted_spatial_grid.dart';

import 'candidate_buffer.dart';
import 'cluster_throttler.dart';
import 'line_buckets.dart';
import 'network_performance.dart';

const bool kReleaseMode = bool.fromEnvironment('dart.vm.product');

/// Single source of truth for the spatial half-stencil neighbor pair scan.
///
/// Implements concrete, flat-loop neighbor searches over SoA typed arrays
/// ([SortedSpatialGrid.xs], [SortedSpatialGrid.ys], [SortedSpatialGrid.cellStart]).
/// Zero virtual dispatch or closures per pair; typed arrays and constants are
/// hoisted into local variables before loop entry.
class PairScanner {
  const PairScanner();

  /// Scans pairs using the ultra-fast uncapped, non-complex path directly into [buckets].
  void scanBatchedFast({
    required SortedSpatialGrid grid,
    required double maxDistSq,
    required double invMaxDistSq,
    required LineBuckets buckets,
  }) {
    final int cols = grid.cols;
    final int rows = grid.rows;
    if (cols <= 0 || rows <= 0) return;

    final Int32List start = grid.cellStart;
    final Float64List xs = grid.xs;
    final Float64List ys = grid.ys;

    for (int cy = 0; cy < rows; cy++) {
      final bool hasSouth = cy < rows - 1;
      final int rowBase = cy * cols;
      for (int cx = 0; cx < cols; cx++) {
        final int c = rowBase + cx;
        final int cellEnd = start[c + 1];
        int i = start[c];
        if (i == cellEnd) continue;

        final bool hasEast = cx < cols - 1;
        final int nearEnd = hasEast ? start[c + 2] : cellEnd;
        int southStart = 0;
        int southEnd = 0;
        if (hasSouth) {
          final int south = c + cols;
          southStart = start[cx > 0 ? south - 1 : south];
          southEnd = start[(hasEast ? south + 1 : south) + 1];
        }

        for (; i < cellEnd; i++) {
          final double x1 = xs[i];
          final double y1 = ys[i];

          for (int j = i + 1; j < nearEnd; j++) {
            if (kParticlesProfile ||
                (!kReleaseMode && SortedSpatialGrid.enableInstrumentation)) {
              SortedSpatialGrid.stats.candidateChecks++;
              SortedSpatialGrid.stats.loopIterations++;
            }
            final double dx = x1 - xs[j];
            final double dxSq = dx * dx;
            if (dxSq > maxDistSq) continue;
            final double dy = y1 - ys[j];
            final double distSq = dxSq + dy * dy;
            if (distSq <= maxDistSq) {
              if (kParticlesProfile ||
                  (!kReleaseMode && SortedSpatialGrid.enableInstrumentation)) {
                SortedSpatialGrid.stats.acceptedPairs++;
              }
              buckets.emitLine(
                x1: x1,
                y1: y1,
                x2: xs[j],
                y2: ys[j],
                distSq: distSq,
                invMaxDistSq: invMaxDistSq,
              );
            }
          }

          for (int j = southStart; j < southEnd; j++) {
            if (kParticlesProfile ||
                (!kReleaseMode && SortedSpatialGrid.enableInstrumentation)) {
              SortedSpatialGrid.stats.candidateChecks++;
              SortedSpatialGrid.stats.loopIterations++;
            }
            final double dx = x1 - xs[j];
            final double dxSq = dx * dx;
            if (dxSq > maxDistSq) continue;
            final double dy = y1 - ys[j];
            final double distSq = dxSq + dy * dy;
            if (distSq <= maxDistSq) {
              if (kParticlesProfile ||
                  (!kReleaseMode && SortedSpatialGrid.enableInstrumentation)) {
                SortedSpatialGrid.stats.acceptedPairs++;
              }
              buckets.emitLine(
                x1: x1,
                y1: y1,
                x2: xs[j],
                y2: ys[j],
                distSq: distSq,
                invMaxDistSq: invMaxDistSq,
              );
            }
          }
        }
      }
    }
  }

  /// Scans pairs with degree capping and/or complex cluster throttling into [buckets].
  void scanBatchedComplex({
    required SortedSpatialGrid grid,
    required double maxDistSq,
    required double invMaxDistSq,
    required double scanDistance,
    required LineBuckets buckets,
    required CandidateBuffer candidateBuffer,
    required ClusterThrottler throttler,
    required NetworkPerformance performance,
    required int? maxConnectionsPerParticle,
    required bool isComplexMode,
  }) {
    final int cols = grid.cols;
    final int rows = grid.rows;
    if (cols <= 0 || rows <= 0) return;

    final Int32List start = grid.cellStart;
    final Float64List xs = grid.xs;
    final Float64List ys = grid.ys;

    final bool capped = maxConnectionsPerParticle != null;
    final int cap = maxConnectionsPerParticle ?? 0;
    final Int32List counts = capped
        ? candidateBuffer.getClearedConnectionCounts(grid.count)
        : candidateBuffer.connectionCounts;

    final int denseThreshold = throttler.computeDenseThreshold(
      distance: scanDistance,
      performance: performance,
    );
    final int maxComplexLines = performance.maxComplexLines ?? 5;

    for (int cy = 0; cy < rows; cy++) {
      final bool hasSouth = cy < rows - 1;
      final int rowBase = cy * cols;
      for (int cx = 0; cx < cols; cx++) {
        final int c = rowBase + cx;
        final int cellEnd = start[c + 1];
        int i = start[c];
        if (i == cellEnd) continue;

        final bool hasEast = cx < cols - 1;
        final int nearEnd = hasEast ? start[c + 2] : cellEnd;
        int southStart = 0;
        int southEnd = 0;
        if (hasSouth) {
          final int south = c + cols;
          southStart = start[cx > 0 ? south - 1 : south];
          southEnd = start[(hasEast ? south + 1 : south) + 1];
        }

        for (; i < cellEnd; i++) {
          if (capped && counts[i] >= cap) continue;
          final double x1 = xs[i];
          final double y1 = ys[i];

          int candidateCount = 0;
          for (int j = i + 1; j < nearEnd; j++) {
            if (kParticlesProfile ||
                (!kReleaseMode && SortedSpatialGrid.enableInstrumentation)) {
              SortedSpatialGrid.stats.candidateChecks++;
              SortedSpatialGrid.stats.loopIterations++;
            }
            if (capped && counts[j] >= cap) continue;
            final double dx = x1 - xs[j];
            final double dxSq = dx * dx;
            if (dxSq > maxDistSq) continue;
            final double dy = y1 - ys[j];
            final double distSq = dxSq + dy * dy;
            if (distSq <= maxDistSq) {
              if (kParticlesProfile ||
                  (!kReleaseMode && SortedSpatialGrid.enableInstrumentation)) {
                SortedSpatialGrid.stats.acceptedPairs++;
              }
              if (candidateCount >= candidateBuffer.capacity) {
                candidateBuffer.ensureCapacity(candidateCount + 1);
              }
              candidateBuffer.indices[candidateCount] = j;
              candidateBuffer.distSq[candidateCount] = distSq;
              candidateCount++;
            }
          }

          for (int j = southStart; j < southEnd; j++) {
            if (kParticlesProfile ||
                (!kReleaseMode && SortedSpatialGrid.enableInstrumentation)) {
              SortedSpatialGrid.stats.candidateChecks++;
              SortedSpatialGrid.stats.loopIterations++;
            }
            if (capped && counts[j] >= cap) continue;
            final double dx = x1 - xs[j];
            final double dxSq = dx * dx;
            if (dxSq > maxDistSq) continue;
            final double dy = y1 - ys[j];
            final double distSq = dxSq + dy * dy;
            if (distSq <= maxDistSq) {
              if (kParticlesProfile ||
                  (!kReleaseMode && SortedSpatialGrid.enableInstrumentation)) {
                SortedSpatialGrid.stats.acceptedPairs++;
              }
              if (candidateCount >= candidateBuffer.capacity) {
                candidateBuffer.ensureCapacity(candidateCount + 1);
              }
              candidateBuffer.indices[candidateCount] = j;
              candidateBuffer.distSq[candidateCount] = distSq;
              candidateCount++;
            }
          }

          if (candidateCount == 0) continue;

          final int remainingCap = capped ? (cap - counts[i]) : candidateCount;
          final int drawCount = throttler.filterCandidates(
            buffer: candidateBuffer,
            candidateCount: candidateCount,
            isCapped: capped,
            remainingCap: remainingCap,
            denseThreshold: denseThreshold,
            defaultMaxLines: maxComplexLines,
            isComplexMode: isComplexMode,
            performance: performance,
          );
          if (drawCount <= 0) continue;

          final bool isThrottled = drawCount < candidateCount;
          final Int32List candIndices = candidateBuffer.indices;
          final Float64List candDistSq = candidateBuffer.distSq;

          for (int k = 0; k < drawCount; k++) {
            final int j = candIndices[k];
            final double distSq = candDistSq[k];

            double rankFade = 1.0;
            if (isComplexMode && isThrottled && drawCount > 1) {
              rankFade = throttler.calculateComplexLineFade(k, drawCount);
            }

            buckets.emitLine(
              x1: x1,
              y1: y1,
              x2: xs[j],
              y2: ys[j],
              distSq: distSq,
              invMaxDistSq: invMaxDistSq,
              rankFade: rankFade,
            );

            if (capped) {
              counts[i]++;
              counts[j]++;
            }
          }
        }
      }
    }
  }

  /// Scans and renders individual lines directly to [canvas] for small scenes (N < 30).
  int scanIndividual({
    required Canvas canvas,
    required SortedSpatialGrid grid,
    required double scanDistance,
    required double maxDistSq,
    required List<Color> lineColorLut,
    required Paint linePaint,
    required CandidateBuffer candidateBuffer,
    required ClusterThrottler throttler,
    required NetworkPerformance performance,
    required int? maxConnectionsPerParticle,
    required bool isComplexMode,
  }) {
    final int cols = grid.cols;
    final int rows = grid.rows;
    if (cols <= 0 || rows <= 0) return 0;

    final Int32List start = grid.cellStart;
    final Float64List xs = grid.xs;
    final Float64List ys = grid.ys;

    final double invLineDistance =
        scanDistance > 0 ? 255.0 / scanDistance : 0.0;
    final int defaultMaxLines =
        performance.maxComplexLines ?? (performance.isComplex ? 3 : 5);
    final int denseThreshold = throttler.computeDenseThreshold(
      distance: scanDistance,
      performance: performance,
      isIndividual: true,
    );

    final bool capped = maxConnectionsPerParticle != null;
    final int cap = maxConnectionsPerParticle ?? 0;
    final Int32List counts = capped
        ? candidateBuffer.getClearedConnectionCounts(grid.count)
        : candidateBuffer.connectionCounts;

    int lineCount = 0;
    final Color previousColor = linePaint.color;

    try {
      for (int cy = 0; cy < rows; cy++) {
        final bool hasSouth = cy < rows - 1;
        final int rowBase = cy * cols;
        for (int cx = 0; cx < cols; cx++) {
          final int c = rowBase + cx;
          final int cellEnd = start[c + 1];
          int i = start[c];
          if (i == cellEnd) continue;

          final bool hasEast = cx < cols - 1;
          final int nearEnd = hasEast ? start[c + 2] : cellEnd;
          int southStart = 0;
          int southEnd = 0;
          if (hasSouth) {
            final int south = c + cols;
            southStart = start[cx > 0 ? south - 1 : south];
            southEnd = start[(hasEast ? south + 1 : south) + 1];
          }

          for (; i < cellEnd; i++) {
            if (capped && counts[i] >= cap) continue;
            final double px = xs[i];
            final double py = ys[i];

            int candidateCount = 0;
            for (int j = i + 1; j < nearEnd; j++) {
              if (kParticlesProfile ||
                  (!kReleaseMode && SortedSpatialGrid.enableInstrumentation)) {
                SortedSpatialGrid.stats.candidateChecks++;
                SortedSpatialGrid.stats.loopIterations++;
              }
              if (capped && counts[j] >= cap) continue;
              final double dx = px - xs[j];
              final double dxSq = dx * dx;
              if (dxSq > maxDistSq) continue;
              final double dy = py - ys[j];
              final double distSq = dxSq + dy * dy;
              if (distSq <= maxDistSq) {
                if (kParticlesProfile ||
                    (!kReleaseMode &&
                        SortedSpatialGrid.enableInstrumentation)) {
                  SortedSpatialGrid.stats.acceptedPairs++;
                }
                if (candidateCount >= candidateBuffer.capacity) {
                  candidateBuffer.ensureCapacity(candidateCount + 1);
                }
                candidateBuffer.indices[candidateCount] = j;
                candidateBuffer.distSq[candidateCount] = distSq;
                candidateCount++;
              }
            }

            for (int j = southStart; j < southEnd; j++) {
              if (kParticlesProfile ||
                  (!kReleaseMode && SortedSpatialGrid.enableInstrumentation)) {
                SortedSpatialGrid.stats.candidateChecks++;
                SortedSpatialGrid.stats.loopIterations++;
              }
              if (capped && counts[j] >= cap) continue;
              final double dx = px - xs[j];
              final double dxSq = dx * dx;
              if (dxSq > maxDistSq) continue;
              final double dy = py - ys[j];
              final double distSq = dxSq + dy * dy;
              if (distSq <= maxDistSq) {
                if (kParticlesProfile ||
                    (!kReleaseMode &&
                        SortedSpatialGrid.enableInstrumentation)) {
                  SortedSpatialGrid.stats.acceptedPairs++;
                }
                if (candidateCount >= candidateBuffer.capacity) {
                  candidateBuffer.ensureCapacity(candidateCount + 1);
                }
                candidateBuffer.indices[candidateCount] = j;
                candidateBuffer.distSq[candidateCount] = distSq;
                candidateCount++;
              }
            }

            if (candidateCount == 0) continue;

            final int remainingCap =
                capped ? (cap - counts[i]) : candidateCount;
            final int drawCount = throttler.filterCandidates(
              buffer: candidateBuffer,
              candidateCount: candidateCount,
              isCapped: capped,
              remainingCap: remainingCap,
              denseThreshold: denseThreshold,
              defaultMaxLines: defaultMaxLines,
              isComplexMode: isComplexMode,
              performance: performance,
            );
            if (drawCount <= 0) continue;

            final bool isThrottled = drawCount < candidateCount;
            final Offset pos = Offset(px, py);
            final Int32List candIndices = candidateBuffer.indices;
            final Float64List candDistSq = candidateBuffer.distSq;

            for (int candIdx = 0; candIdx < drawCount; candIdx++) {
              final int j = candIndices[candIdx];
              final double distance = math.sqrt(candDistSq[candIdx]);
              int alpha =
                  (255 - (distance * invLineDistance)).toInt().clamp(0, 255);
              if (isThrottled && drawCount > 1) {
                final double rankFade =
                    throttler.calculateComplexLineFade(candIdx, drawCount);
                alpha = (alpha * rankFade).toInt().clamp(0, 255);
              }
              linePaint.color = lineColorLut[alpha];
              canvas.drawLine(pos, Offset(xs[j], ys[j]), linePaint);

              if (capped) {
                counts[i]++;
                counts[j]++;
              }
            }
            lineCount += drawCount;
          }
        }
      }
    } finally {
      linePaint.color = previousColor;
    }

    return lineCount;
  }
}
