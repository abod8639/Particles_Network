import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/particles_network.dart';
import 'package:example/main.dart';

void main() {
  testWidgets('ExampleApp smoke test renders ParticleExamplesScreen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(ParticleExamplesScreen), findsOneWidget);
    expect(find.byType(ParticleNetwork), findsOneWidget);
    expect(find.byType(CosmicWebExample), findsOneWidget);
  });

  testWidgets(
    'Direct ParticleNetwork examples can be switched via ChoiceChips',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Cosmic Web'), findsOneWidget);
      expect(find.text('Cyberpunk Matrix'), findsOneWidget);
      expect(find.text('Black Hole'), findsOneWidget);

      // Tap and switch to Cyberpunk Matrix example
      await tester.tap(find.text('Cyberpunk Matrix'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CyberpunkMatrixExample), findsOneWidget);
      expect(find.byType(ParticleNetwork), findsOneWidget);

      // Tap and switch to Black Hole example
      await tester.tap(find.text('Black Hole'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(BlackHoleExample), findsOneWidget);
      expect(find.byType(ParticleNetwork), findsOneWidget);

      // Tap and switch to Supernova example
      await tester.tap(find.text('Supernova'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SupernovaExample), findsOneWidget);
      expect(find.byType(ParticleNetwork), findsOneWidget);
    },
  );

  testWidgets(
    'Responsive layout renders cleanly without overflow on compact screen',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MyApp());
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ParticleExamplesScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
