import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/particles_network.dart';

void main() {
  group('Version 1.6.0 Backward Compatibility Tests', () {
    testWidgets(
      'ParticleNetwork builds and renders with exact 1.6.0 parameters and syntax',
      (WidgetTester tester) async {
        // This is the EXACT syntax used in the 1.6.0 README and by 7,000 existing users
        const widget160 = ParticleNetwork(
          particleCount: 50,
          touchActivation: true,
          maxSpeed: 0.5,
          maxSize: 3.5,
          lineDistance: 180,
          particleColor: Colors.white,
          lineColor: Color(0xFF64FFB4),
          touchColor: Colors.amber,
          linewidth: 0.5, // 1.6.0 lowercase parameter
        );

        // Verify property accessors reflect 1.6.0 values
        expect(widget160.particleCount, equals(50));
        expect(widget160.touchActivation, isTrue);
        expect(widget160.effectiveTouchActivation, isTrue);
        expect(widget160.maxSpeed, equals(0.5));
        expect(widget160.maxSize, equals(3.5));
        expect(widget160.lineDistance, equals(180));
        expect(widget160.particleColor, equals(Colors.white));
        expect(widget160.lineColor, equals(const Color(0xFF64FFB4)));
        expect(widget160.touchColor, equals(Colors.amber));
        expect(widget160.effectiveTouchColor, equals(Colors.amber));
        expect(widget160.effectiveLineWidth, equals(0.5));
        expect(widget160.usedLegacyLinewidth, isTrue);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 300,
                child: widget160,
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 50));
        expect(find.byType(ParticleNetwork), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(ParticleNetwork),
            matching: find.byType(CustomPaint),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'ParticleNetwork works with 1.6.0 custom factory and controller injection',
      (WidgetTester tester) async {
        final customFactory = DefaultParticleFactory(
          random: math.Random(42),
          maxSpeed: 0.8,
          maxSize: 4.0,
          color: Colors.cyan,
        );
        final customController = ParticleUpdater();

        final widgetWithDependencies = ParticleNetwork(
          particleCount: 20,
          touchActivation: false,
          maxSpeed: 0.8,
          maxSize: 4.0,
          lineDistance: 120,
          particleColor: Colors.cyan,
          lineColor: Colors.blue,
          touchColor: Colors.red,
          linewidth: 1.2,
          particleFactory: customFactory,
          particleController: customController,
        );

        expect(widgetWithDependencies.particleFactory, equals(customFactory));
        expect(widgetWithDependencies.particleController, equals(customController));
        expect(widgetWithDependencies.touchActivation, isFalse);
        expect(widgetWithDependencies.effectiveTouchActivation, isFalse);
        expect(widgetWithDependencies.effectiveLineWidth, equals(1.2));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 250,
                height: 250,
                child: widgetWithDependencies,
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 50));
        expect(find.byType(ParticleNetwork), findsOneWidget);
      },
    );
  });

  group('Deduplication & Deprecation Verification', () {
    test('NetworkPerformance.auto and NetworkPerformance.boost produce identical configurations', () {
      const autoPreset = NetworkPerformance.auto();
      // ignore: deprecated_member_use_from_same_package
      const boostPreset = NetworkPerformance.boost();

      expect(boostPreset.maxConnectionsPerParticle, equals(autoPreset.maxConnectionsPerParticle));
      expect(boostPreset.maxLinesPerFrame, equals(autoPreset.maxLinesPerFrame));
      expect(boostPreset.frameRateIndependent, equals(autoPreset.frameRateIndependent));
      expect(boostPreset.lineRenderer, equals(autoPreset.lineRenderer));
      expect(boostPreset.isComplex, equals(autoPreset.isComplex));
      expect(boostPreset.autoBoost, equals(autoPreset.autoBoost));
      expect(boostPreset.cappedDistanceFactor, equals(autoPreset.cappedDistanceFactor));
      expect(boostPreset.antiAlias, equals(autoPreset.antiAlias));
      expect(boostPreset, equals(autoPreset));
    });

    test('ParticleGravity canonical properties and deprecated aliases match', () {
      // ignore: deprecated_member_use_from_same_package
      const gravity = ParticleGravity(
        gravityType: GravityType.global,
        gravityStrength: 0.25,
        gravityDirection: Offset(0, -1),
        gravityCenter: Offset(50, 50),
      );

      // Canonical properties
      expect(gravity.type, equals(GravityType.global));
      expect(gravity.strength, equals(0.25));
      expect(gravity.direction, equals(const Offset(0, -1)));
      expect(gravity.center, equals(const Offset(50, 50)));

      // Deprecated aliases
      // ignore: deprecated_member_use_from_same_package
      expect(gravity.gravityType, equals(gravity.type));
      // ignore: deprecated_member_use_from_same_package
      expect(gravity.gravityStrength, equals(gravity.strength));
      // ignore: deprecated_member_use_from_same_package
      expect(gravity.gravityDirection, equals(gravity.direction));
      // ignore: deprecated_member_use_from_same_package
      expect(gravity.gravityCenter, equals(gravity.center));
    });

    test('TouchFeatures canonical properties and deprecated aliases match', () {
      // ignore: deprecated_member_use_from_same_package
      const touch = TouchFeatures(
        decayRate: 0.35,
        pullForce: 0.45,
        touchActivation: false,
      );

      // Canonical properties
      expect(touch.speed, equals(0.35));
      expect(touch.force, equals(0.45));
      expect(touch.enabled, isFalse);

      // Deprecated aliases
      // ignore: deprecated_member_use_from_same_package
      expect(touch.decayRate, equals(touch.speed));
      // ignore: deprecated_member_use_from_same_package
      expect(touch.pullForce, equals(touch.force));
      // ignore: deprecated_member_use_from_same_package
      expect(touch.touchActivation, equals(touch.enabled));
    });
  });
}
