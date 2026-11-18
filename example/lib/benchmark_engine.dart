// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:material_ui/material_ui.dart';
import 'package:particles_network/particles_network.dart';

/// Scenario definition for spatial benchmarks.
enum BenchmarkScenarioType {
  lowDensity500('Scenario 1: Low Density (500 particles)', 500, false),
  mediumDensity2000(
      'Scenario 2: Medium Density (2,000 particles)', 2000, false),
  highPressure5000('Scenario 3: High Pressure (5,000 particles)', 5000, false),
  clusteringWorstCase(
      'Scenario 4: Clustering Worst-Case (2,000 particles, 80% in corner)',
      2000,
      true);

  final String title;
  final int particleCount;
  final bool isClustered;

  const BenchmarkScenarioType(this.title, this.particleCount, this.isClustered);
}

/// Algorithm type for benchmarking.
enum SpatialAlgorithmType {
  sortedSpatialGrid('SortedSpatialGrid'),
  compressedQuadTree('CompressedQuadTree'),
  standardQuadTree('StandardQuadTree');

  final String displayName;
  const SpatialAlgorithmType(this.displayName);
}

/// Summary statistics for a benchmark run.
class BenchmarkResult {
  final SpatialAlgorithmType algorithm;
  final BenchmarkScenarioType scenario;
  final int measuredFrames;
  final double avgTotalMs;
  final double minTotalMs;
  final double maxTotalMs;
  final double p50TotalMs;
  final double p90TotalMs;
  final double p99TotalMs;
  final double effectiveFps;

  final double avgBuildMs;
  final double avgQueryMs;
  final double avgPhysicsMs;
  final double buildPercent;
  final double queryPercent;

  final int rssBeforeBytes;
  final int rssAfterBytes;
  final int rssDeltaBytes;

  final int totalMatchesSampled;

  BenchmarkResult({
    required this.algorithm,
    required this.scenario,
    required this.measuredFrames,
    required this.avgTotalMs,
    required this.minTotalMs,
    required this.maxTotalMs,
    required this.p50TotalMs,
    required this.p90TotalMs,
    required this.p99TotalMs,
    required this.effectiveFps,
    required this.avgBuildMs,
    required this.avgQueryMs,
    required this.avgPhysicsMs,
    required this.buildPercent,
    required this.queryPercent,
    required this.rssBeforeBytes,
    required this.rssAfterBytes,
    required this.rssDeltaBytes,
    required this.totalMatchesSampled,
  });

  Map<String, dynamic> toJson() => {
        'algorithm': algorithm.displayName,
        'scenario': scenario.title,
        'particleCount': scenario.particleCount,
        'isClustered': scenario.isClustered,
        'measuredFrames': measuredFrames,
        'avgTotalMs': _round(avgTotalMs),
        'minTotalMs': _round(minTotalMs),
        'maxTotalMs': _round(maxTotalMs),
        'p50TotalMs': _round(p50TotalMs),
        'p90TotalMs': _round(p90TotalMs),
        'p99TotalMs': _round(p99TotalMs),
        'effectiveFps': _round(effectiveFps),
        'avgBuildMs': _round(avgBuildMs),
        'avgQueryMs': _round(avgQueryMs),
        'avgPhysicsMs': _round(avgPhysicsMs),
        'buildPercent': _round(buildPercent),
        'queryPercent': _round(queryPercent),
        'rssBeforeMB': _round(rssBeforeBytes / (1024 * 1024)),
        'rssAfterMB': _round(rssAfterBytes / (1024 * 1024)),
        'rssDeltaMB': _round(rssDeltaBytes / (1024 * 1024)),
        'totalMatchesSampled': totalMatchesSampled,
      };

  static double _round(double val) => (val * 1000).roundToDouble() / 1000;
}

/// The core benchmark execution engine.
class SpatialBenchmarkEngine {
  final Size screenSize;
  final double queryRadius;
  final int warmupFrames;
  final int measuredFrames;

  SpatialBenchmarkEngine({
    this.screenSize = const Size(1080, 2280),
    this.queryRadius = 100.0,
    this.warmupFrames = 30,
    this.measuredFrames = 300,
  });

  /// Generates particles according to the scenario.
  List<Particle> generateParticles(BenchmarkScenarioType scenario,
      [int seed = 42]) {
    final rng = math.Random(seed);
    final count = scenario.particleCount;
    final particles = <Particle>[];

    final double width = screenSize.width;
    final double height = screenSize.height;

    for (int i = 0; i < count; i++) {
      double x, y;
      if (scenario.isClustered) {
        // 80% of particles clustered in top-left 20% area
        if (i < (count * 0.8).floor()) {
          x = rng.nextDouble() * (width * 0.2);
          y = rng.nextDouble() * (height * 0.2);
        } else {
          x = rng.nextDouble() * width;
          y = rng.nextDouble() * height;
        }
      } else {
        x = rng.nextDouble() * width;
        y = rng.nextDouble() * height;
      }

      final vx = (rng.nextDouble() * 2.0 - 1.0) * 1.5;
      final vy = (rng.nextDouble() * 2.0 - 1.0) * 1.5;

      particles.add(Particle(
        position: Offset(x, y),
        velocity: Offset(vx, vy),
        color: Colors.white,
        size: 2.0,
      ));
    }
    return particles;
  }

  /// Runs physics simulation step (advancing particles and bouncing against walls).
  void updatePhysics(List<Particle> particles) {
    final double w = screenSize.width;
    final double h = screenSize.height;
    final int n = particles.length;

    for (int i = 0; i < n; i++) {
      final p = particles[i];
      p.x += p.vx;
      p.y += p.vy;

      if (p.x <= 0) {
        p.x = 0;
        p.vx = -p.vx;
      } else if (p.x >= w) {
        p.x = w;
        p.vx = -p.vx;
      }

      if (p.y <= 0) {
        p.y = 0;
        p.vy = -p.vy;
      } else if (p.y >= h) {
        p.y = h;
        p.vy = -p.vy;
      }
    }
  }

  /// Executes a single benchmark scenario for a given algorithm.
  BenchmarkResult runBenchmark({
    required SpatialAlgorithmType algorithm,
    required BenchmarkScenarioType scenario,
    void Function(int frame, int totalFrames)? onProgress,
  }) {
    final particles = generateParticles(scenario);
    final int count = particles.length;
    final visibleIndices = List<int>.generate(count, (i) => i);

    final double width = screenSize.width;
    final double height = screenSize.height;

    // Pre-create spatial structures
    final sortedGrid = SortedSpatialGrid();
    final compressedQuadTree =
        CompressedQuadTree(Rectangle(0, 0, width, height));
    final standardQuadTree = StandardQuadTree(
      width: width,
      height: height,
      nodeCapacity: 8,
      maxDepth: 10,
    );

    final List<int> neighborBuffer = [];

    // Frame timings (in microseconds)
    final buildTimesUs = Float64List(measuredFrames);
    final queryTimesUs = Float64List(measuredFrames);
    final physicsTimesUs = Float64List(measuredFrames);
    final totalTimesUs = Float64List(measuredFrames);

    int totalMatchesSampled = 0;

    final int totalFrames = warmupFrames + measuredFrames;

    // Warm-up phase
    for (int f = 0; f < warmupFrames; f++) {
      updatePhysics(particles);
      _executeFrame(
        algorithm: algorithm,
        particles: particles,
        visibleIndices: visibleIndices,
        sortedGrid: sortedGrid,
        compressedQuadTree: compressedQuadTree,
        standardQuadTree: standardQuadTree,
        neighborBuffer: neighborBuffer,
        width: width,
        height: height,
        sampleMatches: false,
      );
      onProgress?.call(f + 1, totalFrames);
    }

    // Force GC / record RSS
    final int rssBefore = ProcessInfo.currentRss;

    final swFrame = Stopwatch();
    final swPhysics = Stopwatch();
    final swBuild = Stopwatch();
    final swQuery = Stopwatch();

    // Measurement phase
    for (int f = 0; f < measuredFrames; f++) {
      swFrame.reset();
      swPhysics.reset();
      swBuild.reset();
      swQuery.reset();

      swFrame.start();

      // Phase 1: Physics update
      swPhysics.start();
      updatePhysics(particles);
      swPhysics.stop();

      // Phase 2: Build / Partition
      swBuild.start();
      switch (algorithm) {
        case SpatialAlgorithmType.sortedSpatialGrid:
          sortedGrid.build(
              particles, visibleIndices, width, height, queryRadius);
          break;
        case SpatialAlgorithmType.compressedQuadTree:
          compressedQuadTree.clear();
          for (int i = 0; i < count; i++) {
            final p = particles[i];
            compressedQuadTree.insert(QuadTreeParticle(i, p.x, p.y));
          }
          break;
        case SpatialAlgorithmType.standardQuadTree:
          standardQuadTree.build(particles, visibleIndices);
          break;
      }
      swBuild.stop();

      // Phase 3: Query neighbors for all particles
      swQuery.start();
      int matchesInFrame = 0;
      switch (algorithm) {
        case SpatialAlgorithmType.sortedSpatialGrid:
          for (int i = 0; i < count; i++) {
            final p = particles[i];
            sortedGrid.queryRadius(p.x, p.y, queryRadius,
                (otherIdx, px, py, distSq) {
              if (otherIdx != i) matchesInFrame++;
            });
          }
          break;

        case SpatialAlgorithmType.compressedQuadTree:
          for (int i = 0; i < count; i++) {
            final p = particles[i];
            neighborBuffer.clear();
            compressedQuadTree.findNearbyParticlesToOutput(
                p.x, p.y, queryRadius, neighborBuffer);
            for (int k = 0; k < neighborBuffer.length; k++) {
              if (neighborBuffer[k] != i) matchesInFrame++;
            }
          }
          break;

        case SpatialAlgorithmType.standardQuadTree:
          for (int i = 0; i < count; i++) {
            final p = particles[i];
            standardQuadTree.queryRadius(p.x, p.y, queryRadius,
                (otherIdx, px, py, distSq) {
              if (otherIdx != i) matchesInFrame++;
            });
          }
          break;
      }
      swQuery.stop();

      swFrame.stop();

      physicsTimesUs[f] = swPhysics.elapsedMicroseconds.toDouble();
      buildTimesUs[f] = swBuild.elapsedMicroseconds.toDouble();
      queryTimesUs[f] = swQuery.elapsedMicroseconds.toDouble();
      totalTimesUs[f] = swFrame.elapsedMicroseconds.toDouble();

      if (f == 0) {
        totalMatchesSampled = matchesInFrame;
      }

      onProgress?.call(warmupFrames + f + 1, totalFrames);
    }

    final int rssAfter = ProcessInfo.currentRss;

    // Calculate statistical metrics
    final List<double> totalMsList = <double>[
      for (int i = 0; i < measuredFrames; i++) totalTimesUs[i] / 1000.0
    ];
    totalMsList.sort();

    double sumTotal = 0;
    double sumBuild = 0;
    double sumQuery = 0;
    double sumPhysics = 0;

    for (int i = 0; i < measuredFrames; i++) {
      sumTotal += totalTimesUs[i] / 1000.0;
      sumBuild += buildTimesUs[i] / 1000.0;
      sumQuery += queryTimesUs[i] / 1000.0;
      sumPhysics += physicsTimesUs[i] / 1000.0;
    }

    final avgTotalMs = sumTotal / measuredFrames;
    final avgBuildMs = sumBuild / measuredFrames;
    final avgQueryMs = sumQuery / measuredFrames;
    final avgPhysicsMs = sumPhysics / measuredFrames;

    final minTotalMs = totalMsList.first;
    final maxTotalMs = totalMsList.last;
    final p50TotalMs = _percentile(totalMsList, 50);
    final p90TotalMs = _percentile(totalMsList, 90);
    final p99TotalMs = _percentile(totalMsList, 99);
    final effectiveFps = avgTotalMs > 0 ? (1000.0 / avgTotalMs) : 0.0;

    final buildPercent =
        avgTotalMs > 0 ? (avgBuildMs / avgTotalMs * 100.0) : 0.0;
    final queryPercent =
        avgTotalMs > 0 ? (avgQueryMs / avgTotalMs * 100.0) : 0.0;

    return BenchmarkResult(
      algorithm: algorithm,
      scenario: scenario,
      measuredFrames: measuredFrames,
      avgTotalMs: avgTotalMs,
      minTotalMs: minTotalMs,
      maxTotalMs: maxTotalMs,
      p50TotalMs: p50TotalMs,
      p90TotalMs: p90TotalMs,
      p99TotalMs: p99TotalMs,
      effectiveFps: effectiveFps,
      avgBuildMs: avgBuildMs,
      avgQueryMs: avgQueryMs,
      avgPhysicsMs: avgPhysicsMs,
      buildPercent: buildPercent,
      queryPercent: queryPercent,
      rssBeforeBytes: rssBefore,
      rssAfterBytes: rssAfter,
      rssDeltaBytes: rssAfter - rssBefore,
      totalMatchesSampled: totalMatchesSampled,
    );
  }

  void _executeFrame({
    required SpatialAlgorithmType algorithm,
    required List<Particle> particles,
    required List<int> visibleIndices,
    required SortedSpatialGrid sortedGrid,
    required CompressedQuadTree compressedQuadTree,
    required StandardQuadTree standardQuadTree,
    required List<int> neighborBuffer,
    required double width,
    required double height,
    required bool sampleMatches,
  }) {
    final count = particles.length;
    switch (algorithm) {
      case SpatialAlgorithmType.sortedSpatialGrid:
        sortedGrid.build(particles, visibleIndices, width, height, queryRadius);
        for (int i = 0; i < count; i++) {
          final p = particles[i];
          sortedGrid.queryRadius(p.x, p.y, queryRadius, (_, __, ___, ____) {});
        }
        break;
      case SpatialAlgorithmType.compressedQuadTree:
        compressedQuadTree.clear();
        for (int i = 0; i < count; i++) {
          final p = particles[i];
          compressedQuadTree.insert(QuadTreeParticle(i, p.x, p.y));
        }
        for (int i = 0; i < count; i++) {
          final p = particles[i];
          neighborBuffer.clear();
          compressedQuadTree.findNearbyParticlesToOutput(
              p.x, p.y, queryRadius, neighborBuffer);
        }
        break;
      case SpatialAlgorithmType.standardQuadTree:
        standardQuadTree.build(particles, visibleIndices);
        for (int i = 0; i < count; i++) {
          final p = particles[i];
          standardQuadTree.queryRadius(
              p.x, p.y, queryRadius, (_, __, ___, ____) {});
        }
        break;
    }
  }

  static double _percentile(List<double> sorted, int p) {
    if (sorted.isEmpty) return 0;
    final int idx = ((p / 100.0) * (sorted.length - 1)).round();
    return sorted[idx];
  }
}
