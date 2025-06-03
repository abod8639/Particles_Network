import 'dart:math' as math; // Import math library for mathematical operations

// Import the base quadtree manager
import 'package:particles_network/quad_tree/quadtree_manager.dart';

/// Extension methods that add enhanced functionality to CompressedQuadTreeManager
extension CompressedQuadTreeManagerExtensions on CompressedQuadTreeManager {
  /// Performs smart particle search with density-adaptive radius
  /// [x], [y]: Center coordinates for search
  /// [radius]: Base search radius (default 50.0)
  ///
  /// Mathematical Operations:
  /// 1. Calculates particle density (particles per node)
  /// 2. Adjusts radius based on density (higher density = larger radius)
  /// 3. Uses circle query with adaptive radius
  List<int> smartParticlesNear(double x, double y, [double radius = 50.0]) {
    // Get current tree statistics
    final stats = getTreeStats();

    // Calculate particle density (particles per node)
    // math.max(1, stats['nodes']) prevents division by zero
    final dynamic density = stats['particles'] / math.max(1, stats['nodes']);

    // Calculate adaptive radius:
    // - Base factor of 0.8 (minimum radius multiplier)
    // - Plus density/50 (increases radius with higher density)
    final double adaptiveRadius = radius * (0.8 + density / 50.0);

    // Perform circle query with adaptive radius
    return queryCircle(x, y, adaptiveRadius);
  }

  /// Performs efficient square search using circle approximation
  /// [centerX], [centerY]: Center of the square
  /// [sideLength]: Length of the square's sides
  ///
  /// Mathematical Operations:
  /// 1. Uses inscribed circle radius (sideLength * √2/2 ≈ 0.707)
  /// 2. Circle approximation reduces query complexity from O(n) to O(1) in best case
  List<int> efficientSquareSearch(
    double centerX,
    double centerY,
    double sideLength,
  ) {
    // Calculate radius of circle that would inscribe the square:
    // radius = (sideLength * √2)/2 ≈ sideLength * 0.707
    // This covers the entire square area while being more efficient to query
    final double radius = sideLength * 0.707; // sqrt(2)/2 approximation

    // Perform circle query that approximates the square
    return queryCircle(centerX, centerY, radius);
  }

  /// Optimized batch processing of multiple circle queries
  /// [queries]: List of CircleQuery objects to process
  ///
  /// Mathematical Operations:
  /// 1. Spatial sorting using Z-order curve
  /// 2. Merges nearby queries for better cache utilization
  List<List<int>> batchQuery(List<CircleQuery> queries) {
    final results = <List<int>>[];

    // Optimize query order by spatial locality
    final List<CircleQuery> optimizedQueries = _optimizeBatchQueries(queries);

    // Process each optimized query
    for (final query in optimizedQueries) {
      results.add(queryCircle(query.x, query.y, query.radius));
    }

    return results;
  }

  /// Optimizes batch queries by spatial locality using Z-order sorting
  /// [queries]: List of CircleQuery objects to optimize
  ///
  /// Mathematical Operations:
  /// 1. Z-order (Morton) curve calculation for each point
  /// 2. Spatial sorting based on Z-order values
  List<CircleQuery> _optimizeBatchQueries(List<CircleQuery> queries) {
    // Sort queries by spatial locality using Z-order approximation
    queries.sort((a, b) {
      final za = _zOrder(a.x, a.y); // Calculate Z-order for point A
      final zb = _zOrder(b.x, b.y); // Calculate Z-order for point B
      return za.compareTo(zb); // Compare Z-order values
    });

    return queries;
  }

  /// Calculates Z-order (Morton order) value for spatial sorting
  /// [x], [y]: Coordinates to encode
  ///
  /// Mathematical Operations:
  /// 1. Scales coordinates to integers (×1000 for precision)
  /// 2. Interleaves bits of x and y coordinates
  ///
  /// The Z-order curve maps multidimensional data to one dimension while preserving
  /// spatial locality. Points that are close in 2D space will have similar Z-values.
  int _zOrder(double x, double y) {
    // Convert coordinates to integers (16-bit precision)
    // & 0xFFFF ensures we only use 16 bits (0-65535)
    final int ix = (x * 1000).toInt() & 0xFFFF; // X coordinate
    final int iy = (y * 1000).toInt() & 0xFFFF; // Y coordinate

    // Initialize Z-order value
    int z = 0;

    // Interleave bits from x and y coordinates
    for (int i = 0; i < 16; i++) {
      // For each bit position:
      // 1. Extract the ith bit from x coordinate
      // 2. Shift it left by i positions (spacing for y bits)
      // 3. Extract the ith bit from y coordinate
      // 4. Shift it left by i+1 positions
      // 5. Combine both bits using OR operation
      z |= (ix & (1 << i)) << i | (iy & (1 << i)) << (i + 1);
    }

    return z;
  }
}
