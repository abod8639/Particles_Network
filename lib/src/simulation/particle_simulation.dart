/// Manages the particle system simulation independently from Flutter's widget tree.
library;

import 'dart:math';
import 'dart:ui';

import 'package:particles_network/src/core/particle.dart';
import 'package:particles_network/src/factory/default_particle_factory.dart';
import 'package:particles_network/src/factory/particle_factory.dart';
import 'package:particles_network/src/physics/particle_controller.dart';
import 'package:particles_network/src/physics/particle_gravity.dart';
import 'package:particles_network/src/physics/particle_updater.dart';
import 'package:particles_network/src/spatial/sorted_spatial_grid.dart';

/// Independent simulation controller managing the particles lifecycle and physics updates.
class ParticleSimulation {
  /// The active particles in the simulation.
  final List<Particle> particles = [];

  /// Spatial partitioning grid providing O(K) fixed-radius queries for the simulation.
  final SortedSpatialGrid spatialGrid;

  /// The particle factory used to generate new particles.
  IParticleFactory factory;

  /// The physics controller responsible for updating positions/velocities.
  IParticleController controller;

  /// Total particle count requested.
  int particleCount;

  /// Current container bounds.
  Size currentSize = Size.zero;

  /// Cached gravity configuration.
  ParticleGravity gravityConfig;

  /// Exposes gravity configuration.
  ParticleGravity get gravity => gravityConfig;

  /// Creates a [ParticleSimulation].
  ParticleSimulation({
    required this.particleCount,
    IParticleFactory? factory,
    IParticleController? controller,
    this.gravityConfig = const ParticleGravity(),
    double maxSpeed = 0.5,
    double maxSize = 1.5,
    Color particleColor = const Color(0xFFFFFFFF),
    SortedSpatialGrid? spatialGrid,
  })  : spatialGrid = spatialGrid ?? SortedSpatialGrid(),
        factory = factory ??
            DefaultParticleFactory(
              random: Random(),
              maxSpeed: maxSpeed,
              maxSize: maxSize,
              color: particleColor,
            ),
        controller = controller ?? ParticleUpdater();

  /// Advances the simulation with zero allocations.
  ///
  /// [timeScale] is the elapsed time in 60 Hz reference frames (1.0 = 1/60 s).
  /// Controllers that do not implement [ITimeScaledParticleController] always
  /// advance by exactly one frame.
  void step([double timeScale = 1.0]) {
    if (particles.isEmpty ||
        currentSize.width <= 0 ||
        currentSize.height <= 0) {
      return;
    }
    final IParticleController c = controller;
    if (c is ITimeScaledParticleController) {
      c.updateParticlesScaled(
        particles,
        currentSize,
        timeScale,
        gravity: gravityConfig,
      );
    } else {
      c.updateParticles(
        particles,
        currentSize,
        gravity: gravityConfig,
      );
    }
  }

  /// Updates viewport dimensions and handles particle generation or resizing.
  void updateSize(Size size) {
    if (size == currentSize) return;
    currentSize = size;
    particles.clear();

    if (size.width > 0 && size.height > 0) {
      for (int i = 0; i < particleCount; i++) {
        particles.add(factory.createParticle(size));
      }
    }
  }

  /// Updates the target particle count, adding or removing particles as needed.
  void updateParticleCount(int count) {
    if (count == particleCount) return;
    particleCount = count;

    if (currentSize.width > 0 && currentSize.height > 0) {
      if (particles.length < count) {
        final int toAdd = count - particles.length;
        for (int i = 0; i < toAdd; i++) {
          particles.add(factory.createParticle(currentSize));
        }
      } else if (particles.length > count) {
        particles.removeRange(count, particles.length);
      }
    }
  }

  /// Updates the gravity configuration.
  void updateGravity(ParticleGravity config) {
    gravityConfig = config;
  }

  /// Updates the particle factory configuration.
  void updateFactory({
    required double maxSpeed,
    required double maxSize,
    required Color color,
  }) {
    factory = DefaultParticleFactory(
      random: Random(),
      maxSpeed: maxSpeed,
      maxSize: maxSize,
      color: color,
    );
  }

  /// Builds or updates [spatialGrid] for the current simulation state.
  ///
  /// [radius] specifies the query neighborhood radius (defaults to 100.0).
  /// If [visibleIndices] is provided, only those particle indices are indexed;
  /// otherwise all particles from 0 to `particles.length - 1` are indexed.
  /// An optional [cellMultiplier] can be used to scale the grid cell size.
  void buildSpatialGrid([
    double radius = 100.0,
    List<int>? visibleIndices,
    double? cellMultiplier,
  ]) {
    if (particles.isEmpty ||
        currentSize.width <= 0 ||
        currentSize.height <= 0) {
      spatialGrid.clear();
      return;
    }
    spatialGrid.build(
      particles,
      visibleIndices,
      currentSize.width,
      currentSize.height,
      radius,
      cellMultiplier,
    );
  }

  /// Finds all particles within Euclidean distance [radius] of point ([x], [y]) using [spatialGrid].
  void queryRadius(
    double x,
    double y,
    double radius,
    void Function(int particleIndex, double px, double py, double distSq)
        visitor,
  ) {
    spatialGrid.queryRadius(x, y, radius, visitor);
  }

  /// Finds all particles within rectangular boundary `[minX, maxX] x [minY, maxY]` using [spatialGrid].
  void queryRect(
    double minX,
    double minY,
    double maxX,
    double maxY,
    void Function(int particleIndex, double px, double py) visitor,
  ) {
    spatialGrid.queryRect(minX, minY, maxX, maxY, visitor);
  }

  /// Iterates all unique particle pairs within Euclidean distance [maxDistance]
  /// across [spatialGrid] in O(N) time with zero allocations.
  void forEachPair(
    double maxDistance,
    void Function(int i1, int i2, double distSq) visitor,
  ) {
    spatialGrid.forEachPair(maxDistance, visitor);
  }

  /// Iterates all particles stored in [spatialGrid] in contiguous memory order.
  void forEachParticle(
    void Function(int particleIndex, double px, double py) visitor,
  ) {
    spatialGrid.forEachParticle(visitor);
  }

  /// Clears all particles and resets the simulation.
  void clear() {
    particles.clear();
    currentSize = Size.zero;
    spatialGrid.clear();
  }
}
