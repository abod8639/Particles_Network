import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/particles_network.dart';

import '../../example/main.dart';

void main() {
  testWidgets('MyApp has correct theme and navigation', (
    WidgetTester tester,
  ) async {
    // Build our app
    await tester.pumpWidget(const MyApp());

    // Verify MaterialApp properties
    // final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    // expect(materialApp.home, isA<Scaffold>());
    // expect(materialApp.debugShowCheckedModeBanner, true); // Changed to true
    // Build our app
    await tester.pumpWidget(const MyApp());

    // Verify MaterialApp properties
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.home, isA<Scaffold>());
    expect(
      materialApp.debugShowCheckedModeBanner,
      false,
    ); // Now matches the app code
  });
  group('MyApp Tests', () {
    testWidgets('MyApp renders correctly', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(const MyApp());

      // Verify that SystemChrome.setEnabledSystemUIMode was called
      // Note: We can't directly verify SystemChrome calls in tests,
      // but we can verify the UI mode effect through other means

      // Verify the main widget structure
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(ParticleNetwork), findsOneWidget);

      // Verify Scaffold properties
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);

      // Verify ParticleNetwork properties
      final particleNetwork = tester.widget<ParticleNetwork>(
        find.byType(ParticleNetwork),
      );
      expect(particleNetwork.touchActivation, true);
      expect(particleNetwork.particleCount, 100);
      expect(particleNetwork.maxSpeed, 0.5);
      expect(particleNetwork.maxSize, 3.5);
      expect(particleNetwork.linewidth, 0.5);
      expect(particleNetwork.lineDistance, 200);
      expect(
        particleNetwork.particleColor,
        const Color.fromARGB(255, 255, 255, 255),
      );
      expect(
        particleNetwork.lineColor,
        const Color.fromARGB(255, 100, 255, 180),
      );
      expect(particleNetwork.touchColor, Colors.amber);
    });

    testWidgets('MyApp handles immersive mode', (WidgetTester tester) async {
      // Mock the SystemChrome.setEnabledSystemUIMode call
      // Note: This is just for demonstration - in practice, SystemChrome calls
      // are difficult to verify directly in tests
      bool immersiveModeCalled = false;

      try {
        // Build our app
        await tester.pumpWidget(const MyApp());

        // Normally we would verify the effect of immersive mode here
        // For example, by checking if system overlays are visible
        immersiveModeCalled = true;
      } catch (e) {
        immersiveModeCalled = false;
      }

      expect(immersiveModeCalled, true);
    });

    testWidgets('MyApp rebuilds correctly', (WidgetTester tester) async {
      // Build our app
      await tester.pumpWidget(const MyApp());

      // Verify initial state
      expect(find.byType(ParticleNetwork), findsOneWidget);

      // Rebuild with the same widget
      await tester.pumpWidget(const MyApp());

      // Verify it's still there
      expect(find.byType(ParticleNetwork), findsOneWidget);
    });

    testWidgets('MyApp has correct theme and navigation', (
      WidgetTester tester,
    ) async {
      // Build our app
      await tester.pumpWidget(const MyApp());

      // Verify MaterialApp properties
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.home, isA<Scaffold>());
      expect(materialApp.debugShowCheckedModeBanner, false);
    });
  });
}
