/// Configuration class for particle network connection lines and visual styling.
library;

import 'package:flutter/widgets.dart';
import 'package:particles_network/src/rendering/line_vertex_batch.dart';

/// Configuration class for particle connection lines, styling, and rendering backend.
///
/// Encapsulates all connection network properties including whether lines are rendered ([enabled]),
/// connection reach radius ([distance]), stroke width ([width]), base line color ([color]),
/// and GPU rasterization backend ([renderer]).
///
/// Performance Architecture:
/// * **[LineRenderer.vertices] (Recommended / Default)**: Delivers **10x–20x GPU raster acceleration**
///   compared to [LineRenderer.stroke]. Instead of issuing individual stroke segments that incur
///   per-line GPU tessellation overhead (~7 µs per line), it batch-expands connections into indexed
///   triangle quads (4 vertices, 6 shared indices) and submits them in a single `canvas.drawVertices`
///   call per opacity level. It reduces memory payload from 96 down to 44 bytes per line, eliminating
///   GPU raster bottlenecks and sustaining smooth 60/120 FPS even with 1,000+ to 20,000 particles.
/// * **[LineRenderer.stroke]**: Uses native engine Canvas strokes (`drawLine` / `drawRawPoints`
///   with round caps). While visually smooth with rounded ends, stroke tessellation overhead scales
///   rapidly and can bottleneck the GPU rasterizer in line-dense scenes.
///
/// Example:
/// ```dart
/// const network = NetworkFeatures(
///   enabled: true,
///   width: 0.8,
///   distance: 80.0,
///   color: Color(0xFF38BDF8),
///   renderer: LineRenderer.vertices, // 10x–20x GPU raster acceleration
/// );
/// ```
@immutable
class NetworkFeatures {
  /// Whether connection lines between neighboring particles are calculated and drawn.
  ///
  /// When `true`, lines connect neighboring particles within [distance].
  /// When `false`, line calculations and drawing are completely bypassed, rendering
  /// only particle discs and saving substantial CPU/GPU cycles.
  ///
  /// Defaults to `true`.
  final bool enabled;

  /// Stroke width of connection lines between particles in logical pixels.
  ///
  /// Lines thinner than 1 physical pixel are automatically rendered with proportionally
  /// reduced opacity when using [LineRenderer.vertices] to eliminate visual aliasing dropouts.
  ///
  /// Defaults to `0.5`.
  final double width;

  /// Maximum connection distance between particles in logical pixels.
  ///
  /// Two particles connect with a line if the distance between them is less than [distance].
  /// Lines fade out smoothly with distance, reaching full transparency at [distance].
  /// Also serves as the default reach for touch interactions when [TouchFeatures.distance] is `null`.
  ///
  /// Defaults to `100.0`.
  final double distance;

  /// Base color used to render connecting lines between particles.
  ///
  /// Line opacity scales dynamically with particle proximity, fading from full opacity
  /// when particles touch to completely transparent at [distance].
  ///
  /// Defaults to `const Color.fromARGB(255, 100, 255, 180)` (cyan-green).
  final Color color;

  /// The rasterization backend used to render connection lines on the GPU.
  ///
  /// * [LineRenderer.vertices] (Recommended / Default): Submits lines as indexed triangle quads
  ///   in batched `canvas.drawVertices` calls. Delivers a **10x–20x GPU raster speedup** over [LineRenderer.stroke],
  ///   reducing vertex payload from 96 bytes down to 44 bytes per line and completely eliminating per-segment GPU
  ///   stroke tessellation bottlenecks (~7 µs per line). This is essential for sustaining smooth 60/120 FPS
  ///   with 300+ up to 20,000 particles (lines render with crisp square ends).
  /// * [LineRenderer.stroke]: Uses native engine Canvas strokes (`drawLine` / `drawRawPoints`
  ///   with round caps). While it produces rounded ends, stroke tessellation overhead runs on the GPU
  ///   raster thread for every individual line segment, leading to frame drops and GPU saturation in dense scenes.
  ///
  /// Defaults to [LineRenderer.vertices].
  final LineRenderer renderer;

  /// Compatibility alias for [width].
  @Deprecated(
    'lineWidth was renamed to width inside NetworkFeatures. '
    'Use NetworkFeatures.width instead. '
    'This property will be removed in particles_network 2.0.0.',
  )
  double get lineWidth => width;

  /// Compatibility alias for [distance].
  @Deprecated(
    'lineDistance was renamed to distance inside NetworkFeatures. '
    'Use NetworkFeatures.distance instead. '
    'This property will be removed in particles_network 2.0.0.',
  )
  double get lineDistance => distance;

  /// Compatibility alias for [color].
  @Deprecated(
    'lineColor was renamed to color inside NetworkFeatures. '
    'Use NetworkFeatures.color instead. '
    'This property will be removed in particles_network 2.0.0.',
  )
  Color get lineColor => color;

  /// Compatibility alias for [enabled].
  @Deprecated(
    'drawNetwork was renamed to enabled inside NetworkFeatures. '
    'Use NetworkFeatures.enabled instead. '
    'This property will be removed in particles_network 2.0.0.',
  )
  bool get drawNetwork => enabled;

  /// Compatibility alias for [renderer].
  @Deprecated(
    'lineRenderer was renamed to renderer inside NetworkFeatures. '
    'Use NetworkFeatures.renderer instead. '
    'This property will be removed in particles_network 2.0.0.',
  )
  LineRenderer get lineRenderer => renderer;

  /// Creates a [NetworkFeatures] configuration with customizable appearance and rendering backend.
  ///
  /// Parameters:
  /// * [enabled]: Whether connection lines are rendered. Defaults to `true`.
  /// * [width]: Stroke width of connection lines. Defaults to `0.5`.
  /// * [distance]: Max proximity distance for connection lines. Defaults to `100.0`.
  /// * [color]: Color for connection lines. Defaults to `const Color.fromARGB(255, 100, 255, 180)`.
  /// * [renderer]: Rasterization backend engine. Defaults to [LineRenderer.vertices] for
  ///   maximum hardware-accelerated performance (10x–20x faster than [LineRenderer.stroke]).
  const NetworkFeatures({
    bool? enabled,
    @Deprecated(
      'drawNetwork was renamed to enabled inside NetworkFeatures. '
      'Use NetworkFeatures(enabled: ...) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    bool? drawNetwork,
    double? width,
    @Deprecated(
      'lineWidth was renamed to width inside NetworkFeatures. '
      'Use NetworkFeatures(width: ...) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    double? lineWidth,
    double? distance,
    @Deprecated(
      'lineDistance was renamed to distance inside NetworkFeatures. '
      'Use NetworkFeatures(distance: ...) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    double? lineDistance,
    Color? color,
    @Deprecated(
      'lineColor was renamed to color inside NetworkFeatures. '
      'Use NetworkFeatures(color: ...) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    Color? lineColor,
    LineRenderer? renderer,
    @Deprecated(
      'lineRenderer was renamed to renderer inside NetworkFeatures. '
      'Use NetworkFeatures(renderer: ...) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    LineRenderer? lineRenderer,
  })  : enabled = enabled ?? drawNetwork ?? true,
        width = width ?? lineWidth ?? 0.5,
        distance = distance ?? lineDistance ?? 100.0,
        color = color ?? lineColor ?? const Color.fromARGB(255, 100, 255, 180),
        renderer = renderer ?? lineRenderer ?? LineRenderer.vertices;

  /// Creates a copy of this [NetworkFeatures] configuration with updated parameters.
  NetworkFeatures copyWith({
    bool? enabled,
    @Deprecated(
      'drawNetwork was renamed to enabled inside NetworkFeatures. '
      'Use NetworkFeatures.copyWith(enabled: ...) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    bool? drawNetwork,
    double? width,
    @Deprecated(
      'lineWidth was renamed to width inside NetworkFeatures. '
      'Use NetworkFeatures.copyWith(width: ...) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    double? lineWidth,
    double? distance,
    @Deprecated(
      'lineDistance was renamed to distance inside NetworkFeatures. '
      'Use NetworkFeatures.copyWith(distance: ...) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    double? lineDistance,
    Color? color,
    @Deprecated(
      'lineColor was renamed to color inside NetworkFeatures. '
      'Use NetworkFeatures.copyWith(color: ...) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    Color? lineColor,
    LineRenderer? renderer,
    @Deprecated(
      'lineRenderer was renamed to renderer inside NetworkFeatures. '
      'Use NetworkFeatures.copyWith(renderer: ...) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    LineRenderer? lineRenderer,
  }) {
    return NetworkFeatures(
      enabled: enabled ?? drawNetwork ?? this.enabled,
      width: width ?? lineWidth ?? this.width,
      distance: distance ?? lineDistance ?? this.distance,
      color: color ?? lineColor ?? this.color,
      renderer: renderer ?? lineRenderer ?? this.renderer,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkFeatures &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          width == other.width &&
          distance == other.distance &&
          color == other.color &&
          renderer == other.renderer;

  @override
  int get hashCode => Object.hash(
        enabled,
        width,
        distance,
        color,
        renderer,
      );

  @override
  String toString() =>
      'NetworkFeatures(enabled: $enabled, width: $width, '
      'distance: $distance, color: $color, renderer: $renderer)';
}
