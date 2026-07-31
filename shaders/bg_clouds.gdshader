shader_type canvas_item;

uniform float speed:    hint_range(0.0, 0.05) = 0.012;
uniform float coverage: hint_range(0.0, 1.0)  = 0.44;
uniform float density:  hint_range(0.0, 1.0)  = 0.52;
uniform vec4  cloud_color: source_color = vec4(0.80, 0.84, 0.93, 1.0);

// Deterministic hash for value noise
float hash21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

// Smooth value noise
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash21(i),             hash21(i + vec2(1.0, 0.0)), f.x),
		mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x),
		f.y);
}

// Fractal Brownian Motion — 6 octaves for rich cloud texture
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 6; i++) {
		v += a * vnoise(p);
		p  = p * 2.1 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	float sky_fade = smoothstep(0.66, 0.28, UV.y);

	vec2 uv = UV * vec2(2.8, 1.8) + vec2(TIME * speed, 0.0);

	float cloud  = fbm(uv);
	float detail = fbm(uv * 2.3 + vec2(5.1, 3.7)) * 0.35;
	cloud = smoothstep(coverage - 0.18, coverage + 0.20, cloud + detail);
	cloud *= sky_fade * density;

	COLOR = vec4(cloud_color.rgb, cloud * cloud_color.a);
}
