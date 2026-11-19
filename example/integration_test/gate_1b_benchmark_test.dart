// Real-device Gate 1b benchmark for SortedSpatialGrid on physical Galaxy S10.
//
// Run in profile mode on a physical device:
//
//   flutter drive --profile \
//     --driver=test_driver/perf_driver.dart \
//     --target=integration_test/gate_1b_benchmark_test.dart
//
// ignore_for_file: avoid_print, deprecated_member_use
import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import 'package:particles_network/particles_network.dart';

import 'perf_harness.dart';

class ClusteredParticleFactory implements IParticleFactory {
  final math.Random random;
  final double maxSpeed;
  final double maxSize;
  final Color color;

  ClusteredParticleFactory({
    required this.random,
    this.maxSpeed = 0.5,
    this.maxSize = 1.5,
    this.color = Colors.white,
  });

  @override
  Particle createParticle(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final bool inCluster = random.nextDouble() < 0.85;
    double x, y;
    if (inCluster) {
      final angle = random.nextDouble() * 2 * math.pi;
      final r = random.nextDouble() * 60.0;
      x = (center.dx + r * math.cos(angle)).clamp(0.0, size.width);
      y = (center.dy + r * math.sin(angle)).clamp(0.0, size.height);
    } else {
      x = random.nextDouble() * size.width;
      y = random.nextDouble() * size.height;
    }
    return Particle(
      position: Offset(x, y),
      velocity: Offset(
        (random.nextDouble() - 0.5) * maxSpeed,
        (random.nextDouble() - 0.5) * maxSpeed,
      ),
      size: random.nextDouble() * maxSize + 1,
      color: color,
    );
  }
}

class GaussianParticleFactory implements IParticleFactory {
  final math.Random random;
  final double maxSpeed;
  final double maxSize;
  final Color color;

  GaussianParticleFactory({
    required this.random,
    this.maxSpeed = 0.5,
    this.maxSize = 1.5,
    this.color = Colors.white,
  });

  @override
  Particle createParticle(Size size) {
    final sigmaX = size.width / 10.0;
    final sigmaY = size.height / 10.0;
    final meanX = size.width / 2.0;
    final meanY = size.height / 2.0;

    double u1 = random.nextDouble();
    while (u1 == 0) {
      u1 = random.nextDouble();
    }
    final double u2 = random.nextDouble();
    final double z0 =
        math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2);
    final double z1 =
        math.sqrt(-2.0 * math.log(u1)) * math.sin(2.0 * math.pi * u2);

    final double x = (meanX + z0 * sigmaX).clamp(0.0, size.width);
    final double y = (meanY + z1 * sigmaY).clamp(0.0, size.height);

    return Particle(
      position: Offset(x, y),
      velocity: Offset(
        (random.nextDouble() - 0.5) * maxSpeed,
        (random.nextDouble() - 0.5) * maxSpeed,
      ),
      size: random.nextDouble() * maxSize + 1,
      color: color,
    );
  }
}

Widget _wrapTuned({
  required Widget child,
  double safetyFloor = 20.0,
  double k = 1.0,
  bool fitBoundingBox = false,
  double? minFloor,
}) {
  OptimizedNetworkPainter.configureTuning(
    safetyFloor: safetyFloor,
    k: k,
    boundingBox: fitBoundingBox,
    minFloor: minFloor,
  );
  return child;
}

final List<(String, Widget Function())> gate1bScenarios = [
  // =========================================================================
  // GATE 1B BENCHMARK SUITE (Galaxy S10 Profile Mode)
  // Evaluates Baseline (20px floor, k=1) vs Option A (4px floor, k=4)
  // and Question 2 variations: k in {2, 4, 8}, minCellFloor=4px, bounding box.
  // =========================================================================

  // --- BASELINE (safetyFloor = 20.0, k = 1.0) ---
  (
    'gate1b_baseline_uniform_5k_b4k_stroke',
    () => _wrapTuned(
      safetyFloor: 20.0,
      k: 1.0,
      child: ParticleNetwork(
        particleCount: 5000,
        particleFactory: DefaultParticleFactory(
          random: math.Random(42),
          maxSpeed: 0.5,
          maxSize: 1.5,
          color: Colors.white,
        ),
        performance: const NetworkPerformance(
          lineRenderer: LineRenderer.stroke,
          maxLinesPerFrame: 4000,
        ),
        touchFeatures: const TouchFeatures(enabled: false),
      ),
    ),
  ),
  (
    'gate1b_baseline_uniform_5k_b15k_vtx',
    () => _wrapTuned(
      safetyFloor: 20.0,
      k: 1.0,
      child: ParticleNetwork(
        particleCount: 5000,
        particleFactory: DefaultParticleFactory(
          random: math.Random(42),
          maxSpeed: 0.5,
          maxSize: 1.5,
          color: Colors.white,
        ),
        performance: const NetworkPerformance(
          lineRenderer: LineRenderer.vertices,
          maxLinesPerFrame: 15000,
        ),
        touchFeatures: const TouchFeatures(enabled: false),
      ),
    ),
  ),
  (
    'gate1b_baseline_cluster_5k_b4k_stroke',
    () => _wrapTuned(
      safetyFloor: 20.0,
      k: 1.0,
      child: ParticleNetwork(
        particleCount: 5000,
        particleFactory: ClusteredParticleFactory(random: math.Random(42)),
        gravity: const ParticleGravity(
          type: GravityType.point,
          strength: 5.0,
        ),
        performance: const NetworkPerformance(
          lineRenderer: LineRenderer.stroke,
          maxLinesPerFrame: 4000,
        ),
        touchFeatures: const TouchFeatures(enabled: false),
      ),
    ),
  ),
  (
    'gate1b_baseline_cluster_5k_b15k_vtx',
    () => _wrapTuned(
      safetyFloor: 20.0,
      k: 1.0,
      child: ParticleNetwork(
        particleCount: 5000,
        particleFactory: ClusteredParticleFactory(random: math.Random(42)),
        gravity: const ParticleGravity(
          type: GravityType.point,
          strength: 5.0,
        ),
        performance: const NetworkPerformance(
          lineRenderer: LineRenderer.vertices,
          maxLinesPerFrame: 15000,
        ),
        touchFeatures: const TouchFeatures(enabled: false),
      ),
    ),
  ),

  // --- OPTION A (safetyFloor = 4.0, k = 4.0) ---
  (
    'gate1b_optA_k4_uniform_5k_b4k_stroke',
    () => _wrapTuned(
      safetyFloor: 4.0,
      k: 4.0,
      child: ParticleNetwork(
        particleCount: 5000,
        particleFactory: DefaultParticleFactory(
          random: math.Random(42),
          maxSpeed: 0.5,
          maxSize: 1.5,
          color: Colors.white,
        ),
        performance: const NetworkPerformance(
          lineRenderer: LineRenderer.stroke,
          maxLinesPerFrame: 4000,
        ),
        touchFeatures: const TouchFeatures(enabled: false),
      ),
    ),
  ),
  (
    'gate1b_optA_k4_uniform_5k_b15k_vtx',
    () => _wrapTuned(
      safetyFloor: 4.0,
      k: 4.0,
      child: ParticleNetwork(
        particleCount: 5000,
        particleFactory: DefaultParticleFactory(
          random: math.Random(42),
          maxSpeed: 0.5,
          maxSize: 1.5,
          color: Colors.white,
        ),
        performance: const NetworkPerformance(
          lineRenderer: LineRenderer.vertices,
          maxLinesPerFrame: 15000,
        ),
        touchFeatures: const TouchFeatures(enabled: false),
      ),
    ),
  ),
  (
    'gate1b_optA_k4_cluster_5k_b4k_stroke',
    () => _wrapTuned(
      safetyFloor: 4.0,
      k: 4.0,
      child: ParticleNetwork(
        particleCount: 5000,
        particleFactory: ClusteredParticleFactory(random: math.Random(42)),
        gravity: const ParticleGravity(
          type: GravityType.point,
          strength: 5.0,
        ),
        performance: const NetworkPerformance(
          lineRenderer: LineRenderer.stroke,
          maxLinesPerFrame: 4000,
        ),
        touchFeatures: const TouchFeatures(enabled: false),
      ),
    ),
  ),
  (
    'gate1b_optA_k4_cluster_5k_b15k_vtx',
    () => _wrapTuned(
      safetyFloor: 4.0,
      k: 4.0,
      child: ParticleNetwork(
        particleCount: 5000,
        particleFactory: ClusteredParticleFactory(random: math.Random(42)),
        gravity: const ParticleGravity(
          type: GravityType.point,
          strength: 5.0,
        ),
        performance: const NetworkPerformance(
          lineRenderer: LineRenderer.vertices,
          maxLinesPerFrame: 15000,
        ),
        touchFeatures: const TouchFeatures(enabled: false),
      ),
    ),
  ),

  // --- QUESTION 2 VARIATIONS: k in {2, 8}, floor ~4px, and bounding box ---
  (
    'gate1b_q2_k2_cluster_5k_b4k_stroke',
    () => _wrapTuned(
      safetyFloor: 4.0,
      k: 2.0,
      child: ParticleNetwork(
        particleCount: 5000,
        particleFactory: ClusteredParticleFactory(random: math.Random(42)),
        gravity: const ParticleGravity(
          type: GravityType.point,
          strength: 5.0,
        ),
        performance: const NetworkPerformance(
          lineRenderer: LineRenderer.stroke,
          maxLinesPerFrame: 4000,
        ),
        touchFeatures: const TouchFeatures(enabled: false),
      ),
    ),
  ),
  (
    'gate1b_q2_k2_cluster_5k_b15k_vtx',
    () => _wrapTuned(
      safetyFloor: 4.0,
      k: 2.0,
      child: ParticleNetwork(
        particleCount: 5000,
        particleFactory: ClusteredParticleFactory(random: math.Random(42)),
        gravity: const ParticleGravity(
          type: GravityType.point,
          strength: 5.0,
        ),
        performance: const NetworkPerformance(
          lineRenderer: LineRenderer.vertices,
          maxLinesPerFrame: 15000,
        ),
        touchFeatures: const TouchFeatures(enabled: false),
      ),
    ),
  ),
  (
    'gate1b_q2_k8_cluster_5k_b4k_stroke',
    () => _wrapTuned(
      safetyFloor: 4.0,
      k: 8.0,
      child: ParticleNetwork(
        particleCount: 5000,
        particleFactory: ClusteredParticleFactory(random: math.Random(42)),
        gravity: const ParticleGravity(
          type: GravityType.point,
          strength: 5.0,
        ),
        performance: const NetworkPerformance(
          lineRenderer: LineRenderer.stroke,
          maxLinesPerFrame: 4000,
        ),
        touchFeatures: const TouchFeatures(enabled: false),
      ),
    ),
  ),
  (
    'gate1b_q2_k8_cluster_5k_b15k_vtx',
    () => _wrapTuned(
      safetyFloor: 4.0,
      k: 8.0,
      child: ParticleNetwork(
        particleCount: 5000,
        particleFactory: ClusteredParticleFactory(random: math.Random(42)),
        gravity: const ParticleGravity(
          type: GravityType.point,
          strength: 5.0,
        ),
        performance: const NetworkPerformance(
          lineRenderer: LineRenderer.vertices,
          maxLinesPerFrame: 15000,
        ),
        touchFeatures: const TouchFeatures(enabled: false),
      ),
    ),
  ),
  (
    'gate1b_q2_floor4_cluster_5k_b4k_stroke',
    () => _wrapTuned(
      safetyFloor: 4.0,
      minFloor: 4.0,
      child: ParticleNetwork(
        particleCount: 5000,
        particleFactory: ClusteredParticleFactory(random: math.Random(42)),
        gravity: const ParticleGravity(
          type: GravityType.point,
          strength: 5.0,
        ),
        performance: const NetworkPerformance(
          lineRenderer: LineRenderer.stroke,
          maxLinesPerFrame: 4000,
        ),
        touchFeatures: const TouchFeatures(enabled: false),
      ),
    ),
  ),
  (
    'gate1b_q2_floor4_cluster_5k_b15k_vtx',
    () => _wrapTuned(
      safetyFloor: 4.0,
      minFloor: 4.0,
      child: ParticleNetwork(
        particleCount: 5000,
        particleFactory: ClusteredParticleFactory(random: math.Random(42)),
        gravity: const ParticleGravity(
          type: GravityType.point,
          strength: 5.0,
        ),
        performance: const NetworkPerformance(
          lineRenderer: LineRenderer.vertices,
          maxLinesPerFrame: 15000,
        ),
        touchFeatures: const TouchFeatures(enabled: false),
      ),
    ),
  ),
  (
    'gate1b_q2_bb_cluster_5k_b4k_stroke',
    () => _wrapTuned(
      safetyFloor: 4.0,
      k: 4.0,
      fitBoundingBox: true,
      child: ParticleNetwork(
        particleCount: 5000,
        particleFactory: ClusteredParticleFactory(random: math.Random(42)),
        gravity: const ParticleGravity(
          type: GravityType.point,
          strength: 5.0,
        ),
        performance: const NetworkPerformance(
          lineRenderer: LineRenderer.stroke,
          maxLinesPerFrame: 4000,
        ),
        touchFeatures: const TouchFeatures(enabled: false),
      ),
    ),
  ),
  (
    'gate1b_q2_bb_cluster_5k_b15k_vtx',
    () => _wrapTuned(
      safetyFloor: 4.0,
      k: 4.0,
      fitBoundingBox: true,
      child: ParticleNetwork(
        particleCount: 5000,
        particleFactory: ClusteredParticleFactory(random: math.Random(42)),
        gravity: const ParticleGravity(
          type: GravityType.point,
          strength: 5.0,
        ),
        performance: const NetworkPerformance(
          lineRenderer: LineRenderer.vertices,
          maxLinesPerFrame: 15000,
        ),
        touchFeatures: const TouchFeatures(enabled: false),
      ),
    ),
  ),
  // Scenario 1: Uniform, default settings (lineDistance: 100, maxLines: null)
  (
    'S1_uniform_500_default',
    () => ParticleNetwork(
          particleCount: 500,
          particleFactory: DefaultParticleFactory(
            random: math.Random(42),
            maxSpeed: 0.5,
            maxSize: 1.5,
            color: Colors.white,
          ),
          performance: const NetworkPerformance(lineRenderer: LineRenderer.stroke),
          touchFeatures: const TouchFeatures(enabled: false),
        ),
  ),
  // Note: S1 uniform default (r=100) at 5k and 20k without maxLinesPerFrame generates
  // 177k and 2.85M lines, exceeding mobile GPU display list memory and causing Android OOM.
  // Their CPU paint times are measured in test/clustering_gate_benchmark_test.dart.

  // Scenario 2: Uniform with maxLines 4000 (strokes) and 15000 (vertices)
  (
    'S2_uniform_500_b4k_stroke',
    () => ParticleNetwork(
          particleCount: 500,
          particleFactory: DefaultParticleFactory(
            random: math.Random(42),
            maxSpeed: 0.5,
            maxSize: 1.5,
            color: Colors.white,
          ),
          performance: const NetworkPerformance(
            lineRenderer: LineRenderer.stroke,
            maxLinesPerFrame: 4000,
          ),
          touchFeatures: const TouchFeatures(enabled: false),
        ),
  ),
  (
    'S2_uniform_500_b15k_vtx',
    () => ParticleNetwork(
          particleCount: 500,
          particleFactory: DefaultParticleFactory(
            random: math.Random(42),
            maxSpeed: 0.5,
            maxSize: 1.5,
            color: Colors.white,
          ),
          performance: const NetworkPerformance(
            lineRenderer: LineRenderer.vertices,
            maxLinesPerFrame: 15000,
          ),
          touchFeatures: const TouchFeatures(enabled: false),
        ),
  ),
  (
    'S2_uniform_5k_b4k_stroke',
    () => ParticleNetwork(
          particleCount: 5000,
          particleFactory: DefaultParticleFactory(
            random: math.Random(42),
            maxSpeed: 0.5,
            maxSize: 1.5,
            color: Colors.white,
          ),
          performance: const NetworkPerformance(
            lineRenderer: LineRenderer.stroke,
            maxLinesPerFrame: 4000,
          ),
          touchFeatures: const TouchFeatures(enabled: false),
        ),
  ),
  (
    'S2_uniform_5k_b15k_vtx',
    () => ParticleNetwork(
          particleCount: 5000,
          particleFactory: DefaultParticleFactory(
            random: math.Random(42),
            maxSpeed: 0.5,
            maxSize: 1.5,
            color: Colors.white,
          ),
          performance: const NetworkPerformance(
            lineRenderer: LineRenderer.vertices,
            maxLinesPerFrame: 15000,
          ),
          touchFeatures: const TouchFeatures(enabled: false),
        ),
  ),
  (
    'S2_uniform_20k_b4k_stroke',
    () => ParticleNetwork(
          particleCount: 20000,
          particleFactory: DefaultParticleFactory(
            random: math.Random(42),
            maxSpeed: 0.5,
            maxSize: 1.5,
            color: Colors.white,
          ),
          performance: const NetworkPerformance(
            lineRenderer: LineRenderer.stroke,
            maxLinesPerFrame: 4000,
          ),
          touchFeatures: const TouchFeatures(enabled: false),
        ),
  ),
  (
    'S2_uniform_20k_b15k_vtx',
    () => ParticleNetwork(
          particleCount: 20000,
          particleFactory: DefaultParticleFactory(
            random: math.Random(42),
            maxSpeed: 0.5,
            maxSize: 1.5,
            color: Colors.white,
          ),
          performance: const NetworkPerformance(
            lineRenderer: LineRenderer.vertices,
            maxLinesPerFrame: 15000,
          ),
          touchFeatures: const TouchFeatures(enabled: false),
        ),
  ),

  // Scenario 3: Strong clustering (point gravity 5.0) with maxLines 4000 and 15000
  (
    'S3_cluster_500_b4k_stroke',
    () => ParticleNetwork(
      particleCount: 500,
      particleFactory: ClusteredParticleFactory(random: math.Random(42)),
      gravity: const ParticleGravity(
        type: GravityType.point,
        strength: 5.0,
      ),
      performance: const NetworkPerformance(
        lineRenderer: LineRenderer.stroke,
        maxLinesPerFrame: 4000,
      ),
      touchFeatures: const TouchFeatures(enabled: false),
    ),
  ),
  (
    'S3_cluster_500_b15k_vtx',
    () => ParticleNetwork(
      particleCount: 500,
      particleFactory: ClusteredParticleFactory(random: math.Random(42)),
      gravity: const ParticleGravity(
        type: GravityType.point,
        strength: 5.0,
      ),
      performance: const NetworkPerformance(
        lineRenderer: LineRenderer.vertices,
        maxLinesPerFrame: 15000,
      ),
      touchFeatures: const TouchFeatures(enabled: false),
    ),
  ),
  (
    'S3_cluster_5k_b4k_stroke',
    () => ParticleNetwork(
      particleCount: 5000,
      particleFactory: ClusteredParticleFactory(random: math.Random(42)),
      gravity: const ParticleGravity(
        type: GravityType.point,
        strength: 5.0,
      ),
      performance: const NetworkPerformance(
        lineRenderer: LineRenderer.stroke,
        maxLinesPerFrame: 4000,
      ),
      touchFeatures: const TouchFeatures(enabled: false),
    ),
  ),
  (
    'S3_cluster_5k_b15k_vtx',
    () => ParticleNetwork(
      particleCount: 5000,
      particleFactory: ClusteredParticleFactory(random: math.Random(42)),
      gravity: const ParticleGravity(
        type: GravityType.point,
        strength: 5.0,
      ),
      performance: const NetworkPerformance(
        lineRenderer: LineRenderer.vertices,
        maxLinesPerFrame: 15000,
      ),
      touchFeatures: const TouchFeatures(enabled: false),
    ),
  ),
  (
    'S3_cluster_20k_b4k_stroke',
    () => ParticleNetwork(
      particleCount: 20000,
      particleFactory: ClusteredParticleFactory(random: math.Random(42)),
      gravity: const ParticleGravity(
        type: GravityType.point,
        strength: 5.0,
      ),
      performance: const NetworkPerformance(
        lineRenderer: LineRenderer.stroke,
        maxLinesPerFrame: 4000,
      ),
      touchFeatures: const TouchFeatures(enabled: false),
    ),
  ),
  (
    'S3_cluster_20k_b15k_vtx',
    () => ParticleNetwork(
      particleCount: 20000,
      particleFactory: ClusteredParticleFactory(random: math.Random(42)),
      gravity: const ParticleGravity(
        type: GravityType.point,
        strength: 5.0,
      ),
      performance: const NetworkPerformance(
        lineRenderer: LineRenderer.vertices,
        maxLinesPerFrame: 15000,
      ),
      touchFeatures: const TouchFeatures(enabled: false),
    ),
  ),

  // Scenario 4: Gaussian distribution with maxLines 4000 and 15000
  (
    'S4_gaussian_500_b4k_stroke',
    () => ParticleNetwork(
      particleCount: 500,
      particleFactory: GaussianParticleFactory(random: math.Random(42)),
      performance: const NetworkPerformance(
        lineRenderer: LineRenderer.stroke,
        maxLinesPerFrame: 4000,
      ),
      touchFeatures: const TouchFeatures(enabled: false),
    ),
  ),
  (
    'S4_gaussian_500_b15k_vtx',
    () => ParticleNetwork(
      particleCount: 500,
      particleFactory: GaussianParticleFactory(random: math.Random(42)),
      performance: const NetworkPerformance(
        lineRenderer: LineRenderer.vertices,
        maxLinesPerFrame: 15000,
      ),
      touchFeatures: const TouchFeatures(enabled: false),
    ),
  ),
  (
    'S4_gaussian_5k_b4k_stroke',
    () => ParticleNetwork(
      particleCount: 5000,
      particleFactory: GaussianParticleFactory(random: math.Random(42)),
      performance: const NetworkPerformance(
        lineRenderer: LineRenderer.stroke,
        maxLinesPerFrame: 4000,
      ),
      touchFeatures: const TouchFeatures(enabled: false),
    ),
  ),
  (
    'S4_gaussian_5k_b15k_vtx',
    () => ParticleNetwork(
      particleCount: 5000,
      particleFactory: GaussianParticleFactory(random: math.Random(42)),
      performance: const NetworkPerformance(
        lineRenderer: LineRenderer.vertices,
        maxLinesPerFrame: 15000,
      ),
      touchFeatures: const TouchFeatures(enabled: false),
    ),
  ),
  (
    'S4_gaussian_20k_b4k_stroke',
    () => ParticleNetwork(
      particleCount: 20000,
      particleFactory: GaussianParticleFactory(random: math.Random(42)),
      performance: const NetworkPerformance(
        lineRenderer: LineRenderer.stroke,
        maxLinesPerFrame: 4000,
      ),
      touchFeatures: const TouchFeatures(enabled: false),
    ),
  ),
  (
    'S4_gaussian_20k_b15k_vtx',
    () => ParticleNetwork(
      particleCount: 20000,
      particleFactory: GaussianParticleFactory(random: math.Random(42)),
      performance: const NetworkPerformance(
        lineRenderer: LineRenderer.vertices,
        maxLinesPerFrame: 15000,
      ),
      touchFeatures: const TouchFeatures(enabled: false),
    ),
  ),

  // Scenario 5: Extreme (maxLines: 500)
  (
    'S5_cluster_5k_b500_extreme',
    () => ParticleNetwork(
      particleCount: 5000,
      particleFactory: ClusteredParticleFactory(random: math.Random(42)),
      gravity: const ParticleGravity(
        type: GravityType.point,
        strength: 5.0,
      ),
      performance: const NetworkPerformance(
        lineRenderer: LineRenderer.stroke,
        maxLinesPerFrame: 500,
      ),
      touchFeatures: const TouchFeatures(enabled: false),
    ),
  ),
  (
    'S5_cluster_20k_b500_extreme',
    () => ParticleNetwork(
      particleCount: 20000,
      particleFactory: ClusteredParticleFactory(random: math.Random(42)),
      gravity: const ParticleGravity(
        type: GravityType.point,
        strength: 5.0,
      ),
      performance: const NetworkPerformance(
        lineRenderer: LineRenderer.stroke,
        maxLinesPerFrame: 500,
      ),
      touchFeatures: const TouchFeatures(enabled: false),
    ),
  ),
  (
    'S5_cluster_20k_b4000_extreme',
    () => ParticleNetwork(
      particleCount: 20000,
      particleFactory: ClusteredParticleFactory(random: math.Random(42)),
      gravity: const ParticleGravity(
        type: GravityType.point,
        strength: 5.0,
      ),
      performance: const NetworkPerformance(
        lineRenderer: LineRenderer.stroke,
        maxLinesPerFrame: 4000,
      ),
      touchFeatures: const TouchFeatures(enabled: false),
    ),
  ),
  (
    'S5_gaussian_5k_b500_extreme',
    () => ParticleNetwork(
      particleCount: 5000,
      particleFactory: GaussianParticleFactory(random: math.Random(42)),
      performance: const NetworkPerformance(
        lineRenderer: LineRenderer.stroke,
        maxLinesPerFrame: 500,
      ),
      touchFeatures: const TouchFeatures(enabled: false),
    ),
  ),
  (
    'S5_gaussian_20k_b500_extreme',
    () => ParticleNetwork(
      particleCount: 20000,
      particleFactory: GaussianParticleFactory(random: math.Random(42)),
      performance: const NetworkPerformance(
        lineRenderer: LineRenderer.stroke,
        maxLinesPerFrame: 500,
      ),
      touchFeatures: const TouchFeatures(enabled: false),
    ),
  ),
];

void main() {
  runPerfScenarios(gate1bScenarios);
}
