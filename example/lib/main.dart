import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' as flutter_scheduler;
import 'package:flutter/services.dart';
import 'package:particles_network/particles_network.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Particles Network Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.tealAccent,
          secondary: Colors.cyanAccent,
          surface: Color(0xFF1E2126),
        ),
      ),
      home: const ParticleControllerScreen(),
    );
  }
}

//*   ___________________________________________
//*  /                                           \
//* |    ✨ THANK YOU FOR USING PARTICLES ✨      |
//* |                                             |
//* |   If this library helped you build          |
//* |   something amazing, please consider        |
//* |   giving it a star! It means a lot.         |
//* |                                             |
//* |        ⭐ [ star ]  particles_network       |
//*  \___________________________________________/
//*           !  !
//*           !  !
//*           L_ !

/// Model for Showcase Presets
class ParticlePreset {
  final String name;
  final String description;
  final IconData icon;
  final Color particleColor;
  final Color lineColor;
  final Color touchColor;
  final Color backgroundColor;
  final int particleCount;
  final double maxSpeed;
  final double maxSize;
  final double lineWidth;
  final double lineDistance;
  final GravityType gravityType;
  final double gravityStrength;
  final Offset gravityDirection;
  final Offset? gravityCenter;
  final double touchForce;
  final double touchSpeed;
  final double maxTouchSpeed;
  final double touchDamping;
  final double touchLineDistance;
  final bool adaptiveDensity;
  final bool enableAdaptivePerformance;
  final bool fastLineRendering;
  final bool frameRateIndependent;
  final LineRenderer lineRenderer;
  final int? maxConnectionsPerParticle;
  final int? maxLinesPerFrame;

  const ParticlePreset({
    required this.name,
    required this.description,
    required this.icon,
    required this.particleColor,
    required this.lineColor,
    required this.touchColor,
    required this.backgroundColor,
    required this.particleCount,
    required this.maxSpeed,
    required this.maxSize,
    required this.lineWidth,
    required this.lineDistance,
    required this.gravityType,
    required this.gravityStrength,
    required this.gravityDirection,
    this.gravityCenter,
    required this.touchForce,
    required this.touchSpeed,
    required this.maxTouchSpeed,
    required this.touchDamping,
    required this.touchLineDistance,
    required this.adaptiveDensity,
    required this.enableAdaptivePerformance,
    required this.fastLineRendering,
    required this.frameRateIndependent,
    required this.lineRenderer,
    this.maxConnectionsPerParticle,
    this.maxLinesPerFrame,
  });
}

class ParticleControllerScreen extends StatefulWidget {
  const ParticleControllerScreen({super.key});

  @override
  State<ParticleControllerScreen> createState() =>
      _ParticleControllerScreenState();
}

class _ParticleControllerScreenState extends State<ParticleControllerScreen> {
  // --- UI Constants ---
  static const Duration _animationDuration = Duration(milliseconds: 320);
  static const Color _controllerColor = Colors.tealAccent;

  // --- Particle Network Configuration Variables ---
  bool _drawNetwork = true;
  bool _isFill = false;
  bool _isComplex = true;
  bool _antiAlias = true;
  double _lineWidth = 1.0;
  int _particleCount = 300;
  double _maxSpeed = 5.0;
  double _maxSize = 2.0;
  /// Connection distance between particles. Automatically adapts to screen size
  /// (Phone: 60, Tablet: 80, Desktop: 100) unless customized by user via slider.
  bool _isLineDistanceCustom = false;
  double _lineDistance = 100.0;
  GravityType _gravityType = GravityType.none;
  double _gravityStrength = 0.1;
  Offset _gravityDirection = const Offset(0, 1);
  Offset? _gravityCenter;

  // --- Touch Features Variables ---
  bool _touchActivation = true;
  bool _hoverEffect = false;
  double _touchSpeed = 0.42;
  double _touchForce = 0.42;
  double _maxTouchSpeed = 5.5;
  double _touchDamping = 0.985;
  double _touchLineDistance = 150.0;

  // --- Performance Configuration Variables ---
  bool _adaptiveDensity = false;
  bool _enableAdaptivePerformance = false;
  bool _fastLineRendering = false;
  bool _frameRateIndependent = false;
  LineRenderer _lineRenderer = LineRenderer.stroke;
  int? _maxConnectionsPerParticle;
  int? _maxLinesPerFrame;
  double _spatialCellMultiplier = 1.0;
  double _cappedDistanceFactor = 0.75;

  // --- Styling Variables ---
  Color _particleColor = Colors.deepPurple;
  Color _lineColor = Colors.lightBlue;
  Color _touchColor = Colors.amber;
  Color _backgroundColor = Colors.black;

  // --- UI State ---
  bool _showPanel = true;
  bool _showChart = false;
  int _selectedCategoryIndex = 0;
  bool _tapToPlaceSingularity = false;

  /// Tracks collapsed state of cards when in "All" view
  final Map<String, bool> _collapsedSections = {};

  /// UniqueKey forces a full rebuild of the ParticleNetwork when user explicitly re-seeds
  Key _particleKey = UniqueKey();

  void _refreshEngine() {
    setState(() {
      _particleKey = UniqueKey();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLineDistanceCustom) {
      _lineDistance = _getResponsiveLineDistance(context);
    }
  }

  /// Calculates responsive connection line distance based on screen width:
  /// - Phone (< 600px): 60.0 (shorter to avoid visual clutter on compact screens)
  /// - Tablet (600px - 1024px): 80.0 (longer, balanced for mid-sized viewports)
  /// - Computer / Desktop (>= 1024px): 100.0 (full open web connection distance)
  double _getResponsiveLineDistance([BuildContext? ctx]) {
    final effectiveContext = ctx ?? (mounted ? context : null);
    if (effectiveContext == null) return 100.0;
    final width = MediaQuery.sizeOf(effectiveContext).width;
    if (width < 600) {
      return 60.0; // Phone
    } else if (width < 1024) {
      return 80.0; // Tablet
    } else {
      return 100.0; // Computer / Desktop
    }
  }

  // --- Showcase Presets ---
  static const List<ParticlePreset> _presets = [
    ParticlePreset(
      name: "Cosmic Web",
      description: "Delicate starlight web drifting slowly in deep space",
      icon: Icons.auto_awesome_rounded,
      particleColor: Color(0xFF818CF8),
      lineColor: Color(0xFF38BDF8),
      touchColor: Color(0xFFFBBF24),
      backgroundColor: Color(0xFF070B14),
      particleCount: 220,
      maxSpeed: 2.2,
      maxSize: 2.5,
      lineWidth: 0.8,
      lineDistance: 130.0,
      gravityType: GravityType.none,
      gravityStrength: 0.1,
      gravityDirection: Offset(0, 1),
      touchForce: 0.35,
      touchSpeed: 0.3,
      maxTouchSpeed: 4.0,
      touchDamping: 0.990,
      touchLineDistance: 170.0,
      adaptiveDensity: false,
      enableAdaptivePerformance: false,
      fastLineRendering: false,
      frameRateIndependent: false,
      lineRenderer: LineRenderer.stroke,
    ),
    ParticlePreset(
      name: "Cyberpunk Matrix",
      description: "Digital rain downward gravity with neon luminescence",
      icon: Icons.memory_rounded,
      particleColor: Color(0xFF10B981),
      lineColor: Color(0xFF06B6D4),
      touchColor: Color(0xFFF43F5E),
      backgroundColor: Color(0xFF02120A),
      particleCount: 380,
      maxSpeed: 6.5,
      maxSize: 2.2,
      lineWidth: 1.2,
      lineDistance: 95.0,
      gravityType: GravityType.global,
      gravityStrength: 0.40,
      gravityDirection: Offset(0, 1),
      touchForce: 0.80,
      touchSpeed: 0.5,
      maxTouchSpeed: 7.0,
      touchDamping: 0.970,
      touchLineDistance: 200.0,
      adaptiveDensity: true,
      enableAdaptivePerformance: false,
      fastLineRendering: false,
      frameRateIndependent: true,
      lineRenderer: LineRenderer.stroke,
    ),
    ParticlePreset(
      name: "Black Hole Singularity",
      description: "Intense gravitational vortex pulling particles inward",
      icon: Icons.all_inclusive_rounded,
      particleColor: Color(0xFFF59E0B),
      lineColor: Color(0xFFEC4899),
      touchColor: Color(0xFF8B5CF6),
      backgroundColor: Color(0xFF030107),
      particleCount: 420,
      maxSpeed: 4.8,
      maxSize: 3.0,
      lineWidth: 1.0,
      lineDistance: 110.0,
      gravityType: GravityType.point,
      gravityStrength: 0.85,
      gravityDirection: Offset(0, 1),
      touchForce: 1.20,
      touchSpeed: 0.65,
      maxTouchSpeed: 9.0,
      touchDamping: 0.965,
      touchLineDistance: 240.0,
      adaptiveDensity: true,
      enableAdaptivePerformance: true,
      fastLineRendering: true,
      frameRateIndependent: true,
      lineRenderer: LineRenderer.vertices,
      maxConnectionsPerParticle: 6,
    ),
    ParticlePreset(
      name: "Supernova Repulsion",
      description: "Radial repulsive point gravity with explosive velocity",
      icon: Icons.flare_rounded,
      particleColor: Color(0xFFEF4444),
      lineColor: Color(0xFFF97316),
      touchColor: Color(0xFFFDE047),
      backgroundColor: Color(0xFF0C0303),
      particleCount: 500,
      maxSpeed: 8.5,
      maxSize: 3.2,
      lineWidth: 1.4,
      lineDistance: 85.0,
      gravityType: GravityType.point,
      gravityStrength: -1.2,
      gravityDirection: Offset(0, 1),
      touchForce: 0.90,
      touchSpeed: 0.50,
      maxTouchSpeed: 11.0,
      touchDamping: 0.975,
      touchLineDistance: 250.0,
      adaptiveDensity: true,
      enableAdaptivePerformance: true,
      fastLineRendering: true,
      frameRateIndependent: true,
      lineRenderer: LineRenderer.vertices,
      maxConnectionsPerParticle: 5,
      maxLinesPerFrame: 18000,
    ),
    ParticlePreset(
      name: "Neural Synapse",
      description: "High-density interconnected cognitive network",
      icon: Icons.hub_rounded,
      particleColor: Color(0xFFA855F7),
      lineColor: Color(0xFF38BDF8),
      touchColor: Color(0xFF34D399),
      backgroundColor: Color(0xFF080718),
      particleCount: 320,
      maxSpeed: 3.5,
      maxSize: 2.4,
      lineWidth: 1.1,
      lineDistance: 120.0,
      gravityType: GravityType.none,
      gravityStrength: 0.1,
      gravityDirection: Offset(0, 1),
      touchForce: 0.75,
      touchSpeed: 0.40,
      maxTouchSpeed: 6.0,
      touchDamping: 0.980,
      touchLineDistance: 190.0,
      adaptiveDensity: true,
      enableAdaptivePerformance: false,
      fastLineRendering: false,
      frameRateIndependent: true,
      lineRenderer: LineRenderer.stroke,
    ),
    ParticlePreset(
      name: "Quantum Foam",
      description: "Dense turbulent micro-particles with rapid kinetic decay",
      icon: Icons.grain_rounded,
      particleColor: Color(0xFF22D3EE),
      lineColor: Color(0xFF818CF8),
      touchColor: Color(0xFFE879F9),
      backgroundColor: Color(0xFF050814),
      particleCount: 450,
      maxSpeed: 5.0,
      maxSize: 1.8,
      lineWidth: 0.9,
      lineDistance: 80.0,
      gravityType: GravityType.none,
      gravityStrength: 0.1,
      gravityDirection: Offset(0, 1),
      touchForce: 0.60,
      touchSpeed: 0.45,
      maxTouchSpeed: 7.0,
      touchDamping: 0.982,
      touchLineDistance: 150.0,
      adaptiveDensity: true,
      enableAdaptivePerformance: false,
      fastLineRendering: false,
      frameRateIndependent: true,
      lineRenderer: LineRenderer.stroke,
    ),
    ParticlePreset(
      name: "Extreme 60FPS Swarm",
      description: "1000 particles with hardware-accelerated batched vertices",
      icon: Icons.bolt_rounded,
      particleColor: Color(0xFF38BDF8),
      lineColor: Color(0xFF6366F1),
      touchColor: Color(0xFF10B981),
      backgroundColor: Color(0xFF070B16),
      particleCount: 1000,
      maxSpeed: 4.5,
      maxSize: 1.6,
      lineWidth: 0.7,
      lineDistance: 70.0,
      gravityType: GravityType.none,
      gravityStrength: 0.1,
      gravityDirection: Offset(0, 1),
      touchForce: 0.50,
      touchSpeed: 0.45,
      maxTouchSpeed: 6.0,
      touchDamping: 0.985,
      touchLineDistance: 140.0,
      adaptiveDensity: true,
      enableAdaptivePerformance: true,
      fastLineRendering: true,
      frameRateIndependent: true,
      lineRenderer: LineRenderer.vertices,
      maxConnectionsPerParticle: 4,
      maxLinesPerFrame: 15000,
    ),
  ];

  void _applyFullPreset(ParticlePreset preset) {
    setState(() {
      _particleColor = preset.particleColor;
      _lineColor = preset.lineColor;
      _touchColor = preset.touchColor;
      _backgroundColor = preset.backgroundColor;
      _particleCount = preset.particleCount;
      _maxSpeed = preset.maxSpeed;
      _maxSize = preset.maxSize;
      _lineWidth = preset.lineWidth;
      _lineDistance = preset.lineDistance;
      _isLineDistanceCustom = true;
      _gravityType = preset.gravityType;
      _gravityStrength = preset.gravityStrength;
      _gravityDirection = preset.gravityDirection;
      _gravityCenter = preset.gravityCenter;
      _touchForce = preset.touchForce;
      _touchSpeed = preset.touchSpeed;
      _maxTouchSpeed = preset.maxTouchSpeed;
      _touchDamping = preset.touchDamping;
      _touchLineDistance = preset.touchLineDistance;
      _adaptiveDensity = preset.adaptiveDensity;
      _enableAdaptivePerformance = preset.enableAdaptivePerformance;
      _fastLineRendering = preset.fastLineRendering;
      _frameRateIndependent = preset.frameRateIndependent;
      _lineRenderer = preset.lineRenderer;
      _maxConnectionsPerParticle = preset.maxConnectionsPerParticle;
      _maxLinesPerFrame = preset.maxLinesPerFrame;
    });
    _refreshEngine();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Applied preset: ${preset.name}"),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF22262C),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- Individual Section Reset Methods ---
  void _resetDisplaySection() {
    setState(() {
      _particleColor = Colors.deepPurple;
      _lineColor = Colors.lightBlue;
      _touchColor = Colors.amber;
      _backgroundColor = Colors.black;
      _drawNetwork = true;
      _isFill = false;
      _isComplex = true;
      _antiAlias = true;
      _showChart = false;
    });
  }

  void _resetLinesSection() {
    setState(() {
      _lineWidth = 1.0;
      _isLineDistanceCustom = false;
      _lineDistance = _getResponsiveLineDistance(context);
      _fastLineRendering = false;
      _lineRenderer = LineRenderer.stroke;
      _cappedDistanceFactor = 0.75;
    });
  }

  void _resetEngineSection() {
    setState(() {
      _particleCount = 300;
      _maxSpeed = 5.0;
      _maxSize = 2.0;
    });
    _refreshEngine();
  }

  void _resetTouchSection() {
    setState(() {
      _touchActivation = true;
      _hoverEffect = false;
      _touchSpeed = 0.42;
      _touchForce = 0.42;
      _maxTouchSpeed = 5.5;
      _touchDamping = 0.985;
      _touchLineDistance = 150.0;
    });
  }

  void _resetGravitySection() {
    setState(() {
      _gravityType = GravityType.none;
      _gravityStrength = 0.1;
      _gravityDirection = const Offset(0, 1);
      _gravityCenter = null;
      _tapToPlaceSingularity = false;
    });
  }

  void _resetPerformanceSection() {
    setState(() {
      _adaptiveDensity = false;
      _enableAdaptivePerformance = false;
      _fastLineRendering = false;
      _frameRateIndependent = false;
      _lineRenderer = LineRenderer.stroke;
      _antiAlias = true;
      _maxConnectionsPerParticle = null;
      _maxLinesPerFrame = null;
      _spatialCellMultiplier = 1.0;
      _cappedDistanceFactor = 0.75;
    });
  }

  /// Resets all settings to their default values.
  void _resetToDefaults() {
    setState(() {
      _drawNetwork = true;
      _isFill = false;
      _isComplex = true;
      _antiAlias = true;
      _touchActivation = true;
      _hoverEffect = false;
      _lineWidth = 1.0;
      _particleCount = 300;
      _maxSpeed = 5.0;
      _maxSize = 2.0;
      _isLineDistanceCustom = false;
      _lineDistance = _getResponsiveLineDistance(context);
      _gravityType = GravityType.none;
      _gravityStrength = 0.1;
      _gravityDirection = const Offset(0, 1);
      _gravityCenter = null;
      _tapToPlaceSingularity = false;
      _touchSpeed = 0.42;
      _touchForce = 0.42;
      _maxTouchSpeed = 5.5;
      _touchDamping = 0.985;
      _touchLineDistance = 150.0;
      _adaptiveDensity = false;
      _enableAdaptivePerformance = false;
      _fastLineRendering = false;
      _frameRateIndependent = false;
      _lineRenderer = LineRenderer.stroke;
      _maxConnectionsPerParticle = null;
      _maxLinesPerFrame = null;
      _spatialCellMultiplier = 1.0;
      _cappedDistanceFactor = 0.75;
      _particleColor = Colors.deepPurple;
      _lineColor = Colors.lightBlue;
      _touchColor = Colors.amber;
      _backgroundColor = Colors.black;
      _showChart = false;
      _selectedCategoryIndex = 0;
    });
    _refreshEngine();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("All settings reset to defaults"),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF22262C),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _togglePanel() {
    setState(() {
      _showPanel = !_showPanel;
    });
  }

  String _generateDartCode() {
    final buffer = StringBuffer();
    buffer.writeln('ParticleNetwork(');
    buffer.writeln('  particleCount: $_particleCount,');
    buffer.writeln('  maxSpeed: $_maxSpeed,');
    buffer.writeln('  maxSize: $_maxSize,');
    buffer.writeln('  lineWidth: $_lineWidth,');
    buffer.writeln('  lineDistance: $_lineDistance,');
    buffer.writeln(
        '  particleColor: const Color(0x${_particleColor.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}),');
    buffer.writeln(
        '  lineColor: const Color(0x${_lineColor.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}),');
    buffer.writeln('  drawNetwork: $_drawNetwork,');
    buffer.writeln('  fill: $_isFill,');
    buffer.writeln('  hoverEffect: $_hoverEffect,');
    buffer.writeln('  gravity: const ParticleGravity(');
    buffer.writeln('    gravityType: GravityType.${_gravityType.name},');
    buffer.writeln('    gravityStrength: $_gravityStrength,');
    buffer.writeln(
        '    gravityDirection: Offset(${_gravityDirection.dx.toStringAsFixed(2)}, ${_gravityDirection.dy.toStringAsFixed(2)}),');
    if (_gravityCenter != null) {
      buffer.writeln(
          '    gravityCenter: Offset(${_gravityCenter!.dx.toStringAsFixed(1)}, ${_gravityCenter!.dy.toStringAsFixed(1)}),');
    }
    buffer.writeln('  ),');
    buffer.writeln('  touchFeatures: const TouchFeatures(');
    buffer.writeln('    enabled: $_touchActivation,');
    buffer.writeln(
        '    color: Color(0x${_touchColor.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}),');
    buffer.writeln('    force: $_touchForce,');
    buffer.writeln('    speed: $_touchSpeed,');
    buffer.writeln('    maxTouchSpeed: $_maxTouchSpeed,');
    buffer.writeln('    damping: $_touchDamping,');
    buffer.writeln('    lineDistance: $_touchLineDistance,');
    buffer.writeln('  ),');
    buffer.writeln('  performance: const NetworkPerformance(');
    buffer.writeln('    isComplex: $_isComplex,');
    buffer.writeln('    adaptiveDensity: $_adaptiveDensity,');
    buffer.writeln('    fastLineRendering: $_fastLineRendering,');
    buffer.writeln('    enableAdaptivePerformance: $_enableAdaptivePerformance,');
    buffer.writeln('    frameRateIndependent: $_frameRateIndependent,');
    buffer.writeln('    lineRenderer: LineRenderer.${_lineRenderer.name},');
    buffer.writeln('    antiAlias: $_antiAlias,');
    if (_maxConnectionsPerParticle != null) {
      buffer.writeln(
          '    maxConnectionsPerParticle: $_maxConnectionsPerParticle,');
    }
    if (_maxLinesPerFrame != null) {
      buffer.writeln('    maxLinesPerFrame: $_maxLinesPerFrame,');
    }
    if (_spatialCellMultiplier != 1.0) {
      buffer.writeln('    spatialCellMultiplier: $_spatialCellMultiplier,');
    }
    if (_cappedDistanceFactor != 0.75) {
      buffer.writeln('    cappedDistanceFactor: $_cappedDistanceFactor,');
    }
    buffer.writeln('  ),');
    buffer.writeln(')');
    return buffer.toString();
  }

  void _showExportDialog() {
    final code = _generateDartCode();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2126),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: _controllerColor.withValues(alpha: 0.3)),
        ),
        title: const Row(
          children: [
            Icon(Icons.code_rounded, color: _controllerColor, size: 20),
            SizedBox(width: 8),
            Text(
              "Generated Dart Code",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 380),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF121418),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11.5,
                color: Color(0xFF38BDF8),
                height: 1.4,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Close",
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _controllerColor,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text(
              "Copy Code",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Flutter code copied to clipboard!"),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive threshold: wide screen (desktop / tablet landscape / phone landscape)
            final isWide = constraints.maxWidth >= 750 ||
                (constraints.maxWidth > constraints.maxHeight &&
                    constraints.maxWidth >= 550);

            if (isWide) {
              final sidebarWidth = constraints.maxWidth >= 800
                  ? 390.0
                  : (constraints.maxWidth * 0.44).clamp(260.0, 360.0);
              return Row(
                children: [
                  Expanded(
                    child: _buildCanvasArea(
                      isWide: true,
                      constraints: constraints,
                    ),
                  ),
                  AnimatedContainer(
                    duration: _animationDuration,
                    curve: Curves.easeInOut,
                    width: _showPanel ? sidebarWidth : 0,
                    child: _showPanel
                        ? _buildAdvancedControlPanel(
                            isWide: true,
                            maxHeight: constraints.maxHeight,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              );
            } else {
              // Mobile Portrait: Dynamic responsive height with guaranteed minimum canvas breathing room
              final availableHeight = constraints.maxHeight;
              final maxAllowedPanel = (availableHeight - 90.0).clamp(160.0, 520.0);
              final panelMaxHeight =
                  (availableHeight * 0.52).clamp(180.0, maxAllowedPanel);

              return Column(
                children: [
                  Expanded(
                    child: _buildCanvasArea(
                      isWide: false,
                      constraints: constraints,
                    ),
                  ),
                  AnimatedCrossFade(
                    duration: _animationDuration,
                    crossFadeState: _showPanel
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    sizeCurve: Curves.easeInOut,
                    firstChild: _buildAdvancedControlPanel(
                      isWide: false,
                      maxHeight: panelMaxHeight,
                    ),
                    secondChild: _buildMobileFloatingBar(),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  /// Compact floating bar on mobile when panel is collapsed
  Widget _buildMobileFloatingBar() {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! < -100) {
          // Drag up -> expand
          if (!_showPanel) setState(() => _showPanel = true);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2126),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              offset: Offset(0, -3),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _controllerColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _controllerColor.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.grain_rounded,
                      size: 13, color: _controllerColor),
                  const SizedBox(width: 4),
                  Text(
                    "$_particleCount pts",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _controllerColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: _togglePanel,
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2E35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.tune_rounded,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.85)),
                        const SizedBox(width: 6),
                        Text(
                          "Open Engine Controls",
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.code_rounded, size: 18),
              color: _controllerColor,
              tooltip: "Export Code",
              onPressed: _showExportDialog,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the canvas visualization area with live FPS overlay, Point Gravity interactive marker, and HUD
  Widget _buildCanvasArea({
    required bool isWide,
    required BoxConstraints constraints,
  }) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: _backgroundColor,
            child: FPS(
              alignment: Alignment.topRight,
              showChart: _showChart,
              child: ParticleNetwork(
                key: _particleKey,
                drawNetwork: _drawNetwork,
                fill: _isFill,
                lineWidth: _lineWidth,
                particleCount: _particleCount,
                maxSpeed: _maxSpeed,
                maxSize: _maxSize,
                lineDistance: _lineDistance,
                particleColor: _particleColor,
                lineColor: _lineColor,
                hoverEffect: _hoverEffect,
                performance: NetworkPerformance(
                  isComplex: _isComplex,
                  adaptiveDensity: _adaptiveDensity,
                  enableAdaptivePerformance: _enableAdaptivePerformance,
                  fastLineRendering: _fastLineRendering,
                  frameRateIndependent: _frameRateIndependent,
                  lineRenderer: _lineRenderer,
                  antiAlias: _antiAlias,
                  maxConnectionsPerParticle: _maxConnectionsPerParticle,
                  maxLinesPerFrame: _maxLinesPerFrame,
                  cappedDistanceFactor: _cappedDistanceFactor,
                  spatialCellMultiplier: _spatialCellMultiplier != 1.0
                      ? _spatialCellMultiplier
                      : null,
                ),
                touchFeatures: TouchFeatures(
                  enabled: _touchActivation,
                  speed: _touchSpeed,
                  force: _touchForce,
                  maxTouchSpeed: _maxTouchSpeed,
                  lineDistance: _touchLineDistance,
                  color: _touchColor,
                  damping: _touchDamping,
                ),
                gravity: ParticleGravity(
                  gravityType: _gravityType,
                  gravityStrength: _gravityStrength,
                  gravityDirection: _gravityDirection,
                  gravityCenter: _gravityCenter,
                ),
              ),
            ),
          ),
        ),

        // Interactive tap overlay for placing Point Gravity Singularity
        if (_gravityType == GravityType.point && _tapToPlaceSingularity)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (details) {
                setState(() {
                  _gravityCenter = details.localPosition;
                  _tapToPlaceSingularity = false;
                });
              },
              child: Container(
                color: _controllerColor.withValues(alpha: 0.05),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _controllerColor),
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, blurRadius: 8),
                      ],
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app_rounded,
                              size: 16, color: _controllerColor),
                          SizedBox(width: 8),
                          Text(
                            "Tap canvas to place singularity",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Visual indicator for Point Gravity Singularity
        if (_gravityType == GravityType.point && _gravityCenter != null)
          Positioned(
            left: _gravityCenter!.dx - 18,
            top: _gravityCenter!.dy - 18,
            child: IgnorePointer(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _controllerColor.withValues(alpha: 0.75),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _controllerColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _controllerColor,
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Top Left Floating HUD: Responsive quick status pills & shortcuts
        Positioned(
          left: 10,
          top: 10,
          child: SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: math.max(120.0, constraints.maxWidth - 160.0),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHudPill(
                      icon: Icons.grain_rounded,
                      label: "$_particleCount pts",
                      color: _particleColor,
                    ),
                    const SizedBox(width: 6),
                    _buildHudPill(
                      icon: Icons.speed_rounded,
                      label: "${_maxSpeed.toStringAsFixed(1)} px/f",
                      color: _controllerColor,
                    ),
                    const SizedBox(width: 6),
                    _buildQuickActionBtn(
                      icon: Icons.code_rounded,
                      tooltip: "Export Flutter Code",
                      onTap: _showExportDialog,
                    ),
                    const SizedBox(width: 6),
                    _buildQuickActionBtn(
                      icon: Icons.auto_awesome_rounded,
                      tooltip: "Showcase Presets",
                      onTap: () {
                        setState(() => _selectedCategoryIndex = 7);
                        if (!_showPanel) setState(() => _showPanel = true);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Floating Toggle Button when panel is hidden or in wide mode
        if (!_showPanel || isWide)
          Positioned(
            right: 16,
            bottom: 16,
            child: _buildToggleButton(isWide: isWide),
          ),
      ],
    );
  }

  Widget _buildHudPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 4),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            shape: BoxShape.circle,
            border: Border.all(
              color: _controllerColor.withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 4),
            ],
          ),
          child: Icon(icon, size: 14, color: _controllerColor),
        ),
      ),
    );
  }

  /// Builds the floating action button to toggle the panel
  Widget _buildToggleButton({required bool isWide}) {
    return GestureDetector(
      onTap: _togglePanel,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF22262C),
          border: Border.all(
            color: _controllerColor.withValues(alpha: 0.45),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.65),
              offset: const Offset(3, 3),
              blurRadius: 6,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.08),
              offset: const Offset(-2, -2),
              blurRadius: 5,
            ),
          ],
        ),
        child: Icon(
          _showPanel
              ? (isWide
                  ? Icons.chevron_right_rounded
                  : Icons.keyboard_arrow_down_rounded)
              : Icons.tune_rounded,
          color: _controllerColor,
          size: 22,
        ),
      ),
    );
  }

  /// Builds a Neumorphic styled card container with soft extruded shadows
  Widget _buildNeuCard({
    required Widget child,
    String? title,
    IconData? icon,
    VoidCallback? onReset,
    String? sectionKey,
    EdgeInsetsGeometry padding = const EdgeInsets.all(12),
    EdgeInsetsGeometry margin = const EdgeInsets.only(bottom: 12),
  }) {
    final isCollapsible = _selectedCategoryIndex == 0 && sectionKey != null;
    final isCollapsed =
        isCollapsible && (_collapsedSections[sectionKey] ?? false);

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF22262C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            offset: const Offset(4, 4),
            blurRadius: 8,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.05),
            offset: const Offset(-3, -3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: _controllerColor),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                if (onReset != null)
                  Tooltip(
                    message: "Reset this section",
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: onReset,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.restart_alt_rounded,
                          size: 15,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                if (isCollapsible)
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      setState(() {
                        _collapsedSections[sectionKey] = !isCollapsed;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        isCollapsed
                            ? Icons.expand_more_rounded
                            : Icons.expand_less_rounded,
                        size: 16,
                        color: _controllerColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
              ],
            ),
            if (!isCollapsed) const SizedBox(height: 10),
          ],
          if (!isCollapsed) child,
        ],
      ),
    );
  }

  /// Builds the main control panel containing all settings in Neumorphism style
  Widget _buildAdvancedControlPanel({
    required bool isWide,
    required double maxHeight,
  }) {
    return Container(
      width: isWide ? double.infinity : double.infinity,
      height: maxHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2126),
        borderRadius: isWide
            ? null
            : const BorderRadius.vertical(top: Radius.circular(22)),
        border: isWide
            ? Border(
                left: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              )
            : Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            offset: isWide ? const Offset(-5, 0) : const Offset(0, -6),
            blurRadius: 18,
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle with gesture support on mobile
          if (!isWide)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _togglePanel,
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity! > 120) {
                  // Swiped down -> collapse
                  if (_showPanel) setState(() => _showPanel = false);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),

          // Header with Title & Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 6, 4),
            child: Row(
              children: [
                const Icon(Icons.tune_rounded, size: 16, color: _controllerColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "ENGINE CONTROLS",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.code_rounded, size: 18),
                  color: _controllerColor,
                  tooltip: "Export Dart Code",
                  visualDensity: VisualDensity.compact,
                  onPressed: _showExportDialog,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: const EdgeInsets.all(4),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  color: Colors.white.withValues(alpha: 0.6),
                  tooltip: "Reset All to Defaults",
                  visualDensity: VisualDensity.compact,
                  onPressed: _resetToDefaults,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: const EdgeInsets.all(4),
                ),
                IconButton(
                  icon: Icon(
                    isWide
                        ? Icons.chevron_right_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                  ),
                  color: _controllerColor,
                  tooltip: "Hide Panel",
                  visualDensity: VisualDensity.compact,
                  onPressed: _togglePanel,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ),
          ),

          // Category Chips Bar for quick navigation (First Scrollable in tree)
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildCategoryChip(0, "All", Icons.apps_rounded),
                _buildCategoryChip(1, "Display", Icons.palette_outlined),
                _buildCategoryChip(2, "Lines", Icons.linear_scale_rounded),
                _buildCategoryChip(3, "Engine", Icons.speed_rounded),
                _buildCategoryChip(4, "Touch", Icons.touch_app_rounded),
                _buildCategoryChip(5, "Gravity", Icons.public_rounded),
                _buildCategoryChip(6, "Performance", Icons.bolt_rounded),
                _buildCategoryChip(7, "Presets", Icons.auto_awesome_rounded),
                _buildCategoryChip(8, "Export", Icons.code_rounded),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Scrollable Settings Cards
          Expanded(
            child: ClipRRect(
              borderRadius: isWide
                  ? BorderRadius.zero
                  : const BorderRadius.vertical(top: Radius.circular(16)),
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                children: [
                  // Palette & Display Options
                  if (_selectedCategoryIndex == 0 ||
                      _selectedCategoryIndex == 1)
                    _buildNeuCard(
                      title: "Palette & Display Options",
                      icon: Icons.palette_outlined,
                      sectionKey: "display",
                      onReset: _resetDisplaySection,
                      child: _buildDisplaySection(),
                    ),

                  // Line Dynamics
                  if (_selectedCategoryIndex == 0 ||
                      _selectedCategoryIndex == 2)
                    _buildNeuCard(
                      title: "Line Dynamics",
                      icon: Icons.linear_scale_rounded,
                      sectionKey: "lines",
                      onReset: _resetLinesSection,
                      child: _buildLinesSection(),
                    ),

                  // Engine Critical Parameters
                  if (_selectedCategoryIndex == 0 ||
                      _selectedCategoryIndex == 3)
                    _buildNeuCard(
                      title: "Engine Parameters (*Rebuilds)",
                      icon: Icons.speed_rounded,
                      sectionKey: "engine",
                      onReset: _resetEngineSection,
                      child: _buildEngineSection(),
                    ),

                  // Touch Interaction
                  if (_selectedCategoryIndex == 0 ||
                      _selectedCategoryIndex == 4)
                    _buildNeuCard(
                      title: "Touch Interaction",
                      icon: Icons.touch_app_rounded,
                      sectionKey: "touch",
                      onReset: _resetTouchSection,
                      child: _buildTouchFeaturesSection(),
                    ),

                  // Gravity Settings
                  if (_selectedCategoryIndex == 0 ||
                      _selectedCategoryIndex == 5)
                    _buildNeuCard(
                      title: "Gravity Settings",
                      icon: Icons.public_rounded,
                      sectionKey: "gravity",
                      onReset: _resetGravitySection,
                      child: _buildGravitySection(),
                    ),

                  // Performance & Optimizations
                  if (_selectedCategoryIndex == 0 ||
                      _selectedCategoryIndex == 6)
                    _buildNeuCard(
                      title: "Performance & Optimizations",
                      icon: Icons.bolt_rounded,
                      sectionKey: "performance",
                      onReset: _resetPerformanceSection,
                      child: _buildPerformanceSection(),
                    ),

                  // Showcase Presets Gallery
                  if (_selectedCategoryIndex == 0 ||
                      _selectedCategoryIndex == 7)
                    _buildNeuCard(
                      title: "Showcase Presets",
                      icon: Icons.auto_awesome_rounded,
                      sectionKey: "presets",
                      child: _buildPresetsGallery(),
                    ),

                  // Code Export Section
                  if (_selectedCategoryIndex == 8)
                    _buildNeuCard(
                      title: "Export Dart Code",
                      icon: Icons.code_rounded,
                      sectionKey: "export",
                      child: _buildExportInlineSection(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds an interactive category filter chip
  Widget _buildCategoryChip(int index, String label, IconData icon) {
    final isSelected = _selectedCategoryIndex == index;
    return GestureDetector(
      key: ValueKey('category_chip_$label'),
      onTap: () => setState(() => _selectedCategoryIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? _controllerColor.withValues(alpha: 0.15)
              : const Color(0xFF22262C),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? _controllerColor
                : Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Colors.black45,
                    offset: Offset(1, 1),
                    blurRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    offset: const Offset(2, 2),
                    blurRadius: 3,
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected
                  ? _controllerColor
                  : Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? _controllerColor
                    : Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Display & Palette Section ---
  Widget _buildDisplaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildColorSection(),
        const SizedBox(height: 10),

        // Quick Color Themes
        Wrap(
          spacing: 4,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              "Themes: ",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            _buildThemeChip("Cyber", const Color(0xFF10B981),
                const Color(0xFF06B6D4), const Color(0xFFF43F5E)),
            _buildThemeChip("Cosmic", const Color(0xFF818CF8),
                const Color(0xFF38BDF8), const Color(0xFFFBBF24)),
            _buildThemeChip("Sunset", const Color(0xFFF97316),
                const Color(0xFFEC4899), const Color(0xFFFDE047)),
            _buildThemeChip("Mono", Colors.white, Colors.white60, Colors.amber),
            _buildThemeChip("Emerald", const Color(0xFF10B981),
                const Color(0xFF34D399), const Color(0xFF6EE7B7)),
          ],
        ),
        const SizedBox(height: 10),

        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.white.withValues(alpha: 0.08),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildSwitchesSection(),
      ],
    );
  }

  Widget _buildThemeChip(String label, Color p, Color l, Color t) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _particleColor = p;
          _lineColor = l;
          _touchColor = t;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF181A1E),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: p),
            ),
            const SizedBox(width: 2),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: l),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Line Dynamics Section ---
  Widget _buildLinesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Visual Line Preview
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF17191D),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
          ),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _particleColor,
                ),
              ),
              Expanded(
                child: Container(
                  height: _lineWidth.clamp(0.5, 8.0),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: _lineColor,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: _lineColor.withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _particleColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Sliders
        Row(
          children: [
            Expanded(
              child: _buildSlider(
                "Line Width",
                _lineWidth,
                0.1,
                20.0,
                (v) => setState(() => _lineWidth = v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSlider(
                "Line Dist",
                _lineDistance,
                0,
                300,
                (v) => setState(() {
                  _lineDistance = v;
                  _isLineDistanceCustom = true;
                }),
                fractionDigits: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Quick Width chips
        Wrap(
          spacing: 4,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              "Width:",
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            _buildMiniPill("Hairline", _lineWidth == 0.5,
                () => setState(() => _lineWidth = 0.5)),
            _buildMiniPill("Normal", _lineWidth == 1.0,
                () => setState(() => _lineWidth = 1.0)),
            _buildMiniPill("Bold", _lineWidth == 2.5,
                () => setState(() => _lineWidth = 2.5)),
            _buildMiniPill("Heavy", _lineWidth == 5.0,
                () => setState(() => _lineWidth = 5.0)),
          ],
        ),
        const SizedBox(height: 6),

        // Quick Distance chips
        Wrap(
          spacing: 4,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              "Distance:",
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            _buildMiniPill("Auto (Screen)", !_isLineDistanceCustom, () {
              setState(() {
                _isLineDistanceCustom = false;
                _lineDistance = _getResponsiveLineDistance(context);
              });
            }),
            _buildMiniPill("Phone (60)",
                _lineDistance == 60.0 && _isLineDistanceCustom, () {
              setState(() {
                _isLineDistanceCustom = true;
                _lineDistance = 60.0;
              });
            }),
            _buildMiniPill("Tablet (80)",
                _lineDistance == 80.0 && _isLineDistanceCustom, () {
              setState(() {
                _isLineDistanceCustom = true;
                _lineDistance = 80.0;
              });
            }),
            _buildMiniPill("Desktop (100)",
                _lineDistance == 100.0 && _isLineDistanceCustom, () {
              setState(() {
                _isLineDistanceCustom = true;
                _lineDistance = 100.0;
              });
            }),
          ],
        ),
        const SizedBox(height: 10),

        // Renderer Backend toggle
        Row(
          children: [
            Expanded(
              child: Text(
                "Raster Backend",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ),
            _buildPillToggle(
              label: "Stroke",
              isSelected: _lineRenderer == LineRenderer.stroke,
              onTap: () => setState(() => _lineRenderer = LineRenderer.stroke),
            ),
            const SizedBox(width: 6),
            _buildPillToggle(
              label: "Vertices",
              isSelected: _lineRenderer == LineRenderer.vertices,
              onTap: () =>
                  setState(() => _lineRenderer = LineRenderer.vertices),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Capped Distance Factor Slider
        _buildSlider(
          "Capped Distance Factor",
          _cappedDistanceFactor,
          0.25,
          1.0,
          (v) => setState(() => _cappedDistanceFactor = v),
          fractionDigits: 2,
        ),
      ],
    );
  }

  Widget _buildMiniPill(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: isSelected
              ? _controllerColor.withValues(alpha: 0.18)
              : const Color(0xFF17191D),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: isSelected
                ? _controllerColor
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? _controllerColor
                : Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  // --- Engine Parameters Section ---
  Widget _buildEngineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Re-seed Simulation Control Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _controllerColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _controllerColor.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.tune_rounded, size: 13, color: _controllerColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Real-time dynamic particle simulation",
                  style: TextStyle(
                    fontSize: 9.5,
                    color: _controllerColor.withValues(alpha: 0.9),
                  ),
                ),
              ),
              InkWell(
                onTap: _refreshEngine,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _controllerColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.refresh_rounded,
                          size: 11, color: _controllerColor),
                      SizedBox(width: 3),
                      Text(
                        "Re-seed",
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: _controllerColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Count Slider - Smooth live update via didUpdateWidget
        _buildSlider(
          "Count",
          _particleCount.toDouble(),
          10,
          20000,
          (v) => setState(() => _particleCount = v.toInt()),
          fractionDigits: 0,
        ),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            _buildCountChip(50),
            _buildCountChip(150),
            _buildCountChip(300),
            _buildCountChip(600),
            _buildCountChip(1000),
          ],
        ),
        const SizedBox(height: 8),

        // Speed Slider - Smooth live update
        _buildSlider(
          "Speed",
          _maxSpeed,
          0.1,
          20.0,
          (v) => setState(() => _maxSpeed = v),
        ),

        // Size Slider - Smooth live update
        _buildSlider(
          "Max Size",
          _maxSize,
          0.5,
          20.0,
          (v) => setState(() => _maxSize = v),
        ),
      ],
    );
  }

  Widget _buildCountChip(int count) {
    final isSelected = _particleCount == count;
    return GestureDetector(
      onTap: () => setState(() => _particleCount = count),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: isSelected
              ? _controllerColor.withValues(alpha: 0.2)
              : const Color(0xFF17191D),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: isSelected
                ? _controllerColor
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Text(
          "$count",
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? _controllerColor
                : Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  // --- Gravity Section ---
  Widget _buildGravitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gravity Type selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildGravityTypeButton("None", GravityType.none),
            _buildGravityTypeButton("Global", GravityType.global),
            _buildGravityTypeButton("Point", GravityType.point),
          ],
        ),
        const SizedBox(height: 10),

        // Quick Presets
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            _buildMiniPill("Zero-G", _gravityType == GravityType.none, () {
              setState(() => _gravityType = GravityType.none);
            }),
            _buildMiniPill(
                "Earth ⬇️",
                _gravityType == GravityType.global &&
                    _gravityDirection.dy > 0.5, () {
              setState(() {
                _gravityType = GravityType.global;
                _gravityStrength = 0.25;
                _gravityDirection = const Offset(0, 1);
              });
            }),
            _buildMiniPill(
                "Lift ⬆️",
                _gravityType == GravityType.global &&
                    _gravityDirection.dy < -0.5, () {
              setState(() {
                _gravityType = GravityType.global;
                _gravityStrength = 0.25;
                _gravityDirection = const Offset(0, -1);
              });
            }),
            _buildMiniPill(
                "Attract 🌀",
                _gravityType == GravityType.point && _gravityStrength > 0, () {
              setState(() {
                _gravityType = GravityType.point;
                _gravityStrength = 0.8;
                _gravityCenter = null;
              });
            }),
            _buildMiniPill(
                "Repel 💥",
                _gravityType == GravityType.point && _gravityStrength < 0, () {
              setState(() {
                _gravityType = GravityType.point;
                _gravityStrength = -0.9;
                _gravityCenter = null;
              });
            }),
          ],
        ),
        const SizedBox(height: 8),

        _buildSlider(
          "Strength",
          _gravityStrength,
          -2.0,
          2.0,
          (v) => setState(() => _gravityStrength = v),
          fractionDigits: 2,
        ),

        // Global Direction Controls
        if (_gravityType == GravityType.global) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Direction Angle",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF17191D),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.04),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        "${_gravityDirection.dx.toStringAsFixed(1)}, ${_gravityDirection.dy.toStringAsFixed(1)}",
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: _controllerColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderThemeData(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    trackHeight: 4,
                    activeTrackColor: _controllerColor,
                    inactiveTrackColor: const Color(0xFF16181C),
                    thumbColor: _controllerColor,
                    overlayColor: _controllerColor.withValues(alpha: 0.15),
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                    trackShape: const RoundedRectSliderTrackShape(),
                  ),
                  child: Slider(
                    value: math.atan2(
                      _gravityDirection.dy,
                      _gravityDirection.dx,
                    ),
                    min: -math.pi,
                    max: math.pi,
                    onChanged: (v) {
                      setState(() {
                        _gravityDirection = Offset(math.cos(v), math.sin(v));
                      });
                    },
                  ),
                ),
                // 8-Direction Quick Compass
                Center(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildDirBtn("⬅️", const Offset(-1, 0)),
                      _buildDirBtn("↖️", const Offset(-0.707, -0.707)),
                      _buildDirBtn("⬆️", const Offset(0, -1)),
                      _buildDirBtn("↗️", const Offset(0.707, -0.707)),
                      _buildDirBtn("➡️", const Offset(1, 0)),
                      _buildDirBtn("↘️", const Offset(0.707, 0.707)),
                      _buildDirBtn("⬇️", const Offset(0, 1)),
                      _buildDirBtn("↙️", const Offset(-0.707, 0.707)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // Point Singularity Controls
        if (_gravityType == GravityType.point) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF17191D),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.center_focus_strong_rounded,
                        size: 14, color: _controllerColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _gravityCenter == null
                            ? "Singularity: Canvas Center"
                            : "Singularity: (${_gravityCenter!.dx.toStringAsFixed(0)}, ${_gravityCenter!.dy.toStringAsFixed(0)})",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                    if (_gravityCenter != null)
                      InkWell(
                        onTap: () => setState(() => _gravityCenter = null),
                        child: const Text(
                          "Reset Center",
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: _controllerColor,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _tapToPlaceSingularity = !_tapToPlaceSingularity;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: _tapToPlaceSingularity
                                ? _controllerColor.withValues(alpha: 0.25)
                                : const Color(0xFF22262C),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _tapToPlaceSingularity
                                  ? _controllerColor
                                  : Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.touch_app_rounded,
                                  size: 12,
                                  color: _tapToPlaceSingularity
                                      ? _controllerColor
                                      : Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                _tapToPlaceSingularity
                                    ? "Tap Canvas..."
                                    : "Place on Canvas",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _tapToPlaceSingularity
                                      ? _controllerColor
                                      : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDirBtn(String arrow, Offset dir) {
    final isSelected = (_gravityDirection.dx - dir.dx).abs() < 0.25 &&
        (_gravityDirection.dy - dir.dy).abs() < 0.25;
    return GestureDetector(
      onTap: () => setState(() => _gravityDirection = dir),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? _controllerColor.withValues(alpha: 0.2)
              : const Color(0xFF17191D),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? _controllerColor
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Text(
          arrow,
          style: const TextStyle(fontSize: 11),
        ),
      ),
    );
  }

  /// Applies a named performance preset
  void _applyPerformancePreset(String preset) {
    setState(() {
      switch (preset) {
        case "Default":
          _adaptiveDensity = false;
          _enableAdaptivePerformance = false;
          _fastLineRendering = false;
          _frameRateIndependent = false;
          _lineRenderer = LineRenderer.stroke;
          _maxConnectionsPerParticle = null;
          _maxLinesPerFrame = null;
          _spatialCellMultiplier = 1.0;
          break;
        case "Adaptive":
          _adaptiveDensity = true;
          _enableAdaptivePerformance = true;
          _fastLineRendering = false;
          _frameRateIndependent = true;
          _lineRenderer = LineRenderer.stroke;
          _maxConnectionsPerParticle = null;
          _maxLinesPerFrame = null;
          _spatialCellMultiplier = 1.0;
          break;
        case "High FPS":
          _adaptiveDensity = true;
          _enableAdaptivePerformance = true;
          _fastLineRendering = true;
          _frameRateIndependent = true;
          _lineRenderer = LineRenderer.vertices;
          _maxConnectionsPerParticle = 4;
          _maxLinesPerFrame = 15000;
          _spatialCellMultiplier = 1.0;
          break;
      }
    });
  }

  /// Builds the dedicated Performance configuration section
  Widget _buildPerformanceSection() {
    final isHighFpsPreset = _adaptiveDensity &&
        _enableAdaptivePerformance &&
        _fastLineRendering &&
        _frameRateIndependent &&
        _lineRenderer == LineRenderer.vertices &&
        _maxConnectionsPerParticle == 4 &&
        _maxLinesPerFrame == 15000;

    final isAdaptivePreset = _adaptiveDensity &&
        _enableAdaptivePerformance &&
        !_fastLineRendering &&
        _frameRateIndependent &&
        _lineRenderer == LineRenderer.stroke &&
        _maxConnectionsPerParticle == null &&
        _maxLinesPerFrame == null;

    final isDefaultPreset = !_adaptiveDensity &&
        !_enableAdaptivePerformance &&
        !_fastLineRendering &&
        !_frameRateIndependent &&
        _lineRenderer == LineRenderer.stroke &&
        _maxConnectionsPerParticle == null &&
        _maxLinesPerFrame == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Presets row
        Row(
          children: [
            Expanded(
              child: _buildPresetButton(
                "Default",
                isDefaultPreset,
                () => _applyPerformancePreset("Default"),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildPresetButton(
                "Adaptive",
                isAdaptivePreset,
                () => _applyPerformancePreset("Adaptive"),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildPresetButton(
                "High FPS",
                isHighFpsPreset,
                () => _applyPerformancePreset("High FPS"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.35),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.grid_4x4, size: 14, color: Color(0xFF10B981)),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Spatial Engine: SortedSpatialGrid (Zero Heap Allocations)",
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildSlider(
          "Spatial Cell Multiplier",
          _spatialCellMultiplier,
          0.5,
          2.5,
          (v) => setState(() => _spatialCellMultiplier = v),
          fractionDigits: 2,
        ),
        const SizedBox(height: 12),

        // Line Renderer Selector (Stroke vs Vertices)
        Row(
          children: [
            Expanded(
              child: Text(
                "Line Renderer",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ),
            _buildPillToggle(
              label: "Stroke",
              isSelected: _lineRenderer == LineRenderer.stroke,
              onTap: () => setState(() => _lineRenderer = LineRenderer.stroke),
            ),
            const SizedBox(width: 6),
            _buildPillToggle(
              label: "Vertices",
              isSelected: _lineRenderer == LineRenderer.vertices,
              onTap: () =>
                  setState(() => _lineRenderer = LineRenderer.vertices),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Optimization Toggles
        Center(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _buildNeuToggleChip(
                label: "Adaptive Density",
                icon: Icons.grain_rounded,
                value: _adaptiveDensity,
                onChanged: (v) => setState(() => _adaptiveDensity = v),
              ),
              _buildNeuToggleChip(
                label: "Fast Line Draw",
                icon: Icons.flash_on_rounded,
                value: _fastLineRendering,
                onChanged: (v) => setState(() => _fastLineRendering = v),
              ),
              _buildNeuToggleChip(
                label: "Auto Quality",
                icon: Icons.auto_graph_rounded,
                value: _enableAdaptivePerformance,
                onChanged: (v) =>
                    setState(() => _enableAdaptivePerformance = v),
              ),
              _buildNeuToggleChip(
                label: "Delta-Time FPS",
                icon: Icons.av_timer_rounded,
                value: _frameRateIndependent,
                onChanged: (v) => setState(() => _frameRateIndependent = v),
              ),
              _buildNeuToggleChip(
                label: "Anti-Alias",
                icon: Icons.blur_on_rounded,
                value: _antiAlias,
                onChanged: (v) => setState(() => _antiAlias = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Hardware Budget Sliders
        _buildBudgetSlider(
          label: "Max Conn / Particle",
          value: (_maxConnectionsPerParticle ?? 0).toDouble(),
          min: 0,
          max: 20,
          displayValue: _maxConnectionsPerParticle == null
              ? "Off"
              : "$_maxConnectionsPerParticle",
          onChanged: (v) {
            setState(() {
              final val = v.round();
              _maxConnectionsPerParticle = val == 0 ? null : val;
            });
          },
        ),
        _buildBudgetSlider(
          label: "Max Lines / Frame",
          value: (_maxLinesPerFrame ?? 0).toDouble(),
          min: 0,
          max: 30000,
          displayValue: _maxLinesPerFrame == null
              ? "Off"
              : "${(_maxLinesPerFrame! / 1000).toStringAsFixed(1)}k",
          onChanged: (v) {
            setState(() {
              final val = (v / 500).round() * 500;
              _maxLinesPerFrame = val <= 0 ? null : val;
            });
          },
        ),
      ],
    );
  }

  /// Builds the Showcase Presets gallery
  Widget _buildPresetsGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Instant one-tap visual configurations:",
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 10),
        for (final preset in _presets) ...[
          GestureDetector(
            onTap: () => _applyFullPreset(preset),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1C21),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: preset.particleColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: preset.particleColor.withValues(alpha: 0.15),
                      border: Border.all(
                        color: preset.particleColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Icon(preset.icon,
                        size: 18, color: preset.particleColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preset.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          preset.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _controllerColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "Load",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _controllerColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Builds the inline code exporter
  Widget _buildExportInlineSection() {
    final code = _generateDartCode();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Flutter Code Snippet",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _controllerColor,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                minimumSize: const Size(0, 28),
              ),
              icon: const Icon(Icons.copy_rounded, size: 13),
              label: const Text(
                "Copy",
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Flutter code copied to clipboard!"),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 280),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF131518),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10.5,
                color: Color(0xFF38BDF8),
                height: 1.35,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a Neumorphic preset selection button
  Widget _buildPresetButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? _controllerColor.withValues(alpha: 0.15)
              : const Color(0xFF22262C),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? _controllerColor
                : Colors.white.withValues(alpha: 0.04),
            width: 1,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Colors.black54,
                    offset: Offset(1.5, 1.5),
                    blurRadius: 3,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    offset: const Offset(3, 3),
                    blurRadius: 5,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.06),
                    offset: const Offset(-2, -2),
                    blurRadius: 4,
                  ),
                ],
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? _controllerColor
                    : Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a compact pill toggle for renderer selection
  Widget _buildPillToggle({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? _controllerColor.withValues(alpha: 0.15)
              : const Color(0xFF1E2126),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? _controllerColor
                : Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? _controllerColor
                : Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  /// Builds a responsive slider for budget/limit numbers with custom string display
  Widget _buildBudgetSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF17191D),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.04),
                    width: 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  displayValue,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: _controllerColor,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              trackHeight: 4,
              activeTrackColor: _controllerColor,
              inactiveTrackColor: const Color(0xFF16181C),
              thumbColor: _controllerColor,
              overlayColor: _controllerColor.withValues(alpha: 0.15),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              trackShape: const RoundedRectSliderTrackShape(),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  /// Applies a named touch preset
  void _applyTouchPreset(String preset) {
    setState(() {
      switch (preset) {
        case "Default":
          _touchActivation = true;
          _touchSpeed = 0.42;
          _touchForce = 0.42;
          _maxTouchSpeed = 5.5;
          _touchDamping = 0.985;
          _touchLineDistance = 150.0;
          break;
        case "Magnetic":
          _touchActivation = true;
          _touchSpeed = 0.75;
          _touchForce = 1.20;
          _maxTouchSpeed = 8.0;
          _touchDamping = 0.960;
          _touchLineDistance = 220.0;
          break;
        case "Gentle":
          _touchActivation = true;
          _touchSpeed = 0.20;
          _touchForce = 0.15;
          _maxTouchSpeed = 3.0;
          _touchDamping = 0.992;
          _touchLineDistance = 120.0;
          break;
        case "Vortex":
          _touchActivation = true;
          _touchSpeed = 0.50;
          _touchForce = 0.70;
          _maxTouchSpeed = 10.0;
          _touchDamping = 0.980;
          _touchLineDistance = 280.0;
          break;
      }
    });
  }

  /// Builds the dedicated touch features configuration section
  Widget _buildTouchFeaturesSection() {
    final isDefault = (_touchForce - 0.42).abs() < 0.01 &&
        (_touchSpeed - 0.42).abs() < 0.01 &&
        (_maxTouchSpeed - 5.5).abs() < 0.1;
    final isMagnetic = (_touchForce - 1.20).abs() < 0.01;
    final isGentle = (_touchForce - 0.15).abs() < 0.01;
    final isVortex = (_touchForce - 0.70).abs() < 0.01 &&
        (_maxTouchSpeed - 10.0).abs() < 0.1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Presets row
        Row(
          children: [
            Expanded(
              child: _buildPresetButton(
                "Default",
                isDefault,
                () => _applyTouchPreset("Default"),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildPresetButton(
                "Magnetic",
                isMagnetic,
                () => _applyTouchPreset("Magnetic"),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildPresetButton(
                "Gentle",
                isGentle,
                () => _applyTouchPreset("Gentle"),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildPresetButton(
                "Vortex",
                isVortex,
                () => _applyTouchPreset("Vortex"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Toggles & Touch Color Chip
        Center(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _buildNeuToggleChip(
                label: "Touch Active",
                icon: Icons.fingerprint_rounded,
                value: _touchActivation,
                onChanged: (v) => setState(() => _touchActivation = v),
              ),
              _buildNeuToggleChip(
                label: "Mouse Hover",
                icon: Icons.mouse_rounded,
                value: _hoverEffect,
                onChanged: (v) => setState(() => _hoverEffect = v),
              ),
              _buildTouchColorChip(),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 2-column layout for physics sliders
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  _buildSlider(
                    "Attract Force",
                    _touchForce,
                    0.05,
                    2.0,
                    (v) => setState(() => _touchForce = v),
                    fractionDigits: 2,
                  ),
                  _buildSlider(
                    "Decay Speed",
                    _touchSpeed,
                    0.005,
                    1.0,
                    (v) => setState(() => _touchSpeed = v),
                    fractionDigits: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                children: [
                  _buildSlider(
                    "Max Speed",
                    _maxTouchSpeed,
                    1.0,
                    15.0,
                    (v) => setState(() => _maxTouchSpeed = v),
                    fractionDigits: 1,
                  ),
                  _buildSlider(
                    "Damping",
                    _touchDamping,
                    0.80,
                    0.999,
                    (v) => setState(() => _touchDamping = v),
                    fractionDigits: 3,
                  ),
                ],
              ),
            ),
          ],
        ),

        // Full width slider for Touch Line Distance
        _buildSlider(
          "Touch Line Dist",
          _touchLineDistance,
          0,
          500,
          (v) => setState(() => _touchLineDistance = v),
          fractionDigits: 0,
        ),
      ],
    );
  }

  /// Builds a tactile color selection chip for touch highlight color
  Widget _buildTouchColorChip() {
    return GestureDetector(
      onTap: () =>
          _showColorPicker("Touch", (c) => setState(() => _touchColor = c)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF22262C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _touchColor.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              offset: const Offset(3, 3),
              blurRadius: 5,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.06),
              offset: const Offset(-2, -2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _touchColor,
                boxShadow: [
                  BoxShadow(
                    color: _touchColor.withValues(alpha: 0.8),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              "Color",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a Neumorphic gravity type selection pill button
  Widget _buildGravityTypeButton(String label, GravityType type) {
    final isSelected = _gravityType == type;
    return GestureDetector(
      onTap: () => setState(() => _gravityType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? _controllerColor.withValues(alpha: 0.15)
              : const Color(0xFF22262C),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? _controllerColor
                : Colors.white.withValues(alpha: 0.04),
            width: 1,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Colors.black54,
                    offset: Offset(1.5, 1.5),
                    blurRadius: 3,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    offset: const Offset(3, 3),
                    blurRadius: 5,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.06),
                    offset: const Offset(-2, -2),
                    blurRadius: 4,
                  ),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? _controllerColor
                : Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  /// Builds the color picker section for particles, lines, touch, and background
  Widget _buildColorSection() {
    return Row(
      children: [
        Expanded(
          child: _buildColorTile(
            label: "Particle",
            currentColor: _particleColor,
            icon: Icons.grain_rounded,
            onSelect: (c) => setState(() => _particleColor = c),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildColorTile(
            label: "Line",
            currentColor: _lineColor,
            icon: Icons.timeline_rounded,
            onSelect: (c) => setState(() => _lineColor = c),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildColorTile(
            label: "Touch",
            currentColor: _touchColor,
            icon: Icons.ads_click_rounded,
            onSelect: (c) => setState(() => _touchColor = c),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildColorTile(
            label: "Backdrop",
            currentColor: _backgroundColor,
            icon: Icons.wallpaper_rounded,
            onSelect: (c) => setState(() => _backgroundColor = c),
          ),
        ),
      ],
    );
  }

  /// Builds a modern Neumorphic interactive color tile
  Widget _buildColorTile({
    required String label,
    required Color currentColor,
    required IconData icon,
    required ValueChanged<Color> onSelect,
  }) {
    return GestureDetector(
      onTap: () => _showColorPicker(label, onSelect),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF22262C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: currentColor.withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              offset: const Offset(3, 3),
              blurRadius: 5,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.06),
              offset: const Offset(-2, -2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF181A1E),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black54,
                    offset: Offset(1.5, 1.5),
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: currentColor,
                  boxShadow: [
                    BoxShadow(
                      color: currentColor.withValues(alpha: 0.5),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a Neumorphic styled dialog to pick a color
  void _showColorPicker(String label, ValueChanged<Color> onSelect) {
    const List<Color> palette = [
      Colors.white,
      Colors.black,
      Color(0xFF0F172A), // Dark slate
      Color(0xFF1E1B4B), // Dark indigo
      Colors.redAccent,
      Colors.deepOrangeAccent,
      Colors.orangeAccent,
      Colors.amberAccent,
      Colors.yellowAccent,
      Colors.greenAccent,
      Color(0xFF10B981), // Emerald
      Colors.tealAccent,
      Colors.cyanAccent,
      Colors.lightBlueAccent,
      Colors.blueAccent,
      Color(0xFF6366F1), // Indigo
      Colors.purpleAccent,
      Colors.pinkAccent,
    ];

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        buttonPadding: EdgeInsets.zero,
        backgroundColor: const Color(0xFF22262C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
        title: Row(
          children: [
            const Icon(Icons.palette_rounded, size: 18, color: _controllerColor),
            const SizedBox(width: 8),
            Text(
              "Select $label Color",
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: palette
              .map(
                (color) => GestureDetector(
                  onTap: () {
                    onSelect(color);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1E2126),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          offset: const Offset(3, 3),
                          blurRadius: 5,
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.08),
                          offset: const Offset(-1, -1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  /// Builds a responsive wrap of Neumorphic interactive toggle buttons
  Widget _buildSwitchesSection() {
    return Center(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _buildNeuToggleChip(
            label: "Network",
            icon: Icons.hub_rounded,
            value: _drawNetwork,
            onChanged: (v) => setState(() => _drawNetwork = v),
          ),
          _buildNeuToggleChip(
            label: "Fill",
            icon: Icons.format_color_fill_rounded,
            value: _isFill,
            onChanged: (v) => setState(() => _isFill = v),
          ),
          _buildNeuToggleChip(
            label: "Complex",
            icon: Icons.auto_awesome_rounded,
            value: _isComplex,
            onChanged: (v) => setState(() => _isComplex = v),
          ),
          _buildNeuToggleChip(
            label: "Anti-Alias",
            icon: Icons.blur_on_rounded,
            value: _antiAlias,
            onChanged: (v) => setState(() => _antiAlias = v),
          ),
          _buildNeuToggleChip(
            label: "Touch",
            icon: Icons.fingerprint_rounded,
            value: _touchActivation,
            onChanged: (v) => setState(() => _touchActivation = v),
          ),
          _buildNeuToggleChip(
            label: "Chart",
            icon: Icons.analytics_outlined,
            value: _showChart,
            onChanged: (v) => setState(() => _showChart = v),
          ),
        ],
      ),
    );
  }

  /// Builds a tactile Neumorphic toggle chip with glowing LED indicator
  Widget _buildNeuToggleChip({
    required String label,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF191B20) : const Color(0xFF22262C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value
                ? _controllerColor.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.04),
            width: 1,
          ),
          boxShadow: value
              ? const [
                  BoxShadow(
                    color: Colors.black54,
                    offset: Offset(1.5, 1.5),
                    blurRadius: 3,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    offset: const Offset(3, 3),
                    blurRadius: 5,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.06),
                    offset: const Offset(-2, -2),
                    blurRadius: 4,
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: value
                  ? _controllerColor
                  : Colors.white.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: value ? FontWeight.bold : FontWeight.w500,
                color: value
                    ? _controllerColor
                    : Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value
                    ? _controllerColor
                    : Colors.white.withValues(alpha: 0.12),
                boxShadow: value
                    ? [
                        BoxShadow(
                          color: _controllerColor.withValues(alpha: 0.8),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a responsive Neumorphic slider with stacked label/badge and full-width track
  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    int fractionDigits = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF17191D),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.04),
                    width: 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  value.toStringAsFixed(fractionDigits),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: _controllerColor,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              trackHeight: 4,
              activeTrackColor: _controllerColor,
              inactiveTrackColor: const Color(0xFF16181C),
              thumbColor: _controllerColor,
              overlayColor: _controllerColor.withValues(alpha: 0.15),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              trackShape: const RoundedRectSliderTrackShape(),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// A widget that displays FPS (Frames Per Second) overlay with optional chart
class FPS extends StatefulWidget {
  const FPS({
    super.key,
    required this.child,
    this.alignment = Alignment.topRight,
    this.visible = true,
    this.showChart = true,
  });

  final Widget child;
  final Alignment alignment;
  final bool visible;
  final bool showChart;

  @override
  State<FPS> createState() => _FPSState();
}

class _FPSState extends State<FPS> with SingleTickerProviderStateMixin {
  static const int _maxTimingsLength = 72;
  static const int _microsecondsPerSecond = 1000000;

  late final flutter_scheduler.Ticker _ticker;
  final ListQueue<Duration> _timings = ListQueue();
  final ValueNotifier<double> _fpsNotifier = ValueNotifier(0.0);
  final ListQueue<double> _fpsHistory = ListQueue();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    if (widget.visible) {
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    _timings.addLast(elapsed);

    if (_timings.length > _maxTimingsLength) {
      _timings.removeFirst();
    }

    if (_timings.length > 1) {
      final first = _timings.first;
      final last = _timings.last;

      final duration = last.inMicroseconds - first.inMicroseconds;
      if (duration > 0) {
        final currentFps =
            (_timings.length - 1) * _microsecondsPerSecond / duration;

        _fpsNotifier.value = currentFps;

        if (widget.showChart) {
          _fpsHistory.addLast(currentFps);
          if (_fpsHistory.length > _maxTimingsLength) {
            _fpsHistory.removeFirst();
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _fpsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.visible)
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: widget.alignment,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: ValueListenableBuilder<double>(
                      valueListenable: _fpsNotifier,
                      builder: (context, fpsValue, _) {
                        return _buildOverlay(fpsValue);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOverlay(double fps) {
    final Color color = _getFpsColor(fps);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 4),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                "${fps.toStringAsFixed(1)} FPS",
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        if (widget.showChart && _fpsHistory.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 140,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: CustomPaint(
              painter: _FPSChartPainter(_fpsHistory, color),
            ),
          ),
      ],
    );
  }

  /// Returns the appropriate color based on FPS value
  Color _getFpsColor(double fps) {
    if (fps >= 55) return Colors.greenAccent;
    if (fps >= 30) return Colors.orangeAccent;
    return Colors.redAccent;
  }
}

/// Custom painter for rendering the FPS chart
class _FPSChartPainter extends CustomPainter {
  _FPSChartPainter(this.values, this.color);

  final ListQueue<double> values;
  final Color color;

  static const double _maxFps = 120.0;
  static const double _chartWidth = 80.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.4), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    final double stepX = size.width / _chartWidth;
    final int count = values.length;
    final int lastIdx = count - 1;
    int i = 0;

    for (final double fpsVal in values) {
      final double x = i * stepX;
      final double y = size.height -
          (fpsVal / _maxFps * size.height).clamp(0.0, size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      if (i == lastIdx) {
        fillPath.lineTo(x, size.height);
        fillPath.close();
      }
      i++;
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FPSChartPainter oldDelegate) => true;
}
