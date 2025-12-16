import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/particles_network.dart';
import 'package:particles_network/painter/optimized_network_painter.dart';

void main() {
  testWidgets('ParticlesNetwork builds correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ParticleNetwork(
            particleCount: 50,
            lineDistance: 100,
            particleColor: Colors.red,
            lineColor: Colors.blue,
          ),
        ),
      ),
    );

    // Verify widget is present
    expect(find.byType(ParticleNetwork), findsOneWidget);
    expect(find.descendant(
      of: find.byType(ParticleNetwork),
      matching: find.byType(CustomPaint),
    ), findsOneWidget);
  });

  testWidgets('ParticlesNetwork uses fallback painter initially', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ParticleNetwork(
            particleCount: 50,
          ),
        ),
      ),
    );

    // Initially, shader is not loaded, so it should use OptimizedNetworkPainter
    // Note: We can't easily check the painter type directly from the widget tree without finding the CustomPaint
    // but we can verify it doesn't crash.
    
    final customPaintFinder = find.descendant(
      of: find.byType(ParticleNetwork),
      matching: find.byType(CustomPaint),
    );
    final customPaint = tester.widget<CustomPaint>(customPaintFinder);
    expect(customPaint.painter, isA<OptimizedNetworkPainter>());
  });
}
