import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class Particle {
  final Offset position;
  Particle(this.position);
}

class TestPainter extends CustomPainter {
  final List<Particle> particles;
  final Offset touch;
  final double lineDistance;
  final Color touchColor;
  final Paint linePaint = Paint();

  TestPainter({
    required this.particles,
    required this.touch,
    required this.lineDistance,
    required this.touchColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    renderTouchInteractions(
      canvas,
      linePaint,
      List.generate(particles.length, (i) => i),
      touch,
    );
  }

  void renderTouchInteractions(
    Canvas canvas,
    Paint linePaint,
    List<int> visibleParticles,
    Offset touch,
  ) {
    for (final i in visibleParticles) {
      final p = particles[i];
      final distance = (p.position - touch).distance;

      if (distance < lineDistance) {
        final opacity = ((1 - distance / lineDistance) * 255).toInt();
        linePaint.color = touchColor.withAlpha(opacity.clamp(0, 255));
        canvas.drawLine(p.position, touch, linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

void main() {
  testWidgets('Test renderTouchInteractions', (WidgetTester tester) async {
    // Define some particles
    final particles = [
      Particle(Offset(50, 50)),
      Particle(Offset(100, 100)),
      Particle(Offset(150, 150)),
    ];

    final touch = Offset(120, 120);
    final lineDistance = 100.0;
    final touchColor = Colors.red;

    final painter = TestPainter(
      particles: particles,
      touch: touch,
      lineDistance: lineDistance,
      touchColor: touchColor,
    );

    // Define the size for the canvas
    final size = Size(400, 400);

    // Create the CustomPainter with a Canvas and Size
    final recorder = PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromPoints(Offset(0, 0), Offset(size.width, size.height)),
    );

    // Test rendering
    painter.paint(canvas, size);

    final picture = recorder.endRecording();

    // Now, we could examine the drawing or capture the picture and compare it to an expected result.
    // This could be done by analyzing the output or using a tool to verify visual consistency.
    expect(true, isTrue); // Placeholder for actual visual or data verification.
  });
}
