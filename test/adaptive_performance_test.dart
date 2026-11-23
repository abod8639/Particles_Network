import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/particles_network.dart';

void main() {
  group('Invariant 1: Zero Crash on Small Counts', () {
    late AdaptivePerformanceController controller;

    setUp(() {
      controller = AdaptivePerformanceController(targetFrameTimeMs: 16.67);
    });

    test(
        'visibleCount in {0, 1, 5, 10, 16} produces no ArgumentError across all frame states',
        () {
      const counts = <int>[0, 1, 5, 10, 16];
      const frameTimes = <double>[
        -10.0,
        0.0,
        5.0,
        16.67,
        25.0,
        35.0,
        400.0,
        double.nan,
        double.infinity
      ];

      for (final int count in counts) {
        for (final double timeMs in frameTimes) {
          expect(
            () => controller.recordFrame(
                frameTimeMs: timeMs, visibleCount: count),
            returnsNormally,
            reason: 'Failed on visibleCount=$count, frameTimeMs=$timeMs',
          );
        }
      }
    });

    test(
        'non-positive, zero, or non-finite targetFrameTimeMs produces no ArgumentError and defaults safely',
        () {
      const badTargets = <double>[
        0.0,
        -10.0,
        double.nan,
        double.infinity,
        -double.infinity
      ];

      for (final double target in badTargets) {
        final ctrl = AdaptivePerformanceController(targetFrameTimeMs: target);
        expect(ctrl.targetFrameTimeMs, greaterThan(0.0));
        expect(() => ctrl.recordFrame(frameTimeMs: 16.67, visibleCount: 100),
            returnsNormally);

        ctrl.reset(targetFrameTimeMs: target);
        expect(ctrl.targetFrameTimeMs, greaterThan(0.0));
        expect(() => ctrl.recordFrame(frameTimeMs: 16.67, visibleCount: 100),
            returnsNormally);
      }
    });
  });

  group('Invariant 2: Fast-Path Verification', () {
    test(
        'PerformanceFeatures.auto defaults to fast-path (isComplex: false, maxConnections: null)',
        () {
      const perf = PerformanceFeatures.auto();
      expect(perf.isComplex, isTrue);
      expect(perf.maxConnectionsPerParticle, isNull);
      expect(perf.maxLinesPerFrame, isNull);
      expect(perf.autoBoost, isTrue);

      final painter = OptimizedNetworkPainter(
        particleCount: 50,
        particles: const [],
        touchPoint: null,
        lineDistance: 100.0,
        particleColor: const Color(0xFFFFFFFF),
        lineColor: const Color(0xFFFFFFFF),
        lineWidth: 1.0,
        fill: true,
        drawNetwork: true,
        performance: perf,
      );

      expect(painter.performance.isComplex, isTrue);
      expect(painter.effectiveMaxConnections, isNull);
      expect(painter.runtimeMaxConnectionsOverride, isNull);
      expect(painter.runtimeMaxLinesOverride, isNull);
    });
  });

  group('Invariant 3: Convergence Speed (Mathematically Bounded)', () {
    late AdaptivePerformanceController controller;

    setUp(() {
      controller = AdaptivePerformanceController(targetFrameTimeMs: 16.67);
    });

    test(
        'Severe Spike (> 2.0x budget, 35ms at 60Hz): budget drops from 10,000 to <= 500 in <= 6 frames',
        () {
      controller.setDynamicLinesForTesting(10000.0);
      expect(controller.dynamicLineBudget, equals(10000));

      int spikeFrames = 0;
      while (controller.dynamicLineBudget > 500 && spikeFrames < 10) {
        spikeFrames++;
        controller.recordFrame(frameTimeMs: 35.0, visibleCount: 500);
      }

      expect(spikeFrames, lessThanOrEqualTo(6));
      expect(controller.dynamicLineBudget, lessThanOrEqualTo(500));
    });

    test(
        'Sustained Drop (1.5x budget, 25ms at 60Hz): budget drops from 10,000 to <= 500 in <= 20 frames',
        () {
      controller.setDynamicLinesForTesting(10000.0);
      expect(controller.dynamicLineBudget, equals(10000));

      int dropFrames = 0;
      while (controller.dynamicLineBudget > 500 && dropFrames < 30) {
        dropFrames++;
        controller.recordFrame(frameTimeMs: 25.0, visibleCount: 500);
      }

      expect(dropFrames, lessThanOrEqualTo(20));
      expect(controller.dynamicLineBudget, lessThanOrEqualTo(500));
    });
  });

  group('Invariant 4: Deadband & Outlier Immunity', () {
    late AdaptivePerformanceController controller;

    setUp(() {
      controller = AdaptivePerformanceController(targetFrameTimeMs: 16.67);
    });

    test(
        'frames within +/- 10% of target budget cause zero change to dynamicLineBudget',
        () {
      final int initialBudget = controller.dynamicLineBudget;
      expect(initialBudget, equals(4000));

      // Record 20 frames within [15.5ms, 17.5ms]
      for (int i = 0; i < 20; i++) {
        controller.recordFrame(frameTimeMs: 16.0, visibleCount: 200);
        controller.recordFrame(frameTimeMs: 17.0, visibleCount: 200);
      }

      expect(controller.dynamicLineBudget, equals(initialBudget));
    });

    test(
        'a single 400ms outlier frame is discarded and does not alter EMA or budget',
        () {
      final double initialEma = controller.emaFrameTimeMs;
      final int initialBudget = controller.dynamicLineBudget;

      controller.recordFrame(frameTimeMs: 400.0, visibleCount: 200);

      expect(controller.emaFrameTimeMs, equals(initialEma));
      expect(controller.dynamicLineBudget, equals(initialBudget));
    });
  });

  group(
      'Invariant 5: Tier 2 Isolation, Escalation, and Strict Reverse Recovery',
      () {
    late AdaptivePerformanceController controller;

    setUp(() {
      controller = AdaptivePerformanceController(targetFrameTimeMs: 16.67);
    });

    test('mild drop (18ms on 16.67ms) never engages emergencyMaxConnections',
        () {
      for (int i = 0; i < 50; i++) {
        controller.recordFrame(frameTimeMs: 18.0, visibleCount: 200);
      }
      expect(controller.emergencyMaxConnections, isNull);
      expect(controller.isEmergencyActive, isFalse);
    });

    test(
        'at floor (500), 3 consecutive drops step emergencyMaxConnections 16 -> 8 -> 4',
        () {
      // Set to floor 500
      controller.setDynamicLinesForTesting(500.0);
      expect(controller.dynamicLineBudget, equals(500));
      expect(controller.emergencyMaxConnections, isNull);

      // 3 consecutive sustained drops (> 1.35x = > 22.5ms) step null -> 16
      controller.recordFrame(frameTimeMs: 25.0, visibleCount: 200);
      expect(controller.emergencyMaxConnections, isNull);
      controller.recordFrame(frameTimeMs: 25.0, visibleCount: 200);
      expect(controller.emergencyMaxConnections, isNull);
      controller.recordFrame(frameTimeMs: 25.0, visibleCount: 200);
      expect(controller.emergencyMaxConnections, equals(16));
      expect(controller.emergencyTierIndex, equals(1));

      // 3 more drops step 16 -> 8
      controller.recordFrame(frameTimeMs: 25.0, visibleCount: 200);
      expect(controller.emergencyMaxConnections, equals(16));
      controller.recordFrame(frameTimeMs: 25.0, visibleCount: 200);
      expect(controller.emergencyMaxConnections, equals(16));
      controller.recordFrame(frameTimeMs: 25.0, visibleCount: 200);
      expect(controller.emergencyMaxConnections, equals(8));
      expect(controller.emergencyTierIndex, equals(2));

      // 3 more drops step 8 -> 4
      controller.recordFrame(frameTimeMs: 25.0, visibleCount: 200);
      expect(controller.emergencyMaxConnections, equals(8));
      controller.recordFrame(frameTimeMs: 25.0, visibleCount: 200);
      expect(controller.emergencyMaxConnections, equals(8));
      controller.recordFrame(frameTimeMs: 25.0, visibleCount: 200);
      expect(controller.emergencyMaxConnections, equals(4));
      expect(controller.emergencyTierIndex, equals(3));
    });

    test(
        'at floor (500), a severe spike steps emergencyMaxConnections one tier at a time (null -> 16, not 4)',
        () {
      controller.setDynamicLinesForTesting(500.0);
      expect(controller.dynamicLineBudget, equals(500));
      expect(controller.emergencyMaxConnections, isNull);

      // Single severe spike (> 2.0x target = > 33.34ms)
      controller.recordFrame(frameTimeMs: 40.0, visibleCount: 200);
      expect(controller.emergencyMaxConnections, equals(16),
          reason: 'Must step to 16, not jump straight to 4');
      expect(controller.emergencyTierIndex, equals(1));
    });

    test(
        'strict reverse recovery: locked at 500 until emergency tiers fully clear (4 -> 8 -> 16 -> null)',
        () {
      controller.setDynamicLinesForTesting(500.0);
      controller.setEmergencyTierForTesting(3);
      expect(controller.emergencyTierIndex, equals(3));
      expect(controller.emergencyMaxConnections, equals(4));
      expect(controller.dynamicLineBudget, equals(500));

      // 14 smooth frames: tier remains 4, budget locked at 500
      for (int i = 0; i < 14; i++) {
        controller.recordFrame(frameTimeMs: 10.0, visibleCount: 200);
        expect(controller.emergencyMaxConnections, equals(4));
        expect(controller.dynamicLineBudget, equals(500));
      }

      // 15th smooth frame steps 4 -> 8; budget remains locked at 500
      controller.recordFrame(frameTimeMs: 10.0, visibleCount: 200);
      expect(controller.emergencyMaxConnections, equals(8));
      expect(controller.dynamicLineBudget, equals(500));

      // 14 more smooth frames
      for (int i = 0; i < 14; i++) {
        controller.recordFrame(frameTimeMs: 10.0, visibleCount: 200);
        expect(controller.emergencyMaxConnections, equals(8));
        expect(controller.dynamicLineBudget, equals(500));
      }

      // 15th smooth frame steps 8 -> 16; budget remains locked at 500
      controller.recordFrame(frameTimeMs: 10.0, visibleCount: 200);
      expect(controller.emergencyMaxConnections, equals(16));
      expect(controller.dynamicLineBudget, equals(500));

      // 14 more smooth frames
      for (int i = 0; i < 14; i++) {
        controller.recordFrame(frameTimeMs: 10.0, visibleCount: 200);
        expect(controller.emergencyMaxConnections, equals(16));
        expect(controller.dynamicLineBudget, equals(500));
      }

      // 15th smooth frame steps 16 -> null; Tier 2 fully cleared
      controller.recordFrame(frameTimeMs: 10.0, visibleCount: 200);
      expect(controller.emergencyMaxConnections, isNull);
      expect(controller.isEmergencyActive, isFalse);

      // ONLY NOW does dynamicLineBudget ramp above 500
      controller.recordFrame(frameTimeMs: 10.0, visibleCount: 200);
      expect(controller.dynamicLineBudget, greaterThan(500));
    });
  });

  group('Invariant 6: User Cap Precedence', () {
    test(
        'user-configured caps on lines and connections strictly override runtime overrides',
        () {
      final painter = OptimizedNetworkPainter(
        particleCount: 50,
        particles: const [],
        touchPoint: null,
        lineDistance: 100.0,
        particleColor: const Color(0xFFFFFFFF),
        lineColor: const Color(0xFFFFFFFF),
        lineWidth: 1.0,
        fill: true,
        drawNetwork: true,
        performance: const PerformanceFeatures.auto(
          maxLinesPerFrame: 2000,
          maxConnectionsPerParticle: 10,
        ),
      );

      // Lines override
      painter.setDynamicLineBudget(5000);
      expect(painter.effectiveMaxLines, equals(2000),
          reason: 'User cap 2000 must override runtime 5000');

      painter.setDynamicLineBudget(1000);
      expect(painter.effectiveMaxLines, equals(1000),
          reason: 'Runtime 1000 is stricter than user cap 2000');

      painter.setDynamicLineBudget(null);
      expect(painter.effectiveMaxLines, equals(2000));

      // Connections override
      painter.setEmergencyMaxConnections(16);
      expect(painter.effectiveMaxConnections, equals(10),
          reason: 'User cap 10 must override emergency tier 16');

      painter.setEmergencyMaxConnections(4);
      expect(painter.effectiveMaxConnections, equals(4),
          reason: 'Emergency tier 4 is stricter than user cap 10');

      painter.setEmergencyMaxConnections(null);
      expect(painter.effectiveMaxConnections, equals(10));
    });
  });

  group('Invariant 7: Zero Allocation & State Cleansing', () {
    test(
        'setDynamicLineBudget does not reset feedback correction and does not mutate performance reference',
        () {
      final painter = OptimizedNetworkPainter(
        particleCount: 50,
        particles: const [],
        touchPoint: null,
        lineDistance: 100.0,
        particleColor: const Color(0xFFFFFFFF),
        lineColor: const Color(0xFFFFFFFF),
        lineWidth: 1.0,
        fill: true,
        drawNetwork: true,
        performance: const PerformanceFeatures.auto(),
      );

      final pBefore = painter.performance;

      // Simulate feedback update modifying budgetCorrection
      painter.budgetController.updateFeedback(
        maxLinesPerFrame: 1000,
        lastFrameLineCount: 2000,
        usedDistance: 80.0,
        baseDistance: 100.0,
      );
      final double correctionBefore = painter.budgetController.budgetCorrection;
      expect(correctionBefore, isNot(equals(1.0)));

      // Calling setDynamicLineBudget must NOT reset feedback correction
      painter.setDynamicLineBudget(3500);
      expect(
          painter.budgetController.budgetCorrection, equals(correctionBefore));

      // Object reference must remain identical (zero heap allocation)
      expect(identical(pBefore, painter.performance), isTrue);

      // Conversely, public setter resets feedback
      painter.maxLinesPerFrame = 5000;
      expect(painter.budgetController.budgetCorrection, equals(1.0));
    });

    test(
        'updatePerformance resets runtime overrides even with identical performance object',
        () {
      final painter = OptimizedNetworkPainter(
        particleCount: 50,
        particles: const [],
        touchPoint: null,
        lineDistance: 100.0,
        particleColor: const Color(0xFFFFFFFF),
        lineColor: const Color(0xFFFFFFFF),
        lineWidth: 1.0,
        fill: true,
        drawNetwork: true,
        performance: const PerformanceFeatures.auto(),
      );

      painter.setDynamicLineBudget(1500);
      painter.setEmergencyMaxConnections(8);
      expect(painter.runtimeMaxLinesOverride, equals(1500));
      expect(painter.runtimeMaxConnectionsOverride, equals(8));

      // Re-apply identical performance configuration
      painter.updatePerformance(const PerformanceFeatures.auto());
      expect(painter.runtimeMaxLinesOverride, isNull);
      expect(painter.runtimeMaxConnectionsOverride, isNull);
    });

    testWidgets(
        'switching from PerformanceFeatures.auto() to balanced() immediately clears runtime overrides and resets controller',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: ParticleNetwork(
            performance: PerformanceFeatures.auto(),
          ),
        ),
      );

      final state =
          tester.state<ParticleNetworkState>(find.byType(ParticleNetwork));

      // Set runtime overrides
      state.painter.setDynamicLineBudget(1200);
      state.painter.setEmergencyMaxConnections(8);
      expect(state.painter.runtimeMaxLinesOverride, equals(1200));
      expect(state.painter.runtimeMaxConnectionsOverride, equals(8));

      // Switch to balanced preset
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: ParticleNetwork(
            performance: PerformanceFeatures.balanced(),
          ),
        ),
      );

      expect(state.painter.runtimeMaxLinesOverride, isNull);
      expect(state.painter.runtimeMaxConnectionsOverride, isNull);
      expect(state.adaptiveController.emergencyTierIndex, equals(0));
      expect(state.painter.effectiveMaxConnections, equals(6));
      expect(state.painter.effectiveMaxLines, equals(8000));
    });

    test(
        'AdaptivePerformanceController getters and recordFrameTime wrapper (L116-L120, L132-L136, L245-L250)',
        () {
      final ctrl = AdaptivePerformanceController(targetFrameTimeMs: 16.67);

      expect(ctrl.smoothedDynamicLines, equals(4000.0));
      expect(ctrl.scaleFactor, equals(1.0));
      expect(ctrl.consecutiveDrops, equals(0));
      expect(ctrl.consecutiveSmooth, equals(0));

      // Test recordFrameTime wrapper
      ctrl.recordFrameTime(const Duration(milliseconds: 20), 50);
      expect(ctrl.smoothedDynamicLines, isNot(4000.0));

      // Record frames to exercise consecutive counters
      for (int i = 0; i < 20; i++) {
        ctrl.recordFrameTime(const Duration(milliseconds: 50), 200);
      }
      expect(ctrl.consecutiveDrops, greaterThanOrEqualTo(0));
      expect(ctrl.consecutiveSmooth, greaterThanOrEqualTo(0));
    });
  });
}
