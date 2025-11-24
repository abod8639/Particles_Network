import 'dart:collection';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:particles_network/model/particlemodel.dart';

/// ---------------------------------------------------------------------------
/// DistanceCalculator
/// ---------------------------------------------------------------------------
/// A micro‑utility responsible for **quickly** and **safely** returning the
/// Euclidean distance between two *particles* (or arbitrary `Offset`s) while
/// keeping memory usage bounded through a Least‑Recently‑Used cache.
///
/// Why does this class exist?
/// --------------------------
/// In a particle network the naïve way to connect `n` particles requires
/// `n²` distance checks per frame. Even after spatial pruning (e.g., QuadTree)
/// we re‑check many of the *same* pairs across successive frames because most
/// particles hardly move. Memoising those stable pairs eliminates redundant
/// square‑root calls and frees the CPU for painting.
///
/// Mathematical background
/// -----------------------
/// The Euclidean distance *d* between points **p** = (x₁, y₁) and
/// **q** = (x₂, y₂) is
///
/// ```text
/// d = √[(x₂ − x₁)² + (y₂ − y₁)²]
/// ```
///
/// This implementation sticks to the textbook formula for clarity; when you
/// only need comparisons you can cache *d²* and drop the expensive `sqrt`.
///
/// Cache‑key derivation
/// --------------------
/// We need a symmetric, fast key unique to a *pair*.  The bitwise XOR
///
/// ```text
/// key = hash(p) ⊕ hash(q)
/// ```
///
/// satisfies `key(p,q) == key(q,p)` and is a single CPU instruction.
///
/// LRU eviction
/// ------------
/// A `LinkedHashMap` preserves insertion order, so removing
/// `_cache.keys.first` discards the least‑recently‑accessed entry, giving us an
/// O(1) LRU policy without extra metadata.
///
/// Usage pattern
/// -------------
/// ```dart
/// final calc = DistanceCalculator(maxEntries: 2_000);
/// final dist = calc.betweenParticles(p1, p2);
/// // … render frame …
/// calc.reset(); // clear if every particle moved this tick
/// ```
class DistanceCalculator {
  //-------------------------------------------------------------------------
  // Constructor
  //-------------------------------------------------------------------------

  /// Creates a calculator with an upper bound ([maxEntries]) on how many
  /// distances may live in the cache at once.
  ///
  /// * `maxEntries == 0` disables caching.
  /// * On desktop you might raise this to 20 000+, while on 1 GB phones 2 000
  ///   is safer.
  DistanceCalculator({this.maxEntries = 10_000})
    : assert(maxEntries >= 0),
      _cache = LinkedHashMap<int, double>();

  /// Maximum number of memoised distances before eviction.
  int maxEntries;

  /// Internal storage — maintains insertion order ⇒ O(1) LRU removal.
  final LinkedHashMap<int, double> _cache;

  //-------------------------------------------------------------------------
  // Public API
  //-------------------------------------------------------------------------

  /// Returns the Euclidean distance between two [Particle]s using the cache.
  /// The XOR key is computed once here so we don’t hash twice.
  double betweenParticles(Particle a, Particle b) {
    // Symmetric key generation: ensure consistent order for (a,b) and (b,a)
    final int h1 = a.hashCode;
    final int h2 = b.hashCode;
    final int key = h1 < h2 ? (h1 * 31 + h2) : (h2 * 31 + h1);
    return _cachedDistance(a.position, b.position, key);
  }

  /// Raw distance between two `Offset`s **without caching**. Useful for
  /// sporadic checks (e.g., pointer→particle) where caching adds no value.
  double betweenPoints(Offset a, Offset b) =>
      _euclidean(a.dx - b.dx, a.dy - b.dy);

  /// Clears **all** cached entries in O(1). Call every frame if the entire
  /// swarm moves; otherwise let the cache span a few frames for better hits.
  void reset() => _cache.clear();

  /// Updates the cache size based on particle count.
  /// Recommended size is roughly (N * N) / 2 for full connectivity,
  /// but we can cap it to avoid excessive memory usage.
  void updateCacheSize(int particleCount) {
    // Estimate needed pairs: N * (N-1) / 2
    // We cap at 20,000 or user defined max to prevent OOM on huge counts
    final int estimatedPairs = (particleCount * (particleCount - 1)) ~/ 2;
    final int newMax = estimatedPairs.clamp(1000, 20000);
    
    if (maxEntries != newMax) {
      maxEntries = newMax;
      // If we shrank, trim the cache
      if (_cache.length > maxEntries) {
        // Remove oldest entries until we fit
        final int toRemove = _cache.length - maxEntries;
        for (int i = 0; i < toRemove; i++) {
          _cache.remove(_cache.keys.first);
        }
      }
    }
  }

  //-------------------------------------------------------------------------
  // Implementation details
  //-------------------------------------------------------------------------

  /// Look up or compute the distance between [a] and [b] under [key].
  double _cachedDistance(Offset a, Offset b, int key) {
    // ── 1. Fast path ── cache hit
    final cached = _cache[key];
    if (cached != null) return cached;

    // ── 2. Miss ── compute using Δx, Δy then memoise
    final double dx = a.dx - b.dx; // Δx = x₂ − x₁
    final double dy = a.dy - b.dy; // Δy = y₂ − y₁

    final double dist = _euclidean(dx, dy);
    _addToCache(key, dist);
    return dist;
  }

  /// Inserts a new [value] and evicts the least‑recently‑used entry if needed.
  void _addToCache(int key, double value) {
    if (maxEntries == 0) return; // cache disabled
    if (_cache.length >= maxEntries) _cache.remove(_cache.keys.first);
    _cache[key] = value;
  }

  /// Pure utility — computes √(dx² + dy²).
  static double _euclidean(double dx, double dy) =>
      math.sqrt(dx * dx + dy * dy);
}
