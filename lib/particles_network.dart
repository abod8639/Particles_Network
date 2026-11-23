/// Main entry point for the particles_network package.
///
/// This library provides the [ParticleNetwork] widget, which is the primary
/// way to use the particle animation in a Flutter application.
library;

export 'package:particles_network/src/core/particle.dart'
    show Particle, computeVelocity, createMockParticle, scaleFrameRate;
export 'package:particles_network/src/core/particle_features.dart'
    show ParticleFeatures;
export 'package:particles_network/src/core/network_features.dart'
    show NetworkFeatures;
export 'package:particles_network/src/core/rectangle.dart' show Rectangle;
export 'package:particles_network/src/core/trajectory_buffer.dart'
    show TrajectoryBuffer;
export 'package:particles_network/src/factory/default_particle_factory.dart'
    show DefaultParticleFactory;
export 'package:particles_network/src/factory/particle_factory.dart'
    show IParticleFactory;
export 'package:particles_network/src/interaction/touch_features.dart'
    show TouchFeatures, TouchType;
export 'package:particles_network/src/interaction/touch_interaction_handler.dart'
    show TouchInteractionHandler;
export 'package:particles_network/src/physics/legacy/legacy_gravity_config.dart'
    show GravityConfig;
export 'package:particles_network/src/physics/particle_gravity.dart'
    show GravityType, GravityFeatures;
export 'package:particles_network/src/physics/particle_controller.dart'
    show IParticleController, ITimeScaledParticleController;
export 'package:particles_network/src/physics/particle_updater.dart'
    show ParticleUpdater;
export 'package:particles_network/src/rendering/line_vertex_batch.dart'
    show LineRenderer, LineVertexBatch;
export 'package:particles_network/src/rendering/complex_features.dart'
    show ComplexConfig, ComplexFeatures;
export 'package:particles_network/src/rendering/network_performance.dart'
    show PerformanceFeatures;
export 'package:particles_network/src/rendering/object_pool.dart'
    show
        ObjectPool,
        IntListPool,
        ConnectionDataPool,
        ConnectionData,
        PoolManager;
export 'package:particles_network/src/rendering/optimized_network_painter.dart'
    show OptimizedNetworkPainter;
export 'package:particles_network/src/rendering/particle_filter.dart'
    show ParticleFilter;
export 'package:particles_network/src/rendering/performance_utils.dart'
    show AccelerationTracker, PerformanceMonitor, AdaptivePerformanceController;
export 'package:particles_network/src/simulation/particle_simulation.dart'
    show ParticleSimulation;
// High-performance canonical spatial partitioning engine
export 'package:particles_network/src/spatial/grid_tuning.dart' show GridTuning;
export 'package:particles_network/src/spatial/sorted_spatial_grid.dart'
    show SortedSpatialGrid;
// Legacy compatibility shim for CompressedQuadTree (deprecated, removed in 2.0.0)
export 'package:particles_network/src/spatial/compressed_quad_tree.dart'
    show CompressedQuadTree, QuadTreeParticle;
export 'package:particles_network/src/widgets/particle_network_widget.dart'
    show ParticleNetwork, ParticleNetworkState;
