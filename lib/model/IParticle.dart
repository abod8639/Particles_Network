import 'dart:ui';

import 'package:particles_network/model/particlemodel.dart';

abstract class IParticleFactory {
  Particle createParticle(Size size);
}

abstract class IParticleController {
  void updateParticles(List<Particle> particles, Size bounds);
}

class ParticleUpdater implements IParticleController {
  @override
  void updateParticles(List<Particle> particles, Size bounds) {
    for (final p in particles) {
      p.update(bounds);
    }
  }
}
