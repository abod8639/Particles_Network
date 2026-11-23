import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/src/rendering/candidate_buffer.dart';
import 'package:particles_network/src/rendering/cluster_throttler.dart';
import 'package:particles_network/src/rendering/complex_features.dart';
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

    test('connectionCounts and setCapacityForTesting work as expected (L28-L29, L85-L87)', () {
      final buffer = CandidateBuffer();
      expect(buffer.connectionCounts, isEmpty);

      buffer.getClearedConnectionCounts(16);
      expect(buffer.connectionCounts.length, greaterThanOrEqualTo(16));

      buffer.setCapacityForTesting(32);
      expect(buffer.capacity, equals(32));
      expect(buffer.indices.length, equals(32));
      expect(buffer.distSq.length, equals(32));
    });
  });

  group('ClusterThrottler Unit Tests', () {
    const throttler = ClusterThrottler();

    test('computeDenseThreshold calculates correct limits across modes', () {
      final d1 = throttler.computeDenseThreshold(
        distance: 100.0,
        performance: const PerformanceFeatures(complex: ComplexConfig(enabled: true)),
      );
      expect(d1, equals(60)); // 100 * 0.60 (or 100 ~/ (1.0 / 0.60))

      final d2 = throttler.computeDenseThreshold(
        distance: 100.0,
        performance: const PerformanceFeatures(complex: ComplexConfig(enabled: false)),
        isIndividual: true,
      );
      expect(d2, equals(66)); // 100 ~/ 1.5
    });

    test('computeDenseThreshold respects complexDensityFactor when specified (L23-L25)', () {
      final resPositive = throttler.computeDenseThreshold(
        distance: 120.0,
        performance: const PerformanceFeatures(complex: ComplexConfig(densityFactor: 0.5)),
      );
      expect(resPositive, equals(60));

      final resZero = throttler.computeDenseThreshold(
        distance: 0.0,
        performance: const PerformanceFeatures(complex: ComplexConfig(densityFactor: 0.5)),
      );
      expect(resZero, equals(0));

      final resNegative = throttler.computeDenseThreshold(
        distance: -10.0,
        performance: const PerformanceFeatures(complex: ComplexConfig(densityFactor: 0.5)),
      );
      expect(resNegative, equals(0));
    });

    test('resolveComplexTargetLines throttles complex lines using ratio and cap limits (L46-L47)', () {
      // 1. When maxComplexLines != null (L46)
      final resWithCap = throttler.resolveComplexTargetLines(
        candidateCount: 20,
        defaultMaxLines: 15,
        performance: const PerformanceFeatures(
          complex: ComplexConfig(
            ratio: 0.5,
            maxLines: 6,
          ),
        ),
      );
      expect(resWithCap, equals(6)); // min(10, 6) = 6

      // 2. When maxComplexLines == null (L47)
      final resWithoutCap = throttler.resolveComplexTargetLines(
        candidateCount: 20,
        defaultMaxLines: 15,
        performance: const PerformanceFeatures(
          complex: ComplexConfig(
            ratio: 0.5,
            maxLines: null,
          ),
        ),
      );
      expect(resWithoutCap, equals(10)); // max(1, 10) = 10

      // 3. When maxComplexLines == null and reduction brings to 0 (clamps to at least 1)
      final resClampedToOne = throttler.resolveComplexTargetLines(
        candidateCount: 20,
        defaultMaxLines: 15,
        performance: const PerformanceFeatures(
          complex: ComplexConfig(
            ratio: 1.0,
            maxLines: null,
          ),
        ),
      );
      expect(resClampedToOne, equals(1)); // max(1, 0) = 1

      // 4. Fallback when complexReductionRatio == null
      final resDefault = throttler.resolveComplexTargetLines(
        candidateCount: 20,
        defaultMaxLines: 15,
        performance: const PerformanceFeatures(complex: ComplexConfig(ratio: null)),
      );
      expect(resDefault, equals(15));
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
        performance: const PerformanceFeatures(complex: ComplexConfig(enabled: true)),
      );

      expect(filtered, equals(3));
    });
  });
}
