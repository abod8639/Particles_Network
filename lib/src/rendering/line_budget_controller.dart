import 'dart:math' as math;
import 'dart:ui';

import 'frame_radii.dart';
import 'rendering_constants.dart';

/// Controls dynamic line budgeting and connection radii calculation.
///
/// Ensures strict O(N) rendering complexity and soft aesthetic line fading
/// by automatically adapting the connection radius when particle counts or
/// density clusters would otherwise exceed the specified [maxLinesPerFrame].
class LineBudgetController {
  /// Default safety floor for connection radius budgeting (4.0 px).
  static const double defaultSafetyFloor = 4.0;

  /// Legacy safety floor value for backward-compatible 1.9.7 alpha fading (20.0 px).
  static const double legacyAlphaFloor = 20.0;

  // Feedback correction applied on top of the analytic line-budget radius.
  double _budgetCorrection = 1.0;

  /// Exposes the current budget correction multiplier.
  double get budgetCorrection => _budgetCorrection;

  /// Resets the feedback correction factor to default unity (1.0).
  void resetFeedback() {
    _budgetCorrection = 1.0;
  }

  /// Calculates the connection radius that keeps the line count near [maxLinesPerFrame].
  @pragma('vm:prefer-inline')
  double computeBudgetedDistance({
    required double baseDistance,
    required Size size,
    required int visibleCount,
    required int? maxLinesPerFrame,
  }) {
    if (maxLinesPerFrame == null || visibleCount < 2) return baseDistance;
    if (maxLinesPerFrame <= 0) return 0.0;

    final double area = size.width * size.height;
    final double analytic = math.sqrt(
      2.0 * area * maxLinesPerFrame / (math.pi * visibleCount * visibleCount),
    );
    final double r = analytic * _budgetCorrection;
    return r < baseDistance ? r : baseDistance;
  }

  /// Produces the immutable [FrameRadii] for the current frame.
  @pragma('vm:prefer-inline')
  FrameRadii computeFrameRadii({
    required double baseDistance,
    required Size size,
    required int visibleCount,
    required int? maxLinesPerFrame,
    required int? maxConnectionsPerParticle,
    required double cappedDistanceFactor,
    double safetyFloor = defaultSafetyFloor,
  }) {
    final double effectiveSafetyFloor = baseDistance > 0
        ? math.min(baseDistance, safetyFloor)
        : 0.0;

    final double distance = computeBudgetedDistance(
      baseDistance: baseDistance,
      size: size,
      visibleCount: visibleCount,
      maxLinesPerFrame: maxLinesPerFrame,
    );

    double activeDist =
        (maxConnectionsPerParticle != null &&
            cappedDistanceFactor < 1.0 &&
            cappedDistanceFactor > 0.0)
        ? distance * cappedDistanceFactor
        : distance;

    activeDist = math.max(effectiveSafetyFloor, activeDist);

    // Phase 1 Item 2: Compute alphaRadius using 1.9.7 legacy floor semantics (20.0 px)
    // to preserve the authentic line fade look without harsh clipping at 4.0 px.
    final double legacySafetyFloor = baseDistance > 0
        ? math.min(baseDistance, legacyAlphaFloor)
        : 0.0;
    final double alphaDist = math.max(legacySafetyFloor, activeDist);

    return FrameRadii(
      gridRadius: activeDist,
      scanRadius: activeDist,
      alphaRadius: alphaDist,
    );
  }

  /// Updates feedback correction factor based on the actual lines emitted.
  @pragma('vm:prefer-inline')
  void updateFeedback({
    required int? maxLinesPerFrame,
    required int lastFrameLineCount,
    required double usedDistance,
    required double baseDistance,
  }) {
    if (maxLinesPerFrame == null || maxLinesPerFrame <= 0) return;
    if (usedDistance >= baseDistance &&
        lastFrameLineCount <= maxLinesPerFrame) {
      return;
    }
    final double ratio =
        maxLinesPerFrame / (lastFrameLineCount > 0 ? lastFrameLineCount : 1);
    if (ratio > 0.9 && ratio < 1.1) return;

    _budgetCorrection =
        (_budgetCorrection * math.pow(ratio, kBudgetCorrectionExponent)).clamp(
          kMinBudgetCorrection,
          kMaxBudgetCorrection,
        );
  }
}
