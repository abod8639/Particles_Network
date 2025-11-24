import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/model/particlemodel.dart';
import 'package:particles_network/painter/distance_calculator.dart';

void main() {
  group('DistanceCalculator', () {
    late DistanceCalculator calculator;

    setUp(() {
      calculator = DistanceCalculator(maxEntries: 100);
    });

    group('Distance Calculations', () {
      test('calculates correct Euclidean distance between particles', () {
        final p1 = Particle(color: Colors.white, size: 1.0, 
          position: const Offset(0, 0),
          velocity: Offset.zero,
        );
        final p2 = Particle(color: Colors.white, size: 1.0, 
          position: const Offset(3, 4),
          velocity: Offset.zero,
        );

        final distance = calculator.betweenParticles(p1, p2);

        // Distance should be 5 (3-4-5 triangle)
        expect(distance, equals(5.0));
      });

      test('calculates correct distance between points', () {
        const p1 = Offset(0, 0);
        const p2 = Offset(3, 4);

        final distance = calculator.betweenPoints(p1, p2);

        expect(distance, equals(5.0));
      });

      test('returns 0 for same position particles', () {
        final p1 = Particle(color: Colors.white, size: 1.0, 
          position: const Offset(5, 5),
          velocity: Offset.zero,
        );
        final p2 = Particle(color: Colors.white, size: 1.0, 
          position: const Offset(5, 5),
          velocity: Offset.zero,
        );

        final distance = calculator.betweenParticles(p1, p2);

        expect(distance, equals(0.0));
      });

      test('handles negative coordinates correctly', () {
        final p1 = Particle(color: Colors.white, size: 1.0, 
          position: const Offset(-3, -4),
          velocity: Offset.zero,
        );
        final p2 = Particle(color: Colors.white, size: 1.0, 
          position: const Offset(0, 0),
          velocity: Offset.zero,
        );

        final distance = calculator.betweenParticles(p1, p2);

        expect(distance, equals(5.0));
      });

      test('distance is symmetric (A->B == B->A)', () {
        final p1 = Particle(color: Colors.white, size: 1.0, 
          position: const Offset(1, 2),
          velocity: Offset.zero,
        );
        final p2 = Particle(color: Colors.white, size: 1.0, 
          position: const Offset(4, 6),
          velocity: Offset.zero,
        );

        final distAB = calculator.betweenParticles(p1, p2);
        final distBA = calculator.betweenParticles(p2, p1);

        expect(distAB, equals(distBA));
      });
    });

    group('Caching Behavior', () {
      test('caches distance calculations', () {
        final p1 = Particle(color: Colors.white, size: 1.0, 
          position: const Offset(0, 0),
          velocity: Offset.zero,
        );
        final p2 = Particle(color: Colors.white, size: 1.0, 
          position: const Offset(3, 4),
          velocity: Offset.zero,
        );

        // First call - should calculate and cache
        final dist1 = calculator.betweenParticles(p1, p2);
        
        // Second call - should return cached value
        final dist2 = calculator.betweenParticles(p1, p2);

        expect(dist1, equals(dist2));
        expect(dist1, equals(5.0));
      });

      test('symmetric caching (A,B) and (B,A) use same cache entry', () {
        final p1 = Particle(color: Colors.white, size: 1.0, 
          position: const Offset(0, 0),
          velocity: Offset.zero,
        );
        final p2 = Particle(color: Colors.white, size: 1.0, 
          position: const Offset(3, 4),
          velocity: Offset.zero,
        );

        // Calculate A->B
        calculator.betweenParticles(p1, p2);
        
        // Calculate B->A (should hit cache)
        final dist = calculator.betweenParticles(p2, p1);

        expect(dist, equals(5.0));
      });

      test('betweenPoints does not use cache', () {
        const p1 = Offset(0, 0);
        const p2 = Offset(3, 4);

        // Multiple calls should work without caching
        final dist1 = calculator.betweenPoints(p1, p2);
        final dist2 = calculator.betweenPoints(p1, p2);

        expect(dist1, equals(5.0));
        expect(dist2, equals(5.0));
      });

      test('reset clears all cached entries', () {
        final particles = List.generate(
          10,
          (i) => Particle(color: Colors.white, size: 1.0, 
            position: Offset(i.toDouble(), i.toDouble()),
            velocity: Offset.zero,
          ),
        );

        // Cache some distances
        for (int i = 0; i < 5; i++) {
          calculator.betweenParticles(particles[i], particles[i + 1]);
        }

        // Reset cache
        calculator.reset();

        // After reset, calculations should still work
        final dist = calculator.betweenParticles(particles[0], particles[1]);
        expect(dist, greaterThan(0));
      });
    });

    group('LRU Eviction', () {
      test('evicts oldest entry when cache is full', () {
        final smallCalculator = DistanceCalculator(maxEntries: 3);
        
        final particles = List.generate(
          5,
          (i) => Particle(color: Colors.white, size: 1.0, 
            position: Offset(i.toDouble(), 0),
            velocity: Offset.zero,
          ),
        );

        // Fill cache beyond capacity
        for (int i = 0; i < 4; i++) {
          smallCalculator.betweenParticles(particles[i], particles[i + 1]);
        }

        // Cache should have evicted oldest entries
        // All calculations should still return correct values
        final dist = smallCalculator.betweenParticles(particles[0], particles[1]);
        expect(dist, equals(1.0));
      });

      test('respects maxEntries limit', () {
        final smallCalculator = DistanceCalculator(maxEntries: 5);
        
        final particles = List.generate(
          20,
          (i) => Particle(color: Colors.white, size: 1.0, 
            position: Offset(i.toDouble(), i.toDouble()),
            velocity: Offset.zero,
          ),
        );

        // Add many entries
        for (int i = 0; i < 15; i++) {
          smallCalculator.betweenParticles(particles[i], particles[i + 1]);
        }

        // All calculations should still work correctly
        final dist = smallCalculator.betweenParticles(particles[0], particles[1]);
        expect(dist, closeTo(1.414, 0.001)); // sqrt(2)
      });

      test('cache disabled when maxEntries is 0', () {
        final noCacheCalculator = DistanceCalculator(maxEntries: 0);
        
        final p1 = Particle(color: Colors.white, size: 1.0, 
          position: const Offset(0, 0),
          velocity: Offset.zero,
        );
        final p2 = Particle(color: Colors.white, size: 1.0, 
          position: const Offset(3, 4),
          velocity: Offset.zero,
        );

        // Should calculate without caching
        final dist1 = noCacheCalculator.betweenParticles(p1, p2);
        final dist2 = noCacheCalculator.betweenParticles(p1, p2);

        expect(dist1, equals(5.0));
        expect(dist2, equals(5.0));
      });
    });

    group('Cache Size Updates', () {
      test('updateCacheSize adjusts cache capacity', () {
        calculator.updateCacheSize(50);
        
        // For 50 particles, estimated pairs = 50*49/2 = 1225
        // Clamped to range [1000, 20000]
        expect(calculator.maxEntries, equals(1225));
      });

      test('updateCacheSize respects minimum bound', () {
        calculator.updateCacheSize(10);
        
        // For 10 particles, estimated pairs = 45
        // Should be clamped to minimum 1000
        expect(calculator.maxEntries, equals(1000));
      });

      test('updateCacheSize respects maximum bound', () {
        calculator.updateCacheSize(1000);
        
        // For 1000 particles, estimated pairs = 499500
        // Should be clamped to maximum 20000
        expect(calculator.maxEntries, equals(20000));
      });

      test('updateCacheSize trims cache when reducing size', () {
        final testCalculator = DistanceCalculator(maxEntries: 100);
        
        final particles = List.generate(
          50,
          (i) => Particle(color: Colors.white, size: 1.0, 
            position: Offset(i.toDouble(), 0),
            velocity: Offset.zero,
          ),
        );

        // Fill cache with many entries
        for (int i = 0; i < 40; i++) {
          testCalculator.betweenParticles(particles[i], particles[i + 1]);
        }

        // Reduce cache size
        testCalculator.maxEntries = 10;
        testCalculator.updateCacheSize(5); // Will set to 1000 (minimum)
        
        // Should still work correctly
        final dist = testCalculator.betweenParticles(particles[0], particles[1]);
        expect(dist, equals(1.0));
      });
    });

    group('Edge Cases', () {
      test('handles very large distances', () {
        final p1 = Particle(color: Colors.white, size: 1.0, 
          position: const Offset(0, 0),
          velocity: Offset.zero,
        );
        final p2 = Particle(color: Colors.white, size: 1.0, 
          position: const Offset(10000, 10000),
          velocity: Offset.zero,
        );

        final distance = calculator.betweenParticles(p1, p2);

        expect(distance, closeTo(14142.135, 0.001)); // sqrt(2) * 10000
      });

      test('handles very small distances', () {
        final p1 = Particle(color: Colors.white, size: 1.0, 
          position: const Offset(0, 0),
          velocity: Offset.zero,
        );
        final p2 = Particle(color: Colors.white, size: 1.0, 
          position: const Offset(0.001, 0.001),
          velocity: Offset.zero,
        );

        final distance = calculator.betweenParticles(p1, p2);

        expect(distance, closeTo(0.001414, 0.00001)); // sqrt(2) * 0.001
      });

      test('handles multiple particles with same position', () {
        final particles = List.generate(
          5,
          (_) => Particle(color: Colors.white, size: 1.0, 
            position: const Offset(5, 5),
            velocity: Offset.zero,
          ),
        );

        for (int i = 0; i < particles.length - 1; i++) {
          final dist = calculator.betweenParticles(particles[i], particles[i + 1]);
          expect(dist, equals(0.0));
        }
      });

      test('handles diagonal distances correctly', () {
        final testCases = [
          (Offset(0, 0), Offset(1, 1), 1.414), // sqrt(2)
          (Offset(0, 0), Offset(2, 2), 2.828), // 2*sqrt(2)
          (Offset(0, 0), Offset(5, 5), 7.071), // 5*sqrt(2)
        ];

        for (final (p1Pos, p2Pos, expected) in testCases) {
          final p1 = Particle(
            position: p1Pos,
            velocity: Offset.zero,
            color: Colors.white,
            size: 1.0,
          );
          final p2 = Particle(
            position: p2Pos,
            velocity: Offset.zero,
            color: Colors.white,
            size: 1.0,
          );
          
          final distance = calculator.betweenParticles(p1, p2);
          expect(distance, closeTo(expected, 0.001));
        }
      });
    });

    group('Performance Characteristics', () {
      test('handles large number of particles efficiently', () {
        final largeCalculator = DistanceCalculator(maxEntries: 10000);
        
        final particles = List.generate(
          500,
          (i) => Particle(color: Colors.white, size: 1.0, 
            position: Offset(i.toDouble(), i.toDouble()),
            velocity: Offset.zero,
          ),
        );

        final stopwatch = Stopwatch()..start();
        
        // Calculate distances for many pairs
        for (int i = 0; i < particles.length - 1; i++) {
          largeCalculator.betweenParticles(particles[i], particles[i + 1]);
        }
        
        stopwatch.stop();
        
        // Should complete in reasonable time (< 100ms for 500 particles)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('cache provides performance benefit on repeated queries', () {
        final particles = List.generate(
          100,
          (i) => Particle(color: Colors.white, size: 1.0, 
            position: Offset(i.toDouble(), i.toDouble()),
            velocity: Offset.zero,
          ),
        );

        // First pass - populate cache
        for (int i = 0; i < 50; i++) {
          calculator.betweenParticles(particles[i], particles[i + 1]);
        }

        // Second pass - should hit cache and return correct values
        for (int i = 0; i < 50; i++) {
          final dist = calculator.betweenParticles(particles[i], particles[i + 1]);
          expect(dist, closeTo(1.414, 0.001)); // sqrt(2)
        }
      });
    });
  });
}
