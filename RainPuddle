shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back;

// --- Puddle mask ---
uniform sampler2D puddle_mask;
uniform vec2 puddle_scale = vec2(1.0);
uniform vec2 puddle_offset = vec2(0.0);
uniform float puddle_opacity : hint_range(0.0, 1.0) = 0.8;
uniform float puddle_amount : hint_range(0.0, 5.0) = 1.0;
uniform float edge_softness : hint_range(0.0, 1.0) = 0.3;

// --- Water look ---
uniform vec4 water_tint : source_color = vec4(0.15, 0.2, 0.25, 1.0);
uniform float water_roughness : hint_range(0.0, 1.0) = 0.05;
uniform float base_reflection : hint_range(0.0, 1.0) = 0.05;
uniform float reflection_strength : hint_range(0.0, 2.0) = 1.0;
uniform float fresnel_power : hint_range(1.0, 8.0) = 3.0;

void fragment() {
    vec2 uv = UV * puddle_scale + puddle_offset;
    float mask = texture(puddle_mask, uv).r;
    mask = smoothstep(0.0, edge_softness, mask * puddle_amount);

    float fresnel = pow(1.0 - dot(NORMAL, VIEW), fresnel_power);
    float reflection = base_reflection + fresnel * reflection_strength;

    ALBEDO = mix(vec3(0.25, 0.25, 0.25), water_tint.rgb, mask);
    ROUGHNESS = mix(0.3, water_roughness, mask);
    METALLIC = 0.0;
    SPECULAR = reflection * mask;
    ALPHA = mask * puddle_opacity;
}
