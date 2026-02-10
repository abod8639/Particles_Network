import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' as flutter_scheduler;
import 'package:particles_network/particles_network.dart';

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
  static const double _controlPanelHeight = 350.0;
  static const Duration _animationDuration = Duration(milliseconds: 400);
  
  // --- Particle Network Configuration Variables ---
  bool _drawNetwork = true;
  bool _isFill = false;
  bool _isComplex = false;
  bool _touchActivation = true;
  double _lineWidth = 1.0;
  int _particleCount = 100;
  double _maxSpeed = 1.5;
  double _maxSize = 2.0;
  double _lineDistance = 100.0;
  GravityType _gravityType = GravityType.none;
  double _gravityStrength = 0.1;
  Offset _gravityDirection = const Offset(0, 1);

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
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: _controllerColor,
        onPressed: _togglePanel,
        child: Icon(
          _showPanel ? Icons.keyboard_arrow_up : Icons.settings,
          color: Colors.black,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Animated Header Panel for Controls
            AnimatedContainer(
              duration: _animationDuration,
              curve: Curves.easeInOut,
              height: _showPanel ? _controlPanelHeight : 0,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: _buildAdvancedControlPanel(),
              ),
            ),

            // The Particle Network Display Area
            Expanded(
              child: FPS(
                alignment: Alignment.topRight,
                showChart: _showChart,
                child: ParticleNetwork(
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

  /// Builds the main control panel containing all settings
  Widget _buildAdvancedControlPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[900],
      height: _controlPanelHeight,
      child: ListView(
        children: [
          _buildColorSection(),
          const Divider(),
          _buildSwitchesSection(),
          const Divider(),
          // Standard UI Parameters (Real-time update without engine restart)
          _buildSlider(
            "Line Width",
            _lineWidth,
            0.1,
            20.0,
            (v) => setState(() => _lineWidth = v),
          ),
          _buildSlider(
            "Line Dist",
            _lineDistance,
            10,
            500,
            (v) => setState(() => _lineDistance = v),
          ),
          const Divider(),
          // Engine Critical Parameters (Requires _refreshEngine)
          _buildSlider("Count *", _particleCount.toDouble(), 10, 1000, (v) {
            setState(() => _particleCount = v.toInt());
            _refreshEngine();
          }),
          _buildSlider("Speed *", _maxSpeed, 0.1, 20.0, (v) {
            setState(() => _maxSpeed = v);
            _refreshEngine();
          }),
          _buildSlider("Max Size *", _maxSize, 0.5, 20.0, (v) {
            setState(() => _maxSize = v);
            _refreshEngine();
          }),
          const Divider(),
          _buildGravitySection(),
        ],
      ),
    );
  }

  /// Builds the gravity configuration section
  Widget _buildGravitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Gravity Settings",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildGravityTypeButton("None", GravityType.none),
            _buildGravityTypeButton("Global", GravityType.global),
            _buildGravityTypeButton("Point", GravityType.point),
          ],
        ),
        _buildSlider(
          "Strength",
          _gravityStrength,
          -2.0,
          2.0,
          (v) => setState(() => _gravityStrength = v),
        ),
        Row(
          children: [
            const SizedBox(
              width: 80,
              child: Text("Direction", style: TextStyle(fontSize: 10)),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Slider(
                      activeColor: _controllerColor,
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
                  Text(
                    _gravityDirection.toString().replaceAll("Direction", ""),
                    style: TextStyle(color: _controllerColor, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds a gravity type selection button
  Widget _buildGravityTypeButton(String label, GravityType type) {
    final isSelected = _gravityType == type;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? _controllerColor : Colors.grey[800],
        foregroundColor: isSelected ? Colors.black : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(60, 30),
      ),
      onPressed: () => setState(() => _gravityType = type),
      child: Text(label, style: const TextStyle(fontSize: 10)),
    );
  }

  /// Builds the color picker section for particles, lines, and touch
  Widget _buildColorSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildColorButton(
          "Particle",
          _particleColor,
          (c) => setState(() => _particleColor = c),
        ),
        _buildColorButton(
          "Line",
          _lineColor,
          (c) => setState(() => _lineColor = c),
        ),
        _buildColorButton(
          "Touch",
          _touchColor,
          (c) => setState(() => _touchColor = c),
        ),
      ],
    );
  }

  /// Builds an individual color selection button
  Widget _buildColorButton(
    String label,
    Color currentColor,
    ValueChanged<Color> onSelect,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        GestureDetector(
          onTap: () => _showColorPicker(label, onSelect),
          child: Container(
            margin: const EdgeInsets.only(top: 5),
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: currentColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
          ),
        ),
      ],
    );
  }

  /// Shows a dialog to pick a color from a predefined palette
  void _showColorPicker(String label, ValueChanged<Color> onSelect) {
    const List<Color> palette = [
      Colors.white,
      Colors.redAccent,
      Colors.greenAccent,
      Colors.blueAccent,
      Colors.amberAccent,
      Colors.purple,
      Colors.cyanAccent,
      Colors.pinkAccent,
    ];
    
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Select $label Color",
          style: const TextStyle(fontSize: 16),
        ),
        content: Wrap(
          alignment: WrapAlignment.center,
          children: palette
              .map(
                (color) => GestureDetector(
                  onTap: () {
                    onSelect(color);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  /// Builds a horizontal list of toggle switches for boolean controls
  Widget _buildSwitchesSection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Wrap(
        children: [
          _buildSwitch(
            "Network",
            _drawNetwork,
            (v) => setState(() => _drawNetwork = v),
          ),
          _buildSwitch("Fill", _isFill, (v) => setState(() => _isFill = v)),
          _buildSwitch(
            "Complex",
            _isComplex,
            (v) => setState(() => _isComplex = v),
          ),
          _buildSwitch(
            "Touch",
            _touchActivation,
            (v) => setState(() => _touchActivation = v),
          ),
          const SizedBox(width: 30),
          _buildSwitch(
            "Chart",
            _showChart,
            (v) => setState(() => _showChart = v),
          ),
        ],
      ),
    );
  }

  /// Builds a labeled switch widget
  Widget _buildSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 10)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: _controllerColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  /// Builds a custom slider with label and value display
  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontSize: 10)),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            activeColor: _controllerColor,
            onChanged: onChanged,
          ),
        ),
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(fontSize: 10, color: _controllerColor),
        ),
      ],
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
  final List<double> _fpsHistory = [];

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
        final currentFps = (_timings.length - 1) * _microsecondsPerSecond / duration;
        
        _fpsNotifier.value = currentFps;
        
        if (widget.showChart) {
          _fpsHistory.add(currentFps);
          if (_fpsHistory.length > _maxTimingsLength) {
            _fpsHistory.removeAt(0);
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

  final List<double> values;
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

    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final y = size.height - (values[i] / _maxFps * size.height).clamp(0.0, size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
      
      if (i == values.length - 1) {
        fillPath.lineTo(x, size.height);
        fillPath.close();
      }
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FPSChartPainter oldDelegate) => true;
}