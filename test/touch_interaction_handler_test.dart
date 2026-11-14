import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:particles_network/particles_network.dart';

import 'mocks/mock_canvas.mocks.dart';

void main() {
  group('TouchInteractionHandler - applyTouchPhysics', () {
    test('should accelerate visible particles within range', () {
      // Arrange
      final particleInRange = Particle(
        position: const Offset(100, 100),
        velocity: Offset.zero,
        color: Colors.white,
        size: 2,
      );

      final particleOutOfRange = Particle(
        position: const Offset(500, 500), // بعيد جداً عن نقطة اللمس
        velocity: Offset.zero,
        color: Colors.white,
        size: 2,
      );

      final particles = [particleInRange, particleOutOfRange];

      final handler = TouchInteractionHandler(
        particles: particles,
        touchPoint: const Offset(105, 105),
        lineDistance: 100.0,
        touchColor: Colors.amber,
        linePaint: Paint(),
      );

      // Act
      final tracker = AccelerationTracker();
      handler.applyTouchPhysics([0, 1], tracker);

      // Assert
      expect(particles[0].wasAccelerated, isTrue);
      expect(
        particles[0].velocity.dx != 0 || particles[0].velocity.dy != 0,
        isTrue,
      );

      expect(particles[1].wasAccelerated, isFalse);
      expect(particles[1].velocity, Offset.zero);
      expect(tracker.acceleratedParticleCount, greaterThan(0));
    });

    test(
        'clamps velocity to maxTouchSpeed when speedSq > maxTouchSpeedSq (L113-L117)',
        () {
      final p = Particle(
        position: const Offset(90, 90),
        velocity: Offset.zero,
        color: Colors.white,
        size: 2,
      );

      const double maxTouchSpeed = 4.0;
      final handler = TouchInteractionHandler(
        particles: [p],
        touchPoint: const Offset(100, 100),
        lineDistance: 100.0,
        touchColor: Colors.amber,
        linePaint: Paint(),
        touchFeatures: const TouchFeatures(
          force: 50.0, // strong force that exceeds terminal velocity
          maxTouchSpeed: maxTouchSpeed,
          damping: 1.0,
        ),
      );

      final tracker = AccelerationTracker();
      handler.applyTouchPhysics([0], tracker);

      // Velocity magnitude must be clamped to maxTouchSpeed
      expect(p.velocity.distance, closeTo(maxTouchSpeed, 1e-5));
      // Direction towards (100, 100) is 45 degrees, so vx and vy should be equal
      expect(p.velocity.dx, closeTo(p.velocity.dy, 1e-5));
      expect(p.velocity.dx, greaterThan(0));
      expect(p.velocity.dy, greaterThan(0));
    });

    test('returns immediately when touchPoint is null (L83)', () {
      final p = Particle(
        position: const Offset(100, 100),
        velocity: Offset.zero,
        color: Colors.white,
        size: 2,
      );

      final handler = TouchInteractionHandler(
        particles: [p],
        touchPoint: null,
        lineDistance: 100.0,
        touchColor: Colors.amber,
        linePaint: Paint(),
      );

      final tracker = AccelerationTracker();
      handler.applyTouchPhysics([0], tracker);

      expect(p.wasAccelerated, isFalse);
      expect(p.velocity, Offset.zero);
      expect(tracker.acceleratedParticleCount, equals(0));

      handler.applyTouchPhysicsScaled([0], tracker, 2.0);

      expect(p.wasAccelerated, isFalse);
      expect(p.velocity, Offset.zero);
      expect(tracker.acceleratedParticleCount, equals(0));
    });

    test(
        'applyTouchPhysicsScaled calculates damping with math.pow when timeScale != 1.0 (L93)',
        () {
      final p = Particle(
        position: const Offset(100, 100),
        velocity: Offset.zero,
        color: Colors.white,
        size: 2,
      );

      const double damping = 0.8;
      const double forceValue = 1.0;
      const double timeScale = 2.0;

      final handler = TouchInteractionHandler(
        particles: [p],
        touchPoint: const Offset(110, 100),
        lineDistance: 100.0,
        touchColor: Colors.amber,
        linePaint: Paint(),
        touchFeatures: const TouchFeatures(
          force: forceValue,
          damping: damping,
          maxTouchSpeed: 20.0,
        ),
      );

      final tracker = AccelerationTracker();
      handler.applyTouchPhysicsScaled([0], tracker, timeScale);

      final double expectedDamping = math.pow(damping, timeScale).toDouble();
      final double expectedVx =
          (10.0 * handler.force * timeScale + forceValue * 0.9 * timeScale) *
              expectedDamping;

      expect(p.wasAccelerated, isTrue);
      expect(p.velocity.dx, closeTo(expectedVx, 1e-5));
      expect(p.velocity.dy, closeTo(0.0, 1e-5));
      expect(tracker.acceleratedParticleCount, equals(1));
    });
  });

  group('TouchInteractionHandler', () {
    test('drawTouchLines returns immediately when touchPoint is null (L136)',
        () {
      final mockCanvas = MockCanvas();
      final particles = [
        Particle(
          position: const Offset(100, 100),
          velocity: Offset.zero,
          color: Colors.white,
          size: 2,
        ),
      ];

      final handler = TouchInteractionHandler(
        particles: particles,
        touchPoint: null, // touchPoint is null
        lineDistance: 100.0,
        touchColor: Colors.amber,
        linePaint: Paint(),
      );

      handler.drawTouchLines(mockCanvas, [0]);

      // No drawing calls should be made on mockCanvas
      verifyZeroInteractions(mockCanvas);
    });

    testWidgets('drawTouchLines should draw lines for particles within range', (
      WidgetTester tester,
    ) async {
      // إعداد الجسيمات
      final particles = [
        Particle(
          position: const Offset(100, 100),
          velocity: const Offset(0, 0),
          color: Colors.blue,
          size: 10.0,
        ),
        Particle(
          position: const Offset(150, 150),
          velocity: const Offset(0, 0),
          color: Colors.red,
          size: 10.0,
        ),
      ];

      const touchPoint = Offset(120, 120);
      final linePaint = Paint();
      final handler = TouchInteractionHandler(
        particles: particles,
        touchPoint: touchPoint,
        lineDistance: 50,
        touchColor: Colors.red,
        linePaint: linePaint,
      );

      // قم بإنشاء واجهة لاختبار الرسم
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              painter: TestPainter(handler: handler),
              child: Container(),
            ),
          ),
        ),
      );

      // انتظر قليلاً لتمكين رسم الإطار
      await tester.pumpAndSettle();

      // تحقق من أن هناك فقط CustomPaint واحد داخل Scaffold
      final customPaintFinder = find.descendant(
        of: find.byType(Scaffold),
        matching: find.byType(CustomPaint),
      );

      // تحقق من أن هناك فقط CustomPaint واحد
      expect(customPaintFinder, findsOneWidget);
    });

    test('drawTouchLines restores linePaint color after drawing', () {
      final particles = [
        Particle(
          position: const Offset(100, 100),
          velocity: const Offset(0, 0),
          color: Colors.white,
          size: 1.0,
        ),
      ];

      final linePaint = Paint()..color = Colors.green;
      final handler = TouchInteractionHandler(
        particles: particles,
        touchPoint: const Offset(110, 100),
        lineDistance: 50,
        touchColor: Colors.amber,
        linePaint: linePaint,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      handler.drawTouchLines(canvas, [0]);
      recorder.endRecording().dispose();

      expect(linePaint.color.toARGB32(), equals(Colors.green.toARGB32()));
    });
  });

  group('TouchFeatures', () {
    test('default values are set correctly', () {
      const features = TouchFeatures();
      expect(features.speed, equals(0.42));
      expect(features.decayRate, equals(0.42));
      expect(features.force, equals(0.42));
      expect(features.pullForce, equals(0.42));
      expect(features.maxTouchSpeed, equals(5.5));
      expect(features.damping, equals(0.985));
    });

    test('custom values and aliases are supported', () {
      const features = TouchFeatures(
        speed: 0.02,
        force: 0.8,
        maxTouchSpeed: 10.0,
        damping: 0.95,
      );
      expect(features.speed, equals(0.02));
      expect(features.decayRate, equals(0.02));
      expect(features.force, equals(0.8));
      expect(features.maxTouchSpeed, equals(10.0));
      expect(features.damping, equals(0.95));
    });

    test('applies custom TouchFeatures to particle acceleration and decayRate',
        () {
      final p = Particle(
        position: const Offset(100, 100),
        velocity: Offset.zero,
        color: Colors.white,
        size: 2,
      );
      final handler = TouchInteractionHandler(
        particles: [p],
        touchPoint: const Offset(110, 110),
        lineDistance: 100.0,
        touchColor: Colors.amber,
        linePaint: Paint(),
        touchFeatures: const TouchFeatures(
          speed: 0.025,
          force: 1.2,
          maxTouchSpeed: 8.0,
        ),
      );

      final tracker = AccelerationTracker();
      handler.applyTouchPhysics([0], tracker);

      expect(p.wasAccelerated, isTrue);
      expect(p.decayRate, equals(0.025));
      expect(p.velocity.distance, lessThanOrEqualTo(8.0));
    });

    test('equality and hashCode work as expected', () {
      const f1 = TouchFeatures(
        speed: 0.02,
        force: 0.5,
        maxTouchSpeed: 6.0,
        damping: 0.9,
        lineDistance: 80.0,
      );
      const f2 = TouchFeatures(
        speed: 0.02,
        force: 0.5,
        maxTouchSpeed: 6.0,
        damping: 0.9,
        lineDistance: 80.0,
      );
      const f3 = TouchFeatures(
        speed: 0.03,
        force: 0.5,
        maxTouchSpeed: 6.0,
        damping: 0.9,
        lineDistance: 80.0,
      );
      const f4 = TouchFeatures(
        speed: 0.02,
        force: 0.5,
        maxTouchSpeed: 6.0,
        damping: 0.9,
        lineDistance: 120.0,
      );

      expect(f1, equals(f2));
      expect(f1.hashCode, equals(f2.hashCode));
      expect(f1 == f3, isFalse);
      expect(f1 == f4, isFalse);
      expect(f1 == Object(), isFalse);
    });

    test('equality differentiates by color', () {
      const f1 = TouchFeatures(color: Color(0xFFFF0000));
      const f2 = TouchFeatures(color: Color(0xFFFF0000));
      const f3 = TouchFeatures(color: Color(0xFF00FF00));

      expect(f1, equals(f2));
      expect(f1 == f3, isFalse);
    });

    test('toString returns formatted string representation', () {
      const features = TouchFeatures(
        speed: 0.05,
        force: 0.8,
        maxTouchSpeed: 5.0,
        damping: 0.95,
        lineDistance: 100.0,
        color: Color(0xFF123456),
      );
      final str = features.toString();
      expect(str, contains('TouchFeatures'));
      expect(str, contains('speed: 0.05'));
      expect(str, contains('force: 0.8'));
      expect(str, contains('maxTouchSpeed: 5.0'));
      expect(str, contains('damping: 0.95'));
      expect(str, contains('lineDistance: 100.0'));
      expect(str, contains('color: ${const Color(0xFF123456)}'));
    });

    test('lineDistance defaults to null and can be configured', () {
      const defaultFeatures = TouchFeatures();
      expect(defaultFeatures.lineDistance, isNull);

      const customFeatures = TouchFeatures(lineDistance: 150.0);
      expect(customFeatures.lineDistance, equals(150.0));
    });

    test(
        'fastLineRendering and lineRenderer configured correctly and equality works',
        () {
      const f1 = TouchFeatures(
        fastLineRendering: true,
        lineRenderer: LineRenderer.vertices,
      );
      const f2 = TouchFeatures(
        fastLineRendering: true,
        lineRenderer: LineRenderer.vertices,
      );
      const f3 = TouchFeatures(
        fastLineRendering: false,
        lineRenderer: LineRenderer.stroke,
      );

      expect(f1, equals(f2));
      expect(f1.hashCode, equals(f2.hashCode));
      expect(f1 == f3, isFalse);
      expect(f1.fastLineRendering, isTrue);
      expect(f1.lineRenderer, equals(LineRenderer.vertices));

      final copied = f1.copyWith(
          fastLineRendering: false, lineRenderer: LineRenderer.stroke);
      expect(copied.fastLineRendering, isFalse);
      expect(copied.lineRenderer, equals(LineRenderer.stroke));
      expect(f1.toString(), contains('fastLineRendering: true'));
      expect(f1.toString(), contains('lineRenderer: LineRenderer.vertices'));
    });
  });

  group('TouchInteractionHandler - O(K) Spatial Grid & Single Draw Call', () {
    late MockCanvas mockCanvas;

    setUp(() {
      mockCanvas = MockCanvas();
    });

    test(
        'drawTouchLines uses single drawRawPoints call when fastLineRendering is true and LineRenderer.stroke',
        () {
      final p1 = Particle(
        position: const Offset(100, 100),
        velocity: Offset.zero,
        color: Colors.white,
        size: 2,
      );
      final p2 = Particle(
        position: const Offset(110, 105),
        velocity: Offset.zero,
        color: Colors.white,
        size: 2,
      );
      final pFar = Particle(
        position: const Offset(450, 450),
        velocity: Offset.zero,
        color: Colors.white,
        size: 2,
      );

      final particles = [p1, p2, pFar];
      final grid = SortedSpatialGrid()
        ..build(particles, [0, 1, 2], 500, 500, 100);

      final handler = TouchInteractionHandler(
        particles: particles,
        touchPoint: const Offset(105, 105),
        lineDistance: 50.0,
        touchColor: Colors.amber,
        linePaint: Paint()..strokeWidth = 2.0,
        spatialGrid: grid,
        lineRenderer: LineRenderer.stroke,
        fastLineRendering: true,
      );

      handler.drawTouchLines(mockCanvas, [0, 1, 2]);

      // Exactly 1 single draw call for all in-range lines via drawRawPoints
      verify(mockCanvas.drawRawPoints(PointMode.lines, any, any)).called(1);
      verifyNever(mockCanvas.drawLine(any, any, any));
      verifyNever(mockCanvas.drawVertices(any, any, any));
      expect(handler.lastLineCount, equals(2));
    });

    test(
        'drawTouchLines uses single drawVertices call when lineRenderer is LineRenderer.vertices',
        () {
      final p1 = Particle(
        position: const Offset(100, 100),
        velocity: Offset.zero,
        color: Colors.white,
        size: 2,
      );
      final p2 = Particle(
        position: const Offset(115, 110),
        velocity: Offset.zero,
        color: Colors.white,
        size: 2,
      );

      final particles = [p1, p2];
      final grid = SortedSpatialGrid()..build(particles, [0, 1], 500, 500, 100);

      final handler = TouchInteractionHandler(
        particles: particles,
        touchPoint: const Offset(105, 105),
        lineDistance: 50.0,
        touchColor: Colors.amber,
        linePaint: Paint()..strokeWidth = 2.0,
        spatialGrid: grid,
        lineRenderer: LineRenderer.vertices,
        fastLineRendering: true,
      );

      handler.drawTouchLines(mockCanvas, [0, 1]);

      // Single drawVertices call via LineVertexBatch
      verify(mockCanvas.drawVertices(any, any, any)).called(1);
      verifyNever(mockCanvas.drawRawPoints(any, any, any));
      verifyNever(mockCanvas.drawLine(any, any, any));
      expect(handler.lastLineCount, equals(2));
    });

    test(
        'drawTouchLines uses individual drawLine when fastLineRendering is false',
        () {
      final p1 = Particle(
        position: const Offset(100, 100),
        velocity: Offset.zero,
        color: Colors.white,
        size: 2,
      );
      final p2 = Particle(
        position: const Offset(110, 105),
        velocity: Offset.zero,
        color: Colors.white,
        size: 2,
      );

      final particles = [p1, p2];
      final handler = TouchInteractionHandler(
        particles: particles,
        touchPoint: const Offset(105, 105),
        lineDistance: 50.0,
        touchColor: Colors.amber,
        linePaint: Paint(),
        fastLineRendering: false,
      );

      handler.drawTouchLines(mockCanvas, [0, 1]);

      verify(mockCanvas.drawLine(any, any, any)).called(2);
      verifyNever(mockCanvas.drawRawPoints(any, any, any));
      verifyNever(mockCanvas.drawVertices(any, any, any));
      expect(handler.lastLineCount, equals(2));
    });

    test(
        'applyTouchPhysics with SortedSpatialGrid produces identical physics to direct loop',
        () {
      final pDirect = Particle(
        position: const Offset(100, 100),
        velocity: Offset.zero,
        color: Colors.white,
        size: 2,
      );
      final pGrid = Particle(
        position: const Offset(100, 100),
        velocity: Offset.zero,
        color: Colors.white,
        size: 2,
      );

      final trackerDirect = AccelerationTracker();
      final trackerGrid = AccelerationTracker();

      final grid = SortedSpatialGrid()..build([pGrid], [0], 500, 500, 100);

      final handlerDirect = TouchInteractionHandler(
        particles: [pDirect],
        touchPoint: const Offset(110, 110),
        lineDistance: 50.0,
        touchColor: Colors.amber,
        linePaint: Paint(),
      );

      final handlerGrid = TouchInteractionHandler(
        particles: [pGrid],
        touchPoint: const Offset(110, 110),
        lineDistance: 50.0,
        touchColor: Colors.amber,
        linePaint: Paint(),
        spatialGrid: grid,
      );

      handlerDirect.applyTouchPhysics([0], trackerDirect);
      handlerGrid.applyTouchPhysics([0], trackerGrid);

      expect(pGrid.vx, closeTo(pDirect.vx, 1e-6));
      expect(pGrid.vy, closeTo(pDirect.vy, 1e-6));
      expect(pGrid.wasAccelerated, isTrue);
      expect(trackerGrid.acceleratedParticleCount,
          equals(trackerDirect.acceleratedParticleCount));
    });

    test('drawTouchLines safely falls back when grid is null or uninitialized',
        () {
      final p = Particle(
        position: const Offset(100, 100),
        velocity: Offset.zero,
        color: Colors.white,
        size: 2,
      );

      final uninitializedGrid = SortedSpatialGrid(); // cols = 0, rows = 0

      final handler = TouchInteractionHandler(
        particles: [p],
        touchPoint: const Offset(105, 105),
        lineDistance: 50.0,
        touchColor: Colors.amber,
        linePaint: Paint(),
        spatialGrid: uninitializedGrid,
        fastLineRendering: true,
      );

      handler.drawTouchLines(mockCanvas, [0]);

      // Should fall back to direct loop and still draw lines
      verify(mockCanvas.drawRawPoints(PointMode.lines, any, any)).called(1);
      expect(handler.lastLineCount, equals(1));
    });

    test('handles out of bounds touch coordinates gracefully', () {
      final p = Particle(
        position: const Offset(100, 100),
        velocity: Offset.zero,
        color: Colors.white,
        size: 2,
      );

      final grid = SortedSpatialGrid()..build([p], [0], 500, 500, 100);

      final handler = TouchInteractionHandler(
        particles: [p],
        touchPoint: const Offset(-200, -200), // far outside
        lineDistance: 50.0,
        touchColor: Colors.amber,
        linePaint: Paint(),
        spatialGrid: grid,
      );

      handler.drawTouchLines(mockCanvas, [0]);
      verifyZeroInteractions(mockCanvas);
      expect(handler.lastLineCount, equals(0));

      final tracker = AccelerationTracker();
      handler.applyTouchPhysics([0], tracker);
      expect(p.wasAccelerated, isFalse);
    });

    test('buffer expands smoothly when line count exceeds initial capacity',
        () {
      // 80 particles in range to exceed initial 64 capacity
      final particles = List.generate(
        80,
        (i) => Particle(
          position: Offset(100.0 + (i % 5), 100.0 + (i ~/ 5)),
          velocity: Offset.zero,
          color: Colors.white,
          size: 2,
        ),
      );

      final visible = List.generate(80, (i) => i);
      final grid = SortedSpatialGrid()
        ..build(particles, visible, 500, 500, 100);

      final handler = TouchInteractionHandler(
        particles: particles,
        touchPoint: const Offset(100, 100),
        lineDistance: 50.0,
        touchColor: Colors.amber,
        linePaint: Paint(),
        spatialGrid: grid,
        fastLineRendering: true,
      );

      expect(
          () => handler.drawTouchLines(mockCanvas, visible), returnsNormally);
      verify(mockCanvas.drawRawPoints(PointMode.lines, any, any)).called(1);
      expect(handler.lastLineCount, equals(80));
    });

    test(
        'OptimizedNetworkPainter propagates performance and touch settings to handler',
        () {
      final p = Particle(
        position: const Offset(100, 100),
        velocity: Offset.zero,
        color: Colors.white,
        size: 2,
      );

      final painter = OptimizedNetworkPainter(
        drawNetwork: true,
        fill: true,
        particleCount: 1,
        particles: [p],
        touchPoint: const Offset(105, 105),
        lineDistance: 50.0,
        particleColor: Colors.white,
        lineColor: Colors.blue,
        touchActivation: true,
        lineWidth: 1.0,
        fastLineRendering: true,
        lineRenderer: LineRenderer.vertices,
      );

      // In fastLineRendering with LineRenderer.vertices, painter uses drawVertices for touch
      painter.paint(mockCanvas, const Size(500, 500));
      verify(mockCanvas.drawVertices(any, any, any)).called(greaterThan(0));

      // updatePerformanceOptions updates handler
      painter.updatePerformanceOptions(
        fastLineRendering: false,
        lineRenderer: LineRenderer.stroke,
      );
      reset(mockCanvas);

      // Now with fastLineRendering: false and < 30 particles, it draws via drawLine
      painter.paint(mockCanvas, const Size(500, 500));
      verify(mockCanvas.drawLine(any, any, any)).called(greaterThan(0));

      // updateTouchFeatures updates handler overrides
      painter.updateTouchFeatures(const TouchFeatures(
        fastLineRendering: true,
        lineRenderer: LineRenderer.stroke,
      ));
      reset(mockCanvas);

      painter.paint(mockCanvas, const Size(500, 500));
      verify(mockCanvas.drawRawPoints(PointMode.lines, any, any)).called(1);
    });

    test(
        'handles non-finite touch coordinates (NaN / Infinity) without crashing',
        () {
      final p = Particle(
        position: const Offset(100, 100),
        velocity: Offset.zero,
        color: Colors.white,
        size: 2,
      );

      final grid = SortedSpatialGrid()..build([p], [0], 500, 500, 100);

      final handler = TouchInteractionHandler(
        particles: [p],
        touchPoint: const Offset(double.nan, double.nan),
        lineDistance: 50.0,
        touchColor: Colors.amber,
        linePaint: Paint(),
        spatialGrid: grid,
      );

      expect(() => handler.drawTouchLines(mockCanvas, [0]), returnsNormally);
      expect(handler.lastLineCount, equals(0));

      final tracker = AccelerationTracker();
      expect(() => handler.applyTouchPhysics([0], tracker), returnsNormally);
      expect(p.wasAccelerated, isFalse);

      handler.touchPoint = const Offset(double.infinity, 100);
      expect(() => handler.drawTouchLines(mockCanvas, [0]), returnsNormally);
      expect(handler.lastLineCount, equals(0));
      expect(() => handler.applyTouchPhysics([0], tracker), returnsNormally);
    });

    test('rejection of near-boundary negative coordinates via floor check', () {
      final p = Particle(
        position: const Offset(10, 10),
        velocity: Offset.zero,
        color: Colors.white,
        size: 2,
      );

      // Cell size = 50. Columns start at 0.
      final grid = SortedSpatialGrid()..build([p], [0], 500, 500, 50);

      final handler = TouchInteractionHandler(
        particles: [p],
        // tx = -30, maxDist = 20. tx + maxDist = -10. (-10/50).floor() = -1.
        touchPoint: const Offset(-30, -30),
        lineDistance: 20.0,
        touchColor: Colors.amber,
        linePaint: Paint(),
        spatialGrid: grid,
      );

      handler.drawTouchLines(mockCanvas, [0]);
      verifyZeroInteractions(mockCanvas);
      expect(handler.lastLineCount, equals(0));

      final tracker = AccelerationTracker();
      handler.applyTouchPhysics([0], tracker);
      expect(p.wasAccelerated, isFalse);
    });

    test('resets lastLineCount to 0 when touchPoint is null', () {
      final p = Particle(
        position: const Offset(100, 100),
        velocity: Offset.zero,
        color: Colors.white,
        size: 2,
      );

      final grid = SortedSpatialGrid()..build([p], [0], 500, 500, 100);

      final handler = TouchInteractionHandler(
        particles: [p],
        touchPoint: const Offset(102, 102),
        lineDistance: 50.0,
        touchColor: Colors.amber,
        linePaint: Paint(),
        spatialGrid: grid,
      );

      handler.drawTouchLines(mockCanvas, [0]);
      expect(handler.lastLineCount, equals(1));

      handler.touchPoint = null;
      handler.drawTouchLines(mockCanvas, [0]);
      expect(handler.lastLineCount, equals(0));
    });

    test('updating touchColor property updates LUT correctly', () {
      final handler = TouchInteractionHandler(
        particles: [],
        touchPoint: null,
        lineDistance: 50.0,
        touchColor: Colors.amber,
        linePaint: Paint(),
      );

      expect(handler.touchColor, equals(Colors.amber));
      handler.touchColor = Colors.cyan;
      expect(handler.touchColor, equals(Colors.cyan));
    });

    test('direct fallback gracefully skips out of bounds particle indices', () {
      final p = Particle(
        position: const Offset(100, 100),
        velocity: Offset.zero,
        color: Colors.white,
        size: 2,
      );

      final handler = TouchInteractionHandler(
        particles: [p],
        touchPoint: const Offset(105, 105),
        lineDistance: 50.0,
        touchColor: Colors.amber,
        linePaint: Paint(),
        spatialGrid: null, // force direct fallback
      );

      // index 99 is out of bounds for a list of 1 particle
      expect(
          () => handler.drawTouchLines(mockCanvas, [0, 99]), returnsNormally);
      expect(handler.lastLineCount, equals(1));

      final tracker = AccelerationTracker();
      expect(
          () => handler.applyTouchPhysics([0, 99], tracker), returnsNormally);
      expect(p.wasAccelerated, isTrue);
    });

    test(
        'OptimizedNetworkPainter respects TouchFeatures lineRenderer in constructor',
        () {
      final p = Particle(
        position: const Offset(100, 100),
        velocity: Offset.zero,
        color: Colors.white,
        size: 2,
      );

      final painter = OptimizedNetworkPainter(
        drawNetwork: false,
        fill: true,
        particleCount: 1,
        particles: [p],
        touchPoint: const Offset(105, 105),
        lineDistance: 50.0,
        particleColor: Colors.white,
        lineColor: Colors.blue,
        touchActivation: true,
        lineWidth: 1.0,
        fastLineRendering: true,
        lineRenderer: LineRenderer.stroke, // painter default
        touchFeatures: const TouchFeatures(
          lineRenderer: LineRenderer.vertices, // touch feature override
        ),
      );

      painter.paint(mockCanvas, const Size(500, 500));
      // Should draw vertices because touchFeatures.lineRenderer overrides painter.lineRenderer
      verify(mockCanvas.drawVertices(any, any, any)).called(1);
    });
  });
}

// فئة CustomPainter لاختبار الرسم
class TestPainter extends CustomPainter {
  final TouchInteractionHandler handler;

  TestPainter({required this.handler});

  @override
  void paint(Canvas canvas, Size size) {
    handler.drawTouchLines(canvas, [0, 1]);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
