import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:particles_network/model/IParticle.dart';
import 'package:particles_network/model/particlemodel.dart';
import 'package:particles_network/painter/optimizednetworkpainter.dart';

import 'model/DefaultParticleFactory.dart';

class ParticleNetwork extends StatefulWidget {
  //
  final int particleCount;
  final double maxSpeed;
  final double maxSize;
  final double lineDistance;
  final Color particleColor;
  final Color lineColor;
  final Color touchColor;
  final bool touchActivation;
  final double linewidth;

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
    this.lineColor = const Color.fromARGB(255, 100, 255, 180),
    this.touchColor = Colors.amber,
    this.particleFactory,
    this.particleController,
    this.linewidth = 0.5,
  });

  @override
  State<ParticleNetwork> createState() => ParticleNetworkState();
}

class ParticleNetworkState extends State<ParticleNetwork>
    with SingleTickerProviderStateMixin {
  final List<Particle> particles = [];
  late final Ticker ticker;
  Offset touchPoint = Offset.infinite;
  Size currentSize = Size.zero;
  final ValueNotifier<int> frameNotifier = ValueNotifier<int>(0);

  late final IParticleFactory factory;
  late final IParticleController controller;

  @override
  void initState() {
    super.initState();
    factory =
        widget.particleFactory ??
        DefaultParticleFactory(
          random: Random(),
          maxSpeed: widget.maxSpeed,
          maxSize: widget.maxSize,
          color: widget.particleColor,
        );
    controller = widget.particleController ?? ParticleUpdater();

    ticker = createTicker((elapsed) {
      controller.updateParticles(particles, currentSize);
      frameNotifier.value = elapsed.inMilliseconds;
    })..start();
  }

  void _generateParticles(Size size) {
    if (size != currentSize) {
      currentSize = size;
      particles.clear();
      if (size.width > 0 && size.height > 0) {
        for (int i = 0; i < widget.particleCount; i++) {
          particles.add(factory.createParticle(size));
        }
      }
    }
  }

  @override
  void dispose() {
    ticker.dispose();
    frameNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        _generateParticles(constraints.biggest);
        return GestureDetector(
          onPanDown: (d) => touchPoint = d.localPosition,
          onPanUpdate: (d) => touchPoint = d.localPosition,
          onPanEnd: (_) => touchPoint = Offset.infinite,
          onPanCancel: () => touchPoint = Offset.infinite,
          child: ValueListenableBuilder<int>(
            valueListenable: frameNotifier,
            builder:
                (_, __, ___) => CustomPaint(
                  painter: OptimizedNetworkPainter(
                    linewidth: widget.linewidth,
                    particleCount: widget.particleCount,
                    touchActivation: widget.touchActivation,
                    particles: particles,
                    touchPoint: touchPoint,
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
