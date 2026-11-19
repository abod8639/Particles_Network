/// Specialized painter for rendering a high-performance particle network.
///
/// This library provides the [OptimizedNetworkPainter] and related utilities
/// to render particles and their connections using advanced optimization
/// techniques like spatial partitioning and object pooling.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:particles_network/src/core/particle.dart';
import 'package:particles_network/src/interaction/touch_interaction_handler.dart';
import 'package:particles_network/src/legacy/legacy_deprecation_logger.dart';
import 'package:particles_network/src/rendering/line_vertex_batch.dart';
import 'package:particles_network/src/rendering/network_performance.dart';
import 'package:particles_network/src/rendering/particle_filter.dart';
import 'package:particles_network/src/rendering/performance_utils.dart';
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
  ///
  /// Deprecated: Moved into [touchFeatures.enabled].
  /// Configure via [TouchFeatures.enabled] instead:
  /// ```dart
  /// touchFeatures: TouchFeatures(enabled: false)
  /// ```
  /// This property will be removed in particles_network 2.0.0.
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
  ///
  /// Deprecated: Configure complex rendering mode via [performance]
  /// using [NetworkPerformance.isComplex] instead. This parameter will be removed in particles_network 2.0.0.
  @Deprecated(
    'Use performance (NetworkPerformance(isComplex: ...)) instead. This parameter will be removed in particles_network 2.0.0.',
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
  ///
  /// Deprecated: QuadTree spatial partitioning has been superseded by [SortedSpatialGrid].
  /// This parameter has no effect and will be removed in particles_network 2.0.0.
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
  /// Clamping connections guarantees strict O(N) rendering complexity, preventing
  /// explosive line counts and maintaining high FPS in dense particle clusters.
  ///
  /// Note on capping semantics: Degree capping is evaluated in first-come, first-served
  /// order as particles are scanned in row-major grid order. Once a particle reaches
  /// its cap, further candidate pairings with it are rejected.
  /// Note on top-k candidates: Candidate pairing uses a half-stencil to avoid duplicate
  /// checks ($O(N^2)/2$). Therefore, when candidate selection or top-k throttling is
  /// evaluated for particle $i$, it evaluates forward candidates ($j > i$ and South cells).
  int? get maxConnectionsPerParticle => performance.maxConnectionsPerParticle;
  set maxConnectionsPerParticle(int? value) {
    performance = performance.copyWith(
      maxConnectionsPerParticle: value,
      clearMaxConnectionsPerParticle: value == null,
    );
  }

  /// Target upper bound on connection lines drawn per frame.
  ///
  /// When set, the connection radius shrinks automatically so that the line
  /// count stays near this budget regardless of particle count or screen
  /// size. Line opacity fades relative to the reduced radius, so the network
  /// keeps its soft look instead of lines popping in and out.
  int? get maxLinesPerFrame => performance.maxLinesPerFrame;
  set maxLinesPerFrame(int? value) {
    if (value != performance.maxLinesPerFrame) {
      _budgetCorrection = 1.0;
    }
    performance = performance.copyWith(
      maxLinesPerFrame: value,
      clearMaxLinesPerFrame: value == null,
    );
  }

  /// How connection lines are rasterized (default: [LineRenderer.stroke]).
  ///
  /// [LineRenderer.vertices] submits batched connections as indexed triangle
  /// quads (one `drawVertices` call per opacity level), which is far cheaper
  /// on the GPU for large line counts.
  LineRenderer get lineRenderer => performance.lineRenderer;
  set lineRenderer(LineRenderer value) {
    performance = performance.copyWith(lineRenderer: value);
  }

  /// Logical-to-physical pixel ratio of the target display (default: 1.0).
  ///
  /// Used by [LineRenderer.vertices] to keep lines at least one physical
  /// pixel thick (thinner lines fade instead of dropping out).
  double devicePixelRatio;

  /// Whether [paint] applies touch physics itself (default: true).
  ///
  /// [ParticleNetwork] sets this to false and calls [stepTouchPhysics] from
  /// its ticker instead, keeping simulation and rendering decoupled.
  bool simulateTouchInPaint;

  /// Number of connection lines drawn in the most recent [paint] call.
  int get lastFrameLineCount => _lastFrameLineCount;
  int _lastFrameLineCount = 0;

  /// Connection radius actually used in the most recent [paint] call.
  double get lastFrameLineDistance => _lastFrameLineDistance;
  double _lastFrameLineDistance = 0;

  // Feedback correction applied on top of the analytic line-budget radius.
  double _budgetCorrection = 1.0;

  // Triangle batch used by LineRenderer.vertices, reused per opacity bucket.
  final LineVertexBatch _lineVertexBatch = LineVertexBatch();
  final Paint _vertexPaint = Paint();

  // Optimized sub-components
  late final TouchInteractionHandler _touchHandler;
  final SortedSpatialGrid _sortedGrid;

  @visibleForTesting
  TouchInteractionHandler get touchHandler => _touchHandler;

  /// Exposes the underlying [SortedSpatialGrid] used for neighbor lookups.
  SortedSpatialGrid get spatialGrid => _sortedGrid;

  // Reusable painting objects (initialized once for performance)
  late final Paint particlePaint;
  late final Paint linePaint;

  // Performance optimization components
  late final AccelerationTracker _accelerationTracker;

  /// Default safety floor for connection radius budgeting.
  /// When line budgeting shrinks connection radius, effective distance is allowed
  /// down to [defaultMinSafetyLineDistance] (4.0 px), eliminating wasted candidate checks.
  static const double defaultMinSafetyLineDistance = 4.0;
  static double minSafetyLineDistance = defaultMinSafetyLineDistance;

  /// Configures cell sizing floor and density multiplier.
  static void configureTuning({
    double safetyFloor = defaultMinSafetyLineDistance,
    double k = SortedSpatialGrid.defaultCellMultiplierK,
    bool boundingBox = false,
    double? minFloor,
  }) {
    minSafetyLineDistance = safetyFloor;
    SortedSpatialGrid.cellMultiplierK = k;
    SortedSpatialGrid.fitToBoundingBox = boundingBox;
    SortedSpatialGrid.minCellFloor = minFloor;
  }

  /// Resets cell sizing tuning to production defaults.
  static void resetTuning() {
    minSafetyLineDistance = defaultMinSafetyLineDistance;
    SortedSpatialGrid.cellMultiplierK =
        SortedSpatialGrid.defaultCellMultiplierK;
    SortedSpatialGrid.fitToBoundingBox = false;
    SortedSpatialGrid.minCellFloor = SortedSpatialGrid.defaultMinCellFloor;
  }

  Size? _lastSize;

  // Reusable internal buffers to avoid per-frame GC allocations
  final List<int> _visibleParticles = [];
  bool _visibleParticlesFilteredThisStep = false;
  Int32List _candidateIndices = Int32List(128);
  Float64List _candidateDistSq = Float64List(128);
  static const int _maxParticleSizeBuckets = 64;
  late final List<Float32List> _particleRawBuckets;
  final Int32List _particleRawOffsets = Int32List(_maxParticleSizeBuckets);
  final Paint _batchedPointPaint = Paint()..strokeCap = StrokeCap.round;

  // Number of alpha buckets for GPU line draw call batching
  static const int _numLineBuckets = 32;
  static final Int32List distBucketTable = _buildDistBucketTable();

  static Int32List _buildDistBucketTable() {
    final table = Int32List(1025);
    for (int i = 0; i <= 1024; i++) {
      final double ratio = math.sqrt(i / 1024.0);
      table[i] = ((1.0 - ratio) * (_numLineBuckets - 1))
          .round()
          .clamp(0, _numLineBuckets - 1);
    }
    return table;
  }

  late final List<Float32List> _rawBuckets;
  late final Int32List _rawOffsets;
  late final List<Paint> _lineBucketPaints;
  late double _invMaxDistSq;

  // Precomputed color look-up table for zero-allocation alpha line rendering
  late final List<Color> _lineColorLut;

  // Ultra-performance single draw-call line buffer
  Float32List _unifiedLineBuffer = Float32List(4096);
  int _unifiedLineCount = 0;

  // Connection count tracking buffer for strict O(N) capping
  Int32List _connectionCounts = Int32List(0);

  Int32List _getClearedConnectionCounts(int minSize) {
    if (_connectionCounts.length < minSize) {
      _connectionCounts = Int32List(minSize);
    }
    _connectionCounts.fillRange(0, minSize, 0);
    return _connectionCounts;
  }

  /// Constructor with dependency initialization
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
      'Use performance (NetworkPerformance(isComplex: ...)) instead. This parameter will be removed in particles_network 2.0.0.',
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
    SortedSpatialGrid? spatialGrid,
    super.repaint,
  })  : _sortedGrid = spatialGrid ?? SortedSpatialGrid(),
        touchColor = touchColor ?? touchFeatures.color,
        touchActivation = touchActivation ?? touchFeatures.enabled,
        performance = performance.copyWith(
          isComplex: isComplex,
          complexReductionRatio: complexReductionRatio,
          maxComplexLines: maxComplexLines,
          complexDensityFactor: complexDensityFactor,
          maxConnectionsPerParticle: maxConnectionsPerParticle,
          maxLinesPerFrame: maxLinesPerFrame,
          lineRenderer: lineRenderer,
          antiAlias: antiAlias,
        ) {
    if (showQuadTree) {
      LegacyDeprecationLogger.warn(
        deprecatedApi: 'OptimizedNetworkPainter(showQuadTree: true)',
        replacement: 'SortedSpatialGrid (automatic zero-allocation grid)',
      );
    }
    final int baseAlpha = (lineColor.a * 255.0).round().clamp(0, 255);
    _lineColorLut = List<Color>.generate(
      256,
      (int alpha) => lineColor.withAlpha((alpha * baseAlpha) ~/ 255),
      growable: false,
    );

    _particleRawBuckets =
        List.generate(_maxParticleSizeBuckets, (_) => Float32List(256));

    _rawBuckets = List.generate(_numLineBuckets, (_) => Float32List(2048));
    _rawOffsets = Int32List(_numLineBuckets);

    _lineBucketPaints = List.generate(_numLineBuckets, (int b) {
      final int alpha =
          ((b * baseAlpha) ~/ (_numLineBuckets - 1)).clamp(0, 255);
      return Paint()
        ..color = lineColor.withAlpha(alpha)
        ..strokeWidth = lineWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = this.performance.antiAlias;
    });

    final double maxDistSq = lineDistance * lineDistance;
    _invMaxDistSq = maxDistSq > 0 ? 1.0 / maxDistSq : 0.0;

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
      lineRenderer: this.performance.lineRenderer,
      fastLineRendering:
          this.performance.lineRenderer == LineRenderer.vertices ||
              particleCount >= 30,
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

  /// Applies touch attraction to the currently visible particles, integrated
  /// over [timeScale] 60 Hz reference frames.
  ///
  /// Only needed when [simulateTouchInPaint] is false.
  void stepTouchPhysics([double timeScale = 1.0]) {
    if (!_isTouchActive) return;
    // Refresh: the particle list may have shrunk since the last paint.
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
        touchDist > 0 ? touchDist : 100.0,
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

  /// Returns the connection radius that keeps the line count near
  /// [maxLinesPerFrame], never exceeding [baseDistance].
  ///
  /// For N uniformly spread particles over area A, the expected number of
  /// pairs closer than r is N² · π · r² / (2 · A); solving for r gives the
  /// analytic radius. A feedback factor learned from the measured line count
  /// corrects for clustering (gravity, touch) and screen-edge effects.
  double _budgetedDistance(double baseDistance, Size size, int count) {
    final int? budget = maxLinesPerFrame;
    if (budget == null || count < 2) return baseDistance;
    if (budget <= 0) return 0;
    final double area = size.width * size.height;
    final double analytic =
        math.sqrt(2.0 * area * budget / (math.pi * count * count));
    final double r = analytic * _budgetCorrection;
    return r < baseDistance ? r : baseDistance;
  }

  void _updateBudgetCorrection(double usedDistance, double baseDistance) {
    final int? budget = maxLinesPerFrame;
    if (budget == null || budget <= 0) return;
    final int lines = _lastFrameLineCount;
    // Not budget-limited and under budget: nothing to correct.
    if (usedDistance >= baseDistance && lines <= budget) return;
    final double ratio = budget / (lines > 0 ? lines : 1);
    if (ratio > 0.9 && ratio < 1.1) return;
    // Lines scale with r², so r scales with sqrt(ratio); take half of that
    // step (ratio^0.25) to converge without oscillating.
    _budgetCorrection =
        (_budgetCorrection * math.pow(ratio, 0.25)).clamp(0.2, 5.0);
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
      final double safetyFloor = lineDistance > 0
          ? math.min(lineDistance, minSafetyLineDistance)
          : 0.0;

      final double distance = _budgetedDistance(
        lineDistance,
        size,
        visibleParticles.length,
      );

      // When capped, constrain pairing distance to cappedDistanceFactor to eliminate
      // jarring long lines and visual connection thrashing/flickering.
      double activeDist = (maxConnectionsPerParticle != null &&
              performance.cappedDistanceFactor < 1.0 &&
              performance.cappedDistanceFactor > 0.0)
          ? distance * performance.cappedDistanceFactor
          : distance;

      activeDist = math.max(safetyFloor, activeDist);
      _lastFrameLineDistance = activeDist;

      // Fade lines relative to the active radius so connections smoothly
      // fade to transparent without hard popping when density adaptation or capping is enabled.
      final double alphaDistance = activeDist;
      final double alphaDistSq = alphaDistance * alphaDistance;
      _invMaxDistSq = alphaDistSq > 0 ? 1.0 / alphaDistSq : 0.0;

      // Build the unified cell-sorted SoA spatial grid for all connection paths.
      if (SortedSpatialGrid.enableInstrumentation) {
        SortedSpatialGrid.swBuild.reset();
        SortedSpatialGrid.swBuild.start();
      }
      _sortedGrid.build(
        particles,
        visibleParticles,
        size.width,
        size.height,
        activeDist > 0 ? activeDist : 100.0,
        performance.spatialCellMultiplier,
      );
      if (SortedSpatialGrid.enableInstrumentation) {
        SortedSpatialGrid.swBuild.stop();
        SortedSpatialGrid.gridBuildMicros +=
            SortedSpatialGrid.swBuild.elapsedMicroseconds;
      }

      _drawConnections(canvas, visibleParticles, activeDist);
      _updateBudgetCorrection(distance, lineDistance);
    } else {
      _lastFrameLineCount = 0;
      if (_isTouchActive && visibleParticles.isNotEmpty) {
        final double touchDist = _touchHandler.effectiveLineDistance;
        _sortedGrid.build(
          particles,
          visibleParticles,
          size.width,
          size.height,
          touchDist > 0 ? touchDist : 100.0,
          performance.spatialCellMultiplier,
        );
      }
    }

    if (_isTouchActive) {
      final bool useFast =
          _touchHandler.lineRenderer == LineRenderer.vertices ||
              lineRenderer == LineRenderer.vertices ||
              visibleParticles.length >= 30;
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

    _drawParticles(canvas, visibleParticles);
    if (SortedSpatialGrid.enableInstrumentation) {
      SortedSpatialGrid.frameCount++;
    }
  }

  void _drawParticles(Canvas canvas, List<int> visibleParticles) {
    final int count = visibleParticles.length;
    if (count == 0) return;

    if (!fill) {
      for (int i = 0; i < count; i++) {
        final Particle p = particles[visibleParticles[i]];
        canvas.drawCircle(Offset(p.x, p.y), p.size, particlePaint);
      }
      return;
    }

    if (count < 5) {
      for (int i = 0; i < count; i++) {
        final Particle p = particles[visibleParticles[i]];
        canvas.drawCircle(Offset(p.x, p.y), p.size, particlePaint);
      }
      return;
    }

    _drawBatchedParticles(canvas, visibleParticles);
  }

  void _drawBatchedParticles(Canvas canvas, List<int> visibleParticles) {
    _particleRawOffsets.fillRange(0, _maxParticleSizeBuckets, 0);
    final int count = visibleParticles.length;

    for (int i = 0; i < count; i++) {
      final Particle p = particles[visibleParticles[i]];
      int bucket = (p.size * 2).round();
      if (bucket < 1) bucket = 1;
      if (bucket >= _maxParticleSizeBuckets) {
        bucket = _maxParticleSizeBuckets - 1;
      }

      final int off = _particleRawOffsets[bucket];
      Float32List raw = _particleRawBuckets[bucket];
      if (off + 2 > raw.length) {
        final newBuf = Float32List(math.max(raw.length * 2, off + 2));
        newBuf.setRange(0, off, raw);
        _particleRawBuckets[bucket] = newBuf;
        raw = newBuf;
      }
      raw[off] = p.x;
      raw[off + 1] = p.y;
      _particleRawOffsets[bucket] = off + 2;
    }

    _batchedPointPaint
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = performance.antiAlias
      ..color = particleColor;

    for (int b = 1; b < _maxParticleSizeBuckets; b++) {
      final int rawCount = _particleRawOffsets[b];
      if (rawCount > 0) {
        _batchedPointPaint.strokeWidth = b.toDouble();
        canvas.drawRawPoints(
          PointMode.points,
          Float32List.sublistView(_particleRawBuckets[b], 0, rawCount),
          _batchedPointPaint,
        );
      }
    }
  }

  void _growCandidateBuffers() {
    final int newSize = _candidateIndices.length * 2;
    final newIndices = Int32List(newSize);
    newIndices.setRange(0, _candidateIndices.length, _candidateIndices);
    _candidateIndices = newIndices;

    final newDistSq = Float64List(newSize);
    newDistSq.setRange(0, _candidateDistSq.length, _candidateDistSq);
    _candidateDistSq = newDistSq;
  }

  void _selectTopKClosest(int count, int k) {
    final int limit = k < count ? k : count;
    for (int i = 0; i < limit; i++) {
      int minIdx = i;
      double minDistSq = _candidateDistSq[i];
      for (int j = i + 1; j < count; j++) {
        final double dSq = _candidateDistSq[j];
        if (dSq < minDistSq) {
          minDistSq = dSq;
          minIdx = j;
        }
      }
      if (minIdx != i) {
        _candidateDistSq[minIdx] = _candidateDistSq[i];
        _candidateDistSq[i] = minDistSq;
        final int tmpI = _candidateIndices[i];
        _candidateIndices[i] = _candidateIndices[minIdx];
        _candidateIndices[minIdx] = tmpI;
      }
    }
  }

  // ===========================================================================
  // Complex Cluster Throttling & Aesthetic Optimization
  // ===========================================================================

  /// Returns whether complex cluster throttling is active based on [isComplex]
  /// or explicit complex reduction tuning parameters.
  bool get _isComplexThrottlingActive =>
      isComplex ||
      performance.complexReductionRatio != null ||
      performance.maxComplexLines != null;

  /// Calculates the neighbor count threshold above which a particle's neighborhood
  /// is classified as a dense cluster.
  @pragma('vm:prefer-inline')
  int _computeDenseThreshold(double distance, {bool isIndividual = false}) {
    final double? customFactor = performance.complexDensityFactor;
    if (customFactor != null) {
      return distance > 0 ? (distance * customFactor).toInt() : 0;
    }
    if (isComplex) {
      return distance > 0 ? (distance ~/ 4) : 0;
    }
    return distance > 0 ? (distance ~/ (isIndividual ? 1.5 : 4)) : 0;
  }

  /// Resolves the target number of allowed connection lines for a particle in a
  /// dense cluster based on [performance] settings.
  @pragma('vm:prefer-inline')
  int _resolveComplexTargetLines(int candidateCount, int defaultMaxLines) {
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
  /// the closest [k] candidates using [_selectTopKClosest] and returns the final
  /// number of lines to draw. Returns 0 if no lines should be drawn.
  @pragma('vm:prefer-inline')
  int _filterComplexCandidates({
    required int candidateCount,
    required bool isCapped,
    required int remainingCap,
    required int denseThreshold,
    required int defaultMaxLines,
    required bool isComplexMode,
  }) {
    int maxAllowed = candidateCount;
    if (isCapped && remainingCap < maxAllowed) {
      maxAllowed = remainingCap;
    }

    if (isComplexMode && candidateCount > denseThreshold) {
      final int target =
          _resolveComplexTargetLines(candidateCount, defaultMaxLines);
      if (target < maxAllowed) {
        maxAllowed = target;
      }
    }

    if (maxAllowed <= 0) return 0;

    if (candidateCount > maxAllowed) {
      _selectTopKClosest(candidateCount, maxAllowed);
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
  double _calculateComplexLineFade(int rank, int drawCount) {
    if (drawCount <= 1) return 1.0;
    final double progress = rank / (drawCount - 0.5);
    if (progress >= 1.0) return 0.0;
    return 0.5 * (1.0 + math.cos(math.pi * progress));
  }

  Float32List _growBucket(int b, int needed) {
    final newBuf = Float32List(math.max(_rawBuckets[b].length * 2, needed));
    newBuf.setRange(0, _rawOffsets[b], _rawBuckets[b]);
    _rawBuckets[b] = newBuf;
    return newBuf;
  }

  void _growUnifiedLineBuffer(int needed) {
    final int newLen = math.max(_unifiedLineBuffer.length * 2, needed);
    final Float32List newBuf = Float32List(newLen);
    newBuf.setRange(0, _unifiedLineCount, _unifiedLineBuffer);
    _unifiedLineBuffer = newBuf;
  }

  void _drawConnections(
    Canvas canvas,
    List<int> visibleParticles, [
    double? scanRadius,
  ]) {
    final double dist = scanRadius ?? lineDistance;

    if (visibleParticles.length < 30) {
      _drawIndividualConnections(canvas, visibleParticles, dist);
    } else {
      _drawBatchedConnections(canvas, visibleParticles, dist);
    }
  }

  void _drawIndividualConnections(
    Canvas canvas,
    List<int> visibleParticles, [
    double? effectiveDistance,
  ]) {
    final double dist = effectiveDistance ?? lineDistance;
    final double maxDistSq = dist * dist;
    final double invLineDistance = dist > 0 ? 255.0 / dist : 0.0;
    final int defaultMaxLines =
        performance.maxComplexLines ?? (isComplex ? 3 : 5);
    final int denseThreshold = _computeDenseThreshold(dist, isIndividual: true);
    final bool complexMode = _isComplexThrottlingActive;

    final int? maxConn = maxConnectionsPerParticle;
    final bool capped = maxConn != null;
    final int cap = maxConn ?? 0;

    final SortedSpatialGrid grid = _sortedGrid;
    final int cols = grid.cols;
    final int rows = grid.rows;
    if (cols <= 0 || rows <= 0) {
      _lastFrameLineCount = 0;
      return;
    }

    final Int32List start = grid.cellStart;
    final Float64List xs = grid.xs;
    final Float64List ys = grid.ys;

    final Int32List counts;
    if (capped) {
      counts = _getClearedConnectionCounts(grid.count);
    } else {
      counts = _connectionCounts;
    }

    int lineCount = 0;
    final Color previousColor = linePaint.color;

    try {
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
            final double px = xs[i];
            final double py = ys[i];

            int candidateCount = 0;
            for (int j = i + 1; j < nearEnd; j++) {
              if (SortedSpatialGrid.enableInstrumentation) {
                SortedSpatialGrid.candidateChecks++;
                SortedSpatialGrid.loopIterations++;
              }
              if (capped && counts[j] >= cap) continue;
              final double dx = px - xs[j];
              final double dxSq = dx * dx;
              if (dxSq > maxDistSq) continue;
              final double dy = py - ys[j];
              final double distSq = dxSq + dy * dy;
              if (distSq <= maxDistSq) {
                if (SortedSpatialGrid.enableInstrumentation) {
                  SortedSpatialGrid.acceptedPairs++;
                }
                if (candidateCount >= _candidateIndices.length) {
                  _growCandidateBuffers();
                }
                _candidateIndices[candidateCount] = j;
                _candidateDistSq[candidateCount] = distSq;
                candidateCount++;
              }
            }
            for (int j = southStart; j < southEnd; j++) {
              if (SortedSpatialGrid.enableInstrumentation) {
                SortedSpatialGrid.candidateChecks++;
                SortedSpatialGrid.loopIterations++;
              }
              if (capped && counts[j] >= cap) continue;
              final double dx = px - xs[j];
              final double dxSq = dx * dx;
              if (dxSq > maxDistSq) continue;
              final double dy = py - ys[j];
              final double distSq = dxSq + dy * dy;
              if (distSq <= maxDistSq) {
                if (SortedSpatialGrid.enableInstrumentation) {
                  SortedSpatialGrid.acceptedPairs++;
                }
                if (candidateCount >= _candidateIndices.length) {
                  _growCandidateBuffers();
                }
                _candidateIndices[candidateCount] = j;
                _candidateDistSq[candidateCount] = distSq;
                candidateCount++;
              }
            }

            if (candidateCount > 0) {
              final int remainingCap =
                  capped ? (cap - counts[i]) : candidateCount;
              final int drawCount = _filterComplexCandidates(
                candidateCount: candidateCount,
                isCapped: capped,
                remainingCap: remainingCap,
                denseThreshold: denseThreshold,
                defaultMaxLines: defaultMaxLines,
                isComplexMode: complexMode,
              );
              if (drawCount <= 0) continue;

              final bool isThrottled = drawCount < candidateCount;
              final Offset pos = Offset(px, py);
              for (int candIdx = 0; candIdx < drawCount; candIdx++) {
                final int j = _candidateIndices[candIdx];
                final double distance = math.sqrt(_candidateDistSq[candIdx]);
                int alpha =
                    (255 - (distance * invLineDistance)).toInt().clamp(0, 255);
                if (isThrottled && drawCount > 1) {
                  final double rankFade =
                      _calculateComplexLineFade(candIdx, drawCount);
                  alpha = (alpha * rankFade).toInt().clamp(0, 255);
                }
                linePaint.color = _lineColorLut[alpha];
                canvas.drawLine(pos, Offset(xs[j], ys[j]), linePaint);

                if (capped) {
                  counts[i]++;
                  counts[j]++;
                }
              }
              lineCount += drawCount;
            }
          }
        }
      }
    } finally {
      linePaint.color = previousColor;
      _lastFrameLineCount = lineCount;
    }
  }

  void _drawBatchedConnections(
    Canvas canvas,
    List<int> visibleParticles, [
    double? effectiveDistance,
  ]) {
    final double dist = effectiveDistance ?? lineDistance;
    final double maxDistSq = dist * dist;
    _rawOffsets.fillRange(0, _numLineBuckets, 0);

    if (isComplex) {
      _drawBatchedConnectionsComplex(visibleParticles, maxDistSq, dist);
    } else {
      _drawBatchedConnectionsFast(maxDistSq, dist);
    }

    if (SortedSpatialGrid.enableInstrumentation) {
      SortedSpatialGrid.swEmission.reset();
      SortedSpatialGrid.swEmission.start();
    }
    if (lineRenderer == LineRenderer.vertices) {
      _drawBucketsAsVertices(canvas);
      if (SortedSpatialGrid.enableInstrumentation) {
        SortedSpatialGrid.swEmission.stop();
        SortedSpatialGrid.emissionMicros +=
            SortedSpatialGrid.swEmission.elapsedMicroseconds;
      }
      return;
    }

    int lineCount = 0;
    for (int b = 0; b < _numLineBuckets; b++) {
      final int rawCount = _rawOffsets[b];
      lineCount += rawCount ~/ 4;
      if (rawCount > 0) {
        canvas.drawRawPoints(
          PointMode.lines,
          Float32List.sublistView(_rawBuckets[b], 0, rawCount),
          _lineBucketPaints[b],
        );
      }
    }
    _lastFrameLineCount = lineCount;
    if (SortedSpatialGrid.enableInstrumentation) {
      SortedSpatialGrid.swEmission.stop();
      SortedSpatialGrid.emissionMicros +=
          SortedSpatialGrid.swEmission.elapsedMicroseconds;
    }
  }

  /// Quad thickness for [LineRenderer.vertices]: [lineWidth], but never
  /// thinner than one physical pixel so lines cannot drop out of coverage.
  double _vertexLineWidth() {
    final double minWidth = devicePixelRatio > 0 ? 1.0 / devicePixelRatio : 1.0;
    return lineWidth > minWidth ? lineWidth : minWidth;
  }

  /// [color] as ARGB with its alpha multiplied by [alphaScale].
  static int _scaledArgb(Color color, double alphaScale) {
    final int argb = color.toARGB32();
    if (alphaScale >= 1.0) return argb;
    final int alpha = ((argb >>> 24) * alphaScale).round().clamp(0, 255);
    return (alpha << 24) | (argb & 0x00FFFFFF);
  }

  void _drawBucketsAsVertices(Canvas canvas) {
    final double width = _vertexLineWidth();
    final double alphaScale = lineWidth / width;
    final double halfWidth = width * 0.5;
    final LineVertexBatch batch = _lineVertexBatch;

    batch.clear();
    int lineCount = 0;
    for (int b = 0; b < _numLineBuckets; b++) {
      final int rawCount = _rawOffsets[b];
      if (rawCount == 0) continue;
      lineCount += rawCount ~/ 4;
      final int argb = _scaledArgb(_lineBucketPaints[b].color, alphaScale);
      // Fully transparent buckets add GPU work without visible output.
      if ((argb >>> 24) == 0) continue;
      batch.addSegments(_rawBuckets[b], rawCount, halfWidth, null, argb);
    }
    if (batch.lineCount > 0) {
      _vertexPaint.color = const Color(0xFFFFFFFF);
      batch.draw(canvas, _vertexPaint);
    }
    _lastFrameLineCount = lineCount;
  }

  void _drawBatchedConnectionsFast(double maxDistSq, [double? dist]) {
    _collectSortedConnections(maxDistSq, false, dist);
  }

  /// Finds every pair of visible particles closer than `sqrt(maxDistSq)`
  /// using [_sortedGrid], appending each to the alpha buckets or, when
  /// [unified], to the single-colour unified buffer.
  ///
  /// When [isComplex] is true, particles in dense clusters (where neighbor candidates
  /// exceed the density threshold) are throttled to the top 5 closest connections
  /// with rank fading, reducing visual clutter and draw call pressure at points of
  /// high particle density without sacrificing the overall network structure.
  void _collectSortedConnections(
    double maxDistSq,
    bool unified, [
    double? dist,
  ]) {
    final SortedSpatialGrid grid = _sortedGrid;
    final int cols = grid.cols;
    final int rows = grid.rows;
    if (cols <= 0 || rows <= 0) return;

    final Int32List start = grid.cellStart;
    final Float64List xs = grid.xs;
    final Float64List ys = grid.ys;

    final int? maxConn = maxConnectionsPerParticle;
    final bool capped = maxConn != null;
    final int cap = maxConn ?? 0;
    final Int32List counts;
    if (capped) {
      counts = _getClearedConnectionCounts(grid.count);
    } else {
      counts = _connectionCounts;
    }

    final bool complex = _isComplexThrottlingActive;
    final double effectiveDist =
        dist ?? (maxDistSq > 0 ? math.sqrt(maxDistSq) : lineDistance);
    final int denseThreshold = _computeDenseThreshold(effectiveDist);
    final int maxComplexLines = performance.maxComplexLines ?? 5;

    if (SortedSpatialGrid.enableInstrumentation) {
      SortedSpatialGrid.swScan.reset();
      SortedSpatialGrid.swScan.start();
    }

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

          if (!complex && !capped) {
            for (int j = i + 1; j < nearEnd; j++) {
              if (SortedSpatialGrid.enableInstrumentation) {
                SortedSpatialGrid.candidateChecks++;
                SortedSpatialGrid.loopIterations++;
              }
              final double dx = x1 - xs[j];
              final double dxSq = dx * dx;
              if (dxSq > maxDistSq) continue;
              final double dy = y1 - ys[j];
              final double distSq = dxSq + dy * dy;
              if (distSq <= maxDistSq) {
                if (SortedSpatialGrid.enableInstrumentation) {
                  SortedSpatialGrid.acceptedPairs++;
                }
                _emitConnection(unified, x1, y1, xs[j], ys[j], distSq);
              }
            }
            for (int j = southStart; j < southEnd; j++) {
              if (SortedSpatialGrid.enableInstrumentation) {
                SortedSpatialGrid.candidateChecks++;
                SortedSpatialGrid.loopIterations++;
              }
              final double dx = x1 - xs[j];
              final double dxSq = dx * dx;
              if (dxSq > maxDistSq) continue;
              final double dy = y1 - ys[j];
              final double distSq = dxSq + dy * dy;
              if (distSq <= maxDistSq) {
                if (SortedSpatialGrid.enableInstrumentation) {
                  SortedSpatialGrid.acceptedPairs++;
                }
                _emitConnection(unified, x1, y1, xs[j], ys[j], distSq);
              }
            }
            continue;
          }

          int candidateCount = 0;
          for (int j = i + 1; j < nearEnd; j++) {
            if (SortedSpatialGrid.enableInstrumentation) {
              SortedSpatialGrid.candidateChecks++;
              SortedSpatialGrid.loopIterations++;
            }
            if (capped && counts[j] >= cap) continue;
            final double dx = x1 - xs[j];
            final double dxSq = dx * dx;
            if (dxSq > maxDistSq) continue;
            final double dy = y1 - ys[j];
            final double distSq = dxSq + dy * dy;
            if (distSq <= maxDistSq) {
              if (SortedSpatialGrid.enableInstrumentation) {
                SortedSpatialGrid.acceptedPairs++;
              }
              if (candidateCount >= _candidateIndices.length) {
                _growCandidateBuffers();
              }
              _candidateIndices[candidateCount] = j;
              _candidateDistSq[candidateCount] = distSq;
              candidateCount++;
            }
          }
          for (int j = southStart; j < southEnd; j++) {
            if (SortedSpatialGrid.enableInstrumentation) {
              SortedSpatialGrid.candidateChecks++;
              SortedSpatialGrid.loopIterations++;
            }
            if (capped && counts[j] >= cap) continue;
            final double dx = x1 - xs[j];
            final double dxSq = dx * dx;
            if (dxSq > maxDistSq) continue;
            final double dy = y1 - ys[j];
            final double distSq = dxSq + dy * dy;
            if (distSq <= maxDistSq) {
              if (SortedSpatialGrid.enableInstrumentation) {
                SortedSpatialGrid.acceptedPairs++;
              }
              if (candidateCount >= _candidateIndices.length) {
                _growCandidateBuffers();
              }
              _candidateIndices[candidateCount] = j;
              _candidateDistSq[candidateCount] = distSq;
              candidateCount++;
            }
          }

          if (candidateCount == 0) continue;

          final int remainingCap = capped ? (cap - counts[i]) : candidateCount;
          final int drawCount = _filterComplexCandidates(
            candidateCount: candidateCount,
            isCapped: capped,
            remainingCap: remainingCap,
            denseThreshold: denseThreshold,
            defaultMaxLines: maxComplexLines,
            isComplexMode: complex,
          );
          if (drawCount <= 0) continue;

          final bool isThrottled = drawCount < candidateCount;
          for (int k = 0; k < drawCount; k++) {
            final int j = _candidateIndices[k];
            final double distSq = _candidateDistSq[k];
            final double x2 = xs[j];
            final double y2 = ys[j];

            double rankFade = 1.0;
            if (complex && isThrottled && drawCount > 1) {
              rankFade = _calculateComplexLineFade(k, drawCount);
            }

            _emitConnection(unified, x1, y1, x2, y2, distSq, rankFade);

            if (capped) {
              counts[i]++;
              counts[j]++;
            }
          }
        }
      }
    }

    if (SortedSpatialGrid.enableInstrumentation) {
      SortedSpatialGrid.swScan.stop();
      final int micros = SortedSpatialGrid.swScan.elapsedMicroseconds;
      SortedSpatialGrid.scanLoopMicros += micros;
      if (SortedSpatialGrid.frameScanCount <
          SortedSpatialGrid.frameScanTimes.length) {
        SortedSpatialGrid.frameScanTimes[SortedSpatialGrid.frameScanCount++] =
            micros / 1000.0;
      }
    }
  }

  @pragma('vm:prefer-inline')
  void _emitConnection(
    bool unified,
    double x1,
    double y1,
    double x2,
    double y2,
    double distSq, [
    double rankFade = 1.0,
  ]) {
    if (unified) {
      final int off = _unifiedLineCount;
      if (off + 4 > _unifiedLineBuffer.length) {
        _growUnifiedLineBuffer(off + 4);
      }
      final Float32List buf = _unifiedLineBuffer;
      buf[off] = x1;
      buf[off + 1] = y1;
      buf[off + 2] = x2;
      buf[off + 3] = y2;
      _unifiedLineCount = off + 4;
      return;
    }

    int tableIdx = ((distSq * _invMaxDistSq) * 1024).toInt();
    if (tableIdx > 1024) tableIdx = 1024;
    int bucket = distBucketTable[tableIdx];
    if (rankFade < 1.0) {
      bucket = (bucket * rankFade).round().clamp(
            0,
            _numLineBuckets - 1,
          );
    }
    final int off = _rawOffsets[bucket];
    Float32List raw = _rawBuckets[bucket];
    if (off + 4 > raw.length) {
      raw = _growBucket(bucket, off + 4);
    }
    raw[off] = x1;
    raw[off + 1] = y1;
    raw[off + 2] = x2;
    raw[off + 3] = y2;
    _rawOffsets[bucket] = off + 4;
  }

  void _drawBatchedConnectionsComplex(
    List<int> visibleParticles,
    double maxDistSq, [
    double? dist,
  ]) {
    _collectSortedConnections(maxDistSq, false, dist);
  }

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
      _rebuildLineLut(lineColor);
    }
    if (touchColor != null && touchColor != this.touchColor) {
      this.touchColor = touchColor;
      _touchHandler.rebuildTouchColorLut(touchColor);
    }
  }

  void _rebuildLineLut(Color color) {
    final int baseAlpha = (color.a * 255.0).round().clamp(0, 255);
    for (int i = 0; i < 256; i++) {
      _lineColorLut[i] = color.withAlpha((i * baseAlpha) ~/ 255);
    }
    for (int b = 0; b < _numLineBuckets; b++) {
      final int alpha =
          ((b * baseAlpha) ~/ (_numLineBuckets - 1)).clamp(0, 255);
      _lineBucketPaints[b].color = color.withAlpha(alpha);
    }
  }

  void _updateAntiAlias(bool value) {
    particlePaint.isAntiAlias = value;
    linePaint.isAntiAlias = value;
    _batchedPointPaint.isAntiAlias = value;
    for (int b = 0; b < _numLineBuckets; b++) {
      _lineBucketPaints[b].isAntiAlias = value;
    }
  }

  /// Updates all performance settings at once using [NetworkPerformance].
  void updatePerformance(NetworkPerformance newPerformance) {
    if (newPerformance == performance) return;
    if (newPerformance.maxLinesPerFrame != performance.maxLinesPerFrame) {
      _budgetCorrection = 1.0;
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
      _budgetCorrection = 1.0;
    } else if (maxLinesPerFrame != null &&
        maxLinesPerFrame != this.maxLinesPerFrame) {
      this.maxLinesPerFrame = maxLinesPerFrame;
      _budgetCorrection = 1.0;
    }
    if (clearMaxConnectionsPerParticle) {
      this.maxConnectionsPerParticle = null;
    } else if (maxConnectionsPerParticle != null) {
      this.maxConnectionsPerParticle = maxConnectionsPerParticle;
    }
  }

  void updateLineWidth(double width) {
    if (width == lineWidth) return;
    lineWidth = width;
    linePaint.strokeWidth = width;
    for (int b = 0; b < _numLineBuckets; b++) {
      _lineBucketPaints[b].strokeWidth = width;
    }
  }

  void updateLineDistance(double distance) {
    if (distance == lineDistance) return;
    lineDistance = distance;
    _touchHandler.lineDistance = distance;
    final double maxDistSq = distance * distance;
    _invMaxDistSq = maxDistSq > 0 ? 1.0 / maxDistSq : 0.0;
  }

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
        oldDelegate.particles != particles ||
        oldDelegate.particleCount != particleCount ||
        oldDelegate.touchFeatures != touchFeatures ||
        oldDelegate.performance != performance;
  }

  @visibleForTesting
  void setCandidateBufferCapacityForTesting(int capacity) {
    _candidateIndices = Int32List(capacity);
    _candidateDistSq = Float64List(capacity);
  }

  @visibleForTesting
  void setUnifiedLineBufferCapacityForTesting(int capacity) {
    _unifiedLineBuffer = Float32List(capacity);
  }

  @visibleForTesting
  void drawConnectionsForTesting(
    Canvas canvas,
    List<int> visibleParticles, [
    double? effectiveDistance,
  ]) {
    _drawConnections(canvas, visibleParticles, effectiveDistance);
  }

  @visibleForTesting
  void drawIndividualConnectionsForTesting(
    Canvas canvas,
    List<int> visibleParticles, [
    double? effectiveDistance,
  ]) {
    _drawIndividualConnections(canvas, visibleParticles, effectiveDistance);
  }

  @visibleForTesting
  void drawBatchedConnectionsForTesting(
    Canvas canvas,
    List<int> visibleParticles, [
    double? effectiveDistance,
  ]) {
    _drawBatchedConnections(canvas, visibleParticles, effectiveDistance);
  }

  @visibleForTesting
  void collectSortedConnectionsForTesting(
    double maxDistSq,
    bool unified, [
    double? dist,
  ]) {
    _collectSortedConnections(maxDistSq, unified, dist);
  }
}
