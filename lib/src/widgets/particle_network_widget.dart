/// ParticleNetwork widget and state implementation.
library;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:particles_network/src/core/particle.dart';
import 'package:particles_network/src/factory/particle_factory.dart';
import 'package:particles_network/src/interaction/touch_features.dart';
import 'package:particles_network/src/physics/gravity_config.dart';
import 'package:particles_network/src/physics/particle_controller.dart';
import 'package:particles_network/src/rendering/object_pool.dart';
import 'package:particles_network/src/rendering/optimized_network_painter.dart';
import 'package:particles_network/src/rendering/performance_utils.dart';
import 'package:particles_network/src/simulation/particle_simulation.dart';

/// A Flutter widget that renders an interactive particle network visualization.
class ParticleNetwork extends StatefulWidget {
  /// Total number of particles in the visualization [default: 60].
  final int particleCount;

  /// Maximum speed of particles in pixels per frame [default: 0.5].
  final double maxSpeed;

  /// Maximum radius of particles in pixels [default: 1.5].
  final double maxSize;

  /// Stroke width of connection lines in pixels [default: 0.5].
  final double lineWidth;

  /// Maximum connection distance between particles in pixels [default: 100].
  final double lineDistance;

  /// Base color of all particles [default: Colors.white].
  final Color particleColor;

  /// Color of connection lines between particles.
  final Color lineColor;

  /// Highlight color for touch interactions [default: Colors.amber].
  final Color touchColor;

  /// Whether touch interactions are enabled [default: true].
  final bool touchActivation;

  /// Whether the painting logic is complex [default: false].
  final bool isComplex;

  /// Whether to fill particles (true) or stroke them (false) [default: true].
  final bool fill;

  /// Whether to draw connecting lines between particles [default: true].
  final bool drawNetwork;

  /// The type of gravity effect to apply [default: GravityType.none].
  final GravityType gravityType;

  /// The strength of the applied gravity force [default: 0.1].
  final double gravityStrength;

  /// The direction vector for global gravity [default: Offset(0, 1) - downwards].
  final Offset gravityDirection;

  /// The center point for point-based gravity effects.
  final Offset? gravityCenter;

  /// Whether hover effects are enabled.
  final bool? hoverEffect;

  /// Advanced touch interaction features and physics configuration.
  final TouchFeatures touchFeatures;

  /// Maximum number of connection lines a single particle can emit.
  ///
  /// Setting this bounds the total connection count to O(N) instead of O(N^2),
  /// dramatically improving performance for large particle counts.
  final int? maxConnectionsPerParticle;

  /// Whether to automatically scale down connection distance in dense networks.
  final bool adaptiveDensity;

  /// Whether to use ultra-fast single draw-call line rendering.
  final bool fastLineRendering;

  /// Compatibility alias for [fastLineRendering].
  bool get useVerticesRendering => fastLineRendering;

  /// Whether to dynamically monitor frame rate and adapt quality to maintain 60 FPS.
  final bool enableAdaptivePerformance;

  /// Creates a [ParticleNetwork] widget with customizable visualization parameters.
  const ParticleNetwork({
    super.key,
    this.particleCount = 60,
    this.maxSpeed = 0.5,
    this.maxSize = 1.5,
    this.lineWidth = 0.5,
    this.lineDistance = 100,
    this.particleColor = Colors.white,
    this.lineColor = const Color.fromARGB(255, 100, 255, 180),
    this.touchColor = Colors.amber,
    this.touchActivation = true,
    this.isComplex = false,
    this.fill = true,
    this.drawNetwork = true,
    this.gravityType = GravityType.none,
    this.gravityStrength = 0.1,
    this.gravityDirection = const Offset(0, 1),
    this.gravityCenter,
    this.hoverEffect = false,
    this.touchFeatures = const TouchFeatures(),
    this.maxConnectionsPerParticle,
    this.adaptiveDensity = false,
    bool? fastLineRendering,
    bool? useVerticesRendering,
    this.enableAdaptivePerformance = false,
  }) : fastLineRendering =
            fastLineRendering ?? useVerticesRendering ?? false;

  @override
  State<ParticleNetwork> createState() => ParticleNetworkState();
}

/// The stateful logic and animation controller for the [ParticleNetwork] widget.
class ParticleNetworkState extends State<ParticleNetwork>
    with SingleTickerProviderStateMixin {
  /// Underlying simulation decoupled from widget rendering.
  late final ParticleSimulation simulation;

  /// Exposes particles list for compatibility.
  List<Particle> get particles => simulation.particles;

  late final Ticker ticker;
  Offset touchPoint = Offset.infinite;
  Size get currentSize => simulation.currentSize;

  final ValueNotifier<int> frameNotifier = ValueNotifier<int>(0);

  // Injected or default implementations:
  IParticleFactory get factory => simulation.factory;
  set factory(IParticleFactory f) => simulation.factory = f;

  IParticleController get controller => simulation.controller;

  late final AdaptivePerformanceController _adaptiveController;
  int _lastFrameMicros = 0;

  late OptimizedNetworkPainter _painter;

  GravityConfig _buildGravityConfig(Size size) {
    return GravityConfig(
      type: widget.gravityType,
      strength: widget.gravityStrength,
      direction: widget.gravityDirection,
      center: widget.gravityCenter ??
          Offset(size.width / 2, size.height / 2),
    );
  }

  void _initPainter() {
    _painter = OptimizedNetworkPainter(
      drawNetwork: widget.drawNetwork,
      fill: widget.fill,
      isComplex: widget.isComplex,
      lineWidth: widget.lineWidth,
      particleCount: widget.particleCount,
      touchActivation: widget.touchActivation,
      particles: simulation.particles,
      touchPoint: touchPoint,
      lineDistance: widget.lineDistance,
      particleColor: widget.particleColor,
      lineColor: widget.lineColor,
      touchColor: widget.touchColor,
      touchFeatures: widget.touchFeatures,
      maxConnectionsPerParticle: widget.maxConnectionsPerParticle,
      adaptiveDensity: widget.adaptiveDensity,
      fastLineRendering: widget.fastLineRendering,
      repaint: frameNotifier,
    );
  }

  void _updateTouchPoint(Offset point) {
    touchPoint = point;
    _painter.updateTouchPoint(point);
  }

  @override
  void initState() {
    super.initState();

    _adaptiveController = AdaptivePerformanceController();

    simulation = ParticleSimulation(
      particleCount: widget.particleCount,
      maxSpeed: widget.maxSpeed,
      maxSize: widget.maxSize,
      particleColor: widget.particleColor,
      gravityConfig: _buildGravityConfig(Size.zero),
    );

    _initPainter();

    ticker = createTicker((elapsed) {
      final int now = elapsed.inMicroseconds;
      if (widget.enableAdaptivePerformance) {
        if (_lastFrameMicros != 0) {
          final int deltaUs = now - _lastFrameMicros;
          if (deltaUs > 0) {
            _adaptiveController.recordFrameTime(Duration(microseconds: deltaUs));
            final double adjustedDist =
                _adaptiveController.getAdjustedLineDistance(widget.lineDistance);
            if (adjustedDist != _painter.lineDistance) {
              _painter.updateLineDistance(adjustedDist);
            }
            if (widget.maxConnectionsPerParticle != null) {
              final int adjustedConn = _adaptiveController
                  .getAdjustedMaxConnections(widget.maxConnectionsPerParticle!);
              if (adjustedConn != _painter.maxConnectionsPerParticle) {
                _painter.maxConnectionsPerParticle = adjustedConn;
              }
            }
          }
        }
      }
      _lastFrameMicros = now;
      simulation.step();
      frameNotifier.value = now;
    })..start();
  }

  @override
  void didUpdateWidget(ParticleNetwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool factoryChanged = false;
    if (widget.maxSpeed != oldWidget.maxSpeed ||
        widget.maxSize != oldWidget.maxSize ||
        widget.particleColor != oldWidget.particleColor) {
      simulation.updateFactory(
        maxSpeed: widget.maxSpeed,
        maxSize: widget.maxSize,
        color: widget.particleColor,
      );
      factoryChanged = true;
    }

    if (widget.particleCount != oldWidget.particleCount || factoryChanged) {
      simulation.updateParticleCount(widget.particleCount);
    }

    if (widget.gravityType != oldWidget.gravityType ||
        widget.gravityStrength != oldWidget.gravityStrength ||
        widget.gravityDirection != oldWidget.gravityDirection ||
        widget.gravityCenter != oldWidget.gravityCenter) {
      simulation.updateGravity(_buildGravityConfig(currentSize));
    }

    // Targeted painter updates
    if (widget.particleColor != oldWidget.particleColor ||
        widget.lineColor != oldWidget.lineColor ||
        widget.touchColor != oldWidget.touchColor) {
      _painter.updateColors(
        particleColor: widget.particleColor,
        lineColor: widget.lineColor,
        touchColor: widget.touchColor,
      );
    }

    if (widget.lineWidth != oldWidget.lineWidth) {
      _painter.updateLineWidth(widget.lineWidth);
    }

    if (widget.lineDistance != oldWidget.lineDistance) {
      _painter.updateLineDistance(widget.lineDistance);
    }

    if (widget.drawNetwork != oldWidget.drawNetwork ||
        widget.fill != oldWidget.fill ||
        widget.isComplex != oldWidget.isComplex ||
        widget.touchActivation != oldWidget.touchActivation) {
      _painter.updateRenderFlags(
        drawNetwork: widget.drawNetwork,
        fill: widget.fill,
        isComplex: widget.isComplex,
        touchActivation: widget.touchActivation,
      );
    }

    if (widget.touchFeatures != oldWidget.touchFeatures) {
      _painter.updateTouchFeatures(widget.touchFeatures);
    }

    if (widget.maxConnectionsPerParticle !=
            oldWidget.maxConnectionsPerParticle ||
        widget.adaptiveDensity != oldWidget.adaptiveDensity ||
        widget.fastLineRendering != oldWidget.fastLineRendering) {
      _painter.updatePerformanceOptions(
        maxConnectionsPerParticle: widget.maxConnectionsPerParticle,
        adaptiveDensity: widget.adaptiveDensity,
        fastLineRendering: widget.fastLineRendering,
      );
    }
  }

  void _generateParticles(Size size) {
    if (size != currentSize) {
      simulation.updateGravity(_buildGravityConfig(size));
      simulation.updateSize(size);
    }
  }

  @override
  void dispose() {
    ticker.dispose();
    frameNotifier.dispose();
    _adaptiveController.reset();
    PoolManager.getInstance().clearAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hover = widget.hoverEffect ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        _generateParticles(constraints.biggest);

        return MouseRegion(
          onHover: hover ? (event) => _updateTouchPoint(event.localPosition) : null,
          onExit: hover ? (_) => _updateTouchPoint(Offset.infinite) : null,
          child: GestureDetector(
            onPanDown: (d) => _updateTouchPoint(d.localPosition),
            onPanUpdate: (d) => _updateTouchPoint(d.localPosition),
            onPanEnd: (_) => _updateTouchPoint(Offset.infinite),
            onPanCancel: () => _updateTouchPoint(Offset.infinite),
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _painter,
                isComplex: widget.isComplex,
                willChange: true,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        );
      },
    );
  }
}
