import 'package:flutter/material.dart';
import 'package:particles_network/particles_network.dart';

void main() {
  runApp(const MyApp());
}

/// Example app demonstrating the usage of ParticleNetwork widget.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: ParticleNetwork(
          touchActivation: true, // to Activate touch
          particleCount: 50, // Number of particles
          maxSpeed: 0.5, // Maximum particle speed
          maxSize: 3.5, // Maximum particle size
          lineDistance: 200, // Maximum distance for connecting lines
          particleColor: Colors.white,
          lineColor: Colors.greenAccent,
          touchColor: Colors.amber,
        ),
      ),
    );
  }
}
