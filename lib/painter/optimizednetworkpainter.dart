import 'package:flutter/rendering.dart';
import 'package:particles_network/model/particlemodel.dart';

/// A highly optimized CustomPainter that draws the particle network effect.
/// This painter is responsible for rendering particles and the connecting lines between them,
/// using spatial partitioning for improved performance with large numbers of particles.
class OptimizedNetworkPainter extends CustomPainter {
  /// List of all particles to be rendered
  final List<Particle> particles;

  /// Current touch point location (if any)
  final Offset? touchPoint;

  /// Maximum distance for drawing lines between particles
  final double lineDistance;

  /// Color of the particles
  final Color particleColor;

  /// Color of the connecting lines between particles
  final Color lineColor;

  /// Color of lines created by touch interactions
  final Color touchColor;

  /// bool for Activation touch
  final bool touchActivation;

  /// Cache for storing distances between particles to avoid recalculation
  /// Uses string keys in the format "particle1Index-particle2Index"
  final Map<String, double> _distanceCache = {};

  /// Creates a new OptimizedNetworkPainter
  ///
  /// [particles] List of particles to render
  /// [touchPoint] Current touch interaction point (null if no touch)
  /// [lineDistance] Maximum distance for drawing connecting lines
  /// [particleColor] Color of particles
  /// [lineColor] Color of connecting lines
  /// [touchColor] Color of touch interaction lines
  /// [touchActivation]  touch interaction Activation
  OptimizedNetworkPainter({
    required this.particles,
    required this.touchPoint,
    required this.lineDistance,
    required this.particleColor,
    required this.lineColor,
    required this.touchColor,
    required this.touchActivation,
  });

  /// Generates a unique cache key for two particle indices
  /// Ensures consistent key generation regardless of parameter order
  String _getCacheKey(int i, int j) {
    return i < j ? '$i-$j' : '$j-$i';
  }

  /// Gets the cached distance between two particles, calculating it if not cached
  double _getDistance(Particle p1, Particle p2, int i, int j) {
    final key = _getCacheKey(i, j);
    if (!_distanceCache.containsKey(key)) {
      _distanceCache[key] = (p1.position - p2.position).distance;
    }
    return _distanceCache[key]!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Clear the distance cache at the start of each frame
    _distanceCache.clear();

    final particlePaint =
        Paint()
          ..color = particleColor
          ..style = PaintingStyle.fill;

    final linePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

    // Create spatial grid for optimized particle connection checks
    final Map<String, List<int>> grid = _createSpatialGrid(size);

    // Draw the connecting lines between particles
    _drawParticleConnections(canvas, linePaint, grid);

    // Handle and draw touch interactions
    if (touchPoint != null && touchActivation) {
      _drawTouchInteractions(canvas, linePaint);
    }

    // Draw all particles
    for (final p in particles) {
      canvas.drawCircle(p.position, p.size, particlePaint);
    }
  }

  /// Creates a spatial partitioning grid to optimize particle connection checks
  /// Divides the space into cells of size [lineDistance] and assigns particles
  /// to their respective cells and neighboring cells
  Map<String, List<int>> _createSpatialGrid(Size size) {
    final Map<String, List<int>> grid = {};
    final cellSize = lineDistance;

    // Assign particles to grid cells
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      final cellX = (p.position.dx / cellSize).floor();
      final cellY = (p.position.dy / cellSize).floor();

      // Add particle to current cell and neighboring cells
      for (int nx = -1; nx <= 1; nx++) {
        for (int ny = -1; ny <= 1; ny++) {
          final key = '${cellX + nx},${cellY + ny}';
          grid.putIfAbsent(key, () => []);
          grid[key]!.add(i);
        }
      }
    }

    return grid;
  }

  /// Draws connecting lines between particles that are within [lineDistance]
  /// Uses the spatial grid to optimize connection checks
  void _drawParticleConnections(
    Canvas canvas,
    Paint linePaint,
    Map<String, List<int>> grid,
  ) {
    final Set<String> processedPairs = {};

    // Process particles in each grid cell
    for (final entry in grid.entries) {
      final particleIndices = entry.value;

      // Check connections between particles in the same cell
      for (int i = 0; i < particleIndices.length; i++) {
        final pIndex = particleIndices[i];
        final p = particles[pIndex];

        for (int j = i + 1; j < particleIndices.length; j++) {
          final otherIndex = particleIndices[j];
          final pairKey = _getCacheKey(pIndex, otherIndex);

          // Skip if this pair has already been processed
          if (processedPairs.contains(pairKey)) continue;
          processedPairs.add(pairKey);

          final other = particles[otherIndex];
          final distance = _getDistance(p, other, pIndex, otherIndex);

          // Draw line if particles are close enough
          if (distance < lineDistance) {
            final double opacity = (1.0 - distance / lineDistance) * 0.9 * 355;
            linePaint.color = lineColor.withAlpha(opacity.toInt());
            canvas.drawLine(p.position, other.position, linePaint);
          }
        }
      }
    }
  }

  /// Handles touch interactions with particles and draws connecting lines
  /// Applies force to particles near the touch point and draws lines to them
  void _drawTouchInteractions(Canvas canvas, Paint linePaint) {
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      final distance = (p.position - touchPoint!).distance;

      if (distance < lineDistance) {
        // Apply attractive force to particle
        final pull = (touchPoint! - p.position) * 0.0012;
        p.velocity += pull;
        p.wasAccelerated = true;

        // Draw line to touch point with fade based on distance
        final double opacity = (1 - distance / lineDistance) * 0.8 * 355;
        linePaint.color = touchColor.withAlpha(opacity.toInt());
        canvas.drawLine(p.position, touchPoint!, linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(OptimizedNetworkPainter oldDelegate) {
    // Only trigger repaint if touch state changed or particles were accelerated
    return oldDelegate.touchPoint != touchPoint ||
        particles.any((p) => p.wasAccelerated);
  }
}
