import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

/// Precomputed styling palette and lookup tables for connection line rendering.
///
/// Manages alpha color LUTs and pre-allocated bucket [Paint] objects to achieve
/// zero allocations per frame during line emission and drawing.
class LineStylePalette {
  /// Number of discrete opacity buckets for batched draw call submission.
  static const int numLineBuckets = 32;

  /// Shared static lookup table mapping distance ratio squared to bucket index.
  static final Int32List distBucketTable = _buildDistBucketTable();

  static Int32List _buildDistBucketTable() {
    final table = Int32List(1025);
    for (int i = 0; i <= 1024; i++) {
      final double ratio = math.sqrt(i / 1024.0);
      table[i] = ((1.0 - ratio) * (numLineBuckets - 1))
          .round()
          .clamp(0, numLineBuckets - 1);
    }
    return table;
  }

  /// Precomputed 256-entry ARGB color lookup table for individual line rendering.
  late final List<Color> lineColorLut;

  /// Pre-allocated [Paint] objects for each alpha bucket.
  late final List<Paint> lineBucketPaints;

  Color _lineColor;
  double _lineWidth;
  bool _antiAlias;

  Color get lineColor => _lineColor;
  double get lineWidth => _lineWidth;
  bool get antiAlias => _antiAlias;

  LineStylePalette({
    required Color lineColor,
    required double lineWidth,
    required bool antiAlias,
  })  : _lineColor = lineColor,
        _lineWidth = lineWidth,
        _antiAlias = antiAlias {
    lineColorLut = List<Color>.filled(256, lineColor);
    lineBucketPaints = List.generate(
      numLineBuckets,
      (_) => Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = lineWidth
        ..isAntiAlias = antiAlias,
      growable: false,
    );
    _rebuildPaintsAndLut(lineColor);
  }

  void _rebuildPaintsAndLut(Color color) {
    _lineColor = color;
    final int baseAlpha = (color.a * 255.0).round().clamp(0, 255);
    for (int i = 0; i < 256; i++) {
      lineColorLut[i] = color.withAlpha((i * baseAlpha) ~/ 255);
    }
    for (int b = 0; b < numLineBuckets; b++) {
      final int alpha = ((b * baseAlpha) ~/ (numLineBuckets - 1)).clamp(0, 255);
      lineBucketPaints[b].color = color.withAlpha(alpha);
    }
  }

  /// Updates line color in place without reallocating paint objects or lists.
  void updateColor(Color color) {
    if (color == _lineColor) return;
    _rebuildPaintsAndLut(color);
  }

  /// Updates stroke width in place across all bucket paints.
  void updateWidth(double width) {
    if (width == _lineWidth) return;
    _lineWidth = width;
    for (int b = 0; b < numLineBuckets; b++) {
      lineBucketPaints[b].strokeWidth = width;
    }
  }

  /// Updates anti-aliasing flag in place across all bucket paints.
  void updateAntiAlias(bool value) {
    if (value == _antiAlias) return;
    _antiAlias = value;
    for (int b = 0; b < numLineBuckets; b++) {
      lineBucketPaints[b].isAntiAlias = value;
    }
  }
}
