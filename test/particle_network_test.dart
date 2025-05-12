import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/model/particlemodel.dart';
import 'package:particles_network/particles_network.dart';

// Mock implementations for testing
class MockParticleFactory implements IParticleFactory {
  final Particle particleToReturn;

  MockParticleFactory(this.particleToReturn);

  @override
  Particle createParticle(Size size) => particleToReturn;
}

class MockParticleController implements IParticleController {
  int updateCount = 0;
  List<Particle>? lastParticles;
  Size? lastBounds;

  @override
  void updateParticles(List<Particle> particles, Size bounds) {
    updateCount++;
    lastParticles = particles;
    lastBounds = bounds;
  }
}

void main() {
  group('DefaultParticleFactory', () {
    test('creates particles with expected properties', () {
      final random = Random(42); // Seed for predictable results
      const maxSpeed = 2.0;
      const maxSize = 5.0;
      const color = Colors.red;
      final factory = DefaultParticleFactory(
        random: random,
        maxSpeed: maxSpeed,
        maxSize: maxSize,
        color: color,
      );

      final size = Size(100, 100);
      final particle = factory.createParticle(size);

      expect(particle.color, color);
      expect(particle.position.dx, greaterThanOrEqualTo(0));
      expect(particle.position.dx, lessThanOrEqualTo(size.width));
      expect(particle.position.dy, greaterThanOrEqualTo(0));
      expect(particle.position.dy, lessThanOrEqualTo(size.height));
      expect(particle.velocity.dx, greaterThanOrEqualTo(-maxSpeed));
      expect(particle.velocity.dx, lessThanOrEqualTo(maxSpeed));
      expect(particle.velocity.dy, greaterThanOrEqualTo(-maxSpeed));
      expect(particle.velocity.dy, lessThanOrEqualTo(maxSpeed));
      expect(particle.size, greaterThanOrEqualTo(1));
      expect(particle.size, lessThanOrEqualTo(maxSize + 1));
    });
  });

  group('ParticleUpdater', () {
    test('updates all particles', () {
      final updater = ParticleUpdater();
      final particles = [
        Particle(
          position: Offset.zero,
          velocity: Offset(1, 1),
          size: 1,
          color: Colors.white,
        ),
        Particle(
          position: Offset(10, 10),
          velocity: Offset(-1, -1),
          size: 2,
          color: Colors.white,
        ),
      ];
      final bounds = Size(100, 100);

      updater.updateParticles(particles, bounds);

      expect(particles[0].position, Offset(1, 1));
      expect(particles[1].position, Offset(9, 9));
    });
  });

  group('ParticleNetwork', () {
    testWidgets(
      'initializes with default factory and controller when none provided',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: ParticleNetwork(particleCount: 10)),
        );

        final state =
            tester.state(find.byType(ParticleNetwork)) as ParticleNetworkState;
        expect(state.factory, isA<DefaultParticleFactory>());
        expect(state.controller, isA<ParticleUpdater>());
      },
    );

    testWidgets('uses provided factory and controller', (tester) async {
      final mockFactory = MockParticleFactory(
        Particle(
          position: Offset.zero,
          velocity: Offset.zero,
          size: 1,
          color: Colors.white,
        ),
      );
      final mockController = MockParticleController();

      await tester.pumpWidget(
        MaterialApp(
          home: ParticleNetwork(
            particleCount: 10,
            particleFactory: mockFactory,
            particleController: mockController,
          ),
        ),
      );

      final state =
          tester.state(find.byType(ParticleNetwork)) as ParticleNetworkState;
      expect(state.factory, mockFactory);
      expect(state.controller, mockController);
    });

    testWidgets('generates correct number of particles', (tester) async {
      const particleCount = 15;
      await tester.pumpWidget(
        MaterialApp(home: ParticleNetwork(particleCount: particleCount)),
      );

      final state =
          tester.state(find.byType(ParticleNetwork)) as ParticleNetworkState;
      expect(state.particles.length, particleCount);
    });

    testWidgets('updates particles on tick', (tester) async {
      final mockController = MockParticleController();
      await tester.pumpWidget(
        MaterialApp(
          home: ParticleNetwork(
            particleCount: 5,
            particleController: mockController,
          ),
        ),
      );

      // Initial pump doesn't trigger the ticker
      expect(mockController.updateCount, 0);

      // Wait for a frame to pass
      await tester.pump(const Duration(milliseconds: 16));

      expect(mockController.updateCount, greaterThan(0));
      expect(mockController.lastParticles, isNotNull);
      expect(mockController.lastBounds, isNotNull);
    });

    testWidgets('ignores touch events when touchActivation is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ParticleNetwork(particleCount: 5, touchActivation: false),
        ),
      );

      final state =
          tester.state(find.byType(ParticleNetwork)) as ParticleNetworkState;
      expect(state.touchPoint, Offset.infinite);

      // Simulate touch
      await tester.tapAt(const Offset(50, 50));
      expect(state.touchPoint, Offset.infinite);
    });
    /////

    ////////////////
    testWidgets('resets touchPoint to Offset.infinite on pan cancel', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ParticleNetwork(particleCount: 5, touchActivation: true),
        ),
      );

      final state =
          tester.state(find.byType(ParticleNetwork)) as ParticleNetworkState;

      // تحقق من أن النقطة الابتدائية هي infinite (أي لا تفاعل)
      expect(state.touchPoint, Offset.infinite);

      // اسحب من (50,50) إلى (100,100) — هذا يشغل onPanUpdate
      final gesture = await tester.startGesture(const Offset(50, 50));
      await gesture.moveTo(const Offset(100, 100));

      // الآن نلغي السحب باستخدام cancel
      await gesture.cancel(); // هذا يُشغّل onPanCancel

      // استخدم pump لتحديث الواجهة بشكل صريح
      await tester.pump(); // نستخدم pump بدلاً من pumpAndSettle

      // تحقق أن touchPoint تم تعيينه إلى Offset.infinite بعد الإلغاء
      expect(state.touchPoint, Offset.infinite);
    });
  });

  testWidgets('updates touchPoint on pan update when touchActivation is true', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ParticleNetwork(particleCount: 5, touchActivation: true),
      ),
    );

    final state =
        tester.state(find.byType(ParticleNetwork)) as ParticleNetworkState;
    debugPrint(
      'Initial touchPoint: ${state.touchPoint}',
    ); // Debug initial state

    // Perform the gesture
    final gesture = await tester.startGesture(const Offset(50, 50));
    await gesture.moveTo(const Offset(100, 100));
    await gesture.up();

    // Give time for the gesture to be processed
    await tester.pump();
    await tester.pump(
      const Duration(milliseconds: 500),
    ); // Longer delay for debugging

    debugPrint(
      'Current touchPoint: ${state.touchPoint}',
    ); // Debug current state
    expect(state.touchPoint, const Offset(100, 100));
  });
}
