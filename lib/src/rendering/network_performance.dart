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

  /// Whether to automatically scale down connection distance in dense networks.
  final bool adaptiveDensity;

  /// Whether to use ultra-fast single draw-call line rendering.
  final bool fastLineRendering;

  /// Whether to dynamically monitor frame cost and adapt quality to keep up
  /// with the display refresh rate.
  ///
  /// Uses the engine's [FrameTiming] build and raster durations, reacting
  /// to real GPU load rather than to the interval between ticks.
  final bool enableAdaptivePerformance;

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

  /// How connection lines are rasterized (default: [LineRenderer.stroke]).
  final LineRenderer lineRenderer;

  /// Whether to use complex (high-density optimized) painting logic (default: false).
  ///
  /// Optimized mode for high particle counts (300+ / 500+ particles) that
  /// throttles dense clusters, tunes the spatial grid rebuild interval, and
  /// optimizes batched connections without degrading anti-aliasing.
  ///
  /// Can be fine-tuned via [connectionReductionRatio], [maxComplexLines],
  /// and [denseThresholdFactor].
  final bool isComplex;

  /// Connection reduction ratio for dense clusters and complex mode (default: null).
  ///
  /// When specified (value between 0.0 and 1.0), controls the fraction of candidate
  /// connections pruned in dense clusters when [isComplex] or density throttling is active.
  /// For example, `0.4` reduces connections in dense clusters by 40% (keeping 60%),
  /// while `0.7` reduces them by 70% (keeping 30%).
  ///
  /// Specifying this automatically enables density throttling even if [isComplex] is false.
  final double? connectionReductionRatio;

  /// Maximum number of connection lines a particle can emit in dense clusters (default: null).
  ///
  /// When null, defaults to 3 lines (in individual mode) or 5 lines (in batched mode)
  /// when [isComplex] is true.
  final int? maxComplexLines;

  /// Factor multiplied by connection distance to determine when a particle is in a dense cluster (default: null).
  ///
  /// When null, defaults to 0.25 (`dist ~/ 4`) when [isComplex] is true, or ~0.67 (`dist ~/ 1.5`) otherwise.
  final double? denseThresholdFactor;

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

  /// Creates a [NetworkPerformance] configuration.
  const NetworkPerformance({
    this.maxConnectionsPerParticle,
    this.adaptiveDensity = false,
    this.fastLineRendering = false,
    this.enableAdaptivePerformance = false,
    this.maxLinesPerFrame,
    this.frameRateIndependent = false,
    this.lineRenderer = LineRenderer.stroke,
    this.isComplex = false,
    this.connectionReductionRatio,
    this.maxComplexLines,
    this.denseThresholdFactor,
    this.cappedDistanceFactor = 0.75,
    this.antiAlias = true,
    this.spatialCellMultiplier,
  })  : assert(
          connectionReductionRatio == null ||
              (connectionReductionRatio >= 0.0 &&
                  connectionReductionRatio <= 1.0),
          'connectionReductionRatio must be between 0.0 and 1.0',
        ),
        assert(
          maxComplexLines == null || maxComplexLines > 0,
          'maxComplexLines must be greater than 0',
        ),
        assert(
          denseThresholdFactor == null || denseThresholdFactor > 0.0,
          'denseThresholdFactor must be greater than 0.0',
        );

  /// High-performance preset tuned for high particle counts and smooth frame rates.
  const NetworkPerformance.highPerformance({
    this.maxConnectionsPerParticle = 4,
    this.adaptiveDensity = true,
    this.fastLineRendering = true,
    this.enableAdaptivePerformance = true,
    this.maxLinesPerFrame = 15000,
    this.frameRateIndependent = true,
    this.lineRenderer = LineRenderer.vertices,
    this.isComplex = true,
    this.connectionReductionRatio,
    this.maxComplexLines,
    this.denseThresholdFactor,
    this.cappedDistanceFactor = 0.75,
    this.antiAlias = true,
    this.spatialCellMultiplier,
  });

  /// Flexible complex preset for fine-grained control over dense cluster line reduction.
  const NetworkPerformance.complex({
    this.connectionReductionRatio = 0.5,
    this.maxComplexLines = 3,
    this.denseThresholdFactor = 0.25,
    this.maxConnectionsPerParticle,
    this.adaptiveDensity = false,
    this.fastLineRendering = false,
    this.enableAdaptivePerformance = false,
    this.maxLinesPerFrame,
    this.frameRateIndependent = false,
    this.lineRenderer = LineRenderer.stroke,
    this.isComplex = true,
    this.cappedDistanceFactor = 0.75,
    this.antiAlias = true,
    this.spatialCellMultiplier,
  })  : assert(
          connectionReductionRatio == null ||
              (connectionReductionRatio >= 0.0 &&
                  connectionReductionRatio <= 1.0),
          'connectionReductionRatio must be between 0.0 and 1.0',
        ),
        assert(
          maxComplexLines == null || maxComplexLines > 0,
          'maxComplexLines must be greater than 0',
        ),
        assert(
          denseThresholdFactor == null || denseThresholdFactor > 0.0,
          'denseThresholdFactor must be greater than 0.0',
        );

  /// Adaptive preset focusing on dynamic frame rate scaling and independent motion.
  const NetworkPerformance.adaptive({
    this.maxConnectionsPerParticle,
    this.adaptiveDensity = true,
    this.fastLineRendering = false,
    this.enableAdaptivePerformance = true,
    this.maxLinesPerFrame,
    this.frameRateIndependent = true,
    this.lineRenderer = LineRenderer.stroke,
    this.isComplex = false,
    this.connectionReductionRatio,
    this.maxComplexLines,
    this.denseThresholdFactor,
    this.cappedDistanceFactor = 0.75,
    this.antiAlias = true,
    this.spatialCellMultiplier,
  });

  /// Auto-performance preset that automatically adjusts parameters based on particle count.
  const NetworkPerformance.auto({
    this.maxConnectionsPerParticle = 15000,
    this.adaptiveDensity = false,
    this.fastLineRendering = false,
    this.enableAdaptivePerformance = false,
    this.maxLinesPerFrame,
    this.frameRateIndependent = false,
    this.lineRenderer = LineRenderer.stroke,
    this.isComplex = false,
    this.connectionReductionRatio,
    this.maxComplexLines,
    this.denseThresholdFactor,
    this.cappedDistanceFactor = 0.75,
    this.antiAlias = true,
    this.spatialCellMultiplier,
  });

  /// Creates a copy of this [NetworkPerformance] with updated parameters.
  NetworkPerformance copyWith({
    int? maxConnectionsPerParticle,
    bool clearMaxConnectionsPerParticle = false,
    bool? adaptiveDensity,
    bool? fastLineRendering,
    bool? enableAdaptivePerformance,
    int? maxLinesPerFrame,
    bool clearMaxLinesPerFrame = false,
    bool? frameRateIndependent,
    LineRenderer? lineRenderer,
    bool? isComplex,
    double? connectionReductionRatio,
    bool clearConnectionReductionRatio = false,
    int? maxComplexLines,
    bool clearMaxComplexLines = false,
    double? denseThresholdFactor,
    bool clearDenseThresholdFactor = false,
    double? cappedDistanceFactor,
    bool? antiAlias,
    double? spatialCellMultiplier,
    bool clearSpatialCellMultiplier = false,
  }) {
    return NetworkPerformance(
      maxConnectionsPerParticle: clearMaxConnectionsPerParticle
          ? null
          : (maxConnectionsPerParticle ?? this.maxConnectionsPerParticle),
      adaptiveDensity: adaptiveDensity ?? this.adaptiveDensity,
      fastLineRendering: fastLineRendering ?? this.fastLineRendering,
      enableAdaptivePerformance:
          enableAdaptivePerformance ?? this.enableAdaptivePerformance,
      maxLinesPerFrame: clearMaxLinesPerFrame
          ? null
          : (maxLinesPerFrame ?? this.maxLinesPerFrame),
      frameRateIndependent: frameRateIndependent ?? this.frameRateIndependent,
      lineRenderer: lineRenderer ?? this.lineRenderer,
      isComplex: isComplex ?? this.isComplex,
      connectionReductionRatio: clearConnectionReductionRatio
          ? null
          : (connectionReductionRatio ?? this.connectionReductionRatio),
      maxComplexLines: clearMaxComplexLines
          ? null
          : (maxComplexLines ?? this.maxComplexLines),
      denseThresholdFactor: clearDenseThresholdFactor
          ? null
          : (denseThresholdFactor ?? this.denseThresholdFactor),
      cappedDistanceFactor: cappedDistanceFactor ?? this.cappedDistanceFactor,
      antiAlias: antiAlias ?? this.antiAlias,
      spatialCellMultiplier: clearSpatialCellMultiplier
          ? null
          : (spatialCellMultiplier ?? this.spatialCellMultiplier),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkPerformance &&
          runtimeType == other.runtimeType &&
          maxConnectionsPerParticle == other.maxConnectionsPerParticle &&
          adaptiveDensity == other.adaptiveDensity &&
          fastLineRendering == other.fastLineRendering &&
          enableAdaptivePerformance == other.enableAdaptivePerformance &&
          maxLinesPerFrame == other.maxLinesPerFrame &&
          frameRateIndependent == other.frameRateIndependent &&
          lineRenderer == other.lineRenderer &&
          isComplex == other.isComplex &&
          connectionReductionRatio == other.connectionReductionRatio &&
          maxComplexLines == other.maxComplexLines &&
          denseThresholdFactor == other.denseThresholdFactor &&
          cappedDistanceFactor == other.cappedDistanceFactor &&
          antiAlias == other.antiAlias &&
          spatialCellMultiplier == other.spatialCellMultiplier;

  @override
  int get hashCode => Object.hash(
        maxConnectionsPerParticle,
        adaptiveDensity,
        fastLineRendering,
        enableAdaptivePerformance,
        maxLinesPerFrame,
        frameRateIndependent,
        lineRenderer,
        isComplex,
        connectionReductionRatio,
        maxComplexLines,
        denseThresholdFactor,
        cappedDistanceFactor,
        antiAlias,
        spatialCellMultiplier,
      );

  @override
  String toString() {
    return 'NetworkPerformance('
        'maxConnectionsPerParticle: $maxConnectionsPerParticle, '
        'adaptiveDensity: $adaptiveDensity, '
        'fastLineRendering: $fastLineRendering, '
        'enableAdaptivePerformance: $enableAdaptivePerformance, '
        'maxLinesPerFrame: $maxLinesPerFrame, '
        'frameRateIndependent: $frameRateIndependent, '
        'lineRenderer: $lineRenderer, '
        'isComplex: $isComplex, '
        'connectionReductionRatio: $connectionReductionRatio, '
        'maxComplexLines: $maxComplexLines, '
        'denseThresholdFactor: $denseThresholdFactor, '
        'cappedDistanceFactor: $cappedDistanceFactor, '
        'antiAlias: $antiAlias, '
        'spatialCellMultiplier: $spatialCellMultiplier)';
  }
}
