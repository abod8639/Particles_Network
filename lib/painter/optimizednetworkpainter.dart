import 'package:flutter/material.dart';
import 'package:particles_network/model/particlemodel.dart';
import 'package:particles_network/painter/ConnectionDrawer.dart';
import 'package:particles_network/painter/DistanceCalculator.dart';
import 'package:particles_network/painter/ParticleFilter.dart';
import 'package:particles_network/painter/SpatialGridManager.dart';
import 'package:particles_network/painter/TouchInteractionHandler.dart';

/// The core painter class that renders an optimized particle network visualization.
/// 
/// This class implements CustomPainter to efficiently render:
/// 1. Individual particles as circles
/// 2. Dynamic connections between nearby particles
/// 3. Interactive touch effects
///
/// Performance Optimizations:
/// - Spatial partitioning grid (O(1) neighbor lookup)
/// - Cached distance calculations
/// - Batched drawing operations
/// - Selective repainting
class OptimizedNetworkPainter extends CustomPainter {
  // Configuration properties
  final List<Particle> particles;          // All particles in the system
  final Offset? touchPoint;                // Current touch position (nullable)
  final double lineDistance;               // Max connection distance in pixels
  final Color particleColor;               // Base particle color
  final Color lineColor;                   // Connection line color
  final Color touchColor;                  // Touch interaction color
  final bool touchActivation;              // Whether touch is enabled
  final int particleCount;                 // Total particle count
  final double linewidth;                  // Connection line width

  // Optimized sub-components
  late final DistanceCalculator _distanceCalculator;  // Manages distance math
  late final ConnectionDrawer _connectionDrawer;      // Handles line drawing
  late final TouchInteractionHandler _touchHandler;   // Manages touch effects

  // Reusable painting objects
  late final Paint _particlePaint;         // Configured once for all particles
  late final Paint _linePaint;             // Configured once for all lines

  /// Creates a new particle network painter
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
  }) {
    // Initialize particle paint (optimized to do this once)
    _particlePaint = Paint()
      ..color = particleColor
      ..style = PaintingStyle.fill;

    // Initialize line paint with stroke configuration
    _linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = linewidth;

    // Initialize sub-components with dependency injection
    _distanceCalculator = DistanceCalculator(particleCount);
    _connectionDrawer = ConnectionDrawer(
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

    // Step 1: Filter visible particles (O(n) operation)
    final visibleParticles = ParticleFilter.getVisibleParticles(particles);

    // Step 2: Create spatial grid for efficient proximity checks (O(n))
    // Grid cell size = lineDistance ensures we only need to check adjacent cells
    final grid = SpatialGridManager.createOptimizedSpatialGrid(
      particles,
      visibleParticles,
      lineDistance, // Cell size matches connection distance
    );

    // Step 3: Draw connections between nearby particles (O(m) where m = connections)
    // Uses the grid to only check adjacent cells
    _connectionDrawer.drawConnections(canvas, grid);

    // Step 4: Handle touch interactions if active (O(k) where k = nearby particles)
    if (touchPoint != null && touchActivation) {
      // Physics formula: F = k/d (inverse distance force)
      _touchHandler.applyTouchPhysics(visibleParticles);
      
      // Line opacity formula: α = 255 * (1 - d/d_max)
      _touchHandler.drawTouchLines(canvas, visibleParticles);
    }

    // Step 5: Draw all visible particles (O(v) where v = visible particles)
    _drawParticles(canvas, visibleParticles);
  }

  /// Draws individual particles as circles
  /// 
  /// Uses pre-allocated Paint object for efficiency
  /// Only draws visible particles to save rendering time
  void _drawParticles(Canvas canvas, List<int> visibleParticles) {
    for (final index in visibleParticles) {
      final p = particles[index];
      // Circle equation: (x-x₀)² + (y-y₀)² = r²
      canvas.drawCircle(p.position, p.size, _particlePaint);
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