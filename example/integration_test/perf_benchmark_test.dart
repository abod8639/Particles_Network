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
// Optional: --dart-define=PERF_FILTER=lines   (run only scenarios whose
// name contains the given text) and --dart-define=PERF_SECONDS=8.
// ignore_for_file: avoid_print
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:particles_network/particles_network.dart';

const String _filter = String.fromEnvironment('PERF_FILTER');
const int _seconds = int.fromEnvironment('PERF_SECONDS', defaultValue: 5);
const Duration _warmup = Duration(seconds: 1);

class PerfScenario {
  final String name;
  final ParticleNetwork Function() build;

  const PerfScenario(this.name, this.build);
}

final List<PerfScenario> scenarios = [
  PerfScenario(
    'lines_500',
    () => const ParticleNetwork(particleCount: 500, touchActivation: false),
  ),
  PerfScenario(
    'lines_1000',
    () => const ParticleNetwork(particleCount: 1000, touchActivation: false),
  ),
  PerfScenario(
    'lines_2000',
    () => const ParticleNetwork(particleCount: 2000, touchActivation: false),
  ),
  PerfScenario(
    'lines_2000_maxconn5',
    () => const ParticleNetwork(
      particleCount: 2000,
      maxConnectionsPerParticle: 5,
      touchActivation: false,
    ),
  ),
  PerfScenario(
    'lines_2000_fast',
    () => const ParticleNetwork(
      particleCount: 2000,
      fastLineRendering: true,
      touchActivation: false,
    ),
  ),
  PerfScenario(
    'points_5000',
    () => const ParticleNetwork(
      particleCount: 5000,
      drawNetwork: false,
      touchActivation: false,
    ),
  ),
  PerfScenario(
    'points_20000',
    () => const ParticleNetwork(
      particleCount: 20000,
      drawNetwork: false,
      touchActivation: false,
    ),
  ),
  PerfScenario(
    'points_50000',
    () => const ParticleNetwork(
      particleCount: 50000,
      drawNetwork: false,
      touchActivation: false,
    ),
  ),
];

/// Summary statistics of one scenario run, in milliseconds.
class PerfResult {
  final String name;
  final int frames;
  final double refreshRate;
  final List<double> buildMs;
  final List<double> rasterMs;
  final List<double> totalMs;

  PerfResult(
    this.name,
    this.refreshRate,
    this.buildMs,
    this.rasterMs,
    this.totalMs,
  ) : frames = totalMs.length;

  double get budgetMs => 1000.0 / refreshRate;

  /// Effective frames per second over the measured window.
  double fps(Duration window) => frames / (window.inMicroseconds / 1e6);

  /// Fraction of frames whose build or raster exceeded the vsync budget.
  double get jankRatio {
    if (frames == 0) return 0;
    int janky = 0;
    for (int i = 0; i < frames; i++) {
      if (buildMs[i] > budgetMs || rasterMs[i] > budgetMs) janky++;
    }
    return janky / frames;
  }

  Map<String, Object> toJson(Duration window) => {
        'frames': frames,
        'refresh_rate': refreshRate,
        'fps': _round(fps(window)),
        'jank_ratio': _round(jankRatio),
        'build_p50_ms': _round(_percentile(buildMs, 50)),
        'build_p90_ms': _round(_percentile(buildMs, 90)),
        'build_p99_ms': _round(_percentile(buildMs, 99)),
        'raster_p50_ms': _round(_percentile(rasterMs, 50)),
        'raster_p90_ms': _round(_percentile(rasterMs, 90)),
        'raster_p99_ms': _round(_percentile(rasterMs, 99)),
      };
}

double _round(double v) => (v * 100).roundToDouble() / 100;

double _percentile(List<double> values, int p) {
  if (values.isEmpty) return 0;
  final sorted = List<double>.of(values)..sort();
  final int idx = ((p / 100) * (sorted.length - 1)).round();
  return sorted[idx];
}

double _ms(Duration d) => d.inMicroseconds / 1000.0;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  final Map<String, Object> report = {};
  const Duration window = Duration(seconds: _seconds);

  for (final scenario in scenarios) {
    if (_filter.isNotEmpty && !scenario.name.contains(_filter)) continue;

    testWidgets(scenario.name, (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: ColoredBox(color: Colors.black, child: scenario.build()),
        ),
      );
      await Future<void>.delayed(_warmup);

      final List<double> build = [];
      final List<double> raster = [];
      final List<double> total = [];
      void onTimings(List<FrameTiming> timings) {
        for (final t in timings) {
          build.add(_ms(t.buildDuration));
          raster.add(_ms(t.rasterDuration));
          total.add(_ms(t.totalSpan));
        }
      }

      SchedulerBinding.instance.addTimingsCallback(onTimings);
      await Future<void>.delayed(window);
      // Timings are delivered in batches; give the last batch time to land.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      SchedulerBinding.instance.removeTimingsCallback(onTimings);

      final double refreshRate = math.max(
        PlatformDispatcher.instance.views.first.display.refreshRate,
        1.0,
      );
      final result =
          PerfResult(scenario.name, refreshRate, build, raster, total);
      final json = result.toJson(window);
      report[scenario.name] = json;
      binding.reportData = {'scenarios': report};

      print('PERF ${scenario.name.padRight(24)} '
          'fps=${json['fps']} jank=${json['jank_ratio']} '
          'build p50/p90=${json['build_p50_ms']}/${json['build_p90_ms']}ms '
          'raster p50/p90=${json['raster_p50_ms']}/${json['raster_p90_ms']}ms');

      // Tear down so the next scenario starts from a clean slate.
      await tester.pumpWidget(const SizedBox.shrink());
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
  }
}
