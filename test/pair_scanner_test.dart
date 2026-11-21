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

    test(
        'scanIndividual does not apply complex rankFade when isComplexMode is false',
        () {
      // 4 particles: p0 is at (10, 10). Neighbors p1, p2, p3 are at distances 10, 20, 30.
      final particles = [
        Particle(
            position: const Offset(10, 10),
            velocity: Offset.zero,
            size: 1.0,
            color: const Color(0xFFFFFFFF)),
        Particle(
            position: const Offset(20, 10), // dist = 10
            velocity: Offset.zero,
            size: 1.0,
            color: const Color(0xFFFFFFFF)),
        Particle(
            position: const Offset(30, 10), // dist = 20
            velocity: Offset.zero,
            size: 1.0,
            color: const Color(0xFFFFFFFF)),
        Particle(
            position: const Offset(40, 10), // dist = 30
            velocity: Offset.zero,
            size: 1.0,
            color: const Color(0xFFFFFFFF)),
      ];

      final grid = SortedSpatialGrid();
      final visible = [0, 1, 2, 3];
      grid.build(particles, visible, 200, 200, 100.0, 1.0);

      final canvas = RecordingCanvas();
      final candidateBuffer = CandidateBuffer();
      final palette = LineStylePalette(
        lineColor: const Color(0xFFFFFFFF),
        lineWidth: 1.0,
        antiAlias: true,
      );

      // maxConnectionsPerParticle = 2, candidateCount = 3 for p0.
      // isComplexMode = false.
      // Expected: line 2 (distance 20) should NOT have complex rank fade applied!
      scanner.scanIndividual(
        canvas: canvas,
        grid: grid,
        scanDistance: 100.0,
        maxDistSq: 10000.0,
        alphaDistance: 100.0,
        lineColorLut: palette.lineColorLut,
        linePaint: Paint(),
        candidateBuffer: candidateBuffer,
        throttler: throttler,
        performance: const NetworkPerformance(maxConnectionsPerParticle: 2),
        maxConnectionsPerParticle: 2,
        isComplexMode: false,
      );

      // Find the line between p0 and p2 (dist = 20)
      final lineP0P2 = canvas.lineCalls.firstWhere(
        (c) =>
            (c.p1 == const Offset(10, 10) && c.p2 == const Offset(30, 10)) ||
            (c.p2 == const Offset(10, 10) && c.p1 == const Offset(30, 10)),
      );

      // With distance 20 and alphaDistance 100:
      // expected alpha without complex rank fade = (255 - 20 * 2.55) = 204 (0xCC)
      // With buggy complex rank fade (0.5) = (204 * 0.5) = 102 (0x66)
      final int expectedAlphaWithoutFade =
          (255 - (20 * 255.0 / 100.0)).toInt().clamp(0, 255);
      final expectedColor = palette.lineColorLut[expectedAlphaWithoutFade];

      expect(lineP0P2.color.toARGB32(), equals(expectedColor.toARGB32()));
      expect(lineP0P2.color.toARGB32(), equals(0xCCFFFFFF));
    });

    test(
        'scanner methods return early and emit 0 lines when maxDistSq <= 0 or non-finite',
        () {
      final particles = [
        Particle(
            position: const Offset(10, 10),
            velocity: Offset.zero,
            size: 1.0,
            color: const Color(0xFFFFFFFF)),
        Particle(
            position: const Offset(10, 10),
            velocity: Offset.zero,
            size: 1.0,
            color: const Color(0xFFFFFFFF)),
      ];

      final grid = SortedSpatialGrid();
      final visible = [0, 1];
      grid.build(particles, visible, 100, 100, 50.0, 1.0);

      final buckets = LineBuckets();
      scanner.scanBatchedFast(
        grid: grid,
        maxDistSq: 0.0,
        invMaxDistSq: double.infinity,
        buckets: buckets,
      );

      expect(buckets.rawOffsets.every((o) => o == 0), isTrue);

      final candidateBuffer = CandidateBuffer();
      scanner.scanBatchedComplex(
        grid: grid,
        maxDistSq: 0.0,
        invMaxDistSq: double.infinity,
        scanDistance: 0.0,
        buckets: buckets,
        candidateBuffer: candidateBuffer,
        throttler: throttler,
        performance: const NetworkPerformance(),
        maxConnectionsPerParticle: null,
        isComplexMode: false,
      );

      expect(buckets.rawOffsets.every((o) => o == 0), isTrue);

      final canvas = RecordingCanvas();
      final palette = LineStylePalette(
        lineColor: const Color(0xFFFFFFFF),
        lineWidth: 1.0,
        antiAlias: true,
      );

      final count = scanner.scanIndividual(
        canvas: canvas,
        grid: grid,
        scanDistance: 0.0,
        maxDistSq: 0.0,
        alphaDistance: 0.0,
        lineColorLut: palette.lineColorLut,
        linePaint: Paint(),
        candidateBuffer: candidateBuffer,
        throttler: throttler,
        performance: const NetworkPerformance(),
        maxConnectionsPerParticle: null,
        isComplexMode: false,
      );

      expect(count, equals(0));
      expect(canvas.lineCalls, isEmpty);
    });

    test('scanIndividual does not apply complex rankFade when isComplexMode is false', () {
      // 4 particles: p0 is at (10, 10). Neighbors p1, p2, p3 are at distances 10, 20, 30.
      final particles = [
        Particle(
            position: const Offset(10, 10),
            velocity: Offset.zero,
            size: 1.0,
            color: const Color(0xFFFFFFFF)),
        Particle(
            position: const Offset(20, 10), // dist = 10
            velocity: Offset.zero,
            size: 1.0,
            color: const Color(0xFFFFFFFF)),
        Particle(
            position: const Offset(30, 10), // dist = 20
            velocity: Offset.zero,
            size: 1.0,
            color: const Color(0xFFFFFFFF)),
        Particle(
            position: const Offset(40, 10), // dist = 30
            velocity: Offset.zero,
            size: 1.0,
            color: const Color(0xFFFFFFFF)),
      ];

      final grid = SortedSpatialGrid();
      final visible = [0, 1, 2, 3];
      grid.build(particles, visible, 200, 200, 100.0, 1.0);

      final canvas = RecordingCanvas();
      final candidateBuffer = CandidateBuffer();
      final palette = LineStylePalette(
        lineColor: const Color(0xFFFFFFFF),
        lineWidth: 1.0,
        antiAlias: true,
      );

      // maxConnectionsPerParticle = 2, candidateCount = 3 for p0.
      // isComplexMode = false.
      // Expected: line 2 (distance 20) should NOT have complex rank fade applied!
      scanner.scanIndividual(
        canvas: canvas,
        grid: grid,
        scanDistance: 100.0,
        maxDistSq: 10000.0,
        alphaDistance: 100.0,
        lineColorLut: palette.lineColorLut,
        linePaint: Paint(),
        candidateBuffer: candidateBuffer,
        throttler: throttler,
        performance: const NetworkPerformance(maxConnectionsPerParticle: 2),
        maxConnectionsPerParticle: 2,
        isComplexMode: false,
      );

      // Find the line between p0 and p2 (dist = 20)
      final lineP0P2 = canvas.lineCalls.firstWhere(
        (c) => (c.p1 == const Offset(10, 10) && c.p2 == const Offset(30, 10)) ||
               (c.p2 == const Offset(10, 10) && c.p1 == const Offset(30, 10)),
      );

      // With distance 20 and alphaDistance 100:
      // expected alpha without complex rank fade = (255 - 20 * 2.55) = 204 (0xCC)
      // With buggy complex rank fade (0.5) = (204 * 0.5) = 102 (0x66)
      final int expectedAlphaWithoutFade = (255 - (20 * 255.0 / 100.0)).toInt().clamp(0, 255);
      final expectedColor = palette.lineColorLut[expectedAlphaWithoutFade];

      expect(lineP0P2.color.toARGB32(), equals(expectedColor.toARGB32()));
      expect(lineP0P2.color.toARGB32(), equals(0xCCFFFFFF));
    });

    test('scanner methods return early and emit 0 lines when maxDistSq <= 0 or non-finite', () {
      final particles = [
        Particle(
            position: const Offset(10, 10),
            velocity: Offset.zero,
            size: 1.0,
            color: const Color(0xFFFFFFFF)),
        Particle(
            position: const Offset(10, 10),
            velocity: Offset.zero,
            size: 1.0,
            color: const Color(0xFFFFFFFF)),
      ];

      final grid = SortedSpatialGrid();
      final visible = [0, 1];
      grid.build(particles, visible, 100, 100, 50.0, 1.0);

      final buckets = LineBuckets();
      scanner.scanBatchedFast(
        grid: grid,
        maxDistSq: 0.0,
        invMaxDistSq: double.infinity,
        buckets: buckets,
      );

      expect(buckets.rawOffsets.every((o) => o == 0), isTrue);

      final candidateBuffer = CandidateBuffer();
      scanner.scanBatchedComplex(
        grid: grid,
        maxDistSq: 0.0,
        invMaxDistSq: double.infinity,
        scanDistance: 0.0,
        buckets: buckets,
        candidateBuffer: candidateBuffer,
        throttler: throttler,
        performance: const NetworkPerformance(),
        maxConnectionsPerParticle: null,
        isComplexMode: false,
      );

      expect(buckets.rawOffsets.every((o) => o == 0), isTrue);

      final canvas = RecordingCanvas();
      final palette = LineStylePalette(
        lineColor: const Color(0xFFFFFFFF),
        lineWidth: 1.0,
        antiAlias: true,
      );

      final count = scanner.scanIndividual(
        canvas: canvas,
        grid: grid,
        scanDistance: 0.0,
        maxDistSq: 0.0,
        alphaDistance: 0.0,
        lineColorLut: palette.lineColorLut,
        linePaint: Paint(),
        candidateBuffer: candidateBuffer,
        throttler: throttler,
        performance: const NetworkPerformance(),
        maxConnectionsPerParticle: null,
        isComplexMode: false,
      );

      expect(count, equals(0));
      expect(canvas.lineCalls, isEmpty);
    });
  });
}
