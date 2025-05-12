import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:particles_network/model/particlemodel.dart';
import 'package:particles_network/painter/optimizednetworkpainter.dart';

abstract class IParticleFactory {
  Particle createParticle(Size size);
}

abstract class IParticleController {
  void updateParticles(List<Particle> particles, Size bounds);
}

class DefaultParticleFactory implements IParticleFactory {
  final Random random;
  final double maxSpeed;
  final double maxSize;
  final Color color;

  DefaultParticleFactory({
    required this.random,
    required this.maxSpeed,
    required this.maxSize,
    required this.color,
  });

  @override
  Particle createParticle(Size size) {
    final velocity = Offset(
      (random.nextDouble() - 0.5) * maxSpeed,
      (random.nextDouble() - 0.5) * maxSpeed,
    );
    return Particle(
      color: color,
      position: Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      ),
      velocity: velocity,
      size: random.nextDouble() * maxSize + 1,
    );
  }
}

class ParticleUpdater implements IParticleController {
  @override
  void updateParticles(List<Particle> particles, Size bounds) {
    for (final p in particles) {
      p.update(bounds);
    }
  }
}

class ParticleNetwork extends StatefulWidget {
  final int particleCount;
  final double maxSpeed;
  final double maxSize;
  final double lineDistance;
  final Color particleColor;
  final Color lineColor;
  final Color touchColor;
  final bool touchActivation;

  // Injected dependencies
  final IParticleFactory? particleFactory;
  final IParticleController? particleController;

  const ParticleNetwork({
    super.key,
    this.particleCount = 50,
    this.touchActivation = true,
    this.maxSpeed = 0.5,
    this.maxSize = 3.5,
    this.lineDistance = 180,
    this.particleColor = Colors.white,
    this.lineColor = Colors.greenAccent,
    this.touchColor = Colors.amber,
    this.particleFactory,
    this.particleController,
  });

  @override
  State<ParticleNetwork> createState() => _ParticleNetworkState();
}

class _ParticleNetworkState extends State<ParticleNetwork>
    with SingleTickerProviderStateMixin {
  final List<Particle> _particles = [];
  late final Ticker _ticker;
  Offset _touchPoint = Offset.infinite;
  Size _currentSize = Size.zero;
  final ValueNotifier<int> _frameNotifier = ValueNotifier<int>(0);

  late final IParticleFactory _factory;
  late final IParticleController _controller;

  @override
  void initState() {
    super.initState();
    _factory =
        widget.particleFactory ??
        DefaultParticleFactory(
          random: Random(),
          maxSpeed: widget.maxSpeed,
          maxSize: widget.maxSize,
          color: widget.particleColor,
        );
    _controller = widget.particleController ?? ParticleUpdater();

    _ticker = createTicker((elapsed) {
      _controller.updateParticles(_particles, _currentSize);
      _frameNotifier.value = elapsed.inMilliseconds;
    })..start();
  }

  void _generateParticles(Size size) {
    if (size != _currentSize) {
      _currentSize = size;
      _particles.clear();
      if (size.width > 0 && size.height > 0) {
        for (int i = 0; i < widget.particleCount; i++) {
          _particles.add(_factory.createParticle(size));
        }
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frameNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        _generateParticles(constraints.biggest);
        return GestureDetector(
          onPanDown: (d) => _touchPoint = d.localPosition,
          onPanUpdate: (d) => _touchPoint = d.localPosition,
          onPanEnd: (_) => _touchPoint = Offset.infinite,
          onPanCancel: () => _touchPoint = Offset.infinite,
          child: ValueListenableBuilder<int>(
            valueListenable: _frameNotifier,
            builder:
                (_, __, ___) => CustomPaint(
                  painter: OptimizedNetworkPainter(
                    touchActivation: widget.touchActivation,
                    particles: _particles,
                    touchPoint: _touchPoint,
                    lineDistance: widget.lineDistance,
                    particleColor: widget.particleColor,
                    lineColor: widget.lineColor,
                    touchColor: widget.touchColor,
                  ),
                  isComplex: true,
                  willChange: true,
                  child: const SizedBox.expand(),
                ),
          ),
        );
      },
    );
  }
}
