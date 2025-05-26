import 'package:particles_network/model/particlemodel.dart';

/// A utility class for optimized distance calculations between particles with caching
///
/// This implements a memoization pattern to avoid redundant distance calculations
/// between particles that haven't moved. Particularly effective in particle systems
/// where many particles maintain stable positions frame-to-frame.
///
/// Mathematical Basis:
/// Distance between two points (x₁,y₁) and (x₂,y₂) is calculated using:
///   distance = √((x₂-x₁)² + (y₂-y₁)²)
///
/// Caching Strategy:
/// Uses a hash-based cache key combining both particles' identities:
///   cacheKey = p1.hashCode ^ p2.hashCode
/// This ensures:
/// 1. Symmetric pairs (p1,p2) and (p2,p1) use the same cache entry
/// 2. Cache hits when the same particles are checked multiple times
class DistanceCalculator {
  // Cache storage using a map with integer keys and double values
  // Key: Combined hash of two particles
  // Value: Precomputed distance between them
  final Map<int, double> _cache = <int, double>{};

  // Total particle count (used for cache size estimation)
  final int particleCount;

  /// Constructor initializes the calculator with expected particle count
  /// [particleCount] helps estimate potential cache size requirements
  DistanceCalculator(this.particleCount);

  /// Calculates the Euclidean distance between two particles with caching
  ///
  /// Performance Characteristics:
  /// - First call: O(1) actual distance calculation
  /// - Subsequent calls: O(1) cache lookup
  /// - Worst-case memory: O(n²) where n is particle count
  ///   (though in practice much lower due to spatial partitioning)
  ///
  /// [p1] First particle
  /// [p2] Second particle
  /// Returns: Distance between particles in logical pixels
  double calculateDistance(Particle p1, Particle p2) {
    // Generate cache key using bitwise XOR of hash codes
    // This ensures key is identical regardless of parameter order
    final int key = p1.hashCode ^ p2.hashCode;

    // Use Dart's putIfAbsent for thread-safe cache population
    return _cache.putIfAbsent(key, () {
      // Cache miss - compute actual distance
      // Using vector subtraction and distance property
      return (p1.position - p2.position).distance;
    });
  }

  /// Clears the distance cache
  ///
  /// Should be called:
  /// 1. At the start of each animation frame
  /// 2. When particles are added/removed
  /// 3. After significant particle movement
  void clearCache() {
    _cache.clear();
  }
}
