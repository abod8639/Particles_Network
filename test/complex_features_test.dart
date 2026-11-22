import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/particles_network.dart';

void main() {
  group('ComplexFeatures', () {
    test('default constructor has correct default values', () {
      const config = ComplexFeatures();

      expect(config.enabled, isFalse);
      expect(config.ratio, isNull);
      expect(config.maxLines, isNull);
      expect(config.densityFactor, isNull);

      // Compatibility getters
      expect(config.isComplex, isFalse);
      expect(config.complexRatio, isNull);
      expect(config.complexReductionRatio, isNull);
      expect(config.maxComplexLines, isNull);
      expect(config.complexDensityFactor, isNull);
    });

    test('auto preset has recommended high-density defaults', () {
      const config = ComplexFeatures.auto();

      expect(config.enabled, isTrue);
      expect(config.ratio, isNull);
      expect(config.maxLines, equals(3));
      expect(config.densityFactor, equals(0.60));

      expect(config.isComplex, isTrue);
      expect(config.maxComplexLines, equals(3));
      expect(config.complexDensityFactor, equals(0.60));
    });

    test('auto preset allows custom ratio and overrides', () {
      const config = ComplexFeatures.auto(
        ratio: 0.4,
        maxLines: 5,
        densityFactor: 0.75,
      );

      expect(config.enabled, isTrue);
      expect(config.ratio, equals(0.4));
      expect(config.maxLines, equals(5));
      expect(config.densityFactor, equals(0.75));
    });

    test('disabled preset clears all settings', () {
      const config = ComplexFeatures.disabled();

      expect(config.enabled, isFalse);
      expect(config.ratio, isNull);
      expect(config.maxLines, isNull);
      expect(config.densityFactor, isNull);
      expect(config.isComplex, isFalse);
    });

    test('asserts ratio bounds between 0.0 and 1.0', () {
      expect(() => ComplexFeatures(ratio: -0.1), throwsAssertionError);
      expect(() => ComplexFeatures(ratio: 1.1), throwsAssertionError);
      expect(() => ComplexFeatures(ratio: 0.0), returnsNormally);
      expect(() => ComplexFeatures(ratio: 1.0), returnsNormally);
      expect(() => ComplexFeatures(ratio: 0.5), returnsNormally);
    });

    test('asserts maxLines is strictly positive', () {
      expect(() => ComplexFeatures(maxLines: 0), throwsAssertionError);
      expect(() => ComplexFeatures(maxLines: -1), throwsAssertionError);
      expect(() => ComplexFeatures(maxLines: 1), returnsNormally);
      expect(() => ComplexFeatures(maxLines: 5), returnsNormally);
    });

    test('asserts densityFactor is strictly positive', () {
      expect(() => ComplexFeatures(densityFactor: 0.0), throwsAssertionError);
      expect(() => ComplexFeatures(densityFactor: -0.5), throwsAssertionError);
      expect(() => ComplexFeatures(densityFactor: 0.1), returnsNormally);
      expect(() => ComplexFeatures(densityFactor: 0.60), returnsNormally);
    });

    test('copyWith updates specified fields and preserves untouched fields', () {
      const original = ComplexFeatures(
        enabled: false,
        ratio: 0.2,
        maxLines: 4,
        densityFactor: 0.5,
      );

      final updated = original.copyWith(
        enabled: true,
        ratio: 0.6,
      );

      expect(updated.enabled, isTrue);
      expect(updated.ratio, equals(0.6));
      expect(updated.maxLines, equals(4));
      expect(updated.densityFactor, equals(0.5));
    });

    test('copyWith allows clearing nullable fields with clear flags', () {
      const original = ComplexFeatures(
        enabled: true,
        ratio: 0.5,
        maxLines: 4,
        densityFactor: 0.60,
      );

      final cleared = original.copyWith(
        clearRatio: true,
        clearMaxLines: true,
        clearDensityFactor: true,
      );

      expect(cleared.enabled, isTrue);
      expect(cleared.ratio, isNull);
      expect(cleared.maxLines, isNull);
      expect(cleared.densityFactor, isNull);
    });

    test('equality and hashCode contract', () {
      const config1 = ComplexFeatures(
        enabled: true,
        ratio: 0.4,
        maxLines: 3,
        densityFactor: 0.60,
      );

      const config2 = ComplexFeatures(
        enabled: true,
        ratio: 0.4,
        maxLines: 3,
        densityFactor: 0.60,
      );

      const config3 = ComplexFeatures(
        enabled: false,
        ratio: 0.4,
        maxLines: 3,
        densityFactor: 0.60,
      );

      expect(config1, equals(config2));
      expect(config1.hashCode, equals(config2.hashCode));
      expect(config1, isNot(equals(config3)));
      expect(config1.hashCode, isNot(equals(config3.hashCode)));
    });

    test('toString contains class name and properties', () {
      const config = ComplexFeatures(
        enabled: true,
        ratio: 0.35,
        maxLines: 4,
        densityFactor: 0.65,
      );

      final str = config.toString();
      expect(str, contains('ComplexFeatures('));
      expect(str, contains('enabled: true'));
      expect(str, contains('ratio: 0.35'));
      expect(str, contains('maxLines: 4'));
      expect(str, contains('densityFactor: 0.65'));
    });
  });
}
