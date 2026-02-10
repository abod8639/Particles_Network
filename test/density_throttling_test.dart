import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/painter/object_pool.dart';

void main() {
  group('Density Throttling Logic', () {
    late ConnectionDataPool connectionDataPool;
    late List<ConnectionData> connections;

    setUp(() {
      connectionDataPool = ConnectionDataPool(maxPoolSize: 1000);
      connections = <ConnectionData>[];
    });

    tearDown(() {
      // Release all connections
      for (final conn in connections) {
        connectionDataPool.release(conn);
      }
      connections.clear();
      connectionDataPool.clear();
    });

    test('No throttling needed when connections.length <= denseThreshold', () {
      const int denseThreshold = 5;
      const int maxLinesPerDenseParticle = 4;

      // Add connections below threshold
      for (int i = 0; i < 3; i++) {
        connections.add(
          connectionDataPool.acquire(index: i, distance: (i + 1) * 10.0),
        );
      }

      final initialLength = connections.length;

      // Apply throttling logic
      if (connections.length > denseThreshold) {
        connections.sort((a, b) => a.distance.compareTo(b.distance));
        final excess = connections.length - maxLinesPerDenseParticle;
        for (int i = 0; i < excess; i++) {
          connectionDataPool.release(connections.removeLast());
        }
      }

      expect(connections.length, equals(initialLength));
      expect(connections.length, equals(3));
    });

    test('Throttling applied when connections.length > denseThreshold', () {
      const int denseThreshold = 5;
      const int maxLinesPerDenseParticle = 3;

      // Add connections above threshold
      for (int i = 0; i < 8; i++) {
        connections.add(
          connectionDataPool.acquire(index: i, distance: (i + 1) * 10.0),
        );
      }

      expect(connections.length, equals(8));

      // Apply throttling logic
      if (connections.length > denseThreshold) {
        connections.sort((a, b) => a.distance.compareTo(b.distance));
        final excess = connections.length - maxLinesPerDenseParticle;
        for (int i = 0; i < excess; i++) {
          connectionDataPool.release(connections.removeLast());
        }
      }

      expect(connections.length, equals(maxLinesPerDenseParticle));
      expect(connections.length, equals(3));
    });

    test('Closest connections are preserved after throttling', () {
      const int denseThreshold = 5;
      const int maxLinesPerDenseParticle = 3;

      // Add connections with specific distances
      final distances = [50.0, 10.0, 30.0, 40.0, 20.0, 15.0, 25.0];
      for (int i = 0; i < distances.length; i++) {
        connections.add(
          connectionDataPool.acquire(index: i, distance: distances[i]),
        );
      }

      // Apply throttling logic
      if (connections.length > denseThreshold) {
        connections.sort((a, b) => a.distance.compareTo(b.distance));
        final excess = connections.length - maxLinesPerDenseParticle;
        for (int i = 0; i < excess; i++) {
          connectionDataPool.release(connections.removeLast());
        }
      }

      // Verify only closest connections remain
      expect(connections.length, equals(3));

      // Check distances are in ascending order
      for (int i = 0; i < connections.length - 1; i++) {
        expect(
          connections[i].distance,
          lessThanOrEqualTo(connections[i + 1].distance),
        );
      }

      // Verify the distances are the 3 smallest
      final sortedDistances = [...distances]..sort();
      final expectedClosest = sortedDistances.take(3).toList();
      final actualDistances = connections.map((c) => c.distance).toList();

      expect(actualDistances, equals(expectedClosest));
    });

    test('Connections are sorted by distance before throttling', () {
      const int denseThreshold = 5;
      const int maxLinesPerDenseParticle = 3;

      // Add connections in random distance order
      final distances = [80.0, 10.0, 60.0, 20.0, 30.0, 40.0, 70.0];
      for (int i = 0; i < distances.length; i++) {
        connections.add(
          connectionDataPool.acquire(index: i, distance: distances[i]),
        );
      }

      // Apply throttling logic
      if (connections.length > denseThreshold) {
        connections.sort((a, b) => a.distance.compareTo(b.distance));
        final excess = connections.length - maxLinesPerDenseParticle;
        for (int i = 0; i < excess; i++) {
          connectionDataPool.release(connections.removeLast());
        }
      }

      // Verify sorting
      for (int i = 0; i < connections.length - 1; i++) {
        expect(connections[i].distance, lessThan(connections[i + 1].distance));
      }
    });

    test('Excess connections are properly released to pool', () {
      const int denseThreshold = 5;
      const int maxLinesPerDenseParticle = 3;
      final int initialPoolSize = connectionDataPool.poolSize;

      // Add connections
      for (int i = 0; i < 8; i++) {
        connections.add(
          connectionDataPool.acquire(index: i, distance: (i + 1) * 10.0),
        );
      }

      expect(
        connectionDataPool.poolSize,
        equals(initialPoolSize),
      ); // Pool empty

      // Apply throttling logic
      if (connections.length > denseThreshold) {
        connections.sort((a, b) => a.distance.compareTo(b.distance));
        final excess = connections.length - maxLinesPerDenseParticle;
        for (int i = 0; i < excess; i++) {
          connectionDataPool.release(connections.removeLast());
        }
      }

      // Verify 5 connections were released (8 - 3 = 5)
      expect(connectionDataPool.poolSize, equals(5));
    });

    test('Edge case: denseThreshold equals connections.length', () {
      const int denseThreshold = 5;
      const int maxLinesPerDenseParticle = 3;

      // Add exactly threshold number of connections
      for (int i = 0; i < 5; i++) {
        connections.add(
          connectionDataPool.acquire(index: i, distance: (i + 1) * 10.0),
        );
      }

      final initialLength = connections.length;

      // Apply throttling logic
      if (connections.length > denseThreshold) {
        connections.sort((a, b) => a.distance.compareTo(b.distance));
        final excess = connections.length - maxLinesPerDenseParticle;
        for (int i = 0; i < excess; i++) {
          connectionDataPool.release(connections.removeLast());
        }
      }

      // Should not be throttled
      expect(connections.length, equals(initialLength));
      expect(connections.length, equals(5));
    });

    test('Edge case: maxLinesPerDenseParticle equals 1', () {
      const int denseThreshold = 5;
      const int maxLinesPerDenseParticle = 1;

      // Add multiple connections
      for (int i = 0; i < 8; i++) {
        connections.add(
          connectionDataPool.acquire(index: i, distance: (i + 1) * 10.0),
        );
      }

      // Apply throttling logic
      if (connections.length > denseThreshold) {
        connections.sort((a, b) => a.distance.compareTo(b.distance));
        final excess = connections.length - maxLinesPerDenseParticle;
        for (int i = 0; i < excess; i++) {
          connectionDataPool.release(connections.removeLast());
        }
      }

      // Only the closest connection remains
      expect(connections.length, equals(1));
      expect(connections[0].distance, equals(10.0)); // Smallest distance
    });

    test('Edge case: Empty connections list', () {
      const int denseThreshold = 5;
      const int maxLinesPerDenseParticle = 3;

      // Don't add any connections
      expect(connections.length, equals(0));

      // Apply throttling logic
      if (connections.length > denseThreshold) {
        connections.sort((a, b) => a.distance.compareTo(b.distance));
        final excess = connections.length - maxLinesPerDenseParticle;
        for (int i = 0; i < excess; i++) {
          connectionDataPool.release(connections.removeLast());
        }
      }

      expect(connections.length, equals(0));
    });

    test('Throttling with negative excess (should not happen but safe)', () {
      const int denseThreshold = 10;
      const int maxLinesPerDenseParticle = 15; // maxLines > threshold

      // Add connections above threshold but within maxLines
      for (int i = 0; i < 12; i++) {
        connections.add(
          connectionDataPool.acquire(index: i, distance: (i + 1) * 10.0),
        );
      }

      // Apply throttling logic
      if (connections.length > denseThreshold) {
        connections.sort((a, b) => a.distance.compareTo(b.distance));
        final excess = connections.length - maxLinesPerDenseParticle;
        for (int i = 0; i < excess; i++) {
          connectionDataPool.release(connections.removeLast());
        }
      }

      // Should keep all connections (excess is negative, loop doesn't run)
      expect(connections.length, equals(12));
    });

    test('Multiple rounds of throttling', () {
      const int denseThreshold = 5;
      const int maxLinesPerDenseParticle = 3;

      // First round
      for (int i = 0; i < 8; i++) {
        connections.add(
          connectionDataPool.acquire(index: i, distance: (i + 1) * 10.0),
        );
      }

      if (connections.length > denseThreshold) {
        connections.sort((a, b) => a.distance.compareTo(b.distance));
        final excess = connections.length - maxLinesPerDenseParticle;
        for (int i = 0; i < excess; i++) {
          connectionDataPool.release(connections.removeLast());
        }
      }

      expect(connections.length, equals(3));

      // Add more connections and throttle again
      for (int i = 8; i < 15; i++) {
        connections.add(
          connectionDataPool.acquire(index: i, distance: (i + 1) * 10.0),
        );
      }

      expect(connections.length, equals(10));

      if (connections.length > denseThreshold) {
        connections.sort((a, b) => a.distance.compareTo(b.distance));
        final excess = connections.length - maxLinesPerDenseParticle;
        for (int i = 0; i < excess; i++) {
          connectionDataPool.release(connections.removeLast());
        }
      }

      expect(connections.length, equals(3));
    });

    test('Throttling preserves connection data integrity', () {
      const int denseThreshold = 5;
      const int maxLinesPerDenseParticle = 3;

      // Add connections with specific indices
      final indices = [0, 1, 2, 3, 4, 5, 6, 7];
      final distances = [50.0, 10.0, 30.0, 40.0, 20.0, 15.0, 25.0, 35.0];

      for (int i = 0; i < indices.length; i++) {
        connections.add(
          connectionDataPool.acquire(index: indices[i], distance: distances[i]),
        );
      }

      // Apply throttling logic
      if (connections.length > denseThreshold) {
        connections.sort((a, b) => a.distance.compareTo(b.distance));
        final excess = connections.length - maxLinesPerDenseParticle;
        for (int i = 0; i < excess; i++) {
          connectionDataPool.release(connections.removeLast());
        }
      }

      // Verify remaining connections have valid index and distance
      for (final conn in connections) {
        expect(conn.index, greaterThanOrEqualTo(0));
        expect(conn.distance, greaterThan(0));
      }

      // Verify the 3 closest are preserved
      expect(connections.length, equals(3));
      final distancesSorted = [...distances]..sort();
      final expectedClosest = distancesSorted.take(3).toList();
      final actualDistances = connections.map((c) => c.distance).toList();
      expect(actualDistances, equals(expectedClosest));
    });

    test('Performance: Throttling with large number of connections', () {
      const int denseThreshold = 100;
      const int maxLinesPerDenseParticle = 50;

      // Add many connections
      for (int i = 0; i < 500; i++) {
        connections.add(
          connectionDataPool.acquire(index: i, distance: (i % 200) * 1.5),
        );
      }

      final stopwatch = Stopwatch()..start();

      // Apply throttling logic
      if (connections.length > denseThreshold) {
        connections.sort((a, b) => a.distance.compareTo(b.distance));
        final excess = connections.length - maxLinesPerDenseParticle;
        for (int i = 0; i < excess; i++) {
          connectionDataPool.release(connections.removeLast());
        }
      }

      stopwatch.stop();

      expect(connections.length, equals(maxLinesPerDenseParticle));
      expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be fast
    });

    test('Complex scenario: Variable denseThreshold and maxLines', () {
      // Simulate different complexity settings
      final List<int> denseThresholds = [3, 5, 10];
      final List<int> maxLines = [2, 3, 5];

      for (int t = 0; t < denseThresholds.length; t++) {
        connections.clear();
        for (final conn in connections) {
          connectionDataPool.release(conn);
        }

        final int denseThreshold = denseThresholds[t];
        final int maxLinesPerDenseParticle = maxLines[t];

        // Add connections
        for (int i = 0; i < 15; i++) {
          connections.add(
            connectionDataPool.acquire(index: i, distance: (i + 1) * 5.0),
          );
        }

        // Apply throttling logic
        if (connections.length > denseThreshold) {
          connections.sort((a, b) => a.distance.compareTo(b.distance));
          final excess = connections.length - maxLinesPerDenseParticle;
          for (int i = 0; i < excess; i++) {
            connectionDataPool.release(connections.removeLast());
          }
        }

        // Verify result
        if (15 > denseThreshold) {
          expect(connections.length, equals(maxLinesPerDenseParticle));
        } else {
          expect(connections.length, equals(15));
        }
      }
    });
  });
}
