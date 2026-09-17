import 'dart:typed_data';
import 'dart:ui';
import 'package:particles_network/model/ip_article.dart';
import 'package:particles_network/model/particlemodel.dart';

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

    // Clone working particles state for the simulation run
    final List<Particle> simParticles = [];
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      simParticles.add(
        Particle(
          position: p.position,
          velocity: p.velocity,
          color: p.color,
          size: p.size,
          isVisible: p.isVisible,
        )
          ..defaultVelocity = p.defaultVelocity
          ..wasAccelerated = p.wasAccelerated,
      );
    }

    int offset = 0;
    for (int f = 0; f < capacity; f++) {
      controller.updateParticles(simParticles, bounds, gravity: gravity);
      for (int i = 0; i < _particleCount; i++) {
        final p = simParticles[i];
        _buffer[offset++] = p.position.dx;
        _buffer[offset++] = p.position.dy;
        _buffer[offset++] = p.velocity.dx;
        _buffer[offset++] = p.velocity.dy;
      }
    }

    _currentFrame = 0;
    _isValid = true;
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
      final double px = _buffer[offset++];
      final double py = _buffer[offset++];
      final double vx = _buffer[offset++];
      final double vy = _buffer[offset++];

      particles[i].position = Offset(px, py);
      particles[i].velocity = Offset(vx, vy);
    }

    _currentFrame++;
    return true;
  }
}
