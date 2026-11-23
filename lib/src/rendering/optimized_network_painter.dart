/// Specialized painter for rendering a high-performance particle network.
library;

import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:particles_network/src/core/particle.dart';
import 'package:particles_network/src/interaction/touch_interaction_handler.dart';
import 'package:particles_network/src/rendering/candidate_buffer.dart';
import 'package:particles_network/src/rendering/cluster_throttler.dart';
import 'package:particles_network/src/rendering/frame_radii.dart';
import 'package:particles_network/src/rendering/legacy_painter_adapter.dart';
import 'package:particles_network/src/rendering/line_buckets.dart';
import 'package:particles_network/src/rendering/line_budget_controller.dart';
import 'package:particles_network/src/rendering/line_style_palette.dart';
import 'package:particles_network/src/rendering/line_vertex_batch.dart';
import 'package:particles_network/src/rendering/network_performance.dart';
import 'package:particles_network/src/rendering/pair_scanner.dart';
import 'package:particles_network/src/rendering/particle_batch_renderer.dart';
import 'package:particles_network/src/rendering/particle_filter.dart';
import 'package:particles_network/src/rendering/performance_utils.dart';
import 'package:particles_network/src/rendering/rendering_constants.dart';
import 'package:particles_network/src/spatial/grid_tuning.dart';
import 'package:particles_network/src/spatial/sorted_spatial_grid.dart';

/// The main painter class for rendering an optimized particle network.
class OptimizedNetworkPainter extends CustomPainter {
  final List<Particle> particles;
  Offset? touchPoint;
  double lineDistance;
  Color particleColor;
  Color lineColor;
  Color touchColor;

  @Deprecated('Use touchFeatures.enabled. Removed in 2.0.0.')
  bool get touchActivation => touchFeatures.enabled;
  set touchActivation(bool v) =>
      updateTouchFeatures(touchFeatures.copyWith(enabled: v));
  final int particleCount;
  double lineWidth;

  @Deprecated('Use performance.isComplex. Removed in 2.0.0.')
  bool get isComplex => performance.isComplex;
  set isComplex(bool v) =>
      updatePerformance(performance.copyWith(isComplex: v));

  bool fill;
  bool drawNetwork;

  TouchFeatures touchFeatures;
  PerformanceFeatures performance;

  int? _runtimeMaxLinesOverride;
  int? _runtimeMaxConnectionsOverride;

  /// Runtime override for max lines per frame in adaptive/auto mode.
  int? get runtimeMaxLinesOverride => _runtimeMaxLinesOverride;

  /// Runtime override for max connections per particle in emergency capping mode.
  int? get runtimeMaxConnectionsOverride => _runtimeMaxConnectionsOverride;

  /// Number of currently visible particles in the viewport.
  int get visibleParticleCount => _visibleParticles.length;

  /// Effective upper bound on lines per frame respecting user-configured cap precedence.
  int? get effectiveMaxLines {
    final int? userCap = performance.maxLinesPerFrame;
    final int? runtimeCap = _runtimeMaxLinesOverride;
    if (userCap != null && runtimeCap != null) {
      return math.min(userCap, runtimeCap);
    }
    return runtimeCap ?? userCap;
  }

  /// Effective upper bound on connections per particle respecting user-configured cap precedence.
  int? get effectiveMaxConnections {
    final int? userCap = performance.maxConnectionsPerParticle;
    final int? runtimeCap = _runtimeMaxConnectionsOverride;
    if (userCap != null && runtimeCap != null) {
      return math.min(userCap, runtimeCap);
    }
    return runtimeCap ?? userCap;
  }

  /// Sets the dynamic line budget runtime override without resetting feedback correction.
  void setDynamicLineBudget(int? budget) {
    _runtimeMaxLinesOverride = budget;
  }

  /// Sets the emergency connection capping runtime override.
  void setEmergencyMaxConnections(int? connections) {
    _runtimeMaxConnectionsOverride = connections;
  }

  /// Clears all runtime overrides.
  void resetRuntimeOverrides() {
    _runtimeMaxLinesOverride = null;
    _runtimeMaxConnectionsOverride = null;
  }

  int? get maxConnectionsPerParticle => performance.maxConnectionsPerParticle;
  set maxConnectionsPerParticle(int? v) {
    resetRuntimeOverrides();
    updatePerformance(performance.copyWith(
        maxConnectionsPerParticle: v,
        clearMaxConnectionsPerParticle: v == null));
  }

  int? get maxLinesPerFrame => performance.maxLinesPerFrame;
  set maxLinesPerFrame(int? v) {
    resetRuntimeOverrides();
    if (v != performance.maxLinesPerFrame) _budgetController.resetFeedback();
    updatePerformance(performance.copyWith(
        maxLinesPerFrame: v, clearMaxLinesPerFrame: v == null));
  }

  LineRenderer _lineRenderer = LineRenderer.vertices;
  LineRenderer get lineRenderer => _lineRenderer;
  set lineRenderer(LineRenderer v) {
    _lineRenderer = v;
    _touchHandler.lineRenderer = v;
  }

  double devicePixelRatio;
  bool simulateTouchInPaint;
  final GridTuning gridTuning;

  int get lastFrameLineCount => _lastFrameLineCount;
  int _lastFrameLineCount = 0;

  /// Connection scan radius actually used in the most recent [paint] call.
  double get lastFrameLineDistance => _lastFrameLineDistance;
  double get lastFrameScanRadius => _lastFrameLineDistance;
  double _lastFrameLineDistance = 0;

  static const double defaultMinSafetyLineDistance =
      GridTuning.defaultMinCellFloor;

  // Collaborators
  final LineBudgetController _budgetController = LineBudgetController();
  @visibleForTesting
  LineBudgetController get budgetController => _budgetController;
  late final LineStylePalette _palette;
  final CandidateBuffer _candidateBuffer = CandidateBuffer();
  static const ClusterThrottler _throttler = ClusterThrottler();
  final LineBuckets _lineBuckets = LineBuckets();
  final ParticleBatchRenderer _particleRenderer = ParticleBatchRenderer();
  static const PairScanner _scanner = PairScanner();

  final LineVertexBatch _lineVertexBatch = LineVertexBatch();
  final Paint _vertexPaint = Paint();
  late final TouchInteractionHandler _touchHandler;
  final SortedSpatialGrid _sortedGrid;

  SortedSpatialGrid get spatialGrid => _sortedGrid;
  @visibleForTesting
  TouchInteractionHandler get touchHandler => _touchHandler;

  late final Paint particlePaint;
  late final Paint linePaint;
  late final AccelerationTracker _accelerationTracker;

  final List<int> _visibleParticles = [];
  bool _visibleParticlesFilteredThisStep = false;
  Size? _lastSize;

  OptimizedNetworkPainter({
    required this.particleCount,
    required this.particles,
    required this.touchPoint,
    required this.lineDistance,
    required this.particleColor,
    required this.lineColor,
    Color? touchColor,
    @Deprecated('Use touchFeatures.enabled. Removed in 2.0.0.')
    bool? touchActivation,
    required this.lineWidth,
    @Deprecated('Use performance.isComplex. Removed in 2.0.0.') bool? isComplex,
    required this.fill,
    required this.drawNetwork,
    TouchFeatures touchFeatures = const TouchFeatures(),
    PerformanceFeatures performance = const PerformanceFeatures(),
    int? maxConnectionsPerParticle,
    int? maxLinesPerFrame,
    this.simulateTouchInPaint = true,
    LineRenderer? lineRenderer,
    this.devicePixelRatio = 1.0,
    bool? antiAlias,
    double? complexReductionRatio,
    int? maxComplexLines,
    double? complexDensityFactor,
    GridTuning? gridTuning,
    SortedSpatialGrid? spatialGrid,
    super.repaint,
  })  : gridTuning = gridTuning ?? const GridTuning(),
        _sortedGrid = spatialGrid ??
            SortedSpatialGrid(tuning: gridTuning ?? const GridTuning()),
        touchColor = LegacyPainterAdapter.resolveTouchColor(
            touchColor: touchColor, touchFeatures: touchFeatures),
        touchFeatures = touchFeatures.copyWith(
          enabled: LegacyPainterAdapter.resolveTouchActivation(
            touchActivation: touchActivation,
            touchFeatures: touchFeatures,
          ),
          color: touchColor ?? touchFeatures.color,
        ),
        _lineRenderer = lineRenderer ?? LineRenderer.vertices,
        performance = LegacyPainterAdapter.resolvePerformance(
          basePerformance: performance,
          isComplex: isComplex,
          complexReductionRatio: complexReductionRatio,
          maxComplexLines: maxComplexLines,
          complexDensityFactor: complexDensityFactor,
          maxConnectionsPerParticle: maxConnectionsPerParticle,
          maxLinesPerFrame: maxLinesPerFrame,
          antiAlias: antiAlias,
        ) {
    _palette = LineStylePalette(
        lineColor: lineColor,
        lineWidth: lineWidth,
        antiAlias: this.performance.antiAlias);
    particlePaint = Paint()
      ..style = fill ? PaintingStyle.fill : PaintingStyle.stroke
      ..isAntiAlias = this.performance.antiAlias
      ..color = particleColor;
    linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth
      ..isAntiAlias = this.performance.antiAlias
      ..color = lineColor;
    _accelerationTracker = AccelerationTracker();
    _touchHandler = TouchInteractionHandler(
      particles: particles,
      touchPoint: touchPoint,
      lineDistance: lineDistance,
      touchColor: this.touchColor,
      linePaint: linePaint,
      touchFeatures: touchFeatures,
      spatialGrid: _sortedGrid,
      lineRenderer: LineRenderer.vertices,
      fastLineRendering: true,
    );
  }

  void updateTouchPoint(Offset? newPoint) {
    touchPoint = newPoint;
    _touchHandler.touchPoint = newPoint;
  }

  bool get _isTouchActive =>
      touchFeatures.enabled &&
      touchPoint != null &&
      touchPoint!.isFinite &&
      touchPoint != Offset.infinite;

  void stepTouchPhysics([double timeScale = 1.0]) {
    if (!_isTouchActive) return;
    ParticleFilter.getVisibleParticlesTo(particles, _visibleParticles);
    _visibleParticlesFilteredThisStep = true;
    final Size? sz = _lastSize;
    if (sz != null &&
        sz.width > 0 &&
        sz.height > 0 &&
        _visibleParticles.isNotEmpty) {
      final double td = _touchHandler.effectiveLineDistance;
      _sortedGrid.build(
          particles,
          _visibleParticles,
          sz.width,
          sz.height,
          td > 0 ? td : kFallbackLineDistance,
          performance.spatialCellMultiplier);
    }
    _touchHandler.applyTouchPhysicsScaled(
        _visibleParticles, _accelerationTracker, timeScale, _sortedGrid);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _lastSize = size;
    _accelerationTracker.resetFrame();
    if (!_visibleParticlesFilteredThisStep) {
      ParticleFilter.getVisibleParticlesTo(particles, _visibleParticles);
    }
    _visibleParticlesFilteredThisStep = false;
    final List<int> visible = _visibleParticles;

    if (drawNetwork) {
      final FrameRadii r = _budgetController.computeFrameRadii(
        baseDistance: lineDistance,
        size: size,
        visibleCount: visible.length,
        maxLinesPerFrame: effectiveMaxLines,
        maxConnectionsPerParticle: effectiveMaxConnections,
        cappedDistanceFactor: performance.cappedDistanceFactor,
        safetyFloor: gridTuning.minCellFloor,
      );
      _lastFrameLineDistance = r.scanRadius;
      final double alphaSq = r.alphaRadius * r.alphaRadius;
      final double invMaxDistSq = alphaSq > 0 ? 1.0 / alphaSq : 0.0;
      _sortedGrid.build(
          particles,
          visible,
          size.width,
          size.height,
          r.gridRadius > 0 ? r.gridRadius : kFallbackLineDistance,
          performance.spatialCellMultiplier);
      _drawConnections(
          canvas, visible, r.scanRadius, r.alphaRadius, invMaxDistSq);
      _budgetController.updateFeedback(
          maxLinesPerFrame: effectiveMaxLines,
          lastFrameLineCount: _lastFrameLineCount,
          usedDistance: r.gridRadius,
          baseDistance: lineDistance);
    } else {
      _lastFrameLineCount = 0;
      if (_isTouchActive && visible.isNotEmpty) {
        final double td = _touchHandler.effectiveLineDistance;
        _sortedGrid.build(
            particles,
            visible,
            size.width,
            size.height,
            td > 0 ? td : kFallbackLineDistance,
            performance.spatialCellMultiplier);
      }
    }

    if (_isTouchActive) _paintTouch(canvas, visible);
    _particleRenderer.draw(
        canvas: canvas,
        particles: particles,
        visibleParticles: visible,
        particlePaint: particlePaint,
        fill: fill,
        antiAlias: performance.antiAlias,
        particleColor: particleColor);
  }

  void _paintTouch(Canvas canvas, List<int> visible) {
    final bool useFast = _touchHandler.lineRenderer == LineRenderer.vertices ||
        lineRenderer == LineRenderer.vertices ||
        visible.length >= kBatchThreshold;
    _touchHandler.drawTouchLines(canvas, visible,
        grid: _sortedGrid, fastLineRendering: useFast);
    if (simulateTouchInPaint) {
      _touchHandler.applyTouchPhysics(
          visible, _accelerationTracker, _sortedGrid);
    }
  }

  void _drawConnections(Canvas canvas, List<int> visible, double scanDist,
      double alphaDist, double invMaxDistSq) {
    final double maxDistSq = scanDist * scanDist;
    final bool complex = _isComplexThrottlingActive;
    final bool capped = effectiveMaxConnections != null;

    if (visible.length < kBatchThreshold) {
      _lastFrameLineCount = _scanner.scanIndividual(
        canvas: canvas,
        grid: _sortedGrid,
        scanDistance: scanDist,
        maxDistSq: maxDistSq,
        alphaDistance: alphaDist,
        lineColorLut: _palette.lineColorLut,
        linePaint: linePaint,
        candidateBuffer: _candidateBuffer,
        throttler: _throttler,
        performance: performance,
        maxConnectionsPerParticle: effectiveMaxConnections,
        isComplexMode: complex,
      );
      return;
    }

    _lineBuckets.clear();
    if (!complex && !capped) {
      _scanner.scanBatchedFast(
          grid: _sortedGrid,
          maxDistSq: maxDistSq,
          invMaxDistSq: invMaxDistSq,
          buckets: _lineBuckets);
    } else {
      _scanner.scanBatchedComplex(
        grid: _sortedGrid,
        maxDistSq: maxDistSq,
        invMaxDistSq: invMaxDistSq,
        scanDistance: scanDist,
        buckets: _lineBuckets,
        candidateBuffer: _candidateBuffer,
        throttler: _throttler,
        performance: performance,
        maxConnectionsPerParticle: effectiveMaxConnections,
        isComplexMode: complex,
      );
    }

    _lastFrameLineCount = lineRenderer == LineRenderer.vertices
        ? _lineBuckets.renderVertices(
            canvas: canvas,
            batch: _lineVertexBatch,
            vertexPaint: _vertexPaint,
            lineBucketPaints: _palette.lineBucketPaints,
            lineWidth: lineWidth,
            devicePixelRatio: devicePixelRatio)
        : _lineBuckets.renderStroke(canvas, _palette.lineBucketPaints);
  }

  bool get _isComplexThrottlingActive =>
      isComplex ||
      performance.complexReductionRatio != null ||
      performance.maxComplexLines != null;

  void updateColors(
      {Color? particleColor, Color? lineColor, Color? touchColor}) {
    if (particleColor != null && particleColor != this.particleColor) {
      this.particleColor = particleColor;
      particlePaint.color = particleColor;
    }
    if (lineColor != null && lineColor != this.lineColor) {
      this.lineColor = lineColor;
      linePaint.color = lineColor;
      _palette.updateColor(lineColor);
    }
    if (touchColor != null && touchColor != this.touchColor) {
      this.touchColor = touchColor;
      _touchHandler.rebuildTouchColorLut(touchColor);
    }
  }

  void _updateAntiAlias(bool value) {
    particlePaint.isAntiAlias = value;
    linePaint.isAntiAlias = value;
    _palette.updateAntiAlias(value);
  }

  void updatePerformance(PerformanceFeatures newPerformance) {
    resetRuntimeOverrides();
    if (newPerformance == performance) return;
    if (newPerformance.maxLinesPerFrame != performance.maxLinesPerFrame) {
      _budgetController.resetFeedback();
    }
    if (newPerformance.antiAlias != performance.antiAlias) {
      _updateAntiAlias(newPerformance.antiAlias);
    }
    performance = newPerformance;
  }

  void updatePerformanceOptions({
    int? maxConnectionsPerParticle,
    bool clearMaxConnectionsPerParticle = false,
    int? maxLinesPerFrame,
    bool clearMaxLinesPerFrame = false,
    LineRenderer? lineRenderer,
    bool? isComplex,
    double? complexReductionRatio,
    bool clearcomplexReductionRatio = false,
    int? maxComplexLines,
    bool clearMaxComplexLines = false,
    double? complexDensityFactor,
    bool clearcomplexDensityFactor = false,
    bool? antiAlias,
  }) {
    if (maxLinesPerFrame != null ||
        clearMaxLinesPerFrame ||
        maxConnectionsPerParticle != null ||
        clearMaxConnectionsPerParticle) {
      resetRuntimeOverrides();
    }
    if (lineRenderer != null) {
      this.lineRenderer = lineRenderer;
      _touchHandler.lineRenderer = lineRenderer;
    }
    updatePerformance(LegacyPainterAdapter.foldPerformanceOptions(
      current: performance,
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
    ));
  }

  void updateLineWidth(double width) {
    if (width == lineWidth) return;
    lineWidth = width;
    linePaint.strokeWidth = width;
    _palette.updateWidth(width);
  }

  void updateLineDistance(double distance) {
    if (distance == lineDistance) return;
    lineDistance = distance;
    _touchHandler.lineDistance = distance;
  }

  void updateRenderFlags({
    bool? drawNetwork,
    bool? fill,
    bool? isComplex,
    @Deprecated('Removed in 2.0.0.') bool? touchActivation,
    bool? antiAlias,
  }) {
    if (drawNetwork != null) this.drawNetwork = drawNetwork;
    if (touchActivation != null) {
      updateTouchFeatures(touchFeatures.copyWith(enabled: touchActivation));
    }
    if (fill != null && fill != this.fill) {
      this.fill = fill;
      particlePaint.style = fill ? PaintingStyle.fill : PaintingStyle.stroke;
    }
    if (isComplex != null || antiAlias != null) {
      updatePerformance(
          performance.copyWith(isComplex: isComplex, antiAlias: antiAlias));
    }
  }

  void updateTouchFeatures(TouchFeatures features) {
    touchFeatures = features;
    _touchHandler.touchFeatures = features;
    if (features.color != touchColor) {
      touchColor = features.color;
      _touchHandler.rebuildTouchColorLut(features.color);
    }
  }

  @override
  bool shouldRepaint(OptimizedNetworkPainter oldDelegate) =>
      LegacyPainterAdapter.shouldRepaint(
          this, oldDelegate, _accelerationTracker.hadAcceleratedParticles);

  @visibleForTesting
  void setCandidateBufferCapacityForTesting(int cap) =>
      _candidateBuffer.setCapacityForTesting(cap);

  @visibleForTesting
  void setUnifiedLineBufferCapacityForTesting(int cap) {}

  @visibleForTesting
  void drawConnectionsForTesting(Canvas c, List<int> v, [double? dist]) {
    final d = dist ?? lineDistance;
    final dSq = d * d;
    _drawConnections(c, v, d, d, dSq > 0 ? 1.0 / dSq : 0.0);
  }

  @visibleForTesting
  void drawIndividualConnectionsForTesting(Canvas c, List<int> v,
      [double? dist]) {
    final d = dist ?? lineDistance;
    final dSq = d * d;
    _lastFrameLineCount = _scanner.scanIndividual(
      canvas: c,
      grid: _sortedGrid,
      scanDistance: d,
      maxDistSq: dSq,
      alphaDistance: d,
      lineColorLut: _palette.lineColorLut,
      linePaint: linePaint,
      candidateBuffer: _candidateBuffer,
      throttler: _throttler,
      performance: performance,
      maxConnectionsPerParticle: effectiveMaxConnections,
      isComplexMode: _isComplexThrottlingActive,
    );
  }

  @visibleForTesting
  void drawBatchedConnectionsForTesting(Canvas c, List<int> v,
          [double? dist]) =>
      drawConnectionsForTesting(c, v, dist);

  @visibleForTesting
  void collectSortedConnectionsForTesting(double maxDistSq, bool unified,
      [double? dist]) {
    _lineBuckets.clear();
    _scanner.scanBatchedFast(
        grid: _sortedGrid,
        maxDistSq: maxDistSq,
        invMaxDistSq: maxDistSq > 0 ? 1.0 / maxDistSq : 0.0,
        buckets: _lineBuckets);
  }
}
