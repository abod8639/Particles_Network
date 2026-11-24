// ignore_for_file: deprecated_member_use_from_same_package
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/particles_network.dart';

void main() {
  group('SpatialGrid Unit Tests', () {
    test('initializes with expected cell sizes and buffers', () {
      final grid = SpatialGrid(cellSize: 50.0);
      expect(grid.cellSize, equals(50.0));
      expect(grid.invCellSize, equals(1.0 / 50.0));
      expect(grid.cols, equals(0));
      expect(grid.rows, equals(0));
      expect(grid.activeCellsCount, equals(0));

      final zeroGrid = SpatialGrid(cellSize: 0.0);
      expect(zeroGrid.cellSize, equals(0.0));
      expect(zeroGrid.invCellSize, equals(0.0));
    });

    test('updateCellSize updates cell size and inverse cell size', () {
      final grid = SpatialGrid(cellSize: 40.0);
      grid.updateCellSize(80.0);
      expect(grid.cellSize, equals(80.0));
      expect(grid.invCellSize, equals(1.0 / 80.0));

      grid.updateCellSize(-10.0);
      expect(grid.cellSize, equals(-10.0));
      expect(grid.invCellSize, equals(0.0));
    });

    test('build handles invalid dimensions or cell size safely', () {
      final grid = SpatialGrid(cellSize: 50.0);
      final particles = [
        Particle(
          position: const Offset(10, 10),
          velocity: Offset.zero,
          color: const Color(0xFFFFFFFF),
          size: 1.0,
        ),
      ];

      grid.build(particles, [0], 0, 100);
      expect(grid.cols, equals(0));

      grid.build(particles, [0], 100, -50);
      expect(grid.cols, equals(0));

      grid.updateCellSize(0);
      grid.build(particles, [0], 100, 100);
      expect(grid.cols, equals(0));
    });

    test('build partitions particles into cells and supports O(N) rebuild', () {
      final grid = SpatialGrid(cellSize: 50.0);
      final particles = [
        Particle(
          position: const Offset(25, 25),
          velocity: Offset.zero,
          color: const Color(0xFFFFFFFF),
          size: 1.0,
        ),
        Particle(
          position: const Offset(75, 25),
          velocity: Offset.zero,
          color: const Color(0xFFFFFFFF),
          size: 1.0,
        ),
        Particle(
          position: const Offset(25, 75),
          velocity: Offset.zero,
          color: const Color(0xFFFFFFFF),
          size: 1.0,
        ),
        Particle(
          position: const Offset(150, 150),
          velocity: Offset.zero,
          color: const Color(0xFFFFFFFF),
          size: 1.0,
        ),
      ];

      // Build frame 1
      grid.build(particles, [0, 1, 2, 3], 200, 200);
      expect(grid.cols, greaterThan(0));
      expect(grid.rows, greaterThan(0));
      expect(grid.activeCellsCount, equals(4));

      // Rebuild frame 2 with same dimensions (tests fast O(N) reset branch L97-L101)
      grid.build(particles, [0, 1], 200, 200);
      expect(grid.activeCellsCount, equals(2));

      // Rebuild frame 3 with different dimensions (tests dimensionChanged branch L89-L95)
      grid.build(particles, [0, 1], 400, 400);
      expect(grid.activeCellsCount, equals(2));
    });

    test('build clamps particles outside bounds to edge cells', () {
      final grid = SpatialGrid(cellSize: 50.0);
      final particles = [
        Particle(
          position: const Offset(-50, -50),
          velocity: Offset.zero,
          color: const Color(0xFFFFFFFF),
          size: 1.0,
        ),
        Particle(
          position: const Offset(500, 500),
          velocity: Offset.zero,
          color: const Color(0xFFFFFFFF),
          size: 1.0,
        ),
      ];

      grid.build(particles, [0, 1], 100, 100);
      expect(grid.activeCellsCount, greaterThan(0));

      final output = <int>[];
      // Query near top-left cell (clamped cx = 0, cy = 0)
      grid.findNearbyParticlesToOutput(0, 0, 10, output);
      expect(output, contains(0));

      // Query near bottom-right cell (clamped cx = cols-1, cy = rows-1)
      output.clear();
      grid.findNearbyParticlesToOutput(100, 100, 10, output);
      expect(output, contains(1));
    });

    test(
        'findNearbyParticlesToOutput finds neighbor particles across adjacent cells',
        () {
      final grid = SpatialGrid(cellSize: 50.0);
      final particles = [
        Particle(
          position: const Offset(45, 45),
          velocity: Offset.zero,
          color: const Color(0xFFFFFFFF),
          size: 1.0,
        ), // Cell (0, 0)
        Particle(
          position: const Offset(55, 45),
          velocity: Offset.zero,
          color: const Color(0xFFFFFFFF),
          size: 1.0,
        ), // Cell (1, 0)
        Particle(
          position: const Offset(180, 180),
          velocity: Offset.zero,
          color: const Color(0xFFFFFFFF),
          size: 1.0,
        ), // Far away
      ];

      grid.build(particles, [0, 1, 2], 200, 200);

      final output = <int>[];
      // Query point at (50, 45) with radius 20 covers (0, 0) and (1, 0)
      grid.findNearbyParticlesToOutput(50, 45, 20, output);
      expect(output, containsAll([0, 1]));
      expect(output, isNot(contains(2)));

      // Query with uninitialized or empty grid
      final emptyGrid = SpatialGrid(cellSize: 50.0);
      emptyGrid.findNearbyParticlesToOutput(50, 50, 20, output);
      expect(output, isEmpty);
    });

    test('clear resets grid state and buffers', () {
      final grid = SpatialGrid(cellSize: 50.0);
      final particles = [
        Particle(
          position: const Offset(10, 10),
          velocity: Offset.zero,
          color: const Color(0xFFFFFFFF),
          size: 1.0,
        ),
      ];

      grid.build(particles, [0], 100, 100);
      expect(grid.activeCellsCount, equals(1));
      expect(grid.cols, greaterThan(0));

      // Clear when activeCellsCount > 0
      grid.clear();
      expect(grid.cols, equals(0));
      expect(grid.rows, equals(0));
      expect(grid.activeCellsCount, equals(0));

      // Clear second time (activeCellsCount == 0 branch)
      grid.clear();
      expect(grid.cols, equals(0));
      expect(grid.rows, equals(0));
    });
  });
}
