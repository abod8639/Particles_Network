import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/particles_network.dart';

class _LegacyController implements IParticleController {
  int calls = 0;

  @override
  void updateParticles(
    List<Particle> particles,
    Size bounds, {
    GravityConfig gravity = const GravityConfig(),
  }) {
    calls++;
  }
}

List<Particle> _uniformParticles(int count, Size size, [int seed = 7]) {
  final factory = DefaultParticleFactory(
    random: Random(seed),
    maxSpeed: 0.5,
    maxSize: 1.5,
    color: Colors.white,
  );
  return List<Particle>.generate(count, (_) => factory.createParticle(size));
}

OptimizedNetworkPainter _painter(
  List<Particle> particles, {
  int? maxLinesPerFrame,
  bool fastLineRendering = false,
  bool isComplex = false,
}) {
  return OptimizedNetworkPainter(
    particleCount: particles.length,
    particles: particles,
    touchPoint: null,
    lineDistance: 100,
    particleColor: Colors.white,
    lineColor: Colors.white,
    touchColor: Colors.amber,
    touchActivation: false,
    lineWidth: 1,
    isComplex: isComplex,
    fill: true,
    drawNetwork: true,
    fastLineRendering: fastLineRendering,
    maxLinesPerFrame: maxLinesPerFrame,
  );
}

void _paintFrames(OptimizedNetworkPainter painter, Size size, int frames) {
  for (int i = 0; i < frames; i++) {
    final recorder = PictureRecorder();
    painter.paint(Canvas(recorder), size);
    recorder.endRecording().dispose();
  }
}

void main() {
  group('Frame-rate independent physics', () {
    const Size bounds = Size(1000, 1000);

    test('update() is identical to advance(bounds, 1.0)', () {
      final a = Particle(
        position: const Offset(100, 100),
        velocity: const Offset(3, -2),
        color: Colors.white,
        size: 2,
      )..applyForceRaw(4, 4);
      final b = Particle(
        position: const Offset(100, 100),
        velocity: const Offset(3, -2),
        color: Colors.white,
        size: 2,
      )..applyForceRaw(4, 4);

      a.update(bounds);
      b.advance(bounds, 1.0);

      expect(b.x, a.x);
      expect(b.y, a.y);
      expect(b.vx, a.vx);
      expect(b.vy, a.vy);
    });

    test('two half steps cover the same distance as one full step', () {
      final full = Particle(
        position: const Offset(100, 100),
        velocity: const Offset(2, 1),
        color: Colors.white,
        size: 1,
      );
      final half = Particle(
        position: const Offset(100, 100),
        velocity: const Offset(2, 1),
        color: Colors.white,
        size: 1,
      );

      full.advance(bounds, 1.0);
      half
        ..advance(bounds, 0.5)
        ..advance(bounds, 0.5);

      expect(half.x, closeTo(full.x, 1e-9));
      expect(half.y, closeTo(full.y, 1e-9));
    });

    test('post-touch speed decay converges at the same rate per second', () {
      Particle accelerated() => Particle(
            position: const Offset(500, 500),
            velocity: const Offset(1, 0),
            color: Colors.white,
            size: 1,
          )
            ..vx = 10
            ..wasAccelerated = true
            ..decayRate = 0.1;

      final at60 = accelerated();
      final at120 = accelerated();
      for (int i = 0; i < 30; i++) {
        at60.advance(bounds, 1.0);
        at120
          ..advance(bounds, 0.5)
          ..advance(bounds, 0.5);
      }

      expect(at120.vx, closeTo(at60.vx, 0.05));
    });

    test('scaleFrameRate composes over sub-steps', () {
      const double rate = 0.2;
      final double half = scaleFrameRate(rate, 0.5);
      // Applying the half-step rate twice equals one full-step rate.
      expect((1 - half) * (1 - half), closeTo(1 - rate, 1e-12));
      expect(scaleFrameRate(rate, 1.0), rate);
    });

    test('ParticleSimulation passes the time scale to ParticleUpdater', () {
      final sim = ParticleSimulation(particleCount: 1)
        ..updateSize(const Size(500, 500));
      final p = sim.particles.first
        ..x = 250
        ..y = 250
        ..vx = 4
        ..vy = 0;

      sim.step(0.5);

      expect(p.x, closeTo(252, 1e-9));
    });

    test('custom controllers without time scaling keep working', () {
      final controller = _LegacyController();
      final sim = ParticleSimulation(particleCount: 3, controller: controller)
        ..updateSize(const Size(200, 200));

      sim.step(0.5);
      sim.step();

      expect(controller.calls, 2);
    });
  });

  group('Line budget (maxLinesPerFrame)', () {
    const Size size = Size(400, 800);

    test('without a budget, 1500 particles draw far more lines', () {
      final particles = _uniformParticles(1500, size);
      final painter = _painter(particles);
      _paintFrames(painter, size, 1);

      expect(painter.lastFrameLineCount, greaterThan(30000));
      expect(painter.lastFrameLineDistance, 100);
    });

    for (final bool fast in [false, true]) {
      test('converges near the budget (fastLineRendering: $fast)', () {
        final particles = _uniformParticles(1500, size);
        final painter = _painter(
          particles,
          maxLinesPerFrame: 4000,
          fastLineRendering: fast,
        );
        _paintFrames(painter, size, 20);

        expect(painter.lastFrameLineCount, inInclusiveRange(3200, 4800));
        expect(painter.lastFrameLineDistance, lessThan(100));
      });
    }

    test('converges for the isComplex path too', () {
      final particles = _uniformParticles(1500, size);
      final painter = _painter(
        particles,
        maxLinesPerFrame: 4000,
        isComplex: true,
      );
      _paintFrames(painter, size, 20);

      // isComplex also throttles dense neighbourhoods, so it may stay under.
      expect(painter.lastFrameLineCount, lessThanOrEqualTo(4800));
      expect(painter.lastFrameLineDistance, lessThan(100));
    });

    test('corrects for clustered particles', () {
      // All particles packed into a quarter of the screen: the analytic
      // estimate (uniform spread) undershoots, feedback must compensate.
      final particles = _uniformParticles(1200, const Size(200, 400));
      final painter = _painter(particles, maxLinesPerFrame: 3000);
      _paintFrames(painter, size, 30);

      expect(painter.lastFrameLineCount, inInclusiveRange(2400, 3600));
    });

    test('never exceeds lineDistance when the budget is not binding', () {
      final particles = _uniformParticles(60, size);
      final painter = _painter(particles, maxLinesPerFrame: 100000);
      _paintFrames(painter, size, 5);

      expect(painter.lastFrameLineDistance, 100);
    });

    test('can be cleared at runtime', () {
      final particles = _uniformParticles(1500, size);
      final painter = _painter(particles, maxLinesPerFrame: 4000);
      _paintFrames(painter, size, 5);
      painter.updatePerformanceOptions(clearMaxLinesPerFrame: true);
      _paintFrames(painter, size, 1);

      expect(painter.maxLinesPerFrame, isNull);
      expect(painter.lastFrameLineDistance, 100);
    });
  });

  group('ParticleNetwork widget', () {
    Widget network({int count = 200, int? budget, bool fri = false}) {
      return MaterialApp(
        home: SizedBox(
          width: 400,
          height: 400,
          child: ParticleNetwork(
            particleCount: count,
            maxLinesPerFrame: budget,
            frameRateIndependent: fri,
          ),
        ),
      );
    }

    testWidgets('forwards maxLinesPerFrame to the painter', (tester) async {
      await tester.pumpWidget(network(budget: 500));
      final state =
          tester.state<ParticleNetworkState>(find.byType(ParticleNetwork));
      final painter = tester
          .widget<CustomPaint>(
            find.descendant(
              of: find.byType(ParticleNetwork),
              matching: find.byType(CustomPaint),
            ),
          )
          .painter as OptimizedNetworkPainter;
      expect(painter.maxLinesPerFrame, 500);
      expect(painter.simulateTouchInPaint, isFalse);

      await tester.pumpWidget(network(budget: null));
      expect(painter.maxLinesPerFrame, isNull);
      expect(state.mounted, isTrue);
    });

    testWidgets('frameRateIndependent halves per-tick motion at 120 Hz',
        (tester) async {
      Future<double> distanceOverTicks(bool fri) async {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(network(count: 1, fri: fri));
        final state =
            tester.state<ParticleNetworkState>(find.byType(ParticleNetwork));
        await tester.pump(const Duration(microseconds: 8333));
        final p = state.particles.first
          ..x = 200
          ..y = 200
          ..vx = 1
          ..vy = 0
          ..defaultVx = 1
          ..defaultVy = 0;
        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(microseconds: 8333));
        }
        return p.x - 200;
      }

      final double perFrame = await distanceOverTicks(false);
      final double perTime = await distanceOverTicks(true);

      expect(perFrame, closeTo(10, 1e-6));
      expect(perTime, closeTo(5, 0.01));
    });

    testWidgets('shrinking particleCount during touch does not throw',
        (tester) async {
      await tester.pumpWidget(network(count: 300));
      final gesture = await tester.startGesture(const Offset(200, 200));
      await tester.pump(const Duration(milliseconds: 16));

      await tester.pumpWidget(network(count: 10));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));

      await gesture.up();
      expect(tester.takeException(), isNull);
    });
  });
}
