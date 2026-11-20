// Adaptive performance management for the particle network
//
// Provides mechanisms to track particle acceleration state and manage
// spatial grid updates efficiently based on frame performance.
library;

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
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
/// using a mathematically stable Dual-Tier Degradation Ladder to maintain a stable
/// target frame rate without dropped frames.
class AdaptivePerformanceController {
  /// Safety minimum floor for Tier 1 line budget regulation.
  static const int minFloor = 500;

  /// Absolute upper cap on dynamic lines per frame.
  static const int absoluteMaxCap = 25000;

  /// Initial dynamic line budget on startup and reset.
  static const double initialDynamicLines = 4000.0;

  /// Cutoff threshold for discarding outlier frames (transitions, resumes).
  static const double outlierCutoffMs = 250.0;

  /// Emergency connection capping progression steps.
  static const List<int> emergencySteps = <int>[16, 8, 4];

  double _targetFrameTimeMs;
  double _emaFrameTimeMs;
  double _smoothedDynamicLines = initialDynamicLines;
  int _emergencyTierIndex = 0;
  int _consecutiveDrops = 0;
  int _consecutiveSmooth = 0;

  /// Exponential moving average of recorded frame times in milliseconds.
  double get emaFrameTimeMs => _emaFrameTimeMs;

  /// Target frame time in milliseconds.
  double get targetFrameTimeMs => _targetFrameTimeMs;

  /// Current smoothed dynamic line budget rounded to nearest integer.
  int get dynamicLineBudget => _smoothedDynamicLines.round();

  /// Raw smoothed dynamic lines value.
  double get smoothedDynamicLines => _smoothedDynamicLines;

  /// Dynamic scale factor relative to the initial line budget (4000.0).
  double get scaleFactor => _smoothedDynamicLines / initialDynamicLines;

  /// Current emergency connection cap, or `null` if uncapped (fast-path).
  int? get emergencyMaxConnections =>
      _emergencyTierIndex > 0 ? emergencySteps[_emergencyTierIndex - 1] : null;

  /// Whether Tier 2 emergency connection capping is currently engaged.
  bool get isEmergencyActive => _emergencyTierIndex > 0;

  /// Current emergency tier index (0 = uncapped, 1 = 16, 2 = 8, 3 = 4).
  int get emergencyTierIndex => _emergencyTierIndex;

  /// Consecutive dropped frames recorded while at the line budget floor.
  int get consecutiveDrops => _consecutiveDrops;

  /// Consecutive smooth frames recorded while in emergency recovery.
  int get consecutiveSmooth => _consecutiveSmooth;

  /// Creates an [AdaptivePerformanceController].
  AdaptivePerformanceController({
    double targetFrameTimeMs = 16.67,
    bool autoBoost = false,
    double? minScale,
    double? maxScale,
    double? emaWeight,
    PerformanceMonitor? monitor,
  })  : _targetFrameTimeMs = (targetFrameTimeMs > 0 && targetFrameTimeMs.isFinite)
            ? targetFrameTimeMs
            : 16.67,
        _emaFrameTimeMs = (targetFrameTimeMs > 0 && targetFrameTimeMs.isFinite)
            ? targetFrameTimeMs
            : 16.67;

  /// Records a frame timing duration and adapts the line budget and emergency tier.
  void recordFrame({required double frameTimeMs, required int visibleCount}) {
    // 1. Guards
    if (visibleCount < 2 ||
        frameTimeMs <= 0 ||
        !frameTimeMs.isFinite ||
        frameTimeMs > outlierCutoffMs) {
      return;
    }

    // 2. Safe Upper Bound (No ArgumentError)
    final int effectiveMaxCap = math.max(
      minFloor,
      math.min(absoluteMaxCap, visibleCount * 30),
    );
    if (_smoothedDynamicLines > effectiveMaxCap) {
      _smoothedDynamicLines = effectiveMaxCap.toDouble();
    }

    // 3. Asymmetric EMA Update
    final double maxBudgetMs = math.max(1.0, _targetFrameTimeMs * 3.0);
    final double clampedMs = frameTimeMs.clamp(1.0, maxBudgetMs);
    final double emaWeight = clampedMs > _emaFrameTimeMs ? 0.30 : 0.15;
    _emaFrameTimeMs =
        emaWeight * clampedMs + (1.0 - emaWeight) * _emaFrameTimeMs;

    // 4. Tier 1 Update (Locked while Tier 2 is active)
    if (_emergencyTierIndex > 0) {
      _smoothedDynamicLines = minFloor.toDouble();
    } else if (frameTimeMs > 2.0 * _targetFrameTimeMs) {
      _smoothedDynamicLines =
          math.max(minFloor.toDouble(), _smoothedDynamicLines * 0.5);
    } else {
      final double headroomRatio =
          _targetFrameTimeMs / math.max(_emaFrameTimeMs, 1.0);
      if (headroomRatio < 0.90 || headroomRatio > 1.10) {
        final double scale;
        final double alpha;
        if (headroomRatio < 0.90) {
          scale = headroomRatio * headroomRatio;
          alpha = 0.35;
        } else {
          scale = headroomRatio;
          alpha = 0.10;
        }
        final double targetLines = (_smoothedDynamicLines * scale).clamp(
          minFloor.toDouble(),
          effectiveMaxCap.toDouble(),
        );
        _smoothedDynamicLines += alpha * (targetLines - _smoothedDynamicLines);
      }
    }

    // 5. Tier 2 State Machine (Emergency Connection Capping & Step-Up Recovery)
    final bool atFloor = _smoothedDynamicLines <= minFloor * 1.15;
    final bool isSevereSpike = frameTimeMs > 2.0 * _targetFrameTimeMs;
    final bool isSustainedDrop = frameTimeMs > 1.35 * _targetFrameTimeMs;
    final bool isSmoothFrame = frameTimeMs < 0.90 * _targetFrameTimeMs;

    // Escalation (only when atFloor is true)
    if (atFloor) {
      if (isSustainedDrop) {
        _consecutiveDrops++;
        _consecutiveSmooth = 0;
      } else {
        _consecutiveDrops = 0;
      }

      if ((isSevereSpike || _consecutiveDrops >= 3) && _emergencyTierIndex < 3) {
        _emergencyTierIndex++;
        _smoothedDynamicLines = minFloor.toDouble();
        _consecutiveDrops = 0;
        _consecutiveSmooth = 0;
      }
    }

    // Step-Up Recovery (only when _emergencyTierIndex > 0)
    if (_emergencyTierIndex > 0) {
      if (isSmoothFrame) {
        _consecutiveSmooth++;
        if (_consecutiveSmooth >= 15) {
          _emergencyTierIndex--;
          _consecutiveSmooth = 0;
        }
      } else {
        _consecutiveSmooth = 0;
      }
    }
  }

  /// Compatibility wrapper for recording Duration-based frame times.
  void recordFrameTime(Duration duration, [int visibleCount = 100]) {
    recordFrame(
      frameTimeMs: duration.inMicroseconds / 1000.0,
      visibleCount: visibleCount,
    );
  }

  /// Resets controller state and re-initializes EMA with target frame time.
  void reset({required double targetFrameTimeMs}) {
    final double safeTarget =
        (targetFrameTimeMs > 0 && targetFrameTimeMs.isFinite)
            ? targetFrameTimeMs
            : 16.67;
    _targetFrameTimeMs = safeTarget;
    _emaFrameTimeMs = safeTarget;
    _smoothedDynamicLines = initialDynamicLines;
    _emergencyTierIndex = 0;
    _consecutiveDrops = 0;
    _consecutiveSmooth = 0;
  }

  @visibleForTesting
  void setDynamicLinesForTesting(double lines) {
    _smoothedDynamicLines = lines;
  }

  @visibleForTesting
  void setEmergencyTierForTesting(int tier) {
    _emergencyTierIndex = tier;
  }
}
