## Configuration Options

| Property                    | Type            | Default                 | Description                                                                |
| :-------------------------- | :-------------- | :---------------------- | :------------------------------------------------------------------------- |
| `particleCount`             | `int`           | `60`                    | Number of particles in the system.                                         |
| `maxSpeed`                  | `double`        | `0.5`                   | Maximum base wandering velocity (px/frame).                                |
| `maxSize`                   | `double`        | `1.5`                   | Maximum particle radius in pixels.                                         |
| `lineWidth`                 | `double`        | `0.5`                   | Thickness of connection lines.                                             |
| `lineDistance`              | `double`        | `100.0`                 | Maximum distance threshold for drawing connections.                        |
| `particleColor`             | `Color`         | `Colors.white`          | Particle fill or outline color.                                            |
| `lineColor`                 | `Color`         | `Color(0xFF64FFB4)`     | Color of connection lines.                                                 |
| `touchColor`                | `Color`         | `Colors.amber`          | Highlight color for particles near touch position.                         |
| `touchActivation`           | `bool`          | `true`                  | Enables touch and gesture interactions.                                    |
| `touchFeatures`             | `TouchFeatures` | `const TouchFeatures()` | Fine-grained touch physics and response configuration.                     |
| `hoverEffect`               | `bool?`         | `false`                 | Enables cursor tracking on desktop and web.                                |
| `isComplex`                 | `bool`          | `false`                 | Optimized mode for high particle counts (300+).                            |
| `fill`                      | `bool`          | `true`                  | `true` for filled circles, `false` for stroked outlines.                   |
| `drawNetwork`               | `bool`          | `true`                  | Whether to draw connection lines between particles.                        |
| `maxConnectionsPerParticle` | `int?`          | `null`                  | Limits lines per particle, bounding edge complexity to $O(N)$.             |
| `adaptiveDensity`           | `bool`          | `false`                 | Automatically reduces line distance in crowded areas.                      |
| `fastLineRendering`         | `bool`          | `false`                 | Batched single-call line drawing using `canvas.drawRawPoints`.             |
| `enableAdaptivePerformance` | `bool`          | `false`                 | Dynamically throttles effects during frame spikes to keep 60 FPS.          |
| `gravityType`               | `GravityType`   | `GravityType.none`      | Physics type: `none`, `global`, or `point`.                                |
| `gravityStrength`           | `double`        | `0.1`                   | Force intensity ($F = m \cdot a$). Negative values repel in point gravity. |
| `gravityDirection`          | `Offset`        | `Offset(0, 1)`          | Direction vector for `GravityType.global`.                                 |
| `gravityCenter`             | `Offset?`       | `null`                  | Focus position for `GravityType.point` (defaults to viewport center).      |

---

### Touch Features Configuration

Fine-tune interaction dynamics with `TouchFeatures`:

| Property              | Type      | Default | Description                                                   |
| :-------------------- | :-------- | :------ | :------------------------------------------------------------ |
| `force` / `pullForce` | `double`  | `0.42`  | Attraction strength toward the touch point.                   |
| `speed` / `decayRate` | `double`  | `0.42`  | Recovery rate back to cruising speed after touch release.     |
| `damping`             | `double`  | `0.985` | Drag coefficient within the touch field.                      |
| `maxTouchSpeed`       | `double`  | `5.5`   | Strict speed ceiling during touch attraction.                 |
| `lineDistance`        | `double?` | `null`  | Touch interaction radius (defaults to widget `lineDistance`). |

```
  const ParticleNetwork({
    super.key,
    this.particleCount = 60,
    this.maxSpeed = 0.5,
    this.maxSize = 1.5,
    this.lineWidth = 0.5,
    this.lineDistance = 100,
    this.particleColor = Colors.white,
    this.lineColor = const Color.fromARGB(255, 100, 255, 180),
    this.touchColor = Colors.amber,
    this.touchActivation = true,
    this.isComplex = false,
    this.fill = true,
    this.drawNetwork = true,
    this.gravityType = GravityType.none,
    this.gravityStrength = 0.1,
    this.gravityDirection = const Offset(0, 1),
    this.gravityCenter,
    this.hoverEffect = false,
    this.touchFeatures = const TouchFeatures(),
    this.maxConnectionsPerParticle,
    this.adaptiveDensity = false,
    bool? fastLineRendering,
    bool? useVerticesRendering,
    this.enableAdaptivePerformance = false,
  }) : fastLineRendering = fastLineRendering ?? useVerticesRendering ?? false;

```

```
  const TouchFeatures({
    double? speed,
    double? decayRate,
    double? force,
    double? pullForce,
    this.maxTouchSpeed = 5.5,
    this.damping = 0.985,
    this.lineDistance,
  })  : speed = speed ?? decayRate ?? 0.42,
        force = force ?? pullForce ?? 0.42;

```
