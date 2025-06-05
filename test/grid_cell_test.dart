import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/model/grid_cell.dart';

void main() {
  group('GridCell', () {
    test('constructor should set x and y coordinates', () {
      final cell = GridCell(2, 3);
      expect(cell.x, equals(2));
      expect(cell.y, equals(3));
    });

    group('equality', () {
      test('identical cells should be equal', () {
        final cell1 = GridCell(2, 3);
        final cell2 = GridCell(2, 3);
        expect(cell1, equals(cell2));
      });

      test('cells with different x coordinates should not be equal', () {
        final cell1 = GridCell(2, 3);
        final cell2 = GridCell(4, 3);
        expect(cell1, isNot(equals(cell2)));
      });

      test('cells with different y coordinates should not be equal', () {
        final cell1 = GridCell(2, 3);
        final cell2 = GridCell(2, 5);
        expect(cell1, isNot(equals(cell2)));
      });

      test('cell should equal itself', () {
        final cell = GridCell(2, 3);
        // Test reflexive property
        expect(cell, equals(cell));
      });

      test('equality should be symmetric', () {
        final cell1 = GridCell(2, 3);
        final cell2 = GridCell(2, 3);
        // Test symmetric property
        expect(cell1 == cell2, equals(cell2 == cell1));
      });
    });

    group('hashCode', () {
      test('identical cells should have same hash code', () {
        final cell1 = GridCell(2, 3);
        final cell2 = GridCell(2, 3);
        expect(cell1.hashCode, equals(cell2.hashCode));
      });

      test('different cells should have different hash codes', () {
        final cell1 = GridCell(2, 3);
        final cell2 = GridCell(3, 2);
        expect(cell1.hashCode, isNot(equals(cell2.hashCode)));
      });

      test('hash code should be consistent', () {
        final cell = GridCell(2, 3);
        final firstHash = cell.hashCode;
        final secondHash = cell.hashCode;
        expect(firstHash, equals(secondHash));
      });
    });

    test('toString should return formatted string representation', () {
      final cell = GridCell(2, 3);
      expect(cell.toString(), equals('GridCell[x=2, y=3]'));
    });

    test('cells should work correctly in collections', () {
      final cell1 = GridCell(1, 1);
      final cell2 = GridCell(1, 1);
      final cell3 = GridCell(2, 2);

      final set = <GridCell>{cell1, cell2, cell3};
      expect(set.length, equals(2)); // Should only contain 2 unique cells

      final map = <GridCell, String>{};
      map[cell1] = 'Value1';
      map[cell2] = 'Value2'; // Should overwrite the value for cell1
      expect(map.length, equals(1));
      expect(map[cell1], equals('Value2'));
    });
  });
}
