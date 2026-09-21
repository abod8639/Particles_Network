/// Core data structures and logic for the compressed quadtree implementation.
///
/// This library provides the [CompressedQuadTreeNode] and related helper classes
/// like [QuadTreeParticle] and [CompressedPath] to efficiently manage spatial
/// data for the particle network.
library;

import 'dart:math' as math; // For mathematical operations

import 'package:particles_network/src/core/rectangle.dart';

/// Represents a particle with index and 2D coordinates.
class QuadTreeParticle {
  /// Unique identifier or index of the particle.
  final int index;

  /// The x-coordinate of the particle.
  final double x;

  /// The y-coordinate of the particle.
  final double y;

  /// Creates a [QuadTreeParticle] with the given [index] and coordinates ([x], [y]).
  const QuadTreeParticle(this.index, this.x, this.y);
}

/// Enum representing the four quadrants in 2D space.
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
class CompressedQuadTreeNode {
  // Configuration constants
  static const int maxParticles =
      2; // Maximum particles per node before splitting
  static const int maxDepth = 13; // Maximum recursion depth
  static const int minParticlesForCompression = 3; // Threshold for compression

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
  bool get isCompressed => compressedPath != null;
  bool get isLeaf => children.isEmpty;
  bool get hasOnlyOneChild => children.length == 1;

  /// Constructor with boundary, depth and optional compression path
  CompressedQuadTreeNode(this.boundary, [this.depth = 0, this.compressedPath]);

  /// Inserts a particle into the tree with path compression optimization
  /// Returns true if insertion was successful
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

      // If all particles are in one quadrant, use path compression
      if (allSame) {
        // Create compressed child node
        final Rectangle childBoundary = getChildBoundary(newQuad);
        final CompressedPath childPath = compressedPath?.extend(newQuad) ??
            CompressedPath([newQuad], depth + 1);

        final child = CompressedQuadTreeNode(
          childBoundary,
          depth + 1,
          childPath,
        );
        children[newQuad] = child;

        // Move all particles to the compressed child
        for (int i = 0; i < particles.length; i++) {
          child.insert(particles[i]);
        }
        child.insert(particle);
        particles.clear();
        return true;
      } else {
        // Normal subdivision if particles are distributed
        _subdivideNormal();
      }
    }

    // Try to insert into appropriate child if not leaf
    if (!isLeaf) {
      final Quadrant targetQuadrant = _getQuadrant(particle.x, particle.y);
      var child = children[targetQuadrant];
      if (child == null) {
        // Create missing child quadrant if this node was previously compressed
        final Rectangle childBoundary = getChildBoundary(targetQuadrant);
        child = CompressedQuadTreeNode(childBoundary, depth + 1);
        children[targetQuadrant] = child;
      }
      return child.insert(particle);
    }

    // Fallback: store in current node if max depth reached
    particles.add(particle);
    return true;
  }

  /// Performs normal subdivision into 4 quadrants
  void _subdivideNormal() {
    final double halfWidth = boundary.width / 2;
    final double halfHeight = boundary.height / 2;
    final double x = boundary.x;
    final double y = boundary.y;

    // Create all four child quadrants
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

    // Redistribute particles to children
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

    // Keep only particles that couldn't be inserted in children
    particles.clear();
    particles.addAll(remainingParticles);
  }

  /// Determines which quadrant a point belongs to
  Quadrant _getQuadrant(double x, double y) {
    // Calculate midpoint of this node's boundary
    final double midX = boundary.x + boundary.width / 2;
    final double midY = boundary.y + boundary.height / 2;

    // Determine quadrant based on position relative to midpoint
    if (x <= midX && y <= midY) return Quadrant.northWest;
    if (x > midX && y <= midY) return Quadrant.northEast;
    if (x <= midX && y > midY) return Quadrant.southWest;
    return Quadrant.southEast;
  }

  /// Gets the boundary rectangle for a child quadrant
  Rectangle getChildBoundary(Quadrant quadrant) {
    final double halfWidth = boundary.width / 2;
    final double halfHeight = boundary.height / 2;
    final double x = boundary.x;
    final double y = boundary.y;

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

  /// Queries particles within a rectangular area
  List<QuadTreeParticle> queryRange(
    Rectangle range, [
    List<QuadTreeParticle>? found,
  ]) {
    found ??= [];

    // First check if query rectangle intersects this node's boundary
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
