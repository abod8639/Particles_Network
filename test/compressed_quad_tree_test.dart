import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/particles_network.dart';

void main() {
  late CompressedQuadTree quadTree;
  late Rectangle boundary;

  setUp(() {
    boundary = const Rectangle(0, 0, 100, 100);
    quadTree = CompressedQuadTree(boundary);
  });

  group('CompressedQuadTree Initialization', () {
    test('should create empty tree with correct boundary', () {
      expect(quadTree.boundary, equals(boundary));
      expect(quadTree.getAllParticleIndices(), isEmpty);
    });

    test('should expose root node', () {
      expect(quadTree.root, isNotNull);
      expect(quadTree.root, isA<CompressedQuadTreeNode>());
    });
  });

  group('Particle Insertion', () {
    test('should insert particle successfully', () {
      const particle = QuadTreeParticle(1, 50, 50);
      expect(quadTree.insert(particle), isTrue);
      expect(quadTree.getAllParticleIndices(), contains(1));
    });

    test('should not insert particle outside boundary', () {
      const particle = QuadTreeParticle(1, 150, 150);
      expect(quadTree.insert(particle), isFalse);
      expect(quadTree.getAllParticleIndices(), isEmpty);
    });
  });

  group('Range Query', () {
    setUp(() {
      quadTree.insert(const QuadTreeParticle(1, 25, 25));
      quadTree.insert(const QuadTreeParticle(2, 75, 75));
      quadTree.insert(const QuadTreeParticle(3, 10, 10));
    });

    test('should find particles in range', () {
      const queryRange = Rectangle(0, 0, 50, 50);
      final result = quadTree.queryRange(queryRange);
      expect(result, containsAll([1, 3]));
      expect(result, isNot(contains(2)));
    });
  });

  group('Circle Query', () {
    setUp(() {
      quadTree.insert(const QuadTreeParticle(1, 50, 50));
      quadTree.insert(const QuadTreeParticle(2, 10, 10));
      quadTree.insert(const QuadTreeParticle(3, 90, 90));
    });

    test('should find particles within circle radius', () {
      final result = quadTree.queryCircle(50, 50, 20);
      expect(result, contains(1));
      expect(result, isNot(contains(2)));
      expect(result, isNot(contains(3)));
    });

    test('findNearbyParticles should be a wrapper for queryCircle', () {
      final result = quadTree.findNearbyParticles(50, 50, 20);
      expect(result, contains(1));
      expect(result, isNot(contains(2)));
      expect(result, isNot(contains(3)));
    });

    test('findNearbyParticlesToOutput should populate existing list', () {
      final List<int> output = [];
      quadTree.findNearbyParticlesToOutput(50, 50, 20, output);
      expect(output, contains(1));
      expect(output, isNot(contains(2)));
      expect(output, isNot(contains(3)));
    });
  });

  group('Building from Particles', () {
    test('should build tree from particle list', () {
      final List<Particle> particles = [
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
      for (var i = 0; i < 10; i++) {
        quadTree.insert(QuadTreeParticle(i, 10, 10));
      }

      final stats = quadTree.getStats();
      expect(stats, isA<Map<String, dynamic>>());
      expect(quadTree.needsRebalancing(), isA<bool>());
    });

    test('should rebalance tree', () {
      for (var i = 0; i < 5; i++) {
        quadTree.insert(QuadTreeParticle(i, 10, 10));
      }

      quadTree.rebalance();
      expect(quadTree.getAllParticleIndices().length, equals(5));
    });
  });

  group('Rebuild', () {
    test('should rebuild tree with new particles', () {
      final List<Particle> initialParticles = [
        _MockParticle(10, 10),
        _MockParticle(20, 20),
      ];
      final initialVisible = [0, 1];
      quadTree.buildFromParticles(initialParticles, initialVisible);
      expect(quadTree.getAllParticleIndices(), containsAll([0, 1]));

      final List<Particle> newParticles = [
        _MockParticle(30, 30),
        _MockParticle(40, 40),
        _MockParticle(50, 50),
      ];
      final newVisible = [0, 1, 2];
      quadTree.rebuild(newParticles, newVisible);

      final indices = quadTree.getAllParticleIndices();
      expect(indices.length, equals(3));
      expect(indices, containsAll([0, 1, 2]));
    });
  });

  group('Memory Management', () {
    test('should clear tree', () {
      quadTree.insert(const QuadTreeParticle(1, 50, 50));
      quadTree.clear();
      expect(quadTree.getAllParticleIndices(), isEmpty);
    });

    test('should optimize memory', () {
      for (var i = 0; i < 5; i++) {
        quadTree.insert(QuadTreeParticle(i, 10, 10));
      }

      quadTree.optimize();
      expect(quadTree.getAllParticleIndices().length, greaterThan(0));
    });

    test('subdivide handles remaining particles when insertion into children fails (L199-L201)', () {
      // Create a node with capacity 4 and depth 0.
      final node = CompressedQuadTreeNode(const Rectangle(0, 0, 100, 100), 0);
      
      // Insert 4 particles at identical position (10, 10) to reach max capacity (maxParticlesPerNode = 4).
      for (int i = 0; i < 4; i++) {
        node.insert(QuadTreeParticle(i, 10, 10));
      }

      // At this point node.particles.length == 4 and isSubdivided == false.
      // Inserting 5th particle triggers _subdivide() -> _subdivideNormal().
      // During subdivision, particles at (10, 10) go to NorthWest child node.
      // Inserting 5th particle at position outside boundary or edge case verifies subdivision logic.
      expect(node.insert(const QuadTreeParticle(4, 10, 10)), isTrue);
      expect(node.isLeaf, isFalse);
    });
  });
}

class _MockParticle extends Particle {
  _MockParticle(double x, double y)
      : super(
          position: ui.Offset(x, y),
          velocity: ui.Offset.zero,
          color: const ui.Color(0xFF000000),
          size: 2.0,
          isVisible: true,
        );
}

