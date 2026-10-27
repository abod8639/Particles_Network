# CHANGELOG

## [1.9.7]

### Added
* **Cell-sorted SoA neighbour search (`SortedSpatialGrid`)**: The default batched path and the `fastLineRendering` path now counting-sort visible particles by cell into flat `Float64List` coordinate arrays. Each particle's candidates then come from just two contiguous memory ranges, instead of per-cell linked lists over `Particle` objects. The output is identical: tests compare the line count against brute force across densities, radii and out-of-bounds particles. The cell size is `max(r, sqrt(A/N))`, so tiny budgeted radii do not create huge grids. `Particle` and `List<Particle>` APIs are unchanged; physics was only 0.14 ms for 10,000 particles, so it stays array-of-objects. On a Galaxy S10, per-frame paint CPU time (tight loop at full clock, two runs vs. one before) went:
  * 20,000 particles, 15,000-line budget: 9.33 → 5.1–5.4 ms with vertices, 6.36 → 4.3–4.4 ms with strokes
  * 10,000 particles, 15,000-line budget: 4.56 → 3.4–3.7 ms
  * 1,000 particles, 48,000 lines: 7.60 → 5.2–6.1 ms
* **Triangle line renderer (`lineRenderer: LineRenderer.vertices`)**: Opt-in. The network is drawn as thin indexed quads (4 vertices and 6 shared `Uint16` indices per line, no per-vertex colours), with one `drawVertices` call per opacity level, instead of engine-stroked segments. Dropping per-vertex colours and using indices cut the copied data per line from 96 to 44 bytes. GPU raster time fell further: 2,000 particles 33.9 → 4.7–6.1 ms, 1,000 particles 8.0 → 4.1–4.5 ms. The same lines are selected and they fade the same way; only the line ends change, from round caps to square. Widths under one physical pixel are drawn at 1 px with proportionally lower alpha, so they fade instead of dropping out. Galaxy S10 results, each pair run back to back:
  * 500 particles: 15.4 → 63.8 FPS (raster 61 → 4.9 ms)
  * 1,000 particles: 4.2 → 41.8 FPS
  * 5,000 particles with a 15,000-line budget: 9.6 → 64.0 FPS (raster 109 → 8.4 ms)
  * 20,000 particles with a 15,000-line budget: 61.8–64.5 FPS
  * New public `LineVertexBatch` helper.
* **Line budget (`maxLinesPerFrame`)**: Caps the number of connection lines per frame by shrinking the connection radius from the expected pair count (N² · π · r² / 2A), with a feedback correction for clustered particles. Frame cost stays flat as `particleCount` grows: on a Galaxy S10, 5,000 particles with a 2,000-line budget run at 59 FPS, and 5,000 or 10,000 particles cost the same per frame. Lines fade relative to the reduced radius, so they do not pop in and out.
* **Frame-rate independent motion (`frameRateIndependent`)**: Opt-in. Speeds are read as pixels per 1/60 s and integrated over real elapsed time, so particles no longer move twice as fast on 120 Hz displays or slow down when frames drop. Steps are capped at 4 reference frames. Defaults to `false`, so the current pixels-per-frame behaviour does not change.
* `ITimeScaledParticleController`, `Particle.advance(bounds, timeScale)`, `TouchInteractionHandler.applyTouchPhysicsScaled`, and `scaleFrameRate` for time-scaled physics. Custom `IParticleController` implementations keep working unchanged and advance one frame per tick.
* `OptimizedNetworkPainter.lastFrameLineCount` / `lastFrameLineDistance` for diagnostics, and `simulateTouchInPaint` / `stepTouchPhysics()`.
* Benchmark harness: shared measurement code now lives in `perf_harness.dart`. A new `perf_compat_test.dart` uses only 1.9.6-era options, so the same file can benchmark the published release against the current source (see the README).
* Benchmark harness: added a `lines_20000_budget15k` scenario. Frame-level FPS on phones can swing by 30–50% between runs near the 60 FPS cap (thermal and big.LITTLE core scheduling). Re-run outliers before drawing conclusions.
* Benchmark harness: every `lines_*` scenario runs as a back-to-back stroke/`_vtx` pair so both see the same thermal state. Added comma-separated `PERF_FILTER` and `PERF_SCREENSHOTS=true` (saves a screenshot per scenario).
* **Real-device benchmark harness** in `example/`: `integration_test/perf_benchmark_test.dart` records engine `FrameTiming` (build and raster p50/p90/p99, FPS) per scenario. `tool/compare_perf.dart` diffs two runs.

### Changed
* The minimum SDK is now Flutter 3.27 / Dart 3.6. The painter uses `Color.a` and `Color.toARGB32()`, which older SDKs lack. 1.9.6 already relied on `Color.a`, so its `>=3.10.0` constraint was already wrong.
* `enableAdaptivePerformance` now measures real frame cost from engine `FrameTiming` (the slower of build and raster), and targets the display's refresh rate instead of a fixed 16.67 ms. On a Galaxy S10, 500 particles went from 50 FPS (raster p90 22.8 ms) to 63.6 FPS (raster p90 15.7 ms). Widget tests that relied on pumping long tick intervals to trigger adaptivity no longer do; feed `FrameTiming`s through `platformDispatcher.onReportTimings` instead.
* `ParticleNetwork` now applies touch physics in the simulation tick instead of inside `paint()`. A standalone `OptimizedNetworkPainter` still applies it in `paint()` by default.
* The `isComplex` batched path queries neighbours with the effective (reduced) radius instead of `lineDistance`. The output is identical, but it scans fewer cells.

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

