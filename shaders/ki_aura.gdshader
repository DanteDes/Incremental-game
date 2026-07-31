shader_type canvas_item;

uniform float aura: hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec3 ki_color = vec3(1.0, 0.88, 0.3);
	COLOR.rgb = mix(COLOR.rgb, ki_color, aura * COLOR.a * 0.55);
	COLOR.rgb += ki_color * aura * 0.2 * COLOR.a;
}
