import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:particles_network/particles_network.dart';

void main() {
  group('1.9.6 Backward Compatibility Tests', () {
    test('ParticleNetwork compiles and initializes with all 1.9.6 constructor parameters', () {
      const widget = ParticleNetwork(
        particleCount: 80,
        maxSpeed: 0.6,
        maxSize: 2.0,
        lineWidth: 1.0,
        lineDistance: 120.0,
        particleColor: Colors.blue,
        lineColor: Colors.green,
        touchColor: Colors.yellow,
        touchActivation: true,
        isComplex: true,
        fill: false,
        drawNetwork: true,
        gravityType: GravityType.point,
        gravityStrength: 0.2,
        gravityDirection: Offset(1, 0),
        gravityCenter: Offset(50, 50),
        hoverEffect: true,
        touchFeatures: TouchFeatures(
          pullForce: 0.5,
          decayRate: 0.3,
          maxTouchSpeed: 6.0,
          damping: 0.95,
          lineDistance: 110.0,
        ),
        maxConnectionsPerParticle: 4,
        adaptiveDensity: true,
        fastLineRendering: true,
        useVerticesRendering: true,
        enableAdaptivePerformance: true,
      );

      // Verify legacy getters
      expect(widget.particleCount, equals(80));
      expect(widget.maxSpeed, equals(0.6));
      expect(widget.maxSize, equals(2.0));
      expect(widget.lineWidth, equals(1.0));
      expect(widget.lineDistance, equals(120.0));
      expect(widget.particleColor, equals(Colors.blue));
      expect(widget.lineColor, equals(Colors.green));
      expect(widget.touchColor, equals(Colors.yellow));
      expect(widget.touchActivation, isTrue);
      expect(widget.isComplex, isTrue);
      expect(widget.fill, isFalse);
      expect(widget.drawNetwork, isTrue);
      expect(widget.gravityType, equals(GravityType.point));
      expect(widget.gravityStrength, equals(0.2));
      expect(widget.gravityDirection, equals(const Offset(1, 0)));
      expect(widget.gravityCenter, equals(const Offset(50, 50)));
      expect(widget.hoverEffect, isTrue);
      expect(widget.maxConnectionsPerParticle, equals(4));
      expect(widget.adaptiveDensity, isTrue);
      expect(widget.fastLineRendering, isTrue);
      expect(widget.useVerticesRendering, isTrue);
      expect(widget.enableAdaptivePerformance, isTrue);

      // Verify legacy parameter tracking
      expect(widget.usedLegacyParticles, isTrue);
      expect(widget.usedLegacyNetworkParams, isTrue);
      expect(widget.usedLegacyGravity, isTrue);
      expect(widget.usedLegacyIsComplex, isTrue);
      expect(widget.usedLegacyHoverEffect, isTrue);
      expect(widget.usedLegacyMaxConnections, isTrue);
      expect(widget.usedLegacyAdaptiveDensity, isTrue);
      expect(widget.usedLegacyFastLineRendering, isTrue);
      expect(widget.usedLegacyAdaptivePerformance, isTrue);

      // Verify folding into effective modern configuration objects
      expect(widget.effectivePerformance.maxConnectionsPerParticle, equals(4));
      expect(widget.effectivePerformance.complex.enabled, isTrue);
      expect(widget.effectivePerformance.autoBoost, isTrue);
      expect(widget.effectiveNetworkFeatures.renderer, equals(LineRenderer.vertices));
      expect(widget.effectiveNetworkFeatures.width, equals(1.0));
      expect(widget.effectiveNetworkFeatures.distance, equals(120.0));
      expect(widget.effectiveNetworkFeatures.color, equals(Colors.green));
      expect(widget.effectiveNetworkFeatures.enabled, isTrue);
    });

    test('fastLineRendering: false resolves renderer to LineRenderer.stroke', () {
      const widget = ParticleNetwork(
        fastLineRendering: false,
      );

      expect(widget.fastLineRendering, isFalse);
      expect(widget.useVerticesRendering, isFalse);
      expect(widget.effectiveNetworkFeatures.renderer, equals(LineRenderer.stroke));
    });

    test('TouchFeatures defaults to TouchType.pull for 100% 1.9.6 behavior parity', () {
      const touch = TouchFeatures();
      expect(touch.type, equals(TouchType.pull));
      expect(touch.enabled, isTrue);
      expect(touch.force, equals(0.42));
      expect(touch.pullForce, equals(0.42));
      expect(touch.speed, equals(0.42));
      expect(touch.decayRate, equals(0.42));
      expect(touch.maxSpeed, equals(5.5));
      expect(touch.maxTouchSpeed, equals(5.5));
      expect(touch.damping, equals(0.985));
      expect(touch.hover, isFalse);
      expect(touch.hoverEffect, isFalse);
    });

    test('NetworkFeatures compatibility aliases and getters work as expected', () {
      const network = NetworkFeatures(
        drawNetwork: true,
        lineWidth: 1.2,
        lineDistance: 130.0,
        lineColor: Colors.purple,
        lineRenderer: LineRenderer.vertices,
      );

      expect(network.drawNetwork, isTrue);
      expect(network.enabled, isTrue);
      expect(network.lineWidth, equals(1.2));
      expect(network.width, equals(1.2));
      expect(network.lineDistance, equals(130.0));
      expect(network.distance, equals(130.0));
      expect(network.lineColor, equals(Colors.purple));
      expect(network.color, equals(Colors.purple));
      expect(network.lineRenderer, equals(LineRenderer.vertices));
      expect(network.renderer, equals(LineRenderer.vertices));

      final copied = network.copyWith(
        lineWidth: 2.0,
        lineDistance: 90.0,
        lineRenderer: LineRenderer.stroke,
      );
      expect(copied.lineWidth, equals(2.0));
      expect(copied.lineDistance, equals(90.0));
      expect(copied.lineRenderer, equals(LineRenderer.stroke));
    });

    test('GravityConfig backward compatibility defaults', () {
      const config = GravityConfig();

      expect(config.type, equals(GravityType.none));
      expect(config.strength, equals(0.5)); // Verified default 0.5 in 1.9.6
      expect(config.direction, equals(const Offset(0, 1)));
      expect(config.center, equals(Offset.zero)); // Verified non-nullable Offset.zero
      expect(config, isA<GravityFeatures>());

      // Verify copyWith returns GravityConfig
      final copied = config.copyWith(strength: 0.8);
      expect(copied, isA<GravityConfig>());
      expect(copied.strength, equals(0.8));
      expect(copied.center, equals(Offset.zero));
    });

    test('TouchFeatures parameter precedence and copyWith', () {
      // Canonical parameter takes precedence over deprecated alias
      const touch1 = TouchFeatures(
        enabled: false,
        touchActivation: true,
        speed: 0.25,
        decayRate: 0.75,
        force: 0.35,
        pullForce: 0.85,
        maxSpeed: 7.0,
        maxTouchSpeed: 3.0,
        distance: 150.0,
        lineDistance: 80.0,
        hover: true,
        hoverEffect: false,
      );

      expect(touch1.enabled, isFalse);
      expect(touch1.touchActivation, isFalse);
      expect(touch1.speed, equals(0.25));
      expect(touch1.decayRate, equals(0.25));
      expect(touch1.force, equals(0.35));
      expect(touch1.pullForce, equals(0.35));
      expect(touch1.maxSpeed, equals(7.0));
      expect(touch1.maxTouchSpeed, equals(7.0));
      expect(touch1.distance, equals(150.0));
      expect(touch1.lineDistance, equals(150.0));
      expect(touch1.hover, isTrue);
      expect(touch1.hoverEffect, isTrue);

      // copyWith maintains precedence
      final copied = touch1.copyWith(
        enabled: true,
        touchActivation: false,
        speed: 0.5,
        decayRate: 0.9,
      );
      expect(copied.enabled, isTrue);
      expect(copied.speed, equals(0.5));
    });

    test('ParticleNetwork.touchFeatures returns effectiveTouchFeatures with legacy overrides', () {
      const widget = ParticleNetwork(
        touchActivation: false,
        touchColor: Colors.purple,
        hoverEffect: true,
      );

      expect(widget.touchFeatures.enabled, isFalse);
      expect(widget.touchFeatures.color, equals(Colors.purple));
      expect(widget.touchFeatures.hover, isTrue);
      expect(widget.effectiveTouchFeatures.enabled, isFalse);
      expect(widget.effectiveTouchFeatures.color, equals(Colors.purple));
      expect(widget.effectiveTouchFeatures.hover, isTrue);
    });

    test('Conflicting network parameters and legacy overrides precedence', () {
      // Modern network has stroke, legacy fastLineRendering: true overrides to vertices
      const widget1 = ParticleNetwork(
        network: NetworkFeatures(renderer: LineRenderer.stroke),
        fastLineRendering: true,
      );
      expect(widget1.effectiveNetworkFeatures.renderer, equals(LineRenderer.vertices));
      expect(widget1.fastLineRendering, isTrue);

      // Modern network has vertices, legacy fastLineRendering: false overrides to stroke
      const widget2 = ParticleNetwork(
        network: NetworkFeatures(renderer: LineRenderer.vertices),
        fastLineRendering: false,
      );
      expect(widget2.effectiveNetworkFeatures.renderer, equals(LineRenderer.stroke));
      expect(widget2.fastLineRendering, isFalse);
    });

    test('AdaptivePerformanceController backward compatibility signatures and methods', () {
      final controller = AdaptivePerformanceController();

      expect(controller.targetFrameTimeMs, equals(16.67));
      expect(controller.minScale, equals(0.4));
      expect(controller.maxScale, equals(1.0));
      expect(controller.currentScale, equals(1.0));
      expect(controller.scaleFactor, equals(1.0));

      expect(controller.getAdjustedLineDistance(100.0), equals(100.0));
      expect(controller.getAdjustedMaxConnections(10), equals(10));

      // Test zero-argument reset() from 1.9.6
      controller.reset();
      expect(controller.currentScale, equals(1.0));

      // Test reset(targetFrameTimeMs: ...) from 1.9.7
      controller.reset(targetFrameTimeMs: 8.33);
      expect(controller.targetFrameTimeMs, equals(8.33));

      expect(controller.monitor, isNotNull);
    });

    test('Legacy spatial data structures are exported and functional', () {
      // SpatialGrid
      final grid = SpatialGrid(cellSize: 50.0);
      expect(grid.cellSize, equals(50.0));
      grid.updateCellSize(60.0);
      expect(grid.cellSize, equals(60.0));

      // AdaptiveQuadTreeManager
      final manager = AdaptiveQuadTreeManager(rebuildInterval: 3);
      expect(manager.rebuildInterval, equals(3));
      expect(manager.shouldRebuild(), isTrue);

      // Quadrant enum
      expect(Quadrant.values.length, equals(4));

      // CompressedPath
      const path = CompressedPath([Quadrant.northWest], 1);
      expect(path.path, equals([Quadrant.northWest]));
      expect(path.depth, equals(1));
      final extended = path.extend(Quadrant.southEast);
      expect(extended.depth, equals(2));

      // CompressedQuadTreeNode
      final node = CompressedQuadTreeNode(const Rectangle(0, 0, 100, 100));
      expect(node.isLeaf, isTrue);

      // CompressedQuadTree and root accessor
      final tree = CompressedQuadTree(const Rectangle(0, 0, 100, 100));
      expect(tree.boundary.width, equals(100));
      expect(tree.root, isNotNull);
      expect(tree.root.boundary.width, equals(100));
    });

    testWidgets('ParticleNetwork renders without errors using purely 1.9.6 constructor', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ParticleNetwork(
              particleCount: 20,
              maxSpeed: 0.5,
              maxSize: 1.5,
              lineWidth: 0.8,
              lineDistance: 100,
              particleColor: Colors.white,
              lineColor: Colors.cyan,
              touchActivation: true,
              touchColor: Colors.amber,
              isComplex: false,
              fill: true,
              drawNetwork: true,
              maxConnectionsPerParticle: 3,
              adaptiveDensity: false,
              fastLineRendering: true,
              enableAdaptivePerformance: false,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(ParticleNetwork), findsOneWidget);
    });
  });
}
