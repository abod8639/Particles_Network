// Real-device frame benchmark for ParticleNetwork.
//
// Measures what the user actually sees: per-frame build (UI thread) and
// raster (GPU thread) durations reported by the engine via FrameTiming.
//
// Run in profile mode on a physical device:
//
//   flutter drive --profile \
//     --driver=test_driver/perf_driver.dart \
//     --target=integration_test/perf_benchmark_test.dart
//
// Optional:
//   --dart-define=PERF_FILTER=lines_500,budget  run only scenarios whose name
//                                              contains any listed text
//   --dart-define=PERF_SECONDS=8                measurement window
//   --dart-define=PERF_SCREENSHOTS=true         also save a screenshot per
//                                              scenario to build/perf/shots
//                                              (skews timings; run separately)
//
// Every `lines_*` scenario also runs as `<name>_vtx` with
// LineRenderer.vertices for a direct stroke-vs-vertices comparison.
import 'package:particles_network/particles_network.dart';

import 'perf_harness.dart';

class PerfScenario {
  final String name;
  final ParticleNetwork Function(LineRenderer renderer) build;

  const PerfScenario(this.name, this.build);
}

/// [_baseScenarios] with stroke lines, each line scenario immediately
/// followed by a `_vtx` twin using [LineRenderer.vertices]. Running the pair
/// back to back keeps both under the same thermal state, which on phones can
/// shift results by 30% or more over a long run.
final List<(String, ParticleNetwork Function())> scenarios = [
  for (final s in _baseScenarios) ...[
    (s.name, () => s.build(LineRenderer.stroke)),
    if (s.name.startsWith('lines_'))
      ('${s.name}_vtx', () => s.build(LineRenderer.vertices)),
  ],
];

final List<PerfScenario> _baseScenarios = [
  PerfScenario(
    'lines_500',
    (r) => ParticleNetwork(
        lineRenderer: r,
        particleCount: 500,
        touchFeatures: const TouchFeatures(enabled: false)),
  ),
  PerfScenario(
    'lines_1000',
    (r) => ParticleNetwork(
        lineRenderer: r,
        particleCount: 1000,
        touchFeatures: const TouchFeatures(enabled: false)),
  ),
  PerfScenario(
    'lines_2000',
    (r) => ParticleNetwork(
        lineRenderer: r,
        particleCount: 2000,
        touchFeatures: const TouchFeatures(enabled: false)),
  ),
  PerfScenario(
    'lines_2000_maxconn5',
    (r) => ParticleNetwork(
      lineRenderer: r,
      particleCount: 2000,
      maxConnectionsPerParticle: 5,
      touchFeatures: const TouchFeatures(enabled: false),
    ),
  ),
  PerfScenario(
    'lines_2000_fast',
    (r) => ParticleNetwork(
      lineRenderer: r,
      particleCount: 2000,
      fastLineRendering: true,
      touchFeatures: const TouchFeatures(enabled: false),
    ),
  ),
  PerfScenario(
    'lines_5000_budget2k',
    (r) => ParticleNetwork(
      lineRenderer: r,
      particleCount: 5000,
      maxLinesPerFrame: 2000,
      touchFeatures: const TouchFeatures(enabled: false),
    ),
  ),
  PerfScenario(
    'lines_5000_budget4k',
    (r) => ParticleNetwork(
      lineRenderer: r,
      particleCount: 5000,
      maxLinesPerFrame: 4000,
      touchFeatures: const TouchFeatures(enabled: false),
    ),
  ),
  PerfScenario(
    'lines_5000_budget15k',
    (r) => ParticleNetwork(
      lineRenderer: r,
      particleCount: 5000,
      maxLinesPerFrame: 15000,
      touchFeatures: const TouchFeatures(enabled: false),
    ),
  ),
  PerfScenario(
    'lines_10000_budget15k',
    (r) => ParticleNetwork(
      lineRenderer: r,
      particleCount: 1000,
      maxLinesPerFrame: 15000,
      touchFeatures: const TouchFeatures(enabled: false),
    ),
  ),
  PerfScenario(
    'lines_20000_budget15k',
    (r) => ParticleNetwork(
      lineRenderer: r,
      particleCount: 20000,
      maxLinesPerFrame: 15000,
      touchFeatures: const TouchFeatures(enabled: false),
    ),
  ),
  PerfScenario(
    'lines_2000_budget15k_fri',
    (r) => ParticleNetwork(
      lineRenderer: r,
      particleCount: 2000,
      maxLinesPerFrame: 15000,
      frameRateIndependent: true,
      touchFeatures: const TouchFeatures(enabled: false),
    ),
  ),
  PerfScenario(
    'lines_500_adaptive',
    (r) => ParticleNetwork(
      lineRenderer: r,
      particleCount: 500,
      enableAdaptivePerformance: true,
      touchFeatures: const TouchFeatures(enabled: false),
    ),
  ),
  PerfScenario(
    'points_5000',
    (r) => ParticleNetwork(
      lineRenderer: r,
      particleCount: 5000,
      drawNetwork: false,
      touchFeatures: const TouchFeatures(enabled: false),
    ),
  ),
  PerfScenario(
    'points_20000',
    (r) => ParticleNetwork(
      lineRenderer: r,
      particleCount: 20000,
      drawNetwork: false,
      touchFeatures: const TouchFeatures(enabled: false),
    ),
  ),
  PerfScenario(
    'points_50000',
    (r) => ParticleNetwork(
      lineRenderer: r,
      particleCount: 50000,
      drawNetwork: false,
      touchFeatures: const TouchFeatures(enabled: false),
    ),
  ),
];

void main() => runPerfScenarios(scenarios);
