// ملف: spatial_grid_manager.dart

import 'package:particles_network/model/drid_cell.dart';
import 'package:particles_network/model/particlemodel.dart';

/// فئة للتقسيم المكاني للجسيمات
class SpatialGridManager {
  /// إنشاء شبكة مكانية محسّنة باستخدام GridCell كمفتاح
  static Map<GridCell, List<int>> createOptimizedSpatialGrid(
    List<Particle> particles,
    List<int> visibleParticles,
    double cellSize,
  ) {
    final grid = <GridCell, List<int>>{};

    for (final i in visibleParticles) {
      final p = particles[i];
      final cellX = (p.position.dx / cellSize).floor();
      final cellY = (p.position.dy / cellSize).floor();

      // إضافة الجسيم إلى الخلايا المجاورة (3x3) لتسهيل البحث لاحقًا
      for (int nx = -1; nx <= 1; nx++) {
        for (int ny = -1; ny <= 1; ny++) {
          final cell = GridCell(cellX + nx, cellY + ny);
          grid.putIfAbsent(cell, () => []).add(i);
        }
      }
    }

    return grid;
  }
}
