import 'dart:typed_data';

import 'package:flutter/rendering.dart';
import 'package:particles_network/model/particlemodel.dart';

/// A highly optimized CustomPainter that draws the particle network effect.
/// This painter is responsible for rendering particles and the connecting lines between them,
/// using spatial partitioning for improved performance with large numbers of particles.
///
/// Key Components:
/// - Particle Rendering: Draws individual particles on the canvas
/// - Connection Lines: Creates lines between nearby particles
/// - Touch Interaction: Handles user touch input to affect particle behavior
/// - Spatial Partitioning: Optimizes performance by dividing space into grid cells
/// - Distance Caching: Reduces redundant calculations by caching particle distances
class OptimizedNetworkPainter extends CustomPainter {
  /// List of particles to be rendered
  final List<Particle> particles;

  /// Current touch point location (null if no touch)
  final Offset? touchPoint;

  /// Maximum distance for drawing connections between particles
  final double lineDistance;

  /// Color used for rendering individual particles
  final Color particleColor;

  /// Color used for the connecting lines between particles
  final Color lineColor;

  /// Color used for touch interaction effects
  final Color touchColor;

  /// Flag to enable/disable touch interaction features
  final bool touchActivation;

  // Cache system for storing calculated distances between particles
  // Uses bit manipulation for efficient key generation
  final Map<int, double> _distanceCache = {};
  static const _cacheMultiplier = 1 << 16; // Bit shift for cache key generation

  OptimizedNetworkPainter({
    required this.particles,
    required this.touchPoint,
    required this.lineDistance,
    required this.particleColor,
    required this.lineColor,
    required this.touchColor,
    required this.touchActivation,
  });

  /// Generates a unique cache key for a pair of particles
  /// Uses bit manipulation for efficient key generation
  /// @param i First particle index
  /// @param j Second particle index
  /// @return Unique integer key for the particle pair
  int _getCacheKey(int i, int j) {
    return i < j ? i * _cacheMultiplier + j : j * _cacheMultiplier + i;
  }

  /// Calculates and caches the distance between two particles
  /// Uses a caching system to avoid recalculating distances
  /// @param p1 First particle
  /// @param p2 Second particle
  /// @param i Index of first particle
  /// @param j Index of second particle
  /// @return Distance between the particles
  double _getDistance(Particle p1, Particle p2, int i, int j) {
    final key = _getCacheKey(i, j);
    return _distanceCache.putIfAbsent(
      key,
      () => (p1.position - p2.position).distance,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Clear the distance cache at the start of each frame
    _distanceCache.clear();

    // Setup paint objects for particles and lines
    final particlePaint =
        Paint()
          ..color = particleColor
          ..style = PaintingStyle.fill;

    final linePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

    // Create spatial grid for optimized particle proximity detection
    final grid = _createSpatialGrid(size);

    // Draw connections between nearby particles
    _drawParticleConnections(canvas, linePaint, grid);

    // Handle touch interactions if enabled
    if (touchPoint != null && touchActivation) {
      _drawTouchInteractions(canvas, linePaint);
    }

    // Draw all particles
    for (final p in particles) {
      canvas.drawCircle(p.position, p.size, particlePaint);
    }
  }

  /// Creates a spatial partitioning grid for efficient particle proximity detection
  /// Divides the canvas into cells based on lineDistance
  /// Each particle is added to its cell and neighboring cells for complete coverage
  Map<String, Uint16List> _createSpatialGrid(Size size) {
    final grid = <String, Uint16List>{};
    final cellSize = lineDistance;
    final tempLists = <String, List<int>>{};

    // First pass: collect particles per cell
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      final cellX = (p.position.dx / cellSize).floor();
      final cellY = (p.position.dy / cellSize).floor();

      // Add particle to appropriate cells (3x3 neighborhood)
      for (int nx = -1; nx <= 1; nx++) {
        for (int ny = -1; ny <= 1; ny++) {
          final key = '${cellX + nx},${cellY + ny}';
          tempLists.putIfAbsent(key, () => []);
          tempLists[key]!.add(i);
        }
      }
    }

    // Convert to Uint16List
    tempLists.forEach((key, list) {
      grid[key] = Uint16List.fromList(list);
    });

    return grid;
  }

  /// Draws connections between particles that are within lineDistance of each other
  /// Uses the spatial grid for efficient proximity detection
  /// Implements a bit-based system to track processed particle pairs
  void _drawParticleConnections(
    Canvas canvas,
    Paint linePaint,
    Map<String, Uint16List> grid,
  ) {
    final processedPairs = Uint32List(
      (particles.length * particles.length) >> 5,
    );

    // For each cell in the grid
    grid.forEach((key, particleIndices) {
      final count = particleIndices.length;

      // For particles in the same cell
      for (int i = 0; i < count; i++) {
        final pIndex = particleIndices[i];
        final p = particles[pIndex];

        for (int j = i + 1; j < count; j++) {
          final otherIndex = particleIndices[j];
          final pairKey = _getCacheKey(pIndex, otherIndex);
          final bitIndex = pairKey % processedPairs.length;
          final mask = 1 << (pairKey & 31);

          // Check if pair was already processed
          if ((processedPairs[bitIndex] & mask) != 0) continue;
          processedPairs[bitIndex] |= mask;

          final other = particles[otherIndex];
          final distance = _getDistance(p, other, pIndex, otherIndex);

          if (distance < lineDistance) {
            final opacity =
                ((1.0 - distance / lineDistance) * 0.9 * 355).toInt();
            linePaint.color = lineColor.withAlpha(opacity);
            canvas.drawLine(p.position, other.position, linePaint);
          }
        }
      }
    });
  }

  /// Handles particle interactions with touch input
  /// Applies pulling forces to nearby particles and draws connection lines
  /// The force and line opacity are based on distance from touch point
  void _drawTouchInteractions(Canvas canvas, Paint linePaint) {
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      final distance = (p.position - touchPoint!).distance;

      if (distance < lineDistance) {
        final pull = (touchPoint! - p.position) * 0.0012;
        p.velocity += pull;
        p.wasAccelerated = true;

        final opacity = ((1 - distance / lineDistance) * 0.8 * 355).toInt();
        linePaint.color = touchColor.withAlpha(opacity);
        canvas.drawLine(p.position, touchPoint!, linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(OptimizedNetworkPainter oldDelegate) {
    // Repaint if touch position changed or if any particle was accelerated
    return oldDelegate.touchPoint != touchPoint ||
        particles.any((p) => p.wasAccelerated);
  }
}
