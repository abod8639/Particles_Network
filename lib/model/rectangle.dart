import 'dart:math' as math; // For mathematical functions (min, max, etc.)

/// A 2D axis-aligned rectangle with collision detection capabilities
class Rectangle {
  /// The x-coordinate of the rectangle's left edge
  final double x;

  /// The y-coordinate of the rectangle's top edge
  final double y;

  /// The width of the rectangle (extends right from x)
  final double width;

  /// The height of the rectangle (extends down from y)
  final double height;

  /// Creates a rectangle with the given position and dimensions
  const Rectangle(this.x, this.y, this.width, this.height);

  /// Gets the right edge x-coordinate (computed property)
  double get right => x + width;

  /// Gets the bottom edge y-coordinate (computed property)
  double get bottom => y + height;

  /// Gets the left edge x-coordinate (same as x)
  double get left => x;

  /// Gets the top edge y-coordinate (same as y)
  double get top => y;

  /// Checks if a point (px, py) is contained within this rectangle
  ///
  /// Mathematical Operation:
  /// Point containment test using simple inequalities:
  /// px must be between x (left) and x+width (right)
  /// py must be between y (top) and y+height (bottom)
  bool contains(double px, double py) {
    return px >= x && px <= x + width && py >= y && py <= y + height;
  }

  /// Checks if this rectangle intersects with another rectangle
  ///
  /// Mathematical Operation:
  /// Separating axis theorem implementation:
  /// Two rectangles DON'T intersect if:
  /// 1. One is completely to the left of the other OR
  /// 2. One is completely above the other OR
  /// 3. One is completely to the right of the other OR
  /// 4. One is completely below the other
  bool intersects(Rectangle other) {
    return !(other.x >= x + width || // Other is right of us
        other.x + other.width <= x || // Other is left of us
        other.y >= y + height || // Other is below us
        other.y + other.height <= y); // Other is above us
  }

  /// Checks if this rectangle intersects with a circle
  ///
  /// Mathematical Operations:
  /// 1. Finds the closest point on the rectangle to the circle center
  /// 2. Calculates squared distance between circle center and closest point
  /// 3. Compares against squared radius (avoids expensive sqrt operation)
  bool intersectsCircle(double cx, double cy, double radius) {
    // Find closest x-coordinate on rectangle to circle center
    // Clamped between left and right edges
    final closestX = math.max(x, math.min(cx, x + width));

    // Find closest y-coordinate on rectangle to circle center
    // Clamped between top and bottom edges
    final closestY = math.max(y, math.min(cy, y + height));

    // Calculate distance components
    final distanceX = cx - closestX;
    final distanceY = cy - closestY;

    // Compare squared distance to squared radius
    return (distanceX * distanceX + distanceY * distanceY) <= (radius * radius);
  }

  @override
  String toString() => 'Rectangle(x: $x, y: $y, w: $width, h: $height)';
}
