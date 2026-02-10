import 'package:flutter/material.dart';
import 'package:particles_network/particles_network.dart';
import 'package:show_fps/show_fps.dart';

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
  // --- Particle Network Configuration Variables ---
  bool drawNetwork = true;
  bool isFill = false;
  bool isComplex = false;
  bool touchActivation = true;
  double lineWidth = 1.0;
  int particleCount = 100;
  double maxSpeed = 1.5;
  double maxSize = 3.0;
  double lineDistance = 200.0;

  // --- Styling Variables ---
  Color particleColor = Colors.white;
  Color lineColor = Colors.white.withOpacity(0.5);
  Color touchColor = Colors.amber;
  Color controllerColor = Colors.tealAccent;

  // UI state to toggle control panel visibility
  bool showPanel = true;

  // UniqueKey is used to force a full rebuild of the ParticleNetwork
  // when engine-critical parameters change (Count, Speed, Size).
  Key particleKey = UniqueKey();

  // Refreshes the particle engine by generating a new key
  void _refreshEngine() {
    setState(() {
      particleKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // Floating button to hide/show settings
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: controllerColor,
        child: Icon(
          showPanel ? Icons.keyboard_arrow_up : Icons.settings,
          color: Colors.black,
        ),
        onPressed: () => setState(() => showPanel = !showPanel),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Animated Header Panel for Controls
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              height: showPanel ? 320 : 0,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: _buildAdvancedControlPanel(),
              ),
            ),

            // The Particle Network Display Area
            Expanded(
              child: ShowFPS(
                alignment: Alignment.topRight,
                visible: true,
                showChart: false,
                child: ParticleNetwork(
                  key: particleKey, // Key updates only on critical parameter changes
                  drawNetwork: drawNetwork,
                  fill: isFill,
                  isComplex: isComplex,
                  lineWidth: lineWidth,
                  touchActivation: touchActivation,
                  particleCount: particleCount,
                  maxSpeed: maxSpeed,
                  maxSize: maxSize,
                  lineDistance: lineDistance,
                  particleColor: particleColor,
                  lineColor: lineColor,
                  touchColor: touchColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds the main control panel containing all settings
  Widget _buildAdvancedControlPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[900],
      height: 320,
      child: ListView(
        children: [
          _buildColorSection(),
          const Divider(),
          _buildSwitchesSection(),
          const Divider(),
          // Standard UI Parameters (Real-time update without engine restart)
          _buildSlider(
            "Line Width",
            lineWidth,
            0.1,
            20.0,
            (v) => setState(() => lineWidth = v),
          ),
          _buildSlider(
            "Line Dist",
            lineDistance,
            10,
            500,
            (v) => setState(() => lineDistance = v),
          ),
          const Divider(),
          // Engine Critical Parameters (Requires _refreshEngine)
          _buildSlider("Count *", particleCount.toDouble(), 10, 1000, (v) {
            setState(() => particleCount = v.toInt());
            _refreshEngine();
          }),

          _buildSlider("Speed *", maxSpeed, 0.1, 20.0, (v) {
            setState(() => maxSpeed = v);
            _refreshEngine();
          }),

          _buildSlider("Max Size *", maxSize, 0.5, 20.0, (v) {
            setState(() => maxSize = v);
            _refreshEngine();
          }),
        ],
      ),
    );
  }

  // Color Picker Row for Particles, Lines, and Touch
  Widget _buildColorSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildColorButton(
          "Particle",
          particleColor,
          (c) => setState(() => particleColor = c),
        ),
        _buildColorButton(
          "Line",
          lineColor,
          (c) => setState(() => lineColor = c),
        ),
        _buildColorButton(
          "Touch",
          touchColor,
          (c) => setState(() => touchColor = c),
        ),
      ],
    );
  }

  // Individual color selection button
  Widget _buildColorButton(
    String label,
    Color currentColor,
    Function(Color) onSelect,
  ) {
    return Column(
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

  // Dialog to pick a color from a predefined palette
  void _showColorPicker(String label, Function(Color) onSelect) {
    List<Color> palette = [
      Colors.white,
      Colors.redAccent,
      Colors.greenAccent,
      Colors.blueAccent,
      Colors.amberAccent,
      Colors.purple,
      Colors.cyanAccent,
      Colors.pinkAccent,
    ];
    showDialog(
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

  // Horizontal list of toggle switches (Boolean controls)
  Widget _buildSwitchesSection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildSwitch(
            "Network",
            drawNetwork,
            (v) => setState(() => drawNetwork = v),
          ),
          _buildSwitch("Fill", isFill, (v) => setState(() => isFill = v)),
          _buildSwitch(
            "Complex",
            isComplex,
            (v) => setState(() => isComplex = v),
          ),
          _buildSwitch(
            "Touch",
            touchActivation,
            (v) => setState(() => touchActivation = v),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: controllerColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  // Custom slider with label and value display
  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
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
            activeColor: controllerColor,
            onChanged: onChanged,
          ),
        ),
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(fontSize: 10, color: controllerColor),
        ),
      ],
    );
  }
}





