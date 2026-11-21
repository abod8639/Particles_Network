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
}
