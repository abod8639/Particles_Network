import 'package:particles_network/model/particlemodel.dart';

/// مساعد لحساب المسافة بين جسيمين مع التخزين المؤقت
class DistanceCalculator {
  final Map<int, double> _cache = <int, double>{};
  final int particleCount;

  DistanceCalculator(this.particleCount);

  /// حساب المسافة بين جسيمين مع التخزين المؤقت للتحسين
  double calculateDistance(Particle p1, Particle p2) {
    final key = p1.hashCode ^ p2.hashCode;
    return _cache.putIfAbsent(key, () => (p1.position - p2.position).distance);
  }

  /// مسح ذاكرة التخزين المؤقت
  void clearCache() {
    _cache.clear();
  }
}
