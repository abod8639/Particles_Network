import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:particles_network/model/particlemodel.dart';

/// A [CustomPainter] that renders the particle network using a fragment shader.
///
/// This painter handles passing the uniform data (resolution, colors, particle positions)
/// to the provided [FragmentShader] and draws the resulting output on the canvas.
class ShaderNetworkPainter extends CustomPainter {
  /// The compiled fragment shader used to render the network.
  final FragmentShader shader; 
  
  /// The list of particles to be rendered by the shader.
  ///
  /// Note: The shader normally has a fixed limit on the number of particles it can process.
  final List<Particle> particles;
  
  /// The maximum distance between particles to draw a connecting line.
  ///
  /// This value is passed to the shader to determine line visibility.
  final double lineDistance;
  
  /// The color of the particles.
  final Color particleColor;
  
  /// The color of the connecting lines.
  final Color lineColor;
  
  /// The actual number of active particles to be processed.
  final int particleCount;

  /// The paint object used to draw the shader on the canvas.
  final Paint _paint;

  /// Creates a [ShaderNetworkPainter].
  ///
  /// Requires a [shader] (initialized [FragmentShader]), the list of [particles],
  /// drawing parameters like [lineDistance], [particleColor], [lineColor],
  /// and the [particleCount].
  ShaderNetworkPainter({
    required this.shader,
    required this.particles,
    required this.lineDistance,
    required this.particleColor,
    required this.lineColor,
    required this.particleCount,
  }) : _paint = Paint()..shader = shader;

  @override
  void paint(Canvas canvas, Size size) {
    // Set uniforms for the shader.
    // Uniform indices must match the layout in the GLSL code.
    
    // 0: uResolution (vec2) - The width and height of the canvas.
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);

    // 1: uLineDistance (float) - Threshold for drawing lines.
    shader.setFloat(2, lineDistance);

    // 2: uColor (vec4) - The particle color components (R, G, B, A).
    shader.setFloat(3, particleColor.r);
    shader.setFloat(4, particleColor.g);
    shader.setFloat(5, particleColor.b);
    shader.setFloat(6, particleColor.a);

    // 3: uLineColor (vec4) - The line color components (R, G, B, A).
    shader.setFloat(7, lineColor.r);
    shader.setFloat(8, lineColor.g);
    shader.setFloat(9, lineColor.b);
    shader.setFloat(10, lineColor.a);

    // 4: uParticleCount (float) - The number of particles to loop over in the shader.
    shader.setFloat(11, particleCount.toDouble());

    // 5: uParticles (vec2 array) - Flattened positions of particles.
    // Uniform index starts at 12 because we used indices 0-11 for previous uniforms.
    int uniformIndex = 12;
    for (int i = 0; i < particles.length; i++) {
      // Limit to 150 particles as per shader definition to prevent buffer overflow/errors.
      if (i >= 150) break;
      
      // Set X and Y coordinates for each particle.
      shader.setFloat(uniformIndex++, particles[i].position.dx);
      shader.setFloat(uniformIndex++, particles[i].position.dy);
    }

    // Draw the shader covering the entire available size.
    canvas.drawRect(Offset.zero & size, _paint);
  }

  @override
  bool shouldRepaint(covariant ShaderNetworkPainter oldDelegate) {
    // Return true to ensure continuous animation updates.
    return true; 
  }
}
