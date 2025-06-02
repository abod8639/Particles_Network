import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/model/particlemodel.dart';
import 'package:particles_network/particles_network.dart';

void main() {
  testWidgets('touchPoint updates onPanUpdate and resets onPanCancel', (
    WidgetTester tester,
  ) async {
    // بناء الواجهة
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ParticleNetwork(particleCount: 10, touchActivation: true),
        ),
      ),
    );

    // العثور على الحالة الداخلية للكائن ParticleNetwork
    final stateFinder = find.byType(ParticleNetwork);
    final state = tester.state<ParticleNetworkState>(stateFinder);

    // التأكد أن القيمة الابتدائية هي Offset.infinite
    expect(state.touchPoint, equals(Offset.infinite));

    // تنفيذ حدث السحب (onPanUpdate)
    final gesture = await tester.startGesture(const Offset(100, 150));
    await tester.pump(); // تحديث واجهة المستخدم

    expect(state.touchPoint.dx, closeTo(100, 1));
    expect(state.touchPoint.dy, closeTo(150, 1));

    // تنفيذ onPanCancel
    await gesture.cancel();
    await tester.pump();

    // التأكد من رجوع touchPoint إلى Offset.infinite
    expect(state.touchPoint, equals(Offset.infinite));
  });

  testWidgets('Touch updates and cancels set the correct touchPoint', (
    WidgetTester tester,
  ) async {
    // بناء الواجهة
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ParticleNetwork(particleCount: 10, touchActivation: true),
        ),
      ),
    );

    // الوصول إلى الـ state لاختبار touchPoint
    final stateFinder = find.byType(ParticleNetwork);
    final state = tester.state<ParticleNetworkState>(stateFinder);

    // 1. قبل أي تفاعل، يجب أن يكون Offset.infinite
    expect(state.touchPoint, Offset.infinite);

    // 2. تنفيذ PanUpdate (سحب) وتأكيد أن touchPoint تم تحديثه
    final gesture = await tester.startGesture(const Offset(50, 100));
    await tester.pump(); // تحديث الواجهة

    expect(state.touchPoint.dx, closeTo(50.0, 1));
    expect(state.touchPoint.dy, closeTo(100.0, 1));

    // 3. تنفيذ PanCancel وتأكيد أن touchPoint رجع إلى Offset.infinite
    await gesture.cancel();
    await tester.pump(); // تحديث الواجهة

    expect(state.touchPoint, Offset.infinite);
  });
  group('handleScreenBoundaries', () {
    const bounds = Size(100, 100);

    test('should reverse velocity.dx when hitting left boundary', () {
      final particle = createMockParticle(
        position: const Offset(-1, 50),
        velocity: const Offset(-2, 0),
      );
      particle.defaultVelocity = const Offset(-2, 0);

      particle.handleScreenBoundaries(bounds);

      expect(particle.velocity.dx, equals(2));
      expect(particle.defaultVelocity.dx, equals(2));
    });

    test('should reverse velocity.dx when hitting right boundary', () {
      final particle = createMockParticle(
        position: const Offset(101, 50),
        velocity: const Offset(3, 0),
      );
      particle.defaultVelocity = const Offset(3, 0);

      particle.handleScreenBoundaries(bounds);

      expect(particle.velocity.dx, equals(-3));
      expect(particle.defaultVelocity.dx, equals(-3));
    });

    test('should reverse velocity.dy when hitting top boundary', () {
      final particle = createMockParticle(
        position: const Offset(50, -5),
        velocity: const Offset(0, -4),
      );
      particle.defaultVelocity = const Offset(0, -4);

      particle.handleScreenBoundaries(bounds);

      expect(particle.velocity.dy, equals(4));
      expect(particle.defaultVelocity.dy, equals(4));
    });

    test('should reverse velocity.dy when hitting bottom boundary', () {
      final particle = createMockParticle(
        position: const Offset(50, 105),
        velocity: const Offset(0, 2),
      );
      particle.defaultVelocity = const Offset(0, 2);

      particle.handleScreenBoundaries(bounds);

      expect(particle.velocity.dy, equals(-2));
      expect(particle.defaultVelocity.dy, equals(-2));
    });

    test('should not reverse anything if inside bounds', () {
      final particle = createMockParticle(
        position: const Offset(50, 50),
        velocity: const Offset(1, 1),
      );
      particle.defaultVelocity = const Offset(1, 1);

      particle.handleScreenBoundaries(bounds);

      expect(particle.velocity, equals(const Offset(1, 1)));
      expect(particle.defaultVelocity, equals(const Offset(1, 1)));
    });
  });
  group('ParticleNetwork Widget Tests', () {
    testWidgets('ParticleNetwork initializes with custom values', (
      WidgetTester tester,
    ) async {
      const customColor = Colors.red;
      const customCount = 100;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleNetwork(
              particleCount: customCount,
              particleColor: customColor,
              maxSpeed: 1.0,
              maxSize: 5.0,
              lineDistance: 200,
              lineColor: customColor,
              touchColor: customColor,
              touchActivation: false,
              linewidth: 1.0,
            ),
          ),
        ),
      );

      final particleNetwork = tester.widget<ParticleNetwork>(
        find.byType(ParticleNetwork),
      );

      expect(particleNetwork.particleCount, equals(customCount));
      expect(particleNetwork.particleColor, equals(customColor));
      expect(particleNetwork.maxSpeed, equals(1.0));
      expect(particleNetwork.maxSize, equals(5.0));
      expect(particleNetwork.lineDistance, equals(200));
      expect(particleNetwork.lineColor, equals(customColor));
      expect(particleNetwork.touchColor, equals(customColor));
      expect(particleNetwork.touchActivation, isFalse);
      expect(particleNetwork.linewidth, equals(1.0));
    });

    testWidgets('ParticleNetwork handles touch events', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: ParticleNetwork())),
      );

      final stateFinder = find.byType(ParticleNetwork);
      final state = tester.state<ParticleNetworkState>(stateFinder);

      // Test initial state
      expect(state.touchPoint, equals(Offset.infinite));

      // Test onPanUpdate
      final gesture = await tester.startGesture(const Offset(100, 100));
      await tester.pump();
      await tester.dragFrom(const Offset(100, 100), const Offset(50, 50));
      await tester.pump();
      expect(state.touchPoint, isNot(equals(Offset.infinite)));

      // Test onPanCancel
      await gesture.cancel();
      await tester.pump();
      expect(state.touchPoint, equals(Offset.infinite));

      // Simulate another gesture with exact position check
      final gesture2 = await tester.startGesture(const Offset(75, 75));
      await tester.pump();

      // Move to specific position
      await gesture2.moveTo(const Offset(125, 125));
      await tester.pump();

      // Verify exact position update
      expect(state.touchPoint.dx, equals(125));
      expect(state.touchPoint.dy, equals(125));

      // End gesture and verify reset
      await gesture2.up();
      await tester.pump();
      expect(state.touchPoint, equals(Offset.infinite));
    });
  });
}
