import 'dart:ui';

import 'package:particles_network/model/particlemodel.dart';

/// فئة للتعامل مع تفاعل اللمس
class TouchInteractionHandler {
  final List<Particle> particles;
  final Offset? touchPoint;
  final double lineDistance;
  final Color touchColor;
  final Paint linePaint;

  TouchInteractionHandler({
    required this.particles,
    required this.touchPoint,
    required this.lineDistance,
    required this.touchColor,
    required this.linePaint,
  });

  final int test = 00;

  /// تطبيق فيزياء تفاعل اللمس على الجسيمات
  void applyTouchPhysics(List<int> visibleParticles) {
    final touch = touchPoint;
    if (touch == null) return;

    for (final i in visibleParticles) {
      final p = particles[i];
      final distance = (p.position - touch).distance - test;

      if (distance < lineDistance) {
        const double force = 0.00111;
        final pull = (touch - p.position) * force;
        p.velocity += pull;
        p.wasAccelerated = true;
      }
    }
  }

  /// رسم خطوط تفاعل اللمس
  void drawTouchLines(Canvas canvas, List<int> visibleParticles) {
    final touch = touchPoint;
    if (touch == null) return;

    for (final i in visibleParticles) {
      final p = particles[i];
      final distance = (p.position - touch).distance - test;

      if (distance < lineDistance) {
        final opacity = ((1 - distance / lineDistance) * 255).toInt();
        linePaint.color = touchColor.withAlpha(opacity.clamp(0, 255));
        canvas.drawLine(p.position, touch, linePaint);
      }
    }
  }
}
