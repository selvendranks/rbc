shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back;

// --- Ripple Parameters 6277860a c1c1c1---
uniform sampler2D ripple_normal;
uniform float ripple_scale = 4.0;
uniform float ripple_strength : hint_range(0.0, 1.0) = 0.3;
uniform float ripple_speed = 1.0;
uniform float fade_softness : hint_range(0.0, 1.0) = 0.3;

// --- Reflection Control ---
uniform float reflection_multiplier : hint_range(0.0, 2.0) = 1.0; // new parameter

// Random hash function
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
    // Grid setup for localized ripples
    vec2 ripple_uv = UV * ripple_scale;
    vec2 cell = floor(ripple_uv);
    vec2 cell_uv = fract(ripple_uv);

    // Each cell has its own random timing
    float random_phase = hash(cell);

    // Smooth sine pulse with fade-in/out to reduce flicker
    float wave = sin((TIME * ripple_speed) + random_phase * 6.2831) * 0.5 + 0.5;
    float ripple_mask = smoothstep(fade_softness, 1.0, wave);

    // Add a secondary, offset wave for overlap (keeps density constant)
    float wave2 = sin((TIME * ripple_speed * 0.9) + random_phase * 12.2831) * 0.5 + 0.5;
    float ripple_mask2 = smoothstep(fade_softness, 1.0, wave2);

    // Blend both masks so there’s always something active
    float combined_mask = clamp(ripple_mask + ripple_mask2 * 0.8, 0.0, 1.0);

    // Sample normal
    vec3 ripple_n = texture(ripple_normal, cell_uv).rgb * 2.0 - 1.0;
    ripple_n *= combined_mask;

    // Apply ripple normal gently
    NORMAL = normalize(NORMAL + ripple_n * ripple_strength);

    // Output
    ALBEDO = vec3(0.0);
    ROUGHNESS = 0.05;
    METALLIC = 0.0;
    SPECULAR = reflection_multiplier * combined_mask; // control reflection
    ALPHA = combined_mask * 0.6;
}
