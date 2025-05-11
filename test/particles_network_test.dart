import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/model/computevelocity_model.dart';
import 'package:particles_network/model/particlemodel.dart';
import 'package:particles_network/painter/optimizednetworkpainter.dart';
import 'package:particles_network/particles_network.dart';

/// Test suite for the Particles Network package
/// Tests core functionality, particle behavior, and widget rendering
void main() {
  test('decayVelocity returns smooth interpolated velocity', () {
    final currentVelocity = const Offset(4, 0);
    final defaultVelocity = const Offset(1, 0);
    final currentSpeed = currentVelocity.distance;
    final defaultSpeed = defaultVelocity.distance;

    final result = decayVelocity(
      currentVelocity: currentVelocity,
      defaultVelocity: defaultVelocity,
      currentSpeed: currentSpeed,
      defaultSpeed: defaultSpeed,
    );

    // currentVelocity و targetVelocity
    expect(result.dx, lessThan(currentVelocity.dx));
    expect(result.dx, greaterThan(defaultVelocity.dx));
    expect(result.dy, 0); // x
  });

  group('ParticleNetwork Widget Tests', () {
    testWidgets('Widget creates with default parameters', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ParticleNetwork())),
      );

      // Verify widget exists in tree
      expect(find.byType(ParticleNetwork), findsOneWidget);
    });

    testWidgets('Widget respects custom parameters', (tester) async {
      const particleCount = 30;
      const maxSpeed = 1.0;
      const maxSize = 5.0;
      const lineDistance = 200.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ParticleNetwork(
              particleCount: particleCount,
              maxSpeed: maxSpeed,
              maxSize: maxSize,
              lineDistance: lineDistance,
              particleColor: Colors.red,
              lineColor: Colors.blue,
              touchColor: Colors.green,
            ),
          ),
        ),
      );

      // Verify widget exists
      expect(find.byType(ParticleNetwork), findsOneWidget);
    });
  });
  test('applyTouchInteraction affects close particles', () {
    final particles = [
      Particle(
        position: Offset(100, 100),
        velocity: Offset.zero,
        color: Colors.white,
        size: 2.0,
      ), // close to touch
      Particle(
        position: Offset(300, 300),
        velocity: Offset.zero,
        color: Colors.white,
        size: 2.0,
      ), // far from touch
    ];

    final touchPoint = Offset(110, 110);
    final visibleIndices = [0, 1];
    final lineDistance = 50.0;

    applyTouchInteraction(
      touch: touchPoint,
      lineDistance: lineDistance,
      particles: particles,
      visibleIndices: visibleIndices,
    );

    // Particle 0 should be affected
    expect(particles[0].wasAccelerated, isTrue);
    expect(particles[0].velocity.distance, greaterThan(0));

    // Particle 1 should be unaffected
    expect(particles[1].wasAccelerated, isFalse);
    expect(particles[1].velocity, Offset.zero);
  });
  group('Particle Model Tests', () {
    test('Particle updates position correctly', () {
      final particle = Particle(
        position: const Offset(100, 100),
        velocity: const Offset(1, 1),
        color: Colors.white,
        size: 2.0,
      );

      // Test particle movement
      particle.update(const Size(500, 500));
      expect(particle.position.dx, 101);
      expect(particle.position.dy, 101);
    });

    test('Particle bounds checking works', () {
      // Test particle at right edge
      final rightParticle = Particle(
        position: const Offset(499, 100),
        velocity: const Offset(2, 0),
        color: Colors.white,
        size: 2.0,
      );

      rightParticle.update(const Size(500, 500));
      // Velocity should be reversed
      expect(rightParticle.velocity.dx < 0, true);

      // Test particle at bottom edge
      final bottomParticle = Particle(
        position: const Offset(100, 499),
        velocity: const Offset(0, 2),
        color: Colors.white,
        size: 2.0,
      );

      bottomParticle.update(const Size(500, 500));
      // Velocity should be reversed
      expect(bottomParticle.velocity.dy < 0, true);
    });

    test('Particle acceleration flag works', () {
      final particle = Particle(
        position: const Offset(100, 100),
        velocity: const Offset(1, 1),
        color: Colors.white,
        size: 2.0,
      );

      expect(particle.wasAccelerated, false);

      // Simulate touch acceleration
      particle.velocity += const Offset(0.5, 0.5);
      particle.wasAccelerated = true;

      expect(particle.wasAccelerated, true);
    });

    test(
      'computeVelocity returns defaultVelocity when difference < threshold',
      () {
        final v = computeVelocity(Offset(1, 1), Offset(1, 1), 0.1);
        expect(v.dx, closeTo(1.0, 0.01));
        expect(v.dy, closeTo(1.0, 0.01));
      },
    );
  });
}
