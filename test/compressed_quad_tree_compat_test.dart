// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/particles_network.dart';

void main() {
  group('CompressedQuadTree Backward Compatibility & Red Warning Test', () {
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
