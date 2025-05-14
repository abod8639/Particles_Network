// Importing core Dart math library for random number generation
import 'dart:math';

// Importing Flutter material design library
import 'package:flutter/material.dart';
// Importing scheduler for animation tickers
import 'package:flutter/scheduler.dart';
// Importing particle interface
import 'package:particles_network/model/IParticle.dart';
// Importing particle model
import 'package:particles_network/model/particlemodel.dart';
// Importing custom painter for optimized network rendering
import 'package:particles_network/painter/optimizednetworkpainter.dart';

// Importing default particle factory implementation
import 'model/DefaultParticleFactory.dart';

/// A Flutter widget that renders an interactive particle network visualization.
///
/// This widget creates a dynamic system of particles that:
/// - Move continuously within the widget bounds
/// - Connect visually when within a specified distance
/// - Respond to touch interactions when enabled
/// - Can be customized through various parameters
///
/// Performance Features:
/// - Spatial partitioning for efficient neighbor detection
/// - Cached distance calculations
/// - Batched painting operations
/// - Configurable repaint strategies
class ParticleNetwork extends StatefulWidget {
  // Configuration properties with default values:

  /// Total number of particles in the visualization [default: 50]
  final int particleCount;

  /// Maximum speed of particles in pixels per frame [default: 0.5]
  final double maxSpeed;

  /// Maximum radius of particles in pixels [default: 3.5]
  final double maxSize;

  /// Maximum connection distance between particles in pixels [default: 180]
  final double lineDistance;

  /// Base color of all particles [default: Colors.white]
  final Color particleColor;

  /// Color of connection lines between particles [default: Color(0xFF64FFB4)]
  final Color lineColor;

  /// Highlight color for touch interactions [default: Colors.amber]
  final Color touchColor;

  /// Whether touch interactions are enabled [default: true]
  final bool touchActivation;

  /// Stroke width of connection lines in pixels [default: 0.5]
  final double linewidth;

  // Dependency injection points:

  /// Custom particle factory (optional)
  /// If null, uses DefaultParticleFactory
  final IParticleFactory? particleFactory;

  /// Custom particle behavior controller (optional)
  /// If null, uses ParticleUpdater
  final IParticleController? particleController;

  /// Creates a ParticleNetwork widget with customizable parameters
  const ParticleNetwork({
    super.key,
    this.particleCount = 50,
    this.touchActivation = true,
    this.maxSpeed = 0.5,
    this.maxSize = 3.5,
    this.lineDistance = 180,
    this.particleColor = Colors.white,
    this.lineColor = const Color.fromARGB(255, 100, 255, 180),
    this.touchColor = Colors.amber,
    this.particleFactory,
    this.particleController,
    this.linewidth = 0.5,
  });

  @override
  State<ParticleNetwork> createState() => ParticleNetworkState();
}

/// The stateful logic and animation controller for the ParticleNetwork widget
class ParticleNetworkState extends State<ParticleNetwork>
    with SingleTickerProviderStateMixin {
  // Core data structures:
  final List<Particle> particles = []; // All particles in the system
  late final Ticker ticker; // Animation driver
  Offset touchPoint = Offset.infinite; // Current touch location
  Size currentSize = Size.zero; // Current widget dimensions
  final ValueNotifier<int> frameNotifier = ValueNotifier<int>(
    0,
  ); // Repaint trigger

  // Injected or default implementations:
  late final IParticleFactory factory;
  late final IParticleController controller;

  @override
  void initState() {
    super.initState();

    // Initialize with custom or default implementations
    factory =
        widget.particleFactory ??
        DefaultParticleFactory(
          random: Random(),
          maxSpeed: widget.maxSpeed,
          maxSize: widget.maxSize,
          color: widget.particleColor,
        );

    controller = widget.particleController ?? ParticleUpdater();

    // Animation loop (runs at ~60fps when visible)
    ticker = createTicker((elapsed) {
      controller.updateParticles(particles, currentSize);
      frameNotifier.value = elapsed.inMilliseconds; // Trigger repaint
    })..start();
  }

  /// Generates or regenerates particles when size changes
  void _generateParticles(Size size) {
    if (size != currentSize) {
      currentSize = size;
      particles.clear();

      if (size.width > 0 && size.height > 0) {
        // Create particles with random positions within bounds
        for (int i = 0; i < widget.particleCount; i++) {
          particles.add(factory.createParticle(size));
        }
      }
    }
  }

  @override
  void dispose() {
    // Clean up resources
    ticker.dispose();
    frameNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        // Regenerate particles if size changed
        _generateParticles(constraints.biggest);

        return GestureDetector(
          // Touch interaction handling
          onPanDown: (d) => touchPoint = d.localPosition,
          onPanUpdate: (d) => touchPoint = d.localPosition,
          onPanEnd: (_) => touchPoint = Offset.infinite,
          onPanCancel: () => touchPoint = Offset.infinite,

          child: ValueListenableBuilder<int>(
            valueListenable: frameNotifier,
            builder:
                (_, __, ___) => CustomPaint(
                  painter: OptimizedNetworkPainter(
                    linewidth: widget.linewidth,
                    particleCount: widget.particleCount,
                    touchActivation: widget.touchActivation,
                    particles: particles,
                    touchPoint: touchPoint,
                    lineDistance: widget.lineDistance,
                    particleColor: widget.particleColor,
                    lineColor: widget.lineColor,
                    touchColor: widget.touchColor,
                  ),
                  // Performance optimization flags
                  isComplex: true, // Complex painting logic
                  willChange: true, // Frequent repaints expected
                  child: const SizedBox.expand(),
                ),
          ),
        );
      },
    );
  }
}
