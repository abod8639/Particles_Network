import 'dart:math' as math;

import 'package:particles_network/quad_tree/quadtree_manager.dart';

/// Extension methods for enhanced functionality
extension CompressedQuadTreeManagerExtensions on CompressedQuadTreeManager {
  /// Smart particle search with adaptive parameters
  List<int> smartParticlesNear(double x, double y, [double radius = 50.0]) {
    final stats = getTreeStats();
    final density = stats['particles'] / math.max(1, stats['nodes']);
    final adaptiveRadius = radius * (0.8 + density / 50.0);

    return queryCircle(x, y, adaptiveRadius);
  }

  /// Efficient square search with rounded corners optimization
  List<int> efficientSquareSearch(
    double centerX,
    double centerY,
    double sideLength,
  ) {
    // Use circle approximation for better performance
    final radius = sideLength * 0.707; // sqrt(2)/2 for inscribed circle
    return queryCircle(centerX, centerY, radius);
  }

  /// Batch query optimization
  List<List<int>> batchQuery(List<CircleQuery> queries) {
    final results = <List<int>>[];

    // Group nearby queries for optimization
    final optimizedQueries = _optimizeBatchQueries(queries);

    for (final query in optimizedQueries) {
      results.add(queryCircle(query.x, query.y, query.radius));
    }

    return results;
  }

  /// Optimize batch queries by spatial locality
  List<CircleQuery> _optimizeBatchQueries(List<CircleQuery> queries) {
    // Sort by spatial locality (simple Z-order approximation)
    queries.sort((a, b) {
      final za = _zOrder(a.x, a.y);
      final zb = _zOrder(b.x, b.y);
      return za.compareTo(zb);
    });

    return queries;
  }

  /// Calculate Z-order (Morton order) for spatial locality
  int _zOrder(double x, double y) {
    // Simple Morton encoding for spatial sorting
    final ix = (x * 1000).toInt() & 0xFFFF;
    final iy = (y * 1000).toInt() & 0xFFFF;

    int z = 0;
    for (int i = 0; i < 16; i++) {
      z |= (ix & (1 << i)) << i | (iy & (1 << i)) << (i + 1);
    }

    return z;
  }
}
