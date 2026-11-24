import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/src/rendering/line_style_palette.dart';

void main() {
  group('LineStylePalette Unit Tests', () {
    test('Initializes LUT and paints correctly', () {
      final palette = LineStylePalette(
        lineColor: const Color(0x80FFFFFF),
        lineWidth: 1.5,
        antiAlias: true,
      );

      expect(palette.lineColorLut.length, equals(256));
      expect(
        palette.lineBucketPaints.length,
        equals(LineStylePalette.numLineBuckets),
      );
      expect(palette.lineWidth, equals(1.5));
      expect(palette.antiAlias, isTrue);
      expect(palette.lineBucketPaints[0].strokeWidth, equals(1.5));
      expect(palette.lineBucketPaints[0].isAntiAlias, isTrue);
      expect(LineStylePalette.distBucketTable.length, equals(1025));
    });

    test(
      'In-place updates mutate existing paint objects without reallocation',
      () {
        final palette = LineStylePalette(
          lineColor: const Color(0x80FFFFFF),
          lineWidth: 1.5,
          antiAlias: true,
        );

        final originalPaints = palette.lineBucketPaints;
        final originalPaint0 = palette.lineBucketPaints[0];

        palette.updateWidth(2.5);
        expect(palette.lineWidth, equals(2.5));
        expect(identical(palette.lineBucketPaints, originalPaints), isTrue);
        expect(identical(palette.lineBucketPaints[0], originalPaint0), isTrue);
        expect(palette.lineBucketPaints[0].strokeWidth, equals(2.5));

        palette.updateAntiAlias(false);
        expect(palette.antiAlias, isFalse);
        expect(palette.lineBucketPaints[0].isAntiAlias, isFalse);

        palette.updateColor(const Color(0xFFFF0000));
        expect(palette.lineColor, equals(const Color(0xFFFF0000)));
      },
    );
  });
}
