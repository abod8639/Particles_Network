import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/src/rendering/line_buckets.dart';
import 'package:particles_network/src/rendering/line_style_palette.dart';
import 'package:particles_network/src/rendering/line_vertex_batch.dart';

import 'golden_characterization_test.dart';

void main() {
  group('LineBuckets Unit Tests', () {
    test('emitLine buckets segments correctly by distance', () {
      final buckets = LineBuckets();
      final maxDist = 100.0;
      final invMaxDistSq = 1.0 / (maxDist * maxDist);

      // Distance 0 (closest) -> highest opacity bucket (31)
      buckets.emitLine(
        x1: 0,
        y1: 0,
        x2: 0,
        y2: 0,
        distSq: 0,
        invMaxDistSq: invMaxDistSq,
      );

      expect(buckets.rawOffsets[31], equals(4));

      // Distance near max -> lowest opacity bucket (0)
      buckets.emitLine(
        x1: 0,
        y1: 0,
        x2: 99,
        y2: 0,
        distSq: 99.0 * 99.0,
        invMaxDistSq: invMaxDistSq,
      );

      expect(buckets.rawOffsets[0], equals(4));

      buckets.clear();
      expect(buckets.rawOffsets[0], equals(0));
      expect(buckets.rawOffsets[31], equals(0));
    });

    test('renderStroke and renderVertices emit expected calls', () {
      final buckets = LineBuckets();
      final palette = LineStylePalette(
        lineColor: const Color(0x80FFFFFF),
        lineWidth: 1.0,
        antiAlias: true,
      );

      final invMaxDistSq = 1.0 / 10000.0;
      buckets.emitLine(
        x1: 10,
        y1: 10,
        x2: 20,
        y2: 20,
        distSq: 200,
        invMaxDistSq: invMaxDistSq,
      );

      final strokeCanvas = RecordingCanvas();
      final strokeLines =
          buckets.renderStroke(strokeCanvas, palette.lineBucketPaints);
      expect(strokeLines, equals(1));
      expect(strokeCanvas.rawPointsCalls.length, equals(1));

      final vertexCanvas = RecordingCanvas();
      final batch = LineVertexBatch();
      final vertexPaint = Paint();
      final vertexLines = buckets.renderVertices(
        canvas: vertexCanvas,
        batch: batch,
        vertexPaint: vertexPaint,
        lineBucketPaints: palette.lineBucketPaints,
        lineWidth: 1.0,
        devicePixelRatio: 1.0,
      );
      expect(vertexLines, equals(1));
      expect(vertexCanvas.verticesCallCount, equals(1));
    });

    test('rawBuckets exposes coordinate buffers for all buckets (L27-L28)', () {
      final buckets = LineBuckets(initialSegmentCapacityPerBucket: 256);
      expect(buckets.rawBuckets.length, equals(LineBuckets.numBuckets));
      expect(buckets.rawBuckets.first.length, equals(256 * 4));
    });
  });
}
