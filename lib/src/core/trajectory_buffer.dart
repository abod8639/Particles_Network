import 'dart:typed_data';
import 'dart:ui';

import 'package:particles_network/src/core/particle.dart';
import 'package:particles_network/src/physics/gravity_config.dart';
import 'package:particles_network/src/physics/particle_controller.dart';

/// Precalculates and buffers particle trajectory positions and velocities
/// when no external interactions (e.g. touch) are applied.
///
/// This avoids per-frame physics computation, boundary checks, and vector math,
/// reducing CPU cycles to simple array index lookups during idle animation.
class TrajectoryBuffer {
  /// Number of frames precomputed in each batch.
  final int capacity;

  int _particleCount = 0;
  int _currentFrame = 0;
  bool _isValid = false;

  // Packed array: [frame * particleCount * 4 + particleIndex * 4 + offset]
  // 0: posX, 1: posY, 2: velX, 3: velY
  Float64List _buffer = Float64List(0);

  // Reusable simulation state: [particleIndex * 6 + offset]
  // 0: x, 1: y, 2: vx, 3: vy, 4: defaultVx, 5: defaultVy
  // Avoids allocating Particle objects during precompute.
  Float64List _simState = Float64List(0);
  // Separate booleans for wasAccelerated flags (one per sim particle)
  List<bool> _simAccelerated = [];

  TrajectoryBuffer({this.capacity = 120});

  /// Whether the buffer currently contains valid precalculated frames.
  bool get isValid => _isValid && _particleCount > 0;

  /// Current frame index within the buffered batch.
  int get currentFrame => _currentFrame;

  /// Remaining frames in the current buffer.
  int get remainingFrames => _isValid ? capacity - _currentFrame : 0;

  /// Invalidates the buffer (e.g., when touch begins, size changes, or parameters change).
  void invalidate() {
    _isValid = false;
    _currentFrame = 0;
  }

  /// Generates the next [capacity] frames of trajectory for [particles] within [bounds].
  void precompute({
    required List<Particle> particles,
    required Size bounds,
    required IParticleController controller,
    GravityConfig gravity = const GravityConfig(),
  }) {
    if (particles.isEmpty || bounds.width <= 0 || bounds.height <= 0) {
      _isValid = false;
      return;
    }

    _particleCount = particles.length;
    final int requiredLength = capacity * _particleCount * 4;
    if (_buffer.length != requiredLength) {
      _buffer = Float64List(requiredLength);
    }

    // Build reusable flat sim state (zero heap allocations vs List<Particle>)
    final int stateLen = _particleCount * 6;
    if (_simState.length < stateLen) _simState = Float64List(stateLen);
    if (_simAccelerated.length < _particleCount) {
      _simAccelerated = List<bool>.filled(_particleCount, false, growable: true);
    }
    for (int i = 0, o = 0; i < _particleCount; i++, o += 6) {
      final Particle p = particles[i];
      _simState[o]     = p.x;
      _simState[o + 1] = p.y;
      _simState[o + 2] = p.vx;
      _simState[o + 3] = p.vy;
      _simState[o + 4] = p.defaultVx;
      _simState[o + 5] = p.defaultVy;
      _simAccelerated[i] = p.wasAccelerated;
    }

    // Clone working particles state for the simulation run — we still need
    // a Particle list because IParticleController.updateParticles takes one.
    // Reuse a cached list to avoid repeated allocations.
    final List<Particle> simParticles =
        _getCachedSimParticles(particles);

    int offset = 0;
    for (int f = 0; f < capacity; f++) {
      controller.updateParticles(simParticles, bounds, gravity: gravity);
      for (int i = 0, o = 0; i < _particleCount; i++, o += 4) {
        final Particle p = simParticles[i];
        _buffer[offset++] = p.x;
        _buffer[offset++] = p.y;
        _buffer[offset++] = p.vx;
        _buffer[offset++] = p.vy;
      }
    }

    _currentFrame = 0;
    _isValid = true;
  }

  // Reusable sim-particle list to avoid re-allocating Particle objects.
  List<Particle>? _cachedSimParticles;

  List<Particle> _getCachedSimParticles(List<Particle> source) {
    final int n = source.length;
    if (_cachedSimParticles == null || _cachedSimParticles!.length != n) {
      // Allocate once; subsequent calls reuse the same objects.
      _cachedSimParticles = List<Particle>.generate(n, (i) {
        final Particle src = source[i];
        return Particle(
          position: Offset(src.x, src.y),
          velocity: Offset(src.vx, src.vy),
          color: src.color,
          size: src.size,
          isVisible: src.isVisible,
        )
          ..defaultVx = src.defaultVx
          ..defaultVy = src.defaultVy
          ..wasAccelerated = src.wasAccelerated;
      });
    } else {
      // Refresh state in existing objects without allocating
      for (int i = 0; i < n; i++) {
        final Particle src = source[i];
        final Particle sim = _cachedSimParticles![i];
        sim.x = src.x;
        sim.y = src.y;
        sim.vx = src.vx;
        sim.vy = src.vy;
        sim.defaultVx = src.defaultVx;
        sim.defaultVy = src.defaultVy;
        sim.wasAccelerated = src.wasAccelerated;
      }
    }
    return _cachedSimParticles!;
  }

  /// Advances to the next frame and updates [particles] positions and velocities.
  /// Returns [true] if successfully updated from buffer, [false] if buffer reached the end.
  bool advance(List<Particle> particles) {
    if (!_isValid || _particleCount != particles.length) {
      return false;
    }

    if (_currentFrame >= capacity) {
      _isValid = false;
      return false;
    }

    int offset = _currentFrame * _particleCount * 4;
    for (int i = 0; i < _particleCount; i++) {
      final Particle p = particles[i];
      // Direct field writes — avoids Offset allocation (2N objects/frame saved)
      p.x  = _buffer[offset++];
      p.y  = _buffer[offset++];
      p.vx = _buffer[offset++];
      p.vy = _buffer[offset++];
    }

    _currentFrame++;
    return true;
  }
}
