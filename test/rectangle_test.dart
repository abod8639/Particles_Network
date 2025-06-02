import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/model/rectangle.dart';

void main() {
  group('Rectangle', () {
    test('constructor creates rectangle with correct properties', () {
      const rect = Rectangle(10, 20, 30, 40);
      expect(rect.x, equals(10));
      expect(rect.y, equals(20));
      expect(rect.width, equals(30));
      expect(rect.height, equals(40));
    });

    group('contains', () {
      const rect = Rectangle(0, 0, 100, 100);

      test('returns true for point inside rectangle', () {
        expect(rect.contains(50, 50), isTrue);
        expect(rect.contains(0, 0), isTrue);
        expect(rect.contains(100, 100), isTrue);
      });

      test('returns false for point outside rectangle', () {
        expect(rect.contains(-1, 50), isFalse);
        expect(rect.contains(50, -1), isFalse);
        expect(rect.contains(101, 50), isFalse);
        expect(rect.contains(50, 101), isFalse);
      });
    });

    group('intersects', () {
      const rect = Rectangle(0, 0, 100, 100);

      test('returns true for overlapping rectangles', () {
        expect(rect.intersects(const Rectangle(50, 50, 100, 100)), isTrue);
        expect(rect.intersects(const Rectangle(-50, -50, 100, 100)), isTrue);
        expect(rect.intersects(const Rectangle(0, 0, 50, 50)), isTrue);
      });

      test('returns false for non-overlapping rectangles', () {
        expect(rect.intersects(const Rectangle(101, 0, 100, 100)), isFalse);
        expect(rect.intersects(const Rectangle(0, 101, 100, 100)), isFalse);
        expect(rect.intersects(const Rectangle(-101, 0, 100, 100)), isFalse);
        expect(rect.intersects(const Rectangle(0, -101, 100, 100)), isFalse);
      });
    });

    group('intersectsCircle', () {
      const rect = Rectangle(0, 0, 100, 100);

      test('returns true for circle intersecting rectangle', () {
        expect(rect.intersectsCircle(50, 50, 10), isTrue); // Circle inside
        expect(rect.intersectsCircle(0, 0, 10), isTrue); // Circle at corner
        expect(
          rect.intersectsCircle(-5, 50, 10),
          isTrue,
        ); // Circle intersecting from left
        expect(
          rect.intersectsCircle(50, 105, 10),
          isTrue,
        ); // Circle intersecting from bottom
      });

      test('returns false for circle not intersecting rectangle', () {
        expect(rect.intersectsCircle(-20, 50, 10), isFalse); // Circle far left
        expect(
          rect.intersectsCircle(50, 120, 10),
          isFalse,
        ); // Circle far bottom
        expect(
          rect.intersectsCircle(-15, -15, 10),
          isFalse,
        ); // Circle at corner but not touching
      });
    });

    test('toString returns correct string representation', () {
      const rect = Rectangle(10, 20, 30, 40);
      expect(
        rect.toString(),
        equals('Rectangle(x: 10.0, y: 20.0, w: 30.0, h: 40.0)'),
      );
    });
  });
}
