// ignore_for_file: deprecated_member_use
import 'package:flutter_test/flutter_test.dart';
// ignore: avoid_relative_lib_imports
import '../example/lib/benchmark_engine.dart';

void main() {
  group('SpatialBenchmarkEngine Verification', () {
    test(
        'Runs spatial benchmark properly and measures valid latencies across all scenarios',
        () {
      final engine = SpatialBenchmarkEngine(
        warmupFrames: 2,
        measuredFrames: 3,
      );

      for (final scenario in BenchmarkScenarioType.values) {
        final resultGrid = engine.runBenchmark(
          algorithm: SpatialAlgorithmType.sortedSpatialGrid,
          scenario: scenario,
        );

        expect(resultGrid.measuredFrames, equals(3));
        expect(resultGrid.avgTotalMs, isPositive);
        expect(resultGrid.effectiveFps, isPositive);
        expect(resultGrid.avgBuildMs, isPositive);
        expect(resultGrid.avgQueryMs, isPositive);
      }
    });

    test(
        'Runs clustering worst case scenario properly and measures valid latencies',
        () {
      final engine = SpatialBenchmarkEngine(
        warmupFrames: 2,
        measuredFrames: 5,
      );

      final resultGrid = engine.runBenchmark(
        algorithm: SpatialAlgorithmType.sortedSpatialGrid,
        scenario: BenchmarkScenarioType.clusteringWorstCase,
      );

      expect(resultGrid.avgTotalMs, isPositive);
      expect(resultGrid.effectiveFps, isPositive);
      expect(
          resultGrid.p99TotalMs, greaterThanOrEqualTo(resultGrid.p50TotalMs));
      expect(
          resultGrid.maxTotalMs, greaterThanOrEqualTo(resultGrid.minTotalMs));
      expect(resultGrid.avgBuildMs, isPositive);
      expect(resultGrid.avgQueryMs, isPositive);
    });
  });
}
