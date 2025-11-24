import 'dart:math' as math; // For mathematical operations

import 'package:particles_network/model/rectangle.dart';

/// Represents a particle with index and 2D coordinates
class QuadTreeParticle {
  final int index; // Unique identifier for the particle
  final double x, y; // Spatial coordinates

  const QuadTreeParticle(this.index, this.x, this.y);
}

/// Enum representing the four quadrants in 2D space
enum Quadrant { northWest, northEast, southWest, southEast }

/// Represents a compressed path in the quadtree for optimization
class CompressedPath {
  final List<Quadrant> path; // Sequence of quadrant traversals
  final int depth; // Depth in the tree

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
/// 
/// Optimizations:
/// - Cached midpoint coordinates for faster quadrant determination
/// - Pre-calculated child boundaries for faster subdivision
/// - Lazy initialization of expensive calculations
class CompressedQuadTreeNode {
  // Configuration constants
  static const int maxParticles =
      2; // Maximum particles per node before splitting
  static const int maxDepth = 13; // Maximum recursion depth
  static const int minParticlesForCompression = 3; // Threshold for compression

  // Spatial boundaries of this node
  final Rectangle boundary;
  final int depth; // Current depth in the tree
  final CompressedPath? compressedPath; // Compression information

  // Cached calculations for performance
  late final double midX = boundary.x + boundary.width / 2;
  late final double midY = boundary.y + boundary.height / 2;
  late final double halfWidth = boundary.width / 2;
  late final double halfHeight = boundary.height / 2;
  
  // Pre-calculated child boundaries (lazy initialization)
  late final Map<Quadrant, Rectangle> _childBoundaries = {
    Quadrant.northWest: Rectangle(boundary.x, boundary.y, halfWidth, halfHeight),
    Quadrant.northEast: Rectangle(boundary.x + halfWidth, boundary.y, halfWidth, halfHeight),
    Quadrant.southWest: Rectangle(boundary.x, boundary.y + halfHeight, halfWidth, halfHeight),
    Quadrant.southEast: Rectangle(boundary.x + halfWidth, boundary.y + halfHeight, halfWidth, halfHeight),
  };

  // Data storage
  final List<QuadTreeParticle> particles = []; // Particles in this node
  final Map<Quadrant, CompressedQuadTreeNode> children = {}; // Child nodes

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
      // Temporary collection of all particles including new one
      final List<QuadTreeParticle> allParticles = [...particles, particle];

      // Group particles by which quadrant they would fall into
      final Map<Quadrant, List<QuadTreeParticle>> groups = {};
      for (final p in allParticles) {
        final Quadrant quad = _getQuadrant(p.x, p.y);
        groups.putIfAbsent(quad, () => []).add(p);
      }

      // Find the quadrant with most particles (dominant quadrant)
      var maxCount = 0;
      Quadrant? dominantQuad;
      for (final entry in groups.entries) {
        if (entry.value.length > maxCount) {
          maxCount = entry.value.length;
          dominantQuad = entry.key;
        }
      }

      // If all particles are in one quadrant, use path compression
      if (dominantQuad != null && maxCount == allParticles.length) {
        // Create compressed child node
        final Rectangle childBoundary = getChildBoundary(dominantQuad);
        final CompressedPath childPath =
            compressedPath?.extend(dominantQuad) ??
            CompressedPath([dominantQuad], depth + 1);

        children[dominantQuad] = CompressedQuadTreeNode(
          childBoundary,
          depth + 1,
          childPath,
        );

        // Move all particles to the compressed child
        for (final p in allParticles) {
          children[dominantQuad]!.insert(p);
        }
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
      return children[targetQuadrant]?.insert(particle) ?? false;
    }

    // Fallback: store in current node if max depth reached
    particles.add(particle);
    return true;
  }

  /// Performs normal subdivision into 4 quadrants
  /// Uses pre-calculated child boundaries for better performance
  void _subdivideNormal() {
    // Create all four child quadrants using cached boundaries
    children[Quadrant.northWest] = CompressedQuadTreeNode(
      _childBoundaries[Quadrant.northWest]!,
      depth + 1,
    );
    children[Quadrant.northEast] = CompressedQuadTreeNode(
      _childBoundaries[Quadrant.northEast]!,
      depth + 1,
    );
    children[Quadrant.southWest] = CompressedQuadTreeNode(
      _childBoundaries[Quadrant.southWest]!,
      depth + 1,
    );
    children[Quadrant.southEast] = CompressedQuadTreeNode(
      _childBoundaries[Quadrant.southEast]!,
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
  /// Uses cached midpoint coordinates for better performance
  Quadrant _getQuadrant(double x, double y) {
    // Use pre-calculated midpoint coordinates
    if (x <= midX && y <= midY) return Quadrant.northWest;
    if (x > midX && y <= midY) return Quadrant.northEast;
    if (x <= midX && y > midY) return Quadrant.southWest;
    return Quadrant.southEast;
  }

  /// Gets the boundary rectangle for a child quadrant
  /// Returns pre-calculated boundary for optimal performance
  Rectangle getChildBoundary(Quadrant quadrant) {
    return _childBoundaries[quadrant]!;
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
