import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'line_style_palette.dart';
import 'line_vertex_batch.dart';
import 'rendering_constants.dart';

/// Pre-allocated opacity-bucketed line segment buffers.
///
/// Both stroke and triangle quad (vertices) renderers consume these identical
/// buckets, ensuring zero per-pair interface dispatch and zero allocations per frame.
class LineBuckets {
  static const int numBuckets = LineStylePalette.numLineBuckets;

  final List<Float32List> _rawBuckets;
  final Int32List _rawOffsets = Int32List(numBuckets);

  LineBuckets({int initialSegmentCapacityPerBucket = 512})
    : _rawBuckets = List.generate(
        numBuckets,
        (_) => Float32List(initialSegmentCapacityPerBucket * 4),
        growable: false,
      );

  /// Raw coordinate buffers for each alpha bucket.
  List<Float32List> get rawBuckets => _rawBuckets;

  /// Raw float offsets (4 floats per line) for each alpha bucket.
  Int32List get rawOffsets => _rawOffsets;

  /// Resets all bucket offsets for the start of a new frame.
  @pragma('vm:prefer-inline')
  void clear() {
    _rawOffsets.fillRange(0, numBuckets, 0);
  }

  /// Appends a connection line into the appropriate alpha bucket.
  @pragma('vm:prefer-inline')
  void emitLine({
    required double x1,
    required double y1,
    required double x2,
    required double y2,
    required double distSq,
    required double invMaxDistSq,
    double rankFade = 1.0,
  }) {
    int tableIdx = ((distSq * invMaxDistSq) * kDistBucketTableSize).toInt();
    if (tableIdx > kDistBucketTableSize) tableIdx = kDistBucketTableSize;
    int bucket = LineStylePalette.distBucketTable[tableIdx];
    if (rankFade < 1.0) {
      bucket = (bucket * rankFade).round().clamp(0, numBuckets - 1);
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

  Float32List _growBucket(int b, int needed) {
    final newBuf = Float32List(math.max(_rawBuckets[b].length * 2, needed));
    newBuf.setRange(0, _rawOffsets[b], _rawBuckets[b]);
    _rawBuckets[b] = newBuf;
    return newBuf;
  }

  /// Renders all bucketed segments using stroked canvas raw points.
  int renderStroke(Canvas canvas, List<Paint> lineBucketPaints) {
    int lineCount = 0;
    for (int b = 0; b < numBuckets; b++) {
      final int rawCount = _rawOffsets[b];
      lineCount += rawCount ~/ 4;
      if (rawCount > 0) {
        canvas.drawRawPoints(
          PointMode.lines,
          Float32List.sublistView(_rawBuckets[b], 0, rawCount),
          lineBucketPaints[b],
        );
      }
    }
    return lineCount;
  }

  /// Renders all bucketed segments using triangle quads via [LineVertexBatch].
  int renderVertices({
    required Canvas canvas,
    required LineVertexBatch batch,
    required Paint vertexPaint,
    required List<Paint> lineBucketPaints,
    required double lineWidth,
    required double devicePixelRatio,
  }) {
    final double minWidth = devicePixelRatio > 0 ? 1.0 / devicePixelRatio : 1.0;
    final double width = lineWidth > minWidth ? lineWidth : minWidth;
    final double alphaScale = lineWidth / width;
    final double halfWidth = width * 0.5;

    batch.clear();
    int lineCount = 0;

    for (int b = 0; b < numBuckets; b++) {
      final int rawCount = _rawOffsets[b];
      if (rawCount == 0) continue;
      lineCount += rawCount ~/ 4;

      final int argb = _scaledArgb(lineBucketPaints[b].color, alphaScale);
      if ((argb >>> 24) == 0) continue;

      batch.addSegments(_rawBuckets[b], rawCount, halfWidth, null, argb);
    }

    if (batch.lineCount > 0) {
      vertexPaint.color = const Color(0xFFFFFFFF);
      batch.draw(canvas, vertexPaint);
    }

    return lineCount;
  }

  static int _scaledArgb(Color color, double alphaScale) {
    final int argb = color.toARGB32();
    if (alphaScale >= 1.0) return argb;
    final int alpha = ((argb >>> 24) * alphaScale).round().clamp(0, 255);
    return (alpha << 24) | (argb & 0x00FFFFFF);
  }
}
