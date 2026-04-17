shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(0.03, 0.05, 0.08, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.06, 0.08, 0.11, 1.0);
uniform vec4 glow_a : source_color = vec4(0.18, 0.74, 0.62, 1.0);
uniform vec4 glow_b : source_color = vec4(0.96, 0.62, 0.28, 1.0);
uniform vec4 glow_c : source_color = vec4(0.22, 0.45, 0.92, 1.0);
uniform float glow_strength : hint_range(0.0, 1.0) = 0.26;
uniform float line_strength : hint_range(0.0, 1.0) = 0.07;

float soft_blob(vec2 uv, vec2 center, vec2 stretch, float radius) {
	vec2 delta = (uv - center) / stretch;
	float distance_value = length(delta);
	return 1.0 - smoothstep(radius * 0.28, radius, distance_value);
}

void fragment() {
	vec2 uv = UV;
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	float time = TIME * 0.18;

	vec3 color = mix(top_color.rgb, bottom_color.rgb, smoothstep(0.0, 1.0, uv.y));

	float blob_a = soft_blob(uv, vec2(0.18 + sin(time * 1.4) * 0.05, 0.22 + cos(time * 0.9) * 0.04), vec2(0.82, 0.72), 0.62);
	float blob_b = soft_blob(uv, vec2(0.76 + cos(time * 1.1) * 0.05, 0.34 + sin(time * 0.8) * 0.05), vec2(0.72, 0.66), 0.56);
	float blob_c = soft_blob(uv, vec2(0.54 + sin(time * 0.7) * 0.07, 0.86 + cos(time * 0.5) * 0.03), vec2(0.94, 0.52), 0.58);

	color += glow_a.rgb * blob_a * glow_strength;
	color += glow_b.rgb * blob_b * glow_strength * 0.82;
	color += glow_c.rgb * blob_c * glow_strength * 0.68;

	float scan_lines = 0.5 + 0.5 * sin((uv.y + time * 0.4) * 95.0);
	color += vec3(0.03, 0.04, 0.05) * scan_lines * line_strength;

	vec2 centered = vec2((uv.x - 0.5) * aspect, uv.y - 0.5);
	float vignette = 1.0 - smoothstep(0.34, 1.08, length(centered));
	color *= mix(0.58, 1.0, vignette);

	COLOR = vec4(color, 1.0);
}
