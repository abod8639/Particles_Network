/// Configuration class for rendering performance and physics optimization settings.
library;

import 'package:flutter/foundation.dart';
import 'package:particles_network/src/rendering/line_vertex_batch.dart';

/// Configuration class for network rendering performance and optimization settings.
///
/// Encapsulates all performance-related configurations such as connection line limits,
/// density adaptation, batched drawing, adaptive frame rate scaling, and line rasterization backend.
///
/// Performance Architecture:
/// * **$O(N)$ Line Bounds**: By setting [maxConnectionsPerParticle], total connections are
///   bounded to $O(N)$ instead of $O(N^2)$, preventing quadratic slowdowns at high particle counts.
/// * **Dynamic Line Budget**: With [maxLinesPerFrame], connection radius dynamically shrinks
///   under heavy load to maintain a flat frame budget (e.g. steady 60/120 FPS).
/// * **GPU Triangle Batching**: [lineRenderer] set to [LineRenderer.vertices] submits indexed
///   quads in a single GPU draw call per opacity level, avoiding per-segment stroke overhead.
/// * **Delta-Time Motion**: Enabling [frameRateIndependent] ensures consistent visual speed
///   across 60 Hz, 90 Hz, and 120 Hz displays.
/// * **Cluster Throttling**: Setting [isComplex] prunes redundant connections in dense particle
///   clusters, freeing GPU and CPU fill rate.
/// * **Dynamic Auto-Boost**: Enabling [autoBoost] actively monitors engine frame times and
///   scales connection limits in real time.
///
/// Predefined Presets:
/// * [NetworkPerformance.highPerformance]: Tuned for 500+ particles with $O(N)$ capping and GPU batching.
/// * [NetworkPerformance.balanced]: Ideal for general UI with moderate connection budgets.
/// * [NetworkPerformance.auto]: Self-adjusting preset that dynamically targets optimal frame rate.
/// * [NetworkPerformance.complex]: Fine-grained control over dense cluster connection pruning.
///
/// Example:
/// ```dart
/// // High-performance configuration for large particle counts:
/// const performance = NetworkPerformance(
///   maxConnectionsPerParticle: 4,
///   maxLinesPerFrame: 10000,
///   frameRateIndependent: true,
///   lineRenderer: LineRenderer.vertices,
///   isComplex: true,
/// );
/// ```
@immutable
class NetworkPerformance {
  /// Maximum number of connection lines a single particle can emit.
  ///
  /// Setting this bounds the total connection count to $O(N)$ instead of $O(N^2)$,
  /// dramatically improving performance for large particle counts (e.g., 300+ particles).
  ///
  /// When `null`, no per-particle connection limit is enforced, allowing particles to connect
  /// to all eligible neighbors within range.
  ///
  /// Defaults to `null`.
  final int? maxConnectionsPerParticle;

  /// Target upper bound on the total connection lines drawn across the network per frame.
  ///
  /// Setting a budget causes the painter to automatically and smoothly shrink the connection
  /// distance when density spikes, ensuring frame rendering cost stays completely flat
  /// and predictable regardless of how many particles congregate on screen.
  ///
  /// When `null`, lines are drawn up to the unconstrained configured connection distance.
  ///
  /// Defaults to `null`.
  final int? maxLinesPerFrame;

  /// Whether particle motion speed is independent of the display refresh rate.
  ///
  /// When `false`, particles advance a fixed distance per frame tick (pixels per frame).
  ///
  /// When `true`, particle velocities are interpreted as pixels per 1/60 s reference frame
  /// and integrated against real elapsed delta time, ensuring identical visual speed across
  /// 60 Hz, 90 Hz, 120 Hz displays and during temporary frame drops.
  ///
  /// Defaults to `false`.
  final bool frameRateIndependent;

  /// The rasterization backend used to render connection lines on the GPU.
  ///
  /// * [LineRenderer.vertices]: Submits lines as indexed triangle quads in batched `drawVertices`
  ///   calls. Substantially reduces GPU overhead for high line counts (lines render with square ends).
  /// * [LineRenderer.stroke]: Uses native engine Canvas strokes (`drawLine` / `drawRawPoints`
  ///   with rounded ends).
  ///
  /// Defaults to [LineRenderer.vertices].
  final LineRenderer lineRenderer;

  /// Whether to use complex (high-density optimized) painting and clustering logic.
  ///
  /// Specially optimized for high particle counts (300+ to 1,000+ particles).
  /// Throttles candidate connections in dense particle clusters, optimizes spatial grid rebuilds,
  /// and prevents visual clutter and frame drops in congested areas.
  ///
  /// Can be fine-tuned via [complexReductionRatio], [maxComplexLines], and [complexDensityFactor].
  ///
  /// Defaults to `false`.
  final bool isComplex;

  /// Connection reduction ratio for dense clusters when complex mode or density throttling is active.
  ///
  /// Controls the fraction of candidate connections pruned in dense clusters (value between `0.0` and `1.0`).
  /// For example, `0.4` eliminates 40% of cluster lines (keeping 60%), while `0.7` eliminates 70% (keeping 30%).
  ///
  /// Specifying this automatically enables density throttling even if [isComplex] is `false`.
  /// When `null`, default internal reduction heuristics are used.
  ///
  /// Defaults to `null`.
  final double? complexReductionRatio;

  /// Maximum number of connection lines an individual particle can emit when located in a dense cluster.
  ///
  /// When `null`, automatically defaults to 3 lines (in individual mode) or 5 lines (in batched mode)
  /// when [isComplex] is `true`.
  ///
  /// Defaults to `null`.
  final int? maxComplexLines;

  /// Distance multiplier factor used to identify whether a particle is inside a dense cluster.
  ///
  /// When `null`, defaults to `0.60` (`dist ~/ (1.0 / 0.60)`) when [isComplex] is `true`,
  /// or approximately `0.67` (`dist ~/ 1.5`) otherwise.
  ///
  /// Defaults to `null`.
  final double? complexDensityFactor;

  /// Proximity distance ratio threshold applied when [maxConnectionsPerParticle] is active.
  ///
  /// Restricts candidate connection searches to `lineDistance * cappedDistanceFactor`
  /// (value between `0.0` exclusive and `1.0` inclusive). This eliminates jarring long lines
  /// to distant particles and prevents flickering/thrashing as particles cross boundaries.
  ///
  /// Defaults to `0.75`.
  final double cappedDistanceFactor;

  /// Whether to enable anti-aliasing on particle circles and connection lines.
  ///
  /// Keeping anti-aliasing enabled produces smooth, circular particles and clean, non-shimmering lines.
  /// Disabling anti-aliasing can be used for retro pixel-art aesthetic styling or extreme low-end hardware.
  ///
  /// Defaults to `true`.
  final bool antiAlias;

  /// Optional cell size multiplier for spatial partitioning grid calculations.
  ///
  /// When `null`, the spatial grid automatically derives the mathematically optimal cell size
  /// as `max(radius, sqrt(area / (4 * particleCount)))`.
  ///
  /// Defaults to `null`.
  final double? spatialCellMultiplier;

  /// Whether dynamic real-time performance auto-boosting is enabled.
  ///
  /// When `true`, the engine actively measures actual frame delivery timings and dynamically
  /// scales connection budgets up or down in real time to deliver the maximum visual density
  /// and line richness that the host device can comfortably sustain without dropping frames.
  ///
  /// Defaults to `false`.
  final bool autoBoost;

  /// Creates a [NetworkPerformance] configuration with customizable optimization settings.
  ///
  /// Parameters:
  /// * [maxConnectionsPerParticle]: Per-particle line emission limit ($O(N)$ bound). Defaults to `null`.
  /// * [maxLinesPerFrame]: Total connection line budget per frame. Defaults to `null`.
  /// * [frameRateIndependent]: Normalizes movement across 60/90/120 Hz displays. Defaults to `false`.
  /// * [lineRenderer]: GPU rasterization engine backend. Defaults to [LineRenderer.vertices].
  /// * [isComplex]: Dense cluster throttling optimization. Defaults to `false`.
  /// * [complexReductionRatio]: Fraction of pruned lines in clusters (0.0 to 1.0). Defaults to `null`.
  /// * [maxComplexLines]: Max lines per particle in dense clusters. Defaults to `null`.
  /// * [complexDensityFactor]: Cluster detection threshold multiplier. Defaults to `null`.
  /// * [cappedDistanceFactor]: Distance ratio limit for capped lines. Defaults to `0.75`.
  /// * [antiAlias]: Smooth edge anti-aliasing. Defaults to `true`.
  /// * [spatialCellMultiplier]: Custom grid cell size multiplier. Defaults to `null`.
  /// * [autoBoost]: Real-time frame-rate based dynamic optimization. Defaults to `false`.
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
          maxConnectionsPerParticle == null || maxConnectionsPerParticle > 0,
          'maxConnectionsPerParticle must be greater than 0',
        ),
        assert(
          maxLinesPerFrame == null || maxLinesPerFrame > 0,
          'maxLinesPerFrame must be greater than 0',
        ),
        assert(
          cappedDistanceFactor > 0.0 && cappedDistanceFactor <= 1.0,
          'cappedDistanceFactor must be between 0.0 (exclusive) and 1.0 (inclusive)',
        ),
        assert(
          spatialCellMultiplier == null || spatialCellMultiplier > 0.0,
          'spatialCellMultiplier must be greater than 0.0',
        ),
        assert(
          complexReductionRatio == null ||
              (complexReductionRatio >= 0.0 && complexReductionRatio <= 1.0),
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

  /// High-performance preset tuned for high particle counts (300+ to 1,000+ particles) and rock-solid 60/120 FPS.
  ///
  /// Combines $O(N)$ connection clamping, line budgeting, GPU triangle-quad batching,
  /// and high-density cluster throttling.
  ///
  /// Preconfigured Settings:
  /// * [maxConnectionsPerParticle]: `4` (clamps each particle to 4 connections maximum).
  /// * [maxLinesPerFrame]: `15000` (caps total frame lines at 15,000).
  /// * [frameRateIndependent]: `true` (normalizes motion across 60/90/120 Hz displays).
  /// * [lineRenderer]: [LineRenderer.vertices] (GPU triangle batching).
  /// * [isComplex]: `true` (enables cluster throttling for dense groups).
  /// * [cappedDistanceFactor]: `0.75` (avoids long flickering lines).
  /// * [antiAlias]: `true` (smooth anti-aliased rendering).
  /// * [autoBoost]: `false`.
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
  })  : assert(
          maxConnectionsPerParticle == null || maxConnectionsPerParticle > 0,
          'maxConnectionsPerParticle must be greater than 0',
        ),
        assert(
          maxLinesPerFrame == null || maxLinesPerFrame > 0,
          'maxLinesPerFrame must be greater than 0',
        ),
        assert(
          cappedDistanceFactor > 0.0 && cappedDistanceFactor <= 1.0,
          'cappedDistanceFactor must be between 0.0 (exclusive) and 1.0 (inclusive)',
        ),
        assert(
          spatialCellMultiplier == null || spatialCellMultiplier > 0.0,
          'spatialCellMultiplier must be greater than 0.0',
        ),
        assert(
          complexReductionRatio == null ||
              (complexReductionRatio >= 0.0 && complexReductionRatio <= 1.0),
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

  /// Flexible complex preset for fine-grained control over dense cluster line reduction.
  ///
  /// Specifically designed to prevent visual clutter and GPU fill-rate degradation
  /// when large numbers of particles gravitate into tight clusters.
  ///
  /// Preconfigured Settings:
  /// * [complexReductionRatio]: `0.5` (prunes 50% of redundant candidate lines in clusters).
  /// * [maxComplexLines]: `3` (caps lines per particle to 3 in dense clusters).
  /// * [complexDensityFactor]: `0.60` (detects clusters within 60% of connection distance).
  /// * [isComplex]: `true` (enables high-density cluster mode).
  /// * [lineRenderer]: [LineRenderer.vertices] (GPU triangle batching).
  /// * [cappedDistanceFactor]: `0.75`.
  /// * [antiAlias]: `true`.
  const NetworkPerformance.complex({
    this.complexReductionRatio = 0.5,
    this.maxComplexLines = 3,
    this.complexDensityFactor = 0.60,
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
          maxConnectionsPerParticle == null || maxConnectionsPerParticle > 0,
          'maxConnectionsPerParticle must be greater than 0',
        ),
        assert(
          maxLinesPerFrame == null || maxLinesPerFrame > 0,
          'maxLinesPerFrame must be greater than 0',
        ),
        assert(
          cappedDistanceFactor > 0.0 && cappedDistanceFactor <= 1.0,
          'cappedDistanceFactor must be between 0.0 (exclusive) and 1.0 (inclusive)',
        ),
        assert(
          spatialCellMultiplier == null || spatialCellMultiplier > 0.0,
          'spatialCellMultiplier must be greater than 0.0',
        ),
        assert(
          complexReductionRatio == null ||
              (complexReductionRatio >= 0.0 && complexReductionRatio <= 1.0),
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

  /// Auto-performance preset that dynamically adapts parameters based on device frame rates.
  ///
  /// Actively measures frame rendering durations in real time and adjusts connection
  /// limits to deliver the highest possible visual density that the device can comfortably
  /// sustain at 60/90/120 FPS without dropping frames.
  ///
  /// Preconfigured Settings:
  /// * [autoBoost]: `true` (enables real-time dynamic budget adaptation).
  /// * [frameRateIndependent]: `true` (normalizes motion across all refresh rates).
  /// * [isComplex]: `true` (activates cluster throttling).
  /// * [lineRenderer]: [LineRenderer.vertices] (GPU triangle batching).
  /// * [cappedDistanceFactor]: `0.75`.
  /// * [antiAlias]: `true`.
  const NetworkPerformance.auto({
    this.maxConnectionsPerParticle,
    this.maxLinesPerFrame,
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
  })  : assert(
          maxConnectionsPerParticle == null || maxConnectionsPerParticle > 0,
          'maxConnectionsPerParticle must be greater than 0',
        ),
        assert(
          maxLinesPerFrame == null || maxLinesPerFrame > 0,
          'maxLinesPerFrame must be greater than 0',
        ),
        assert(
          cappedDistanceFactor > 0.0 && cappedDistanceFactor <= 1.0,
          'cappedDistanceFactor must be between 0.0 (exclusive) and 1.0 (inclusive)',
        ),
        assert(
          spatialCellMultiplier == null || spatialCellMultiplier > 0.0,
          'spatialCellMultiplier must be greater than 0.0',
        ),
        assert(
          complexReductionRatio == null ||
              (complexReductionRatio >= 0.0 && complexReductionRatio <= 1.0),
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

  /// Balanced preset that maintains rich visual density with sensible performance limits.
  ///
  /// Ideal for standard applications and mobile screens with 50 to 200 particles where
  /// full connection density is desired alongside delta-time smooth animation.
  ///
  /// Preconfigured Settings:
  /// * [maxConnectionsPerParticle]: `6` (allows up to 6 connections per particle).
  /// * [maxLinesPerFrame]: `8000` (caps total frame lines at 8,000).
  /// * [frameRateIndependent]: `true` (normalizes motion across displays).
  /// * [lineRenderer]: [LineRenderer.vertices] (GPU triangle batching).
  /// * [isComplex]: `false` (standard unconstrained clustering).
  /// * [cappedDistanceFactor]: `0.75`.
  /// * [antiAlias]: `true`.
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
  })  : assert(
          maxConnectionsPerParticle == null || maxConnectionsPerParticle > 0,
          'maxConnectionsPerParticle must be greater than 0',
        ),
        assert(
          maxLinesPerFrame == null || maxLinesPerFrame > 0,
          'maxLinesPerFrame must be greater than 0',
        ),
        assert(
          cappedDistanceFactor > 0.0 && cappedDistanceFactor <= 1.0,
          'cappedDistanceFactor must be between 0.0 (exclusive) and 1.0 (inclusive)',
        ),
        assert(
          spatialCellMultiplier == null || spatialCellMultiplier > 0.0,
          'spatialCellMultiplier must be greater than 0.0',
        ),
        assert(
          complexReductionRatio == null ||
              (complexReductionRatio >= 0.0 && complexReductionRatio <= 1.0),
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

  /// Creates a copy of this [NetworkPerformance] configuration with updated parameters.
  ///
  /// For nullable properties like [maxConnectionsPerParticle], [maxLinesPerFrame],
  /// [complexReductionRatio], [maxComplexLines], [complexDensityFactor], and [spatialCellMultiplier],
  /// passing the corresponding `clear*` flag as `true` explicitly resets the value to `null`.
  NetworkPerformance copyWith({
    int? maxConnectionsPerParticle,
    bool clearMaxConnectionsPerParticle = false,
    int? maxLinesPerFrame,
    bool clearMaxLinesPerFrame = false,
    bool? frameRateIndependent,
    LineRenderer? lineRenderer,
    bool? isComplex,
    double? complexReductionRatio,
    bool clearComplexReductionRatio = false,
    bool clearcomplexReductionRatio = false,
    int? maxComplexLines,
    bool clearMaxComplexLines = false,
    double? complexDensityFactor,
    bool clearComplexDensityFactor = false,
    bool clearcomplexDensityFactor = false,
    double? cappedDistanceFactor,
    bool? antiAlias,
    double? spatialCellMultiplier,
    bool clearSpatialCellMultiplier = false,
    bool? autoBoost,
  }) {
    final bool shouldClearReduction =
        clearComplexReductionRatio || clearcomplexReductionRatio;
    final bool shouldClearDensity =
        clearComplexDensityFactor || clearcomplexDensityFactor;

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
      complexReductionRatio: shouldClearReduction
          ? null
          : (complexReductionRatio ?? this.complexReductionRatio),
      maxComplexLines: clearMaxComplexLines
          ? null
          : (maxComplexLines ?? this.maxComplexLines),
      complexDensityFactor: shouldClearDensity
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
