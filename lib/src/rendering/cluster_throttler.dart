import 'dart:math' as math;

import 'candidate_buffer.dart';
import 'network_performance.dart';
import 'rendering_constants.dart';

/// Throttles and fades candidate connections in dense clusters.
///
/// Prevents visual spider-web clutter and maintains high frame rates in
/// high-density particle regions using smooth cosine rank falloff.
class ClusterThrottler {
  const ClusterThrottler();

  /// Calculates the neighbor count threshold above which a particle's neighborhood
  /// is classified as a dense cluster.
  @pragma('vm:prefer-inline')
  int computeDenseThreshold({
    required double distance,
    required NetworkPerformance performance,
    bool isIndividual = false,
  }) {
    final double? customFactor = performance.complexDensityFactor;
    if (customFactor != null) {
      return distance > 0 ? (distance * customFactor).toInt() : 0;
    }
    if (performance.isComplex) {
      return distance > 0 ? (distance ~/ kDefaultDenseDivisor) : 0;
    }
    final double divisor =
        isIndividual ? kIndividualDenseDivisor : kDefaultDenseDivisor;
    return distance > 0 ? (distance ~/ divisor) : 0;
  }

  /// Resolves the target number of allowed connection lines for a particle in a
  /// dense cluster based on [performance] settings.
  @pragma('vm:prefer-inline')
  int resolveComplexTargetLines({
    required int candidateCount,
    required int defaultMaxLines,
    required NetworkPerformance performance,
  }) {
    if (performance.complexReductionRatio != null) {
      final double ratio = performance.complexReductionRatio!.clamp(0.0, 1.0);
      final int reduced = (candidateCount * (1.0 - ratio)).round();
      return performance.maxComplexLines != null
          ? math.min(reduced, performance.maxComplexLines!)
          : math.max(1, reduced);
    }
    return defaultMaxLines;
  }

  /// Filters and throttles candidate connections for a particle in complex or capped mode.
  ///
  /// If the particle is in a dense cluster or exceeds connection caps, this selects
  /// the closest [k] candidates using [buffer.selectTopKClosest] and returns the final
  /// number of lines to draw. Returns 0 if no lines should be drawn.
  @pragma('vm:prefer-inline')
  int filterCandidates({
    required CandidateBuffer buffer,
    required int candidateCount,
    required bool isCapped,
    required int remainingCap,
    required int denseThreshold,
    required int defaultMaxLines,
    required bool isComplexMode,
    required NetworkPerformance performance,
  }) {
    int maxAllowed = candidateCount;
    if (isCapped && remainingCap < maxAllowed) {
      maxAllowed = remainingCap;
    }

    if (isComplexMode && candidateCount > denseThreshold) {
      final int target = resolveComplexTargetLines(
        candidateCount: candidateCount,
        defaultMaxLines: defaultMaxLines,
        performance: performance,
      );
      if (target < maxAllowed) {
        maxAllowed = target;
      }
    }

    if (maxAllowed <= 0) return 0;

    if (candidateCount > maxAllowed) {
      buffer.selectTopKClosest(candidateCount, maxAllowed);
      return maxAllowed;
    }

    return candidateCount;
  }

  /// Calculates the visual fade factor for connection lines in dense clusters.
  ///
  /// Uses a smooth cosine-tapered falloff across candidate ranks instead of a sharp
  /// linear cutoff. This prevents visual flickering (popping) when particles drift
  /// across cluster boundaries while maintaining full opacity for the closest connections.
  @pragma('vm:prefer-inline')
  double calculateComplexLineFade(int rank, int drawCount) {
    if (drawCount <= 1) return 1.0;
    final double progress = rank / (drawCount - 0.5);
    if (progress >= 1.0) return 0.0;
    return 0.5 * (1.0 + math.cos(math.pi * progress));
  }
}
