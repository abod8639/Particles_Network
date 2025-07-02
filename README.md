

# particles\_network

Transform your Flutter app’s UI with a high-performance particle network animation that responds to touch and adapts seamlessly to any screen size.

<div align="center">
  <a href="https://github.com/abod8639/Particles_Network">
    <img alt="particles_network demo" width="300" src="assets/Picsart_25-05-10_12-57-34-680.png">
  </a>

  <br>

  <a href="https://pub.dev/packages/particles_network">
    <img alt="Pub Version" src="https://img.shields.io/pub/v/particles_network">
  </a>
  <a href="https://github.com/abod8639/Particles_Network/actions/workflows/flutter-ci.yml">
    <img alt="CI Status" src="https://github.com/abod8639/Particles_Network/actions/workflows/flutter-ci.yml/badge.svg">
  </a>
  <a href="https://opensource.org/licenses/MIT">
    <img alt="MIT License" src="https://img.shields.io/badge/license-MIT-blue.svg">
  </a>
  <a href="https://codecov.io/gh/abod8639/Particles_Network">
    <img alt="Code Coverage" src="https://codecov.io/gh/abod8639/Particles_Network/branch/main/graph/badge.svg">
  </a>
  <img alt="Pub Likes" src="https://img.shields.io/pub/likes/particles_network">
  <img alt="Pub Points" src="https://img.shields.io/pub/points/particles_network">
</div>

---

## Features

* **Ultra-High Performance**

  * Advanced QuadTree spatial partitioning for O(log n) neighbor searches
  * Compressed QuadTree structure for optimal memory usage
  * Smart distance caching to minimize calculations
  * Efficient memory management with scoped caches

* **Rich Customization**

  * Control particle count, speed, size, and colors
  * Adjust connection distance and line thickness
  * Enable or disable touch interactions

* **Responsive Design**

  * Adapts to any screen size or orientation
  * Smooth animations at 60+ FPS
  * Touch-responsive with configurable effects

---

## Demo

![Demo](assets/image.png)

**GIF Preview:**

<img src="https://github.com/abod8639/flutter_habit_tracker/blob/main/assets/gif/c49ae41c72134b67b31d54593d3414f8.gif?raw=true" alt="Touch Interaction Demo" width="300">

---

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  particles_network: ^1.8.0
```

Then run:

```bash
flutter pub get
```

Or use the CLI:

```bash
flutter pub add particles_network
```

---

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:particles_network/particles_network.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: ParticleNetwork(
          particleCount: 60,
          maxSpeed: 0.5,
          maxSize: 1.5,
          lineWidth: 0.5,
          lineDistance: 100,
          particleColor: Colors.white,
          lineColor: const Color.fromARGB(255, 100, 255, 180),
          touchColor: Colors.amber,
          touchActivation: true,
          drawNetwork: true,
          fill: false,
          isComplex: false,
        ),
      ),
    );
  }
}
```

Full tutorial available [here](https://youtu.be/FZyFgUXCrHg).

---

## Configuration Options

| Property          | Type     | Default        | Description                  |
| ----------------- | -------- | -------------- | ---------------------------- |
| `particleCount`   | `int`    | `60`           | Number of particles          |
| `maxSpeed`        | `double` | `0.5`          | Maximum particle speed       |
| `maxSize`         | `double` | `1.5`          | Maximum particle radius      |
| `lineWidth`       | `double` | `0.5`          | Line thickness               |
| `lineDistance`    | `double` | `100`          | Connection distance          |
| `particleColor`   | `Color`  | `Colors.white` | Particle color               |
| `lineColor`       | `Color`  | `Colors.teal`  | Connection line color        |
| `touchColor`      | `Color`  | `Colors.amber` | Highlight color on touch     |
| `touchActivation` | `bool`   | `true`         | Enables touch interaction    |
| `isComplex`       | `bool`   | `false`        | Optimizes complex scenes     |
| `fill`            | `bool`   | `true`         | Filled or outlined particles |
| `drawNetwork`     | `bool`   | `true`         | Draw lines between particles |

---

## Advanced Usage

### Theme Integration

```dart
AnimatedBuilder(
  animation: Theme.of(context),
  builder: (context, _) => ParticleNetwork(
    particleColor: Theme.of(context).primaryColor,
    lineColor: Theme.of(context).colorScheme.secondary,
    // other configs...
  ),
)
```

### Background Usage

```dart
Stack(
  children: [
    ParticleNetwork(/* configuration */),
    YourAppContent(),
  ],
)
```

### Performance Tips

* Reduce `particleCount` and `lineDistance` for weaker devices
* Use `isComplex: true` for high-density scenes
* Use `fill: false` for better performance and lighter visuals

---

## Technical Details

The package uses an advanced **Compressed QuadTree** spatial data structure for efficient particle management.

```dart
final quadTree = CompressedQuadTreeNode(
  Rectangle(0, 0, screenWidth, screenHeight),
);

particles.forEach((particle) => 
  quadTree.insert(QuadTreeParticle(
    particle.id, 
    particle.x, 
    particle.y
  ))
);

final nearbyParticles = quadTree.queryCircle(
  touchX, 
  touchY, 
  searchRadius
);
```

##  Technical Details
![image2](assets/250530_22h33m09s_screenshot.png)
* **O(log n)** insertion and query
* Path compression to reduce memory for clustered particles
* Smart node consolidation and rebalancing
* Memory-efficient structure with typed arrays and sparse representation

---

## Contributing

We welcome contributions! See the [contributing guide](https://github.com/abod8639) for more details.

## License

This package is released under the [MIT License](LICENSE).

---

<div align="center">
  Crafted with care and ❤️  by <a href="https://github.com/abod8639">Dexter</a>
</div>

---

