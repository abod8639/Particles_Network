import 'package:particles_network/model/particlemodel.dart';

/// فئة لتحديد الجسيمات المرئية
class ParticleFilter {
  /// تصفية وإرجاع قائمة بمؤشرات الجسيمات المرئية
  static List<int> getVisibleParticles(List<Particle> particles) {
    final visibleParticles = <int>[];
    for (int i = 0; i < particles.length; i++) {
      if (particles[i].isVisible) {
        visibleParticles.add(i);
      }
    }
    return visibleParticles;
  }
}
