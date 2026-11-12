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

  /// Creates a [NetworkPerformance] configuration.
  const NetworkPerformance({
    this.maxConnectionsPerParticle,
    this.adaptiveDensity = false,
    this.fastLineRendering = false,
    this.enableAdaptivePerformance = false,
    this.maxLinesPerFrame,
    this.frameRateIndependent = false,
    this.lineRenderer = LineRenderer.vertices,
  });

  /// High-performance preset tuned for high particle counts and smooth frame rates.
  const NetworkPerformance.highPerformance({
    this.maxConnectionsPerParticle = 4,
    this.adaptiveDensity = true,
    this.fastLineRendering = true,
    this.enableAdaptivePerformance = true,
    this.maxLinesPerFrame = 15000,
    this.frameRateIndependent = true,
    this.lineRenderer = LineRenderer.vertices,
  });

  /// Adaptive preset focusing on dynamic frame rate scaling and independent motion.
  const NetworkPerformance.adaptive({
    this.maxConnectionsPerParticle,
    this.adaptiveDensity = true,
    this.fastLineRendering = false,
    this.enableAdaptivePerformance = true,
    this.maxLinesPerFrame,
    this.frameRateIndependent = true,
    this.lineRenderer = LineRenderer.stroke,
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
          lineRenderer == other.lineRenderer;

  @override
  int get hashCode => Object.hash(
        maxConnectionsPerParticle,
        adaptiveDensity,
        fastLineRendering,
        enableAdaptivePerformance,
        maxLinesPerFrame,
        frameRateIndependent,
        lineRenderer,
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
        'lineRenderer: $lineRenderer)';
  }
}

