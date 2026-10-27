// Shared frame-measurement logic for the perf integration tests.
//
// Kept free of any API newer than particles_network 1.9.6 so the same code
// can measure both the published release and the current source.
// ignore_for_file: avoid_print
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const String _filter = String.fromEnvironment('PERF_FILTER');
const int _seconds = int.fromEnvironment('PERF_SECONDS', defaultValue: 5);
const bool _screenshots = bool.fromEnvironment('PERF_SCREENSHOTS');
const Duration _warmup = Duration(seconds: 1);

bool _selected(String name) =>
    _filter.isEmpty ||
    _filter.split(',').any((String f) => f.isNotEmpty && name.contains(f));

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
  ///
  /// Raster duration can include time spent waiting on the GPU, so a frame
  /// may count here while the app still holds its refresh rate; treat [fps]
  /// as the headline number and this as an early-warning signal.
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

/// Registers one integration test per selected scenario. Each test shows the
/// scenario's widget full screen on black, waits for warm-up, then records
/// engine [FrameTiming]s for the measurement window and adds a summary to
/// `binding.reportData['scenarios']`.
void runPerfScenarios(List<(String, Widget Function())> scenarios) {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  final Map<String, Object> report = {};
  const Duration window = Duration(seconds: _seconds);

  for (final (String name, Widget Function() buildNetwork) in scenarios) {
    if (!_selected(name)) continue;

    testWidgets(name, (tester) async {
      // The binding restores the normal surface after every test.
      if (_screenshots && Platform.isAndroid) {
        await binding.convertFlutterSurfaceToImage();
      }
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: ColoredBox(color: Colors.black, child: buildNetwork()),
        ),
      );
      await Future<void>.delayed(_warmup);
      if (_screenshots) await binding.takeScreenshot(name);

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
      final result = PerfResult(name, refreshRate, build, raster, total);
      final json = result.toJson(window);
      report[name] = json;
      (binding.reportData ??= <String, dynamic>{})['scenarios'] = report;

      print('PERF ${name.padRight(24)} '
          'fps=${json['fps']} jank=${json['jank_ratio']} '
          'build p50/p90=${json['build_p50_ms']}/${json['build_p90_ms']}ms '
          'raster p50/p90=${json['raster_p50_ms']}/${json['raster_p90_ms']}ms');

      // Tear down so the next scenario starts from a clean slate.
      await tester.pumpWidget(const SizedBox.shrink());
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
  }
}
