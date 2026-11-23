# CHANGELOG

## [1.9.7]

### Added
* **Touch Physics Interaction Mode (`TouchType`)**: Added `TouchType` enum (`push` and `pull`) to `TouchFeatures`. `TouchType.push` (default) repels and scatters particles away from the touch/mouse pointer, while `TouchType.pull` attracts particles toward it.
* **Cluster Optimization Configuration (`ComplexConfig`)**: Introduced dedicated `ComplexConfig` class (with `ComplexConfig.auto()` preset) encapsulating cluster throttling options (`enabled`, `ratio`, `maxLines`, `densityFactor`) inside `PerformanceFeatures`.
* **Network Features Configuration (`NetworkFeatures`)**: Introduced immutable `NetworkFeatures` configuration object encapsulating connection line properties with modernized parameter names (`enabled`, `width`, `distance`, `color`, `renderer`). Replaces flat line parameters on `ParticleNetwork` while preserving 100% backward compatibility for v1.9.6.
* **Particle Features Configuration (`ParticleFeatures`)**: Introduced immutable `ParticleFeatures` configuration object encapsulating particle count, max speed, max size, color, and fill mode with built-in presets (`subtle`, `dense`, `cosmic`). Replaces flat deprecated parameters on `ParticleNetwork` with full backward compatibility.
* **Performance Features Configuration (`PerformanceFeatures`)**: Grouped line budgeting, delta-time physics, and cluster throttling into a unified `PerformanceFeatures` configuration object.
* **Touch Features Hover Support (`TouchFeatures.hover`)**: Added `hover` directly into `TouchFeatures` to unify all touch and pointer interactions into a single immutable configuration object.
* **Cell-Sorted Neighbor Search (`SortedSpatialGrid`)**: Implemented structure-of-arrays (SoA) counting sort for visible particles into contiguous coordinate buffers, significantly reducing memory hopping and accelerating connection pair queries.
* **Spatial Grid Sizing & Density Tuning**: Lowered connection budgeting safety floor to 4.0 px and introduced configurable cell density multiplier ($k=4.0$), minimizing distance comparisons in dense and clustered scenes.
* **Grid Cell Count Protection**: Capped total grid cells (`SortedSpatialGrid.maxTotalCells`) to prevent excessive memory usage on ultra-high-resolution displays.
* **Configurable Tuning Constants**: Exposed `SortedSpatialGrid.defaultCellMultiplierK`, `defaultMinCellFloor`, and `OptimizedNetworkPainter.defaultMinSafetyLineDistance` for fine-grained spatial tuning.
* **Vertices Line Renderer (`LineRenderer.vertices`)**: Added opt-in indexed mesh renderer (`drawVertices`) using thin quads to minimize GPU draw calls and rasterization overhead.
* **Dynamic Line Budgeting (`maxLinesPerFrame`)**: Added line budget capping to bound per-frame connection counts by dynamically adjusting connection radius while preserving smooth alpha fading.
* **Frame-Rate Independent Motion (`frameRateIndependent`)**: Added opt-in delta-time integration so particle speeds remain consistent across varying display refresh rates (e.g. 60 Hz vs 120 Hz).
* **Time-Scaled Physics APIs**: Added `ITimeScaledParticleController`, `Particle.advance`, `TouchInteractionHandler.applyTouchPhysicsScaled`, and `scaleFrameRate` helper.
* **Diagnostics & Benchmarking**: Added `OptimizedNetworkPainter.lastFrameScanRadius`, performance benchmark harness in `example/`, and integration test suites.

### Changed
* **Default Touch Interaction Mode (`TouchType.push`)**: Defaulted touch interaction mode to `TouchType.push` (repelling/scattering particles away from the cursor), with `TouchType.pull` available for attraction.
* **Modernized Feature Parameter Names**:
  - `TouchFeatures`: `hover` (replaces `hoverEffect`), `maxSpeed` (replaces `maxTouchSpeed`), `distance` (replaces `lineDistance`), `force` (replaces `pullForce`), `speed` (replaces `decayRate`), and `enabled` (replaces `touchActivation`).
  - `NetworkFeatures`: `enabled` (replaces `drawNetwork`), `width` (replaces `lineWidth`), `distance` (replaces `lineDistance`), `color` (replaces `lineColor`), and `renderer` (replaces `lineRenderer`).
* **Default Line Renderer (`LineRenderer.vertices`)**: Upgraded the default line renderer to `LineRenderer.vertices` (submitting indexed triangle quads) for a 10x–20x GPU raster acceleration and steady 60/120 FPS. Lines render with square ends; developers desiring round-ended strokes can explicitly set `renderer: LineRenderer.stroke`.
* **100% Backward Compatibility Restoration**: Restored complete backward compatibility with all v1.9.6 APIs with informative debug deprecation logging and `@Deprecated` annotations:
  - Restored constructor parameters and getters on `ParticleNetwork`: `maxConnectionsPerParticle`, `adaptiveDensity`, `fastLineRendering`, `useVerticesRendering`, and `enableAdaptivePerformance`.
  - Restored spatial compatibility shims: `SpatialGrid`, `AdaptiveQuadTreeManager`, `Quadrant`, `CompressedPath`, `CompressedQuadTreeNode`, and `CompressedQuadTree.root`.
  - Maintained full compatibility for `GravityConfig` (defaults `strength: 0.5`, `center: Offset.zero`) and `AdaptivePerformanceController` (`reset({double targetFrameTimeMs = 16.67})`, `currentScale`, `getAdjustedLineDistance()`, `getAdjustedMaxConnections()`).
* **Modular Painter Architecture**: Refactored `OptimizedNetworkPainter` into modular, single-responsibility components (`LineBudgetController`, `FrameRadii`, `LineStylePalette`, `CandidateBuffer`, `ClusterThrottler`, `LineBuckets`, `ParticleBatchRenderer`, `PairScanner`, `LegacyPainterAdapter`) with zero steady-state heap allocations on hot paths.
* **Immutable Grid Configuration**: Replaced mutable static tuning state with immutable `GridTuning` configuration.
* **Compile-Time Profiling**: Replaced runtime profiling flags with the `kParticlesProfile` environment constant, enabling complete dead-code elimination in release builds.
* **Repaint & Budget Invariants**: Fixed edge cases in connection radius capping under degree limits, improved `shouldRepaint` detection for visual property changes, and eliminated redundant internal recalculations.
* **Engine-Accurate Adaptive Performance**: `enableAdaptivePerformance` now leverages real engine `FrameTiming` callbacks targeted to the active display refresh rate.
* **Physics Execution Timing**: `ParticleNetwork` now computes touch physics during the simulation tick rather than inside `paint()`.
* **Minimum SDK Requirements**: Bumped minimum SDK requirements to Flutter >= 3.27.0 and Dart >= 3.6.0.

### Fixed
* **Boundary Collision**: Accounted for particle radius (`size`) in screen boundary collision checks, ensuring particles bounce on edge contact rather than their center point.

## [1.9.6]

### Added
* **Adaptive Performance Engine**: Introduced `AdaptivePerformanceController` and `enableAdaptivePerformance` to dynamically adjust rendering quality and connection density based on real-time FPS monitoring.
* **Fast Line Rendering**: Added `fastLineRendering` (with `useVerticesRendering` alias) for high-efficiency batch line drawing with minimal GPU draw calls.
* **Connection Density Limiting**: Added `maxConnectionsPerParticle` to bound edge generation to $O(N)$ complexity instead of $O(N^2)$, enabling high particle counts without frame drops.
* **Adaptive Density Scaling**: Added `adaptiveDensity` to automatically scale connection radius in dense particle regions.
* **Advanced Touch Physics**: Added `TouchFeatures` configuration support (`speed`/`decayRate`, `force`/`pullForce`, `damping`, `maxTouchSpeed`, `lineDistance`) for fine-grained gesture control.
* **Trajectory Direction Preservation**: Improved physics engine to maintain true velocity angle vectors during particle deceleration and inertia settling.
* **Expanded Test Suite**: Added extensive unit tests for `CompressedQuadTree` subdivision, uninsertable boundary particles, TouchFeatures physics, and painter repaint optimizations.

## [1.9.5]

* Added optional mouse hover support on Desktop and Web (`hoverEffect`).
* Implemented interactive particle network system with spatial partitioning (Compressed QuadTree).
* Added zero-allocation Color LUT (`_lineColorLut`) and Touch Inactivity Bypass.
* Added deterministic trajectory precomputation (`TrajectoryBuffer`).
* Added global and point gravity simulation.
* Improved rendering performance using GPU Fragment Shaders.
