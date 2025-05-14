import 'dart:ui';

import 'package:particles_network/model/particlemodel.dart';

List<Map<String, dynamic>> calculateParticleConnections(
  List<Particle> particles,
  double lineDistance,
) {
  final List<Map<String, dynamic>> connections = [];

  for (int i = 0; i < particles.length; i++) {
    for (int j = i + 1; j < particles.length; j++) {
      final distance = (particles[i].position - particles[j].position).distance;
      if (distance < lineDistance) {
        connections.add({
          'particle1': particles[i],
          'particle2': particles[j],
          'distance': distance,
        });
      }
    }
  }

  return connections;
}

List<Map<String, dynamic>> calculateTouchInteractions(
  List<Particle> particles,
  Offset touchPoint,
  double lineDistance,
) {
  final List<Map<String, dynamic>> interactions = [];

  for (final particle in particles) {
    final distance = (particle.position - touchPoint).distance;
    if (distance < lineDistance) {
      interactions.add({'particle': particle, 'distance': distance});
    }
  }

  return interactions;
}
