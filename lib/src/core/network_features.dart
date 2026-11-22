/// Configuration class for particle network connection lines and visual styling.
library;

import 'package:flutter/widgets.dart';
import 'package:particles_network/src/rendering/line_vertex_batch.dart';

/// Configuration class for particle connection lines, styling, and rendering backend.
///
/// Encapsulates all connection network properties including whether lines are rendered ([drawNetwork]),
/// connection reach radius ([lineDistance]), stroke width ([lineWidth]), base line color ([lineColor]),
/// and GPU rasterization backend ([lineRenderer]).
///
/// Example:
/// ```dart
/// const network = NetworkFeatures(
///   drawNetwork: true,
///   lineWidth: 0.8,
///   lineDistance: 80.0,
///   lineColor: Color(0xFF38BDF8),
///   lineRenderer: LineRenderer.vertices,
/// );
/// ```
@immutable
class NetworkFeatures {
  /// Whether connection lines between neighboring particles are calculated and drawn.
  ///
  /// When `true`, lines connect neighboring particles within [lineDistance].
  /// When `false`, line calculations and drawing are completely bypassed, rendering
  /// only particle discs and saving substantial CPU/GPU cycles.
  ///
  /// Defaults to `true`.
  final bool drawNetwork;

  /// Compatibility alias for [drawNetwork].
  ///
  /// Deprecated: Renamed to [drawNetwork] inside [NetworkFeatures]. Use [drawNetwork] instead.
  /// This property will be removed in particles_network 2.0.0.
  @Deprecated(
    'drawnetwork was renamed to drawNetwork inside NetworkFeatures. '
    'Use NetworkFeatures.drawNetwork instead. '
    'This property will be removed in particles_network 2.0.0.',
  )
  bool get drawnetwork => drawNetwork;

  /// Stroke width of connection lines between particles in logical pixels.
  ///
  /// Lines thinner than 1 physical pixel are automatically rendered with proportionally
  /// reduced opacity when using [LineRenderer.vertices] to eliminate visual aliasing dropouts.
  ///
  /// Defaults to `0.5`.
  final double lineWidth;

  /// Compatibility alias for [lineWidth].
  ///
  /// Deprecated: Renamed to [lineWidth] inside [NetworkFeatures]. Use [lineWidth] instead.
  /// This property will be removed in particles_network 2.0.0.
  @Deprecated(
    'linewidth was renamed to lineWidth inside NetworkFeatures. '
    'Use NetworkFeatures.lineWidth instead. '
    'This property will be removed in particles_network 2.0.0.',
  )
  double get linewidth => lineWidth;

  /// Maximum connection distance between particles in logical pixels.
  ///
  /// Two particles connect with a line if the distance between them is less than [lineDistance].
  /// Lines fade out smoothly with distance, reaching full transparency at [lineDistance].
  /// Also serves as the default reach for touch interactions when [TouchFeatures.lineDistance] is `null`.
  ///
  /// Defaults to `100.0`.
  final double lineDistance;

  /// Base color used to render connecting lines between particles.
  ///
  /// Line opacity scales dynamically with particle proximity, fading from full opacity
  /// when particles touch to completely transparent at [lineDistance].
  ///
  /// Defaults to `const Color.fromARGB(255, 100, 255, 180)` (cyan-green).
  final Color lineColor;

  /// The rasterization backend used to render connection lines on the GPU.
  ///
  /// * [LineRenderer.vertices]: Submits lines as indexed triangle quads in batched `drawVertices`
  ///   calls. Substantially reduces GPU overhead for high line counts (lines render with square ends).
  /// * [LineRenderer.stroke]: Uses native engine Canvas strokes (`drawLine` / `drawRawPoints`
  ///   with rounded ends).
  ///
  /// Defaults to [LineRenderer.vertices].
  final LineRenderer lineRenderer;

  /// Creates a [NetworkFeatures] configuration with customizable appearance and rendering backend.
  ///
  /// Parameters:
  /// * [drawNetwork]: Whether connection lines are rendered. Defaults to `true`.
  /// * [lineWidth]: Stroke width of connection lines. Defaults to `0.5`.
  /// * [lineDistance]: Max proximity distance for connection lines. Defaults to `100.0`.
  /// * [lineColor]: Color for connection lines. Defaults to `const Color.fromARGB(255, 100, 255, 180)`.
  /// * [lineRenderer]: Rasterization backend engine. Defaults to [LineRenderer.vertices].
  const NetworkFeatures({
    bool? drawNetwork,
    @Deprecated(
      'drawnetwork was renamed to drawNetwork inside NetworkFeatures. '
      'Use NetworkFeatures(drawNetwork: ...) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    bool? drawnetwork,
    double? lineWidth,
    @Deprecated(
      'linewidth was renamed to lineWidth inside NetworkFeatures. '
      'Use NetworkFeatures(lineWidth: ...) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    double? linewidth,
    this.lineDistance = 100.0,
    this.lineColor = const Color.fromARGB(255, 100, 255, 180),
    this.lineRenderer = LineRenderer.vertices,
  })  : drawNetwork = drawnetwork ?? drawNetwork ?? true,
        lineWidth = linewidth ?? lineWidth ?? 0.5;

  /// Creates a copy of this [NetworkFeatures] configuration with updated parameters.
  NetworkFeatures copyWith({
    bool? drawNetwork,
    @Deprecated(
      'drawnetwork was renamed to drawNetwork inside NetworkFeatures. '
      'Use NetworkFeatures.copyWith(drawNetwork: ...) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    bool? drawnetwork,
    double? lineWidth,
    @Deprecated(
      'linewidth was renamed to lineWidth inside NetworkFeatures. '
      'Use NetworkFeatures.copyWith(lineWidth: ...) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    double? linewidth,
    double? lineDistance,
    Color? lineColor,
    LineRenderer? lineRenderer,
  }) {
    return NetworkFeatures(
      drawNetwork: drawnetwork ?? drawNetwork ?? this.drawNetwork,
      lineWidth: linewidth ?? lineWidth ?? this.lineWidth,
      lineDistance: lineDistance ?? this.lineDistance,
      lineColor: lineColor ?? this.lineColor,
      lineRenderer: lineRenderer ?? this.lineRenderer,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkFeatures &&
          runtimeType == other.runtimeType &&
          drawNetwork == other.drawNetwork &&
          lineWidth == other.lineWidth &&
          lineDistance == other.lineDistance &&
          lineColor == other.lineColor &&
          lineRenderer == other.lineRenderer;

  @override
  int get hashCode => Object.hash(
        drawNetwork,
        lineWidth,
        lineDistance,
        lineColor,
        lineRenderer,
      );

  @override
  String toString() =>
      'NetworkFeatures(drawNetwork: $drawNetwork, lineWidth: $lineWidth, '
      'lineDistance: $lineDistance, lineColor: $lineColor, lineRenderer: $lineRenderer)';
}
