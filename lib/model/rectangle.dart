import 'dart:math' as math;

class Rectangle {
  final double x, y, width, height;

  const Rectangle(this.x, this.y, this.width, this.height);

  bool contains(double px, double py) {
    return px >= x && px <= x + width && py >= y && py <= y + height;
  }

  bool intersects(Rectangle other) {
    return !(other.x >= x + width ||
        other.x + other.width <= x ||
        other.y >= y + height ||
        other.y + other.height <= y);
  }

  bool intersectsCircle(double cx, double cy, double radius) {
    final closestX = math.max(x, math.min(cx, x + width));
    final closestY = math.max(y, math.min(cy, y + height));

    final distanceX = cx - closestX;
    final distanceY = cy - closestY;

    return (distanceX * distanceX + distanceY * distanceY) <= (radius * radius);
  }

  @override
  String toString() => 'Rectangle(x: $x, y: $y, w: $width, h: $height)';
}
