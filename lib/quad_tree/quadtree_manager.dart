// File: compressed_quadtree_manager.dart

import 'dart:math' as math;

import 'package:particles_network/model/rectangle.dart';
import 'package:particles_network/quad_tree/compressed_quad_tree.dart';

/// Enhanced Manager class for Compressed QuadTree with advanced optimization
///
/// This manager provides additional features for compressed quadtrees:
/// 1. Adaptive compression based on particle distribution
/// 2. Memory optimization and rebalancing
/// 3. Performance monitoring and auto-tuning
/// 4. Advanced query strategies
///
/// Helper class for circle queries
class CircleQuery {
  final double x, y, radius;
  const CircleQuery(this.x, this.y, this.radius);
}

class CompressedQuadTreeManager {
  CompressedQuadTree? _quadTree;
  Rectangle? _worldBounds;

  // Performance tracking
  int _queryCount = 0;
  int _insertCount = 0;
  DateTime? _lastOptimization;

  // Adaptive parameters
  double _compressionThreshold = .3;
  final int _optimizationInterval = 1000; // operations between optimizations

  /// Initialize with enhanced bounds calculation
  void initialize(double minX, double minY, double maxX, double maxY) {
    _worldBounds = Rectangle(minX, minY, maxX - minX, maxY - minY);
    _quadTree = CompressedQuadTree(_worldBounds!);
    _resetPerformanceCounters();
  }

  /// Build tree with compression optimization
  void buildTree(List<dynamic> particles, List<int> visibleParticles) {
    if (_quadTree == null) {
      _initializeFromParticles(particles, visibleParticles);
    }

    _quadTree!.buildFromParticles(particles, visibleParticles);
    _insertCount += visibleParticles.length;

    // Auto-optimize if needed
    _checkAutoOptimization();
  }

  /// Enhanced initialization with adaptive bounds
  void _initializeFromParticles(
    List<dynamic> particles,
    List<int> visibleParticles,
  ) {
    if (visibleParticles.isEmpty) {
      initialize(-1, -1, 1, 1);
      return;
    }

    // Calculate bounds with statistical analysis
    final positions =
        visibleParticles
            .where((i) => i < particles.length)
            .map((i) => particles[i])
            .toList();

    if (positions.isEmpty) {
      initialize(-1, -1, 1, 1);
      return;
    }

    // Basic bounds
    double minX = positions.first.position.dx;
    double minY = positions.first.position.dy;
    double maxX = minX;
    double maxY = minY;

    for (final p in positions) {
      minX = math.min(minX, p.position.dx);
      minY = math.min(minY, p.position.dy);
      maxX = math.max(maxX, p.position.dx);
      maxY = math.max(maxY, p.position.dy);
    }

    // Adaptive padding based on particle distribution
    final width = maxX - minX;
    final height = maxY - minY;
    final avgDimension = (width + height) / 2;

    double padding = avgDimension * 0.15; // 15% padding
    padding = math.max(padding, 1.0);

    // Ensure minimum useful size
    if (width < padding) {
      final center = minX + width / 2;
      minX = center - padding / 2;
      maxX = center + padding / 2;
    }

    if (height < padding) {
      final center = minY + height / 2;
      minY = center - padding / 2;
      maxY = center + padding / 2;
    }

    initialize(minX - padding, minY - padding, maxX + padding, maxY + padding);
  }

  /// Optimized rectangular query with performance tracking
  List<int> queryRectangle(double x, double y, double width, double height) {
    if (_quadTree == null) return const [];

    _queryCount++;

    // استخدام final لتوضيح أن المتغير لن يتغير بعد إنشائه
    final searchArea = Rectangle(x, y, width, height);

    return _quadTree!.queryRange(searchArea);
  }

  /// Optimized circular query with caching hints
  List<int> queryCircle(double centerX, double centerY, double radius) {
    if (_quadTree == null) return [];

    _queryCount++;
    return _quadTree!.queryCircle(centerX, centerY, radius);
  }

  /// Enhanced nearby particle search with adaptive radius
  List<int> findNearbyParticles(dynamic particle, double searchRadius) {
    if (_quadTree == null) return [];

    // Adaptive search radius based on tree density
    final stats = getTreeStats();
    final particleDensity = stats['particles'] / stats['nodes'];
    final adaptiveRadius = searchRadius * (1.0 + particleDensity / 100.0);

    List<int> nearby = _quadTree!.findNearbyParticles(
      particle.position.dx,
      particle.position.dy,
      adaptiveRadius,
    );

    return nearby;
  }

  /// Advanced collision detection with spatial optimization
  List<int> getCollisionCandidates(
    int particleIndex,
    List<dynamic> particles,
    double collisionRadius,
  ) {
    if (_quadTree == null || particleIndex >= particles.length) return [];

    final targetParticle = particles[particleIndex];

    // Use hierarchical search for better performance
    List<int> candidates = queryCircle(
      targetParticle.position.dx,
      targetParticle.position.dy,
      collisionRadius,
    );

    candidates.removeWhere((index) => index == particleIndex);
    return candidates;
  }

  /// Intelligent tree update with selective rebuilding
  void updateTree(List<dynamic> particles, List<int> visibleParticles) {
    if (_quadTree == null) {
      buildTree(particles, visibleParticles);
      return;
    }

    // Check if we should rebuild or just optimize
    if (_shouldRebuildTree()) {
      buildTree(particles, visibleParticles);
    } else {
      // Incremental update (simplified approach)
      _quadTree!.optimize();
    }
  }

  /// Enhanced statistics with compression metrics
  Map<String, dynamic> getTreeStats() {
    if (_quadTree == null) {
      return {
        'nodes': 0,
        'leaves': 0,
        'particles': 0,
        'maxDepth': 0,
        'compressedNodes': 0,
        'sparseNodes': 0,
        'compressionRatio': 0.0,
        'sparsityRatio': 0.0,
      };
    }

    final stats = _quadTree!.getStats();

    // Add performance metrics
    stats['queryCount'] = _queryCount;
    stats['insertCount'] = _insertCount;
    stats['avgQueriesPerNode'] =
        _queryCount / math.max(1, stats['nodes'] as int);

    return stats;
  }

  /// Performance monitoring and auto-tuning
  void _checkAutoOptimization() {
    final totalOperations = _queryCount + _insertCount;

    if (totalOperations >= _optimizationInterval) {
      _performAutoOptimization();
      _resetPerformanceCounters();
      _lastOptimization = DateTime.now();
    }
  }

  /// Perform automatic optimization based on usage patterns
  void _performAutoOptimization() {
    if (_quadTree == null) return;

    final stats = _quadTree!.getStats();
    final compressionRatio = stats['compressionRatio'] as double;
    final sparsityRatio = stats['sparsityRatio'] as double;

    // Adjust compression threshold based on performance
    if (compressionRatio < 0.2 && _queryCount > _insertCount) {
      // Query-heavy workload, optimize for search
      _compressionThreshold *= 0.9;
      _quadTree!.rebalance();
    } else if (sparsityRatio > 0.6 && _insertCount > _queryCount) {
      // Insert-heavy workload, optimize for updates
      _compressionThreshold *= 1.1;
      _quadTree!.optimize();
    }

    // Memory optimization
    _quadTree!.optimize();
  }

  /// Advanced rebuild decision logic
  bool _shouldRebuildTree() {
    if (_quadTree == null) return true;

    final stats = _quadTree!.getStats();
    final maxDepth = stats['maxDepth'] as int;
    final compressionRatio = stats['compressionRatio'] as double;
    final sparsityRatio = stats['sparsityRatio'] as double;

    // Multiple criteria for rebuilding
    return maxDepth > 12 ||
        compressionRatio < 0.1 ||
        sparsityRatio > 0.8 ||
        _quadTree!.needsRebalancing();
  }

  /// Reset performance counters
  void _resetPerformanceCounters() {
    _queryCount = 0;
    _insertCount = 0;
  }

  /// Manual optimization trigger
  void optimizeTree() {
    _quadTree?.optimize();
  }

  /// Manual rebalancing trigger
  void rebalanceTree() {
    _quadTree?.rebalance();
  }

  /// Advanced multi-query optimization
  List<int> queryMultipleCircles(List<CircleQuery> circles) {
    if (_quadTree == null) return [];

    // Optimize overlapping queries
    final optimizedCircles = _optimizeCircleQueries(circles);

    Set<int> allResults = <int>{};
    for (final circle in optimizedCircles) {
      final results = queryCircle(circle.x, circle.y, circle.radius);
      allResults.addAll(results);
    }

    return allResults.toList();
  }

  /// Optimize overlapping circle queries
  List<CircleQuery> _optimizeCircleQueries(List<CircleQuery> circles) {
    if (circles.length <= 1) return circles;

    final optimized = <CircleQuery>[];
    final processed = <bool>[...List.filled(circles.length, false)];

    for (int i = 0; i < circles.length; i++) {
      if (processed[i]) continue;

      CircleQuery current = circles[i];
      processed[i] = true;

      // Try to merge with nearby circles
      for (int j = i + 1; j < circles.length; j++) {
        if (processed[j]) continue;

        final other = circles[j];
        if (_circlesOverlap(current, other)) {
          current = _mergeCircles(current, other);
          processed[j] = true;
        }
      }

      optimized.add(current);
    }

    return optimized;
  }

  /// Check if two circles overlap significantly
  bool _circlesOverlap(CircleQuery a, CircleQuery b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    final distance = math.sqrt(dx * dx + dy * dy);
    final radiusSum = a.radius + b.radius;

    return distance < radiusSum * 0.8; // 80% overlap threshold
  }

  /// Merge two overlapping circles into one larger circle
  CircleQuery _mergeCircles(CircleQuery a, CircleQuery b) {
    // final dx = b.x - a.x;
    // final dy = b.y - a.y;
    final totalWeight = a.radius + b.radius;

    final centerX = (a.x * a.radius + b.x * b.radius) / totalWeight;
    final centerY = (a.y * a.radius + b.y * b.radius) / totalWeight;

    // أبسط طريقة لتوسيع نصف القطر بعد الدمج: اجمع نصفي القطر مع معامل تصحيح
    final newRadius = (a.radius + b.radius) * 0.6;

    return CircleQuery(centerX, centerY, newRadius);
  }

  /// Get performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    final stats = getTreeStats();
    return {
      ...stats,
      'compressionThreshold': _compressionThreshold,
      'optimizationInterval': _optimizationInterval,
      'lastOptimization': _lastOptimization?.toIso8601String() ?? 'Never',
      'queriesPerSecond': _calculateQPS(),
    };
  }

  /// Calculate queries per second
  double _calculateQPS() {
    if (_lastOptimization == null) return 0.0;

    final elapsed = DateTime.now().difference(_lastOptimization!);
    if (elapsed.inMilliseconds == 0) return 0.0;

    return _queryCount * 1000 / elapsed.inMilliseconds;
  }

  // Standard interface methods
  void clear() => _quadTree?.clear();
  bool get isInitialized => _quadTree != null;
  Rectangle? get worldBounds => _worldBounds;
}
