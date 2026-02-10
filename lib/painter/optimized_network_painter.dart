import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:particles_network/model/particlemodel.dart';
import 'package:particles_network/model/rectangle.dart';
import 'package:particles_network/painter/distance_calculator.dart';
import 'package:particles_network/painter/object_pool.dart';
import 'package:particles_network/painter/particle_filter.dart';
import 'package:particles_network/painter/performance_utils.dart';
import 'package:particles_network/painter/touch_interaction_handler.dart';
import 'package:particles_network/quad_tree/compressed_quad_tree.dart';
import 'package:particles_network/quad_tree/compressed_quad_tree_node.dart';

// The main painter class for rendering an optimized particle network
//
// This class implements CustomPainter to efficiently render:
// - Individual particles as circles
// - Connection lines between nearby particles
// - Touch interaction effects
//
// Optimization Techniques:
// 1. Spatial partitioning using QuadTree
// 2. Distance calculation caching
// 3. Visible particle filtering
// 4. Batched drawing operations
// 5. Conditional rendering based on visibility
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

  // Performance optimization components
  late final AccelerationTracker _accelerationTracker;
  late final AdaptiveQuadTreeManager _quadTreeManager;
  late final PoolManager _poolManager;
  late final IntListPool _intListPool;
  late final ConnectionDataPool _connectionDataPool;

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
    // Initialize particle paint
    particlePaint = Paint()
      ..style = fill ? PaintingStyle.fill : PaintingStyle.stroke
      ..color = particleColor;

    // Initialize line paint with stroke configuration
    linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth
      // ..strokeCap = StrokeCap.round
      ..isAntiAlias = false
      ..color = lineColor;

    // Initialize performance tracking components
    _accelerationTracker = AccelerationTracker();
    _quadTreeManager = AdaptiveQuadTreeManager();
    _poolManager = PoolManager.getInstance();
    _intListPool = _poolManager.intListPool;
    _connectionDataPool = _poolManager.connectionDataPool;

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
    _accelerationTracker.resetFrame();

    final List<int> visibleParticles = ParticleFilter.getVisibleParticles(
      particles,
    );

    // Adaptive QuadTree update: only rebuild when necessary
    if (_quadTreeManager.shouldRebuild()) {
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
    }

    if (drawNetwork) {
      _drawConnections(canvas, visibleParticles);
    }

    if (touchPoint != null && touchActivation) {
      _touchHandler.drawTouchLines(canvas, visibleParticles);
      _touchHandler.applyTouchPhysics(visibleParticles, _accelerationTracker);
      _quadTreeManager.forceRebuild(); // Rebuild after touch interaction
    }

    // Always draw particles at the end
    _drawParticles(canvas, visibleParticles);
  }

  // Draws individual particles as circles
  //
  // Optimizations:
  // - Uses pre-allocated Paint object (avoids object creation each frame)
  // - Only draws visible particles (reduced draw calls)
  // - Simple drawCircle operation (hardware accelerated)
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

  // Draw connections between nearby particles using QuadTree
  //
  // Algorithm:
  // 1. For each particle, query nearby particles using QuadTree
  // 2. Calculate distance to each nearby particle
  // 3. Draw line if within max distance, with opacity based on distance
  //
  // Optimizations:
  // - Uses QuadTree for O(log n) proximity queries instead of O(n²)
  // - Distance calculation caching
  // - Skips duplicate connections (i < j)
  // - Distance-based opacity creates visual depth
  // - Object pooling for reduced memory allocations
  void _drawConnections(Canvas canvas, List<int> visibleParticles) {
    final double maxDistSq = lineDistance * lineDistance;
    final int maxLines = isComplex ? 4 : 5;
    // Throttling threshold: only sort and prune if we exceed this number of connections
    final int denseThreshold = isComplex ? (lineDistance ~/ 3) : (lineDistance ~/ 1);

    final List<int> nearbyIndices = _intListPool.acquire();
    final List<ConnectionData> connections = [];

    try {
      for (final int index in visibleParticles) {
        final Particle particle = particles[index];
        final Offset pos = particle.position;

        nearbyIndices.clear();
        _quadTree.findNearbyParticlesToOutput(pos.dx, pos.dy, lineDistance, nearbyIndices);

        connections.clear();
        for (final int neighborIndex in nearbyIndices) {
          // Avoid duplicate lines and self-connection
          if (neighborIndex <= index) continue;

          final Particle neighbor = particles[neighborIndex];
          final Offset neighborPos = neighbor.position;
          final double dx = pos.dx - neighborPos.dx;
          final double dy = pos.dy - neighborPos.dy;
          final double distSq = dx * dx + dy * dy;

          if (distSq <= maxDistSq) {
            connections.add(
              _connectionDataPool.acquire(
                index: neighborIndex,
                distance: math.sqrt(distSq),
              ),
            );
          }
        }

        // Density throttling: if we have too many connections, keep only the closest ones
        if (connections.length > denseThreshold) {
          connections.sort((a, b) => a.distance.compareTo(b.distance));
          while (connections.length > maxLines) {
            _connectionDataPool.release(connections.removeLast());
          }
        }

        // Draw connections for this particle
        for (final conn in connections) {
          final double opacity = (1.0 - (conn.distance / lineDistance)).clamp(0.0, 1.0);
          linePaint.color = lineColor.withAlpha((opacity * 255).toInt());
          canvas.drawLine(pos, particles[conn.index].position, linePaint);
          _connectionDataPool.release(conn);
        }
      }
    } finally {
      // Cleanup any remaining pooled objects in case of early return/error
      for (final conn in connections) {
        _connectionDataPool.release(conn);
      }
      _intListPool.release(nearbyIndices);
    }
  }

  @override
  bool shouldRepaint(OptimizedNetworkPainter oldDelegate) {
    return oldDelegate.touchPoint != touchPoint ||
        _accelerationTracker.hadAcceleratedParticles ||
        oldDelegate.lineDistance != lineDistance ||
        oldDelegate.particleColor != particleColor ||
        oldDelegate.lineColor != lineColor;
  }
}
