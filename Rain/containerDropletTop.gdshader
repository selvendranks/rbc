shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, unshaded;

// --- Textures ---
uniform sampler2D drop_tex;
uniform sampler2D noise_tex;

// --- Droplet Controls ---
uniform vec2 drop_uv_scale = vec2(1.0, 1.0);
uniform vec2 drop_uv_offset = vec2(0.0, 0.0);
uniform float drop_speed : hint_range(0.1, 5.0) = 1.0;

// --- Visual Controls ---
uniform float reflection_strength : hint_range(0.0, 2.0) = 1.0;
uniform float distortion_strength : hint_range(0.0, 0.1) = 0.02;
uniform float drop_density : hint_range(0.0, 1.0) = 1.0; // new: controls droplet visibility
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// --- Internal variables ---
varying float up;

void vertex() {
    vec3 w_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
    up = smoothstep(0.0, 0.1, w_normal.y);
}

void fragment() {
    vec2 uv = UV;

    // Droplet UV motion
    vec2 drop_uv = uv * drop_uv_scale + drop_uv_offset;
    float noise_val = texture(noise_tex, uv * 5.0).r;

    // Animated droplet pattern
    vec4 drop = texture(drop_tex, drop_uv);
    vec3 drop_normalmap = normalize(vec3(drop.x, drop.y, 1.0));

    // Droplet animation and density modulation
    float drop_anim = fract(drop.b - (TIME + noise_val * 10.0) * drop_speed);
    float drop_mix_ratio = drop_anim * drop.b * up * drop_density;

    // Distortion of background using droplet normals
    vec2 offset = drop_normalmap.xy * distortion_strength * drop_mix_ratio;
    vec3 distorted_bg = texture(noise_tex, uv + offset).rgb; // fake refraction

    // Combine tinted reflection and droplet highlights
    ALBEDO = mix(distorted_bg, tint_color.rgb, drop_mix_ratio);
    SPECULAR = 0.8 + drop_mix_ratio * reflection_strength * drop_density;
    ROUGHNESS = mix(0.9, 0.05, drop_mix_ratio);
    METALLIC = 0.0;
    ALPHA = clamp(drop_mix_ratio * 0.8, 0.0, 1.0);
}
