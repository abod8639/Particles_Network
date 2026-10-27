import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/particles_network.dart';

/// Counts the draw calls the painter issues; ignores everything else.
class _CountingCanvas implements Canvas {
  int vertexCalls = 0;
  int rawLineCalls = 0;
  int lineCalls = 0;

  @override
  void drawVertices(ui.Vertices vertices, BlendMode blendMode, Paint paint) {
    vertexCalls++;
  }

  @override
  void drawRawPoints(ui.PointMode mode, Float32List points, Paint paint) {
    if (mode == ui.PointMode.lines) rawLineCalls++;
  }

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {
    lineCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

List<Particle> _particles(int count, Size size, [int seed = 3]) {
  final factory = DefaultParticleFactory(
    random: Random(seed),
    maxSpeed: 0.5,
    maxSize: 1.5,
    color: Colors.white,
  );
  return List<Particle>.generate(count, (_) => factory.createParticle(size));
}

OptimizedNetworkPainter _painter(
  List<Particle> particles,
  LineRenderer renderer, {
  bool isComplex = false,
  bool fastLineRendering = false,
  double lineWidth = 1.0,
  double devicePixelRatio = 1.0,
}) {
  return OptimizedNetworkPainter(
    particleCount: particles.length,
    particles: particles,
    touchPoint: null,
    lineDistance: 80,
    particleColor: Colors.white,
    lineColor: const Color(0xFF64FFB4),
    touchColor: Colors.amber,
    touchActivation: false,
    lineWidth: lineWidth,
    isComplex: isComplex,
    fill: true,
    drawNetwork: true,
    fastLineRendering: fastLineRendering,
    lineRenderer: renderer,
    devicePixelRatio: devicePixelRatio,
  );
}

Future<Uint8List> _render(OptimizedNetworkPainter painter, Size size) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  final data = await image.toByteData();
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  final String? dir = Platform.environment['LINE_RENDER_PNG_DIR'];
  if (dir != null && png != null) {
    File('$dir/${painter.lineRenderer.name}_w${painter.lineWidth}.png')
        .writeAsBytesSync(png.buffer.asUint8List());
  }
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}

/// Sum of the green channel, a proxy for drawn line coverage × opacity.
double _greenEnergy(Uint8List rgba) {
  double sum = 0;
  for (int i = 1; i < rgba.length; i += 4) {
    sum += rgba[i];
  }
  return sum;
}

void main() {
  group('LineVertexBatch', () {
    test('emits two triangles per segment around the segment axis', () {
      final batch = LineVertexBatch();
      batch.addSegments(
        Float32List.fromList([0, 0, 10, 0]),
        4,
        0x80FF0000,
        1.0,
      );

      expect(batch.lineCount, 1);
      expect(
        batch.positions,
        // A(0,1) B(0,-1) C(10,1) | C(10,1) B(0,-1) D(10,-1)
        [0, 1, 0, -1, 10, 1, 10, 1, 0, -1, 10, -1],
      );
      expect(batch.colors.toSet(), {
        Int32List.fromList([0x80FF0000])[0]
      });
    });

    test('skips zero-length segments', () {
      final batch = LineVertexBatch()
        ..addSegments(
            Float32List.fromList([5, 5, 5, 5, 0, 0, 0, 3]), 8, 0xFFFFFFFF, 0.5);
      expect(batch.lineCount, 1);
    });

    test('grows past its initial capacity and keeps earlier quads', () {
      final batch = LineVertexBatch();
      final segments = Float32List(4 * 2000);
      for (int i = 0; i < 2000; i++) {
        segments[i * 4] = i.toDouble();
        segments[i * 4 + 2] = i.toDouble();
        segments[i * 4 + 3] = 10;
      }
      batch.addSegments(segments, 4 * 1000, 0xFFFFFFFF, 0.5);
      batch.addSegments(
        Float32List.sublistView(segments, 4 * 1000),
        4 * 1000,
        0xFFFFFFFF,
        0.5,
      );

      expect(batch.lineCount, 2000);
      // First vertex of line 0 and of line 1999 (x offset by -halfWidth).
      expect(batch.positions[0], closeTo(-0.5, 1e-6));
      expect(batch.positions[1999 * 12], closeTo(1998.5, 1e-3));
    });

    test('clear() resets without shrinking', () {
      final batch = LineVertexBatch()
        ..addSegments(Float32List.fromList([0, 0, 1, 1]), 4, 0xFFFFFFFF, 1)
        ..clear();
      expect(batch.lineCount, 0);
      expect(batch.positions, isEmpty);
    });
  });

  group('OptimizedNetworkPainter with LineRenderer.vertices', () {
    const Size size = Size(400, 400);

    for (final (String name, bool complex, bool fast) in [
      ('batched', false, false),
      ('isComplex', true, false),
      ('fastLineRendering', false, true),
    ]) {
      test('$name: one drawVertices call, no stroked lines', () {
        final particles = _particles(400, size);
        final painter = _painter(
          particles,
          LineRenderer.vertices,
          isComplex: complex,
          fastLineRendering: fast,
        );
        final canvas = _CountingCanvas();
        painter.paint(canvas, size);

        expect(canvas.vertexCalls, 1);
        expect(canvas.rawLineCalls, 0);
        expect(canvas.lineCalls, 0);
        expect(painter.lastFrameLineCount, greaterThan(100));
      });

      test('$name: selects exactly the same lines as stroke mode', () {
        final particles = _particles(400, size);
        final stroke = _painter(
          particles,
          LineRenderer.stroke,
          isComplex: complex,
          fastLineRendering: fast,
        );
        final vertices = _painter(
          particles,
          LineRenderer.vertices,
          isComplex: complex,
          fastLineRendering: fast,
        );
        stroke.paint(_CountingCanvas(), size);
        vertices.paint(_CountingCanvas(), size);

        expect(vertices.lastFrameLineCount, stroke.lastFrameLineCount);
      });
    }

    test('small networks (< 30 particles) keep individual strokes', () {
      final painter = _painter(_particles(20, size), LineRenderer.vertices);
      final canvas = _CountingCanvas();
      painter.paint(canvas, size);
      expect(canvas.vertexCalls, 0);
    });

    test('renders comparable coverage to stroked lines', () async {
      final particles = _particles(400, size);
      final double stroke = _greenEnergy(
          await _render(_painter(particles, LineRenderer.stroke), size));
      final double vertices = _greenEnergy(
          await _render(_painter(particles, LineRenderer.vertices), size));

      expect(stroke, greaterThan(0));
      expect(vertices / stroke, inInclusiveRange(0.8, 1.25));
    });

    test('sub-pixel widths fade instead of disappearing', () async {
      final particles = _particles(400, size);
      final double full = _greenEnergy(await _render(
          _painter(particles, LineRenderer.vertices, lineWidth: 1.0), size));
      final double thin = _greenEnergy(await _render(
          _painter(particles, LineRenderer.vertices, lineWidth: 0.25), size));

      // Drawn at 1 px with 25% alpha: roughly a quarter of the energy.
      expect(thin / full, inInclusiveRange(0.15, 0.4));
    });
  });
}
