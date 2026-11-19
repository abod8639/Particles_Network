import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:particles_network/src/core/particle.dart';

import 'rendering_constants.dart';

/// Batched particle renderer for high-performance point and circle drawing.
///
/// Automatically batches particles by size into separate raw point buffers,
/// collapsing hundreds or thousands of individual canvas draw calls into a
/// handful of bucketed GPU drawRawPoints calls.
class ParticleBatchRenderer {
  static const int maxParticleSizeBuckets = kMaxParticleSizeBuckets;

  final List<Float32List> _particleRawBuckets;
  final Int32List _particleRawOffsets = Int32List(maxParticleSizeBuckets);
  final Paint _batchedPointPaint = Paint()..strokeCap = StrokeCap.round;

  ParticleBatchRenderer()
      : _particleRawBuckets = List.generate(
          maxParticleSizeBuckets,
          (_) => Float32List(256),
          growable: false,
        );

  /// Draws the [visibleParticles] onto [canvas] using either batched points or circles.
  void draw({
    required Canvas canvas,
    required List<Particle> particles,
    required List<int> visibleParticles,
    required Paint particlePaint,
    required bool fill,
    required bool antiAlias,
    required Color particleColor,
  }) {
    final int count = visibleParticles.length;
    if (count == 0) return;

    if (!fill || count < kMinParticleBatchThreshold) {
      for (int i = 0; i < count; i++) {
        final Particle p = particles[visibleParticles[i]];
        canvas.drawCircle(Offset(p.x, p.y), p.size, particlePaint);
      }
      return;
    }

    _drawBatchedParticles(
      canvas: canvas,
      particles: particles,
      visibleParticles: visibleParticles,
      antiAlias: antiAlias,
      particleColor: particleColor,
    );
  }

  void _drawBatchedParticles({
    required Canvas canvas,
    required List<Particle> particles,
    required List<int> visibleParticles,
    required bool antiAlias,
    required Color particleColor,
  }) {
    _particleRawOffsets.fillRange(0, maxParticleSizeBuckets, 0);
    final int count = visibleParticles.length;

    for (int i = 0; i < count; i++) {
      final Particle p = particles[visibleParticles[i]];
      int bucket = (p.size * 2).round();
      if (bucket < 1) bucket = 1;
      if (bucket >= maxParticleSizeBuckets) {
        bucket = maxParticleSizeBuckets - 1;
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
      ..isAntiAlias = antiAlias
      ..color = particleColor;

    for (int b = 1; b < maxParticleSizeBuckets; b++) {
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
}
