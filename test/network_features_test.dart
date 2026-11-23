import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:particles_network/particles_network.dart';
import 'package:particles_network/src/legacy/legacy_deprecation_logger.dart';

void main() {
  setUp(() {
    LegacyDeprecationLogger.resetWarned();
  });

  tearDown(() {
    LegacyDeprecationLogger.resetWarned();
  });

  group('NetworkFeatures Unit Tests', () {
    test('default constructor initializes canonical default values', () {
      const net = NetworkFeatures();

      expect(net.enabled, isTrue);
      expect(net.width, equals(0.5));
      expect(net.distance, equals(100.0));
      expect(net.color, equals(const Color.fromARGB(255, 100, 255, 180)));
      expect(net.renderer, equals(LineRenderer.vertices));
    });

    test('custom values are correctly assigned', () {
      const net = NetworkFeatures(
        enabled: false,
        width: 1.8,
        distance: 150.0,
        color: Colors.deepPurple,
        renderer: LineRenderer.stroke,
      );

      expect(net.enabled, isFalse);
      expect(net.width, equals(1.8));
      expect(net.distance, equals(150.0));
      expect(net.color, equals(Colors.deepPurple));
      expect(net.renderer, equals(LineRenderer.stroke));
    });

    test('copyWith updates specified properties while retaining others', () {
      const base = NetworkFeatures(
        width: 1.0,
        distance: 80.0,
        color: Colors.cyan,
      );

      final updated = base.copyWith(
        width: 2.0,
        renderer: LineRenderer.stroke,
      );

      expect(updated.width, equals(2.0));
      expect(updated.distance, equals(80.0));
      expect(updated.color, equals(Colors.cyan));
      expect(updated.enabled, isTrue);
      expect(updated.renderer, equals(LineRenderer.stroke));
    });

    test('operator == and hashCode differentiate by each property', () {
      const n1 = NetworkFeatures(
        enabled: true,
        width: 1.0,
        distance: 80.0,
        color: Colors.blue,
        renderer: LineRenderer.vertices,
      );
      const n2 = NetworkFeatures(
        enabled: true,
        width: 1.0,
        distance: 80.0,
        color: Colors.blue,
        renderer: LineRenderer.vertices,
      );
      const nDifferentRenderer = NetworkFeatures(
        enabled: true,
        width: 1.0,
        distance: 80.0,
        color: Colors.blue,
        renderer: LineRenderer.stroke,
      );
      const nDifferentWidth = NetworkFeatures(
        enabled: true,
        width: 2.0,
        distance: 80.0,
        color: Colors.blue,
        renderer: LineRenderer.vertices,
      );

      expect(n1, equals(n2));
      expect(n1.hashCode, equals(n2.hashCode));
      expect(n1, isNot(equals(nDifferentRenderer)));
      expect(n1, isNot(equals(nDifferentWidth)));
    });

    test('toString formats a readable representation including lineRenderer', () {
      const net = NetworkFeatures(
        width: 1.2,
        distance: 90.0,
        renderer: LineRenderer.stroke,
      );

      final str = net.toString();
      expect(str, contains('NetworkFeatures'));
      expect(str, contains('width: 1.2'));
      expect(str, contains('distance: 90.0'));
      expect(str, contains('renderer: LineRenderer.stroke'));
    });
  });

  group('NetworkFeatures ParticleNetwork Integration & Backward Compatibility', () {
    testWidgets('ParticleNetwork passes canonical NetworkFeatures to painter', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                network: NetworkFeatures(
                  enabled: true,
                  width: 1.5,
                  distance: 120.0,
                  color: Colors.amber,
                  renderer: LineRenderer.stroke,
                ),
              ),
            ),
          ),
        ),
      );

      final state = tester.state<ParticleNetworkState>(
        find.byType(ParticleNetwork),
      );

      expect(state.painter.lineWidth, equals(1.5));
      expect(state.painter.lineDistance, equals(120.0));
      expect(state.painter.lineColor, equals(Colors.amber));
      expect(state.painter.lineRenderer, equals(LineRenderer.stroke));
      expect(state.painter.drawNetwork, isTrue);
    });

    testWidgets('legacy parameters on ParticleNetwork fold into effectiveNetworkFeatures', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              // ignore: deprecated_member_use_from_same_package
              child: ParticleNetwork(
                lineWidth: 2.2,
                lineDistance: 75.0,
                lineColor: Colors.redAccent,
                drawNetwork: false,
              ),
            ),
          ),
        ),
      );

      final widget = tester.widget<ParticleNetwork>(find.byType(ParticleNetwork));
      expect(widget.effectiveLineWidth, equals(2.2));
      // ignore: deprecated_member_use_from_same_package
      expect(widget.lineWidth, equals(2.2));
      expect(widget.effectiveLineDistance, equals(75.0));
      // ignore: deprecated_member_use_from_same_package
      expect(widget.lineDistance, equals(75.0));
      expect(widget.effectiveLineColor, equals(Colors.redAccent));
      // ignore: deprecated_member_use_from_same_package
      expect(widget.lineColor, equals(Colors.redAccent));
      expect(widget.effectiveDrawNetwork, isFalse);
      // ignore: deprecated_member_use_from_same_package
      expect(widget.drawNetwork, isFalse);
      expect(widget.usedLegacyNetworkParams, isTrue);

      final state = tester.state<ParticleNetworkState>(find.byType(ParticleNetwork));
      expect(state.painter.lineWidth, equals(2.2));
      expect(state.painter.lineDistance, equals(75.0));
      expect(state.painter.lineColor, equals(Colors.redAccent));
      expect(state.painter.drawNetwork, isFalse);
    });

    testWidgets('updating NetworkFeatures at runtime updates painter', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                network: NetworkFeatures(
                  width: 1.0,
                  distance: 80.0,
                  renderer: LineRenderer.vertices,
                ),
              ),
            ),
          ),
        ),
      );

      final state = tester.state<ParticleNetworkState>(find.byType(ParticleNetwork));
      expect(state.painter.lineWidth, equals(1.0));
      expect(state.painter.lineRenderer, equals(LineRenderer.vertices));

      // Update widget with new NetworkFeatures
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleNetwork(
                network: NetworkFeatures(
                  width: 3.0,
                  distance: 130.0,
                  renderer: LineRenderer.stroke,
                ),
              ),
            ),
          ),
        ),
      );

      expect(state.painter.lineWidth, equals(3.0));
      expect(state.painter.lineDistance, equals(130.0));
      expect(state.painter.lineRenderer, equals(LineRenderer.stroke));
    });
  });
}
