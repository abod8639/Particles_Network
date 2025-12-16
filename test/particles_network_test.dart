import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/particles_network.dart';

void main() {
  testWidgets('ParticleNetwork builds correctly with default parameters', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: ParticleNetwork(),
          ),
        ),
      ),
    );

    // Verify widget is present
    expect(find.byType(ParticleNetwork), findsOneWidget);
    
    // Verify CustomPaint is used (which triggers the painter)
    expect(
      find.descendant(
        of: find.byType(ParticleNetwork),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
    
    // Verify GestureDetector is present (for user interaction)
    expect(
      find.descendant(
        of: find.byType(ParticleNetwork),
        matching: find.byType(GestureDetector),
      ),
      findsOneWidget,
    );
  });

  testWidgets('ParticleNetwork respects parameters', (WidgetTester tester) async {
    const testColor = Color(0xFFFF0000);
    
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: ParticleNetwork(
              particleCount: 10,
              particleColor: testColor,
              touchActivation: false,
            ),
          ),
        ),
      ),
    );

    final widget = tester.widget<ParticleNetwork>(find.byType(ParticleNetwork));
    expect(widget.particleCount, 10);
    expect(widget.particleColor, testColor);
    expect(widget.touchActivation, false);
  });
  
  testWidgets('ParticleNetwork handles resize', (WidgetTester tester) async {
    // Initial size
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 100,
            height: 100,
            child: ParticleNetwork(),
          ),
        ),
      ),
    );
    
    expect(find.byType(ParticleNetwork), findsOneWidget);

    // Resize
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 200,
            child: ParticleNetwork(),
          ),
        ),
      ),
    );
    
    // Should still exist and not crash
    expect(find.byType(ParticleNetwork), findsOneWidget);
  });
}
