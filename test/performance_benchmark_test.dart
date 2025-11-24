import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/model/default_particle_factory.dart';
import 'package:particles_network/model/ip_article.dart';
import 'package:particles_network/model/particlemodel.dart';
import 'package:particles_network/painter/optimized_network_painter.dart';
import 'dart:math';

void main() {
  test('Performance Benchmark: Update Loop', () {
    final int particleCount = 1000;
    final Size size = Size(1000, 1000);
    final Random random = Random(42); // Fixed seed for reproducibility
    
    final factory = DefaultParticleFactory(
      random: random,
      maxSpeed: 1.0,
      maxSize: 2.0,
      color: Colors.white,
    );
    
    final List<Particle> particles = List.generate(
      particleCount, 
      (_) => factory.createParticle(size)
    );
    
    final controller = ParticleUpdater();
    
    final stopwatch = Stopwatch()..start();
    
    // Run 1000 frames
    for (int i = 0; i < 1000; i++) {
      controller.updateParticles(particles, size);
    }
    
    stopwatch.stop();
    print('Update Loop (1000 particles, 1000 frames): ${stopwatch.elapsedMilliseconds}ms');
    
    // Expect reasonable performance (e.g. < 500ms for 1M updates is very fast, 
    // but Dart is fast. 1000 * 1000 = 1M updates. 
    // If it takes < 100ms, that's great.)
  });

  test('Performance Benchmark: Rendering', () {
    final int particleCount = 500;
    final Size size = Size(1000, 1000);
    final Random random = Random(42);
    
    final factory = DefaultParticleFactory(
      random: random,
      maxSpeed: 1.0,
      maxSize: 2.0,
      color: Colors.white,
    );
    
    final List<Particle> particles = List.generate(
      particleCount, 
      (_) => factory.createParticle(size)
    );
    
    // Initialize painter
    final painter = OptimizedNetworkPainter(
      particleCount: particleCount,
      particles: particles,
      touchPoint: Offset.zero,
      lineDistance: 100,
      particleColor: Colors.white,
      lineColor: Colors.blue,
      touchColor: Colors.red,
      touchActivation: true,
      lineWidth: 1.0,
      isComplex: false,
      fill: true,
      drawNetwork: true,
    );
    
    // Mock canvas
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    
    final stopwatch = Stopwatch()..start();
    
    // Render 100 frames
    for (int i = 0; i < 100; i++) {
      painter.paint(canvas, size);
    }
    
    stopwatch.stop();
    print('Rendering (500 particles, 100 frames): ${stopwatch.elapsedMilliseconds}ms');
  });
}
