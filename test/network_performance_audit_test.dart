import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/particles_network.dart';

void main() {
  group('NetworkPerformance Phase 1 Audit', () {
    test(
        'assertion guards on cappedDistanceFactor, spatialCellMultiplier, maxConnections, maxLines across constructors',
        () {
      expect(
        () => NetworkPerformance(cappedDistanceFactor: -0.1),
        throwsAssertionError,
      );
      expect(
        () => NetworkPerformance(cappedDistanceFactor: 0.0),
        throwsAssertionError,
      );
      expect(
        () => NetworkPerformance(cappedDistanceFactor: 1.1),
        throwsAssertionError,
      );
      expect(
        () => NetworkPerformance(spatialCellMultiplier: -0.5),
        throwsAssertionError,
      );
      expect(
        () => NetworkPerformance(spatialCellMultiplier: 0.0),
        throwsAssertionError,
      );
      expect(
        () => NetworkPerformance(maxConnectionsPerParticle: 0),
        throwsAssertionError,
      );
      expect(
        () => NetworkPerformance(maxConnectionsPerParticle: -1),
        throwsAssertionError,
      );
      expect(
        () => NetworkPerformance(maxLinesPerFrame: 0),
        throwsAssertionError,
      );
      expect(
        () => NetworkPerformance(maxLinesPerFrame: -10),
        throwsAssertionError,
      );

      // Preset constructors must also guard invariants
      expect(
        () => NetworkPerformance.highPerformance(complexReductionRatio: 1.5),
        throwsAssertionError,
      );
      expect(
        () => NetworkPerformance.auto(maxConnectionsPerParticle: -1),
        throwsAssertionError,
      );
      expect(
        () => NetworkPerformance.balanced(cappedDistanceFactor: 0.0),
        throwsAssertionError,
      );
    });

    test('copyWith supports both camelCase and legacy lowercase clear flags',
        () {
      const initial = NetworkPerformance(
        complexReductionRatio: 0.6,
        maxComplexLines: 5,
        complexDensityFactor: 0.4,
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
