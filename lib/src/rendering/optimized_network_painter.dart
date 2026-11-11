/// Specialized painter for rendering a high-performance particle network.
///
/// This library provides the [OptimizedNetworkPainter] and related utilities
/// to render particles and their connections using advanced optimization
/// techniques like spatial partitioning and object pooling.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:particles_network/src/core/particle.dart';
import 'package:particles_network/src/core/rectangle.dart';
import 'package:particles_network/src/interaction/touch_interaction_handler.dart';
import 'package:particles_network/src/rendering/line_vertex_batch.dart';
import 'package:particles_network/src/rendering/network_performance.dart';
import 'package:particles_network/src/rendering/object_pool.dart';
import 'package:particles_network/src/rendering/particle_filter.dart';
import 'package:particles_network/src/rendering/performance_utils.dart';
import 'package:particles_network/src/spatial/compressed_quad_tree.dart';
import 'package:particles_network/src/spatial/compressed_quad_tree_node.dart';
import 'package:particles_network/src/spatial/sorted_spatial_grid.dart';
import 'package:particles_network/src/spatial/spatial_grid.dart';

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
  bool touchActivation;

  /// The total number of particles, used for pre-allocation optimizations.
  final int particleCount;

  /// The width of the connecting lines.
  double lineWidth;

  /// Whether to use complex (high-quality) or optimized painting logic.
  bool isComplex;

  /// Whether to fill particles (true) or draw them as outlines (false).
  bool fill;

  /// Whether to draw the web of connection lines between particles.
  bool drawNetwork;

  /// Whether to visualize the underlying QuadTree structure for debugging.
  final bool showQuadTree;

  /// Advanced touch interaction features and physics configuration.
  TouchFeatures touchFeatures;

  /// Performance settings and optimizations for rendering.
  NetworkPerformance performance;

  /// Maximum number of connection lines a single particle can emit.
  ///
  /// Clamping connections guarantees strict O(N) rendering complexity, preventing
  /// explosive line counts and maintaining high FPS in dense particle clusters.
  int? get maxConnectionsPerParticle => performance.maxConnectionsPerParticle;
  set maxConnectionsPerParticle(int? value) {
    performance = performance.copyWith(
      maxConnectionsPerParticle: value,
      clearMaxConnectionsPerParticle: value == null,
    );
  }

  /// Whether to automatically scale down connection distance in dense networks.
  bool get adaptiveDensity => performance.adaptiveDensity;
  set adaptiveDensity(bool value) {
    performance = performance.copyWith(adaptiveDensity: value);
  }

  /// Whether to use ultra-fast single draw-call line rendering.
  bool get fastLineRendering => performance.fastLineRendering;
  set fastLineRendering(bool value) {
    performance = performance.copyWith(fastLineRendering: value);
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
  late final CompressedQuadTree _quadTree;
  late final SpatialGrid _spatialGrid;
  final SortedSpatialGrid _sortedGrid = SortedSpatialGrid();

  // Reusable painting objects (initialized once for performance)
  late final Paint particlePaint;
  late final Paint linePaint;

  // Performance optimization components
  late final AccelerationTracker _accelerationTracker;
  late final AdaptiveQuadTreeManager _quadTreeManager;
  late final PoolManager _poolManager;
  late final IntListPool _intListPool;

  // Reusable internal buffers to avoid per-frame GC allocations
  final List<int> _visibleParticles = [];
  Int32List _candidateIndices = Int32List(128);
  Float64List _candidateDistSq = Float64List(128);
  static const int _maxParticleSizeBuckets = 64;
  late final List<Float32List> _particleRawBuckets;
  final Int32List _particleRawOffsets = Int32List(_maxParticleSizeBuckets);
  final Paint _batchedPointPaint = Paint()..strokeCap = StrokeCap.round;

  // Number of alpha buckets for GPU line draw call batching
  static const int _numLineBuckets = 32;
  late final List<Float32List> _rawBuckets;
  late final Int32List _rawOffsets;
  late final List<Paint> _lineBucketPaints;
  late final Int32List _distBucketTable;
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
    bool? touchActivation,
    required this.lineWidth,
    required this.isComplex,
    required this.fill,
    required this.drawNetwork,
    this.touchFeatures = const TouchFeatures(),
    NetworkPerformance performance = const NetworkPerformance(),
    this.showQuadTree = false,
    int? maxConnectionsPerParticle,
    bool? adaptiveDensity,
    bool? fastLineRendering,
    int? maxLinesPerFrame,
    this.simulateTouchInPaint = true,
    LineRenderer? lineRenderer,
    this.devicePixelRatio = 1.0,
    super.repaint,
  })  : touchColor = touchColor ?? touchFeatures.color,
        touchActivation = touchActivation ?? touchFeatures.enabled,
        performance = performance.copyWith(
          maxConnectionsPerParticle: maxConnectionsPerParticle,
          adaptiveDensity: adaptiveDensity,
          fastLineRendering: fastLineRendering,
          maxLinesPerFrame: maxLinesPerFrame,
          lineRenderer: lineRenderer,
        ) {
    final int baseAlpha = (lineColor.a * 255.0).round().clamp(0, 255);
    _lineColorLut = List<Color>.generate(
      256,
      (int alpha) => lineColor.withAlpha((alpha * baseAlpha) ~/ 255),
      growable: false,
    );

    _quadTree = CompressedQuadTree(
      const Rectangle(-5, -5, 1000, 1000),
    );

    _spatialGrid = SpatialGrid(
      cellSize: lineDistance > 0 ? lineDistance : 100.0,
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
        ..isAntiAlias = !isComplex;
    });

    final double maxDistSq = lineDistance * lineDistance;
    _invMaxDistSq = maxDistSq > 0 ? 1.0 / maxDistSq : 0.0;
    _distBucketTable = Int32List(1025);
    for (int i = 0; i <= 1024; i++) {
      final double ratio = math.sqrt(i / 1024.0);
      _distBucketTable[i] = ((1.0 - ratio) * (_numLineBuckets - 1))
          .round()
          .clamp(0, _numLineBuckets - 1);
    }

    particlePaint = Paint()
      ..style = fill ? PaintingStyle.fill : PaintingStyle.stroke
      ..isAntiAlias = !isComplex
      ..color = particleColor;

    linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth
      ..isAntiAlias = !isComplex
      ..color = lineColor;

    _accelerationTracker = AccelerationTracker();
    _quadTreeManager = AdaptiveQuadTreeManager(
      rebuildInterval: isComplex ? 6 : 3,
    );
    _poolManager = PoolManager.getInstance();
    _intListPool = _poolManager.intListPool;

    _touchHandler = TouchInteractionHandler(
      particles: particles,
      touchPoint: touchPoint,
      lineDistance: lineDistance,
      touchColor: this.touchColor,
      linePaint: linePaint,
      touchFeatures: touchFeatures,
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
    _touchHandler.applyTouchPhysicsScaled(
      _visibleParticles,
      _accelerationTracker,
      timeScale,
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
    _accelerationTracker.resetFrame();

    if (size.width > 0 && size.height > 0) {
      if (showQuadTree) {
        _quadTree.updateBoundary(
          Rectangle(-5, -5, size.width + 10, size.height + 10),
        );
      }
    }

    ParticleFilter.getVisibleParticlesTo(particles, _visibleParticles);
    final List<int> visibleParticles = _visibleParticles;

    if (drawNetwork) {
      double? effectiveDistance;
      if (adaptiveDensity &&
          size.width > 0 &&
          size.height > 0 &&
          visibleParticles.isNotEmpty) {
        final double screenArea = size.width * size.height;
        final double areaPerParticle = screenArea / visibleParticles.length;
        // 5333 px^2 corresponds to ~60 particles on a 400x800 screen.
        final double factor =
            math.sqrt(areaPerParticle / 5333.0).clamp(0.25, 1.0);
        effectiveDistance = lineDistance * factor;
      }

      final double baseDistance = effectiveDistance ?? lineDistance;
      final double distance = _budgetedDistance(
        baseDistance,
        size,
        visibleParticles.length,
      );
      if (distance != baseDistance) effectiveDistance = distance;
      _lastFrameLineDistance = distance;

      // Fade lines relative to the budgeted radius; otherwise relative to
      // lineDistance as before.
      final double alphaDistance =
          maxLinesPerFrame != null ? distance : lineDistance;
      final double alphaDistSq = alphaDistance * alphaDistance;
      _invMaxDistSq = alphaDistSq > 0 ? 1.0 / alphaDistSq : 0.0;

      // The batched and unified paths scan a cell-sorted SoA grid; the
      // isComplex and small-network paths query the linked-list grid.
      if (fastLineRendering || (!isComplex && visibleParticles.length >= 30)) {
        _sortedGrid.build(
          particles,
          visibleParticles,
          size.width,
          size.height,
          distance > 0 ? distance : 100.0,
        );
      } else {
        _spatialGrid.updateCellSize(
          distance > 0 ? distance : 100.0,
        );
        _spatialGrid.build(
          particles,
          visibleParticles,
          size.width,
          size.height,
        );
      }

      if (showQuadTree && _quadTreeManager.shouldRebuild()) {
        _quadTree.clear();
        for (int i = 0; i < visibleParticles.length; i++) {
          final Particle particle = particles[visibleParticles[i]];
          _quadTree.insert(
            QuadTreeParticle(
              visibleParticles[i],
              particle.x,
              particle.y,
            ),
          );
        }
      }

      _drawConnections(canvas, visibleParticles, effectiveDistance);
      _updateBudgetCorrection(distance, baseDistance);
    } else {
      _lastFrameLineCount = 0;
    }

    if (_isTouchActive) {
      _touchHandler.drawTouchLines(canvas, visibleParticles);
      if (simulateTouchInPaint) {
        _touchHandler.applyTouchPhysics(
          visibleParticles,
          _accelerationTracker,
        );
      }
      _quadTreeManager.forceRebuild();
    }

    _drawParticles(canvas, visibleParticles);
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
      ..isAntiAlias = !isComplex
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

  void _drawFastUnifiedConnections(Canvas canvas, double effectiveDistance) {
    _unifiedLineCount = 0;
    _collectSortedConnections(effectiveDistance * effectiveDistance, true);

    _lastFrameLineCount = _unifiedLineCount ~/ 4;
    if (_unifiedLineCount > 0 && lineRenderer == LineRenderer.vertices) {
      final double width = _vertexLineWidth();
      _vertexPaint.color =
          Color(_scaledArgb(lineColor, lineWidth / width));
      _lineVertexBatch
        ..clear()
        ..addSegments(_unifiedLineBuffer, _unifiedLineCount, width * 0.5)
        ..draw(canvas, _vertexPaint);
    } else if (_unifiedLineCount > 0) {
      linePaint.color = lineColor;
      canvas.drawRawPoints(
        PointMode.lines,
        Float32List.sublistView(_unifiedLineBuffer, 0, _unifiedLineCount),
        linePaint,
      );
    }
  }

  void _drawConnections(
    Canvas canvas,
    List<int> visibleParticles, [
    double? effectiveDistance,
  ]) {
    final double dist = effectiveDistance ?? lineDistance;
    if (fastLineRendering) {
      _drawFastUnifiedConnections(canvas, dist);
    } else if (visibleParticles.length < 30) {
      _drawIndividualConnections(canvas, visibleParticles, effectiveDistance);
    } else {
      _drawBatchedConnections(canvas, visibleParticles, effectiveDistance);
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
    final int defaultMaxLines = isComplex ? 3 : 5;
    final int denseThreshold = isComplex ? (dist ~/ 4) : (dist ~/ 1.5);

    final int? maxConn = maxConnectionsPerParticle;
    final bool capped = maxConn != null;
    final int cap = maxConn ?? 0;
    final Int32List? counts =
        capped ? _getClearedConnectionCounts(particles.length) : null;

    final List<int> nearbyIndices = _intListPool.acquire();
    int lineCount = 0;
    final Color previousColor = linePaint.color;

    try {
      final int count = visibleParticles.length;
      for (int i = 0; i < count; i++) {
        final int index = visibleParticles[i];
        if (capped && counts![index] >= cap) continue;

        final Particle particle = particles[index];
        final double px = particle.x;
        final double py = particle.y;

        nearbyIndices.clear();
        _spatialGrid.findNearbyParticlesToOutput(
          px,
          py,
          dist,
          nearbyIndices,
        );

        int candidateCount = 0;
        final int nearbyCount = nearbyIndices.length;
        for (int n = 0; n < nearbyCount; n++) {
          final int neighborIndex = nearbyIndices[n];
          if (neighborIndex <= index) continue;
          if (capped && counts![neighborIndex] >= cap) continue;

          final Particle neighbor = particles[neighborIndex];
          final double dx = px - neighbor.x;
          final double dy = py - neighbor.y;
          final double distSq = dx * dx + dy * dy;

          if (distSq <= maxDistSq) {
            if (candidateCount >= _candidateIndices.length) {
              _growCandidateBuffers();
            }
            _candidateIndices[candidateCount] = neighborIndex;
            _candidateDistSq[candidateCount] = distSq;
            candidateCount++;
          }
        }

        if (candidateCount > 0) {
          int drawCount = candidateCount;
          bool isThrottled = false;

          if (capped) {
            final int allowed = cap - counts![index];
            if (candidateCount > allowed) {
              _selectTopKClosest(candidateCount, allowed);
              drawCount = allowed;
              isThrottled = true;
            }
          } else {
            isThrottled = candidateCount > denseThreshold;
            if (isThrottled) {
              _selectTopKClosest(candidateCount, defaultMaxLines);
              drawCount = defaultMaxLines < candidateCount
                  ? defaultMaxLines
                  : candidateCount;
            }
          }

          final Offset pos = Offset(px, py);
          for (int c = 0; c < drawCount; c++) {
            final int neighborIdx = _candidateIndices[c];
            final Particle neighbor = particles[neighborIdx];
            final double distance = math.sqrt(_candidateDistSq[c]);
            int alpha =
                (255 - (distance * invLineDistance)).toInt().clamp(0, 255);
            if (isThrottled && drawCount > 1) {
              final double rankFade =
                  ((drawCount - c) / drawCount).clamp(0.0, 1.0);
              alpha = (alpha * rankFade).toInt().clamp(0, 255);
            }
            linePaint.color = _lineColorLut[alpha];
            canvas.drawLine(pos, Offset(neighbor.x, neighbor.y), linePaint);

            if (capped) {
              counts![index]++;
              counts[neighborIdx]++;
            }
          }
          lineCount += drawCount;
        }
      }
    } finally {
      linePaint.color = previousColor;
      _intListPool.release(nearbyIndices);
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
      _drawBatchedConnectionsComplex(visibleParticles, maxDistSq);
    } else {
      _drawBatchedConnectionsFast(maxDistSq);
    }

    if (lineRenderer == LineRenderer.vertices) {
      _drawBucketsAsVertices(canvas);
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

    int lineCount = 0;
    for (int b = 0; b < _numLineBuckets; b++) {
      final int rawCount = _rawOffsets[b];
      if (rawCount == 0) continue;
      lineCount += rawCount ~/ 4;
      final int argb = _scaledArgb(_lineBucketPaints[b].color, alphaScale);
      // Fully transparent buckets add GPU work without visible output.
      if ((argb >>> 24) == 0) continue;
      _vertexPaint.color = Color(argb);
      batch
        ..clear()
        ..addSegments(_rawBuckets[b], rawCount, halfWidth)
        ..draw(canvas, _vertexPaint);
    }
    _lastFrameLineCount = lineCount;
  }

  void _drawBatchedConnectionsFast(double maxDistSq) {
    _collectSortedConnections(maxDistSq, false);
  }

  /// Finds every pair of visible particles closer than `sqrt(maxDistSq)`
  /// using [_sortedGrid], appending each to the alpha buckets or, when
  /// [unified], to the single-colour unified buffer.
  ///
  /// Cells are row-major and counting-sorted, so for a particle `i` in cell
  /// `c` the candidates form just two contiguous ranges:
  /// * the rest of its own cell plus the east cell (`c`, `c + 1` are
  ///   adjacent in memory), and
  /// * the south-west, south and south-east cells (`c + cols - 1` to
  ///   `c + cols + 1`, also adjacent).
  /// Together with the cells that scan *into* `c`, this visits each pair of
  /// neighbouring cells exactly once.
  void _collectSortedConnections(double maxDistSq, bool unified) {
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

          pairs:
          {
            for (int j = i + 1; j < nearEnd; j++) {
              if (capped && counts[j] >= cap) continue;
              final double dx = x1 - xs[j];
              final double dy = y1 - ys[j];
              final double distSq = dx * dx + dy * dy;
              if (distSq <= maxDistSq) {
                _emitConnection(unified, x1, y1, xs[j], ys[j], distSq);
                if (capped) {
                  counts[j]++;
                  if (++counts[i] >= cap) break pairs;
                }
              }
            }
            for (int j = southStart; j < southEnd; j++) {
              if (capped && counts[j] >= cap) continue;
              final double dx = x1 - xs[j];
              final double dy = y1 - ys[j];
              final double distSq = dx * dx + dy * dy;
              if (distSq <= maxDistSq) {
                _emitConnection(unified, x1, y1, xs[j], ys[j], distSq);
                if (capped) {
                  counts[j]++;
                  if (++counts[i] >= cap) break pairs;
                }
              }
            }
          }
        }
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
    double distSq,
  ) {
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
    final int bucket = _distBucketTable[tableIdx];
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
    double maxDistSq,
  ) {
    final double queryRadius = math.sqrt(maxDistSq);
    final List<int> nearbyIndices = _intListPool.acquire();

    final int? maxConn = maxConnectionsPerParticle;
    final bool capped = maxConn != null;
    final int cap = maxConn ?? 0;
    final Int32List? counts =
        capped ? _getClearedConnectionCounts(particles.length) : null;

    try {
      final int count = visibleParticles.length;
      final int denseThreshold = lineDistance ~/ 3;

      for (int i = 0; i < count; i++) {
        final int index = visibleParticles[i];
        if (capped && counts![index] >= cap) continue;

        final Particle particle = particles[index];
        final double px = particle.x;
        final double py = particle.y;

        nearbyIndices.clear();
        _spatialGrid.findNearbyParticlesToOutput(
          px,
          py,
          queryRadius,
          nearbyIndices,
        );

        final int nearbyCount = nearbyIndices.length;
        int candidateCount = 0;
        for (int n = 0; n < nearbyCount; n++) {
          final int neighborIndex = nearbyIndices[n];
          if (neighborIndex <= index) continue;
          if (capped && counts![neighborIndex] >= cap) continue;

          final Particle neighbor = particles[neighborIndex];
          final double dx = px - neighbor.x;
          final double dy = py - neighbor.y;
          final double distSq = dx * dx + dy * dy;

          if (distSq <= maxDistSq) {
            if (candidateCount >= _candidateIndices.length) {
              _growCandidateBuffers();
            }
            _candidateIndices[candidateCount] = neighborIndex;
            _candidateDistSq[candidateCount] = distSq;
            candidateCount++;
          }
        }

        if (candidateCount > 0) {
          int drawCount = candidateCount;
          bool isThrottled = false;

          if (capped) {
            final int allowed = cap - counts![index];
            if (candidateCount > allowed) {
              _selectTopKClosest(candidateCount, allowed);
              drawCount = allowed;
              isThrottled = true;
            }
          } else {
            isThrottled = candidateCount > denseThreshold;
            if (isThrottled) {
              const int maxLines = 5;
              _selectTopKClosest(candidateCount, maxLines);
              drawCount = maxLines < candidateCount ? maxLines : candidateCount;
            }
          }

          for (int c = 0; c < drawCount; c++) {
            final int neighborIdx = _candidateIndices[c];
            final Particle neighbor = particles[neighborIdx];
            final double distSq = _candidateDistSq[c];
            final int tableIdx =
                ((distSq * _invMaxDistSq) * 1024).toInt().clamp(0, 1024);
            int bucket = _distBucketTable[tableIdx];

            if (isThrottled && drawCount > 1) {
              final double rankFade =
                  ((drawCount - c) / drawCount).clamp(0.0, 1.0);
              bucket =
                  (bucket * rankFade).round().clamp(0, _numLineBuckets - 1);
            }

            final int off = _rawOffsets[bucket];
            Float32List raw = _rawBuckets[bucket];
            if (off + 4 > raw.length) {
              raw = _growBucket(bucket, off + 4);
            }
            raw[off] = px;
            raw[off + 1] = py;
            raw[off + 2] = neighbor.x;
            raw[off + 3] = neighbor.y;
            _rawOffsets[bucket] = off + 4;

            if (capped) {
              counts![index]++;
              counts[neighborIdx]++;
            }
          }
        }
      }
    } finally {
      _intListPool.release(nearbyIndices);
    }
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

  /// Updates all performance settings at once using [NetworkPerformance].
  void updatePerformance(NetworkPerformance newPerformance) {
    if (newPerformance == performance) return;
    if (newPerformance.maxLinesPerFrame != performance.maxLinesPerFrame) {
      _budgetCorrection = 1.0;
    }
    performance = newPerformance;
  }

  /// Updates performance and rendering strategy options.
  void updatePerformanceOptions({
    int? maxConnectionsPerParticle,
    bool clearMaxConnectionsPerParticle = false,
    bool? adaptiveDensity,
    bool? fastLineRendering,
    int? maxLinesPerFrame,
    bool clearMaxLinesPerFrame = false,
    LineRenderer? lineRenderer,
  }) {
    if (lineRenderer != null) this.lineRenderer = lineRenderer;
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
    if (adaptiveDensity != null) {
      this.adaptiveDensity = adaptiveDensity;
    }
    if (fastLineRendering != null) {
      this.fastLineRendering = fastLineRendering;
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
    _spatialGrid.updateCellSize(distance > 0 ? distance : 100.0);
    final double maxDistSq = distance * distance;
    _invMaxDistSq = maxDistSq > 0 ? 1.0 / maxDistSq : 0.0;
    for (int i = 0; i <= 1024; i++) {
      final double ratio = math.sqrt(i / 1024.0);
      _distBucketTable[i] = ((1.0 - ratio) * (_numLineBuckets - 1))
          .round()
          .clamp(0, _numLineBuckets - 1);
    }
  }

  void updateRenderFlags({
    bool? drawNetwork,
    bool? fill,
    bool? isComplex,
    bool? touchActivation,
  }) {
    if (drawNetwork != null) this.drawNetwork = drawNetwork;
    if (touchActivation != null) this.touchActivation = touchActivation;
    if (fill != null && fill != this.fill) {
      this.fill = fill;
      particlePaint.style = fill ? PaintingStyle.fill : PaintingStyle.stroke;
    }
    if (isComplex != null && isComplex != this.isComplex) {
      this.isComplex = isComplex;
      particlePaint.isAntiAlias = !isComplex;
      linePaint.isAntiAlias = !isComplex;
      for (int b = 0; b < _numLineBuckets; b++) {
        _lineBucketPaints[b].isAntiAlias = !isComplex;
      }
      _quadTreeManager.rebuildInterval = isComplex ? 6 : 3;
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
}
