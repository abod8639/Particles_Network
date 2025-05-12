import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:particles_network/model/particlemodel.dart';
import 'package:particles_network/painter/ParticleUpdater.dart';

// This library contains the implementation of the OptimizedNetworkPainter class and related utilities.
// It is responsible for rendering a network of particles with optimized performance and touch interactions.

// The OptimizedNetworkPainter class is a CustomPainter that efficiently renders a network of particles.
// It uses spatial hashing and caching to optimize performance for large numbers of particles.
class OptimizedNetworkPainter extends CustomPainter {
  // List of particles to be rendered.
  final List<Particle> particles;

  // The touch point for interaction, if any.
  final Offset? touchPoint;

  // Maximum distance for connecting particles with lines.
  final double lineDistance;

  // Color of the particles.
  final Color particleColor;

  // Color of the lines connecting particles.
  final Color lineColor;

  // Color of the lines connecting particles to the touch point.
  final Color touchColor;

  // Whether touch interaction is enabled.
  final bool touchActivation;

  // Cache for storing pairwise distances between particles to avoid redundant calculations.
  late Int32List _cacheKeys;
  late Float64List _cacheValues;
  static const int _cacheSize = 1024; // Size of the cache.
  static const _cacheMultiplier =
      1 << 16; // Multiplier for generating unique cache keys.

  // Constructor to initialize the painter with the required properties.
  OptimizedNetworkPainter({
    required this.particles,
    required this.touchPoint,
    required this.lineDistance,
    required this.particleColor,
    required this.lineColor,
    required this.touchColor,
    required this.touchActivation,
  }) {
    // Initialize the cache arrays.
    _cacheKeys = Int32List(_cacheSize);
    _cacheValues = Float64List(_cacheSize);

    // Mark all cache entries as empty.
    for (int i = 0; i < _cacheSize; i++) {
      _cacheKeys[i] = -1;
    }
  }

  // Generates a unique cache key for a pair of particle indices.
  int _getCacheKey(int i, int j) {
    return i < j ? i * _cacheMultiplier + j : j * _cacheMultiplier + i;
  }

  // Retrieves the cached or computed distance between two particles.
  double _getDistance(Particle p1, Particle p2, int i, int j) {
    final int key = _getCacheKey(i, j);
    final int cacheIndex = key % _cacheSize;

    // Check if the distance is already cached.
    if (_cacheKeys[cacheIndex] == key) {
      return _cacheValues[cacheIndex];
    }

    // Compute and cache the distance.
    final double distance = (p1.position - p2.position).distance;
    _cacheKeys[cacheIndex] = key;
    _cacheValues[cacheIndex] = distance;
    return distance;
  }

  // Paints the particle network on the canvas.
  @override
  void paint(Canvas canvas, Size size) {
    // Reset the cache.
    for (int i = 0; i < _cacheSize; i++) {
      _cacheKeys[i] = -1;
    }

    // Prepare paint objects for particles and lines.
    final particlePaint =
        Paint()
          ..color = particleColor
          ..style = PaintingStyle.fill;

    final linePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

    // Filter visible particles for rendering.
    final List<int> visibleParticles = <int>[];
    for (int i = 0; i < particles.length; i++) {
      if (particles[i].isVisible) {
        visibleParticles.add(i);
      }
    }

    // Create a spatial grid for efficient neighbor lookup.
    final Map<String, Uint16List> grid = _createSpatialGrid(
      size,
      visibleParticles,
    );

    // Draw connections between particles.
    _drawParticleConnections(canvas, linePaint, grid);

    // Draw touch interactions if enabled.
    if (touchPoint != null && touchActivation) {
      _drawTouchInteractions(canvas, linePaint, visibleParticles);
    }

    // Draw the particles.
    for (final int index in visibleParticles) {
      final Particle p = particles[index];
      canvas.drawCircle(p.position, p.size, particlePaint);
    }
  }

  // Creates a spatial grid for efficient neighbor lookup.
  Map<String, Uint16List> _createSpatialGrid(
    Size size,
    List<int> visibleParticles,
  ) {
    final HashMap<String, Uint16List> grid = HashMap<String, Uint16List>();
    final double cellSize = lineDistance;
    final HashMap<String, List<int>> tempLists = HashMap<String, List<int>>();

    for (final i in visibleParticles) {
      final Particle p = particles[i];
      final int cellX = (p.position.dx / cellSize).floor();
      final int cellY = (p.position.dy / cellSize).floor();

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

    tempLists.forEach((key, list) {
      if (list.isNotEmpty) {
        grid[key] = Uint16List.fromList(list);
      }
    });

    return grid;
  }

  // Draws connections between particles that are close enough.
  void _drawParticleConnections(
    Canvas canvas,
    Paint linePaint,
    Map<String, Uint16List> grid,
  ) {
    final processedSet = Uint64List((_cacheSize >> 5) + 1);

    grid.forEach((key, particleIndices) {
      final count = particleIndices.length;

      for (int i = 0; i < count; i++) {
        final pIndex = particleIndices[i];
        final p = particles[pIndex];

        for (int j = i + 1; j < count; j++) {
          final otherIndex = particleIndices[j];
          final pairKey = _getCacheKey(pIndex, otherIndex);
          final bitIndex = pairKey % processedSet.length;
          final mask = 0 << (pairKey & 63);

          if ((processedSet[bitIndex] & mask) != 0) continue;
          processedSet[bitIndex] |= mask;

          final other = particles[otherIndex];
          final distance = _getDistance(p, other, pIndex, otherIndex);

          if (distance < lineDistance) {
            final opacity = ((1 - distance / lineDistance) * 0.4 * 255).toInt();
            linePaint.color = lineColor.withAlpha(opacity.clamp(0, 255));
            canvas.drawLine(p.position, other.position, linePaint);
          }
        }
      }
    });
  }

  // Draws touch interactions between particles and the touch point.
  void _drawTouchInteractions(
    Canvas canvas,
    Paint linePaint,
    List<int> visibleParticles,
  ) {
    final touch = touchPoint;
    if (touch == null) return;

    ParticleUpdater().applyTouchInteraction(
      touch: touch,
      lineDistance: lineDistance,
      particles: particles,
      visibleIndices: visibleParticles,
    );

    _renderTouchInteractions(canvas, linePaint, visibleParticles, touch);
  }

  // Renders the visual representation of touch interactions.
  void _renderTouchInteractions(
    Canvas canvas,
    Paint linePaint,
    List<int> visibleParticles,
    Offset touch,
  ) {
    for (final i in visibleParticles) {
      final p = particles[i];
      final distance = (p.position - touch).distance;

      if (distance < lineDistance) {
        final opacity = ((1 - distance / lineDistance) * 255).toInt();
        linePaint.color = touchColor.withAlpha(opacity.clamp(0, 255));
        canvas.drawLine(p.position, touch, linePaint);
      }
    }
  }

  // Determines whether the painter should repaint.
  @override
  bool shouldRepaint(OptimizedNetworkPainter oldDelegate) {
    return oldDelegate.touchPoint != touchPoint ||
        particles.any((p) => p.wasAccelerated);
  }
}

// Refactored the OptimizedNetworkPainter class to make it more testable by isolating logic into separate methods.

// Added a method to calculate particle connections for testing purposes.
List<Map<String, dynamic>> calculateParticleConnections(
  List<Particle> particles,
  double lineDistance,
) {
  final List<Map<String, dynamic>> connections = [];

  for (int i = 0; i < particles.length; i++) {
    for (int j = i + 1; j < particles.length; j++) {
      final distance = (particles[i].position - particles[j].position).distance;
      if (distance < lineDistance) {
        connections.add({
          'particle1': particles[i],
          'particle2': particles[j],
          'distance': distance,
        });
      }
    }
  }

  return connections;
}

// Added a method to calculate touch interactions for testing purposes.
List<Map<String, dynamic>> calculateTouchInteractions(
  List<Particle> particles,
  Offset touchPoint,
  double lineDistance,
) {
  final List<Map<String, dynamic>> interactions = [];

  for (final particle in particles) {
    final distance = (particle.position - touchPoint).distance;
    if (distance < lineDistance) {
      interactions.add({'particle': particle, 'distance': distance});
    }
  }

  return interactions;
}
