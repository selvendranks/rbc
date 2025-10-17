shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back;

// --- Droplet textures ---
uniform sampler2D rain_drip_grad_text;
uniform sampler2D rain_drip_tex;
uniform vec3 rain_drip_color : source_color;

// UV scaling for droplets
uniform vec2 rain_drip_scale = vec2(1.0);

// Normal intensity for highlights
uniform float normal_strength : hint_range(0.0, 5.0) = 1.0;

// Control droplet density (0 = none, 1 = full)
uniform float droplet_density : hint_range(0.0, 1.0) = 1.0;

// Reflection control
uniform float reflection_multiplier : hint_range(0.0, 3.0) = 1.0;

varying vec3 my_pos;
varying vec3 my_normal;
varying float up;

void vertex() {
	my_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	my_normal = abs(normalize(MODEL_NORMAL_MATRIX * NORMAL));
	my_pos.y *= -1.0;
	up = smoothstep(0.1, 0.0, my_normal.y);
}

void fragment() {
	// Compute droplet UV based on mesh position
	vec2 rain_drip_uv = mix(my_pos.xy, my_pos.zy, round(my_normal.x));
	rain_drip_uv *= rain_drip_scale;

	// Sample droplet texture
	vec4 drip = texture(rain_drip_tex, rain_drip_uv);
	vec3 drip_normalmap = vec3(drip.x, drip.y, 1.0);

	// Animate flow using gradient
	vec2 rain_drip_move_uv = rain_drip_uv.yx - vec2(TIME * 0.3 * drip.a, 0.0);
	float drip_grad = texture(rain_drip_grad_text, rain_drip_move_uv).r;

	// Droplet intensity with density and surface orientation
	float drip_mix_ratio = drip.b * drip_grad * up * droplet_density;

	// Normals for highlights
	vec3 normal_map = normalize(vec3(0.0, 0.0, 1.0));
	normal_map = mix(normal_map, drip_normalmap, drip_mix_ratio * normal_strength);
	NORMAL_MAP = normal_map * 0.5 + 0.5;

	// Reflection / wet look
	ROUGHNESS = mix(0.8, 0.05, drip_mix_ratio);
	SPECULAR = mix(0.5, reflection_multiplier, drip_mix_ratio);
	METALLIC = mix(0.0, 0.3, drip_mix_ratio);

	// Droplet color and transparency
	ALBEDO = rain_drip_color;
	ALPHA = drip_mix_ratio;
}
