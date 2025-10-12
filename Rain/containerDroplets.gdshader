shader_type spatial;

uniform sampler2D drop_tex;
uniform sampler2D albedo_texture;
uniform sampler2D normalmap_texture;
uniform sampler2D noise_tex;

// Albedo color multiplier (default white = no change)
uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// UV controls for droplet texture
uniform vec2 drop_uv_scale = vec2(1.0, 1.0);
uniform vec2 drop_uv_offset = vec2(0.0, 0.0);

varying float up;

void vertex() {
    vec3 w_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
    up = smoothstep(0.0, 0.1, w_normal.y);
}

void fragment() {
    vec2 uv = UV;

    // Base albedo
    vec3 albedo_tex = texture(albedo_texture, uv).rgb;
    vec3 final_albedo = albedo_tex * albedo_color.rgb;
    ALBEDO = final_albedo;

    // Base normal
    NORMAL_MAP = texture(normalmap_texture, uv).rgb;

    // Droplet UV with scale + offset
    vec2 drop_uv = uv * drop_uv_scale + drop_uv_offset;

    // Noise value for random timing offset
    float noise_val = texture(noise_tex, uv * 5.0).r; // scale controls variation

    // Droplet texture
    vec4 drop = texture(drop_tex, drop_uv);
    vec3 drop_normalmap = vec3(drop.x, drop.y, 1.0);

    // Droplet mixing ratio (animated with TIME + noise offset)
    float drop_mix_ratio = drop.b - (TIME + noise_val * 10.0) * 1.0;
    drop_mix_ratio = fract(drop_mix_ratio) * drop.b;

    // Restrict to upward-facing surfaces
    drop_mix_ratio *= up;

    // Blend droplet normals into base normal
    NORMAL_MAP = mix(NORMAL_MAP, drop_normalmap, drop_mix_ratio);

    // Specular boost where droplets are
    SPECULAR = mix(0.5, 1.0, drop_mix_ratio);

    // Optional: refract/distort albedo slightly with noise
    vec3 albedo_deform = texture(albedo_texture, uv + noise_val * 0.02).rgb;
    ALBEDO = mix(ALBEDO, albedo_deform, drop_mix_ratio);
}