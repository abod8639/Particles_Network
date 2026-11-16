/// Configuration class for rendering performance and physics optimization settings.
library;

import 'package:flutter/foundation.dart';
import 'package:particles_network/src/rendering/line_vertex_batch.dart';

/// Configuration class for network rendering performance and optimization settings.
///
/// Encapsulates all performance-related configurations such as connection line limits,
/// density adaptation, batched drawing, adaptive frame rate scaling, and line rasterization backend.
@immutable
class NetworkPerformance {
  /// Maximum number of connection lines a single particle can emit.
  ///
  /// Setting this bounds the total connection count to O(N) instead of O(N^2),
  /// dramatically improving performance for large particle counts.
  final int? maxConnectionsPerParticle;


  /// Target upper bound on connection lines drawn per frame.
  ///
  /// Setting a budget shrinks the connection radius automatically so frame cost stays
  /// flat no matter how many particles are shown. `null` (default) keeps lineDistance fixed.
  final int? maxLinesPerFrame;

  /// Whether motion speed is independent of the display refresh rate (default: false).
  ///
  /// When false, particles move pixels per frame. When true, speeds are interpreted
  /// as pixels per 1/60 s and integrated over the real elapsed time.
  final bool frameRateIndependent;

  /// How connection lines are rasterized (default: [LineRenderer.vertices]).
  final LineRenderer lineRenderer;

  /// Whether to use complex (high-density optimized) painting logic (default: false).
  ///
  /// Optimized mode for high particle counts (300+ / 500+ particles) that
  /// throttles dense clusters, tunes the spatial grid rebuild interval, and
  /// optimizes batched connections without degrading anti-aliasing.
  ///
  /// Can be fine-tuned via [complexReductionRatio], [maxComplexLines],
  /// and [complexDensityFactor].
  final bool isComplex;

  /// Connection reduction ratio for dense clusters and complex mode (default: null).
  ///
  /// When specified (value between 0.0 and 1.0), controls the fraction of candidate
  /// connections pruned in dense clusters when [isComplex] or density throttling is active.
  /// For example, `0.4` reduces connections in dense clusters by 40% (keeping 60%),
  /// while `0.7` reduces them by 70% (keeping 30%).
  ///
  /// Specifying this automatically enables density throttling even if [isComplex] is false.
  final double? complexReductionRatio;

  /// Maximum number of connection lines a particle can emit in dense clusters (default: null).
  ///
  /// When null, defaults to 3 lines (in individual mode) or 5 lines (in batched mode)
  /// when [isComplex] is true.
  final int? maxComplexLines;

  /// Factor multiplied by connection distance to determine when a particle is in a dense cluster (default: null).
  ///
  /// When null, defaults to 0.25 (`dist ~/ 4`) when [isComplex] is true, or ~0.67 (`dist ~/ 1.5`) otherwise.
  final double? complexDensityFactor;

  /// Distance ratio threshold for capped connections (default: 0.75).
  ///
  /// When [maxConnectionsPerParticle] is active, restricts candidate search
  /// to `lineDistance * cappedDistanceFactor` to eliminate jarring long lines
  /// to distant particles and prevent connection thrashing/flickering.
  final double cappedDistanceFactor;

  /// Whether to enable anti-aliasing on particle and line paints (default: true).
  ///
  /// Keeping anti-aliasing enabled produces smooth, circular particles and clean,
  /// non-shimmering lines. Disabling anti-aliasing can be used for retro pixel art
  /// aesthetics or extreme low-end hardware.
  final bool antiAlias;

  /// Optional cell size multiplier for [SortedSpatialGrid] spatial partitioning (default: null).
  ///
  /// When null, [SortedSpatialGrid] automatically calculates the optimal cell size as
  /// `max(radius, sqrt(area / particleCount))`.
  final double? spatialCellMultiplier;

  /// Whether dynamic performance boosting is enabled (default: false).
  ///
  /// When true, dynamically scales connection limits and line budgets up or down
  /// in real time based on actual engine frame timings to deliver the highest possible
  /// visual fidelity that the host device can comfortably sustain.
  final bool autoBoost;

  /// Creates a [NetworkPerformance] configuration.
  const NetworkPerformance({
    this.maxConnectionsPerParticle,
    this.maxLinesPerFrame,
    this.frameRateIndependent = false,
    this.lineRenderer = LineRenderer.vertices,
    this.isComplex = false,
    this.complexReductionRatio,
    this.maxComplexLines,
    this.complexDensityFactor,
    this.cappedDistanceFactor = 0.75,
    this.antiAlias = true,
    this.spatialCellMultiplier,
    this.autoBoost = false,
  })  : assert(
          complexReductionRatio == null ||
              (complexReductionRatio >= 0.0 &&
                  complexReductionRatio <= 1.0),
          'complexReductionRatio must be between 0.0 and 1.0',
        ),
        assert(
          maxComplexLines == null || maxComplexLines > 0,
          'maxComplexLines must be greater than 0',
        ),
        assert(
          complexDensityFactor == null || complexDensityFactor > 0.0,
          'complexDensityFactor must be greater than 0.0',
        );

  /// High-performance preset tuned for high particle counts and smooth frame rates.
  const NetworkPerformance.highPerformance({
    this.maxConnectionsPerParticle = 4,
    this.maxLinesPerFrame = 15000,
    this.frameRateIndependent = true,
    this.lineRenderer = LineRenderer.vertices,
    this.isComplex = true,
    this.complexReductionRatio,
    this.maxComplexLines,
    this.complexDensityFactor,
    this.cappedDistanceFactor = 0.75,
    this.antiAlias = true,
    this.spatialCellMultiplier,
    this.autoBoost = false,
  });

  /// Flexible complex preset for fine-grained control over dense cluster line reduction.
  const NetworkPerformance.complex({
    this.complexReductionRatio = 0.5,
    this.maxComplexLines = 3,
    this.complexDensityFactor = 0.25,
    this.maxConnectionsPerParticle,
    this.maxLinesPerFrame,
    this.frameRateIndependent = false,
    this.lineRenderer = LineRenderer.vertices,
    this.isComplex = true,
    this.cappedDistanceFactor = 0.75,
    this.antiAlias = true,
    this.spatialCellMultiplier,
    this.autoBoost = false,
  })  : assert(
          complexReductionRatio == null ||
              (complexReductionRatio >= 0.0 &&
                  complexReductionRatio <= 1.0),
          'complexReductionRatio must be between 0.0 and 1.0',
        ),
        assert(
          maxComplexLines == null || maxComplexLines > 0,
          'maxComplexLines must be greater than 0',
        ),
        assert(
          complexDensityFactor == null || complexDensityFactor > 0.0,
          'complexDensityFactor must be greater than 0.0',
        );

  /// Adaptive preset focusing on dynamic frame rate scaling and independent motion.
  const NetworkPerformance.adaptive({
    this.maxConnectionsPerParticle,
    this.maxLinesPerFrame,
    this.frameRateIndependent = true,
    this.lineRenderer = LineRenderer.vertices,
    this.isComplex = false,
    this.complexReductionRatio,
    this.maxComplexLines,
    this.complexDensityFactor,
    this.cappedDistanceFactor = 0.75,
    this.antiAlias = true,
    this.spatialCellMultiplier,
    this.autoBoost = true,
  });

  /// Auto-performance preset that automatically adapts parameters based on
  /// device performance and frame rate, maximizing visual density and connections
  /// while maintaining smooth target frame rates.
  const NetworkPerformance.auto({
    this.maxConnectionsPerParticle = 15000,
    this.maxLinesPerFrame = 15000,
    this.frameRateIndependent = true,
    this.lineRenderer = LineRenderer.vertices,
    this.isComplex = true,
    this.complexReductionRatio,
    this.maxComplexLines,
    this.complexDensityFactor,
    this.cappedDistanceFactor = 0.75,
    this.antiAlias = true,
    this.spatialCellMultiplier,
    this.autoBoost = true,
  });

  /// Boost preset that dynamically tunes and scales connection budgets
  /// to unlock maximum performance and visual density for the host device.
  const NetworkPerformance.boost({
    this.maxConnectionsPerParticle = 15000,
    this.maxLinesPerFrame = 15000,
    this.frameRateIndependent = true,
    this.lineRenderer = LineRenderer.vertices,
    this.isComplex = true,
    this.complexReductionRatio,
    this.maxComplexLines,
    this.complexDensityFactor,
    this.cappedDistanceFactor = 0.75,
    this.antiAlias = true,
    this.spatialCellMultiplier,
    this.autoBoost = true,
  });

  /// Balanced preset that maintains good visual quality with sensible performance limits.
  const NetworkPerformance.balanced({
    this.maxConnectionsPerParticle = 6,
    this.maxLinesPerFrame = 8000,
    this.frameRateIndependent = true,
    this.lineRenderer = LineRenderer.vertices,
    this.isComplex = false,
    this.complexReductionRatio,
    this.maxComplexLines,
    this.complexDensityFactor,
    this.cappedDistanceFactor = 0.75,
    this.antiAlias = true,
    this.spatialCellMultiplier,
    this.autoBoost = false,
  });

  /// Battery saver preset tuned to minimize CPU/GPU load on low-end or battery-constrained devices.
  const NetworkPerformance.batterySaver({
    this.maxConnectionsPerParticle = 3,
    this.maxLinesPerFrame = 3000,
    this.frameRateIndependent = true,
    this.lineRenderer = LineRenderer.vertices,
    this.isComplex = true,
    this.complexReductionRatio = 0.5,
    this.maxComplexLines = 2,
    this.complexDensityFactor = 0.25,
    this.cappedDistanceFactor = 0.75,
    this.antiAlias = true,
    this.spatialCellMultiplier,
    this.autoBoost = false,
  });

  /// Creates a copy of this [NetworkPerformance] with updated parameters.
  NetworkPerformance copyWith({
    int? maxConnectionsPerParticle,
    bool clearMaxConnectionsPerParticle = false,
    int? maxLinesPerFrame,
    bool clearMaxLinesPerFrame = false,
    bool? frameRateIndependent,
    LineRenderer? lineRenderer,
    bool? isComplex,
    double? complexReductionRatio,
    bool clearcomplexReductionRatio = false,
    int? maxComplexLines,
    bool clearMaxComplexLines = false,
    double? complexDensityFactor,
    bool clearcomplexDensityFactor = false,
    double? cappedDistanceFactor,
    bool? antiAlias,
    double? spatialCellMultiplier,
    bool clearSpatialCellMultiplier = false,
    bool? autoBoost,
  }) {
    return NetworkPerformance(
      maxConnectionsPerParticle: clearMaxConnectionsPerParticle
          ? null
          : (maxConnectionsPerParticle ?? this.maxConnectionsPerParticle),
      maxLinesPerFrame: clearMaxLinesPerFrame
          ? null
          : (maxLinesPerFrame ?? this.maxLinesPerFrame),
      frameRateIndependent: frameRateIndependent ?? this.frameRateIndependent,
      lineRenderer: lineRenderer ?? this.lineRenderer,
      isComplex: isComplex ?? this.isComplex,
      complexReductionRatio: clearcomplexReductionRatio
          ? null
          : (complexReductionRatio ?? this.complexReductionRatio),
      maxComplexLines: clearMaxComplexLines
          ? null
          : (maxComplexLines ?? this.maxComplexLines),
      complexDensityFactor: clearcomplexDensityFactor
          ? null
          : (complexDensityFactor ?? this.complexDensityFactor),
      cappedDistanceFactor: cappedDistanceFactor ?? this.cappedDistanceFactor,
      antiAlias: antiAlias ?? this.antiAlias,
      spatialCellMultiplier: clearSpatialCellMultiplier
          ? null
          : (spatialCellMultiplier ?? this.spatialCellMultiplier),
      autoBoost: autoBoost ?? this.autoBoost,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkPerformance &&
          runtimeType == other.runtimeType &&
          maxConnectionsPerParticle == other.maxConnectionsPerParticle &&
          maxLinesPerFrame == other.maxLinesPerFrame &&
          frameRateIndependent == other.frameRateIndependent &&
          lineRenderer == other.lineRenderer &&
          isComplex == other.isComplex &&
          complexReductionRatio == other.complexReductionRatio &&
          maxComplexLines == other.maxComplexLines &&
          complexDensityFactor == other.complexDensityFactor &&
          cappedDistanceFactor == other.cappedDistanceFactor &&
          antiAlias == other.antiAlias &&
          spatialCellMultiplier == other.spatialCellMultiplier &&
          autoBoost == other.autoBoost;

  @override
  int get hashCode => Object.hash(
        maxConnectionsPerParticle,
        maxLinesPerFrame,
        frameRateIndependent,
        lineRenderer,
        isComplex,
        complexReductionRatio,
        maxComplexLines,
        complexDensityFactor,
        cappedDistanceFactor,
        antiAlias,
        spatialCellMultiplier,
        autoBoost,
      );

  @override
  String toString() {
    return 'NetworkPerformance('
        'maxConnectionsPerParticle: $maxConnectionsPerParticle, '
        'maxLinesPerFrame: $maxLinesPerFrame, '
        'frameRateIndependent: $frameRateIndependent, '
        'lineRenderer: $lineRenderer, '
        'isComplex: $isComplex, '
        'complexReductionRatio: $complexReductionRatio, '
        'maxComplexLines: $maxComplexLines, '
        'complexDensityFactor: $complexDensityFactor, '
        'cappedDistanceFactor: $cappedDistanceFactor, '
        'antiAlias: $antiAlias, '
        'spatialCellMultiplier: $spatialCellMultiplier, '
        'autoBoost: $autoBoost)';
  }
}
