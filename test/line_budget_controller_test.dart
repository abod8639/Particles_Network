import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/src/rendering/frame_radii.dart';
import 'package:particles_network/src/rendering/line_budget_controller.dart';

void main() {
  group('FrameRadii Unit Tests', () {
    test('equality, hashCode and toString work as expected (L23-L37)', () {
      const r1 = FrameRadii(
        gridRadius: 100.0,
        scanRadius: 80.0,
        alphaRadius: 60.0,
      );
      const r2 = FrameRadii(
        gridRadius: 100.0,
        scanRadius: 80.0,
        alphaRadius: 60.0,
      );
      const diffGrid = FrameRadii(
        gridRadius: 90.0,
        scanRadius: 80.0,
        alphaRadius: 60.0,
      );
      const diffScan = FrameRadii(
        gridRadius: 100.0,
        scanRadius: 70.0,
        alphaRadius: 60.0,
      );
      const diffAlpha = FrameRadii(
        gridRadius: 100.0,
        scanRadius: 80.0,
        alphaRadius: 50.0,
      );

      // Identical & value equality
      expect(r1 == r1, isTrue);
      expect(r1, equals(r2));
      expect(r1.hashCode, equals(r2.hashCode));

      // Differences
      expect(r1 == diffGrid, isFalse);
      expect(r1 == diffScan, isFalse);
      expect(r1 == diffAlpha, isFalse);
      expect(r1 == Object(), isFalse);

      // toString
      expect(
        r1.toString(),
        equals(
          'FrameRadii(gridRadius: 100.0, scanRadius: 80.0, alphaRadius: 60.0)',
        ),
      );
    });
  });

  group('LineBudgetController Unit Tests', () {
    late LineBudgetController controller;

    setUp(() {
      controller = LineBudgetController();
    });

    test('Unbudgeted scenes return base distance unchanged', () {
      final radii = controller.computeFrameRadii(
        baseDistance: 100.0,
        size: const Size(800, 600),
        visibleCount: 50,
        maxLinesPerFrame: null,
        maxConnectionsPerParticle: null,
        cappedDistanceFactor: 1.0,
      );

      expect(radii.gridRadius, equals(100.0));
      expect(radii.scanRadius, equals(100.0));
      expect(radii.alphaRadius, equals(100.0));
    });

    test('Budgeted scenes shrink radius proportionally to line budget', () {
      final radii = controller.computeFrameRadii(
        baseDistance: 100.0,
        size: const Size(800, 600),
        visibleCount: 500,
        maxLinesPerFrame: 50,
        maxConnectionsPerParticle: null,
        cappedDistanceFactor: 1.0,
      );

      expect(radii.gridRadius, lessThan(100.0));
      expect(radii.gridRadius, equals(radii.scanRadius));
      expect(radii.gridRadius, greaterThanOrEqualTo(4.0));
    });

    test(
      'Capped factor scales active distance when maxConnectionsPerParticle is set',
      () {
        final radii = controller.computeFrameRadii(
          baseDistance: 100.0,
          size: const Size(800, 600),
          visibleCount: 50,
          maxLinesPerFrame: null,
          maxConnectionsPerParticle: 3,
          cappedDistanceFactor: 0.6,
        );

        expect(radii.gridRadius, equals(60.0));
        expect(radii.scanRadius, equals(60.0));
      },
    );

    test('Feedback correction converges without oscillation', () {
      controller.updateFeedback(
        maxLinesPerFrame: 100,
        lastFrameLineCount: 400, // 4x over budget
        usedDistance: 50.0,
        baseDistance: 100.0,
      );

      expect(controller.budgetCorrection, lessThan(1.0));
      expect(controller.budgetCorrection, greaterThanOrEqualTo(0.2));

      controller.resetFeedback();
      expect(controller.budgetCorrection, equals(1.0));
    });
  });
}
