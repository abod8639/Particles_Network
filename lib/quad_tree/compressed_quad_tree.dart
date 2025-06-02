import 'package:particles_network/model/rectangle.dart';
import 'package:particles_network/quad_tree/compressed_quad_tree_node.dart';

/// A space-partitioning data structure for efficient 2D spatial queries
///
/// Mathematical Foundations:
/// 1. Quadtree divides space into 4 quadrants (NW, NE, SW, SE)
/// 2. Uses recursive subdivision until capacity or depth limit reached
/// 3. Compression merges similar nodes to optimize memory usage
///
/// Performance Characteristics:
/// - Insertion: O(log n) average case
/// - Query: O(log n + k) where k is number of results
/// - Memory: O(n) with compression
class CompressedQuadTree {
  late CompressedQuadTreeNode _root; // Root node of the tree
  final Rectangle boundary; // Bounding rectangle of entire space

  /// Constructor initializes tree with given boundary
  /// [boundary]: The rectangular area this tree will cover
  CompressedQuadTree(this.boundary) {
    _root = CompressedQuadTreeNode(boundary);
  }

  /// Public accessor for root node (for debugging/inspection)
  CompressedQuadTreeNode get root => _root;

  /// Inserts a particle into the tree
  /// Returns true if insertion was successful
  ///
  /// Mathematical Operation:
  /// - Recursively finds the smallest quadrant that can contain the particle
  /// - Uses point-in-rectangle test at each level
  bool insert(QuadTreeParticle particle) {
    return _root.insert(particle);
  }

  /// Bulk builds the tree from a list of particles
  /// [particles]: Complete list of particle objects
  /// [visibleParticles]: Indices of particles to include in tree
  ///
  /// Optimization:
  /// - Clears existing tree first
  /// - Performs bulk insertion followed by memory optimization
  void buildFromParticles(
    List<dynamic> particles, // Using dynamic to match original interface
    List<int> visibleParticles,
  ) {
    clear(); // Reset the tree

    // Insert all visible particles
    for (final i in visibleParticles) {
      if (i < particles.length) {
        final p = particles[i];
        // Create QuadTreeParticle with index and position
        insert(QuadTreeParticle(i, p.position.dx, p.position.dy));
      }
    }

    // Optimize memory after bulk insertion
    _root.optimizeMemory();
  }

  /// Queries particles within a rectangular area
  /// Returns list of particle indices within the range
  ///
  /// Mathematical Operation:
  /// - Rectangle-rectangle intersection test at each node
  /// - Recursively checks child nodes that intersect the query area
  List<int> queryRange(Rectangle range) {
    return _root.queryRange(range).map((p) => p.index).toList();
  }

  /// Queries particles within a circular area
  /// Returns list of particle indices within the circle
  ///
  /// Mathematical Operations:
  /// 1. First filters nodes using rectangle-circle intersection
  /// 2. Then checks exact distance using: sqrt((x2-x1)² + (y2-y1)²) <= radius
  List<int> queryCircle(double centerX, double centerY, double radius) {
    return _root
        .queryCircle(centerX, centerY, radius)
        .map((p) => p.index)
        .toList();
  }

  /// Finds nearby particles using circular query
  /// Convenience wrapper around queryCircle
  List<int> findNearbyParticles(double x, double y, double searchRadius) {
    return queryCircle(x, y, searchRadius);
  }

  /// Gets indices of all particles in the tree
  List<int> getAllParticleIndices() {
    return _root.getAllParticles().map((p) => p.index).toList();
  }

  /// Clears all particles from the tree
  void clear() {
    _root.clear();
  }

  /// Gets comprehensive tree statistics including:
  /// - Node counts
  /// - Depth information
  /// - Compression metrics
  ///
  /// Key Metrics Calculated:
  /// 1. Compression Ratio: compressedNodes/totalNodes
  /// 2. Sparsity Ratio: emptyNodes/totalNodes
  Map<String, dynamic> getStats() {
    return _root.getStats();
  }

  /// Optimizes memory usage by compressing similar nodes
  ///
  /// Compression Algorithm:
  /// 1. Recursively traverses tree
  /// 2. Merges nodes where all particles could fit in parent node
  /// 3. Eliminates redundant empty nodes
  void optimize() {
    _root.optimizeMemory();
  }

  /// Rebalances the tree structure
  ///
  /// Mathematical Operation:
  /// 1. Collects all particles
  /// 2. Rebuilds tree from scratch with optimal structure
  void rebalance() {
    _root.rebalance();
  }

  /// Determines if tree needs rebalancing based on compression metrics
  ///
  /// Decision Formula:
  /// Rebalance when:
  /// compressionRatio < 0.1 (tree is under-compressed) OR
  /// sparsityRatio > 0.7 (tree is too sparse)
  bool needsRebalancing() {
    final stats = getStats();
    final compressionRatio = stats['compressionRatio'] as double;
    final sparsityRatio = stats['sparsityRatio'] as double;

    return compressionRatio < 0.1 || sparsityRatio > 0.7;
  }

  /// Rebuilds the entire tree from particle data
  ///
  /// Optimization Note:
  /// More efficient than clearing and reinserting when particle
  /// set hasn't changed significantly
  void rebuild(List<dynamic> particles, List<int> visibleParticles) {
    buildFromParticles(particles, visibleParticles);
  }
}
