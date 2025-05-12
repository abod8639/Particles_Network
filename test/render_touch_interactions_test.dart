import 'package:flutter/widgets.dart'; // لاستخدام Offset
import 'package:test/test.dart';

// تعريف الجسيمات
class Particle {
  final Offset position;
  Particle({required this.position});
}

// الكود الذي نختبره
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

void main() {
  group('calculateTouchInteractions', () {
    test('returns empty list when no particles are close to touchPoint', () {
      // إعداد البيانات
      final particles = [
        Particle(position: Offset(100, 100)),
        Particle(position: Offset(200, 200)),
      ];
      final touchPoint = Offset(10, 10);
      final lineDistance = 5.0;

      // استدعاء الدالة
      final interactions = calculateTouchInteractions(
        particles,
        touchPoint,
        lineDistance,
      );

      // التحقق من أن القائمة فارغة
      expect(interactions, isEmpty);
    });

    test('returns correct particles within the lineDistance', () {
      // إعداد البيانات
      final particles = [
        Particle(position: Offset(10, 10)),
        Particle(position: Offset(30, 30)),
        Particle(position: Offset(50, 50)),
      ];
      final touchPoint = Offset(20, 20);
      final lineDistance = 15.0;

      // استدعاء الدالة
      final interactions = calculateTouchInteractions(
        particles,
        touchPoint,
        lineDistance,
      );

      // التحقق من النتائج
      expect(interactions, hasLength(2)); // يجب أن يكون هناك تفاعل مع جسيمين
      expect(
        interactions[0]['distance'],
        closeTo(14.14, 0.01),
      ); // المسافة بين (10,10) و (20,20) تقريباً 14.14
      expect(
        interactions[1]['distance'],
        closeTo(14.14, 0.01),
      ); // المسافة بين (30,30) و (20,20) تقريباً 14.14
    });

    test('returns correct particles within the lineDistance', () {
      // إعداد البيانات
      final particles = [
        Particle(position: Offset(10, 10)),
        Particle(position: Offset(30, 30)),
        Particle(position: Offset(50, 50)),
      ];
      final touchPoint = Offset(20, 20);
      final lineDistance = 15.0;

      // استدعاء الدالة
      final interactions = calculateTouchInteractions(
        particles,
        touchPoint,
        lineDistance,
      );

      // التحقق من النتائج
      expect(interactions, hasLength(2)); // يجب أن يكون هناك تفاعل مع جسيمين
      expect(
        interactions[0]['distance'],
        closeTo(14.14, 0.01),
      ); // المسافة بين (10,10) و (20,20) تقريباً 14.14
      expect(
        interactions[1]['distance'],
        closeTo(14.14, 0.01),
      ); // المسافة بين (30,30) و (20,20) تقريباً 14.14
    });
  });
}
