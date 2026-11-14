/// Standard canonical 2D QuadTree implementation for spatial partitioning.
///
/// Provides [StandardQuadTree] and [StandardQuadTreeNode] for benchmarking
/// and comparing against [SortedSpatialGrid] and [CompressedQuadTree].
library;

import 'package:particles_network/src/core/particle.dart';
import 'package:particles_network/src/legacy/legacy_deprecation_logger.dart';

/// A classical pointer-based QuadTree partitioning 2D space recursively.
@Deprecated(
  'StandardQuadTree is provided for benchmarking comparisons only. '
  'Use SortedSpatialGrid for production particle networks. Scheduled for removal in particles_network 2.0.0.',
)
class StandardQuadTree {
  StandardQuadTreeNode? _root;
  double width;
  double height;
  final int nodeCapacity;
  final int maxDepth;

  StandardQuadTree({
    required this.width,
    required this.height,
    this.nodeCapacity = 8,
    this.maxDepth = 10,
  }) {
    LegacyDeprecationLogger.warn(
      deprecatedApi: 'StandardQuadTree',
      replacement: 'SortedSpatialGrid',
    );
  }

  /// Rebuilds the quadtree with visible particles within [width] x [height].
  void build(List<Particle> particles, List<int> visible) {
    if (width <= 0 || height <= 0 || visible.isEmpty) {
      _root = null;
      return;
    }
    _root = StandardQuadTreeNode(
      0.0,
      0.0,
      width,
      height,
      0,
      nodeCapacity,
      maxDepth,
    );
    for (int i = 0; i < visible.length; i++) {
      final int idx = visible[i];
      if (idx < 0 || idx >= particles.length) continue;
      final Particle p = particles[idx];
      if (!p.x.isFinite || !p.y.isFinite) continue;
      final double px = p.x.clamp(0.0, width);
      final double py = p.y.clamp(0.0, height);
      _root!.insert(idx, px, py);
    }
  }

  /// Queries all particles within Euclidean distance [radius] of point ([x], [y]).
  void queryRadius(
    double x,
    double y,
    double radius,
    void Function(int index, double px, double py, double distSq) visitor,
  ) {
    if (_root == null ||
        radius <= 0 ||
        !radius.isFinite ||
        !x.isFinite ||
        !y.isFinite) {
      return;
    }
    _root!.queryRadius(x, y, radius, radius * radius, visitor);
  }

  /// Queries particles into an output index list.
  void queryRadiusIndices(
    double x,
    double y,
    double radius,
    List<int> output,
  ) {
    if (_root == null ||
        radius <= 0 ||
        !radius.isFinite ||
        !x.isFinite ||
        !y.isFinite) {
      return;
    }
    _root!.queryRadiusIndices(x, y, radius, radius * radius, output);
  }

  /// Clears the tree structure.
  void clear() {
    _root = null;
  }
}

/// A node in the [StandardQuadTree].
@Deprecated(
  'StandardQuadTreeNode is provided for benchmarking comparisons only. '
  'Use SortedSpatialGrid for production particle networks. Scheduled for removal in particles_network 2.0.0.',
)
class StandardQuadTreeNode {
  final double minX;
  final double minY;
  final double maxX;
  final double maxY;
  final double midX;
  final double midY;
  final int depth;
  final int capacity;
  final int maxDepth;

  final List<int> indices = [];
  final List<double> xs = [];
  final List<double> ys = [];

  StandardQuadTreeNode? nw;
  StandardQuadTreeNode? ne;
  StandardQuadTreeNode? sw;
  StandardQuadTreeNode? se;

  bool get isLeaf => nw == null;

  StandardQuadTreeNode(
    this.minX,
    this.minY,
    this.maxX,
    this.maxY,
    this.depth,
    this.capacity,
    this.maxDepth,
  )   : midX = (minX + maxX) * 0.5,
        midY = (minY + maxY) * 0.5;

  /// Inserts a particle into this node or its children.
  bool insert(int index, double x, double y) {
    if (x < minX || x > maxX || y < minY || y > maxY) {
      return false;
    }

    if (isLeaf) {
      if (indices.length < capacity || depth >= maxDepth) {
        indices.add(index);
        xs.add(x);
        ys.add(y);
        return true;
      }
      _subdivide();
    }

    // Insert into appropriate child
    if (x <= midX) {
      if (y <= midY) {
        return nw!.insert(index, x, y);
      } else {
        return sw!.insert(index, x, y);
      }
    } else {
      if (y <= midY) {
        return ne!.insert(index, x, y);
      } else {
        return se!.insert(index, x, y);
      }
    }
  }

  void _subdivide() {
    nw = StandardQuadTreeNode(
      minX,
      minY,
      midX,
      midY,
      depth + 1,
      capacity,
      maxDepth,
    );
    ne = StandardQuadTreeNode(
      midX,
      minY,
      maxX,
      midY,
      depth + 1,
      capacity,
      maxDepth,
    );
    sw = StandardQuadTreeNode(
      minX,
      midY,
      midX,
      maxY,
      depth + 1,
      capacity,
      maxDepth,
    );
    se = StandardQuadTreeNode(
      midX,
      midY,
      maxX,
      maxY,
      depth + 1,
      capacity,
      maxDepth,
    );

    for (int i = 0; i < indices.length; i++) {
      final int idx = indices[i];
      final double px = xs[i];
      final double py = ys[i];
      if (px <= midX) {
        if (py <= midY) {
          nw!.insert(idx, px, py);
        } else {
          sw!.insert(idx, px, py);
        }
      } else {
        if (py <= midY) {
          ne!.insert(idx, px, py);
        } else {
          se!.insert(idx, px, py);
        }
      }
    }
    indices.clear();
    xs.clear();
    ys.clear();
  }

  /// Traverses intersecting nodes and executes [visitor] for matching particles.
  void queryRadius(
    double qx,
    double qy,
    double radius,
    double radiusSq,
    void Function(int index, double px, double py, double distSq) visitor,
  ) {
    // AABB vs Circle intersection test
    double closestX = qx;
    if (closestX < minX) {
      closestX = minX;
    } else if (closestX > maxX) {
      closestX = maxX;
    }

    double closestY = qy;
    if (closestY < minY) {
      closestY = minY;
    } else if (closestY > maxY) {
      closestY = maxY;
    }

    final double dX = qx - closestX;
    final double dY = qy - closestY;
    if (dX * dX + dY * dY > radiusSq) {
      return;
    }

    if (isLeaf) {
      final int count = indices.length;
      for (int i = 0; i < count; i++) {
        final double px = xs[i];
        final double dx = qx - px;
        if (dx > radius || dx < -radius) continue;

        final double py = ys[i];
        final double dy = qy - py;
        if (dy > radius || dy < -radius) continue;

        final double distSq = dx * dx + dy * dy;
        if (distSq <= radiusSq) {
          visitor(indices[i], px, py, distSq);
        }
      }
      return;
    }

    nw?.queryRadius(qx, qy, radius, radiusSq, visitor);
    ne?.queryRadius(qx, qy, radius, radiusSq, visitor);
    sw?.queryRadius(qx, qy, radius, radiusSq, visitor);
    se?.queryRadius(qx, qy, radius, radiusSq, visitor);
  }

  /// Traverses intersecting nodes and collects indices into [output].
  void queryRadiusIndices(
    double qx,
    double qy,
    double radius,
    double radiusSq,
    List<int> output,
  ) {
    double closestX = qx;
    if (closestX < minX) {
      closestX = minX;
    } else if (closestX > maxX) {
      closestX = maxX;
    }

    double closestY = qy;
    if (closestY < minY) {
      closestY = minY;
    } else if (closestY > maxY) {
      closestY = maxY;
    }

    final double dX = qx - closestX;
    final double dY = qy - closestY;
    if (dX * dX + dY * dY > radiusSq) {
      return;
    }

    if (isLeaf) {
      final int count = indices.length;
      for (int i = 0; i < count; i++) {
        final double px = xs[i];
        final double dx = qx - px;
        if (dx > radius || dx < -radius) continue;

        final double py = ys[i];
        final double dy = qy - py;
        if (dy > radius || dy < -radius) continue;

        final double distSq = dx * dx + dy * dy;
        if (distSq <= radiusSq) {
          output.add(indices[i]);
        }
      }
      return;
    }

    nw?.queryRadiusIndices(qx, qy, radius, radiusSq, output);
    ne?.queryRadiusIndices(qx, qy, radius, radiusSq, output);
    sw?.queryRadiusIndices(qx, qy, radius, radiusSq, output);
    se?.queryRadiusIndices(qx, qy, radius, radiusSq, output);
  }
}
