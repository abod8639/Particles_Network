import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
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

class MockBuildContext extends Mock implements BuildContext {}

void main() {
  late BuildContext mockContext;
  late MockParticle particle;
  late OptimizedNetworkPainter defaultPainter;

  setUp(() {
    mockContext = MockBuildContext();
    particle = MockParticle(position: const Offset(0, 0));
    defaultPainter = OptimizedNetworkPainter(
      context: mockContext,
      drawnetwork: true,
      fill: true,
      isComplex: false,
      particleCount: 1,
      particles: [particle],
      touchPoint: null,
      lineDistance: 100,
      particleColor: Colors.white,
      lineColor: Colors.grey,
      touchColor: Colors.red,
      touchActivation: true,
      linewidth: 1.0,
    );
  });

  group('OptimizedNetworkPainter Initialization', () {
    test('initializes with default values', () {
      expect(defaultPainter.particleCount, equals(1));
      expect(defaultPainter.lineDistance, equals(100));
      expect(defaultPainter.particleColor, equals(Colors.white));
      expect(defaultPainter.lineColor, equals(Colors.grey));
      expect(defaultPainter.touchColor, equals(Colors.red));
      expect(defaultPainter.touchActivation, isTrue);
      expect(defaultPainter.linewidth, equals(1.0));
      expect(defaultPainter.fill, isTrue);
      expect(defaultPainter.drawnetwork, isTrue);
      expect(defaultPainter.showQuadTree, isFalse);
    });

    test('handles null touchPoint gracefully', () {
      final painter = OptimizedNetworkPainter(
        context: mockContext,
        drawnetwork: true,
        fill: true,
        isComplex: false,
        particleCount: 1,
        particles: [particle],
        touchPoint: null,
        lineDistance: 100,
        particleColor: Colors.white,
        lineColor: Colors.grey,
        touchColor: Colors.red,
        touchActivation: true,
        linewidth: 1.0,
      );

      expect(painter.touchPoint, isNull);
    });
  });

  group('ShouldRepaint Tests', () {
    test('returns true when touchPoint changes', () {
      final newPainter = OptimizedNetworkPainter(
        context: mockContext,
        drawnetwork: true,
        fill: true,
        isComplex: false,
        particleCount: 1,
        particles: [particle],
        touchPoint: const Offset(5, 5),
        lineDistance: 100,
        particleColor: Colors.white,
        lineColor: Colors.grey,
        touchColor: Colors.red,
        touchActivation: true,
        linewidth: 1.0,
      );

      expect(newPainter.shouldRepaint(defaultPainter), isTrue);
    });

    test('returns true when particle is accelerated', () {
      final p1 = MockParticle(position: const Offset(0, 0));
      final p2 = MockParticle(position: const Offset(10, 10));

      final oldPainter = OptimizedNetworkPainter(
        context: mockContext,
        drawnetwork: true,
        fill: true,
        isComplex: false,
        particleCount: 2,
        particles: [p1, p2],
        touchPoint: null,
        lineDistance: 100,
        particleColor: Colors.white,
        lineColor: Colors.grey,
        touchColor: Colors.red,
        touchActivation: true,
        linewidth: 1.0,
      );

      p2.accelerate();

      final newPainter = OptimizedNetworkPainter(
        context: mockContext,
        drawnetwork: true,
        fill: true,
        isComplex: false,
        particleCount: 2,
        particles: [p1, p2],
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

    test('returns true when line distance changes', () {
      final newPainter = OptimizedNetworkPainter(
        context: mockContext,
        drawnetwork: true,
        fill: true,
        isComplex: false,
        particleCount: 1,
        particles: [particle],
        touchPoint: null,
        lineDistance: 150, // Changed line distance
        particleColor: Colors.white,
        lineColor: Colors.grey,
        touchColor: Colors.red,
        touchActivation: true,
        linewidth: 1.0,
      );

      expect(newPainter.shouldRepaint(defaultPainter), isTrue);
    });

    test('returns true when colors change', () {
      final newPainter = OptimizedNetworkPainter(
        context: mockContext,
        drawnetwork: true,
        fill: true,
        isComplex: false,
        particleCount: 1,
        particles: [particle],
        touchPoint: null,
        lineDistance: 100,
        particleColor: Colors.blue, // Changed particle color
        lineColor: Colors.green, // Changed line color
        touchColor: Colors.red,
        touchActivation: true,
        linewidth: 1.0,
      );

      expect(newPainter.shouldRepaint(defaultPainter), isTrue);
    });

    test('returns false when no relevant properties change', () {
      final newPainter = OptimizedNetworkPainter(
        context: mockContext,
        drawnetwork: true,
        fill: true,
        isComplex: false,
        particleCount: 1,
        particles: [particle],
        touchPoint: null,
        lineDistance: 100,
        particleColor: Colors.white,
        lineColor: Colors.grey,
        touchColor: Colors.red,
        touchActivation: true,
        linewidth: 1.0,
      );

      expect(newPainter.shouldRepaint(defaultPainter), isFalse);
    });
  });

  group('Drawing Behavior Tests', () {
    test('respects drawnetwork flag', () {
      final painter = OptimizedNetworkPainter(
        context: mockContext,
        drawnetwork: false,
        fill: true,
        isComplex: false,
        particleCount: 1,
        particles: [particle],
        touchPoint: null,
        lineDistance: 100,
        particleColor: Colors.white,
        lineColor: Colors.grey,
        touchColor: Colors.red,
        touchActivation: true,
        linewidth: 1.0,
      );

      expect(painter.drawnetwork, isFalse);
    });

    test('respects fill style', () {
      final painter = OptimizedNetworkPainter(
        context: mockContext,
        drawnetwork: true,
        fill: false,
        isComplex: false,
        particleCount: 1,
        particles: [particle],
        touchPoint: null,
        lineDistance: 100,
        particleColor: Colors.white,
        lineColor: Colors.grey,
        touchColor: Colors.red,
        touchActivation: true,
        linewidth: 1.0,
      );

      expect(painter.fill, isFalse);
    });
  });
}
