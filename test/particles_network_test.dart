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
  testWidgets('ParticleNetwork handles touch interactions', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: ParticleNetwork(
              touchActivation: true,
            ),
          ),
        ),
      ),
    );

    final state = tester.state<ParticleNetworkState>(find.byType(ParticleNetwork));
    
    // Initial state
    expect(state.touchPoint, equals(Offset.infinite));

    // Pan Down
    final gesture = await tester.startGesture(const Offset(150, 150));
    await tester.pump();
    expect(state.touchPoint, equals(const Offset(150, 150)));

    // Pan Update
    await gesture.moveBy(const Offset(10, 10)); // Moves to 160, 160
    await tester.pump();
    expect(state.touchPoint, equals(const Offset(160, 160)));

    // Pan End
    await gesture.up();
    await tester.pump();
    expect(state.touchPoint, equals(Offset.infinite));

    // Pan Cancel verification
    // We start a new gesture and cancel it
    final cancelGesture = await tester.startGesture(const Offset(100, 100));
    await tester.pump();
    expect(state.touchPoint, equals(const Offset(100, 100)));
    
    await cancelGesture.cancel();
    await tester.pump();
    expect(state.touchPoint, equals(Offset.infinite));
  });

  testWidgets('ParticleNetwork logs error when shader fails to load', (WidgetTester tester) async {
    final originalDebugPrint = debugPrint;
    final logs = <String>[];
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) logs.add(message);
    };

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: ParticleNetwork(
              shaderPath: 'non/existent/path.frag', // Should trigger error
            ),
          ),
        ),
      ),
    );
    
    // Wait for async load
    // We cannot use pumpAndSettle because ParticleNetwork has an infinite animation loop.
    await tester.pump(const Duration(milliseconds: 100));

    debugPrint = originalDebugPrint;

    expect(logs.any((log) => log.contains('Failed to load shader')), isTrue);
  });
}
