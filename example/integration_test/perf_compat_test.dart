// Version-comparison frame benchmark for ParticleNetwork.
//
// Uses only constructor parameters that already existed in
// particles_network 1.9.6, so the exact same file can measure the published
// release and the current source. Point the example's dependency at either
// one, then run in profile mode:
//
//   flutter drive --profile \
//     --driver=test_driver/perf_driver.dart \
//     --target=integration_test/perf_compat_test.dart
//
// Every scenario uses library defaults apart from the options in its name,
// so the comparison reflects what existing users get by upgrading.
import 'package:particles_network/particles_network.dart';

import 'perf_harness.dart';

final scenarios = <(String, ParticleNetwork Function())>[
  (
    'lines_100',
    () => const ParticleNetwork(particleCount: 100, touchActivation: false),
  ),
  (
    'lines_300',
    () => const ParticleNetwork(particleCount: 300, touchActivation: false),
  ),
  (
    'lines_500',
    () => const ParticleNetwork(particleCount: 500, touchActivation: false),
  ),
  (
    'lines_1000',
    () => const ParticleNetwork(particleCount: 1000, touchActivation: false),
  ),
  (
    'lines_300_complex',
    () => const ParticleNetwork(
          particleCount: 300,
          isComplex: true,
          touchActivation: false,
        ),
  ),
  (
    'lines_1000_maxconn5',
    () => const ParticleNetwork(
          particleCount: 1000,
          maxConnectionsPerParticle: 5,
          touchActivation: false,
        ),
  ),
  (
    'lines_1000_fast',
    () => const ParticleNetwork(
          particleCount: 1000,
          fastLineRendering: true,
          touchActivation: false,
        ),
  ),
  (
    'lines_500_adaptive',
    () => const ParticleNetwork(
          particleCount: 500,
          enableAdaptivePerformance: true,
          touchActivation: false,
        ),
  ),
  (
    'points_5000',
    () => const ParticleNetwork(
          particleCount: 5000,
          drawNetwork: false,
          touchActivation: false,
        ),
  ),
  (
    'points_20000',
    () => const ParticleNetwork(
          particleCount: 20000,
          drawNetwork: false,
          touchActivation: false,
        ),
  ),
];

void main() => runPerfScenarios(scenarios);
