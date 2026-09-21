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

    test('clamps velocity to maxTouchSpeed when speedSq > maxTouchSpeedSq (L113-L117)', () {
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
  });

  group('TouchInteractionHandler', () {
    test('drawTouchLines returns immediately when touchPoint is null (L136)', () {
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
  });

  group('TouchFeatures', () {
    test('default values are set correctly', () {
      const features = TouchFeatures();
      expect(features.speed, equals(0.012));
      expect(features.decayRate, equals(0.012));
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

    test('applies custom TouchFeatures to particle acceleration and decayRate', () {
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

    test('lineDistance defaults to null and can be configured', () {
      const defaultFeatures = TouchFeatures();
      expect(defaultFeatures.lineDistance, isNull);

      const customFeatures = TouchFeatures(lineDistance: 150.0);
      expect(customFeatures.lineDistance, equals(150.0));
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
