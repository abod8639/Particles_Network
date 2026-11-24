// Object pooling utilities for efficient memory management
//
// Provides reusable object pools to reduce garbage collection pressure
// by pre-allocating and reusing objects across frames.
library;

// Generic object pool for recycling objects
class ObjectPool<T> {
  final List<T> _available = [];
  final T Function() factory;
  final void Function(T)? resetFn;
  final int maxPoolSize;

  // Creates a new object pool
  // [factory]: Function to create new instances
  // [resetFn]: Optional function to reset object state for reuse
  // [maxPoolSize]: Maximum objects to keep in pool (default: 1000)
  ObjectPool({required this.factory, this.resetFn, this.maxPoolSize = 1000});

  // Acquire an object from the pool or create a new one
  T acquire() {
    if (_available.isNotEmpty) {
      return _available.removeLast();
    }
    return factory();
  }

  // Release an object back to the pool for reuse
  void release(T object) {
    if (_available.length < maxPoolSize) {
      resetFn?.call(object);
      _available.add(object);
    }
  }

  // Clear all pooled objects
  void clear() {
    _available.clear();
  }

  // Get current pool size
  int get poolSize => _available.length;
}

// Specialized pool for List<int> objects
class IntListPool {
  final List<List<int>> _available = [];
  final int maxPoolSize;

  IntListPool({this.maxPoolSize = 500});

  // Acquire a list from the pool, clearing it if it was previously used
  List<int> acquire() {
    if (_available.isNotEmpty) {
      return _available.removeLast()..clear();
    }
    return <int>[];
  }

  // Release a list back to the pool
  void release(List<int> list) {
    if (_available.length < maxPoolSize) {
      list.clear();
      _available.add(list);
    }
  }

  // Clear all pooled lists
  void clear() {
    _available.clear();
  }

  // Get current pool size
  int get poolSize => _available.length;
}

// Specialized pool for ConnectionData objects
class ConnectionDataPool {
  final List<ConnectionData> _available = [];
  final int maxPoolSize;

  ConnectionDataPool({this.maxPoolSize = 1000});

  // Acquire a connection data object from the pool
  ConnectionData acquire({required int index, required double distance}) {
    if (_available.isNotEmpty) {
      final data = _available.removeLast();
      data.index = index;
      data.distance = distance;
      return data;
    }
    return ConnectionData(index: index, distance: distance);
  }

  // Release a connection data object back to the pool
  void release(ConnectionData data) {
    if (_available.length < maxPoolSize) {
      _available.add(data);
    }
  }

  // Clear all pooled objects
  void clear() {
    _available.clear();
  }

  // Get current pool size
  int get poolSize => _available.length;
}

// Reusable connection data structure
class ConnectionData {
  int index;
  double distance;

  ConnectionData({required this.index, required this.distance});
}

// Global pool manager for efficient resource reuse
class PoolManager {
  static final PoolManager _instance = PoolManager._internal();

  late final IntListPool intListPool;
  late final ConnectionDataPool connectionDataPool;

  PoolManager._internal() {
    intListPool = IntListPool(maxPoolSize: 500);
    connectionDataPool = ConnectionDataPool(maxPoolSize: 1000);
  }

  // Get singleton instance
  static PoolManager getInstance() => _instance;

  // Reset all pools (call at the end of each frame if needed)
  void resetAll() {
    // Pools manage themselves; this is for explicit cleanup if needed
  }

  // Clear all pools to free memory
  void clearAll() {
    intListPool.clear();
    connectionDataPool.clear();
  }
}
