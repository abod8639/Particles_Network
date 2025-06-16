import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:particles_network/model/connection_candidate.dart';
import 'package:particles_network/model/particlemodel.dart';
import 'package:particles_network/model/rectangle.dart';
import 'package:particles_network/painter/distance_calculator.dart';
import 'package:particles_network/painter/particle_filter.dart';
import 'package:particles_network/painter/touch_interaction_handler.dart';
import 'package:particles_network/quad_tree/compressed_quad_tree.dart';
import 'package:particles_network/quad_tree/compressed_quad_tree_node.dart';

/// The main painter class for rendering an optimized particle network
///
/// This class implements CustomPainter to efficiently render:
/// - Individual particles as circles
/// - Connection lines between nearby particles
/// - Touch interaction effects
///
/// Optimization Techniques:
/// 1. Spatial partitioning using QuadTree
/// 2. Distance calculation caching
/// 3. Visible particle filtering
/// 4. Batched drawing operations
/// 5. Conditional rendering based on visibility
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
  // final BuildContext context; // Build context for media queries
  final bool fill; // Whether to fill particles or stroke them
  final bool drawnetwork; // Whether to draw connection lines
  final bool showQuadTree; // Whether to visualize QuadTree structure

  // Optimized sub-components
  late final DistanceCalculator _distanceCalculator;
  late final TouchInteractionHandler _touchHandler;
  late final CompressedQuadTree _quadTree; // Changed to CompressedQuadTree

  // Reusable painting objects (initialized once for performance)
  late final Paint particlePaint; // Paint config for particles
  late final Paint linePaint; // Paint config for connections

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
    // required this.context,
    required this.fill,
    required this.drawnetwork,
    this.showQuadTree = false, // Default to false
  }) {
    // Get viewport dimensions for QuadTree initialization
    // final mw = MediaQuery.of(context).size.width + 10;
    // final mh = double.infinity ;

    // final s = Size(width, height)

    // Initialize QuadTree with viewport bounds
    _quadTree = CompressedQuadTree(
      Rectangle(-5, -5, double.maxFinite, double.maxFinite),
    );
    // Initialize particle paint
    particlePaint = Paint()
      ..style = fill ? PaintingStyle.fill : PaintingStyle.stroke
      ..color = particleColor;

    // Initialize line paint with stroke configuration
    linePaint = Paint()
      ..style = fill ? PaintingStyle.stroke : PaintingStyle.fill
      ..strokeWidth = linewidth
      ..color = lineColor; // Added line color

    // Initialize sub-components with dependency injection
    _distanceCalculator = DistanceCalculator(particleCount);
    _touchHandler = TouchInteractionHandler(
      particles: particles,
      touchPoint: touchPoint,
      lineDistance: lineDistance,
      touchColor: touchColor,
      linePaint: linePaint,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    _distanceCalculator.clearCache();

    final List<int> visibleParticles = ParticleFilter.getVisibleParticles(
      particles,
    );

    _quadTree.clear();
    if (drawnetwork) {
      for (int i = 0; i < visibleParticles.length; i++) {
        final particle = particles[visibleParticles[i]];
        _quadTree.insert(
          QuadTreeParticle(
            visibleParticles[i],
            particle.position.dx,
            particle.position.dy,
          ),
        );
      }
    }

    if (drawnetwork) {
      _drawConnections(canvas, visibleParticles);
    }

    if (touchPoint != null && touchActivation) {
      _touchHandler.drawTouchLines(canvas, visibleParticles);
      _touchHandler.applyTouchPhysics(visibleParticles);
      _drawParticles(canvas, visibleParticles);
    }

    // Optional: Draw QuadTree visualization for debugging
    //   if (showQuadTree) {
    //     final quadTreePainter = QuadTreePainter(_quadTree);
    //     quadTreePainter.paint(canvas, size);
    //   }
  }

  /// Draws individual particles as circles
  ///
  /// Optimizations:
  /// - Uses pre-allocated Paint object (avoids object creation each frame)
  /// - Only draws visible particles (reduced draw calls)
  /// - Simple drawCircle operation (hardware accelerated)
  void _drawParticles(Canvas canvas, List<int> visibleParticles) {
    for (final index in visibleParticles) {
      final Particle p = particles[index];
      canvas.drawCircle(
        p.position, // Center point
        p.size, // Particle radius
        particlePaint, // Pre-configured paint
      );
    }
  }

  /// Draw connections between nearby particles using QuadTree
  ///
  /// Algorithm:
  /// 1. For each particle, query nearby particles using QuadTree
  /// 2. Calculate distance to each nearby particle
  /// 3. Draw line if within max distance, with opacity based on distance
  ///
  /// Optimizations:
  /// - Uses QuadTree for O(log n) proximity queries instead of O(n²)
  /// - Distance calculation caching
  /// - Skips duplicate connections (i < j)
  /// - Distance-based opacity creates visual depth
  void _drawConnections(Canvas canvas, List<int> visibleParticles) {
    int maxLinesPerDenseParticle = isComplex ? 4 : 5; //
    int denseThreshold = isComplex ? lineDistance ~/ 3 : lineDistance ~/ 1; //

    for (final int index in visibleParticles) {
      final Particle particle = particles[index];

      final List<int> nearbyParticles = _quadTree.findNearbyParticles(
        particle.position.dx,
        particle.position.dy,
        lineDistance,
      );

      final List<int> filteredNearby = nearbyParticles
          .where((i) => i > index)
          .toList();

      final List<ConnectionCandidate> connections = filteredNearby
          .map(
            (i) => ConnectionCandidate(
              index: i,
              distance: _calculateDistance(
                particle.position,
                particles[i].position,
              ),
            ),
          )
          .where((c) => c.distance <= lineDistance)
          .toList();

      if (connections.length > denseThreshold) {
        connections.sort((a, b) => a.distance.compareTo(b.distance));
        connections.removeRange(maxLinesPerDenseParticle, connections.length);
      }

      for (final connection in connections) {
        final Particle nearbyParticle = particles[connection.index];
        final int opacity = ((1 - connection.distance / lineDistance) * 255)
            .toInt();
        linePaint.color = lineColor.withAlpha(opacity.clamp(0, 255));
        canvas.drawLine(particle.position, nearbyParticle.position, linePaint);
      }
    }
  }

  /// Calculate distance between two points with caching
  double _calculateDistance(Offset p1, Offset p2) {
    // Use Euclidean distance
    final double dx = p1.dx - p2.dx;
    final double dy = p1.dy - p2.dy;
    return math.sqrt(dx * dx + dy * dy);
  }

  @override
  bool shouldRepaint(OptimizedNetworkPainter oldDelegate) {
    return oldDelegate.touchPoint != touchPoint ||
        particles.any((p) => p.wasAccelerated) ||
        oldDelegate.lineDistance != lineDistance ||
        oldDelegate.particleColor != particleColor ||
        oldDelegate.lineColor != lineColor;
  }
}
