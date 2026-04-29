/// Particle Network Fragment Shader
///
/// Renders the full particle network (connections + particles) on the GPU
/// in a single draw call.
///
/// Technique: Full-screen fragment shader pass.
/// Each pixel independently checks its proximity to all particle pairs
/// (lines) and all particles (circles). This is parallelized across ALL
/// pixels on the GPU simultaneously.
///
/// Uniform layout (flat float index):
///   0-1   : uResolution (vec2)
///   2     : uTime (float)
///   3     : uLineDistance (float)
///   4     : uParticleCount (float)
///   5-8   : uParticleColor (vec4)
///   9-12  : uLineColor (vec4)
///   13-14 : uTouchPoint (vec2)
///   15    : uTouchActive (float)
///   16-19 : uTouchColor (vec4)
///   20    : uGlowIntensity (float)
///   21    : uLineWidth (float)
///   22-171: uParticleSizes[150] (float array)
///   172-471: uParticles[150] (vec2 array = 300 floats)
///
/// Total uniforms: 472 floats.

#version 460 core

precision highp float;

#include <flutter/runtime_effect.glsl>

// ── Uniforms ────────────────────────────────────────────────────────────────
uniform vec2  uResolution;        // Viewport size in pixels
uniform float uTime;              // Elapsed time in seconds (for animation)
uniform float uLineDistance;      // Max connection distance (pixels)
uniform float uParticleCount;     // Active particle count (≤ 150)
uniform vec4  uParticleColor;     // RGBA particle color
uniform vec4  uLineColor;         // RGBA line color
uniform vec2  uTouchPoint;        // Touch/cursor position (pixels)
uniform float uTouchActive;       // 1.0 = touch active, 0.0 = inactive
uniform vec4  uTouchColor;        // RGBA touch line / ripple color
uniform float uGlowIntensity;     // Glow strength (0.0 = off, 1.0 = full)
uniform float uLineWidth;         // Stroke width for lines (pixels)

uniform float uParticleSizes[150]; // Per-particle radius (pixels)
uniform vec2  uParticles[150];     // Per-particle position (pixels)

out vec4 fragColor;

// ── Helper: signed distance from point p to segment (a, b) ─────────────────
float distToSegment(vec2 p, vec2 a, vec2 b) {
    vec2 ab = b - a;
    vec2 ap = p - a;
    float lenSq = dot(ab, ab);
    if (lenSq < 0.0001) return length(ap);
    float t = clamp(dot(ap, ab) / lenSq, 0.0, 1.0);
    return length(ap - ab * t);
}

// ── Helper: smooth alpha compositing (Porter-Duff over) ────────────────────
vec4 blendOver(vec4 dst, vec4 src) {
    float outA = src.a + dst.a * (1.0 - src.a);
    if (outA < 0.0001) return vec4(0.0);
    vec3 outRGB = (src.rgb * src.a + dst.rgb * dst.a * (1.0 - src.a)) / outA;
    return vec4(outRGB, outA);
}

void main() {
    vec2  uv         = FlutterFragCoord().xy;
    vec4  color      = vec4(0.0);          // Accumulator (starts transparent)
    int   count      = int(uParticleCount);
    float lineDist   = uLineDistance;
    float lineDistSq = lineDist * lineDist;
    float halfLine   = uLineWidth * 0.5;

    // ── 1. CONNECTION LINES ────────────────────────────────────────────────
    if (lineDist > 0.0) {
        for (int i = 0; i < 150; i++) {
            if (i >= count) break;
            vec2 p1 = uParticles[i];

            // Early exit: if this pixel is farther than lineDist from p1 it
            // cannot lie on any line that *starts* at p1 AND has length ≤ lineDist.
            // We use 1.5× margin so pixels near the far end of a line are included.
            vec2 dp1 = uv - p1;
            if (dot(dp1, dp1) > lineDistSq * 2.25) continue;

            for (int j = 0; j < 150; j++) {
                if (j <= i) continue;
                if (j >= count) break;
                vec2 p2 = uParticles[j];

                // Discard pairs that are too far apart to form a connection.
                vec2  pp       = p1 - p2;
                float pDistSq  = dot(pp, pp);
                if (pDistSq > lineDistSq) continue;

                // Cheap pre-test: pixel must be within the line's AABB + halfLine.
                vec2 mn = min(p1, p2) - halfLine - 1.0;
                vec2 mx = max(p1, p2) + halfLine + 1.0;
                if (uv.x < mn.x || uv.x > mx.x ||
                    uv.y < mn.y || uv.y > mx.y) continue;

                // Actual distance from pixel to the line segment.
                float d = distToSegment(uv, p1, p2);
                if (d > halfLine + 1.5) continue;

                // Opacity fades with particle pair distance.
                float pairDist    = sqrt(pDistSq);
                float distOpacity = 1.0 - (pairDist / lineDist);

                // Smooth pulse travelling along the line (time-driven).
                float pulse = sin(uTime * 1.8 + pairDist * 0.04) * 0.12 + 0.88;

                // Sub-pixel anti-aliasing.
                float aa = 1.0 - smoothstep(halfLine - 0.5, halfLine + 1.0, d);

                vec4 lc = uLineColor;
                lc.a   *= distOpacity * aa * pulse;
                color   = blendOver(color, lc);
            }
        }
    }

    // ── 2. TOUCH LINES + RIPPLE ────────────────────────────────────────────
    if (uTouchActive > 0.5) {
        vec2 touch = uTouchPoint;

        for (int i = 0; i < 150; i++) {
            if (i >= count) break;
            vec2 p = uParticles[i];

            vec2  dp         = p - touch;
            float pDistSq    = dot(dp, dp);
            if (pDistSq > lineDistSq) continue;

            float d = distToSegment(uv, p, touch);
            if (d > halfLine + 1.5) continue;

            float pDist  = sqrt(pDistSq);
            float opacity = 1.0 - (pDist / lineDist);
            float aa      = 1.0 - smoothstep(halfLine - 0.5, halfLine + 1.0, d);

            vec4 tc  = uTouchColor;
            tc.a    *= opacity * aa;
            color    = blendOver(color, tc);
        }

        // Expanding ripple ring centred on the touch point.
        float touchDist    = length(uv - touch);
        float rippleRadius = mod(uTime * 55.0, lineDist);
        float ripple       = smoothstep(2.5, 0.0, abs(touchDist - rippleRadius));

        if (ripple > 0.001) {
            vec4 rc  = uTouchColor;
            rc.a    *= ripple * 0.5;
            color    = blendOver(color, rc);
        }
    }

    // ── 3. PARTICLES (glow + solid circle) ────────────────────────────────
    for (int i = 0; i < 150; i++) {
        if (i >= count) break;
        vec2  p    = uParticles[i];
        float rad  = uParticleSizes[i];

        vec2  diff = uv - p;
        float dist = length(diff);

        // Soft radial glow (exponential falloff).
        if (uGlowIntensity > 0.001) {
            float glowRadius = rad * 5.0;
            if (dist < glowRadius) {
                float glow = exp(-dist / (rad * 1.4)) * uGlowIntensity;
                vec4 gc    = uParticleColor;
                gc.a      *= glow;
                color      = blendOver(color, gc);
            }
        }

        // Solid particle disc with anti-aliased edge.
        if (dist < rad + 1.5) {
            float aa  = 1.0 - smoothstep(rad - 0.5, rad + 1.0, dist);
            vec4  pc  = uParticleColor;
            pc.a     *= aa;
            color     = blendOver(color, pc);
        }
    }

    fragColor = color;
}
