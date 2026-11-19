# Architecture: OptimizedNetworkPainter & Spatial Engine

## 1. Overview
The `particles_network` rendering engine achieves high-throughput particle and network line rendering at 60–120 FPS on resource-constrained mobile hardware (e.g., Galaxy S10) through:
- **Zero steady-state heap allocations** across the hot rendering path (grid construction, neighbor pair scan, alpha bucketing, GPU emission).
- **Structure-of-Arrays (SoA)** flat typed memory layout in `SortedSpatialGrid`, eliminating object pointer chasing and cache misses.
- **Single-pass half-stencil spatial neighbor walk** in `PairScanner`, guaranteeing $O(N)$ pair candidate visitation without duplicate pair checks.
- **Single-responsibility extracted collaborators** orchestrated by a slim `OptimizedNetworkPainter`.

---

## 2. Per-Frame Hot-Path Flow

Each frame rendered by `OptimizedNetworkPainter.paint(Canvas, Size)` follows a deterministic pipeline:

```
[Particles]
     │
     ▼
1. ParticleFilter (Viewport culling)
   └─ Identifies visible particles, writing indices into reusable Int32List buffer.
     │
     ▼
2. LineBudgetController (FrameRadii computation)
   └─ Calculates gridRadius, scanRadius, alphaRadius with dynamic line-budget feedback.
     │
     ▼
3. SortedSpatialGrid.build()
   └─ Counting-sorts visible particles into contiguous SoA typed arrays (xs, ys, indices).
     │
     ▼
4. PairScanner.scan()
   └─ Half-stencil walk (own cell + E, SW, S, SE neighbors).
   └─ Selected path: scanIndividual (N < 30), scanBatchedFast, or scanBatchedComplex.
     │
     ▼
5. LineBuckets (Opacity quantization)
   └─ Quantizes distance-squared into 32 pre-binned Float32List segment buffers.
     │
     ▼
6. Line Rasterization
   ├─ Stroke path: canvas.drawRawPoints(PointMode.lines, ...)
   └─ Vertices path: LineVertexBatch (GPU triangle quads via drawVertices)
     │
     ▼
7. ParticleBatchRenderer.draw()
   └─ Batches filled/outlined particle points into canvas draw calls.
```

---

## 3. Core Architectural Invariants

### Invariant 1: `cellSize >= scanRadius`
The spatial grid cell width and height (`cellSize`) are guaranteed to never fall below the query/scan radius (`scanRadius`).
- **Proof of Correctness**: When `cellSize >= scanRadius`, any particle within distance $r$ of particle $(x, y)$ in cell $(c_x, c_y)$ is guaranteed to reside either in $(c_x, c_y)$ or in one of the 8 immediately adjacent neighbor cells.
- **Half-Stencil Half-Space Property**: Because pair relationships are symmetric ($(A, B) \equiv (B, A)$), scanning cell $(c_x, c_y)$ against itself (for $j > i$), East, South-West, South, and South-East visits every candidate pair exactly once. If `cellSize < scanRadius`, candidate pairs could span across multiple cells, violating the half-stencil guarantee and dropping valid connections.

### Invariant 2: Half-Stencil Half-Space Scan
The neighbor stencil evaluates 4 directional offsets from cell $(c_x, c_y)$:
1. **Intra-cell**: particles $j > i$ in the current cell.
2. **East**: $(c_x + 1, c_y)$.
3. **South-West**: $(c_x - 1, c_y + 1)$.
4. **South**: $(c_x, c_y + 1)$.
5. **South-East**: $(c_x + 1, c_y + 1)$.

This visits each potential pairing between distinct particles in the grid exactly once without needing visited sets or duplicate pair filtering.

### Invariant 3: Zero Steady-State Heap Allocations
Once buffers reach steady-state capacity after the first few frames:
- `LineBuckets`: reusable `Float32List` arrays for 32 alpha buckets.
- `CandidateBuffer`: reusable `Int32List` and `Float64List` arrays with geometric monotonic expansion policy.
- `FrameRadii`: single mutable instance updated in place per frame.
- `LineStylePalette`: precomputed static lookup table and 32 cached `Paint` objects mutated in place on configuration changes.
- `ParticleBatchRenderer`: pre-allocated `Float32List` coordinates buffer for particle batches.
- No closures, callbacks, or heap object allocations occur inside the inner pair loops.

---

## 4. Component Responsibilities

| Component | Responsibility |
|---|---|
| `OptimizedNetworkPainter` | Thin orchestrator; delegates to specialized collaborators; public API boundary. |
| `LineBudgetController` | Computes `FrameRadii` (`gridRadius`, `scanRadius`, `alphaRadius`), adapts feedback to meet `maxLinesPerFrame`. |
| `LineStylePalette` | Owns static 1024-entry distance bucket lookup table and 32 discrete alpha `Paint` objects. |
| `CandidateBuffer` | Monotonically growing typed arrays for top-k selection and particle connection degrees. |
| `ClusterThrottler` | Calculates dense cluster thresholds, filters candidates, and computes cosine rank-order line fading. |
| `PairScanner` | Single source of truth for the half-stencil grid walk; specialized fast, complex, and individual routines. |
| `LineBuckets` | Alpha-binned typed segment buffers; provides `renderStroke` and `renderVertices` sinks. |
| `ParticleBatchRenderer` | Batched circle and point rasterization for particles. |
| `SortedSpatialGrid` | Structure-of-Arrays (SoA) counting-sort spatial indexing engine with immutable `GridTuning`. |
| `ScanStats` | Zero-allocation profiling counters, pruned at compile time in release builds via `kParticlesProfile`. |
| `LegacyPainterAdapter` | Translates and isolates deprecated parameters and legacy compatibility settings. |
