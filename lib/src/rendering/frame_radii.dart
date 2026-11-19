import 'package:flutter/foundation.dart';

/// Immutable container for per-frame connection radii.
///
/// Guaranteed to uphold the invariant: `gridRadius >= scanRadius`.
@immutable
class FrameRadii {
  /// The radius used to partition particles into spatial grid cells.
  final double gridRadius;

  /// The radius used during neighbor scan to check candidate pairs.
  final double scanRadius;

  /// The radius used to compute alpha distance fade.
  final double alphaRadius;

  const FrameRadii({
    required this.gridRadius,
    required this.scanRadius,
    required this.alphaRadius,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FrameRadii &&
          runtimeType == other.runtimeType &&
          gridRadius == other.gridRadius &&
          scanRadius == other.scanRadius &&
          alphaRadius == other.alphaRadius;

  @override
  int get hashCode => Object.hash(gridRadius, scanRadius, alphaRadius);

  @override
  String toString() =>
      'FrameRadii(gridRadius: $gridRadius, scanRadius: $scanRadius, alphaRadius: $alphaRadius)';
}
