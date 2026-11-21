import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:particles_network/src/spatial/scan_stats.dart';
import 'package:particles_network/src/spatial/sorted_spatial_grid.dart';

import 'candidate_buffer.dart';
import 'cluster_throttler.dart';
import 'line_buckets.dart';
import 'network_performance.dart';
import 'rendering_constants.dart';

/// Single source of truth for the spatial half-stencil neighbor pair scan.
///
/// Implements concrete, flat-loop neighbor searches over SoA typed arrays
/// ([SortedSpatialGrid.xs], [SortedSpatialGrid.ys], [SortedSpatialGrid.cellStart]).
/// Zero virtual dispatch or closures per pair; typed arrays and constants are
/// hoisted into local variables before loop entry.
///
/// Note on Half-Stencil & Degree Capping / Top-K:
/// - Degree capping is evaluated in first-come, first-served order as particles
///   are scanned in row-major grid order. Once a particle reaches its cap,
///   further candidate pairings with it are rejected.
/// - Top-k candidate selection only sees candidates j > i (and in neighboring cells
///   to the East and South) due to the half-stencil half-space optimization.
class PairScanner {
  const PairScanner();

  /// Scans pairs using the ultra-fast uncapped, non-complex path directly into [buckets].
  // Performance exception: This hot loop exceeds 50 lines to avoid per-pair
  // dispatch, closures, or helper function call overhead in the rendering hot path.
  // One specialized copy is maintained per variant per architecture specification.
  void scanBatchedFast({
    required SortedSpatialGrid grid,
    required double maxDistSq,
    required double invMaxDistSq,
    required LineBuckets buckets,
  }) {
    final int cols = grid.cols;
    final int rows = grid.rows;
    if (cols <= 0 || rows <= 0 || maxDistSq <= 0 || !maxDistSq.isFinite) {
      return;
    }

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
            if (kParticlesProfile) {
              ScanStats.instance.candidateChecks++;
              ScanStats.instance.loopIterations++;
            }
            final double dx = x1 - xs[j];
            final double dxSq = dx * dx;
            if (dxSq > maxDistSq) continue;
            final double dy = y1 - ys[j];
            final double distSq = dxSq + dy * dy;
            if (distSq <= maxDistSq) {
              if (kParticlesProfile) {
                ScanStats.instance.acceptedPairs++;
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
            if (kParticlesProfile) {
              ScanStats.instance.candidateChecks++;
              ScanStats.instance.loopIterations++;
            }
            final double dx = x1 - xs[j];
            final double dxSq = dx * dx;
            if (dxSq > maxDistSq) continue;
            final double dy = y1 - ys[j];
            final double distSq = dxSq + dy * dy;
            if (distSq <= maxDistSq) {
              if (kParticlesProfile) {
                ScanStats.instance.acceptedPairs++;
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

  /// Scans pairs using the capped or complex throttling path into [buckets].
  // Performance exception: This hot loop exceeds 50 lines to avoid per-pair
  // dispatch, closures, or helper function call overhead in the rendering hot path.
  // One specialized copy is maintained per variant per architecture specification.
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
    if (cols <= 0 || rows <= 0 || maxDistSq <= 0 || !maxDistSq.isFinite) {
      return;
    }

    final Int32List start = grid.cellStart;
    final Float64List xs = grid.xs;
    final Float64List ys = grid.ys;

    final int denseThreshold = throttler.computeDenseThreshold(
      distance: scanDistance,
      performance: performance,
    );
    final int defaultMaxLines =
        performance.maxComplexLines ?? kDefaultMaxComplexLinesBatched;

    final bool capped = maxConnectionsPerParticle != null;
    final int cap = maxConnectionsPerParticle ?? 0;
    final Int32List counts =
        candidateBuffer.getClearedConnectionCounts(grid.count);

    Int32List candIndices = candidateBuffer.indices;
    Float64List candDistSq = candidateBuffer.distSq;
    int candCapacity = candIndices.length;

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
            if (kParticlesProfile) {
              ScanStats.instance.candidateChecks++;
              ScanStats.instance.loopIterations++;
            }
            if (capped && counts[j] >= cap) continue;
            final double dx = x1 - xs[j];
            final double dxSq = dx * dx;
            if (dxSq > maxDistSq) continue;
            final double dy = y1 - ys[j];
            final double distSq = dxSq + dy * dy;
            if (distSq <= maxDistSq) {
              if (kParticlesProfile) {
                ScanStats.instance.acceptedPairs++;
              }
              if (candidateCount >= candCapacity) {
                candidateBuffer.ensureCapacity(candidateCount + 1);
                candIndices = candidateBuffer.indices;
                candDistSq = candidateBuffer.distSq;
                candCapacity = candIndices.length;
              }
              candIndices[candidateCount] = j;
              candDistSq[candidateCount] = distSq;
              candidateCount++;
            }
          }

          for (int j = southStart; j < southEnd; j++) {
            if (kParticlesProfile) {
              ScanStats.instance.candidateChecks++;
              ScanStats.instance.loopIterations++;
            }
            if (capped && counts[j] >= cap) continue;
            final double dx = x1 - xs[j];
            final double dxSq = dx * dx;
            if (dxSq > maxDistSq) continue;
            final double dy = y1 - ys[j];
            final double distSq = dxSq + dy * dy;
            if (distSq <= maxDistSq) {
              if (kParticlesProfile) {
                ScanStats.instance.acceptedPairs++;
              }
              if (candidateCount >= candCapacity) {
                candidateBuffer.ensureCapacity(candidateCount + 1);
                candIndices = candidateBuffer.indices;
                candDistSq = candidateBuffer.distSq;
                candCapacity = candIndices.length;
              }
              candIndices[candidateCount] = j;
              candDistSq[candidateCount] = distSq;
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
            defaultMaxLines: defaultMaxLines,
            isComplexMode: isComplexMode,
            performance: performance,
          );
          if (drawCount <= 0) continue;

          final bool isThrottled = drawCount < candidateCount;

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
              counts[j]++;
            }
          }
          if (capped) {
            counts[i] += drawCount;
          }
        }
      }
    }
  }

  /// Scans and renders individual lines directly to [canvas] for small scenes (N < 30).
  // Performance exception: This hot loop exceeds 50 lines to avoid per-pair
  // dispatch, closures, or helper function call overhead in the rendering hot path.
  // One specialized copy is maintained per variant per architecture specification.
  int scanIndividual({
    required Canvas canvas,
    required SortedSpatialGrid grid,
    required double scanDistance,
    required double maxDistSq,
    required double alphaDistance,
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
    if (cols <= 0 || rows <= 0 || maxDistSq <= 0 || !maxDistSq.isFinite) {
      return 0;
    }

    final Int32List start = grid.cellStart;
    final Float64List xs = grid.xs;
    final Float64List ys = grid.ys;

    // Phase 1 Item 2: Fade relative to alphaDistance (preserves 1.9.7 floor semantics)
    final double invAlphaDistance =
        alphaDistance > 0 ? 255.0 / alphaDistance : 0.0;
    final int defaultMaxLines =
        performance.maxComplexLines ?? kDefaultMaxComplexLinesIndividual;
    final int denseThreshold = throttler.computeDenseThreshold(
      distance: scanDistance,
      performance: performance,
      isIndividual: true,
    );

    final bool capped = maxConnectionsPerParticle != null;
    final int cap = maxConnectionsPerParticle ?? 0;
    final Int32List counts =
        candidateBuffer.getClearedConnectionCounts(grid.count);

    Int32List candIndices = candidateBuffer.indices;
    Float64List candDistSq = candidateBuffer.distSq;
    int candCapacity = candIndices.length;

    int lineCount = 0;
    final Color previousColor = linePaint.color;

    try {
      for (int cy = 0; cy < rows; cy++) {
        final bool hasSouth = cy < rows - 1;
        final int rowBase = cy * cols;
        for (int cx = 0; cx < cols; cx++) {
          final int cellIndex = rowBase + cx;
          final int cellEnd = start[cellIndex + 1];
          int i = start[cellIndex];
          if (i == cellEnd) continue;

          final bool hasEast = cx < cols - 1;
          final int nearEnd = hasEast ? start[cellIndex + 2] : cellEnd;
          int southStart = 0;
          int southEnd = 0;
          if (hasSouth) {
            final int south = cellIndex + cols;
            southStart = start[cx > 0 ? south - 1 : south];
            southEnd = start[(hasEast ? south + 1 : south) + 1];
          }

          for (; i < cellEnd; i++) {
            if (capped && counts[i] >= cap) continue;

            final double px = xs[i];
            final double py = ys[i];
            int candidateCount = 0;

            for (int j = i + 1; j < nearEnd; j++) {
              if (kParticlesProfile) {
                ScanStats.instance.candidateChecks++;
                ScanStats.instance.loopIterations++;
              }
              if (capped && counts[j] >= cap) continue;
              final double dx = px - xs[j];
              final double dxSq = dx * dx;
              if (dxSq > maxDistSq) continue;
              final double dy = py - ys[j];
              final double distSq = dxSq + dy * dy;
              if (distSq <= maxDistSq) {
                if (kParticlesProfile) {
                  ScanStats.instance.acceptedPairs++;
                }
                if (candidateCount >= candCapacity) {
                  candidateBuffer.ensureCapacity(candidateCount + 1);
                  candIndices = candidateBuffer.indices;
                  candDistSq = candidateBuffer.distSq;
                  candCapacity = candIndices.length;
                }
                candIndices[candidateCount] = j;
                candDistSq[candidateCount] = distSq;
                candidateCount++;
              }
            }

            for (int j = southStart; j < southEnd; j++) {
              if (kParticlesProfile) {
                ScanStats.instance.candidateChecks++;
                ScanStats.instance.loopIterations++;
              }
              if (capped && counts[j] >= cap) continue;
              final double dx = px - xs[j];
              final double dxSq = dx * dx;
              if (dxSq > maxDistSq) continue;
              final double dy = py - ys[j];
              final double distSq = dxSq + dy * dy;
              if (distSq <= maxDistSq) {
                if (kParticlesProfile) {
                  ScanStats.instance.acceptedPairs++;
                }
                if (candidateCount >= candCapacity) {
                  candidateBuffer.ensureCapacity(candidateCount + 1);
                  candIndices = candidateBuffer.indices;
                  candDistSq = candidateBuffer.distSq;
                  candCapacity = candIndices.length;
                }
                candIndices[candidateCount] = j;
                candDistSq[candidateCount] = distSq;
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

            // Phase 1 Item 8: loop index named candIdx so it does not shadow cellIndex
            for (int candIdx = 0; candIdx < drawCount; candIdx++) {
              final int j = candIndices[candIdx];
              final double distance = math.sqrt(candDistSq[candIdx]);
              int alpha =
                  (255 - (distance * invAlphaDistance)).toInt().clamp(0, 255);
              if (isComplexMode && isThrottled && drawCount > 1) {
                final double rankFade =
                    throttler.calculateComplexLineFade(candIdx, drawCount);
                alpha = (alpha * rankFade).toInt().clamp(0, 255);
              }
              linePaint.color = lineColorLut[alpha];
              canvas.drawLine(pos, Offset(xs[j], ys[j]), linePaint);

              if (capped) {
                counts[j]++;
              }
            }
            if (capped) {
              counts[i] += drawCount;
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
