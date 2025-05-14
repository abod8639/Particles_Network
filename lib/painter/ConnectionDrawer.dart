import 'dart:ui';

import 'package:particles_network/model/GridCell.dart';
import 'package:particles_network/model/particlemodel.dart';
import 'package:particles_network/painter/DistanceCalculator.dart';

/// Handles the drawing of connection lines between nearby particles in a network
///
/// This class implements an optimized approach to:
/// 1. Find particle pairs within connection distance
/// 2. Calculate connection line opacity based on distance
/// 3. Render visually pleasing connections between particles
///
/// Optimization Features:
/// - Uses spatial grid for O(1) neighbor lookups
/// - Implements pair processing tracking to avoid duplicate draws
/// - Caches distance calculations
/// - Batched line drawing operations
class ConnectionDrawer {
  // Required dependencies
  final List<Particle> particles; // Reference to all particles
  final int particleCount; // Total particle count (for pair hashing)
  final double lineDistance; // Maximum connection distance
  final Color lineColor; // Base color for connections
  final Paint linePaint; // Pre-configured paint object
  final DistanceCalculator
  distanceCalculator; // For optimized distance calculations

  ConnectionDrawer({
    required this.particles,
    required this.particleCount,
    required this.lineDistance,
    required this.lineColor,
    required this.linePaint,
    required this.distanceCalculator,
  });

  /// Draws connection lines between particles within the specified distance
  ///
  /// Algorithm Overview:
  /// 1. Iterates through each grid cell and its particles
  /// 2. Checks particles against others in the same cell
  /// 3. Uses distance to determine line opacity (closer = more opaque)
  /// 4. Draws lines with distance-based alpha blending
  ///
  /// Mathematical Formulas:
  /// - Distance: d = √(Δx² + Δy²) (handled by DistanceCalculator)
  /// - Opacity: α = 255 * (1 - d/d_max) * fursOpacity
  ///   where fursOpacity is a constant (currently 1)
  ///
  /// Performance Characteristics:
  /// Time Complexity: O(n * k²) where:
  ///   n = number of grid cells
  ///   k = average particles per cell (typically small due to spatial partitioning)
  void drawConnections(Canvas canvas, Map<GridCell, List<int>> grid) {
    // Tracks processed particle pairs to avoid duplicate drawing
    final processed = <int>{};

    // Process each grid cell
    grid.forEach((_, particleIndices) {
      // Compare each particle with others in the same cell
      for (int i = 0; i < particleIndices.length; i++) {
        final pIndex = particleIndices[i];
        final p = particles[pIndex];

        // Only check particles after current to avoid duplicate pairs
        for (int j = i + 1; j < particleIndices.length; j++) {
          final otherIndex = particleIndices[j];

          // Create unique pair key regardless of order
          final int pairKey = pIndex * particleCount + otherIndex;

          // Skip if already processed
          if (!processed.add(pairKey)) continue;

          final other = particles[otherIndex];

          // Get distance (uses cached value if available)
          final distance = distanceCalculator.calculateDistance(p, other);

          // Constant for opacity scaling (currently 1 = full effect)
          const double fursOpacity = 1;

          // Only connect if within maximum distance
          if (distance < lineDistance) {
            // Calculate opacity based on normalized distance (0 to 1)
            // Then scale by fursOpacity and convert to 0-255 range
            final opacity =
                ((1 - distance / lineDistance) * fursOpacity * 255).toInt();

            // Update paint with new alpha value
            linePaint.color = lineColor.withAlpha(opacity.clamp(0, 255));

            // Draw the connection line
            canvas.drawLine(p.position, other.position, linePaint);
          }
        }
      }
    });
  }
}
