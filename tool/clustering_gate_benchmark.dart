// ignore_for_file: avoid_print
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:particles_network/particles_network.dart';

class ScenarioBenchmarkResult {
  final String scenarioName;
  final int particleCount;
  final int measuredFrames;
  final double candidateChecksPerFrame;
  final double acceptedPairsPerFrame;
  final double ratio;
  final double cpuPaintTimeMs;

  const ScenarioBenchmarkResult({
    required this.scenarioName,
    required this.particleCount,
    required this.measuredFrames,
    required this.candidateChecksPerFrame,
    required this.acceptedPairsPerFrame,
    required this.ratio,
    required this.cpuPaintTimeMs,
  });
}

List<Particle> _generateUniformParticles(
    int count, Size size, math.Random rng) {
  return List<Particle>.generate(count, (i) {
    return Particle(
      position:
          Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
      velocity: Offset(
          (rng.nextDouble() * 2 - 1) * 1.0, (rng.nextDouble() * 2 - 1) * 1.0),
      color: Colors.white,
      size: 2.0,
    );
  });
}

List<Particle> _generateClusteredParticles(
    int count, Size size, math.Random rng) {
  final center = Offset(size.width / 2, size.height / 2);
  return List<Particle>.generate(count, (i) {
    double x, y;
    if (i < (count * 0.85).floor()) {
      final angle = rng.nextDouble() * 2 * math.pi;
      final r = rng.nextDouble() * 60.0;
      x = (center.dx + r * math.cos(angle)).clamp(0.0, size.width);
      y = (center.dy + r * math.sin(angle)).clamp(0.0, size.height);
    } else {
      x = rng.nextDouble() * size.width;
      y = rng.nextDouble() * size.height;
    }
    return Particle(
      position: Offset(x, y),
      velocity: Offset(
          (rng.nextDouble() * 2 - 1) * 0.5, (rng.nextDouble() * 2 - 1) * 0.5),
      color: Colors.white,
      size: 2.0,
    );
  });
}

List<Particle> _generateGaussianParticles(
    int count, Size size, math.Random rng) {
  final sigmaX = size.width / 10.0;
  final sigmaY = size.height / 10.0;
  final meanX = size.width / 2.0;
  final meanY = size.height / 2.0;

  return List<Particle>.generate(count, (i) {
    double u1 = rng.nextDouble();
    while (u1 == 0) {
      u1 = rng.nextDouble();
    }
    final double u2 = rng.nextDouble();
    final double z0 =
        math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2);
    final double z1 =
        math.sqrt(-2.0 * math.log(u1)) * math.sin(2.0 * math.pi * u2);

    final double x = (meanX + z0 * sigmaX).clamp(0.0, size.width);
    final double y = (meanY + z1 * sigmaY).clamp(0.0, size.height);

    return Particle(
      position: Offset(x, y),
      velocity: Offset(
          (rng.nextDouble() * 2 - 1) * 0.5, (rng.nextDouble() * 2 - 1) * 0.5),
      color: Colors.white,
      size: 2.0,
    );
  });
}

ScenarioBenchmarkResult runScenarioBenchmark({
  required String scenarioName,
  required int scenarioId,
  required int particleCount,
  required int warmupFrames,
  required int measuredFrames,
  required Size size,
}) {
  final rng = math.Random(1337 + scenarioId * 100 + particleCount);
  final List<Particle> particles;
  GravityFeatures gravity = const GravityFeatures();
  final int? maxLines;

  switch (scenarioId) {
    case 1:
      particles = _generateUniformParticles(particleCount, size, rng);
      maxLines = null;
      break;
    case 2:
      particles = _generateClusteredParticles(particleCount, size, rng);
      gravity = GravityFeatures(
        type: GravityType.point,
        strength: 5.0,
        center: Offset(size.width / 2, size.height / 2),
      );
      maxLines = 500;
      break;
    case 3:
      particles = _generateGaussianParticles(particleCount, size, rng);
      maxLines = 500;
      break;
    default:
      throw ArgumentError('Invalid scenarioId: $scenarioId');
  }

  final painter = OptimizedNetworkPainter(
    particleCount: particles.length,
    particles: particles,
    touchPoint: null,
    lineDistance: 100.0,
    lineWidth: 1.0,
    lineColor: Colors.white,
    particleColor: Colors.white,
    fill: true,
    drawNetwork: true,
    isComplex: false,
    maxLinesPerFrame: maxLines,
  );

  final updater = ParticleUpdater();

  // Warm-up phase (stabilizes budget correction factor)
  for (int f = 0; f < warmupFrames; f++) {
    updater.updateParticles(particles, size, gravity: gravity);
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    painter.paint(canvas, size);
    final pic = recorder.endRecording();
    pic.dispose();
  }

  // Measured phase
  int totalCandidateChecks = 0;
  int totalAcceptedPairs = 0;
  int totalPaintMicros = 0;

  for (int f = 0; f < measuredFrames; f++) {
    updater.updateParticles(particles, size, gravity: gravity);

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    SortedSpatialGrid.resetCounters();
    final sw = Stopwatch()..start();
    painter.paint(canvas, size);
    sw.stop();

    totalPaintMicros += sw.elapsedMicroseconds;
    totalCandidateChecks += SortedSpatialGrid.candidateChecks;
    totalAcceptedPairs += SortedSpatialGrid.acceptedPairs;

    final pic = recorder.endRecording();
    pic.dispose();
  }

  SortedSpatialGrid.resetCounters();

  final double avgChecks = totalCandidateChecks / measuredFrames;
  final double avgAccepted = totalAcceptedPairs / measuredFrames;
  final double ratio = avgAccepted > 0 ? avgChecks / avgAccepted : 0.0;
  final double avgPaintMs = totalPaintMicros / (measuredFrames * 1000.0);

  return ScenarioBenchmarkResult(
    scenarioName: scenarioName,
    particleCount: particleCount,
    measuredFrames: measuredFrames,
    candidateChecksPerFrame: avgChecks,
    acceptedPairsPerFrame: avgAccepted,
    ratio: ratio,
    cpuPaintTimeMs: avgPaintMs,
  );
}

void main() {
  test('Clustering & Measurement Gate Benchmark (Scenarios 1, 2, 3)', () {
    const size = Size(1920, 1080);
    const warmupFrames = 30;

    final results = <ScenarioBenchmarkResult>[];

    final scenarios = [
      (
        1,
        'Scenario 1: Uniform Distribution (default, lineDist=100, maxLines=null)'
      ),
      (2, 'Scenario 2: Strong Clustering (point gravity, r from maxLines=500)'),
      (
        3,
        'Scenario 3: Normal Distribution (Gaussian sigma=dim/10, maxLines=500)'
      ),
    ];

    final particleCounts = [500, 5000, 20000];

    for (final s in scenarios) {
      for (final n in particleCounts) {
        final int measuredFrames = (n == 20000) ? 50 : (n == 5000 ? 80 : 100);
        print('Running ${s.$2} with N=$n ($measuredFrames measured frames)...');
        final res = runScenarioBenchmark(
          scenarioName: s.$2,
          scenarioId: s.$1,
          particleCount: n,
          warmupFrames: warmupFrames,
          measuredFrames: measuredFrames,
          size: size,
        );
        results.add(res);
        print(
          '  -> CandidateChecks/frame: ${res.candidateChecksPerFrame.toStringAsFixed(1)}, '
          'AcceptedPairs/frame: ${res.acceptedPairsPerFrame.toStringAsFixed(1)}, '
          'Ratio: ${res.ratio.toStringAsFixed(2)}, '
          'PaintTime: ${res.cpuPaintTimeMs.toStringAsFixed(3)} ms/frame',
        );
      }
    }

    print(
        '\n========================================================================================================');
    print(
        '                              MILESTONE 2: DECISION GATE REPORT TABLE                                   ');
    print(
        '========================================================================================================');
    print(
      '| Scenario                                | Particles | Candidate Checks/frame | Accepted Pairs/frame | Ratio (Checks/Accepted) | CPU Paint Time (ms) |',
    );
    print(
      '|-----------------------------------------|-----------|------------------------|----------------------|-------------------------|---------------------|',
    );

    bool maxRatioGte10 = false;
    bool allRatiosLt4 = true;

    for (final r in results) {
      if (r.ratio >= 10.0) maxRatioGte10 = true;
      if (r.ratio >= 4.0) allRatiosLt4 = false;

      final scenarioShort = r.scenarioName.split('(').first.trim();
      final pStr = r.particleCount.toString().padLeft(9);
      final cStr = r.candidateChecksPerFrame.toStringAsFixed(1).padLeft(22);
      final aStr = r.acceptedPairsPerFrame.toStringAsFixed(1).padLeft(20);
      final rStr = ('${r.ratio.toStringAsFixed(2)}x').padLeft(23);
      final tStr = ('${r.cpuPaintTimeMs.toStringAsFixed(3)} ms').padLeft(19);

      print(
          '| ${scenarioShort.padRight(39)} | $pStr | $cStr | $aStr | $rStr | $tStr |');
    }
    print(
        '========================================================================================================\n');

    print('Decision Gate Evaluation:');
    if (allRatiosLt4) {
      print(
          '>>> GATE RESULT: STOP (all scenarios ratio < ~4.0, two-level sub-grid NOT justified)');
    } else if (maxRatioGte10) {
      print(
          '>>> GATE RESULT: GATE CONFIRMED (Scenario 2/3 ratio >= 10.0, two-level sub-grid IS justified)');
    } else {
      print('>>> GATE RESULT: INCONCLUSIVE (ratio between 4.0 and 10.0)');
    }

    expect(results.length, equals(9));
    for (final r in results) {
      expect(r.candidateChecksPerFrame, greaterThan(0));
      expect(r.cpuPaintTimeMs, greaterThan(0));
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
