import 'dart:typed_data';

/// Compile-time constant flag for zero-overhead AOT profiling removal.
///
/// When building without `--dart-define=PARTICLES_NETWORK_PROFILE=true`,
/// the compiler strips all profiling blocks as dead code in release mode.
const bool kParticlesProfile =
    bool.fromEnvironment('PARTICLES_NETWORK_PROFILE');

/// Profiling statistics container for spatial grid neighbor scans.
class ScanStats {
  int candidateChecks = 0;
  int loopIterations = 0;
  int acceptedPairs = 0;
  int scanLoopMicros = 0;
  int gridBuildMicros = 0;
  int physicsMicros = 0;
  int emissionMicros = 0;
  int frameCount = 0;
  final Float64List frameScanTimes = Float64List(4096);
  int frameScanCount = 0;

  /// Ratio of candidate checks to accepted pairs.
  double get ratio => acceptedPairs > 0 ? candidateChecks / acceptedPairs : 0.0;

  /// Resets all profiling counters to zero.
  void reset() {
    candidateChecks = 0;
    loopIterations = 0;
    acceptedPairs = 0;
    scanLoopMicros = 0;
    gridBuildMicros = 0;
    physicsMicros = 0;
    emissionMicros = 0;
    frameCount = 0;
    frameScanCount = 0;
  }
}
