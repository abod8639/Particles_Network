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

      final updated = base.copyWith(width: 2.0, renderer: LineRenderer.stroke);

      expect(updated.width, equals(2.0));
      expect(updated.distance, equals(80.0));
      expect(updated.color, equals(Colors.cyan));
      expect(updated.enabled, isTrue);
      expect(updated.renderer, equals(LineRenderer.stroke));
    });

    test(
      'legacy compatibility getters map correctly to canonical properties',
      () {
        const net = NetworkFeatures(
          enabled: false,
          width: 2.5,
          distance: 120.0,
          color: Colors.green,
          renderer: LineRenderer.stroke,
        );

        // ignore: deprecated_member_use_from_same_package
        expect(net.lineWidth, equals(net.width));
        // ignore: deprecated_member_use_from_same_package
        expect(net.lineWidth, equals(2.5));

        // ignore: deprecated_member_use_from_same_package
        expect(net.lineDistance, equals(net.distance));
        // ignore: deprecated_member_use_from_same_package
        expect(net.lineDistance, equals(120.0));

        // ignore: deprecated_member_use_from_same_package
        expect(net.lineColor, equals(net.color));
        // ignore: deprecated_member_use_from_same_package
        expect(net.lineColor, equals(Colors.green));

        // ignore: deprecated_member_use_from_same_package
        expect(net.drawNetwork, equals(net.enabled));
        // ignore: deprecated_member_use_from_same_package
        expect(net.drawNetwork, isFalse);

        // ignore: deprecated_member_use_from_same_package
        expect(net.lineRenderer, equals(net.renderer));
        // ignore: deprecated_member_use_from_same_package
        expect(net.lineRenderer, equals(LineRenderer.stroke));
      },
    );

    test(
      'copyWith precedence: canonical parameters take precedence over legacy aliases',
      () {
        const base = NetworkFeatures(
          enabled: true,
          width: 1.0,
          distance: 100.0,
          color: Colors.blue,
          renderer: LineRenderer.vertices,
        );

        // 1. renderer takes precedence over lineRenderer (L202-L203)
        // ignore: deprecated_member_use_from_same_package
        final withBothRenderers = base.copyWith(
          renderer: LineRenderer.stroke,
          lineRenderer: LineRenderer.vertices,
        );
        expect(withBothRenderers.renderer, equals(LineRenderer.stroke));
        // ignore: deprecated_member_use_from_same_package
        expect(withBothRenderers.lineRenderer, equals(LineRenderer.stroke));

        // 2. lineRenderer used when renderer is omitted
        // ignore: deprecated_member_use_from_same_package
        final withLegacyRendererOnly = base.copyWith(
          lineRenderer: LineRenderer.stroke,
        );
        expect(withLegacyRendererOnly.renderer, equals(LineRenderer.stroke));

        // 3. this.renderer preserved when neither renderer nor lineRenderer passed
        final withNoRenderer = withLegacyRendererOnly.copyWith(width: 3.0);
        expect(withNoRenderer.renderer, equals(LineRenderer.stroke));
        expect(withNoRenderer.width, equals(3.0));

        // 4. Precedence for all other aliases: enabled vs drawNetwork, width vs lineWidth, etc.
        // ignore: deprecated_member_use_from_same_package
        final fullPrecedence = base.copyWith(
          enabled: false,
          drawNetwork: true,
          width: 4.0,
          lineWidth: 1.5,
          distance: 200.0,
          lineDistance: 50.0,
          color: Colors.red,
          lineColor: Colors.yellow,
          renderer: LineRenderer.stroke,
          lineRenderer: LineRenderer.vertices,
        );
        expect(fullPrecedence.enabled, isFalse);
        expect(fullPrecedence.width, equals(4.0));
        expect(fullPrecedence.distance, equals(200.0));
        expect(fullPrecedence.color, equals(Colors.red));
        expect(fullPrecedence.renderer, equals(LineRenderer.stroke));

        // 5. Fallback to legacy alias when canonical is null
        // ignore: deprecated_member_use_from_same_package
        final legacyOnly = base.copyWith(
          drawNetwork: false,
          lineWidth: 3.5,
          lineDistance: 70.0,
          lineColor: Colors.teal,
          lineRenderer: LineRenderer.stroke,
        );
        expect(legacyOnly.enabled, isFalse);
        expect(legacyOnly.width, equals(3.5));
        expect(legacyOnly.distance, equals(70.0));
        expect(legacyOnly.color, equals(Colors.teal));
        expect(legacyOnly.renderer, equals(LineRenderer.stroke));
      },
    );

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

    test(
      'toString formats a readable representation including lineRenderer',
      () {
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
      },
    );
  });

  group(
    'NetworkFeatures ParticleNetwork Integration & Backward Compatibility',
    () {
      testWidgets(
        'ParticleNetwork passes canonical NetworkFeatures to painter',
        (WidgetTester tester) async {
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
        },
      );

      testWidgets(
        'legacy parameters on ParticleNetwork fold into effectiveNetworkFeatures',
        (WidgetTester tester) async {
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

          final widget = tester.widget<ParticleNetwork>(
            find.byType(ParticleNetwork),
          );
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

          final state = tester.state<ParticleNetworkState>(
            find.byType(ParticleNetwork),
          );
          expect(state.painter.lineWidth, equals(2.2));
          expect(state.painter.lineDistance, equals(75.0));
          expect(state.painter.lineColor, equals(Colors.redAccent));
          expect(state.painter.drawNetwork, isFalse);
        },
      );

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

        final state = tester.state<ParticleNetworkState>(
          find.byType(ParticleNetwork),
        );
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
    },
  );
}
