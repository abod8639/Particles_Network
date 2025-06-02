import 'dart:math' as math;

import 'package:particles_network/model/rectangle.dart';

/// Represents a rectangular boundary in 2D space with utility methods

/// Represents a particle with its index and positionQuadTreeParticle
class QuadTreeParticle {
  final int index;
  final double x, y;

  const QuadTreeParticle(this.index, this.x, this.y);
}

/// Enum to represent quadrant directions
enum Quadrant { northWest, northEast, southWest, southEast }

/// Compressed path representation for path compression
class CompressedPath {
  final List<Quadrant> path;
  final int depth;

  const CompressedPath(this.path, this.depth);

  CompressedPath extend(Quadrant quad) {
    return CompressedPath([...path, quad], depth + 1);
  }

  @override
  String toString() =>
      'Path: ${path.map((q) => q.name).join('->')} (depth: $depth)';
}

/// A compressed node in the QuadTree data structure
class CompressedQuadTreeNode {
  static const int maxParticles = 2;
  static const int maxDepth = 13;
  static const int minParticlesForCompression =
      3; // Minimum particles to justify compression

  final Rectangle boundary;
  final int depth;
  final CompressedPath? compressedPath; // Path compression information

  // Storage options
  final List<QuadTreeParticle> particles = [];

  // Children - using a Map for sparse representation
  final Map<Quadrant, CompressedQuadTreeNode> children = {};

  // Compression flags
  bool get isCompressed => compressedPath != null;
  bool get isLeaf => children.isEmpty;
  bool get hasOnlyOneChild => children.length == 1;

  CompressedQuadTreeNode(this.boundary, [this.depth = 0, this.compressedPath]);

  /// Insert particle with path compression optimization
  bool insert(QuadTreeParticle particle) {
    if (!boundary.contains(particle.x, particle.y)) return false;

    // If we can store here and don't need subdivision
    if (particles.length < maxParticles && isLeaf) {
      particles.add(particle);
      return true;
    }

    // Check if we should compress this path before subdividing
    if (isLeaf && depth < maxDepth) {
      _subdivideWithCompression();
    }

    // Try to insert into appropriate child
    if (!isLeaf) {
      final targetQuadrant = _getQuadrant(particle.x, particle.y);
      if (children.containsKey(targetQuadrant)) {
        return children[targetQuadrant]!.insert(particle);
      } else {
        // Create compressed child if needed
        final childBoundary = _getChildBoundary(targetQuadrant);
        final childPath =
            compressedPath?.extend(targetQuadrant) ??
            CompressedPath([targetQuadrant], depth + 1);

        children[targetQuadrant] = CompressedQuadTreeNode(
          childBoundary,
          depth + 1,
          childPath,
        );
        return children[targetQuadrant]!.insert(particle);
      }
    }

    // Fallback: store in current node if max depth reached
    particles.add(particle);
    return true;
  }

  /// Subdivide with path compression optimization
  void _subdivideWithCompression() {
    if (particles.length < minParticlesForCompression) {
      // Don't compress if we have too few particles
      _subdivideNormal();
      return;
    }

    // Group particles by quadrant to identify compression opportunities
    final Map<Quadrant, List<QuadTreeParticle>> quadrantGroups = {};

    for (final particle in particles) {
      final quad = _getQuadrant(particle.x, particle.y);
      quadrantGroups.putIfAbsent(quad, () => []).add(particle);
    }

    // Create children only for quadrants that have particles
    for (final entry in quadrantGroups.entries) {
      final quadrant = entry.key;
      final quadParticles = entry.value;

      final childBoundary = _getChildBoundary(quadrant);
      final childPath =
          compressedPath?.extend(quadrant) ??
          CompressedPath([quadrant], depth + 1);

      final child = CompressedQuadTreeNode(childBoundary, depth + 1, childPath);

      // Add particles to child
      for (final particle in quadParticles) {
        child.insert(particle);
      }

      children[quadrant] = child;
    }

    particles.clear();
  }

  /// Normal subdivision (creates all 4 children)
  void _subdivideNormal() {
    final halfWidth = boundary.width / 2;
    final halfHeight = boundary.height / 2;
    final x = boundary.x;
    final y = boundary.y;

    // Create all four children
    children[Quadrant.northWest] = CompressedQuadTreeNode(
      Rectangle(x, y, halfWidth, halfHeight),
      depth + 1,
    );
    children[Quadrant.northEast] = CompressedQuadTreeNode(
      Rectangle(x + halfWidth, y, halfWidth, halfHeight),
      depth + 1,
    );
    children[Quadrant.southWest] = CompressedQuadTreeNode(
      Rectangle(x, y + halfHeight, halfWidth, halfHeight),
      depth + 1,
    );
    children[Quadrant.southEast] = CompressedQuadTreeNode(
      Rectangle(x + halfWidth, y + halfHeight, halfWidth, halfHeight),
      depth + 1,
    );

    // Redistribute particles
    final remainingParticles = <QuadTreeParticle>[];

    for (final particle in particles) {
      bool inserted = false;
      for (final child in children.values) {
        if (child.insert(particle)) {
          inserted = true;
          break;
        }
      }
      if (!inserted) {
        remainingParticles.add(particle);
      }
    }

    particles.clear();
    particles.addAll(remainingParticles);
  }

  /// Get quadrant for a point
  Quadrant _getQuadrant(double x, double y) {
    final midX = boundary.x + boundary.width / 2;
    final midY = boundary.y + boundary.height / 2;

    if (x <= midX && y <= midY) return Quadrant.northWest;
    if (x > midX && y <= midY) return Quadrant.northEast;
    if (x <= midX && y > midY) return Quadrant.southWest;
    return Quadrant.southEast;
  }

  /// Get boundary for a child quadrant
  Rectangle _getChildBoundary(Quadrant quadrant) {
    final halfWidth = boundary.width / 2;
    final halfHeight = boundary.height / 2;
    final x = boundary.x;
    final y = boundary.y;

    switch (quadrant) {
      case Quadrant.northWest:
        return Rectangle(x, y, halfWidth, halfHeight);
      case Quadrant.northEast:
        return Rectangle(x + halfWidth, y, halfWidth, halfHeight);
      case Quadrant.southWest:
        return Rectangle(x, y + halfHeight, halfWidth, halfHeight);
      case Quadrant.southEast:
        return Rectangle(x + halfWidth, y + halfHeight, halfWidth, halfHeight);
    }
  }

  /// Query range with compression awareness
  List<QuadTreeParticle> queryRange(
    Rectangle range, [
    List<QuadTreeParticle>? found,
  ]) {
    found ??= [];

    if (!boundary.intersects(range)) return found;

    // Check particles in this node
    for (final particle in particles) {
      if (range.contains(particle.x, particle.y)) {
        found.add(particle);
      }
    }

    // Query existing children only (sparse representation)
    for (final child in children.values) {
      child.queryRange(range, found);
    }

    return found;
  }

  /// Query circle with compression awareness
  List<QuadTreeParticle> queryCircle(
    double centerX,
    double centerY,
    double radius, [
    List<QuadTreeParticle>? found,
  ]) {
    found ??= [];

    if (!boundary.intersectsCircle(centerX, centerY, radius)) return found;

    final radiusSquared = radius * radius;

    // Check particles in this node
    for (final particle in particles) {
      final dx = particle.x - centerX;
      final dy = particle.y - centerY;
      if (dx * dx + dy * dy <= radiusSquared) {
        found.add(particle);
      }
    }

    // Query existing children only
    for (final child in children.values) {
      child.queryCircle(centerX, centerY, radius, found);
    }

    return found;
  }

  /// Get all particles including compressed paths
  List<QuadTreeParticle> getAllParticles([
    List<QuadTreeParticle>? allParticles,
  ]) {
    allParticles ??= [];
    allParticles.addAll(particles);

    for (final child in children.values) {
      child.getAllParticles(allParticles);
    }

    return allParticles;
  }

  /// Clear with compression cleanup
  void clear() {
    particles.clear();
    children.clear();
  }

  /// Get comprehensive statistics including compression info
  Map<String, dynamic> getStats() {
    int nodeCount = 1;
    int leafCount = isLeaf ? 1 : 0;
    int particleCount = particles.length;
    int maxDepth = depth;
    int compressedNodes = isCompressed ? 1 : 0;
    int sparseNodes = children.length < 4 && !isLeaf ? 1 : 0;

    for (final child in children.values) {
      final childStats = child.getStats();
      nodeCount += childStats['nodes'] as int;
      leafCount += childStats['leaves'] as int;
      particleCount += childStats['particles'] as int;
      maxDepth = math.max(maxDepth, childStats['maxDepth'] as int);
      compressedNodes += childStats['compressedNodes'] as int;
      sparseNodes += childStats['sparseNodes'] as int;
    }

    return {
      'nodes': nodeCount,
      'leaves': leafCount,
      'particles': particleCount,
      'maxDepth': maxDepth,
      'compressedNodes': compressedNodes,
      'sparseNodes': sparseNodes,
      'compressionRatio': compressedNodes / nodeCount,
      'sparsityRatio': sparseNodes / nodeCount,
    };
  }

  /// Memory optimization: Remove empty children
  void optimizeMemory() {
    children.removeWhere((_, child) => child.particles.isEmpty && child.isLeaf);

    for (final child in children.values) {
      child.optimizeMemory();
    }
  }

  /// Advanced: Rebalance tree with compression
  void rebalance() {
    if (isLeaf) return;

    // Collect all particles from subtree
    final allParticles = getAllParticles();

    // Clear current structure
    clear();

    // Reinsert with new compression strategy
    for (final particle in allParticles) {
      insert(particle);
    }
  }
}
