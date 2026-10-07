# CHANGELOG

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

