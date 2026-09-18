shader_type spatial;

uniform sampler2D height_noise;
uniform float height_scale = 18.0;

uniform vec4 valley_color : source_color = vec4(0.55, 0.68, 0.70, 1.0);
uniform vec4 plains_color : source_color = vec4(0.88, 0.82, 0.74, 1.0);
uniform vec4 peak_color   : source_color = vec4(0.68, 0.76, 0.65, 1.0);
uniform vec4 cliff_color  : source_color = vec4(0.78, 0.58, 0.52, 1.0);

varying float world_y;
varying vec3 calc_normal;

float get_height(vec2 uv) {
	float h = texture(height_noise, uv).r;
	// Narrow terrace band so peaks and valleys stay prominent
	if (h > 0.45 && h < 0.55) {
		h = mix(h, 0.5, 0.6);
	}
	return h;
}

void vertex() {
	float h = get_height(UV);
	VERTEX.y += h * height_scale;
	world_y = VERTEX.y;

	// Calculate true slope normals from neighboring points
	float texel = 1.0 / 120.0;
	float h_right = get_height(UV + vec2(texel, 0.0)) * height_scale;
	float h_up    = get_height(UV + vec2(0.0, texel)) * height_scale;
	
	vec3 tangent = normalize(vec3(1.0, (h_right - VERTEX.y), 0.0));
	vec3 binormal = normalize(vec3(0.0, (h_up - VERTEX.y), 1.0));
	calc_normal = normalize(cross(binormal, tangent));
	NORMAL = calc_normal;
}

void fragment() {
	float slope = clamp(dot(calc_normal, vec3(0.0, 1.0, 0.0)), 0.0, 1.0);

	vec3 base_color = valley_color.rgb;
	float valley_plains = smoothstep(3.0, 7.0, world_y);
	base_color = mix(base_color, plains_color.rgb, valley_plains);
	
	float plains_peaks = smoothstep(10.0, 14.0, world_y);
	base_color = mix(base_color, peak_color.rgb, plains_peaks);

	float cliff_mask = 1.0 - smoothstep(0.55, 0.85, slope);
	vec3 final_color = mix(base_color, cliff_color.rgb, cliff_mask);

	ALBEDO = final_color;
	ROUGHNESS = 0.85;
}