# Comprehensive API Reference - Particles Network

> **Current Version:** `v1.9.7` | **Environment:** Flutter & Dart  
> Comprehensive documentation for all public APIs, classes, enums, functions, and configuration objects provided by the `particles_network` package. Each entry details parameter types, default values, behavioral descriptions, and deprecation status (Canonical vs. Deprecated).

---

## Table of Contents

1. [Core Widget: `ParticleNetwork`](#1-core-widget-particlenetwork)
2. [Widget State: `ParticleNetworkState`](#2-widget-state-particlenetworkstate)
3. [Particle Configuration: `ParticleFeatures`](#3-particle-configuration-particlefeatures)
4. [Network Line Configuration: `NetworkFeatures`](#4-network-line-configuration-networkfeatures)
5. [Touch Interaction Configuration: `TouchFeatures`](#5-touch-interaction-configuration-touchfeatures)
6. [Performance & Rendering Optimization: `PerformanceFeatures` & `ComplexConfig`](#6-performance--rendering-optimization-performancefeatures--complexconfig)
7. [Gravity & Physics Forces: `GravityFeatures` & `GravityType`](#7-gravity--physics-forces-gravityfeatures--gravitytype)
8. [Particle Model & Mathematics: `Particle` and Helper Utilities](#8-particle-model--mathematics-particle-and-helper-utilities)
9. [Geometric Primitives: `Rectangle`](#9-geometric-primitives-rectangle)
10. [Trajectory Caching: `TrajectoryBuffer`](#10-trajectory-caching-trajectorybuffer)
11. [Particle Factory: `IParticleFactory` & `DefaultParticleFactory`](#11-particle-factory-iparticlefactory--defaultparticlefactory)
12. [Touch Interaction Handler: `TouchInteractionHandler`](#12-touch-interaction-handler-touchinteractionhandler)
13. [Particle Controllers & Physics: `IParticleController`, `ITimeScaledParticleController`, & `ParticleUpdater`](#13-particle-controllers--physics-iparticlecontroller-itimescaledparticlecontroller--particleupdater)
14. [Simulation Engine: `ParticleSimulation`](#14-simulation-engine-particlesimulation)
15. [Spatial Partitioning: `SortedSpatialGrid` & `GridTuning`](#15-spatial-partitioning-sortedspatialgrid--gridtuning)
16. [GPU Batching Layer: `LineRenderer` & `LineVertexBatch`](#16-gpu-batching-layer-linerenderer--linevertexbatch)
17. [Custom Painter: `OptimizedNetworkPainter`](#17-custom-painter-optimizednetworkpainter)
18. [Viewport Particle Culling: `ParticleFilter`](#18-viewport-particle-culling-particlefilter)
19. [Performance Profiling & Adaptation: `AccelerationTracker`, `PerformanceMonitor`, & `AdaptivePerformanceController`](#19-performance-profiling--adaptation-accelerationtracker-performancemonitor--adaptiveperformancecontroller)
20. [Memory & Object Pooling: `ObjectPool` & `PoolManager`](#20-memory--object-pooling-objectpool--poolmanager)
21. [Deprecated APIs & Migration Guide (v2.0.0)](#21-deprecated-apis--migration-guide-v200)
22. [Complete Example with All APIs & Default Values](#22-complete-example-with-all-apis--default-values)

---

## 1. Core Widget: `ParticleNetwork`

Source File: [lib/src/widgets/particle_network_widget.dart](file:///home/dexter/flutter_library/particles_network/lib/src/widgets/particle_network_widget.dart)

The primary Flutter widget (`StatefulWidget`) for rendering interactive, high-performance particle network animations.

### Constructor & Canonical Parameters

| Parameter                 | Type                   | Default Value                 | Description                                                                                                                   |
| ------------------------- | ---------------------- | ----------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `particles`               | `ParticleFeatures`     | `const ParticleFeatures()`    | Encapsulated particle visual appearance, count, velocity limits, radius bounds, and fill/stroke style.                       |
| `network`                 | `NetworkFeatures`      | `const NetworkFeatures()`     | Encapsulated network line configuration: drawing toggle, line width, connection distance, line color, and `LineRenderer`.   |
| `touch` / `touchFeatures` | `TouchFeatures`        | `const TouchFeatures()`       | Fine-grained touch and mouse hover physics, repulsion/attraction force, highlight color, and gestures.                       |
| `performance`             | `PerformanceFeatures`  | `const PerformanceFeatures()` | Performance tuning, line budgets, frame-rate independence, and cluster throttling.                                           |
| `gravity`                 | `GravityFeatures?`     | `null`                        | Unified directional or point attractor/repeller gravity configuration.                                                        |
| `spatialGrid`             | `SortedSpatialGrid?`   | `null`                        | Optional custom spatial partitioning grid instance for neighbor indexing (defaults to an internally managed instance).       |

### Deprecated Constructor Parameters

*(Maintained for 100% backward compatibility with v1.x; scheduled for removal in v2.0.0)*

| Deprecated Parameter        | Type                   | Recommended Replacement                                                                     |
| --------------------------- | ---------------------- | ------------------------------------------------------------------------------------------- |
| `particleCount`             | `int?`                 | Use `particles: ParticleFeatures(count: ...)`                                               |
| `maxSpeed`                  | `double?`              | Use `particles: ParticleFeatures(maxSpeed: ...)`                                            |
| `maxSize`                   | `double?`              | Use `particles: ParticleFeatures(maxSize: ...)`                                             |
| `particleColor`             | `Color?`               | Use `particles: ParticleFeatures(color: ...)`                                               |
| `fill`                      | `bool?`                | Use `particles: ParticleFeatures(fill: ...)`                                                |
| `particleFeatures`          | `ParticleFeatures?`    | Use `particles: ParticleFeatures(...)` (canonical naming consistency)                       |
| `lineWidth`                 | `double?`              | Use `network: NetworkFeatures(width: ...)`                                                  |
| `lineDistance`              | `double?`              | Use `network: NetworkFeatures(distance: ...)`                                               |
| `lineColor`                 | `Color?`               | Use `network: NetworkFeatures(color: ...)`                                                  |
| `drawNetwork`               | `bool?`                | Use `network: NetworkFeatures(enabled: ...)`                                                |
| `networkFeatures`           | `NetworkFeatures?`     | Use `network: NetworkFeatures(...)` (canonical naming consistency)                          |
| `isComplex`                 | `bool?`                | Use `performance: PerformanceFeatures(complex: ComplexConfig.auto())`                       |
| `maxConnectionsPerParticle` | `int?`                 | Use `performance: PerformanceFeatures(maxConnectionsPerParticle: ...)`                       |
| `adaptiveDensity`           | `bool`                 | Use `performance: PerformanceFeatures(complex: ComplexConfig.auto())`                       |
| `fastLineRendering`         | `bool?`                | Use `network: NetworkFeatures(renderer: LineRenderer.vertices)`                             |
| `useVerticesRendering`      | `bool?`                | Use `network: NetworkFeatures(renderer: LineRenderer.vertices)`                             |
| `enableAdaptivePerformance` | `bool`                 | Use `performance: PerformanceFeatures(autoBoost: ...)`                                      |
| `touchActivation`           | `bool?`                | Use `touch: TouchFeatures(enabled: ...)`                                                    |
| `touchColor`                | `Color?`               | Use `touch: TouchFeatures(color: ...)`                                                      |
| `hoverEffect`               | `bool?`                | Use `touch: TouchFeatures(hover: ...)`                                                      |
| `gravityType`               | `GravityType`          | Use `gravity: GravityFeatures(type: ...)`                                                   |
| `gravityStrength`           | `double`               | Use `gravity: GravityFeatures(strength: ...)`                                               |
| `gravityDirection`          | `Offset`               | Use `gravity: GravityFeatures(direction: ...)`                                              |
| `gravityCenter`             | `Offset?`              | Use `gravity: GravityFeatures(center: ...)`                                                 |
| `particleFactory`           | `IParticleFactory?`    | Pass directly to `ParticleSimulation`                                                       |
| `particleController`        | `IParticleController?` | Pass directly to `ParticleSimulation`                                                       |

---

## 2. Widget State: `ParticleNetworkState`

Source File: [lib/src/widgets/particle_network_widget.dart#L278](file:///home/dexter/flutter_library/particles_network/lib/src/widgets/particle_network_widget.dart#L278)

The backing state class for `ParticleNetwork`, managing lifecycle, animation ticks, interactions, and dynamic layout scaling:

### Public Getters & Properties

| Property / Getter         | Type                            | Description                                                                                     |
| ------------------------- | ------------------------------- | ----------------------------------------------------------------------------------------------- |
| `simulation`              | `ParticleSimulation`            | Decoupled physics simulation instance executing particle dynamics independently of the UI.     |
| `particles`               | `List<Particle>`                | Live list of simulated particles.                                                               |
| `spatialGrid`             | `SortedSpatialGrid`             | Active spatial partitioning grid used for high-speed $O(K)$ neighbor searches.                 |
| `painter`                 | `OptimizedNetworkPainter`       | Custom painter executing GPU-accelerated frame rendering.                                      |
| `adaptiveController`      | `AdaptivePerformanceController` | Autonomous controller adjusting line budgets and connections to sustain target FPS.             |
| `lastFrameLineCount`      | `int`                           | Total connection lines rasterized in the most recent frame.                                     |
| `lastFrameLineDistance`   | `double`                        | Effective connection radius used in the last frame (dynamically reduced under budget pressure).|
| `effectiveMaxConnections` | `int?`                          | Effective maximum allowed connections per particle for the current frame.                       |
| `effectiveMaxLines`       | `int?`                          | Effective total line cap for the current frame.                                                 |
| `ticker`                  | `Ticker`                        | Animation ticker driving 60Hz/120Hz frame synchronization.                                      |
| `touchPoint`              | `Offset`                        | Current touch or cursor coordinates (`Offset.infinite` when no interaction is active).          |
| `currentSize`             | `Size`                          | Current canvas dimensions.                                                                      |
| `frameNotifier`           | `ValueNotifier<int>`            | Frame tick notifier driving repaints without triggering widget tree rebuilds.                   |
| `factory`                 | `IParticleFactory`              | Active particle factory instance.                                                               |
| `controller`              | `IParticleController`           | Active particle physics controller.                                                             |

---

## 3. Particle Configuration: `ParticleFeatures`

Source File: [lib/src/core/particle_features.dart](file:///home/dexter/flutter_library/particles_network/lib/src/core/particle_features.dart)

An immutable configuration object grouping all visual and motion parameters of individual particles (count, speed limit, size, color, fill mode), adhering to SOLID principles and clean modular architecture.

> [!NOTE]
> **Legacy API Migration Notice:**  
> In versions up to v1.9.6, particle settings were supplied as direct parameters on `ParticleNetwork` (`particleCount`, `maxSpeed`, `maxSize`, `particleColor`, `fill`).  
> These parameters are now deprecated (`@Deprecated`) and scheduled for removal in `v2.0.0`.  
> Consolidate them into `particles: const ParticleFeatures(...)`:
>
> ```dart
> // ❌ Deprecated:
> ParticleNetwork(
>   particleCount: 80,
>   maxSpeed: 0.8,
>   maxSize: 2.0,
>   particleColor: Colors.white,
>   fill: true,
> )
>
> // ✅ Canonical (Recommended):
> ParticleNetwork(
>   particles: const ParticleFeatures(
>     count: 80,
>     maxSpeed: 0.8,
>     maxSize: 2.0,
>     color: Colors.white,
>     fill: true,
>   ),
> )
> ```

### Constructor: `ParticleFeatures`

| Parameter  | Type     | Default Value                              | Description                                                                                       |
| ---------- | -------- | ------------------------------------------ | ------------------------------------------------------------------------------------------------- |
| `count`    | `int`    | `60`                                       | Total active particles simulated on the canvas (cloud density).                                    |
| `maxSpeed` | `double` | `0.5`                                      | Maximum random particle velocity ceiling (pixels per 60Hz reference frame).                       |
| `maxSize`  | `double` | `1.5`                                      | Maximum particle radius in logical pixels.                                                        |
| `color`    | `Color`  | `const Color(0xFFFFFFFF)` (`Colors.white`) | Base color for all particles.                                                                     |
| `fill`     | `bool`   | `true`                                     | `true` renders filled solid circular particles; `false` renders outlined circular rings (stroked).|

### Built-in Presets

1. **`ParticleFeatures.subtle()`**:
   - Gentle, low-density field suited for non-distracting background atmospheres.
   - `count: 35`, `maxSpeed: 0.3`, `maxSize: 1.2`, `color: Colors.white`, `fill: true`.

2. **`ParticleFeatures.dense()`**:
   - High-density, vibrant particle field ideal for hero sections and dynamic network visuals.
   - `count: 120`, `maxSpeed: 0.8`, `maxSize: 2.0`, `color: Colors.white`, `fill: true`.

3. **`ParticleFeatures.cosmic()`**:
   - Fast, spacious particles with larger radii for dramatic interactive displays.
   - `count: 90`, `maxSpeed: 1.2`, `maxSize: 2.5`, `color: Colors.white`, `fill: true`.

### Deprecated Aliases

- `particleCount`: Deprecated compatibility alias for `count`.
- `particleColor`: Deprecated compatibility alias for `color`.

### Methods

- `copyWith(...)`: Returns a modified copy with specified fields overridden.
- Standard value equality via `operator ==`, `hashCode`, and `toString()`.

---

## 4. Network Line Configuration: `NetworkFeatures`

Source File: [lib/src/core/network_features.dart](file:///home/dexter/flutter_library/particles_network/lib/src/core/network_features.dart)

An immutable configuration object encapsulating all visual, geometric, and backend rendering settings for the inter-particle connection lines.

### Constructor: `NetworkFeatures`

| Parameter  | Type           | Default Value                              | Description                                                                                                    |
| ---------- | -------------- | ------------------------------------------ | -------------------------------------------------------------------------------------------------------------- |
| `enabled`  | `bool`         | `true`                                     | Enables or disables drawing connection lines between nearby particles.                                         |
| `width`    | `double`       | `0.5`                                      | Stroke thickness of connection lines in logical pixels.                                                        |
| `distance` | `double`       | `100.0`                                    | Maximum proximity distance threshold for drawing a connection line (connection radius).                        |
| `color`    | `Color`        | `const Color.fromARGB(255, 100, 255, 180)` | Base color for network connection lines (line opacity fades smoothly with distance).                          |
| `renderer` | `LineRenderer` | `LineRenderer.vertices`                    | GPU rasterization backend (`vertices` batches quads into `drawVertices`; `stroke` uses legacy path rendering). |

### Deprecated Aliases

- `drawNetwork`: Deprecated compatibility alias for `enabled`.
- `lineWidth`: Deprecated compatibility alias for `width`.
- `lineDistance`: Deprecated compatibility alias for `distance`.
- `lineColor`: Deprecated compatibility alias for `color`.
- `lineRenderer`: Deprecated compatibility alias for `renderer`.

### Methods

- `copyWith(...)`: Returns a modified copy with specified fields overridden.
- Standard value equality via `operator ==`, `hashCode`, and `toString()`.

---

## 5. Touch Interaction Configuration: `TouchFeatures`

Source File: [lib/src/interaction/touch_features.dart](file:///home/dexter/flutter_library/particles_network/lib/src/interaction/touch_features.dart)

An immutable configuration object controlling touch, mouse drag, and desktop hover physics (attraction vs. repulsion, recovery settling speed, velocity ceiling, and glowing highlight colors).

### Constructor: `TouchFeatures`

| Parameter  | Type        | Default Value                              | Description                                                                                              |
| ---------- | ----------- | ------------------------------------------ | -------------------------------------------------------------------------------------------------------- |
| `type`     | `TouchType` | `TouchType.push`                           | Interaction physics mode: `TouchType.push` (repels/scatters, default) or `TouchType.pull` (attracts).     |
| `show`     | `bool`      | `true`                                     | Enables or disables rendering touch connecting lines while keeping touch physics active.                 |
| `enabled`  | `bool`      | `true`                                     | Enables touch and gesture interactions.                                                                  |
| `speed`    | `double`    | `0.42`                                     | Recovery settling speed returning particles to cruising speed after touch release.                       |
| `force`    | `double`    | `0.42`                                     | Acceleration intensity pulling or pushing particles relative to the pointer location.                    |
| `maxSpeed` | `double`    | `5.5`                                      | Strict velocity ceiling during touch interaction to prevent runaway acceleration.                       |
| `damping`  | `double`    | `0.985`                                    | Fluid resistance drag factor within the touch field preventing excessive slingshot oscillation.          |
| `distance` | `double?`   | `null`                                     | Effective touch interaction radius (defaults to widget/network `distance` when `null`).                  |
| `color`    | `Color`     | `const Color(0xFFFFC107)` (`Colors.amber`) | Highlight line color for touch connections.                                                              |
| `hover`    | `bool`      | `false`                                    | Enables mouse cursor tracking on desktop and web without requiring a pointer press or drag gesture.     |

### Deprecated Aliases

- `touchActivation`: Deprecated compatibility alias for `enabled`.
- `decayRate`: Deprecated compatibility alias for `speed`.
- `pullForce`: Deprecated compatibility alias for `force`.
- `maxTouchSpeed`: Deprecated compatibility alias for `maxSpeed`.
- `lineDistance`: Deprecated compatibility alias for `distance`.
- `hoverEffect`: Deprecated compatibility alias for `hover`.

### Methods

- `copyWith(...)`: Returns a modified copy with specified fields overridden.
- Standard value equality via `operator ==`, `hashCode`, and `toString()`.

---

## 6. Performance & Rendering Optimization: `PerformanceFeatures` & `ComplexConfig`

Source Files:  
- [lib/src/rendering/network_performance.dart](file:///home/dexter/flutter_library/particles_network/lib/src/rendering/network_performance.dart)  
- [lib/src/rendering/complex_features.dart](file:///home/dexter/flutter_library/particles_network/lib/src/rendering/complex_features.dart)

### Constructor: `PerformanceFeatures`

| Parameter                   | Type            | Default Value           | Description                                                                                                   |
| --------------------------- | --------------- | ----------------------- | ------------------------------------------------------------------------------------------------------------- |
| `maxConnectionsPerParticle` | `int?`          | `null`                  | Upper bound on connection lines emitted per particle (transitions asymptotic complexity from $O(N^2)$ to $O(N)$).|
| `maxLinesPerFrame`          | `int?`          | `null`                  | Global line budget per frame; smoothly contracts the connection radius under load to stabilize frame time.   |
| `frameRateIndependent`      | `bool`          | `false`                 | Scales physics integration by delta-time so particle speeds remain identical across 60Hz, 90Hz, and 120Hz.   |
| `complex`                   | `ComplexConfig` | `const ComplexConfig()` | High-density particle cluster optimization and connection throttling settings.                                |
| `cappedDistanceFactor`      | `double`        | `0.75`                  | Safety radius multiplier when pruning connections to eliminate visual pop-in flickering.                     |
| `antiAlias`                 | `bool`          | `true`                  | Enables anti-aliasing on canvas paints.                                                                       |
| `spatialCellMultiplier`     | `double?`       | `null`                  | Scaling factor for `SortedSpatialGrid` cell dimensions.                                                       |
| `autoBoost`                 | `bool`          | `false`                 | Enables real-time dynamic frame-time adaptation via `AdaptivePerformanceController`.                          |

### `ComplexConfig` Configuration

Controls high-density particle cluster throttling and connection pruning:

```dart
const ComplexConfig({
  this.enabled = false,
  this.ratio,
  this.maxLines,
  this.densityFactor,
});

// Preset for automatic clustering thresholds:
const ComplexConfig.auto();
```

- `enabled`: Enables cluster throttling logic (`false` by default).
- `ratio`: Cluster detection ratio threshold.
- `maxLines`: Connection cap within dense clusters.
- `densityFactor`: Distance multiplier within dense clusters.

### Built-in Presets for `PerformanceFeatures`

1. **`PerformanceFeatures.highPerformance()`**:
   - `maxConnectionsPerParticle: 4`
   - `maxLinesPerFrame: 15000`
   - `frameRateIndependent: true`
   - `complex: const ComplexConfig.auto()`
   - `cappedDistanceFactor: 0.75`
   - `antiAlias: true`
   - `autoBoost: false`
2. **`PerformanceFeatures.complex()`**:
   - `complex: const ComplexConfig(enabled: true, ratio: 0.5, maxLines: 3, densityFactor: 0.60)`
   - `cappedDistanceFactor: 0.75`
   - `antiAlias: true`
   - `autoBoost: false`
3. **`PerformanceFeatures.auto()`**:
   - `frameRateIndependent: true`
   - `complex: const ComplexConfig.auto()`
   - `cappedDistanceFactor: 0.75`
   - `antiAlias: true`
   - `autoBoost: true` (enables real-time dynamic adaptation)
4. **`PerformanceFeatures.balanced()`**:
   - `maxConnectionsPerParticle: 6`
   - `maxLinesPerFrame: 8000`
   - `frameRateIndependent: true`
   - `complex: const ComplexConfig()`
   - `cappedDistanceFactor: 0.75`
   - `antiAlias: true`
   - `autoBoost: false`

---

## 7. Gravity & Physics Forces: `GravityFeatures` & `GravityType`

Source File: [lib/src/physics/particle_gravity.dart](file:///home/dexter/flutter_library/particles_network/lib/src/physics/particle_gravity.dart)

### Enum: `GravityType`

- `GravityType.none`: No external gravity field applied (default).
- `GravityType.global`: Uniform directional acceleration applied to all particles (e.g. downward rain or lateral wind).
- `GravityType.point`: Radial gravity directed toward or away from a focal point (attractor if positive, repeller if negative).

### Class: `GravityFeatures`

#### Primary Constructor: `GravityFeatures(...)`

| Parameter   | Type          | Default Value        | Description                                                                                     |
| ----------- | ------------- | -------------------- | ----------------------------------------------------------------------------------------------- |
| `type`      | `GravityType` | `GravityType.none`   | Physics gravity mode applied to particles.                                                      |
| `strength`  | `double`      | `0.1`                | Force intensity (in point mode: positive attracts particles, negative repels them).             |
| `direction` | `Offset`      | `const Offset(0, 1)` | Direction vector for global gravity (default points downwards).                                 |
| `center`    | `Offset?`     | `null`               | Coordinates of the point gravity attractor (defaults to viewport center when `null`).          |

#### Named Constructors

- **`GravityFeatures.none()`**: Disabled gravity (`type: GravityType.none`, `strength: 0.0`).
- **`GravityFeatures.global({double strength = 0.1, Offset direction = const Offset(0, 1)})`**: Directional global field.
- **`GravityFeatures.point({double strength = 0.1, Offset? center})`**: Point attractor/repeller field.

#### Backward Compatibility: `GravityConfig`

- `class GravityConfig extends GravityFeatures`: Subclass preserving v1.9.6 compatibility without code modifications (`strength: 0.5`, non-nullable `center: Offset.zero`).

---

## 8. Particle Model & Mathematics: `Particle` and Helper Utilities

Source File: [lib/src/core/particle.dart](file:///home/dexter/flutter_library/particles_network/lib/src/core/particle.dart)

The fundamental unit of the simulation, engineered with primitive unboxed `double` fields to guarantee **Zero Heap Allocation** during frame updates.

### Constructor: `Particle(...)`

| Parameter    | Type     | Default Value | Description                                                                                    |
| ------------ | -------- | ------------- | ---------------------------------------------------------------------------------------------- |
| `position`   | `Offset` | *(Required)*  | Initial particle location (unpacked into `x` and `y`).                                         |
| `velocity`   | `Offset` | *(Required)*  | Initial velocity vector (unpacked into `vx` and `vy`).                                         |
| `color`      | `Color`  | *(Required)*  | Particle render color.                                                                         |
| `size`       | `double` | *(Required)*  | Particle radius (mass automatically scales as $\text{size}^2$).                                |
| `isVisible`  | `bool`   | `true`        | Visibility status within the viewport.                                                         |

### Fields & Properties

| Field / Property         | Type     | Initial / Default Value | Description                                                                        |
| ------------------------ | -------- | ----------------------- | ---------------------------------------------------------------------------------- |
| `x`, `y`                 | `double` | From `position`         | Primitive floating-point 2D coordinates.                                           |
| `vx`, `vy`               | `double` | From `velocity`         | Primitive floating-point velocity components.                                      |
| `ax`, `ay`               | `double` | `0.0`                   | Accumulated frame acceleration forces.                                             |
| `mass`                   | `double` | `size * size`           | Particle inertia mass ($a = F / m$).                                               |
| `defaultVx`, `defaultVy` | `double` | Initial velocity        | Baseline cruising velocity restored once external impulses fade.                   |
| `wasAccelerated`         | `bool`   | `false`                 | Flag indicating active external acceleration (e.g. touch or drag).                 |
| `decayRate`              | `double` | `0.012`                 | Rate of velocity decay back to baseline velocity.                                  |
| `position`               | `Offset` | Getter / Setter         | High-level `Offset` accessor and mutator.                                          |
| `velocity`               | `Offset` | Getter / Setter         | High-level `Offset` accessor and mutator.                                          |
| `acceleration`           | `Offset` | Getter / Setter         | High-level `Offset` accessor and mutator.                                          |
| `defaultVelocity`        | `Offset` | Getter / Setter         | High-level `Offset` accessor and mutator.                                          |

### Particle Methods

- `void applyForce(Offset force)`: Applies a 2D force vector.
- `void applyForceRaw(double fx, double fy)`: Applies a 2D force using primitive values without object allocation.
- `void update(Size bounds)`: Advances the particle by one reference frame (60Hz).
- `void advance(Size bounds, double timeScale)`: Advances the particle scaled by delta-time.
- `void handleScreenBoundaries(Size bounds)`: Handles elastic bounce reflection at canvas boundaries.
- `void updateVisibility(Size bounds)`: Updates the `isVisible` flag based on viewport bounds.

### Exported Helper Functions

1. **`scaleFrameRate(double rate, double timeScale) -> double`**:
   - Converts reference-frame decay factors to match the active screen refresh rate.
2. **`computeVelocity(Offset currentVelocity, Offset defaultVelocity, double speedThreshold, [double decayRate = 0.012]) -> Offset`**:
   - Computes gradual velocity decay towards default cruising velocity.
3. **`createMockParticle({Offset? position, Offset? velocity, Color? color, double? size}) -> Particle`**:
   - Utility for unit tests and benchmarks (`position: Offset.zero`, `velocity: Offset.zero`, `color: Colors.white`, `size: 1.0`).

---

## 9. Geometric Primitives: `Rectangle`

Source File: [lib/src/core/rectangle.dart](file:///home/dexter/flutter_library/particles_network/lib/src/core/rectangle.dart)

An Axis-Aligned Bounding Box (AABB) designed for geometric spatial queries and viewport intersection tests:

- **Constructor:** `const Rectangle(double x, double y, double width, double height)`
- **Properties:** `x`, `y`, `width`, `height`, `left`, `top`, `right`, `bottom`.
- **Methods:**
  - `bool contains(double px, double py)`: Point-in-rectangle containment test.
  - `bool intersects(Rectangle other)`: Separating Axis Theorem (SAT) AABB intersection test.
  - `bool intersectsCircle(double cx, double cy, double radius)`: Circle-rectangle intersection test without expensive `sqrt` calls.

---

## 10. Trajectory Caching: `TrajectoryBuffer`

Source File: [lib/src/core/trajectory_buffer.dart](file:///home/dexter/flutter_library/particles_network/lib/src/core/trajectory_buffer.dart)

A deterministic precomputation engine caching upcoming particle positions in contiguous flat arrays (`Float64List`) during idle periods to eliminate per-frame math:

- **Constructor:** `TrajectoryBuffer({int capacity = 120})`
- **Properties:**
  - `isValid`: Whether cached frame data is valid for playback.
  - `currentFrame`: Read pointer inside the precomputed batch.
  - `remainingFrames`: Frames remaining in the active batch.
- **Methods:**
  - `void invalidate()`: Invalidates cache (triggered upon touch or canvas resize).
  - `void precompute({required List<Particle> particles, required Size bounds, required IParticleController controller, GravityFeatures gravity = const GravityFeatures()})`: Generates future frames.
  - `bool advance(List<Particle> particles)`: Steps forward one frame and writes positions to particles.

---

## 11. Particle Factory: `IParticleFactory` & `DefaultParticleFactory`

Source File: [lib/src/factory/default_particle_factory.dart](file:///home/dexter/flutter_library/particles_network/lib/src/factory/default_particle_factory.dart)

Abstract interface and default implementation for the Particle Factory pattern:

### `IParticleFactory` Interface

- `Particle createParticle(Size size)`: Spawns a new particle within the specified bounds.

### `DefaultParticleFactory` Implementation

- **Constructor:**
  ```dart
  DefaultParticleFactory({
    required Random random,
    required double maxSpeed,
    required double maxSize,
    required Color color,
  })
  ```
- Generates uniformly distributed random coordinates, velocities, and radii within configured bounds.

---

## 12. Touch Interaction Handler: `TouchInteractionHandler`

Source File: [lib/src/interaction/touch_interaction_handler.dart](file:///home/dexter/flutter_library/particles_network/lib/src/interaction/touch_interaction_handler.dart)

Engine handling pointer proximity physics, repulsion/attraction impulses, connecting lines, and precomputed color Look-Up Tables (LUT):

### Constructor: `TouchInteractionHandler`

| Parameter             | Type                   | Default Value           | Description                                                        |
| --------------------- | ---------------------- | ----------------------- | ------------------------------------------------------------------ |
| `particles`           | `List<Particle>`       | *(Required)*            | List of all active particles.                                      |
| `touchPoint`          | `Offset?`              | *(Required)*            | Active pointer position (`null` when no touch exists).              |
| `lineDistance`        | `double`               | *(Required)*            | Baseline touch connection radius.                                  |
| `touchColor`          | `Color`                | *(Required)*            | Base color for touch connection lines.                             |
| `linePaint`           | `Paint`                | *(Required)*            | Paint object used for canvas drawing.                              |
| `touchFeatures`       | `TouchFeatures`        | `const TouchFeatures()` | Touch physics and styling configuration.                           |
| `spatialGrid`         | `SortedSpatialGrid?`   | `null`                  | Active spatial grid for $O(K)$ neighbor searches.                  |
| `lineRenderer`        | `LineRenderer?`        | `LineRenderer.vertices` | Rasterization backend for touch lines.                             |
| `fastLineRendering`   | `bool?`                | `true`                  | Merges touch lines into a single GPU draw call.                    |

### Properties & Getters

- `bool show`: Getter and setter controlling whether touch connection lines are rendered.

### Methods

- `void rebuildTouchColorLut(Color newColor)`: Rebuilds the 256-level alpha fade LUT without per-frame heap allocations.
- `void applyTouchPhysics(List<int> visibleParticles, AccelerationTracker tracker, [SortedSpatialGrid? grid])`: Integrates pointer physics.
- `void applyTouchPhysicsScaled(...)`: Integrates pointer physics scaled by delta-time.
- `void drawTouchLines(Canvas canvas, List<int> visibleParticles, {...})`: Draws touch connection lines.

---

## 13. Particle Controllers & Physics: `IParticleController`, `ITimeScaledParticleController`, & `ParticleUpdater`

Source File: [lib/src/physics/particle_controller.dart](file:///home/dexter/flutter_library/particles_network/lib/src/physics/particle_controller.dart)

### Interfaces

1. **`IParticleController`**:
   - `void updateParticles(List<Particle> particles, Size bounds, {GravityFeatures gravity = const GravityFeatures()})`
2. **`ITimeScaledParticleController`**:
   - `void updateParticlesScaled(List<Particle> particles, Size bounds, double timeScale, {GravityFeatures gravity = const GravityFeatures()})`

### Implementation: `ParticleUpdater`

- Implements `ITimeScaledParticleController` using high-precision **Semi-implicit Euler Integration**, supporting directional and point gravity with zero allocations in the hot loop.

---

## 14. Simulation Engine: `ParticleSimulation`

Source File: [lib/src/simulation/particle_simulation.dart](file:///home/dexter/flutter_library/particles_network/lib/src/simulation/particle_simulation.dart)

Decoupled simulation engine managing particle lifecycles, bounds, and physics independent of the Flutter widget tree:

### Constructor: `ParticleSimulation`

| Parameter         | Type                   | Default Value                 | Description                                    |
| ----------------- | ---------------------- | ----------------------------- | ---------------------------------------------- |
| `particleCount`   | `int`                  | *(Required)*                  | Target particle count to simulate.             |
| `factory`         | `IParticleFactory?`    | `DefaultParticleFactory(...)` | Particle creation factory.                     |
| `controller`      | `IParticleController?` | `ParticleUpdater()`           | Physics integration controller.                |
| `gravityConfig`   | `GravityFeatures`      | `const GravityFeatures()`     | Active gravity configuration.                  |
| `maxSpeed`        | `double`               | `0.5`                         | Maximum random cruising speed.                 |
| `maxSize`         | `double`               | `1.5`                         | Maximum particle radius.                       |
| `particleColor`   | `Color`                | `const Color(0xFFFFFFFF)`     | Default particle color.                        |
| `spatialGrid`     | `SortedSpatialGrid?`   | `SortedSpatialGrid()`         | Spatial partitioning grid instance.            |

### Methods

- `void step([double timeScale = 1.0])`: Steps the physics simulation forward by one delta increment.
- `void updateSize(Size size)`: Updates bounds and safely repopulates/repositions particles.
- `void updateParticleCount(int count)`: Adjusts particle count smoothly without a full restart.
- `void updateGravity(GravityFeatures config)`: Updates active gravity forces.
- `void updateFactory(...)`: Updates the particle factory configuration.
- `void buildSpatialGrid([double radius = 100.0, List<int>? visibleIndices, double? cellMultiplier])`: Reindexes the spatial partitioning grid.

---

## 15. Spatial Partitioning: `SortedSpatialGrid` & `GridTuning`

Source File: [lib/src/spatial/sorted_spatial_grid.dart](file:///home/dexter/flutter_library/particles_network/lib/src/spatial/sorted_spatial_grid.dart)

High-performance canonical spatial partitioning grid based on a contiguous **Structure-of-Arrays (SoA)** layout, eliminating pointer chasing and cache misses.

### Configuration Class: `GridTuning`

```dart
const GridTuning({
  this.cellMultiplierK = 4.0,       // Cell density multiplier
  this.minCellFloor = 4.0,          // Minimum cell size (4px)
  this.fitToBoundingBox = false,    // Fits grid to particle bounding box rather than full canvas
  this.maxTotalCells = 250000,      // Upper limit on allocated grid cells
})
```

### Grid Class: `SortedSpatialGrid`

- **Constructor:** `SortedSpatialGrid({GridTuning? tuning})` (Defaults to `const GridTuning()`).
- **Fields & Arrays:**
  - `cellSize`: Final cell edge length in logical pixels.
  - `cols`, `rows`: Grid dimensions.
  - `count`: Number of particles currently indexed.
  - `cellStart`: Int32List of cell boundary offsets.
  - `xs`, `ys`: Contiguous Float64List coordinate buffers.
  - `indices`: Int32List storing original particle indices.
- **Query Methods:**
  - `void build(List<Particle> particles, List<int>? visible, double width, double height, double radius, [double? cellMultiplier])`
  - `void queryRadius(double qx, double qy, double radius, void Function(int idx, double px, double py, double distSq) onHit)`
  - `void queryRect(double minX, double minY, double maxX, double maxY, void Function(int idx, double px, double py) onHit)`
  - `void scanPairs(double radius, void Function(int i, int j, double distSq) onPair)`
- **Static Diagnostics & Profiling Counters:**
  - `candidateChecks`, `loopIterations`, `acceptedPairs`, `scanLoopMicros`, `gridBuildMicros`, `ratio`, `resetCounters()`.

---

## 16. GPU Batching Layer: `LineRenderer` & `LineVertexBatch`

Source File: [lib/src/rendering/line_vertex_batch.dart](file:///home/dexter/flutter_library/particles_network/lib/src/rendering/line_vertex_batch.dart)

### Enum: `LineRenderer`

- `LineRenderer.stroke`: Classic line drawing via `drawLine` or `drawRawPoints` with round caps.
- `LineRenderer.vertices`: Converts each line segment into a two-triangle quad in local vertex memory and submits batched calls via `Canvas.drawVertices`, achieving 4x–10x GPU throughput.

### Class: `LineVertexBatch`

- **Constants:** `maxQuadsPerDraw = 16383` (maximum quads per call to stay within 16-bit vertex indices).
- **Properties:** `lineCount`, `hasColors`, `positions`, `colors`.
- **Methods:**
  - `static Uint16List indicesFor(int quads)`: Retrieves cached shared index buffers.
  - `void clear()`: Resets batch count while retaining memory allocations.
  - `void addSegments(Float32List segments, int floatCount, double halfWidth, [Int32List? colors, int? color])`: Adds line segments.
  - `void draw(Canvas canvas, Paint paint)`: Executes `Canvas.drawVertices`.

---

## 17. Custom Painter: `OptimizedNetworkPainter`

Source File: [lib/src/rendering/optimized_network_painter.dart](file:///home/dexter/flutter_library/particles_network/lib/src/rendering/optimized_network_painter.dart)

A specialized `CustomPainter` orchestrating the entire rendering pipeline.

### Constructor: `OptimizedNetworkPainter`

| Parameter                   | Type                   | Default Value                                |
| --------------------------- | ---------------------- | -------------------------------------------- |
| `particleCount`             | `int`                  | *(Required)*                                 |
| `particles`                 | `List<Particle>`       | *(Required)*                                 |
| `touchPoint`                | `Offset?`              | *(Required)*                                 |
| `lineDistance`              | `double`               | *(Required)*                                 |
| `particleColor`             | `Color`                | *(Required)*                                 |
| `lineColor`                 | `Color`                | *(Required)*                                 |
| `touchColor`                | `Color?`               | `null` (extracted from `touchFeatures`)      |
| `lineWidth`                 | `double`               | *(Required)*                                 |
| `fill`                      | `bool`                 | *(Required)*                                 |
| `drawNetwork`               | `bool`                 | *(Required)*                                 |
| `touchFeatures`             | `TouchFeatures`        | `const TouchFeatures()`                      |
| `performance`               | `PerformanceFeatures`  | `const PerformanceFeatures()`                |
| `maxConnectionsPerParticle` | `int?`                 | `null`                                       |
| `maxLinesPerFrame`          | `int?`                 | `null`                                       |
| `simulateTouchInPaint`      | `bool`                 | `true`                                       |
| `lineRenderer`              | `LineRenderer?`        | `null`                                       |
| `devicePixelRatio`          | `double`               | `1.0`                                        |
| `antiAlias`                 | `bool?`                | `null`                                       |
| `complexReductionRatio`     | `double?`              | `null`                                       |
| `maxComplexLines`           | `int?`                 | `null`                                       |
| `complexDensityFactor`      | `double?`              | `null`                                       |
| `gridTuning`                | `GridTuning?`          | `const GridTuning()`                         |
| `spatialGrid`               | `SortedSpatialGrid?`   | `null`                                       |
| `repaint`                   | `Listenable?`          | `null`                                       |

### Live Painter Mutator Methods

- `updateTouchPoint(Offset? newPoint)`
- `updateColors({required Color particleColor, required Color lineColor, required Color touchColor})`
- `updateLineWidth(double width)`
- `updateLineDistance(double distance)`
- `updateRenderFlags({required bool drawNetwork, required bool fill, required bool isComplex, required bool touchActivation})`
- `updateTouchFeatures(TouchFeatures features)`
- `bool show`: Getter and setter controlling whether touch interaction lines are rendered.
- `updatePerformance(PerformanceFeatures perf)`
- `resetRuntimeOverrides()`

---

## 18. Viewport Particle Culling: `ParticleFilter`

Source File: [lib/src/rendering/particle_filter.dart](file:///home/dexter/flutter_library/particles_network/lib/src/rendering/particle_filter.dart)

Utilities for culling off-screen particles outside the visible viewport:

1. `static void getVisibleParticlesTo(List<Particle> particles, List<int> output)`:
   - Populates an existing output list with visible particle indices without allocating new heap memory.
2. `static void getVisibleParticlesUsingGrid(SortedSpatialGrid grid, Rect viewport, List<int> output)`:
   - Ultra-fast $O(K_{\text{viewport}})$ culling using the spatial grid instead of scanning all particles linearly.
3. `static List<int> getVisibleParticles(List<Particle> particles)`:
   - *(Deprecated)* Legacy method that allocated a new `List<int>` every frame, producing garbage collection pressure.

---

## 19. Performance Profiling & Adaptation: `AccelerationTracker`, `PerformanceMonitor`, & `AdaptivePerformanceController`

Source File: [lib/src/rendering/performance_utils.dart](file:///home/dexter/flutter_library/particles_network/lib/src/rendering/performance_utils.dart)

### `AccelerationTracker`

- Tracks particles accelerated by touch to eliminate idle friction checks once all particles settle.
- Methods: `recordAcceleration()`, `resetFrame()`, `hadAcceleratedParticles`, `lastFrameAcceleratedCount`.

### `PerformanceMonitor`

- 60-frame rolling window calculating `averageFrameTime` and detecting dropped frames via `isDroppingFrames()`.

### `AdaptivePerformanceController`

- Implements a Dual-Tier Degradation Ladder to maintain a solid 60FPS/120FPS under fluctuating system load.
- **Constants:**
  - `minFloor = 500`: Minimum safe line budget floor.
  - `absoluteMaxCap = 25000`: Upper ceiling on interactive lines.
  - `initialDynamicLines = 4000.0`: Default line budget starting point.
  - `outlierCutoffMs = 250.0`: Threshold ignoring cold-start and app-resume latency spikes.
  - `emergencySteps = [16, 8, 4]`: Emergency degradation thresholds for connections per particle.
- **Properties:** `dynamicLineBudget`, `emaFrameTimeMs`, `scaleFactor`, `isEmergencyActive`, `emergencyMaxConnections`.
- **Methods:**
  - `void recordFrame({required double frameTimeMs, required int visibleCount})`
  - `void recordFrameTime(Duration duration, [int visibleCount = 100])`
  - `void reset({double? targetFrameTimeMs})`

---

## 20. Memory & Object Pooling: `ObjectPool` & `PoolManager`

Source File: [lib/src/rendering/object_pool.dart](file:///home/dexter/flutter_library/particles_network/lib/src/rendering/object_pool.dart)

Object recycling pools designed to eliminate garbage collection pauses in rendering loops:

1. **`ObjectPool<T>`**:
   - Generic object pool: `acquire()`, `release(T object)`, `clear()`, `poolSize`.
2. **`IntListPool`**:
   - Recycles reusable `List<int>` instances (default max capacity: `500`).
3. **`ConnectionDataPool`**:
   - Recycles `ConnectionData(index, distance)` instances (default max capacity: `1000`).
4. **`PoolManager`**:
   - Singleton manager accessed via `PoolManager.getInstance()`, offering `intListPool` and `connectionDataPool` along with `clearAll()` and `resetAll()`.

---

## 21. Deprecated APIs & Migration Guide (v2.0.0)

Reference Document: [DEPRECATED_APIS.md](file:///home/dexter/flutter_library/particles_network/DEPRECATED_APIS.md)

All entries below are tagged with `@Deprecated` and will be permanently removed in `v2.0.0`:

| Deprecated Identifier                | Location / Type                    | Canonical Replacement                                 |
| ------------------------------------ | ---------------------------------- | ----------------------------------------------------- |
| `particleCount`                      | Parameter in `ParticleNetwork`     | `particles: ParticleFeatures(count: ...)`             |
| `maxSpeed`                           | Parameter in `ParticleNetwork`     | `particles: ParticleFeatures(maxSpeed: ...)`          |
| `maxSize`                            | Parameter in `ParticleNetwork`     | `particles: ParticleFeatures(maxSize: ...)`           |
| `particleColor`                      | Parameter in `ParticleNetwork`     | `particles: ParticleFeatures(color: ...)`             |
| `fill`                               | Parameter in `ParticleNetwork`     | `particles: ParticleFeatures(fill: ...)`              |
| `particleFeatures`                   | Parameter in `ParticleNetwork`     | `particles: ParticleFeatures(...)`                    |
| `drawNetwork`                        | Parameter in `ParticleNetwork`     | `network: NetworkFeatures(enabled: ...)`              |
| `lineWidth`                          | Parameter in `ParticleNetwork`     | `network: NetworkFeatures(width: ...)`                |
| `lineDistance`                       | Parameter in `ParticleNetwork`     | `network: NetworkFeatures(distance: ...)`             |
| `lineColor`                          | Parameter in `ParticleNetwork`     | `network: NetworkFeatures(color: ...)`                |
| `networkFeatures`                    | Parameter in `ParticleNetwork`     | `network: NetworkFeatures(...)`                       |
| `isComplex`                          | Parameter in `ParticleNetwork`     | `performance: PerformanceFeatures(complex: ...)`      |
| `maxConnectionsPerParticle`          | Parameter in `ParticleNetwork`     | `performance: PerformanceFeatures(maxConnections: ...)` |
| `adaptiveDensity`                    | Parameter in `ParticleNetwork`     | `performance: PerformanceFeatures(complex: ...)`      |
| `fastLineRendering`                  | Parameter in `ParticleNetwork`     | `network: NetworkFeatures(renderer: ...)`             |
| `useVerticesRendering`               | Parameter in `ParticleNetwork`     | `network: NetworkFeatures(renderer: ...)`             |
| `enableAdaptivePerformance`          | Parameter in `ParticleNetwork`     | `performance: PerformanceFeatures(autoBoost: true)`   |
| `touchActivation`                    | Parameter in `ParticleNetwork`     | `touch: TouchFeatures(enabled: ...)`                  |
| `touchColor`                         | Parameter in `ParticleNetwork`     | `touch: TouchFeatures(color: ...)`                    |
| `touchFeatures`                      | Parameter in `ParticleNetwork`     | `touch: TouchFeatures(...)`                           |
| `hoverEffect`                        | Parameter in `ParticleNetwork`     | `touch: TouchFeatures(hover: ...)`                    |
| `gravityType`                        | Parameter in `ParticleNetwork`     | `gravity: GravityFeatures(type: ...)`                 |
| `gravityStrength`                    | Parameter in `ParticleNetwork`     | `gravity: GravityFeatures(strength: ...)`             |
| `gravityDirection`                   | Parameter in `ParticleNetwork`     | `gravity: GravityFeatures(direction: ...)`            |
| `gravityCenter`                      | Parameter in `ParticleNetwork`     | `gravity: GravityFeatures(center: ...)`               |
| `particleFactory`                    | Parameter in `ParticleNetwork`     | Pass to `ParticleSimulation`                          |
| `particleController`                 | Parameter in `ParticleNetwork`     | Pass to `ParticleSimulation`                          |
| `particleCount`                      | Property in `ParticleFeatures`     | `ParticleFeatures.count`                              |
| `particleColor`                      | Property in `ParticleFeatures`     | `ParticleFeatures.color`                              |
| `drawNetwork`                        | Property in `NetworkFeatures`      | `NetworkFeatures.enabled`                             |
| `lineWidth`                          | Property in `NetworkFeatures`      | `NetworkFeatures.width`                               |
| `lineDistance`                       | Property in `NetworkFeatures`      | `NetworkFeatures.distance`                            |
| `lineColor`                          | Property in `NetworkFeatures`      | `NetworkFeatures.color`                               |
| `lineRenderer`                       | Property in `NetworkFeatures`      | `NetworkFeatures.renderer`                            |
| `touchActivation`                    | Property in `TouchFeatures`        | `TouchFeatures.enabled`                               |
| `decayRate`                          | Property in `TouchFeatures`        | `TouchFeatures.speed`                                 |
| `pullForce`                          | Property in `TouchFeatures`        | `TouchFeatures.force`                                 |
| `maxTouchSpeed`                      | Property in `TouchFeatures`        | `TouchFeatures.maxSpeed`                              |
| `lineDistance`                       | Property in `TouchFeatures`        | `TouchFeatures.distance`                              |
| `hoverEffect`                        | Property in `TouchFeatures`        | `TouchFeatures.hover`                                 |
| `GravityConfig`                      | Class / Subclass                   | `GravityFeatures`                                     |
| `ParticleFilter.getVisibleParticles` | Method in `ParticleFilter`         | `ParticleFilter.getVisibleParticlesTo`                |

---

## 22. Complete Example with All APIs & Default Values

The code snippet below demonstrates instantiating `ParticleNetwork` with all modular configuration objects (`ParticleFeatures`, `NetworkFeatures`, `TouchFeatures`, `PerformanceFeatures`, `GravityFeatures`, and `SortedSpatialGrid`), displaying every available canonical option with its default value:

```dart
import 'package:flutter/material.dart';
import 'package:particles_network/particles_network.dart';

class CompleteParticleNetworkScreen extends StatelessWidget {
  const CompleteParticleNetworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ParticleNetwork(
        // ==========================================
        // 1. Particle Configuration
        // ==========================================
        particles: const ParticleFeatures(
          count: 60,                                          // Total particle cloud density
          maxSpeed: 0.5,                                      // Maximum random cruising speed (px/frame)
          maxSize: 1.5,                                       // Maximum particle radius in pixels
          color: Color(0xFFFFFFFF),                           // Particle color (Colors.white)
          fill: true,                                         // Render filled circles (true) or stroked rings (false)
        ),

        // ==========================================
        // 2. Network Connection Lines Configuration
        // ==========================================
        network: const NetworkFeatures(
          width: 0.5,                                         // Stroke width of connection lines
          distance: 100.0,                                    // Connection radius threshold
          color: Color.fromARGB(255, 100, 255, 180),          // Connection line color
          enabled: true,                                      // Whether network lines are drawn
          renderer: LineRenderer.vertices,                    // GPU rasterization mode (.vertices or .stroke)
        ),

        // ==========================================
        // 3. Touch & Pointer Interaction Configuration
        // ==========================================
        touch: const TouchFeatures(
          type: TouchType.push,                               // TouchType.push (repels, default) or TouchType.pull (attracts)
          hover: false,                                       // Enables cursor proximity tracking on desktop/web
          enabled: true,                                      // Enables touch and drag interaction
          speed: 0.42,                                        // Recovery settling speed after release
          force: 0.42,                                        // Impulse force strength
          maxSpeed: 5.5,                                      // Maximum speed ceiling during touch interaction
          damping: 0.985,                                     // Fluid resistance damping factor
          distance: null,                                     // Proximity radius (null uses network distance)
          color: Color(0xFFFFC107),                           // Highlight line color (Colors.amber)
        ),

        // ==========================================
        // 4. Performance & Rendering Configuration
        // ==========================================
        performance: const PerformanceFeatures(
          maxConnectionsPerParticle: null,                    // Max lines per particle (null = unconstrained)
          maxLinesPerFrame: null,                             // Global line budget per frame (null = unconstrained)
          frameRateIndependent: false,                        // Delta-time scaling for 60/90/120Hz displays
          complex: ComplexConfig(),                           // Cluster throttling for ultra-dense networks
          cappedDistanceFactor: 0.75,                         // Safety distance multiplier to avoid line popping
          antiAlias: true,                                    // Antialiasing toggle
          spatialCellMultiplier: null,                        // Spatial grid cell dimension multiplier
          autoBoost: false,                                   // Dynamic real-time frame time budget adjustment
        ),

        // ==========================================
        // 5. Gravity & External Forces Configuration
        // ==========================================
        gravity: const GravityFeatures(
          type: GravityType.none,                             // GravityType.none, .global, or .point
          strength: 0.1,                                      // Field strength (positive = pull, negative = push)
          direction: Offset(0, 1),                            // Direction vector for global gravity (downward)
          center: null,                                       // Focal point for point gravity (null = canvas center)
        ),

        // ==========================================
        // 6. Advanced Spatial Partitioning Grid
        // ==========================================
        spatialGrid: SortedSpatialGrid(
          tuning: const GridTuning(
            cellMultiplierK: 4.0,                             // Cell density multiplier
            minCellFloor: 4.0,                                // Minimum cell dimension floor in pixels
            fitToBoundingBox: false,                          // Binds grid to particle bounds instead of canvas
            maxTotalCells: 250000,                            // Maximum allocated cells ceiling
          ),
        ),

        // ==========================================
        // 7. Deprecated Parameters (Legacy Backward Compatibility Only)
        // ==========================================
        // particleCount: 60,                                 // Replaced by particles: ParticleFeatures(count: ...)
        // maxSpeed: 0.5,                                     // Replaced by particles: ParticleFeatures(maxSpeed: ...)
        // maxSize: 1.5,                                      // Replaced by particles: ParticleFeatures(maxSize: ...)
        // particleColor: const Color(0xFFFFFFFF),            // Replaced by particles: ParticleFeatures(color: ...)
        // fill: true,                                        // Replaced by particles: ParticleFeatures(fill: ...)
        // drawNetwork: true,                                 // Replaced by network: NetworkFeatures(enabled: ...)
        // lineWidth: 0.5,                                    // Replaced by network: NetworkFeatures(width: ...)
        // lineDistance: 100.0,                               // Replaced by network: NetworkFeatures(distance: ...)
        // lineColor: const Color.fromARGB(255, 100, 255, 180), // Replaced by network: NetworkFeatures(color: ...)
        // isComplex: false,                                  // Replaced by performance: PerformanceFeatures(complex: ...)
        // maxConnectionsPerParticle: null,                   // Replaced by performance: PerformanceFeatures(maxConnectionsPerParticle: ...)
        // adaptiveDensity: false,                            // Replaced by performance: PerformanceFeatures(complex: ComplexConfig.auto())
        // fastLineRendering: true,                           // Replaced by network: NetworkFeatures(renderer: LineRenderer.vertices)
        // useVerticesRendering: true,                        // Replaced by network: NetworkFeatures(renderer: LineRenderer.vertices)
        // enableAdaptivePerformance: false,                  // Replaced by performance: PerformanceFeatures(autoBoost: true)
        // touchActivation: true,                             // Replaced by touch: TouchFeatures(enabled: ...)
        // touchColor: const Color(0xFFFFC107),               // Replaced by touch: TouchFeatures(color: ...)
        // hoverEffect: false,                                // Replaced by touch: TouchFeatures(hover: ...)
        // gravityType: GravityType.none,                     // Replaced by gravity: GravityFeatures(type: ...)
        // gravityStrength: 0.1,                              // Replaced by gravity: GravityFeatures(strength: ...)
        // gravityDirection: const Offset(0, 1),              // Replaced by gravity: GravityFeatures(direction: ...)
        // gravityCenter: null,                               // Replaced by gravity: GravityFeatures(center: ...)
        // particleFactory: null,                             // Handled by ParticleSimulation
        // particleController: null,                          // Handled by ParticleSimulation
      ),
    );
  }
}
```
