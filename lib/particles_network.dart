/// Main entry point for the particles_network package.
///
/// This library provides the [ParticleNetwork] widget, which is the primary
/// way to use the particle animation in a Flutter application.
library;

export 'package:particles_network/src/core/particle.dart'
    show Particle, computeVelocity, createMockParticle;
export 'package:particles_network/src/core/rectangle.dart' show Rectangle;
export 'package:particles_network/src/core/trajectory_buffer.dart'
    show TrajectoryBuffer;
export 'package:particles_network/src/factory/default_particle_factory.dart'
    show DefaultParticleFactory;
export 'package:particles_network/src/factory/particle_factory.dart'
    show IParticleFactory;
export 'package:particles_network/src/interaction/touch_features.dart'
    show TouchFeatures;
export 'package:particles_network/src/interaction/touch_interaction_handler.dart'
    show TouchInteractionHandler;
export 'package:particles_network/src/physics/gravity_config.dart'
    show GravityType, GravityConfig;
export 'package:particles_network/src/physics/particle_controller.dart'
    show IParticleController;
export 'package:particles_network/src/physics/particle_updater.dart'
    show ParticleUpdater;
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
    show AccelerationTracker, AdaptiveQuadTreeManager, PerformanceMonitor;
export 'package:particles_network/src/simulation/particle_simulation.dart'
    show ParticleSimulation;
export 'package:particles_network/src/spatial/compressed_quad_tree.dart'
    show CompressedQuadTree;
export 'package:particles_network/src/spatial/compressed_quad_tree_node.dart'
    show
        QuadTreeParticle,
        Quadrant,
        CompressedPath,
        CompressedQuadTreeNode;
export 'package:particles_network/src/spatial/spatial_grid.dart'
    show SpatialGrid;
export 'package:particles_network/src/widgets/particle_network_widget.dart'
    show ParticleNetwork, ParticleNetworkState;
