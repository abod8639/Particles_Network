import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:particles_network/model/particlemodel.dart';

class ShaderNetworkPainter extends CustomPainter {
  final FragmentShader shader;
  final List<Particle> particles;
  final double lineDistance;
  final Color particleColor;
  final Color lineColor;
  final int particleCount;

  final Paint _paint;

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
    // Set uniforms
    // 0: uResolution (vec2)
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);

    // 1: uLineDistance (float)
    shader.setFloat(2, lineDistance);

    // 2: uColor (vec4)
    shader.setFloat(3, particleColor.r);
    shader.setFloat(4, particleColor.g);
    shader.setFloat(5, particleColor.b);
    shader.setFloat(6, particleColor.a);

    // 3: uLineColor (vec4)
    shader.setFloat(7, lineColor.r);
    shader.setFloat(8, lineColor.g);
    shader.setFloat(9, lineColor.b);
    shader.setFloat(10, lineColor.a);

    // 4: uParticleCount (float)
    shader.setFloat(11, particleCount.toDouble());

    // 5: uParticles (vec2 array)
    // Uniform index starts at 12
    int uniformIndex = 12;
    for (int i = 0; i < particles.length; i++) {
      // Limit to 150 particles as per shader definition
      if (i >= 150) break;
      
      shader.setFloat(uniformIndex++, particles[i].position.dx);
      shader.setFloat(uniformIndex++, particles[i].position.dy);
    }

    canvas.drawRect(Offset.zero & size, _paint);
  }

  @override
  bool shouldRepaint(covariant ShaderNetworkPainter oldDelegate) {
    return true; // Always repaint for animation
  }
}
