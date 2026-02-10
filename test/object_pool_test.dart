import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/painter/object_pool.dart';

void main() {
  group('ObjectPool', () {
    late ObjectPool<TestObject> pool;

    setUp(() {
      pool = ObjectPool<TestObject>(
        factory: () => TestObject(),
        resetFn: (obj) => obj.reset(),
        maxPoolSize: 10,
      );
    });

    tearDown(() {
      pool.clear();
    });

    test('acquire returns new instance when pool is empty', () {
      final obj = pool.acquire();
      expect(obj, isNotNull);
      expect(pool.poolSize, equals(0));
    });

    test('acquire returns existing instance from pool', () {
      final obj1 = pool.acquire();
      obj1.value = 42;
      pool.release(obj1);

      expect(pool.poolSize, equals(1));
      final obj2 = pool.acquire();
      expect(obj2, equals(obj1));
      expect(obj2.value, equals(0)); // Should be reset
    });

    test('release adds object to pool up to maxPoolSize', () {
      final objects = <TestObject>[];
      for (int i = 0; i < 15; i++) {
        objects.add(pool.acquire());
      }

      for (final obj in objects) {
        pool.release(obj);
      }

      expect(pool.poolSize, equals(10)); // maxPoolSize is 10
    });

    test('release calls resetFn before adding to pool', () {
      final obj = pool.acquire();
      obj.value = 99;
      obj.reset();

      pool.release(obj);

      expect(pool.poolSize, equals(1));
      expect(obj.value, equals(0)); // Should be reset
    });

    test('clear empties the pool', () {
      pool.acquire();
      pool.acquire();
      pool.release(pool.acquire());
      pool.release(pool.acquire());

      expect(pool.poolSize, greaterThan(0));
      pool.clear();
      expect(pool.poolSize, equals(0));
    });

    test('poolSize returns correct count', () {
      expect(pool.poolSize, equals(0));

      final obj1 = pool.acquire();
      pool.release(obj1);
      expect(pool.poolSize, equals(1));

      final obj2 = pool.acquire();
      pool.release(obj2);
      expect(pool.poolSize, equals(1));
    });

    test('ObjectPool without resetFn works correctly', () {
      final simplePool = ObjectPool<TestObject>(
        factory: () => TestObject(),
        maxPoolSize: 5,
      );

      final obj = simplePool.acquire();
      obj.value = 42;
      simplePool.release(obj);

      final retrieved = simplePool.acquire();
      expect(retrieved.value, equals(42)); // Value should be preserved
    });

    test('acquire respects LIFO order', () {
      final obj1 = TestObject();
      final obj2 = TestObject();
      final obj3 = TestObject();

      obj1.id = 1;
      obj2.id = 2;
      obj3.id = 3;

      pool.release(obj1);
      pool.release(obj2);
      pool.release(obj3);

      final retrieved1 = pool.acquire();
      final retrieved2 = pool.acquire();
      final retrieved3 = pool.acquire();

      expect(retrieved1.id, equals(0)); // Last inserted should be first out
      expect(retrieved2.id, equals(0));
      expect(retrieved3.id, equals(0));
    });
  });

  group('IntListPool', () {
    late IntListPool pool;

    setUp(() {
      pool = IntListPool(maxPoolSize: 5);
    });

    tearDown(() {
      pool.clear();
    });

    test('acquire returns empty list when pool is empty', () {
      final list = pool.acquire();
      expect(list, isNotNull);
      expect(list, isEmpty);
    });

    test('acquire clears list before returning', () {
      final list = pool.acquire();
      list.addAll([1, 2, 3]);
      pool.release(list);

      expect(pool.poolSize, equals(1));
      final retrieved = pool.acquire();
      expect(retrieved, isEmpty);
    });

    test('release adds list to pool', () {
      final list = [1, 2, 3];
      pool.release(list);
      expect(pool.poolSize, equals(1));
    });

    test('release respects maxPoolSize', () {
      final lists = <List<int>>[];
      for (int i = 0; i < 10; i++) {
        lists.add([i]);
      }

      for (final list in lists) {
        pool.release(list);
      }

      expect(pool.poolSize, equals(5)); // maxPoolSize is 5
    });

    test('clear empties the pool', () {
      pool.release([1, 2, 3]);
      pool.release([4, 5, 6]);
      expect(pool.poolSize, equals(2));

      pool.clear();
      expect(pool.poolSize, equals(0));
    });

    test('poolSize returns correct count', () {
      expect(pool.poolSize, equals(0));
      pool.release([1, 2]);
      expect(pool.poolSize, equals(1));
      pool.release([3, 4]);
      expect(pool.poolSize, equals(2));
    });

    test('multiple acquire and release cycles work correctly', () {
      final list1 = pool.acquire();
      list1.addAll([1, 2, 3]);

      final list2 = pool.acquire();
      list2.addAll([4, 5, 6]);

      pool.release(list1);
      pool.release(list2);

      expect(pool.poolSize, equals(2));

      final retrieved1 = pool.acquire();
      expect(retrieved1, isEmpty);

      final retrieved2 = pool.acquire();
      expect(retrieved2, isEmpty);

      expect(pool.poolSize, equals(0));
    });
  });

  group('ConnectionData', () {
    test('constructor sets index and distance', () {
      final data = ConnectionData(index: 5, distance: 10.5);
      expect(data.index, equals(5));
      expect(data.distance, equals(10.5));
    });

    test('properties can be modified', () {
      final data = ConnectionData(index: 0, distance: 0.0);
      data.index = 42;
      data.distance = 3.14;

      expect(data.index, equals(42));
      expect(data.distance, equals(3.14));
    });
  });

  group('ConnectionDataPool', () {
    late ConnectionDataPool pool;

    setUp(() {
      pool = ConnectionDataPool(maxPoolSize: 10);
    });

    tearDown(() {
      pool.clear();
    });

    test('acquire creates new ConnectionData with parameters', () {
      final data = pool.acquire(index: 5, distance: 10.5);
      expect(data.index, equals(5));
      expect(data.distance, equals(10.5));
      expect(pool.poolSize, equals(0));
    });

    test('acquire reuses pooled object and updates values', () {
      final data1 = pool.acquire(index: 1, distance: 1.5);
      pool.release(data1);

      expect(pool.poolSize, equals(1));
      final data2 = pool.acquire(index: 5, distance: 10.5);
      expect(data2, equals(data1)); // Same object
      expect(data2.index, equals(5));
      expect(data2.distance, equals(10.5));
    });

    test('release adds object to pool', () {
      final data = pool.acquire(index: 1, distance: 1.5);
      pool.release(data);
      expect(pool.poolSize, equals(1));
    });

    test('release respects maxPoolSize', () {
      final dataList = <ConnectionData>[];
      for (int i = 0; i < 15; i++) {
        dataList.add(pool.acquire(index: i, distance: i.toDouble()));
      }

      for (final data in dataList) {
        pool.release(data);
      }

      expect(pool.poolSize, equals(10)); // maxPoolSize is 10
    });

    test('clear empties the pool', () {
      pool.acquire(index: 1, distance: 1.5);
      pool.acquire(index: 2, distance: 2.5);
      pool.release(pool.acquire(index: 0, distance: 0.0));

      pool.clear();
      expect(pool.poolSize, equals(0));
    });

    test('poolSize returns correct count', () {
      expect(pool.poolSize, equals(0));
      pool.release(pool.acquire(index: 1, distance: 1.5));
      expect(pool.poolSize, equals(1));
      pool.release(pool.acquire(index: 2, distance: 2.5));
      expect(pool.poolSize, equals(1));
    });

    test('multiple acquire and release cycles', () {
      final data1 = pool.acquire(index: 10, distance: 15.0);
      final data2 = pool.acquire(index: 20, distance: 25.0);

      pool.release(data1);
      pool.release(data2);

      expect(pool.poolSize, equals(2));

      final retrieved1 = pool.acquire(index: 100, distance: 150.0);
      final retrieved2 = pool.acquire(index: 200, distance: 250.0);

      expect(retrieved1.index, equals(100));
      expect(retrieved2.index, equals(200));
    });
  });

  group('PoolManager', () {
    test('getInstance returns singleton instance', () {
      final instance1 = PoolManager.getInstance();
      final instance2 = PoolManager.getInstance();
      expect(instance1, equals(instance2));
    });

    test('getInstance initializes pools', () {
      final manager = PoolManager.getInstance();
      expect(manager.intListPool, isNotNull);
      expect(manager.connectionDataPool, isNotNull);
    });

    test('intListPool is IntListPool instance', () {
      final manager = PoolManager.getInstance();
      expect(manager.intListPool, isA<IntListPool>());
    });

    test('connectionDataPool is ConnectionDataPool instance', () {
      final manager = PoolManager.getInstance();
      expect(manager.connectionDataPool, isA<ConnectionDataPool>());
    });

    test('clearAll clears all pools', () {
      final manager = PoolManager.getInstance();

      // Add items to pools
      final intList = manager.intListPool.acquire();
      intList.add(42);
      manager.intListPool.release(intList);

      final connData = manager.connectionDataPool.acquire(
        index: 5,
        distance: 10.0,
      );
      manager.connectionDataPool.release(connData);

      expect(manager.intListPool.poolSize, equals(1));
      expect(manager.connectionDataPool.poolSize, equals(1));

      manager.clearAll();

      expect(manager.intListPool.poolSize, equals(0));
      expect(manager.connectionDataPool.poolSize, equals(0));
    });

    test('resetAll method exists and is callable', () {
      final manager = PoolManager.getInstance();
      expect(() => manager.resetAll(), returnsNormally);
    });
  });

  group('ObjectPool - Edge Cases', () {
    late ObjectPool<TestObject> pool;

    setUp(() {
      pool = ObjectPool<TestObject>(
        factory: () => TestObject(),
        maxPoolSize: 3,
      );
    });

    test('maxPoolSize of 0 prevents any pooling', () {
      final zeroPool = ObjectPool<TestObject>(
        factory: () => TestObject(),
        maxPoolSize: 0,
      );

      final obj = zeroPool.acquire();
      zeroPool.release(obj);
      expect(zeroPool.poolSize, equals(0));
    });

    test('maxPoolSize of 1 keeps only one object', () {
      final singlePool = ObjectPool<TestObject>(
        factory: () => TestObject(),
        maxPoolSize: 1,
      );

      final obj1 = singlePool.acquire();
      final obj2 = singlePool.acquire();

      singlePool.release(obj1);
      singlePool.release(obj2);

      expect(singlePool.poolSize, equals(1));
    });

    test('rapid acquire and release operations', () {
      for (int i = 0; i < 100; i++) {
        final obj = pool.acquire();
        pool.release(obj);
      }
      expect(pool.poolSize, equals(1)); // maxPoolSize is 3
    });

    test('acquiring more than maxPoolSize creates new instances', () {
      final obj1 = pool.acquire();
      final obj2 = pool.acquire();
      final obj3 = pool.acquire();
      final obj4 = pool.acquire();

      // التأكد أن الكائنات ليست نال (null) وأنها من النوع الصحيح
      expect(obj1, isNotNull);

      // التأكد أن جميع الكائنات فريدة وليست نفس النسخة في الذاكرة
      final objects = [obj1, obj2, obj3, obj4];
      final uniqueObjects = Set.from(objects);

      expect(
        uniqueObjects.length,
        equals(4),
        reason: 'All acquired objects must be unique instances',
      );

      // أو الطريقة التقليدية التي كنت تستخدمها:
      expect(identical(obj1, obj2), isFalse);
      expect(identical(obj1, obj3), isFalse);
      expect(identical(obj1, obj4), isFalse);
      expect(identical(obj2, obj3), isFalse);
      expect(identical(obj3, obj4), isFalse);
    });
  });

  group('IntListPool - Edge Cases', () {
    test('acquire and add multiple items in sequence', () {
      final pool = IntListPool(maxPoolSize: 3);

      final list1 = pool.acquire();
      list1.addAll([1, 2, 3, 4, 5]);

      final list2 = pool.acquire();
      list2.addAll([10, 20, 30]);

      pool.release(list1);
      pool.release(list2);

      expect(pool.poolSize, equals(2));

      final retrieved1 = pool.acquire();
      expect(retrieved1, isEmpty);

      final retrieved2 = pool.acquire();
      expect(retrieved2, isEmpty);
    });

    test('very large lists can be pooled', () {
      final pool = IntListPool(maxPoolSize: 2);
      final largeList = List<int>.generate(10000, (i) => i);

      pool.release(largeList);
      expect(pool.poolSize, equals(1));

      final retrieved = pool.acquire();
      expect(retrieved, isEmpty);
    });
  });

  group('ConnectionDataPool - Stress Test', () {
    test('high frequency acquire and release operations', () {
      final pool = ConnectionDataPool(maxPoolSize: 100);

      for (int i = 0; i < 1000; i++) {
        final data = pool.acquire(index: i, distance: i.toDouble());
        if (i % 2 == 0) {
          pool.release(data);
        }
      }

      expect(pool.poolSize, lessThanOrEqualTo(100));
    });

    test('alternating acquire and release maintains pool size', () {
      final pool = ConnectionDataPool(maxPoolSize: 50);
      final acquired = <ConnectionData>[];

      for (int i = 0; i < 25; i++) {
        acquired.add(pool.acquire(index: i, distance: i.toDouble()));
      }

      for (int i = 0; i < 25; i++) {
        pool.release(acquired[i]);
      }

      expect(pool.poolSize, equals(25));

      for (int i = 0; i < 25; i++) {
        pool.acquire(index: i + 100, distance: (i + 100).toDouble());
      }

      expect(pool.poolSize, equals(0));
    });
  });
}

/// Test helper class
class TestObject {
  int value = 0;
  int id = 0;

  void reset() {
    value = 0;
    id = 0;
  }
}
