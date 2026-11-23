/// Configuration class for particle visual appearance, physics bounds, and density.
library;

import 'package:flutter/widgets.dart';

/// Configuration class for particle visual characteristics, density, and cruising velocity limits.
///
/// Encapsulates all particle-specific properties including cloud density ([count]),
/// velocity ceiling ([maxSpeed]), radius bounds ([maxSize]), base color ([color]),
/// and rendering mode ([fill]).
///
/// Predefined Presets:
/// * [ParticleFeatures.subtle]: Gentle, low-density cloud suited for quiet, non-intrusive backgrounds.
/// * [ParticleFeatures.dense]: Rich, high-density particle field with elevated dynamics.
/// * [ParticleFeatures.cosmic]: Rapid, wide-radius particle cloud suited for dynamic hero sections.
///
/// Example:
/// ```dart
/// // Custom particle styling:
/// const particles = ParticleFeatures(
///   count: 80,
///   maxSpeed: 0.8,
///   maxSize: 2.0,
///   color: Color(0xFF00E5FF),
///   fill: true,
/// );
/// ```
@immutable
class ParticleFeatures {
  /// Total number of particles simulated and rendered on the canvas.
  ///
  /// Controls the visual density of the particle cloud. Higher counts produce
  /// dense cosmic or plexus effects, while lower counts produce clean, subtle
  /// interactive backgrounds.
  ///
  /// Defaults to `60`.
  final int count;

  /// Maximum base velocity of particles in pixels per frame.
  ///
  /// Each particle is initialized with a randomized velocity between `0.0` and [maxSpeed].
  /// When frame-rate independent scaling is active, this speed corresponds to pixels
  /// per 1/60 s reference frame.
  ///
  /// Defaults to `0.5`.
  final double maxSpeed;

  /// Maximum radius of particles in logical pixels.
  ///
  /// Each particle's radius is randomized between `0.5` and [maxSize] upon initialization.
  /// Heavier particles (larger radius) exhibit higher physical inertia.
  ///
  /// Defaults to `1.5`.
  final double maxSize;

  /// Base solid color used to render all particles on the canvas.
  ///
  /// Defaults to `const Color(0xFFFFFFFF)` (white).
  final Color color;

  /// Whether particles are rendered as filled solid circles or hollow stroked outlines.
  ///
  /// When `true`, particles are drawn as solid discs (`PaintingStyle.fill`).
  /// When `false`, particles are drawn as stroked rings (`PaintingStyle.stroke`).
  ///
  /// Defaults to `true`.
  final bool fill;

  /// Creates a [ParticleFeatures] configuration with customizable appearance and physics limits.
  ///
  /// Parameters:
  /// * [count]: Total number of particles. Defaults to `60`.
  /// * [maxSpeed]: Maximum wandering speed ceiling in px/frame. Defaults to `0.5`.
  /// * [maxSize]: Maximum particle radius in logical pixels. Defaults to `1.5`.
  /// * [color]: Base color for particle discs or rings. Defaults to `const Color(0xFFFFFFFF)`.
  /// * [fill]: Whether particles are filled solid or stroked rings. Defaults to `true`.
  const ParticleFeatures({
    /// The total number of particles simulated and rendered on the canvas.
    ///
    /// Higher counts create richer networks but require more CPU/GPU calculation.
    ///
    /// Defaults to `60`.
    this.count = 60,

    /// The maximum cruising speed ceiling of wandering particles in logical pixels per frame.
    ///
    /// Defaults to `0.5`.
    this.maxSpeed = 0.5,

    /// The maximum radius of particle circles in logical pixels.
    ///
    /// Defaults to `1.5`.
    this.maxSize = 1.5,

    /// The base color used to render particle discs or circle rings.
    ///
    /// Defaults to `const Color(0xFFFFFFFF)` (white).
    this.color = const Color(0xFFFFFFFF),

    /// Whether particles are rendered as filled solid discs or stroked circular rings.
    ///
    /// Defaults to `true`.
    this.fill = true,
  })  : assert(
          count >= 0,
          'count must be non-negative',
        ),
        assert(
          maxSpeed >= 0.0,
          'maxSpeed must be non-negative',
        ),
        assert(
          maxSize > 0.0,
          'maxSize must be positive',
        );

  /// Subtle preset with reduced particle count and gentle velocity.
  ///
  /// Ideal for calm, non-distracting backgrounds and content-heavy pages.
  ///
  /// Settings:
  /// * [count]: `35`
  /// * [maxSpeed]: `0.3`
  /// * [maxSize]: `1.2`
  /// * [color]: `Color(0xFFFFFFFF)`
  /// * [fill]: `true`
  const ParticleFeatures.subtle({
    int count = 35,
    double maxSpeed = 0.3,
    double maxSize = 1.2,
    Color color = const Color(0xFFFFFFFF),
    bool fill = true,
  }) : this(
          count: count,
          maxSpeed: maxSpeed,
          maxSize: maxSize,
          color: color,
          fill: fill,
        );

  /// Dense preset with elevated particle count and energetic velocity.
  ///
  /// Ideal for rich visual canvases, hero headers, and plexus effects.
  ///
  /// Settings:
  /// * [count]: `120`
  /// * [maxSpeed]: `0.8`
  /// * [maxSize]: `2.0`
  /// * [color]: `Color(0xFFFFFFFF)`
  /// * [fill]: `true`
  const ParticleFeatures.dense({
    int count = 120,
    double maxSpeed = 0.8,
    double maxSize = 2.0,
    Color color = const Color(0xFFFFFFFF),
    bool fill = true,
  }) : this(
          count: count,
          maxSpeed: maxSpeed,
          maxSize: maxSize,
          color: color,
          fill: fill,
        );

  /// Cosmic preset featuring fast-moving, larger particles for dramatic hero effects.
  ///
  /// Settings:
  /// * [count]: `90`
  /// * [maxSpeed]: `1.2`
  /// * [maxSize]: `2.5`
  /// * [color]: `Color(0xFFFFFFFF)`
  /// * [fill]: `true`
  const ParticleFeatures.cosmic({
    int count = 90,
    double maxSpeed = 1.2,
    double maxSize = 2.5,
    Color color = const Color(0xFFFFFFFF),
    bool fill = true,
  }) : this(
          count: count,
          maxSpeed: maxSpeed,
          maxSize: maxSize,
          color: color,
          fill: fill,
        );

  /// Creates a copy of this [ParticleFeatures] configuration with updated parameters.
  ///
  /// Calling `copyWith` without arguments returns an identical [ParticleFeatures] instance.
  ParticleFeatures copyWith({
    /// Total particle count.
    int? count,

    /// Maximum cruising speed ceiling in px/frame.
    double? maxSpeed,

    /// Maximum particle radius in logical pixels.
    double? maxSize,

    /// Base particle color.
    Color? color,

    /// Whether particles are filled solid or stroked rings.
    bool? fill,
  }) {
    return ParticleFeatures(
      count: count ?? this.count,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      maxSize: maxSize ?? this.maxSize,
      color: color ?? this.color,
      fill: fill ?? this.fill,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParticleFeatures &&
          runtimeType == other.runtimeType &&
          count == other.count &&
          maxSpeed == other.maxSpeed &&
          maxSize == other.maxSize &&
          color == other.color &&
          fill == other.fill;

  @override
  int get hashCode => Object.hash(
        count,
        maxSpeed,
        maxSize,
        color,
        fill,
      );

  @override
  String toString() =>
      'ParticleFeatures(count: $count, maxSpeed: $maxSpeed, '
      'maxSize: $maxSize, color: $color, fill: $fill)';
}
