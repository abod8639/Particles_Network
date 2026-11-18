// ignore_for_file: deprecated_member_use
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/particles_network.dart';

void main() {
  group('StandardQuadTree', () {
    test('inserts particles and performs radius queries correctly', () {
      final tree = StandardQuadTree(width: 500, height: 500, nodeCapacity: 4);

      final p1 = Particle(
        position: const Offset(50, 50),
        velocity: const Offset(1, 1),
        color: Colors.white,
        size: 2,
      );
      final p2 = Particle(
        position: const Offset(60, 60),
        velocity: const Offset(1, 1),
        color: Colors.white,
        size: 2,
      );
      final p3 = Particle(
        position: const Offset(400, 400),
        velocity: const Offset(1, 1),
        color: Colors.white,
        size: 2,
      );

      final particles = [p1, p2, p3];
      final visible = [0, 1, 2];

      tree.build(particles, visible);

      final List<int> matches = [];
      tree.queryRadius(50, 50, 20, (idx, px, py, distSq) {
        matches.add(idx);
      });

      expect(matches, containsAll([0, 1]));
      expect(matches, isNot(contains(2)));
    });

    test('queryRadiusIndices collects matching indices', () {
      final tree = StandardQuadTree(width: 300, height: 300, nodeCapacity: 2);
      final particles = [
        Particle(
          position: const Offset(10, 10),
          velocity: Offset.zero,
          color: Colors.white,
          size: 2,
        ),
        Particle(
          position: const Offset(20, 20),
          velocity: Offset.zero,
          color: Colors.white,
          size: 2,
        ),
        Particle(
          position: const Offset(100, 100),
          velocity: Offset.zero,
          color: Colors.white,
          size: 2,
        ),
      ];

      tree.build(particles, [0, 1, 2]);
      final output = <int>[];
      tree.queryRadiusIndices(15, 15, 10, output);
      expect(output, containsAll([0, 1]));
      expect(output, isNot(contains(2)));
    });

    test(
        'handles edge cases, boundary clamping, and non-finite values gracefully',
        () {
      final tree = StandardQuadTree(width: 200, height: 200, nodeCapacity: 2);

      // Uninitialized / clear
      tree.clear();
      int calls = 0;
      tree.queryRadius(10, 10, 5, (_, __, ___, ____) => calls++);
      expect(calls, equals(0));

      // Particles with slight boundary overflow and non-finite
      final particles = [
        Particle(
          position:
              const Offset(-0.5, 50), // slightly left of bounds -> clamped to 0
          velocity: Offset.zero,
          color: Colors.white,
          size: 2,
        ),
        Particle(
          position: const Offset(200.5, 50), // slightly right -> clamped to 200
          velocity: Offset.zero,
          color: Colors.white,
          size: 2,
        ),
        Particle(
          position: const Offset(double.nan, 50), // non-finite -> skipped
          velocity: Offset.zero,
          color: Colors.white,
          size: 2,
        ),
      ];

      tree.build(particles,
          [0, 1, 2, 99]); // 99 is invalid index, should be skipped safely

      final found = <int>[];
      tree.queryRadius(0, 50, 5, (idx, px, py, distSq) => found.add(idx));
      expect(found, contains(0));

      final foundRight = <int>[];
      tree.queryRadius(
          200, 50, 5, (idx, px, py, distSq) => foundRight.add(idx));
      expect(foundRight, contains(1));

      // Non-finite query parameters
      calls = 0;
      tree.queryRadius(double.nan, 50, 10, (_, __, ___, ____) => calls++);
      tree.queryRadius(50, double.infinity, 10, (_, __, ___, ____) => calls++);
      tree.queryRadius(50, 50, double.nan, (_, __, ___, ____) => calls++);
      tree.queryRadius(50, 50, -5, (_, __, ___, ____) => calls++);
      tree.queryRadius(50, 50, 0, (_, __, ___, ____) => calls++);
      expect(calls, equals(0));

      // Invalid dimensions
      final invalidTree = StandardQuadTree(width: -10, height: 100);
      invalidTree.build(particles, [0]);
      calls = 0;
      invalidTree.queryRadius(0, 0, 10, (_, __, ___, ____) => calls++);
      expect(calls, equals(0));
    });

    test(
        'handles maxDepth subdivision gracefully when particles share identical coordinates',
        () {
      final tree = StandardQuadTree(
          width: 100, height: 100, nodeCapacity: 2, maxDepth: 4);
      final particles = List.generate(
        10,
        (i) => Particle(
          position: const Offset(50, 50),
          velocity: Offset.zero,
          color: Colors.white,
          size: 2,
        ),
      );

      final visible = List.generate(10, (i) => i);
      tree.build(particles, visible);

      final matches = <int>[];
      tree.queryRadius(50, 50, 1, (idx, px, py, distSq) => matches.add(idx));
      expect(matches.length, equals(10));
    });
  });
}
