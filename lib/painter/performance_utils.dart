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
  static const int rebuildInterval = 3;

  int _frameSinceLastRebuild = rebuildInterval; // Start at rebuild interval
  bool _forceNextRebuild = false;

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
