/// Legacy entry point for gravity configuration.
///
/// Deprecated: Import 'package:particles_network/src/physics/particle_gravity.dart'
/// or use 'package:particles_network/particles_network.dart' instead.
/// This file will be removed in particles_network 2.0.0.
@Deprecated('Use particle_gravity.dart instead. Will be removed in 2.0.0')
library;

export 'package:particles_network/src/physics/particle_gravity.dart'
    show GravityType, ParticleGravity;
export 'package:particles_network/src/physics/legacy/legacy_gravity_config.dart'
    show GravityConfig;
