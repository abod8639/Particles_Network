import 'package:flutter/material.dart';
import 'package:particles_network/model/particlemodel.dart';
import 'package:particles_network/particles_network.dart';

// Mock implementations for testing
class MockParticleFactory implements IParticleFactory {
  final Particle particleToReturn;

  MockParticleFactory(this.particleToReturn);

  @override
  Particle createParticle(Size size) => particleToReturn;
}

class MockParticleController implements IParticleController {
  int updateCount = 0;
  List<Particle>? lastParticles;
  Size? lastBounds;

  @override
  void updateParticles(List<Particle> particles, Size bounds) {
    updateCount++;
    lastParticles = particles;
    lastBounds = bounds;
  }
}
