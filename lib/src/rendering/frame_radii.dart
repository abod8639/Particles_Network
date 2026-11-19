/// Immutable or reusable container for per-frame connection radii.
class FrameRadii {
  /// The radius used to partition particles into spatial grid cells.
  double gridRadius;

  /// The radius used during neighbor scan to check candidate pairs.
  double scanRadius;

  /// The radius used to compute alpha distance fade.
  double alphaRadius;

  FrameRadii({
    this.gridRadius = 0.0,
    this.scanRadius = 0.0,
    this.alphaRadius = 0.0,
  });

  /// In-place update to ensure zero heap allocations in steady-state rendering.
  @pragma('vm:prefer-inline')
  void update({
    required double gridRadius,
    required double scanRadius,
    required double alphaRadius,
  }) {
    this.gridRadius = gridRadius;
    this.scanRadius = scanRadius;
    this.alphaRadius = alphaRadius;
  }
}
