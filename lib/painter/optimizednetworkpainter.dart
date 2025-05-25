import 'package:flutter/material.dart';
import 'package:particles_network/model/particlemodel.dart';
import 'package:particles_network/painter/ParticleFilter.dart';
import 'package:particles_network/painter/connection_drawer.dart';
import 'package:particles_network/painter/distance_calculator.dart';
import 'package:particles_network/painter/spatiall_grid_manager.dart';
import 'package:particles_network/painter/touch_interaction_handler.dart';

/// The main painter class for rendering an optimized particle network
///
/// This class implements CustomPainter to efficiently render:
/// - Individual particles as circles
/// - Connection lines between nearby particles
/// - Touch interaction effects
///
/// Optimization Techniques:
/// 1. Spatial partitioning using grid cells
/// 2. Distance calculation caching
/// 3. Visible particle filtering
/// 4. Batched drawing operations
class OptimizedNetworkPainter extends CustomPainter {
  // Configuration properties
  final List<Particle> particles; // All particles in the system
  final Offset? touchPoint; // Current touch position (nullable)
  final double lineDistance; // Max connection distance (in pixels)
  final Color particleColor; // Base color for particles
  final Color lineColor; // Color for connection lines
  final Color touchColor; // Color for touch interactions
  final bool touchActivation; // Whether touch effects are enabled
  final int particleCount; // Total particle count (for pre-allocation)
  final double linewidth; // Width of connection lines
  final bool isComplex; // Debug mode flag

  // Optimized sub-components
  late final DistanceCalculator
  _distanceCalculator; // Manages distance calculations
  late final ConnectionDrawer _connectionDrawer; // Handles connection drawing
  late final TouchInteractionHandler
  _touchHandler; // Manages touch interactions

  // Reusable painting objects
  late final Paint _particlePaint; // Paint config for particles
  late final Paint _linePaint; // Paint config for connections

  /// Constructor with dependency initialization
  OptimizedNetworkPainter({
    required this.particleCount,
    required this.particles,
    required this.touchPoint,
    required this.lineDistance,
    required this.particleColor,
    required this.lineColor,
    required this.touchColor,
    required this.touchActivation,
    required this.linewidth,
    required this.isComplex,
  }) {
    // Initialize particle paint (optimized to do this once)
    _particlePaint =
        Paint()
          ..color = particleColor
          ..style = PaintingStyle.fill;

    // Initialize line paint with stroke configuration
    _linePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = linewidth;

    // Initialize sub-components with dependency injection
    _distanceCalculator = DistanceCalculator(particleCount);
    _connectionDrawer = ConnectionDrawer(
      isComplex: isComplex,
      particles: particles,
      particleCount: particleCount,
      lineDistance: lineDistance,
      lineColor: lineColor,
      linePaint: _linePaint,
      distanceCalculator: _distanceCalculator,
    );
    _touchHandler = TouchInteractionHandler(
      particles: particles,
      touchPoint: touchPoint,
      lineDistance: lineDistance,
      touchColor: touchColor,
      linePaint: _linePaint,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Clear previous frame's distance cache
    _distanceCalculator.clearCache();

    // Step 1: Filter visible particles (viewport culling)
    final visibleParticles = ParticleFilter.getVisibleParticles(particles);

    // Step 2: Create spatial grid for efficient proximity checks
    // Spatial Complexity: O(n) where n = visibleParticles.length
    // Uses a grid with cellSize = lineDistance for optimal neighbor finding
    final grid = SpatialGridManager.createOptimizedSpatialGrid(
      particles,
      visibleParticles,
      lineDistance, // Cell size matches connection distance
    );

    // Step 3: Draw connections between nearby particles
    // Uses the grid to only check adjacent cells (O(1) neighbor access)
    _connectionDrawer.drawConnections(canvas, grid);

    // Step 4: Handle touch interactions if active
    if (touchPoint != null && touchActivation) {
      // Applies physics: F = k/d (inverse distance force)
      _touchHandler.applyTouchPhysics(visibleParticles);
      // Draws touch lines with distance-based opacity: α = 1 - d/d_max
      _touchHandler.drawTouchLines(canvas, visibleParticles);
    }

    // Step 5: Draw all visible particles
    _drawParticles(canvas, visibleParticles);
  }

  /// Draws individual particles as circles
  ///
  /// Optimizations:
  /// - Uses pre-allocated Paint object
  /// - Only draws visible particles
  /// - Simple drawCircle operation (hardware accelerated)
  void _drawParticles(Canvas canvas, List<int> visibleParticles) {
    for (final index in visibleParticles) {
      final p = particles[index];
      canvas.drawCircle(
        p.position,
        p.size, // Particle radius
        _particlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(OptimizedNetworkPainter oldDelegate) {
    // Only repaint when:
    // 1. Touch position changes, or
    // 2. Any particle was accelerated (position changed)
    return oldDelegate.touchPoint != touchPoint ||
        particles.any((p) => p.wasAccelerated);
  }
}
