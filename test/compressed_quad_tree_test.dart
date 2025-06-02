import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/model/rectangle.dart';
import 'package:particles_network/quad_tree/compressed_quad_tree.dart';
import 'package:particles_network/quad_tree/compressed_quad_tree_node.dart';

void main() {
  late CompressedQuadTree quadTree;
  late Rectangle boundary;

  setUp(() {
    boundary = Rectangle(0, 0, 100, 100);
    quadTree = CompressedQuadTree(boundary);
  });

  group('CompressedQuadTree Initialization', () {
    test('should create empty tree with correct boundary', () {
      expect(quadTree.boundary, equals(boundary));
      expect(quadTree.getAllParticleIndices(), isEmpty);
    });
  });

  group('Particle Insertion', () {
    test('should insert particle successfully', () {
      final particle = QuadTreeParticle(1, 50, 50);
      expect(quadTree.insert(particle), isTrue);
      expect(quadTree.getAllParticleIndices(), contains(1));
    });

    test('should not insert particle outside boundary', () {
      final particle = QuadTreeParticle(1, 150, 150);
      expect(quadTree.insert(particle), isFalse);
      expect(quadTree.getAllParticleIndices(), isEmpty);
    });
  });

  group('Range Query', () {
    setUp(() {
      // Insert some test particles
      quadTree.insert(QuadTreeParticle(1, 25, 25));
      quadTree.insert(QuadTreeParticle(2, 75, 75));
      quadTree.insert(QuadTreeParticle(3, 10, 10));
    });

    test('should find particles in range', () {
      final queryRange = Rectangle(0, 0, 50, 50);
      final result = quadTree.queryRange(queryRange);
      expect(result, containsAll([1, 3]));
      expect(result, isNot(contains(2)));
    });
  });

  group('Circle Query', () {
    setUp(() {
      quadTree.insert(QuadTreeParticle(1, 50, 50));
      quadTree.insert(QuadTreeParticle(2, 10, 10));
      quadTree.insert(QuadTreeParticle(3, 90, 90));
    });

    test('should find particles within circle radius', () {
      final result = quadTree.queryCircle(50, 50, 20);
      expect(result, contains(1));
      expect(result, isNot(contains(2)));
      expect(result, isNot(contains(3)));
    });
  });

  group('Building from Particles', () {
    test('should build tree from particle list', () {
      final particles = [
        _MockParticle(10, 10),
        _MockParticle(30, 30),
        _MockParticle(50, 50),
      ];
      final visibleParticles = [0, 1, 2];

      quadTree.buildFromParticles(particles, visibleParticles);

      expect(quadTree.getAllParticleIndices().length, equals(3));
      expect(quadTree.getAllParticleIndices(), containsAll([0, 1, 2]));
    });
  });

  group('Optimization and Rebalancing', () {
    test('should determine need for rebalancing', () {
      // Add many particles to one quadrant to create imbalance
      for (var i = 0; i < 10; i++) {
        quadTree.insert(QuadTreeParticle(i, 10, 10));
      }

      final stats = quadTree.getStats();
      expect(stats, isA<Map<String, dynamic>>());
      expect(quadTree.needsRebalancing(), isA<bool>());
    });

    test('should rebalance tree', () {
      // Add particles and rebalance
      for (var i = 0; i < 5; i++) {
        quadTree.insert(QuadTreeParticle(i, 10, 10));
      }

      quadTree.rebalance();
      expect(quadTree.getAllParticleIndices().length, equals(5));
    });
  });

  group('Root Access', () {
    test('should return root node', () {
      expect(quadTree.root, isA<CompressedQuadTreeNode>());
      expect(quadTree.root.boundary, equals(boundary));
    });
  });

  group('Rebuild', () {
    test('should rebuild tree with new particles', () {
      // Initial build
      final initialParticles = [_MockParticle(10, 10), _MockParticle(20, 20)];
      final initialVisible = [0, 1];
      quadTree.buildFromParticles(initialParticles, initialVisible);
      expect(quadTree.getAllParticleIndices(), containsAll([0, 1]));

      // Rebuild with new particles
      final newParticles = [
        _MockParticle(30, 30),
        _MockParticle(40, 40),
        _MockParticle(50, 50),
      ];
      final newVisible = [0, 1, 2];
      quadTree.rebuild(newParticles, newVisible);

      // Verify rebuild results
      final indices = quadTree.getAllParticleIndices();
      expect(indices.length, equals(3));
      expect(indices, containsAll([0, 1, 2]));
    });
  });

  group('Memory Management', () {
    test('should clear tree', () {
      quadTree.insert(QuadTreeParticle(1, 50, 50));
      expect(quadTree.getAllParticleIndices(), isNotEmpty);

      quadTree.clear();
      expect(quadTree.getAllParticleIndices(), isEmpty);
    });

    test('should optimize memory', () {
      for (var i = 0; i < 5; i++) {
        quadTree.insert(QuadTreeParticle(i, i * 10.0, i * 10.0));
      }

      quadTree.optimize();
      expect(quadTree.getAllParticleIndices().length, equals(3));
    });
  });
}

class _MockParticle {
  final double dx;
  final double dy;

  _MockParticle(this.dx, this.dy);

  Position get position => Position(dx, dy);
}

class Position {
  final double dx;
  final double dy;

  Position(this.dx, this.dy);
}
