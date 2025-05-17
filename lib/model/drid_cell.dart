/// Represents a discrete cell in a 2D spatial partitioning grid
///
/// This class is used for spatial hashing and efficient neighbor lookups
/// in particle systems. Each GridCell corresponds to a fixed-size region
/// in the continuous coordinate space.
///
/// Key Features:
/// - Immutable coordinates (safe for hash-based collections)
/// - Proper equality and hash code implementation
/// - Human-readable string representation
///
/// Mathematical Basis:
/// Continuous space → Discrete grid mapping:
///   cellX = floor(worldX / cellSize)
///   cellY = floor(worldY / cellSize)
class GridCell {
  /// The x-coordinate of the grid cell (discrete grid space, not world space)
  final int x;

  /// The y-coordinate of the grid cell (discrete grid space, not world space)
  final int y;

  /// Creates a grid cell with discrete coordinates
  GridCell(this.x, this.y);

  /// Equality operator that compares both coordinates
  ///
  /// Essential for correct behavior in collections like Set and Map.
  /// Follows Dart's equality contract:
  /// 1. Reflexive: a == a
  /// 2. Symmetric: a == b ⇒ b == a
  /// 3. Transitive: a == b && b == c ⇒ a == c
  @override
  bool operator ==(Object other) =>
      identical(this, other) || // Reference equality check
      other is GridCell && // Type check
          runtimeType == other.runtimeType && // Subtype check
          x == other.x && // Coordinate comparison
          y == other.y;

  /// Hash code implementation following Dart's hash code contract:
  /// 1. Consistent: same object ⇒ same hash code
  /// 2. Collision-minimizing: different objects ⇒ different hash codes when possible
  ///
  /// Uses bitwise XOR (^) which provides good distribution for grid coordinates:
  /// hash = x.hashCode ^ y.hashCode
  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  /// Human-readable string representation for debugging
  ///
  /// Example output: "GridCell[x=5, y=3]"
  @override
  String toString() => 'GridCell[x=$x, y=$y]';
}
