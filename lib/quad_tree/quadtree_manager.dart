// File: compressed_quadtree_manager.dart

import 'dart:math' as math; // Import math library for mathematical operations

// Import necessary model and quadtree implementation
import 'package:particles_network/model/particlemodel.dart';
import 'package:particles_network/model/rectangle.dart';
import 'package:particles_network/quad_tree/compressed_quad_tree.dart';

/// Helper class for circle queries that stores circle parameters
class CircleQuery {
  final double x, y, radius; // Center coordinates and radius
  const CircleQuery(this.x, this.y, this.radius);
}

/// Manages a compressed quadtree with advanced optimization features
class CompressedQuadTreeManager {
  CompressedQuadTree? _quadTree; // The underlying quadtree instance
  Rectangle? _worldBounds; // Boundaries of the world space

  // Performance tracking variables
  int _queryCount = 0; // Counts total queries performed
  int _insertCount = 0; // Counts total insert operations
  DateTime? lastOptimization; // Timestamp of last optimization

  // Adaptive parameters for tree optimization
  double compressionThreshold = .3; // Threshold for node compression (0-1)
  final int _optimizationInterval = 1000; // Operations between optimizations

  /// Initializes quadtree with specified world boundaries
  /// [minX], [minY]: Bottom-left corner coordinates
  /// [maxX], [maxY]: Top-right corner coordinates
  void initialize(double minX, double minY, double maxX, double maxY) {
    // Create rectangle representing world bounds
    // Width and height are calculated as (max - min)
    _worldBounds = Rectangle(minX, minY, maxX - minX, maxY - minY);

    // Initialize the compressed quadtree with these bounds
    _quadTree = CompressedQuadTree(_worldBounds!);

    // Reset performance counters
    _resetPerformanceCounters();
  }

  /// Builds the tree from particles with compression optimization
  /// [particles]: Complete list of particles
  /// [visibleParticles]: Indices of currently visible particles to include
  void buildTree(List<Particle> particles, List<int> visibleParticles) {
    // Initialize tree if not already done
    if (_quadTree == null) {
      _initializeFromParticles(particles, visibleParticles);
    }

    // Build tree from the visible particles
    _quadTree!.buildFromParticles(particles, visibleParticles);

    // Update insert counter
    _insertCount += visibleParticles.length;

    // Check if optimization is needed based on operation counts
    _checkAutoOptimization();
  }

  /// Initializes tree bounds based on particle positions with statistical padding
  void _initializeFromParticles(
    List<Particle> particles,
    List<int> visibleParticles,
  ) {
    // Handle empty particle list case
    if (visibleParticles.isEmpty) {
      initialize(-1, -1, 1, 1); // Default bounds if no particles
      return;
    }

    // Filter valid particles and extract their positions
    final positions =
        visibleParticles
            .where((i) => i < particles.length) // Filter invalid indices
            .map((i) => particles[i]) // Get particle objects
            .toList();

    // Handle case where all indices were invalid
    if (positions.isEmpty) {
      initialize(-1, -1, 1, 1);
      return;
    }

    // Initialize bounds with first particle's position
    double minX = positions.first.position.dx;
    double minY = positions.first.position.dy;
    double maxX = minX;
    double maxY = minY;

    // Expand bounds to contain all particles using min/max comparisons
    for (final p in positions) {
      minX = math.min(minX, p.position.dx); // Find minimum x
      minY = math.min(minY, p.position.dy); // Find minimum y
      maxX = math.max(maxX, p.position.dx); // Find maximum x
      maxY = math.max(maxY, p.position.dy); // Find maximum y
    }

    // Calculate adaptive padding based on particle distribution
    final width = maxX - minX; // Current width of particle distribution
    final height = maxY - minY; // Current height of particle distribution
    final avgDimension = (width + height) / 2; // Average dimension
    double padding = avgDimension * 0.15; // 15% of average dimension as padding
    padding = math.max(padding, 1.0); // Ensure minimum padding of 1.0

    // Adjust bounds if they're too small in either dimension
    if (width < padding) {
      final center = minX + width / 2; // Calculate center x
      minX = center - padding / 2; // Expand left
      maxX = center + padding / 2; // Expand right
    }

    if (height < padding) {
      final center = minY + height / 2; // Calculate center y
      minY = center - padding / 2; // Expand bottom
      maxY = center + padding / 2; // Expand top
    }

    // Initialize with expanded bounds including padding
    initialize(minX - padding, minY - padding, maxX + padding, maxY + padding);
  }

  /// Queries particles within a rectangular area
  /// Returns list of particle indices within the specified rectangle
  /// Uses axis-aligned bounding box (AABB) intersection test
  List<int> queryRectangle(double x, double y, double width, double height) {
    if (_quadTree == null) return const [];

    _queryCount++; // Increment query counter
    final searchArea = Rectangle(x, y, width, height);
    return _quadTree!.queryRange(searchArea);
  }

  /// Queries particles within a circular area
  /// Uses Euclidean distance formula: sqrt((x2-x1)² + (y2-y1)²) <= radius
  List<int> queryCircle(double centerX, double centerY, double radius) {
    if (_quadTree == null) return [];
    _queryCount++; // Increment query counter
    return _quadTree!.queryCircle(centerX, centerY, radius);
  }

  /// Finds nearby particles with adaptive search radius
  /// Radius increases based on local particle density
  List<int> findNearbyParticles(dynamic particle, double searchRadius) {
    if (_quadTree == null) return [];

    // Calculate adaptive radius based on density
    final stats = getTreeStats();
    // Particle density = total particles / total nodes
    final particleDensity = stats['particles'] / stats['nodes'];
    // Increase radius proportionally to density (1% per density unit)
    final adaptiveRadius = searchRadius * (1.0 + particleDensity / 100.0);

    // Perform query with adaptive radius
    return _quadTree!.findNearbyParticles(
      particle.position.dx,
      particle.position.dy,
      adaptiveRadius,
    );
  }

  /// Gets potential collision candidates for a particle
  /// Uses circular query and filters out the particle itself
  List<int> getCollisionCandidates(
    int particleIndex,
    List<dynamic> particles,
    double collisionRadius,
  ) {
    // Validate input
    if (_quadTree == null || particleIndex >= particles.length) return [];

    // Get target particle
    final targetParticle = particles[particleIndex];

    // Find all particles within collision radius
    List<int> candidates = queryCircle(
      targetParticle.position.dx,
      targetParticle.position.dy,
      collisionRadius,
    );

    // Remove the particle itself from candidates
    candidates.removeWhere((index) => index == particleIndex);
    return candidates;
  }

  /// Updates the tree with current particle positions
  /// Decides whether to rebuild or optimize based on tree statistics
  void updateTree(List<Particle> particles, List<int> visibleParticles) {
    if (_quadTree == null) {
      buildTree(particles, visibleParticles);
      return;
    }

    _quadTree!.optimize(); // Always optimize before update
  }

  /// Gets comprehensive tree statistics including performance metrics
  Map<String, dynamic> getTreeStats() {
    if (_quadTree == null) return _emptyStats();

    // Get basic tree statistics
    final stats = _quadTree!.getStats();

    // Add performance metrics
    stats.addAll({
      'queryCount': _queryCount,
      'insertCount': _insertCount,
      // Average queries per node (measure of query concentration)
      'avgQueriesPerNode': _queryCount / math.max(1, stats['nodes'] as int),
    });
    return stats;
  }

  /// Checks if optimization should be performed based on operation count
  void _checkAutoOptimization() {
    // Check if total operations reached optimization interval
    if ((_queryCount + _insertCount) >= _optimizationInterval) {
      _performAutoOptimization();
      _resetPerformanceCounters();
      lastOptimization = DateTime.now();
    }
  }

  /// Performs automatic optimization based on usage patterns
  void _performAutoOptimization() {
    if (_quadTree == null) return;

    // Get current tree statistics
    final stats = _quadTree!.getStats();
    final compressionRatio = stats['compressionRatio'] as double;
    final sparsityRatio = stats['sparsityRatio'] as double;

    // Adjust compression based on workload characteristics
    if (compressionRatio < 0.2 && _queryCount > _insertCount) {
      // If tree is under-compressed and query-heavy, favor query performance
      compressionThreshold *= 0.9; // Reduce compression threshold
      _quadTree!.rebalance(); // Rebalance the tree
    } else if (sparsityRatio > 0.6 && _insertCount > _queryCount) {
      // If tree is sparse and insertion-heavy, favor insertion performance
      compressionThreshold *= 1.1; // Increase compression threshold
    }

    // Perform the optimization
    _quadTree!.optimize();
  }

  /// Returns empty statistics map
  Map<String, dynamic> _emptyStats() => {
    'nodes': 0,
    'leaves': 0,
    'particles': 0,
    'maxDepth': 0,
    'compressedNodes': 0,
    'sparseNodes': 0,
    'compressionRatio': 0.0,
    'sparsityRatio': 0.0,
  };

  // Standard interface methods
  void clear() => _quadTree?.clear();
  bool get isInitialized => _quadTree != null;
  Rectangle? get worldBounds => _worldBounds;
  void _resetPerformanceCounters() {
    _queryCount = 0;
    _insertCount = 0;
  }

  void optimizeTree() => _quadTree?.optimize();
  void rebalanceTree() => _quadTree?.rebalance();
}
