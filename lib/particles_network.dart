// Importing core Dart math library for random number generation
import 'dart:math';

// Importing Flutter material design library for UI components
import 'package:flutter/material.dart';
// Importing scheduler for animation tickers (frame callbacks)
import 'package:flutter/scheduler.dart';
import 'package:particles_network/model/ip_article.dart';
import 'package:particles_network/model/particlemodel.dart';
import 'package:particles_network/painter/optimized_network_painter.dart';

// Importing default particle factory implementation
import 'model/default_particle_factory.dart';

/// A Flutter widget that renders an interactive particle network visualization.
///
/// This widget creates a dynamic system of particles that:
/// - Move continuously within the widget bounds using basic physics
/// - Connect visually when within a specified distance (Euclidean distance)
/// - Respond to touch interactions when enabled (distance-based highlighting)
/// - Can be customized through various parameters
///
/// Mathematical Concepts Used:
/// - 2D vector math for particle movement (position + velocity)
/// - Euclidean distance calculation for connection detection
/// - Random number generation for initial placement and movement
/// - Basic collision detection with boundaries
///
/// Performance Features:
/// - Spatial partitioning for efficient neighbor detection (O(n) → O(n log n))
/// - Cached distance calculations to minimize recomputation
/// - Batched painting operations to reduce GPU calls
/// - Configurable repaint strategies based on complexity
class ParticleNetwork extends StatefulWidget {
  // Configuration properties with default values:

  /// Total number of particles in the visualization [default: 60]
  /// Affects performance: O(n) for updates, O(n²) for connection checks
  final int particleCount;

  /// Maximum speed of particles in pixels per frame [default: 0.5]
  /// Determines how fast particles move (velocity magnitude)
  final double maxSpeed;

  /// Maximum radius of particles in pixels [default: 1.5]
  /// Used for rendering particle size
  final double maxSize;

  /// Stroke width of connection lines in pixels [default: 0.5]
  final double lineWidth;

  /// Maximum connection distance between particles in pixels [default: 100]
  /// Threshold for drawing connecting lines (Euclidean distance)
  final double lineDistance;

  /// Base color of all particles [default: Colors.white]
  final Color particleColor;

  /// Color of connection lines between particles [default: Color.fromARGB(255, 100, 255, 180)]
  /// Lines are drawn with opacity based on distance (inverse linear interpolation)
  final Color lineColor;

  /// Highlight color for touch interactions [default: Colors.amber]
  /// Particles near touch point get this color (distance-based)
  final Color touchColor;

  /// Whether touch interactions are enabled [default: true]
  /// Adds gesture detection and touch response logic
  final bool touchActivation;

  /// Whether the painting logic is complex (affects repaint strategy) [default: false]
  /// If true, Flutter may optimize repainting differently
  final bool isComplex;

  /// Whether to fill particles (true) or stroke them (false) [default: true]
  final bool fill;

  /// Whether to draw connecting lines between particles [default: true]
  final bool drawNetwork;

  /// Creates a ParticleNetwork widget with customizable parameters
  const ParticleNetwork({
    super.key,
    this.particleCount = 60,
    this.maxSpeed = 0.5,
    this.maxSize = 1.5,
    this.lineWidth = 0.5,
    this.lineDistance = 100,
    this.particleColor = Colors.white,
    this.lineColor = const Color.fromARGB(255, 100, 255, 180),
    this.touchColor = Colors.amber,
    this.touchActivation = true,
    this.isComplex = false,
    this.fill = true,
    this.drawNetwork = true,
  });

  @override
  State<ParticleNetwork> createState() => ParticleNetworkState();
}

/// The stateful logic and animation controller for the ParticleNetwork widget
/// Handles:
/// - Particle system initialization
/// - Animation loop management
/// - Touch interaction handling
/// - Dynamic resizing
class ParticleNetworkState extends State<ParticleNetwork>
    with SingleTickerProviderStateMixin {
  // Core data structures:
  final List<Particle> particles = []; // All particles in the system
  late final Ticker ticker; // Animation driver (calls callback each frame)
  Offset touchPoint =
      Offset.infinite; // Current touch location (or infinite if no touch)
  Size currentSize = Size.zero; // Current widget dimensions
  final ValueNotifier<int> frameNotifier = ValueNotifier<int>(
    0,
  ); // Repaint trigger

  // Injected or default implementations:
  late final IParticleFactory
  factory; // Creates particles with random properties
  late final IParticleController
  controller; // Updates particle positions each frame

  @override
  void initState() {
    super.initState();

    // Initialize with custom or default implementations
    factory = DefaultParticleFactory(
      random: Random(), // Random number generator for initial properties
      maxSpeed: widget.maxSpeed, // Maximum velocity magnitude
      maxSize: widget.maxSize, // Maximum particle radius
      color: widget.particleColor, // Base particle color
    );

    controller = ParticleUpdater(); // Handles particle movement logic

    // Animation loop (runs at ~60fps when visible)
    ticker = createTicker((elapsed) {
      // Update all particle positions based on their velocity
      controller.updateParticles(particles, currentSize);

      // Trigger repaint by updating the frame counter
      // Using a simple increment is sufficient and avoids large numbers
      frameNotifier.value++;
    })..start(); // Start the animation loop immediately
  }

  /// Generates or regenerates particles when size changes
  /// Uses the factory to create particles with:
  /// - Random positions within bounds (uniform distribution)
  /// - Random velocities (direction and magnitude)
  /// - Random sizes (within maxSize)
  void _generateParticles(Size size) {
    if (size != currentSize) {
      currentSize = size;
      particles.clear();

      // Only generate particles if we have valid dimensions
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
    // Clean up resources to prevent memory leaks
    ticker.dispose(); // Stop the animation loop
    frameNotifier.dispose(); // Dispose the value notifier
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Regenerate particles if size changed
        // This ensures particles stay within bounds when widget resizes
        _generateParticles(constraints.biggest);

        return GestureDetector(
          // Touch interaction handling
          onPanDown: (d) => touchPoint = d.localPosition, // Touch started
          onPanUpdate: (d) => touchPoint = d.localPosition, // Touch moved
          onPanEnd: (_) => touchPoint = Offset.infinite, // Touch ended
          onPanCancel: () => touchPoint = Offset.infinite, // Touch cancelled

          child: ValueListenableBuilder<int>(
            valueListenable: frameNotifier,
            // Rebuild only the CustomPaint when frameNotifier changes
            builder: (_, _, _) => CustomPaint(
              painter: OptimizedNetworkPainter(
                // Configuration passed to the painter:
                drawNetwork: widget.drawNetwork, // Whether to draw connections
                fill: widget.fill, // Fill vs stroke particles
                isComplex: widget.isComplex, // Painting complexity hint
                lineWidth: widget.lineWidth, // Connection line thickness
                particleCount: widget.particleCount,
                touchActivation: widget.touchActivation, // Touch interaction
                particles: particles, // The particle data
                touchPoint: touchPoint, // Current touch position
                lineDistance: widget.lineDistance, // Max connection distance
                particleColor: widget.particleColor,
                lineColor: widget.lineColor,
                touchColor: widget.touchColor,
              ),
              // Performance optimization flags:
              isComplex:
                  true, // Hint that painting is computationally intensive
              willChange: true, // Widget will change frequently (animation)
              child: const SizedBox.expand(), // Fill available space
            ),
          ),
        );
      },
    );
  }
}
