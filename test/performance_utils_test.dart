// ignore_for_file: deprecated_member_use
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/particles_network.dart';

void main() {
  group('AccelerationTracker', () {
    late AccelerationTracker tracker;

    setUp(() {
      tracker = AccelerationTracker();
    });

    test('initializes with zero acceleration count', () {
      expect(tracker.acceleratedParticleCount, equals(0));
      expect(tracker.hadAcceleratedParticles, isFalse);
    });

    test('recordAcceleration increments the counter', () {
      tracker.recordAcceleration();
      expect(tracker.acceleratedParticleCount, equals(1));

      tracker.recordAcceleration();
      expect(tracker.acceleratedParticleCount, equals(2));
    });

    test('resetFrame moves current count to last frame count', () {
      tracker.recordAcceleration();
      tracker.recordAcceleration();
      tracker.recordAcceleration();

      expect(tracker.acceleratedParticleCount, equals(3));
      expect(tracker.lastFrameAcceleratedCount, equals(0));

      tracker.resetFrame();

      expect(tracker.acceleratedParticleCount, equals(0));
      expect(tracker.lastFrameAcceleratedCount, equals(3));
      expect(tracker.hadAcceleratedParticles, isTrue);
    });

    test('hadAcceleratedParticles reflects last frame state', () {
      expect(tracker.hadAcceleratedParticles, isFalse);

      tracker.recordAcceleration();
      tracker.resetFrame();

      expect(tracker.hadAcceleratedParticles, isTrue);

      tracker.resetFrame(); // Reset with no new accelerations
      expect(tracker.hadAcceleratedParticles, isFalse);
    });

    test('handles multiple frame cycles correctly', () {
      // Frame 1: 5 accelerations
      for (int i = 0; i < 5; i++) {
        tracker.recordAcceleration();
      }
      tracker.resetFrame();
      expect(tracker.lastFrameAcceleratedCount, equals(5));
      expect(tracker.acceleratedParticleCount, equals(0));

      // Frame 2: 3 new accelerations
      for (int i = 0; i < 3; i++) {
        tracker.recordAcceleration();
      }
      tracker.resetFrame();
      expect(tracker.lastFrameAcceleratedCount, equals(3));
      expect(tracker.acceleratedParticleCount, equals(0));
    });
  });

  group('PerformanceMonitor', () {
    late PerformanceMonitor monitor;

    setUp(() {
      monitor = PerformanceMonitor();
    });

    test('initializes with empty frame times', () {
      expect(monitor.recordedFrameCount, equals(0));
      expect(monitor.averageFrameTime, isNull);
      expect(monitor.isDroppingFrames(), isFalse);
    });

    test('isDroppingFrames returns false when averageFrameTime is null', () {
      // Empty monitor initially has avg == null
      expect(monitor.averageFrameTime, isNull);
      expect(monitor.isDroppingFrames(), isFalse);

      // Record slow frame to make it true
      monitor.recordFrameTime(const Duration(milliseconds: 30));
      expect(monitor.isDroppingFrames(), isTrue);

      // Clear empties frames so avg becomes null again
      monitor.clear();
      expect(monitor.averageFrameTime, isNull);
      expect(monitor.isDroppingFrames(), isFalse);
    });

    test('recordFrameTime adds durations', () {
      monitor.recordFrameTime(const Duration(milliseconds: 16));
      expect(monitor.recordedFrameCount, equals(1));

      monitor.recordFrameTime(const Duration(milliseconds: 17));
      expect(monitor.recordedFrameCount, equals(2));
    });

    test('averageFrameTime calculates correct average', () {
      monitor.recordFrameTime(const Duration(milliseconds: 16));
      monitor.recordFrameTime(const Duration(milliseconds: 18));
      monitor.recordFrameTime(const Duration(milliseconds: 14));

      final average = monitor.averageFrameTime;
      expect(average, isNotNull);
      expect(average!.inMilliseconds, equals(16)); // (16+18+14)/3 = 16
    });

    test('isDroppingFrames returns false at 60 FPS', () {
      // 60 FPS = ~16.67ms per frame
      for (int i = 0; i < 10; i++) {
        monitor.recordFrameTime(const Duration(milliseconds: 16));
      }

      expect(monitor.isDroppingFrames(), isFalse);
    });

    test('isDroppingFrames returns true below 50 FPS', () {
      // Below 50 FPS = > 20ms per frame
      for (int i = 0; i < 10; i++) {
        monitor.recordFrameTime(const Duration(milliseconds: 25));
      }

      expect(monitor.isDroppingFrames(), isTrue);
    });

    test('isDroppingFrames with mixed frame times', () {
      // Mix of good and bad frames
      monitor.recordFrameTime(const Duration(milliseconds: 15));
      monitor.recordFrameTime(const Duration(milliseconds: 16));
      monitor.recordFrameTime(const Duration(milliseconds: 50)); // Bad frame
      monitor.recordFrameTime(const Duration(milliseconds: 16));

      // Average: (15+16+50+16)/4 = 24.25ms > 20ms
      expect(monitor.isDroppingFrames(), isTrue);
    });

    test('sample window maintains max size', () {
      const maxSize = 60;
      final frameTimes = List<Duration>.filled(
        maxSize + 20,
        const Duration(milliseconds: 16),
      );

      for (final time in frameTimes) {
        monitor.recordFrameTime(time);
      }

      expect(monitor.recordedFrameCount, lessThanOrEqualTo(maxSize));
    });

    test('clear removes all recorded times', () {
      monitor.recordFrameTime(const Duration(milliseconds: 16));
      monitor.recordFrameTime(const Duration(milliseconds: 17));

      expect(monitor.recordedFrameCount, equals(2));

      monitor.clear();

      expect(monitor.recordedFrameCount, equals(0));
      expect(monitor.averageFrameTime, isNull);
    });

    test('performance degradation detection', () {
      // Start with good frames
      for (int i = 0; i < 30; i++) {
        monitor.recordFrameTime(const Duration(milliseconds: 16));
      }
      expect(monitor.isDroppingFrames(), isFalse);

      // Add degrading frames
      for (int i = 0; i < 30; i++) {
        monitor.recordFrameTime(const Duration(milliseconds: 22));
      }

      // Window keeps last 60 frames
      // Last 30 are 22ms each, previous 30 are 16ms each
      // Average: (30*16 + 30*22) / 60 = 19ms, which is < 20, but close
      // Let's make it clearer
      monitor.clear();
      for (int i = 0; i < 60; i++) {
        monitor.recordFrameTime(const Duration(milliseconds: 25));
      }

      expect(monitor.isDroppingFrames(), isTrue);
    });

    test('single frame time calculations', () {
      monitor.recordFrameTime(const Duration(milliseconds: 50));

      expect(monitor.recordedFrameCount, equals(1));
      expect(monitor.averageFrameTime!.inMilliseconds, equals(50));
      expect(monitor.isDroppingFrames(), isTrue);
    });
  });

  group('Integration Tests', () {
    test('tracker records acceleration and resets frame correctly', () {
      final tracker = AccelerationTracker();
      tracker.recordAcceleration();
      expect(tracker.acceleratedParticleCount, equals(1));
      tracker.resetFrame();
      expect(tracker.hadAcceleratedParticles, isTrue);
      expect(tracker.lastFrameAcceleratedCount, equals(1));
    });

    test('full performance monitoring cycle', () {
      final tracker = AccelerationTracker();
      final monitor = PerformanceMonitor();

      // Simulate 10 frames
      for (int frame = 0; frame < 10; frame++) {
        // Simulate some work
        if (frame % 2 == 0) {
          tracker.recordAcceleration();
        }

        // Simulate frame time: 16ms for good frames, 25ms for frame 7
        final frameTime = frame == 7 ? 25 : 16;
        monitor.recordFrameTime(Duration(milliseconds: frameTime));

        if (frame % 3 == 0) {
          tracker.resetFrame();
        }
      }

      expect(monitor.recordedFrameCount, equals(10));
      // Average with most frames at 16ms and one at 25ms = ~17.9ms < 20ms
      expect(monitor.isDroppingFrames(), isFalse); // Single spike not enough
    });
  });

  group('AdaptiveQuadTreeManager', () {
    test('initializes with default rebuildInterval and frame counter', () {
      final manager = AdaptiveQuadTreeManager();
      expect(manager.rebuildInterval, equals(3));
      expect(manager.frameSinceLastRebuild, equals(3));
    });

    test('rebuildInterval can be configured', () {
      final manager = AdaptiveQuadTreeManager(rebuildInterval: 5);
      expect(manager.rebuildInterval, equals(5));
      expect(manager.frameSinceLastRebuild, equals(5));
    });

    test('shouldRebuild returns true initially and follows intervals', () {
      final manager = AdaptiveQuadTreeManager(rebuildInterval: 3);

      // Initial call: frameSinceLastRebuild starts at 3, increments to 4 (>= 3), resets to 0, returns true
      expect(manager.shouldRebuild(), isTrue);
      expect(manager.frameSinceLastRebuild, equals(0));

      // Frame 1: increments to 1 (< 3) -> false
      expect(manager.shouldRebuild(), isFalse);
      expect(manager.frameSinceLastRebuild, equals(1));

      // Frame 2: increments to 2 (< 3) -> false
      expect(manager.shouldRebuild(), isFalse);
      expect(manager.frameSinceLastRebuild, equals(2));

      // Frame 3: increments to 3 (>= 3) -> resets to 0, returns true
      expect(manager.shouldRebuild(), isTrue);
      expect(manager.frameSinceLastRebuild, equals(0));
    });

    test(
      'forceRebuild triggers immediate rebuild on next shouldRebuild call',
      () {
        final manager = AdaptiveQuadTreeManager(rebuildInterval: 5);

        // Consume initial rebuild
        expect(manager.shouldRebuild(), isTrue);
        expect(manager.frameSinceLastRebuild, equals(0));

        // Advance one frame
        expect(manager.shouldRebuild(), isFalse);
        expect(manager.frameSinceLastRebuild, equals(1));

        // Force rebuild
        manager.forceRebuild();

        // Next call must rebuild immediately regardless of interval
        expect(manager.shouldRebuild(), isTrue);
        expect(manager.frameSinceLastRebuild, equals(0));

        // Subsequent frame resumes normal counting
        expect(manager.shouldRebuild(), isFalse);
        expect(manager.frameSinceLastRebuild, equals(1));
      },
    );

    test('reset restores frameSinceLastRebuild and clears force flag', () {
      final manager = AdaptiveQuadTreeManager(rebuildInterval: 4);

      // Advance frames
      manager.shouldRebuild(); // Initial true, resets to 0
      manager.shouldRebuild(); // false, frame 1
      manager.forceRebuild();

      // Reset
      manager.reset();
      expect(manager.frameSinceLastRebuild, equals(4));

      // Next shouldRebuild should rebuild because counter is at interval
      expect(manager.shouldRebuild(), isTrue);
      expect(manager.frameSinceLastRebuild, equals(0));
    });
  });

  group('AdaptivePerformanceController scaling and adjustment tests', () {
    test(
      'currentScale reflects scaleFactor initially and under degradation',
      () {
        final controller = AdaptivePerformanceController(
          targetFrameTimeMs: 16.67,
          minScale: 0.4,
          maxScale: 1.0,
        );

        // Initial scale is 1.0
        expect(controller.currentScale, equals(1.0));
        expect(controller.currentScale, equals(controller.scaleFactor));

        // Simulate heavy load to degrade performance
        for (int i = 0; i < 20; i++) {
          controller.recordFrame(frameTimeMs: 40.0, visibleCount: 100);
        }

        expect(controller.currentScale, lessThan(1.0));
        expect(controller.currentScale, equals(controller.scaleFactor));
        expect(
          controller.currentScale,
          greaterThanOrEqualTo(controller.minScale),
        );
      },
    );

    test('getAdjustedLineDistance scales base distance by currentScale', () {
      final controller = AdaptivePerformanceController(
        targetFrameTimeMs: 16.67,
        minScale: 0.4,
        maxScale: 1.0,
      );

      // At scale 1.0
      expect(controller.getAdjustedLineDistance(100.0), closeTo(100.0, 0.001));
      expect(controller.getAdjustedLineDistance(50.0), closeTo(50.0, 0.001));

      // Degrade scale
      for (int i = 0; i < 25; i++) {
        controller.recordFrame(frameTimeMs: 50.0, visibleCount: 100);
      }

      final expected = 100.0 * controller.currentScale;
      expect(
        controller.getAdjustedLineDistance(100.0),
        closeTo(expected, 0.001),
      );
    });

    test('getAdjustedMaxConnections scales and clamps properly', () {
      final controller = AdaptivePerformanceController(
        targetFrameTimeMs: 16.67,
        minScale: 0.4,
        maxScale: 1.0,
      );

      // At scale 1.0
      expect(controller.getAdjustedMaxConnections(10), equals(10));
      expect(controller.getAdjustedMaxConnections(20), equals(20));

      // Degrade scale to minScale (0.4)
      for (int i = 0; i < 30; i++) {
        controller.recordFrame(frameTimeMs: 50.0, visibleCount: 100);
      }

      final scaledConnections = controller.getAdjustedMaxConnections(10);
      expect(
        scaledConnections,
        equals((10 * controller.currentScale).round().clamp(1, 10)),
      );
      expect(scaledConnections, lessThanOrEqualTo(10));
      expect(scaledConnections, greaterThanOrEqualTo(1));

      // Clamping: minimum must never be below 1 even for small base values
      expect(controller.getAdjustedMaxConnections(1), equals(1));
    });
  });
}
