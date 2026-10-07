import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/particles_network.dart';

void main() {
  group('AdaptivePerformanceController Tests', () {
    late AdaptivePerformanceController controller;

    setUp(() {
      controller = AdaptivePerformanceController();
    });

    test('initializes with default quality scale of 1.0', () {
      expect(controller.scaleFactor, equals(1.0));
      expect(controller.targetFrameTimeMs, closeTo(16.67, 0.01));
      expect(controller.minScale, equals(0.4));
      expect(controller.maxScale, equals(1.0));
    });

    test('getAdjustedLineDistance returns proportional distance', () {
      expect(controller.getAdjustedLineDistance(100.0), equals(100.0));
    });

    test('getAdjustedMaxConnections clamps to minimum of 1', () {
      expect(controller.getAdjustedMaxConnections(4), equals(4));
    });

    test('reduces scaleFactor when frame times consistently exceed budget', () {
      // 3 consecutive frames exceeding targetFrameTimeMs * 1.25 (16.67 * 1.25 = 20.83ms)
      controller.recordFrameTime(const Duration(milliseconds: 25));
      controller.recordFrameTime(const Duration(milliseconds: 25));
      controller.recordFrameTime(const Duration(milliseconds: 25));

      expect(controller.scaleFactor, closeTo(0.9, 0.001));
      expect(controller.getAdjustedLineDistance(100.0), closeTo(90.0, 0.001));
    });

    test('clamps scaleFactor to minScale during severe degradation', () {
      for (int i = 0; i < 30; i++) {
        controller.recordFrameTime(const Duration(milliseconds: 35));
      }

      expect(controller.scaleFactor, equals(0.4));
      expect(controller.getAdjustedLineDistance(100.0), equals(40.0));
      expect(controller.getAdjustedMaxConnections(5), equals(2));
    });

    test('recovers scaleFactor when performance returns to smooth 60 FPS', () {
      // Force down to minScale
      for (int i = 0; i < 30; i++) {
        controller.recordFrameTime(const Duration(milliseconds: 35));
      }
      expect(controller.scaleFactor, equals(0.4));

      // 15 consecutive smooth frames (< 14ms)
      for (int i = 0; i < 15; i++) {
        controller.recordFrameTime(const Duration(milliseconds: 8));
      }

      expect(controller.scaleFactor, closeTo(0.45, 0.001));
    });

    test('reset restores initial scale and clears monitor', () {
      controller.recordFrameTime(const Duration(milliseconds: 35));
      controller.recordFrameTime(const Duration(milliseconds: 35));
      controller.recordFrameTime(const Duration(milliseconds: 35));
      expect(controller.scaleFactor, lessThan(1.0));

      controller.reset();

      expect(controller.scaleFactor, equals(1.0));
      expect(controller.monitor.recordedFrameCount, equals(0));
    });
    test('normal frame times reset consecutive drop and smooth counters (L176-L179)', () {
      // 2 consecutive dropped frames (> 20.83ms)
      controller.recordFrameTime(const Duration(milliseconds: 25));
      controller.recordFrameTime(const Duration(milliseconds: 25));

      // Normal frame within [14.17ms, 20.83ms] (16ms) triggers the else branch (L176-L179)
      controller.recordFrameTime(const Duration(milliseconds: 16));

      // Another dropped frame: since consecutiveDrops was reset to 0, count is now 1 (< 3)
      // and scaleFactor should remain 1.0 (not step down to 0.9)
      controller.recordFrameTime(const Duration(milliseconds: 25));
      expect(controller.scaleFactor, equals(1.0));

      // Force scale down to 0.9
      controller.recordFrameTime(const Duration(milliseconds: 25));
      controller.recordFrameTime(const Duration(milliseconds: 25));
      expect(controller.scaleFactor, closeTo(0.9, 0.001));

      // 10 smooth frames (< 14.17ms)
      for (int i = 0; i < 10; i++) {
        controller.recordFrameTime(const Duration(milliseconds: 10));
      }

      // Normal frame resets consecutiveSmooth to 0 (L176-L179)
      controller.recordFrameTime(const Duration(milliseconds: 16));

      // 10 more smooth frames: total smooth after reset is 10 (< 15), so scale does not recover yet
      for (int i = 0; i < 10; i++) {
        controller.recordFrameTime(const Duration(milliseconds: 10));
      }
      expect(controller.scaleFactor, closeTo(0.9, 0.001));
    });
  });
}
