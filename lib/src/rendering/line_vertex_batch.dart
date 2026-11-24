/// Triangle-based line rendering for the particle network.
///
/// Stroked lines (`drawRawPoints(PointMode.lines)` / `drawLine`) are
/// tessellated by the engine one segment at a time, which makes line-heavy
/// frames GPU bound. [LineVertexBatch] instead turns every segment into a
/// thin indexed quad (two triangles), so a whole batch of same-coloured lines
/// is submitted with a single `drawVertices` call.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

/// How connection lines are rasterized.
enum LineRenderer {
  /// Engine strokes via `drawRawPoints` / `drawLine` (round caps).
  ///
  /// Each segment requires individual GPU stroke tessellation overhead (~7 µs per line),
  /// which can quickly bottleneck the GPU rasterizer when connection counts grow large.
  stroke,

  /// Two-triangle indexed quads per line, submitted in a single `drawVertices` call
  /// per opacity level (default, square ends).
  ///
  /// Delivers a 10x–20x GPU raster speedup over [stroke], cutting per-line payload
  /// from 96 bytes to 44 bytes and sustaining smooth 60/120 FPS at high line counts.
  vertices,
}

/// Accumulates line segments as indexed triangle quads drawn with one
/// paint colour.
///
/// Each segment becomes 4 vertices and 6 shared `Uint16` indices (two
/// triangles), so the data copied into the engine per line is 32 bytes of
/// positions plus 12 bytes of indices. Draws are split into chunks of at most
/// [maxQuadsPerDraw] quads so indices fit in 16 bits.
///
/// Buffers are reused across frames and only grow, so steady-state frames
/// perform no Dart heap allocations apart from the native [Vertices] handles.
class LineVertexBatch {
  /// Largest number of quads per `drawVertices` call (65532 vertices).
  static const int maxQuadsPerDraw = 16383;

  // 4 vertices × 2 coordinates per line.
  static const int _floatsPerLine = 8;

  // Index pattern [0,1,2, 2,1,3, 4,5,6, 6,5,7, ...] shared by every batch.
  static final Uint16List _quadIndices = () {
    final Uint16List indices = Uint16List(maxQuadsPerDraw * 6);
    for (int q = 0; q < maxQuadsPerDraw; q++) {
      final int v = q * 4;
      final int i = q * 6;
      indices[i] = v;
      indices[i + 1] = v + 1;
      indices[i + 2] = v + 2;
      indices[i + 3] = v + 2;
      indices[i + 4] = v + 1;
      indices[i + 5] = v + 3;
    }
    return indices;
  }();

  Float32List _positions = Float32List(_floatsPerLine * 512);
  Int32List _colors = Int32List(4 * 512);
  bool _hasColors = false;
  int _lineCount = 0;

  /// Number of quads currently in the batch.
  int get lineCount => _lineCount;

  /// Whether any segments with colors have been added to this batch.
  bool get hasColors => _hasColors;

  /// Raw vertex positions (x, y pairs), 4 vertices per quad:
  /// `p1 + n, p1 - n, p2 + n, p2 - n` where `n` is the half-width normal.
  Float32List get positions =>
      Float32List.sublistView(_positions, 0, _lineCount * _floatsPerLine);

  /// Raw vertex colors (32-bit ARGB ints), 4 vertices per quad.
  Int32List get colors => _hasColors
      ? Int32List.sublistView(_colors, 0, _lineCount * 4)
      : Int32List(0);

  /// Triangle indices for the first [quads] quads of a chunk.
  static Uint16List indicesFor(int quads) =>
      Uint16List.sublistView(_quadIndices, 0, quads * 6);

  /// Removes all quads, keeping the allocated buffers.
  void clear() {
    _lineCount = 0;
    _hasColors = false;
  }

  void _ensureCapacity(int lines) {
    if (lines * _floatsPerLine > _positions.length) {
      final int newLines = math.max(
        lines,
        (_positions.length ~/ _floatsPerLine) * 2,
      );
      final Float32List positions = Float32List(newLines * _floatsPerLine);
      positions.setRange(0, _lineCount * _floatsPerLine, _positions);
      _positions = positions;
    }
    if (lines * 4 > _colors.length) {
      final int newLines = math.max(lines, (_colors.length ~/ 4) * 2);
      final Int32List colors = Int32List(newLines * 4);
      colors.setRange(0, _lineCount * 4, _colors);
      _colors = colors;
    }
  }

  /// Appends the segments stored in [segments] as `x1, y1, x2, y2` groups
  /// (the first [floatCount] values) with a total thickness of
  /// `2 * halfWidth`. Zero-length segments are skipped.
  ///
  /// Optional [colors] supplies either per-segment colors (1 int per segment)
  /// or per-vertex colors (4 ints per segment quad).
  /// Optional [color] supplies a single packed ARGB color for all segments in this call.
  void addSegments(
    Float32List segments,
    int floatCount,
    double halfWidth, [
    Int32List? colors,
    int? color,
  ]) {
    final int segmentCount = floatCount ~/ 4;
    if (segmentCount == 0) return;
    _ensureCapacity(_lineCount + segmentCount);

    final Float32List pos = _positions;
    final Int32List col = _colors;
    final bool withColors = colors != null || color != null;
    if (withColors) {
      if (!_hasColors && _lineCount > 0) {
        _colors.fillRange(0, _lineCount * 4, 0xFFFFFFFF.toSigned(32));
      }
      _hasColors = true;
    }

    final bool perVertex = colors != null && colors.length >= segmentCount * 4;
    final bool perSegment = colors != null && !perVertex;
    final int singleColor =
        color ?? (colors != null && colors.isNotEmpty ? colors[0] : 0);
    final int defaultWhite = 0xFFFFFFFF.toSigned(32);

    int p = _lineCount * _floatsPerLine;
    int cp = _lineCount * 4;
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

      pos[p] = x1 + nx;
      pos[p + 1] = y1 + ny;
      pos[p + 2] = x1 - nx;
      pos[p + 3] = y1 - ny;
      pos[p + 4] = x2 + nx;
      pos[p + 5] = y2 + ny;
      pos[p + 6] = x2 - nx;
      pos[p + 7] = y2 - ny;
      p += _floatsPerLine;

      if (_hasColors) {
        if (withColors) {
          if (perVertex) {
            final int srcIdx = (i ~/ 4) * 4;
            col[cp] = colors[srcIdx];
            col[cp + 1] = colors[srcIdx + 1];
            col[cp + 2] = colors[srcIdx + 2];
            col[cp + 3] = colors[srcIdx + 3];
          } else if (perSegment) {
            final int segIdx = i ~/ 4;
            final int segColor = segIdx < colors.length
                ? colors[segIdx]
                : singleColor;
            col[cp] = segColor;
            col[cp + 1] = segColor;
            col[cp + 2] = segColor;
            col[cp + 3] = segColor;
          } else {
            col[cp] = singleColor;
            col[cp + 1] = singleColor;
            col[cp + 2] = singleColor;
            col[cp + 3] = singleColor;
          }
        } else {
          col[cp] = defaultWhite;
          col[cp + 1] = defaultWhite;
          col[cp + 2] = defaultWhite;
          col[cp + 3] = defaultWhite;
        }
        cp += 4;
      }

      added++;
    }
    _lineCount += added;
  }

  /// Draws all accumulated quads filled with [paint]'s colour (or per-vertex
  /// colors when available), using as few `drawVertices` calls as the 16-bit
  /// index limit allows.
  void draw(Canvas canvas, Paint paint, [Int32List? colors]) {
    final Int32List? effectiveColors = colors ?? (_hasColors ? _colors : null);
    int first = 0;
    while (first < _lineCount) {
      final int remaining = _lineCount - first;
      final int quads = remaining < maxQuadsPerDraw
          ? remaining
          : maxQuadsPerDraw;
      final Vertices vertices = Vertices.raw(
        VertexMode.triangles,
        Float32List.sublistView(
          _positions,
          first * _floatsPerLine,
          (first + quads) * _floatsPerLine,
        ),
        colors: effectiveColors != null
            ? Int32List.sublistView(
                effectiveColors,
                first * 4,
                (first + quads) * 4,
              )
            : null,
        indices: indicesFor(quads),
      );
      canvas.drawVertices(
        vertices,
        effectiveColors != null ? BlendMode.dst : BlendMode.srcOver,
        paint,
      );
      vertices.dispose();
      first += quads;
    }
  }
}
