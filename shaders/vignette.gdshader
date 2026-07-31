shader_type canvas_item;

uniform float strength: hint_range(0.0, 2.0) = 0.5;
uniform vec3 tint_color: source_color = vec3(0.03, 0.05, 0.12);

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv * vec2(1.0, 1.3));
	float vignette = smoothstep(0.55, 0.25, dist);
	float alpha = (1.0 - vignette) * strength;
	COLOR = vec4(tint_color, alpha);
}
