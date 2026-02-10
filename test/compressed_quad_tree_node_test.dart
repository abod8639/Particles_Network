import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/model/rectangle.dart';
import 'package:particles_network/quad_tree/compressed_quad_tree_node.dart';

void main() {
  group('Child Boundary Calculation', () {
    test('returns correct boundary for each quadrant', () {
      final node = CompressedQuadTreeNode(const Rectangle(0, 0, 100, 100));
      const halfWidth = 50.0;
      const halfHeight = 50.0;

      final nw = node.getChildBoundary(Quadrant.northWest);
      expect(nw.x, 0);
      expect(nw.y, 0);
      expect(nw.width, halfWidth);
      expect(nw.height, halfHeight);

      final ne = node.getChildBoundary(Quadrant.northEast);
      expect(ne.x, 50);
      expect(ne.y, 0);
      expect(ne.width, halfWidth);
      expect(ne.height, halfHeight);

      final sw = node.getChildBoundary(Quadrant.southWest);
      expect(sw.x, 0);
      expect(sw.y, 50);
      expect(sw.width, halfWidth);
      expect(sw.height, halfHeight);

      final se = node.getChildBoundary(Quadrant.southEast);
      expect(se.x, 50);
      expect(se.y, 50);
      expect(se.width, halfWidth);
      expect(se.height, halfHeight);
    });
  });
  late CompressedQuadTreeNode quadTree;

  setUp(() {
    // Create a quad tree node with boundary 0,0,100,100
    quadTree = CompressedQuadTreeNode(const Rectangle(0, 0, 100, 100));
  });

  group('Basic Properties', () {
    test('initial state is correct', () {
      expect(quadTree.isLeaf, isTrue);
      expect(quadTree.isCompressed, isFalse);
      expect(quadTree.hasOnlyOneChild, isFalse);
      expect(quadTree.particles, isEmpty);
    });

    test('boundary is correctly set', () {
      expect(quadTree.boundary.x, equals(0));
      expect(quadTree.boundary.y, equals(0));
      expect(quadTree.boundary.width, equals(100));
      expect(quadTree.boundary.height, equals(100));
    });
  });

  group('Particle Insertion', () {
    test('insert particle within bounds', () {
      const particle = QuadTreeParticle(1, 50, 50);
      expect(quadTree.insert(particle), isTrue);
      expect(quadTree.particles, contains(particle));
    });

    test('reject particle outside bounds', () {
      const particle = QuadTreeParticle(1, 150, 150);
      expect(quadTree.insert(particle), isFalse);
      expect(quadTree.particles, isEmpty);
    });

    test('subdivision occurs when maxParticles exceeded', () {
      // Insert more than maxParticles (2) particles in same quadrant
      const p1 = QuadTreeParticle(1, 25, 25); // NW
      const p2 = QuadTreeParticle(2, 20, 20); // NW
      const p3 = QuadTreeParticle(3, 15, 15); // NW

      quadTree.insert(p1);
      quadTree.insert(p2);
      expect(quadTree.isLeaf, isTrue); // Still a leaf with 2 particles

      quadTree.insert(p3);
      expect(quadTree.isLeaf, isFalse); // Should subdivide
    });
  });

  group('Path Compression', () {
    test('compression occurs with sufficient particles', () {
      // Insert enough particles to trigger compression in NW quadrant
      final particles = [
        const QuadTreeParticle(1, 10, 10), // NW
        const QuadTreeParticle(2, 15, 15), // NW
        const QuadTreeParticle(3, 20, 20), // NW
        const QuadTreeParticle(4, 25, 25), // NW
      ];

      for (var i = 0; i < particles.length; i++) {
        quadTree.insert(particles[i]);
        print('After inserting particle ${i + 1}:');
        print('isLeaf: ${quadTree.isLeaf}');
        print('children count: ${quadTree.children.length}');
        if (!quadTree.isLeaf) {
          print(
            'child quadrants: ${quadTree.children.keys.map((q) => q.name).join(', ')}',
          );
        }
      }

      expect(
        quadTree.isLeaf,
        isFalse,
        reason: 'Tree should not be a leaf after compression',
      );
      expect(
        quadTree.children.length,
        equals(1),
        reason: 'Should only have NW quadrant due to compression',
      );
      expect(
        quadTree.children.keys.first,
        equals(Quadrant.northWest),
        reason: 'Should contain only NW quadrant',
      );
    });
  });

  group('Range Query', () {
    test('queryRange finds particles in range', () {
      const p1 = QuadTreeParticle(1, 25, 25);
      const p2 = QuadTreeParticle(2, 75, 75);
      quadTree.insert(p1);
      quadTree.insert(p2);

      const queryBoundary = Rectangle(0, 0, 50, 50);
      final result = quadTree.queryRange(queryBoundary);

      expect(result.length, equals(1));
      expect(result.first.index, equals(1));
    });
  });

  group('Circle Query', () {
    test('queryCircle finds particles within radius', () {
      const p1 = QuadTreeParticle(1, 10, 10);
      const p2 = QuadTreeParticle(2, 90, 90);
      quadTree.insert(p1);
      quadTree.insert(p2);

      final result = quadTree.queryCircle(0, 0, 20);

      expect(result.length, equals(1));
      expect(result.first.index, equals(1));
    });
  });

  group('Statistics and Optimization', () {
    test('getStats returns correct values', () {
      const p1 = QuadTreeParticle(1, 25, 25);
      const p2 = QuadTreeParticle(2, 75, 75);
      quadTree.insert(p1);
      quadTree.insert(p2);

      final stats = quadTree.getStats();

      expect(stats['nodes'], isPositive);
      expect(stats['particles'], equals(2));
      expect(stats['leaves'], isPositive);
    });

    test('optimizeMemory removes empty nodes', () {
      // Insert and then remove particles to create empty nodes
      const p1 = QuadTreeParticle(1, 25, 25);
      const p2 = QuadTreeParticle(2, 75, 75);
      quadTree.insert(p1);
      quadTree.insert(p2);

      quadTree.clear();
      quadTree.optimizeMemory();

      expect(quadTree.isLeaf, isTrue);
      expect(quadTree.particles, isEmpty);
    });

    test('rebalance restructures the tree', () {
      // Insert particles to create an unbalanced tree
      List.generate(
        5,
        (i) => QuadTreeParticle(i, 25 + i.toDouble(), 25 + i.toDouble()),
      ).forEach(quadTree.insert);

      final beforeStats = quadTree.getStats();
      quadTree.rebalance();
      final afterStats = quadTree.getStats();

      expect(afterStats['particles'], equals(beforeStats['particles']));
    });
  });

  group('CompressedPath', () {
    test('initial construction is correct', () {
      final path = [Quadrant.northWest, Quadrant.northEast];
      final compressed = CompressedPath(path, 2);

      expect(compressed.path, equals(path));
      expect(compressed.depth, equals(2));
    });

    test('extend method creates new path correctly', () {
      const initial = CompressedPath([Quadrant.northWest], 1);
      final extended = initial.extend(Quadrant.northEast);

      expect(extended.path.length, equals(2));
      expect(extended.path[0], equals(Quadrant.northWest));
      expect(extended.path[1], equals(Quadrant.northEast));
      expect(extended.depth, equals(2));

      // Original should be unchanged
      expect(initial.path.length, equals(1));
      expect(initial.depth, equals(1));
    });

    test('toString returns correct format', () {
      const path = CompressedPath([
        Quadrant.northWest,
        Quadrant.southEast,
        Quadrant.northEast,
      ], 3);

      expect(
        path.toString(),
        equals('Path: northWest->southEast->northEast (depth: 3)'),
      );
    });
  });
}
