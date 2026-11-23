# Particles Network — Performance Benchmarks & Reproduction Guide

This document contains comprehensive benchmark measurements, real-device frame timings, and step-by-step reproduction instructions for **Particles Network** across version transitions (`1.9.6` vs `1.9.7`).

---

## 1. Test Environment & Hardware Specification

All primary mobile benchmarks were measured under identical physical conditions on physical hardware:

* **Device:** Samsung Galaxy S10 (SM-G973U)
* **SoC:** Qualcomm Snapdragon 855 (1x 2.84 GHz Kryo 485 Gold Prime + 3x 2.42 GHz Kryo 485 Gold + 4x 1.78 GHz Kryo 485 Silver)
* **GPU:** Qualcomm Adreno 640
* **Graphics Backend:** Flutter Impeller (Vulkan)
* **Compilation Mode:** Flutter Profile AOT Mode (`flutter drive --profile`)
* **Display Mode:** Full-Screen viewport (1080x2280 @ 60 Hz)
* **Flutter Version:** Flutter >= 3.27.0 | Dart >= 3.6.0

---

## 2. Real-Device Frame Timings (Galaxy S10)

### 2.1. Version Comparison: 1.9.6 (Old) vs 1.9.7 (New)

| Scenario / Workload | Old Version (1.9.6) | New Version (1.9.7) | Performance Gain / Impact |
| :------------------ | :------------------ | :------------------ | :----------------|
| **500 Particles**<br>*(Default `lineDistance: 100`)* | **15.0 – 15.4 FPS**<br>• Raster p50: 61.0 – 68.1 ms<br>• Jank Ratio: 1.0 (100% dropped frames)<br>• Pipeline: Stroke lines, QuadTree | **63.8 FPS**<br>• Raster p50: **4.88 ms** (p90: 6.0 ms)<br>• Jank Ratio: **0.0 (Zero jank)**<br>• Pipeline: `LineRenderer.vertices` + `SortedSpatialGrid` | **+314% FPS** (4.1x boost)<br>**12.5x faster rasterization**<br>Jank eliminated |
| **1,000 Particles**<br>*(Default connections enabled)* | **4.2 FPS**<br>• Raster p50: 248.1 – 253.1 ms<br>• Jank Ratio: 1.0 (Unusable slideshow)<br>• Pipeline: Unbudgeted strokes | **41.8 FPS**<br>• Raster p50: **12.38 ms** (p90: 15.9 ms)<br>• Jank Ratio: 0.47<br>• Pipeline: Indexed triangle quads | **10x FPS increase**<br>**20x faster rasterization** (248 ms → 12.4 ms) |
| **2,000 Particles**<br>*(Constrained degree: `maxConnections: 5`)* | **23.8 – 26.0 FPS**<br>• Raster p50: 39.6 – 43.3 ms<br>• Jank Ratio: 1.0<br>• Pipeline: Stroked edges | **62.4 FPS**<br>• Raster p50: **5.60 ms** (p90: 6.5 ms)<br>• Jank Ratio: **0.0 (Rock solid)**<br>• Pipeline: Triangle quads | **+140% FPS** (2.4x boost)<br>**7x faster rasterization**<br>Sustains locked 60+ FPS |
| **2,000 Particles**<br>*(Unbudgeted connections)* | **0.6 FPS**<br>• Raster p50: 2,096.7 ms (2.1s per frame!)<br>• Load: ~229,000 lines generated<br>• Fatal GPU lockup / freeze | **62.0 FPS** *(with line budget)*<br>• Raster p50: **8.07 ms** (p90: 9.6 ms)<br>• Jank Ratio: 0.02 | **103x FPS boost**<br>**260x faster rasterization**<br>Prevents device freeze and GPU OOM |
| **5,000 Particles**<br>*(Connection network)* | **Unviable in 1.9.6**<br>• No line budget ($O(N^2)$ edge explosion)<br>• >1.4 million lines, GPU crash | **64.0 FPS** *(with 15k budget + vertices)*<br>• Raster p50: **8.42 ms** (p90: 9.4 ms)<br>• Jank Ratio: **0.0** *(vs 9.6 FPS with strokes)* | **Brand-new capability**<br>**13x faster rasterization**<br>Zero jank at 5k particles |
| **10,000 Particles**<br>*(Connection network)* | **Unviable in 1.9.6**<br>• Device lockup / OOM crash | **60.2 FPS** *(with 15k budget + vertices)*<br>• Raster p50: **7.99 ms**<br>• Pipeline: SoA Grid + Vertices | **Brand-new capability**<br>Sustains 60 FPS on 10,000 nodes |
| **20,000 Particles**<br>*(Connection network)* | **Unviable in 1.9.6**<br>• Device lockup / OOM crash | **61.8 – 64.5 FPS** *(with 15k budget)*<br>• Raster p50: **8.0 ms**<br>• UI build: 5.1–5.4 ms | **Brand-new capability**<br>Sustains 60+ FPS on 20k nodes |
| **500 Particles (Adaptive Mode)**<br>*(`enableAdaptivePerformance`)* | **50.0 – 58.4 FPS**<br>• Raster p90: 18.9 – 22.8 ms<br>• Mechanism: Timer tick heuristic (60Hz fixed) | **63.6 FPS**<br>• Raster p50: **14.0 ms**, p90: **15.7 ms**<br>• Mechanism: Engine `FrameTiming` telemetry | **Accurate hardware feedback**<br>Adapts to native 60/90/120 Hz displays |
| **Spatial Grid Build & Query**<br>*(CPU Time per Frame)* | **High GC Pressure & Pointer Chasing**<br>• Legacy QuadTree node allocations<br>• Cache misses on linked lists | **Sub-0.1 ms build time**<br>• **0 steady-state heap allocations**<br>• 32%–45% lower CPU paint times | **Zero GC pressure**<br>Cache-friendly contiguous memory |
| **Physics on High-Refresh Screens**<br>*(90 Hz / 120 Hz Displays)* | **Frame-rate dependent**<br>• Ran 1.5x–2x too fast on 90/120 Hz<br>• Motion lagged during frame drops | **Frame-rate independent**<br>• Delta-time integration (`frameRateIndependent`)<br>• Consistent speed across 60/90/120 Hz | **Uniform physics trajectory**<br>No velocity warp on high refresh rates |

---

### 2.2. Renderer Comparison: `LineRenderer.stroke` vs `LineRenderer.vertices`

Stroked lines represent the dominant rendering bottleneck: each stroke takes ~7 µs of GPU time on the Snapdragon 855. `LineRenderer.vertices` cuts this cost by ~10x by submitting indexed triangle quads with a single `canvas.drawVertices` call per opacity level:

| Scenario                                           |  `LineRenderer.stroke`  |   `LineRenderer.vertices`    |
| :------------------------------------------------- | :---------------------: | :--------------------------: |
| 500 particles, lines (default `lineDistance: 100`) | 15.4 FPS (raster 61 ms) | **63.8 FPS** (raster 4.9 ms) |
| 1,000 particles, lines                             |         4.2 FPS         |         **41.8 FPS**         |
| 2,000 particles, `maxConnectionsPerParticle: 5`    |        26.0 FPS         |         **62.4 FPS**         |
| 5,000 particles, `maxLinesPerFrame: 4000`          |        33.4 FPS         |         **62.8 FPS**         |
| 5,000 particles, `maxLinesPerFrame: 15000`         | 9.6 FPS (raster 109 ms) | **64.0 FPS** (raster 8.4 ms) |
| 10,000 particles, `maxLinesPerFrame: 15000`        |         9.0 FPS         |         **60.2 FPS**         |
| 20,000 particles, `maxLinesPerFrame: 15000`        |            —            |      **61.8–64.5 FPS**       |

### 2.3. Pure Particle Scaling (Zero Connections)

When line rendering is disabled (`drawNetwork: false`), particle updates and point drawing scale to extreme counts:

| Scenario                                          | FPS  | Raster p50 |
| :------------------------------------------------ | :--: | :--------: |
| 500 particles, lines, `enableAdaptivePerformance` | 63.6 |   14 ms    |
| 20,000 particles, no lines                        | 63.0 |    8 ms    |
| 50,000 particles, no lines                        | 61.0 |   11 ms    |

---

## 3. CPU-Side Microbenchmarks

| Benchmark Scenario                         |      Standard Loop       |      Optimized Engine      |              Gain               |
| :----------------------------------------- | :----------------------: | :------------------------: | :-----------------------------: |
| **500 Particles (100 Frames Render)**      | 4,608 ms (~46 ms/frame)  | **496 ms** (~4.9 ms/frame) |         **9.3x Faster**         |
| **1,000 Particles (1,000 Frames Physics)** |         ~120 ms          |         **45 ms**          |         **2.6x Faster**         |
| **Framerate (500 Particles)**              |         ~21 FPS          |       **> 120 FPS**        |        Rock-solid smooth        |
| **Line Color Heap Allocations**            | Thousands of `Color`/sec |  **0 (`_lineColorLut`)**   | **100% GC pressure eliminated** |
| **Idle Touch Calculation Overhead**        |       Every frame        |  **0 (`isTouchActive`)**   |     **Zero idle CPU waste**     |

---

## 4. Benchmarking & Reproducing the Comparison

The repository includes a dedicated benchmark driver and comparison suite under `example/`.

### 4.1. Running the Integration Benchmark Suite

To measure real frame timings (`FrameTiming.buildDuration`, `FrameTiming.rasterDuration`) on a physical device:

```bash
cd example
flutter drive --profile \
  --driver=test_driver/perf_driver.dart \
  --target=integration_test/perf_benchmark_test.dart
```

### 4.2. Comparing 1.9.6 vs Current Source

`example/integration_test/perf_compat_test.dart` uses only constructor options supported by both 1.9.6 and 1.9.7, enabling direct head-to-head evaluation:

```bash
cd example

# 1. Run benchmark against current source:
PERF_LABEL=current flutter drive --profile \
  --driver=test_driver/perf_driver.dart \
  --target=integration_test/perf_compat_test.dart

# 2. Switch dependency in example/pubspec.yaml to published 1.9.6:
# dependencies:
#   particles_network: 1.9.6
flutter pub get

# 3. Run benchmark against 1.9.6:
PERF_LABEL=v196 flutter drive --profile \
  --driver=test_driver/perf_driver.dart \
  --target=integration_test/perf_compat_test.dart

# 4. Generate diff comparison report:
dart run tool/compare_perf.dart build/perf/v196.json build/perf/current.json
```

### 4.3. Test Methodology Guidelines

* **Physical Hardware:** Always run benchmarks on physical Android or iOS hardware. Emulators translate mobile GPU commands to host drivers, which introduces artificial variance.
* **Thermal Management:** Near the 60/120 FPS ceiling, modern big.LITTLE mobile processors alternate between performance and efficiency cores based on thermal envelopes. Run tests back-to-back with short cooldown intervals to ensure comparable thermal states.
* **AOT Profile Mode:** Never benchmark in Debug mode (`--debug`). JIT compilation, assertion checks, and observatory VM services introduce false latency that does not reflect production release performance.
