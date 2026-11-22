import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

      expect(net.drawNetwork, isTrue);
      expect(net.drawnetwork, isTrue);
      expect(net.lineWidth, equals(0.5));
      expect(net.linewidth, equals(0.5));
      expect(net.lineDistance, equals(100.0));
      expect(net.lineColor, equals(const Color.fromARGB(255, 100, 255, 180)));
      expect(net.lineRenderer, equals(LineRenderer.vertices));
    });

    test('custom values are correctly assigned', () {
      const net = NetworkFeatures(
        drawNetwork: false,
        lineWidth: 1.8,
        lineDistance: 150.0,
        lineColor: Colors.deepPurple,
        lineRenderer: LineRenderer.stroke,
      );

      expect(net.drawNetwork, isFalse);
      expect(net.lineWidth, equals(1.8));
      expect(net.lineDistance, equals(150.0));
      expect(net.lineColor, equals(Colors.deepPurple));
      expect(net.lineRenderer, equals(LineRenderer.stroke));
    });

    test('deprecated aliases (drawnetwork, linewidth) correctly populate fields', () {
      // ignore: deprecated_member_use_from_same_package
      const net = NetworkFeatures(
        drawnetwork: false,
        linewidth: 2.5,
      );

      expect(net.drawNetwork, isFalse);
      expect(net.lineWidth, equals(2.5));
    });

    test('copyWith updates specified properties while retaining others', () {
      const base = NetworkFeatures(
        lineWidth: 1.0,
        lineDistance: 80.0,
        lineColor: Colors.cyan,
      );

      final updated = base.copyWith(
        lineWidth: 2.0,
        lineRenderer: LineRenderer.stroke,
      );

      expect(updated.lineWidth, equals(2.0));
      expect(updated.lineDistance, equals(80.0));
      expect(updated.lineColor, equals(Colors.cyan));
      expect(updated.drawNetwork, isTrue);
      expect(updated.lineRenderer, equals(LineRenderer.stroke));
    });

    test('operator == and hashCode differentiate by each property', () {
      const n1 = NetworkFeatures(
        drawNetwork: true,
        lineWidth: 1.0,
        lineDistance: 80.0,
        lineColor: Colors.blue,
        lineRenderer: LineRenderer.vertices,
      );
      const n2 = NetworkFeatures(
        drawNetwork: true,
        lineWidth: 1.0,
        lineDistance: 80.0,
        lineColor: Colors.blue,
        lineRenderer: LineRenderer.vertices,
      );
      const nDifferentRenderer = NetworkFeatures(
        drawNetwork: true,
        lineWidth: 1.0,
        lineDistance: 80.0,
        lineColor: Colors.blue,
        lineRenderer: LineRenderer.stroke,
      );
      const nDifferentWidth = NetworkFeatures(
        drawNetwork: true,
        lineWidth: 2.0,
        lineDistance: 80.0,
        lineColor: Colors.blue,
        lineRenderer: LineRenderer.vertices,
      );

      expect(n1, equals(n2));
      expect(n1.hashCode, equals(n2.hashCode));
      expect(n1, isNot(equals(nDifferentRenderer)));
      expect(n1, isNot(equals(nDifferentWidth)));
    });

    test('toString formats a readable representation including lineRenderer', () {
      const net = NetworkFeatures(
        lineWidth: 1.2,
        lineDistance: 90.0,
        lineRenderer: LineRenderer.stroke,
      );

      final str = net.toString();
      expect(str, contains('NetworkFeatures'));
      expect(str, contains('lineWidth: 1.2'));
      expect(str, contains('lineDistance: 90.0'));
      expect(str, contains('lineRenderer: LineRenderer.stroke'));
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
                  drawNetwork: true,
                  lineWidth: 1.5,
                  lineDistance: 120.0,
                  lineColor: Colors.amber,
                  lineRenderer: LineRenderer.stroke,
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
                  lineWidth: 1.0,
                  lineDistance: 80.0,
                  lineRenderer: LineRenderer.vertices,
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
                  lineWidth: 3.0,
                  lineDistance: 130.0,
                  lineRenderer: LineRenderer.stroke,
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
