/// Core data structures and logic for the compressed quadtree implementation.
///
/// This library provides the [CompressedQuadTreeNode] and related helper classes
/// like [QuadTreeParticle] and [CompressedPath] to efficiently manage spatial
/// data for the particle network.
library;

import 'dart:math' as math;

import 'package:particles_network/src/core/rectangle.dart';
import 'package:particles_network/src/spatial/compressed_quad_tree.dart';

export 'package:particles_network/src/spatial/compressed_quad_tree.dart'
    show QuadTreeParticle;

/// Enum representing the four quadrants in 2D space.
@Deprecated(
  'QuadTree quadrants are deprecated. Use SortedSpatialGrid instead. '
  'This enum will be removed in particles_network 2.0.0.',
)
enum Quadrant {
  /// The top-left quadrant.
  northWest,

  /// The top-right quadrant.
  northEast,

  /// The bottom-left quadrant.
  southWest,

  /// The bottom-right quadrant.
  southEast,
}

/// Represents a compressed path in the quadtree for optimization
@Deprecated(
  'CompressedPath is deprecated. Use SortedSpatialGrid instead. '
  'This class will be removed in particles_network 2.0.0.',
)
class CompressedPath {
  /// The sequence of quadrants traversed to reach this path.
  final List<Quadrant> path;

  /// The depth of this path in the quadtree structure.
  final int depth;

  /// Creates a new [CompressedPath] with the given [path] and [depth].
  const CompressedPath(this.path, this.depth);

  /// Extends the path with a new quadrant
  CompressedPath extend(Quadrant quad) {
    return CompressedPath([...path, quad], depth + 1);
  }

  @override
  String toString() =>
      'Path: ${path.map((q) => q.name).join('->')} (depth: $depth)';
}

/// A node in the compressed quadtree data structure
@Deprecated(
  'Use SortedSpatialGrid instead. This class will be removed in particles_network 2.0.0.',
)
class CompressedQuadTreeNode {
  // Configuration constants
  /// Maximum particles per node before splitting
  static const int maxParticles = 2;

  /// Maximum recursion depth
  static const int maxDepth = 13;

  /// Threshold for compression
  static const int minParticlesForCompression = 3;

  // Spatial boundaries of this node
  /// The spatial boundary covered by this node.
  final Rectangle boundary;

  /// The depth level of this node in the quadtree.
  final int depth;

  /// The compressed path information, if this node is part of a compressed segment.
  final CompressedPath? compressedPath;

  // Data storage
  /// The list of particles currently stored within this node.
  final List<QuadTreeParticle> particles = [];

  /// The mapping of child quadrants to their corresponding sub-nodes.
  final Map<Quadrant, CompressedQuadTreeNode> children = {};

  // Status flags
  /// Whether this node represents a compressed path.
  bool get isCompressed => compressedPath != null;

  /// Whether this node has no children.
  bool get isLeaf => children.isEmpty;

  /// Whether this node has exactly one child.
  bool get hasOnlyOneChild => children.length == 1;

  /// Constructor with boundary, depth and optional compression path
  CompressedQuadTreeNode(this.boundary, [this.depth = 0, this.compressedPath]);

  /// Inserts a particle into the tree with path compression optimization.
  /// Returns true if insertion was successful.
  bool insert(QuadTreeParticle particle) {
    // First check if particle is within this node's boundary
    if (!boundary.contains(particle.x, particle.y)) return false;

    // If we have capacity and this is a leaf node, store here
    if (particles.length < maxParticles && isLeaf) {
      particles.add(particle);
      return true;
    }

    // At capacity but not at max depth - consider subdivision
    if (isLeaf && depth < maxDepth) {
      final Quadrant newQuad = _getQuadrant(particle.x, particle.y);
      bool allSame = true;
      for (int i = 0; i < particles.length; i++) {
        if (_getQuadrant(particles[i].x, particles[i].y) != newQuad) {
          allSame = false;
          break;
        }
      }

      // Path compression: If all existing and new particle fall into same quadrant,
      // and we have enough particles to justify compression, create compressed path
      if (allSame && particles.length >= minParticlesForCompression) {
        return _insertWithCompression(particle, newQuad);
      }

      // Standard subdivision
      _subdivide();
    }

    // If subdivided or at max depth, try to insert into children
    if (!isLeaf) {
      final Quadrant quad = _getQuadrant(particle.x, particle.y);
      if (children.containsKey(quad)) {
        return children[quad]!.insert(particle);
      }
    }

    // Fallback: Store in this node if we can't subdivide further
    particles.add(particle);
    return true;
  }

  /// Inserts a particle using path compression optimization
  bool _insertWithCompression(QuadTreeParticle particle, Quadrant commonQuad) {
    final List<Quadrant> path = [commonQuad];
    Rectangle currentBounds = _getSubdivisionBoundary(commonQuad);
    int currentDepth = depth + 1;

    // Determine how deep the compression can go
    while (currentDepth < maxDepth) {
      final double midX = currentBounds.x + currentBounds.width / 2;
      final double midY = currentBounds.y + currentBounds.height / 2;

      final Quadrant nextQuad = _getQuadrantForBounds(
        particle.x,
        particle.y,
        midX,
        midY,
      );
      bool allFollow = true;

      for (int i = 0; i < particles.length; i++) {
        if (_getQuadrantForBounds(particles[i].x, particles[i].y, midX, midY) !=
            nextQuad) {
          allFollow = false;
          break;
        }
      }

      if (!allFollow) break;

      path.add(nextQuad);
      currentBounds = _getSubdivisionBoundaryForBounds(nextQuad, currentBounds);
      currentDepth++;
    }

    // Create compressed child node
    final compressedNode = CompressedQuadTreeNode(
      currentBounds,
      currentDepth,
      CompressedPath(path, path.length),
    );

    // Move all particles to the compressed node
    for (int i = 0; i < particles.length; i++) {
      compressedNode.particles.add(particles[i]);
    }
    compressedNode.particles.add(particle);
    particles.clear();

    // Attach to the first quadrant in path
    children[commonQuad] = compressedNode;
    return true;
  }

  /// Subdivides this node into four quadrants
  void _subdivide() {
    final double halfWidth = boundary.width / 2;
    final double halfHeight = boundary.height / 2;
    final double x = boundary.x;
    final double y = boundary.y;

    // Create four child quadrants
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

    // Redistribute existing particles to children
    final List<QuadTreeParticle> oldParticles = List.from(particles);
    particles.clear();

    for (final QuadTreeParticle p in oldParticles) {
      final Quadrant quad = _getQuadrant(p.x, p.y);
      children[quad]!.insert(p);
    }
  }

  /// Determines which quadrant a point falls into relative to this node
  Quadrant _getQuadrant(double px, double py) {
    final double midX = boundary.x + boundary.width / 2;
    final double midY = boundary.y + boundary.height / 2;
    return _getQuadrantForBounds(px, py, midX, midY);
  }

  /// Determines quadrant based on explicit center coordinates
  Quadrant _getQuadrantForBounds(
    double px,
    double py,
    double midX,
    double midY,
  ) {
    final bool west = px < midX;
    final bool north = py < midY;

    if (north) {
      return west ? Quadrant.northWest : Quadrant.northEast;
    } else {
      return west ? Quadrant.southWest : Quadrant.southEast;
    }
  }

  /// Calculates boundary for a specific subdivision quadrant
  Rectangle _getSubdivisionBoundary(Quadrant quad) {
    return _getSubdivisionBoundaryForBounds(quad, boundary);
  }

  /// Calculates subdivision boundary for given parent bounds
  Rectangle _getSubdivisionBoundaryForBounds(
    Quadrant quad,
    Rectangle parentBounds,
  ) {
    final double halfWidth = parentBounds.width / 2;
    final double halfHeight = parentBounds.height / 2;
    final double x = parentBounds.x;
    final double y = parentBounds.y;

    switch (quad) {
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

  /// Queries particles within a rectangular range
  List<QuadTreeParticle> queryRange(
    Rectangle range, [
    List<QuadTreeParticle>? found,
  ]) {
    found ??= [];

    // First check if range intersects this node's boundary
    if (!boundary.intersects(range)) return found;

    // Check particles in this node
    for (final QuadTreeParticle particle in particles) {
      if (range.contains(particle.x, particle.y)) {
        found.add(particle);
      }
    }

    // Recursively query children
    for (final CompressedQuadTreeNode child in children.values) {
      child.queryRange(range, found);
    }

    return found;
  }

  /// Queries particles within a circular area
  List<QuadTreeParticle> queryCircle(
    double centerX,
    double centerY,
    double radius, [
    List<QuadTreeParticle>? found,
  ]) {
    found ??= [];

    // First check if circle intersects this node's boundary
    if (!boundary.intersectsCircle(centerX, centerY, radius)) return found;

    // Pre-calculate squared radius for efficient comparison
    final double radiusSquared = radius * radius;

    // Check particles in this node
    for (final particle in particles) {
      final double dx = particle.x - centerX;
      final double dy = particle.y - centerY;
      if (dx * dx + dy * dy <= radiusSquared) {
        found.add(particle);
      }
    }

    // Recursively query children
    for (final CompressedQuadTreeNode child in children.values) {
      child.queryCircle(centerX, centerY, radius, found);
    }

    return found;
  }

  /// Queries particle indices within a circular area directly into an output list.
  /// Eliminates intermediate object allocations during connection checks.
  void queryCircleIndices(
    double centerX,
    double centerY,
    double radius,
    List<int> output,
  ) {
    // First check if circle intersects this node's boundary
    if (!boundary.intersectsCircle(centerX, centerY, radius)) return;

    // Pre-calculate squared radius for efficient comparison
    final double radiusSquared = radius * radius;

    // Check particles in this node
    for (final particle in particles) {
      final double dx = particle.x - centerX;
      final double dy = particle.y - centerY;
      if (dx * dx + dy * dy <= radiusSquared) {
        output.add(particle.index);
      }
    }

    // Recursively query children
    children.forEach((_, child) {
      child.queryCircleIndices(centerX, centerY, radius, output);
    });
  }

  /// Collects all particles in this subtree
  List<QuadTreeParticle> getAllParticles([
    List<QuadTreeParticle>? allParticles,
  ]) {
    allParticles ??= [];
    allParticles.addAll(particles);

    for (final CompressedQuadTreeNode child in children.values) {
      child.getAllParticles(allParticles);
    }

    return allParticles;
  }

  /// Clears all particles and children from this node
  void clear() {
    particles.clear();
    children.clear();
  }

  /// Gathers statistics about the tree structure
  Map<String, dynamic> getStats() {
    int nodeCount = 1; // Count this node
    int leafCount = isLeaf ? 1 : 0;
    int particleCount = particles.length;
    int currentMaxDepth = depth;
    int compressedNodes = isCompressed ? 1 : 0;
    int sparseNodes = children.length < 4 && !isLeaf ? 1 : 0;

    // Aggregate statistics from children
    for (final CompressedQuadTreeNode child in children.values) {
      final childStats = child.getStats();
      nodeCount += childStats['nodes'] as int;
      leafCount += childStats['leaves'] as int;
      particleCount += childStats['particles'] as int;
      currentMaxDepth = math.max(
        currentMaxDepth,
        childStats['maxDepth'] as int,
      );
      compressedNodes += childStats['compressedNodes'] as int;
      sparseNodes += childStats['sparseNodes'] as int;
    }

    return {
      'nodes': nodeCount,
      'leaves': leafCount,
      'particles': particleCount,
      'maxDepth': currentMaxDepth,
      'compressedNodes': compressedNodes,
      'sparseNodes': sparseNodes,
      'compressionRatio': compressedNodes / nodeCount,
      'sparsityRatio': sparseNodes / nodeCount,
    };
  }

  /// Optimizes memory usage by removing empty leaf nodes
  void optimizeMemory() {
    // Remove empty leaf children
    children.removeWhere((_, child) => child.particles.isEmpty && child.isLeaf);

    // Recursively optimize children
    for (final CompressedQuadTreeNode child in children.values) {
      child.optimizeMemory();
    }
  }

  /// Rebalances the tree by rebuilding its structure
  void rebalance() {
    if (isLeaf) return;

    // Collect all particles from subtree
    final allParticles = getAllParticles();

    // Clear current structure
    clear();

    // Rebuild with optimal structure
    for (final QuadTreeParticle particle in allParticles) {
      insert(particle);
    }
  }
}
