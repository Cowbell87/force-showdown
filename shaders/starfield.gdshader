shader_type canvas_item;
// Animated deep-space backdrop: drifting nebula, three parallax star layers,
// a lit planet in the corner and a "danger" tint used during Sudden Death.

uniform vec3 deep_color : source_color = vec3(0.01, 0.012, 0.035);
uniform vec3 nebula_a : source_color = vec3(0.16, 0.05, 0.28);
uniform vec3 nebula_b : source_color = vec3(0.02, 0.18, 0.32);
uniform vec3 planet_color : source_color = vec3(0.85, 0.45, 0.25);
uniform float drift = 0.004;
uniform float danger : hint_range(0.0, 1.0) = 0.0;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

float star_layer(vec2 uv, float density, float threshold, float t) {
	vec2 g = floor(uv * density);
	vec2 f = fract(uv * density);
	float h = hash(g);
	if (h < threshold) {
		return 0.0;
	}
	vec2 c = vec2(hash(g + 3.1), hash(g + 7.7)) * 0.8 + 0.1;
	float d = length(f - c);
	float twinkle = 0.65 + 0.35 * sin(t * (1.5 + h * 3.0) + h * 40.0);
	return (1.0 - smoothstep(0.0, 0.09, d)) * twinkle;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 p = vec2(uv.x * aspect, uv.y);
	float t = TIME;

	vec3 col = deep_color;
	float n1 = fbm(p * 2.2 + vec2(t * drift, 0.0));
	float n2 = fbm(p * 3.7 - vec2(0.0, t * drift * 0.7) + 5.0);
	col += nebula_a * smoothstep(0.45, 0.95, n1) * 1.4;
	col += nebula_b * smoothstep(0.5, 1.0, n2) * 1.2;

	col += vec3(star_layer(p + vec2(t * 0.002, 0.0), 90.0, 0.93, t)) * 0.7;
	col += vec3(0.75, 0.85, 1.0) * star_layer(p + vec2(t * 0.005, 0.0), 45.0, 0.96, t * 1.3);
	col += vec3(1.0, 0.95, 0.85) * star_layer(p + vec2(t * 0.009, 0.0), 22.0, 0.985, t * 0.7) * 1.2;

	// Planet in the lower right.
	vec2 pc = vec2(aspect * 0.92, 1.25);
	float pr = 0.55;
	float d = length(p - pc);
	if (d < pr) {
		vec2 local = (p - pc) / pr;
		float bands = fbm(vec2(local.x * 3.0 + t * 0.01, local.y * 12.0));
		vec3 surf = planet_color * (0.35 + 0.65 * bands);
		vec3 sphere_n = normalize(vec3(local, sqrt(max(0.0, 1.0 - dot(local, local)))));
		float light = clamp(dot(sphere_n, normalize(vec3(-0.6, -0.7, 0.4))), 0.0, 1.0);
		col = mix(col, surf * (0.08 + light), 0.97);
	}
	float rim = (1.0 - smoothstep(pr, pr + 0.03, d)) * smoothstep(pr - 0.02, pr + 0.005, d);
	col += planet_color * rim * 0.9;
	col += planet_color * 0.25 * (1.0 - smoothstep(pr, pr + 0.25, d)) * step(pr, d);

	// Vignette and Sudden Death tint.
	float vig = 1.0 - smoothstep(0.3, 1.2, length(uv - 0.5) * 1.6);
	col *= mix(0.55, 1.0, vig);
	col = mix(col, col + vec3(0.35, 0.0, 0.02) * (1.2 - vig), danger);
	COLOR = vec4(col, 1.0);
}
