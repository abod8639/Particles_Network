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
      network: NetworkFeatures(renderer: r),
      particles: const ParticleFeatures(count: 500),
      touch: const TouchFeatures(enabled: false),
    ),
  ),
  PerfScenario(
    'lines_1000',
    (r) => ParticleNetwork(
      network: NetworkFeatures(renderer: r),
      particles: const ParticleFeatures(count: 1000),
      touch: const TouchFeatures(enabled: false),
    ),
  ),
  PerfScenario(
    'lines_2000',
    (r) => ParticleNetwork(
      network: NetworkFeatures(renderer: r),
      particles: const ParticleFeatures(count: 2000),
      touch: const TouchFeatures(enabled: false),
    ),
  ),
  PerfScenario(
    'lines_2000_maxconn5',
    (r) => ParticleNetwork(
      network: NetworkFeatures(renderer: r),
      performance: const PerformanceFeatures(maxConnectionsPerParticle: 5),
      particles: const ParticleFeatures(count: 2000),
      touch: const TouchFeatures(enabled: false),
    ),
  ),
  PerfScenario(
    'lines_2000_fast',
    (r) => ParticleNetwork(
      network: NetworkFeatures(renderer: r),
      particles: const ParticleFeatures(count: 2000),
      touch: const TouchFeatures(enabled: false),
    ),
  ),
  PerfScenario(
    'lines_5000_budget2k',
    (r) => ParticleNetwork(
      network: NetworkFeatures(renderer: r),
      particles: const ParticleFeatures(count: 500),
      performance: const PerformanceFeatures(maxLinesPerFrame: 2000),
      touch: const TouchFeatures(enabled: false),
    ),
  ),
  PerfScenario(
    'lines_5000_budget4k',
    (r) => ParticleNetwork(
      network: NetworkFeatures(renderer: r),
      particles: const ParticleFeatures(count: 5000),
      performance: const PerformanceFeatures(maxLinesPerFrame: 4000),
      touch: const TouchFeatures(enabled: false),
    ),
  ),
  PerfScenario(
    'lines_5000_budget15k',
    (r) => ParticleNetwork(
      network: NetworkFeatures(renderer: r),
      particles: const ParticleFeatures(count: 5000),
      performance: const PerformanceFeatures(maxLinesPerFrame: 15000),
      touch: const TouchFeatures(enabled: false),
    ),
  ),
  PerfScenario(
    'lines_10000_budget15k',
    (r) => ParticleNetwork(
      network: NetworkFeatures(renderer: r),
      particles: const ParticleFeatures(count: 1000),
      performance: const PerformanceFeatures(maxLinesPerFrame: 15000),
      touch: const TouchFeatures(enabled: false),
    ),
  ),
  PerfScenario(
    'lines_20000_budget15k',
    (r) => ParticleNetwork(
      network: NetworkFeatures(renderer: r),
      particles: const ParticleFeatures(count: 20000),
      performance: const PerformanceFeatures(maxLinesPerFrame: 15000),
      touch: const TouchFeatures(enabled: false),
    ),
  ),
  PerfScenario(
    'lines_2000_budget15k_fri',
    (r) => ParticleNetwork(
      network: NetworkFeatures(renderer: r),
      particles: const ParticleFeatures(count: 2000),
      performance: const PerformanceFeatures(
        maxLinesPerFrame: 15000,
        frameRateIndependent: true,
      ),
      touch: const TouchFeatures(enabled: false),
    ),
  ),
  PerfScenario(
    'lines_500_adaptive',
    (r) => ParticleNetwork(
      network: NetworkFeatures(renderer: r),
      particles: const ParticleFeatures(count: 500),
      performance: const PerformanceFeatures(autoBoost: true),
      touch: const TouchFeatures(enabled: false),
    ),
  ),
  PerfScenario(
    'points_5000',
    (r) => ParticleNetwork(
      network: NetworkFeatures(renderer: r, enabled: false),
      particles: const ParticleFeatures(count: 5000),
      touch: const TouchFeatures(enabled: false),
    ),
  ),
  PerfScenario(
    'points_20000',
    (r) => ParticleNetwork(
      network: NetworkFeatures(renderer: r, enabled: false),
      particles: const ParticleFeatures(count: 20000),
      touch: const TouchFeatures(enabled: false),
    ),
  ),
  PerfScenario(
    'points_50000',
    (r) => ParticleNetwork(
      network: NetworkFeatures(renderer: r, enabled: false),
      particles: const ParticleFeatures(count: 50000),
      touch: const TouchFeatures(enabled: false),
    ),
  ),
];

void main() => runPerfScenarios(scenarios);
