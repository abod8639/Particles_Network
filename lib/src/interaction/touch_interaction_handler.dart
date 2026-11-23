import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:particles_network/src/core/particle.dart';
import 'package:particles_network/src/interaction/touch_features.dart';
import 'package:particles_network/src/rendering/line_vertex_batch.dart';
import 'package:particles_network/src/rendering/performance_utils.dart';
import 'package:particles_network/src/spatial/sorted_spatial_grid.dart';

export 'package:particles_network/src/interaction/touch_features.dart';

/// Class that handles touch interactions with particles
class TouchInteractionHandler {
  // List of all particles in the network
  final List<Particle> particles;

  // Current touch position (null when not touching)
  Offset? touchPoint;

  // Base maximum distance for touch interactions (fallback if not specified in touchFeatures)
  double lineDistance;

  /// Effective distance for touch interactions
  double get effectiveLineDistance =>
      touchFeatures.distance ?? lineDistance;

  /// Whether touch lines connecting the pointer and nearby particles are rendered.
  ///
  /// When `true`, lines are drawn between the touch pointer and nearby particles.
  /// When `false`, touch line rendering is bypassed while touch physics remain active.
  ///
  /// Defaults to `true` (controlled by [touchFeatures.show]).
  bool get show => touchFeatures.show;
  set show(bool value) {
    touchFeatures = touchFeatures.copyWith(show: value);
  }

  // Color to use for touch interactions
  Color get touchColor => _touchColor;
  Color _touchColor;
  set touchColor(Color newColor) {
    if (_touchColor != newColor) {
      rebuildTouchColorLut(newColor);
    }
  }

  // Paint object for drawing touch interaction lines
  final Paint linePaint;

  // Configuration for touch features and physics
  TouchFeatures touchFeatures;

  /// Spatial grid used for O(K) neighborhood lookups
  SortedSpatialGrid? spatialGrid;

  /// Line rendering backend (stroke or vertices)
  LineRenderer renderer;

  /// Whether to batch touch lines into a single draw call
  bool fastLineRendering;

  /// Number of touch lines drawn in the last call to [drawTouchLines]
  int get lastLineCount => _lastLineCount;
  int _lastLineCount = 0;

  // Reusable flat buffers for single draw-call line rendering (zero per-frame allocations)
  Float32List _lineCoordinates = Float32List(256);
  Int32List _lineColors = Int32List(64);
  final LineVertexBatch _touchVertexBatch = LineVertexBatch();
  final Paint _touchVertexPaint = Paint()..color = const Color(0xFFFFFFFF);

  // Constructor for the touch interaction handler
  TouchInteractionHandler({
    required this.particles,
    required this.touchPoint,
    required this.lineDistance,
    required Color touchColor,
    required this.linePaint,
    this.touchFeatures = const TouchFeatures(),
    this.spatialGrid,
    LineRenderer? renderer,
    bool? fastLineRendering,
  })  : _touchColor = touchColor,
        renderer = renderer ?? LineRenderer.vertices,
        fastLineRendering = fastLineRendering ?? true;

  // Test variable (kept for API compatibility)
  final int test = 0;
  final double force = 0.00111;
  // Precomputed color look-up table for touch lines (zero allocation)
  late List<Color> _touchColorLut = List<Color>.generate(
    256,
    (int a) => _touchColor.withAlpha(a),
    growable: false,
  );

  /// Rebuilds the touch color LUT with a new color — called by the painter
  /// to avoid full reconstruction when only the touch color changes.
  void rebuildTouchColorLut(Color newColor) {
    _touchColor = newColor;
    _touchColorLut = List<Color>.generate(
      256,
      (int a) => newColor.withAlpha(a),
      growable: false,
    );
  }

  void _ensureLineBufferCapacity(int lineCount) {
    final int requiredFloats = lineCount * 4;
    if (requiredFloats > _lineCoordinates.length) {
      final int newCap = math.max(requiredFloats, _lineCoordinates.length * 2);
      final Float32List newBuf = Float32List(newCap);
      newBuf.setRange(0, _lineCoordinates.length, _lineCoordinates);
      _lineCoordinates = newBuf;
    }
    if (lineCount > _lineColors.length) {
      final int newCap = math.max(lineCount, _lineColors.length * 2);
      final Int32List newBuf = Int32List(newCap);
      newBuf.setRange(0, _lineColors.length, _lineColors);
      _lineColors = newBuf;
    }
  }

  // Applies touch physics to visible particles
  // [visibleParticles] - List of indices of currently visible particles
  // [tracker] - Acceleration tracker to record accelerated particles
  // [grid] - Optional spatial grid override for O(K) neighborhood queries
  void applyTouchPhysics(
    List<int> visibleParticles,
    AccelerationTracker tracker, [
    SortedSpatialGrid? grid,
  ]) {
    applyTouchPhysicsScaled(visibleParticles, tracker, 1.0, grid);
  }

  /// Same as [applyTouchPhysics], but integrates over [timeScale] 60 Hz
  /// reference frames so the pull feels identical at any refresh rate.
  void applyTouchPhysicsScaled(
    List<int> visibleParticles,
    AccelerationTracker tracker,
    double timeScale, [
    SortedSpatialGrid? grid,
  ]) {
    final Offset? touch = touchPoint;
    if (touch == null || !touch.isFinite) {
      return; // Exit if no current or non-finite touch
    }
    if (visibleParticles.isEmpty) return;

    final double maxDist = effectiveLineDistance;
    if (!maxDist.isFinite || maxDist <= 0) return;

    final double tx = touch.dx;
    final double ty = touch.dy;
    final double maxDistSq = maxDist * maxDist;
    final double pullForce = touchFeatures.force;
    final double t = timeScale;
    final double touchDamping = t == 1.0
        ? touchFeatures.damping
        : math.pow(touchFeatures.damping, t).toDouble();
    final double frameForce = force * t;
    final double maxTouchSpeed = touchFeatures.maxSpeed;
    final double maxTouchSpeedSq = maxTouchSpeed * maxTouchSpeed;
    final double touchSpeed = touchFeatures.speed;
    final double dirSign = touchFeatures.type == TouchType.push ? -1.0 : 1.0;

    final SortedSpatialGrid? activeGrid = grid ?? spatialGrid;
    final bool useGrid = activeGrid != null &&
        activeGrid.isInitialized &&
        activeGrid.count == visibleParticles.length;

    if (useGrid) {
      activeGrid.queryRadius(tx, ty, maxDist, (idx, px, py, distSq) {
        if (idx < 0 || idx >= particles.length) return;
        final Particle p = particles[idx];
        final double dx = tx - p.x;
        final double dy = ty - p.y;
        final double actualDistSq = dx * dx + dy * dy;
        if (actualDistSq >= maxDistSq) return;

        p.vx += dx * frameForce * dirSign;
        p.vy += dy * frameForce * dirSign;

        final double dist = math.sqrt(actualDistSq);
        final double falloff = 1.0 - (dist / maxDist);
        final double invDist = dist > 0.001 ? 1.0 / dist : 0.0;
        final double nx = dx * invDist;
        final double ny = dy * invDist;

        final double pull = pullForce * falloff * t * dirSign;
        double vx = (p.vx + nx * pull) * touchDamping;
        double vy = (p.vy + ny * pull) * touchDamping;

        final double speedSq = vx * vx + vy * vy;
        if (speedSq > maxTouchSpeedSq) {
          final double scale = maxTouchSpeed / math.sqrt(speedSq);
          vx *= scale;
          vy *= scale;
        }

        p.vx = vx;
        p.vy = vy;
        p.decayRate = touchSpeed;
        p.wasAccelerated = true;
        tracker.recordAcceleration();
      });
    } else {
      // Safe fallback: direct O(N) loop over visibleParticles
      final int count = visibleParticles.length;
      for (int idx = 0; idx < count; idx++) {
        final int pIdx = visibleParticles[idx];
        if (pIdx < 0 || pIdx >= particles.length) continue;
        final Particle p = particles[pIdx];
        final double dx = tx - p.x;
        if (dx > maxDist || dx < -maxDist) continue;
        final double dy = ty - p.y;
        if (dy > maxDist || dy < -maxDist) continue;
        final double distSq = dx * dx + dy * dy;

        if (distSq < maxDistSq) {
          p.vx += dx * frameForce * dirSign;
          p.vy += dy * frameForce * dirSign;

          final double dist = math.sqrt(distSq);
          final double falloff = 1.0 - (dist / maxDist);
          final double invDist = dist > 0.001 ? 1.0 / dist : 0.0;
          final double nx = dx * invDist;
          final double ny = dy * invDist;

          final double pull = pullForce * falloff * t * dirSign;
          double vx = (p.vx + nx * pull) * touchDamping;
          double vy = (p.vy + ny * pull) * touchDamping;

          final double speedSq = vx * vx + vy * vy;
          if (speedSq > maxTouchSpeedSq) {
            final double scale = maxTouchSpeed / math.sqrt(speedSq);
            vx *= scale;
            vy *= scale;
          }

          p.vx = vx;
          p.vy = vy;
          p.decayRate = touchSpeed;
          p.wasAccelerated = true;
          tracker.recordAcceleration();
        }
      }
    }
  }

  // Draws lines between touch point and nearby particles
  // [canvas] - The canvas to draw on
  // [visibleParticles] - List of indices of currently visible particles
  // [grid] - Optional spatial grid for O(K) neighborhood queries
  // [fastLineRendering] - Optional override for single draw call batching
  // [lineRenderer] - Optional override for line rasterization backend
  // [show] - Optional override for displaying touch connection lines
  void drawTouchLines(
    Canvas canvas,
    List<int> visibleParticles, {
    SortedSpatialGrid? grid,
    bool? fastLineRendering,
    LineRenderer? renderer,
    bool? show,
  }) {
    final bool effectiveShow = show ?? this.show;
    if (!effectiveShow) {
      _lastLineCount = 0;
      return;
    }
    final Offset? touch = touchPoint;
    if (touch == null || !touch.isFinite) {
      _lastLineCount = 0;
      return;
    }
    if (visibleParticles.isEmpty) {
      _lastLineCount = 0;
      return;
    }

    final double maxDist = effectiveLineDistance;
    if (!maxDist.isFinite || maxDist <= 0) {
      _lastLineCount = 0;
      return;
    }

    final double tx = touch.dx;
    final double ty = touch.dy;
    final double maxDistSq = maxDist * maxDist;
    final double invMaxDist = 1.0 / maxDist;

    int lineCount = 0;
    int totalAlpha = 0;

    final SortedSpatialGrid? activeGrid = grid ?? spatialGrid;
    final bool useGrid = activeGrid != null &&
        activeGrid.isInitialized &&
        activeGrid.count == visibleParticles.length;

    if (useGrid) {
      activeGrid.queryRadius(tx, ty, maxDist, (idx, px, py, distSq) {
        if (idx < 0 || idx >= particles.length) return;
        final Particle p = particles[idx];
        final double dx = tx - p.x;
        final double dy = ty - p.y;
        final double actualDistSq = dx * dx + dy * dy;
        if (actualDistSq >= maxDistSq) return;

        final double distance = math.sqrt(actualDistSq);
        final double opacity = 1.0 - (distance * invMaxDist);
        final int alpha = (255 * opacity).toInt().clamp(0, 255);

        final int offset = lineCount * 4;
        if (offset + 4 > _lineCoordinates.length ||
            lineCount >= _lineColors.length) {
          _ensureLineBufferCapacity(lineCount + 32);
        }
        _lineCoordinates[offset] = p.x;
        _lineCoordinates[offset + 1] = p.y;
        _lineCoordinates[offset + 2] = tx;
        _lineCoordinates[offset + 3] = ty;
        _lineColors[lineCount] = _touchColorLut[alpha].toARGB32();
        lineCount++;
        totalAlpha += alpha;
      });
    } else {
      // Safe fallback: direct O(N) loop over visibleParticles
      final int count = visibleParticles.length;
      for (int idx = 0; idx < count; idx++) {
        final int pIdx = visibleParticles[idx];
        if (pIdx < 0 || pIdx >= particles.length) continue;
        final Particle p = particles[pIdx];
        final double dx = tx - p.x;
        if (dx > maxDist || dx < -maxDist) continue;
        final double dy = ty - p.y;
        if (dy > maxDist || dy < -maxDist) continue;
        final double distSq = dx * dx + dy * dy;

        if (distSq < maxDistSq) {
          final double distance = math.sqrt(distSq);
          final double opacity = 1.0 - (distance * invMaxDist);
          final int alpha = (255 * opacity).toInt().clamp(0, 255);

          final int offset = lineCount * 4;
          if (offset + 4 > _lineCoordinates.length ||
              lineCount >= _lineColors.length) {
            _ensureLineBufferCapacity(lineCount + 32);
          }
          _lineCoordinates[offset] = p.x;
          _lineCoordinates[offset + 1] = p.y;
          _lineCoordinates[offset + 2] = tx;
          _lineCoordinates[offset + 3] = ty;
          _lineColors[lineCount] = _touchColorLut[alpha].toARGB32();
          lineCount++;
          totalAlpha += alpha;
        }
      }
    }

    _lastLineCount = lineCount;
    if (lineCount == 0) return;

    final bool effectiveFast = fastLineRendering ?? this.fastLineRendering;

    if (!effectiveFast) {
      // Legacy individual line drawing mode (retains canvas.drawLine for compatibility with small counts)
      final Color previousColor = linePaint.color;
      try {
        for (int l = 0; l < lineCount; l++) {
          final int off = l * 4;
          linePaint.color = Color(_lineColors[l]);
          canvas.drawLine(
            Offset(_lineCoordinates[off], _lineCoordinates[off + 1]),
            touch,
            linePaint,
          );
        }
      } finally {
        linePaint.color = previousColor;
      }
      return;
    }

    // Single unified draw call
    final LineRenderer effectiveRenderer = renderer ?? this.renderer;

    if (effectiveRenderer == LineRenderer.vertices) {
      final double halfWidth = math.max(0.5, linePaint.strokeWidth * 0.5);
      _touchVertexBatch.clear();
      _touchVertexBatch.addSegments(
        _lineCoordinates,
        lineCount * 4,
        halfWidth,
        _lineColors,
      );
      _touchVertexPaint.isAntiAlias = linePaint.isAntiAlias;
      _touchVertexPaint.color = const Color(0xFFFFFFFF);
      _touchVertexBatch.draw(canvas, _touchVertexPaint);
    } else {
      final Color previousColor = linePaint.color;
      try {
        final int avgAlpha = (totalAlpha ~/ lineCount).clamp(0, 255);
        linePaint.color = _touchColorLut[avgAlpha];
        canvas.drawRawPoints(
          PointMode.lines,
          Float32List.sublistView(_lineCoordinates, 0, lineCount * 4),
          linePaint,
        );
      } finally {
        linePaint.color = previousColor;
      }
    }
  }
}
