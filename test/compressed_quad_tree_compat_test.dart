// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/particles_network.dart';

class _MockParticlePoint {
  final double x;
  final double y;
  const _MockParticlePoint(this.x, this.y);
}

void main() {
  group('CompressedQuadTree Backward Compatibility & Red Warning Test', () {
    test('QuadTreeParticle holds index, x, and y coordinate values', () {
      const particle = QuadTreeParticle(42, 123.45, 678.90);
      expect(particle.index, equals(42));
      expect(particle.x, equals(123.45));
      expect(particle.y, equals(678.90));
    });

    test('boundary getter and updateBoundary correctly update and report boundary', () {
      const initialBoundary = Rectangle(0, 0, 100, 100);
      final quadTree = CompressedQuadTree(initialBoundary);
      expect(quadTree.boundary, equals(initialBoundary));
      expect(quadTree.root.boundary, equals(initialBoundary));
      expect(quadTree.root.particles, isEmpty);

      // 1. Only x differs
      final root1 = quadTree.root;
      quadTree.updateBoundary(const Rectangle(10, 0, 100, 100));
      expect(quadTree.boundary, equals(const Rectangle(10, 0, 100, 100)));
      expect(quadTree.root, isNot(same(root1)));
      expect(quadTree.root.boundary.x, equals(10));

      // 2. Only y differs (x is identical, triggers L81)
      final root2 = quadTree.root;
      quadTree.updateBoundary(const Rectangle(10, 20, 100, 100));
      expect(quadTree.boundary, equals(const Rectangle(10, 20, 100, 100)));
      expect(quadTree.root, isNot(same(root2)));
      expect(quadTree.root.boundary.y, equals(20));

      // 3. Only width differs (x and y are identical, triggers L82)
      final root3 = quadTree.root;
      quadTree.updateBoundary(const Rectangle(10, 20, 150, 100));
      expect(quadTree.boundary, equals(const Rectangle(10, 20, 150, 100)));
      expect(quadTree.root, isNot(same(root3)));
      expect(quadTree.root.boundary.width, equals(150));

      // 4. Only height differs (x, y, and width are identical, triggers L83)
      final root4 = quadTree.root;
      quadTree.updateBoundary(const Rectangle(10, 20, 150, 250));
      expect(quadTree.boundary, equals(const Rectangle(10, 20, 150, 250)));
      expect(quadTree.root, isNot(same(root4)));
      expect(quadTree.root.boundary.height, equals(250));

      // 5. Unchanged boundary (all 4 conditions evaluated and false, root preserved)
      final root5 = quadTree.root;
      quadTree.updateBoundary(const Rectangle(10, 20, 150, 250));
      expect(quadTree.boundary, equals(const Rectangle(10, 20, 150, 250)));
      expect(identical(quadTree.root, root5), isTrue);
    });

    test(
        'exact 1.9.6 README architecture snippet executes correctly without crashing',
        () {
      const width = 500.0;
      const height = 500.0;

      // 1.9.6 README syntax:
      final quadTree = CompressedQuadTree(const Rectangle(0, 0, width, height));

      final mockParticles = [
        const QuadTreeParticle(0, 50.0, 50.0),
        const QuadTreeParticle(1, 60.0, 60.0),
        const QuadTreeParticle(2, 400.0, 400.0),
      ];

      for (int i = 0; i < mockParticles.length; i++) {
        quadTree.insert(mockParticles[i]);
      }

      const touchX = 55.0;
      const touchY = 55.0;
      const radius = 20.0;

      final nearbyParticleIndices =
          quadTree.queryCircle(touchX, touchY, radius);

      expect(nearbyParticleIndices, containsAll([0, 1]));
      expect(nearbyParticleIndices, isNot(contains(2)));
    });

    test('findNearbyParticles queries particles within search radius', () {
      final quadTree = CompressedQuadTree(const Rectangle(0, 0, 500, 500));
      quadTree.insert(const QuadTreeParticle(0, 50.0, 50.0));
      quadTree.insert(const QuadTreeParticle(1, 55.0, 55.0));
      quadTree.insert(const QuadTreeParticle(2, 200.0, 200.0));

      final nearby = quadTree.findNearbyParticles(50.0, 50.0, 10.0);
      expect(nearby, containsAll([0, 1]));
      expect(nearby, isNot(contains(2)));
    });

    test('buildFromParticles populates tree from particle list and filters out-of-bounds indices', () {
      final quadTree = CompressedQuadTree(const Rectangle(0, 0, 500, 500));
      quadTree.insert(const QuadTreeParticle(999, 1.0, 1.0));

      final particles = [
        const _MockParticlePoint(10.0, 10.0),
        const _MockParticlePoint(20.0, 20.0),
        const _MockParticlePoint(30.0, 30.0),
      ];

      // visibleParticles contains indices 0, 2, and an out-of-bounds index 50
      quadTree.buildFromParticles(particles, [0, 2, 50]);

      expect(quadTree.getAllParticleIndices(), equals([0, 2]));
    });

    test('rebuild delegates to buildFromParticles and replaces existing particles', () {
      final quadTree = CompressedQuadTree(const Rectangle(0, 0, 500, 500));
      quadTree.insert(const QuadTreeParticle(888, 5.0, 5.0));

      final particles = [
        const _MockParticlePoint(100.0, 100.0),
        const _MockParticlePoint(200.0, 200.0),
      ];

      quadTree.rebuild(particles, [1]);

      expect(quadTree.getAllParticleIndices(), equals([1]));
      final nearby = quadTree.findNearbyParticles(200.0, 200.0, 5.0);
      expect(nearby, equals([1]));
    });

    test('getStats reports accurate particle count and deprecated flag', () {
      final quadTree = CompressedQuadTree(const Rectangle(0, 0, 200, 200));
      expect(quadTree.getStats(), equals({'totalParticles': 0, 'deprecated': true}));

      quadTree.insert(const QuadTreeParticle(0, 10, 10));
      quadTree.insert(const QuadTreeParticle(1, 20, 20));

      final stats = quadTree.getStats();
      expect(stats['totalParticles'], equals(2));
      expect(stats['deprecated'], isTrue);
    });

    test('optimize, rebalance, and needsRebalancing compatibility no-op stubs', () {
      final quadTree = CompressedQuadTree(const Rectangle(0, 0, 200, 200));
      quadTree.insert(const QuadTreeParticle(0, 50, 50));

      expect(() => quadTree.optimize(), returnsNormally);
      expect(() => quadTree.rebalance(), returnsNormally);
      expect(quadTree.needsRebalancing(), isFalse);
    });

    test('queryRange and buffer output helpers function properly', () {
      final quadTree = CompressedQuadTree(const Rectangle(0, 0, 300, 300));
      quadTree.insert(const QuadTreeParticle(0, 10, 10));
      quadTree.insert(const QuadTreeParticle(1, 200, 200));

      final output = <int>[];
      quadTree.findNearbyParticlesToOutput(10, 10, 15, output);
      expect(output, equals([0]));

      final inRange = quadTree.queryRange(const Rectangle(150, 150, 100, 100));
      expect(inRange, equals([1]));

      expect(quadTree.getAllParticleIndices(), containsAll([0, 1]));

      quadTree.clear();
      expect(quadTree.getAllParticleIndices(), isEmpty);
    });
  });

  group('CompressedPath and Quadrant Unit Tests', () {
    test('CompressedPath creates path, extends, and formats toString', () {
      const initialPath = CompressedPath([Quadrant.northWest], 1);
      expect(initialPath.path, equals([Quadrant.northWest]));
      expect(initialPath.depth, equals(1));
      expect(initialPath.toString(), contains('northWest'));
      expect(initialPath.toString(), contains('depth: 1'));

      final extended = initialPath.extend(Quadrant.southEast);
      expect(extended.path, equals([Quadrant.northWest, Quadrant.southEast]));
      expect(extended.depth, equals(2));
      expect(extended.toString(), contains('northWest->southEast'));
    });
  });

  group('CompressedQuadTreeNode Unit Tests', () {
    test('initializes with boundary and default depth', () {
      final node = CompressedQuadTreeNode(const Rectangle(0, 0, 100, 100));
      expect(node.boundary, equals(const Rectangle(0, 0, 100, 100)));
      expect(node.depth, equals(0));
      expect(node.compressedPath, isNull);
      expect(node.isCompressed, isFalse);
      expect(node.isLeaf, isTrue);
      expect(node.hasOnlyOneChild, isFalse);
      expect(node.particles, isEmpty);
      expect(node.children, isEmpty);
    });

    test('insert rejects points outside node boundary', () {
      final node = CompressedQuadTreeNode(const Rectangle(0, 0, 100, 100));
      expect(node.insert(const QuadTreeParticle(0, 150, 50)), isFalse);
      expect(node.insert(const QuadTreeParticle(1, -10, 50)), isFalse);
      expect(node.particles, isEmpty);
    });

    test('insert adds particles up to maxParticles without subdivision', () {
      final node = CompressedQuadTreeNode(const Rectangle(0, 0, 100, 100));
      expect(node.insert(const QuadTreeParticle(0, 10, 10)), isTrue);
      expect(node.insert(const QuadTreeParticle(1, 20, 20)), isTrue);
      expect(node.isLeaf, isTrue);
      expect(node.particles.length, equals(2));
    });

    test('insert subdivides into quadrants when capacity exceeded', () {
      final node = CompressedQuadTreeNode(const Rectangle(0, 0, 100, 100));
      // Insert in NW, NE, SW, SE
      expect(node.insert(const QuadTreeParticle(0, 20, 20)), isTrue); // NW
      expect(node.insert(const QuadTreeParticle(1, 80, 20)), isTrue); // NE
      expect(node.insert(const QuadTreeParticle(2, 20, 80)), isTrue); // SW (triggers subdivision)
      expect(node.insert(const QuadTreeParticle(3, 80, 80)), isTrue); // SE

      expect(node.isLeaf, isFalse);
      expect(node.children.length, equals(4));
      expect(node.children.containsKey(Quadrant.northWest), isTrue);
      expect(node.children.containsKey(Quadrant.northEast), isTrue);
      expect(node.children.containsKey(Quadrant.southWest), isTrue);
      expect(node.children.containsKey(Quadrant.southEast), isTrue);

      expect(node.getAllParticles().length, equals(4));
    });

    test('insert with path compression across all four quadrants (L286-L292)', () {
      final quadrantCoords = <Quadrant, Offset>{
        Quadrant.northWest: const Offset(10, 10),
        Quadrant.northEast: const Offset(80, 10),
        Quadrant.southWest: const Offset(10, 80),
        Quadrant.southEast: const Offset(80, 80),
      };

      for (final entry in quadrantCoords.entries) {
        final quad = entry.key;
        final base = entry.value;

        final node = CompressedQuadTreeNode(const Rectangle(0, 0, 100, 100));
        // First 2 particles in this quadrant
        node.insert(QuadTreeParticle(0, base.dx + 1, base.dy + 1));
        node.insert(QuadTreeParticle(1, base.dx + 2, base.dy + 2));

        // Manually add third particle to reach minParticlesForCompression (>= 3)
        node.particles.add(QuadTreeParticle(2, base.dx + 3, base.dy + 3));

        // 4th particle in exact same sub-quadrant triggers compression for this quadrant
        expect(node.insert(QuadTreeParticle(3, base.dx + 4, base.dy + 4)), isTrue);
        expect(node.children[quad], isNotNull);
        expect(node.children[quad]!.isCompressed, isTrue);
        expect(node.children[quad]!.compressedPath, isNotNull);
        expect(node.children[quad]!.compressedPath!.path, contains(quad));
      }
    });

    test('insert at maxDepth falls back to storing in current node', () {
      final node = CompressedQuadTreeNode(
        const Rectangle(0, 0, 100, 100),
        CompressedQuadTreeNode.maxDepth,
      );

      expect(node.insert(const QuadTreeParticle(0, 10, 10)), isTrue);
      expect(node.insert(const QuadTreeParticle(1, 20, 20)), isTrue);
      expect(node.insert(const QuadTreeParticle(2, 30, 30)), isTrue);
      expect(node.isLeaf, isTrue);
      expect(node.particles.length, equals(3));
    });

    test('queryRange, queryCircle, and queryCircleIndices query particles correctly', () {
      final node = CompressedQuadTreeNode(const Rectangle(0, 0, 200, 200));
      node.insert(const QuadTreeParticle(0, 20, 20));
      node.insert(const QuadTreeParticle(1, 30, 30));
      node.insert(const QuadTreeParticle(2, 180, 180));

      // queryRange
      final rangeResult = node.queryRange(const Rectangle(0, 0, 50, 50));
      expect(rangeResult.map((p) => p.index), containsAll([0, 1]));
      expect(rangeResult.map((p) => p.index), isNot(contains(2)));

      // queryRange with non-intersecting range
      final emptyRange = node.queryRange(const Rectangle(300, 300, 50, 50));
      expect(emptyRange, isEmpty);

      // queryCircle
      final circleResult = node.queryCircle(25, 25, 15);
      expect(circleResult.map((p) => p.index), containsAll([0, 1]));
      expect(circleResult.map((p) => p.index), isNot(contains(2)));

      // queryCircle outside boundary
      final emptyCircle = node.queryCircle(500, 500, 10);
      expect(emptyCircle, isEmpty);

      // queryCircleIndices directly into output list
      final indicesOutput = <int>[];
      node.queryCircleIndices(25, 25, 15, indicesOutput);
      expect(indicesOutput, containsAll([0, 1]));
      expect(indicesOutput, isNot(contains(2)));
    });

    test('getStats, optimizeMemory, rebalance, and clear work as expected', () {
      final node = CompressedQuadTreeNode(const Rectangle(0, 0, 200, 200));
      node.insert(const QuadTreeParticle(0, 20, 20));
      node.insert(const QuadTreeParticle(1, 150, 150));
      node.insert(const QuadTreeParticle(2, 160, 160)); // Subdivides

      final stats = node.getStats();
      expect(stats['nodes'], greaterThan(1));
      expect(stats['particles'], equals(3));
      expect(stats['maxDepth'], greaterThanOrEqualTo(1));
      expect(stats['leaves'], greaterThan(0));

      // optimizeMemory
      expect(() => node.optimizeMemory(), returnsNormally);

      // rebalance
      expect(() => node.rebalance(), returnsNormally);
      expect(node.getAllParticles().length, equals(3));

      // clear
      node.clear();
      expect(node.isLeaf, isTrue);
      expect(node.particles, isEmpty);
      expect(node.getAllParticles(), isEmpty);
    });
  });
}
