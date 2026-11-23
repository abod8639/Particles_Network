import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/particles_network.dart';

void main() {
  group('PerformanceFeatures Phase 1 Audit', () {
    test(
        'assertion guards on cappedDistanceFactor, spatialCellMultiplier, maxConnections, maxLines across constructors',
        () {
      expect(
        () => PerformanceFeatures(cappedDistanceFactor: -0.1),
        throwsAssertionError,
      );
      expect(
        () => PerformanceFeatures(cappedDistanceFactor: 0.0),
        throwsAssertionError,
      );
      expect(
        () => PerformanceFeatures(cappedDistanceFactor: 1.1),
        throwsAssertionError,
      );
      expect(
        () => PerformanceFeatures(spatialCellMultiplier: -0.5),
        throwsAssertionError,
      );
      expect(
        () => PerformanceFeatures(spatialCellMultiplier: 0.0),
        throwsAssertionError,
      );
      expect(
        () => PerformanceFeatures(maxConnectionsPerParticle: 0),
        throwsAssertionError,
      );
      expect(
        () => PerformanceFeatures(maxConnectionsPerParticle: -1),
        throwsAssertionError,
      );
      expect(
        () => PerformanceFeatures(maxLinesPerFrame: 0),
        throwsAssertionError,
      );
      expect(
        () => PerformanceFeatures(maxLinesPerFrame: -10),
        throwsAssertionError,
      );

      // Preset constructors must also guard invariants
      expect(
        () => ComplexConfig(ratio: 1.5),
        throwsAssertionError,
      );
      expect(
        () => PerformanceFeatures.auto(maxConnectionsPerParticle: -1),
        throwsAssertionError,
      );
      expect(
        () => PerformanceFeatures.balanced(cappedDistanceFactor: 0.0),
        throwsAssertionError,
      );
    });

    test('copyWith supports both camelCase and legacy lowercase clear flags',
        () {
      const initial = PerformanceFeatures(
        complex: ComplexConfig(
          ratio: 0.6,
          maxLines: 5,
          densityFactor: 0.4,
        ),
      );

      // Using idiomatic camelCase
      final clearedCamel = initial.copyWith(
        clearComplexReductionRatio: true,
        clearComplexDensityFactor: true,
      );
      expect(clearedCamel.complexReductionRatio, isNull);
      expect(clearedCamel.complexDensityFactor, isNull);

      // Using legacy lowercase
      final clearedLegacy = initial.copyWith(
        clearcomplexReductionRatio: true,
        clearcomplexDensityFactor: true,
      );
      expect(clearedLegacy.complexReductionRatio, isNull);
      expect(clearedLegacy.complexDensityFactor, isNull);
    });
  });
}
