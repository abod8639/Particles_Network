import 'package:flutter/material.dart';
import 'package:particles_network/model/particlemodel.dart';
import 'package:particles_network/painter/ConnectionDrawer.dart';
import 'package:particles_network/painter/DistanceCalculator.dart';
import 'package:particles_network/painter/ParticleFilter.dart';
import 'package:particles_network/painter/SpatialGridManager.dart';
import 'package:particles_network/painter/TouchInteractionHandler.dart';

// سيتم تقسيم OptimizedNetworkPainter إلى أجزاء صغيرة يمكن اختبارها

/// المكون الرئيسي لرسم شبكة الجسيمات
class OptimizedNetworkPainter extends CustomPainter {
  final List<Particle> particles;
  final Offset? touchPoint;
  final double lineDistance;
  final Color particleColor;
  final Color lineColor;
  final Color touchColor;
  final bool touchActivation;
  final int particleCount;
  final double linewidth;

  // مكونات محسّنة
  late final DistanceCalculator _distanceCalculator;
  late final ConnectionDrawer _connectionDrawer;
  late final TouchInteractionHandler _touchHandler;

  // أدوات الرسم المُعاد استخدامها
  late final Paint _particlePaint;
  late final Paint _linePaint;

  OptimizedNetworkPainter({
    required this.particleCount,
    required this.particles,
    required this.touchPoint,
    required this.lineDistance,
    required this.particleColor,
    required this.lineColor,
    required this.touchColor,
    required this.touchActivation,
    required this.linewidth,
  }) {
    // تهيئة أدوات الرسم مرة واحدة أثناء الإنشاء
    _particlePaint =
        Paint()
          ..color = particleColor
          ..style = PaintingStyle.fill;

    _linePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = linewidth;

    // تهيئة المكونات
    _distanceCalculator = DistanceCalculator(particleCount);
    _connectionDrawer = ConnectionDrawer(
      particles: particles,
      particleCount: particleCount,
      lineDistance: lineDistance,
      lineColor: lineColor,
      linePaint: _linePaint,
      distanceCalculator: _distanceCalculator,
    );
    _touchHandler = TouchInteractionHandler(
      particles: particles,
      touchPoint: touchPoint,
      lineDistance: lineDistance,
      touchColor: touchColor,
      linePaint: _linePaint,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // مسح ذاكرة التخزين المؤقت
    _distanceCalculator.clearCache();

    // الحصول على الجسيمات المرئية
    final visibleParticles = ParticleFilter.getVisibleParticles(particles);

    // إنشاء الشبكة المكانية للبحث السريع
    final grid = SpatialGridManager.createOptimizedSpatialGrid(
      particles,
      visibleParticles,
      lineDistance,
    );

    // رسم الاتصالات بين الجسيمات
    _connectionDrawer.drawConnections(canvas, grid);

    // معالجة تفاعل اللمس ورسمه
    if (touchPoint != null && touchActivation) {
      _touchHandler.applyTouchPhysics(visibleParticles);
      _touchHandler.drawTouchLines(canvas, visibleParticles);
    }

    // رسم الجسيمات
    _drawParticles(canvas, visibleParticles);
  }

  /// رسم الجسيمات الفردية
  void _drawParticles(Canvas canvas, List<int> visibleParticles) {
    for (final index in visibleParticles) {
      final p = particles[index];
      canvas.drawCircle(p.position, p.size, _particlePaint);
    }
  }

  @override
  bool shouldRepaint(OptimizedNetworkPainter oldDelegate) {
    return oldDelegate.touchPoint != touchPoint ||
        particles.any((p) => p.wasAccelerated);
  }
}



// // فئات اختبار إضافية لاختبارات الوحدات

// /// فئة وهمية للجسيمات لاستخدامها في الاختبارات
// class MockParticle extends Particle {
//   MockParticle(Offset position, {bool isVisible = true}) : super(position, isVisible: isVisible);
// }

// /// مساعد لإنشاء بيانات اختبار
// class TestDataGenerator {
//   /// إنشاء قائمة من الجسيمات الوهمية للاختبار
//   static List<Particle> createMockParticles(int count, Size size) {
//     final particles = <Particle>[];
//     for (int i = 0; i < count; i++) {
//       final x = (i * 10) % size.width;
//       final y = ((i * 10) / size.width).floor() * 10;
//       particles.add(MockParticle(Offset(x, y)));
//     }
//     return particles;
//   }
// }

// /// فئة اختبار لحساب المسافة
// class DistanceCalculatorTest {
//   static void runTests() {
//     test('حساب المسافة بين جسيمين', () {
//       final calculator = DistanceCalculator(10);
//       final p1 = MockParticle(const Offset(0, 0));
//       final p2 = MockParticle(const Offset(3, 4));
      
//       final distance = calculator.calculateDistance(p1, p2);
//       expect(distance, 5.0);
//     });
    
//     test('ذاكرة التخزين المؤقت تعمل بشكل صحيح', () {
//       final calculator = DistanceCalculator(10);
//       final p1 = MockParticle(const Offset(0, 0));
//       final p2 = MockParticle(const Offset(3, 4));
      
//       // المرة الأولى تحسب المسافة
//       final distance1 = calculator.calculateDistance(p1, p2);
//       // المرة الثانية يجب أن تستخدم التخزين المؤقت
//       final distance2 = calculator.calculateDistance(p1, p2);
      
//       expect(distance1, 5.0);
//       expect(distance2, 5.0);
      
//       calculator.clearCache();
//       // بعد المسح، يجب أن يعاد الحساب
//     });
//   }
// }

// /// فئة اختبار لفلتر الجسيمات
// class ParticleFilterTest {
//   static void runTests() {
//     test('يجب أن يعرض فقط الجسيمات المرئية', () {
//       final particles = [
//         MockParticle(const Offset(0, 0), isVisible: true),
//         MockParticle(const Offset(10, 10), isVisible: false),
//         MockParticle(const Offset(20, 20), isVisible: true),
//       ];
      
//       final visibleParticles = ParticleFilter.getVisibleParticles(particles);
      
//       expect(visibleParticles.length, 2);
//       expect(visibleParticles, [0, 2]);
//     });
//   }
// }

// /// فئة اختبار للشبكة المكانية
// class SpatialGridManagerTest {
//   static void runTests() {
//     test('إنشاء شبكة مكانية بالحجم الصحيح', () {
//       final particles = [
//         MockParticle(const Offset(10, 10)),
//         MockParticle(const Offset(20, 20)),
//       ];
//       final visibleParticles = [0, 1];
//       final cellSize = 15.0;
      
//       final grid = SpatialGridManager.createOptimizedSpatialGrid(
//         particles, 
//         visibleParticles, 
//         cellSize
//       );
      
//       // يجب أن تحتوي الشبكة على خلايا تغطي كلا الجسيمين
//       expect(grid.isNotEmpty, true);
//     });
//   }
// }

// // يمكن تشغيل اختبارات الوحدة هكذا:
// void runAllTests() {
//   DistanceCalculatorTest.runTests();
//   ParticleFilterTest.runTests();
//   SpatialGridManagerTest.runTests();
//   // يمكن إضافة المزيد من الاختبارات هنا
// }