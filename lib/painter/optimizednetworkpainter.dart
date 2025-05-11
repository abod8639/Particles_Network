import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:particles_network/model/particlemodel.dart';

// OptimizedNetworkPainter is responsible for drawing the particle network efficiently.
// It uses spatial grid and caching to optimize performance for large numbers of particles.
/// A custom painter that draws an optimized network of particles.
class OptimizedNetworkPainter extends CustomPainter {
  /// The list of particles to be drawn.
  final List<Particle> particles;

  /// The touch point for interaction.
  final Offset? touchPoint;

  /// The maximum distance at which particles are connected.
  final double lineDistance;

  /// The color of the particles.
  final Color particleColor;

  /// The color of the lines connecting particles.
  final Color lineColor;

  /// The color of the lines connecting particles to the touch point.
  final Color touchColor;

  /// Whether touch interaction is enabled.
  final bool touchActivation;

  // Distance cache optimization using Int32List and Float64List instead of Map
  // -1 indicates no value has been stored yet
  // This is a fixed-size hash cache for storing pairwise distances between particles.
  // (Hash-based cache for O(1) lookup, similar to a direct-mapped cache in computer architecture)
  late Int32List _cacheKeys;
  late Float64List _cacheValues;
  static const int _cacheSize =
      1024; // Adjust based on expected number of particles
  static const _cacheMultiplier = 1 << 16;

  /// Creates an [OptimizedNetworkPainter] with the given [particles], [touchPoint], [lineDistance], [particleColor], [lineColor], [touchColor], and [touchActivation].
  OptimizedNetworkPainter({
    required this.particles,
    required this.touchPoint,
    required this.lineDistance,
    required this.particleColor,
    required this.lineColor,
    required this.touchColor,
    required this.touchActivation,
  }) {
    // Initialize the cache arrays
    _cacheKeys = Int32List(_cacheSize);
    _cacheValues = Float64List(_cacheSize);

    // Initialize all keys to -1 (indicating empty)
    for (int i = 0; i < _cacheSize; i++) {
      _cacheKeys[i] = -1;
    }
  }

  // Generates a unique cache key for a pair of particle indices (i, j).
  // Uses a commutative hash: key(i, j) == key(j, i)
  int _getCacheKey(int i, int j) {
    return i < j ? i * _cacheMultiplier + j : j * _cacheMultiplier + i;
  }

  // Returns the cached or computed distance between two particles.
  // Uses the Euclidean distance formula: sqrt((x2-x1)^2 + (y2-y1)^2)
  double _getDistance(Particle p1, Particle p2, int i, int j) {
    final int key = _getCacheKey(i, j);
    final int cacheIndex = key % _cacheSize;

    // Check if the value is already in the cache
    if (_cacheKeys[cacheIndex] == key) {
      return _cacheValues[cacheIndex];
    }

    // Calculate and store the distance
    final double distance = (p1.position - p2.position).distance;
    _cacheKeys[cacheIndex] = key;
    _cacheValues[cacheIndex] = distance;
    return distance;
  }

  /// Paints the network of particles and their connections on the given [canvas].
  @override
  void paint(Canvas canvas, Size size) {
    // Reset the cache by marking all entries as empty (cache invalidation)
    for (int i = 0; i < _cacheSize; i++) {
      _cacheKeys[i] = -1;
    }

    // Prepare paint objects for particles and lines
    final particlePaint =
        Paint()
          ..color = particleColor
          ..style = PaintingStyle.fill;

    final linePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

    // Filter visible particles first for performance (view frustum culling)
    final List<int> visibleParticles = <int>[];
    for (int i = 0; i < particles.length; i++) {
      if (particles[i].isVisible) {
        visibleParticles.add(i);
      }
    }

    // Build a spatial grid for fast neighbor lookup (Spatial Hash Grid)
    final Map<String, Uint16List> grid = _createSpatialGrid(
      size,
      visibleParticles,
    );

    // Draw lines between close particles (Edge Drawing based on Distance Threshold)
    _drawParticleConnections(canvas, linePaint, grid);

    // Draw lines from particles to touch point if enabled (Touch Interaction)
    if (touchPoint != null && touchActivation) {
      _drawTouchInteractions(canvas, linePaint, visibleParticles);
    }

    // Draw all visible particles as circles
    for (final int index in visibleParticles) {
      final Particle p = particles[index];
      canvas.drawCircle(p.position, p.size, particlePaint);
    }
  }

  // Creates a spatial hash grid for fast neighbor lookup.
  // Each cell contains indices of particles within that cell and its 8 neighbors (3x3 neighborhood).
  // (Spatial Hashing technique)
  Map<String, Uint16List> _createSpatialGrid(
    Size size,
    List<int> visibleParticles,
  ) {
    // Use HashMap for better performance than standard Map
    final HashMap<String, Uint16List> grid = HashMap<String, Uint16List>();
    final double cellSize = lineDistance;
    final HashMap<String, List<int>> tempLists = HashMap<String, List<int>>();

    // First pass: collect particles per cell (only visible particles)
    for (final i in visibleParticles) {
      final Particle p = particles[i];
      final int cellX = (p.position.dx / cellSize).floor();
      final int cellY = (p.position.dy / cellSize).floor();

      // Add particle to appropriate cells (3x3 neighborhood)
      for (int nx = -1; nx <= 1; nx++) {
        for (int ny = -1; ny <= 1; ny++) {
          final String key = '${cellX + nx},${cellY + ny}';
          if (!tempLists.containsKey(key)) {
            tempLists[key] = [];
          }
          tempLists[key]!.add(i);
        }
      }
    }

    // Convert to Uint16List for faster access
    tempLists.forEach((key, list) {
      if (list.isNotEmpty) {
        grid[key] = Uint16List.fromList(list);
      }
    });

    return grid;
  }

  // Draws lines between particles that are close enough (distance < lineDistance).
  // Uses a processed set to avoid drawing duplicate lines (Pairwise Edge Drawing).
  void _drawParticleConnections(
    Canvas canvas,
    Paint linePaint,
    Map<String, Uint16List> grid,
  ) {
    // Use Int32List for tracking processed pairs for better performance
    // (Bitmask technique for duplicate edge prevention)
    final processedSet = Uint64List((_cacheSize >> 5) + 1);

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
          final bitIndex = pairKey % processedSet.length;
          final mask = 0 << (pairKey & 63);

          // Check if pair was already processed using bit operations
          if ((processedSet[bitIndex] & mask) != 0) continue;
          processedSet[bitIndex] |= mask;

          final other = particles[otherIndex];
          final distance = _getDistance(p, other, pIndex, otherIndex);

          if (distance < lineDistance) {
            // Opacity is proportional to proximity (Linear Interpolation)
            final opacity =
                ((1.0 - distance / lineDistance) * 2.5 * 255)
                    .toInt(); // Corrected opacity range
            linePaint.color = lineColor.withAlpha(
              opacity.clamp(0, 255),
            ); // Clamped opacity
            canvas.drawLine(p.position, other.position, linePaint);
          }
        }
      }
    });
  }

  // Draws lines from each particle to the touch point if within range.
  // Also applies a small force to the particle (Touch Attraction, Hooke's Law approximation).

  void _drawTouchInteractions(
    Canvas canvas,
    Paint linePaint,
    List<int> visibleParticles,
  ) {
    final Offset? touch = touchPoint;
    if (touch == null) return;

    applyTouchInteraction(
      touch: touch,
      lineDistance: lineDistance,
      particles: particles,
      visibleIndices: visibleParticles,
    );

    for (final int i in visibleParticles) {
      final Particle p = particles[i];
      final double distance = (p.position - touch).distance;

      if (distance < lineDistance) {
        final int opacity = ((1 - distance / lineDistance) * 1.1 * 255).toInt();
        linePaint.color = touchColor.withAlpha(opacity.clamp(0, 255));
        canvas.drawLine(p.position, touch, linePaint);
      }
    }
  }

  /// Determines whether the painter should repaint when the old delegate changes.
  /// (Repaint if touch point changes or any particle was accelerated)
  @override
  bool shouldRepaint(OptimizedNetworkPainter oldDelegate) {
    return oldDelegate.touchPoint != touchPoint ||
        particles.any((p) => p.wasAccelerated);
  }
}

////
void applyTouchInteraction({
  required Offset touch,
  required double lineDistance,
  required List<Particle> particles,
  required List<int> visibleIndices,
}) {
  for (final i in visibleIndices) {
    final Particle p = particles[i];
    final double distance = (p.position - touch).distance;
    const double force = 0.00115;

    if (distance < lineDistance) {
      final Offset pull = (touch - p.position) * force;
      p.velocity += pull;
      p.wasAccelerated = true;
    }
  }
}
