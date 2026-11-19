/// Immutable configuration tuning for spatial grid sizing and cell density.
class GridTuning {
  /// Default cell density multiplier k=4.0.
  static const double defaultCellMultiplierK = 4.0;

  /// Default minimum cell floor 4.0 px.
  static const double defaultMinCellFloor = 4.0;

  /// Absolute cap on total grid cells (default: 250,000).
  static const int defaultMaxTotalCells = 250000;

  /// Density multiplier for cell sizing: minCell = sqrt(area / (count * k)).
  final double cellMultiplierK;

  /// Safety floor for cell sizing (in pixels).
  final double minCellFloor;

  /// Whether to fit the grid bounding box to particle min/max bounds instead of screen size.
  final bool fitToBoundingBox;

  /// Maximum allowed grid cells across both dimensions.
  final int maxTotalCells;

  const GridTuning({
    this.cellMultiplierK = defaultCellMultiplierK,
    this.minCellFloor = defaultMinCellFloor,
    this.fitToBoundingBox = false,
    this.maxTotalCells = defaultMaxTotalCells,
  });
}
