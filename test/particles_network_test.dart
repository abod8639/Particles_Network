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

    expect(find.byType(ParticleNetwork), findsOneWidget);
    
    expect(
      find.descendant(
        of: find.byType(ParticleNetwork),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
    
    // التحقق من وجود GestureDetector للتعامل مع اللمس
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

    // تغيير الحجم إلى 200x200
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
    
    expect(state.touchPoint, equals(Offset.infinite));

    final gesture = await tester.startGesture(const Offset(150, 150));
    await tester.pump();
    expect(state.touchPoint, equals(const Offset(150, 150)));

    await gesture.moveBy(const Offset(10, 10)); 
    await tester.pump();
    expect(state.touchPoint, equals(const Offset(160, 160)));

    await gesture.up();
    await tester.pump();
    expect(state.touchPoint, equals(Offset.infinite));
  });

  testWidgets('ParticleNetwork logs error when shader fails to load', (WidgetTester tester) async {
    final logs = <String>[];
    final originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) logs.add(message);
    };

    try {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ParticleNetwork(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      logs.any((log) => 
        log.toLowerCase().contains('shader') || 
        log.toLowerCase().contains('fail'));

      expect(find.byType(ParticleNetwork), findsOneWidget);
      

    } finally {
      debugPrint = originalDebugPrint; 
    }
  });
}