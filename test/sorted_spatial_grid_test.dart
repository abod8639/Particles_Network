// ignore_for_file: deprecated_member_use
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/particles_network.dart';
import 'package:particles_network/src/legacy/legacy_deprecation_logger.dart';

List<Particle> _scatter(int n, Size size, int seed, {double spill = 0}) {
  final r = Random(seed);
  return List<Particle>.generate(
    n,
    (_) => Particle(
      // spill > 0 places some particles slightly outside the area.
      position: Offset(
        r.nextDouble() * (size.width + 2 * spill) - spill,
        r.nextDouble() * (size.height + 2 * spill) - spill,
      ),
      velocity: Offset.zero,
      color: Colors.white,
      size: 1,
    ),
  );
}

int _bruteForcePairs(List<Particle> ps, double radius) {
  final double r2 = radius * radius;
  int count = 0;
  for (int i = 0; i < ps.length; i++) {
    for (int j = i + 1; j < ps.length; j++) {
      final double dx = ps[i].x - ps[j].x;
      final double dy = ps[i].y - ps[j].y;
      if (dx * dx + dy * dy <= r2) count++;
    }
  }
  return count;
}

void main() {
  group('SortedSpatialGrid', () {
    test('sorts every particle into the cell that contains it', () {
      const size = Size(300, 200);
      final ps = _scatter(500, size, 1, spill: 20);
      final visible = List<int>.generate(ps.length, (i) => i);
      final grid = SortedSpatialGrid()
        ..build(ps, visible, size.width, size.height, 25);

      expect(grid.count, 500);
      expect(grid.cellSize, greaterThanOrEqualTo(25));
      expect(grid.cellStart[grid.cols * grid.rows], 500);
      expect(grid.indices.sublist(0, 500).toSet().length, 500);

      for (int c = 0; c < grid.cols * grid.rows; c++) {
        final int cx = c % grid.cols;
        final int cy = c ~/ grid.cols;
        for (int k = grid.cellStart[c]; k < grid.cellStart[c + 1]; k++) {
          final Particle p = ps[grid.indices[k]];
          expect(grid.xs[k], p.x);
          expect(grid.ys[k], p.y);
          final int px = (p.x / grid.cellSize).floor().clamp(0, grid.cols - 1);
          final int py = (p.y / grid.cellSize).floor().clamp(0, grid.rows - 1);
          expect((px, py), (cx, cy));
        }
      }
    });

    test('only includes visible particles', () {
      const size = Size(100, 100);
      final ps = _scatter(10, size, 2);
      final grid = SortedSpatialGrid()..build(ps, [1, 3, 5], 100, 100, 10);
      expect(grid.count, 3);
      expect(grid.indices.sublist(0, 3).toSet(), {1, 3, 5});
    });

    test('keeps cell count near the particle count for tiny radii', () {
      const size = Size(1920, 1080);
      final ps = _scatter(2000, size, 3);
      final visible = List<int>.generate(ps.length, (i) => i);
      final grid = SortedSpatialGrid()..build(ps, visible, 1920, 1080, 1);
      expect(grid.cols * grid.rows, lessThan(2000 * 2));
    });

    test(
        'resets cols and rows to 0 when dimensions, radius, or count are non-positive (L68-L69)',
        () {
      final grid = SortedSpatialGrid();
      const size = Size(100, 100);
      final ps = _scatter(10, size, 1);
      final visible = [0, 1, 2];

      // Build with valid parameters first
      grid.build(ps, visible, 100, 100, 20);
      expect(grid.cols, greaterThan(0));
      expect(grid.rows, greaterThan(0));

      // width <= 0
      grid.build(ps, visible, 0, 100, 20);
      expect(grid.cols, equals(0));
      expect(grid.rows, equals(0));

      // height <= 0
      grid.build(ps, visible, 100, -10, 20);
      expect(grid.cols, equals(0));
      expect(grid.rows, equals(0));

      // radius <= 0
      grid.build(ps, visible, 100, 100, 0);
      expect(grid.cols, equals(0));
      expect(grid.rows, equals(0));

      // visible is empty (n == 0)
      grid.build(ps, [], 100, 100, 20);
      expect(grid.cols, equals(0));
      expect(grid.rows, equals(0));
      expect(grid.count, equals(0));
    });
  });

  group('Sorted pair search matches brute force', () {
    for (final (int n, double radius, Size size, double spill) in [
      (300, 60.0, const Size(400, 400), 0.0),
      (800, 25.0, const Size(400, 800), 30.0),
      (1500, 9.0, const Size(1000, 600), 0.0),
      (200, 150.0, const Size(300, 300), 10.0),
    ]) {
      for (final bool unified in [false, true]) {
        test('n=$n r=$radius unified=$unified', () {
          final ps = _scatter(n, size, n, spill: spill);
          final painter = OptimizedNetworkPainter(
            particleCount: n,
            particles: ps,
            touchPoint: null,
            lineDistance: radius,
            particleColor: Colors.white,
            lineColor: Colors.white,
            touchColor: Colors.amber,
            touchActivation: false,
            lineWidth: 1,
            isComplex: false,
            fill: true,
            drawNetwork: true,
            fastLineRendering: unified,
          );
          final recorder = PictureRecorder();
          painter.paint(Canvas(recorder), size);
          recorder.endRecording().dispose();

          // Particles beyond the 50 px margin are invisible and skipped.
          final visibleParticles = ps.where((p) => p.isVisible).toList();
          expect(
            painter.lastFrameLineCount,
            _bruteForcePairs(visibleParticles, radius),
          );
        });
      }
    }

    test('maxConnectionsPerParticle still caps every particle', () {
      const size = Size(400, 400);
      final ps = _scatter(600, size, 9);
      final painter = OptimizedNetworkPainter(
        particleCount: ps.length,
        particles: ps,
        touchPoint: null,
        lineDistance: 80,
        particleColor: Colors.white,
        lineColor: Colors.white,
        touchColor: Colors.amber,
        touchActivation: false,
        lineWidth: 1,
        isComplex: false,
        fill: true,
        drawNetwork: true,
        maxConnectionsPerParticle: 3,
      );
      final recorder = PictureRecorder();
      painter.paint(Canvas(recorder), size);
      recorder.endRecording().dispose();

      // Each line uses two endpoints, each endpoint has at most 3 lines.
      expect(painter.lastFrameLineCount, lessThanOrEqualTo(600 * 3 ~/ 2));
      expect(painter.lastFrameLineCount, greaterThan(600 ~/ 2));
    });
  });

  group('SortedSpatialGrid Query API & Extensions', () {
    test('isInitialized reports correct readiness state', () {
      final grid = SortedSpatialGrid();
      expect(grid.isInitialized, isFalse);

      final ps = _scatter(10, const Size(100, 100), 1);
      grid.build(ps, [0, 1, 2], 100, 100, 20);
      expect(grid.isInitialized, isTrue);

      grid.build(ps, [], 100, 100, 20);
      expect(grid.isInitialized, isFalse);
    });

    test('particleCountInCell and particleCountAt report correct cell counts',
        () {
      final p1 = Particle(
        position: const Offset(10, 10),
        velocity: Offset.zero,
        color: Colors.white,
        size: 1,
      );
      final p2 = Particle(
        position: const Offset(15, 15),
        velocity: Offset.zero,
        color: Colors.white,
        size: 1,
      );
      final pFar = Particle(
        position: const Offset(150, 150),
        velocity: Offset.zero,
        color: Colors.white,
        size: 1,
      );

      final grid = SortedSpatialGrid()
        ..build([p1, p2, pFar], [0, 1, 2], 200, 200, 50);

      expect(grid.particleCountAt(12, 12), equals(2));
      expect(grid.particleCountAt(150, 150), equals(1));
      expect(grid.particleCountAt(190, 10), equals(0));
      expect(grid.particleCountAt(-10, 10), equals(0));
      expect(grid.particleCountAt(double.nan, 10), equals(0));

      expect(grid.particleCountInCell(0, 0), equals(2));
      expect(grid.particleCountInCell(-1, 0), equals(0));
      expect(grid.particleCountInCell(99, 99), equals(0));
    });

    test('queryRadius matches brute force search and ignores far particles',
        () {
      const size = Size(300, 300);
      final ps = _scatter(150, size, 42);
      final visible = List<int>.generate(ps.length, (i) => i);
      final grid = SortedSpatialGrid()
        ..build(ps, visible, size.width, size.height, 40);

      const target = Offset(120, 120);
      const queryRadius = 35.0;
      final foundIndices = <int>{};

      grid.queryRadius(target.dx, target.dy, queryRadius,
          (idx, px, py, distSq) {
        expect(distSq, lessThanOrEqualTo(queryRadius * queryRadius));
        expect((ps[idx].x - px).abs(), lessThan(1e-6));
        expect((ps[idx].y - py).abs(), lessThan(1e-6));
        foundIndices.add(idx);
      });

      // Brute force verification
      final expected = <int>{};
      for (int i = 0; i < ps.length; i++) {
        final double dx = ps[i].x - target.dx;
        final double dy = ps[i].y - target.dy;
        if (dx * dx + dy * dy <= queryRadius * queryRadius) {
          expected.add(i);
        }
      }

      expect(foundIndices, equals(expected));
    });

    test('queryRadius handles edge cases gracefully without throwing', () {
      final grid = SortedSpatialGrid();
      // Uninitialized
      int calls = 0;
      grid.queryRadius(10, 10, 20, (_, __, ___, ____) => calls++);
      expect(calls, equals(0));

      final ps = _scatter(10, const Size(100, 100), 5);
      grid.build(ps, [0, 1], 100, 100, 20);

      // Non-finite
      grid.queryRadius(double.nan, 10, 20, (_, __, ___, ____) => calls++);
      grid.queryRadius(10, double.infinity, 20, (_, __, ___, ____) => calls++);
      grid.queryRadius(10, 10, -5, (_, __, ___, ____) => calls++);
      grid.queryRadius(10, 10, 0, (_, __, ___, ____) => calls++);
      // Out of bounds
      grid.queryRadius(-200, -200, 10, (_, __, ___, ____) => calls++);
      grid.queryRadius(500, 500, 10, (_, __, ___, ____) => calls++);
      expect(calls, equals(0));
    });

    test('queryRect matches brute force AABB search', () {
      const size = Size(400, 400);
      final ps = _scatter(200, size, 88);
      final visible = List<int>.generate(ps.length, (i) => i);
      final grid = SortedSpatialGrid()
        ..build(ps, visible, size.width, size.height, 50);

      const rect = Rect.fromLTRB(50, 50, 180, 220);
      final found = <int>{};

      grid.queryRect(rect.left, rect.top, rect.right, rect.bottom,
          (idx, px, py) {
        expect(px, greaterThanOrEqualTo(rect.left));
        expect(px, lessThanOrEqualTo(rect.right));
        expect(py, greaterThanOrEqualTo(rect.top));
        expect(py, lessThanOrEqualTo(rect.bottom));
        found.add(idx);
      });

      final expected = <int>{};
      for (int i = 0; i < ps.length; i++) {
        if (ps[i].x >= rect.left &&
            ps[i].x <= rect.right &&
            ps[i].y >= rect.top &&
            ps[i].y <= rect.bottom) {
          expected.add(i);
        }
      }

      expect(found, equals(expected));
    });

    test('queryRect handles edge cases', () {
      final grid = SortedSpatialGrid();
      int calls = 0;
      // Inverted rect
      grid.queryRect(100, 100, 50, 50, (_, __, ___) => calls++);
      // Non-finite
      grid.queryRect(double.nan, 0, 10, 10, (_, __, ___) => calls++);
      // Out of bounds
      grid.queryRect(-200, -200, -100, -100, (_, __, ___) => calls++);
      expect(calls, equals(0));
    });

    test('forEachPair matches brute force pairs exactly without duplicates',
        () {
      const size = Size(300, 300);
      const radius = 45.0;
      final ps = _scatter(100, size, 123);
      final visible = List<int>.generate(ps.length, (i) => i);
      final grid = SortedSpatialGrid()
        ..build(ps, visible, size.width, size.height, radius);

      final foundPairs = <(int, int)>{};
      grid.forEachPair(radius, (i1, i2, distSq) {
        expect(distSq, lessThanOrEqualTo(radius * radius));
        final pair = i1 < i2 ? (i1, i2) : (i2, i1);
        expect(foundPairs.contains(pair), isFalse,
            reason: 'Duplicate pair ($i1, $i2)');
        foundPairs.add(pair);
      });

      expect(foundPairs.length, equals(_bruteForcePairs(ps, radius)));
    });

    test('forEachPair handles uninitialized and non-positive radius', () {
      final grid = SortedSpatialGrid();
      int calls = 0;
      grid.forEachPair(50, (_, __, ___) => calls++);
      expect(calls, equals(0));

      final ps = _scatter(5, const Size(100, 100), 1);
      grid.build(ps, [0, 1], 100, 100, 20);
      grid.forEachPair(-10, (_, __, ___) => calls++);
      grid.forEachPair(0, (_, __, ___) => calls++);
      grid.forEachPair(double.nan, (_, __, ___) => calls++);
      expect(calls, equals(0));
    });

    test('forEachParticle visits all particles in grid', () {
      final ps = _scatter(25, const Size(100, 100), 7);
      final visible = [2, 4, 6, 8, 10];
      final grid = SortedSpatialGrid()..build(ps, visible, 100, 100, 20);

      final visited = <int>{};
      grid.forEachParticle((idx, px, py) {
        visited.add(idx);
        expect(ps[idx].x, equals(px));
        expect(ps[idx].y, equals(py));
      });

      expect(visited, equals({2, 4, 6, 8, 10}));
    });

    test(
        'ParticleFilter.getVisibleParticlesUsingGrid filters particles within viewport',
        () {
      final pIn = Particle(
        position: const Offset(50, 50),
        velocity: Offset.zero,
        color: Colors.white,
        size: 1,
      );
      final pOut = Particle(
        position: const Offset(350, 350),
        velocity: Offset.zero,
        color: Colors.white,
        size: 1,
      );

      final grid = SortedSpatialGrid()
        ..build([pIn, pOut], [0, 1], 400, 400, 50);
      final output = <int>[];

      ParticleFilter.getVisibleParticlesUsingGrid(
        grid,
        const Rect.fromLTWH(0, 0, 100, 100),
        output,
      );

      expect(output, equals([0]));
    });

    test('ParticleSimulation builds and clears spatialGrid properly', () {
      final sim = ParticleSimulation(
        particleCount: 10,
        maxSpeed: 1.0,
      );
      sim.updateSize(const Size(200, 200));

      expect(sim.spatialGrid.isInitialized, isFalse);
      sim.buildSpatialGrid(50);
      expect(sim.spatialGrid.isInitialized, isTrue);
      expect(sim.spatialGrid.count, equals(10));

      sim.clear();
      expect(sim.spatialGrid.isInitialized, isFalse);
      expect(sim.particles.isEmpty, isTrue);
    });

    test(
        'findNearbyParticlesToOutput populates output and clears previous entries',
        () {
      final p1 = Particle(
        position: const Offset(20, 20),
        velocity: Offset.zero,
        color: Colors.white,
        size: 1,
      );
      final p2 = Particle(
        position: const Offset(25, 25),
        velocity: Offset.zero,
        color: Colors.white,
        size: 1,
      );
      final p3 = Particle(
        position: const Offset(150, 150),
        velocity: Offset.zero,
        color: Colors.white,
        size: 1,
      );

      final grid = SortedSpatialGrid()
        ..build([p1, p2, p3], [0, 1, 2], 200, 200, 50);

      final output = <int>[999]; // Existing dirty state
      grid.findNearbyParticlesToOutput(20, 20, 30, output);

      expect(output, containsAll([0, 1]));
      expect(output.contains(2), isFalse);
      expect(output.contains(999), isFalse);

      // Query far away
      grid.findNearbyParticlesToOutput(190, 190, 10, output);
      expect(output, isEmpty);
    });

    test('clear resets grid state completely', () {
      final p = Particle(
        position: const Offset(50, 50),
        velocity: Offset.zero,
        color: Colors.white,
        size: 1,
      );
      final grid = SortedSpatialGrid()..build([p], [0], 100, 100, 30);
      expect(grid.isInitialized, isTrue);
      expect(grid.count, equals(1));
      expect(grid.cols, greaterThan(0));

      grid.clear();
      expect(grid.isInitialized, isFalse);
      expect(grid.count, equals(0));
      expect(grid.cols, equals(0));
      expect(grid.rows, equals(0));
      expect(grid.cellSize, equals(0));
    });

    test('build respects optional cellMultiplier', () {
      final p = Particle(
        position: const Offset(50, 50),
        velocity: Offset.zero,
        color: Colors.white,
        size: 1,
      );
      final grid1 = SortedSpatialGrid()..build([p], [0], 200, 200, 40);
      final baseCell = grid1.cellSize;

      final grid2 = SortedSpatialGrid()..build([p], [0], 200, 200, 40, 1.5);
      expect(grid2.cellSize, closeTo(baseCell * 1.5, 1e-6));

      // Non-positive multiplier falls back to 1.0
      final grid3 = SortedSpatialGrid()..build([p], [0], 200, 200, 40, -1.0);
      expect(grid3.cellSize, closeTo(baseCell, 1e-6));
    });

    test(
        'build clamps fractional cellMultiplier so cellSize never drops below radius',
        () {
      final p1 = Particle(
        position: const Offset(10, 50),
        velocity: Offset.zero,
        color: Colors.white,
        size: 1,
      );
      final p2 = Particle(
        position: const Offset(95, 50),
        velocity: Offset.zero,
        color: Colors.white,
        size: 1,
      );
      // Distance is 85 <= 90 radius
      final particles = [p1, p2];
      final grid = SortedSpatialGrid()
        ..build(particles, [0, 1], 500, 500, 90, 0.2);

      // cellSize must never be less than radius (90)
      expect(grid.cellSize, greaterThanOrEqualTo(90.0));

      int pairsFound = 0;
      grid.forEachPair(90, (i1, i2, distSq) {
        pairsFound++;
      });
      expect(pairsFound, equals(1));
    });

    test('build with invalid dimensions sets count to 0', () {
      final p = Particle(
        position: const Offset(50, 50),
        velocity: Offset.zero,
        color: Colors.white,
        size: 1,
      );
      final grid = SortedSpatialGrid();
      grid.build([p], [0], -100, 100, 40);
      expect(grid.count, equals(0));
      expect(grid.cols, equals(0));
      expect(grid.rows, equals(0));
      expect(grid.isInitialized, isFalse);
    });

    test(
        'build supports null visible to index all particles without allocation',
        () {
      final p1 = Particle(
        position: const Offset(20, 20),
        velocity: Offset.zero,
        color: Colors.white,
        size: 1,
      );
      final p2 = Particle(
        position: const Offset(40, 20),
        velocity: Offset.zero,
        color: Colors.white,
        size: 1,
      );
      final grid = SortedSpatialGrid()..build([p1, p2], null, 200, 200, 50);
      expect(grid.isInitialized, isTrue);
      expect(grid.count, equals(2));
      expect(grid.indices.sublist(0, 2).toSet(), equals({0, 1}));
    });

    test('build handles out of bounds visible indices gracefully', () {
      final p = Particle(
        position: const Offset(50, 50),
        velocity: Offset.zero,
        color: Colors.white,
        size: 1,
      );
      final grid = SortedSpatialGrid();
      expect(() => grid.build([p], [0, 999], 200, 200, 50), returnsNormally);
      expect(grid.count, equals(1));
    });

    test('ParticleSimulation convenience spatial query methods', () {
      final customGrid = SortedSpatialGrid();
      final sim = ParticleSimulation(
        particleCount: 2,
        spatialGrid: customGrid,
      );
      expect(identical(sim.spatialGrid, customGrid), isTrue);

      sim.updateSize(const Size(100, 100));
      sim.particles[0] = Particle(
        position: const Offset(20, 20),
        velocity: Offset.zero,
        color: Colors.white,
        size: 1,
      );
      sim.particles[1] = Particle(
        position: const Offset(30, 20),
        velocity: Offset.zero,
        color: Colors.white,
        size: 1,
      );

      sim.buildSpatialGrid(50);

      final radiusMatches = <int>[];
      sim.queryRadius(20, 20, 25, (idx, px, py, distSq) {
        radiusMatches.add(idx);
      });
      expect(radiusMatches, containsAll([0, 1]));

      final rectMatches = <int>[];
      sim.queryRect(10, 10, 25, 25, (idx, px, py) {
        rectMatches.add(idx);
      });
      expect(rectMatches, equals([0]));

      int pairCount = 0;
      sim.forEachPair(50, (i1, i2, distSq) {
        pairCount++;
        expect({i1, i2}, equals({0, 1}));
      });
      expect(pairCount, equals(1));

      final particleIndices = <int>[];
      sim.forEachParticle((idx, px, py) {
        particleIndices.add(idx);
      });
      expect(particleIndices, containsAll([0, 1]));
    });

    test('OptimizedNetworkPainter spatialGrid injection and exposure', () {
      final customGrid = SortedSpatialGrid();
      final p = Particle(
        position: const Offset(40, 40),
        velocity: Offset.zero,
        color: Colors.white,
        size: 1,
      );

      final painter = OptimizedNetworkPainter(
        particleCount: 1,
        particles: [p],
        touchPoint: null,
        lineDistance: 50,
        particleColor: Colors.white,
        lineColor: Colors.blue,
        lineWidth: 1.0,
        fill: true,
        drawNetwork: true,
        spatialGrid: customGrid,
        performance: const NetworkPerformance(spatialCellMultiplier: 1.2),
      );

      expect(identical(painter.spatialGrid, customGrid), isTrue);
    });

    test('OptimizedNetworkPainter showQuadTree logs deprecation warning', () {
      LegacyDeprecationLogger.resetWarned();
      final p = Particle(
        position: const Offset(40, 40),
        velocity: Offset.zero,
        color: Colors.white,
        size: 1,
      );

      OptimizedNetworkPainter(
        particleCount: 1,
        particles: [p],
        touchPoint: null,
        lineDistance: 50,
        particleColor: Colors.white,
        lineColor: Colors.blue,
        lineWidth: 1.0,
        fill: true,
        drawNetwork: true,
        showQuadTree: true,
      );

      expect(
        LegacyDeprecationLogger.hasWarned(
            'OptimizedNetworkPainter(showQuadTree: true)'),
        isTrue,
      );
    });

    testWidgets(
        'ParticleNetwork shares spatialGrid across widget, sim, and painter',
        (tester) async {
      final customGrid = SortedSpatialGrid();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                particleCount: 10,
                spatialGrid: customGrid,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 50));

      final state =
          tester.state<ParticleNetworkState>(find.byType(ParticleNetwork));
      expect(identical(state.spatialGrid, customGrid), isTrue);
      expect(identical(state.simulation.spatialGrid, customGrid), isTrue);
    });

    test('Legacy spatial classes constructor deprecation warnings', () {
      LegacyDeprecationLogger.resetWarned();

      SpatialGrid(cellSize: 20);
      expect(LegacyDeprecationLogger.hasWarned('SpatialGrid'), isTrue);

      CompressedQuadTree(const Rectangle(0, 0, 100, 100));
      expect(LegacyDeprecationLogger.hasWarned('CompressedQuadTree'), isTrue);

      StandardQuadTree(width: 100, height: 100);
      expect(LegacyDeprecationLogger.hasWarned('StandardQuadTree'), isTrue);

      AdaptiveQuadTreeManager();
      expect(
          LegacyDeprecationLogger.hasWarned('AdaptiveQuadTreeManager'), isTrue);
    });

    test('NetworkPerformance spatialCellMultiplier equality and copyWith', () {
      const perf = NetworkPerformance(spatialCellMultiplier: 1.3);
      expect(perf.spatialCellMultiplier, equals(1.3));

      final copy1 = perf.copyWith(spatialCellMultiplier: 1.5);
      expect(copy1.spatialCellMultiplier, equals(1.5));

      final copy2 = perf.copyWith(clearSpatialCellMultiplier: true);
      expect(copy2.spatialCellMultiplier, isNull);

      final copy3 = perf.copyWith();
      expect(copy3.spatialCellMultiplier, equals(1.3));
      expect(copy3, equals(perf));
      expect(copy3.hashCode, equals(perf.hashCode));
      expect(copy3.toString(), contains('spatialCellMultiplier: 1.3'));
    });
  });
}
