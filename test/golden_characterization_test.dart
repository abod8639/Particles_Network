import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/particles_network.dart';

class RawPointsCall {
  final PointMode pointMode;
  final Float32List points;
  final Color color;
  final double strokeWidth;

  RawPointsCall({
    required this.pointMode,
    required this.points,
    required this.color,
    required this.strokeWidth,
  });
}

class LineCall {
  final Offset p1;
  final Offset p2;
  final Color color;
  final double strokeWidth;

  LineCall({
    required this.p1,
    required this.p2,
    required this.color,
    required this.strokeWidth,
  });
}

class CircleCall {
  final Offset center;
  final double radius;
  final Color color;

  CircleCall({
    required this.center,
    required this.radius,
    required this.color,
  });
}

class RecordingCanvas implements Canvas {
  final List<RawPointsCall> rawPointsCalls = [];
  final List<LineCall> lineCalls = [];
  final List<CircleCall> circleCalls = [];
  int verticesCallCount = 0;

  void clear() {
    rawPointsCalls.clear();
    lineCalls.clear();
    circleCalls.clear();
    verticesCallCount = 0;
  }

  @override
  void drawRawPoints(PointMode pointMode, Float32List points, Paint paint) {
    rawPointsCalls.add(RawPointsCall(
      pointMode: pointMode,
      points: Float32List.fromList(points),
      color: paint.color,
      strokeWidth: paint.strokeWidth,
    ));
  }

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {
    lineCalls.add(LineCall(
      p1: p1,
      p2: p2,
      color: paint.color,
      strokeWidth: paint.strokeWidth,
    ));
  }

  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    circleCalls.add(CircleCall(
      center: c,
      radius: radius,
      color: paint.color,
    ));
  }

  @override
  void drawVertices(Vertices vertices, BlendMode blendMode, Paint paint) {
    verticesCallCount++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

List<Particle> _generateFixedParticles(int count, int seed, Size size) {
  final random = math.Random(seed);
  return List.generate(count, (index) {
    return Particle(
      position: Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      ),
      velocity: Offset(
        (random.nextDouble() - 0.5) * 2.0,
        (random.nextDouble() - 0.5) * 2.0,
      ),
      size: 1.0 + random.nextDouble() * 3.0,
      color: const Color(0xFFFFFFFF),
    );
  });
}

void main() {
  const Size size = Size(600, 600);

  group('Phase 0: Golden Characterization Tests', () {
    test('Individual path (N < 30) records exact line counts and colors', () {
      final particles = _generateFixedParticles(25, 42, size);
      final canvas = RecordingCanvas();

      final painter = OptimizedNetworkPainter(
        particles: particles,
        particleCount: particles.length,
        touchPoint: null,
        lineDistance: 120.0,
        particleColor: const Color(0xFFFFFFFF),
        lineColor: const Color(0x80FFFFFF),
        lineWidth: 1.5,
        fill: true,
        drawNetwork: true,
        performance: const NetworkPerformance(
          lineRenderer: LineRenderer.stroke,
        ),
      );

      painter.paint(canvas, size);

      expect(canvas.lineCalls.length, equals(painter.lastFrameLineCount));
      expect(painter.lastFrameLineCount, equals(37));
      expect(canvas.circleCalls.length, equals(0)); // batched points used
      expect(canvas.rawPointsCalls.length, greaterThan(0)); // particle points
    });

    test('Batched stroke path (N = 100) uncapped records exact bucket points',
        () {
      final particles = _generateFixedParticles(100, 42, size);
      final canvas = RecordingCanvas();

      final painter = OptimizedNetworkPainter(
        particles: particles,
        particleCount: particles.length,
        touchPoint: null,
        lineDistance: 100.0,
        particleColor: const Color(0xFFFFFFFF),
        lineColor: const Color(0x80FFFFFF),
        lineWidth: 1.0,
        fill: true,
        drawNetwork: true,
        performance: const NetworkPerformance(
          lineRenderer: LineRenderer.stroke,
        ),
      );

      painter.paint(canvas, size);

      final lineCalls = canvas.rawPointsCalls
          .where((call) => call.pointMode == PointMode.lines)
          .toList();

      int totalSegments = 0;
      for (final call in lineCalls) {
        totalSegments += call.points.length ~/ 4;
      }

      expect(totalSegments, equals(painter.lastFrameLineCount));
      expect(painter.lastFrameLineCount, equals(399));
    });

    test('Batched vertices path (N = 100) records exact drawVertices calls',
        () {
      final particles = _generateFixedParticles(100, 42, size);
      final canvas = RecordingCanvas();

      final painter = OptimizedNetworkPainter(
        particles: particles,
        particleCount: particles.length,
        touchPoint: null,
        lineDistance: 100.0,
        particleColor: const Color(0xFFFFFFFF),
        lineColor: const Color(0x80FFFFFF),
        lineWidth: 1.0,
        fill: true,
        drawNetwork: true,
        performance: const NetworkPerformance(
          lineRenderer: LineRenderer.vertices,
        ),
      );

      painter.paint(canvas, size);

      expect(canvas.verticesCallCount, equals(1));
      expect(painter.lastFrameLineCount, equals(399));
    });

    test(
        'Capped maxConnectionsPerParticle path reduces line count deterministically',
        () {
      final particles = _generateFixedParticles(100, 42, size);
      final canvas = RecordingCanvas();

      final painter = OptimizedNetworkPainter(
        particles: particles,
        particleCount: particles.length,
        touchPoint: null,
        lineDistance: 100.0,
        particleColor: const Color(0xFFFFFFFF),
        lineColor: const Color(0x80FFFFFF),
        lineWidth: 1.0,
        fill: true,
        drawNetwork: true,
        performance: const NetworkPerformance(
          lineRenderer: LineRenderer.stroke,
          maxConnectionsPerParticle: 3,
        ),
      );

      painter.paint(canvas, size);

      expect(painter.lastFrameLineCount, lessThan(399));
      expect(painter.lastFrameLineCount, equals(130));
    });

    test(
        'Complex throttling path reduces dense cluster lines deterministically',
        () {
      final particles = _generateFixedParticles(100, 42, size);
      final canvas = RecordingCanvas();

      final painter = OptimizedNetworkPainter(
        particles: particles,
        particleCount: particles.length,
        touchPoint: null,
        lineDistance: 150.0,
        particleColor: const Color(0xFFFFFFFF),
        lineColor: const Color(0x80FFFFFF),
        lineWidth: 1.0,
        fill: true,
        drawNetwork: true,
        performance: const NetworkPerformance(
          lineRenderer: LineRenderer.stroke,
          isComplex: true,
        ),
      );

      painter.paint(canvas, size);

      expect(painter.lastFrameLineCount, equals(812));
    });

    test('Budgeted line distance automatically adjusts radius', () {
      final particles = _generateFixedParticles(200, 42, size);
      final canvas = RecordingCanvas();

      final painter = OptimizedNetworkPainter(
        particles: particles,
        particleCount: particles.length,
        touchPoint: null,
        lineDistance: 150.0,
        particleColor: const Color(0xFFFFFFFF),
        lineColor: const Color(0x80FFFFFF),
        lineWidth: 1.0,
        fill: true,
        drawNetwork: true,
        performance: const NetworkPerformance(
          lineRenderer: LineRenderer.stroke,
          maxLinesPerFrame: 50,
        ),
      );

      // Frame 1
      painter.paint(canvas, size);
      expect(painter.lastFrameLineDistance, lessThan(150.0));
      final double r1 = painter.lastFrameLineDistance;

      // Frame 2
      canvas.clear();
      painter.paint(canvas, size);
      final double r2 = painter.lastFrameLineDistance;

      expect(r1, greaterThan(0));
      expect(r2, greaterThan(0));
    });

    test('Fill true vs false toggles particle rendering path', () {
      final particles = _generateFixedParticles(20, 42, size);
      final canvasFill = RecordingCanvas();
      final canvasStroke = RecordingCanvas();

      final painterFill = OptimizedNetworkPainter(
        particles: particles,
        particleCount: particles.length,
        touchPoint: null,
        lineDistance: 100.0,
        particleColor: const Color(0xFFFFFFFF),
        lineColor: const Color(0x80FFFFFF),
        lineWidth: 1.0,
        fill: true,
        drawNetwork: false,
      );

      painterFill.paint(canvasFill, size);
      // fill=true with N=20 uses batched point buckets
      expect(canvasFill.rawPointsCalls.length, greaterThan(0));
      expect(canvasFill.circleCalls.length, equals(0));

      final painterStroke = OptimizedNetworkPainter(
        particles: particles,
        particleCount: particles.length,
        touchPoint: null,
        lineDistance: 100.0,
        particleColor: const Color(0xFFFFFFFF),
        lineColor: const Color(0x80FFFFFF),
        lineWidth: 1.0,
        fill: false,
        drawNetwork: false,
      );

      painterStroke.paint(canvasStroke, size);
      // fill=false uses canvas.drawCircle
      expect(canvasStroke.circleCalls.length, equals(20));
      expect(canvasStroke.rawPointsCalls.length, equals(0));
    });
  });

  group('Phase 0: Steady-State Zero-Allocation Invariance', () {
    test('Buffers maintain identity and capacity across multiple frames', () {
      final particles = _generateFixedParticles(200, 42, size);
      final canvas = RecordingCanvas();

      final painter = OptimizedNetworkPainter(
        particles: particles,
        particleCount: particles.length,
        touchPoint: null,
        lineDistance: 100.0,
        particleColor: const Color(0xFFFFFFFF),
        lineColor: const Color(0x80FFFFFF),
        lineWidth: 1.0,
        fill: true,
        drawNetwork: true,
        performance: const NetworkPerformance(
          lineRenderer: LineRenderer.stroke,
          maxConnectionsPerParticle: 4,
        ),
      );

      // Warmup frame 1: initializes/sizes buffers
      painter.paint(canvas, size);

      final grid = painter.spatialGrid;
      final xsIdentity = grid.xs;
      final ysIdentity = grid.ys;
      final cellStartIdentity = grid.cellStart;
      final xsLength = grid.xs.length;
      final ysLength = grid.ys.length;
      final cellStartLength = grid.cellStart.length;

      // Frames 2-5: check steady-state buffer invariance
      for (int f = 0; f < 5; f++) {
        canvas.clear();
        painter.paint(canvas, size);

        // Verify identical buffer references (no reallocation)
        expect(identical(grid.xs, xsIdentity), isTrue,
            reason: 'grid.xs reallocated on frame $f');
        expect(identical(grid.ys, ysIdentity), isTrue,
            reason: 'grid.ys reallocated on frame $f');
        expect(identical(grid.cellStart, cellStartIdentity), isTrue,
            reason: 'grid.cellStart reallocated on frame $f');

        // Verify buffer capacities remain unchanged
        expect(grid.xs.length, equals(xsLength));
        expect(grid.ys.length, equals(ysLength));
        expect(grid.cellStart.length, equals(cellStartLength));
      }
    });
  });
}
