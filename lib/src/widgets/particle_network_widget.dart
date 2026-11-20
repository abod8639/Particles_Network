/// ParticleNetwork widget and state implementation.
library;

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:particles_network/src/core/particle.dart';
import 'package:particles_network/src/factory/particle_factory.dart';
import 'package:particles_network/src/interaction/touch_features.dart';
import 'package:particles_network/src/legacy/legacy_deprecation_logger.dart';
import 'package:particles_network/src/physics/particle_controller.dart';
import 'package:particles_network/src/physics/particle_gravity.dart';
import 'package:particles_network/src/rendering/network_performance.dart';
import 'package:particles_network/src/rendering/optimized_network_painter.dart';
import 'package:particles_network/src/rendering/performance_utils.dart';
import 'package:particles_network/src/simulation/particle_simulation.dart';
import 'package:particles_network/src/spatial/sorted_spatial_grid.dart';

/// A Flutter widget that renders an interactive particle network visualization.
class ParticleNetwork extends StatefulWidget {
  /// Total number of particles in the visualization (default: 60).
  final int particleCount;

  /// Maximum speed of particles in pixels per frame (default: 0.5).
  final double maxSpeed;

  /// Maximum radius of particles in pixels (default: 1.5).
  final double maxSize;

  /// Stroke width of connection lines in pixels (default: 0.5).
  final double lineWidth;

  /// Maximum connection distance between particles in pixels (default: 100).
  final double lineDistance;

  /// Base color of all particles (default: Colors.white).
  final Color particleColor;

  /// Color of connection lines between particles.
  final Color lineColor;

  /// Explicitly provided legacy touch highlight color, if any.
  final Color? _touchColor;

  /// Highlight color for touch interactions (default: Colors.amber).
  ///
  /// Deprecated: Configure touch highlight color via [touchFeatures]
  /// using [TouchFeatures.color] instead. This parameter will be removed in particles_network 2.0.0.
  @Deprecated(
    'Use touchFeatures (TouchFeatures(color: ...)) instead. This parameter will be removed in particles_network 2.0.0.',
  )
  Color get touchColor => _touchColor ?? touchFeatures.color;

  /// Effective color used for touch highlight.
  Color get effectiveTouchColor => _touchColor ?? touchFeatures.color;

  /// Checks whether the deprecated [touchColor] parameter was explicitly configured.
  bool get usedLegacyTouchColor => _touchColor != null;

  /// Explicitly provided legacy touch activation flag, if any.
  final bool? _touchActivation;

  /// Whether touch interactions are enabled (default: true).
  ///
  /// Deprecated: Moved into [TouchFeatures] and renamed to [TouchFeatures.enabled].
  /// Use `touchFeatures: TouchFeatures(enabled: ...)` instead:
  /// ```dart
  /// ParticleNetwork(
  ///   touchFeatures: TouchFeatures(enabled: false),
  /// )
  /// ```
  /// This parameter will be removed in particles_network 2.0.0.
  @Deprecated(
    'touchActivation was moved to TouchFeatures and renamed to enabled. '
    'Use ParticleNetwork(touchFeatures: TouchFeatures(enabled: ...)) instead. '
    'This parameter will be removed in particles_network 2.0.0.',
  )
  bool get touchActivation => _touchActivation ?? touchFeatures.enabled;

  /// Effective flag used for touch activation.
  bool get effectiveTouchActivation =>
      _touchActivation ?? touchFeatures.enabled;

  /// Checks whether the deprecated [touchActivation] parameter was explicitly configured.
  bool get usedLegacyTouchActivation => _touchActivation != null;

  /// Explicitly provided legacy isComplex flag, if any.
  final bool? _isComplex;

  /// Whether the painting logic is complex (default: false).
  ///
  /// Deprecated: Configure complex rendering mode via [performance]
  /// using [NetworkPerformance.isComplex] instead. This parameter will be removed in particles_network 2.0.0.
  @Deprecated(
    'Use performance (NetworkPerformance(isComplex: ...)) instead. This parameter will be removed in particles_network 2.0.0.',
  )
  bool get isComplex => _isComplex ?? performance.isComplex;

  /// Effective flag used for complex rendering mode.
  bool get effectiveIsComplex => _isComplex ?? performance.isComplex;

  /// Checks whether the deprecated [isComplex] parameter was explicitly configured.
  bool get usedLegacyIsComplex => _isComplex != null;

  /// Effective touch features configuration merging legacy and modern parameters.
  TouchFeatures get effectiveTouchFeatures => touchFeatures.copyWith(
        color: _touchColor,
        enabled: _touchActivation,
      );

  /// Effective performance configuration merging legacy and modern parameters.
  NetworkPerformance get effectivePerformance => performance.copyWith(
        isComplex: _isComplex,
      );

  /// Whether to fill particles (true) or stroke them (false) (default: true).
  final bool fill;

  /// Whether to draw connecting lines between particles (default: true).
  final bool drawNetwork;

  /// Explicitly provided legacy drawnetwork flag, if any.
  final bool? _drawnetwork;

  /// Effective flag used for drawing connection lines.
  bool get effectiveDrawNetwork => _drawnetwork ?? drawNetwork;

  /// Checks whether the deprecated [drawnetwork] parameter was explicitly configured.
  bool get usedLegacyDrawnetwork => _drawnetwork != null;

  /// Explicitly provided legacy linewidth parameter, if any.
  final double? _linewidth;

  /// Effective connection line width.
  double get effectiveLineWidth => _linewidth ?? lineWidth;

  /// Checks whether the deprecated [linewidth] parameter was explicitly configured.
  bool get usedLegacyLinewidth => _linewidth != null;

  /// Custom particle factory (legacy support).
  ///
  /// Deprecated: Inject custom factories into [ParticleSimulation] directly.
  /// Scheduled for removal in particles_network 2.0.0.
  @Deprecated(
    'Use ParticleSimulation for custom particle creation. This parameter will be removed in particles_network 2.0.0.',
  )
  final IParticleFactory? particleFactory;

  /// Custom particle behavior controller (legacy support).
  ///
  /// Deprecated: Inject custom controllers into [ParticleSimulation] directly.
  /// Scheduled for removal in particles_network 2.0.0.
  @Deprecated(
    'Use ParticleSimulation for custom particle behavior. This parameter will be removed in particles_network 2.0.0.',
  )
  final IParticleController? particleController;

  /// Gravity configuration for the particle network.
  ///
  /// Controls global or point gravity effects.
  /// Prefer using this parameter over the deprecated individual gravity parameters.
  final ParticleGravity? gravity;

  /// The type of gravity effect to apply (default: [GravityType.none]).
  ///
  /// Deprecated: Use [gravity] with [ParticleGravity.gravityType] instead.
  /// This parameter will be removed in particles_network 2.0.0.
  @Deprecated(
    'Use gravity (ParticleGravity) instead. This parameter will be removed in particles_network 2.0.0.',
  )
  final GravityType gravityType;

  /// The strength of the applied gravity force (default: 0.1).
  ///
  /// Deprecated: Use [gravity] with [ParticleGravity.gravityStrength] instead.
  /// This parameter will be removed in particles_network 2.0.0.
  @Deprecated(
    'Use gravity (ParticleGravity) instead. This parameter will be removed in particles_network 2.0.0.',
  )
  final double gravityStrength;

  /// The direction vector for global gravity (default: `Offset(0, 1)` - downwards).
  ///
  /// Deprecated: Use [gravity] with [ParticleGravity.gravityDirection] instead.
  /// This parameter will be removed in particles_network 2.0.0.
  @Deprecated(
    'Use gravity (ParticleGravity) instead. This parameter will be removed in particles_network 2.0.0.',
  )
  final Offset gravityDirection;

  /// The center point for point-based gravity effects.
  ///
  /// Deprecated: Use [gravity] with [ParticleGravity.gravityCenter] instead.
  /// This parameter will be removed in particles_network 2.0.0.
  @Deprecated(
    'Use gravity (ParticleGravity) instead. This parameter will be removed in particles_network 2.0.0.',
  )
  final Offset? gravityCenter;

  /// Checks whether deprecated individual gravity parameters were configured.
  bool get usedLegacyGravity =>
      gravity == null &&
      (gravityType != GravityType.none ||
          gravityStrength != 0.1 ||
          gravityDirection != const Offset(0, 1) ||
          gravityCenter != null);

  /// Whether hover effects are enabled.
  final bool? hoverEffect;

  /// Advanced touch interaction features and physics configuration.
  final TouchFeatures touchFeatures;

  /// Advanced performance settings and rendering optimizations.
  final NetworkPerformance performance;

  /// Optional custom spatial grid for particle queries.
  /// If null, a default [SortedSpatialGrid] is used.
  final SortedSpatialGrid? spatialGrid;

  /// Creates a [ParticleNetwork] widget with customizable visualization parameters.
  const ParticleNetwork({
    super.key,
    this.particleCount = 60,
    this.maxSpeed = 0.5,
    this.maxSize = 1.5,
    this.lineWidth = 0.5,
    @Deprecated(
      'Use lineWidth instead. This parameter will be removed in particles_network 2.0.0.',
    )
    double? linewidth,
    this.lineDistance = 100,
    this.particleColor = const Color(0xFFFFFFFF),
    this.lineColor = const Color.fromARGB(255, 100, 255, 180),
    @Deprecated(
      'Use touchFeatures (TouchFeatures(color: ...)) instead. This parameter will be removed in particles_network 2.0.0.',
    )
    Color? touchColor,
    @Deprecated(
      'touchActivation was moved to TouchFeatures and renamed to enabled. '
      'Use ParticleNetwork(touchFeatures: TouchFeatures(enabled: ...)) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    bool? touchActivation,
    @Deprecated(
      'Use performance (NetworkPerformance(isComplex: ...)) instead. This parameter will be removed in particles_network 2.0.0.',
    )
    bool? isComplex,
    this.fill = true,
    this.drawNetwork = true,
    @Deprecated(
      'Use drawNetwork instead. This parameter will be removed in particles_network 2.0.0.',
    )
    bool? drawnetwork,
    @Deprecated(
      'Use ParticleSimulation for custom particle creation. This parameter will be removed in particles_network 2.0.0.',
    )
    this.particleFactory,
    @Deprecated(
      'Use ParticleSimulation for custom particle controllers. This parameter will be removed in particles_network 2.0.0.',
    )
    this.particleController,
    this.gravity,
    @Deprecated(
      'Use gravity (ParticleGravity) instead. This parameter will be removed in particles_network 2.0.0.',
    )
    this.gravityType = GravityType.none,
    @Deprecated(
      'Use gravity (ParticleGravity) instead. This parameter will be removed in particles_network 2.0.0.',
    )
    this.gravityStrength = 0.1,
    @Deprecated(
      'Use gravity (ParticleGravity) instead. This parameter will be removed in particles_network 2.0.0.',
    )
    this.gravityDirection = const Offset(0, 1),
    @Deprecated(
      'Use gravity (ParticleGravity) instead. This parameter will be removed in particles_network 2.0.0.',
    )
    this.gravityCenter,
    this.hoverEffect = false,
    this.touchFeatures = const TouchFeatures(),
    this.performance = const NetworkPerformance(),
    this.spatialGrid,
  })  : _touchColor = touchColor,
        _touchActivation = touchActivation,
        _isComplex = isComplex,
        _linewidth = linewidth,
        _drawnetwork = drawnetwork;

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

  /// Exposes the underlying [SortedSpatialGrid] used by simulation and painter.
  SortedSpatialGrid get spatialGrid => simulation.spatialGrid;

  /// Exposes the underlying painter.
  OptimizedNetworkPainter get painter => _painter;

  /// Exposes the adaptive performance controller.
  AdaptivePerformanceController get adaptiveController => _adaptiveController;

  /// Number of connection lines drawn in the most recent paint call.
  int get lastFrameLineCount => _painter.lastFrameLineCount;

  /// Connection radius actually used in the most recent paint call.
  double get lastFrameLineDistance => _painter.lastFrameLineDistance;

  /// Effective maximum connections allowed per particle in the current frame.
  int? get effectiveMaxConnections => _painter.effectiveMaxConnections;

  /// Effective maximum lines allowed per frame in the current frame.
  int? get effectiveMaxLines => _painter.effectiveMaxLines;

  late final Ticker ticker;
  Offset touchPoint = Offset.infinite;
  int? _activePointerId;
  Size get currentSize => simulation.currentSize;

  final ValueNotifier<int> frameNotifier = ValueNotifier<int>(0);

  // Injected or default implementations:
  IParticleFactory get factory => simulation.factory;
  set factory(IParticleFactory f) => simulation.factory = f;

  IParticleController get controller => simulation.controller;

  late AdaptivePerformanceController _adaptiveController;
  bool _timingsCallbackRegistered = false;
  int _lastFrameMicros = 0;

  /// Upper bound on a single simulation step, in 60 Hz reference frames.
  /// Prevents particles from jumping after a long hitch or app resume.
  static const double _maxTimeScale = 4.0;

  late OptimizedNetworkPainter _painter;

  ParticleGravity _buildGravityConfig(Size size) {
    if (widget.gravity != null) {
      final g = widget.gravity!;
      if (g.center == null && size != Size.zero) {
        return g.copyWith(center: Offset(size.width / 2, size.height / 2));
      }
      return g;
    }
    return ParticleGravity(
      type: widget.gravityType,
      strength: widget.gravityStrength,
      direction: widget.gravityDirection,
      center: widget.gravityCenter ?? Offset(size.width / 2, size.height / 2),
    );
  }

  void _initPainter() {
    final effectiveTouch = widget.effectiveTouchFeatures;
    final effectivePerf = widget.effectivePerformance;

    _painter = OptimizedNetworkPainter(
      drawNetwork: widget.effectiveDrawNetwork,
      fill: widget.fill,
      isComplex: effectivePerf.isComplex,
      lineWidth: widget.effectiveLineWidth,
      particleCount: widget.particleCount,
      touchActivation: effectiveTouch.enabled,
      particles: simulation.particles,
      spatialGrid: simulation.spatialGrid,
      touchPoint: touchPoint,
      lineDistance: widget.lineDistance,
      particleColor: widget.particleColor,
      lineColor: widget.lineColor,
      touchColor: effectiveTouch.color,
      touchFeatures: effectiveTouch,
      performance: effectivePerf,
      simulateTouchInPaint: false,
      repaint: frameNotifier,
    );
  }

  void _setAdaptiveTimings(bool enabled) {
    if (enabled == _timingsCallbackRegistered) return;
    if (enabled) {
      _adaptiveController.reset(targetFrameTimeMs: _displayFrameBudgetMs());
      SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
    } else {
      SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
      _painter.resetRuntimeOverrides();
      _adaptiveController.reset(targetFrameTimeMs: _displayFrameBudgetMs());
    }
    _timingsCallbackRegistered = enabled;
  }

  /// Feeds real frame cost into the adaptive controller and applies dual-tier
  /// dynamic budgeting and emergency capping overrides.
  void _onFrameTimings(List<FrameTiming> timings) {
    if (!mounted) return;
    for (final FrameTiming t in timings) {
      final double durationMs = math.max(
            t.buildDuration.inMicroseconds,
            t.rasterDuration.inMicroseconds,
          ) /
          1000.0;
      _adaptiveController.recordFrame(
        frameTimeMs: durationMs,
        visibleCount: _painter.visibleParticleCount,
      );
    }
    final int nextLines = _adaptiveController.dynamicLineBudget;
    if (nextLines != _painter.runtimeMaxLinesOverride) {
      _painter.setDynamicLineBudget(nextLines);
    }
    final int? nextConn = _adaptiveController.emergencyMaxConnections;
    if (nextConn != _painter.runtimeMaxConnectionsOverride) {
      _painter.setEmergencyMaxConnections(nextConn);
    }
  }

  double _displayFrameBudgetMs() {
    final double rawRate = WidgetsBinding
            .instance.platformDispatcher.implicitView?.display.refreshRate ??
        60.0;
    final double safeRate =
        (rawRate >= 30.0 && rawRate <= 240.0) ? rawRate : 60.0;
    return 1000.0 / safeRate;
  }

  void _updateTouchPoint(Offset point) {
    touchPoint = point;
    _painter.updateTouchPoint(point);
  }

  @override
  void initState() {
    super.initState();

    if (kDebugMode) {
      if (widget.usedLegacyGravity) {
        LegacyDeprecationLogger.warn(
          deprecatedApi:
              'ParticleNetwork(gravityType, gravityStrength, gravityDirection, gravityCenter)',
          replacement: 'ParticleNetwork(gravity: ParticleGravity(...))',
        );
      }
      if (widget.usedLegacyTouchColor) {
        LegacyDeprecationLogger.warn(
          deprecatedApi: 'ParticleNetwork(touchColor)',
          replacement:
              'ParticleNetwork(touchFeatures: TouchFeatures(color: ...))',
        );
      }
      if (widget.usedLegacyTouchActivation) {
        LegacyDeprecationLogger.warn(
          deprecatedApi: 'ParticleNetwork(touchActivation)',
          replacement:
              'ParticleNetwork(touchFeatures: TouchFeatures(enabled: ...)) (touchActivation was moved to TouchFeatures and renamed to enabled)',
        );
      }
      if (widget.usedLegacyIsComplex) {
        LegacyDeprecationLogger.warn(
          deprecatedApi: 'ParticleNetwork(isComplex)',
          replacement:
              'ParticleNetwork(performance: NetworkPerformance(isComplex: ...))',
        );
      }
    }

    _adaptiveController = AdaptivePerformanceController(
      targetFrameTimeMs: _displayFrameBudgetMs(),
    );

    simulation = ParticleSimulation(
      particleCount: widget.particleCount,
      factory: widget.particleFactory,
      controller: widget.particleController,
      maxSpeed: widget.maxSpeed,
      maxSize: widget.maxSize,
      particleColor: widget.particleColor,
      gravityConfig: _buildGravityConfig(Size.zero),
      spatialGrid: widget.spatialGrid,
    );

    _initPainter();
    _setAdaptiveTimings(widget.performance.autoBoost);

    ticker = createTicker((elapsed) {
      final int now = elapsed.inMicroseconds;
      double timeScale = 1.0;
      if (widget.performance.frameRateIndependent && _lastFrameMicros != 0) {
        timeScale = (now - _lastFrameMicros) / 16666.667;
        if (timeScale < 0) timeScale = 0;
        if (timeScale > _maxTimeScale) timeScale = _maxTimeScale;
      }
      _lastFrameMicros = now;
      simulation.step(timeScale);
      _painter.stepTouchPhysics(timeScale);
      frameNotifier.value = now;
    })
      ..start();
  }

  @override
  void didUpdateWidget(ParticleNetwork oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (kDebugMode) {
      if (widget.usedLegacyGravity) {
        LegacyDeprecationLogger.warn(
          deprecatedApi:
              'ParticleNetwork(gravityType, gravityStrength, gravityDirection, gravityCenter)',
          replacement: 'ParticleNetwork(gravity: ParticleGravity(...))',
        );
      }
      if (widget.usedLegacyTouchColor) {
        LegacyDeprecationLogger.warn(
          deprecatedApi: 'ParticleNetwork(touchColor)',
          replacement:
              'ParticleNetwork(touchFeatures: TouchFeatures(color: ...))',
        );
      }
      if (widget.usedLegacyTouchActivation) {
        LegacyDeprecationLogger.warn(
          deprecatedApi: 'ParticleNetwork(touchActivation)',
          replacement:
              'ParticleNetwork(touchFeatures: TouchFeatures(enabled: ...)) (touchActivation was moved to TouchFeatures and renamed to enabled)',
        );
      }
      if (widget.usedLegacyIsComplex) {
        LegacyDeprecationLogger.warn(
          deprecatedApi: 'ParticleNetwork(isComplex)',
          replacement:
              'ParticleNetwork(performance: NetworkPerformance(isComplex: ...))',
        );
      }
    }

    bool factoryChanged = false;
    if (widget.particleFactory != oldWidget.particleFactory) {
      if (widget.particleFactory != null) {
        simulation.factory = widget.particleFactory!;
      } else {
        simulation.updateFactory(
          maxSpeed: widget.maxSpeed,
          maxSize: widget.maxSize,
          color: widget.particleColor,
        );
      }
      factoryChanged = true;
    } else if (widget.maxSpeed != oldWidget.maxSpeed ||
        widget.maxSize != oldWidget.maxSize ||
        widget.particleColor != oldWidget.particleColor) {
      simulation.updateFactory(
        maxSpeed: widget.maxSpeed,
        maxSize: widget.maxSize,
        color: widget.particleColor,
      );
      factoryChanged = true;
    }

    if (widget.particleController != oldWidget.particleController &&
        widget.particleController != null) {
      simulation.controller = widget.particleController!;
    }

    if (widget.particleCount != oldWidget.particleCount || factoryChanged) {
      simulation.updateParticleCount(widget.particleCount);
    }

    if (widget.gravity != oldWidget.gravity ||
        widget.gravityType != oldWidget.gravityType ||
        widget.gravityStrength != oldWidget.gravityStrength ||
        widget.gravityDirection != oldWidget.gravityDirection ||
        widget.gravityCenter != oldWidget.gravityCenter) {
      simulation.updateGravity(_buildGravityConfig(currentSize));
    }

    final effectiveTouch = widget.effectiveTouchFeatures;
    final oldEffectiveTouch = oldWidget.effectiveTouchFeatures;
    final effectivePerf = widget.effectivePerformance;
    final oldEffectivePerf = oldWidget.effectivePerformance;

    // Targeted painter updates
    if (widget.particleColor != oldWidget.particleColor ||
        widget.lineColor != oldWidget.lineColor ||
        effectiveTouch.color != oldEffectiveTouch.color) {
      _painter.updateColors(
        particleColor: widget.particleColor,
        lineColor: widget.lineColor,
        touchColor: effectiveTouch.color,
      );
    }

    if (widget.effectiveLineWidth != oldWidget.effectiveLineWidth) {
      _painter.updateLineWidth(widget.effectiveLineWidth);
    }

    if (widget.lineDistance != oldWidget.lineDistance ||
        _painter.lineDistance != widget.lineDistance) {
      _painter.updateLineDistance(widget.lineDistance);
    }

    if (widget.effectiveDrawNetwork != oldWidget.effectiveDrawNetwork ||
        widget.fill != oldWidget.fill ||
        effectivePerf.isComplex != oldEffectivePerf.isComplex ||
        effectiveTouch.enabled != oldEffectiveTouch.enabled) {
      _painter.updateRenderFlags(
        drawNetwork: widget.effectiveDrawNetwork,
        fill: widget.fill,
        isComplex: effectivePerf.isComplex,
        touchActivation: effectiveTouch.enabled,
      );
    }

    if (effectiveTouch != oldEffectiveTouch) {
      _painter.updateTouchFeatures(effectiveTouch);
    }

    if (effectivePerf != oldEffectivePerf) {
      _painter.updatePerformance(effectivePerf);
      if (effectivePerf.autoBoost != oldEffectivePerf.autoBoost) {
        _setAdaptiveTimings(effectivePerf.autoBoost);
      } else if (effectivePerf.autoBoost) {
        _painter.resetRuntimeOverrides();
        _adaptiveController.reset(targetFrameTimeMs: _displayFrameBudgetMs());
      }
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
    _setAdaptiveTimings(false);
    ticker.dispose();
    frameNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hover = widget.hoverEffect ?? false;
    _painter.devicePixelRatio =
        MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool hasBoundedWidth = constraints.hasBoundedWidth;
        final bool hasBoundedHeight = constraints.hasBoundedHeight;

        final Size safeSize = Size(
          hasBoundedWidth ? constraints.maxWidth : 0.0,
          hasBoundedHeight ? constraints.maxHeight : 0.0,
        );

        if (hasBoundedWidth && hasBoundedHeight) {
          _generateParticles(safeSize);
        } else {
          _generateParticles(Size.zero);
        }

        Widget content = RepaintBoundary(
          child: CustomPaint(
            painter: _painter,
            willChange: true,
            child: (hasBoundedWidth && hasBoundedHeight)
                ? const SizedBox.expand()
                : SizedBox(
                    width: safeSize.width,
                    height: safeSize.height,
                  ),
          ),
        );

        content = Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (event) {
            if (_activePointerId == null) {
              _activePointerId = event.pointer;
              _updateTouchPoint(event.localPosition);
            }
          },
          onPointerMove: (event) {
            if (event.pointer == _activePointerId) {
              _updateTouchPoint(event.localPosition);
            }
          },
          onPointerUp: (event) {
            if (event.pointer == _activePointerId) {
              _activePointerId = null;
              _updateTouchPoint(Offset.infinite);
            }
          },
          onPointerCancel: (event) {
            if (_activePointerId == null || event.pointer == _activePointerId) {
              _activePointerId = null;
              _updateTouchPoint(Offset.infinite);
            }
          },
          child: content,
        );

        if (hover) {
          content = MouseRegion(
            onEnter: (event) => _updateTouchPoint(event.localPosition),
            onHover: (event) => _updateTouchPoint(event.localPosition),
            onExit: (_) => _updateTouchPoint(Offset.infinite),
            child: content,
          );
        }

        return content;
      },
    );
  }
}
