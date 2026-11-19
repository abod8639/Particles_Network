import 'dart:ui';

import 'package:particles_network/src/interaction/touch_features.dart';
import 'package:particles_network/src/legacy/legacy_deprecation_logger.dart';
import 'package:particles_network/src/rendering/line_vertex_batch.dart';
import 'package:particles_network/src/rendering/network_performance.dart';

/// Adapter isolating legacy parameter translation for [OptimizedNetworkPainter].
///
/// Ensures backward compatibility for deprecated constructor parameters and
/// flags without polluting the painter's core rendering pipeline.
class LegacyPainterAdapter {
  const LegacyPainterAdapter._();

  /// Resolves the effective [NetworkPerformance] by folding in legacy parameters.
  static NetworkPerformance resolvePerformance({
    required NetworkPerformance basePerformance,
    bool? isComplex,
    double? complexReductionRatio,
    int? maxComplexLines,
    double? complexDensityFactor,
    int? maxConnectionsPerParticle,
    int? maxLinesPerFrame,
    LineRenderer? lineRenderer,
    bool? antiAlias,
  }) {
    return basePerformance.copyWith(
      isComplex: isComplex,
      complexReductionRatio: complexReductionRatio,
      maxComplexLines: maxComplexLines,
      complexDensityFactor: complexDensityFactor,
      maxConnectionsPerParticle: maxConnectionsPerParticle,
      maxLinesPerFrame: maxLinesPerFrame,
      lineRenderer: lineRenderer,
      antiAlias: antiAlias,
    );
  }

  /// Resolves effective touch activation flag from legacy parameter or [TouchFeatures].
  static bool resolveTouchActivation({
    bool? touchActivation,
    required TouchFeatures touchFeatures,
  }) {
    return touchActivation ?? touchFeatures.enabled;
  }

  /// Resolves effective touch color from legacy parameter or [TouchFeatures].
  static Color resolveTouchColor({
    Color? touchColor,
    required TouchFeatures touchFeatures,
  }) {
    return touchColor ?? touchFeatures.color;
  }

  /// Emits a deprecation warning if legacy `showQuadTree` was requested.
  static void warnIfQuadTreeRequested(bool showQuadTree) {
    if (showQuadTree) {
      LegacyDeprecationLogger.warn(
        deprecatedApi: 'OptimizedNetworkPainter(showQuadTree: true)',
        replacement: 'SortedSpatialGrid (automatic zero-allocation grid)',
      );
    }
  }
}
