/// A Flutter package that creates an interactive particle network effect.
/// This library provides a customizable particle system that creates connecting lines
/// between particles and responds to touch input.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:particles_network/model/particlemodel.dart';
import 'package:particles_network/painter/optimizednetworkpainter.dart';

/// OptimizedParticleNetwork is the main widget that creates an interactive particle system.
/// It manages the particle creation, animation, and touch interactions.
class OptimizedParticleNetwork extends StatefulWidget {
  /// The number of particles to create in the system
  final int particleCount;

  /// Maximum speed at which particles can move
  final double maxSpeed;

  /// Maximum size of individual particles
  final double maxSize;

  /// Maximum distance at which particles will create connecting lines
  final double lineDistance;

  /// Color of the particles
  final Color particleColor;

  /// Color of the lines connecting particles
  final Color lineColor;

  /// Color of lines created when touching the system
  final Color touchColor;

  /// bool for Activation touch
  final bool touchActivation;

  /// Creates a new particle network system
  ///
  /// [particleCount] determines how many particles to create (default: 50)
  /// [maxSpeed] sets the maximum velocity of particles (default: 0.5)
  /// [maxSize] sets the maximum particle size (default: 3.5)
  /// [lineDistance] sets the maximum distance for particle connections (default: 180)
  /// [particleColor] sets the color of particles (default: white)
  /// [lineColor] sets the color of connecting lines (default: teal)
  /// [touchColor] sets the color of touch interaction lines (default: amber)
  const OptimizedParticleNetwork({
    super.key,
    this.particleCount = 50,
    this.maxSpeed = 0.5,
    this.maxSize = 3.5,
    this.lineDistance = 100,
    this.particleColor = Colors.white,
    this.lineColor = Colors.teal,
    this.touchColor = Colors.amber,
    this.touchActivation = true,
  });

  @override
  State<OptimizedParticleNetwork> createState() =>
      _OptimizedParticleNetworkState();
}

/// The state class for OptimizedParticleNetwork that handles the animation
/// and particle system logic
class _OptimizedParticleNetworkState extends State<OptimizedParticleNetwork>
    with SingleTickerProviderStateMixin {
  /// List of all particles in the system
  final List<Particle> _particles = [];

  /// Random number generator for particle properties
  final Random _random = Random();

  /// Current touch point location
  Offset? _touchPoint;

  /// Ticker for animations
  late final Ticker _ticker;

  /// Current size of the widget
  Size _currentSize = Size.zero;

  /// Notifier for frame updates to trigger repaints efficiently
  final ValueNotifier<int> _frameNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    // Create a ticker for smooth animation
    _ticker = createTicker((elapsed) {
      _updateParticles();
      _frameNotifier.value = elapsed.inMilliseconds;
    })..start();
  }

  /// Updates the position of all particles in the system
  void _updateParticles() {
    for (final p in _particles) {
      p.update(_currentSize);
    }
  }

  /// Generates particles when the widget size changes
  /// This ensures particles are properly distributed in the available space
  void _generateParticles(Size size) {
    if (size != _currentSize) {
      _currentSize = size;
      _particles.clear();
      if (size.width > 0 && size.height > 0) {
        for (int i = 0; i < widget.particleCount; i++) {
          // Create random velocity vector
          final velocity = Offset(
            (_random.nextDouble() - 0.5) * widget.maxSpeed,
            (_random.nextDouble() - 0.5) * widget.maxSpeed,
          );

          // Create new particle with random position
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
    _ticker.dispose();
    _frameNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        _generateParticles(constraints.biggest);
        return GestureDetector(
          // trackpadScrollCausesScale: true,
          // Handle touch interactions
          onPanDown: (d) => _touchPoint = d.localPosition,
          onPanUpdate: (d) => _touchPoint = d.localPosition,
          onPanEnd: (_) => _touchPoint = null,
          onPanCancel: () => _touchPoint = null,
          child: ValueListenableBuilder<int>(
            valueListenable: _frameNotifier,
            builder: (context, frame, child) {
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
