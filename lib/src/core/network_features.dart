/// Configuration class for particle network connection lines and visual styling.
library;

import 'package:flutter/widgets.dart';
import 'package:particles_network/src/rendering/line_vertex_batch.dart';

/// Configuration class for particle connection lines, styling, and rendering backend.
///
/// Encapsulates all connection network properties including whether lines are rendered ([enabled]),
/// connection reach radius ([distance]), stroke width ([width]), base line color ([color]),
/// and GPU rasterization backend ([lineRenderer]).
///
/// Example:
/// ```dart
/// const network = NetworkFeatures(
///   enabled: true,
///   width: 0.8,
///   distance: 80.0,
///   color: Color(0xFF38BDF8),
///   lineRenderer: LineRenderer.vertices,
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
  /// * [LineRenderer.vertices]: Submits lines as indexed triangle quads in batched `drawVertices`
  ///   calls. Substantially reduces GPU overhead for high line counts (lines render with square ends).
  /// * [LineRenderer.stroke]: Uses native engine Canvas strokes (`drawLine` / `drawRawPoints`
  ///   with rounded ends).
  ///
  /// Defaults to [LineRenderer.vertices].
  final LineRenderer renderer;

  /// Creates a [NetworkFeatures] configuration with customizable appearance and rendering backend.
  ///
  /// Parameters:
  /// * [enabled]: Whether connection lines are rendered. Defaults to `true`.
  /// * [width]: Stroke width of connection lines. Defaults to `0.5`.
  /// * [distance]: Max proximity distance for connection lines. Defaults to `100.0`.
  /// * [color]: Color for connection lines. Defaults to `const Color.fromARGB(255, 100, 255, 180)`.
  /// * [renderer]: Rasterization backend engine. Defaults to [LineRenderer.vertices].
  const NetworkFeatures({
    this.enabled = true,
    this.width = 0.5,
    this.distance = 100.0,
    this.color = const Color.fromARGB(255, 100, 255, 180),
    this.renderer = LineRenderer.vertices,
  });

  /// Creates a copy of this [NetworkFeatures] configuration with updated parameters.
  NetworkFeatures copyWith({
    bool? enabled,
    double? width,
    double? distance,
    Color? color,
    LineRenderer? renderer,
  }) {
    return NetworkFeatures(
      enabled: enabled ?? this.enabled,
      width: width ?? this.width,
      distance: distance ?? this.distance,
      color: color ?? this.color,
      renderer: renderer ?? this.renderer,
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
