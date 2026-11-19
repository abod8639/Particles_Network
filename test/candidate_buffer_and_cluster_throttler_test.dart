import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/src/rendering/candidate_buffer.dart';
import 'package:particles_network/src/rendering/cluster_throttler.dart';
import 'package:particles_network/src/rendering/network_performance.dart';

void main() {
  group('CandidateBuffer Unit Tests', () {
    test('Initializes with default capacity and grows monotonically', () {
      final buffer = CandidateBuffer(initialCapacity: 16);
      expect(buffer.capacity, equals(16));

      buffer.ensureCapacity(20);
      expect(buffer.capacity, greaterThanOrEqualTo(20));

      final prevCapacity = buffer.capacity;
      buffer.ensureCapacity(10); // should not shrink
      expect(buffer.capacity, equals(prevCapacity));
    });

    test('selectTopKClosest places k smallest distances at front', () {
      final buffer = CandidateBuffer(initialCapacity: 8);
      // Unordered distances
      final distances = [100.0, 25.0, 4.0, 64.0, 9.0, 16.0, 49.0];
      for (int i = 0; i < distances.length; i++) {
        buffer.indices[i] = i;
        buffer.distSq[i] = distances[i];
      }

      // Select top 3 closest (4.0, 9.0, 16.0)
      buffer.selectTopKClosest(distances.length, 3);

      expect(buffer.distSq[0], equals(4.0));
      expect(buffer.indices[0], equals(2));

      expect(buffer.distSq[1], equals(9.0));
      expect(buffer.indices[1], equals(4));

      expect(buffer.distSq[2], equals(16.0));
      expect(buffer.indices[2], equals(5));
    });

    test('Connection degree buffer clears and resizes on demand', () {
      final buffer = CandidateBuffer();
      final counts = buffer.getClearedConnectionCounts(10);
      expect(counts.length, greaterThanOrEqualTo(10));
      expect(counts.take(10).every((c) => c == 0), isTrue);

      counts[0] = 5;
      final counts2 = buffer.getClearedConnectionCounts(10);
      expect(counts2[0], equals(0)); // cleared
    });
  });

  group('ClusterThrottler Unit Tests', () {
    const throttler = ClusterThrottler();

    test('computeDenseThreshold calculates correct limits across modes', () {
      final d1 = throttler.computeDenseThreshold(
        distance: 100.0,
        performance: const NetworkPerformance(isComplex: true),
      );
      expect(d1, equals(25)); // 100 ~/ 4

      final d2 = throttler.computeDenseThreshold(
        distance: 100.0,
        performance: const NetworkPerformance(isComplex: false),
        isIndividual: true,
      );
      expect(d2, equals(66)); // 100 ~/ 1.5
    });

    test('calculateComplexLineFade provides smooth cosine falloff', () {
      // rank 0 is closest -> fade = 1.0
      expect(throttler.calculateComplexLineFade(0, 5), equals(1.0));

      // middle rank has intermediate fade between 0 and 1
      final midFade = throttler.calculateComplexLineFade(2, 5);
      expect(midFade, greaterThan(0.0));
      expect(midFade, lessThan(1.0));

      // drawCount <= 1 returns 1.0
      expect(throttler.calculateComplexLineFade(0, 1), equals(1.0));
    });

    test(
        'filterCandidates throttles candidate count according to caps and limits',
        () {
      final buffer = CandidateBuffer(initialCapacity: 16);
      for (int i = 0; i < 10; i++) {
        buffer.indices[i] = i;
        buffer.distSq[i] = (i + 1) * 10.0;
      }

      final filtered = throttler.filterCandidates(
        buffer: buffer,
        candidateCount: 10,
        isCapped: true,
        remainingCap: 3,
        denseThreshold: 5,
        defaultMaxLines: 5,
        isComplexMode: true,
        performance: const NetworkPerformance(isComplex: true),
      );

      expect(filtered, equals(3));
    });
  });
}
