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

      const updatedBoundary = Rectangle(10, 20, 200, 300);
      quadTree.updateBoundary(updatedBoundary);
      expect(quadTree.boundary, equals(updatedBoundary));
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
}
