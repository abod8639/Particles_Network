/// Specialized painter for rendering a high-performance particle network.
///
/// This library provides [OptimizedNetworkPainter] and delegates its responsibilities
/// to small, testable single-purpose collaborators ([PairScanner], [LineBuckets],
/// [ParticleBatchRenderer], [LineBudgetController], [LineStylePalette]).
library;

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
  /// The list of particles currently in the system.
  final List<Particle> particles;

  /// The current touch position, if any.
  Offset? touchPoint;

  /// The maximum distance (in pixels) for connection lines to be drawn.
  double lineDistance;

  /// The base color for rendering particles.
  Color particleColor;

  /// The color used for connecting lines between particles.
  Color lineColor;

  /// The color used to highlight particles near a touch point.
  Color touchColor;

  /// Whether touch interaction effects are enabled.
  @Deprecated(
    'touchActivation was moved to touchFeatures.enabled. '
    'Use touchFeatures: TouchFeatures(enabled: ...) instead. '
    'This property will be removed in particles_network 2.0.0.',
  )
  bool touchActivation;

  /// The total number of particles, used for pre-allocation optimizations.
  final int particleCount;

  /// The width of the connecting lines.
  double lineWidth;

  /// Whether to use complex (high-quality) or optimized painting logic.
  @Deprecated(
    'Use performance (NetworkPerformance(isComplex: ...)) instead. '
    'This parameter will be removed in particles_network 2.0.0.',
  )
  bool get isComplex => performance.isComplex;
  set isComplex(bool value) {
    if (value != performance.isComplex) {
      performance = performance.copyWith(isComplex: value);
    }
  }

  /// Whether to fill particles (true) or draw them as outlines (false).
  bool fill;

  /// Whether to draw the web of connection lines between particles.
  bool drawNetwork;

  /// Legacy debug flag previously used to visualize QuadTree partitioning.
  @Deprecated(
    'QuadTree spatial partitioning has been superseded by SortedSpatialGrid. '
    'This parameter has no effect and will be removed in particles_network 2.0.0.',
  )
  final bool showQuadTree;

  /// Advanced touch interaction features and physics configuration.
  TouchFeatures touchFeatures;

  /// Performance settings and optimizations for rendering.
  NetworkPerformance performance;

  /// Maximum number of connection lines a single particle can emit.
  ///
  /// Degree capping is evaluated in first-come, first-served order as particles
  /// are scanned in row-major grid order. Once a particle reaches its cap, further
  /// candidate pairings with it are rejected.
  int? get maxConnectionsPerParticle => performance.maxConnectionsPerParticle;
  set maxConnectionsPerParticle(int? value) {
    performance = performance.copyWith(
      maxConnectionsPerParticle: value,
      clearMaxConnectionsPerParticle: value == null,
    );
  }

  /// Target upper bound on connection lines drawn per frame.
  int? get maxLinesPerFrame => performance.maxLinesPerFrame;
  set maxLinesPerFrame(int? value) {
    if (value != performance.maxLinesPerFrame) {
      _budgetController.resetFeedback();
    }
    performance = performance.copyWith(
      maxLinesPerFrame: value,
      clearMaxLinesPerFrame: value == null,
    );
  }

  /// How connection lines are rasterized (default: [LineRenderer.stroke]).
  LineRenderer get lineRenderer => performance.lineRenderer;
  set lineRenderer(LineRenderer value) {
    performance = performance.copyWith(lineRenderer: value);
  }

  /// Logical-to-physical pixel ratio of the target display (default: 1.0).
  double devicePixelRatio;

  /// Whether [paint] applies touch physics itself (default: true).
  bool simulateTouchInPaint;

  /// Immutable tuning parameters for spatial grid cell sizing and budgeting.
  final GridTuning gridTuning;

  /// Number of connection lines drawn in the most recent [paint] call.
  int get lastFrameLineCount => _lastFrameLineCount;
  int _lastFrameLineCount = 0;

  /// Connection scan radius actually used in the most recent [paint] call.
  double get lastFrameLineDistance => _lastFrameLineDistance;
  double _lastFrameLineDistance = 0;

  /// Default safety floor for connection radius budgeting and cell sizing (4.0 px).
  static const double defaultMinSafetyLineDistance =
      GridTuning.defaultMinCellFloor;

  // Collaborators
  final LineBudgetController _budgetController = LineBudgetController();
  late final LineStylePalette _palette;
  final CandidateBuffer _candidateBuffer = CandidateBuffer();
  static const ClusterThrottler _throttler = ClusterThrottler();
  final LineBuckets _lineBuckets = LineBuckets();
  final ParticleBatchRenderer _particleRenderer = ParticleBatchRenderer();
  static const PairScanner _scanner = PairScanner();

  // Rendering batches & handlers
  final LineVertexBatch _lineVertexBatch = LineVertexBatch();
  final Paint _vertexPaint = Paint();
  late final TouchInteractionHandler _touchHandler;
  final SortedSpatialGrid _sortedGrid;

  /// Exposes the underlying [SortedSpatialGrid] used for neighbor lookups.
  SortedSpatialGrid get spatialGrid => _sortedGrid;

  @visibleForTesting
  TouchInteractionHandler get touchHandler => _touchHandler;

  // Reusable paints
  late final Paint particlePaint;
  late final Paint linePaint;

  // Acceleration tracker
  late final AccelerationTracker _accelerationTracker;

  // Reusable particle visibility filter buffer
  final List<int> _visibleParticles = [];
  bool _visibleParticlesFilteredThisStep = false;
  Size? _lastSize;

  /// Creates a new [OptimizedNetworkPainter] with full backward compatibility.
  OptimizedNetworkPainter({
    required this.particleCount,
    required this.particles,
    required this.touchPoint,
    required this.lineDistance,
    required this.particleColor,
    required this.lineColor,
    Color? touchColor,
    @Deprecated(
      'touchActivation was moved to touchFeatures.enabled. '
      'Use touchFeatures: TouchFeatures(enabled: ...) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    bool? touchActivation,
    required this.lineWidth,
    @Deprecated(
      'Use performance (NetworkPerformance(isComplex: ...)) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    bool? isComplex,
    required this.fill,
    required this.drawNetwork,
    this.touchFeatures = const TouchFeatures(),
    NetworkPerformance performance = const NetworkPerformance(),
    this.showQuadTree = false,
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
          touchColor: touchColor,
          touchFeatures: touchFeatures,
        ),
        touchActivation = LegacyPainterAdapter.resolveTouchActivation(
          touchActivation: touchActivation,
          touchFeatures: touchFeatures,
        ),
        performance = LegacyPainterAdapter.resolvePerformance(
          basePerformance: performance,
          isComplex: isComplex,
          complexReductionRatio: complexReductionRatio,
          maxComplexLines: maxComplexLines,
          complexDensityFactor: complexDensityFactor,
          maxConnectionsPerParticle: maxConnectionsPerParticle,
          maxLinesPerFrame: maxLinesPerFrame,
          lineRenderer: lineRenderer,
          antiAlias: antiAlias,
        ) {
    LegacyPainterAdapter.warnIfQuadTreeRequested(showQuadTree);

    _palette = LineStylePalette(
      lineColor: lineColor,
      lineWidth: lineWidth,
      antiAlias: this.performance.antiAlias,
    );

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

  /// Updates touch point without recreating the painter instance
  void updateTouchPoint(Offset? newPoint) {
    touchPoint = newPoint;
    _touchHandler.touchPoint = newPoint;
  }

  bool get _isTouchActive =>
      touchActivation &&
      touchPoint != null &&
      touchPoint!.isFinite &&
      touchPoint != Offset.infinite;

  /// Applies touch attraction to the currently visible particles.
  void stepTouchPhysics([double timeScale = 1.0]) {
    if (!_isTouchActive) return;
    ParticleFilter.getVisibleParticlesTo(particles, _visibleParticles);
    _visibleParticlesFilteredThisStep = true;
    final Size? lastSize = _lastSize;
    if (lastSize != null &&
        lastSize.width > 0 &&
        lastSize.height > 0 &&
        _visibleParticles.isNotEmpty) {
      final double touchDist = _touchHandler.effectiveLineDistance;
      _sortedGrid.build(
        particles,
        _visibleParticles,
        lastSize.width,
        lastSize.height,
        touchDist > 0 ? touchDist : kFallbackLineDistance,
        performance.spatialCellMultiplier,
      );
    }
    _touchHandler.applyTouchPhysicsScaled(
      _visibleParticles,
      _accelerationTracker,
      timeScale,
      _sortedGrid,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    _lastSize = size;
    _accelerationTracker.resetFrame();

    if (!_visibleParticlesFilteredThisStep) {
      ParticleFilter.getVisibleParticlesTo(particles, _visibleParticles);
    }
    _visibleParticlesFilteredThisStep = false;
    final List<int> visibleParticles = _visibleParticles;

    if (drawNetwork) {
      final FrameRadii radii = _budgetController.computeFrameRadii(
        baseDistance: lineDistance,
        size: size,
        visibleCount: visibleParticles.length,
        maxLinesPerFrame: maxLinesPerFrame,
        maxConnectionsPerParticle: maxConnectionsPerParticle,
        cappedDistanceFactor: performance.cappedDistanceFactor,
        safetyFloor: gridTuning.minCellFloor,
      );

      _lastFrameLineDistance = radii.scanRadius;
      final double scanDist = radii.scanRadius;
      final double alphaDist = radii.alphaRadius;
      final double alphaDistSq = alphaDist * alphaDist;
      final double invMaxDistSq = alphaDistSq > 0 ? 1.0 / alphaDistSq : 0.0;

      _sortedGrid.build(
        particles,
        visibleParticles,
        size.width,
        size.height,
        radii.gridRadius > 0 ? radii.gridRadius : kFallbackLineDistance,
        performance.spatialCellMultiplier,
      );

      _drawConnections(canvas, visibleParticles, scanDist, invMaxDistSq);
      _budgetController.updateFeedback(
        maxLinesPerFrame: maxLinesPerFrame,
        lastFrameLineCount: _lastFrameLineCount,
        usedDistance: radii.gridRadius,
        baseDistance: lineDistance,
      );
    } else {
      _lastFrameLineCount = 0;
      if (_isTouchActive && visibleParticles.isNotEmpty) {
        final double touchDist = _touchHandler.effectiveLineDistance;
        _sortedGrid.build(
          particles,
          visibleParticles,
          size.width,
          size.height,
          touchDist > 0 ? touchDist : kFallbackLineDistance,
          performance.spatialCellMultiplier,
        );
      }
    }

    if (_isTouchActive) {
      final bool useFast =
          _touchHandler.lineRenderer == LineRenderer.vertices ||
              lineRenderer == LineRenderer.vertices ||
              visibleParticles.length >= kBatchThreshold;
      _touchHandler.drawTouchLines(
        canvas,
        visibleParticles,
        grid: _sortedGrid,
        fastLineRendering: useFast,
      );
      if (simulateTouchInPaint) {
        _touchHandler.applyTouchPhysics(
          visibleParticles,
          _accelerationTracker,
          _sortedGrid,
        );
      }
    }

    _particleRenderer.draw(
      canvas: canvas,
      particles: particles,
      visibleParticles: visibleParticles,
      particlePaint: particlePaint,
      fill: fill,
      antiAlias: performance.antiAlias,
      particleColor: particleColor,
    );
  }

  void _drawConnections(
    Canvas canvas,
    List<int> visibleParticles,
    double scanDist,
    double invMaxDistSq,
  ) {
    final double maxDistSq = scanDist * scanDist;
    final bool complex = _isComplexThrottlingActive;
    final bool capped = maxConnectionsPerParticle != null;

    if (visibleParticles.length < kBatchThreshold) {
      _lastFrameLineCount = _scanner.scanIndividual(
        canvas: canvas,
        grid: _sortedGrid,
        scanDistance: scanDist,
        maxDistSq: maxDistSq,
        lineColorLut: _palette.lineColorLut,
        linePaint: linePaint,
        candidateBuffer: _candidateBuffer,
        throttler: _throttler,
        performance: performance,
        maxConnectionsPerParticle: maxConnectionsPerParticle,
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
        buckets: _lineBuckets,
      );
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
        maxConnectionsPerParticle: maxConnectionsPerParticle,
        isComplexMode: complex,
      );
    }

    if (lineRenderer == LineRenderer.vertices) {
      _lastFrameLineCount = _lineBuckets.renderVertices(
        canvas: canvas,
        batch: _lineVertexBatch,
        vertexPaint: _vertexPaint,
        lineBucketPaints: _palette.lineBucketPaints,
        lineWidth: lineWidth,
        devicePixelRatio: devicePixelRatio,
      );
    } else {
      _lastFrameLineCount = _lineBuckets.renderStroke(
        canvas,
        _palette.lineBucketPaints,
      );
    }
  }

  bool get _isComplexThrottlingActive =>
      isComplex ||
      performance.complexReductionRatio != null ||
      performance.maxComplexLines != null;

  /// Updates colors for particles, lines, and optional touch feedback in-place.
  void updateColors({
    Color? particleColor,
    Color? lineColor,
    Color? touchColor,
  }) {
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

  /// Updates all performance settings at once using [NetworkPerformance].
  void updatePerformance(NetworkPerformance newPerformance) {
    if (newPerformance == performance) return;
    if (newPerformance.maxLinesPerFrame != performance.maxLinesPerFrame) {
      _budgetController.resetFeedback();
    }
    if (newPerformance.antiAlias != performance.antiAlias) {
      _updateAntiAlias(newPerformance.antiAlias);
    }
    _touchHandler.lineRenderer = newPerformance.lineRenderer;
    performance = newPerformance;
  }

  /// Updates performance and rendering strategy options.
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
    if (lineRenderer != null) {
      this.lineRenderer = lineRenderer;
      _touchHandler.lineRenderer = lineRenderer;
    }
    if (isComplex != null) this.isComplex = isComplex;
    if (clearcomplexReductionRatio ||
        complexReductionRatio != null ||
        clearMaxComplexLines ||
        maxComplexLines != null ||
        clearcomplexDensityFactor ||
        complexDensityFactor != null) {
      performance = performance.copyWith(
        complexReductionRatio: complexReductionRatio,
        clearcomplexReductionRatio: clearcomplexReductionRatio,
        maxComplexLines: maxComplexLines,
        clearMaxComplexLines: clearMaxComplexLines,
        complexDensityFactor: complexDensityFactor,
        clearcomplexDensityFactor: clearcomplexDensityFactor,
      );
    }
    if (antiAlias != null && antiAlias != performance.antiAlias) {
      performance = performance.copyWith(antiAlias: antiAlias);
      _updateAntiAlias(antiAlias);
    }
    if (clearMaxLinesPerFrame) {
      this.maxLinesPerFrame = null;
      _budgetController.resetFeedback();
    } else if (maxLinesPerFrame != null &&
        maxLinesPerFrame != this.maxLinesPerFrame) {
      this.maxLinesPerFrame = maxLinesPerFrame;
      _budgetController.resetFeedback();
    }
    if (clearMaxConnectionsPerParticle) {
      this.maxConnectionsPerParticle = null;
    } else if (maxConnectionsPerParticle != null) {
      this.maxConnectionsPerParticle = maxConnectionsPerParticle;
    }
  }

  /// Updates line width and synchronizes underlying stroke paints.
  void updateLineWidth(double width) {
    if (width == lineWidth) return;
    lineWidth = width;
    linePaint.strokeWidth = width;
    _palette.updateWidth(width);
  }

  /// Updates line connection distance and synchronizes touch handler.
  void updateLineDistance(double distance) {
    if (distance == lineDistance) return;
    lineDistance = distance;
    _touchHandler.lineDistance = distance;
  }

  /// Updates render flags (drawing network, fill mode, anti-alias).
  void updateRenderFlags({
    bool? drawNetwork,
    bool? fill,
    bool? isComplex,
    @Deprecated(
      'touchActivation was moved to touchFeatures.enabled. '
      'Use updateTouchFeatures(touchFeatures.copyWith(enabled: ...)) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    bool? touchActivation,
    bool? antiAlias,
  }) {
    if (drawNetwork != null) this.drawNetwork = drawNetwork;
    if (touchActivation != null) this.touchActivation = touchActivation;
    if (fill != null && fill != this.fill) {
      this.fill = fill;
      particlePaint.style = fill ? PaintingStyle.fill : PaintingStyle.stroke;
    }
    if (isComplex != null && isComplex != this.isComplex) {
      this.isComplex = isComplex;
    }
    if (antiAlias != null && antiAlias != performance.antiAlias) {
      performance = performance.copyWith(antiAlias: antiAlias);
      _updateAntiAlias(antiAlias);
    }
  }

  /// Updates touch interaction features.
  void updateTouchFeatures(TouchFeatures features) {
    touchFeatures = features;
    _touchHandler.touchFeatures = features;
    touchActivation = features.enabled;
    if (features.color != touchColor) {
      touchColor = features.color;
      _touchHandler.rebuildTouchColorLut(features.color);
    }
  }

  @override
  bool shouldRepaint(OptimizedNetworkPainter oldDelegate) {
    return oldDelegate.touchPoint != touchPoint ||
        _accelerationTracker.hadAcceleratedParticles ||
        oldDelegate.lineDistance != lineDistance ||
        oldDelegate.particleColor != particleColor ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.lineWidth != lineWidth ||
        oldDelegate.fill != fill ||
        oldDelegate.drawNetwork != drawNetwork ||
        oldDelegate.devicePixelRatio != devicePixelRatio ||
        oldDelegate.particleCount != particleCount ||
        oldDelegate.particles.length != particles.length ||
        oldDelegate.touchFeatures != touchFeatures ||
        oldDelegate.performance != performance;
  }

  @visibleForTesting
  void setCandidateBufferCapacityForTesting(int capacity) {
    _candidateBuffer.setCapacityForTesting(capacity);
  }

  @visibleForTesting
  void setUnifiedLineBufferCapacityForTesting(int capacity) {
    // Deprecated shim for legacy unified buffer test
  }

  @visibleForTesting
  void drawConnectionsForTesting(
    Canvas canvas,
    List<int> visibleParticles, [
    double? effectiveDistance,
  ]) {
    final double dist = effectiveDistance ?? lineDistance;
    final double maxDistSq = dist * dist;
    final double invMaxDistSq = maxDistSq > 0 ? 1.0 / maxDistSq : 0.0;
    _drawConnections(canvas, visibleParticles, dist, invMaxDistSq);
  }

  @visibleForTesting
  void drawIndividualConnectionsForTesting(
    Canvas canvas,
    List<int> visibleParticles, [
    double? effectiveDistance,
  ]) {
    final double dist = effectiveDistance ?? lineDistance;
    final double maxDistSq = dist * dist;
    _lastFrameLineCount = _scanner.scanIndividual(
      canvas: canvas,
      grid: _sortedGrid,
      scanDistance: dist,
      maxDistSq: maxDistSq,
      lineColorLut: _palette.lineColorLut,
      linePaint: linePaint,
      candidateBuffer: _candidateBuffer,
      throttler: _throttler,
      performance: performance,
      maxConnectionsPerParticle: maxConnectionsPerParticle,
      isComplexMode: _isComplexThrottlingActive,
    );
  }

  @visibleForTesting
  void drawBatchedConnectionsForTesting(
    Canvas canvas,
    List<int> visibleParticles, [
    double? effectiveDistance,
  ]) {
    final double dist = effectiveDistance ?? lineDistance;
    final double maxDistSq = dist * dist;
    final double invMaxDistSq = maxDistSq > 0 ? 1.0 / maxDistSq : 0.0;
    _drawConnections(canvas, visibleParticles, dist, invMaxDistSq);
  }

  @visibleForTesting
  void collectSortedConnectionsForTesting(
    double maxDistSq,
    bool unified, [
    double? dist,
  ]) {
    final double invMaxDistSq = maxDistSq > 0 ? 1.0 / maxDistSq : 0.0;
    _lineBuckets.clear();
    _scanner.scanBatchedFast(
      grid: _sortedGrid,
      maxDistSq: maxDistSq,
      invMaxDistSq: invMaxDistSq,
      buckets: _lineBuckets,
    );
  }
}
