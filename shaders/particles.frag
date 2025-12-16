#version 460 core

precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uLineDistance;
uniform vec4 uColor; // Particle color
uniform vec4 uLineColor; // Line color
uniform float uParticleCount;
uniform vec2 uParticles[150]; // Max 150 particles

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy;
    vec4 finalColor = vec4(0.0);
    
    float lineDistSq = uLineDistance * uLineDistance;

    // Draw particles
    for (int i = 0; i < 150; i++) {
        if (i >= int(uParticleCount)) break;
        vec2 p = uParticles[i];
        vec2 diff = uv - p;
        float dSq = dot(diff, diff);
        
        // Draw particle circle (radius 2.0 -> squared 4.0)
        if (dSq < 4.0) {
            finalColor = mix(finalColor, uColor, uColor.a);
        }
    }

    // Draw connections
    // Optimization: Only check connections if particles are within range of the pixel.
    // If a particle is further than uLineDistance from the pixel, it cannot form a visible
    // line segment with another particle (since max line length is uLineDistance).
    // Actually, to be safe, we use uLineDistance + margin.
    float searchDistSq = (uLineDistance + 2.0) * (uLineDistance + 2.0);

    for (int i = 0; i < 150; i++) {
        if (i >= int(uParticleCount)) break;
        vec2 p1 = uParticles[i];
        
        // Early exit: if p1 is too far from pixel, it can't be part of a relevant line
        vec2 diff1 = uv - p1;
        if (dot(diff1, diff1) > searchDistSq) continue;
        
        for (int j = 0; j < 150; j++) {
            if (j <= i) continue; // Avoid duplicates
            if (j >= int(uParticleCount)) break;
            
            vec2 p2 = uParticles[j];
            
            // Early exit: if p2 is too far, skip
            vec2 diff2 = uv - p2;
            if (dot(diff2, diff2) > searchDistSq) continue;
            
            vec2 diff = p1 - p2;
            float distSq = dot(diff, diff);
            
            if (distSq < lineDistSq) {
                // Distance from pixel to line segment p1-p2
                vec2 pa = uv - p1;
                vec2 ba = p2 - p1;
                float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
                vec2 dVec = pa - ba * h;
                float dLineSq = dot(dVec, dVec);
                
                if (dLineSq < 1.0) { // Line width squared (1.0^2)
                    float dist = sqrt(distSq);
                    float opacity = 1.0 - (dist / uLineDistance);
                    vec4 lineColor = uLineColor;
                    lineColor.a *= opacity;
                    finalColor = mix(finalColor, lineColor, lineColor.a);
                }
            }
        }
    }

    fragColor = finalColor;
}

