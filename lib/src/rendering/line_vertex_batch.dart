/// Triangle-based line rendering for the particle network.
///
/// Stroked lines (`drawRawPoints(PointMode.lines)` / `drawLine`) are
/// tessellated by the engine one segment at a time, which makes line-heavy
/// frames GPU bound. [LineVertexBatch] instead turns every segment into a
/// thin quad (two triangles) with per-vertex colors, so the whole network is
/// submitted as a single `drawVertices` call.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

/// How connection lines are rasterized.
enum LineRenderer {
  /// Engine strokes via `drawRawPoints` / `drawLine` (default, round caps).
  stroke,

  /// One `drawVertices` call with a two-triangle quad per line. Much cheaper
  /// on the GPU for large line counts; lines have square ends.
  vertices,
}

/// Accumulates line segments as triangle quads for one `drawVertices` call.
///
/// Buffers are reused across frames and only grow, so steady-state frames
/// perform no Dart heap allocations apart from the native [Vertices] handle.
class LineVertexBatch {
  // 6 vertices × 2 coordinates per line.
  static const int _floatsPerLine = 12;
  static const int _verticesPerLine = 6;

  Float32List _positions = Float32List(_floatsPerLine * 512);
  Int32List _colors = Int32List(_verticesPerLine * 512);
  int _lineCount = 0;

  /// Number of quads currently in the batch.
  int get lineCount => _lineCount;

  /// Raw vertex positions (x, y pairs) of the current batch.
  Float32List get positions =>
      Float32List.sublistView(_positions, 0, _lineCount * _floatsPerLine);

  /// Raw per-vertex ARGB colors of the current batch.
  Int32List get colors =>
      Int32List.sublistView(_colors, 0, _lineCount * _verticesPerLine);

  /// Removes all quads, keeping the allocated buffers.
  void clear() {
    _lineCount = 0;
  }

  void _ensureCapacity(int lines) {
    if (lines * _floatsPerLine <= _positions.length) return;
    final int newLines =
        math.max(lines, (_positions.length ~/ _floatsPerLine) * 2);
    final Float32List positions = Float32List(newLines * _floatsPerLine);
    positions.setRange(0, _lineCount * _floatsPerLine, _positions);
    _positions = positions;
    final Int32List colors = Int32List(newLines * _verticesPerLine);
    colors.setRange(0, _lineCount * _verticesPerLine, _colors);
    _colors = colors;
  }

  /// Appends the segments stored in [segments] as `x1, y1, x2, y2` groups
  /// (the first [floatCount] values), all with color [argb] and a total
  /// thickness of `2 * halfWidth`. Zero-length segments are skipped.
  void addSegments(
    Float32List segments,
    int floatCount,
    int argb,
    double halfWidth,
  ) {
    final int segmentCount = floatCount ~/ 4;
    if (segmentCount == 0) return;
    _ensureCapacity(_lineCount + segmentCount);

    final Float32List pos = _positions;
    final Int32List col = _colors;
    int p = _lineCount * _floatsPerLine;
    int c = _lineCount * _verticesPerLine;
    int added = 0;

    for (int i = 0; i < floatCount; i += 4) {
      final double x1 = segments[i];
      final double y1 = segments[i + 1];
      final double x2 = segments[i + 2];
      final double y2 = segments[i + 3];
      final double dx = x2 - x1;
      final double dy = y2 - y1;
      final double lenSq = dx * dx + dy * dy;
      if (lenSq < 1e-12) continue;

      // Perpendicular offset of length halfWidth.
      final double scale = halfWidth / math.sqrt(lenSq);
      final double nx = -dy * scale;
      final double ny = dx * scale;

      // Triangle 1: A, B, C — Triangle 2: C, B, D
      //   A = p1 + n, B = p1 - n, C = p2 + n, D = p2 - n
      final double ax = x1 + nx, ay = y1 + ny;
      final double bx = x1 - nx, by = y1 - ny;
      final double cx = x2 + nx, cy = y2 + ny;
      final double ex = x2 - nx, ey = y2 - ny;

      pos[p] = ax;
      pos[p + 1] = ay;
      pos[p + 2] = bx;
      pos[p + 3] = by;
      pos[p + 4] = cx;
      pos[p + 5] = cy;
      pos[p + 6] = cx;
      pos[p + 7] = cy;
      pos[p + 8] = bx;
      pos[p + 9] = by;
      pos[p + 10] = ex;
      pos[p + 11] = ey;
      p += _floatsPerLine;

      col[c] = argb;
      col[c + 1] = argb;
      col[c + 2] = argb;
      col[c + 3] = argb;
      col[c + 4] = argb;
      col[c + 5] = argb;
      c += _verticesPerLine;

      added++;
    }
    _lineCount += added;
  }

  /// Draws all accumulated quads with a single `drawVertices` call.
  ///
  /// Vertex colors are used as-is ([BlendMode.dst] ignores the paint color);
  /// [paint] still controls how the result composites onto the canvas.
  void draw(Canvas canvas, Paint paint) {
    if (_lineCount == 0) return;
    final Vertices vertices = Vertices.raw(
      VertexMode.triangles,
      positions,
      colors: colors,
    );
    canvas.drawVertices(vertices, BlendMode.dst, paint);
    vertices.dispose();
  }
}
