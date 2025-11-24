

# particles\_network

Transform your Flutter app’s UI with a high-performance particle network animation that responds to touch and adapts seamlessly to any screen size.

<div align="center">
  <a href="https://github.com/abod8639/Particles_Network">
    <img alt="particles_network demo" width="300" src="assets/Picsart_25-05-10_12-57-34-680.png">
  </a>

  <br>
  <a href="https://pub.dev/packages/particles_network">
    <img alt="Pub Version" src="https://img.shields.io/pub/v/particles_network"></a>
  <a href="https://github.com/abod8639/Particles_Network/actions/workflows/flutter-ci.yml">
    <img alt="CI Status" src="https://github.com/abod8639/Particles_Network/actions/workflows/flutter-ci.yml/badge.svg"></a>
  <a href="https://opensource.org/licenses/MIT">
    <img alt="MIT License" src="https://img.shields.io/badge/license-MIT-blue.svg"></a>
  <a href="https://codecov.io/gh/abod8639/Particles_Network"></a>
    <a href="https://codecov.io/gh/abod8639/Particles_Network">
     <img alt="Code Coverage" src="https://codecov.io/gh/abod8639/Particles_Network/branch/main/graph/badge.svg"></a>
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

<video width="300" height="600" autoplay loop muted>
  <source src="assets/Screen_Recording_20251124_055354.mp4" type="video/mp4">
</video>


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
          lineDistance: 120,
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

## Full tutorial [available <svg width="50px" height="50px" viewBox="0 0 24.00 13.00" fill="none" xmlns="http://www.w3.org/2000/svg" stroke="#4CFFA7"><g id="SVGRepo_bgCarrier" stroke-width="0"></g><g id="SVGRepo_tracerCarrier" stroke-linecap="round" stroke-linejoin="round"></g><g id="SVGRepo_iconCarrier"> <path d="M20.5245 6.00694C20.3025 5.81544 20.0333 5.70603 19.836 5.63863C19.6156 5.56337 19.3637 5.50148 19.0989 5.44892C18.5677 5.34348 17.9037 5.26005 17.1675 5.19491C15.6904 5.06419 13.8392 5 12 5C10.1608 5 8.30956 5.06419 6.83246 5.1949C6.09632 5.26005 5.43231 5.34348 4.9011 5.44891C4.63628 5.50147 4.38443 5.56337 4.16403 5.63863C3.96667 5.70603 3.69746 5.81544 3.47552 6.00694C3.26514 6.18846 3.14612 6.41237 3.07941 6.55976C3.00507 6.724 2.94831 6.90201 2.90314 7.07448C2.81255 7.42043 2.74448 7.83867 2.69272 8.28448C2.58852 9.18195 2.53846 10.299 2.53846 11.409C2.53846 12.5198 2.58859 13.6529 2.69218 14.5835C2.74378 15.047 2.81086 15.4809 2.89786 15.8453C2.97306 16.1603 3.09841 16.5895 3.35221 16.9023C3.58757 17.1925 3.92217 17.324 4.08755 17.3836C4.30223 17.461 4.55045 17.5218 4.80667 17.572C5.32337 17.6733 5.98609 17.7527 6.72664 17.8146C8.2145 17.9389 10.1134 18 12 18C13.8865 18 15.7855 17.9389 17.2733 17.8146C18.0139 17.7527 18.6766 17.6733 19.1933 17.572C19.4495 17.5218 19.6978 17.461 19.9124 17.3836C20.0778 17.324 20.4124 17.1925 20.6478 16.9023C20.9016 16.5895 21.0269 16.1603 21.1021 15.8453C21.1891 15.4809 21.2562 15.047 21.3078 14.5835C21.4114 13.6529 21.4615 12.5198 21.4615 11.409C21.4615 10.299 21.4115 9.18195 21.3073 8.28448C21.2555 7.83868 21.1874 7.42043 21.0969 7.07448C21.0517 6.90201 20.9949 6.72401 20.9206 6.55976C20.8539 6.41236 20.7349 6.18846 20.5245 6.00694Z" stroke="#4CFFA7" stroke-width="1.224" stroke-linecap="round" stroke-linejoin="round"></path> <path d="M14.5385 11.5L10.0962 14.3578L10.0962 8.64207L14.5385 11.5Z" stroke="#FF4C4CFF" stroke-width="1.224" stroke-linecap="round" stroke-linejoin="round"></path> </g></svg>](https://youtu.be/FZyFgUXCrHg)


---
```

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
| `fill`             | `bool`   | `true`         | Filled or outlined particles |
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

