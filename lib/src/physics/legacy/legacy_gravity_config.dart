/// Legacy gravity configuration.
///
/// This file maintains backward compatibility for [GravityConfig].
/// It is scheduled for removal in particles_network 2.0.0.
library;

import 'dart:ui';
import 'package:particles_network/src/physics/particle_gravity.dart';

/// Legacy configuration class for gravity effects.
///
/// Deprecated: Use [GravityFeatures] instead. This class will be removed in version 2.0.0.
@Deprecated(
  'Use GravityFeatures instead. GravityConfig will be removed in particles_network 2.0.0.',
)
class GravityConfig extends GravityFeatures {
  /// The center point coordinates for [GravityType.point].
  @override
  Offset get center => super.center ?? Offset.zero;

  /// Creates a [GravityConfig] with the specified parameters.
  const GravityConfig({
    super.type = GravityType.none,
    super.strength = 0.5,
    super.direction = const Offset(0, 1),
    Offset center = Offset.zero,
  }) : super(center: center);

  @override
  GravityConfig copyWith({
    GravityType? type,
    double? strength,
    Offset? direction,
    Offset? center,
  }) {
    return GravityConfig(
      type: type ?? this.type,
      strength: strength ?? this.strength,
      direction: direction ?? this.direction,
      center: center ?? this.center,
    );
  }
}
