import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/particles_network.dart';

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
}
