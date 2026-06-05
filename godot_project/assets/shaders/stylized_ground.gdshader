shader_type spatial;
render_mode cull_back, diffuse_burley, specular_disabled;

// Стилизованная "мультяшная" земля: смесь двух оттенков травы по шуму,
// плюс крупные пятна для разнообразия. Без текстур — чистый low-poly вид.

uniform vec3 color_a : source_color = vec3(0.36, 0.55, 0.27); // основная трава
uniform vec3 color_b : source_color = vec3(0.45, 0.62, 0.32); // светлее
uniform vec3 color_dirt : source_color = vec3(0.50, 0.45, 0.30); // проплешины
uniform float patch_scale = 0.06;   // масштаб крупных пятен
uniform float detail_scale = 0.5;   // мелкая зернистость
uniform float dirt_amount = 0.12;   // сколько земли

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 wp = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xz;
	float macro = noise(wp * patch_scale);
	float micro = noise(wp * detail_scale);
	vec3 grass = mix(color_a, color_b, smoothstep(0.35, 0.65, macro));
	grass = mix(grass, grass * 0.92, micro * 0.4);
	// редкие земляные пятна
	float dirt = smoothstep(1.0 - dirt_amount, 1.0, noise(wp * patch_scale * 1.7 + 13.0));
	vec3 col = mix(grass, color_dirt, dirt);
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.1;
}
