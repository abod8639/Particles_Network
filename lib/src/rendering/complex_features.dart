/// Configuration class for complex particle cluster throttling and optimization.
library;

import 'package:flutter/foundation.dart';

/// Configuration class for high-density particle cluster throttling and connection pruning.
///
/// Encapsulates optimization settings used to eliminate visual clutter and maintain high
/// frame rates in congested particle clusters without degrading visual quality in sparse areas.
///
/// Settings:
/// * [enabled]: Whether cluster throttling is active. When `false`, candidate lines in clusters
///   are drawn normally without pruning. Defaults to `false`.
/// * [ratio]: Fraction of candidate connection lines pruned in dense clusters (`0.0` to `1.0`).
///   When `null`, default internal reduction heuristics are used. Defaults to `null`.
/// * [maxLines]: Maximum connection lines an individual particle can emit in dense clusters.
///   When `null`, automatically defaults to 3 lines (individual mode) or 5 lines (batched mode). Defaults to `null`.
/// * [densityFactor]: Proximity factor used to detect whether a particle is inside a dense cluster.
///   Defaults to `0.60` when complex mode is active. Defaults to `null`.
///
/// Presets:
/// * [ComplexConfig.auto]: Automatically configures cluster throttling with recommended defaults (`maxLines: 3`, `densityFactor: 0.60`).
/// * [ComplexConfig.disabled]: Explicitly disables cluster throttling.
@immutable
class ComplexConfig {
  /// Whether cluster throttling optimization is active.
  ///
  /// Defaults to `false`.
  final bool enabled;

  /// Fraction of connection lines to prune in dense clusters (`0.0` to `1.0`).
  ///
  /// For example, `0.4` eliminates 40% of cluster lines (keeping 60%), while `0.7` eliminates 70% (keeping 30%).
  /// Defaults to `null`.
  final double? ratio;

  /// Maximum connection lines allowed per particle in a dense cluster.
  ///
  /// Defaults to `null`.
  final int? maxLines;

  /// Threshold multiplier used to detect dense clusters.
  ///
  /// Defaults to `null`.
  final double? densityFactor;

  /// Compatibility getter for [enabled].
  bool get isComplex => enabled;

  /// Compatibility getter for [ratio].
  double? get complexRatio => ratio;

  /// Compatibility getter for [ratio].
  double? get complexReductionRatio => ratio;

  /// Compatibility getter for [maxLines].
  int? get maxComplexLines => maxLines;

  /// Compatibility getter for [densityFactor].
  double? get complexDensityFactor => densityFactor;

  /// Default constructor (disabled by default unless parameters are explicitly provided).
  const ComplexConfig({
    this.enabled = false,
    this.ratio,
    this.maxLines,
    this.densityFactor,
  }) : assert(
         ratio == null || (ratio >= 0.0 && ratio <= 1.0),
         'ratio must be between 0.0 and 1.0',
       ),
       assert(maxLines == null || maxLines > 0, 'maxLines must be positive'),
       assert(
         densityFactor == null || densityFactor > 0.0,
         'densityFactor must be positive',
       );

  /// Preconfigured auto-tuning constructor for high-density clustering.
  ///
  /// Automatically enables cluster throttling with default recommended bounds:
  /// * [enabled]: `true`
  /// * [maxLines]: `3`
  /// * [densityFactor]: `0.60`
  const ComplexConfig.auto({
    this.ratio,
    this.maxLines = 3,
    this.densityFactor = 0.60,
  }) : enabled = true,
       assert(
         ratio == null || (ratio >= 0.0 && ratio <= 1.0),
         'ratio must be between 0.0 and 1.0',
       ),
       assert(maxLines == null || maxLines > 0, 'maxLines must be positive'),
       assert(
         densityFactor == null || densityFactor > 0.0,
         'densityFactor must be positive',
       );

  /// Disabled preset with all parameters cleared.
  const ComplexConfig.disabled()
    : enabled = false,
      ratio = null,
      maxLines = null,
      densityFactor = null;

  /// Creates a copy of this [ComplexConfig] with updated parameters.
  ComplexConfig copyWith({
    bool? enabled,
    double? ratio,
    bool clearRatio = false,
    int? maxLines,
    bool clearMaxLines = false,
    double? densityFactor,
    bool clearDensityFactor = false,
  }) {
    return ComplexConfig(
      enabled: enabled ?? this.enabled,
      ratio: clearRatio ? null : (ratio ?? this.ratio),
      maxLines: clearMaxLines ? null : (maxLines ?? this.maxLines),
      densityFactor: clearDensityFactor
          ? null
          : (densityFactor ?? this.densityFactor),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComplexConfig &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          ratio == other.ratio &&
          maxLines == other.maxLines &&
          densityFactor == other.densityFactor;

  @override
  int get hashCode => Object.hash(enabled, ratio, maxLines, densityFactor);

  @override
  String toString() =>
      'ComplexConfig(enabled: $enabled, ratio: $ratio, '
      'maxLines: $maxLines, densityFactor: $densityFactor)';
}

/// Compatibility alias for [ComplexConfig].
typedef ComplexFeatures = ComplexConfig;
