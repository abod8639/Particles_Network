// ignore_for_file: avoid_print
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/model/default_particle_factory.dart';
import 'package:particles_network/model/ip_article.dart';
import 'package:particles_network/model/particlemodel.dart';
import 'package:particles_network/painter/optimized_network_painter.dart';

void main() {
  test('Benchmark 500 particles simulation and paint', () {
    final random = Random(42);
    final factory = DefaultParticleFactory(
      random: random,
      maxSpeed: 1.5,
      maxSize: 2.0,
      color: Colors.white,
    );

    const size = Size(1920, 1080);
    final particles = List<Particle>.generate(500, (_) => factory.createParticle(size));
    final updater = ParticleUpdater();

    // Warm up
    for (int i = 0; i < 20; i++) {
      updater.updateParticles(particles, size);
    }

    // Benchmark 1: 500 particles, line distance 100, fill: true
    final painterFill = OptimizedNetworkPainter(
      particleCount: particles.length,
      particles: particles,
      touchPoint: null,
      lineDistance: 100,
      particleColor: Colors.white,
      lineColor: Colors.white,
      touchColor: Colors.amber,
      touchActivation: false,
      lineWidth: 1.0,
      isComplex: false,
      fill: true,
      drawNetwork: true,
    );

    final sw1 = Stopwatch()..start();
    const int frames = 300;
    for (int i = 0; i < frames; i++) {
      updater.updateParticles(particles, size);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painterFill.paint(canvas, size);
      final picture = recorder.endRecording();
      picture.dispose();
    }
    sw1.stop();
    final double avgMs1 = sw1.elapsedMicroseconds / (frames * 1000.0);
    print('BENCHMARK 1 (500 particles, fill: true): ${avgMs1.toStringAsFixed(3)} ms/frame');


    // Detailed breakdown for 500 particles:
    final swPhysics = Stopwatch();
    final swPainter = Stopwatch();

    for (int i = 0; i < frames; i++) {
      swPhysics.start();
      updater.updateParticles(particles, size);
      swPhysics.stop();

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      swPainter.start();
      painterFill.paint(canvas, size);
      swPainter.stop();

      final picture = recorder.endRecording();
      picture.dispose();
    }

    final double p500Physics = swPhysics.elapsedMicroseconds / (frames * 1000.0);
    final double p500Painter = swPainter.elapsedMicroseconds / (frames * 1000.0);
    final double p500Total = p500Physics + p500Painter;

    print('=== SCALABILITY BENCHMARK ===');
    print('500 particles (fill: true):');
    print('  - Physics Update: ${p500Physics.toStringAsFixed(3)} ms');
    print('  - Painter Render: ${p500Painter.toStringAsFixed(3)} ms');
    print('  - Total Frame:    ${p500Total.toStringAsFixed(3)} ms (${(1000 / p500Total).toStringAsFixed(0)} FPS capability)');

    // 1000 particles test:
    final particles1000 = List<Particle>.generate(1000, (_) => factory.createParticle(size));
    final painter1000 = OptimizedNetworkPainter(
      particleCount: particles1000.length,
      particles: particles1000,
      touchPoint: null,
      lineDistance: 100,
      particleColor: Colors.white,
      lineColor: Colors.white,
      touchColor: Colors.amber,
      touchActivation: false,
      lineWidth: 1.0,
      isComplex: false,
      fill: true,
      drawNetwork: true,
    );

    final sw1000Physics = Stopwatch();
    final sw1000Painter = Stopwatch();
    for (int i = 0; i < frames; i++) {
      sw1000Physics.start();
      updater.updateParticles(particles1000, size);
      sw1000Physics.stop();

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      sw1000Painter.start();
      painter1000.paint(canvas, size);
      sw1000Painter.stop();

      final picture = recorder.endRecording();
      picture.dispose();
    }

    final double p1000Physics = sw1000Physics.elapsedMicroseconds / (frames * 1000.0);
    final double p1000Painter = sw1000Painter.elapsedMicroseconds / (frames * 1000.0);
    final double p1000Total = p1000Physics + p1000Painter;

    print('1000 particles (fill: true):');
    print('  - Physics Update: ${p1000Physics.toStringAsFixed(3)} ms');
    print('  - Painter Render: ${p1000Painter.toStringAsFixed(3)} ms');
    print('  - Total Frame:    ${p1000Total.toStringAsFixed(3)} ms (${(1000 / p1000Total).toStringAsFixed(0)} FPS capability)');
  });
}



