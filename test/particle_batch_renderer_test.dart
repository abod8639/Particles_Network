import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/src/core/particle.dart';
import 'package:particles_network/src/rendering/particle_batch_renderer.dart';

import 'golden_characterization_test.dart';

void main() {
  group('ParticleBatchRenderer Unit Tests', () {
    late ParticleBatchRenderer renderer;
    late RecordingCanvas canvas;

    setUp(() {
      renderer = ParticleBatchRenderer();
      canvas = RecordingCanvas();
    });

    test('Draws circles when fill is false', () {
      final particles = [
        Particle(
          position: const Offset(10, 10),
          velocity: Offset.zero,
          size: 2.0,
          color: const Color(0xFFFFFFFF),
        ),
        Particle(
          position: const Offset(20, 20),
          velocity: Offset.zero,
          size: 3.0,
          color: const Color(0xFFFFFFFF),
        ),
      ];

      final paint = Paint();
      renderer.draw(
        canvas: canvas,
        particles: particles,
        visibleParticles: [0, 1],
        particlePaint: paint,
        fill: false,
        antiAlias: true,
        particleColor: const Color(0xFFFFFFFF),
      );

      expect(canvas.circleCalls.length, equals(2));
      expect(canvas.rawPointsCalls.length, equals(0));
    });

    test(
      'Batches points into size buckets when fill is true and count >= 5',
      () {
        final particles = List.generate(
          10,
          (i) => Particle(
            position: Offset(i * 10.0, i * 10.0),
            velocity: Offset.zero,
            size: 2.0,
            color: const Color(0xFFFFFFFF),
          ),
        );

        final paint = Paint();
        renderer.draw(
          canvas: canvas,
          particles: particles,
          visibleParticles: List.generate(10, (i) => i),
          particlePaint: paint,
          fill: true,
          antiAlias: true,
          particleColor: const Color(0xFFFFFFFF),
        );

        expect(canvas.circleCalls.length, equals(0));
        expect(canvas.rawPointsCalls.length, greaterThan(0));
        expect(canvas.rawPointsCalls[0].pointMode, equals(PointMode.points));
      },
    );
  });
}
