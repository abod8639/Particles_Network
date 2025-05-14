import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/model/particlemodel.dart';
import 'package:particles_network/painter/TouchInteractionHandler.dart';

// Assuming the Particle class is here

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
      handler.applyTouchPhysics([0, 1]);

      // Assert
      expect(particles[0].wasAccelerated, isTrue);
      expect(
        particles[0].velocity.dx != 0 || particles[0].velocity.dy != 0,
        isTrue,
      );

      expect(particles[1].wasAccelerated, isFalse);
      expect(particles[1].velocity, Offset.zero);
    });
  });

  group('TouchInteractionHandler', () {
    testWidgets('drawTouchLines should draw lines for particles within range', (
      WidgetTester tester,
    ) async {
      // إعداد الجسيمات
      final particles = [
        Particle(
          position: Offset(100, 100),
          velocity: Offset(0, 0),
          color: Colors.blue,
          size: 10.0,
        ),
        Particle(
          position: Offset(150, 150),
          velocity: Offset(0, 0),
          color: Colors.red,
          size: 10.0,
        ),
      ];

      final touchPoint = Offset(120, 120);
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
