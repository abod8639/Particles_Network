import 'dart:ui' as ui;
import 'package:flutter/material.dart';
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
  final double lineWidth; // Width of connection lines
  final bool isComplex; // Debug mode flag
  final bool fill; // Whether to fill particles or stroke them
  final bool drawNetwork; // Whether to draw connection lines
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
    required this.lineWidth,
    required this.isComplex,
    required this.fill,
    required this.drawNetwork,
    this.showQuadTree = false, // Default to false
  }) {
    // Get viewport dimensions for QuadTree initialization
    // final mw = MediaQuery.of(context).size.width + 10;
    // final mh = double.infinity ;

    // final s = Size(width, height)

    // Initialize QuadTree with viewport bounds
    _quadTree = CompressedQuadTree(
      Rectangle(
        -5,
        -5,
        double.maxFinite,
        double.maxFinite,
      ), // Placeholder, will be updated in paint
    );
    // Initialize particle paint with anti-aliasing for smooth rendering
    particlePaint = Paint()
      ..style = fill ? PaintingStyle.fill : PaintingStyle.stroke
      ..color = particleColor
      ..isAntiAlias = true;

    // Initialize line paint with stroke configuration and smooth rendering
    linePaint = Paint()
      ..style = fill ? PaintingStyle.stroke : PaintingStyle.fill
      ..strokeWidth = lineWidth
      ..color = lineColor
      ..isAntiAlias = true // Enable anti-aliasing for smoother lines
      ..strokeCap = StrokeCap.round // Round line endings for smoother appearance
      ..strokeJoin = StrokeJoin.round; // Smooth line joints

    // Initialize sub-components with dependency injection
    _distanceCalculator = DistanceCalculator();
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
    _distanceCalculator.reset();

    final List<int> visibleParticles = ParticleFilter.getVisibleParticles(
      particles,
    );

    _quadTree.clear();
    if (drawNetwork) {
      for (int i = 0; i < visibleParticles.length; i++) {
        final Particle particle = particles[visibleParticles[i]];
        _quadTree.insert(
          QuadTreeParticle(
            visibleParticles[i],
            particle.position.dx,
            particle.position.dy,
          ),
        );
      }
    }

    if (drawNetwork) {
      _drawConnections(canvas, visibleParticles);
    }

    if (touchPoint != null && touchActivation) {
      _touchHandler.handleTouchInteraction(canvas, visibleParticles);
    }

    // Always draw particles at the end
    _drawParticles(canvas, visibleParticles);
  }

  /// Draws individual particles as circles
  void _drawParticles(Canvas canvas, List<int> visibleParticles) {
    for (final int index in visibleParticles) {
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
  /// Optimizations:
  /// - Batched rendering using opacity buckets (10 draw calls max)
  /// - QuadTree spatial queries for O(log n) proximity detection
  /// - Distance caching to avoid redundant calculations
  /// - Smart connection limiting in dense particle areas
  void _drawConnections(Canvas canvas, List<int> visibleParticles) {
    // Configuration for connection limiting in dense areas
    final int maxConnectionsPerParticle = isComplex ? 4 : 5;
    final double densityThreshold = lineDistance / 3;
    
    // Opacity buckets for batched rendering (0-9 = 10 levels)
    // Each bucket contains pairs of points: [start1, end1, start2, end2, ...]
    final List<List<Offset>> opacityBuckets = List.generate(10, (_) => []);

    // Process each visible particle
    for (final int particleIndex in visibleParticles) {
      final Particle particle = particles[particleIndex];
      final double particleX = particle.position.dx;
      final double particleY = particle.position.dy;

      // Query nearby particles using spatial index
      final List<int> nearbyIndices = _quadTree.findNearbyParticles(
        particleX,
        particleY,
        lineDistance,
      );

      // Track connections for density limiting
      int denseConnectionCount = 0;
      
      // Process each nearby particle
      for (final int nearbyIndex in nearbyIndices) {
        // Skip self-connections and avoid duplicate lines (only draw A->B, not B->A)
        if (nearbyIndex <= particleIndex) continue;
        
        // Limit connections in dense areas to prevent visual clutter
        if (denseConnectionCount >= maxConnectionsPerParticle) break;

        final Particle nearbyParticle = particles[nearbyIndex];
        
        // Calculate distance using cached calculator
        final double distance = _distanceCalculator.betweenParticles(
          particle,
          nearbyParticle,
        );

        // Only draw if within connection range
        if (distance <= lineDistance) {
          // Count connections in dense areas for limiting
          if (distance < densityThreshold) {
            denseConnectionCount++;
          }
          
          // Calculate opacity: closer particles = more opaque
          // opacity ranges from 0.0 (far) to 1.0 (close)
          final double opacity = 1.0 - (distance / lineDistance);
          
          if (opacity > 0) {
            // Map opacity to bucket index (0-9)
            // Higher opacity = higher bucket index = drawn later with more opacity
            final int bucketIndex = (opacity * 9).floor().clamp(0, 9);
            
            // Add line endpoints to appropriate bucket
            opacityBuckets[bucketIndex].add(particle.position);
            opacityBuckets[bucketIndex].add(nearbyParticle.position);
          }
        }
      }
    }

    // Render all buckets with batched draw calls
    for (int bucketIndex = 0; bucketIndex < 10; bucketIndex++) {
      final List<Offset> points = opacityBuckets[bucketIndex];
      
      if (points.isNotEmpty) {
        // Calculate opacity for this bucket
        // Bucket 0 = 0.1 opacity, Bucket 9 = 1.0 opacity
        final double bucketOpacity = (bucketIndex + 1) / 10.0;
        
        // Update paint color with calculated opacity
        linePaint.color = lineColor.withValues(alpha: bucketOpacity);
        
        // Draw all lines in this bucket with a single call
        canvas.drawPoints(ui.PointMode.lines, points, linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(OptimizedNetworkPainter oldDelegate) {
    // Optimized check: assume if any property changed we need to repaint
    // For particles, we assume they move every frame so we always repaint
    // unless explicitly paused (which isn't implemented yet).
    return true; 
  }
}
