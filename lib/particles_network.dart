import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:particles_network/model/particlemodel.dart';
import 'package:particles_network/painter/optimizednetworkpainter.dart';

// ParticleNetwork is a customizable widget that displays an animated network of particles.
// It supports touch interaction, color customization, and performance optimizations.
class ParticleNetwork extends StatefulWidget {
  // Number of particles to display in the network.
  final int particleCount;
  // Maximum speed for each particle.
  final double maxSpeed;
  // Maximum size (radius) for each particle.
  final double maxSize;
  // Maximum distance to draw a line between two particles.
  final double lineDistance;
  // Color of the particles.
  final Color particleColor;
  // Color of the lines connecting particles.
  final Color lineColor;
  // Color of the lines when interacting with touch.
  final Color touchColor;
  // Enable or disable touch interaction.
  final bool touchActivation;

  const ParticleNetwork({
    super.key,
    this.particleCount = 50,
    this.touchActivation = true,
    this.maxSpeed = 0.5,
    this.maxSize = 3.5,
    this.lineDistance = 180,
    this.particleColor = Colors.white,
    this.lineColor = Colors.greenAccent,
    this.touchColor = Colors.amber,
  });

  @override
  State<ParticleNetwork> createState() => _ParticleNetworkState();
}

// State class for ParticleNetwork. Handles animation, particle updates, and touch events.
class _ParticleNetworkState extends State<ParticleNetwork>
    with SingleTickerProviderStateMixin {
  // List of all particles in the network.
  final List<Particle> _particles = [];
  // Random number generator for initial positions and velocities.
  final Random _random = Random();
  // Current touch point, if any.
  Offset _touchPoint = Offset.infinite;
  // Animation ticker for driving the particle updates.
  late final Ticker _ticker;
  // Current size of the widget area.
  Size _currentSize = Size.zero;

  // Using ValueNotifier instead of setState to update rendering only
  final ValueNotifier<int> _frameNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    // Start the animation ticker. Each tick updates the particles and triggers a repaint.
    _ticker = createTicker((elapsed) {
      // Update new frame without calling setState
      _updateParticles();
      _frameNotifier.value = elapsed.inMilliseconds;
    })..start();
  }

  // Update all particles' positions and states for the current frame.
  void _updateParticles() {
    for (final p in _particles) {
      p.update(_currentSize);
    }
  }

  // Generate or regenerate particles when the widget size changes.
  void _generateParticles(Size size) {
    if (size != _currentSize) {
      _currentSize = size;
      _particles.clear();
      if (size.width > 0 && size.height > 0) {
        for (int i = 0; i < widget.particleCount; i++) {
          // Assign random velocity and position to each particle.
          final Offset velocity = Offset(
            (_random.nextDouble() - 0.5) * widget.maxSpeed,
            (_random.nextDouble() - 0.5) * widget.maxSpeed,
          );

          _particles.add(
            Particle(
              color: widget.particleColor,
              position: Offset(
                _random.nextDouble() * size.width,
                _random.nextDouble() * size.height,
              ),
              velocity: velocity,
              size: _random.nextDouble() * widget.maxSize + 1,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    // Dispose of the ticker and notifier to avoid memory leaks.
    _ticker.dispose();
    _frameNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to get the available size and regenerate particles if needed.
    return LayoutBuilder(
      builder: (_, constraints) {
        _generateParticles(constraints.biggest);
        return GestureDetector(
          // Update touch point for interaction.
          onPanDown: (d) => _touchPoint = d.localPosition,
          onPanUpdate: (d) => _touchPoint = d.localPosition,
          onPanEnd: (_) => _touchPoint = Offset.infinite,
          onPanCancel: () => _touchPoint = Offset.infinite,
          child: ValueListenableBuilder<int>(
            valueListenable: _frameNotifier,
            builder: (context, frame, child) {
              // CustomPaint draws the animated particle network.
              return CustomPaint(
                painter: OptimizedNetworkPainter(
                  touchActivation: widget.touchActivation,
                  particles: _particles,
                  touchPoint: _touchPoint,
                  lineDistance: widget.lineDistance,
                  particleColor: widget.particleColor,
                  lineColor: widget.lineColor,
                  touchColor: widget.touchColor,
                ),
                isComplex: true,
                willChange: true,
                child: const SizedBox.expand(),
              );
            },
          ),
        );
      },
    );
  }
}
