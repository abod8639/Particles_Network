import 'dart:math' as math;
import 'dart:typed_data';

/// Reusable typed buffers for collecting and sorting candidate connection pairs.
///
/// Ensures zero per-frame heap allocations by growing buffers monotonically
/// and reusing existing memory across frames.
class CandidateBuffer {
  Int32List _indices;
  Float64List _distSq;

  Int32List _connectionCounts = Int32List(0);

  CandidateBuffer({int initialCapacity = 128})
    : _indices = Int32List(initialCapacity),
      _distSq = Float64List(initialCapacity);

  /// Candidate particle index array.
  Int32List get indices => _indices;

  /// Candidate squared distance array.
  Float64List get distSq => _distSq;

  /// Current buffer capacity.
  int get capacity => _indices.length;

  /// Connection degree count array.
  Int32List get connectionCounts => _connectionCounts;

  /// Returns a zero-cleared connection count buffer sized at least [minSize].
  @pragma('vm:prefer-inline')
  Int32List getClearedConnectionCounts(int minSize) {
    if (_connectionCounts.length < minSize) {
      _connectionCounts = Int32List(
        math.max(minSize, _connectionCounts.length * 2),
      );
    }
    _connectionCounts.fillRange(0, minSize, 0);
    return _connectionCounts;
  }

  /// Ensures capacity for at least [needed] candidates, doubling when required.
  @pragma('vm:prefer-inline')
  void ensureCapacity(int needed) {
    if (needed <= _indices.length) return;
    final int newSize = math.max(_indices.length * 2, needed);

    final newIndices = Int32List(newSize);
    newIndices.setRange(0, _indices.length, _indices);
    _indices = newIndices;

    final newDistSq = Float64List(newSize);
    newDistSq.setRange(0, _distSq.length, _distSq);
    _distSq = newDistSq;
  }

  /// Partially sorts the first [count] candidates in-place so that the [k] closest
  /// occupy positions `0..min(k, count) - 1`.
  @pragma('vm:prefer-inline')
  void selectTopKClosest(int count, int k) {
    final int limit = k < count ? k : count;
    final Int32List idxs = _indices;
    final Float64List dSq = _distSq;

    for (int i = 0; i < limit; i++) {
      int minIdx = i;
      double minDistSq = dSq[i];
      for (int j = i + 1; j < count; j++) {
        final double d = dSq[j];
        if (d < minDistSq) {
          minDistSq = d;
          minIdx = j;
        }
      }
      if (minIdx != i) {
        dSq[minIdx] = dSq[i];
        dSq[i] = minDistSq;
        final int tmpI = idxs[i];
        idxs[i] = idxs[minIdx];
        idxs[minIdx] = tmpI;
      }
    }
  }

  /// For testing: sets explicit buffer capacity.
  void setCapacityForTesting(int capacity) {
    _indices = Int32List(capacity);
    _distSq = Float64List(capacity);
  }
}
