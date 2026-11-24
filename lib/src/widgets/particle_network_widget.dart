// ignore_for_file: prefer_initializing_formals
/// ParticleNetwork widget and state implementation.
library;

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:particles_network/src/core/network_features.dart';
import 'package:particles_network/src/core/particle.dart';
import 'package:particles_network/src/core/particle_features.dart';
import 'package:particles_network/src/factory/particle_factory.dart';
import 'package:particles_network/src/interaction/touch_features.dart';
import 'package:particles_network/src/legacy/legacy_deprecation_logger.dart';
import 'package:particles_network/src/physics/particle_controller.dart';
import 'package:particles_network/src/physics/particle_gravity.dart';
import 'package:particles_network/src/rendering/complex_features.dart';
import 'package:particles_network/src/rendering/line_vertex_batch.dart';
import 'package:particles_network/src/rendering/network_performance.dart';
import 'package:particles_network/src/rendering/optimized_network_painter.dart';
import 'package:particles_network/src/rendering/performance_utils.dart';
import 'package:particles_network/src/simulation/particle_simulation.dart';
import 'package:particles_network/src/spatial/sorted_spatial_grid.dart';

/// A high-performance Flutter widget that renders an interactive particle network (plexus) animation.
///
/// Simulates organic floating particles and dynamic proximity connection lines with full physics support,
/// interactive touch responses, GPU-accelerated rendering, and adaptive performance scaling.
///
/// Features:
/// * **Visual Customization**: Tailor [particleCount], [maxSpeed], [maxSize], [lineWidth],
///   [lineDistance], [particleColor], [lineColor], and [fill] mode.
/// * **Gravitational Fields**: Add directional gravity (falling rain, rising bubbles) or radial
///   vortexes (black hole, repulsion shield) via [gravity] with [GravityFeatures].
/// * **Interactive Touch & Hover**: Attract nearby particles with fluid settling and glowing lines
///   via [touch] with [TouchFeatures].
/// * **High-Performance Architecture**: Scalable to 1,000+ particles with $O(N)$ connection clamping,
///   GPU triangle-batch rendering, dynamic line budgeting, and spatial grid acceleration via [performance] with [PerformanceFeatures].
///
/// Example:
/// ```dart
/// ParticleNetwork(
///   particles: const ParticleFeatures(
///     count: 80,
///     maxSpeed: 0.8,
///     maxSize: 2.0,
///     color: Colors.white,
///   ),
///   lineWidth: 0.8,
///   lineDistance: 120.0,
///   lineColor: const Color(0xFF00E5FF),
///   touch: const TouchFeatures(
///     enabled: true,
///     color: Colors.amber,
///   ),
///   gravity: const GravityFeatures.global(
///     strength: 0.15,
///     direction: Offset(0, 1),
///   ),
///   performance: const PerformanceFeatures(
///     frameRateIndependent: true,
///   ),
///   network: const NetworkFeatures(
///     renderer: LineRenderer.vertices,
///   ),
/// )
/// ```
class ParticleNetwork extends StatefulWidget {
  /// Advanced particle visual appearance, count, velocity limits, and styling.
  ///
  /// Governs particle density ([ParticleFeatures.count]), velocity limits ([ParticleFeatures.maxSpeed]),
  /// radius bounds ([ParticleFeatures.maxSize]), base color ([ParticleFeatures.color]), and
  /// fill/stroke mode ([ParticleFeatures.fill]). See [ParticleFeatures] for configuration options and presets.
  ///
  /// Defaults to `const ParticleFeatures()`.
  final ParticleFeatures particles;

  /// Compatibility alias for [particles].
  @Deprecated(
    'Use particles instead. This property will be removed in particles_network 2.0.0.',
  )
  ParticleFeatures get particleFeatures => effectiveParticleFeatures;

  /// Explicitly provided legacy particleFeatures alias, if any.
  final ParticleFeatures? _particleFeatures;

  /// Explicitly provided legacy particle count, if any.
  final int? _particleCount;

  /// Explicitly provided legacy max speed, if any.
  final double? _maxSpeed;

  /// Explicitly provided legacy max size, if any.
  final double? _maxSize;

  /// Explicitly provided legacy particle color, if any.
  final Color? _particleColor;

  /// Explicitly provided legacy fill mode, if any.
  final bool? _fill;

  /// Effective particle configuration merging modern and legacy parameters.
  ParticleFeatures get effectiveParticleFeatures {
    final base = _particleFeatures ?? particles;
    if (_particleCount == null &&
        _maxSpeed == null &&
        _maxSize == null &&
        _particleColor == null &&
        _fill == null) {
      return base;
    }
    return base.copyWith(
      count: _particleCount,
      maxSpeed: _maxSpeed,
      maxSize: _maxSize,
      color: _particleColor,
      fill: _fill,
    );
  }

  /// Checks whether deprecated individual particle parameters were explicitly configured.
  bool get usedLegacyParticles =>
      _particleCount != null ||
      _maxSpeed != null ||
      _maxSize != null ||
      _particleColor != null ||
      _fill != null;

  /// Checks whether deprecated [particleFeatures] parameter was explicitly configured.
  bool get usedLegacyParticleFeatures => _particleFeatures != null;

  /// Checks whether deprecated [particleCount] parameter was explicitly configured.
  bool get usedLegacyParticleCount => _particleCount != null;

  /// Checks whether deprecated [maxSpeed] parameter was explicitly configured.
  bool get usedLegacyMaxSpeed => _maxSpeed != null;

  /// Checks whether deprecated [maxSize] parameter was explicitly configured.
  bool get usedLegacyMaxSize => _maxSize != null;

  /// Checks whether deprecated [particleColor] parameter was explicitly configured.
  bool get usedLegacyParticleColor => _particleColor != null;

  /// Checks whether deprecated [fill] parameter was explicitly configured.
  bool get usedLegacyFill => _fill != null;

  /// Total number of particles simulated and rendered on the canvas.
  ///
  /// Deprecated: Configure particle count via [particles] using [ParticleFeatures.count] instead.
  /// This property will be removed in particles_network 2.0.0.
  @Deprecated(
    'Use particles: ParticleFeatures(count: ...) instead. '
    'This property will be removed in particles_network 2.0.0.',
  )
  int get particleCount => effectiveParticleFeatures.count;

  /// Maximum base velocity of particles in pixels per frame.
  ///
  /// Deprecated: Configure particle speed via [particles] using [ParticleFeatures.maxSpeed] instead.
  /// This property will be removed in particles_network 2.0.0.
  @Deprecated(
    'Use particles: ParticleFeatures(maxSpeed: ...) instead. '
    'This property will be removed in particles_network 2.0.0.',
  )
  double get maxSpeed => effectiveParticleFeatures.maxSpeed;

  /// Maximum radius of particles in logical pixels.
  ///
  /// Deprecated: Configure particle size via [particles] using [ParticleFeatures.maxSize] instead.
  /// This property will be removed in particles_network 2.0.0.
  @Deprecated(
    'Use particles: ParticleFeatures(maxSize: ...) instead. '
    'This property will be removed in particles_network 2.0.0.',
  )
  double get maxSize => effectiveParticleFeatures.maxSize;

  /// Base solid color used to render all particles on the canvas.
  ///
  /// Deprecated: Configure particle color via [particles] using [ParticleFeatures.color] instead.
  /// This property will be removed in particles_network 2.0.0.
  @Deprecated(
    'Use particles: ParticleFeatures(color: ...) instead. '
    'This property will be removed in particles_network 2.0.0.',
  )
  Color get particleColor => effectiveParticleFeatures.color;

  /// Whether particles are rendered as filled solid circles or hollow stroked outlines.
  ///
  /// Deprecated: Configure fill mode via [particles] using [ParticleFeatures.fill] instead.
  /// This property will be removed in particles_network 2.0.0.
  @Deprecated(
    'Use particles: ParticleFeatures(fill: ...) instead. '
    'This property will be removed in particles_network 2.0.0.',
  )
  bool get fill => effectiveParticleFeatures.fill;

  /// Advanced connection network visual appearance, connection limits, and styling.
  ///
  /// Governs whether lines are drawn ([NetworkFeatures.drawNetwork]), line reach distance ([NetworkFeatures.lineDistance]),
  /// line width ([NetworkFeatures.lineWidth]), line color ([NetworkFeatures.lineColor]), and GPU rendering
  /// backend ([NetworkFeatures.lineRenderer]). See [NetworkFeatures] for configuration options.
  ///
  /// Defaults to `const NetworkFeatures()`.
  final NetworkFeatures network;

  /// Compatibility alias for [network].
  @Deprecated(
    'Use network instead. This property will be removed in particles_network 2.0.0.',
  )
  NetworkFeatures get networkFeatures => effectiveNetworkFeatures;

  /// Explicitly provided legacy networkFeatures alias, if any.
  final NetworkFeatures? _networkFeatures;

  /// Explicitly provided legacy lineWidth, if any.
  final double? _lineWidth;

  /// Explicitly provided legacy lineDistance, if any.
  final double? _lineDistance;

  /// Explicitly provided legacy lineColor, if any.
  final Color? _lineColor;

  /// Explicitly provided legacy drawNetwork, if any.
  final bool? _drawNetwork;

  /// Explicitly provided legacy fastLineRendering / useVerticesRendering override, if any.
  final bool? _explicitFastLineRendering;

  /// Effective network configuration merging modern and legacy parameters.
  NetworkFeatures get effectiveNetworkFeatures {
    final base = _networkFeatures ?? network;
    final resolvedLineWidth = _lineWidth;
    final resolvedDrawNetwork = _drawNetwork;
    final resolvedRenderer = _explicitFastLineRendering != null
        ? (_explicitFastLineRendering
              ? LineRenderer.vertices
              : LineRenderer.stroke)
        : base.renderer;

    if (resolvedLineWidth == null &&
        _lineDistance == null &&
        _lineColor == null &&
        resolvedDrawNetwork == null &&
        _explicitFastLineRendering == null) {
      return base;
    }
    return base.copyWith(
      width: resolvedLineWidth,
      distance: _lineDistance,
      color: _lineColor,
      enabled: resolvedDrawNetwork,
      renderer: resolvedRenderer,
    );
  }

  /// Stroke width of connection lines between particles in logical pixels (legacy accessor).
  @Deprecated(
    'lineWidth has been moved into NetworkFeatures. '
    'Use network.width or effectiveNetworkFeatures.width instead. '
    'This property will be removed in particles_network 2.0.0.',
  )
  double get lineWidth => effectiveNetworkFeatures.width;

  /// Maximum connection distance between particles in logical pixels (legacy accessor).
  @Deprecated(
    'lineDistance has been moved into NetworkFeatures. '
    'Use network.distance or effectiveNetworkFeatures.distance instead. '
    'This property will be removed in particles_network 2.0.0.',
  )
  double get lineDistance => effectiveNetworkFeatures.distance;

  /// Base color used to render connecting lines between particles (legacy accessor).
  @Deprecated(
    'lineColor has been moved into NetworkFeatures. '
    'Use network.color or effectiveNetworkFeatures.color instead. '
    'This property will be removed in particles_network 2.0.0.',
  )
  Color get lineColor => effectiveNetworkFeatures.color;

  /// Whether to draw connection lines between neighboring particles (legacy accessor).
  @Deprecated(
    'drawNetwork has been moved into NetworkFeatures. '
    'Use network.enabled or effectiveNetworkFeatures.enabled instead. '
    'This property will be removed in particles_network 2.0.0.',
  )
  bool get drawNetwork => effectiveNetworkFeatures.enabled;

  /// Effective connection line width.
  double get effectiveLineWidth => effectiveNetworkFeatures.width;

  /// Effective connection line distance.
  double get effectiveLineDistance => effectiveNetworkFeatures.distance;

  /// Effective connection line color.
  Color get effectiveLineColor => effectiveNetworkFeatures.color;

  /// Effective flag used for drawing connection lines.
  bool get effectiveDrawNetwork => effectiveNetworkFeatures.enabled;

  /// Checks whether deprecated individual network parameters were explicitly configured.
  bool get usedLegacyNetworkParams =>
      _lineWidth != null ||
      _lineDistance != null ||
      _lineColor != null ||
      _drawNetwork != null;

  /// Checks whether deprecated [networkFeatures] parameter was explicitly configured.
  bool get usedLegacyNetworkFeatures => _networkFeatures != null;

  /// Explicitly provided legacy isComplex flag, if any.
  final bool? _isComplex;

  /// Whether the painting logic is complex (default: false).
  ///
  /// Deprecated: Configure complex rendering mode via [performance]
  /// using [PerformanceFeatures.isComplex] instead. This parameter will be removed in particles_network 2.0.0.
  @Deprecated(
    'Use performance (PerformanceFeatures(isComplex: ...)) instead. This parameter will be removed in particles_network 2.0.0.',
  )
  bool get isComplex => _isComplex ?? performance.isComplex;

  /// Effective flag used for complex rendering mode.
  bool get effectiveIsComplex => _isComplex ?? performance.isComplex;

  /// Checks whether the deprecated [isComplex] parameter was explicitly configured.
  bool get usedLegacyIsComplex => _isComplex != null;

  /// Explicitly provided legacy touch activation flag, if any.
  final bool? _touchActivation;

  /// Explicitly provided legacy touch highlight color, if any.
  final Color? _touchColor;

  /// Effective touch configuration merging legacy and modern parameters.
  TouchFeatures get effectiveTouchFeatures {
    final baseTouch = touch;
    if (_touchColor == null &&
        _touchActivation == null &&
        _hoverEffect == null) {
      return baseTouch;
    }
    return baseTouch.copyWith(
      color: _touchColor,
      enabled: _touchActivation,
      hover: _hoverEffect,
    );
  }

  /// Whether touch interactions are enabled (legacy accessor).
  @Deprecated(
    'Use touch.enabled instead. This property will be removed in particles_network 2.0.0.',
  )
  bool get touchActivation => effectiveTouchFeatures.enabled;

  /// Highlight color for touch interactions (legacy accessor).
  @Deprecated(
    'Use touch.color instead. This property will be removed in particles_network 2.0.0.',
  )
  Color get touchColor => effectiveTouchFeatures.color;

  /// Effective performance configuration merging legacy and modern parameters.
  PerformanceFeatures get effectivePerformance {
    var resolved = performance;
    if (_isComplex != null) {
      resolved = resolved.copyWith(isComplex: _isComplex);
    }
    if (maxConnectionsPerParticle != null) {
      resolved = resolved.copyWith(
        maxConnectionsPerParticle: maxConnectionsPerParticle,
      );
    }
    if (adaptiveDensity) {
      resolved = resolved.copyWith(complex: const ComplexConfig.auto());
    }
    if (enableAdaptivePerformance) {
      resolved = resolved.copyWith(autoBoost: true);
    }
    return resolved;
  }

  /// Maximum number of connection lines a single particle can emit (legacy accessor).
  @Deprecated(
    'maxConnectionsPerParticle has been moved into PerformanceFeatures. '
    'Use performance: PerformanceFeatures(maxConnectionsPerParticle: ...) instead. '
    'This property will be removed in particles_network 2.0.0.',
  )
  final int? maxConnectionsPerParticle;

  /// Automatically reduces line distance in crowded areas (legacy accessor).
  @Deprecated(
    'adaptiveDensity has been replaced by PerformanceFeatures(complex: ComplexConfig.auto()). '
    'This property will be removed in particles_network 2.0.0.',
  )
  final bool adaptiveDensity;

  /// Batched single-call line drawing using vertices (legacy accessor).
  @Deprecated(
    'fastLineRendering has been moved into NetworkFeatures. '
    'Use network: NetworkFeatures(renderer: LineRenderer.vertices) instead. '
    'This property will be removed in particles_network 2.0.0.',
  )
  bool get fastLineRendering =>
      _explicitFastLineRendering ??
      (effectiveNetworkFeatures.renderer == LineRenderer.vertices);

  /// Compatibility alias for [fastLineRendering].
  @Deprecated(
    'useVerticesRendering has been moved into NetworkFeatures. '
    'Use network: NetworkFeatures(renderer: LineRenderer.vertices) instead. '
    'This property will be removed in particles_network 2.0.0.',
  )
  bool get useVerticesRendering => fastLineRendering;

  /// Dynamically throttles effects during frame spikes to keep target FPS (legacy accessor).
  @Deprecated(
    'enableAdaptivePerformance has been moved into PerformanceFeatures. '
    'Use performance: PerformanceFeatures(autoBoost: ...) instead. '
    'This property will be removed in particles_network 2.0.0.',
  )
  final bool enableAdaptivePerformance;

  /// Checks whether deprecated [maxConnectionsPerParticle] was explicitly configured.
  bool get usedLegacyMaxConnections => maxConnectionsPerParticle != null;

  /// Checks whether deprecated [adaptiveDensity] was explicitly configured.
  bool get usedLegacyAdaptiveDensity => adaptiveDensity;

  /// Checks whether deprecated [fastLineRendering] or [useVerticesRendering] was explicitly configured.
  bool get usedLegacyFastLineRendering => _explicitFastLineRendering != null;

  /// Checks whether deprecated [enableAdaptivePerformance] was explicitly configured.
  bool get usedLegacyAdaptivePerformance => enableAdaptivePerformance;

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

  /// Gravitational physics configuration governing directional or point-based particle acceleration.
  ///
  /// Configured using [GravityFeatures], supporting:
  /// * [GravityFeatures.none]: Free-floating particles without external gravity.
  /// * [GravityFeatures.global]: Uniform directional acceleration (gravity, wind, rain).
  /// * [GravityFeatures.point]: Radial attraction or repulsion (black hole, vortex, repulsion shield).
  ///
  /// Defaults to `null` (which defaults to no gravity).
  final GravityFeatures? gravity;

  /// The type of gravity effect to apply (default: [GravityType.none]).
  ///
  /// Deprecated: Use [gravity] with [GravityFeatures.type] instead.
  /// This parameter will be removed in particles_network 2.0.0.
  @Deprecated(
    'Use gravity (GravityFeatures) instead. This parameter will be removed in particles_network 2.0.0.',
  )
  final GravityType gravityType;

  /// The strength of the applied gravity force (default: 0.1).
  ///
  /// Deprecated: Use [gravity] with [GravityFeatures.strength] instead.
  /// This parameter will be removed in particles_network 2.0.0.
  @Deprecated(
    'Use gravity (GravityFeatures) instead. This parameter will be removed in particles_network 2.0.0.',
  )
  final double gravityStrength;

  /// The direction vector for global gravity (default: `Offset(0, 1)` - downwards).
  ///
  /// Deprecated: Use [gravity] with [GravityFeatures.direction] instead.
  /// This parameter will be removed in particles_network 2.0.0.
  @Deprecated(
    'Use gravity (GravityFeatures) instead. This parameter will be removed in particles_network 2.0.0.',
  )
  final Offset gravityDirection;

  /// The center point for point-based gravity effects.
  ///
  /// Deprecated: Use [gravity] with [GravityFeatures.center] instead.
  /// This parameter will be removed in particles_network 2.0.0.
  @Deprecated(
    'Use gravity (GravityFeatures) instead. This parameter will be removed in particles_network 2.0.0.',
  )
  final Offset? gravityCenter;

  /// Checks whether deprecated individual gravity parameters were configured.
  bool get usedLegacyGravity =>
      gravity == null &&
      (gravityType != GravityType.none ||
          gravityStrength != 0.1 ||
          gravityDirection != const Offset(0, 1) ||
          gravityCenter != null);

  /// Explicitly provided legacy hoverEffect flag on [ParticleNetwork], if any.
  final bool? _hoverEffect;

  /// Whether mouse cursor movement triggers interactive proximity effects on web and desktop.
  ///
  /// When `true`, hovering the mouse over the widget attracts nearby particles without
  /// requiring a mouse button press or drag gesture.
  ///
  /// Defaults to `false`.
  ///
  /// Deprecated: Configure hover effects inside [touch] using [TouchFeatures.hover] instead.
  /// This property will be removed in particles_network 2.0.0.
  @Deprecated(
    'hoverEffect has been moved into TouchFeatures. '
    'Use touch.hover or effectiveTouchFeatures.hover instead. '
    'This property will be removed in particles_network 2.0.0.',
  )
  bool get hoverEffect => effectiveTouchFeatures.hover;

  /// Checks whether the deprecated [hoverEffect] parameter was explicitly configured on [ParticleNetwork].
  bool get usedLegacyHoverEffect => _hoverEffect != null;

  /// Advanced touch and pointer interaction configuration.
  ///
  /// Governs attraction pull force, recovery speed, fluid damping, interaction radius,
  /// and highlight line color. See [TouchFeatures] for configuration options.
  ///
  /// Defaults to `const TouchFeatures()`.
  final TouchFeatures touch;

  /// Compatibility alias for [touch].
  @Deprecated(
    'Use touch or effectiveTouchFeatures instead. This property will be removed in particles_network 2.0.0.',
  )
  TouchFeatures get touchFeatures => effectiveTouchFeatures;

  /// Advanced rendering performance and physics optimization configuration.
  ///
  /// Governs connection line limits ($O(N)$ bound), line budgets, GPU vertex batching,
  /// delta-time scaling, cluster throttling, and dynamic auto-boost. See [PerformanceFeatures]
  /// for configuration options and presets.
  ///
  /// Defaults to `const PerformanceFeatures()`.
  final PerformanceFeatures performance;

  /// Optional custom spatial indexing grid for particle neighbor queries.
  ///
  /// When `null`, a default [SortedSpatialGrid] is automatically created and tuned
  /// to optimal cell dimensions based on canvas bounds and [particleCount].
  ///
  /// Defaults to `null`.
  final SortedSpatialGrid? spatialGrid;

  /// Creates a [ParticleNetwork] widget with customizable visualization and physics parameters.
  ///
  /// Parameters:
  /// * [particles]: Advanced particle configuration ([ParticleFeatures]). Defaults to `const ParticleFeatures()`.
  /// * [lineWidth]: Stroke width of connection lines. Defaults to `0.5`.
  /// * [lineDistance]: Max proximity distance for connection lines. Defaults to `100.0`.
  /// * [lineColor]: Color for connection lines. Defaults to `const Color.fromARGB(255, 100, 255, 180)`.
  /// * [drawNetwork]: Whether connection lines are rendered. Defaults to `true`.
  /// * [gravity]: Gravitational force configuration ([GravityFeatures]). Defaults to `null`.
  /// * [hoverEffect]: Whether mouse hover triggers touch interaction. Defaults to `false`.
  /// * [touch]: Interactive touch and pointer physics settings ([TouchFeatures]). Defaults to `const TouchFeatures()`.
  /// * [performance]: Rendering performance and optimization settings ([PerformanceFeatures]). Defaults to `const PerformanceFeatures()`.
  /// * [spatialGrid]: Custom spatial partition grid ([SortedSpatialGrid]). Defaults to `null`.
  const ParticleNetwork({
    super.key,

    /// Advanced particle visual appearance, count, velocity limits, and styling.
    ///
    /// Defaults to `const ParticleFeatures()`.
    this.particles = const ParticleFeatures(),

    /// Compatibility alias for [particles].
    @Deprecated(
      'Use particles instead. This parameter will be removed in particles_network 2.0.0.',
    )
    ParticleFeatures? particleFeatures,

    /// Total number of particles simulated and rendered on the canvas.
    ///
    /// Deprecated: Use [particles] with [ParticleFeatures.count] instead.
    /// This parameter will be removed in particles_network 2.0.0.
    @Deprecated(
      'Use particles (ParticleFeatures(count: ...)) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    int? particleCount,

    /// Maximum base velocity of particles in pixels per frame.
    ///
    /// Deprecated: Use [particles] with [ParticleFeatures.maxSpeed] instead.
    /// This parameter will be removed in particles_network 2.0.0.
    @Deprecated(
      'Use particles (ParticleFeatures(maxSpeed: ...)) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    double? maxSpeed,

    /// Maximum radius of particles in logical pixels.
    ///
    /// Deprecated: Use [particles] with [ParticleFeatures.maxSize] instead.
    /// This parameter will be removed in particles_network 2.0.0.
    @Deprecated(
      'Use particles (ParticleFeatures(maxSize: ...)) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    double? maxSize,

    /// Stroke width of connection lines between particles in logical pixels.
    ///
    /// Defaults to `0.5`.
    @Deprecated(
      'lineWidth has been moved into NetworkFeatures. '
      'Use network: NetworkFeatures(width: ...) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    double? lineWidth,

    /// Maximum connection distance between particles in logical pixels.
    ///
    /// Defaults to `100.0`.
    @Deprecated(
      'lineDistance has been moved into NetworkFeatures. '
      'Use network: NetworkFeatures(distance: ...) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    double? lineDistance,

    /// Base solid color used to render all particles on the canvas.
    ///
    /// Deprecated: Use [particles] with [ParticleFeatures.color] instead.
    /// This parameter will be removed in particles_network 2.0.0.
    @Deprecated(
      'Use particles (ParticleFeatures(color: ...)) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    Color? particleColor,

    /// Base color used to render connecting lines between particles.
    ///
    /// Defaults to `const Color.fromARGB(255, 100, 255, 180)`.
    @Deprecated(
      'lineColor has been moved into NetworkFeatures. '
      'Use network: NetworkFeatures(color: ...) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    Color? lineColor,

    @Deprecated(
      'Use performance (PerformanceFeatures(isComplex: ...)) instead. This parameter will be removed in particles_network 2.0.0.',
    )
    bool? isComplex,

    /// Whether particles are rendered as filled solid circles or hollow stroked outlines.
    ///
    /// Deprecated: Use [particles] with [ParticleFeatures.fill] instead.
    /// This parameter will be removed in particles_network 2.0.0.
    @Deprecated(
      'Use particles (ParticleFeatures(fill: ...)) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    bool? fill,

    /// Whether to draw connection lines between neighboring particles.
    ///
    /// Defaults to `true`.
    @Deprecated(
      'drawNetwork has been moved into NetworkFeatures. '
      'Use network: NetworkFeatures(enabled: ...) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    bool? drawNetwork,

    @Deprecated(
      'Use ParticleSimulation for custom particle creation. This parameter will be removed in particles_network 2.0.0.',
    )
    this.particleFactory,

    @Deprecated(
      'Use ParticleSimulation for custom particle controllers. This parameter will be removed in particles_network 2.0.0.',
    )
    this.particleController,

    /// Gravitational physics configuration governing directional or point-based particle acceleration.
    ///
    /// Defaults to `null`.
    this.gravity,

    @Deprecated(
      'Use gravity (GravityFeatures) instead. This parameter will be removed in particles_network 2.0.0.',
    )
    this.gravityType = GravityType.none,

    @Deprecated(
      'Use gravity (GravityFeatures) instead. This parameter will be removed in particles_network 2.0.0.',
    )
    this.gravityStrength = 0.1,

    @Deprecated(
      'Use gravity (GravityFeatures) instead. This parameter will be removed in particles_network 2.0.0.',
    )
    this.gravityDirection = const Offset(0, 1),

    @Deprecated(
      'Use gravity (GravityFeatures) instead. This parameter will be removed in particles_network 2.0.0.',
    )
    this.gravityCenter,

    @Deprecated(
      'Use touch: TouchFeatures(color: ...) instead. This parameter will be removed in particles_network 2.0.0.',
    )
    Color? touchColor,

    @Deprecated(
      'Use touch: TouchFeatures(enabled: ...) instead. This parameter will be removed in particles_network 2.0.0.',
    )
    bool? touchActivation,

    /// Whether mouse cursor movement triggers interactive proximity effects on web and desktop.
    ///
    /// Deprecated: Configure hover effects inside [TouchFeatures] using [TouchFeatures(hover: ...)].
    /// This parameter will be removed in particles_network 2.0.0.
    @Deprecated(
      'hoverEffect has been moved into TouchFeatures. '
      'Use touch: TouchFeatures(hover: ...) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    bool? hoverEffect,

    /// Advanced touch interaction features and physics configuration.
    ///
    /// Defaults to `const TouchFeatures()`.
    TouchFeatures touch = const TouchFeatures(),

    /// Compatibility alias for [touch].
    ///
    /// Defaults to `const TouchFeatures()`.
    @Deprecated(
      'Use touch instead. This parameter will be removed in particles_network 2.0.0.',
    )
    TouchFeatures? touchFeatures,

    /// Advanced rendering performance and physics optimization configuration.
    ///
    /// Defaults to `const PerformanceFeatures()`.
    this.performance = const PerformanceFeatures(),

    /// Advanced connection network visual configuration.
    ///
    /// Defaults to `const NetworkFeatures()`.
    this.network = const NetworkFeatures(),

    /// Compatibility alias for [network].
    @Deprecated(
      'Use network instead. This parameter will be removed in particles_network 2.0.0.',
    )
    NetworkFeatures? networkFeatures,

    /// Optional custom spatial grid for particle queries.
    ///
    /// Defaults to `null`.
    this.spatialGrid,

    @Deprecated(
      'Use performance: PerformanceFeatures(maxConnectionsPerParticle: ...) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    this.maxConnectionsPerParticle,

    @Deprecated(
      'Use performance: PerformanceFeatures(complex: ComplexConfig.auto()) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    this.adaptiveDensity = false,

    @Deprecated(
      'Use network: NetworkFeatures(renderer: LineRenderer.vertices) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    bool? fastLineRendering,

    @Deprecated(
      'Use network: NetworkFeatures(renderer: LineRenderer.vertices) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    bool? useVerticesRendering,

    @Deprecated(
      'Use performance: PerformanceFeatures(autoBoost: ...) instead. '
      'This parameter will be removed in particles_network 2.0.0.',
    )
    this.enableAdaptivePerformance = false,
  }) : _particleCount = particleCount,
       _maxSpeed = maxSpeed,
       _maxSize = maxSize,
       _particleColor = particleColor,
       _fill = fill,
       _particleFeatures = particleFeatures,
       _networkFeatures = networkFeatures,
       _lineWidth = lineWidth,
       _lineDistance = lineDistance,
       _lineColor = lineColor,
       _drawNetwork = drawNetwork,
       touch = touchFeatures ?? touch,
       _touchActivation = touchActivation,
       _touchColor = touchColor,
       _hoverEffect = hoverEffect,
       _isComplex = isComplex,
       _explicitFastLineRendering = fastLineRendering ?? useVerticesRendering;

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

  GravityFeatures _buildGravityConfig(Size size) {
    if (widget.gravity != null) {
      final g = widget.gravity!;
      if (g.center == null && size != Size.zero) {
        return g.copyWith(center: Offset(size.width / 2, size.height / 2));
      }
      return g;
    }
    return GravityFeatures(
      type: widget.gravityType,
      strength: widget.gravityStrength,
      direction: widget.gravityDirection,
      center: widget.gravityCenter ?? Offset(size.width / 2, size.height / 2),
    );
  }

  void _initPainter() {
    final effectiveTouch = widget.effectiveTouchFeatures;
    final effectivePerf = widget.effectivePerformance;
    final particleConfig = widget.effectiveParticleFeatures;
    final effectiveNetwork = widget.effectiveNetworkFeatures;

    _painter = OptimizedNetworkPainter(
      drawNetwork: effectiveNetwork.enabled,
      fill: particleConfig.fill,
      isComplex: effectivePerf.isComplex,
      lineWidth: effectiveNetwork.width,
      particleCount: particleConfig.count,
      touchActivation: effectiveTouch.enabled,
      particles: simulation.particles,
      spatialGrid: simulation.spatialGrid,
      touchPoint: touchPoint,
      lineDistance: effectiveNetwork.distance,
      particleColor: particleConfig.color,
      lineColor: effectiveNetwork.color,
      touchColor: effectiveTouch.color,
      touchFeatures: effectiveTouch,
      performance: effectivePerf,
      lineRenderer: effectiveNetwork.renderer,
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
      final double durationMs =
          math.max(
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
    final double rawRate =
        WidgetsBinding
            .instance
            .platformDispatcher
            .implicitView
            ?.display
            .refreshRate ??
        60.0;
    final double safeRate = (rawRate >= 30.0 && rawRate <= 240.0)
        ? rawRate
        : 60.0;
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
      if (widget.usedLegacyParticles) {
        LegacyDeprecationLogger.warn(
          deprecatedApi:
              'ParticleNetwork(particleCount, maxSpeed, maxSize, particleColor, fill)',
          replacement: 'ParticleNetwork(particles: ParticleFeatures(...))',
          message:
              'Individual particle configuration parameters have been consolidated into ParticleFeatures. Use particles: ParticleFeatures(...) to configure count, maxSpeed, maxSize, color, and fill.',
        );
      }
      if (widget.usedLegacyParticleFeatures) {
        LegacyDeprecationLogger.warn(
          deprecatedApi: 'ParticleNetwork(particleFeatures)',
          replacement: 'ParticleNetwork(particles: ParticleFeatures(...))',
          message:
              'The parameter particleFeatures has been renamed to particles for consistency with touch and performance.',
        );
      }
      if (widget.usedLegacyGravity) {
        LegacyDeprecationLogger.warn(
          deprecatedApi:
              'ParticleNetwork(gravityType, gravityStrength, gravityDirection, gravityCenter)',
          replacement: 'ParticleNetwork(gravity: GravityFeatures(...))',
        );
      }
      if (widget.usedLegacyIsComplex) {
        LegacyDeprecationLogger.warn(
          deprecatedApi: 'ParticleNetwork(isComplex)',
          replacement:
              'ParticleNetwork(performance: PerformanceFeatures(isComplex: ...))',
        );
      }
      if (widget.usedLegacyHoverEffect) {
        LegacyDeprecationLogger.warn(
          deprecatedApi: 'ParticleNetwork(hoverEffect)',
          replacement: 'ParticleNetwork(touch: TouchFeatures(hover: ...))',
          message:
              'The hoverEffect parameter has been consolidated into TouchFeatures. Use touch: TouchFeatures(hover: ...) instead.',
        );
      }
      if (widget.usedLegacyNetworkParams) {
        LegacyDeprecationLogger.warn(
          deprecatedApi:
              'ParticleNetwork(drawNetwork, lineWidth, lineDistance, lineColor)',
          replacement: 'ParticleNetwork(network: NetworkFeatures(...))',
          message:
              'Network line configuration parameters have been consolidated into NetworkFeatures. Use network: NetworkFeatures(...) to configure drawNetwork, lineWidth, lineDistance, lineColor, and lineRenderer.',
        );
      }
      if (widget.usedLegacyNetworkFeatures) {
        LegacyDeprecationLogger.warn(
          deprecatedApi: 'ParticleNetwork(networkFeatures)',
          replacement: 'ParticleNetwork(network: NetworkFeatures(...))',
          message:
              'The parameter networkFeatures has been renamed to network for consistency.',
        );
      }
      if (widget.usedLegacyMaxConnections) {
        LegacyDeprecationLogger.warn(
          deprecatedApi: 'ParticleNetwork(maxConnectionsPerParticle)',
          replacement:
              'ParticleNetwork(performance: PerformanceFeatures(maxConnectionsPerParticle: ...))',
          message:
              'maxConnectionsPerParticle has been consolidated into PerformanceFeatures. Use performance: PerformanceFeatures(maxConnectionsPerParticle: ...) instead.',
        );
      }
      if (widget.usedLegacyAdaptiveDensity) {
        LegacyDeprecationLogger.warn(
          deprecatedApi: 'ParticleNetwork(adaptiveDensity)',
          replacement:
              'ParticleNetwork(performance: PerformanceFeatures(complex: ComplexConfig.auto()))',
          message:
              'adaptiveDensity has been consolidated into PerformanceFeatures. Use performance: PerformanceFeatures(complex: ComplexConfig.auto()) instead.',
        );
      }
      if (widget.usedLegacyFastLineRendering) {
        LegacyDeprecationLogger.warn(
          deprecatedApi:
              'ParticleNetwork(fastLineRendering, useVerticesRendering)',
          replacement:
              'ParticleNetwork(network: NetworkFeatures(renderer: LineRenderer.vertices))',
          message:
              'fastLineRendering and useVerticesRendering have been consolidated into NetworkFeatures. Use network: NetworkFeatures(renderer: LineRenderer.vertices) instead.',
        );
      }
      if (widget.usedLegacyAdaptivePerformance) {
        LegacyDeprecationLogger.warn(
          deprecatedApi: 'ParticleNetwork(enableAdaptivePerformance)',
          replacement:
              'ParticleNetwork(performance: PerformanceFeatures(autoBoost: ...))',
          message:
              'enableAdaptivePerformance has been consolidated into PerformanceFeatures. Use performance: PerformanceFeatures(autoBoost: ...) instead.',
        );
      }
    }

    _adaptiveController = AdaptivePerformanceController(
      targetFrameTimeMs: _displayFrameBudgetMs(),
    );

    final particleConfig = widget.effectiveParticleFeatures;
    simulation = ParticleSimulation(
      particleCount: particleConfig.count,
      factory: widget.particleFactory,
      controller: widget.particleController,
      maxSpeed: particleConfig.maxSpeed,
      maxSize: particleConfig.maxSize,
      particleColor: particleConfig.color,
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
    })..start();
  }

  @override
  void didUpdateWidget(ParticleNetwork oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (kDebugMode) {
      if (widget.usedLegacyParticles) {
        LegacyDeprecationLogger.warn(
          deprecatedApi:
              'ParticleNetwork(particleCount, maxSpeed, maxSize, particleColor, fill)',
          replacement: 'ParticleNetwork(particles: ParticleFeatures(...))',
          message:
              'Individual particle configuration parameters have been consolidated into ParticleFeatures. Use particles: ParticleFeatures(...) to configure count, maxSpeed, maxSize, color, and fill.',
        );
      }
      if (widget.usedLegacyParticleFeatures) {
        LegacyDeprecationLogger.warn(
          deprecatedApi: 'ParticleNetwork(particleFeatures)',
          replacement: 'ParticleNetwork(particles: ParticleFeatures(...))',
          message:
              'The parameter particleFeatures has been renamed to particles for consistency with touch and performance.',
        );
      }
      if (widget.usedLegacyGravity) {
        LegacyDeprecationLogger.warn(
          deprecatedApi:
              'ParticleNetwork(gravityType, gravityStrength, gravityDirection, gravityCenter)',
          replacement: 'ParticleNetwork(gravity: GravityFeatures(...))',
        );
      }
      if (widget.usedLegacyIsComplex) {
        LegacyDeprecationLogger.warn(
          deprecatedApi: 'ParticleNetwork(isComplex)',
          replacement:
              'ParticleNetwork(performance: PerformanceFeatures(isComplex: ...))',
        );
      }
      if (widget.usedLegacyHoverEffect) {
        LegacyDeprecationLogger.warn(
          deprecatedApi: 'ParticleNetwork(hoverEffect)',
          replacement: 'ParticleNetwork(touch: TouchFeatures(hover: ...))',
          message:
              'The hoverEffect parameter has been consolidated into TouchFeatures. Use touch: TouchFeatures(hover: ...) instead.',
        );
      }
      if (widget.usedLegacyNetworkParams) {
        LegacyDeprecationLogger.warn(
          deprecatedApi:
              'ParticleNetwork(drawNetwork, lineWidth, lineDistance, lineColor)',
          replacement: 'ParticleNetwork(network: NetworkFeatures(...))',
          message:
              'Network line configuration parameters have been consolidated into NetworkFeatures. Use network: NetworkFeatures(...) to configure drawNetwork, lineWidth, lineDistance, lineColor, and lineRenderer.',
        );
      }
      if (widget.usedLegacyNetworkFeatures) {
        LegacyDeprecationLogger.warn(
          deprecatedApi: 'ParticleNetwork(networkFeatures)',
          replacement: 'ParticleNetwork(network: NetworkFeatures(...))',
          message:
              'The parameter networkFeatures has been renamed to network for consistency.',
        );
      }
      if (widget.usedLegacyMaxConnections) {
        LegacyDeprecationLogger.warn(
          deprecatedApi: 'ParticleNetwork(maxConnectionsPerParticle)',
          replacement:
              'ParticleNetwork(performance: PerformanceFeatures(maxConnectionsPerParticle: ...))',
          message:
              'maxConnectionsPerParticle has been consolidated into PerformanceFeatures. Use performance: PerformanceFeatures(maxConnectionsPerParticle: ...) instead.',
        );
      }
      if (widget.usedLegacyAdaptiveDensity) {
        LegacyDeprecationLogger.warn(
          deprecatedApi: 'ParticleNetwork(adaptiveDensity)',
          replacement:
              'ParticleNetwork(performance: PerformanceFeatures(complex: ComplexConfig.auto()))',
          message:
              'adaptiveDensity has been consolidated into PerformanceFeatures. Use performance: PerformanceFeatures(complex: ComplexConfig.auto()) instead.',
        );
      }
      if (widget.usedLegacyFastLineRendering) {
        LegacyDeprecationLogger.warn(
          deprecatedApi:
              'ParticleNetwork(fastLineRendering, useVerticesRendering)',
          replacement:
              'ParticleNetwork(network: NetworkFeatures(renderer: LineRenderer.vertices))',
          message:
              'fastLineRendering and useVerticesRendering have been consolidated into NetworkFeatures. Use network: NetworkFeatures(renderer: LineRenderer.vertices) instead.',
        );
      }
      if (widget.usedLegacyAdaptivePerformance) {
        LegacyDeprecationLogger.warn(
          deprecatedApi: 'ParticleNetwork(enableAdaptivePerformance)',
          replacement:
              'ParticleNetwork(performance: PerformanceFeatures(autoBoost: ...))',
          message:
              'enableAdaptivePerformance has been consolidated into PerformanceFeatures. Use performance: PerformanceFeatures(autoBoost: ...) instead.',
        );
      }
    }

    final particleConfig = widget.effectiveParticleFeatures;
    final oldParticleConfig = oldWidget.effectiveParticleFeatures;

    bool factoryChanged = false;
    if (widget.particleFactory != oldWidget.particleFactory) {
      if (widget.particleFactory != null) {
        simulation.factory = widget.particleFactory!;
      } else {
        simulation.updateFactory(
          maxSpeed: particleConfig.maxSpeed,
          maxSize: particleConfig.maxSize,
          color: particleConfig.color,
        );
      }
      factoryChanged = true;
    } else if (particleConfig.maxSpeed != oldParticleConfig.maxSpeed ||
        particleConfig.maxSize != oldParticleConfig.maxSize ||
        particleConfig.color != oldParticleConfig.color) {
      simulation.updateFactory(
        maxSpeed: particleConfig.maxSpeed,
        maxSize: particleConfig.maxSize,
        color: particleConfig.color,
      );
      factoryChanged = true;
    }

    if (widget.particleController != oldWidget.particleController &&
        widget.particleController != null) {
      simulation.controller = widget.particleController!;
    }

    if (particleConfig.count != oldParticleConfig.count || factoryChanged) {
      simulation.updateParticleCount(particleConfig.count);
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
    final effectiveNetwork = widget.effectiveNetworkFeatures;
    final oldEffectiveNetwork = oldWidget.effectiveNetworkFeatures;

    // Targeted painter updates
    if (particleConfig.color != oldParticleConfig.color ||
        effectiveNetwork.color != oldEffectiveNetwork.color ||
        effectiveTouch.color != oldEffectiveTouch.color) {
      _painter.updateColors(
        particleColor: particleConfig.color,
        lineColor: effectiveNetwork.color,
        touchColor: effectiveTouch.color,
      );
    }

    if (effectiveNetwork.width != oldEffectiveNetwork.width) {
      _painter.updateLineWidth(effectiveNetwork.width);
    }

    if (effectiveNetwork.distance != oldEffectiveNetwork.distance ||
        _painter.lineDistance != effectiveNetwork.distance) {
      _painter.updateLineDistance(effectiveNetwork.distance);
    }

    if (effectiveNetwork.enabled != oldEffectiveNetwork.enabled ||
        particleConfig.fill != oldParticleConfig.fill ||
        effectivePerf.isComplex != oldEffectivePerf.isComplex ||
        effectiveTouch.enabled != oldEffectiveTouch.enabled) {
      _painter.updateRenderFlags(
        drawNetwork: effectiveNetwork.enabled,
        fill: particleConfig.fill,
        isComplex: effectivePerf.isComplex,
        touchActivation: effectiveTouch.enabled,
      );
    }

    if (effectiveNetwork.renderer != oldEffectiveNetwork.renderer) {
      _painter.lineRenderer = effectiveNetwork.renderer;
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
    final bool hover = widget.effectiveTouchFeatures.hover;
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
                : SizedBox(width: safeSize.width, height: safeSize.height),
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
