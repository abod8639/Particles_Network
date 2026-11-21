import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:particles_network/src/interaction/touch_features.dart';
import 'package:particles_network/src/rendering/line_vertex_batch.dart';
import 'package:particles_network/src/rendering/network_performance.dart';
import 'package:particles_network/src/rendering/optimized_network_painter.dart';

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

  /// Folds multiple performance parameter updates into an updated [NetworkPerformance].
  static NetworkPerformance foldPerformanceOptions({
    required NetworkPerformance current,
    LineRenderer? lineRenderer,
    bool? isComplex,
    double? complexReductionRatio,
    bool clearcomplexReductionRatio = false,
    int? maxComplexLines,
    bool clearMaxComplexLines = false,
    double? complexDensityFactor,
    bool clearcomplexDensityFactor = false,
    bool? antiAlias,
    int? maxLinesPerFrame,
    bool clearMaxLinesPerFrame = false,
    int? maxConnectionsPerParticle,
    bool clearMaxConnectionsPerParticle = false,
  }) {
    return current.copyWith(
      lineRenderer: lineRenderer,
      isComplex: isComplex,
      complexReductionRatio: complexReductionRatio,
      clearcomplexReductionRatio: clearcomplexReductionRatio,
      maxComplexLines: maxComplexLines,
      clearMaxComplexLines: clearMaxComplexLines,
      complexDensityFactor: complexDensityFactor,
      clearcomplexDensityFactor: clearcomplexDensityFactor,
      antiAlias: antiAlias,
      maxLinesPerFrame: maxLinesPerFrame,
      clearMaxLinesPerFrame: clearMaxLinesPerFrame,
      maxConnectionsPerParticle: maxConnectionsPerParticle,
      clearMaxConnectionsPerParticle: clearMaxConnectionsPerParticle,
    );
  }

  /// Evaluates whether the painter should repaint based on old delegate differences.
  static bool shouldRepaint(
    OptimizedNetworkPainter current,
    OptimizedNetworkPainter oldDelegate,
    bool hadAcceleratedParticles,
  ) {
    return oldDelegate.touchPoint != current.touchPoint ||
        hadAcceleratedParticles ||
        oldDelegate.lineDistance != current.lineDistance ||
        oldDelegate.particleColor != current.particleColor ||
        oldDelegate.lineColor != current.lineColor ||
        oldDelegate.lineWidth != current.lineWidth ||
        oldDelegate.fill != current.fill ||
        oldDelegate.drawNetwork != current.drawNetwork ||
        oldDelegate.devicePixelRatio != current.devicePixelRatio ||
        oldDelegate.particleCount != current.particleCount ||
        oldDelegate.particles.length != current.particles.length ||
        oldDelegate.touchFeatures != current.touchFeatures ||
        oldDelegate.performance != current.performance;
  }
}
