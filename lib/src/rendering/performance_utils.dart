// Adaptive performance management for the particle network
//
// Provides mechanisms to track particle acceleration state and manage
// QuadTree updates efficiently based on frame performance.
library;

// Tracks the acceleration state of particles
class AccelerationTracker {
  int acceleratedParticleCount = 0;
  int _lastFrameAcceleratedCount = 0;

  // Record that a particle was accelerated
  void recordAcceleration() {
    acceleratedParticleCount++;
  }

  // Reset count for new frame
  void resetFrame() {
    _lastFrameAcceleratedCount = acceleratedParticleCount;
    acceleratedParticleCount = 0;
  }

  // Get the number of accelerated particles from last frame
  int get lastFrameAcceleratedCount => _lastFrameAcceleratedCount;

  // Check if there were any accelerated particles
  bool get hadAcceleratedParticles => _lastFrameAcceleratedCount > 0;
}

// Manages adaptive QuadTree updates
//
// Instead of rebuilding QuadTree every frame, this class monitors
// particle movement and rebuilds only when necessary.
class AdaptiveQuadTreeManager {
  // How many frames to skip between mandatory rebuilds
  int rebuildInterval;

  int _frameSinceLastRebuild;
  bool _forceNextRebuild = false;

  AdaptiveQuadTreeManager({this.rebuildInterval = 3})
      : _frameSinceLastRebuild = rebuildInterval;

  // Check if QuadTree should be rebuilt this frame
  bool shouldRebuild() {
    // Force rebuild if explicitly requested
    if (_forceNextRebuild) {
      _frameSinceLastRebuild = 0;
      _forceNextRebuild = false;
      return true;
    }

    // Periodically rebuild to handle accumulated changes
    _frameSinceLastRebuild++;
    if (_frameSinceLastRebuild >= rebuildInterval) {
      _frameSinceLastRebuild = 0;
      return true;
    }

    return false;
  }

  // Force a rebuild on the next frame (e.g., after touch interaction)
  void forceRebuild() {
    _forceNextRebuild = true;
  }

  // Reset the frame counter
  void reset() {
    _frameSinceLastRebuild = rebuildInterval;
    _forceNextRebuild = false;
  }

  // Get the number of frames since last rebuild
  int get frameSinceLastRebuild => _frameSinceLastRebuild;
}

// Monitors frame performance and provides adaptive metrics
class PerformanceMonitor {
  static const int _sampleWindowSize = 60; // 1 second at 60 FPS
  final List<Duration> _frameTimes = [];

  // Record the duration of a frame
  void recordFrameTime(Duration frameDuration) {
    _frameTimes.add(frameDuration);

    // Keep only recent samples to avoid memory bloat
    if (_frameTimes.length > _sampleWindowSize) {
      _frameTimes.removeAt(0);
    }
  }

  // Get average frame time over the sample window
  Duration? get averageFrameTime {
    if (_frameTimes.isEmpty) return null;

    final totalDuration = _frameTimes.fold<Duration>(
      Duration.zero,
      (prev, current) => prev + current,
    );

    return Duration(
      microseconds: totalDuration.inMicroseconds ~/ _frameTimes.length,
    );
  }

  // Check if we're consistently dropping frames (< 50 FPS)
  bool isDroppingFrames() {
    final avg = averageFrameTime;
    if (avg == null) return false;
    // At 60 FPS, frame time should be ~16.67ms
    // At 50 FPS, it's 20ms
    return avg.inMilliseconds > 20;
  }

  // Get the number of recorded frame times
  int get recordedFrameCount => _frameTimes.length;

  // Clear all recorded times
  void clear() {
    _frameTimes.clear();
  }
}

/// Dynamically adjusts visualization quality metrics (distance, connections)
/// to maintain a stable target frame rate without dropped frames.
class AdaptivePerformanceController {
  /// Underlying performance monitor tracking frame durations.
  final PerformanceMonitor monitor;

  /// Target frame time in milliseconds (default: 16.67ms for 60 FPS).
  final double targetFrameTimeMs;

  /// Minimum quality scale allowed.
  final double minScale;

  /// Maximum quality scale allowed.
  final double maxScale;

  double _currentScale = 1.0;
  int _consecutiveDrops = 0;
  int _consecutiveSmooth = 0;

  /// Creates an [AdaptivePerformanceController].
  AdaptivePerformanceController({
    PerformanceMonitor? monitor,
    this.targetFrameTimeMs = 16.67,
    this.minScale = 0.4,
    this.maxScale = 1.0,
  }) : monitor = monitor ?? PerformanceMonitor();

  /// Current quality scale factor between [minScale] and [maxScale].
  double get scaleFactor => _currentScale;

  /// Records a frame duration and adapts the scale factor if necessary.
  void recordFrameTime(Duration duration) {
    monitor.recordFrameTime(duration);
    final double ms = duration.inMicroseconds / 1000.0;

    if (ms > targetFrameTimeMs * 1.25) {
      _consecutiveDrops++;
      _consecutiveSmooth = 0;
      if (_consecutiveDrops >= 3) {
        // Step down quality scale to recover frame rate
        _currentScale = (_currentScale - 0.1).clamp(minScale, maxScale);
        _consecutiveDrops = 0;
      }
    } else if (ms < targetFrameTimeMs * 0.85) {
      _consecutiveSmooth++;
      _consecutiveDrops = 0;
      if (_consecutiveSmooth >= 15) {
        // Step up quality scale gradually when performance is consistently smooth
        _currentScale = (_currentScale + 0.05).clamp(minScale, maxScale);
        _consecutiveSmooth = 0;
      }
    } else {
      _consecutiveDrops = 0;
      _consecutiveSmooth = 0;
    }
  }

  /// Returns the line distance scaled by the current performance factor.
  double getAdjustedLineDistance(double baseDistance) {
    return baseDistance * _currentScale;
  }

  /// Returns the maximum connection count scaled by the current performance factor.
  int getAdjustedMaxConnections(int baseMaxConnections) {
    return (baseMaxConnections * _currentScale)
        .round()
        .clamp(1, baseMaxConnections);
  }

  /// Resets controller state and underlying monitor.
  void reset() {
    _currentScale = 1.0;
    _consecutiveDrops = 0;
    _consecutiveSmooth = 0;
    monitor.clear();
  }
}

