import 'dart:collection';
import 'dart:math' as math;

import 'package:particles_network/particles_network.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' as flutter_scheduler;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(), // Using Dark Theme for better contrast
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

class ParticleControllerScreen extends StatefulWidget {
  const ParticleControllerScreen({super.key});
  @override
  State<ParticleControllerScreen> createState() =>
      _ParticleControllerScreenState();
}

class _ParticleControllerScreenState extends State<ParticleControllerScreen> {
  // --- UI Constants ---
  static const double _controlPanelHeight = 390.0;
  static const Duration _animationDuration = Duration(milliseconds: 400);

  // --- Particle Network Configuration Variables ---
  bool _drawNetwork = true;
  bool _isFill = false;
  bool _isComplex = false;
  bool _touchActivation = true;
  double _lineWidth = 1.0;
  int _particleCount = 500;
  double _maxSpeed = 1.5;
  double _maxSize = 2.0;
  double _lineDistance = 50.0;
  GravityType _gravityType = GravityType.none;
  double _gravityStrength = 0.1;
  Offset _gravityDirection = const Offset(0, 1);
  final bool _hoverEffect = false;

  // --- Touch Features Variables ---
  double _touchSpeed = 0.012;
  double _touchForce = 0.42;
  double _maxTouchSpeed = 3.0;
  double _touchLineDistance = 100.0;

  // --- Styling Variables ---
  Color _particleColor = Colors.white;
  Color _lineColor = Colors.white;
  Color _touchColor = Colors.amber;
  final Color _controllerColor = Colors.tealAccent;

  // --- UI State ---
  bool _showPanel = true;
  bool _showChart = false;

  /// UniqueKey is used to force a full rebuild of the ParticleNetwork
  /// when engine-critical parameters change (Count, Speed, Size).
  Key _particleKey = UniqueKey();

  /// Refreshes the particle engine by generating a new key.
  /// This forces a complete rebuild of the particle system.
  void _refreshEngine() {
    setState(() {
      _particleKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: GestureDetector(
        onTap: _togglePanel,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF22262C),
            border: Border.all(
              color: _controllerColor.withValues(alpha: 0.35),
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
            _showPanel ? Icons.keyboard_arrow_up_rounded : Icons.tune_rounded,
            color: _controllerColor,
            size: 22,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Animated Header Panel for Controls
            AnimatedCrossFade(
              duration: _animationDuration,
              crossFadeState: _showPanel
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              sizeCurve: Curves.easeInOut,
              firstChild: _buildAdvancedControlPanel(),
              secondChild: const SizedBox(width: double.infinity, height: 0),
            ),
            Expanded(
              child: FPS(
                alignment: Alignment.topRight,
                showChart: _showChart,
                child: ParticleNetwork(
                  touchFeatures: TouchFeatures(
                    speed: _touchSpeed,
                    force: _touchForce,
                    maxTouchSpeed: _maxTouchSpeed,
                    lineDistance: _touchLineDistance,
                  ),
                  key: _particleKey,
                  drawNetwork: _drawNetwork,
                  fill: _isFill,
                  isComplex: _isComplex,
                  lineWidth: _lineWidth,
                  touchActivation: _touchActivation,
                  particleCount: _particleCount,
                  maxSpeed: _maxSpeed,
                  maxSize: _maxSize,
                  lineDistance: _lineDistance,
                  particleColor: _particleColor,
                  lineColor: _lineColor,
                  touchColor: _touchColor,
                  gravityType: _gravityType,
                  gravityStrength: _gravityStrength,
                  gravityDirection: _gravityDirection,
                  hoverEffect: _hoverEffect,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Toggles the visibility of the control panel
  void _togglePanel() {
    setState(() {
      _showPanel = !_showPanel;
    });
  }

  /// Builds a Neumorphic styled card container with soft extruded shadows
  Widget _buildNeuCard({
    required Widget child,
    String? title,
    IconData? icon,
    EdgeInsetsGeometry padding = const EdgeInsets.all(12),
    EdgeInsetsGeometry margin = const EdgeInsets.only(bottom: 12),
  }) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF22262C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.04),
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
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );
  }

  /// Builds the main control panel containing all settings in Neumorphism style
  Widget _buildAdvancedControlPanel() {
    return Container(
      height: _controlPanelHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2126),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            offset: const Offset(0, 10),
            blurRadius: 18,
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          children: [
            // Palette & Display Options
            _buildNeuCard(
              title: "Palette & Display Options",
              icon: Icons.palette_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildColorSection(),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 12),
                  _buildSwitchesSection(),
                ],
              ),
            ),
            // Line Dynamics
            _buildNeuCard(
              title: "Line Dynamics",
              icon: Icons.linear_scale_rounded,
              child: Row(
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
                  Expanded(
                      child: _buildSlider(
                    "Line Dist",
                    _lineDistance,
                    0,
                    200,
                    (v) => setState(() => _lineDistance = v),
                  ))
                ],
              ),
            ),
            // Engine Critical Parameters
            _buildNeuCard(
              title: "Engine Parameters (*Rebuilds)",
              icon: Icons.speed_rounded,
              child: Column(
                children: [
                  _buildSlider(
                    "Count *",
                    _particleCount.toDouble(),
                    10,
                    1000,
                    (v) {
                      setState(() => _particleCount = v.toInt());
                      _refreshEngine();
                    },
                  ),
                  _buildSlider(
                    "Speed *",
                    _maxSpeed,
                    0.1,
                    20.0,
                    (v) {
                      setState(() => _maxSpeed = v);
                      _refreshEngine();
                    },
                  ),
                  _buildSlider(
                    "Max Size *",
                    _maxSize,
                    0.5,
                    20.0,
                    (v) {
                      setState(() => _maxSize = v);
                      _refreshEngine();
                    },
                  ),
                ],
              ),
            ),
            // Gravity Settings
            _buildNeuCard(
              title: "Touch Interaction",
              icon: Icons.touch_app_rounded,
              child: _buildTouchFeaturesSection(),
            ),
            _buildNeuCard(
              title: "Gravity Settings",
              icon: Icons.public_rounded,
              child: _buildGravitySection(),
            ),
            // Touch Features Settings
          ],
        ),
      ),
    );
  }

  /// Builds the gravity configuration section with Neumorphic controls
  Widget _buildGravitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildGravityTypeButton("None", GravityType.none),
            _buildGravityTypeButton("Global", GravityType.global),
            _buildGravityTypeButton("Point", GravityType.point),
          ],
        ),
        const SizedBox(height: 8),
        _buildSlider(
          "Strength",
          _gravityStrength,
          -2.0,
          2.0,
          (v) => setState(() => _gravityStrength = v),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              SizedBox(
                width: 85,
                child: Text(
                  "Direction",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
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
              ),
              Container(
                width: 46,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
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
                  "${_gravityDirection.dx.toStringAsFixed(1)},${_gravityDirection.dy.toStringAsFixed(1)}",
                  style: TextStyle(
                    fontSize: 9,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: _controllerColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the touch features configuration section
  Widget _buildTouchFeaturesSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              _buildSlider(
                "Touch Speed",
                _touchSpeed,
                0.005,
                0.08,
                (v) => setState(() => _touchSpeed = v),
              ),
              _buildSlider(
                "Touch Force",
                _touchForce,
                0.05,
                1.5,
                (v) => setState(() => _touchForce = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              _buildSlider(
                "Max Touch Speed",
                _maxTouchSpeed,
                1.0,
                5.0,
                (v) => setState(() => _maxTouchSpeed = v),
              ),
              _buildSlider(
                "Touch Line Dist",
                _touchLineDistance,
                0,
                500,
                (v) => setState(() => _touchLineDistance = v),
              ),
            ],
          ),
        ),
      ],
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

  /// Builds the color picker section for particles, lines, and touch with Neumorphic tiles
  Widget _buildColorSection() {
    return Row(
      children: [
        Expanded(
          child: _buildColorTile(
            isSelected: true,
            label: "Particle",
            currentColor: _particleColor,
            icon: Icons.grain_rounded,
            onSelect: (c) => setState(() => _particleColor = c),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildColorTile(
            isSelected: false,
            label: "Line",
            currentColor: _lineColor,
            icon: Icons.timeline_rounded,
            onSelect: (c) => setState(() => _lineColor = c),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildColorTile(
            isSelected: false,
            label: "Touch",
            currentColor: _touchColor,
            icon: Icons.ads_click_rounded,
            onSelect: (c) => setState(() => _touchColor = c),
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
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _showColorPicker(label, onSelect),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
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
            // Sunken well for the color swatch
            Container(
              width: isSelected ? 26 : 80,
              height: isSelected ? 26 : 10,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: isSelected ? BoxShape.circle : BoxShape.rectangle,
                color: const Color(0xFF181A1E),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    offset: Offset(1.5, 1.5),
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: isSelected ? BoxShape.circle : BoxShape.rectangle,
                  color: currentColor,
                  boxShadow: [
                    BoxShadow(
                      color: currentColor.withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 11,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
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
      Colors.redAccent,
      Colors.greenAccent,
      Colors.blueAccent,
      Colors.amberAccent,
      Colors.purpleAccent,
      Colors.cyanAccent,
      Colors.pinkAccent,
    ];

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF22262C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.palette_rounded, size: 18, color: _controllerColor),
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
          spacing: 12,
          runSpacing: 12,
          children: palette
              .map(
                (color) => GestureDetector(
                  onTap: () {
                    onSelect(color);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 42,
                    height: 42,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1E2126),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          offset: const Offset(3, 3),
                          blurRadius: 5,
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.08),
                          offset: const Offset(-2, -2),
                          blurRadius: 4,
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
                fontSize: 11,
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

  /// Builds a Neumorphic slider with a recessed numeric badge
  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal:3 ),
      child: Row(
        children: [
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              
              data: SliderThemeData(
                padding:const EdgeInsetsGeometry.symmetric(horizontal: 10),
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
          ),
          Container(
            width: 50,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
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
              value.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: _controllerColor,
              ),
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
            _fpsHistory.removeFirst(); // O(1) vs O(n) removeAt(0) on List
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
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 6),
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
              const SizedBox(width: 9),
              Text(
                "${fps.toStringAsFixed(1)} FPS",
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        if (widget.showChart && _fpsHistory.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 1),
            width: 150,
            height: 40,
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

  static const double _maxFps = 72.0;
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
