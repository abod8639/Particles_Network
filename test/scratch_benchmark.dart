import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/particles_network.dart';
import 'package:particles_network/model/default_particle_factory.dart';
import 'package:particles_network/model/ip_article.dart';
import 'package:particles_network/model/trajectory_buffer.dart';
import 'package:particles_network/painter/optimized_network_painter.dart';

void main() {
  test('Check frames WITH TrajectoryBuffer', () {
    const int particleCount = 500;
    const Size size = Size(1000, 1000);
    final Random random = Random(42);

    final factory = DefaultParticleFactory(
      random: random,
      maxSpeed: 1.5,
      maxSize: 2.0,
      color: Colors.white,
    );

    final List<Particle> particles = List.generate(
      particleCount,
      (_) => factory.createParticle(size),
    );

    final controller = ParticleUpdater();
    final buffer = TrajectoryBuffer(capacity: 120);

    final painter = OptimizedNetworkPainter(
      particleCount: particleCount,
      particles: particles,
      touchPoint: Offset.zero,
      lineDistance: 100,
      particleColor: Colors.white,
      lineColor: Colors.teal,
      touchColor: Colors.amber,
      touchActivation: true,
      lineWidth: 1.0,
      isComplex: false,
      fill: true,
      drawNetwork: true,
    );

    // Warmup
    for (int i = 0; i < 20; i++) {
      controller.updateParticles(particles, size);
      final rec = PictureRecorder();
      painter.paint(Canvas(rec), size);
    }

    print('--- Starting 360 frames test with TrajectoryBuffer ---');
    for (int frame = 0; frame < 360; frame++) {
      final sw = Stopwatch()..start();
      
      // Mimic ticker exactly:
      if (!buffer.advance(particles)) {
        final swP = Stopwatch()..start();
        buffer.precompute(
          particles: particles,
          bounds: size,
          controller: controller,
          gravity: const GravityConfig(),
        );
        swP.stop();
        buffer.advance(particles);
        print('Frame $frame: PRECOMPUTE TOOK ${swP.elapsedMicroseconds / 1000} ms!');
      }

      final rec = PictureRecorder();
      painter.paint(Canvas(rec), size);
      sw.stop();

      final totalMs = sw.elapsedMicroseconds / 1000;
      if (totalMs > 16.6) {
        print('JANK FRAME $frame: Total = $totalMs ms');
      }
    }
  });
}
