# Deprecated APIs & Migration Guide

> **Target Removal Version:** `v2.0.0`  
> This document provides an exhaustive, developer-facing reference for all classes, methods, fields, and constructor parameters marked with `@Deprecated` in `particles_network`.  
> These deprecations unify naming conventions (standard CamelCase), adhere to SOLID design principles and Clean Architecture, and eliminate per-frame heap allocations (Zero Allocation) across the hot rendering pipeline.

---

## ⚡ Quick Migration Cheat-Sheet

Compare legacy initialization with modern, canonical patterns:

```dart
// ❌ Legacy Code (Deprecated in v1.9.7, scheduled for removal in v2.0.0)
ParticleNetwork(
  particleCount: 80,                     // ⚠️ Fragmented particle parameters
  maxSpeed: 0.8,                         // ⚠️ Fragmented particle parameters
  maxSize: 2.0,                          // ⚠️ Fragmented particle parameters
  particleColor: Colors.white,           // ⚠️ Fragmented particle parameters
  fill: true,                            // ⚠️ Fragmented particle parameters
  linewidth: 1.0,                        // ⚠️ Inconsistent naming
  drawnetwork: true,                     // ⚠️ Inconsistent naming
  isComplex: true,                       // ⚠️ Dispersed performance options
  touchActivation: true,                 // ⚠️ Fragmented touch configuration
  touchColor: Colors.amber,              // ⚠️ Fragmented touch configuration
  gravityType: GravityType.global,       // ⚠️ Dispersed gravity parameters
  gravityStrength: 0.15,                 // ⚠️ Dispersed gravity parameters
  gravityDirection: const Offset(0, 1),  // ⚠️ Dispersed gravity parameters
)

// ✅ Modern, Canonical Code (Clean, modular, and performance-tuned)
ParticleNetwork(
  particles: const ParticleFeatures(
    count: 80,
    maxSpeed: 0.8,
    maxSize: 2.0,
    color: Colors.white,
    fill: true,
  ),
  network: const NetworkFeatures(
    lineWidth: 1.0,
    drawNetwork: true,
  ),
  performance: const PerformanceFeatures(
    isComplex: true,
  ),
  touch: const TouchFeatures(
    enabled: true,
    color: Colors.amber,
  ),
  gravity: const GravityFeatures.global(
    strength: 0.15,
    direction: Offset(0, 1),
  ),
)
```

---

## 1. Core Widget (`ParticleNetwork`)

Source: [lib/src/widgets/particle_network_widget.dart](file:///home/dexter/flutter_library/particles_network/lib/src/widgets/particle_network_widget.dart)

### A. Deprecated Constructor Parameters

| Deprecated Parameter | Type                   | Reason & Architectural Goal                                     | Recommended Replacement                          |
| -------------------- | ---------------------- | --------------------------------------------------------------- | ------------------------------------------------ |
| `particleCount`      | `int?`                 | Consolidates particle count and density into `ParticleFeatures` | `particles: ParticleFeatures(count: ...)`        |
| `maxSpeed`           | `double?`              | Consolidates speed limits into `ParticleFeatures`               | `particles: ParticleFeatures(maxSpeed: ...)`     |
| `maxSize`            | `double?`              | Consolidates particle size bounds into `ParticleFeatures`       | `particles: ParticleFeatures(maxSize: ...)`      |
| `particleColor`      | `Color?`               | Consolidates particle styling into `ParticleFeatures`           | `particles: ParticleFeatures(color: ...)`        |
| `fill`               | `bool?`                | Consolidates rendering mode into `ParticleFeatures`             | `particles: ParticleFeatures(fill: ...)`         |
| `particleFeatures`   | `ParticleFeatures?`    | Unifies naming with `touch` and `performance`                   | `particles: ParticleFeatures(...)`               |
| `linewidth`          | `double?`              | Enforces standard Dart CamelCase naming                         | `network: NetworkFeatures(lineWidth: ...)`       |
| `drawnetwork`        | `bool?`                | Enforces standard Dart CamelCase naming                         | `network: NetworkFeatures(drawNetwork: ...)`     |
| `lineWidth`          | `double?`              | Consolidates network line settings into `NetworkFeatures`       | `network: NetworkFeatures(lineWidth: ...)`       |
| `lineDistance`       | `double?`              | Consolidates network line settings into `NetworkFeatures`       | `network: NetworkFeatures(lineDistance: ...)`    |
| `lineColor`          | `Color?`               | Consolidates network line settings into `NetworkFeatures`       | `network: NetworkFeatures(lineColor: ...)`       |
| `drawNetwork`        | `bool?`                | Consolidates network line settings into `NetworkFeatures`       | `network: NetworkFeatures(drawNetwork: ...)`     |
| `networkFeatures`    | `NetworkFeatures?`     | Canonical parameter name is `network`                           | `network: NetworkFeatures(...)`                  |
| `isComplex`          | `bool?`                | Groups rendering and performance configurations                 | `performance: PerformanceFeatures(isComplex: ...)`|
| `maxConnectionsPerParticle` | `int?`          | Consolidates degree capping into `PerformanceFeatures`          | `performance: PerformanceFeatures(maxConnectionsPerParticle: ...)`|
| `adaptiveDensity`           | `bool`          | Replaced by auto cluster density configuration                  | `performance: PerformanceFeatures(complex: ComplexConfig.auto())`|
| `fastLineRendering`         | `bool?`         | Consolidates GPU line rendering into `NetworkFeatures`          | `network: NetworkFeatures(renderer: LineRenderer.vertices)`|
| `useVerticesRendering`      | `bool?`         | Alias for `fastLineRendering` moved into `NetworkFeatures`      | `network: NetworkFeatures(renderer: LineRenderer.vertices)`|
| `enableAdaptivePerformance` | `bool`          | Replaced by telemetry auto-boost in `PerformanceFeatures`       | `performance: PerformanceFeatures(autoBoost: ...)`|
| `touchActivation`    | `bool?`                | Consolidates touch state inside `TouchFeatures`                 | `touch: TouchFeatures(enabled: ...)`             |
| `touchColor`         | `Color?`               | Consolidates touch highlight styling                            | `touch: TouchFeatures(color: ...)`               |
| `touchFeatures`      | `TouchFeatures?`       | Unifies naming with `touch` and `performance`                   | `touch: TouchFeatures(...)`                      |
| `hoverEffect`        | `bool?`                | Consolidates hover interaction inside `TouchFeatures`           | `touch: TouchFeatures(hoverEffect: ...)`         |
| `gravityType`        | `GravityType`          | Consolidates gravity configuration into an immutable object     | `gravity: GravityFeatures(type: ...)`            |
| `gravityStrength`    | `double`               | Consolidates gravity configuration into an immutable object     | `gravity: GravityFeatures(strength: ...)`        |
| `gravityDirection`   | `Offset`               | Consolidates gravity configuration into an immutable object     | `gravity: GravityFeatures(direction: ...)`       |
| `gravityCenter`      | `Offset?`              | Consolidates gravity configuration into an immutable object     | `gravity: GravityFeatures(center: ...)`          |
| `particleFactory`    | `IParticleFactory?`    | Separates particle generation concerns into simulation layer    | Pass factory directly to `ParticleSimulation`    |
| `particleController` | `IParticleController?` | Separates particle behavioral control into simulation layer     | Pass controller directly to `ParticleSimulation` |

### B. Deprecated Properties & Getters

| Deprecated Getter / Property | Type                   | Recommended Replacement                                                         |
| ---------------------------- | ---------------------- | ------------------------------------------------------------------------------- |
| `widget.particleCount`       | `int`                  | `widget.particles.count` or `widget.effectiveParticleFeatures.count`            |
| `widget.maxSpeed`            | `double`               | `widget.particles.maxSpeed` or `widget.effectiveParticleFeatures.maxSpeed`      |
| `widget.maxSize`             | `double`               | `widget.particles.maxSize` or `widget.effectiveParticleFeatures.maxSize`        |
| `widget.particleColor`       | `Color`                | `widget.particles.color` or `widget.effectiveParticleFeatures.color`            |
| `widget.fill`                | `bool`                 | `widget.particles.fill` or `widget.effectiveParticleFeatures.fill`              |
| `widget.particleFeatures`    | `ParticleFeatures`     | `widget.particles` or `widget.effectiveParticleFeatures`                        |
| `widget.isComplex`           | `bool`                 | `widget.effectiveIsComplex` or `widget.performance.isComplex`                   |
| `widget.touchActivation`     | `bool`                 | `widget.touch.enabled` or `widget.effectiveTouchFeatures.enabled`               |
| `widget.touchColor`          | `Color`                | `widget.touch.color` or `widget.effectiveTouchFeatures.color`                   |
| `widget.touchFeatures`       | `TouchFeatures`        | `widget.touch` or `widget.effectiveTouchFeatures`                               |
| `widget.hoverEffect`         | `bool`                 | `widget.touch.hoverEffect` or `widget.effectiveTouchFeatures.hoverEffect`       |
| `widget.networkFeatures`     | `NetworkFeatures`      | `widget.network` or `widget.effectiveNetworkFeatures`                           |
| `widget.lineWidth`           | `double`               | `widget.network.lineWidth` or `widget.effectiveNetworkFeatures.lineWidth`       |
| `widget.lineDistance`        | `double`               | `widget.network.lineDistance` or `widget.effectiveNetworkFeatures.lineDistance` |
| `widget.lineColor`           | `Color`                | `widget.network.lineColor` or `widget.effectiveNetworkFeatures.lineColor`       |
| `widget.drawNetwork`         | `bool`                 | `widget.network.drawNetwork` or `widget.effectiveNetworkFeatures.drawNetwork`   |
| `widget.gravityType`         | `GravityType`          | `widget.gravity?.type ?? GravityType.none`                                      |
| `widget.gravityStrength`     | `double`               | `widget.gravity?.strength ?? 0.1`                                               |
| `widget.gravityDirection`    | `Offset`               | `widget.gravity?.direction ?? const Offset(0, 1)`                               |
| `widget.gravityCenter`       | `Offset?`              | `widget.gravity?.center`                                                        |
| `widget.particleFactory`     | `IParticleFactory?`    | Access via `ParticleSimulation` model                                           |
| `widget.particleController`  | `IParticleController?` | Access via `ParticleSimulation` model                                           |

---

## 2. Particle Appearance & Physics Limits (`ParticleFeatures`)

Source: [lib/src/core/particle_features.dart](file:///home/dexter/flutter_library/particles_network/lib/src/core/particle_features.dart)

To adhere strictly to **SOLID design principles** (Single Responsibility Principle) and Clean Architecture, particle characteristics previously scattered as top-level parameters on `ParticleNetwork` have been grouped into an immutable value object: **`ParticleFeatures`**.

### A. Migrating Flat Parameters to `ParticleFeatures`

| Legacy Parameter in `ParticleNetwork` | Type     | Canonical in `ParticleFeatures` | Physical Role & Description                                                |
| ------------------------------------- | -------- | ------------------------------- | -------------------------------------------------------------------------- |
| `particleCount`                       | `int`    | `count`                         | Total simulated particles cloud density (default: `60`).                   |
| `maxSpeed`                            | `double` | `maxSpeed`                      | Wandering velocity limit in pixels per reference frame (default: `0.5`).   |
| `maxSize`                             | `double` | `maxSize`                       | Radius ceiling in logical pixels (default: `1.5`).                         |
| `particleColor`                       | `Color`  | `color`                         | Solid fill or stroked outline color (default: `Color(0xFFFFFFFF)`).        |
| `fill`                                | `bool`   | `fill`                          | Filled discs (`true`) vs hollow stroked rings (`false`) (default: `true`). |

### B. Deprecated Parameter Aliases inside `ParticleFeatures`

Parameter names within `ParticleFeatures` were streamlined to eliminate redundant prefixes:

| Deprecated Parameter in `ParticleFeatures` | Type     | Canonical Replacement | Description                                                              |
| ------------------------------------------ | -------- | --------------------- | ------------------------------------------------------------------------ |
| `particleCount`                            | `int?`   | `count`               | Legacy alias supported in constructor, `copyWith`, and property getters. |
| `particleColor`                            | `Color?` | `color`               | Legacy alias supported in constructor, `copyWith`, and property getters. |

```dart
// ✅ Modern Canonical ParticleFeatures Usage
const particles = ParticleFeatures(
  count: 80,
  maxSpeed: 0.8,
  maxSize: 2.0,
  color: Colors.white,
  fill: true,
);

// ✅ Predefined Presets
const subtleCloud = ParticleFeatures.subtle(); // 35 particles, calm speed 0.3
const denseField  = ParticleFeatures.dense();  // 120 particles, dynamic speed 0.8
const cosmicVibe  = ParticleFeatures.cosmic(); // 90 particles, fast speed 1.2
```

---

## 3. Touch Physics & Interaction (`TouchFeatures`)

Source: [lib/src/interaction/touch_features.dart](file:///home/dexter/flutter_library/particles_network/lib/src/interaction/touch_features.dart)

Parameter names within `TouchFeatures` were streamlined to be concise, unambiguous, and mathematically descriptive:

| Deprecated Name   | Type      | Canonical Replacement | Physical Role & Description                                                               |
| ----------------- | --------- | --------------------- | ----------------------------------------------------------------------------------------- |
| `touchActivation` | `bool?`   | `enabled`             | Enables or disables particle interaction upon pointer hover or drag (default: `true`).    |
| `decayRate`       | `double?` | `speed`               | Rate at which particles recover cruising velocity after touch release (default: `0.42`).  |
| `pullForce`       | `double?` | `force`               | Magnitude of attraction force drawing particles toward the touch locus (default: `0.42`). |

> **Scope of deprecation:** Applies to constructor parameters, `copyWith(...)`, and property getters.

```dart
// ✅ Modern TouchFeatures Configuration
const touchConfig = TouchFeatures(
  enabled: true,         // Replaces touchActivation
  speed: 0.5,           // Replaces decayRate
  force: 0.6,           // Replaces pullForce
  color: Colors.cyan,   // Touch connection highlight color
  maxTouchSpeed: 6.0,   // Velocity ceiling while influenced by touch field
  damping: 0.98,        // Fluid viscosity damping factor
);
```

---

## 4. Physics & Gravity Simulation (`GravityFeatures` & Aliases)

Sources:

- [lib/src/physics/particle_gravity.dart](file:///home/dexter/flutter_library/particles_network/lib/src/physics/particle_gravity.dart)
- [lib/src/physics/legacy/legacy_gravity_config.dart](file:///home/dexter/flutter_library/particles_network/lib/src/physics/legacy/legacy_gravity_config.dart)
- [lib/src/physics/gravity_config.dart](file:///home/dexter/flutter_library/particles_network/lib/src/physics/gravity_config.dart)

### A. Migration to GravityFeatures Canonical Properties

In legacy versions, `ParticleNetwork` accepted dispersed gravity parameters (`gravityType`, `gravityStrength`, `gravityDirection`, `gravityCenter`). Within `GravityFeatures`, canonical property names without redundant prefixes are used exclusively:

| Legacy Parameter in `ParticleNetwork` | Type          | Canonical in `GravityFeatures` | Description                                                        |
| ------------------------------------- | ------------- | ------------------------------ | ------------------------------------------------------------------ |
| `gravityType`                         | `GravityType` | `type`                         | Gravity field model (`none`, `global`, `point`).                   |
| `gravityStrength`                     | `double`      | `strength`                     | Force multiplier applied to particle acceleration.                 |
| `gravityDirection`                    | `Offset`      | `direction`                    | Vector direction for global gravity (default: downwards `(0, 1)`). |
| `gravityCenter`                       | `Offset?`     | `center`                       | Focal coordinates for radial point gravity.                        |

### B. Recommended Factory Constructors

Prefer idiomatic named constructors over manual parameter configuration:

```dart
// 1. Disabled Gravity (Default)
const gravity = GravityFeatures.none();

// 2. Directional Global Gravity (e.g., downward fall or wind drift)
const gravity = GravityFeatures.global(
  strength: 0.15,
  direction: Offset(0, 1),
);

// 3. Radial Point Gravity (Attractor or repulsor at specific coordinates)
const gravity = GravityFeatures.point(
  strength: 0.25,
  center: Offset(200, 300),
);
```

### C. Legacy Libraries & Typedefs

| Deprecated Symbol             | Legacy Source                | Canonical Replacement                                                   |
| ----------------------------- | ---------------------------- | ----------------------------------------------------------------------- |
| `library gravity_config.dart` | `gravity_config.dart`        | `import 'package:particles_network/src/physics/particle_gravity.dart';` |
| `class GravityConfig`         | `legacy_gravity_config.dart` | `GravityFeatures` (extends `GravityFeatures` with 1.9.6 defaults)       |

---

## 5. Spatial Indexing Structures (`CompressedQuadTree` -> `SortedSpatialGrid`)

Source: [lib/src/spatial/compressed_quad_tree.dart](file:///home/dexter/flutter_library/particles_network/lib/src/spatial/compressed_quad_tree.dart)

Legacy versions utilized pointer-chasing quadtrees (`CompressedQuadTree`). This has been superseded by **`SortedSpatialGrid`**, a Structure-of-Arrays (SoA) layout over flat typed memory (`Float64List` coordinate arrays). It cuts CPU pair-search overhead by up to 97%.

| Deprecated Class           | Status                                                     | Canonical Replacement |
| -------------------------- | ---------------------------------------------------------- | --------------------- |
| `class CompressedQuadTree` | `@Deprecated` + Emits highlighted warning in debug console | `SortedSpatialGrid`   |
| `class QuadTreeParticle`   | `@Deprecated`                                              | `Particle`            |

```dart
// ❌ Legacy QuadTree (Pointer dereferencing overhead)
final tree = CompressedQuadTree(boundary: rect, capacity: 16);

// ✅ Modern Flat-Memory Grid (Cache-locality and contiguous SIMD-ready arrays)
final grid = SortedSpatialGrid();
grid.build(particles, visibleIndices, width, height, connectionRadius);
```

---

## 6. Custom Painter Engine (`OptimizedNetworkPainter`)

Source: [lib/src/rendering/optimized_network_painter.dart](file:///home/dexter/flutter_library/particles_network/lib/src/rendering/optimized_network_painter.dart)

| Deprecated Member | Scope                    | Recommended Replacement                        |
| ----------------- | ------------------------ | ---------------------------------------------- |
| `touchActivation` | Getter & Setter          | `touchFeatures.enabled`                        |
| `isComplex`       | Getter & Setter          | `performance.isComplex`                        |
| `touchActivation` | Constructor Parameter    | `touchFeatures: TouchFeatures(enabled: ...)`   |
| `isComplex`       | Constructor Parameter    | `performance: PerformanceFeatures(isComplex: ...)` |
| `touchActivation` | `updateRenderFlags(...)` | Invoke `updateTouchFeatures(...)`              |

---

## 7. Visibility Culling (`ParticleFilter`)

Source: [lib/src/rendering/particle_filter.dart](file:///home/dexter/flutter_library/particles_network/lib/src/rendering/particle_filter.dart)

To eliminate GC pressure and frame stutter at 60–120 FPS:

| Deprecated Method                         | Drawback                                        | Zero-Allocation Replacement                                                                                           |
| ----------------------------------------- | ----------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `ParticleFilter.getVisibleParticles(...)` | Allocates a new `List<int>` on every paint pass | `ParticleFilter.getVisibleParticlesTo(particles, existingList)` or `ParticleFilter.getVisibleParticlesUsingGrid(...)` |

```dart
// ❌ Allocates new list every frame (triggers GC thrashing)
final visible = ParticleFilter.getVisibleParticles(particles, size);

// ✅ Zero-allocation: reuses a pre-allocated index buffer
ParticleFilter.getVisibleParticlesTo(particles, reusableVisibleList, size);
```

---

## 8. Runtime Deprecation Warnings (`LegacyDeprecationLogger`)

Source: [lib/src/legacy/legacy_deprecation_logger.dart](file:///home/dexter/flutter_library/particles_network/lib/src/legacy/legacy_deprecation_logger.dart)

When running applications in `Debug Mode` (`kDebugMode`), accessing deprecated members triggers a single ANSI-formatted warning banner in the console detailing the exact migration step:

```text
════════════════════════════════════════════════════════════════════════════════
[particles_network] ⚠️  DEPRECATION NOTICE (Scheduled for removal in v2.0.0)
• Deprecated API : ParticleNetwork(particleCount, maxSpeed, maxSize, particleColor, fill)
• Recommended    : ParticleNetwork(particles: ParticleFeatures(...))
════════════════════════════════════════════════════════════════════════════════
```

---

## 📅 Removal Roadmap

- **v1.9.7 (Current):** Full backward compatibility layers with helpful compile-time warnings and debug runtime guidance.
- **v2.0.0 (Upcoming Major):** All `@Deprecated` symbols will be completely removed to minimize package payload and maximize runtime efficiency.
