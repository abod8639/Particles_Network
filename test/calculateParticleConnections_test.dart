import 'package:flutter_test/flutter_test.dart';

// تعريف الكائن Particle
class Particle {
  final Offset position;
  Particle(this.position);
}

// الدالة التي نريد اختبارها
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

// تحليلات المسافات بين الجسيمات:

//     المسافة بين Offset(0, 0) و Offset(50, 50) هي:
//     (50−0)2+(50−0)2=2500+2500=5000≈70.71
//     (50−0)2+(50−0)2

// ​=2500+2500
// ​=5000
// ​≈70.71

// المسافة بين Offset(0, 0) و Offset(100, 100) هي:
// (100−0)2+(100−0)2=10000+10000=20000≈141.42
// (100−0)2+(100−0)2
// ​=10000+10000
// ​=20000
// ​≈141.42

// المسافة بين Offset(50, 50) و Offset(100, 100) هي:
// (100−50)2+(100−50)2=2500+2500=5000≈70.71
// (100−50)2+(100−50)2
// ​=2500+2500
// ​=5000
// ​≈70.71

// المسافة بين Offset(100, 100) و Offset(200, 200) هي:
// (200−100)2+(200−100)2=10000+10000=20000≈141.42
// (200−100)2+(200−100)2
// ​=10000+10000
// ​=20000

//     ​≈141.42

void main() {
  test('Test calculateParticleConnections', () {
    // تعريف بعض الجسيمات مع مواقع محددة
    final particles = [
      Particle(Offset(0, 0)),
      Particle(Offset(50, 50)),
      Particle(Offset(100, 100)),
      Particle(Offset(200, 200)),
    ];

    final lineDistance = 100.0; // المسافة القصوى لتحديد الاتصال بين الجسيمات

    // حساب الاتصالات بين الجسيمات
    final connections = calculateParticleConnections(particles, lineDistance);

    // التحقق من النتائج
    expect(
      connections.length,
      2,
    ); // بناءً على المسافات يجب أن يكون هناك 2 اتصال فقط

    // التحقق من أن الجسيمات المتصلة هي كما هو متوقع
    expect(connections[0]['particle1'].position, Offset(0, 0));
    expect(connections[0]['particle2'].position, Offset(50, 50));
    expect(
      connections[0]['distance'],
      (Offset(0, 0) - Offset(50, 50)).distance,
    );

    expect(connections[1]['particle1'].position, Offset(50, 50));
    expect(connections[1]['particle2'].position, Offset(100, 100));
    expect(
      connections[1]['distance'],
      (Offset(50, 50) - Offset(100, 100)).distance,
    );
  });
}
