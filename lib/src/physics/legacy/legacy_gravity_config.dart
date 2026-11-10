/// Legacy gravity configuration.
///
/// This file maintains backward compatibility for [GravityConfig].
/// It is scheduled for removal in particles_network 2.0.0.
library;

import 'package:particles_network/src/physics/particle_gravity.dart';

/// Legacy configuration class for gravity effects.
///
/// Deprecated: Use [ParticleGravity] instead. This class will be removed in version 2.0.0.
@Deprecated(
  'Use ParticleGravity instead. GravityConfig will be removed in particles_network 2.0.0.',
)
typedef GravityConfig = ParticleGravity;
