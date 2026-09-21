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
import 'package:particles_network/src/rendering/object_pool.dart';
import 'package:particles_network/src/rendering/particle_filter.dart';
import 'package:particles_network/src/rendering/performance_utils.dart';
import 'package:particles_network/src/spatial/compressed_quad_tree.dart';
import 'package:particles_network/src/spatial/compressed_quad_tree_node.dart';
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

  // Optimized sub-components
  late final TouchInteractionHandler _touchHandler;
  late final CompressedQuadTree _quadTree;
  late final SpatialGrid _spatialGrid;

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

  /// Constructor with dependency initialization
  OptimizedNetworkPainter({
    required this.particleCount,
    required this.particles,
    required this.touchPoint,
    required this.lineDistance,
    required this.particleColor,
    required this.lineColor,
    required this.touchColor,
    required this.touchActivation,
    required this.lineWidth,
    required this.isComplex,
    required this.fill,
    required this.drawNetwork,
    this.touchFeatures = const TouchFeatures(),
    this.showQuadTree = false,
    super.repaint,
  }) {
    final int baseAlpha = lineColor.alpha;
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
      _distBucketTable[i] =
          ((1.0 - ratio) * (_numLineBuckets - 1)).round().clamp(0, _numLineBuckets - 1);
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
      touchColor: touchColor,
      linePaint: linePaint,
      touchFeatures: touchFeatures,
    );
  }

  /// Updates touch point without recreating the painter instance
  void updateTouchPoint(Offset? newPoint) {
    touchPoint = newPoint;
    _touchHandler.touchPoint = newPoint;
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
      _spatialGrid.updateCellSize(lineDistance > 0 ? lineDistance : 100.0);
      _spatialGrid.build(particles, visibleParticles, size.width, size.height);

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

      _drawConnections(canvas, visibleParticles);
    }

    final bool isTouchActive = touchActivation &&
        touchPoint != null &&
        touchPoint!.isFinite &&
        touchPoint != Offset.infinite;

    if (isTouchActive) {
      _touchHandler.drawTouchLines(canvas, visibleParticles);
      _touchHandler.applyTouchPhysics(visibleParticles, _accelerationTracker);
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

  void _drawConnections(Canvas canvas, List<int> visibleParticles) {
    if (visibleParticles.length < 30) {
      _drawIndividualConnections(canvas, visibleParticles);
    } else {
      _drawBatchedConnections(canvas, visibleParticles);
    }
  }

  void _drawIndividualConnections(
    Canvas canvas,
    List<int> visibleParticles,
  ) {
    final double maxDistSq = lineDistance * lineDistance;
    final double invLineDistance =
        lineDistance > 0 ? 255.0 / lineDistance : 0.0;
    final int maxLines = isComplex ? 3 : 5;
    final int denseThreshold =
        isComplex ? (lineDistance ~/ 4) : (lineDistance ~/ 1.5);

    final List<int> nearbyIndices = _intListPool.acquire();

    try {
      final int count = visibleParticles.length;
      for (int i = 0; i < count; i++) {
        final int index = visibleParticles[i];
        final Particle particle = particles[index];
        final double px = particle.x;
        final double py = particle.y;

        nearbyIndices.clear();
        _spatialGrid.findNearbyParticlesToOutput(
          px,
          py,
          lineDistance,
          nearbyIndices,
        );

        int candidateCount = 0;
        final int nearbyCount = nearbyIndices.length;
        for (int n = 0; n < nearbyCount; n++) {
          final int neighborIndex = nearbyIndices[n];
          if (neighborIndex <= index) continue;

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
          if (candidateCount > denseThreshold) {
            _selectTopKClosest(candidateCount, maxLines);
            drawCount = maxLines < candidateCount ? maxLines : candidateCount;
          }

          final Offset pos = Offset(px, py);
          for (int c = 0; c < drawCount; c++) {
            final int neighborIdx = _candidateIndices[c];
            final Particle neighbor = particles[neighborIdx];
            final double distance = math.sqrt(_candidateDistSq[c]);
            final int alpha =
                (255 - (distance * invLineDistance)).toInt().clamp(0, 255);
            linePaint.color = _lineColorLut[alpha];
            canvas.drawLine(pos, Offset(neighbor.x, neighbor.y), linePaint);
          }
        }
      }
    } finally {
      _intListPool.release(nearbyIndices);
    }
  }

  void _drawBatchedConnections(
    Canvas canvas,
    List<int> visibleParticles,
  ) {
    final double maxDistSq = lineDistance * lineDistance;
    _rawOffsets.fillRange(0, _numLineBuckets, 0);

    if (isComplex) {
      _drawBatchedConnectionsComplex(visibleParticles, maxDistSq);
    } else {
      _drawBatchedConnectionsFast(maxDistSq);
    }

    for (int b = 0; b < _numLineBuckets; b++) {
      final int rawCount = _rawOffsets[b];
      if (rawCount > 0) {
        canvas.drawRawPoints(
          PointMode.lines,
          Float32List.sublistView(_rawBuckets[b], 0, rawCount),
          _lineBucketPaints[b],
        );
      }
    }
  }

  void _drawBatchedConnectionsFast(double maxDistSq) {
    final int cols = _spatialGrid.cols;
    final int rows = _spatialGrid.rows;
    if (cols <= 0 || rows <= 0) return;

    final Int32List cellHeads = _spatialGrid.cellHeads;
    final Int32List particleNext = _spatialGrid.particleNext;
    final Int32List activeCells = _spatialGrid.activeCells;
    final int activeCount = _spatialGrid.activeCellsCount;

    for (int a = 0; a < activeCount; a++) {
      final int cell = activeCells[a];
      final int p1Head = cellHeads[cell];
      if (p1Head == -1) continue;

      final int cx = cell % cols;
      final int cy = cell ~/ cols;

      final int east = (cx < cols - 1) ? cell + 1 : -1;
      final int southWest =
          (cy < rows - 1 && cx > 0) ? cell + cols - 1 : -1;
      final int south = (cy < rows - 1) ? cell + cols : -1;
      final int southEast =
          (cy < rows - 1 && cx < cols - 1) ? cell + cols + 1 : -1;

      int p1 = p1Head;
      while (p1 != -1) {
        final Particle particle1 = particles[p1];
        final double p1x = particle1.x;
        final double p1y = particle1.y;

        int p2 = particleNext[p1];
        while (p2 != -1) {
          final Particle particle2 = particles[p2];
          final double dx = p1x - particle2.x;
          final double dy = p1y - particle2.y;
          final double distSq = dx * dx + dy * dy;

          if (distSq <= maxDistSq) {
            int tableIdx = ((distSq * _invMaxDistSq) * 1024).toInt();
            if (tableIdx > 1024) tableIdx = 1024;
            final int bucket = _distBucketTable[tableIdx];

            final int off = _rawOffsets[bucket];
            Float32List raw = _rawBuckets[bucket];
            if (off + 4 > raw.length) {
              raw = _growBucket(bucket, off + 4);
            }
            raw[off] = p1x;
            raw[off + 1] = p1y;
            raw[off + 2] = particle2.x;
            raw[off + 3] = particle2.y;
            _rawOffsets[bucket] = off + 4;
          }
          p2 = particleNext[p2];
        }

        if (east != -1) {
          _connectWithCell(p1x, p1y, east, maxDistSq, cellHeads, particleNext);
        }
        if (southWest != -1) {
          _connectWithCell(
              p1x, p1y, southWest, maxDistSq, cellHeads, particleNext);
        }
        if (south != -1) {
          _connectWithCell(
              p1x, p1y, south, maxDistSq, cellHeads, particleNext);
        }
        if (southEast != -1) {
          _connectWithCell(
              p1x, p1y, southEast, maxDistSq, cellHeads, particleNext);
        }

        p1 = particleNext[p1];
      }
    }
  }

  void _connectWithCell(
    double p1x,
    double p1y,
    int neighborCell,
    double maxDistSq,
    Int32List cellHeads,
    Int32List particleNext,
  ) {
    int p2 = cellHeads[neighborCell];
    while (p2 != -1) {
      final Particle particle2 = particles[p2];
      final double dx = p1x - particle2.x;
      final double dy = p1y - particle2.y;
      final double distSq = dx * dx + dy * dy;

      if (distSq <= maxDistSq) {
        int tableIdx = ((distSq * _invMaxDistSq) * 1024).toInt();
        if (tableIdx > 1024) tableIdx = 1024;
        final int bucket = _distBucketTable[tableIdx];

        final int off = _rawOffsets[bucket];
        Float32List raw = _rawBuckets[bucket];
        if (off + 4 > raw.length) {
          raw = _growBucket(bucket, off + 4);
        }
        raw[off] = p1x;
        raw[off + 1] = p1y;
        raw[off + 2] = particle2.x;
        raw[off + 3] = particle2.y;
        _rawOffsets[bucket] = off + 4;
      }
      p2 = particleNext[p2];
    }
  }

  void _drawBatchedConnectionsComplex(
    List<int> visibleParticles,
    double maxDistSq,
  ) {
    final List<int> nearbyIndices = _intListPool.acquire();

    try {
      final int count = visibleParticles.length;
      final int maxLines = 3;
      final int denseThreshold = lineDistance ~/ 4;

      for (int i = 0; i < count; i++) {
        final int index = visibleParticles[i];
        final Particle particle = particles[index];
        final double px = particle.x;
        final double py = particle.y;

        nearbyIndices.clear();
        _spatialGrid.findNearbyParticlesToOutput(
          px,
          py,
          lineDistance,
          nearbyIndices,
        );

        final int nearbyCount = nearbyIndices.length;
        int candidateCount = 0;
        for (int n = 0; n < nearbyCount; n++) {
          final int neighborIndex = nearbyIndices[n];
          if (neighborIndex <= index) continue;

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
          if (candidateCount > denseThreshold) {
            _selectTopKClosest(candidateCount, maxLines);
            drawCount = maxLines < candidateCount ? maxLines : candidateCount;
          }

          for (int c = 0; c < drawCount; c++) {
            final int neighborIdx = _candidateIndices[c];
            final Particle neighbor = particles[neighborIdx];
            final double distSq = _candidateDistSq[c];
            final int tableIdx =
                ((distSq * _invMaxDistSq) * 1024).toInt().clamp(0, 1024);
            final int bucket = _distBucketTable[tableIdx];

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
    final int baseAlpha = color.alpha;
    for (int i = 0; i < 256; i++) {
      _lineColorLut[i] = color.withAlpha((i * baseAlpha) ~/ 255);
    }
    for (int b = 0; b < _numLineBuckets; b++) {
      final int alpha =
          ((b * baseAlpha) ~/ (_numLineBuckets - 1)).clamp(0, 255);
      _lineBucketPaints[b].color = color.withAlpha(alpha);
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
      _distBucketTable[i] =
          ((1.0 - ratio) * (_numLineBuckets - 1)).round().clamp(0, _numLineBuckets - 1);
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
  }

  @override
  bool shouldRepaint(OptimizedNetworkPainter oldDelegate) {
    return oldDelegate.touchPoint != touchPoint ||
        _accelerationTracker.hadAcceleratedParticles ||
        oldDelegate.lineDistance != lineDistance ||
        oldDelegate.particleColor != particleColor ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.touchFeatures != touchFeatures;
  }
}
