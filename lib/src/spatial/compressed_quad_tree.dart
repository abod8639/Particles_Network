/// Legacy compressed quadtree spatial partitioning structure.
///
/// Deprecated: This structure has been superseded by [SortedSpatialGrid] in 1.9.7+.
/// It is maintained solely for backward compatibility and will be removed in 2.0.0.
library;

import 'package:flutter/foundation.dart';
import 'package:particles_network/src/core/rectangle.dart';

/// Legacy particle representation used by [CompressedQuadTree].
@Deprecated(
  'QuadTreeParticle is deprecated and will be removed in particles_network 2.0.0. '
  'Use Particle directly with SortedSpatialGrid instead.',
)
class QuadTreeParticle {
  /// Index of the particle in the source collection.
  final int index;

  /// X-coordinate of the particle.
  final double x;

  /// Y-coordinate of the particle.
  final double y;

  /// Creates a [QuadTreeParticle].
  const QuadTreeParticle(this.index, this.x, this.y);
}

/// A space-partitioning data structure retained for backward compatibility.
///
/// Deprecated: Superseded by [SortedSpatialGrid] which provides contiguous
/// Structure-of-Arrays (SoA) layout with zero steady-state heap allocations.
/// This class will be removed in particles_network 2.0.0.
@Deprecated(
  'CompressedQuadTree is deprecated and will be removed in particles_network 2.0.0. '
  'Use SortedSpatialGrid instead for zero-allocation spatial partitioning.',
)
class CompressedQuadTree {
  Rectangle _boundary;

  /// Current rectangular boundary.
  Rectangle get boundary => _boundary;

  final List<QuadTreeParticle> _particles = [];
  static bool _warned = false;

  /// Emits a prominent red warning in the console indicating deprecation.
  static void _emitRedWarning() {
    if (!_warned) {
      _warned = true;
      // \x1B[31m = ANSI red foreground, \x1B[0m = ANSI reset
      debugPrint(
        '\x1B[31m'
        '================================================================================\n'
        '[particles_network DEPRECATION WARNING]\n'
        'CompressedQuadTree is deprecated and will be removed in particles_network 2.0.0.\n'
        'This API is no longer active in the rendering engine.\n'
        'Please migrate your code to SortedSpatialGrid for zero-allocation performance.\n'
        '================================================================================'
        '\x1B[0m',
      );
    }
  }

  /// Creates a [CompressedQuadTree] with the given [boundary].
  CompressedQuadTree(Rectangle boundary) : _boundary = boundary {
    _emitRedWarning();
  }

  /// Updates tree boundary.
  void updateBoundary(Rectangle newBoundary) {
    _boundary = newBoundary;
  }

  /// Inserts a particle into the tree.
  bool insert(QuadTreeParticle particle) {
    _particles.add(particle);
    return true;
  }

  /// Bulk builds the tree from a list of particles and visible indices.
  void buildFromParticles(
    List<dynamic> particles,
    List<int> visibleParticles,
  ) {
    clear();
    for (final i in visibleParticles) {
      if (i < particles.length) {
        final p = particles[i];
        insert(QuadTreeParticle(i, p.x as double, p.y as double));
      }
    }
  }

  /// Queries particles within a circular area defined by ([centerX], [centerY]) and [radius].
  List<int> queryCircle(double centerX, double centerY, double radius) {
    _emitRedWarning();
    final double rSq = radius * radius;
    final results = <int>[];
    for (final p in _particles) {
      final dx = p.x - centerX;
      final dy = p.y - centerY;
      if (dx * dx + dy * dy <= rSq) {
        results.add(p.index);
      }
    }
    return results;
  }

  /// Finds nearby particles within [searchRadius] and fills [output].
  void findNearbyParticlesToOutput(
    double x,
    double y,
    double searchRadius,
    List<int> output,
  ) {
    output.clear();
    output.addAll(queryCircle(x, y, searchRadius));
  }

  /// Finds nearby particles within [searchRadius].
  List<int> findNearbyParticles(double x, double y, double searchRadius) {
    return queryCircle(x, y, searchRadius);
  }

  /// Queries particles within a rectangular [range].
  List<int> queryRange(Rectangle range) {
    _emitRedWarning();
    final results = <int>[];
    for (final p in _particles) {
      if (range.contains(p.x, p.y)) {
        results.add(p.index);
      }
    }
    return results;
  }

  /// Gets indices of all particles stored in the tree.
  List<int> getAllParticleIndices() {
    return _particles.map((p) => p.index).toList();
  }

  /// Clears all particles.
  void clear() {
    _particles.clear();
  }

  /// Returns legacy performance and node statistics.
  Map<String, dynamic> getStats() {
    return {
      'totalParticles': _particles.length,
      'deprecated': true,
    };
  }

  /// Compatibility no-op for memory optimization.
  void optimize() {}

  /// Compatibility no-op for rebalancing.
  void rebalance() {}

  /// Checks if rebalancing is needed (always false in compatibility shim).
  bool needsRebalancing() => false;

  /// Rebuilds tree from particle data.
  void rebuild(List<dynamic> particles, List<int> visibleParticles) {
    buildFromParticles(particles, visibleParticles);
  }
}
