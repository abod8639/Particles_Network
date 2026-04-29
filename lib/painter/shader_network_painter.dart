/// GPU-accelerated painter for the particle network.
///
/// Uses a [FragmentShader] to render all particles and connection lines
/// in a **single draw call** on the GPU, replacing the CPU-bound
/// [OptimizedNetworkPainter] when shaders are available.
///
/// Uniform indices mirror the layout declared in `shaders/particles.frag`.
/// See that file for the authoritative index table.
library;

import 'dart:ui' show FragmentShader;

import 'package:flutter/material.dart';
import 'package:particles_network/model/particlemodel.dart';

/// Maximum particles the shader supports (matches the GLSL array size).
const int _kMaxShaderParticles = 150;

/// Flat-float start index for [uParticleSizes] array.
const int _kSizesStart = 22;

/// Flat-float start index for [uParticles] vec2 array (2 floats per entry).
const int _kPositionsStart = _kSizesStart + _kMaxShaderParticles; // = 172

/// Total floats consumed by the uniforms (for assertion / documentation).
// ignore: unused_element
const int _kTotalUniforms =
    _kPositionsStart + _kMaxShaderParticles * 2; // = 472

/// A [CustomPainter] that delegates all rendering to a [FragmentShader].
///
/// Every frame the painter writes particle positions and colours into the
/// shader's uniform buffer, then issues a single [Canvas.drawRect] covering
/// the full widget area.  The GPU resolves every pixel in parallel.
class ShaderNetworkPainter extends CustomPainter {
  /// The compiled + instantiated fragment shader (one per paint, no recreation).
  final FragmentShader shader;

  /// Snapshot of particle state for this frame.
  final List<Particle> particles;

  /// Current touch / cursor position, or [Offset.infinite] when inactive.
  final Offset? touchPoint;

  /// Maximum distance for drawing connection lines.
  final double lineDistance;

  /// Base colour for particles.
  final Color particleColor;

  /// Colour for connection lines.
  final Color lineColor;

  /// Colour for touch lines and the ripple ring.
  final Color touchColor;

  /// Whether touch interaction effects are enabled.
  final bool touchActivation;

  /// Width of connection / touch lines (pixels).
  final double lineWidth;

  /// When false, line rendering is skipped (lineDistance set to 0 in shader).
  final bool drawNetwork;

  /// Seconds elapsed since animation start (drives pulse & ripple timings).
  final double time;

  /// Intensity of the radial glow surrounding each particle (0–1).
  final double glowIntensity;

  const ShaderNetworkPainter({
    required this.shader,
    required this.particles,
    required this.touchPoint,
    required this.lineDistance,
    required this.particleColor,
    required this.lineColor,
    required this.touchColor,
    required this.touchActivation,
    required this.lineWidth,
    required this.drawNetwork,
    required this.time,
    this.glowIntensity = 0.3,
  });

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Returns [true] when there is an active touch within a finite position.
  bool get _hasTouchPoint =>
      touchActivation &&
      touchPoint != null &&
      touchPoint!.isFinite &&
      touchPoint != Offset.infinite;

  // ── Paint ─────────────────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    final bool touchActive = _hasTouchPoint;
    final Offset touch =
        touchActive ? touchPoint! : const Offset(-9999, -9999);

    final int count = particles.length.clamp(0, _kMaxShaderParticles);

    // ── Write uniforms in declaration order (matches particles.frag) ────────
    int idx = 0;

    // vec2  uResolution
    shader.setFloat(idx++, size.width);
    shader.setFloat(idx++, size.height);

    // float uTime
    shader.setFloat(idx++, time);

    // float uLineDistance  (0 disables line loop in the shader)
    shader.setFloat(idx++, drawNetwork ? lineDistance : 0.0);

    // float uParticleCount
    shader.setFloat(idx++, count.toDouble());

    // vec4  uParticleColor
    shader.setFloat(idx++, particleColor.r);
    shader.setFloat(idx++, particleColor.g);
    shader.setFloat(idx++, particleColor.b);
    shader.setFloat(idx++, particleColor.a);

    // vec4  uLineColor
    shader.setFloat(idx++, lineColor.r);
    shader.setFloat(idx++, lineColor.g);
    shader.setFloat(idx++, lineColor.b);
    shader.setFloat(idx++, lineColor.a);

    // vec2  uTouchPoint
    shader.setFloat(idx++, touch.dx);
    shader.setFloat(idx++, touch.dy);

    // float uTouchActive
    shader.setFloat(idx++, touchActive ? 1.0 : 0.0);

    // vec4  uTouchColor
    shader.setFloat(idx++, touchColor.r);
    shader.setFloat(idx++, touchColor.g);
    shader.setFloat(idx++, touchColor.b);
    shader.setFloat(idx++, touchColor.a);

    // float uGlowIntensity
    shader.setFloat(idx++, glowIntensity);

    // float uLineWidth
    shader.setFloat(idx++, lineWidth);

    // ── float uParticleSizes[150] ──────────────────────────────────────────
    assert(idx == _kSizesStart);
    for (int i = 0; i < _kMaxShaderParticles; i++) {
      shader.setFloat(idx++, i < count ? particles[i].size : 0.0);
    }

    // ── vec2 uParticles[150] ──────────────────────────────────────────────
    assert(idx == _kPositionsStart);
    for (int i = 0; i < _kMaxShaderParticles; i++) {
      if (i < count) {
        shader.setFloat(idx++, particles[i].position.dx);
        shader.setFloat(idx++, particles[i].position.dy);
      } else {
        shader.setFloat(idx++, -9999.0);
        shader.setFloat(idx++, -9999.0);
      }
    }

    // ── Single GPU draw call ───────────────────────────────────────────────
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = shader,
    );
  }

  // ── shouldRepaint ─────────────────────────────────────────────────────────

  @override
  bool shouldRepaint(ShaderNetworkPainter old) {
    // The animation is continuous; always repaint.
    // Flutter's scheduler guarantees we only get called when a new frame
    // is actually needed (driven by the Ticker in ParticleNetworkState).
    return true;
  }
}
