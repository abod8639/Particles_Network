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
    test(
        'normal frame times reset consecutive drop and smooth counters (L176-L179)',
        () {
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

    test('EMA tracks exponential moving average of frame times', () {
      final custom = AdaptivePerformanceController(
        targetFrameTimeMs: 16.67,
        emaWeight: 0.2,
      );

      // Initially equals targetFrameTimeMs
      expect(custom.emaFrameTimeMs, closeTo(16.67, 0.01));

      // First sample initializes EMA directly
      custom.recordFrameTime(const Duration(milliseconds: 20));
      expect(custom.emaFrameTimeMs, closeTo(20.0, 0.001));

      // Second sample applies EMA smoothing: 0.2 * 30 + 0.8 * 20 = 6 + 16 = 22
      custom.recordFrameTime(const Duration(milliseconds: 30));
      expect(custom.emaFrameTimeMs, closeTo(22.0, 0.001));

      // Reset clears EMA back to default targetFrameTimeMs
      custom.reset();
      expect(custom.emaFrameTimeMs, closeTo(16.67, 0.01));
    });

    test('exposes hysteresis thresholds for dropped and smooth frames', () {
      expect(controller.dropThresholdMs, closeTo(16.67 * 1.25, 0.01));
      expect(controller.smoothThresholdMs, closeTo(16.67 * 0.85, 0.01));
    });

    group('autoBoost dynamic scaling', () {
      late AdaptivePerformanceController boostController;

      setUp(() {
        boostController = AdaptivePerformanceController(
          autoBoost: true,
        );
      });

      test('initializes with maxScale of 2.5 when autoBoost is true', () {
        expect(boostController.autoBoost, isTrue);
        expect(boostController.maxScale, equals(2.5));
        expect(boostController.scaleFactor, equals(1.0));
      });

      test('scales up beyond 1.0 during sustained smooth frames', () {
        // Feed smooth frames with low latency (e.g. 5ms, well under 60% of budget)
        for (int i = 0; i < 8; i++) {
          boostController.recordFrameTime(const Duration(milliseconds: 5));
        }
        expect(boostController.scaleFactor, closeTo(1.05, 0.001));

        for (int i = 0; i < 8; i++) {
          boostController.recordFrameTime(const Duration(milliseconds: 5));
        }
        expect(boostController.scaleFactor, closeTo(1.10, 0.001));
      });

      test('getAdjustedMaxConnections scales up beyond base in autoBoost mode',
          () {
        // Initially at scale 1.0
        expect(boostController.getAdjustedMaxConnections(4), equals(4));

        // Boost scale to ~1.5
        for (int step = 0; step < 10; step++) {
          for (int i = 0; i < 8; i++) {
            boostController.recordFrameTime(const Duration(milliseconds: 5));
          }
        }
        expect(boostController.scaleFactor, closeTo(1.5, 0.01));
        // 4 * 1.5 = 6 connections
        expect(boostController.getAdjustedMaxConnections(4), equals(6));
      });

      test('getAutoMaxConnections dynamically computes connections with cap',
          () {
        expect(boostController.getAutoMaxConnections(base: 6), equals(6));

        // Boost scale to 2.0
        for (int step = 0; step < 20; step++) {
          for (int i = 0; i < 8; i++) {
            boostController.recordFrameTime(const Duration(milliseconds: 4));
          }
        }
        expect(boostController.scaleFactor, closeTo(2.0, 0.01));
        // 6 * 2.0 = 12 connections
        expect(boostController.getAutoMaxConnections(base: 6), equals(12));
      });

      test('getAdjustedMaxLines scales line budget proportionally', () {
        expect(boostController.getAdjustedMaxLines(15000), equals(15000));

        // Boost scale to 1.5
        for (int step = 0; step < 10; step++) {
          for (int i = 0; i < 8; i++) {
            boostController.recordFrameTime(const Duration(milliseconds: 5));
          }
        }
        expect(boostController.getAdjustedMaxLines(15000), equals(22500));
      });

      test('getAdjustedLineDistance clamps to 1.0 baseDistance during boost',
          () {
        expect(boostController.getAdjustedLineDistance(100.0), equals(100.0));

        // Boost scale to 2.0
        for (int step = 0; step < 20; step++) {
          for (int i = 0; i < 8; i++) {
            boostController.recordFrameTime(const Duration(milliseconds: 4));
          }
        }
        expect(boostController.scaleFactor, closeTo(2.0, 0.01));
        // Line distance should not stretch beyond configured base distance
        expect(boostController.getAdjustedLineDistance(100.0), equals(100.0));
      });

      test(
          'getAutoMaxConnections scales to high numbers when headroom and maxScale allow',
          () {
        final highBoost = AdaptivePerformanceController(
          autoBoost: true,
          maxScale: 20.0,
        );

        expect(
            highBoost.getAutoMaxConnections(base: 6, maxCap: 100), equals(6));

        // Boost scale to 10.0 (180 smooth steps of 0.05)
        for (int step = 0; step < 180; step++) {
          for (int i = 0; i < 8; i++) {
            highBoost.recordFrameTime(const Duration(milliseconds: 3));
          }
        }
        expect(highBoost.scaleFactor, closeTo(10.0, 0.01));
        // 6 * 10.0 = 60 connections (well above the old 15 limit)
        expect(
            highBoost.getAutoMaxConnections(base: 6, maxCap: 100), equals(60));
      });

      test('steps down scale when dropped frames occur even after boosting',
          () {
        // Boost up to 1.10
        for (int i = 0; i < 16; i++) {
          boostController.recordFrameTime(const Duration(milliseconds: 5));
        }
        expect(boostController.scaleFactor, closeTo(1.10, 0.001));

        // 3 dropped frames (> 20.83ms)
        boostController.recordFrameTime(const Duration(milliseconds: 25));
        boostController.recordFrameTime(const Duration(milliseconds: 25));
        boostController.recordFrameTime(const Duration(milliseconds: 25));

        expect(boostController.scaleFactor, closeTo(1.00, 0.001));
      });
    });
  });
}
