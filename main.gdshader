shader_type spatial;

uniform sampler2D height_noise;
uniform float height_scale = 18.0;

// Path uniforms
uniform vec4 path_color   : source_color = vec4(0.48, 0.40, 0.32, 1.0);
uniform float path_width  : hint_range(1.0, 15.0) = 4.5;

// Biome Palettes
uniform vec4 desert_color : source_color = vec4(0.88, 0.72, 0.54, 1.0); // Dune Sand
uniform vec4 rock_color   : source_color = vec4(0.45, 0.42, 0.40, 1.0); // Mountain Rock
uniform vec4 snow_color   : source_color = vec4(0.92, 0.95, 0.98, 1.0); // Snow Peak
uniform vec4 grass_color  : source_color = vec4(0.40, 0.58, 0.35, 1.0); // Riverbank Flora
uniform vec4 water_bed    : source_color = vec4(0.18, 0.38, 0.42, 1.0); // Pond Shallows

varying float world_y;
varying vec3 world_pos;
varying vec3 calc_normal;

float get_base_height(vec2 uv) {
	return texture(height_noise, uv).r;
}

void vertex() {
	// Standard height matching the physics collision exactly
	float raw_h = get_base_height(UV);
	VERTEX.y += raw_h * height_scale;
	
	world_y = VERTEX.y;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// Slope normals
	float texel = 1.0 / 150.0;
	float hr = (get_base_height(UV + vec2(texel, 0.0)) * height_scale);
	float hu = (get_base_height(UV + vec2(0.0, texel)) * height_scale);
	vec3 tangent = normalize(vec3(1.0, (hr - VERTEX.y), 0.0));
	vec3 binormal = normalize(vec3(0.0, (hu - VERTEX.y), 1.0));
	calc_normal = normalize(cross(binormal, tangent));
	NORMAL = calc_normal;
}

void fragment() {
	float slope = clamp(dot(calc_normal, vec3(0.0, 1.0, 0.0)), 0.0, 1.0);

	// Quadrant Biomes using World Position across 400m
	float snow_zone  = smoothstep(-20.0, 120.0, world_pos.x) * smoothstep(40.0, -120.0, world_pos.z);
	float basin_zone = smoothstep(20.0, -120.0, world_pos.x) * smoothstep(40.0, -120.0, world_pos.z);

	// 1. Base Desert
	vec3 col = desert_color.rgb;

	// 2. Pond / Oasis Basin Corner
	if (basin_zone > 0.01) {
		vec3 oasis = mix(water_bed.rgb, grass_color.rgb, smoothstep(2.0, 8.0, world_y));
		col = mix(col, oasis, basin_zone);
	}

	// 3. Snowy Mountain Corner
	if (snow_zone > 0.01) {
		vec3 mountain = mix(rock_color.rgb, snow_color.rgb, smoothstep(10.0, 16.0, world_y));
		col = mix(col, mountain, snow_zone);
	}

	// 4. Steep Cliffs
	float cliff_mask = 1.0 - smoothstep(0.45, 0.75, slope);
	col = mix(col, rock_color.rgb, cliff_mask * 0.75);

	// 5. Natural Meandering Path
	float ground_noise = texture(height_noise, (world_pos.xz + 200.0) / 400.0 * 3.0).r - 0.5;
	float path_curve = sin(world_pos.z * 0.025) * 45.0 
	                 + cos(world_pos.z * 0.065) * 22.0 
	                 + sin(world_pos.z * 0.12) * 8.0;
	float warped_x = world_pos.x + (ground_noise * 12.0);
	float dist_to_path = abs(warped_x - path_curve);
	float local_width = path_width * (0.8 + ground_noise * 0.4);
	float path_mask = 1.0 - smoothstep(local_width * 0.35, local_width, dist_to_path);

	col = mix(col, path_color.rgb, path_mask * 0.9);

	ALBEDO = col;
	ROUGHNESS = mix(0.85, 0.95, path_mask);
}