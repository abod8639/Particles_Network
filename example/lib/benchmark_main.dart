// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'benchmark_engine.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BenchmarkApp());
}

class BenchmarkApp extends StatelessWidget {
  const BenchmarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spatial Partitioning Benchmark',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          secondary: Color(0xFF818CF8),
        ),
      ),
      home: const BenchmarkScreen(),
    );
  }
}

class BenchmarkScreen extends StatefulWidget {
  const BenchmarkScreen({super.key});

  @override
  State<BenchmarkScreen> createState() => _BenchmarkScreenState();
}

class _BenchmarkScreenState extends State<BenchmarkScreen> {
  bool _isRunning = false;
  bool _isCompleted = false;
  String _statusMessage = 'Ready to start Profile Benchmark';
  double _progress = 0.0;

  final List<BenchmarkResult> _results = [];

  @override
  void initState() {
    super.initState();
    // Auto-start after a brief delay so the initial frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startBenchmarkSuite();
    });
  }

  Future<void> _startBenchmarkSuite() async {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
      _isCompleted = false;
      _statusMessage = 'Initializing Benchmark Suite...';
      _results.clear();
    });

    // Short pause for UI to settle
    await Future.delayed(const Duration(milliseconds: 500));

    final engine = SpatialBenchmarkEngine(
      screenSize: const Size(1080, 2280),
      queryRadius: 100.0,
      warmupFrames: 30,
      measuredFrames: 300,
    );

    final scenarios = [
      BenchmarkScenarioType.lowDensity500,
      BenchmarkScenarioType.mediumDensity2000,
      BenchmarkScenarioType.highPressure5000,
      BenchmarkScenarioType.clusteringWorstCase,
    ];

    final algorithms = [SpatialAlgorithmType.sortedSpatialGrid];

    final int totalRuns = scenarios.length * algorithms.length;
    int currentRunIndex = 0;

    print('\n=============================================================');
    print('   SAMSUNG GALAXY S10 PROFILE BENCHMARK: SPATIAL ALGORITHMS   ');
    print('   Device: SM-G973U (Qualcomm Snapdragon 855 / Kryo 485)     ');
    print('   Mode: Profile AOT | Frames: 300 (+30 warmup) per test      ');
    print('=============================================================\n');

    for (final scenario in scenarios) {
      print('\n-------------------------------------------------------------');
      print('>>> SCENARIO: ${scenario.title}');
      print('-------------------------------------------------------------');

      for (final algorithm in algorithms) {
        currentRunIndex++;
        final double baseProgress = (currentRunIndex - 1) / totalRuns;
        final double runWeight = 1.0 / totalRuns;

        setState(() {
          _statusMessage =
              'Running $currentRunIndex / $totalRuns: ${algorithm.displayName}';
        });

        // Small delay to allow UI refresh
        await Future.delayed(const Duration(milliseconds: 50));

        final result = engine.runBenchmark(
          algorithm: algorithm,
          scenario: scenario,
          onProgress: (frame, totalFrames) {
            final double currentRunFrac = frame / totalFrames;
            final double overall = baseProgress + runWeight * currentRunFrac;
            if (frame % 30 == 0 || frame == totalFrames) {
              setState(() {
                _progress = overall;
                _statusMessage =
                    '${algorithm.displayName} (${scenario.particleCount}p): frame $frame/$totalFrames';
              });
            }
          },
        );

        _results.add(result);

        // Print immediate frame result
        print(
          '  [${algorithm.displayName.padRight(19)}] Avg: ${result.avgTotalMs.toStringAsFixed(3).padLeft(7)} ms | P99: ${result.p99TotalMs.toStringAsFixed(3).padLeft(7)} ms | FPS: ${result.effectiveFps.toStringAsFixed(1).padLeft(6)} | Build: ${result.avgBuildMs.toStringAsFixed(3).padLeft(6)} ms (${result.buildPercent.toStringAsFixed(1)}%) | Query: ${result.avgQueryMs.toStringAsFixed(3).padLeft(6)} ms (${result.queryPercent.toStringAsFixed(1)}%) | RSS: ${(result.rssAfterBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
        );
      }
    }

    print('\n=============================================================');
    print('              FINAL BENCHMARK COMPARISON TABLE               ');
    print('=============================================================');
    print(
      '| Scenario                 | Algorithm           | Avg Frame (ms) | P99 (ms) | FPS     | Build (ms) | Query (ms) | RSS (MB) |',
    );
    print(
      '|--------------------------|---------------------|----------------|----------|---------|------------|------------|----------|',
    );
    for (final r in _results) {
      final scenName = r.scenario.name.padRight(24);
      final algName = r.algorithm.displayName.padRight(19);
      final avg = r.avgTotalMs.toStringAsFixed(3).padLeft(14);
      final p99 = r.p99TotalMs.toStringAsFixed(3).padLeft(8);
      final fps = r.effectiveFps.toStringAsFixed(1).padLeft(7);
      final bld = r.avgBuildMs.toStringAsFixed(3).padLeft(10);
      final qry = r.avgQueryMs.toStringAsFixed(3).padLeft(10);
      final rss = (r.rssAfterBytes / (1024 * 1024))
          .toStringAsFixed(1)
          .padLeft(8);
      print(
        '| $scenName | $algName | $avg | $p99 | $fps | $bld | $qry | $rss |',
      );
    }
    print('=============================================================\n');

    // Print JSON payload line by line for machine parsing
    print('### JSON_BENCHMARK_RESULTS_START ###');
    for (final r in _results) {
      print('RESULT_JSON: ${jsonEncode(r.toJson())}');
    }
    print('### JSON_BENCHMARK_RESULTS_END ###\n');

    setState(() {
      _isRunning = false;
      _isCompleted = true;
      _progress = 1.0;
      _statusMessage = 'Benchmark Completed Successfully!';
    });

    await Future.delayed(const Duration(seconds: 4));
    print('### BENCHMARK_EXITING_DEVICE_RUN ###');
    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Samsung S10 Spatial Benchmark'),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          if (!_isRunning)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _startBenchmarkSuite,
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hardware & Environment info card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target Device: Samsung Galaxy S10 (SM-G973U)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF38BDF8),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'CPU: Qualcomm Snapdragon 855 (1x2.84GHz + 3x2.42GHz + 4x1.78GHz Kryo 485)',
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                    Text(
                      'Mode: Flutter Profile (AOT Compiled) • 300 Frames/Scenario (+30 Warmup)',
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Progress Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isCompleted
                        ? const Color(0xFF10B981)
                        : const Color(0xFF38BDF8).withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _statusMessage,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _isCompleted
                                  ? const Color(0xFF10B981)
                                  : Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${(_progress * 100).toInt()}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF38BDF8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: const Color(0xFF334155),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _isCompleted
                            ? const Color(0xFF10B981)
                            : const Color(0xFF38BDF8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Results List
              Expanded(
                child: _results.isEmpty
                    ? const Center(
                        child: Text(
                          'Executing benchmark suite on device...',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final r = _results[index];
                          final isGrid =
                              r.algorithm ==
                              SpatialAlgorithmType.sortedSpatialGrid;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isGrid
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF475569),
                                width: isGrid ? 1.5 : 1.0,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        r.algorithm.displayName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: isGrid
                                              ? const Color(0xFF34D399)
                                              : const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      Text(
                                        '${r.effectiveFps.toStringAsFixed(1)} FPS',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: r.effectiveFps >= 60
                                              ? const Color(0xFF34D399)
                                              : const Color(0xFFF87171),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    r.scenario.title,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                  const Divider(
                                    height: 16,
                                    color: Color(0xFF334155),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _MetricItem(
                                        'Avg Frame',
                                        '${r.avgTotalMs.toStringAsFixed(2)} ms',
                                      ),
                                      _MetricItem(
                                        'P99 Frame',
                                        '${r.p99TotalMs.toStringAsFixed(2)} ms',
                                      ),
                                      _MetricItem(
                                        'Build Phase',
                                        '${r.avgBuildMs.toStringAsFixed(2)} ms (${r.buildPercent.toStringAsFixed(0)}%)',
                                      ),
                                      _MetricItem(
                                        'Query Phase',
                                        '${r.avgQueryMs.toStringAsFixed(2)} ms (${r.queryPercent.toStringAsFixed(0)}%)',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;

  const _MetricItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
