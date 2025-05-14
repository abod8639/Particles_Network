import 'dart:math';

import 'package:flutter/material.dart';
import 'package:particles_network/model/IParticle.dart';
import 'package:particles_network/model/particlemodel.dart';

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
