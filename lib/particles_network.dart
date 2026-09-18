/// Main entry point for the particles_network package.
///
/// This library provides the [ParticleNetwork] widget, which is the primary
/// way to use the particle animation in a Flutter application.
library;

import 'dart:math';

// Importing Flutter material design library for UI components
import 'package:flutter/material.dart';
// Importing scheduler for animation tickers (frame callbacks)
import 'package:flutter/scheduler.dart';
import 'package:particles_network/model/ip_article.dart';
import 'package:particles_network/model/particlemodel.dart';
import 'package:particles_network/painter/object_pool.dart';
import 'package:particles_network/painter/optimized_network_painter.dart';

export 'package:particles_network/model/ip_article.dart'
    show GravityType, GravityConfig;
export 'package:particles_network/model/particlemodel.dart' show Particle;
export 'package:particles_network/model/trajectory_buffer.dart'
    show TrajectoryBuffer;

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
  /// Total number of particles in the visualization [default: 60].
  /// Affects performance: O(n) for updates, O(n²) for connection checks.
  final int particleCount;

  /// Maximum speed of particles in pixels per frame [default: 0.5].
  /// Determines how fast particles move (velocity magnitude).
  final double maxSpeed;

  /// Maximum radius of particles in pixels [default: 1.5].
  /// Used for rendering particle size.
  final double maxSize;

  /// Stroke width of connection lines in pixels [default: 0.5].
  final double lineWidth;

  /// Maximum connection distance between particles in pixels [default: 100].
  /// Threshold for drawing connecting lines (Euclidean distance).
  final double lineDistance;

  /// Base color of all particles [default: Colors.white].
  final Color particleColor;

  /// Color of connection lines between particles [default: Color.fromARGB(255, 100, 255, 180)].
  /// Lines are drawn with opacity based on distance (inverse linear interpolation).
  final Color lineColor;

  /// Highlight color for touch interactions [default: Colors.amber].
  /// Particles near touch point get this color (distance-based).
  final Color touchColor;

  /// Whether touch interactions are enabled [default: true].
  /// Adds gesture detection and touch response logic.
  final bool touchActivation;

  /// Whether the painting logic is complex (affects repaint strategy) [default: false].
  /// If true, Flutter may optimize repainting differently.
  final bool isComplex;

  /// Whether to fill particles (true) or stroke them (false) [default: true].
  final bool fill;

  /// Whether to draw connecting lines between particles [default: true].
  final bool drawNetwork;

  /// The type of gravity effect to apply [default: GravityType.none].
  final GravityType gravityType;

  /// The strength of the applied gravity force [default: 0.1].
  final double gravityStrength;

  /// The direction vector for global gravity [default: Offset(0, 1) - downwards].
  final Offset gravityDirection;

  /// The center point for point-based gravity effects.
  /// Defaults to the widget's center if null.
  final Offset? gravityCenter;

  /// Whether hover effects are enabled.
  /// If true, particles will follow the mouse cursor when hovered.
  /// If false, particles will not follow the mouse cursor when hovered.
  /// If null, hover effects will be enabled by default.
  final bool? hoverEffect;

  /// Creates a [ParticleNetwork] widget with customizable visualization parameters.
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
    this.gravityType = GravityType.none,
    this.gravityStrength = 0.1,
    this.gravityDirection = const Offset(0, 1),
    this.gravityCenter,
    this.hoverEffect = false,
  });

  @override
  State<ParticleNetwork> createState() => ParticleNetworkState();
}

// The stateful logic and animation controller for the ParticleNetwork widget
// Handles:
// - Particle system initialization
// - Animation loop management
// - Touch interaction handling
// - Dynamic resizing
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
  late IParticleFactory factory; // Creates particles with random properties
  late final IParticleController
      controller; // Updates particle positions each frame
  late OptimizedNetworkPainter _painter; // Single painter instance

  // Cached gravity configuration to avoid per-frame allocations
  GravityConfig _gravityConfig = const GravityConfig();

  void _initPainter() {
    _painter = OptimizedNetworkPainter(
      drawNetwork: widget.drawNetwork,
      fill: widget.fill,
      isComplex: widget.isComplex,
      lineWidth: widget.lineWidth,
      particleCount: widget.particleCount,
      touchActivation: widget.touchActivation,
      particles: particles,
      touchPoint: touchPoint,
      lineDistance: widget.lineDistance,
      particleColor: widget.particleColor,
      lineColor: widget.lineColor,
      touchColor: widget.touchColor,
      repaint: frameNotifier,
    );
  }

  void _updateTouchPoint(Offset point) {
    touchPoint = point;
    _painter.updateTouchPoint(point);
  }

  void _updateGravityConfig() {
    _gravityConfig = GravityConfig(
      type: widget.gravityType,
      strength: widget.gravityStrength,
      direction: widget.gravityDirection,
      center: widget.gravityCenter ??
          Offset(currentSize.width / 2, currentSize.height / 2),
    );
  }

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
    _updateGravityConfig();
    _initPainter();

    // Animation loop (runs at ~60fps when visible)
    ticker = createTicker((elapsed) {
      // Update all particle positions smoothly each frame (zero allocations, ~0.05ms)
      controller.updateParticles(
        particles,
        currentSize,
        gravity: _gravityConfig,
      );

      // Trigger repaint by updating the frame counter
      frameNotifier.value = elapsed.inMicroseconds;
    })
      ..start(); // Start the animation loop immediately
  }

  @override
  void didUpdateWidget(ParticleNetwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool factoryChanged = false;
    if (widget.maxSpeed != oldWidget.maxSpeed ||
        widget.maxSize != oldWidget.maxSize ||
        widget.particleColor != oldWidget.particleColor) {
      factory = DefaultParticleFactory(
        random: Random(),
        maxSpeed: widget.maxSpeed,
        maxSize: widget.maxSize,
        color: widget.particleColor,
      );
      factoryChanged = true;
    }

    if (widget.particleCount != oldWidget.particleCount || factoryChanged) {
      if (currentSize.width > 0 && currentSize.height > 0) {
        if (particles.length < widget.particleCount) {
          final int toAdd = widget.particleCount - particles.length;
          for (int i = 0; i < toAdd; i++) {
            particles.add(factory.createParticle(currentSize));
          }
        } else if (particles.length > widget.particleCount) {
          particles.removeRange(widget.particleCount, particles.length);
        }
      }
    }

    if (widget.gravityType != oldWidget.gravityType ||
        widget.gravityStrength != oldWidget.gravityStrength ||
        widget.gravityDirection != oldWidget.gravityDirection ||
        widget.gravityCenter != oldWidget.gravityCenter) {
      _updateGravityConfig();
    }

    if (widget.drawNetwork != oldWidget.drawNetwork ||
        widget.fill != oldWidget.fill ||
        widget.isComplex != oldWidget.isComplex ||
        widget.lineWidth != oldWidget.lineWidth ||
        widget.particleCount != oldWidget.particleCount ||
        widget.touchActivation != oldWidget.touchActivation ||
        widget.lineDistance != oldWidget.lineDistance ||
        widget.particleColor != oldWidget.particleColor ||
        widget.lineColor != oldWidget.lineColor ||
        widget.touchColor != oldWidget.touchColor) {
      _initPainter();
    }
  }

  // Generates or regenerates particles when size changes
  // Uses the factory to create particles with:
  // - Random positions within bounds (uniform distribution)
  // - Random velocities (direction and magnitude)
  // - Random sizes (within maxSize)
  void _generateParticles(Size size) {
    if (size != currentSize) {
      currentSize = size;
      _updateGravityConfig();
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
    PoolManager.getInstance().clearAll(); // Free static pools memory
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hover = widget.hoverEffect ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Regenerate particles if size changed
        // This ensures particles stay within bounds when widget resizes
        _generateParticles(constraints.biggest);

        return MouseRegion(
          // Mouse hover (desktop and web): particles follow the cursor
          // without requiring a click. On touch platforms MouseRegion is
          // a no-op, so existing touch and drag behavior is preserved.
          onHover: hover ? (event) => _updateTouchPoint(event.localPosition) : null,
          onExit: hover ? (_) => _updateTouchPoint(Offset.infinite) : null,

          child: GestureDetector(
            // Touch interaction handling
            onPanDown: (d) => _updateTouchPoint(d.localPosition), // Touch started
            onPanUpdate: (d) => _updateTouchPoint(d.localPosition), // Touch moved
            onPanEnd: (_) => _updateTouchPoint(Offset.infinite), // Touch ended
            onPanCancel: () => _updateTouchPoint(Offset.infinite), // Touch cancelled

            child: CustomPaint(
              painter: _painter,
              isComplex: widget.isComplex,
              willChange: true, // Widget will change frequently (animation)
              child: const SizedBox.expand(), // Fill available space
            ),
          ),
        );
      },
    );
  }
}
