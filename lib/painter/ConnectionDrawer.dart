import 'dart:ui';

import 'package:particles_network/model/GridCell.dart';
import 'package:particles_network/model/particlemodel.dart';
import 'package:particles_network/painter/DistanceCalculator.dart';

/// فئة لرسم الاتصالات بين الجسيمات
class ConnectionDrawer {
  final List<Particle> particles;
  final int particleCount;
  final double lineDistance;
  final Color lineColor;
  final Paint linePaint;
  final DistanceCalculator distanceCalculator;

  ConnectionDrawer({
    required this.particles,
    required this.particleCount,
    required this.lineDistance,
    required this.lineColor,
    required this.linePaint,
    required this.distanceCalculator,
  });

  /// رسم الاتصالات بين الجسيمات
  void drawConnections(Canvas canvas, Map<GridCell, List<int>> grid) {
    final processed = <int>{};

    grid.forEach((_, particleIndices) {
      for (int i = 0; i < particleIndices.length; i++) {
        final pIndex = particleIndices[i];
        final p = particles[pIndex];

        for (int j = i + 1; j < particleIndices.length; j++) {
          final otherIndex = particleIndices[j];

          // تجنب معالجة الأزواج مرة أخرى
          // final pairKey = pIndex * particleCount + otherIndex;
          final int pairKey = pIndex * particleCount + otherIndex;
          if (!processed.add(pairKey)) continue;

          final other = particles[otherIndex];
          final distance = distanceCalculator.calculateDistance(p, other);
          const double fursOpacity = 1;
          if (distance < lineDistance) {
            final opacity =
                ((1 - distance / lineDistance) * fursOpacity * 255).toInt();
            linePaint.color = lineColor.withAlpha(opacity.clamp(0, 255));
            canvas.drawLine(p.position, other.position, linePaint);
          }
        }
      }
    });
  }
}
