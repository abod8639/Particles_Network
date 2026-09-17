<div align="center">

# Particle Blob 3D

**High-performance, GPU-accelerated 3D particle blob visualization for Flutter.**

<p align="center">
  <a href="https://github.com/yourusername/blob_flutter/actions"><img src="https://github.com/yourusername/blob_flutter/actions/workflows/flutter-ci.yml/badge.svg" alt="CI Status"></a>
  <a href="https://pub.dev/packages/blob_flutter"><img src="https://img.shields.io/pub/v/blob_flutter?color=blue&label=pub.dev&logo=dart" alt="Pub Version"></a>
  <a href="https://codecov.io/gh/yourusername/blob_flutter"><img src="https://codecov.io/gh/yourusername/blob_flutter/branch/main/graph/badge.svg" alt="Code Coverage"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-purple.svg" alt="License: MIT"></a>
</p>

<p align="center">
  <a href="https://github.com/yourusername/blob_flutter/stargazers"><img src="https://img.shields.io/github/stars/yourusername/blob_flutter?style=flat&logo=github&color=blue" alt="GitHub stars"></a>
  <img src="https://img.shields.io/pub/likes/blob_flutter?logo=flutter&color=gold" alt="Pub Likes">
  <img src="https://img.shields.io/pub/points/blob_flutter?logo=dart&color=blue" alt="Pub Points">
  <a href="https://particle-blob-demo.web.app"><img src="https://img.shields.io/badge/Demo-Live_Preview-EA4335?logo=firebase" alt="Live Demo"></a>
</p>

---

<p align="center">
  <a href="#features"><b>Features</b></a> •
  <a href="#architecture--performance"><b>Architecture</b></a> •
  <a href="#quick-start"><b>Quick Start</b></a> •
  <a href="#configuration-options"><b>Documentation</b></a>
</p>

</div>

---

## Table of Contents

- [Features](#features)
- [Use Cases](#use-cases)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Platform Support](#platform-support)
- [Configuration Options](#configuration-options)
- [Controller API Guide](#controller-api-guide)
- [Advanced Usage](#advanced-usage)
- [Architecture & Performance](#architecture--performance)
- [Troubleshooting](#troubleshooting)
- [License](#license)

---

## Features

* **Advanced 3D Mathematics**
  * **Fibonacci Sphere Distribution**: Ensures mathematically perfect, uniform distribution of thousands of particles across a 3D sphere.
  * **Fast Noise Displacement**: Utilizes synchronized sine/cosine wave interference to simulate complex 3D noise without the heavy computational overhead of Perlin noise.
  * **Interactive Physics**: Supports real-time rotational physics and particle dispersion mechanics.

* **Ultra-High Performance**
  * **GPU-Accelerated Rendering**: Utilizes custom GLSL Fragment Shaders to calculate lighting, depth shading, and color interpolation directly on the graphics hardware.
  * **Zero Allocation Rendering**: Operates entirely on contiguous C-style memory buffers (Float32List), completely eliminating Dart Garbage Collection (GC) pauses during animation frames.
  * **Single Draw Call**: Leverages `canvas.drawRawPoints` to push up to 10,000 particles to the Skia/Impeller engine in a single, batched operation.

* **Rich Customization**
  * Programmatic control over blob geometry (blobiness/noise amplitude).
  * Control particle count, rotation speed, point size, and base radius.
  * Dynamic, hardware-blended color gradients based on spatial coordinates.

---

## Use Cases

Perfect for creating stunning, high-end visual effects in:

- **Landing Pages** - Create memorable, interactive first impressions.
- **Application Onboarding** - Engage users with fluid, responsive backgrounds.
- **Audio Visualizers** - Bind the controller API to audio frequencies to make the blob pulse to music.
- **Data Representation** - Use as a dynamic central hub for network visualizations.

---

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:blob_flutter/blob_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: SizedBox(
            width: 400,
            height: 400,
            child: ParticleBlob(
              particleCount: 5000,
              radius: 120.0,
              pointSize: 2.0,
              color1: Colors.pinkAccent,
              color2: Colors.deepPurpleAccent,
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  blob_flutter: ^1.0.0
```

Then run:

```bash
flutter pub get
```

### Platform-Specific Setup

#### Web
For optimal performance on the web, compiling with CanvasKit is highly recommended to ensure the fragment shaders compile and run efficiently:
```bash
flutter build web --web-renderer canvaskit
```

#### Mobile and Desktop
No additional setup is required. The fragment shaders are automatically compiled ahead-of-time (AOT) by the Flutter engine.

---

## Platform Support

| Platform | Support | Performance | Notes                         |
|----------|---------|-------------|-------------------------------|
| Android  | Full    | Excellent   | Hardware acceleration enabled |
| iOS      | Full    | Excellent   | Optimized for Metal rendering |
| Web      | Full    | Very Good   | Requires CanvasKit renderer   |
| Windows  | Full    | Excellent   | DirectX acceleration          |
| macOS    | Full    | Excellent   | Metal acceleration            |
| Linux    | Full    | Very Good   | OpenGL acceleration           |

**Minimum Requirements:**
- Flutter SDK: >=3.10.0
- Dart SDK: >=3.0.0

---

## Configuration Options

| Property        | Type                     | Default                | Description                                                |
| --------------- | ------------------------ | ---------------------- | ---------------------------------------------------------- |
| `particleCount` | `int`                    | `5000`                 | Total number of points distributed across the sphere.      |
| `radius`        | `double`                 | `150.0`                | Base radius of the 3D sphere before noise displacement.    |
| `pointSize`     | `double`                 | `2.0`                  | Stroke width of each individual particle.                  |
| `controller`    | `ParticleBlobController` | `null`                 | Exposes programmatic control over physics and geometry.    |
| `color1`        | `Color`                  | `Colors.pinkAccent`    | Primary color injected into the fragment shader.           |
| `color2`        | `Color`                  | `Colors.purpleAccent`  | Secondary color injected into the fragment shader.         |

---

## Controller API Guide

The library features a robust API allowing you to manipulate the physical properties of the blob at runtime without rebuilding the widget tree.

### Initialization

```dart
final ParticleBlobController _controller = ParticleBlobController();
```

### Mutating Geometry

You can dynamically alter how distorted or "blobby" the sphere is. Setting this to `0.0` results in a perfect sphere.

```dart
_controller.setBlobiness(2.5); // High distortion
```

### Modifying Temporal Speed

Accelerate or decelerate the autonomous rotation and noise evolution.

```dart
_controller.setSpeed(0.5); // Half speed (Slow motion)
_controller.setSpeed(2.0); // Double speed
```

### Triggering Dispersion

You can forcefully scatter the particles outwards from the center. This is highly effective when bound to user tap events or application state changes.

```dart
// Scatter particles outward
_controller.setDispersion(0.8);

// Return particles to their mathematical origin
_controller.setDispersion(0.0);
```

---

## Architecture & Performance

This package combines memory-safe Dart mathematics with GPU-side rendering to achieve optimal performance.

### GPU-Accelerated Shading

The visual presentation is entirely decoupled from the CPU. We utilize a custom GLSL Fragment Shader (`shaders/blob.frag`). When `canvas.drawRawPoints` is invoked, the shader is applied to the `Paint` object. The GPU processes the spatial coordinates of each fragment to interpolate between `color1` and `color2` based on the normalized screen coordinates and time. This avoids the severe CPU bottleneck of iterating through 5,000 colors in Dart.

### Zero-Allocation Memory Model

In standard Flutter development, representing coordinates requires objects (e.g., `Offset(x, y)`). 5,000 particles updated 60 times a second would require allocating and discarding 300,000 objects per second, destroying performance via Garbage Collection.

This library utilizes a single, contiguous `Float32List`.
```dart
// Memory is allocated exactly once.
Float32List _projectedPoints = Float32List(particleCount * 2);

// Direct memory access mutates coordinates without object creation.
_projectedPoints[i * 2] = computedX;
_projectedPoints[i * 2 + 1] = computedY;
```

---

## Troubleshooting

### Issue: Low Framerate on Web

**Solution:** Ensure you are not running the HTML renderer. The fragment shaders require WebGL capabilities provided by CanvasKit. Run or build your project with the appropriate flags:
```bash
flutter run -d chrome --web-renderer canvaskit
```

### Issue: Particles Are Rendering as Squares

**Solution:** Ensure `pointSize` is reasonable and your target platform supports `StrokeCap.round` in `drawRawPoints`. By default, the library enforces rounded caps, but specific legacy OpenGL drivers may default to square fragments.

### Issue: Controller Methods Have No Effect

**Solution:** Ensure you are passing your instantiated `ParticleBlobController` to the `ParticleBlob` widget.
```dart
ParticleBlob(
  controller: _myController, // Do not omit this line
  particleCount: 5000,
)
```

---

## License

This package is released under the [MIT License](LICENSE).
