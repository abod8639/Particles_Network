import 'dart:ui';

import 'package:particles_network/model/particlemodel.dart';

/// Calculates all connections between particles within a specified distance
///
/// This function implements a brute-force approach to find all particle pairs
/// that are closer than [lineDistance]. It returns a list of connection records
/// containing both particles and their exact distance.
///
/// Mathematical Formula:
/// For particles at positions p1(x₁,y₁) and p2(x₂,y₂):
///   distance = √((x₂-x₁)² + (y₂-y₁)²)
///
/// Performance Characteristics:
/// Time Complexity: O(n²) - checks all possible particle pairs
/// Space Complexity: O(k) - where k is number of connections found
///
/// [particles] - List of all particles in the system
/// [lineDistance] - Maximum connection distance in pixels
/// Returns: List of connection maps with structure:
///   {
///     'particle1': Particle,
///     'particle2': Particle,
///     'distance': double
///   }
List<Map<String, dynamic>> calculateParticleConnections(
  List<Particle> particles,
  double lineDistance,
) {
  final List<Map<String, dynamic>> connections = [];

  // Outer loop: process each particle as the first in potential pairs
  for (int i = 0; i < particles.length; i++) {
    // Inner loop: only check particles after current one (avoids duplicate pairs)
    for (int j = i + 1; j < particles.length; j++) {
      // Calculate Euclidean distance between particles
      final distance = (particles[i].position - particles[j].position).distance;

      // Only create connection if within specified distance
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

/// Calculates interactions between particles and a touch point
///
/// Finds all particles within [lineDistance] of the touch point and returns
/// their references along with exact distances. Used for touch visualization
/// and physics effects.
///
/// Mathematical Formula:
/// For particle at p(x,y) and touch point t(tx,ty):
///   distance = √((tx-x)² + (ty-y)²)
///
/// Performance Characteristics:
/// Time Complexity: O(n) - checks each particle once
/// Space Complexity: O(k) - where k is particles near touch point
///
/// [particles] - List of all particles in the system
/// [touchPoint] - Current touch position in screen coordinates
/// [lineDistance] - Maximum interaction distance in pixels
/// Returns: List of interaction maps with structure:
///   {
///     'particle': Particle,
///     'distance': double
///   }
List<Map<String, dynamic>> calculateTouchInteractions(
  List<Particle> particles,
  Offset touchPoint,
  double lineDistance,
) {
  final List<Map<String, dynamic>> interactions = [];

  // Check each particle's distance from touch point
  for (final particle in particles) {
    final distance = (particle.position - touchPoint).distance;

    // Record interaction if within activation distance
    if (distance < lineDistance) {
      interactions.add({'particle': particle, 'distance': distance});
    }
  }

  return interactions;
}
