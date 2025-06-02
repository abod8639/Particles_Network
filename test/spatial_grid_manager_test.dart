import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/model/grid_cell.dart';
import 'package:particles_network/model/particlemodel.dart';
import 'package:particles_network/painter/spatiall_grid_manager.dart';

void main() {
  test('GridCell toString returns expected format', () {
    final cell = GridCell(3, 7);

    expect(cell.toString(), equals('GridCell[x=3, y=7]'));
  });
  group('SpatialGridManager Tests', () {
    test(
      'createOptimizedSpatialGrid should place particles in correct cells',
      () {
        final particles = [
          Particle(
            position: Offset(10, 10),
            velocity: Offset(0, 0),
            color: Colors.blue,
            size: 10,
          ),
          Particle(
            position: Offset(20, 20),
            velocity: Offset(0, 0),
            color: Colors.red,
            size: 10,
          ),
          Particle(
            position: Offset(30, 30),
            velocity: Offset(0, 0),
            color: Colors.green,
            size: 10,
          ),
        ];

        final visibleParticles = [0, 1, 2];

        final cellSize = 15.0;

        final grid = SpatialGridManager.createOptimizedSpatialGrid(
          particles,
          visibleParticles,
          cellSize,
        );

        expect(grid.isNotEmpty, true);

        final particle0Cells = grid.keys.where(
          (cell) =>
              cell.x == (particles[0].position.dx / cellSize).floor() ||
              cell.y == (particles[0].position.dy / cellSize).floor(),
        );

        expect(particle0Cells.isNotEmpty, true);

        final particle0Cell = GridCell(0, 0);
        expect(grid[particle0Cell]?.contains(0), true);

        final particle1Cell = GridCell(1, 1);
        expect(grid[particle1Cell]?.contains(1), true);

        final particle2Cell = GridCell(2, 2);
        expect(grid[particle2Cell]?.contains(2), true);
      },
    );
  });
}
