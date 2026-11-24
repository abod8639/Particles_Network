import 'package:material_ui/material_ui.dart';
import 'package:particles_network/particles_network.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Particles Network Examples',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF070B14),
        colorScheme: const ColorScheme.dark(
          primary: Color.fromARGB(255, 0, 0, 0),
          surface: Color(0xFF111827),
        ),
      ),
      home: const ParticleExamplesScreen(),
    );
  }
}

/// Showcase screen allowing direct switching between [ParticleNetwork] examples.
class ParticleExamplesScreen extends StatefulWidget {
  const ParticleExamplesScreen({super.key});

  @override
  State<ParticleExamplesScreen> createState() => _ParticleExamplesScreenState();
}

class _ParticleExamplesScreenState extends State<ParticleExamplesScreen> {
  int _currentIndex = 0;

  static const List<String> _titles = [
    'Cosmic Web',
    'Cyberpunk Matrix',
    'Black Hole',
    'Supernova',
    'Neural Synapse',
    'Quantum Foam',
    'Swarm',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Particles Network'),
        elevation: 0,
        backgroundColor: const Color(0xFF0F172A),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: SizedBox(
            height: 48,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: List.generate(_titles.length, (index) {
                  final isSelected = _currentIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_titles[index]),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _currentIndex = index);
                        }
                      },
                      selectedColor: const Color(0xFF38BDF8),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
      body: _buildExample(_currentIndex),
    );
  }

  Widget _buildExample(int index) {
    switch (index) {
      case 0:
        return const CosmicWebExample();
      case 1:
        return const CyberpunkMatrixExample();
      case 2:
        return const BlackHoleExample();
      case 3:
        return const SupernovaExample();
      case 4:
        return const NeuralSynapseExample();
      case 5:
        return const QuantumFoamExample();
      case 6:
        return const SwarmExample();
      default:
        return const CosmicWebExample();
    }
  }
}

double? getResponsiveLineDistance([BuildContext? context]) {
  final effectiveContext = context;
  if (effectiveContext == null) return null;
  final width = MediaQuery.sizeOf(effectiveContext).width;
  if (width < 600) {
    return 60.0;
  } else if (width < 1024.0) {
    return 80.0;
  } else {
    return 100.0;
  }
}

/// 1. Cosmic Web: Delicate starlight web drifting slowly in deep space.
class CosmicWebExample extends StatelessWidget {
  const CosmicWebExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF070B14),
      child: ParticleNetwork(
        network: NetworkFeatures(
          width: 0.8,
          distance: getResponsiveLineDistance(context),
          color: const Color(0xFF38BDF8),
        ),
        particles: const ParticleFeatures(
          count: 220,
          maxSpeed: 2.2,
          maxSize: 2.5,
          color: Colors.transparent,
        ),
        touch: const TouchFeatures(
          color: Color(0xFFFBBF24),
          force: 0.35,
          speed: 0.30,
          maxSpeed: 4.0,
          distance: 170.0,
        ),
      ),
    );
  }
}

/// 2. Cyberpunk Matrix: Digital rain downward gravity with neon colors.
class CyberpunkMatrixExample extends StatelessWidget {
  const CyberpunkMatrixExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF02120A),
      child: const ParticleNetwork(
        particles: ParticleFeatures(
          count: 350,
          maxSpeed: 6.5,
          maxSize: 2.2,
          color: Color(0xFF10B981),
        ),
        network: NetworkFeatures(
          width: 1.2,
          distance: 70.0,
          color: Color(0xFF06B6D4),
        ),
        gravity: GravityFeatures.global(
          strength: 0.40,
          direction: Offset(0, 1),
        ),
        touch: TouchFeatures(
          color: Color(0xFFF43F5E),
          force: 0.80,
          speed: 0.50,
          damping: 0.970,
          maxSpeed: 7.0,
          distance: 200.0,
        ),
        performance: PerformanceFeatures(frameRateIndependent: true),
      ),
    );
  }
}

/// 3. Black Hole: Gravitational point vortex pulling particles inward.
class BlackHoleExample extends StatelessWidget {
  const BlackHoleExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF030107),
      child: const ParticleNetwork(
        particles: ParticleFeatures(
          fill: false,
          count: 400,
          maxSpeed: 4.8,
          maxSize: 3.0,
          color: Color(0xFFF59E0B),
        ),
        network: NetworkFeatures(
          width: 1.5,
          distance: 95.0,
          color: Color(0xFFEC4899),
        ),
        gravity: GravityFeatures.point(strength: 0.85),
        touch: TouchFeatures(
          color: Color(0xFF8B5CF6),
          force: 1.0,
          speed: 0.65,
          damping: 0.965,
          maxSpeed: 9.0,
          distance: 220.0,
        ),
        performance: PerformanceFeatures(
          maxConnectionsPerParticle: 6,
          autoBoost: true,
        ),
      ),
    );
  }
}

/// 4. Supernova: Radial repulsive point gravity pushing particles outward.
class SupernovaExample extends StatelessWidget {
  const SupernovaExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0C0303),
      child: const ParticleNetwork(
        particles: ParticleFeatures(
          count: 450,
          maxSpeed: 8.0,
          maxSize: 3.2,
          color: Color(0xFFEF4444),
        ),
        network: NetworkFeatures(
          width: 1.4,
          distance: 85.0,
          color: Color(0xFFF97316),
        ),
        gravity: GravityFeatures(strength: -0.9, type: GravityType.point),
        touch: TouchFeatures(
          color: Color(0xFFFDE047),
          force: 0.90,
          speed: 0.50,
          damping: 0.975,
          maxSpeed: 10.0,
          distance: 230.0,
        ),
        performance: PerformanceFeatures(
          maxConnectionsPerParticle: 5,
          maxLinesPerFrame: 15000,
          autoBoost: true,
        ),
      ),
    );
  }
}

/// 5. Neural Synapse: High-density interactive touch mesh.
class NeuralSynapseExample extends StatelessWidget {
  const NeuralSynapseExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF080718),
      child: ParticleNetwork(
        particles: const ParticleFeatures(
          count: 300,
          maxSpeed: 3.5,
          maxSize: 2.4,
          color: Color(0xFFA855F7),
        ),
        network: NetworkFeatures(
          width: 1.1,
          distance: getResponsiveLineDistance(context),
          color: const Color(0xFF38BDF8),
        ),
        touch: const TouchFeatures(
          color: Color(0xFF34D399),
          speed: 0.40,
          damping: 0.980,
          maxSpeed: 6.0,
          distance: 190.0,
        ),
        performance: const PerformanceFeatures(frameRateIndependent: true),
      ),
    );
  }
}

/// 6. Quantum Foam: Rapid kinetic decay micro-particles with cyan glow.
class QuantumFoamExample extends StatelessWidget {
  const QuantumFoamExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF050814),
      child: const ParticleNetwork(
        particles: ParticleFeatures(
          count: 400,
          maxSpeed: 5.0,
          maxSize: 1.8,
          color: Color(0xFF22D3EE),
        ),
        network: NetworkFeatures(
          width: 0.9,
          distance: 75.0,
          color: Color(0xFF818CF8),
        ),
        touch: TouchFeatures(
          color: Color(0xFFE879F9),
          speed: 0.45,
          maxSpeed: 7.0,
          distance: 150.0,
        ),
        performance: PerformanceFeatures(
          frameRateIndependent: true,
          complex: ComplexConfig(enabled: true),
        ),
      ),
    );
  }
}

/// 7. Swarm: 1000 hardware-accelerated batched particles.
class SwarmExample extends StatelessWidget {
  const SwarmExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF070B16),
      child: const ParticleNetwork(
        particles: ParticleFeatures(
          count: 1000,
          maxSpeed: 4.5,
          maxSize: 1.6,
          color: Color(0xFF38BDF8),
        ),
        network: NetworkFeatures(
          width: 1.3,
          distance: 65.0,
          color: Color(0xFF6366F1),
        ),
        touch: TouchFeatures(
          color: Color(0xFF10B981),
          force: 0.50,
          speed: 0.45,
          maxSpeed: 6.0,
          distance: 140.0,
        ),
        performance: PerformanceFeatures(
          maxConnectionsPerParticle: 4,
          maxLinesPerFrame: 15000,
          autoBoost: true,
          frameRateIndependent: true,
        ),
      ),
    );
  }
}
