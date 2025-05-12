import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/model/particlemodel.dart';
import 'package:particles_network/particles_network.dart';

import 'fakeparticle.dart';

/// Test suite for the Particles Network package
/// Tests core functionality, particle behavior, and widget rendering
///

//////////////////////////////
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

    testWidgets('regenerates particles when size changes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 100,
            height: 100,
            child: ParticleNetwork(particleCount: 10),
          ),
        ),
      );

      final state =
          tester.state(find.byType(ParticleNetwork)) as ParticleNetworkState;
      final initialParticles = List<Particle>.from(state.particles);

      // Change size
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 200,
            height: 200,
            child: ParticleNetwork(particleCount: 10),
          ),
        ),
      );

      expect(state.particles, isNot(equals(initialParticles)));
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

    testWidgets('handles touch events when touchActivation is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ParticleNetwork(particleCount: 5, touchActivation: true),
        ),
      );

      final state =
          tester.state(find.byType(ParticleNetwork)) as ParticleNetworkState;
      expect(state.touchPoint, Offset.infinite);

      // Simulate touch
      await tester.tapAt(const Offset(50, 50));
      expect(state.touchPoint, const Offset(50, 50));

      // Simulate touch end
      await tester.pump(const Duration(milliseconds: 100));
      final gesture = await tester.startGesture(const Offset(50, 50));
      await gesture.up();
      await tester.pump();
      expect(state.touchPoint, Offset.infinite);
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

    testWidgets('disposes resources correctly', (tester) async {
      final mockController = MockParticleController();
      final element = await tester.pumpWidget(
        MaterialApp(
          home: ParticleNetwork(
            particleCount: 5,
            particleController: mockController,
          ),
        ),
      );

      // Verify ticker is running
      final state =
          tester.state(find.byType(ParticleNetwork)) as ParticleNetworkState;
      expect(state.ticker.isActive, isTrue);

      // Dispose
      await tester.pumpWidget(Container());
      expect(state.ticker.isActive, isFalse);
    });
  });

  ///////////////////////////////////////////
  group('DefaultParticleFactory', () {
    test('creates particle within given size bounds', () {
      final random = Random(42); // ثابت لاختبار متكرر
      final factory = DefaultParticleFactory(
        random: random,
        maxSpeed: 1.0,
        maxSize: 5.0,
        color: Colors.red,
      );

      final size = Size(100, 100);
      final particle = factory.createParticle(size);

      expect(particle.position.dx, inInclusiveRange(0, size.width));
      expect(particle.position.dy, inInclusiveRange(0, size.height));
      expect(particle.size, inInclusiveRange(1, 6)); // لأن: random * 5 + 1
      expect(particle.velocity.dx, inInclusiveRange(-0.5, 0.5));
      expect(particle.velocity.dy, inInclusiveRange(-0.5, 0.5));
      expect(particle.color, equals(Colors.red));
    });
  });

  group('ParticleUpdater', () {
    test('updates particles within bounds', () {
      final particle = Particle(
        color: Colors.blue,
        position: Offset(10, 10),
        velocity: Offset(2, 3),
        size: 2,
      );

      final controller = ParticleUpdater();
      final particles = [particle];
      final bounds = Size(100, 100);

      controller.updateParticles(particles, bounds);

      expect(particle.position.dx, greaterThan(10));
      expect(particle.position.dy, greaterThan(10));
    });

    test('bounces particle off horizontal wall', () {
      final particle = Particle(
        color: Colors.blue,
        position: Offset(99, 10), // قريب من الحد الأيمن
        velocity: Offset(5, 0),
        size: 2,
      );

      final controller = ParticleUpdater();
      final bounds = Size(100, 100);
      controller.updateParticles([particle], bounds);

      expect(particle.velocity.dx, lessThan(0)); // يجب أن ينعكس
    });
  });

  ///////////////////////////////////////////////////////
  // 1. اختبار إنشاء الجسيم
  group('Particle Constructor Tests', () {
    test('Creates particle with correct initial properties', () {
      final position = Offset(100, 100);
      final velocity = Offset(2, 3);
      final color = Colors.blue;
      final size = 5.0;

      final particle = Particle(
        position: position,
        velocity: velocity,
        color: color,
        size: size,
      );

      expect(particle.position, equals(position));
      expect(particle.velocity, equals(velocity));
      expect(particle.defaultVelocity, equals(velocity));
      expect(particle.color, equals(color));
      expect(particle.size, equals(size));
      expect(particle.wasAccelerated, isFalse);
      expect(particle.isVisible, isTrue);
    });

    test('Creates mock particle with default values', () {
      final mockParticle = createMockParticle();

      expect(mockParticle.position, equals(Offset.zero));
      expect(mockParticle.velocity, equals(Offset.zero));
      expect(mockParticle.color, equals(Colors.white));
      expect(mockParticle.size, equals(1.0));
    });

    test('Creates mock particle with custom values', () {
      final position = Offset(50, 50);
      final velocity = Offset(1, 1);
      final color = Colors.red;
      final size = 2.0;

      final mockParticle = createMockParticle(
        position: position,
        velocity: velocity,
        color: color,
        size: size,
      );

      expect(mockParticle.position, equals(position));
      expect(mockParticle.velocity, equals(velocity));
      expect(mockParticle.color, equals(color));
      expect(mockParticle.size, equals(size));
    });
  });

  // 2. اختبار تحديث موقع الجسيم
  group('Particle Update Tests', () {
    test('Updates position based on velocity', () {
      final particle = Particle(
        position: Offset(10, 10),
        velocity: Offset(5, 5),
        color: Colors.white,
        size: 1.0,
      );

      final bounds = Size(800, 600);
      particle.update(bounds);

      expect(particle.position, equals(Offset(15, 15)));
    });

    test('Gradually reduces velocity when accelerated', () {
      final particle = Particle(
        position: Offset(100, 100),
        velocity: Offset(10, 10),
        color: Colors.white,
        size: 1.0,
      );

      // ضبط السرعة الافتراضية لتكون أقل من السرعة الحالية
      particle.defaultVelocity = Offset(2, 2);
      particle.wasAccelerated = true;

      final bounds = Size(800, 600);
      particle.update(bounds);
      const double sqrt2 = 1.4142;

      // توقع أن تكون السرعة قد انخفضت لكن لا تزال أكبر من السرعة الافتراضية
      expect(particle.velocity.distance, lessThan(10 * sqrt2));
      expect(particle.velocity.distance, greaterThan(2 * sqrt2));
    });
  });

  // 3. اختبار معالجة حدود الشاشة
  group('Screen Boundaries Tests', () {
    test('Reverses x-velocity when hitting left boundary', () {
      final particle = Particle(
        position: Offset(-5, 100), // خارج الحد الأيسر
        velocity: Offset(-2, 3),
        color: Colors.white,
        size: 1.0,
      );

      final bounds = Size(800, 600);
      particle.handleScreenBoundaries(bounds);

      expect(particle.velocity.dx, equals(2)); // عكس اتجاه dx
      expect(particle.velocity.dy, equals(3)); // بقاء dy كما هو
      expect(
        particle.defaultVelocity.dx,
        equals(2),
      ); // عكس اتجاه dx الافتراضي أيضاً
      expect(particle.defaultVelocity.dy, equals(3));
    });

    test('Reverses x-velocity when hitting right boundary', () {
      final particle = Particle(
        position: Offset(805, 100), // خارج الحد الأيمن
        velocity: Offset(2, 3),
        color: Colors.white,
        size: 1.0,
      );

      final bounds = Size(800, 600);
      particle.handleScreenBoundaries(bounds);

      expect(particle.velocity.dx, equals(-2)); // عكس اتجاه dx
      expect(particle.velocity.dy, equals(3)); // بقاء dy كما هو
    });

    test('Reverses y-velocity when hitting top boundary', () {
      final particle = Particle(
        position: Offset(100, -5), // خارج الحد العلوي
        velocity: Offset(2, -3),
        color: Colors.white,
        size: 1.0,
      );

      final bounds = Size(800, 600);
      particle.handleScreenBoundaries(bounds);

      expect(particle.velocity.dx, equals(2)); // بقاء dx كما هو
      expect(particle.velocity.dy, equals(3)); // عكس اتجاه dy
    });

    test('Reverses y-velocity when hitting bottom boundary', () {
      final particle = Particle(
        position: Offset(100, 605), // خارج الحد السفلي
        velocity: Offset(2, 3),
        color: Colors.white,
        size: 1.0,
      );

      final bounds = Size(800, 600);
      particle.handleScreenBoundaries(bounds);

      expect(particle.velocity.dx, equals(2)); // بقاء dx كما هو
      expect(particle.velocity.dy, equals(-3)); // عكس اتجاه dy
    });
  });

  // 4. اختبار تحديث حالة الرؤية
  group('Visibility Update Tests', () {
    test('Particle is visible when in bounds', () {
      final particle = Particle(
        position: Offset(100, 100),
        velocity: Offset(2, 3),
        color: Colors.white,
        size: 1.0,
      );

      final bounds = Size(800, 600);
      particle.updateVisibility(bounds);

      expect(particle.isVisible, isTrue);
    });

    test('Particle is visible when slightly out of bounds (within margin)', () {
      final particle = Particle(
        position: Offset(-50, 100), // خارج الحدود قليلاً لكن ضمن الهامش
        velocity: Offset(2, 3),
        color: Colors.white,
        size: 1.0,
      );

      final bounds = Size(800, 600);
      particle.updateVisibility(bounds);

      expect(particle.isVisible, isTrue);
    });

    test('Particle is not visible when far out of bounds', () {
      final particle = Particle(
        position: Offset(-150, 100), // خارج الحدود بشكل كبير
        velocity: Offset(2, 3),
        color: Colors.white,
        size: 1.0,
      );

      final bounds = Size(800, 600);
      particle.updateVisibility(bounds);

      expect(particle.isVisible, isFalse);
    });
  });

  // 5. اختبار دالة computeVelocity
  group('Compute Velocity Tests', () {
    test('Returns default velocity when speeds are close', () {
      final currentVelocity = Offset(2.001, 3.001);
      final defaultVelocity = Offset(2.000, 3.000);
      final speedThreshold = 0.01;

      final result = computeVelocity(
        currentVelocity,
        defaultVelocity,
        speedThreshold,
      );

      expect(result, equals(defaultVelocity));
    });

    test('Gradually reduces velocity towards default', () {
      final currentVelocity = Offset(10.0, 0.0);
      final defaultVelocity = Offset(2.0, 0.0);
      final speedThreshold = 0.01;

      final result = computeVelocity(
        currentVelocity,
        defaultVelocity,
        speedThreshold,
      );

      // توقع أن تكون السرعة قد انخفضت لكن لا تزال أكبر من السرعة الافتراضية
      expect(result.dx, lessThan(10.0));
      expect(result.dx, greaterThan(2.0));
    });

    test('Maintains direction when reducing speed', () {
      final currentVelocity = Offset(10.0, 10.0);
      final defaultVelocity = Offset(1.0, 1.0);
      final speedThreshold = 0.01;

      final result = computeVelocity(
        currentVelocity,
        defaultVelocity,
        speedThreshold,
      );

      // التحقق من أن الاتجاه لم يتغير (نسبة dx إلى dy)
      expect(result.dx / result.dy, closeTo(1.0, 0.00001));
    });
  });

  // تعريف بسيط لثابت رياضي مستخدم في الاختبارات
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
      expect(particle.position, const Offset(101, 101));
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
      expect(rightParticle.velocity.dx, lessThan(0));

      // Test particle at bottom edge
      final bottomParticle = Particle(
        position: const Offset(100, 499),
        velocity: const Offset(0, 2),
        color: Colors.white,
        size: 2.0,
      );

      bottomParticle.update(const Size(500, 500));
      // Velocity should be reversed
      expect(bottomParticle.velocity.dy, lessThan(0));
    });

    test('Particle acceleration flag works', () {
      final particle = Particle(
        position: const Offset(100, 100),
        velocity: const Offset(1, 1),
        color: Colors.white,
        size: 2.0,
      );

      expect(particle.wasAccelerated, isFalse);

      // Simulate touch acceleration
      particle.velocity += const Offset(0.5, 0.5);
      particle.wasAccelerated = true;

      expect(particle.wasAccelerated, isTrue);
      expect(particle.velocity, const Offset(1.5, 1.5));
    });

    test('Particle visibility updates correctly', () {
      final particle = Particle(
        position: const Offset(50, 50),
        velocity: const Offset(0, 0),
        color: Colors.white,
        size: 2.0,
      );

      // Test visibility within bounds
      particle.updateVisibility(const Size(500, 500));
      expect(particle.isVisible, isTrue);

      // Test visibility outside bounds
      particle.position = const Offset(-200, -200);
      particle.updateVisibility(const Size(500, 500));
      expect(particle.isVisible, isFalse);
    });
  });
}
