import 'package:flutter/material.dart';

// Optimized line batch drawing by opacity for reduced GPU state changes
//
// Instead of changing paint color for every line, this class groups
// lines by opacity and draws all lines with the same color together.
// This significantly reduces GPU state changes.
class LineRenderBatch {
  // Map of opacity level to list of line pairs
  final Map<int, List<(Offset, Offset)>> linesByOpacity = {};

  // Add a line to the batch
  void addLine(Offset p1, Offset p2, int opacity) {
    linesByOpacity.putIfAbsent(opacity, () => []).add((p1, p2));
  }

  // Clear all batched lines
  void clear() {
    linesByOpacity.clear();
  }

  // Get number of unique opacity levels
  int get opacityLevelCount => linesByOpacity.length;

  // Get total number of lines
  int get lineCount {
    var total = 0;
    for (final lines in linesByOpacity.values) {
      total += lines.length;
    }
    return total;
  }

  // Draw all batched lines using a single paint object
  //
  // This method iterates through opacity levels and draws all lines
  // with the same opacity together, minimizing GPU state changes.
  void drawBatch(Canvas canvas, Paint paint, Color baseColor) {
    // Sort by opacity to ensure consistent ordering
    final sortedOpacities = linesByOpacity.keys.toList()..sort();

    for (final opacity in sortedOpacities) {
      // Update paint color once per opacity level
      paint.color = baseColor.withAlpha(opacity);

      // Draw all lines with this opacity
      final lines = linesByOpacity[opacity]!;
      for (final (p1, p2) in lines) {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }
}

// Reusable batch renderer for efficient line drawing
class BatchLineRenderer {
  late final LineRenderBatch _batch;

  // Create a batch renderer
  BatchLineRenderer() {
    _batch = LineRenderBatch();
  }

  // Get the internal batch (for testing/inspection)
  LineRenderBatch get batch => _batch;

  // Begin a new batch
  void startBatch() {
    _batch.clear();
  }

  // Add a line with opacity calculation
  void addLineWithOpacity(
    Offset p1,
    Offset p2,
    double distance,
    double maxDistance,
  ) {
    final int opacity = ((1 - distance / maxDistance) * 255).toInt().clamp(
          0,
          255,
        );
    _batch.addLine(p1, p2, opacity);
  }

  // Draw the current batch
  void endBatch(Canvas canvas, Paint paint, Color baseColor) {
    _batch.drawBatch(canvas, paint, baseColor);
  }

  // Get batch statistics
  ({int opacityLevels, int totalLines}) getStats() {
    return (
      opacityLevels: _batch.opacityLevelCount,
      totalLines: _batch.lineCount,
    );
  }
}
