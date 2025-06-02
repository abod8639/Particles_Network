import 'package:particles_network/model/rectangle.dart';
import 'package:particles_network/quad_tree/compressed_quad_tree_node.dart';

/// Main Compressed QuadTree class
class CompressedQuadTree {
  late CompressedQuadTreeNode _root;
  final Rectangle boundary;

  CompressedQuadTree(this.boundary) {
    _root = CompressedQuadTreeNode(boundary);
  }

  CompressedQuadTreeNode get root => _root;

  bool insert(QuadTreeParticle particle) {
    return _root.insert(particle);
  }

  void buildFromParticles(
    List<dynamic> particles, // Using dynamic to match original interface
    List<int> visibleParticles,
  ) {
    clear();

    for (final i in visibleParticles) {
      if (i < particles.length) {
        final p = particles[i];
        // Assuming particles have position.dx and position.dy properties
        insert(QuadTreeParticle(i, p.position.dx, p.position.dy));
      }
    }

    // Optimize memory after bulk insertion
    _root.optimizeMemory();
  }

  List<int> queryRange(Rectangle range) {
    return _root.queryRange(range).map((p) => p.index).toList();
  }

  List<int> queryCircle(double centerX, double centerY, double radius) {
    return _root
        .queryCircle(centerX, centerY, radius)
        .map((p) => p.index)
        .toList();
  }

  List<int> findNearbyParticles(double x, double y, double searchRadius) {
    return queryCircle(x, y, searchRadius);
  }

  List<int> getAllParticleIndices() {
    return _root.getAllParticles().map((p) => p.index).toList();
  }

  void clear() {
    _root.clear();
  }

  /// Enhanced statistics with compression metrics
  Map<String, dynamic> getStats() {
    return _root.getStats();
  }

  /// Memory optimization
  void optimize() {
    _root.optimizeMemory();
  }

  /// Rebalance the entire tree
  void rebalance() {
    _root.rebalance();
  }

  /// Check if tree needs rebalancing based on compression metrics
  bool needsRebalancing() {
    final stats = getStats();
    final compressionRatio = stats['compressionRatio'] as double;
    final sparsityRatio = stats['sparsityRatio'] as double;

    // Rebalance if compression is too low or sparsity is too high
    return compressionRatio < 0.1 || sparsityRatio > 0.7;
  }

  void rebuild(List<dynamic> particles, List<int> visibleParticles) {
    buildFromParticles(particles, visibleParticles);
  }
}
