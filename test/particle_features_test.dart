import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:particles_network/particles_network.dart';
import 'package:particles_network/src/legacy/legacy_deprecation_logger.dart';

void main() {
  group('ParticleFeatures Unit Tests', () {
    test('Default constructor sets expected canonical defaults', () {
      const features = ParticleFeatures();

      expect(features.count, equals(60));
      expect(features.maxSpeed, equals(0.5));
      expect(features.maxSize, equals(1.5));
      expect(features.color, equals(const Color(0xFFFFFFFF)));
      expect(features.fill, isTrue);
    });

    test('Accepts explicit custom values', () {
      const features = ParticleFeatures(
        count: 150,
        maxSpeed: 2.5,
        maxSize: 4.0,
        color: Color(0xFF10B981),
        fill: false,
      );

      expect(features.count, equals(150));
      expect(features.maxSpeed, equals(2.5));
      expect(features.maxSize, equals(4.0));
      expect(features.color, equals(const Color(0xFF10B981)));
      expect(features.fill, isFalse);
    });

    test('Presets initialize with well-tuned parameters', () {
      // Subtle preset
      const subtle = ParticleFeatures.subtle();
      expect(subtle.count, equals(35));
      expect(subtle.maxSpeed, equals(0.3));
      expect(subtle.maxSize, equals(1.2));
      expect(subtle.color, equals(const Color(0xFFFFFFFF)));
      expect(subtle.fill, isTrue);

      // Dense preset
      const dense = ParticleFeatures.dense();
      expect(dense.count, equals(120));
      expect(dense.maxSpeed, equals(0.8));
      expect(dense.maxSize, equals(2.0));
      expect(dense.color, equals(const Color(0xFFFFFFFF)));
      expect(dense.fill, isTrue);

      // Cosmic preset
      const cosmic = ParticleFeatures.cosmic();
      expect(cosmic.count, equals(90));
      expect(cosmic.maxSpeed, equals(1.2));
      expect(cosmic.maxSize, equals(2.5));
      expect(cosmic.color, equals(const Color(0xFFFFFFFF)));
      expect(cosmic.fill, isTrue);
    });

    test('Presets accept custom overrides for count, speed, size, color, and fill', () {
      const customSubtle = ParticleFeatures.subtle(
        count: 40,
        maxSpeed: 0.4,
        maxSize: 1.5,
        color: Color(0xFF00FF00),
        fill: false,
      );
      expect(customSubtle.count, equals(40));
      expect(customSubtle.maxSpeed, equals(0.4));
      expect(customSubtle.maxSize, equals(1.5));
      expect(customSubtle.color, equals(const Color(0xFF00FF00)));
      expect(customSubtle.fill, isFalse);

      const customDense = ParticleFeatures.dense(
        count: 150,
        maxSpeed: 1.0,
        maxSize: 3.0,
        color: Color(0xFFFF0000),
        fill: false,
      );
      expect(customDense.count, equals(150));
      expect(customDense.maxSpeed, equals(1.0));
      expect(customDense.maxSize, equals(3.0));
      expect(customDense.color, equals(const Color(0xFFFF0000)));
      expect(customDense.fill, isFalse);

      const customCosmic = ParticleFeatures.cosmic(
        count: 100,
        maxSpeed: 2.0,
        maxSize: 4.0,
        color: Color(0xFF0000FF),
        fill: false,
      );
      expect(customCosmic.count, equals(100));
      expect(customCosmic.maxSpeed, equals(2.0));
      expect(customCosmic.maxSize, equals(4.0));
      expect(customCosmic.color, equals(const Color(0xFF0000FF)));
      expect(customCosmic.fill, isFalse);
    });

    test('Presets redirecting constructors forward all parameters into canonical instance', () {
      // 1. Subtle (L127-L128, L133-L134)
      final runtimeSubtle = ParticleFeatures.subtle(
        count: 42,
        maxSpeed: 0.25,
        maxSize: 1.1,
        color: const Color(0xFF123456),
        fill: false,
      );
      expect(runtimeSubtle.count, equals(42));
      expect(runtimeSubtle.maxSpeed, equals(0.25));
      expect(runtimeSubtle.maxSize, equals(1.1));
      expect(runtimeSubtle.color, equals(const Color(0xFF123456)));
      expect(runtimeSubtle.fill, isFalse);

      final defaultRuntimeSubtle = ParticleFeatures.subtle();
      expect(defaultRuntimeSubtle.count, equals(35));
      expect(defaultRuntimeSubtle.maxSpeed, equals(0.3));
      expect(defaultRuntimeSubtle.maxSize, equals(1.2));
      expect(defaultRuntimeSubtle.color, equals(const Color(0xFFFFFFFF)));
      expect(defaultRuntimeSubtle.fill, isTrue);

      // 2. Dense (L151-L152, L157-L158)
      final runtimeDense = ParticleFeatures.dense(
        count: 140,
        maxSpeed: 0.95,
        maxSize: 2.2,
        color: const Color(0xFF654321),
        fill: false,
      );
      expect(runtimeDense.count, equals(140));
      expect(runtimeDense.maxSpeed, equals(0.95));
      expect(runtimeDense.maxSize, equals(2.2));
      expect(runtimeDense.color, equals(const Color(0xFF654321)));
      expect(runtimeDense.fill, isFalse);

      final defaultRuntimeDense = ParticleFeatures.dense();
      expect(defaultRuntimeDense.count, equals(120));
      expect(defaultRuntimeDense.maxSpeed, equals(0.8));
      expect(defaultRuntimeDense.maxSize, equals(2.0));
      expect(defaultRuntimeDense.color, equals(const Color(0xFFFFFFFF)));
      expect(defaultRuntimeDense.fill, isTrue);

      // 3. Cosmic (L173-L174, L179-L180)
      final runtimeCosmic = ParticleFeatures.cosmic(
        count: 95,
        maxSpeed: 1.35,
        maxSize: 2.8,
        color: const Color(0xFFABCDEF),
        fill: false,
      );
      expect(runtimeCosmic.count, equals(95));
      expect(runtimeCosmic.maxSpeed, equals(1.35));
      expect(runtimeCosmic.maxSize, equals(2.8));
      expect(runtimeCosmic.color, equals(const Color(0xFFABCDEF)));
      expect(runtimeCosmic.fill, isFalse);

      final defaultRuntimeCosmic = ParticleFeatures.cosmic();
      expect(defaultRuntimeCosmic.count, equals(90));
      expect(defaultRuntimeCosmic.maxSpeed, equals(1.2));
      expect(defaultRuntimeCosmic.maxSize, equals(2.5));
      expect(defaultRuntimeCosmic.color, equals(const Color(0xFFFFFFFF)));
      expect(defaultRuntimeCosmic.fill, isTrue);
    });

    test('copyWith creates modified copy and preserves existing properties', () {
      const original = ParticleFeatures(
        count: 80,
        maxSpeed: 1.0,
        maxSize: 2.0,
        color: Color(0xFF3B82F6),
        fill: false,
      );

      // Empty copy returns equivalent instance
      final unchanged = original.copyWith();
      expect(unchanged, equals(original));
      expect(unchanged.hashCode, equals(original.hashCode));

      // Partial updates
      final updatedSpeed = original.copyWith(maxSpeed: 3.0);
      expect(updatedSpeed.count, equals(80));
      expect(updatedSpeed.maxSpeed, equals(3.0));
      expect(updatedSpeed.maxSize, equals(2.0));
      expect(updatedSpeed.color, equals(const Color(0xFF3B82F6)));
      expect(updatedSpeed.fill, isFalse);

      final updatedColor = original.copyWith(color: const Color(0xFFEC4899));
      expect(updatedColor.color, equals(const Color(0xFFEC4899)));
      expect(updatedColor.count, equals(80));

      final updatedFill = original.copyWith(fill: true);
      expect(updatedFill.fill, isTrue);
    });

    test('Equality, hashCode, and toString work as expected', () {
      const a1 = ParticleFeatures(count: 70, maxSpeed: 1.0);
      const a2 = ParticleFeatures(count: 70, maxSpeed: 1.0);
      const b = ParticleFeatures(count: 71, maxSpeed: 1.0);
      const c = ParticleFeatures(count: 70, maxSpeed: 1.5);
      const d = ParticleFeatures(count: 70, maxSpeed: 1.0, maxSize: 3.0);
      const e = ParticleFeatures(count: 70, maxSpeed: 1.0, color: Color(0xFF00FF00));
      const f = ParticleFeatures(count: 70, maxSpeed: 1.0, fill: false);

      expect(a1, equals(a2));
      expect(a1.hashCode, equals(a2.hashCode));
      expect(a1 == a2, isTrue);

      expect(a1 == b, isFalse);
      expect(a1 == c, isFalse);
      expect(a1 == d, isFalse);
      expect(a1 == e, isFalse);
      expect(a1 == f, isFalse);
      // ignore: unrelated_type_equality_checks
      expect(a1 == 'other_type', isFalse);

      final str = a1.toString();
      expect(str, contains('ParticleFeatures('));
      expect(str, contains('count: 70'));
      expect(str, contains('maxSpeed: 1.0'));
      expect(str, contains('maxSize: 1.5'));
      expect(str, contains('fill: true'));
    });

    test('Asserts enforce valid parameters in debug mode', () {
      // Negative count
      expect(
        () => ParticleFeatures(count: -1),
        throwsA(isA<AssertionError>()),
      );

      // Negative maxSpeed
      expect(
        () => ParticleFeatures(maxSpeed: -0.1),
        throwsA(isA<AssertionError>()),
      );

      // Non-positive maxSize
      expect(
        () => ParticleFeatures(maxSize: 0.0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => ParticleFeatures(maxSize: -1.0),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('ParticleFeatures Widget Integration Tests', () {
    testWidgets('ParticleNetwork initializes with canonical ParticleFeatures', (
      WidgetTester tester,
    ) async {
      LegacyDeprecationLogger.resetWarned();

      const modernConfig = ParticleFeatures(
        count: 75,
        maxSpeed: 1.2,
        maxSize: 2.8,
        color: Color(0xFF00E5FF),
        fill: false,
      );

      const widget = ParticleNetwork(
        particles: modernConfig,
      );

      expect(widget.particles, equals(modernConfig));
      expect(widget.effectiveParticleFeatures, equals(modernConfig));
      // ignore: deprecated_member_use_from_same_package
      expect(widget.particleCount, equals(75));
      // ignore: deprecated_member_use_from_same_package
      expect(widget.maxSpeed, equals(1.2));
      // ignore: deprecated_member_use_from_same_package
      expect(widget.maxSize, equals(2.8));
      // ignore: deprecated_member_use_from_same_package
      expect(widget.particleColor, equals(const Color(0xFF00E5FF)));
      // ignore: deprecated_member_use_from_same_package
      expect(widget.fill, isFalse);
      expect(widget.usedLegacyParticles, isFalse);
      expect(widget.usedLegacyParticleFeatures, isFalse);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: widget,
            ),
          ),
        ),
      );

      final state = tester.state<ParticleNetworkState>(find.byType(ParticleNetwork));
      expect(state.simulation.particleCount, equals(75));
      expect(state.painter.particleCount, equals(75));
      expect(state.painter.particleColor, equals(const Color(0xFF00E5FF)));
      expect(state.painter.fill, isFalse);

      // Verify NO deprecation warning is logged for canonical usage
      expect(
        LegacyDeprecationLogger.hasWarned(
          'ParticleNetwork(particleCount, maxSpeed, maxSize, particleColor, fill)',
        ),
        isFalse,
      );
    });

    testWidgets('ParticleNetwork default constructor logs NO deprecation warning', (
      WidgetTester tester,
    ) async {
      LegacyDeprecationLogger.resetWarned();

      const defaultWidget = ParticleNetwork();
      expect(defaultWidget.usedLegacyParticles, isFalse);
      expect(defaultWidget.usedLegacyParticleFeatures, isFalse);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: defaultWidget,
            ),
          ),
        ),
      );

      expect(
        LegacyDeprecationLogger.hasWarned(
          'ParticleNetwork(particleCount, maxSpeed, maxSize, particleColor, fill)',
        ),
        isFalse,
      );
    });

    testWidgets('ParticleNetwork logs deprecation warning when legacy flat parameters are used', (
      WidgetTester tester,
    ) async {
      LegacyDeprecationLogger.resetWarned();

      // ignore: deprecated_member_use_from_same_package
      const legacyWidget = ParticleNetwork(
        particleCount: 45,
        maxSpeed: 0.9,
        maxSize: 3.1,
        particleColor: Color(0xFFEF4444),
        fill: false,
      );

      expect(legacyWidget.usedLegacyParticles, isTrue);
      expect(legacyWidget.effectiveParticleFeatures.count, equals(45));
      expect(legacyWidget.effectiveParticleFeatures.maxSpeed, equals(0.9));
      expect(legacyWidget.effectiveParticleFeatures.maxSize, equals(3.1));
      expect(legacyWidget.effectiveParticleFeatures.color, equals(const Color(0xFFEF4444)));
      expect(legacyWidget.effectiveParticleFeatures.fill, isFalse);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: legacyWidget,
            ),
          ),
        ),
      );

      expect(
        LegacyDeprecationLogger.hasWarned(
          'ParticleNetwork(particleCount, maxSpeed, maxSize, particleColor, fill)',
        ),
        isTrue,
      );

      final state = tester.state<ParticleNetworkState>(find.byType(ParticleNetwork));
      expect(state.simulation.particleCount, equals(45));
      expect(state.painter.particleCount, equals(45));
      expect(state.painter.particleColor, equals(const Color(0xFFEF4444)));
      expect(state.painter.fill, isFalse);
    });

    testWidgets('ParticleNetwork logs deprecation warning when particleFeatures alias is used', (
      WidgetTester tester,
    ) async {
      LegacyDeprecationLogger.resetWarned();

      // ignore: deprecated_member_use_from_same_package
      const widgetWithAlias = ParticleNetwork(
        particleFeatures: ParticleFeatures(count: 88),
      );

      expect(widgetWithAlias.usedLegacyParticleFeatures, isTrue);
      expect(widgetWithAlias.effectiveParticleFeatures.count, equals(88));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: widgetWithAlias,
            ),
          ),
        ),
      );

      expect(
        LegacyDeprecationLogger.hasWarned('ParticleNetwork(particleFeatures)'),
        isTrue,
      );
    });

    testWidgets('ParticleNetwork correctly detects individual usedLegacy getters', (
      WidgetTester tester,
    ) async {
      // ignore: deprecated_member_use_from_same_package
      const w1 = ParticleNetwork(particleCount: 50);
      expect(w1.usedLegacyParticleCount, isTrue);
      expect(w1.usedLegacyMaxSpeed, isFalse);
      expect(w1.usedLegacyMaxSize, isFalse);
      expect(w1.usedLegacyParticleColor, isFalse);
      expect(w1.usedLegacyFill, isFalse);
      expect(w1.usedLegacyParticles, isTrue);

      // ignore: deprecated_member_use_from_same_package
      const w2 = ParticleNetwork(maxSpeed: 1.5);
      expect(w2.usedLegacyMaxSpeed, isTrue);
      expect(w2.usedLegacyParticleCount, isFalse);

      // ignore: deprecated_member_use_from_same_package
      const w3 = ParticleNetwork(maxSize: 3.0);
      expect(w3.usedLegacyMaxSize, isTrue);

      // ignore: deprecated_member_use_from_same_package
      const w4 = ParticleNetwork(particleColor: Colors.red);
      expect(w4.usedLegacyParticleColor, isTrue);

      // ignore: deprecated_member_use_from_same_package
      const w5 = ParticleNetwork(fill: false);
      expect(w5.usedLegacyFill, isTrue);

      const canonical = ParticleNetwork(
        particles: ParticleFeatures(count: 50),
      );
      expect(canonical.usedLegacyParticleCount, isFalse);
      expect(canonical.usedLegacyMaxSpeed, isFalse);
      expect(canonical.usedLegacyMaxSize, isFalse);
      expect(canonical.usedLegacyParticleColor, isFalse);
      expect(canonical.usedLegacyFill, isFalse);
      expect(canonical.usedLegacyParticles, isFalse);
    });

    testWidgets('ParticleNetwork merges particles with explicit legacy parameters', (
      WidgetTester tester,
    ) async {
      // ignore: deprecated_member_use_from_same_package
      const mixed = ParticleNetwork(
        particles: ParticleFeatures(
          count: 100,
          maxSpeed: 2.0,
          maxSize: 3.0,
          color: Colors.blue,
          fill: true,
        ),
        particleCount: 45, // Overrides count from particles
        fill: false, // Overrides fill from particles
      );

      expect(mixed.effectiveParticleFeatures.count, equals(45));
      expect(mixed.effectiveParticleFeatures.maxSpeed, equals(2.0));
      expect(mixed.effectiveParticleFeatures.maxSize, equals(3.0));
      expect(mixed.effectiveParticleFeatures.color, equals(Colors.blue));
      expect(mixed.effectiveParticleFeatures.fill, isFalse);
      expect(mixed.usedLegacyParticles, isTrue);
    });

    testWidgets('didUpdateWidget responds to ParticleFeatures updates', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                particles: ParticleFeatures(
                  count: 40,
                  maxSpeed: 0.5,
                  maxSize: 1.5,
                  color: Color(0xFFFFFFFF),
                  fill: true,
                ),
              ),
            ),
          ),
        ),
      );

      final state = tester.state<ParticleNetworkState>(find.byType(ParticleNetwork));
      expect(state.simulation.particleCount, equals(40));
      expect(state.painter.particleColor, equals(const Color(0xFFFFFFFF)));
      expect(state.painter.fill, isTrue);

      // Rebuild with updated ParticleFeatures
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                particles: ParticleFeatures(
                  count: 65,
                  maxSpeed: 1.8,
                  maxSize: 2.2,
                  color: Color(0xFFF59E0B),
                  fill: false,
                ),
              ),
            ),
          ),
        ),
      );

      expect(state.simulation.particleCount, equals(65));
      expect(state.painter.particleColor, equals(const Color(0xFFF59E0B)));
      expect(state.painter.fill, isFalse);
    });

    testWidgets('didUpdateWidget dynamically transitions from legacy to canonical particles without error', (
      WidgetTester tester,
    ) async {
      // Step 1: mount with legacy parameters
      // ignore: deprecated_member_use_from_same_package
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                particleCount: 50,
                maxSpeed: 0.8,
                particleColor: Color(0xFF123456),
              ),
            ),
          ),
        ),
      );

      final state = tester.state<ParticleNetworkState>(find.byType(ParticleNetwork));
      expect(state.simulation.particleCount, equals(50));
      expect(state.painter.particleColor, equals(const Color(0xFF123456)));

      // Step 2: rebuild with canonical particles parameter
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                particles: ParticleFeatures(
                  count: 90,
                  maxSpeed: 1.5,
                  color: Color(0xFF654321),
                ),
              ),
            ),
          ),
        ),
      );

      expect(state.simulation.particleCount, equals(90));
      expect(state.painter.particleColor, equals(const Color(0xFF654321)));

      // Step 3: rebuild with preset
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                particles: ParticleFeatures.dense(),
              ),
            ),
          ),
        ),
      );

      expect(state.simulation.particleCount, equals(120));
      expect(state.painter.particleColor, equals(const Color(0xFFFFFFFF)));
    });

    test('LegacyDeprecationLogger formats Notice line when message is provided', () {
      LegacyDeprecationLogger.resetWarned();
      final List<String> printedMessages = [];
      final originalDebugPrint = debugPrint;
      debugPrint = (String? msg, {int? wrapWidth}) {
        if (msg != null) printedMessages.add(msg);
      };

      try {
        LegacyDeprecationLogger.warn(
          deprecatedApi: 'ParticleNetwork(testNotice)',
          replacement: 'ParticleNetwork(particles: ParticleFeatures(...))',
          message: 'Consolidated particle properties.',
        );

        expect(printedMessages, hasLength(1));
        expect(printedMessages.first, contains('Notice         : Consolidated particle properties.'));
      } finally {
        debugPrint = originalDebugPrint;
      }
    });
  });
}
