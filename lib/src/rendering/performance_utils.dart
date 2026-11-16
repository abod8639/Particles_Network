// Adaptive performance management for the particle network
//
// Provides mechanisms to track particle acceleration state and manage
// spatial grid updates efficiently based on frame performance.
library;

import 'dart:math' as math;
import 'package:particles_network/src/legacy/legacy_deprecation_logger.dart';

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

// Manages adaptive QuadTree updates (legacy)
//
// Deprecated: SortedSpatialGrid rebuilds in sub-0.1ms with zero allocations every frame,
// making periodic skipping obsolete.
@Deprecated(
  'AdaptiveQuadTreeManager is deprecated. SortedSpatialGrid performs full '
  'zero-allocation rebuilds in sub-0.1ms every frame without needing periodic skipping. '
  'Scheduled for removal in particles_network 2.0.0.',
)
class AdaptiveQuadTreeManager {
  // How many frames to skip between mandatory rebuilds
  int rebuildInterval;

  int _frameSinceLastRebuild;
  bool _forceNextRebuild = false;

  AdaptiveQuadTreeManager({this.rebuildInterval = 3})
      : _frameSinceLastRebuild = rebuildInterval {
    LegacyDeprecationLogger.warn(
      deprecatedApi: 'AdaptiveQuadTreeManager',
      replacement: 'SortedSpatialGrid',
    );
  }

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

  /// Weight factor (alpha) for exponential moving average updates (default: 0.1).
  final double emaWeight;

  /// Whether dynamic performance boosting is active to maximize connections
  /// and line density when excess frame headroom is available.
  final bool autoBoost;

  double _currentScale = 1.0;
  int _consecutiveDrops = 0;
  int _consecutiveSmooth = 0;
  double? _emaFrameTimeMs;

  /// Exponential moving average of recorded frame times in milliseconds.
  double get emaFrameTimeMs => _emaFrameTimeMs ?? targetFrameTimeMs;

  /// Upper threshold factor for detecting dropped frames (hysteresis upper bound).
  double get dropThresholdMs => targetFrameTimeMs * 1.25;

  /// Lower threshold factor for detecting smooth frames (hysteresis lower bound).
  double get smoothThresholdMs => targetFrameTimeMs * 0.85;

  /// Creates an [AdaptivePerformanceController].
  AdaptivePerformanceController({
    PerformanceMonitor? monitor,
    this.targetFrameTimeMs = 16.67,
    this.minScale = 0.4,
    double? maxScale,
    this.emaWeight = 0.1,
    this.autoBoost = false,
  })  : maxScale = maxScale ?? (autoBoost ? 2.5 : 1.0),
        monitor = monitor ?? PerformanceMonitor();

  /// Current quality scale factor between [minScale] and [maxScale].
  double get scaleFactor => _currentScale;

  /// Records a frame duration and adapts the scale factor if necessary.
  void recordFrameTime(Duration duration) {
    monitor.recordFrameTime(duration);
    final double ms = duration.inMicroseconds / 1000.0;
    _emaFrameTimeMs = _emaFrameTimeMs == null
        ? ms
        : (emaWeight * ms + (1.0 - emaWeight) * _emaFrameTimeMs!);

    if (ms > dropThresholdMs) {
      _consecutiveDrops++;
      _consecutiveSmooth = 0;
      if (_consecutiveDrops >= 3) {
        // Step down quality scale to recover frame rate
        _currentScale = (_currentScale - 0.1).clamp(minScale, maxScale);
        _consecutiveDrops = 0;
      }
    } else if (ms < smoothThresholdMs) {
      _consecutiveSmooth++;
      _consecutiveDrops = 0;
      final int requiredSmooth =
          (autoBoost && ms < smoothThresholdMs * 0.6) ? 8 : 15;
      if (_consecutiveSmooth >= requiredSmooth) {
        // Step up quality scale gradually when performance is consistently smooth
        _currentScale = (_currentScale + 0.05).clamp(minScale, maxScale);
        _consecutiveSmooth = 0;
      }
    } else {
      // Within hysteresis deadband: stabilize counters
      _consecutiveDrops = 0;
      _consecutiveSmooth = 0;
    }
  }

  /// Returns the line distance scaled by the current performance factor.
  ///
  /// Clamped between [minScale] and 1.0 so that dynamic performance boosting
  /// increases connection limits and density without distorting the visual
  /// reach of particles across the canvas.
  double getAdjustedLineDistance(double baseDistance) {
    return baseDistance * _currentScale.clamp(minScale, 1.0);
  }

  /// Returns the maximum connection count scaled by the current performance factor.
  int getAdjustedMaxConnections(int baseMaxConnections, [int? maxAllowed]) {
    final int upper = maxAllowed ??
        (autoBoost
            ? math.max(
                baseMaxConnections, (baseMaxConnections * maxScale).round())
            : baseMaxConnections);
    return (baseMaxConnections * _currentScale).round().clamp(1, upper);
  }

  /// Dynamically computes the maximum connections per particle in auto-boost mode,
  /// scaling up to [maxCap] to give the maximum possible number according to device speed.
  int getAutoMaxConnections({int base = 6, int maxCap = 15000}) {
    final int upper = math.min(maxCap, (base * maxScale).round());
    final int target = (base * _currentScale).round();
    return target.clamp(1, upper);
  }

  /// Returns the maximum lines per frame scaled by the current performance factor.
  int getAdjustedMaxLines(int baseMaxLines, [int? maxAllowed]) {
    final int upper = maxAllowed ??
        (autoBoost
            ? math.max(baseMaxLines, (baseMaxLines * maxScale).round())
            : baseMaxLines);
    return (baseMaxLines * _currentScale).round().clamp(100, upper);
  }

  /// Resets controller state and underlying monitor.
  void reset() {
    _currentScale = 1.0;
    _consecutiveDrops = 0;
    _consecutiveSmooth = 0;
    _emaFrameTimeMs = null;
    monitor.clear();
  }
}
