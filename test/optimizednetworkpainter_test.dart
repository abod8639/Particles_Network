import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/model/particlemodel.dart';
import 'package:particles_network/painter/optimized_network_painter.dart';

class MockParticle extends Particle {
  MockParticle({
    required super.position,
    super.velocity = Offset.zero,
    super.color = Colors.white,
    super.size = 1.0,
    bool wasAccelerated = false,
  });

  void accelerate() {
    wasAccelerated = true;
  }
}

void main() {
  group('OptimizedNetworkPainter', () {
    test('shouldRepaint returns true if touchPoint changed', () {
      final p = MockParticle(position: Offset(0, 0));

      final oldPainter = OptimizedNetworkPainter(
        isComplex: false,
        particleCount: 1,
        particles: [p],
        touchPoint: const Offset(0, 0),
        lineDistance: 100,
        particleColor: Colors.white,
        lineColor: Colors.grey,
        touchColor: Colors.red,
        touchActivation: true,
        linewidth: 1.0,
      );

      final newPainter = OptimizedNetworkPainter(
        isComplex: false,
        particleCount: 1,
        particles: [p],
        touchPoint: const Offset(5, 5), // تغيرت نقطة اللمس
        lineDistance: 100,
        particleColor: Colors.white,
        lineColor: Colors.grey,
        touchColor: Colors.red,
        touchActivation: true,
        linewidth: 1.0,
      );

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('shouldRepaint returns true if any particle was accelerated', () {
      final p = MockParticle(position: Offset(0, 0));
      final p2 = MockParticle(position: Offset(10, 10));

      final oldPainter = OptimizedNetworkPainter(
        isComplex: false,
        particleCount: 2,
        particles: [p, p2],
        touchPoint: null,
        lineDistance: 100,
        particleColor: Colors.white,
        lineColor: Colors.grey,
        touchColor: Colors.red,
        touchActivation: true,
        linewidth: 1.0,
      );

      // نقوم بتسريع أحد الجسيمات
      p2.accelerate();

      final newPainter = OptimizedNetworkPainter(
        isComplex: false,
        particleCount: 2,
        particles: [p, p2],
        touchPoint: null,
        lineDistance: 100,
        particleColor: Colors.white,
        lineColor: Colors.grey,
        touchColor: Colors.red,
        touchActivation: true,
        linewidth: 1.0,
      );

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('shouldRepaint returns false if nothing changed', () {
      final p = MockParticle(position: Offset(0, 0));

      final painter1 = OptimizedNetworkPainter(
        isComplex: false,
        particleCount: 1,
        particles: [p],
        touchPoint: null,
        lineDistance: 100,
        particleColor: Colors.white,
        lineColor: Colors.grey,
        touchColor: Colors.red,
        touchActivation: true,
        linewidth: 1.0,
      );

      final painter2 = OptimizedNetworkPainter(
        isComplex: false,
        particleCount: 1,
        particles: [p],
        touchPoint: null,
        lineDistance: 100,
        particleColor: Colors.white,
        lineColor: Colors.grey,
        touchColor: Colors.red,
        touchActivation: true,
        linewidth: 1.0,
      );

      expect(painter2.shouldRepaint(painter1), isFalse);
    });
  });
}
