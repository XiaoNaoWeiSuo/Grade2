#version 320 es
precision highp float;

#include <flutter/runtime_effect.glsl>

// Uniforms:
// Index 0, 1: u_size (width, height)
layout(location = 0) uniform vec2 u_size;
// Index 2..5: u_base_color (r, g, b, a)
layout(location = 1) uniform vec4 u_base_color;
// Index 6..9: u_accent_color (r, g, b, a)
layout(location = 2) uniform vec4 u_accent_color;
// Index 10: u_is_dark (1.0 if dark mode, 0.0 if light mode)
layout(location = 3) uniform float u_is_dark;
// Index 11: u_seed (hash float for variety)
layout(location = 4) uniform float u_seed;
// Index 12: u_radius (border radius in px)
layout(location = 5) uniform float u_radius;

layout(location = 0) out vec4 fragColor;

// Signed distance function for a rounded rectangle
float sdRoundedBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + vec2(r);
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

// Pseudo-random noise for tactile micro-texture
float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21) + vec2(u_seed * 13.1, u_seed * 7.7));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 size = u_size;
    if (size.x <= 0.0 || size.y <= 0.0) {
        fragColor = u_base_color;
        return;
    }

    vec2 uv = fragCoord / size;
    vec2 center = size * 0.5;
    vec2 halfSize = size * 0.5;
    float r = clamp(u_radius, 2.0, min(halfSize.x, halfSize.y));

    // Signed distance to card rounded edge
    float d = sdRoundedBox(fragCoord - center, halfSize, r);

    // Smooth anti-aliased edge mask (0.0 outside, 1.0 inside)
    float edgeMask = clamp(0.5 - d, 0.0, 1.0);
    if (edgeMask <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }

    // 1. Base gradient: Soft vertical lighting (top ambient light -> bottom depth)
    // Physical cards reflect environmental lighting stronger at top
    float topLight = mix(1.06, 0.94, uv.y);
    vec3 baseRgb = u_base_color.rgb * topLight;

    // 2. Anisotropic brushed texture & micro-grain (实体银行卡拉丝/细磨砂触感)
    // Slightly horizontally biased fine grain simulates brushed polycarbonate/metal
    float grainX = hash21(floor(fragCoord * vec2(0.5, 2.5)));
    float microGrain = (grainX - 0.5) * (u_is_dark > 0.5 ? 0.035 : 0.022);
    baseRgb += vec3(microGrain);

    // 3. Diagonal holographic sheen / refractive luster (银行卡全息防伪光泽)
    // Dynamic angle based on seed
    float angle = 0.65 + sin(u_seed * 2.3) * 0.15;
    float diagonal = uv.x * cos(angle) + uv.y * sin(angle);
    float sheenPos = fract(diagonal * 1.4 + u_seed * 0.2);
    // Smooth dual-band iridescent highlight
    float sheen = exp(-pow((sheenPos - 0.5) * 6.5, 2.0)) * 0.45;
    sheen += exp(-pow((sheenPos - 0.35) * 12.0, 2.0)) * 0.25;

    // Subtle prismatic color shift in the sheen
    vec3 sheenColor = mix(
        u_accent_color.rgb,
        mix(vec3(1.0, 0.96, 0.88), vec3(0.85, 0.92, 1.0), sin(diagonal * 6.28) * 0.5 + 0.5),
        0.35
    );
    float sheenStrength = (u_is_dark > 0.5 ? 0.16 : 0.22);
    baseRgb = mix(baseRgb, baseRgb + sheenColor * sheen, sheenStrength);

    // 4. Physical Volumetric Bevel & Rim Light (实体卡片倒角高光与下沿沉浸阴影)
    // Calculate distance from boundary to create bevel
    float bevelWidth = 2.0;
    // Normalized distance from border: 0 at outer border, 1 at inner card
    float borderDist = clamp(-d / bevelWidth, 0.0, 1.0);

    // Directional light vector from top-left (approx -0.5, -0.8)
    vec2 normalToBorder = normalize(fragCoord - center);
    vec2 lightDir = normalize(vec2(-0.45, -0.75));
    float rimLight = dot(-normalToBorder, lightDir);

    // Top-left catches specular highlight; bottom-right catches subtle ambient shadow
    if (d > -bevelWidth) {
        float bevelFactor = 1.0 - borderDist;
        if (rimLight > 0.1) {
            // Highlight rim (1px-2px crisp metallic edge catch)
            float highlight = rimLight * bevelFactor * (u_is_dark > 0.5 ? 0.38 : 0.48);
            baseRgb += vec3(highlight) * mix(vec3(1.0), u_accent_color.rgb, 0.3);
        } else {
            // Bevel shade (inner shadow edge giving thickness)
            float shadow = (-rimLight) * bevelFactor * 0.18;
            baseRgb = mix(baseRgb, baseRgb * 0.72, shadow);
        }
    }

    // 5. Left accent stripe / security chip track (bank card signature physical groove)
    // A micro-embossed accent ribbon at left margin (width ~ 3.5px)
    float stripeX = fragCoord.x;
    if (stripeX < 4.0) {
        float stripeFactor = clamp(stripeX / 3.5, 0.0, 1.0);
        vec3 stripeColor = u_accent_color.rgb;
        // subtle highlight on the right edge of stripe
        if (stripeX >= 2.5 && stripeX <= 3.8) {
            stripeColor = mix(stripeColor, vec3(1.0), 0.25);
        }
        baseRgb = mix(stripeColor, baseRgb, smoothstep(3.0, 4.0, stripeX));
    }

    // Final color with alpha compositing and anti-aliased edge mask
    float alpha = u_base_color.a * edgeMask;
    fragColor = vec4(baseRgb * alpha, alpha);
}
