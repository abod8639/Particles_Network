/// A helper class representing a candidate for a connection between particles.
///
/// This class stores the index of a target particle and the distance to it,
/// used during the calculation of connections in the network.
class ConnectionCandidate {
  /// The index of the connected candidate particle in the particle list.
  final int index;

  /// The squared distance (or actual distance depending on usage) to the candidate particle.
  final double distance;

  /// Creates a [ConnectionCandidate] with the given [index] and [distance].
  ConnectionCandidate({required this.index, required this.distance});
}
