import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/particles_network.dart';

void main() {
  group('SpatialGrid', () {
    late SpatialGrid grid;

    setUp(() {
      grid = SpatialGrid(cellSize: 50.0);
    });

    group('Boundary Clamping', () {
      test('clamps cx to cols - 1 when particle x produces cx >= cols', () {
        // width = 100, cellSize = 50 -> cols = (100 / 50).ceil() + 1 = 3 (indices 0, 1, 2)
        // rows = 3 (indices 0, 1, 2)
        final particles = [
          createMockParticle(position: const Offset(250.0, 25.0)), // cx = 5 >= cols (3)
        ];
        final visibleIndices = [0];

        grid.build(particles, visibleIndices, 100.0, 100.0);

        expect(grid.cols, 3);
        expect(grid.rows, 3);

        // Clamped cell: cy = 0, cx = cols - 1 = 2 -> cell = 0 * 3 + 2 = 2
        final expectedCell = 0 * grid.cols + (grid.cols - 1);
        expect(grid.cellHeads[expectedCell], equals(0));

        // Verify findNearbyParticles around the rightmost boundary finds particle 0
        final output = <int>[];
        grid.findNearbyParticlesToOutput(100.0, 25.0, 50.0, output);
        expect(output, contains(0));
      });

      test('clamps cy to rows - 1 when particle y produces cy >= rows', () {
        // height = 100, cellSize = 50 -> rows = 3 (indices 0, 1, 2)
        final particles = [
          createMockParticle(position: const Offset(25.0, 300.0)), // cy = 6 >= rows (3)
        ];
        final visibleIndices = [0];

        grid.build(particles, visibleIndices, 100.0, 100.0);

        expect(grid.cols, 3);
        expect(grid.rows, 3);

        // Clamped cell: cx = 0, cy = rows - 1 = 2 -> cell = 2 * 3 + 0 = 6
        final expectedCell = (grid.rows - 1) * grid.cols + 0;
        expect(grid.cellHeads[expectedCell], equals(0));

        // Verify findNearbyParticles around the bottom boundary finds particle 0
        final output = <int>[];
        grid.findNearbyParticlesToOutput(25.0, 100.0, 50.0, output);
        expect(output, contains(0));
      });

      test('clamps both cx and cy to cols - 1 and rows - 1 for particles beyond bottom-right', () {
        final particles = [
          createMockParticle(position: const Offset(500.0, 500.0)),
        ];
        final visibleIndices = [0];

        grid.build(particles, visibleIndices, 100.0, 100.0);

        final cornerCell = (grid.rows - 1) * grid.cols + (grid.cols - 1);
        expect(grid.cellHeads[cornerCell], equals(0));

        final output = <int>[];
        grid.findNearbyParticlesToOutput(100.0, 100.0, 50.0, output);
        expect(output, contains(0));
      });

      test('clamps cx to 0 when x < 0 and cy to 0 when y < 0', () {
        final particles = [
          createMockParticle(position: const Offset(-20.0, -30.0)),
        ];
        final visibleIndices = [0];

        grid.build(particles, visibleIndices, 100.0, 100.0);

        // cell = 0 * cols + 0 = 0
        expect(grid.cellHeads[0], equals(0));

        final output = <int>[];
        grid.findNearbyParticlesToOutput(0.0, 0.0, 50.0, output);
        expect(output, contains(0));
      });
    });

    group('clear()', () {
      test('resets grid state and active cells when activeCellsCount > 0', () {
        final particles = [
          createMockParticle(position: const Offset(20.0, 20.0)),
          createMockParticle(position: const Offset(70.0, 70.0)),
        ];
        final visibleIndices = [0, 1];

        grid.build(particles, visibleIndices, 100.0, 100.0);

        expect(grid.activeCellsCount, greaterThan(0));
        expect(grid.cols, greaterThan(0));
        expect(grid.rows, greaterThan(0));

        // Store which cells were active
        final activeCellsCopy = grid.activeCells.sublist(0, grid.activeCellsCount);

        grid.clear();

        expect(grid.activeCellsCount, equals(0));
        expect(grid.cols, equals(0));
        expect(grid.rows, equals(0));

        // Check that previously active cells are reset to -1
        for (final cell in activeCellsCopy) {
          expect(grid.cellHeads[cell], equals(-1));
        }

        // Queries after clear should return empty immediately
        final output = <int>[];
        grid.findNearbyParticlesToOutput(20.0, 20.0, 50.0, output);
        expect(output, isEmpty);
      });

      test('resets entire cellHeads range when activeCellsCount == 0 but cellHeads is not empty', () {
        // Build with empty visibleIndices -> cellHeads is allocated, but activeCellsCount == 0
        grid.build([], [], 100.0, 100.0);

        expect(grid.cellHeads.isNotEmpty, isTrue);
        expect(grid.activeCellsCount, equals(0));
        expect(grid.cols, 3);
        expect(grid.rows, 3);

        // Manually dirty a cell in cellHeads to verify fillRange resets it
        grid.cellHeads[0] = 42;

        grid.clear();

        expect(grid.cols, equals(0));
        expect(grid.rows, equals(0));
        expect(grid.activeCellsCount, equals(0));
        expect(grid.cellHeads[0], equals(-1));
        expect(grid.cellHeads.every((head) => head == -1), isTrue);
      });

      test('handles clear() on freshly initialized SpatialGrid without errors', () {
        final freshGrid = SpatialGrid(cellSize: 50.0);

        expect(() => freshGrid.clear(), returnsNormally);
        expect(freshGrid.cols, equals(0));
        expect(freshGrid.rows, equals(0));
        expect(freshGrid.activeCellsCount, equals(0));
      });
    });
  });
}
