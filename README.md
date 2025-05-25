## particles_network

Transform your app's UI with a breathtaking, high-performance particle network animation that reacts to touch and adapts seamlessly to any screen.

<p align="center">
  <a href="https://github.com/abod8639/Particles_Network">
    <img alt="particles_network demo" width="300" src="assets/Picsart_25-05-10_12-57-34-680.png">
  </a>
</p>

 [![Pub Version](https://img.shields.io/pub/v/particles_network)](https://pub.dev/packages/particles_network)
 [![CI Status](https://github.com/abod8639/Particles_Network/actions/workflows/flutter-ci.yml/badge.svg)]()
![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)
 [![Codecov](https://codecov.io/gh/abod8639/Particles_Network/branch/main/graph/badge.svg)]() 
[![pub points](https://img.shields.io/pub/points/device_info_plus?color=0F80C1&label=pub%20points)](https://pub.dev/packages/particles_network/score)
<p align="left">
  <a href="https://github.com/abod8639/Particles_Network">
    <img alt="particles_network demo" width="100" src="https://github.com/fluttercommunity/plus_plugins/raw/main/assets/flutter-favorite-badge.png">
  </a>
</p>

---

### ✨ Key Features

* ⚡ **Ultra‑Smooth Rendering**: Spatial partitioning grid and smart distance caching for minimal CPU overhead.
* 🛠 **Fully Customizable**: Adjust particle count, speed, size, colors, and connection distance.
* 👆 **Touch-Responsive**: Particles attract to touch points with configurable strength and color.
* 🔗 **Dynamic Connections**: Lines automatically draw between neighbors within a configurable radius.
* 📱 **Responsive Layout**: Auto‑scales across devices, orientations, and screen sizes.
* 🧠 **Resource Efficient**: Minimal allocations per frame, automatic cache cleanup, and optimized repainting.

## Image

![🖼️ Static Preview](assets/image.png)

## Gif
<p align="center">
  <img src="https://github.com/abod8639/flutter_habit_tracker/blob/main/assets/gif/c49ae41c72134b67b31d54593d3414f8.gif?raw=true" alt="✨ Touch Interaction Demo">
</p>

---

## 🚀 Installation

### direct
```
flutter pub add particles_network
```
### OR

Add `particles_network` to your project's `pubspec.yaml`:

```yaml
dependencies:
  particles_network: ^1.6.5
```

Run:

```bash
flutter pub get
```

---

## 🧪 Usage Example

```dart
import 'package:flutter/material.dart';
import 'package:particles_network/particles_network.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: ParticleNetwork(
          isComplex: false,            // This reduces complex calculations
          touchActivation: true,       // Enable touch interaction
          particleCount: 60,           // Number of particles
          maxSpeed: 0.7,               // Max particle velocity
          maxSize: 3.5,                // Max particle size
          lineDistance: 180,           // Connection radius
          particleColor: Colors.white,
          lineColor: const Color(0xFF4CFFA7),
          touchColor: Colors.amber,
        ),
      ),
    );
  }
}
```

---

## 🎛️ Configuration Options

| ⚙️ Property       | 🧾 Type  | 🧪 Default     | 📋 Description                       |
| ----------------- | -------- | -------------- | ------------------------------------ |
| `particleCount`   | `int`    | `50`           | Total number of particles            |
| `maxSpeed`        | `double` | `0.5`          | Maximum movement speed               |
| `maxSize`         | `double` | `3.5`          | Maximum particle radius              |
| `lineDistance`    | `double` | `100`          | Distance threshold for drawing lines |
| `particleColor`   | `Color`  | `Colors.white` | Particle fill color                  |
| `lineColor`       | `Color`  | `Colors.teal`  | Color of connecting lines            |
| `touchActivation` | `bool`   | `false`        | Enable touch-based attraction        |
| `touchColor`      | `Color`  | `Colors.amber` | Color of lines created by touch      |
| `isComplex`       | `bool`   | `false`        | This reduces complex calculations    |

> ⚠️ **Performance Tip**: Increase `particleCount` with caution. Pair high counts with lower `lineDistance` to maintain frame rate.

---

## 🏎️ Under the Hood

* 🧩 **Spatial Partitioning**: Particles are binned into grid cells to limit neighbor searches.
* 🗂️ **Distance Caching**: Recent proximity checks are cached each frame to avoid redundant calculations.
* 🖌️ **Efficient Repaints**: CustomPainter’s `shouldRepaint` ensures redraws only when parameters change.
* 🧼 **Memory Management**: Typed arrays and frame‑scoped caches prevent memory churn.

---

## 🧠 Advanced Usage

* 🌗 **Theme Adaptation**: Wrap `ParticleNetwork` in `AnimatedBuilder` to animate colors for dark/light mode.
* 🌀 **Custom Physics**: Extend `Particle` class to introduce forces like gravity or repulsion.
* 🧱 **Integration**: Use inside any Flutter layout—`Stack`, `Container`, or as a `background` in `Scaffold`.

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to open a pull request or issue on [Github](https://github.com/abod8639/Particles_Network).

---

## 📜 License

Distributed under the MIT License. See [LICENSE](LICENSE) for details.

<p align="center">
  Made with ❤️ by Dexter for Flutter developers
</p>
