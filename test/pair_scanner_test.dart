import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/particles_network.dart';
import 'package:particles_network/src/rendering/candidate_buffer.dart';
import 'package:particles_network/src/rendering/cluster_throttler.dart';
import 'package:particles_network/src/rendering/line_buckets.dart';
import 'package:particles_network/src/rendering/line_style_palette.dart';
import 'package:particles_network/src/rendering/pair_scanner.dart';

import 'golden_characterization_test.dart';

void main() {
  group('PairScanner Unit Tests', () {
    const scanner = PairScanner();
    const throttler = ClusterThrottler();

    test('scanBatchedFast scans pairs into LineBuckets accurately', () {
      final random = math.Random(42);
      final particles = List.generate(50, (i) {
        return Particle(
          position:
              Offset(random.nextDouble() * 500, random.nextDouble() * 500),
          velocity: Offset.zero,
          size: 1.0,
          color: const Color(0xFFFFFFFF),
        );
      });

      final grid = SortedSpatialGrid();
      final visible = List.generate(50, (i) => i);
      grid.build(particles, visible, 500, 500, 100.0, 1.0);

      final buckets = LineBuckets();
      final double maxDistSq = 100.0 * 100.0;
      final double invMaxDistSq = 1.0 / maxDistSq;

      scanner.scanBatchedFast(
        grid: grid,
        maxDistSq: maxDistSq,
        invMaxDistSq: invMaxDistSq,
        buckets: buckets,
      );

      final canvas = RecordingCanvas();
      final palette = LineStylePalette(
        lineColor: const Color(0x80FFFFFF),
        lineWidth: 1.0,
        antiAlias: true,
      );

      final count = buckets.renderStroke(canvas, palette.lineBucketPaints);
      expect(count, greaterThan(0));
    });

    test('scanBatchedComplex enforces degree capping', () {
      final random = math.Random(42);
      final particles = List.generate(50, (i) {
        return Particle(
          position:
              Offset(random.nextDouble() * 500, random.nextDouble() * 500),
          velocity: Offset.zero,
          size: 1.0,
          color: const Color(0xFFFFFFFF),
        );
      });

      final grid = SortedSpatialGrid();
      final visible = List.generate(50, (i) => i);
      grid.build(particles, visible, 500, 500, 100.0, 1.0);

      final buckets = LineBuckets();
      final candidateBuffer = CandidateBuffer();
      final double maxDistSq = 100.0 * 100.0;
      final double invMaxDistSq = 1.0 / maxDistSq;

      scanner.scanBatchedComplex(
        grid: grid,
        maxDistSq: maxDistSq,
        invMaxDistSq: invMaxDistSq,
        scanDistance: 100.0,
        buckets: buckets,
        candidateBuffer: candidateBuffer,
        throttler: throttler,
        performance: const NetworkPerformance(maxConnectionsPerParticle: 2),
        maxConnectionsPerParticle: 2,
        isComplexMode: false,
      );

      final canvas = RecordingCanvas();
      final palette = LineStylePalette(
        lineColor: const Color(0x80FFFFFF),
        lineWidth: 1.0,
        antiAlias: true,
      );

      final count = buckets.renderStroke(canvas, palette.lineBucketPaints);
      expect(count, greaterThan(0));
      expect(count, lessThanOrEqualTo(50 * 2));
    });

    test('scanIndividual renders direct lines onto canvas for small counts',
        () {
      final particles = [
        Particle(
            position: const Offset(10, 10),
            velocity: Offset.zero,
            size: 1.0,
            color: const Color(0xFFFFFFFF)),
        Particle(
            position: const Offset(20, 20),
            velocity: Offset.zero,
            size: 1.0,
            color: const Color(0xFFFFFFFF)),
        Particle(
            position: const Offset(30, 30),
            velocity: Offset.zero,
            size: 1.0,
            color: const Color(0xFFFFFFFF)),
      ];

      final grid = SortedSpatialGrid();
      final visible = [0, 1, 2];
      grid.build(particles, visible, 100, 100, 50.0, 1.0);

      final canvas = RecordingCanvas();
      final candidateBuffer = CandidateBuffer();
      final palette = LineStylePalette(
        lineColor: const Color(0x80FFFFFF),
        lineWidth: 1.0,
        antiAlias: true,
      );

      final lineCount = scanner.scanIndividual(
        canvas: canvas,
        grid: grid,
        scanDistance: 50.0,
        maxDistSq: 2500.0,
        alphaDistance: 50.0,
        lineColorLut: palette.lineColorLut,
        linePaint: Paint(),
        candidateBuffer: candidateBuffer,
        throttler: throttler,
        performance: const NetworkPerformance(),
        maxConnectionsPerParticle: null,
        isComplexMode: false,
      );

      expect(lineCount, equals(3));
      expect(canvas.lineCalls.length, equals(3));
    });
  });
}
